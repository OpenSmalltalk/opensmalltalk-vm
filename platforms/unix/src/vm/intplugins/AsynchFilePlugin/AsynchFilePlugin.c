/* Automatically generated from Squeak on #(18 March 2005 7:42:21 pm) */

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
#include "AsynchFilePlugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
static AsyncFile * asyncFileValueOf(int oop);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
EXPORT(int) moduleUnloaded(char * aModuleName);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveAsyncFileClose(void);
EXPORT(int) primitiveAsyncFileOpen(void);
EXPORT(int) primitiveAsyncFileReadResult(void);
EXPORT(int) primitiveAsyncFileReadStart(void);
EXPORT(int) primitiveAsyncFileWriteResult(void);
EXPORT(int) primitiveAsyncFileWriteStart(void);
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
	"AsynchFilePlugin 18 March 2005 (i)"
#else
	"AsynchFilePlugin 18 March 2005 (e)"
#endif
;
static int sCOAFfn;



/*	Return a pointer to the first byte of the async file record within the given Smalltalk bytes object, or nil if oop is not an async file record. */

static AsyncFile * asyncFileValueOf(int oop) {
	interpreterProxy->success((!((oop & 1))) && ((interpreterProxy->isBytes(oop)) && ((interpreterProxy->slotSizeOf(oop)) == (sizeof(AsyncFile)))));
	if (interpreterProxy->failed()) {
		return null;
	}
	return (AsyncFile *) (oop + 4);
}


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


/*	Initialise the module */

EXPORT(int) initialiseModule(void) {
	sCOAFfn = interpreterProxy->ioLoadFunctionFrom("secCanOpenAsyncFileOfSizeWritable", "SecurityPlugin");
	return asyncFileInit();
}


/*	The module with the given name was just unloaded. 
	Make sure we have no dangling references. */

EXPORT(int) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SecurityPlugin")) == 0) {
		sCOAFfn = 0;
	}
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveAsyncFileClose(void) {
	AsyncFile *f;
	int fh;

	fh = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fh);
	asyncFileClose(f);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveAsyncFileOpen(void) {
	AsyncFile *f;
	int fOop;
	int okToOpen;
	int fileNameSize;
	char *fileName;
	int writeFlag;
	int semaIndex;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	fileName = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	writeFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok */

	fileNameSize = interpreterProxy->slotSizeOf(((int) fileName) - 4);
	if (sCOAFfn != 0) {
		okToOpen =  ((int (*) (char *, int, int)) sCOAFfn)(fileName, fileNameSize, writeFlag);
		if (!(okToOpen)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	fOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(AsyncFile));
	f = asyncFileValueOf(fOop);
	if (!(interpreterProxy->failed())) {
		asyncFileOpen(f, (int)fileName, fileNameSize, writeFlag, semaIndex);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, fOop);
	return null;
}

EXPORT(int) primitiveAsyncFileReadResult(void) {
	AsyncFile *f;
	int count;
	int startIndex;
	int bufferSize;
	int r;
	int bufferPtr;
	int fhandle;
	int buffer;
	int start;
	int num;
	int _return_value;

	fhandle = interpreterProxy->stackValue(3);
	buffer = interpreterProxy->stackValue(2);
	start = interpreterProxy->stackIntegerValue(1);
	num = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fhandle);
	count = num;
	startIndex = start;

	/* in bytes or words */

	bufferSize = interpreterProxy->slotSizeOf(buffer);
	if (interpreterProxy->isWords(buffer)) {
		count = count * 4;
		startIndex = ((startIndex - 1) * 4) + 1;
		bufferSize = bufferSize * 4;
	}
	interpreterProxy->success((startIndex >= 1) && (((startIndex + count) - 1) <= bufferSize));

	/* adjust for zero-origin indexing */

	bufferPtr = ((((int) (interpreterProxy->firstIndexableField(buffer)))) + startIndex) - 1;
	if (!(interpreterProxy->failed())) {
		r = asyncFileReadResult(f, bufferPtr, count);
	}
	_return_value = interpreterProxy->integerObjectOf(r);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(int) primitiveAsyncFileReadStart(void) {
	AsyncFile *f;
	int fHandle;
	int fPosition;
	int count;

	fHandle = interpreterProxy->stackValue(2);
	fPosition = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fHandle);
	asyncFileReadStart(f, fPosition, count);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(int) primitiveAsyncFileWriteResult(void) {
	AsyncFile *f;
	int r;
	int fHandle;
	int _return_value;

	fHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fHandle);
	r =  asyncFileWriteResult(f);
	_return_value = interpreterProxy->integerObjectOf(r);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveAsyncFileWriteStart(void) {
	AsyncFile *f;
	int count;
	int startIndex;
	int bufferSize;
	int bufferPtr;
	int fHandle;
	int fPosition;
	int buffer;
	int start;
	int num;

	fHandle = interpreterProxy->stackValue(4);
	fPosition = interpreterProxy->stackIntegerValue(3);
	buffer = interpreterProxy->stackValue(2);
	start = interpreterProxy->stackIntegerValue(1);
	num = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	f = asyncFileValueOf(fHandle);
	if (interpreterProxy->failed()) {
		return null;
	}
	count = num;
	startIndex = start;

	/* in bytes or words */

	bufferSize = interpreterProxy->slotSizeOf(buffer);
	if (interpreterProxy->isWords(buffer)) {
		count = count * 4;
		startIndex = ((startIndex - 1) * 4) + 1;
		bufferSize = bufferSize * 4;
	}
	interpreterProxy->success((startIndex >= 1) && (((startIndex + count) - 1) <= bufferSize));

	/* adjust for zero-origin indexing */

	bufferPtr = ((((int) (interpreterProxy->firstIndexableField(buffer)))) + startIndex) - 1;
	if (!(interpreterProxy->failed())) {
		asyncFileWriteStart(f, fPosition, bufferPtr, count);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(5);
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


/*	Initialise the module */

EXPORT(int) shutdownModule(void) {
	return asyncFileShutdown();
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* AsynchFilePlugin_exports[][3] = {
	{"AsynchFilePlugin", "primitiveAsyncFileReadResult", (void*)primitiveAsyncFileReadResult},
	{"AsynchFilePlugin", "primitiveAsyncFileWriteStart", (void*)primitiveAsyncFileWriteStart},
	{"AsynchFilePlugin", "primitiveAsyncFileOpen", (void*)primitiveAsyncFileOpen},
	{"AsynchFilePlugin", "initialiseModule", (void*)initialiseModule},
	{"AsynchFilePlugin", "primitiveAsyncFileClose", (void*)primitiveAsyncFileClose},
	{"AsynchFilePlugin", "shutdownModule", (void*)shutdownModule},
	{"AsynchFilePlugin", "primitiveAsyncFileWriteResult", (void*)primitiveAsyncFileWriteResult},
	{"AsynchFilePlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"AsynchFilePlugin", "getModuleName", (void*)getModuleName},
	{"AsynchFilePlugin", "primitiveAsyncFileReadStart", (void*)primitiveAsyncFileReadStart},
	{"AsynchFilePlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

