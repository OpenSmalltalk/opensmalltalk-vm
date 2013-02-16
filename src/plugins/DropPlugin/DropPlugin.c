/* Automatically generated from Squeak on 15 February 2013 7:50:48 pm 
   by VMMaker 4.10.12
 */

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
#include "DropPlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
EXPORT(sqInt) primitiveDropRequestFileHandle(void);
EXPORT(sqInt) primitiveDropRequestFileName(void);
EXPORT(sqInt) setFileAccessCallback(int address);
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
EXPORT(sqInt) shutdownModule(void);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"DropPlugin 15 February 2013 (i)"
#else
	"DropPlugin 15 February 2013 (e)"
#endif
;



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
	return dropInit();
}


/*	Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box. */

EXPORT(sqInt) primitiveDropRequestFileHandle(void) {
    sqInt dropIndex;
    sqInt handleOop;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	dropIndex = interpreterProxy->stackIntegerValue(0);

	/* dropRequestFileHandle needs to return the actual oop returned */

	handleOop = dropRequestFileHandle(dropIndex);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
		interpreterProxy->push(handleOop);
	}
}


/*	Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box. */

EXPORT(sqInt) primitiveDropRequestFileName(void) {
    sqInt dropIndex;
    char *dropName;
    sqInt i;
    sqInt nameLength;
    sqInt nameOop;
    char *namePtr;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	dropIndex = interpreterProxy->stackIntegerValue(0);

	/* dropRequestFileName returns name or NULL on error */

	dropName = dropRequestFileName(dropIndex);
	if (dropName == null) {
		return interpreterProxy->primitiveFail();
	}
	nameLength = strlen(dropName);
	nameOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), nameLength);
	namePtr = interpreterProxy->firstIndexableField(nameOop);
	for (i = 0; i <= (nameLength - 1); i += 1) {
		namePtr[i] = (dropName[i]);
	}
	interpreterProxy->pop(2);
	interpreterProxy->push(nameOop);
}

EXPORT(sqInt) setFileAccessCallback(int address) {
	return sqSecFileAccessCallback((void *) address);
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter) {
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
	return dropShutdown();
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* DropPlugin_exports[][3] = {
	{"DropPlugin", "primitiveDropRequestFileHandle", (void*)primitiveDropRequestFileHandle},
	{"DropPlugin", "setInterpreter", (void*)setInterpreter},
	{"DropPlugin", "shutdownModule", (void*)shutdownModule},
	{"DropPlugin", "primitiveDropRequestFileName", (void*)primitiveDropRequestFileName},
	{"DropPlugin", "setFileAccessCallback", (void*)setFileAccessCallback},
	{"DropPlugin", "initialiseModule", (void*)initialiseModule},
	{"DropPlugin", "getModuleName", (void*)getModuleName},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

