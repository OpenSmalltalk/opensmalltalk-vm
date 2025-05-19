/* sqMemoryAccess.h -- memory accessors (and associated type definitions)
 *
 * Authors: Ian Piumarta, Nicolas Cellier, David Lewis, & Eliot Miranda.
 * If you feel you should be included here, let us know.
 */

/* This file defines the core types for the VM, sqInt, usqInt et al, and
 * the memory access API for the Smalltalk heap.  Consequently this file
 * is the minimum required prerequisite for Smalltalk-related code.
 */

/* Systematic use of the macros defined in this file within the Interpreter,
 * ObjectMemory and plugins will permit all four combinations of 32/64-bit
 * image and 32/64-bit host to compile and run correctly.  (Code that uses
 * explicit casts and/or integer constants in arithmetic on object pointers
 * will invariably fail in at least one of the four possible combinations.)
 */

#ifndef __sqMemoryAccess_h
#define __sqMemoryAccess_h

#include "config.h"
#include "interp.h"

#define true	1
#define false	0
#define null	0  /* using "null" because nil is predefined in Think C */

#ifndef SIZEOF_LONG
#  if LLP64
#    define SIZEOF_LONG 4
#  else
#    define SIZEOF_LONG SIZEOF_VOID_P /* default is sizeof(long)==sizeof(void *) */
#  endif
#endif

#if (SQ_VI_BYTES_PER_WORD == 4)
# define SQ_IMAGE32 1
# define SQ_IMAGE64 0
#else
# define SQ_IMAGE64 1
# define SQ_IMAGE32 0
#endif

#if (SQ_IMAGE64 || SPURVM)
# define OBJECTS_64BIT_ALIGNED 1
# define OBJECTS_32BIT_ALIGNED 0
#else
# define OBJECTS_32BIT_ALIGNED 1
# define OBJECTS_64BIT_ALIGNED 0
#endif

#if (SIZEOF_VOID_P == 4)
# define SQ_HOST32 1
#elif (SIZEOF_VOID_P == 8)
# define SQ_HOST64 1
#else
# error host is neither 32- nor 64-bit?
#endif

/* sqInt is a signed integer with size adequate for holding an Object Oriented Pointer
 * (or immediate value).  That is 32bits in a 32bit image or 64bits in a 64bit image.
 * usqInt is the unsigned flavour. SQABS is a macro for the absolute value of a sqInt.
 *
 * We could use C99 int32_t and int64_t once retiring legacy compiler support this
 * time has not yet come.
 */
#if (SQ_IMAGE32 && (SIZEOF_LONG == 4)) || (SQ_HOST64 && (SIZEOF_LONG == 8))
  typedef long           sqInt;
  typedef unsigned long usqInt;
# define PRIdSQINT "ld"
# define PRIuSQINT "lu"
# define PRIxSQINT "lx"
# define PRIXSQINT "lX"
# define SQABS labs
#elif SQ_IMAGE32
  typedef int           sqInt;
  typedef unsigned int usqInt;
# define PRIdSQINT "d"
# define PRIuSQINT "u"
# define PRIxSQINT "x"
# define PRIXSQINT "X"
# define SQABS abs
#elif (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
#else
  typedef long long           sqInt;
  typedef unsigned long long usqInt;
# define PRIdSQINT "lld"
# define PRIuSQINT "llu"
# define PRIxSQINT "llx"
# define PRIXSQINT "llX"
# define SQABS llabs
#endif

/* sqLong is a signed integer with at least 64bits on both 32 and 64 bit platforms.
 * usqLong is the unsigned flavour. SQLABS is a macro for the absolute value of a sqLong
 */
#if !defined(sqLong)
#  if SIZEOF_LONG == 8
#     define sqLong long
#     define usqLong unsigned long
#     define SQLABS labs
#  elif _MSC_VER
#     define sqLong __int64
#     define usqLong unsigned __int64
#     define SQLABS llabs
#  else
#     define sqLong long long
#     define usqLong unsigned long long
#     define SQLABS llabs
#  endif
#endif /* !defined(sqLong) */

/* sqIntptr_t is a signed integer with enough bits to hold a pointer (a void *).
 * usqIntptr_t is the unsigned flavour.
 * this is essentially C99 intptr_t and uintptr_t but we support legacy compilers
 * the C99 printf formats macros are also defined with SQ prefix
 */
