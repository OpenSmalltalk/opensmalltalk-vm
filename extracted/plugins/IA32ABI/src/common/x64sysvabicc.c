/*
 *  x86ia32abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin on x86_64.
 *  Written by Eliot Miranda 12/14, Ryan Macnak 9/15
 *
 * Based on
 *      System V Application Binary Interface
 *      AMD64 Architecture Processor Supplement
 *      Draft Version 0.99.6
 * here referred to as x64ABI
 */

/* null if compiled on other than x64, to get around gnu make bugs or
 * misunderstandings on our part.
 */
#if x86_64|x64|__x86_64|__x86_64__

#if defined(_MSC_VER) || defined(__MINGW32__)
# include "windows.h" /* for GetSystemInfo & VirtualAlloc */
# error Windows doesn't use the SystemV ABI
#elif __APPLE__ && __MACH__
# include <sys/mman.h> /* for mprotect */
# if OBJC_DEBUG /* define this to get debug info for struct objc_class et al */
#  include <objc/objc.h>
#  include <objc/objc-class.h>

struct objc_class *baz;

void setbaz(void *p) { baz = p; }
void *getbaz() { return baz; }
# endif
# include <stdlib.h> /* for valloc */
# include <sys/mman.h> /* for mprotect */
#else
# include <stdlib.h> /* for valloc */
# include <sys/mman.h> /* for mprotect */
#endif

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

#define NUM_REG_ARGS 6
#define NUM_DREG_ARGS 8

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;

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

#define sizeField(alien) (*(long *)pointerForOop((sqInt)(alien) + BaseHeaderSize))
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
#define intVal(oop) (((long)(oop))>>3)

/*
 * Call a foreign function that answers an integral result in %rax (and
 * possibly %rdx?) according to x64-ish ABI rules.
 */
sqInt callIA32IntegralReturn(SIGNATURE) {
  long (*f)(long rdi, long rsi, long rdx, long rcx, long r8, long r9,
            double xmm0, double xmm1, double xmm2, double xmm3,
            double xmm4, double xmm5, double xmm6, double xmm7);
  long r;
#include "dax64business.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in %xmm0 according to x64-ish ABI rules.
 */
sqInt callIA32FloatReturn(SIGNATURE) {
  float (*f)(long rdi, long rsi, long rdx, long rcx, long r8, long r9,
             double xmm0, double xmm1, double xmm2, double xmm3,
             double xmm4, double xmm5, double xmm6, double xmm7);
  float r;
#include "dax64business.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in %xmm0 according to x64-ish ABI rules.
 */
sqInt callIA32DoubleReturn(SIGNATURE) {
  double (*f)(long rdi, long rsi, long rdx, long rcx, long r8, long r9,
              double xmm0, double xmm1, double xmm2, double xmm3,
              double xmm4, double xmm5, double xmm6, double xmm7);
  double r;
#include "dax64business.h"
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
 * rsp->retpc (thunkEntry)
 *
 * This function's roles are to use setjmp/longjmp to save the call point
 * and return to it, and to return any of the various values from the callback.
 *
 * To support x86-64, which when using the SysV ABI has 6 integer register arguments, and 8
 * floating-point register arguments, the function takes 16 arguments, the 6 register args
 * as longs, folowed by 8 floating-point arguments as doubles, followed by the thunkp and
 * stackp passed on the stack.  The register args get copied into a struct on the stack.
 * A pointer to the struct is then passed as an element of the VMCallbackContext.
 */

long
thunkEntry(long a0, long a1, long a2, long a3, long a4, long a5,
			double d0, double d1, double d2, double d3,
			double d4, double d5, double d6, double d7,
			void *thunkp, sqIntptr_t *stackp)
{
	VMCallbackContext vmcc;
	VMCallbackContext *previousCallbackContext;
	long flags, returnType;
	long intargs[6];
	double fpargs[8];

	intargs[0] = a0;
	intargs[1] = a1;
	intargs[2] = a2;
	intargs[3] = a3;
	intargs[4] = a4;
	intargs[5] = a5;

	fpargs[0] = d0;
	fpargs[1] = d1;
	fpargs[2] = d2;
	fpargs[3] = d3;
	fpargs[4] = d4;
	fpargs[5] = d5;
	fpargs[6] = d6;
	fpargs[7] = d7;


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

	case retword:
    case retword64:
        return vmcc.rvs.valword;

	case retdouble: {
		double valflt64 = vmcc.rvs.valflt64;
#if _MSC_VER
				_asm mov qword ptr valflt64, xmm0;
#elif __GNUC__
				__asm__("movq %0, %%xmm0" : : "m"(valflt64));
#else
# error need to load %xmm0 with vmcc.rvs.valflt64 on this compiler
#endif
				return 0;
	}

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
	long pagesize = getpagesize();

	/* This is equivalent to valloc(pagesize) but at least on some versions of
	 * SELinux valloc fails to yield an wexecutable page, whereas this mmap
	 * call works everywhere we've tested so far.  See
	 * http://lists.squeakfoundation.org/pipermail/vm-dev/2018-October/029102.html
	 */
	if (!(mem = mmap(0, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0)))
		return 0;

	// MAP_ANON should zero out the allocated page, but explicitly doing it shouldn't hurt
	memset(mem, 0, pagesize);
	*size = pagesize;
#endif
	return mem;
}
#endif /* x86_64|x64|__x86_64|__x86_64__ */
