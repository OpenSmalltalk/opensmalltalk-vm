/* Automatically generated from Squeak on #(19 March 2005 10:08:54 am) */

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
EXPORT(int) primitiveDropRequestFileHandle(void);
EXPORT(int) primitiveDropRequestFileName(void);
EXPORT(int) setFileAccessCallback(int address);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"DropPlugin 19 March 2005 (i)"
#else
	"DropPlugin 19 March 2005 (e)"
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
	return dropInit();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box. */

EXPORT(int) primitiveDropRequestFileHandle(void) {
    int handleOop;
    int dropIndex;

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

EXPORT(int) primitiveDropRequestFileName(void) {
    int nameOop;
    int i;
    char * dropName;
    int nameLength;
    int dropIndex;
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

EXPORT(int) setFileAccessCallback(int address) {
	return sqSecFileAccessCallback((void *) address);
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
	return dropShutdown();
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* DropPlugin_exports[][3] = {
	{"DropPlugin", "shutdownModule", (void*)shutdownModule},
	{"DropPlugin", "primitiveDropRequestFileName", (void*)primitiveDropRequestFileName},
	{"DropPlugin", "primitiveDropRequestFileHandle", (void*)primitiveDropRequestFileHandle},
	{"DropPlugin", "setFileAccessCallback", (void*)setFileAccessCallback},
	{"DropPlugin", "getModuleName", (void*)getModuleName},
	{"DropPlugin", "initialiseModule", (void*)initialiseModule},
	{"DropPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

