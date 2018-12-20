/* sqMemoryAccess.h -- memory accessors (and associated type definitions)
 *
 * Author: Ian.Piumarta@squeakland.org
 *
 * Last edited: 2013-10-14 12:23:39 by eliot on McStalker
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

/* sqInt is a signed integer with size adequate for holding an Object Oriented Pointer (or immediate value)
  - that is 32bits long on a 32bits image or 64bits long on a 64bits image
  we could use C99 int32_t and int64_t once retiring legacy compiler support this time has not yet come
  usqInt is the unsigned flavour
  SQABS is a macro for taking absolute value of an sqInt */
#if SQ_IMAGE32
  typedef int		sqInt;
  typedef unsigned int	usqInt;
#define PRIdSQINT "d"
#define PRIuSQINT "u"
#define PRIxSQINT "x"
#define PRIXSQINT "X"
# define SQABS abs
#elif SQ_HOST64 && (SIZEOF_LONG == 8)
  typedef long		sqInt;
  typedef unsigned long	usqInt;
#define PRIdSQINT "ld"
#define PRIuSQINT "lu"
#define PRIxSQINT "lx"
#define PRIXSQINT "lX"
# define SQABS labs
#elif (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
#else
  typedef long long		sqInt;
  typedef unsigned long long	usqInt;
#define PRIdSQINT "lld"
#define PRIuSQINT "llu"
#define PRIxSQINT "llx"
#define PRIXSQINT "llX"
# define SQABS llabs
#endif

/* sqLong is a signed integer with at least 64bits on both 32 and 64 bits images
   usqLong is the unsigned flavour
   SQLABS is a macro for taking absolute value of a sqLong */
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

/* sqIntptr_t is a signed integer with enough bits to hold a pointer
   usqIntptr_t is the unsigned flavour
   this is essentially C99 intptr_t and uintptr_t but we support legacy compilers
   the C99 printf formats macros are also defined with SQ prefix */
#if SIZEOF_LONG == SIZEOF_VOID_P
typedef long sqIntptr_t;
typedef unsigned long usqIntptr_t;
#define PRIdSQPTR "ld"
#define PRIuSQPTR "lu"
#define PRIxSQPTR "lx"
#define PRIXSQPTR "lX"
#else
typedef long long sqIntptr_t;
typedef unsigned long long usqIntptr_t;
#define PRIdSQPTR "lld"
#define PRIuSQPTR "llu"
#define PRIxSQPTR "llx"
#define PRIXSQPTR "llX"
#endif

#if SQ_HOST64 && SQ_IMAGE32
  extern char *sqMemoryBase;
# define SQ_FAKE_MEMORY_OFFSET	16 // (1*1024*1024)	/* nonzero to debug addr xlation */
#else
# define sqMemoryBase 0
#endif

#ifdef USE_INLINE_MEMORY_ACCESSORS
  /* Use static inline functions when the compiler produces efficient code for small accessors.
     These are preferred because static type checking will prevent inadvertent confusion of pointers and oops. */
  static inline sqInt byteAtPointer(char *ptr)			{ return (sqInt)(*((unsigned char *)ptr)); }
  static inline sqInt byteAtPointerput(char *ptr, int val)	{ return (sqInt)(*((unsigned char *)ptr)= (unsigned char)val); }
  static inline sqInt shortAtPointer(char *ptr)			{ return (sqInt)(*((short *)ptr)); }
  static inline sqInt shortAtPointerput(char *ptr, int val)	{ return (sqInt)(*((short *)ptr)= (short)val); }
  static inline sqInt intAtPointer(char *ptr)			{ return (sqInt)(*((int *)ptr)); }
  static inline sqInt intAtPointerput(char *ptr, int val)	{ return (sqInt)(*((int *)ptr)= val); }
  static inline sqInt longAtPointer(char *ptr)			{ return *(sqInt *)ptr; }
  static inline sqInt longAtPointerput(char *ptr, sqInt val)	{ return *(sqInt *)ptr= val; }
  static inline sqLong long64AtPointer(char *ptr)			{ return *(sqLong *)ptr; }
  static inline sqLong long64AtPointerput(char *ptr, sqLong val)	{ return *(sqLong *)ptr= val; }
  static inline float singleFloatAtPointer(char *ptr)			{ return *(float *)ptr; }
  static inline float singleFloatAtPointerput(char *ptr, float val)	{ return *(float *)ptr= val; }
  static inline double floatAtPointer(char *ptr)			{ return *(double *)ptr; }
  static inline double floatAtPointerput(char *ptr, double val)	{ return *(double *)ptr= val; }  
  static inline sqInt oopAtPointer(char *ptr)			{ return *(sqInt *)ptr; }
  static inline sqInt oopAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*(sqInt *)ptr= val); }
