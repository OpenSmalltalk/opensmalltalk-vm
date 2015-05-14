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
 
#if __i386__ && (__SSE2__ || __APPLE__ && __MACH__ || __linux__)
/* 16-byte stack alignment on x86 is required for SSE instructions which
 * insist on aligned addresses for accessing 64 or 128 bit values in memory.
 */
# define STACK_ALIGN_BYTES 16
# define LEAF_CALL_STACK_ALIGN_BYTES 12
# define STACK_FP_ALIGN_BYTES 8
#endif

#if defined(__arm__) || defined(__arm32__) || defined(ARM32)
/* 8-byte stack alignment on ARM32 is required for instructions
 * which access doubles and insist on 8-byte alignment.
 */
# define STACK_ALIGN_BYTES 8
# define STACK_FP_ALIGN_BYTES 8
#endif

#if defined(STACK_ALIGN_BYTES)
# if defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__)
#  if __GNUC__
#   define getfp() ({ register unsigned long fp;					\
					  asm volatile ("movl %%ebp,%0" : "=r"(fp) : );	\
					  fp; })
#  else
extern unsigned long getfp();
#  endif
# elif defined(__arm__) || defined(__arm32__) || defined(ARM32)
	/* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0041c/Cegbidie.html
	 * ARM DUI 0041C Page 9-7
	 */
#  if __GNUC__
/* # define getsp() ({ void *sp; asm volatile ("mov %0, %%sp" : "=r"(sp) : ); sp;}) */

#   define getfp() ({ unsigned long fp;					\
					  asm volatile ("mov %0, %%fp" : "=r"(fp) : );	\
					  fp; })
#  else
extern unsigned long getfp();
#  endif
# else
#  error define code for your processor here
# endif
extern unsigned long (*ceGetSP)(); /* provided by Cogit */
# define STACK_ALIGN_MASK (STACK_ALIGN_BYTES-1)
# if defined(LEAF_CALL_STACK_ALIGN_BYTES)
	/* On CISCs, calling cGetSP will push ret pc and change algnment */
#	define assertCStackWellAligned() do {									\
	extern sqInt cFramePointerInUse;										\
	if (cFramePointerInUse)													\
		assert((getfp() & STACK_ALIGN_MASK) == STACK_FP_ALIGN_BYTES);		\
	assert((ceGetSP() & STACK_ALIGN_MASK) == LEAF_CALL_STACK_ALIGN_BYTES);	\
} while (0)
# else
	/* on RISCs, LinkReg implies stack ptr unchanged when doing cGetSP */
#	define assertCStackWellAligned() do {									\
	extern sqInt cFramePointerInUse;										\
	if (cFramePointerInUse)													\
		assert((getfp() & STACK_ALIGN_MASK) == STACK_FP_ALIGN_BYTES);		\
	assert((ceGetSP() & STACK_ALIGN_MASK) == 0);	\
} while (0)
# endif
#else /* defined(STACK_ALIGN_BYTES) */
# define STACK_ALIGN_BYTES 4
# define assertCStackWellAligned() 0
#endif /* defined(STACK_ALIGN_BYTES) */
