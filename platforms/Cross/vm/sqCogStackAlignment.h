/****************************************************************************
 *   FILE:    sqCogUnixStackAlignment.h
 *   CONTENT: Answer & check stack alignment for current plaform
 *
 *   AUTHOR:   Eliot Miranda
 *   DATE:     February 2009
 */

#if __APPLE__ && __MACH__ && __i386__
# define STACK_ALIGN_BYTES 16
# define LEAF_CALL_STACK_ALIGN_BYTES 12
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
# else
#  error define code for your processor here
# endif
extern unsigned long (*ceGetSP)(); /* provided by Cogit */
# define STACK_ALIGN_MASK (STACK_ALIGN_BYTES-1)
# define assertCStackWellAligned() do {										\
	extern sqInt cFramePointerInUse;										\
	if (cFramePointerInUse)													\
		assert((getfp() & STACK_ALIGN_MASK) == STACK_FP_ALIGN_BYTES);		\
	assert((ceGetSP() & STACK_ALIGN_MASK) == LEAF_CALL_STACK_ALIGN_BYTES);	\
} while (0)
#else /* defined(STACK_ALIGN_BYTES) */
# define STACK_ALIGN_BYTES 4
# define assertCStackWellAligned() 0
#endif /* defined(STACK_ALIGN_BYTES) */