# if defined(sqMemoryBase) && !sqMemoryBase
  static inline char *pointerForOop(usqInt oop)			{ return (char *)oop; }
  static inline sqInt oopForPointer(void *ptr)			{ return (sqInt)ptr; }
# else
  static inline char *pointerForOop(usqInt oop)			{ return sqMemoryBase + oop; }
  static inline sqInt oopForPointer(void *ptr)			{ return (sqInt)(ptr - sqMemoryBase); }
# endif
  static inline sqInt byteAt(sqInt oop)				{ return byteAtPointer(pointerForOop(oop)); }
  static inline sqInt byteAtput(sqInt oop, int val)		{ return byteAtPointerput(pointerForOop(oop), val); }
  static inline sqInt shortAt(sqInt oop)			{ return shortAtPointer(pointerForOop(oop)); }
  static inline sqInt shortAtput(sqInt oop, int val)		{ return shortAtPointerput(pointerForOop(oop), val); }
  static inline sqInt intAt(sqInt oop)				{ return intAtPointer(pointerForOop(oop)); }
  static inline sqInt intAtput(sqInt oop, int val)		{ return intAtPointerput(pointerForOop(oop), val); }
  static inline sqInt longAt(sqInt oop)				{ return longAtPointer(pointerForOop(oop)); }
  static inline sqInt longAtput(sqInt oop, sqInt val)		{ return longAtPointerput(pointerForOop(oop), val); }
  static inline sqLong long64At(sqInt oop)				{ return long64AtPointer(pointerForOop(oop)); }
  static inline sqLong long64Atput(sqInt oop, sqLong val)		{ return long64AtPointerput(pointerForOop(oop), val); }
  static inline sqInt oopAt(sqInt oop)				{ return oopAtPointer(pointerForOop(oop)); }
  static inline sqInt oopAtput(sqInt oop, sqInt val)		{ return oopAtPointerput(pointerForOop(oop), val); }

  static inline char* pointerAtPointer(char *ptr)			{ return *(char **)ptr; }
  static inline char* pointerAtPointerput(char *ptr, char* val)	{ return *(char **)ptr = val; }

  static inline signed char int8AtPointer(char *ptr)			            { return (*((signed char *)ptr)); }
  static inline signed char int8AtPointerput(char *ptr, signed char val)	{ return (*((signed char *)ptr)= val); }
  static inline unsigned char uint8AtPointer(char *ptr)			            { return (*((unsigned char *)ptr)); }
  static inline unsigned char uint8AtPointerput(char *ptr, unsigned char val)	{ return (*((unsigned char *)ptr)= val); }

  static inline short int16AtPointer(char *ptr)			                    { return (*((short *)ptr)); }
  static inline short int16AtPointerput(char *ptr, short val)	            { return (*((short *)ptr)= val); }
  static inline unsigned short uint16AtPointer(char *ptr)			                    { return (*((unsigned short *)ptr)); }
  static inline unsigned short uint16AtPointerput(char *ptr, unsigned short val)	    { return (*((unsigned short *)ptr)= val); }

  static inline int int32AtPointer(char *ptr)			    { return (*((int *)ptr)); }
  static inline int int32AtPointerput(char *ptr, int val)	{ return (*((int *)ptr)= val); }
  static inline unsigned int uint32AtPointer(char *ptr)			    { return (*((unsigned int *)ptr)); }
  static inline unsigned int uint32AtPointerput(char *ptr, unsigned int val)	{ return (*((unsigned int *)ptr)= val); }

  static inline sqLong int64AtPointer(char *ptr)			    { return (*((sqLong *)ptr)); }
  static inline sqLong int64AtPointerput(char *ptr, int val)	{ return (*((sqLong *)ptr)= val); }
  static inline usqLong uint64AtPointer(char *ptr)			    { return (*((usqLong *)ptr)); }
  static inline usqLong uint64AtPointerput(char *ptr, usqLong val)	{ return (*((usqLong *)ptr)= val); }

  static inline sqLong asIEEE64BitWord(double val) {return *((sqLong*)&val); }
  static inline unsigned int asIEEE32BitWord(float val) {return *((unsigned int*)&val); }
