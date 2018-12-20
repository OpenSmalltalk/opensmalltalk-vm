#if __BIG_ENDIAN__
/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqMacFFIPPC.c
*   CONTENT: Mac/PPC specific support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqMacFFIPPC.c 1413 2006-04-10 06:40:23Z johnmci $
*
*   NOTES:

* April 9th, 2006 JMM fix, double was pushed on stack incorrectly, this affected things only when 14 values passed

*
*****************************************************************************/
#include "sq.h"
#include "sqFFI.h"

/* note: LONGLONG is usually declared by universal headers */
#ifndef LONGLONG
#define LONGLONG long long
#endif

#define MAX_PATH PATH_MAX

//#define DEBUGFFI 1

#if defined ( __APPLE__ ) && defined ( __MACH__ )
#define staticIssue 
#else
#define staticIssue static 
#endif 

extern struct VirtualMachine *interpreterProxy;
#define primitiveFail() interpreterProxy->primitiveFail();


#define GP_MAX_REGS 8
#define FP_MAX_REGS 13

/* Values passed in GPR3-GPR10 */
static int GPRegs[8];
/* Nr of GPRegs used so far */
staticIssue int gpRegCount = 0;
/* Values passed in FPR1-FPR13 */
static double FPRegs[13];
/* Nr of FPRegs used so far */
staticIssue int fpRegCount = 0;

/* Max stack size */
#define FFI_MAX_STACK 512
/* The stack used to assemble the arguments for a call */
static int   ffiStack[FFI_MAX_STACK];
/* The stack pointer while filling the stack */
staticIssue int   ffiStackIndex = 0;
/* The area for temporarily allocated strings */
static char *ffiTempStrings[FFI_MAX_STACK];
/* The number of temporarily allocated strings */
static int   ffiTempStringCount = 0;

/* The return values for calls */
staticIssue int      intReturnValue;
static LONGLONG longReturnValue;
static double   floatReturnValue;
static int *structReturnValue = NULL;

/**************************************************************/

#if DEBUGFFI
# define DPRINTF(ARGS)	printf ARGS; fflush(stdout)
#else
# define DPRINTF(ARGS)
#endif

#define ARG_CHECK() if(gpRegCount >= GP_MAX_REGS && ffiStackIndex >= FFI_MAX_STACK) return primitiveFail();
#define ARG_PUSH(value) { \
	ARG_CHECK(); \
	if(gpRegCount < GP_MAX_REGS) GPRegs[gpRegCount++] = value; \
	DPRINTF(("ARG_PUSH %i (%08x)\n", ffiStackIndex, value)); \
	ffiStack[ffiStackIndex++] = value; \
}

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
	ffiStackIndex = 0;
	gpRegCount = 0;
	fpRegCount = 0;
	floatReturnValue = 0.0;
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
	int data = (int) malloc(byteSize);
	DPRINTF(("ffiAlloc (%08x)\n",data));
	return data;
}

