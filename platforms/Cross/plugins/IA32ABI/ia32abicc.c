#if defined(__powerpc__) || defined(PPC) || defined(_POWER) || defined(_IBMR2) || defined(__ppc__)
#else
/*
 * Copyright 2008 Cadence Design Systems, Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
 */
/* 
 *  ia32abicc.c
 *
 * Support for Call-outs and Call-backs from the Plugin.
 *  Written by Eliot Miranda 11/07.
 * Changes by John M McIntosh 12/08.
 *
 */

#if defined(_MSC_VER) || defined(__MINGW32__)
# include "windows.h" /* for GetSystemInfo & VirtualAlloc */
extern int inIoProcessEvents;
# define noteEnterCallback() (++inIoProcessEvents)
# define noteExitCallback()  do { if (inIoProcessEvents) --inIoProcessEvents; } while (0)
# if DEBUG
DWORD vmThread = 0;
#  define EnsureHaveVMThreadID() do { \
						if (!vmThread) vmThread = GetCurrentThreadId(); \
						} while (0)
#  define CheckInVMThread() (vmThread == GetCurrentThreadId())
# endif /* DEBUG */
#elif __APPLE__ && __MACH__
# include <sys/mman.h> /* for mprotect */
# if OBJC_DEBUG /* define this to get debug info for struct objc_class et al */
#  include <objc/objc.h>
#  include <objc/objc-class.h>

struct objc_class *baz;

void setbaz(void *p) { baz = p; }
void *getbaz() { return baz; }
# endif
#else
# include <malloc.h> /* for valloc */
# include <sys/mman.h> /* for mprotect */
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "sqMemoryAccess.h"
#include "sqVirtualMachine.h"
#include "ia32abi.h"

#include <setjmp.h>

#if !defined(min)
# define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#if !defined(noteEnterCallback)
# define noteEnterCallback() 0
#endif
#if !defined(noteExitCallback)
# define noteExitCallback() 0
#endif
#if !defined(EnsureHaveVMThreadID)
# define EnsureHaveVMThreadID() 0
#endif
#if !defined(CheckInVMThread)
# define CheckInVMThread() 1
#endif

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif 
struct VirtualMachine* interpreterProxy;

#if defined(SQ_IMAGE32)
# define BytesPerOop    4
#elif defined(SQ_IMAGE64)
# define BytesPerOop    8
#else   
# error cannot determine image word size/object header size
#endif

#define BaseHeaderSize BytesPerOop
 
#ifdef _MSC_VER
# define alloca _alloca
#endif
#if __GNUC__
# define setsp(sp) asm volatile ("movl %0,%%esp" : : "memory"(sp))
# define getsp(sp) asm volatile ("movl %%esp,%0" : "=r"(sp) : )
#endif
#if __APPLE__ && __MACH__ && __i386__
# define STACK_ALIGN_BYTES 16
#endif

#if !defined(setsp)
# define setsp(ignored) 0
#endif

#define moduloPOT(m,v) ((v)+(m)-1 & ~((m)-1))
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

int figureOutFloatSize(int typeSignatureArray,int index) {
	int floatSize,objectSize;
	char *floatSizePointer;
	sqInt oops = interpreterProxy->stackValue(typeSignatureArray);
	objectSize = interpreterProxy->stSizeOf(oops);
	if (index >= objectSize) 
		return sizeof(double);
	floatSizePointer = interpreterProxy->firstIndexableField(oops);
	floatSize = floatSizePointer[index];
	return floatSize;
}
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
#include "dabusinessPostLogic.h"
}

/*
 * Call a foreign function that answers a single-precision floating-point
 * result in %f0 according to IA32-ish ABI rules.
 */
sqInt
callIA32FloatReturn(SIGNATURE) { float (*f)(), r;
#include "dabusiness.h"
#include "dabusinessPostLogic.h"
}

/*
 * Call a foreign function that answers a double-precision floating-point
 * result in %f0 according to IA32-ish ABI rules.
 */
sqInt
callIA32DoubleReturn(SIGNATURE) { double (*f)(), r;
#include "dabusiness.h"
#include "dabusinessPostLogic.h"
}

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
 * Pushing the stack pointer twice is done to keep the stack alignment to 16
 * bytes, a requirement on Mac OS X, and harmless elsewhere.
 *
 * This function's roles are to use setjmp/longjmp to save the call point
 * and return to it, and to return any of the various values from the callback.
 *
 * Looking forward to support for x86-64, which typically has 6 register
 * arguments, the function would take 8 arguments, the 6 register args as
 * longs, followed by the thunkp and stackp passed on the stack.  The register
 * args would get copied into a struct on the stack. A pointer to the struct
 * is then passed as the 3rd argument of sendInvokeCallbackStackRegistersJmpbuf
 */
long
thunkEntry(void *thunkp, long *stackp)
{
	jmp_buf trampoline;
	volatile CallBackReturnSpec *rs;

	if (sizeof(int) != sizeof(rs)) {
		perror("setjmp cannot return a pointer; reimplement!\n");
		exit(1);
	}
	if (!CheckInVMThread()) {
		printf("NOT IN VM THREAD!\n");
		perror("Not in VM thread!\n");
		exit(666);
	}

	noteEnterCallback();
	if (!(rs = (void *)setjmp(trampoline))) {
		interpreterProxy->
			sendInvokeCallbackStackRegistersJmpbuf(	(sqInt)thunkp,
													(sqInt)(stackp + 2),
													0,
													(sqInt)&trampoline);
		perror("Warning; callback failed to invoke\n");
		return 0;
	}
	noteExitCallback();

	switch (rs->type) {

	case retint32:	return rs->rvs.valint32;

	case retint64: {
		long vhigh = rs->rvs.valint64.high;
#if _MSC_VER
				_asm mov edx, dword ptr vhigh;
#elif __GNUC__
				asm("mov %0,%%edx" : : "m"(vhigh));
#else
# error need to load edx with rs->rvs.valint64.high on this compiler
#endif
				return rs->rvs.valint64.low;
	}

	case retdouble: {
		double valflt64 = rs->rvs.valflt64;
#if _MSC_VER
				_asm fld qword ptr valflt64;
#elif __GNUC__
				asm("fldl %0" : : "m"(valflt64));
#else
# error need to load %f0 with rs->rvs.valflt64 on this compiler
#endif
				return 0;
	}

	case retstruct:	memcpy( (void *)(stackp[1]),
						rs->rvs.valstruct.addr,
						rs->rvs.valstruct.size);
				return stackp[1];
	}
	perror("Warning; invalid callback return type\n");
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
 * page amongst thunks so there is no need to free these pages, sicne the image
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
#endif
