/* Automatically generated from Squeak on {11 December 2012 . 5:56:02 pm} */

static char __buildInfo[] = "Generated on {11 December 2012 . 5:56:02 pm}. Compiled on "__DATE__ ;



#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif

#include "BochsIA32Plugin.h"
#include "sqMemoryAccess.h"
#include "sqMemoryAccess.h"


/*** Constants ***/
#define BaseHeaderSize 4
#define BytesPerOop 4
#define BytesPerWord 4
#define PrimErrBadReceiver 2
#define PrimErrInappropriate 6
#define PrimErrNoMemory 9


/*** Function Prototypes ***/
static void forceStopOnInterrupt(void);
static VirtualMachine * getInterpreter(void);
EXPORT(const char*) getModuleName(void);
static sqInt halt(void);
static sqInt msg(char *s);
EXPORT(sqInt) primitiveDisassembleAtInMemory(void);
EXPORT(sqInt) primitiveErrorAndLog(void);
EXPORT(sqInt) primitiveFlushICacheFromTo(void);
EXPORT(sqInt) primitiveNewCPU(void);
EXPORT(sqInt) primitiveResetCPU(void);
EXPORT(sqInt) primitiveRunInMemoryMinimumAddressReadWrite(void);
EXPORT(sqInt) primitiveSingleStepInMemoryMinimumAddressReadWrite(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
static sqInt sizeField(sqInt rcvr);
static void sqAssert(sqInt aBool);
static sqInt startOfData(sqInt rcvr);


/*** Variables ***/

#if !defined(SQUEAK_BUILTIN_PLUGIN)
static void * (*arrayValueOf)(sqInt oop);
static sqInt (*byteSizeOf)(sqInt oop);
static sqInt (*classArray)(void);
static sqInt (*classString)(void);
static sqInt (*failed)(void);
static void * (*firstIndexableField)(sqInt oop);
static sqInt (*getInterruptPending)(void);
static sqInt (*instantiateClassindexableSize)(sqInt classPointer, sqInt size);
static sqInt (*integerObjectOf)(sqInt value);
static sqInt (*isWordsOrBytes)(sqInt oop);
static sqInt (*pop)(sqInt nItems);
static sqInt (*popthenPush)(sqInt nItems, sqInt oop);
static sqInt (*popRemappableOop)(void);
static sqInt (*positive32BitIntegerFor)(sqInt integerValue);
static sqInt (*positive32BitValueOf)(sqInt oop);
static sqInt (*primitiveFail)(void);
static sqInt (*primitiveFailFor)(sqInt reasonCode);
static sqInt (*pushRemappableOop)(sqInt oop);
static void (*(*setInterruptCheckChain)(void (*aFunction)(void)))() ;
static sqInt (*stackValue)(sqInt offset);
static sqInt (*storePointerofObjectwithValue)(sqInt index, sqInt oop, sqInt valuePointer);
static sqInt (*success)(sqInt aBoolean);
#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */
extern void * arrayValueOf(sqInt oop);
extern sqInt byteSizeOf(sqInt oop);
extern sqInt classArray(void);
extern sqInt classString(void);
extern sqInt failed(void);
extern void * firstIndexableField(sqInt oop);
extern sqInt getInterruptPending(void);
extern sqInt instantiateClassindexableSize(sqInt classPointer, sqInt size);
extern sqInt integerObjectOf(sqInt value);
extern sqInt isWordsOrBytes(sqInt oop);
extern sqInt pop(sqInt nItems);
extern sqInt popthenPush(sqInt nItems, sqInt oop);
extern sqInt popRemappableOop(void);
extern sqInt positive32BitIntegerFor(sqInt integerValue);
extern sqInt positive32BitValueOf(sqInt oop);
extern sqInt primitiveFail(void);
extern sqInt primitiveFailFor(sqInt reasonCode);
extern sqInt pushRemappableOop(sqInt oop);
extern void (*setInterruptCheckChain(void (*aFunction)(void)))() ;
extern sqInt stackValue(sqInt offset);
extern sqInt storePointerofObjectwithValue(sqInt index, sqInt oop, sqInt valuePointer);
extern sqInt success(sqInt aBoolean);

extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"BochsIA32Plugin 11 December 2012 (i)"
#else
	"BochsIA32Plugin 11 December 2012 (e)"
#endif
;


static void
forceStopOnInterrupt(void)
{
	if (getInterruptPending()) {
		forceStopRunning();
	}
}


/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine *
getInterpreter(void)
{
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*)
getModuleName(void)
{
	return moduleName;
}

static sqInt
halt(void)
{
	;
	return 0;
}

static sqInt
msg(char *s)
{
	fprintf(stderr, "\n%s: %s", moduleName, s);
	return 0;
}


/*	cpuAlien <BochsIA32Alien> */
/*	<Integer> */
/*	<Bitmap|ByteArray|WordArray> */
/*	Return an Array of the instruction length and its decompilation as a
	string for the instruction at address in memory.
 */

EXPORT(sqInt)
primitiveDisassembleAtInMemory(void)
{
	unsigned long address;
	void *cpu;
	sqInt cpuAlien;
	sqInt instrLenOrErr;
	sqInt log;
	sqInt logLen;
	sqInt logObj;
	sqInt logObjData;
	char *memory;
	sqInt resultObj;

	address = positive32BitValueOf(stackValue(1));
	success(isWordsOrBytes(stackValue(0)));
	memory = ((char *) (firstIndexableField(stackValue(0))));
	cpuAlien = stackValue(2);
	if (failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	instrLenOrErr = disassembleForAtInSize(cpu, address, memory, byteSizeOf(((sqInt)(long)(memory) - 4)));
	if (instrLenOrErr < 0) {
		primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	log = getlog((&logLen));
	resultObj = instantiateClassindexableSize(classArray(), 2);
	if (resultObj == 0) {
		primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	pushRemappableOop(resultObj);
	logObj = instantiateClassindexableSize(classString(), logLen);
	if (failed()) {
		popRemappableOop();
		primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	logObjData = arrayValueOf(logObj);
	memcpy(logObjData, log, logLen);
	resultObj = popRemappableOop();
	storePointerofObjectwithValue(0, resultObj, integerObjectOf(instrLenOrErr));
	storePointerofObjectwithValue(1, resultObj, logObj);
	if (failed()) {
		return null;
	}
	popthenPush(3, resultObj);
	return null;
}

EXPORT(sqInt)
primitiveErrorAndLog(void)
{
	char *log;
	sqInt logLen;
	sqInt logObj;
	char *logObjData;
	sqInt resultObj;

	log = getlog((&logLen));
	resultObj = instantiateClassindexableSize(classArray(), 2);
	if (resultObj == 0) {
		primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	storePointerofObjectwithValue(0, resultObj, integerObjectOf(errorAcorn()));
	if (logLen > 0) {
		pushRemappableOop(resultObj);
		logObj = instantiateClassindexableSize(classString(), logLen);
		if (failed()) {
			popRemappableOop();
			primitiveFailFor(PrimErrNoMemory);
			return null;
		}
		resultObj = popRemappableOop();
		logObjData = arrayValueOf(logObj);
		memcpy(logObjData, log, logLen);
		storePointerofObjectwithValue(1, resultObj, logObj);
	}
	popthenPush(1, resultObj);
	if (failed()) {
		return null;
	}
	return null;
}


/*	cpuAlien <BochsIA32Alien> */
/*	<Integer> */
/*	<Integer> */
/*	Flush the icache in the requested range */

EXPORT(sqInt)
primitiveFlushICacheFromTo(void)
{
	void *cpu;
	sqInt cpuAlien;
	unsigned long endAddress;
	unsigned long startAddress;

	startAddress = positive32BitValueOf(stackValue(1));
	endAddress = positive32BitValueOf(stackValue(0));
	cpuAlien = stackValue(2);
	if (failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	flushICacheFromTo(cpu, startAddress, endAddress);
	if (failed()) {
		return null;
	}
	pop(2);
	return null;
}

EXPORT(sqInt)
primitiveNewCPU(void)
{
	void *cpu;

	cpu = newCPU();
	if (cpu == 0) {
		primitiveFail();
		return null;
	}
	popthenPush(1, positive32BitIntegerFor(((unsigned long) cpu)));
	if (failed()) {
		return null;
	}
	return null;
}

EXPORT(sqInt)
primitiveResetCPU(void)
{
	void *cpu;
	sqInt cpuAlien;
	sqInt maybeErr;

	cpuAlien = stackValue(0);
	if (failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	maybeErr = resetCPU(cpu);
	if (maybeErr != 0) {
		primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (failed()) {
		return null;
	}
	popthenPush(1, cpuAlien);
	return null;
}


/*	cpuAlien <BochsIA32Alien> */
/*	<Bitmap|ByteArray|WordArray> */
/*	<Integer> */
/*	<Integer> */
/*	Run the cpu using the first argument as the memory and the following
	arguments defining valid addresses, running until it halts or hits an
	exception. 
 */

EXPORT(sqInt)
primitiveRunInMemoryMinimumAddressReadWrite(void)
{
	void *cpu;
	sqInt cpuAlien;
	sqInt maybeErr;
	char *memory;
	unsigned long minAddress;
	unsigned long minWriteMaxExecAddress;

	success(isWordsOrBytes(stackValue(2)));
	memory = ((char *) (firstIndexableField(stackValue(2))));
	minAddress = positive32BitValueOf(stackValue(1));
	minWriteMaxExecAddress = positive32BitValueOf(stackValue(0));
	cpuAlien = stackValue(3);
	if (failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	prevInterruptCheckChain = setInterruptCheckChain(forceStopOnInterrupt);
	if (prevInterruptCheckChain == (forceStopOnInterrupt)) {
		prevInterruptCheckChain == 0;
	}
	maybeErr = runCPUInSizeMinAddressReadWrite(cpu, memory, byteSizeOf(((sqInt)(long)(memory) - 4)), minAddress, minWriteMaxExecAddress);
	setInterruptCheckChain(prevInterruptCheckChain);
	if (maybeErr != 0) {
		primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (failed()) {
		return null;
	}
	popthenPush(4, cpuAlien);
	return null;
}


/*	cpuAlien <BochsIA32Alien> */
/*	<Bitmap|ByteArray|WordArray> */
/*	<Integer> */
/*	<Integer> */
/*	Single-step the cpu using the first argument as the memory and the
	following arguments defining valid addresses.
 */

EXPORT(sqInt)
primitiveSingleStepInMemoryMinimumAddressReadWrite(void)
{
	void *cpu;
	sqInt cpuAlien;
	sqInt maybeErr;
	char *memory;
	unsigned long minAddress;
	unsigned long minWriteMaxExecAddress;

	success(isWordsOrBytes(stackValue(2)));
	memory = ((char *) (firstIndexableField(stackValue(2))));
	minAddress = positive32BitValueOf(stackValue(1));
	minWriteMaxExecAddress = positive32BitValueOf(stackValue(0));
	cpuAlien = stackValue(3);
	if (failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	maybeErr = singleStepCPUInSizeMinAddressReadWrite(cpu, memory, byteSizeOf(((sqInt)(long)(memory) - 4)), minAddress, minWriteMaxExecAddress);
	if (maybeErr != 0) {
		primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (failed()) {
		return null;
	}
	popthenPush(4, cpuAlien);
	return null;
}


/*	Note: This is coded so that it can be run in Squeak. */

EXPORT(sqInt)
setInterpreter(struct VirtualMachine*anInterpreter)
{
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = ((interpreterProxy->majorVersion()) == (VM_PROXY_MAJOR))
	 && ((interpreterProxy->minorVersion()) >= (VM_PROXY_MINOR));
	if (ok) {
		
#if !defined(SQUEAK_BUILTIN_PLUGIN)
		arrayValueOf = interpreterProxy->arrayValueOf;
		byteSizeOf = interpreterProxy->byteSizeOf;
		classArray = interpreterProxy->classArray;
		classString = interpreterProxy->classString;
		failed = interpreterProxy->failed;
		firstIndexableField = interpreterProxy->firstIndexableField;
		getInterruptPending = interpreterProxy->getInterruptPending;
		instantiateClassindexableSize = interpreterProxy->instantiateClassindexableSize;
		integerObjectOf = interpreterProxy->integerObjectOf;
		isWordsOrBytes = interpreterProxy->isWordsOrBytes;
		pop = interpreterProxy->pop;
		popthenPush = interpreterProxy->popthenPush;
		popRemappableOop = interpreterProxy->popRemappableOop;
		positive32BitIntegerFor = interpreterProxy->positive32BitIntegerFor;
		positive32BitValueOf = interpreterProxy->positive32BitValueOf;
		primitiveFail = interpreterProxy->primitiveFail;
		primitiveFailFor = interpreterProxy->primitiveFailFor;
		pushRemappableOop = interpreterProxy->pushRemappableOop;
		setInterruptCheckChain = interpreterProxy->setInterruptCheckChain;
		stackValue = interpreterProxy->stackValue;
		storePointerofObjectwithValue = interpreterProxy->storePointerofObjectwithValue;
		success = interpreterProxy->success;
#endif /* !defined(SQUEAK_BUILTIN_PLUGIN) */;
	}
	return ok;
}


/*	Answer the first field of rcvr which is assumed to be an Alien of at least
	8 bytes
 */

static sqInt
sizeField(sqInt rcvr)
{
	return longAt(rcvr + BaseHeaderSize);
}

static void
sqAssert(sqInt aBool)
{
	/* missing DebugCode */;
}


/*	<Alien oop> ^<Integer> */
/*	Answer the start of rcvr's data. For direct aliens this is the address of
	the second field. For indirect and pointer aliens it is what the second
	field points to. */

static sqInt
startOfData(sqInt rcvr)
{
	return ((longAt(rcvr + BaseHeaderSize)) > 0
		? (rcvr + BaseHeaderSize) + BytesPerOop
		: longAt((rcvr + BaseHeaderSize) + BytesPerOop));
}


#ifdef SQUEAK_BUILTIN_PLUGIN

void* BochsIA32Plugin_exports[][3] = {
	{"BochsIA32Plugin", "getModuleName", (void*)getModuleName},
	{"BochsIA32Plugin", "primitiveDisassembleAtInMemory", (void*)primitiveDisassembleAtInMemory},
	{"BochsIA32Plugin", "primitiveErrorAndLog", (void*)primitiveErrorAndLog},
	{"BochsIA32Plugin", "primitiveFlushICacheFromTo", (void*)primitiveFlushICacheFromTo},
	{"BochsIA32Plugin", "primitiveNewCPU", (void*)primitiveNewCPU},
	{"BochsIA32Plugin", "primitiveResetCPU", (void*)primitiveResetCPU},
	{"BochsIA32Plugin", "primitiveRunInMemoryMinimumAddressReadWrite", (void*)primitiveRunInMemoryMinimumAddressReadWrite},
	{"BochsIA32Plugin", "primitiveSingleStepInMemoryMinimumAddressReadWrite", (void*)primitiveSingleStepInMemoryMinimumAddressReadWrite},
	{"BochsIA32Plugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};

#endif /* ifdef SQ_BUILTIN_PLUGIN */