int ffiFree(sqIntptr_t ptr)
{
	DPRINTF(("ffiFree (%08x)\n",ptr));
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

int ffiPushSignedLongLong(int low, int high)
{
	ARG_PUSH(high);
	ARG_PUSH(low);
	return 1;
}

int ffiPushUnsignedLongLong(int low, int high) 
{ 
	ARG_PUSH(high); 
	ARG_PUSH(low); 
	return 1; 
}

int ffiPushSingleFloat(double value)
{
	float floatValue = (float) value;
	if(fpRegCount < FP_MAX_REGS) {
		/* Still space in FPRegs - so we use the more accurate double value */
		FPRegs[fpRegCount++] = value;
	}
	/* Note: Even for args that are passed in FPRegs 
	   we pass the actual 32bit value in either GPRegs
	   or stack frame for varargs calls. */
	ARG_PUSH(*(int*)(&floatValue));
	return 1;
}

int ffiPushDoubleFloat(double value)
{
	if(fpRegCount < FP_MAX_REGS) {
		/* Still space in FPRegs */
		FPRegs[fpRegCount++] = value;
	}
	/* Note: Even for args that are passed in FPRegs 
	   we pass the actual 64bit value in either GPRegs
	   or stack frame for varargs calls. */
	ARG_PUSH(((int*)(&value))[0]);  //JMM April 9th, 2006 was push 1 push 0, but testing shows it was wrong
	ARG_PUSH(((int*)(&value))[1]);
	return 1;
}

int ffiPushStructureOfLength(int pointer, int *structSpec, int specSize)
{
	int i, typeSpec;
	int *data = (int*) pointer;

	for(i = 0; i<specSize; i++) {
		typeSpec = structSpec[i];
		if(typeSpec & FFIFlagPointer) {
			ARG_PUSH(*data);
			data++;
		} else if(typeSpec & FFIFlagStructure) {
			/* embedded structure */
		} else {
			/* atomic type */
			int atomicType = (typeSpec & FFIAtomicTypeMask) >> FFIAtomicTypeShift;
			switch(atomicType) {
				case FFITypeUnsignedChar:
				case FFITypeUnsignedByte:
					ffiPushUnsignedByte(*(unsigned char*)data);
					break;
				case FFITypeSignedChar:
				case FFITypeSignedByte:
					ffiPushSignedByte(*(signed char*)data);
					break;
				case FFITypeUnsignedShort:
					ffiPushUnsignedShort(*(unsigned short*)data);
					break;
				case FFITypeSignedShort:
					ffiPushSignedShort(*(signed short*)data);
					break;
				case FFITypeUnsignedInt:
					ffiPushUnsignedInt(*(unsigned int*)data);
					break;
				case FFITypeSignedInt:
					ffiPushSignedInt(*(signed int*)data);
					break;
				case FFITypeUnsignedLongLong:
					ffiPushUnsignedLongLong( ((unsigned int*)data)[1], ((unsigned int*)data)[0]);
					break;
				case FFITypeSignedLongLong:
					ffiPushSignedLongLong( ((signed int*)data)[1], ((signed int*)data)[0]);
					break;
				case FFITypeSingleFloat:
					ffiPushSingleFloat( *(float*)data);
					break;
				case FFITypeDoubleFloat:
					{ double fArg;
					  ((int*)&fArg)[0] = ((int*)data)[0];
					  ((int*)&fArg)[1] = ((int*)data)[1];
					  ffiPushDoubleFloat(fArg);
					}
					break;
				default:
					return primitiveFail();
			}
			data = (int*) ((int)data + (typeSpec & FFIStructSizeMask));
		}
	}
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
		/* structs are always returned as pointers to hidden structures */
		int structSize = header & FFIStructSizeMask;
		structReturnValue = malloc(structSize);
		if(!structReturnValue) return 0;
		ARG_PUSH((int)structReturnValue);
	}
	return 1;
}

/*  ffiReturnFloatValue:
	Return the value from a previous ffi call with float return type. */
double ffiReturnFloatValue(void)
{
	DPRINTF(("ffiReturnFloatValue %d\n",floatReturnValue));
	return floatReturnValue;
}

/*  ffiLongLongResultLow:
	Return the low 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultLow(void)
{
	DPRINTF(("ffiLongLongResultLow %i\n",((int*) &longReturnValue)[1]));
	return ((int*) &longReturnValue)[1];
}

/*  ffiLongLongResultHigh:
	Return the high 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultHigh(void)
{
	DPRINTF(("ffiLongLongResultHigh %i\n",((int*) &longReturnValue)[0]));
	return ((int*) &longReturnValue)[0];
}

/*  ffiStoreStructure:
	Store the structure result of a previous ffi call into the given address. */
int ffiStoreStructure(int address, int structSize)
{
	DPRINTF(("ffiStoreStructure\n"));
	if(structReturnValue) {
		memcpy((void*)address, (void*)structReturnValue, structSize);
	} else {
		memcpy((void*)address, (void*)&intReturnValue, structSize);
  	}
  	return 1;
}

/*  ffiCleanup:
	Cleanup after a foreign function call has completed.
	The generic support code only frees the temporarily
	allocated strings. */
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

int  ffiStackLocation=(int) &ffiStack;
int  FPRegsLocation=(int) &FPRegs;
int  GPRegsLocation=(int) &GPRegs;
int  longReturnValueLocation=(int) &longReturnValue;
int  floatReturnValueLocation=(int) &floatReturnValue;
/*****************************************************************************/
/*****************************************************************************/
#if defined ( __APPLE__ ) && defined ( __MACH__ )
extern int ffiCallAddressOf(int);
#endif

static int giLocker;

