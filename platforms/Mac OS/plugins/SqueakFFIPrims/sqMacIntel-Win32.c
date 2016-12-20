#if __LITTLE_ENDIAN__
/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqWin32FFI.c
*   CONTENT: Win32 support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: sqWin32FFI.c 414 2002-06-01 11:44:39Z andreasraab $
*
*   NOTES:
*   Altered by John M McIntosh for Mac Intel Support, use UI Lock, also use system V with Darwin and MacIntel logic assembler
*
*****************************************************************************/
#include "sq.h"
#include "sqFFI.h"

#if !defined(PATH_MAX)
# include <sys/syslimits.h>
#endif

extern struct VirtualMachine *interpreterProxy;
#define primitiveFail() interpreterProxy->primitiveFail();

#ifdef _MSC_VER
#define LONGLONG __int64
#endif
#ifdef __GNUC__
#define LONGLONG long long int
#endif

/* Max stack size */
#define FFI_MAX_ARGS 128
/* The stack used to assemble the arguments for a call */
 int   ffiArgs[FFI_MAX_ARGS];
/* The stack pointer while filling the stack */
 int   ffiArgIndex = 0;
/* The area for temporarily allocated strings */
static char *ffiTempStrings[FFI_MAX_ARGS];
/* The number of temporarily allocated strings */
static int   ffiTempStringCount = 0;

/* The return values for calls */
volatile  int      intReturnValue;
volatile  int      intReturnValue2;
volatile  double   floatReturnValue;
static void*    structReturnValue;

#define ARG_CHECK() if(ffiArgIndex >= FFI_MAX_ARGS) return primitiveFail();
#define ARG_PUSH(value) { ARG_CHECK(); ffiArgs[ffiArgIndex++] = value; }
#define MAX_PATH  PATH_MAX

/*****************************************************************************/
/*****************************************************************************/
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

/*****************************************************************************/
/*****************************************************************************/

/*  ffiInitialize:
	Announce that the VM is about to do an external function call. */
int ffiInitialize(void)
{
	ffiArgIndex = 0;
	ffiTempStringCount = 0;
	return 1;
}

/*  ffiSupportsCallingConvention:
	Return true if the support code supports the given calling convention. */
int ffiSupportsCallingConvention(int callType)
{
	if(callType == FFICallTypeCDecl) return 1;
	if(callType == FFICallTypeApi) return 1;
	return 0;
}

int ffiAlloc(int byteSize)
{
	return (int) malloc(byteSize);
}

int ffiFree(sqIntptr_t ptr)
{
	if(ptr) free((void*)ptr);
	return 1;
}

/*****************************************************************************/
/*****************************************************************************/

