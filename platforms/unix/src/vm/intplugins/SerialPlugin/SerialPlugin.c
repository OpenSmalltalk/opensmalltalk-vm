/* Automatically generated from Squeak on #(18 March 2005 7:42:45 pm) */

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
#include "SerialPlugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveSerialPortClose(void);
EXPORT(int) primitiveSerialPortOpen(void);
EXPORT(int) primitiveSerialPortRead(void);
EXPORT(int) primitiveSerialPortWrite(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off
static int sqAssert(int aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SerialPlugin 18 March 2005 (i)"
#else
	"SerialPlugin 18 March 2005 (e)"
#endif
;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int halt(void) {
	;
}

EXPORT(int) initialiseModule(void) {
	return serialPortInit();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveSerialPortClose(void) {
	int portNum;

	portNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	serialPortClose(portNum);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveSerialPortOpen(void) {
	int portNum;
	int baudRate;
	int stopBitsType;
	int parityType;
	int dataBits;
	int inFlowControl;
	int outFlowControl;
	int xOnChar;
	int xOffChar;

	portNum = interpreterProxy->stackIntegerValue(8);
	baudRate = interpreterProxy->stackIntegerValue(7);
	stopBitsType = interpreterProxy->stackIntegerValue(6);
	parityType = interpreterProxy->stackIntegerValue(5);
	dataBits = interpreterProxy->stackIntegerValue(4);
	inFlowControl = interpreterProxy->stackIntegerValue(3);
	outFlowControl = interpreterProxy->stackIntegerValue(2);
	xOnChar = interpreterProxy->stackIntegerValue(1);
	xOffChar = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	serialPortOpen(
			portNum, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(9);
	return null;
}

EXPORT(int) primitiveSerialPortRead(void) {
	int arrayPtr;
	int bytesRead;
	int portNum;
	char *array;
	int startIndex;
	int count;
	int _return_value;

	portNum = interpreterProxy->stackIntegerValue(3);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	array = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success((startIndex >= 1) && (((startIndex + count) - 1) <= (interpreterProxy->byteSizeOf(((int) (array) -4)))));
	arrayPtr = ((((int) array )) + startIndex) - 1;

	/* adjust for zero-origin indexing */

	bytesRead = serialPortReadInto( portNum, count, arrayPtr);
	_return_value = interpreterProxy->integerObjectOf(bytesRead);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(int) primitiveSerialPortWrite(void) {
	int arrayPtr;
	int bytesWritten;
	int portNum;
	char *array;
	int startIndex;
	int count;
	int _return_value;

	portNum = interpreterProxy->stackIntegerValue(3);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	array = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success((startIndex >= 1) && (((startIndex + count) - 1) <= (interpreterProxy->byteSizeOf(((int) (array) -4)))));
	if (!(interpreterProxy->failed())) {
		arrayPtr = ((((int) array )) + startIndex) - 1;
		bytesWritten = serialPortWriteFrom(portNum, count, arrayPtr);
	}
	_return_value = interpreterProxy->integerObjectOf(bytesWritten);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
	int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

EXPORT(int) shutdownModule(void) {
	return serialPortShutdown();
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SerialPlugin_exports[][3] = {
	{"SerialPlugin", "setInterpreter", (void*)setInterpreter},
	{"SerialPlugin", "primitiveSerialPortRead", (void*)primitiveSerialPortRead},
	{"SerialPlugin", "primitiveSerialPortClose", (void*)primitiveSerialPortClose},
	{"SerialPlugin", "primitiveSerialPortWrite", (void*)primitiveSerialPortWrite},
	{"SerialPlugin", "getModuleName", (void*)getModuleName},
	{"SerialPlugin", "primitiveSerialPortOpen", (void*)primitiveSerialPortOpen},
	{"SerialPlugin", "initialiseModule", (void*)initialiseModule},
	{"SerialPlugin", "shutdownModule", (void*)shutdownModule},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

