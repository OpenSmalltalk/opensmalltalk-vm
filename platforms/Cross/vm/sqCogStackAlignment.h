/********************************************************************************
 *   FILE:    sqCogUnixStackAlignment.h
 *   CONTENT: Answer & check stack alignment for current plaform. Provide
 *			  getReturnAddress which is part of ceInvokeInterpret, the fly-weight
 *			  setjmp/longjmp alternative that enters interpret from machine code.
 *			  Provide setsp which may required to correct the result of alloca in
 *			  SqueakFFIPrims when marshalling a call involving stacked arguments.
 *
 *   AUTHOR:   Eliot Miranda
 *   DATE:     February 2009
 *
 * Changes: eem Sep 2024 add assertStackPointersWellAligned; use assertfnl
 *			eem Sep 2020 move getReturnAddress here from sq.h
 *          eem Jan 2020 add support for ARMv8
 *          eem Apr 2015 Add ARM32 support
 *			eem Jul 2010 make 16 bytes the default alignment for all x86 (SSE2)
 */
 
/* getReturnAddress optionally defined here rather than in sqPlatformSpecific.h
 * to reduce duplication. The GCC intrinics are provided by other compilers too.
 */
#if COGVM && !defined(getReturnAddress)
# if _MSC_VER
#	define getReturnAddress() _ReturnAddress()
#	include <intrin.h>
#	pragma intrinsic(_ReturnAddress)
# elif defined(__GNUC__) /* gcc, clang, icc etc */
#	define getReturnAddress() __builtin_extract_return_addr(__builtin_return_address(0))
# else
#	error "Cog requires getReturnAddress to be defined for the current platform."
# endif
#endif

/* Support for stack alignment checking, used to ensure that when C is invoked
 * from machine code, the stack alignment meets the ABI's constraints.  If the
 * stack is not correctly aligned bad things happen, especially involving the
 * use of high-performance multi-media instructions, vector arithmetic etc.
 */
#if __i386__ || _M_IX86
# if __SSE2__ || (__APPLE__ && __MACH__) || __linux__ || _M_IX86_FP==2
/* 16 byte stack alignment on x86 is required for SSE instructions which
 * require 16 byte aligned addresses to access 64 or 128 bit values in memory.
 */
#	define STACK_ALIGN_BYTES 16
#	define STACK_FP_ALIGNMENT 8 /* aligned sp - retpc - saved fp */
# else
#	define STACK_ALIGN_BYTES 4
#	define STACK_FP_ALIGNMENT 0
# endif
# if _MSC_VER
#	define STACK_SP_ALIGNMENT 4
# endif
#endif

#if defined(__arm64__) || defined(__aarch64__) || defined(ARM64)
/* 16 byte stack alignment on ARM64 is required always. (SP mod 16) == 0 */
# define STACK_ALIGN_BYTES 16
# define STACK_FP_ALIGNMENT 0
#elif defined(__arm__) || defined(__arm32__) || defined(ARM32)
/* 8 byte stack alignment on ARM32 is required for instructions which
 * require 8 byte aligned addresses to access doubles in memory.
 */
# define STACK_ALIGN_BYTES 8
# define STACK_FP_ALIGNMENT 4
#elif defined(__riscv64__) || defined(__rv64g__) || defined(__rv64gc__)
#	define STACK_ALIGN_BYTES 16
#	define STACK_FP_ALIGNMENT 0
#endif

#if defined(x86_64) || defined(__amd64) || defined(__x86_64) || defined(__amd64__) || defined(__x86_64__) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
/* From the System V ABI:
 * 3.2.2 The Stack Frame
 * ...	The end of the input argument area shall be aligned on a 16 (32, if
 * __m256 is passed on stack) byte boundary. In other words, the value
 * (%rsp + 8) is always a multiple of 16 (32) when control is transferred to
 * the function entry point.
 * However,
 * https://developer.apple.com/library/mac/documentation/DeveloperTools/
 * Conceptual/LowLevelABI/140-x86-64_Function_Calling_Conventions/x86_64.html
 * claims
 * "The OS X x86-64 function calling conventions are the same as the function
 * calling conventions described in System V Application Binary Interface AMD64
 * Architecture Processor Supplement, found at
 * http://people.freebsd.org/~obrien/amd64-elf-abi.pdf. See that document for
 * details."
 * and that document states:
 * "The end of the input argument area shall be aligned on a 16 byte boundary.
 * In other words, the value (%rsp ? 8) is always a multiple of 16 when control
 * is transferred to the function entry point. The stack pointer, %rsp, always
 * points to the end of the latest allocated stack frame."
 */
# if __APPLE__ && __MACH__ && 0/* i.e. the __m256 regime */
#	define STACK_ALIGN_BYTES 32
#	define STACK_FP_ALIGNMENT 16 /* aligned sp - retpc - saved fp */
# else
#	define STACK_ALIGN_BYTES 16
#	define STACK_FP_ALIGNMENT 0 /* aligned sp - retpc - saved fp */
# endif
#endif

#if defined(STACK_ALIGN_BYTES)
# if defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__)
#  if __GNUC__ || __clang__
#   define getfp() ({ register usqIntptr_t fp;						\
					  asm volatile ("movl %%ebp,%0" : "=r"(fp) : );	\
					  fp; })
#   define getsp() ({ register usqIntptr_t sp;						\
					  asm volatile ("movl %%esp,%0" : "=r"(sp) : );	\
					  sp; })
