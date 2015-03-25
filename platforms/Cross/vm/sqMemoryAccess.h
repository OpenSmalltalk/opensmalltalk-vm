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

#if (SQ_VI_BYTES_PER_WORD == 4)
# define SQ_IMAGE32 1
#else
# define SQ_IMAGE64 1
#endif

#if (SQ_IMAGE64 || SPURVM)
# define OBJECTS_32BIT_ALIGNED 0
#else
# define OBJECTS_32BIT_ALIGNED 1
#endif

#if (SIZEOF_VOID_P == 4)
# define SQ_HOST32 1
#elif (SIZEOF_VOID_P == 8)
# define SQ_HOST64 1
#else
# error host is neither 32- nor 64-bit?
#endif

#if defined(SQ_IMAGE32)
  typedef int		sqInt;
  typedef unsigned int	usqInt;
#elif defined(SQ_HOST64)
  typedef long		sqInt;
  typedef unsigned long	usqInt;
#elif (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
#else
  typedef long long		sqInt;
  typedef unsigned long long	usqInt;
#endif

#if !defined(sqLong)
#  if SIZEOF_VOID_P == 8
#     define sqLong long
#     define usqLong unsigned long
#  elif _MSC_VER
#     define sqLong __int64
#     define usqLong unsigned __int64
#  else
#     define sqLong long long
#     define usqLong unsigned long long
#  endif
#endif /* !defined(sqLong) */

#if defined(SQ_HOST64) && defined(SQ_IMAGE32)
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
  static inline sqInt intAtPointer(char *ptr)			{ return (sqInt)(*((unsigned int *)ptr)); }
  static inline sqInt intAtPointerput(char *ptr, int val)	{ return (sqInt)(*((unsigned int *)ptr)= val); }
  static inline sqInt longAtPointer(char *ptr)			{ return *(sqInt *)ptr; }
  static inline sqInt longAtPointerput(char *ptr, sqInt val)	{ return *(sqInt *)ptr= val; }
  static inline sqLong long64AtPointer(char *ptr)			{ return *(sqLong *)ptr; }
  static inline sqLong long64AtPointerput(char *ptr, sqLong val)	{ return *(sqLong *)ptr= val; }
  static inline sqInt oopAtPointer(char *ptr)			{ return *(sqInt *)ptr; }
  static inline sqInt oopAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*(sqInt *)ptr= val); }
# if defined(sqMemoryBase) && !sqMemoryBase
  static inline char *pointerForOop(usqInt oop)			{ return (char *)oop; }
  static inline sqInt oopForPointer(char *ptr)			{ return (sqInt)ptr; }
# else
  static inline char *pointerForOop(usqInt oop)			{ return sqMemoryBase + oop; }
  static inline sqInt oopForPointer(char *ptr)			{ return (sqInt)(ptr - sqMemoryBase); }
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
# elif defined(OBJECTS_32BIT_ALIGNED)
/* this is to allow strict aliasing assumption in the optimizer */
typedef union { double d; int i[sizeof(double) / sizeof(int)]; } _aligner;
/* word-based copy for machines with alignment restrictions */
# define storeFloatAtPointerfrom(intPointerToFloat, doubleVar) do { \
	*((int *)(intPointerToFloat) + 0) = ((_aligner *)(&doubleVar))->i[0]; \
	*((int *)(intPointerToFloat) + 1) = ((_aligner *)(&doubleVar))->i[1]; \
  } while (0)
# define fetchFloatAtPointerinto(intPointerToFloat, doubleVar) do { \
	((_aligner *)(&doubleVar))->i[0] = *((int *)(intPointerToFloat) + 0); \
	((_aligner *)(&doubleVar))->i[1] = *((int *)(intPointerToFloat) + 1); \
  } while (0)
#else /* !(BigEndianFloats && !VMBIGENDIAN) && !OBJECTS_32BIT_ALIGNED */
/* for machines that allow doubles to be on any word boundary */
# define storeFloatAtPointerfrom(i, doubleVar) (*((double *) (i)) = (doubleVar))
# define fetchFloatAtPointerinto(i, doubleVar) ((doubleVar) = *((double *) (i)))
#endif /* !(BigEndianFloats && !VMBIGENDIAN) && !OBJECTS_32BIT_ALIGNED */

#define storeFloatAtfrom(i, doubleVar)	storeFloatAtPointerfrom(pointerForOop(i), doubleVar)
#define fetchFloatAtinto(i, doubleVar)	fetchFloatAtPointerinto(pointerForOop(i), doubleVar)
# define storeSingleFloatAtPointerfrom(i, floatVar) (*((float *) (i)) = (float)(floatVar))
# define fetchSingleFloatAtPointerinto(i, floatVar) ((floatVar) = *((float *) (i)))
#define storeSingleFloatAtfrom(i, floatVar)	storeSingleFloatAtPointerfrom(pointerForOop(i), floatVar)
#define fetchSingleFloatAtinto(i, floatVar)	fetchSingleFloatAtPointerinto(pointerForOop(i), floatVar)


/* This doesn't belong here, but neither do 'self flag: ...'s belong in the
   image. We use a macro, not an inline function; we need no trace of flag.
 */
#define flag(foo) 0

/* heap debugging facilities in sqHeapMap.c */
extern void clearHeapMap(void);
extern int  heapMapAtWord(void *wordPointer);
extern void heapMapAtWordPut(void *wordPointer, int bit);

#endif /* __sqMemoryAccess_h */
