/* Automatically generated from Squeak on #(19 March 2005 10:09 am) */

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
#include "MIDIPlugin.h"

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
EXPORT(int) primitiveMIDIClosePort(void);
EXPORT(int) primitiveMIDIGetClock(void);
EXPORT(int) primitiveMIDIGetPortCount(void);
EXPORT(int) primitiveMIDIGetPortDirectionality(void);
EXPORT(int) primitiveMIDIGetPortName(void);
EXPORT(int) primitiveMIDIOpenPort(void);
EXPORT(int) primitiveMIDIParameterGet(void);
EXPORT(int) primitiveMIDIParameterGetOrSet(void);
EXPORT(int) primitiveMIDIParameterSet(void);
EXPORT(int) primitiveMIDIRead(void);
EXPORT(int) primitiveMIDIWrite(void);
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
	"MIDIPlugin 19 March 2005 (i)"
#else
	"MIDIPlugin 19 March 2005 (e)"
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
	return midiInit();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveMIDIClosePort(void) {
	int portNum;

	portNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	sqMIDIClosePort(portNum);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}


/*	Return the value of the MIDI clock as a SmallInteger. The range is limited to SmallInteger maxVal / 2 to allow scheduling MIDI events into the future without overflowing a SmallInteger. The sqMIDIGetClock function is assumed to wrap at or before 16r20000000. */

EXPORT(int) primitiveMIDIGetClock(void) {
	int clockValue;
	int _return_value;

	clockValue = (sqMIDIGetClock()) & 536870911;
	_return_value = interpreterProxy->integerObjectOf(clockValue);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveMIDIGetPortCount(void) {
	int n;
	int _return_value;

	n = sqMIDIGetPortCount();
	_return_value = interpreterProxy->integerObjectOf(n);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveMIDIGetPortDirectionality(void) {
	int dir;
	int portNum;
	int _return_value;

	portNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	dir = sqMIDIGetPortDirectionality(portNum);
	_return_value = interpreterProxy->integerObjectOf(dir);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMIDIGetPortName(void) {
	int nameObj;
	char portName[256];
	int sz;
	char * namePtr;
	int portNum;

	portNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	sz = sqMIDIGetPortName(portNum, (int) &portName, 255);
	nameObj = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), sz);
	if (interpreterProxy->failed()) {
		return null;
	}
	namePtr = ((char *) interpreterProxy->firstIndexableField(nameObj));
	memcpy(namePtr, portName, sz);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, nameObj);
	return null;
}

EXPORT(int) primitiveMIDIOpenPort(void) {
	int portNum;
	int semaIndex;
	int clockRate;

	portNum = interpreterProxy->stackIntegerValue(2);
	semaIndex = interpreterProxy->stackIntegerValue(1);
	clockRate = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	sqMIDIOpenPort(portNum, semaIndex, clockRate);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}


/*	read parameter */

EXPORT(int) primitiveMIDIParameterGet(void) {
	int currentValue;
	int whichParameter;
	int _return_value;

	whichParameter = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	currentValue = sqMIDIParameterGet(whichParameter);
	_return_value = interpreterProxy->integerObjectOf(currentValue);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	Backward compatibility */

EXPORT(int) primitiveMIDIParameterGetOrSet(void) {
	if ((interpreterProxy->methodArgumentCount()) == 1) {
		return primitiveMIDIParameterGet();
	} else {
		return primitiveMIDIParameterSet();
	}
}


/*	write parameter */

EXPORT(int) primitiveMIDIParameterSet(void) {
	int whichParameter;
	int newValue;

	whichParameter = interpreterProxy->stackIntegerValue(1);
	newValue = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	sqMIDIParameterSet(whichParameter, newValue);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(int) primitiveMIDIRead(void) {
	int arrayLength;
	int bytesRead;
	int portNum;
	char *array;
	int _return_value;

	portNum = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	array = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	arrayLength = interpreterProxy->byteSizeOf(((int) (array) -4));
	bytesRead = sqMIDIPortReadInto(portNum, arrayLength, ((int) array ));
	_return_value = interpreterProxy->integerObjectOf(bytesRead);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMIDIWrite(void) {
	int arrayLength;
	int bytesWritten;
	int portNum;
	char *array;
	int time;
	int _return_value;

	portNum = interpreterProxy->stackIntegerValue(2);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	array = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	time = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	arrayLength = interpreterProxy->byteSizeOf(((int) (array) -4));
	bytesWritten = sqMIDIPortWriteFromAt(portNum, arrayLength, ((int) array ), time);
	_return_value = interpreterProxy->integerObjectOf(bytesWritten);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
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
	return midiShutdown();
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* MIDIPlugin_exports[][3] = {
	{"MIDIPlugin", "primitiveMIDIGetPortDirectionality", (void*)primitiveMIDIGetPortDirectionality},
	{"MIDIPlugin", "primitiveMIDIParameterGetOrSet", (void*)primitiveMIDIParameterGetOrSet},
	{"MIDIPlugin", "primitiveMIDIWrite", (void*)primitiveMIDIWrite},
	{"MIDIPlugin", "primitiveMIDIClosePort", (void*)primitiveMIDIClosePort},
	{"MIDIPlugin", "primitiveMIDIRead", (void*)primitiveMIDIRead},
	{"MIDIPlugin", "primitiveMIDIParameterSet", (void*)primitiveMIDIParameterSet},
	{"MIDIPlugin", "primitiveMIDIGetPortName", (void*)primitiveMIDIGetPortName},
	{"MIDIPlugin", "shutdownModule", (void*)shutdownModule},
	{"MIDIPlugin", "primitiveMIDIOpenPort", (void*)primitiveMIDIOpenPort},
	{"MIDIPlugin", "primitiveMIDIGetClock", (void*)primitiveMIDIGetClock},
	{"MIDIPlugin", "initialiseModule", (void*)initialiseModule},
	{"MIDIPlugin", "primitiveMIDIGetPortCount", (void*)primitiveMIDIGetPortCount},
	{"MIDIPlugin", "getModuleName", (void*)getModuleName},
	{"MIDIPlugin", "primitiveMIDIParameterGet", (void*)primitiveMIDIParameterGet},
	{"MIDIPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

