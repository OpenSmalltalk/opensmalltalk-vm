/* Automatically generated from Squeak on #(18 March 2005 7:42:40 pm) */

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
#include "JoystickTabletPlugin.h"

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
EXPORT(int) primitiveGetTabletParameters(void);
EXPORT(int) primitiveReadJoystick(void);
EXPORT(int) primitiveReadTablet(void);
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
	"JoystickTabletPlugin 18 March 2005 (i)"
#else
	"JoystickTabletPlugin 18 March 2005 (e)"
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
	return joystickInit();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Get information on the pen tablet attached to this machine. Fail if there is no tablet. If successful, the result is an array of integers; see the Smalltalk call on this primitive for its interpretation. */

EXPORT(int) primitiveGetTabletParameters(void) {
	int * resultPtr;
	int resultSize;
	int result;
	int cursorIndex;

	cursorIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	resultSize = tabletResultSize();
	result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classBitmap(), resultSize);
	resultPtr = (int *) interpreterProxy->firstIndexableField(result);
	interpreterProxy->success(tabletGetParameters(cursorIndex, resultPtr));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, result);
	return null;
}


/*	Read an input word from the joystick with the given index. */

EXPORT(int) primitiveReadJoystick(void) {
	int index;
	int _return_value;

	index = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->positive32BitIntegerFor((joystickRead(index)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	Get the current state of the cursor of the pen tablet specified by my argument. Fail if there is no tablet. If successful, the result is an array of integers; see the Smalltalk call on this primitive for its interpretation. */

EXPORT(int) primitiveReadTablet(void) {
	int * resultPtr;
	int resultSize;
	int result;
	int cursorIndex;

	cursorIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	resultSize = tabletResultSize();
	result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classBitmap(), resultSize);
	resultPtr = (int *) interpreterProxy->firstIndexableField(result);
	interpreterProxy->success(tabletRead(cursorIndex, resultPtr));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, result);
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
	return joystickShutdown();
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* JoystickTabletPlugin_exports[][3] = {
	{"JoystickTabletPlugin", "shutdownModule", (void*)shutdownModule},
	{"JoystickTabletPlugin", "initialiseModule", (void*)initialiseModule},
	{"JoystickTabletPlugin", "primitiveReadJoystick", (void*)primitiveReadJoystick},
	{"JoystickTabletPlugin", "primitiveReadTablet", (void*)primitiveReadTablet},
	{"JoystickTabletPlugin", "getModuleName", (void*)getModuleName},
	{"JoystickTabletPlugin", "primitiveGetTabletParameters", (void*)primitiveGetTabletParameters},
	{"JoystickTabletPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

