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

#if 0
# define dprintf(ARGS)	printf ARGS
#else
# define dprintf(ARGS)
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


int ffiFree(int ptr)
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
  dprintf(("ffiPushPointer %d\n", pointer));
  pushGPR(pointer);
  return 1;
}


#define checkFPR()					\
  if ((fprCount >= FPR_MAX) && (stackIndex >= ARG_MAX))	\
    return primitiveFail()

#define dalignStack()	stackIndex += (stackIndex & 1)


int ffiPushSingleFloat(double value)
{
  dprintf(("ffiPushSingleFloat %f\n", (float)value));
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
  dprintf(("ffiPushDoubleFloat %f\n", (float)value));
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


#define salign(size)					\
  structCount= (structCount + (size) - 1) & ~(size)

#define pushStruct(type, value)				\
{							\
  dprintf(("  ++ "#type"\n"));				\
  if ((structCount + sizeof(type)) > sizeof(structs))	\
    return primitiveFail();				\
  *(type *)(structs + structCount)= value;		\
  structCount += sizeof(type);				\
}


int ffiPushStructureOfLength(int pointer, int *structSpec, int specSize)
{
  int size= *structSpec & FFIStructSizeMask;
  dprintf(("ffiPushStructureOfLength %d (%db)\n", specSize, size));
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
