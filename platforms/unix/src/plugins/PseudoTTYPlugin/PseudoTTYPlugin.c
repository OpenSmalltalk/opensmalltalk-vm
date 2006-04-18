/* Automatically generated from Squeak on an Array(18 April 2006 11:01:41 am) */

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
#include "PseudoTTYPlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
static AsyncFile * asyncFileValueOf(sqInt oop);
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt msg(char * s);
#pragma export on
EXPORT(sqInt) primPtyClose(void);
EXPORT(sqInt) primPtyForkAndExec(void);
EXPORT(sqInt) primPtyWindowSize(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(sqInt) shutdownModule(void);
#pragma export off
static sqInt sqAssert(sqInt aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"PseudoTTYPlugin 18 April 2006 (i)"
#else
	"PseudoTTYPlugin 18 April 2006 (e)"
#endif
;
static sqInt sCOAFfn;



/*	Return a pointer to the first byte of the async file record within the given Smalltalk bytes object, or nil if oop is not an async file record. */

static AsyncFile * asyncFileValueOf(sqInt oop) {
	interpreterProxy->success((!((oop & 1))) && ((interpreterProxy->isBytes(oop)) && ((interpreterProxy->slotSizeOf(oop)) == (sizeof(AsyncFile)))));
	if (interpreterProxy->failed()) {
		return null;
	}
	return (AsyncFile *) (oop + 4);
}


/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine * getInterpreter(void) {
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static sqInt halt(void) {
	;
}

EXPORT(sqInt) initialiseModule(void) {
	interpreterProxy->ioLoadFunctionFrom("initializeModule", "AsynchFilePlugin");
	return ptyInit();
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(sqInt) primPtyClose(void) {
	AsyncFile *f;
	sqInt fHandle;

	fHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fHandle);
	if (!(interpreterProxy->failed())) {
		ptyClose(f);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primPtyForkAndExec(void) {
	AsyncFile *f;
	sqInt argLen;
	sqInt argIdx;
	sqInt fOop;
	sqInt cmdLen;
	sqInt cmdIdx;
	sqInt cmd;
	sqInt args;
	sqInt semaIndex;

	cmd = interpreterProxy->stackValue(2);
	args = interpreterProxy->stackValue(1);
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(interpreterProxy->isBytes(cmd));
	interpreterProxy->success(interpreterProxy->isPointers(args));
	if (interpreterProxy->failed()) {
		return null;
	}
	cmdIdx = ((int) (interpreterProxy->firstIndexableField(cmd)));

	/* in bytes */

	cmdLen = interpreterProxy->slotSizeOf(cmd);
	argIdx = ((int) (interpreterProxy->firstIndexableField(args)));

	/* in fields */

	argLen = interpreterProxy->slotSizeOf(args);
	fOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(AsyncFile));
	f = asyncFileValueOf(fOop);
	if (!(interpreterProxy->failed())) {
		ptyForkAndExec(f, semaIndex, cmdIdx, cmdLen, argIdx, argLen);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, fOop);
	return null;
}

EXPORT(sqInt) primPtyWindowSize(void) {
	AsyncFile *f;
	sqInt fHandle;
	sqInt cols;
	sqInt rows;

	fHandle = interpreterProxy->stackValue(2);
	cols = interpreterProxy->stackIntegerValue(1);
	rows = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fHandle);
	if (!(interpreterProxy->failed())) {
		ptyWindowSize(f, cols, rows);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter) {
	sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

EXPORT(sqInt) shutdownModule(void) {
	return ptyShutdown();
}

static sqInt sqAssert(sqInt aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* PseudoTTYPlugin_exports[][3] = {
	{"PseudoTTYPlugin", "shutdownModule", (void*)shutdownModule},
	{"PseudoTTYPlugin", "primPtyForkAndExec", (void*)primPtyForkAndExec},
	{"PseudoTTYPlugin", "getModuleName", (void*)getModuleName},
	{"PseudoTTYPlugin", "setInterpreter", (void*)setInterpreter},
	{"PseudoTTYPlugin", "initialiseModule", (void*)initialiseModule},
	{"PseudoTTYPlugin", "primPtyClose", (void*)primPtyClose},
	{"PseudoTTYPlugin", "primPtyWindowSize", (void*)primPtyWindowSize},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