#if SIZEOF_LONG == SIZEOF_VOID_P
typedef long sqIntptr_t;
typedef unsigned long usqIntptr_t;
# define PRIdSQPTR "ld"
# define PRIuSQPTR "lu"
# define PRIxSQPTR "lx"
# define PRIXSQPTR "lX"
#else
typedef long long sqIntptr_t;
typedef unsigned long long usqIntptr_t;
# define PRIdSQPTR "lld"
# define PRIuSQPTR "llu"
# define PRIxSQPTR "llx"
# define PRIXSQPTR "llX"
#endif

#if SQ_HOST64 && SQ_IMAGE32
  extern char *sqMemoryBase;
# define sqMemoryBase sqMemoryBase
# define SQ_FAKE_MEMORY_OFFSET	16 // (1*1024*1024)	// nonzero to debug addr xlation
#endif

#if USE_INLINE_MEMORY_ACCESSORS
  // Use static inline functions when the compiler produces efficient code for small accessors.
  // These are preferred because static type checking will prevent inadvertent confusion of pointers and oops.

# if defined(sqMemoryBase)
  static inline char *pointerForOop(usqInt oop)			{ return sqMemoryBase + oop; }
  static inline sqInt oopForPointer(void *ptr)			{ return (sqInt)((char *)ptr - sqMemoryBase); }
# else
  static inline char *pointerForOop(usqInt oop)			{ return (char *)oop; }
  static inline sqInt oopForPointer(void *ptr)			{ return (sqInt)ptr; }
# endif

  static inline sqInt byteAt(void *ptr)					{ return *(unsigned char *)ptr; }
  static inline sqInt byteAtput(void *ptr, int val)		{ return *(unsigned char *)ptr = val; }
  static inline sqInt shortAt(void *ptr)				{ return *(short *)ptr; }
  static inline sqInt shortAtput(void *ptr, int val)	{ return *(short *)ptr = val; }
  static inline sqInt intAt(void *ptr)					{ return *(int *)ptr; }
  static inline sqInt intAtput(void *ptr, int val)		{ return *(int *)ptr = val; }
  static inline sqInt longAt(void *ptr)					{ return *(sqInt *)ptr; }
  static inline sqInt longAtput(void *ptr, sqInt val)	{ return *(sqInt *)ptr = val; }
  static inline sqInt oopAt(void *ptr)					{ return *(sqInt *)ptr; }
  static inline sqInt oopAtput(void *ptr, sqInt val)	{ return *(sqInt *)ptr = val; }
  static inline int   long32At(void *ptr)				{ return *(int *)ptr; }
  static inline int   long32Atput(void *ptr, int val)	{ return *(int *)ptr = val; }
  static inline sqLong long64At(void *ptr)				{ return *(sqLong *)ptr; }
  static inline sqLong long64Atput(void *ptr, sqLong v)	{ return *(sqLong *)ptr = v; }

  static inline float  singleFloatAt(void *ptr)				{ return *(float *)ptr; }
  static inline float  singleFloatAtput(void *ptr, float f)	{ return *(float *)ptr = f; }
  static inline double floatAt(void *ptr)					{ return *(double *)ptr; }
  static inline double floatAtput(void *ptr, double d)		{ return *(double *)ptr = d; }  

# if LowcodeVM
  static inline char *pointerAt(void *ptr)					{ return *(char **)ptr; }
  static inline char *pointerAtput(void *ptr, char *val)	{ return *(char **)ptr = val; }

  static inline signed char int8At(void *ptr)							{ return *(signed char *)ptr; }
  static inline signed char int8Atput(void *ptr, signed char val)		{ return *(signed char *)ptr = val; }
  static inline unsigned char uint8At(void *ptr)						{ return *(unsigned char *)ptr; }
  static inline unsigned char uint8Atput(void *ptr, unsigned char val)	{ return *(unsigned char *)ptr = val; }

  static inline short int16At(void *ptr)								{ return *(short *)ptr; }
  static inline short int16Atput(void *ptr, short val)					{ return *(short *)ptr = val; }
  static inline unsigned short uint16At(void *ptr)						{ return *(unsigned short *)ptr; }
  static inline unsigned short uint16Atput(void *ptr, unsigned short s)	{ return *(unsigned short *)ptr = s; }

  static inline int int32At(void *ptr)									{ return *(int *)ptr; }
  static inline int int32Atput(void *ptr, int val)						{ return *(int *)ptr = val; }
  static inline unsigned int uint32At(void *ptr)						{ return *(unsigned int *)ptr; }
  static inline unsigned int uint32Atput(void *ptr, unsigned int val)	{ return *(unsigned int *)ptr = val; }

  static inline sqLong int64At(void *ptr)					{ return *(sqLong *)ptr; }
  static inline sqLong int64Atput(void *ptr, sqLong val)	{ return *(sqLong *)ptr = val; }
  static inline usqLong uint64At(void *ptr)					{ return *(usqLong *)ptr; }
  static inline usqLong uint64Atput(void *ptr, usqLong val)	{ return *(usqLong *)ptr = val; }
