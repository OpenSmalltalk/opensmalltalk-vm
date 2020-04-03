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
#include <sys/param.h>

#ifndef LONGLONG
# define LONGLONG long long
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

static char	*ffiTempStrings[FFI_MAX_STACK];
static int	 ffiTempStringCount= 0;


int	 ffiIntReturnValue;
int	 ffiLongReturnValue;
double	 ffiFloatReturnValue;
int	*ffiStructReturnValue;


extern int ffiCallAddressOf(void *addr, void *stack, int size);

int ffiLogCallOfLength(void *nameIndex, int nameLength) {
   logTrace("%.*s\n", nameIndex, nameLength);
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
  if (header & FFIFlagPointer)
    return 1;
  if (header & FFIFlagStructure)
    {
      /* structs are always returned as pointers to hidden structures */
      int structSize= header & FFIStructSizeMask;
      ffiStructReturnValue= malloc(structSize);
      if (!ffiStructReturnValue)
	return 0;
      pushInt((int)ffiStructReturnValue);
    }
  return 1;
}


int ffiPushSignedChar(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedChar(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushSignedByte(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedByte(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushSignedShort(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedShort(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushSignedInt(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushUnsignedInt(int value)
{ 
  pushInt(value);
  return 1; 
}

int ffiPushSignedLongLong(int low, int high)
{ 
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushUnsignedLongLong(int low, int high)
{ 
  pushInt(low);
  pushInt(high);
  return 1; 
}

int ffiPushPointer(int pointer)
{ 
  pushInt(pointer);
  return 1; 
}

int ffiPushSingleFloat(double value)
{ 
  float f= (float)value;
  pushInt(*(int *)&f);
  return 1; 
}

int ffiPushDoubleFloat(double value)
{ 
  pushInt(((int *)&value)[0]);
  pushInt(((int *)&value)[1]);
  return 1; 
}

int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
  checkStack();
  ptr= (char *)malloc(length + 1);
  if (!ptr)
    return primitiveFail();
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
  memcpy((void *)address, (ffiStructReturnValue
			   ? (void *)ffiStructReturnValue
			   : (void *)&ffiIntReturnValue),
	 structSize);
  return 1;
}


int ffiCleanup(void)
{
  int i;
  for (i= 0;  i < ffiTempStringCount;  ++i)
    {
      free(ffiTempStrings[i]);
    }
  ffiTempStringCount= 0;
  if (ffiStructReturnValue)
    {
      free(ffiStructReturnValue);
      ffiStructReturnValue= 0;
    }
  return 1;
}


int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithStructReturn(int fn, int callType, int* structSpec, int specSize)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiStack,
			  ffiStackIndex * sizeof(int));
}


#if defined(FFI_TEST)
void ffiDoAssertions(void) {}
#endif
