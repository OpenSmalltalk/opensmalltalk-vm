/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqWin32FFI.c
*   CONTENT: Win32 support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: sqWin32FFI.c,v 1.1 2002/05/04 23:20:28 andreasraab Exp $
*
*   NOTES:
*
*****************************************************************************/
#include "sq.h"
#include "sqFFI.h"

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
static int   ffiArgs[FFI_MAX_ARGS];
/* The stack pointer while filling the stack */
static int   ffiArgIndex = 0;
/* The area for temporarily allocated strings */
static char *ffiTempStrings[FFI_MAX_ARGS];
/* The number of temporarily allocated strings */
static int   ffiTempStringCount = 0;

/* The return values for calls */
volatile static int      intReturnValue;
volatile static int      intReturnValue2;
volatile static double   floatReturnValue;
static void*    structReturnValue;

#define ARG_CHECK() if(ffiArgIndex >= FFI_MAX_ARGS) return primitiveFail();
#define ARG_PUSH(value) { ARG_CHECK(); ffiArgs[ffiArgIndex++] = value; }

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

int ffiFree(int ptr)
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
int oldSP;
int oldBP;
int newSP;
int newBP;

/*  ffiCallAddress:
	Perform the actual function call. */
int ffiCallAddress(int fn)
{
   {
     FILE *f = fopen("ffi.log","at");
     fprintf(f, "%x",fn);
     fflush(f);
     fclose(f);
   }
#ifdef _MSC_VER
	__asm {
		push ebx
		mov ebx, fn
		push ecx
		push edx
		push edi
		push esi
		push ebp
		/* mark the frame */
		mov ebp, esp
		/* alloca() ffiStackIndex size bytes */
		mov ecx, ffiArgIndex
		shl ecx, 2
		sub esp, ecx
		/* copy stack */
		mov edi, esp
		lea esi, ffiArgs
		shr ecx, 2
		cld
		rep movsd
		/* go calling */
		call ebx
		/* restore frame */
		mov esp, ebp
		/* store the return values */
		mov intReturnValue, eax
		mov intReturnValue2, edx
		fstp floatReturnValue
		/* restore register values */
		pop ebp
		pop esi
		pop edi
		pop edx
		pop ecx
		pop ebx
		/* done */
	}
#endif
#ifdef __GNUC__
	asm("
	  movl %%ebp, _oldBP
	  movl %%esp, _oldSP
		pushl %%ebx;
		pushl %%ecx;
		pushl %%edx;
		pushl %%edi;
		pushl %%esi;
		pushl %%ebp;
		/* mark the frame */
		movl %%esp, %%ebp
		/* alloca() ffiStackIndex size bytes */
		movl _ffiArgIndex, %%ecx;
		shll $2, %%ecx;
		subl %%ecx, %%esp
		/* copy stack */
		movl %%esp, %%edi;
		leal _ffiArgs, %%esi;
		shrl $2, %%ecx;
		cld;
		rep movsl;
		/* go calling */
		call *%%ebx
		/* restore frame */
		movl %%ebp, %%esp
		/* store the return values */
		movl %%eax, _intReturnValue
		movl %%edx, _intReturnValue2
		fstpl _floatReturnValue
		/* restore register values */
		popl %%ebp
		popl %%esi
		popl %%edi
		popl %%edx
		popl %%ecx
		popl %%ebx
movl %%ebp, _newBP
movl %%esp, _newSP
		": /* no outputs */ : "ebx" (fn) : "eax" /* clobbered registers */);
		/* done */
#endif
   {
     FILE *f = fopen("ffi.log","at");
     fprintf(f, "...ok\n");
     if(oldBP != newBP || oldSP != newSP) {
       fprintf(f,"oldSP=%x, oldBP=%x\nnewSP=%x, newBP=%x\n",oldSP, oldBP,newSP,newBP);
     }
       fprintf(f,"SP=%x, BP=%x\n",newSP,newBP);
     fflush(f);
     fclose(f);
   }

	return intReturnValue;
}

int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
	return ffiCallAddress(fn);
}
int ffiCallAddressOfWithStructReturn(int fn, int callType, int* structSpec, int specSize)
{
	return ffiCallAddress(fn);
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
	return ffiCallAddress(fn);
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