int ffiPushSignedChar(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushUnsignedChar(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushSignedByte(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushUnsignedByte(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushSignedShort(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushUnsignedShort(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushSignedInt(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushUnsignedInt(int value) 
{ 
	ARG_PUSH(value); 
	return 1; 
}

int ffiPushSignedLongLong(int lowWord, int highWord) 
{ 
	ARG_PUSH(lowWord); 
	ARG_PUSH(highWord); 
	return 1; 
}

int ffiPushUnsignedLongLong(int lowWord, int highWord) 
{ 
	ARG_PUSH(lowWord); 
	ARG_PUSH(highWord); 
	return 1; 
}

int ffiPushSingleFloat(double value)
{
	float floatValue;
	floatValue = (float) value;
	ARG_PUSH(*(int*)(&floatValue));
	return 1;
}

int ffiPushDoubleFloat(double value)
{
	ARG_PUSH(((int*)(&value))[0]);
	ARG_PUSH(((int*)(&value))[1]);
	return 1;
}

int ffiPushStructureOfLength(int pointer, int* structSpec, int structSize)
{
	int nItems, i;
	nItems = ((*structSpec & FFIStructSizeMask) + 3) / 4;
	if(pointer == 0) 
		return primitiveFail();
	for(i=0; i < nItems;i++)
		ARG_PUSH(((int*)pointer)[i]);
	return 1;
}

int ffiPushPointer(int pointer)
{
	ARG_PUSH(pointer);
	return 1;
}

int ffiPushStringOfLength(int srcIndex, int length)
{
	char *ptr;
	ARG_CHECK(); /* fail before allocating */
	ptr = (char*) malloc(length+1);
	if(!ptr) return primitiveFail();
	memcpy(ptr, (void*)srcIndex, length);
	ptr[length] = 0;
	ffiTempStrings[ffiTempStringCount++] = ptr;
	ARG_PUSH((int)ptr);
	return 1;
}

/*****************************************************************************/
/*****************************************************************************/

/*  ffiCanReturn:
	Return true if the support code can return the given type. */
int ffiCanReturn(int *structSpec, int specSize)
{
	int header = *structSpec;
	if(header & FFIFlagPointer) return 1;
	if(header & FFIFlagStructure) {
		int structSize = header & FFIStructSizeMask;
		if(structSize > 8) {
			structReturnValue = malloc(structSize);
			if(!structReturnValue) return 0;
			ARG_PUSH((int)structReturnValue);
		}
	}
	return 1;
}

/*  ffiReturnFloatValue:
	Return the value from a previous ffi call with float return type. */
double ffiReturnFloatValue(void)
{
	return floatReturnValue;
}

/*  ffiLongLongResultLow:
	Return the low 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultLow(void)
{
	return intReturnValue;
}

/*  ffiLongLongResultHigh:
	Return the high 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultHigh(void)
{
	return intReturnValue2;
}

/*  ffiStoreStructure:
	Store the structure result of a previous ffi call into the given address.
	Note: Since the ST allocator always allocates multiples of 32bit we can
	use the atomic types for storing <= 64bit result structures. */
int ffiStoreStructure(int address, int structSize)
{
	if(structSize <= 4) {
		*(int*)address = intReturnValue;
		return 1;
	}
	if(structSize <= 8) {
		*(int*)address = intReturnValue;
		*(int*)(address+4) = intReturnValue2;
		return 1;
	}
	/* assume pointer to hidden structure */
	memcpy((void*)address, (void*) structReturnValue, structSize);
	return 1;
}

/*  ffiCleanup:
	Cleanup after a foreign function call has completed. */
int ffiCleanup(void)
{
	int i;
	for(i=0; i<ffiTempStringCount; i++)
		free(ffiTempStrings[i]);
	ffiTempStringCount = 0;
	if(structReturnValue) {
		free(structReturnValue);
		structReturnValue = NULL;
	}
	return 1;
}

/*****************************************************************************/
/*****************************************************************************/


int ffiCallAddressOfWithPointerReturnx(int fn, int callType)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiArgs,
			  ffiArgIndex * sizeof(int));
}
int ffiCallAddressOfWithStructReturnx(int fn, int callType, int* structSpec, int specSize)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiArgs,
			  ffiArgIndex * sizeof(int));
}

int ffiCallAddressOfWithReturnTypex(int fn, int callType, int typeSpec)
{
  return ffiCallAddressOf((void *)fn, (void *)ffiArgs,
			  ffiArgIndex * sizeof(int));
}

static int giLocker;

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


/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/************ Test functions for the foreign function interface **************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
#ifndef NO_FFI_TEST
typedef struct ffiTestPoint2 {
	int x;
	int y;
} ffiTestPoint2;

typedef struct ffiTestPoint4 {
	int x;
	int y;
	int z;
	int w;
} ffiTestPoint4;

#pragma export on
EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4);
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4);
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4);
EXPORT(float) ffiTestFloats(float f1, float f2);
EXPORT(double) ffiTestDoubles(double d1, double d2);
EXPORT(char *) ffiPrintString(char *string);
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2);
#pragma export off


/* test passing characters */
EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4) {
	printf("4 characters came in as\nc1 = %c (%x)\nc2 = %c (%x)\nc3 = %c (%x)\nc4 = %c (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

/* test passing shorts */
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4) {
	printf("4 shorts came in as\ns1 = %d (%x)\ns2 = %d (%x)\ns3 = %d (%x)\ns4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

/* test passing ints */
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4) {
	printf("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return c1+c2;
}

/* test passing and returning floats */
EXPORT(float) ffiTestFloats(float f1, float f2) {
	printf("The two floats are %f and %f\n", f1, f2);
	return (float) (f1 + f2);
}

/* test passing and returning doubles */
EXPORT(double) ffiTestDoubles(double d1, double d2) {
	printf("The two floats are %f and %f\n", (float)d1, (float)d2);
	return d1+d2;
}

/* test passing and returning strings */
EXPORT(char*) ffiPrintString(char *string) {
	printf("%s\n", string);
	return string;
}

/* test passing and returning 64bit structures */
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2) {
	ffiTestPoint2 result;
	printf("pt1.x = %d\npt1.y = %d\npt2.x = %d\npt2.y = %d\n",
			pt1.x, pt1.y, pt2.x, pt2.y);
	result.x = pt1.x + pt2.x;
	result.y = pt1.y + pt2.y;
	return result;
}

/* test passing and returning large structures */
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2) {
	ffiTestPoint4 result;
	printf("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
			pt1.x, pt1.y, pt1.z, pt1.w);
	printf("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
			pt2.x, pt2.y, pt2.z, pt2.w);
	result.x = pt1.x + pt2.x;
	result.y = pt1.y + pt2.y;
	result.z = pt1.z + pt2.z;
	result.w = pt1.w + pt2.w;
	return result;
}

/* test passing and returning pointers */
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2) {
	ffiTestPoint4 *result;
	printf("pt1.x = %d\npt1.y = %d\npt1.z = %d\npt1.w = %d\n",
			pt1->x, pt1->y, pt1->z, pt1->w);
	printf("pt2.x = %d\npt2.y = %d\npt2.z = %d\npt2.w = %d\n",
			pt2->x, pt2->y, pt2->z, pt2->w);
	result = (ffiTestPoint4*) malloc(sizeof(ffiTestPoint4));
	result->x = pt1->x + pt2->x;
	result->y = pt1->y + pt2->y;
	result->z = pt1->z + pt2->z;
	result->w = pt1->w + pt2->w;
	return result;
}

/* test passing and returning longlongs */
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2) {
	return i1 + i2;
}

#endif /* NO_FFI_TEST */
#endif
