/* sqMemoryAccess.h -- memory accessors (and associated type definitions)
 * 
 *   Copyright (C) 2004-2005 by Ian Piumarta
 *   
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

/* Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2005-03-22 14:53:47 by piumarta on kim.local
 */

/* Systematic use of the macros defined in this file within the
 * Interpreter, ObjectMemory and plugins will permit all four
 * combinations of 32/64-bit image and 32/64-bit host to compile and
 * run correctly.  (Code that uses explicit casts and/or integer
 * constants in arithmetic on object pointers will invariably fail in
 * at least one of the four possible combinations.)
 */

#ifndef __sqMemoryAccess_h
#define __sqMemoryAccess_h

#if defined(HAVE_INTERP_H)
# include "interp.h"
  typedef void *sqModule;
  typedef void *sqFunction;
#else
# define SQ_VI_BYTES_PER_WORD 4		/* build a 32-bit VM */
  typedef int sqModule;
  typedef int sqFunction;
#endif

#include "config.h"

#if (SQ_VI_BYTES_PER_WORD == 4)
# define SQ_IMAGE32 1
#else
# define SQ_IMAGE64 1
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
#else
# if (SIZEOF_LONG_LONG != 8)
#   error long long integers are not 64-bits wide?
# endif 
  typedef long long		sqInt;
  typedef unsigned long long	usqInt;
#endif

#if defined(SQ_HOST64) && defined(SQ_IMAGE32)
  extern char *sqMemoryBase;
# define SQ_FAKE_MEMORY_OFFSET	16 // (1*1024*1024)	/* nonzero to debug addr xlation */
#else
# define sqMemoryBase		((char *)0)
#endif

static inline sqInt byteAtPointer(char *ptr)			{ return (sqInt)(*((unsigned char *)ptr)); }
static inline sqInt byteAtPointerput(char *ptr, int val)	{ return (sqInt)(*((unsigned char *)ptr)= (unsigned char)val); }
static inline sqInt shortAtPointer(char *ptr)			{ return (sqInt)(*((short *)ptr)); }
static inline sqInt shortAtPointerput(char *ptr, int val)	{ return (sqInt)(*((short *)ptr)= (short)val); }
static inline sqInt intAtPointer(char *ptr)			{ return (sqInt)(*((unsigned int *)ptr)); }
static inline sqInt intAtPointerput(char *ptr, int val)		{ return (sqInt)(*((unsigned int *)ptr)= (int)val); }
static inline sqInt longAtPointer(char *ptr)			{ return (sqInt)(*((sqInt *)ptr)); }
static inline sqInt longAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*((sqInt *)ptr)= (sqInt)val); }
static inline sqInt oopAtPointer(char *ptr)			{ return (sqInt)(*((sqInt *)ptr)); }
static inline sqInt oopAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*((sqInt *)ptr)= (sqInt)val); }

static inline char *pointerForOop(sqInt oop)			{ return sqMemoryBase + oop; }
static inline sqInt oopForPointer(char *ptr)			{ return (sqInt)(ptr - sqMemoryBase); }

static inline sqInt byteAt(sqInt oop)				{ return byteAtPointer(pointerForOop(oop)); }
static inline sqInt byteAtput(sqInt oop, int val)		{ return byteAtPointerput(pointerForOop(oop), val); }
static inline sqInt shortAt(sqInt oop)				{ return shortAtPointer(pointerForOop(oop)); }
static inline sqInt shortAtput(sqInt oop, int val)		{ return shortAtPointerput(pointerForOop(oop), val); }
static inline sqInt intAt(sqInt oop)				{ return intAtPointer(pointerForOop(oop)); }
static inline sqInt intAtput(sqInt oop, int val)		{ return intAtPointerput(pointerForOop(oop), val); }
static inline sqInt longAt(sqInt oop)				{ return longAtPointer(pointerForOop(oop)); }
static inline sqInt longAtput(sqInt oop, sqInt val)		{ return longAtPointerput(pointerForOop(oop), val); }
static inline sqInt oopAt(sqInt oop)				{ return oopAtPointer(pointerForOop(oop)); }
static inline sqInt oopAtput(sqInt oop, sqInt val)		{ return oopAtPointerput(pointerForOop(oop), val); }

#define long32At	intAt
#define long32Atput	intAtput

#if defined(HAVE_INTERP_H)

/* platform-dependent float conversion macros */
/* Note: Second argument must be a variable name, not an expression! */
/* Note: Floats in image are always in PowerPC word order; change
   these macros to swap words if necessary. This costs no extra and
   obviates sometimes having to word-swap floats when reading an image.
*/
#if defined(DOUBLE_WORD_ALIGNMENT) || defined(DOUBLE_WORD_ORDER)
/* this is to allow strict aliasing assumption in the optimizer */
typedef union { double d; int i[sizeof(double) / sizeof(int)]; } _swapper;
# ifdef DOUBLE_WORD_ORDER
/* word-based copy with swapping for non-PowerPC order */
#   define storeFloatAtPointerfrom(intPointerToFloat, floatVarName) \
	*((int *)(intPointerToFloat) + 0) = ((_swapper *)(&floatVarName))->i[1]; \
	*((int *)(intPointerToFloat) + 1) = ((_swapper *)(&floatVarName))->i[0];
#   define fetchFloatAtPointerinto(intPointerToFloat, floatVarName) \
	((_swapper *)(&floatVarName))->i[1] = *((int *)(intPointerToFloat) + 0); \
	((_swapper *)(&floatVarName))->i[0] = *((int *)(intPointerToFloat) + 1);
# else /*!DOUBLE_WORD_ORDER*/
/* word-based copy for machines with alignment restrictions */
#   define storeFloatAtPointerfrom(intPointerToFloat, floatVarName) \
	*((int *)(intPointerToFloat) + 0) = ((_swapper *)(&floatVarName))->i[0]; \
	*((int *)(intPointerToFloat) + 1) = ((_swapper *)(&floatVarName))->i[1];
#   define fetchFloatAtPointerinto(intPointerToFloat, floatVarName) \
	((_swapper *)(&floatVarName))->i[0] = *((int *)(intPointerToFloat) + 0); \
	((_swapper *)(&floatVarName))->i[1] = *((int *)(intPointerToFloat) + 1);
# endif /*!DOUBLE_WORD_ORDER*/
#else /*!(DOUBLE_WORD_ORDER||DOUBLE_WORD_ALIGNMENT)*/
/* for machines that allow doubles to be on any word boundary */
# define storeFloatAtPointerfrom(i, floatVarName) \
	*((double *) (i)) = (floatVarName);
# define fetchFloatAtPointerinto(i, floatVarName) \
	(floatVarName) = *((double *) (i));
#endif

#define storeFloatAtfrom(i, floatVarName)	storeFloatAtPointerfrom(pointerForOop(i), floatVarName)
#define fetchFloatAtinto(i, floatVarName)	fetchFloatAtPointerinto(pointerForOop(i), floatVarName)

#endif


/* This doesn't belong here, but neither do 'self flag: ...'s belong in the image. */

static void inline flag(char *ignored) {}


#endif /* __sqMemoryAccess_h */
