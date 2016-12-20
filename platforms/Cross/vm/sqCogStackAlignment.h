/****************************************************************************
 *   FILE:    sqCogUnixStackAlignment.h
 *   CONTENT: Answer & check stack alignment for current plaform
 *
 *   AUTHOR:   Eliot Miranda
 *   DATE:     February 2009
 *
 * Changes: eem Tue 28 Apr 2015 Add ARM32 support.
 *			eem Wed Jul 14 2010 make 16 bytes the default alignment for all x86.
 */
 
#if __i386__ || _M_IX86
# if __SSE2__ || (__APPLE__ && __MACH__) || __linux__ || _M_IX86_FP==2
/* 16-byte stack alignment on x86 is required for SSE instructions which
 * require 16-byte aligned addresses to access 64 or 128 bit values in memory.
 */
#	define STACK_ALIGN_BYTES 16
#	define STACK_FP_ALIGNMENT 8 /* aligned sp - retpc - saved fp */
# else
#	define STACK_ALIGN_BYTES 4
#	define STACK_FP_ALIGNMENT 0
# endif
#endif

#if defined(__arm__) || defined(__arm32__) || defined(ARM32)
/* 8-byte stack alignment on ARM32 is required for instructions which
 * require 8-byte aligned addresses to access doubles in memory.
 */
# define STACK_ALIGN_BYTES 8
# define STACK_FP_ALIGNMENT 4
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
#   define getfp() ({ register usqIntptr_t fp;					\
					  asm volatile ("movl %%ebp,%0" : "=r"(fp) : );	\
					  fp; })
#   define getsp() ({ register usqIntptr_t sp;					\
					  asm volatile ("movl %%esp,%0" : "=r"(sp) : );	\
					  sp; })
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
# elif __x86_64__
#  if __GNUC__ || __clang__
#   define getfp() ({ register usqIntptr_t fp;					\
					  asm volatile ("movq %%rbp,%0" : "=r"(fp) : );	\
					  fp; })
#   define getsp() ({ register usqIntptr_t sp;					\
					  asm volatile ("movq %%rsp,%0" : "=r"(sp) : );	\
					  sp; })
#  endif
# else /* !(__i386__ || __arm__ || __x86_64__) */
#  error define code for your processor here
# endif
# if !defined(getfp)
# define getfp() ceGetFP() /* provided by Cogit */
# endif
# if !defined(getsp)
# define getsp() ceGetSP() /* provided by Cogit */
# endif
# define STACK_ALIGN_MASK (STACK_ALIGN_BYTES-1)
#	define assertCStackWellAligned() do {									\
	extern sqInt cFramePointerInUse;										\
	if (cFramePointerInUse)													\
		assert((getfp() & STACK_ALIGN_MASK) == STACK_FP_ALIGNMENT);		\
	assert((getsp() & STACK_ALIGN_MASK) == 0);	\
} while (0)
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
