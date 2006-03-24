#if __LITTLE_ENDIAN__


// THIS IS BROKEN FOR CROQUET


/* ppc-sysv.c -- FFI support for PowerPC SVr4 ABI
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2003-02-06 20:08:58 by piumarta on felina.inria.fr
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
 * BUGS:
 * 
 *   Because of the way strings and structs are handled, this implementation
 *   is neither reentrant nor thread safe.
 */

#include "sq.h"
#include "sqFFI.h"

#include <stdio.h>
#include <stdlib.h>

#ifndef LONGLONG
# define LONGLONG long long
#endif

#if 1
# define dprintf(ARGS)printf ARGS
#else
# define dprintf(ARGS)
#endif

#if defined(FFI_TEST)
  static int primitiveFail(void) { puts("primitive fail"); exit(1); return 0; }
#else
  extern struct VirtualMachine *interpreterProxy;
# define primitiveFail() interpreterProxy->primitiveFail()
#endif

enum { FFI_MAX_STACK= 512 };

int	 ffiStack[FFI_MAX_STACK];
int	 ffiStackIndex= 0;
static int giLocker;


static char	*ffiTempStrings[FFI_MAX_STACK];
static int	 ffiTempStringCount= 0;


volatile int	 ffiIntReturnValue;
volatile int	 ffiLongReturnValue;
volatile double	 ffiFloatReturnValue;
volatile int	*ffiStructReturnValue;


extern int ffiCallAddressOf(void *addr, void *stack, int size);


int ffiInitialize(void)
{
  ffiStackIndex= 0;
  ffiFloatReturnValue= 0.0;
  return 1;
}


int ffiSupportsCallingConvention(int callType)
{
  return (callType == FFICallTypeCDecl)
    ||   (callType == FFICallTypeApi);
}


int ffiAlloc(int byteSize)
{
  return (int)malloc(byteSize);
}


int ffiFree(int ptr)
{
  if (ptr) free((void *)ptr);
  return 1;
}


#define checkStack()				\
  if (ffiStackIndex >= FFI_MAX_STACK)		\
     return primitiveFail();

#define pushInt(value)				\
  checkStack();					\
  ffiStack[ffiStackIndex++]= (value)


int ffiCanReturn(int *structSpec, int specSize)
{
  int header= *structSpec;
  dprintf(("ffiCanReturn structSpec %d specSize %d\n", structSpec, specSize));
  if (header & FFIFlagPointer)
    return 1;
  if (header & FFIFlagStructure)
    {
      /* structs are always returned as pointers to hidden structures */
      int structSize= header & FFIStructSizeMask;
      ffiStructReturnValue= malloc(structSize);
      if (!ffiStructReturnValue)
		return 0;
	  dprintf(("ffiCanReturn allocated Spec %d \n", ffiStructReturnValue));
      pushInt((int)ffiStructReturnValue);
    }
  return 1;
}


int ffiPushSignedChar(int value)
{ 
  dprintf(("ffiPushSignedChar %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedChar(int value)
{ 
  dprintf(("ffiPushUnsignedChar %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedByte(int value)
{ 
  dprintf(("ffiPushSignedByte %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedByte(int value)
{ 
  dprintf(("ffiPushUnsignedByte %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedShort(int value)
{ 
  dprintf(("ffiPushSignedShort %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedShort(int value)
{ 
  dprintf(("ffiPushUnsignedShort %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedInt(int value)
{ 
  dprintf(("ffiPushSignedInt %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedInt(int value)
{ 
  dprintf(("ffiPushUnsignedInt %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedLongLong(int low, int high)
{ 
  dprintf(("ffiPushSignedLongLong %d %d\n", low, high));
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushUnsignedLongLong(int low, int high)
{ 
  dprintf(("ffiPushUnsignedLongLong %d %d\n", low, high));
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushPointer(int pointer)
{ 
  dprintf(("ffiPushPointer %d\n", pointer));
  pushInt(pointer);
  return 1; 
}

int ffiPushSingleFloat(double value)
{ 
  float f= (float)value;
  dprintf(("ffiPushSingleFloat %f\n", value));
  pushInt(*(int *)&f);
  return 1; 
}

int ffiPushDoubleFloat(double value)
{ 
  dprintf(("ffiPushDoubleFloat %f\n", value));
  pushInt(((int *)&value)[0]);
  pushInt(((int *)&value)[1]);
  return 1; 
}

int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
  dprintf(("ffiPushStringOfLength %d\n", length));
  checkStack();
  ptr= (char *)malloc(length + 1);
  if (!ptr)
    return primitiveFail();
  dprintf(("  ++ alloc string\n"));
  memcpy(ptr, (void *)srcIndex, length);
  ptr[length]= '\0';
  ffiTempStrings[ffiTempStringCount++]= ptr;
  pushInt((int)ptr);
  return 1;
}

int ffiPushStructureOfLength(int pointer, int *structSpec, int specSize)
{
  int lbs= *structSpec & FFIStructSizeMask;
  int size= (lbs + sizeof(int) - 1) / sizeof(int);
  dprintf(("ffiPushStructureOfLength %d (%db %dw)\n", specSize, lbs, size));
  if (ffiStackIndex + size > FFI_MAX_STACK)
    return primitiveFail();
  memcpy((void *)(ffiStack + ffiStackIndex), (void *)pointer, lbs);
  ffiStackIndex += size;
  return 1;
}


double  ffiReturnFloatValue(void)	{ return ffiFloatReturnValue; }
int	ffiLongLongResultLow(void)	{ return ffiIntReturnValue; }
int	ffiLongLongResultHigh(void)	{ return ffiLongReturnValue; }


int ffiStoreStructure(int address, int structSize)
{
  dprintf(("ffiStoreStructure %d %d\n", address, structSize));
// JMM  memcpy((void *)address, (ffiStructReturnValue
//			   ? (void *)ffiStructReturnValue
//			   : (void *)&ffiIntReturnValue),
//	 structSize);
	if(structSize <= 4) {
		*(int*)address = ffiIntReturnValue;
		return 1;
	}
	if(structSize <= 8) {
		*(int*)address = ffiIntReturnValue;
		*(int*)(address+4) = ffiLongReturnValue;
		return 1;
	}
	/* assume pointer to hidden structure */
	memcpy((void*)address, (void*) ffiStructReturnValue, structSize);
	return 1;
}


int ffiCleanup(void)
{
  int i;
  dprintf(("ffiCleanup\n"));
  for (i= 0;  i < ffiTempStringCount;  ++i)
    {
      dprintf(("  ++ free string\n"));
      free(ffiTempStrings[i]);
    }
  ffiTempStringCount= 0;
  if (ffiStructReturnValue)
    {
      dprintf(("  ++ free struct\n"));
      free(ffiStructReturnValue);
      ffiStructReturnValue= 0;
    }
  return 1;
}


int ffiCallAddressOfWithPointerReturnx(int fn, int callType)
{
  dprintf(("ffiCallAddressOfWithPointerReturnx fn %d callType %d \n", fn, callType));
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithStructReturnx(int fn, int callType, int* structSpec, int specSize)
{
  dprintf(("ffiCallAddressOfWithStructReturnx fn %d callType %d structSpec %d specSize %d\n", fn, callType, structSpec, specSize));
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithReturnTypex(int fn, int callType, int typeSpec)
{
  dprintf(("ffiCallAddressOfWithReturnTypex fn %d callType %d \n", fn, callType, typeSpec));
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
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



#if defined(FFI_TEST)
void ffiDoAssertions(void) {}
#endif
#endif
