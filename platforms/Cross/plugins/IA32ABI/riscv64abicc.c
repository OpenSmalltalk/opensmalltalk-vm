/*
 *  riscv64abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin on RV64G.
 *  Written by Eliot Miranda & Ryan Macnak, 07/15.
 *  Updated for riscv64 by Ken Dickey 06/22
 */
/*
 Stack grows Down; 16 byte aligned
 32 integer and 32 double float registers
  x0 - always Zero  [Thread swap shadow uses slot for PC]
  x1 - Return Address
  x2 - Stack Pointer (SP)
  x8 - Frame Pointer
  Argument registers: 8 integer and 8 float
    A0..7 = x10..x17  ;  FA0..FA7 = f10..f17
  In RV64 sizeof(long) = sizeof(long long) = 8 = sizeof(void *)
  Args larger than (void *) pointer are passed by reference.
  Conceptually, args as fields of C struct with pointer alignment;
    more args than # arg regs passed on stack with SP pointing
    to 1st arg not passed in a register.
    Excess float args may be passed in otherwise unused int regs.
  Values returned in A0/A1 or FA0/FA1
  Larger return values are placed in space alloc'ed by caller,
    with pointer passed as implicit 1st parameter (A0).

  Note reuse of "dabusinessARM.h" call mechanics code.
*/

/* null if compiled on other than riscv64, to get around gnu make bugs or
 * misunderstandings on our part.
 */
#if defined(__riscv64__)

#include <unistd.h> // for getpagesize/sysconf
#include <stdlib.h> // for valloc
#include <sys/mman.h> // for mprotect
#include <string.h> // for memcpy et al
#include <setjmp.h>
#include <stdio.h> // for fprintf(stderr,...)

#include "objAccess.h"
#include "vmCallback.h"
#include "sqAssert.h"
#include "ia32abi.h"

#if !defined(min)
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#define STACK_ALIGN_BYTES 16
#define NUM_REG_ARGS  8
#define NUM_DREG_ARGS 16

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;

#ifdef _MSC_VER
# define alloca _alloca
#endif

#define RoundUpPowerOfTwo(value, modulus) \
  (((value) + (modulus) - 1) & ~((modulus) - 1))

#define IsAlignedPowerOfTwo(value, modulus) \
  (((value) & ((modulus) - 1)) == 0)

/*
 * Call a foreign function to set structure result address return register
 */
extern void callAndReturnWithStructAddr(sqLong structAddr, sqLong procAddr, sqLong regValuesArrayAddr)
{ /* Any float regs already loaded
     Alloca'd struct address already in A0 for results.
     Move call target into temp6 for jump.
     Spread int args into other int registers.
   */
  asm volatile (
	"ADDI t6,  a1, 0  \n\t"
	"ADDI t5,  a2, 0  \n\t"
	"LD   a1,  0(t5)  \n\t"
	"LD   a2,  8(t5)  \n\t"
	"LD   a3,  16(t5) \n\t"
	"LD   a4,  24(t5) \n\t"
	"LD   a5,  32(t5) \n\t"
	"LD   a6,  40(t5) \n\t"
	"JALR x0,  t6, 0  \n\t"
  );
}

/*
 * Call a foreign function to get structure value from a1
 * (a0's value already returned as result of ffi call)
 */
extern sqLong returnX1value()
{
  sqLong value = 0;
  asm volatile ("ADDI a0, a1, 0" : "=r"(value) ) ;
  return (value) ;
}


/*
 * Call a foreign function that answers an integral result in r0 according to
 * RISCV RV64 ABI rules.
 */
