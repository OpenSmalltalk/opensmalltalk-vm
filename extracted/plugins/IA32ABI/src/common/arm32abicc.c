/*
 *  armia32abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin on ARM.
 *  Written by Eliot Miranda & Ryan Macnak, 07/15.
 */

/* null if compiled on other than arm32, to get around gnu make bugs or
 * misunderstandings on our part.
 */
#if defined(__ARM_ARCH__) || defined(__arm__) || defined(__arm32__) || defined(ARM32)

#include <stdlib.h> /* for valloc */
#include <sys/mman.h> /* for mprotect */

#include <string.h> /* for memcpy et al */
#include <setjmp.h>

#include "sqMemoryAccess.h"
#include "vmCallback.h"
#include "sqAssert.h"
#include "sqVirtualMachine.h"
#include "ia32abi.h"

#include "pharovm/debug.h"

#if !defined(min)
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#define STACK_ALIGN_BYTES 8
#define NUM_REG_ARGS 4
#define NUM_DREG_ARGS 8

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;

#ifdef _MSC_VER
# define alloca _alloca
#endif

#define RoundUpPowerOfTwo(value, modulus)                                      \
  (((value) + (modulus) - 1) & ~((modulus) - 1))

#define IsAlignedPowerOfTwo(value, modulus)                                    \
  (((value) & ((modulus) - 1)) == 0)

#define objIsAlien(anOop)                                                      \
    (interpreterProxy->includesBehaviorThatOf(                                 \
      interpreterProxy->fetchClassOf(anOop),                                   \
      interpreterProxy->classAlien()))

#define objIsUnsafeAlien(anOop)                                                \
    (interpreterProxy->includesBehaviorThatOf(                                 \
      interpreterProxy->fetchClassOf(anOop),                                   \
      interpreterProxy->classUnsafeAlien()))

#define sizeField(alien)                                                       \
    (*(long*)pointerForOop((sqInt)(alien) + BaseHeaderSize))

#define dataPtr(alien)                                                         \
    pointerForOop((sqInt)(alien) + BaseHeaderSize + BytesPerOop)

#define isIndirect(alien)                                                      \
    (sizeField(alien) < 0)

#define startOfParameterData(alien)                                            \
    (isIndirect(alien)  ? *(void **)dataPtr(alien)                             \
                        :  (void  *)dataPtr(alien))

#define isIndirectSize(size)                                                   \
    ((size) < 0)

#define startOfDataWithSize(alien, size)                                       \
    (isIndirectSize(size) ? *(void **)dataPtr(alien)	                       \
                          :  (void  *)dataPtr(alien))

#define isSmallInt(oop)                                                        \
    ((oop)&1)

#define intVal(oop)                                                            \
    (((long)(oop))>>1)

/*
 * Call a foreign function that answers an integral result in r0 according to
 * ARM EABI rules.
 */
sqInt callIA32IntegralReturn(SIGNATURE) {
  long (*f)(long r0, long r1, long r2, long r3,
            double d0, double d1, double d2, double d3,
            double d4, double d5, double d6, double d7);
  long r;
#include "dabusinessARM.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in VFP's s0 according to ARM EABI rules.
 */
sqInt callIA32FloatReturn(SIGNATURE) {
  float (*f)(long r0, long r1, long r2, long r3,
             double d0, double d1, double d2, double d3,
             double d4, double d5, double d6, double d7);
  float r;
#include "dabusinessARM.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in VFP's d0 according to ARM EABI rules.
 */
sqInt
callIA32DoubleReturn(SIGNATURE) {
  double (*f)(long r0, long r1, long r2, long r3,
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

#define getMRCC()   mostRecentCallbackContext
#define setMRCC(t) (mostRecentCallbackContext = (void *)(t))

extern void error(char *s);

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
 */
long long
thunkEntry(long r0, long r1, long r2, long r3,
			double d0, double d1, double d2, double d3,
			double d4, double d5, double d6, double d7,
			void *thunkpPlus16, sqIntptr_t *stackp)
{
  VMCallbackContext vmcc;
  VMCallbackContext *previousCallbackContext;
  int flags;
  int returnType;
  long regArgs[NUM_REG_ARGS];
  double dregArgs[NUM_DREG_ARGS];

  regArgs[0] = r0;
  regArgs[1] = r1;
  regArgs[2] = r2;
  regArgs[3] = r3;

  dregArgs[0] = d0;
  dregArgs[1] = d1;
  dregArgs[2] = d2;
  dregArgs[3] = d3;
  dregArgs[4] = d4;
  dregArgs[5] = d5;
  dregArgs[6] = d6;
  dregArgs[7] = d7;

  flags = interpreterProxy->ownVM(0);
  if (flags < 0) {
    logWarn("Warning; callback failed to own the VM\n");
    return -1;
  }

  if ((returnType = setjmp(vmcc.trampoline)) == 0) {
    previousCallbackContext = getMRCC();
    setMRCC(&vmcc);
    vmcc.thunkp = (void *)((char *)thunkpPlus16 - 16);
    vmcc.stackp = stackp;
    vmcc.intregargsp = regArgs;
    vmcc.floatregargsp = dregArgs;
    interpreterProxy->sendInvokeCallbackContext(&vmcc);
    logWarn("Warning; callback failed to invoke\n");
    setMRCC(previousCallbackContext);
    interpreterProxy->disownVM(flags);
    return -1;
  }

  setMRCC(previousCallbackContext);
  interpreterProxy->disownVM(flags);

  switch (returnType) {
  case retword:
    return vmcc.rvs.valword;
  case retword64:
  case retdouble:
    return *(long long *)&vmcc.rvs.valword;
  case retstruct:
    memcpy((void *)r0, vmcc.rvs.valstruct.addr, vmcc.rvs.valstruct.size);
    return r0;
  }

  logWarn("Warning; invalid callback return type\n");
  return 0;
}

/*
 * Thunk allocation support.  Since thunks must be exectuable and some OSs
 * may not provide default execute permission on memory returned by malloc
 * we must provide memory that is guaranteed to be executable.  The abstraction
 * is to answer an Alien that references an executable piece of memory that
 * is some (possiby unitary) multiple of the pagesize.
 *
 * We assume the Smalltalk image code will manage subdividing the executable
 * page amongst thunks so there is no need to free these pages, since the image
 * will recycle parts of the page for reclaimed thunks.
 */
#if defined(_MSC_VER) || defined(__MINGW32__)
static unsigned long pagesize = 0;
#endif

void *
allocateExecutablePage(long *size)
{
	void *mem;

#if defined(_MSC_VER) || defined(__MINGW32__)
#if !defined(MEM_TOP_DOWN)
# define MEM_TOP_DOWN 0x100000
#endif
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
#else
	long pagesize = getpagesize();

	if (!(mem = valloc(pagesize)))
		return 0;

	memset(mem, 0, pagesize);
	if (mprotect(mem, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC) < 0) {
		free(mem);
		return 0;
	}
	*size = pagesize;
#endif
	return mem;
}
#endif /* defined(__ARM_ARCH__) || defined(__arm__) || ... */
