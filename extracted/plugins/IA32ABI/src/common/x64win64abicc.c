/*
 *  x64win64ia32abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin on x86_64 on Windows.
 * here referred to as x64win64ABI
 */

/* null if compiled on other than x64, to get around gnu make bugs or
 * misunderstandings on our part.
 */
#if defined(x86_64) || defined(__amd64) || defined(__x86_64) || defined(__amd64__) || defined(__x86_64__) || defined(_M_AMD64) || defined(_M_X64)

#if defined(_MSC_VER) || defined(__MINGW32__)
# include "windows.h" /* for GetSystemInfo & VirtualAlloc */
#else
# error Non windows should use the SystemV ABI, not the win64 ABI
#endif

# include <stdlib.h> /* for valloc */
#include <string.h> /* for memcpy et al */
#include <setjmp.h>

#include "sq.h"

#include "sqMemoryAccess.h"
#include "vmCallback.h"
#include "sqAssert.h"
#include "sqVirtualMachine.h"
#include "ia32abi.h"

#include "pharovm/debug.h"

#if !defined(min)
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#define NUM_REG_ARGS 4

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;

#ifdef _MSC_VER
# define alloca _alloca
#endif
#if __GNUC__
# define setsp(sp) __asm__ volatile ("movq %0,%%rsp" : : "m"(sp))
# define getsp() ({ void *sp; __asm__ volatile ("movq %%rsp,%0" : "=r"(sp) : ); sp;})
#endif
#define STACK_ALIGN_BYTES 32 /* 32 if a 256-bit argument is passed; 16 otherwise */

#if !defined(setsp)
# define setsp(ignored) 0
#endif

#define RoundUpPowerOfTwo(value, modulus)                                      \
  (((value) + (modulus) - 1) & ~((modulus) - 1))

#define IsAlignedPowerOfTwo(value, modulus)                                    \
  (((value) & ((modulus) - 1)) == 0)

#define objIsAlien(anOop) (interpreterProxy->includesBehaviorThatOf(interpreterProxy->fetchClassOf(anOop), interpreterProxy->classAlien()))
#define objIsUnsafeAlien(anOop) (interpreterProxy->includesBehaviorThatOf(interpreterProxy->fetchClassOf(anOop), interpreterProxy->classUnsafeAlien()))

#define sizeField(alien) (*(long long *)pointerForOop((sqInt)(alien) + BaseHeaderSize))
#define dataPtr(alien) pointerForOop((sqInt)(alien) + BaseHeaderSize + BytesPerOop)
#define isIndirect(alien) (sizeField(alien) < 0)
#define startOfParameterData(alien) (isIndirect(alien)	\
									? *(void **)dataPtr(alien)	\
									:  (void  *)dataPtr(alien))
#define isIndirectSize(size) ((size) < 0)
#define startOfDataWithSize(alien,size) (isIndirectSize(size)	\
								? *(void **)dataPtr(alien)		\
								:  (void  *)dataPtr(alien))

#define isSmallInt(oop) (((oop)&7)==1)
#define intVal(oop) (((long long)(oop))>>3)

extern void loadFloatRegs(double,double,double,double);

typedef union {
    long long i;
    double    d;
} int64_or_double;

/*
 * Call a foreign function that answers an integral result in %rax
 * according to x64-ish ABI rules.
 */
