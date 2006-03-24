#if __BIG_ENDIAN__

// THIS IS BROKEN FOR CROQUET






/* ppc-darwin.c -- FFI support for PowerPC on Mach-O (Darwin)
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2004-04-03 02:59:34 by piumarta on emilia.local
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
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
 *
 * Notes:
 *
 *  This is a complete rewrite of the version for MacPPC.  (The latter
 *  is hopelessly broken when passing long longs or structs containing
 *  an element of alignment less strict than int.)
 *
 * Bugs:
 * 
 *   Because of the way strings are handled, this implementation is
 *   neither reentrant nor thread safe.
 *
 * References:
 * 
 *   Mach-O Runtime Architecture, Apple Computer Inc., July 2002.
 */

#include "sq.h"
#include "sqFFI.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef LONGLONG
# define LONGLONG long long
#endif

#if 0
# define dprintf(ARGS)	printf ARGS; fflush(stdout)
#else
# define dprintf(ARGS)
#endif

extern struct VirtualMachine *interpreterProxy;

#if defined(FFI_TEST)
  static int primitiveFail(void) { puts("primitive fail"); exit(1); return 0; }
#else
# define primitiveFail() interpreterProxy->primitiveFail();
#endif

#define GPR_MAX	   8
#define FPR_MAX	  13
#define ARG_MAX	 512

static char	*strings[ARG_MAX];
static int	 stringCount= 0;
static int giLocker;

#if 0
static char	 structs[ARG_MAX * sizeof(int)];
static int	 structCount= 0;
#endif

/* the following avoids an awful lot of _very_ inefficient junk in the asm */

static struct
{
  int	   _gprCount;		//  0
  int	   _fprCount;		//  4
  int	   _stackIndex;		//  8
  int	  *_structReturnValue;	// 12	(everything below is 8-byte aligned)
  LONGLONG _longReturnValue;	// 16
  double   _floatReturnValue;	// 24
  int	   _gprs[GPR_MAX];	// 32
  double   _fprs[FPR_MAX];	// 32 + 4*GPR_MAX
  int	   _stack[ARG_MAX];	// 32 + 4*GPR_MAX + 8*FPR_MAX
} global;

#define gprCount		global._gprCount
#define fprCount		global._fprCount
#define stackIndex		global._stackIndex
#define structReturnValue	global._structReturnValue
#define longReturnValue		global._longReturnValue
#define floatReturnValue	global._floatReturnValue
#define gprs			global._gprs
#define fprs			global._fprs
#define stack			global._stack


extern int ffiCallAddressOf(void *addr, void *globals);


int ffiInitialize(void)
{
  dprintf(("ffiInitialize\n"));
  stackIndex= gprCount= fprCount= 0;
#if 0
  structCount= 0;
#endif
  floatReturnValue= 0.0;
  return 1;
}


int ffiSupportsCallingConvention(int callType)
{
  return (callType == FFICallTypeCDecl)
    ||   (callType == FFICallTypeApi);
}


int ffiAlloc(int byteSize)
{
  int ptr= (int)malloc(byteSize);
  dprintf(("ffiAlloc(%d) => %08x\n", byteSize, ptr));
  return ptr;
}


int ffiFree(int ptr)
{
  dprintf(("ffiFree(%08x)\n", ptr));
  if (ptr) free((void *)ptr);
  return 1;
}


#define checkStack()				\
  if (stackIndex >= ARG_MAX)			\
    return primitiveFail()

#define checkGPR()					\
  if ((gprCount >= GPR_MAX) && (stackIndex >= ARG_MAX))	\
    return primitiveFail()

#define qalignStack()	stackIndex += (stackIndex & 1)

#define pushGPR(value)				\
  checkGPR();					\
  if (gprCount < GPR_MAX)			\
    gprs[gprCount++]= value;			\
  stack[stackIndex++]= value

#define qalignGPR()	gprCount += (gprCount & 1)


int ffiPushSignedChar(int value)
{ 
  dprintf(("ffiPushSignedChar %d\n", value));
  pushGPR(value);
  return 1;
}


int ffiPushUnsignedChar(int value) 
{ 
  dprintf(("ffiPushUnsignedChar %d\n", value));
  pushGPR(value);
  return 1;
}


int ffiPushSignedByte(int value) 
{ 
  dprintf(("ffiPushSignedByte %d\n", value));
  pushGPR(value);
  return 1;
}


int ffiPushUnsignedByte(int value)
{ 
  dprintf(("ffiPushUnsignedByte %d\n", value));
  pushGPR(value);
  return 1;
}


