/*
 *  ia32abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin.
 *  Written by Eliot Miranda 11/07.
 */

/* null if compiled on other than x86, to get around gnu make bugs or
 * misunderstandings on our part.
 */
#if i386|i486|i586|i686

#if defined(_MSC_VER) || defined(__MINGW32__)
# include "windows.h" /* for GetSystemInfo & VirtualAlloc */
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
#include <stdio.h> /* for fprintf(stderr,...) */

#include "sqMemoryAccess.h"
#include "vmCallback.h"
#include "sqAssert.h"
#include "sqVirtualMachine.h"
#include "ia32abi.h"

#if !defined(min)
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif 
struct VirtualMachine* interpreterProxy;

#ifdef _MSC_VER
# define alloca _alloca
#endif
#if __GNUC__
# define setsp(sp) asm volatile ("movl %0,%%esp" : : "m"(sp))
# define getsp() ({ void *sp; asm volatile ("movl %%esp,%0" : "=r"(sp) : ); sp;})
#endif
#if __APPLE__ && __MACH__ && __i386__
# define STACK_ALIGN_BYTES 16
#elif __linux__ && __i386__
# define STACK_ALIGN_BYTES 16
#elif defined(WIN32) && __SSE2__
/* using sse2 instructions requires 16-byte stack alignment but on win32 there's
 * no guarantee that libraries preserve alignment so compensate on callback.
 */
# define STACK_ALIGN_HACK 1
# define STACK_ALIGN_BYTES 16
#endif

#if !defined(setsp)
# define setsp(ignored) 0
#endif

#define moduloPOT(m,v) (((v)+(m)-1) & ~((m)-1))
#define alignModuloPOT(m,v) ((void *)moduloPOT(m,(unsigned long)(v)))

#define objIsAlien(anOop) (interpreterProxy->includesBehaviorThatOf(interpreterProxy->fetchClassOf(anOop), interpreterProxy->classAlien()))
#define objIsUnsafeAlien(anOop) (interpreterProxy->includesBehaviorThatOf(interpreterProxy->fetchClassOf(anOop), interpreterProxy->classUnsafeAlien()))

#define sizeField(alien) (*(long *)pointerForOop((sqInt)(alien) + BaseHeaderSize))
#define dataPtr(alien) pointerForOop((sqInt)(alien) + BaseHeaderSize + BytesPerOop)
#if 0 /* obsolete after adding pointer Aliens with size field == 0 */
# define isIndirectOrPointer(alien) (sizeField(alien) <= 0)
# define startOfData(alien) (isIndirectOrPointer(alien)		\
								? *(void **)dataPtr(alien)	\
								:  (void  *)dataPtr(alien))
#endif
#define isIndirect(alien) (sizeField(alien) < 0)
#define startOfParameterData(alien) (isIndirect(alien)	\
									? *(void **)dataPtr(alien)	\
									:  (void  *)dataPtr(alien))
#define isIndirectSize(size) ((size) < 0)
#define startOfDataWithSize(alien,size) (isIndirectSize(size)	\
								? *(void **)dataPtr(alien)		\
								:  (void  *)dataPtr(alien))

#define isSmallInt(oop) ((oop)&1)
#define intVal(oop) (((long)(oop))>>1)

/*
 * Call a foreign function that answers an integral result in %eax (and
 * possibly %edx) according to IA32-ish ABI rules.
 */
