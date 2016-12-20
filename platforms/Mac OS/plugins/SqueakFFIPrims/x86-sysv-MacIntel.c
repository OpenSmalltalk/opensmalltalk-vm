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
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
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
# define DPRINTF(ARGS)printf ARGS
#else
# define DPRINTF(ARGS)
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
int	* volatile   ffiStructReturnValue;


extern int ffiCallAddressOf(void *addr, void *stack, int size);

static FILE *ffiLogFile = NULL;

int ffiLogFileNameOfLength(void *nameIndex, int nameLength) {
  char fileName[MAX_PATH];
  FILE *fp;

  if(nameIndex && nameLength) {
    if(nameLength >= MAX_PATH) return 0;
    strncpy(fileName, nameIndex, nameLength);
    fileName[nameLength] = 0;
    /* attempt to open the file and if we can't fail */
    fp = fopen(fileName, "at");
    if(fp == NULL) return 0;
    /* close the old log file if needed and use the new one */
    if(ffiLogFile) fclose(ffiLogFile);
    ffiLogFile = fp;
    fprintf(ffiLogFile, "------- Log started -------\n");
    fflush(fp);
  } else {
    if(ffiLogFile) fclose(ffiLogFile);
    ffiLogFile = NULL;
  }
  return 1;
}

int ffiLogCallOfLength(void *nameIndex, int nameLength) {
    if(ffiLogFile == NULL) return 0;
    fprintf(ffiLogFile, "%.*s\n", nameIndex, nameLength);
    fflush(ffiLogFile);
}


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


int ffiFree(sqIntptr_t ptr)
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
  DPRINTF(("ffiCanReturn structSpec %d specSize %d\n", structSpec, specSize));
  if (header & FFIFlagPointer)
    return 1;
  if (header & FFIFlagStructure)
    {
      /* structs are always returned as pointers to hidden structures */
      int structSize= header & FFIStructSizeMask;
      ffiStructReturnValue= malloc(structSize);
      if (!ffiStructReturnValue)
		return 0;
	  DPRINTF(("ffiCanReturn allocated Spec %d \n", ffiStructReturnValue));
      pushInt((int)ffiStructReturnValue);
    }
  return 1;
}


int ffiPushSignedChar(int value)
{ 
  DPRINTF(("ffiPushSignedChar %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedChar(int value)
{ 
  DPRINTF(("ffiPushUnsignedChar %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedByte(int value)
{ 
  DPRINTF(("ffiPushSignedByte %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedByte(int value)
{ 
  DPRINTF(("ffiPushUnsignedByte %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedShort(int value)
{ 
  DPRINTF(("ffiPushSignedShort %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedShort(int value)
{ 
  DPRINTF(("ffiPushUnsignedShort %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedInt(int value)
{ 
  DPRINTF(("ffiPushSignedInt %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedInt(int value)
{ 
  DPRINTF(("ffiPushUnsignedInt %d\n", value));
  pushInt(value);
  return 1; 
}

int ffiPushSignedLongLong(int low, int high)
{ 
  DPRINTF(("ffiPushSignedLongLong %d %d\n", low, high));
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushUnsignedLongLong(int low, int high)
{ 
  DPRINTF(("ffiPushUnsignedLongLong %d %d\n", low, high));
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushPointer(int pointer)
{ 
  DPRINTF(("ffiPushPointer %d\n", pointer));
  pushInt(pointer);
  return 1; 
}

int ffiPushSingleFloat(double value)
{ 
  float f= (float)value;
  DPRINTF(("ffiPushSingleFloat %f\n", value));
  pushInt(*(int *)&f);
  return 1; 
}

int ffiPushDoubleFloat(double value)
{ 
  DPRINTF(("ffiPushDoubleFloat %f\n", value));
  pushInt(((int *)&value)[0]);
  pushInt(((int *)&value)[1]);
  return 1; 
}

int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
  DPRINTF(("ffiPushStringOfLength %d\n", length));
  checkStack();
  ptr= (char *)malloc(length + 1);
  if (!ptr)
    return primitiveFail();
  DPRINTF(("  ++ alloc string\n"));
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
  DPRINTF(("ffiPushStructureOfLength %d (%db %dw)\n", specSize, lbs, size));
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
  DPRINTF(("ffiStoreStructure %d %d\n", address, structSize));
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
  DPRINTF(("ffiCleanup\n"));
  for (i= 0;  i < ffiTempStringCount;  ++i)
    {
      DPRINTF(("  ++ free string\n"));
      free(ffiTempStrings[i]);
    }
  ffiTempStringCount= 0;
  if (ffiStructReturnValue)
    {
      DPRINTF(("  ++ free struct\n"));
      free(ffiStructReturnValue);
      ffiStructReturnValue= 0;
    }
  return 1;
}


int ffiCallAddressOfWithPointerReturnx(int fn, int callType)
{
  DPRINTF(("ffiCallAddressOfWithPointerReturnx fn %d callType %d \n", fn, callType));
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithStructReturnx(int fn, int callType, int* structSpec, int specSize)
{
  DPRINTF(("ffiCallAddressOfWithStructReturnx fn %d callType %d structSpec %d specSize %d\n", fn, callType, structSpec, specSize));
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithReturnTypex(int fn, int callType, int typeSpec)
{
  DPRINTF(("ffiCallAddressOfWithReturnTypex fn %d callType %d \n", fn, callType, typeSpec));
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