int ffiPushSignedShort(int value)
{ 
  dprintf(("ffiPushSignedShort %d\n", value));
  pushGPR(value); 
  return 1; 
}


int ffiPushUnsignedShort(int value) 
{ 
  dprintf(("ffiPushUnsignedShort %d\n", value));
  pushGPR(value); 
  return 1; 
}


int ffiPushSignedInt(int value) 
{ 
  dprintf(("ffiPushSignedInt %d\n", value));
  pushGPR(value); 
  return 1; 
}


int ffiPushUnsignedInt(int value) 
{ 
  dprintf(("ffiPushUnsignedInt %d\n", value));
  pushGPR(value);
  return 1;
}


int ffiPushSignedLongLong(int low, int high)
{
  dprintf(("ffiPushSignedLongLong %d %d\n", low, high));
  qalignGPR();
  qalignStack();
  pushGPR(high);
  pushGPR(low);
  return 1;
}


int ffiPushUnsignedLongLong(int low, int high)
{ 
  dprintf(("ffiPushUnsignedLongLong %d %d\n", low, high));
  qalignGPR();
  qalignStack();
  pushGPR(high);
  pushGPR(low);
  return 1;
}


int ffiPushPointer(int pointer)
{
  dprintf(("ffiPushPointer %08x\n", pointer));
  pushGPR(pointer);
  return 1;
}


int ffiPushSingleFloat(double value)
{
  dprintf(("ffiPushSingleFloat %f\n", (float)value));
  if (fprCount < FPR_MAX)
    fprs[fprCount++]= value;
  {
    float floatValue= (float)value;
    pushGPR(*(int *)&floatValue);
  }
  return 1;
}


int ffiPushDoubleFloat(double value)
{
  dprintf(("ffiPushDoubleFloat %f\n", (float)value));
  if (fprCount < FPR_MAX)
    fprs[fprCount++]= value;
  pushGPR(((int *)&value)[0]);
  pushGPR(((int *)&value)[1]);
  return 1;
}


int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
  dprintf(("ffiPushStringOfLength %d\n", length));
  checkGPR();
  ptr= (char *)malloc(length + 1);
  if (!ptr)
    return primitiveFail();
  memcpy(ptr, (void *)srcIndex, length);
  ptr[length]= '\0';
  strings[stringCount++]= ptr;
  pushGPR((int)ptr);
  return 1;
}


static inline int min(int x, int y) { return (x < y) ? x : y; }


int ffiPushStructureOfLength(int pointer, int *structSpec, int specSize)
{
  int i;
  char *data	= (char *)pointer;
  char *argp	= (char *)&stack[stackIndex];
#define argl	  (char *)&stack[ARG_MAX]
  int   argSize	= *structSpec & FFIStructSizeMask;
  char *gprp	= (char *)&gprs[gprCount];
#define gprl	  (char *)&gprs[GPR_MAX]
  int   gprSize	= min(argSize, gprl - gprp);

  dprintf(("ffiPush %08x Structure %p OfLength %d\n", pointer, structSpec, specSize));

  if (gprSize < 4) gprp += (4 - gprSize);
  if (argSize < 4) argp += (4 - gprSize);
  if (argp + argSize > argl)
    return primitiveFail();

  memcpy((void *)gprp, (void *)data, gprSize);
  memcpy((void *)argp, (void *)data, argSize);
  gprCount   += (gprSize + sizeof(int) - 1) / sizeof(int);
  stackIndex += (argSize + sizeof(int) - 1) / sizeof(int);

#undef argl
#undef gprl

  for (i= 0;  i < specSize;  ++i)
    {
      int typeSpec= structSpec[i];
      if (typeSpec & FFIFlagPointer)
	continue;
      else if (typeSpec & FFIFlagStructure)
	continue;
      else
	{	
	  int atomicType= (typeSpec & FFIAtomicTypeMask) >> FFIAtomicTypeShift;
	  switch (atomicType)
	    {
	    case FFITypeSingleFloat:
	      if (fprCount < FPR_MAX)
		fprs[fprCount++]= *(float *)data;
	      break;
	    case FFITypeDoubleFloat:
	      if (fprCount < FPR_MAX)
		fprs[fprCount++]= *(double *)data;
	      break;
	    default:
	      break;
	    }
	  data += typeSpec & FFIStructSizeMask;
	}
    }
  return 1;
}