sqInt
callIA32IntegralReturn(SIGNATURE) {
#ifdef _MSC_VER
__int64 (*f)(), r;
#else
long long (*f)(), r;
#endif
#include "dabusiness.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in %f0 according to IA32-ish ABI rules.
 */
sqInt
callIA32FloatReturn(SIGNATURE) { float (*f)(), r;
#include "dabusiness.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in %f0 according to IA32-ish ABI rules.
 */
sqInt
callIA32DoubleReturn(SIGNATURE) { double (*f)(), r;
#include "dabusiness.h"
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

#define getRMCC(t) mostRecentCallbackContext
#define setRMCC(t) (mostRecentCallbackContext = (void *)(t))

/*
 * Entry-point for call-back thunks.  Args are thunk address and stack pointer,
 * where the stack pointer is pointing one word below the return address of the
 * thunk's callee, 4 bytes below the thunk's first argument.  The stack is:
 *		callback
 *		arguments
 *		retpc (thunk) <--\
 *		address of retpc-/        <--\
 *		address of address of ret pc-/
 *		thunkp
 * esp->retpc (thunkEntry)
 *
 * The stack pointer is pushed twice to keep the stack alignment to 16 bytes, a
 * requirement on platforms using SSE2 such as Mac OS X, and harmless elsewhere.
 *
 * This function's roles are to use setjmp/longjmp to save the call point
 * and return to it, to correct C stack pointer alignment if necessary (see
 * STACK_ALIGN_HACK), and to return any of the various values from the callback.
 *
 * Looking forward to support for x86-64, which typically has 6 register
 * arguments, the function would take 8 arguments, the 6 register args as
 * longs, followed by the thunkp and stackp passed on the stack.  The register
 * args would get copied into a struct on the stack. A pointer to the struct
 * is then passed as an element of the VMCallbackContext.
 */
long
thunkEntry(void *thunkp, sqIntptr_t *stackp)
{
	VMCallbackContext vmcc;
	VMCallbackContext *previousCallbackContext;
	int flags, returnType;

#if STACK_ALIGN_HACK
  { void *sp = getsp();
    int offset = (unsigned long)sp & (STACK_ALIGN_BYTES - 1);
	if (offset) {
# if _MSC_VER
		_asm sub esp, dword ptr offset;
# elif __GNUC__
		asm("sub %0,%%esp" : : "m"(offset));
# else
#  error need to subtract offset from esp
# endif
		sp = getsp();
		assert(!((unsigned long)sp & (STACK_ALIGN_BYTES - 1)));
	}
  }
#endif /* STACK_ALIGN_HACK */

	if ((flags = interpreterProxy->ownVM(0)) < 0) {
		fprintf(stderr,"Warning; callback failed to own the VM\n");
		return -1;
	}

	if (!(returnType = setjmp(vmcc.trampoline))) {
		previousCallbackContext = getRMCC();
		setRMCC(&vmcc);
		vmcc.thunkp = thunkp;
		vmcc.stackp = stackp + 2; /* skip address of retpc & retpc (thunk) */
		vmcc.intregargsp = 0;
		vmcc.floatregargsp = 0;
		interpreterProxy->sendInvokeCallbackContext(&vmcc);
		fprintf(stderr,"Warning; callback failed to invoke\n");
		setRMCC(previousCallbackContext);
		interpreterProxy->disownVM(flags);
		return -1;
	}
	setRMCC(previousCallbackContext);
	interpreterProxy->disownVM(flags);

	switch (returnType) {

	case retword:	return vmcc.rvs.valword;

	case retword64: {
		long vhigh = vmcc.rvs.valleint64.high;
#if _MSC_VER
				_asm mov edx, dword ptr vhigh;
#elif __GNUC__
				asm("mov %0,%%edx" : : "m"(vhigh));
#else
# error need to load edx with vmcc.rvs.valleint64.high on this compiler
#endif
				return vmcc.rvs.valleint64.low;
	}

	case retdouble: {
		double valflt64 = vmcc.rvs.valflt64;
#if _MSC_VER
				_asm fld qword ptr valflt64;
#elif __GNUC__
				asm("fldl %0" : : "m"(valflt64));
#else
# error need to load %f0 with vmcc.rvs.valflt64 on this compiler
#endif
				return 0;
	}

	case retstruct:	memcpy( (void *)(stackp[1]),
							vmcc.rvs.valstruct.addr,
							vmcc.rvs.valstruct.size);
					return stackp[1];
	}
	fprintf(stderr,"Warning; invalid callback return type\n");
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
#endif /* i386|i486|i586|i686 */