# endif // LowcodeVM
#else // USE_INLINE_MEMORY_ACCESSORS
  // Use macros if and when static inline functions aren't efficient.
# if defined(sqMemoryBase)
#  define pointerForOop(oop)	((sqMemoryBase) + (usqInt)(oop))
#  define oopForPointer(ptr)	((sqInt)((char *)(ptr) - (sqMemoryBase)))
# else
#  define pointerForOop(oop)	((char *)(oop))
#  define oopForPointer(ptr)	((sqInt)(ptr))
# endif

# define byteAt(ptr)			((sqInt)*(unsigned char *)(ptr))
# define byteAtput(ptr,val)		((sqInt)(*(unsigned char *)(ptr) = (val)))
# define shortAt(ptr)			((sqInt)*(short *)(ptr))
# define shortAtput(ptr,val)	((sqInt)(*(short *)(ptr) = (val)))
# define intAt(ptr)				((sqInt)*(int *)(ptr))
# define intAtput(ptr,val)		((sqInt)(*(int *)(ptr) = (val)))
# define longAt(ptr)			(*(sqInt *)(ptr))
# define longAtput(ptr,val)		(*(sqInt *)(ptr) = (val))
# define long32At(ptr)			((sqInt)*(int *)(ptr))
# define long32Atput(ptr,val)	((sqInt)(*(int *)(ptr) = (val)))
# define long64At(ptr)			(*(sqLong *)(ptr))
# define long64Atput(ptr,val)	(*(sqLong *)(ptr) = (val))
# define oopAt(ptr)				(*(sqInt *)(ptr))
# define oopAtput(ptr,val)		(*(sqInt *)(ptr) = (val))

# define singleFloatAt(oop)			(*(float *)(oop))
# define singleFloatAtput(oop, f)	(*(float *)(oop) = (f))
# define floatAt(oop)				(*(double *)(oop))
# define floatAtput(oop, d)			(*(double *)(oop) = (d))

# if LowcodeVM
# define pointerAt(ptr)			(*(void **)(ptr))
# define pointerAtput(ptr, val)	(*(void **)(ptr) = (val))

# define int8At(ptr)			(*(signed char *)(ptr))
# define int8Atput(ptr, val)	(*(signed char *)(ptr) = (val))
# define uint8At(ptr)			(*(unsigned char *)(ptr))
# define uint8Atput(ptr, val)	(*(unsigned char *)(ptr) = (val))

# define int16At(ptr)			(*(signed short *)(ptr))
# define int16Atput(ptr, val)	(*(signed short *)(ptr) = (val))
# define uint16At(ptr)			(*(unsigned short *)(ptr))
# define uint16Atput(ptr, val)	(*(unsigned short *)(ptr) = (val))

# define int32At(ptr)			(*(signed int *)(ptr))
# define int32Atput(ptr, val)	(*(signed int *)(ptr) = (val))
# define uint32At(ptr)			(*(unsigned int *)(ptr))
# define uint32Atput(ptr, val)	(*(unsigned int *)(ptr) = (val))

# define int64At(ptr)			(*(sqLong *)(ptr))
# define int64Atput(ptr, val)	(*(sqLong *)(ptr) = (val))
# define uint64At(ptr)			(*(usqLong *)(ptr))
# define uint64Atput(ptr, val)	(*(usqLong *)(ptr) = (val))
# endif // LowcodeVM
#endif // USE_INLINE_MEMORY_ACCESSORS

static inline sqLong
asIEEE64BitWord(double val)
{
    /* Use an union here to not violate the strict aliasing rule. */
    union {
        double input;
        sqLong output;
    } data;
    data.input = val;
    return data.output;
}

static inline unsigned int
asIEEE32BitWord(float val)
{
    /* Use an union here to not violate the strict aliasing rule. */
    union {
        float input;
        unsigned int output;
    } data;
    data.input = val;
    return data.output;
}

/* platform-dependent float conversion macros.
 * Note: Second argument must be a variable name, not an expression!
 * Pre-Cog systems stored floats in Mac PowerPC big-endian format.
 * BigEndianFloats selects this behaviour for backwards-compatibility.
 * RISC systems typically insist on double-word alignment of double-words, but
 * the V3 heap is only word-aligned.
 */
