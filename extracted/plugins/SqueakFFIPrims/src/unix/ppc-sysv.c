/* ppc-sysv.c -- FFI support for PowerPC SVr4 ABI
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2003-01-30 00:18:07 by piumarta on emilia.inria.fr
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
 *
 * References:
 * 
 *   System V Application Binary Interface, Third Edition,
 *	Unix System Laboratories, 1994, ISBN 0-13-100439-5.
 * 
 *   System V Application Binary Interface, PowerPC Processor Supplement,
 *	Sun Microsystems and IBM, 1995.
 */

/* Differences between the SVr4 PPC ABI and the implementation found on
 * GNU-based systems (which is implemented herein):
 * 
 *   Float arguments are passed as doubles when in registers but as
 *   floats when on the stack.  (The ABI says they should always be
 *   passed as doubles, even on the stack.)
 * 
 *   All structures are passed by reference (to a copy), even when
 *   small (< 8 bytes).  The ABI would have small structs passed in
 *   registers.  (GCC copies such structs to the top of the param save
 *   area, after the actual arguments, at the start of the alloca
 *   area.  The implementation in this file copies them into a
 *   temporary static array, which makes stack management simpler
 *   and seems to work just fine.)
 *   
 *   Structures are always returned via a pointer to caller-allocated
 *   memory (passed as a hidden first argument), even when small.
 *   (The ABI would have small structs, < 8 bytes, returned in r3 and
 *   r4.)
 */

#include "sq.h"
#include "sqFFI.h"

#include <stdio.h>
#include <stdlib.h>

#ifndef LONGLONG
# define LONGLONG long long
#endif

#if defined(FFI_TEST)
  static int primitiveFail(void) { puts("primitive fail"); exit(1); return 0; }
#else
  extern struct VirtualMachine *interpreterProxy;
# define primitiveFail() interpreterProxy->primitiveFail()
#endif

enum {
  GPR_MAX=   8,
  FPR_MAX=   8,
  ARG_MAX= 512
};

       int	 ffiGPRs[GPR_MAX];
static int	 gprCount= 0;
       double	 ffiFPRs[FPR_MAX];
static int	 fprCount= 0;

       int	 ffiStack[ARG_MAX];
static int	 stackIndex= 0;

static char	*strings[ARG_MAX];
static int	 stringCount= 0;

static char	 structs[ARG_MAX * sizeof(int)];
static int	 structCount= 0;

       LONGLONG	 ffiLongReturnValue;
       double	 ffiFloatReturnValue;
static int	*structReturnValue= 0;


extern int ffiCallAddressOf(void *addr, int nGPR, int nFPR, int nStack);


int ffiInitialize(void)
{
  stackIndex= gprCount= fprCount= structCount= 0;
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
  if (stackIndex >= ARG_MAX)		\
    return primitiveFail()

#define checkGPR()						\
  if ((gprCount >= GPR_MAX) && (stackIndex >= ARG_MAX))	\
    return primitiveFail()

#define qalignStack()	stackIndex += (stackIndex & 1)

#define pushGPR(value)				\
  checkGPR();					\
  if (gprCount < GPR_MAX)			\
    ffiGPRs[gprCount++]= value;			\
  else						\
    ffiStack[stackIndex++]= value

#define qalignGPR()	gprCount += (gprCount & 1)


int ffiPushSignedChar(int value)
{ 
  pushGPR(value);
  return 1;
}


int ffiPushUnsignedChar(int value) 
{ 
  pushGPR(value);
  return 1;
}


int ffiPushSignedByte(int value) 
{ 
  pushGPR(value);
  return 1;
}


int ffiPushUnsignedByte(int value)
{ 
  pushGPR(value);
  return 1;
}


int ffiPushSignedShort(int value)
{ 
  pushGPR(value); 
  return 1; 
}


int ffiPushUnsignedShort(int value) 
{ 
  pushGPR(value); 
  return 1; 
}


int ffiPushSignedInt(int value) 
{ 
  pushGPR(value); 
  return 1; 
}


int ffiPushUnsignedInt(int value) 
{ 
  pushGPR(value);
  return 1;
}


int ffiPushSignedLongLong(int low, int high)
{
  qalignGPR();
  qalignStack();
  pushGPR(high);
  pushGPR(low);
  return 1;
}


int ffiPushUnsignedLongLong(int low, int high)
{ 
  qalignGPR();
  qalignStack();
  pushGPR(high);
  pushGPR(low);
  return 1;
}


int ffiPushPointer(int pointer)
{
  pushGPR(pointer);
  return 1;
}


#define checkFPR()					\
  if ((fprCount >= FPR_MAX) && (stackIndex >= ARG_MAX))	\
    return primitiveFail()

#define dalignStack()	stackIndex += (stackIndex & 1)


int ffiPushSingleFloat(double value)
{
  if (fprCount < FPR_MAX)
    ffiFPRs[fprCount++]= value;
  else
    {
      float floatValue= (float)value;
      checkStack();
      ffiStack[stackIndex++]= *(int *)&floatValue;
    }
  return 1;
}


int ffiPushDoubleFloat(double value)
{
  if (fprCount < FPR_MAX)
    ffiFPRs[fprCount++]= value;
  else
    {
      dalignStack();
      checkStack();
      ffiStack[stackIndex++]= ((int *)(&value))[0];
      checkStack();
      ffiStack[stackIndex++]= ((int *)(&value))[1];
    }
  return 1;
}


int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
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


#define salign(size)					\
  structCount= (structCount + (size) - 1) & ~(size)

#define pushStruct(type, value)				\
{							\
  if ((structCount + sizeof(type)) > sizeof(structs))	\
    return primitiveFail();				\
  *(type *)(structs + structCount)= value;		\
  structCount += sizeof(type);				\
}


int ffiPushStructureOfLength(int pointer, int *structSpec, int specSize)
{
  int size= *structSpec & FFIStructSizeMask;
  salign(16);
  if (structCount + size > sizeof(structs))
    return primitiveFail();
  ffiPushPointer((int)(structs + structCount));
  memcpy((void *)(structs + structCount), (void *)pointer, size);
  structCount += size;
  return 1;
}


/* answer true if the support code can return the given type.
 */
int ffiCanReturn(int *structSpec, int specSize)
{
  int header= *structSpec;
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


double ffiReturnFloatValue(void)	{ return ffiFloatReturnValue; }
int    ffiLongLongResultLow(void)	{ return ((int *)&ffiLongReturnValue)[1]; }
int    ffiLongLongResultHigh(void)	{ return ((int *)&ffiLongReturnValue)[0]; }


int ffiStoreStructure(int address, int structSize)
{
  memcpy((void *)address, (void *)structReturnValue, structSize);
  return 1;
}


int ffiCleanup(void)
{
  int i;
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


int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
  return ffiCallAddressOf((void *)fn, gprCount, fprCount, stackIndex);
}


int ffiCallAddressOfWithStructReturn(int fn, int callType, int* structSpec, int specSize)
{
  return ffiCallAddressOf((void *)fn, gprCount, fprCount, stackIndex);
}


int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
  return ffiCallAddressOf((void *)fn, gprCount, fprCount, stackIndex);
}


#if defined(FFI_TEST)

void ffiDoAssertions(void)
{
}

#endif
