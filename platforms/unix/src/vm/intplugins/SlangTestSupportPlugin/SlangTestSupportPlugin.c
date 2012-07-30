/* Automatically generated from Squeak on 27 June 2012 4:45:56 am 
   by VMMaker 4.9.5
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

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
static sqInt declareExportFalseByMethod(void);
static sqInt declareExportFalseByPragma(void);
#pragma export on
EXPORT(sqInt) declareExportTrueByMethod(void);
EXPORT(sqInt) declareExportTrueByPragma(void);
#pragma export off
sqInt declareStaticFalseByMethod(void);
sqInt declareStaticFalseByPragma(void);
static sqInt declareStaticTrueByMethod(void);
static sqInt declareStaticTrueByPragma(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
static sqInt inlineByMethod(void);
static sqInt inlineByPragma(void);
static sqInt methodThatShouldBeInlinedByMethod(void);
static sqInt methodThatShouldBeInlinedByPragma(void);
static sqInt methodThatShouldNotBeInlinedByMethod(void);
static sqInt methodThatShouldNotBeInlinedByPragma(void);
static char * returnTypeByMethod(void);
static char * returnTypeByPragma(void);
#pragma export on
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
static sqInt varDefByMethod(void);
static sqInt varDefByMethodAndPragma(void);
static sqInt varDefByPragma(void);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SlangTestSupportPlugin 27 June 2012 (i)"
#else
	"SlangTestSupportPlugin 27 June 2012 (e)"
#endif
;



/*	SlangTestSupport asCString: #declareExportFalseByMethod */

static sqInt declareExportFalseByMethod(void) {
}


/*	SlangTestSupport asCString: #declareExportFalseByPragma */

static sqInt declareExportFalseByPragma(void) {
}


/*	SlangTestSupport asCString: #declareExportTrueByMethod */

EXPORT(sqInt) declareExportTrueByMethod(void) {
}


/*	SlangTestSupport asCString: #declareExportTrueByPragma */

EXPORT(sqInt) declareExportTrueByPragma(void) {
}


/*	SlangTestSupport asCString: #declareStaticFalseByMethod */

sqInt declareStaticFalseByMethod(void) {
}


/*	SlangTestSupport asCString: #declareStaticFalseByPragma */

sqInt declareStaticFalseByPragma(void) {
}


/*	SlangTestSupport asCString: #declareStaticTrueByMethod */

static sqInt declareStaticTrueByMethod(void) {
}


/*	SlangTestSupport asCString: #declareStaticTrueByPragma */

static sqInt declareStaticTrueByPragma(void) {
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


/*	SlangTestSupport asCString: #inlineByMethod */
/*	SlangTestSupport asInlinedCString: #inlineByMethod */

static sqInt inlineByMethod(void) {
    sqInt bar;
    sqInt foo;

	foo = "foo";
	bar = methodThatShouldNotBeInlinedByMethod();
}


/*	SlangTestSupport asCString: #inlineByPragma */
/*	SlangTestSupport asInlinedCString: #inlineByPragma */

static sqInt inlineByPragma(void) {
    sqInt bar;
    sqInt foo;

	foo = "foo";
	bar = methodThatShouldNotBeInlinedByPragma();
}

static sqInt methodThatShouldBeInlinedByMethod(void) {
	return "foo";
}

static sqInt methodThatShouldBeInlinedByPragma(void) {
	return "foo";
}

static sqInt methodThatShouldNotBeInlinedByMethod(void) {
	return "bar";
}

static sqInt methodThatShouldNotBeInlinedByPragma(void) {
	return "bar";
}


/*	SlangTestSupport asCString: #returnTypeByMethod */

static char * returnTypeByMethod(void) {
}


/*	SlangTestSupport asCString: #returnTypeByPragma */

static char * returnTypeByPragma(void) {
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


/*	SlangTestSupport asCString: #varDefByMethod */

static sqInt varDefByMethod(void) {
    unsigned int * bar;
    char *foo;

}


/*	SlangTestSupportPlugin asCString: #varDefByMethodAndPragma */

static sqInt varDefByMethodAndPragma(void) {
    unsigned int * bar;
    float baz;
    char *foo;
    double fum;

}


/*	SlangTestSupport asCString: #varDefByPragma */

static sqInt varDefByPragma(void) {
    unsigned int * bar;
    char *foo;

}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SlangTestSupportPlugin_exports[][3] = {
	{"SlangTestSupportPlugin", "declareExportTrueByMethod", (void*)declareExportTrueByMethod},
	{"SlangTestSupportPlugin", "setInterpreter", (void*)setInterpreter},
	{"SlangTestSupportPlugin", "declareExportTrueByPragma", (void*)declareExportTrueByPragma},
	{"SlangTestSupportPlugin", "getModuleName", (void*)getModuleName},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