#else /* USE_INLINE_MEMORY_ACCESSORS */
  /* Use macros when static inline functions aren't efficient. */
# define byteAtPointer(ptr)			((sqInt)(*((unsigned char *)(ptr))))
# define byteAtPointerput(ptr,val)	((sqInt)(*((unsigned char *)(ptr))= (unsigned char)(val)))
# define shortAtPointer(ptr)		((sqInt)(*((short *)(ptr))))
# define shortAtPointerput(ptr,val)	((sqInt)(*((short *)(ptr))= (short)(val)))
# define intAtPointer(ptr)			((sqInt)(*((int *)(ptr))))
# define intAtPointerput(ptr,val)	((sqInt)(*((int *)(ptr))= (int)(val)))
# define longAtPointer(ptr)			(*(sqInt *)(ptr))
# define longAtPointerput(ptr,val)	(*(sqInt *)(ptr)= (sqInt)(val))
# define long64AtPointer(ptr)			(*(sqLong *)(ptr))
# define long64AtPointerput(ptr,val)	(*(sqLong *)(ptr)= (sqLong)(val))
# define singleFloatAtPointer(ptr)		(*(float*)(ptr))
# define singleFloatAtPointerput(ptr, val)		(*(float*)(ptr) = val)
# define floatAtPointer(ptr)		        (*(double*)(ptr))
# define floatAtPointerput(ptr, val)		(*(double*)(ptr) = val)
# define pointerAtPointer(ptr)		        (*(char**)(ptr))
# define pointerAtPointerput(ptr, val)		(*(char**)(ptr) = val)
# define oopAtPointer(ptr)			(*(sqInt *)(ptr))
# define oopAtPointerput(ptr,val)	(*(sqInt *)(ptr)= (sqInt)(val))
# if defined(sqMemoryBase) && !sqMemoryBase
#  define pointerForOop(oop)		((char *)(oop))
#  define oopForPointer(ptr)		((sqInt)(ptr))
#  define atPointerArg(oop)			oop
# else
#  define pointerForOop(oop)		((char *)(sqMemoryBase + ((usqInt)(oop))))
#  define oopForPointer(ptr)		((sqInt)(((char *)(ptr)) - (sqMemoryBase)))
#  define atPointerArg(oop)			sqMemoryBase + (usqInt)(oop)
# endif
# define byteAt(oop)				byteAtPointer(atPointerArg(oop))
# define byteAtput(oop,val)			byteAtPointerput(atPointerArg(oop), val)
# define shortAt(oop)				shortAtPointer(atPointerArg(oop))
# define shortAtput(oop,val)		shortAtPointerput(atPointerArg(oop), val)
# define longAt(oop)				longAtPointer(atPointerArg(oop))
# define longAtput(oop,val)			longAtPointerput(atPointerArg(oop), val)
# define long64At(oop)				long64AtPointer(atPointerArg(oop))
# define long64Atput(oop,val)		long64AtPointerput(atPointerArg(oop), val)
# define intAt(oop)					intAtPointer(atPointerArg(oop))
# define intAtput(oop,val)			intAtPointerput(atPointerArg(oop), val)
# define oopAt(oop)					oopAtPointer(atPointerArg(oop))
# define oopAtput(oop,val)			oopAtPointerput(atPointerArg(oop), val)

# define int8AtPointer(ptr)          (*(signed char*)(ptr))
# define int8AtPointerput(ptr, val)  (*(signed char*)(ptr) = val)
# define uint8AtPointer(ptr)          (*(unsigned char*)(ptr))
# define uint8AtPointerput(ptr, val)  (*(unsigned char*)(ptr) = val)

