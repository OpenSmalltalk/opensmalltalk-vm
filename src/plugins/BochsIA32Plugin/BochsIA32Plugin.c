/* Automatically generated from Squeak on {26 November 2012 . 4:09:30 pm} */

static char __buildInfo[] = "Generated on {26 November 2012 . 4:09:30 pm}. Compiled on "__DATE__ ;



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

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"BochsIA32Plugin 26 November 2012 (i)"
#else
	"BochsIA32Plugin 26 November 2012 (e)"
#endif
;


static void
forceStopOnInterrupt(void)
{
	if (interpreterProxy->getInterruptPending()) {
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

	address = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(interpreterProxy->stackValue(0)));
	memory = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	cpuAlien = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	instrLenOrErr = disassembleForAtInSize(cpu, address, memory, interpreterProxy->byteSizeOf(((sqInt)(long)(memory) - 4)));
	if (instrLenOrErr < 0) {
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	log = getlog((&logLen));
	resultObj = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	if (resultObj == 0) {
		interpreterProxy->primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	interpreterProxy->pushRemappableOop(resultObj);
	logObj = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), logLen);
	if (interpreterProxy->failed()) {
		interpreterProxy->popRemappableOop();
		interpreterProxy->primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	logObjData = interpreterProxy->arrayValueOf(logObj);
	memcpy(logObjData, log, logLen);
	resultObj = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, resultObj, interpreterProxy->integerObjectOf(instrLenOrErr));
	interpreterProxy->storePointerofObjectwithValue(1, resultObj, logObj);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, resultObj);
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
	resultObj = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	if (resultObj == 0) {
		interpreterProxy->primitiveFailFor(PrimErrNoMemory);
		return null;
	}
	interpreterProxy->storePointerofObjectwithValue(0, resultObj, interpreterProxy->integerObjectOf(errorAcorn()));
	if (logLen > 0) {
		interpreterProxy->pushRemappableOop(resultObj);
		logObj = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), logLen);
		if (interpreterProxy->failed()) {
			interpreterProxy->popRemappableOop();
			interpreterProxy->primitiveFailFor(PrimErrNoMemory);
			return null;
		}
		resultObj = interpreterProxy->popRemappableOop();
		logObjData = interpreterProxy->arrayValueOf(logObj);
		memcpy(logObjData, log, logLen);
		interpreterProxy->storePointerofObjectwithValue(1, resultObj, logObj);
	}
	interpreterProxy->popthenPush(1, resultObj);
	if (interpreterProxy->failed()) {
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

	startAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	endAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(0));
	cpuAlien = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	flushICacheFromTo(cpu, startAddress, endAddress);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt)
primitiveNewCPU(void)
{
	void *cpu;

	cpu = newCPU();
	if (cpu == 0) {
		interpreterProxy->primitiveFail();
		return null;
	}
	interpreterProxy->popthenPush(1, interpreterProxy->positive32BitIntegerFor(((unsigned long) cpu)));
	if (interpreterProxy->failed()) {
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

	cpuAlien = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	maybeErr = resetCPU(cpu);
	if (maybeErr != 0) {
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, cpuAlien);
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

	interpreterProxy->success(interpreterProxy->isWordsOrBytes(interpreterProxy->stackValue(2)));
	memory = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	minAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	minWriteMaxExecAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(0));
	cpuAlien = interpreterProxy->stackValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	prevInterruptCheckChain = interpreterProxy->setInterruptCheckChain(forceStopOnInterrupt);
	if (prevInterruptCheckChain == (forceStopOnInterrupt)) {
		prevInterruptCheckChain == 0;
	}
	maybeErr = runCPUInSizeMinAddressReadWrite(cpu, memory, interpreterProxy->byteSizeOf(((sqInt)(long)(memory) - 4)), minAddress, minWriteMaxExecAddress);
	interpreterProxy->setInterruptCheckChain(prevInterruptCheckChain);
	if (maybeErr != 0) {
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, cpuAlien);
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

	interpreterProxy->success(interpreterProxy->isWordsOrBytes(interpreterProxy->stackValue(2)));
	memory = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	minAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(1));
	minWriteMaxExecAddress = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(0));
	cpuAlien = interpreterProxy->stackValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (((cpu = ((longAt(cpuAlien + BaseHeaderSize)) > 0
	? (cpuAlien + BaseHeaderSize) + BytesPerOop
	: longAt((cpuAlien + BaseHeaderSize) + BytesPerOop)))) == 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadReceiver);
		return null;
	}
	maybeErr = singleStepCPUInSizeMinAddressReadWrite(cpu, memory, interpreterProxy->byteSizeOf(((sqInt)(long)(memory) - 4)), minAddress, minWriteMaxExecAddress);
	if (maybeErr != 0) {
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
		return null;
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, cpuAlien);
	return null;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt)
setInterpreter(struct VirtualMachine*anInterpreter)
{
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
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
