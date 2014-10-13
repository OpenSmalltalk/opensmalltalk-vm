/****************************************************************************
*   PROJECT: Atomic operations for multi-threading.
*			 Atomic reads and writes of 64-bit values (e.g. for 64-bit clock).
*				get64(sqLong variable)
*				set64(sqLong variable, sqLong value)
*			 Atomic 32-bit increment (e.g. for signalSemaphoreWithIndex:).
*				sqAtomicAddConst(var,n)
*				sqCompareAndSwap(var,old,new)
*				sqCompareAndSwapRes(var,old,new,res)
*   FILE:    sqAtomicOps.h
*
*   AUTHOR:  Eliot Miranda
*   EMAIL:   eliot@teleplace.com
*
*****************************************************************************/

/* Atomic access to 64-bit values allows variables to be updated safely by
 * interrupts on 32-bit systems without using locks.  This is used e.g. by
 * the heartbeat as it updates the 64-bit microsecond clocks.
 *
 * Re LP32 ILP32 LP64 ILP64 & LLP64
 * These are convenient names for different C programming models. See e.g.
 * http://www.unix.org/version2/whatsnew/lp64_wp.html. LP32 et al are models in
 * which the basic word size is 32-bits and LP64 et al are models in which the
 * basic word size is 64-bits.  gcc defines these.  Other compilers may not.
 * Here we assume that if either LP32 or ILP32 are defined as 1 then special
 * effort is required to access a 64-bit datum atomically.
 *
 * Only some compilers define LP32 et al.  If not, and __LONG_MAX__ is defined
 * we can make a good guess that __LONG_MAX__ implies 32-bits or 64-bits.
 */

// tpr; Raspbian does not define ILP32 or LP32, therefore LP32 is #def'd below

#if defined(__LONG_MAX__) && !defined(LP32) && !defined(ILP32) \
       && !defined(LP64) && !defined(ILP64) && !defined(LLP64)
# if __LONG_MAX__ > 0xFFFFFFFF
#	define LP64 1
# else
#	define LP32 1
# endif
#endif

#if LP64 || ILP64 || LLP64
	/* On 64-bit systems 64-bit access is automatic by default. */
# define get64(variable) variable
# define set64(variable,value) (variable = value)

#elif LP32 || ILP32


# if TARGET_OS_IS_IPHONE
static inline void
AtomicSet(uint64_t *target, uint64_t new_value)
{
	while (true) {
		uint64_t old_value = *target;
		if (OSAtomicCompareAndSwap64Barrier(old_value, new_value, target))
			return;
	}
}

static inline uint64_t
AtomicGet(uint64_t *target)
{
	while (true) {
		int64 value = *target;
		if (OSAtomicCompareAndSwap64Barrier(value, value, target))
			return value;
	}
}
#	define get64(variable) AtomicGet(&(variable))
#	define set64(variable,value) AtomicSet(&(variable),value)

	/* Currently we provide definitions for x86 and GCC only.  But see below. */
# elif defined(__GNUC__) && (defined(i386) || defined(__i386) || defined(__i386__) || defined(_X86_))

/* atomic read & write of 64-bit values using SSE2 movq to/from sse register.
 * 64-bit reads & writes are only guaranteed to be atomic if aligned on a 64-bit
 * boundary.  Since 64-bit globals are so aligned a global access is atomic.
 */
#  if __SSE2__
/* atomic read & write of 64-bit values using sse instructions. */
#	define get64(variable) \
	({ long long result; \
		asm volatile ("movq %1, %%xmm7;	movq %%xmm7, %0"\
						: "=m" (result)					\
						: "m" (variable)				\
						: "memory", "%xmm7");			\
		result;})

#	define set64(variable,value) \
		asm volatile ("movq %1, %%xmm7;	movq %%xmm7, %0"\
						: "=m" (variable)				\
						: "m" (value)					\
						: "memory", "%xmm7")
#  else /* __SSE2__ */
/* atomic read & write of 64-bit values using the CMPXCHG8B instruction.
 * CMPXCHG8B m64 compares EDX:EAX with m64 and if equal loads ECX:EBX into m64.
 * If different it loads m64 into EDX:EAX.
 * Thanks to Frank http://www.exit.com/blog/archives/000361.html.
 *
 * Note that we could simply use movq which is guaranteed to provide atomic
 * reading or writing of 64-bit values aligned on a 64-bit boundary.  But we
 * can only depend on global variables being correctly aligned on systems
 * such as Mac OS X, which aligns the stack on a 128-bit boundary.
 */
#	include "sqAssert.h"

#	define lo32(x) (*(((unsigned long *)&(x))+0))
#	define hi32(x) (*(((unsigned long *)&(x))+1))

#	define get64(variable) \
	({ long long result; \
		assert((variable) != 0); \
		asm volatile (	"xorl %%eax, %%eax\n\t" \
						"xorl %%edx, %%edx\n\t" \
						"xorl %%ebx, %%ebx\n\t" \
						"xorl %%ecx, %%ecx\n\t" \
						"lock cmpxchg8b %2\n\t" \
						"movl %%eax, %0\n\t" \
						"movl %%edx, %1" \
							: "=m" (lo32(result)), "=m" (hi32(result)) \
							: "o" (variable) \
							: "memory", "eax", "ebx", "ecx", "edx", "cc"); \
		result;})

