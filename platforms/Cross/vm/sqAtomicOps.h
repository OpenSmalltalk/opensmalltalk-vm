/****************************************************************************
*   PROJECT: Atomic operations for multi-threading.
*			 Atomic reads and writes of 64-bit values (e.g. for 64-bit clock).
*				get64(sqLong variable)
*				set64(sqLong variable, sqLong value)
*			 Atomic 32-bit increment (e.g. for signalSemaphoreWithIndex:).
*				sqAtomicAddConst(var,n)
*				sqCompareAndSwap(var,old,new)
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
 * Only some compilers define LP32 et al.  If not, try to infer from other macros.
 * (Also, same for LONG_MAX, the name defined by the Standard)
 */

#include <limits.h>

# if TARGET_OS_IS_IPHONE
#include <libkern/OSAtomic.h>  /* For Mac OS atomics ops for SDK 10.4 (Tiger) and above */
#endif

#if defined(_MSC_VER)
#include <windows.h> /* for atomic ops */
#endif	

#if    defined(LP32) || defined(ILP32) \
    || defined(LP64) || defined(ILP64) || defined(LLP64)

#  if LP64 || ILP64 || LLP64
#    define IS_64_BIT_ARCH 1
#  elif LP32 || ILP32
#    define IS_32_BIT_ARCH 1
#  else /* unknown platform */
#  endif

#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64) || defined(ARM64) || defined(__ARCH_ARM_ISA_A64)

#  define IS_64_BIT_ARCH 1

#elif defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__) || defined(__arm32__)

#  define IS_32_BIT_ARCH 1

#elif defined(__SIZEOF_POINTER__)

#  if __SIZEOF_POINTER__ == 8
#    define IS_64_BIT_ARCH 1
#  elif __SIZEOF_POINTER__ == 4
#    define IS_32_BIT_ARCH 1
#  else /* unknown platform */
#  endif

#elif defined(LONG_MAX) || defined(__LONG_MAX__)

#  if (defined(LONG_MAX) && LONG_MAX > 0xFFFFFFFFUL) \
   || (defined(__LONG_MAX__) &&  __LONG_MAX__ > 0xFFFFFFFFUL)
#    define IS_64_BIT_ARCH 1
#  else
#    define IS_32_BIT_ARCH 1
#  endif

#else /* unknown platform */
#endif

#if IS_64_BIT_ARCH
	/* On 64-bit systems 64-bit access is automatic by default. */
# define get64(variable) variable
# define set64(variable,value) (variable = value)

#elif IS_32_BIT_ARCH


# if TARGET_OS_IS_IPHONE
static inline void
AtomicSet(int64_t *target, int64_t new_value)
{
	while (true) {
		int64_t old_value = *target;
		if (OSAtomicCompareAndSwap64Barrier(old_value, new_value, target))
			return;
	}
}