sqInt callIA32IntegralReturn(SIGNATURE) {
    long long (*f0)(long long rcx, long long rdx, long long r8, long long r9);
    long long (*f1)(double   xmm0, long long rdx, long long r8, long long r9);
    long long (*f2)(long long rcx, double   xmm1, long long r8, long long r9);
    long long (*f3)(double   xmm0, double   xmm1, long long r8, long long r9);
    long long (*f4)(long long rcx, long long rdx, double  xmm2, long long r9);
    long long (*f5)(double   xmm0, long long rdx, double  xmm2, long long r9);
    long long (*f6)(long long rcx, double   xmm1, double  xmm2, long long r9);
    long long (*f7)(double   xmm0, double   xmm1, double  xmm2, long long r9);
    long long (*f8)(long long rcx, long long rdx, long long r8, double  xmm3);
    long long (*f9)(double   xmm0, long long rdx, long long r8, double  xmm3);
    long long (*fA)(long long rcx, double   xmm1, long long r8, double  xmm3);
    long long (*fB)(double   xmm0, double   xmm1, long long r8, double  xmm3);
    long long (*fC)(long long rcx, long long rdx, double  xmm2, double  xmm3);
    long long (*fD)(double   xmm0, long long rdx, double  xmm2, double  xmm3);
    long long (*fE)(long long rcx, double   xmm1, double  xmm2, double  xmm3);
    long long (*fF)(double   xmm0, double   xmm1, double  xmm2, double  xmm3);
    long long r;
#include "dax64win64business.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in %xmm0 according to x64-ish ABI rules.
 */
sqInt callIA32FloatReturn(SIGNATURE) {
    float (*f0)(long long rcx, long long rdx, long long r8, long long r9);
    float (*f1)(double   xmm0, long long rdx, long long r8, long long r9);
    float (*f2)(long long rcx, double   xmm1, long long r8, long long r9);
    float (*f3)(double   xmm0, double   xmm1, long long r8, long long r9);
    float (*f4)(long long rcx, long long rdx, double  xmm2, long long r9);
    float (*f5)(double   xmm0, long long rdx, double  xmm2, long long r9);
    float (*f6)(long long rcx, double   xmm1, double  xmm2, long long r9);
    float (*f7)(double   xmm0, double   xmm1, double  xmm2, long long r9);
    float (*f8)(long long rcx, long long rdx, long long r8, double  xmm3);
    float (*f9)(double   xmm0, long long rdx, long long r8, double  xmm3);
    float (*fA)(long long rcx, double   xmm1, long long r8, double  xmm3);
    float (*fB)(double   xmm0, double   xmm1, long long r8, double  xmm3);
    float (*fC)(long long rcx, long long rdx, double  xmm2, double  xmm3);
    float (*fD)(double   xmm0, long long rdx, double  xmm2, double  xmm3);
    float (*fE)(long long rcx, double   xmm1, double  xmm2, double  xmm3);
    float (*fF)(double   xmm0, double   xmm1, double  xmm2, double  xmm3);
    float r;
#include "dax64win64business.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in %xmm0 according to x64-ish ABI rules.
 */
sqInt callIA32DoubleReturn(SIGNATURE) {
    double (*f0)(long long rcx, long long rdx, long long r8, long long r9);
    double (*f1)(double   xmm0, long long rdx, long long r8, long long r9);
    double (*f2)(long long rcx, double   xmm1, long long r8, long long r9);
    double (*f3)(double   xmm0, double   xmm1, long long r8, long long r9);
    double (*f4)(long long rcx, long long rdx, double  xmm2, long long r9);
    double (*f5)(double   xmm0, long long rdx, double  xmm2, long long r9);
    double (*f6)(long long rcx, double   xmm1, double  xmm2, long long r9);
    double (*f7)(double   xmm0, double   xmm1, double  xmm2, long long r9);
    double (*f8)(long long rcx, long long rdx, long long r8, double  xmm3);
    double (*f9)(double   xmm0, long long rdx, long long r8, double  xmm3);
    double (*fA)(long long rcx, double   xmm1, long long r8, double  xmm3);
    double (*fB)(double   xmm0, double   xmm1, long long r8, double  xmm3);
    double (*fC)(long long rcx, long long rdx, double  xmm2, double  xmm3);
    double (*fD)(double   xmm0, long long rdx, double  xmm2, double  xmm3);
    double (*fE)(long long rcx, double   xmm1, double  xmm2, double  xmm3);
    double (*fF)(double   xmm0, double   xmm1, double  xmm2, double  xmm3);
    double r;
#include "dax64win64business.h"
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

/*
 * Entry-point for call-back thunks.  Args are the integer register args, the
 * floating-point register arguments, the thunk address and stack pointer, where
 * the stack pointer is pointing one word below the return address of the thunk's
 * callee, 8 bytes below the thunk's first stacked argument.  The stack is:
 *		callback stack arguments
 *		retpc (thunk) <--\
 *		address of retpc-/        <--\
 *		address of address of ret pc-/
 *		thunkp
 *      space for saving 4 registers rcx,rdx,r8,r9
 * rsp->retpc (thunkEntry)
 *
 * This function's roles are to use setjmp/longjmp to save the call point
 * and return to it, and to return any of the various values from the callback.
 *
 * To support x86-64, which on WIN^$ has 4 register arguments (int or floating-point)
 * the function takes 6 arguments, the 4 register args as long longs,
 * followed by the thunkp and stackp passed on the stack.  The register
 * args get copied into a struct on the stack. A pointer to the struct is then
 * passed as an element of the VMCallbackContext.
 */

long long
thunkEntry(long long rcx, long long rdx,
           long long r8, long long r9,
			void *thunkp, sqIntptr_t *stackp)
{
	VMCallbackContext vmcc;
	VMCallbackContext *previousCallbackContext;
	long long flags, returnType;
	long long intargs[4];
	double fpargs[4];

	intargs[0] = rcx;
	intargs[1] = rdx;
	intargs[2] = r8;
	intargs[3] = r9;

extern void saveFloatRegsWin64(long long xmm0,long long xmm1,long long xmm2, long long xmm3,double *fpargs); /* fake passing long long args */
    saveFloatRegsWin64(rcx,rdx,r8,r9,fpargs); /* the callee expects double parameters that it will retrieve thru registers */

	if ((flags = interpreterProxy->ownVM(0)) < 0) {
		logWarn("Warning; callback failed to own the VM\n");
		return -1;
	}

	if (!(returnType = setjmp(vmcc.trampoline))) {
		previousCallbackContext = getMRCC();
		setMRCC(&vmcc);
		vmcc.thunkp = thunkp;
		vmcc.stackp = stackp + 2; /* skip address of retpc & retpc (thunk) */
		vmcc.intregargsp = intargs;
		vmcc.floatregargsp = fpargs;
		interpreterProxy->sendInvokeCallbackContext(&vmcc);
		logWarn("Warning; callback failed to invoke\n");
		setMRCC(previousCallbackContext);
		interpreterProxy->disownVM(flags);
		return -1;
	}
	setMRCC(previousCallbackContext);
	interpreterProxy->disownVM(flags);

	switch (returnType) {

	case retword:	return vmcc.rvs.valword;

	case retword64:  return (((unsigned long long)vmcc.rvs.valleint64.high) << 32)  | (unsigned int)vmcc.rvs.valleint64.low;

	case retdouble:
					fakeReturnDouble( vmcc.rvs.valflt64 );
					return 0;

	case retstruct:	memcpy( (void *)(stackp[1]),
							vmcc.rvs.valstruct.addr,
							vmcc.rvs.valstruct.size);
					return stackp[1];
	}
	logWarn("Warning; invalid callback return type\n");
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
	long long pagesize = getpagesize();

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
#endif /* x86_64|x64|__x86_64|__x86_64__ */
