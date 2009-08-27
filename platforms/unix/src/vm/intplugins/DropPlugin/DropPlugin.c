/* Automatically generated from Squeak on an Array(26 August 2009 10:00:59 pm)
by VMMaker 3.11.3
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
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt msg(char * s);
static sqInt primitiveDndOutAcceptedType(void);
static sqInt primitiveDndOutSend(sqInt bytes);
static sqInt primitiveDndOutStart(sqInt types);
#pragma export on
EXPORT(sqInt) primitiveDropRequestFileHandle(void);
EXPORT(sqInt) primitiveDropRequestFileName(void);
EXPORT(sqInt) setFileAccessCallback(int address);
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(sqInt) shutdownModule(void);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"DropPlugin 26 August 2009 (i)"
#else
	"DropPlugin 26 August 2009 (e)"
#endif
;



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
	return dropInit();
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

static sqInt primitiveDndOutAcceptedType(void) {
	primitiveparameters("primitiveDndOutAcceptedType", "XXX UNTRANSLATABLE CONSTANT XXX");
	return sqDndOutAcceptedType();
}

static sqInt primitiveDndOutSend(sqInt bytes) {
    sqInt nbytes;

	primitiveparameters("primitiveDndOutSend", "XXX UNTRANSLATABLE CONSTANT XXX");
	nbytes = interpreterProxy->slotSizeOf(cPtrAsOop(bytes));
	sqDndOutSend(bytes, nbytes);
}


/*	Start drag out session. Formats are types for the data separated with NULL. */

static sqInt primitiveDndOutStart(sqInt types) {
    sqInt ntypes;

	primitiveparameters("primitiveDndOutStart", "XXX UNTRANSLATABLE CONSTANT XXX");
	ntypes = interpreterProxy->slotSizeOf(cPtrAsOop(types));
	sqDndOutStart(types, ntypes);
}


/*	Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box. */

EXPORT(sqInt) primitiveDropRequestFileHandle(void) {
    sqInt handleOop;
    sqInt dropIndex;

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
    sqInt nameOop;
    sqInt i;
    char * dropName;
    sqInt nameLength;
    sqInt dropIndex;
    char * namePtr;

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
	return dropShutdown();
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* DropPlugin_exports[][3] = {
	{"DropPlugin", "getModuleName", (void*)getModuleName},
	{"DropPlugin", "shutdownModule", (void*)shutdownModule},
	{"DropPlugin", "setFileAccessCallback", (void*)setFileAccessCallback},
	{"DropPlugin", "primitiveDropRequestFileName", (void*)primitiveDropRequestFileName},
	{"DropPlugin", "primitiveDropRequestFileHandle", (void*)primitiveDropRequestFileHandle},
	{"DropPlugin", "setInterpreter", (void*)setInterpreter},
	{"DropPlugin", "initialiseModule", (void*)initialiseModule},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