#	define set64(variable,value) \
		asm volatile (	"movl %0, %%eax\n\t" \
						"movl %1, %%edx\n\t" \
						"movl %2, %%ebx\n\t" \
						"movl %3, %%ecx\n\t" \
						"lock cmpxchg8b %0" \
							: "+m" (lo32(variable)), "+m" (hi32(variable)) \
							: "m" (lo32(value)), "m" (hi32(value)) \
							: "memory", "eax", "ebx", "ecx", "edx", "cc")
#  endif /* __SSE2__ */
# else /* TARGET_OS_IS_IPHONE elif x86 variants etc */

#if defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
/* tpr - this is code intended for the Raspberry Pi Raspbian OS 
 * We'll experimentally trust in our MMU to keep 64bit accesses atomic */
#define get64(var)  \
	(var)
#define set64(var,value) \
		(var) = (value)

#else
/* Dear implementor, you have choices.  For example consider defining get64 &
 * set64 thusly
 * #define get64(var)  read64(&(var))
 * #define set64(var,val) write64(&(var),val)
 * and get the JIT to generate read64 & write64 above atomic 64-bit read/write.
 */
#	error atomic access of 64-bit variables not yet defined for this platform
#endif
# endif

#else /* LP32 || ILP32 else LP64 || ILP64 || LLP64 */
# error shurly shome mishtake; too drunk to shpot the programming muddle. hic.
#endif




/* Atomic increment of 32-bit values allows a lock-free implementation of the
 * request side of signalSemaphoreWithIndex:
 */

	/* Currently we provide definitions for x86 and GCC only.  */
#if defined(__GNUC__) && (defined(i386) || defined(__i386) || defined(__i386__) || defined(_X86_))
#ifdef TARGET_OS_IS_IPHONE
#define sqAtomicAddConst(var,n) OSAtomicAdd32(n,&var)
#else
# define sqAtomicAddConst(var,n) \
	asm volatile ("lock addl %1, %0" : "=m" (var) : "i" (n), "m" (var))
#endif
#elif defined TARGET_OS_IS_IPHONE
#define sqAtomicAddConst(var,n) OSAtomicAdd32(n,&var)
#elif  defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
/* tpr - this is code intended for the Raspberry Pi Raspbian OS */
/* We'll experimentally use the gcc inbuilt functions detailed in
 * http://gcc.gnu.org/onlinedocs/gcc-4.1.2/gcc/Atomic-Builtins.html
 */
#define sqAtomicAddConst(var,n) \
	__sync_fetch_and_add((int *)&var, n)
#else
/* Dear implementor, you have choices.  Google atomic increment and you will
 * find a number of implementations for other architectures.
 */
#	error atomic increment of 32-bit variables not yet defined for this platfom
#endif




/* Atomic compare and swap of 32-bit values allows a lock-free implementation of
 * the request side of signalSemaphoreWithIndex: using tides to limit the range
 * of indices examined.
 *
 * sqCompareAndSwap(var,old,new) arranges atomically that if var's value is
 * equal to old, then var's is set to new.
 *
 * sqCompareAndSwapRes(var,old,new,res) arranges atomically that if var's value
 * is equal to old, then var's value is set to new, and that in any case, res
 * is set to the previous value of var.
 */

	/* Currently we provide definitions for x86 and GCC only.  */
#if defined(__GNUC__) && (defined(i386) || defined(__i386) || defined(__i386__) || defined(_X86_))

#ifdef TARGET_OS_IS_IPHONE
# define sqCompareAndSwap(var,old,new) OSAtomicCompareAndSwap32(old, new, &var) 
/* N.B.  This is not atomic in fetching var's old value :( */
# define sqCompareAndSwapRes(var,old,new,res) do { res = var; if (OSAtomicCompareAndSwap32(old, new, &var)) res = new; } while (0)
#else
# define sqCompareAndSwap(var,old,new) \
	asm volatile ("movl %1, %%eax; lock cmpxchg %2, %0" \
					: "=m"(var) \
					: "g"(old), "r"(new), "m"(var)\
					: "memory", "%eax")

# define sqCompareAndSwapRes(var,old,new,res) \
	asm volatile ("movl %2, %%eax; lock cmpxchg %3, %0; movl %%eax, %1" \
					: "=m"(var), "=g"(res) \
					: "g"(old), "r"(new), "m"(var) \
					: "memory", "%eax")
#endif
#elif defined TARGET_OS_IS_IPHONE
# define sqCompareAndSwap(var,old,new) OSAtomicCompareAndSwap32(old, new, &var) 
# define sqCompareAndSwapRes(var,old,new,res) res = var; OSAtomicCompareAndSwap32(old, new, &var) 

#elif  defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
/* tpr - this is code intended for the Raspberry Pi Raspbian OS */
/* We'll experimentally use the gcc inbuilt functions detailed in
 * http://gcc.gnu.org/onlinedocs/gcc-4.1.2/gcc/Atomic-Builtins.html */
# define sqCompareAndSwap(var,old,new) \
	__sync_bool_compare_and_swap(&(var), (old), (new))

# define sqCompareAndSwapRes(var,old,new,res) \
	(res = __sync_val_compare_and_swap(&(var), (old), (new)))

#else
/* Dear implementor, you have choices.  Google atomic increment and you will
 * find a number of implementations for other architectures.
 */
#	error atomic compare/swap of 32-bit variables not yet defined for this platfom
#endif
