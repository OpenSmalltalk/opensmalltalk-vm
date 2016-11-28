/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqWin32FFI.c
*   CONTENT: Win32 support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*
*****************************************************************************/
#include <windows.h>
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
int oldSP;
int oldBP;
int newSP;
int newBP;

/*  ffiCallAddress:
	Perform the actual function call. */
int ffiCallAddress(int fn)
{
#if 0
   {
     FILE *f = fopen("ffi.log","at");
     fprintf(f, "%x",fn);
     fflush(f);
     fclose(f);
   }
#endif
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
	asm(
	  "movl %%ebp, _oldBP\n\t"
	  "movl %%esp, _oldSP\n\t"
		"pushl %%ebx\n\t"
		"pushl %%ecx\n\t"
		"pushl %%edx\n\t"
		"pushl %%edi\n\t"
		"pushl %%esi\n\t"
		"pushl %%ebp\n\t"
		/* mark the frame */
		"movl %%esp, %%ebp\n\t"
		/* alloca() ffiStackIndex size bytes */
		"movl _ffiArgIndex, %%ecx\n\t"
		"shll $2, %%ecx\n\t"
		"subl %%ecx, %%esp\n\t"
		/* copy stack */
		"movl %%esp, %%edi\n\t"
		"leal _ffiArgs, %%esi\n\t"
		"shrl $2, %%ecx\n\t"
		"cld\n\t"
		"rep movsl\n\t"
		/* go calling */
		"call *%%ebx\n\t"
		/* restore frame */
		"movl %%ebp, %%esp\n\t"
		/* store the return values */
		"movl %%eax, _intReturnValue\n\t"
		"movl %%edx, _intReturnValue2\n\t"
		"fstpl _floatReturnValue\n\t"
		/* restore register values */
		"popl %%ebp\n\t"
		"popl %%esi\n\t"
		"popl %%edi\n\t"
		"popl %%edx\n\t"
		"popl %%ecx\n\t"
		"popl %%ebx\n\t"
"movl %%ebp, _newBP\n\t"
"movl %%esp, _newSP\n\t"
		: /* no outputs */ : "ebx" (fn) : "eax" /* clobbered registers */);
		/* done */
#endif
#if 0
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
#endif
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