static inline int64_t
AtomicGet(int64_t *target)
{
	while (true) {
		int64_t value = *target;
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

# elif defined(_MSC_VER) && (defined(_M_IX86) || defined(_X86_) || defined(i386))

# pragma message(" TODO: verify thoroughly")
/* see http://web.archive.org/web/20120411073941/http://www.niallryan.com/node/137 */

static __inline void
AtomicSet(__int64 *target, __int64 new_value)
{
   __asm
   {
      mov edi, target
      fild qword ptr [new_value]
      fistp qword ptr [edi]
   }
}

static __inline __int64
AtomicGet(__int64 *target)
{
   __asm
   {
      mov edi, target
      xor eax, eax
      xor edx, edx
      xor ebx, ebx
      xor ecx, ecx
      lock cmpxchg8b [edi]
   }
}
#	define get64(variable) AtomicGet(&((__int64)variable))
#	define set64(variable,value) AtomicSet(&((__int64)variable), (__int64)value)

# else /* TARGET_OS_IS_IPHONE elif x86 variants etc */

#if defined(__arm__) && (defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_7A__))
/* tpr - this is code intended for the Raspberry Pi Raspbian OS 
 * We'll experimentally trust in our MMU to keep 64bit accesses atomic */
# define get64(variable) variable
# define set64(variable,value) (variable = value)

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

#else /* neither IS_64_BIT_ARCH nor IS_32_BIT_ARCH */
# error Could not infer if architecture is 32 or 64 bits. Please modify sqAtomicOps.h inference rules.
#endif

#if defined(__GNUC__)
# define GCC_HAS_BUILTIN_SYNC \
			(__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
# define GCC_HAS_BUILTIN_ATOMIC \
			(__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 7))
#endif

/* Atomic increment of 16 or 32-bit variables allows a lock-free implementation
 * of the request side of signalSemaphoreWithIndex:. If the platform provides
 * the operation on 16-bit variables, define ATOMICADD16 as 1.
 */

#undef ATOMICADD16

#if TARGET_OS_IS_IPHONE
# define sqAtomicAddConst(var,n) assert(sizeof(var) == 4), OSAtomicAdd32(n,&(var))

#elif defined(__GNUC__) || defined(__clang__)
/* N.B. I know you want to use the intrinsics; they're pretty; they're official;
 * they're portable.  But they only apply to int, long and long long sizes.
 * Since we want to use 16-bit variables for signal requests and responses in
 * sqExternalSemaphores.c we use the assembler constructs.  Please /don't/
 * change this unless you understand the use of ATOMICADD16 and you test that
 * the replacement works.
 */
# if defined(i386) || defined(__i386) || defined(__i386__) || defined(_X86_)
#	define ATOMICADD16 1
#	define sqAtomicAddConst(var,n) do {\
	if (sizeof(var) == sizeof(char)) \
		asm volatile ("lock addb %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	else if (sizeof(var) == sizeof(short)) \
		asm volatile ("lock addw %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	else \
		asm volatile ("lock addl %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	} while (0)
# elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__)
#	define ATOMICADD16 1
#	define sqAtomicAddConst(var,n) do {\
	if (sizeof(var) == sizeof(char)) \
		asm volatile ("lock addb %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	else if (sizeof(var) == sizeof(short)) \
		asm volatile ("lock addw %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	else if (sizeof(var) == sizeof(int)) \
		asm volatile ("lock addl %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	else \
		asm volatile ("lock addq %1, %0" : "=m" (var) : "i" (n), "m" (var)); \
	} while (0)
# elif GCC_HAS_BUILTIN_SYNC || defined(__clang__)
#	define sqAtomicAddConst(var,n) __sync_fetch_and_add((sqInt *)&(var), n)
# endif
#elif defined(_MSC_VER)
#	define sqAtomicAddConst(var,n) do {\
	if (sizeof(var) == sizeof(int)) \
		InterlockedAdd(&var,n); \
	else if (sizeof(var) == 8) \
		InterlockedAdd64(&var,n); \
	else \
		error("no interlocked add for this variable size"); \
	} while (0)
#endif

#if !defined(sqAtomicAddConst)
/* Dear implementor, you have choices.  Google atomic increment and you will
 * find a number of alternative implementations.
 */
#	error atomic increment of variables not yet defined for this platform
#endif

/* Atomic compare and swap of sqInt variables allows a lock-free implementation
 * of the request side of signalSemaphoreWithIndex: using tides to limit the
 * range of indices examined.
 *
 * sqCompareAndSwap(var,old,new) arranges atomically that if var's value is
 * equal to old, then var's value is set to new, and answers true iff the swap
 * was made.
 */

#if TARGET_OS_IS_IPHONE
# define sqCompareAndSwap(var,old,new) \
	(sizeof(var) == 8 \
		? OSAtomicCompareAndSwap64(old, new, &var) \
		: OSAtomicCompareAndSwap32(old, new, &var))

#elif defined(__GNUC__) || defined(__clang__)
# if GCC_HAS_BUILTIN_SYNC || defined(__clang__)
#	define sqCompareAndSwap(var,old,new) \
	__sync_bool_compare_and_swap(&(var), old, new)

# elif defined(i386) || defined(__i386) || defined(__i386__) || defined(_X86_) \
    || defined(x86_64) || defined(__x86_64) || defined(__x86_64__)
	/* support for gcc 3.x, clang; 32-bit only */
	/* N.B.  One cannot test the result of this expression.  If you need that
	 * you'll have to wrap the code in a function and return the result.  This
			sete %%al;movzbl %%al,%%eax
	 * can be used to set al based on the condition code & extend it to 32-bits.
	 */
#	define sqCompareAndSwap(var,old,new) do { \
	assert(sizeof(var) == 4); \
	asm volatile ("movl %1, %%eax; lock cmpxchg %2, %0"\
						: "=m"(var) \
						: "g"(old), "r"(new), "m"(var) \
						: "memory", "%eax"); \
	} while (0)
# endif

#elif defined(_MSC_VER)
#	define sqCompareAndSwap(var,old,new) \
	InterlockedCompareExchange(&(var), new, old)
#else
/* Dear implementor, you have choices.  Google atomic compare and swap and you
 * will find a number of alternative implementations.
 */
#	error atomic compare/swap of 32-bit variables not yet defined for this platfom
#endif