int ffiCanReturn(int *structSpec, int specSize)
{
  int header= *structSpec;
  dprintf(("ffiCanReturn %p %d\n", structSpec, specSize));
  if (header & FFIFlagPointer)
    return 1;
  if (header & FFIFlagStructure)
    {
      /* structs are always returned as pointers to hidden structures */
      int structSize= header & FFIStructSizeMask;
      structReturnValue= malloc(structSize);
      if (!structReturnValue)
	return 0;
      pushGPR((int)structReturnValue);
    }
  return 1;
}


double ffiReturnFloatValue(void)	{ return floatReturnValue; }
int    ffiLongLongResultLow(void)	{ return ((int *)&longReturnValue)[1]; }
int    ffiLongLongResultHigh(void)	{ return ((int *)&longReturnValue)[0]; }


int ffiStoreStructure(int address, int structSize)
{
  dprintf(("ffiStoreStructure %08x %d\n", address, structSize));
  memcpy((void *)address,
	 structReturnValue ? (void *)structReturnValue : (void *)&longReturnValue,
	 structSize);
  return 1;
}


int ffiCleanup(void)
{
  int i;
  dprintf(("ffiCleanup\n"));
  for (i= 0;  i < stringCount;  ++i)
    free(strings[i]);
  stringCount= 0;
  if (structReturnValue)
    {
      free(structReturnValue);
      structReturnValue= 0;
    }
  return 1;
}


int ffiCallAddressOfWithPointerReturnx(int fn, int callType)
{
  dprintf(("ffiCallAddressOfWithPointerReturn %08x %d\n", fn, callType));
  return ffiCallAddressOf((void *)fn, (void *)&global);
}


int ffiCallAddressOfWithStructReturnx(int fn, int callType, int* structSpec, int specSize)
{
  dprintf(("ffiCallAddressOfWithStructReturn %08x %d %p %d\n",
	   fn, callType, structSpec, specSize));
  return ffiCallAddressOf((void *)fn, (void *)&global);
}


int ffiCallAddressOfWithReturnTypex(int fn, int callType, int typeSpec)
{
  dprintf(("ffiCallAddressOfWithReturnType %08x %d %d\n", fn, callType, typeSpec));
  return ffiCallAddressOf((void *)fn, (void *)&global);
}

int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
	int resultsOfCall;

	if (giLocker == 0)
		giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		long *foo;
		foo = malloc(sizeof(long)*5);
		foo[0] = 2;
		foo[1] = ffiCallAddressOfWithPointerReturnx;
		foo[2] = fn;
		foo[3] = callType;
		foo[4] = 0;
		((int (*) (void *)) giLocker)(foo);
		resultsOfCall = foo[4];
		free(foo);
		return resultsOfCall;
	}
}

int ffiCallAddressOfWithStructReturn(int fn, int callType, int* structSpec, int specSize)
{
	int resultsOfCall;

	if (giLocker == 0)
		giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		long *foo;
		foo = malloc(sizeof(long)*7);
		foo[0] = 4;
		foo[1] = ffiCallAddressOfWithStructReturnx;
		foo[2] = fn;
		foo[3] = callType;
		foo[4] = structSpec;
		foo[5] = specSize;
		foo[6] = 0;
		((int (*) (void *)) giLocker)(foo);
		resultsOfCall = foo[6];
		free(foo);
		return resultsOfCall;
	}
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
	int resultsOfCall;

	if (giLocker == 0)
		giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		long *foo;
		foo = malloc(sizeof(long)*6);
		foo[0] = 3;
		foo[1] = ffiCallAddressOfWithReturnTypex;
		foo[2] = fn;
		foo[3] = callType;
		foo[4] = typeSpec;
		foo[5] = 0;
		((int (*) (void *)) giLocker)(foo);
		resultsOfCall = foo[5];
		free(foo);
		return resultsOfCall;
	}
}

#if !defined(NO_FFI_TEST)

#undef gprCount
#undef fprCount
#undef stackIndex
#undef structReturnValue
#undef longReturnValue
#undef floatReturnValue
#undef gprs
#undef fprs
#undef stack

#include "ppc-global.h"

#define offset(field)	((char *)&global._##field - (char *)&global._gprCount)

#include <assert.h>

void ffiDoAssertions(void)
{
  assert(gprCount		== offset(gprCount));
  assert(fprCount		== offset(fprCount));
  assert(stackIndex		== offset(stackIndex));
  assert(structReturnValue	== offset(structReturnValue));
  assert(longReturnValue	== offset(longReturnValue));
  assert(floatReturnValue	== offset(floatReturnValue));
  assert(gprs			== offset(gprs));
  assert(fprs			== offset(fprs));
  assert(stack			== offset(stack));

  assert(stack + (ARG_MAX * sizeof(int)) == sizeof(global));
}

#endif
#endif