#  endif
# elif defined(__arm64__) || defined(__aarch64__) || defined(ARM64)
	/* https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html#Extended-Asm
	 * http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.den0024a/index.html
	 */
#  if __GNUC__
#   define getfp() ({ usqIntptr_t fpval;							\
					  __asm volatile ("mov %0, fp" : "=r"(fpval) );	\
					  fpval; })
#   define getsp() ({ usqIntptr_t spval;							\
					  __asm volatile ("mov %0, sp" : "=r"(spval) );	\
					  spval; })

#	define setsp(spval) __asm volatile ("mov sp, %0"  : : "r"(spval))

#  endif
# elif defined(__arm__) || defined(__arm32__) || defined(ARM32)
	/* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0041c/Cegbidie.html
	 * ARM DUI 0041C Page 9-7
	 */
#  if __GNUC__
#   define getfp() ({ usqIntptr_t fp;								\
					 asm volatile ("mov %0, %%fp" : "=r"(fp) : );	\
					  fp; })
#   define getsp() ({ usqIntptr_t sp;								\
					  asm volatile ("mov %0, %%sp" : "=r"(sp) : );	\
					  sp; })
#  endif
# elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
#  if __GNUC__ || __clang__
#	define getfp() ({ register usqIntptr_t fp;						\
					  asm volatile ("movq %%rbp,%0" : "=r"(fp) : );	\
					  fp; })
#	define getsp() ({ register usqIntptr_t sp;						\
					  asm volatile ("movq %%rsp,%0" : "=r"(sp) : );	\
					  sp; })
#  else /* MSVC for example: use ceGetFP ceGetSP */
#  endif
#elif defined(__riscv64__) || defined(__rv64g__) || defined(__rv64gc__)
#  if __GNUC__ || __clang__
#	define setsp(spval) asm volatile ("addi sp, %0, 0 " : : "r"(spval) : )
#	define setfp(fpval) asm volatile ("addi fp, %0, 0 " : : "r"(fpval) : )
#	define getsp() asm volatile ("addi a0, sp, 0 " )
#	define getfp() asm volatile ("addi a0, fp, 0 " )
#  endif
# else /* !(__i386__ || __arm__ || __x86_64__) */
#  error define code for your processor here
# endif

#else /* defined(STACK_ALIGN_BYTES) */
#  if defined(powerpc) || defined(__powerpc__) || defined(_POWER) || defined(__POWERPC__) || defined(__PPC__)
#    define STACK_ALIGN_BYTES 16
#  elif defined(__sparc64__) || defined(__sparcv9__) || defined(__sparc_v9__) /* must precede 32-bit sparc defs */
#    define STACK_ALIGN_BYTES 16
#  elif defined(sparc) || defined(__sparc__) || defined(__sparclite__)
#    define STACK_ALIGN_BYTES 8
#  else
#    define STACK_ALIGN_BYTES sizeof(void *)
#  endif
#  define assertCStackWellAligned() 0
#endif /* defined(STACK_ALIGN_BYTES) */

#if !defined(getfp)
# define getfp() ceGetFP() /* provided by Cogit */
#endif
#if !defined(getsp)
# define getsp() ceGetSP() /* provided by Cogit */
#endif
#define STACK_ALIGN_MASK (STACK_ALIGN_BYTES-1)
#if !defined(STACK_SP_ALIGNMENT)
#	define STACK_SP_ALIGNMENT 0
#endif

#if !defined(assertStackPointersWellAligned)
# if defined(NDEBUG) // compatible with Mac OS X (FreeBSD) /usr/include/assert.h
#	  define assertStackPointersWellAligned(fpa,spa,fn,ln) 0
	// N.B. macro arguments assigned to locals to avoid expanding the getsp/getfp
	// macros above in the assert messages. Different names needed for debugger.
# elif defined(cFramePointerInUse)
#	if cFramePointerInUse
#	  define assertStackPointersWellAligned(fpa,spa,fn,ln) do {			\
		usqInt spv = (usqInt)(spa); usqInt fpv = (usqInt)(fpa);			\
		assertfnl((fpv & STACK_ALIGN_MASK) == STACK_FP_ALIGNMENT,fn,ln);\
		assertfnl((spv & STACK_ALIGN_MASK) == STACK_SP_ALIGNMENT,fn,ln);\
	  } while (0)
#	else
#	  define assertStackPointersWellAligned(fpa,spa,fn,ln) do { 		\
		usqInt spv = (usqInt)(spa);										\
		assertfnl((spv & STACK_ALIGN_MASK) == STACK_SP_ALIGNMENT,fn,ln);\
	  } while (0)
#	endif
# else
#	define assertStackPointersWellAligned(fpa,spa,fn,ln) do {				\
		extern sqInt cFramePointerInUse;									\
		usqInt spv = (usqInt)(spa); usqInt fpv = (usqInt)(fpa);				\
		if (cFramePointerInUse)												\
			assertfnl((fpv & STACK_ALIGN_MASK) == STACK_FP_ALIGNMENT,fn,ln);\
		assertfnl((spv & STACK_ALIGN_MASK) == STACK_SP_ALIGNMENT,fn,ln);	\
	  } while (0)
# endif
#endif

#if !defined(assertCStackWellAligned)
# define assertCStackWellAligned() \
	assertStackPointersWellAligned(getfp(),getsp(),__func__,__LINE__)
#endif
#if !defined(assertSavedCStackPointersWellAligned)
# define assertSavedCStackPointersWellAligned() \
	assertStackPointersWellAligned(CFramePointer,CStackPointer,__func__,__LINE__)
#endif