int ffiCallAddressOfWithPointerReturnx(int fn, int callType)
{
	return ffiCallAddressOf(fn);
}
int ffiCallAddressOfWithStructReturnx(int fn, int callType, int* structSpec, int specSize)
{
	return ffiCallAddressOf(fn);
}

int ffiCallAddressOfWithReturnTypex(int fn, int callType, int typeSpec)
{
	return ffiCallAddressOf(fn);
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
EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8);
EXPORT(float) ffiTestFloats(float f1, float f2);
EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7);
EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13);
EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14);
EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14);
EXPORT(double) ffiTestDoubles(double d1, double d2);
EXPORT(char *) ffiPrintString(char *string);
EXPORT(ffiTestPoint2) ffiTestStruct64(ffiTestPoint2 pt1, ffiTestPoint2 pt2);
EXPORT(ffiTestPoint4) ffiTestStructBig(ffiTestPoint4 pt1, ffiTestPoint4 pt2);
EXPORT(ffiTestPoint4*) ffiTestPointers(ffiTestPoint4 *pt1, ffiTestPoint4 *pt2);
EXPORT(LONGLONG) ffiTestLongLong(LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLong8a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9,  char c10, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2);
EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2);
#pragma export off


/* test passing characters */
EXPORT(char) ffiTestChars(char c1, char c2, char c3, char c4) {
	printf("4 characters came in as\nc1 = %c (%x)\nc2 = %c (%x)\nc3 = %c (%x)\nc4 = %c (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return 'C';
}

/* test passing shorts */
EXPORT(short) ffiTestShorts(short c1, short c2, short c3, short c4) {
	printf("4 shorts came in as\ns1 = %d (%x)\ns2 = %d (%x)\ns3 = %d (%x)\ns4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return -42;
}

/* test passing ints */
EXPORT(int) ffiTestInts(int c1, int c2, int c3, int c4) {
	printf("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4);
	return 42;
}

EXPORT(int) ffiTestInts8(int c1, int c2, int c3, int c4, int c5, int c6, int c7, int c8) {
	printf("4 ints came in as\ni1 = %d (%x)\ni2 = %d (%x)\ni3 = %d (%x)\ni4 = %d (%x)\ni5 = %d (%x)\ni6 = %d (%x)\ni7 = %d (%x)\ni8 = %d (%x)\n", c1, c1, c2, c2, c3, c3, c4, c4, c5, c5, c6, c6, c7, c7, c8, c8);
	return 42;
}


/* test passing and returning floats */
EXPORT(float) ffiTestFloats(float f1, float f2) {
	printf("The two floats are %f and %f\n", f1, f2);
	return (float) (f1 + f2);
}

EXPORT(float) ffiTestFloats7(float f1, float f2, float f3, float f4, float f5, float f6, float f7) {
	printf("The 7 floats are %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7);
}

EXPORT(float) ffiTestFloats13(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13) {
	printf("The 13 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13);
}

EXPORT(float) ffiTestFloats14(float f1, float f2, float f3, float f4, float f5, float f6, float f7, float f8, float f9, float f10, float f11, float f12, float f13, float f14) {
	printf("The 14 floats are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (float) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
}

EXPORT(double) ffiTestDoubles14(double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14) {
	printf("The 14 double are %f %f %f %f %f %f %f %f %f %f %f %f %f\n", f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13);
	return (double) (f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13 + f14);
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

EXPORT(LONGLONG) ffiTestLongLonga1(char c1, LONGLONG i1, LONGLONG i2) {
	return c1 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLonga2(char c1, char c2, LONGLONG i1, LONGLONG i2) {
	return c1 + c2 + i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, LONGLONG i1, LONGLONG i2) {
	return c1+c2+c3+c4+c5+c6+c7+c8+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8a1(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, LONGLONG i1, LONGLONG i2) {
	return c1+c2+c3+c4+c5+c6+c7+c8+c9+i1 + i2;
}

EXPORT(LONGLONG) ffiTestLongLong8a2(char c1, char c2, char c3, char c4, char c5, char c6, char c7, char c8, char c9, char c10, LONGLONG i1, LONGLONG i2) {
	return c1+c2+c3+c4+c5+c6+c7+c8+c9+c10+i1 + i2;
}

#endif /* NO_FFI_TEST */
#endif