sqLong callIA32IntegralReturn(SIGNATURE) {
  sqInt (*f)(long r0, long r1, long r2, long r3,
             long r4, long r5, long r6, long r7,
             double d0, double d1, double d2, double d3,
             double d4, double d5, double d6, double d7);
  sqInt r;
#include "dabusinessARM.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in VFP's s0 according to RV64 EABI rules.
 */
sqLong callIA32FloatReturn(SIGNATURE) {
  float (*f)(long r0, long r1, long r2, long r3,
             long r4, long r5, long r6, long r7,
             double d0, double d1, double d2, double d3,
             double d4, double d5, double d6, double d7);
  float r;
#include "dabusinessARM.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in VFP's d0 according to RV64 EABI rules.
 */
sqInt
callIA32DoubleReturn(SIGNATURE) {
  double (*f)(long r0, long r1, long r2, long r3,
              long r4, long r5, long r6, long r7,
              double d0, double d1, double d2, double d3,
              double d4, double d5, double d6, double d7);
  double r;
#include "dabusinessARM.h"
}

/* Queueing order for callback returns.  To ensure that callback returns occur
 * in LIFO order we provide mostRecentCallbackContext which is tested by the
 * return primitive primReturnFromContextThrough.  Note that in the threaded VM
 * this does not have to be thread-specific or locked since it is within the
 * bounds of the ownVM/disownVM pair.
 */
static VMCallbackContext *mostRecentCallbackContext = 0;

VMCallbackContext *
getMostRecentCallbackContext() { return mostRecentCallbackContext; }

#define getMRCC(t) mostRecentCallbackContext
#define setMRCC(t) (mostRecentCallbackContext = (void *)(t))

/*
 * Entry-point for call-back thunks.  Args are register args, thunk address
 * and stack pointer.
 * The stack is:
 *     stackp
 * sp->thunk address
 *
 * This function's roles are to collect any register arguments (including
 * floating point), to use setjmp/longjmp to save the point of call and
 * return to it, to correct C stack pointer alignment if necessary (see
 * STACK_ALIGN_HACK), and to return any of the various values from the callback.
 *
 * Nota Bene:
 *	double result in fa0, NOT a0
 *	large struct address returns in a0 (UNlike arm's x8)
 */
long long
thunkEntry(long x0, long x1, long x2, long x3,
	   long x4, long x5, long x6, long x7,
	   double d0, double d1, double d2, double d3,
	   double d4, double d5, double d6, double d7,
	   void *thunkp, sqIntptr_t *stackp)
{
  VMCallbackContext vmcc;  /* See  src/spur64.stack/vmCallback.h */
  int returnType;
  sqIntptr_t regArgs[NUM_REG_ARGS];
  double dregArgs[NUM_DREG_ARGS];

  regArgs[0] = x0;
  regArgs[1] = x1;
  regArgs[2] = x2;
  regArgs[3] = x3;
  regArgs[4] = x4;
  regArgs[5] = x5;
  regArgs[6] = x6;
  regArgs[7] = x7;
  dregArgs[0] = d0;
  dregArgs[1] = d1;
  dregArgs[2] = d2;
  dregArgs[3] = d3;
  dregArgs[4] = d4;
  dregArgs[5] = d5;
  dregArgs[6] = d6;
  dregArgs[7] = d7;

  if (interpreterProxy->ownVM(NULL /* unidentified thread */) < 0) {
    fprintf(stderr,"Warning; callback failed to own the VM\n");
    return -1;
  }

  if ((returnType = setjmp(vmcc.trampoline)) == 0) {
    vmcc.savedMostRecentCallbackContext = getMRCC();
    setMRCC(&vmcc);
    vmcc.thunkp = thunkp;
    vmcc.stackp = stackp;
    vmcc.intregargsp   = regArgs;
    vmcc.floatregargsp = dregArgs;
    interpreterProxy->sendInvokeCallbackContext(&vmcc);
    fprintf(stderr,"Warning; callback failed to invoke\n");
    setMRCC(vmcc.savedMostRecentCallbackContext);
    interpreterProxy->disownVM(DisownVMFromCallback);
    return -1;
  }

  setMRCC(vmcc.savedMostRecentCallbackContext);
  interpreterProxy->disownVM(DisownVMFromCallback);

  switch (returnType) {
  case retword:
    return vmcc.rvs.valword;
  case retword64:
    return *(long *)&vmcc.rvs.valword;
  case retdouble:
/*    memcpy(d0, vmcc.rvs.valflt64, sizeof(double)); */
    d0 = vmcc.rvs.valflt64;
    return d0;
  case retstruct:
    memcpy((void *)x0, vmcc.rvs.valstruct.addr, vmcc.rvs.valstruct.size);
    return x0;
  }

  fprintf(stderr, "Warning; invalid callback return type\n");
  return 0;
}

/*
 * Thunk allocation support.  Since thunks must be executable and some OSs
 * may not provide default execute permission on memory returned by malloc
 * we must provide memory that is guaranteed to be executable.  The abstraction
 * is to answer an Alien that references an executable piece of memory that
 * is some (possiby unitary) multiple of the pagesize.
 *
 * We assume the Smalltalk image code will manage subdividing the executable
 * page amongst thunks so there is no need to free these pages, since the image
 * will recycle parts of the page for reclaimed thunks.
 */
static usqInt pagesize = 0;

#if defined(MAP_JIT)
void **allocatedPages = 0;
int allocatedPagesSize = 0;
#endif

void *
allocateExecutablePage(sqIntptr_t *size)
{
	void *mem;

#if defined(_MSC_VER) || defined(__MINGW32__)
# if !defined(MEM_TOP_DOWN)
#	define MEM_TOP_DOWN 0x100000
# endif
	if (!pagesize) {
		SYSTEM_INFO	sysinf;

		GetSystemInfo(&sysinf);

		pagesize = sysinf.dwPageSize;
	}
	/* N.B. VirtualAlloc MEM_COMMIT initializes the memory returned to zero. */
	mem = VirtualAlloc(	0,
						pagesize,
						MEM_COMMIT | MEM_TOP_DOWN,
						PAGE_EXECUTE_READWRITE);
	if (mem)
		*size = pagesize;
	return mem;

#elif defined(MAP_JIT)
# if __OpenBSD__
#	define MAP_FLAGS	(MAP_ANON | MAP_PRIVATE | MAP_STACK)
# else
#	define MAP_FLAGS	(MAP_ANON | MAP_PRIVATE)
# endif

	void **newAllocatedPages;
	if (!pagesize)
# if !defined(_POSIX_C_SOURCE) || _POSIX_C_SOURCE < 200112L
		pagesize = getpagesize();
# else
		pagesize = sysconf(_SC_PAGESIZE);
# endif

	mem = mmap(	0, pagesize,
				PROT_READ | PROT_WRITE | PROT_EXEC,
				MAP_FLAGS | MAP_JIT, -1, 0);
	if (mem == MAP_FAILED) {
		perror("Could not allocateExecutablePage");
		return 0;
	}
	*size = pagesize;

# if defined(MAP_JIT)
	newAllocatedPages = realloc(allocatedPages,
								 ++allocatedPagesSize * sizeof(void *));
	if (!newAllocatedPages) {
		--allocatedPagesSize;
		munmap(mem, pagesize);
		perror("Could not realloc allocatedPages");
		return 0;
	}
	allocatedPages = newAllocatedPages;
	newAllocatedPages[allocatedPagesSize - 1] = mem;
# endif
	return mem;
#else

	if (!pagesize)
# if !defined(_POSIX_C_SOURCE) || _POSIX_C_SOURCE < 200112L
		pagesize = getpagesize();
# else
		pagesize = sysconf(_SC_PAGESIZE);
# endif

	if (!(mem = valloc(pagesize)))
		return 0;

	memset(mem, 0, pagesize);
	if (mprotect(mem, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC) < 0) {
		free(mem);
		return 0;
	}
	*size = pagesize;
	return mem;
#endif
}

#if defined(MAP_JIT)
sqInt
ifIsWithinExecutablePageMakePageWritable(char *address)
{
	void *page = (void *)((uintptr_t)address & ~(pagesize - 1));
	int i;

	if (!pagesize)
		return 0;

	for (i = 0; i < allocatedPagesSize; i++)
		if (allocatedPages[i] == page) {
			pthread_jit_write_protect_np(0);
			return 1;
		}
	return 0;
}

void
makePageExecutableAgain(char *address)
{
	pthread_jit_write_protect_np(1);
#if __APPLE__ && __MACH__ /* Mac OS X */
	sys_dcache_flush(address, 64);
	sys_icache_invalidate(address, 64);
#endif
}
#endif // defined(MAP_JIT)
#endif /* defined(__ARM_ARCH_ISA_A64) || defined(__arm64__) || ... */