#if BigEndianFloats && !VMBIGENDIAN
/* this is to allow strict aliasing assumption in the optimizer */
typedef union { double d; int i[sizeof(double) / sizeof(int)]; } _swapper;
/* word-based copy with swapping for non-PowerPC order */
# define storeFloatAtfrom(intPointerToFloat, doubleVar) do { \
		*((int *)(intPointerToFloat) + 0) = ((_swapper *)(&doubleVar))->i[1]; \
		*((int *)(intPointerToFloat) + 1) = ((_swapper *)(&doubleVar))->i[0]; \
	} while (0)
# define fetchFloatAtinto(intPointerToFloat, doubleVar) do { \
		((_swapper *)(&doubleVar))->i[1] = *((int *)(intPointerToFloat) + 0); \
		((_swapper *)(&doubleVar))->i[0] = *((int *)(intPointerToFloat) + 1); \
	} while (0)
#else
# define storeFloatAtfrom(intPointerToFloat, doubleVar) \
    memcpy((char *)intPointerToFloat,&doubleVar,sizeof(double))
# define fetchFloatAtinto(intPointerToFloat, doubleVar) \
    memcpy(&doubleVar,(char *)intPointerToFloat,sizeof(double))
#endif /* !(BigEndianFloats && !VMBIGENDIAN) */

#define storeSingleFloatAtfrom(intPointerToFloat, floatVar) \
        do {float __f = floatVar; memcpy((char *)intPointerToFloat,&__f,sizeof(float));} while(0)
#define fetchSingleFloatAtinto(intPointerToFloat, floatVar) \
        do {float __f; memcpy(&__f,(char *)intPointerToFloat,sizeof(float)); floatVar = __f;} while(0)

/* These accessors are for accelerating byte swapping
   whenever intrinsics or other fast functions are available */
/* Compatibility with non-clang compilers */
#ifndef __has_builtin
#  define __has_builtin(x) 0
#endif

/*  GCC and Clang recent versions provide intrinsic byte swaps via builtins */
#if (defined(__clang__) && __has_builtin(__builtin_bswap32) && __has_builtin(__builtin_bswap64)) \
  || (defined(__GNUC__ ) && \
  (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3)))
#  define SQ_SWAP_4_BYTES(x) __builtin_bswap32(x)
#  define SQ_SWAP_8_BYTES(x) __builtin_bswap64(x)
#elif defined(__linux__)
#  include <byteswap.h>
#  define SQ_SWAP_4_BYTES(x) bswap_32(x)
#  define SQ_SWAP_8_BYTES(x) bswap_64(x)
#elif defined(_MSC_VER)
#  include <stdlib.h>
#  define SQ_SWAP_4_BYTES(x) _byteswap_ulong(x)
#  define SQ_SWAP_8_BYTES(x) _byteswap_uint64(x)
#else
#  define SQ_SWAP_4_BYTES(x) \
	(((unsigned int)(x) << 24) | \
	(((unsigned int)(x) <<  8) & 0xff0000U) | \
	(((unsigned int)(x) >>  8) & 0xff00U) | \
	( (unsigned int)(x) >> 24))
#  define SQ_SWAP_8_BYTES(x) \
	(((unsigned long long)(x) << 56) | \
	(((unsigned long long)(x) << 40) & 0xff000000000000ULL) | \
	(((unsigned long long)(x) << 24) & 0xff0000000000ULL) | \
	(((unsigned long long)(x) << 8)  & 0xff00000000ULL) | \
	(((unsigned long long)(x) >> 8)  & 0xff000000ULL) | \
	(((unsigned long long)(x) >> 24) & 0xff0000ULL) | \
	(((unsigned long long)(x) >> 40) & 0xff00ULL) | \
	( (unsigned long long)(x) >> 56))
#endif

/* Since Large Integers are Bytes Oops allways stored as little endian,
   the following macros are handy to retrieve 4 or 8 byte limbs */
#if VMBIGENDIAN
#  define SQ_SWAP_4_BYTES_IF_BIGENDIAN(x) SQ_SWAP_4_BYTES(x)
#  define SQ_SWAP_8_BYTES_IF_BIGENDIAN(x) SQ_SWAP_8_BYTES(x)
#else
#  define SQ_SWAP_4_BYTES_IF_BIGENDIAN(x) (x)
#  define SQ_SWAP_8_BYTES_IF_BIGENDIAN(x) (x)
#endif

/* This doesn't belong here, but neither do 'self flag: ...'s belong in the
   image. We use a macro, not an inline function; we need no trace of flag.
 */