# define int16AtPointer(ptr)          (*(signed short*)(ptr))
# define int16AtPointerput(ptr, val)  (*(signed short*)(ptr) = val)
# define uint16AtPointer(ptr)          (*(unsigned short*)(ptr))
# define uint16AtPointerput(ptr, val)  (*(unsigned short*)(ptr) = val)

# define int32AtPointer(ptr)          (*(signed int*)(ptr))
# define int32AtPointerput(ptr, val)  (*(signed int*)(ptr) = val)
# define uint32AtPointer(ptr)          (*(unsigned int*)(ptr))
# define uint32AtPointerput(ptr, val)  (*(unsigned int*)(ptr) = val)

# define int64AtPointer(ptr)          (*(sqLong*)(ptr))
# define int64AtPointerput(ptr, val)  (*(sqLong*)(ptr) = val)
# define uint64AtPointer(ptr)          (*(usqLong*)(ptr))
# define uint64AtPointerput(ptr, val)  (*(usqLong*)(ptr) = val)

# define asIEEE64BitWord(val) (*((sqLong*)&val))
# define asIEEE32BitWord(val) (*((unsigned int*)&val))
#endif /* USE_INLINE_MEMORY_ACCESSORS */

#define long32At	intAt
#define long32Atput	intAtput

/* platform-dependent float conversion macros.
 * Note: Second argument must be a variable name, not an expression!
 * Pre-Cog systems stored floats in Mac PowerPC big-endian format.
 * BigEndianFloats selects this behaviour for backwards-compatibility.
 * RISC systems typically insist on double-word alignment of double-words, but
 * the heap is only word-aligned.  OBJECTS_32BIT_ALIGNED selects word access.
 */
#if BigEndianFloats && !VMBIGENDIAN
/* this is to allow strict aliasing assumption in the optimizer */
typedef union { double d; int i[sizeof(double) / sizeof(int)]; } _swapper;
/* word-based copy with swapping for non-PowerPC order */
# define storeFloatAtPointerfrom(intPointerToFloat, doubleVar) do { \
		*((int *)(intPointerToFloat) + 0) = ((_swapper *)(&doubleVar))->i[1]; \
		*((int *)(intPointerToFloat) + 1) = ((_swapper *)(&doubleVar))->i[0]; \
	} while (0)
# define fetchFloatAtPointerinto(intPointerToFloat, doubleVar) do { \
		((_swapper *)(&doubleVar))->i[1] = *((int *)(intPointerToFloat) + 0); \
		((_swapper *)(&doubleVar))->i[0] = *((int *)(intPointerToFloat) + 1); \
	} while (0)
# else
# define storeFloatAtPointerfrom(intPointerToFloat, doubleVar) \
    memcpy((char *)intPointerToFloat,&doubleVar,sizeof(double));
# define fetchFloatAtPointerinto(intPointerToFloat, doubleVar) \
    memcpy(&doubleVar,(char *)intPointerToFloat,sizeof(double));
#endif /* !(BigEndianFloats && !VMBIGENDIAN) && !OBJECTS_32BIT_ALIGNED */

# define storeSingleFloatAtPointerfrom(intPointerToFloat, floatVar) \
        do {float __f=floatVar; memcpy((char *)intPointerToFloat,&__f,sizeof(float));} while(0)
# define fetchSingleFloatAtPointerinto(intPointerToFloat, floatVar) \
        do {float __f; memcpy(&__f,(char *)intPointerToFloat,sizeof(float)); floatVar=__f;} while(0)

#define storeFloatAtfrom(i, doubleVar)	storeFloatAtPointerfrom(pointerForOop(i), doubleVar)
#define fetchFloatAtinto(i, doubleVar)	fetchFloatAtPointerinto(pointerForOop(i), doubleVar)
#define storeSingleFloatAtfrom(i, floatVar)	storeSingleFloatAtPointerfrom(pointerForOop(i), floatVar)
#define fetchSingleFloatAtinto(i, floatVar)	fetchSingleFloatAtPointerinto(pointerForOop(i), floatVar)

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

#endif /* __sqMemoryAccess_h */
