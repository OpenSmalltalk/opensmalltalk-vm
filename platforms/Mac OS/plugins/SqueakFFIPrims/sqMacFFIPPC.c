/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqMacFFIPPC.c
*   CONTENT: Mac/PPC specific support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqMacFFIPPC.c,v 1.3 2002/11/18 19:09:23 johnmci Exp $
*
*   NOTES:
*
*****************************************************************************/
#include "sq.h"
#include "sqFFI.h"

/* note: LONGLONG is usually declared by universal headers */
#ifndef LONGLONG
#define LONGLONG long long
#endif

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
#define ARG_CHECK() if(gpRegCount >= GP_MAX_REGS && ffiStackIndex >= FFI_MAX_STACK) return primitiveFail();
#define ARG_PUSH(value) { \
	ARG_CHECK(); \
	if(gpRegCount < GP_MAX_REGS) GPRegs[gpRegCount++] = value; \
	ffiStack[ffiStackIndex++] = value; \
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
	ARG_PUSH(((int*)(&value))[1]);
	ARG_PUSH(((int*)(&value))[0]);
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
	return floatReturnValue;
}

/*  ffiLongLongResultLow:
	Return the low 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultLow(void)
{
	return ((int*) &longReturnValue)[1];
}

/*  ffiLongLongResultHigh:
	Return the high 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultHigh(void)
{
	return ((int*) &longReturnValue)[0];
}

/*  ffiStoreStructure:
	Store the structure result of a previous ffi call into the given address. */
int ffiStoreStructure(int address, int structSize)
{
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
#else
asm int ffiCallAddressOf(int);

#if TARGET_CPU_PPC
asm int ffiCallAddressOf(int addr) {
	/* Save link register */
	mflr r0
	stw r0, 8(SP)
    mfcr r0		/* save CCR  */
    stw r0,4(sp)

	/* get stack index and preserve it for copying stuff later */
	lwz r4, ffiStackIndex(RTOC)

	/* compute frame size */
	rlwinm r5, r4, 2, 0, 29  /* ffiStackIndex words to bytes (e.g., "slwi r5, r4, 2") */
	addi r5, r5, 24+15 	/* linkage area */
    rlwinm r5,r5,0,0,27 	/* JMM round up to quad word*/
	neg  r5, r5     /* stack goes down */

	/* adjust stack frame */
	stwux SP, SP, r5

	/* load the stack frame area */
	/* note: r4 == ffiStackIndex */
	addi r5, SP, 24         /* dst = SP + linkage area */
	lwz r6, ffiStack(RTOC)  /* src = ffiStack */
	li r7, 0                /* i = 0 */
	b nextItem
copyItem:
	rlwinm r8, r7, 2, 0, 29 /* r8 = i << 2 (e.g., "slwi r8, r7, 2") */
	lwzx r0, r6, r8         /* r0 = ffiStack[r8] */
	addi r7, r7, 1          /* i = i + 1 */
	stwx r0, r5, r8         /* dst[r8] = r0 */
nextItem:
	cmpw r7, r4             /* i < ffiStackIndex ? */
	blt copyItem

	/* Keep addr in GPR0 so we can load all regs beforehand */
	mr r0, r3

	/* load all the floating point registers */
	lwz r3, fpRegCount
	lwz r12, FPRegs(RTOC)
	cmpwi r3, 0     /* skip all fpregs if no FP values used */
	beq _0_fpregs
	cmpwi r3, 8
	blt _7_fpregs   /* skip last N fpregs if unused */
_all_fpregs:
	lfd  fp8, 56(r12)
	lfd  fp9, 64(r12)
	lfd fp10, 72(r12)
	lfd fp11, 80(r12)
	lfd fp12, 88(r12)
	lfd fp13, 96(r12)
_7_fpregs:
	lfd  fp1,  0(r12)
	lfd  fp2,  8(r12)
	lfd  fp3, 16(r12)
	lfd  fp4, 24(r12)
	lfd  fp5, 32(r12)
	lfd  fp6, 40(r12)
	lfd  fp7, 48(r12)
_0_fpregs:

	/* load all the general purpose registers */
	lwz  r3, gpRegCount
	lwz  r12, GPRegs(RTOC)
	cmpwi r3, 5
	blt _4_gpregs    /* skip last four gpregs if unused */
_all_gpregs:
	lwz  r7, 16(r12)
	lwz  r8, 20(r12)
	lwz  r9, 24(r12)
	lwz r10, 28(r12)
_4_gpregs:
	lwz  r3,  0(r12)
	lwz  r4,  4(r12)
	lwz  r5,  8(r12)
	lwz  r6, 12(r12)
_0_gpregs:

	/* go calling out */
	mr r12, r0      /* tvector into GPR12 */
	/* Note: The code below is nearly identical to to what's described in
		"MacOS Runtime Architectures"
		Chapter 2, Listing 2-2, pp. 2-11
	*/
	lwz r0, 0(r12)  /* get entry point */
	stw r2, 20(SP)  /* save GPR2 */
	mtctr r0        /* move entry point into count register */
	lwz r2, 4(r12)  /* new base pointer */
	bctrl           /* jump through count register and link */
	lwz r2, 20(SP)  /* restore GPR2 */
	lwz SP, 0(SP)   /* restore frame */

	/* store the result of the call */
	stw r3, intReturnValue(RTOC)
	lwz r12, longReturnValue(RTOC)
	stw r3, 0(r12)
	stw r4, 4(r12)
	stfd fp1, floatReturnValue(RTOC)

	/* and get out of here */
    lwz r0, 4(sp) 	/*restore CCR */
    mtcrf 0xff,r0                               
	lwz r0, 8(SP)
	mtlr r0
	blr
}
#endif
#endif

int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
	return ffiCallAddressOf(fn);
}
int ffiCallAddressOfWithStructReturn(int fn, int callType, int* structSpec, int specSize)
{
	return ffiCallAddressOf(fn);
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
	return ffiCallAddressOf(fn);
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