#define flag(foo) 0

/* heap debugging facilities in sqHeapMap.c */
extern void clearHeapMap(void);
extern int  heapMapAtWord(void *wordPointer);
extern void heapMapAtWordPut(void *wordPointer, int bit);

/* Platform-dependent API to allocate/manage object memory. */

#if SPURVM
/* Spur is an improved object representation/garbage collector/heap manager that
 * replaces the original BttF "V3" Memory Manager (so called because Spur came
 * after Squeak V3).  Spur offers considerable performance improvements but is
 * not backwards-compatible with V3, and requires different internal plumbing.
 * Unlike the V3 memory manager, Spur manages old space heap memory in segments,
 * and is able to release memory back to the OS when the heap shrinks.
 */

/* Allocate a region of memory of al least sz bytes, at or above minAddr.
 * If the attempt fails, answer null.  If the attempt succeeds, answer the
 * start of the region and assign its size through asp.
 */
extern void *sqAllocateMemorySegmentOfSizeAboveAllocatedSizeInto(usqInt sz, void *minAddr, usqInt *asp);
extern void sqDeallocateMemorySegmentAtOfSize(void *addr, sqInt sz);

#else /* SPURVM */

/* Note: The grow/shrink macros assume that the object memory can be extended
   continuously at its prior end. The garbage collector cannot deal with
   'holes' in the object memory so the support code needs to reserve the
   virtual maximum of pages that can be allocated beforehand. The amount of
   'extra' memory should describe the amount of memory that can be allocated
   from the OS (including swap space if the flag is set to true) and must not
   exceed the prior reserved memory.
   In other words: don't you dare to report more free space then you can
   actually allocate.
   The default implementation assumes a fixed size memory allocated at startup.
*/
# define sqAllocateMemory(minHeapSize, desiredHeapSize)  malloc(desiredHeapSize)
# define sqGrowMemoryBy(oldLimit, delta)			oldLimit
# define sqShrinkMemoryBy(oldLimit, delta)		oldLimit
# define sqMemoryExtraBytesLeft(includingSwap)	0
#endif /* SPURVM */

#if COGVM
/* Cog is a JIT extension for the VM. It still relies on the Interpreter (called
 * the CoInterpreter because it sits alongside the "Cogit") for primitives,
 * for executing methods the first time, and to fall back on in exceptional
 * circumstances.  COGVM implies STACKVM.  See STACKVM below.
 */
extern void sqMakeMemoryExecutableFromToCodeToDataDelta(usqInt, usqInt, sqInt*);
extern void *allocateJITMemory(usqInt *desiredSize);
#endif

/* Platform-dependent memory size adjustment macro. */

/* Note: This macro can be redefined to allows platforms with a
   fixed application memory partition (notably, the Macintosh)
   to reserve extra C heap memory for special applications that need
   it (e.g., for a 3D graphics library). Since most platforms can
   extend their application memory partition at run time if needed,
   this macro is defined as a noop here and redefined if necessary
   in sqPlatformSpecific.h.
*/

#define reserveExtraCHeapBytes(origHeapSize, bytesToReserve) origHeapSize

/* Pluggable primitives macros. */

/* Note: All pluggable primitives are defined as
	EXPORT(int) somePrimitive(void)
   All non-static variables in the VM and plugins are declared as
	VM_EXPORT type var
   If the platform requires special declaration modifiers, the EXPORT and
   VM_EXPORT macros can be redefined.
*/
#if !defined(EXPORT)
# define EXPORT(returnType) returnType
#endif
#if !defined(VM_EXPORT)
# define VM_EXPORT
#endif
#if !defined(VM_FUNCTION_EXPORT)
# define VM_FUNCTION_EXPORT(returnType) returnType
#endif

/* sqPlatformSpecific.h serves a couple of contradictory purposes. One is to
 * define platforms-specific implementations of facilities such as the EXPORT
 * macros.  Another is to define platform-specific implementations of support
 * functions, such as allocating memory, opening files, etc. This file needs
 * the EXPORT macros, but defines the types needed to define the support APIs.
 * So there is a circular dependency.  To solve ths sqPlatformSpecific.h only
 * defines the support APIs if __sqMemoryAccess_h is defined, and this file
 * arranges to include sqPlatformSpecific.h a second time to allow it to
 * declare the support funciton API.
 */
#if defined(_SQ_PLATFORM_SPECIFIC_H)
# undef _SQ_PLATFORM_SPECIFIC_H
# include "sqPlatformSpecific.h"
#endif
#endif /* __sqMemoryAccess_h */
