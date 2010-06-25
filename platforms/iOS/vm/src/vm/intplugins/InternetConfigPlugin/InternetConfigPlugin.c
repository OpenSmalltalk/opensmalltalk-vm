/* Automatically generated from Squeak on 15 June 2010 5:06:16 pm 
   by VMMaker 4.2.4
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
#include "InternetConfigPlugin.h"

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
#pragma export on
EXPORT(sqInt) primitiveGetMacintoshFileTypeAndCreatorFrom(void);
EXPORT(sqInt) primitiveGetStringKeyedBy(void);
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
	"InternetConfigPlugin 15 June 2010 (i)"
#else
	"InternetConfigPlugin 15 June 2010 (e)"
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
	return sqInternetConfigurationInit();
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(sqInt) primitiveGetMacintoshFileTypeAndCreatorFrom(void) {
	sqInt oop;
	char * ptr;
	sqInt keyLength;
	sqInt i;
	char creator[8];
	char *aFileName;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aFileName = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	keyLength = interpreterProxy->byteSizeOf((oopForPointer( aFileName ) - BASE_HEADER_SIZE));
	sqInternetGetMacintoshFileTypeAndCreatorFromkeySizeinto(aFileName, keyLength, creator);
	oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), 8);
	ptr = interpreterProxy->firstIndexableField(oop);
	for (i = 0; i <= 7; i += 1) {
		ptr[i] = (creator[i]);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, oop);
	return null;
}

EXPORT(sqInt) primitiveGetStringKeyedBy(void) {
	char aString[1025];
	sqInt oop;
	char * ptr;
	sqInt keyLength;
	sqInt size;
	sqInt i;
	char *aKey;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aKey = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	keyLength = interpreterProxy->byteSizeOf((oopForPointer( aKey ) - BASE_HEADER_SIZE));
	size = sqInternetConfigurationGetStringKeyedBykeySizeinto(aKey, keyLength, aString);
	oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), size);
	ptr = interpreterProxy->firstIndexableField(oop);
	for (i = 0; i <= (size - 1); i += 1) {
		ptr[i] = (aString[i]);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, oop);
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
	return sqInternetConfigurationShutdown();
}

static sqInt sqAssert(sqInt aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* InternetConfigPlugin_exports[][3] = {
	{"InternetConfigPlugin", "primitiveGetStringKeyedBy", (void*)primitiveGetStringKeyedBy},
	{"InternetConfigPlugin", "shutdownModule", (void*)shutdownModule},
	{"InternetConfigPlugin", "setInterpreter", (void*)setInterpreter},
	{"InternetConfigPlugin", "initialiseModule", (void*)initialiseModule},
	{"InternetConfigPlugin", "primitiveGetMacintoshFileTypeAndCreatorFrom", (void*)primitiveGetMacintoshFileTypeAndCreatorFrom},
	{"InternetConfigPlugin", "getModuleName", (void*)getModuleName},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

