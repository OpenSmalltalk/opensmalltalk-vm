/* Automatically generated from Squeak on #(15 March 2005 2:29:17 pm) */

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
#include "SoundCodecPrims.h"

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
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveGSMDecode(void);
EXPORT(int) primitiveGSMEncode(void);
EXPORT(int) primitiveGSMNewState(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SoundCodecPrims 15 March 2005 (i)"
#else
	"SoundCodecPrims 15 March 2005 (e)"
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

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

EXPORT(int) primitiveGSMDecode(void) {
    int srcIndex;
    int state;
    int dstSize;
    int dstIndex;
    int frameCount;
    int dst;
    int result;
    int srcSize;
    int src;
    int dstDelta;
    int srcDelta;

	dstIndex = interpreterProxy->stackIntegerValue(0);
	dst = interpreterProxy->stackObjectValue(1);
	srcIndex = interpreterProxy->stackIntegerValue(2);
	src = interpreterProxy->stackObjectValue(3);
	frameCount = interpreterProxy->stackIntegerValue(4);
	state = interpreterProxy->stackObjectValue(5);
	interpreterProxy->success(interpreterProxy->isWords(dst));
	interpreterProxy->success(interpreterProxy->isBytes(src));
	interpreterProxy->success(interpreterProxy->isBytes(state));
	if (interpreterProxy->failed()) {
		return null;
	}
	srcSize = interpreterProxy->slotSizeOf(src);
	dstSize = (interpreterProxy->slotSizeOf(dst)) * 2;
	gsmDecode(state + 4, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta);
	if (interpreterProxy->failed()) {
		return null;
	}
	result = interpreterProxy->makePointwithxValueyValue(srcDelta, dstDelta);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(6);
	interpreterProxy->push(result);
}

EXPORT(int) primitiveGSMEncode(void) {
    int srcIndex;
    int state;
    int dstSize;
    int dstIndex;
    int frameCount;
    int dst;
    int result;
    int srcSize;
    int src;
    int dstDelta;
    int srcDelta;

	dstIndex = interpreterProxy->stackIntegerValue(0);
	dst = interpreterProxy->stackObjectValue(1);
	srcIndex = interpreterProxy->stackIntegerValue(2);
	src = interpreterProxy->stackObjectValue(3);
	frameCount = interpreterProxy->stackIntegerValue(4);
	state = interpreterProxy->stackObjectValue(5);
	interpreterProxy->success(interpreterProxy->isBytes(dst));
	interpreterProxy->success(interpreterProxy->isWords(src));
	interpreterProxy->success(interpreterProxy->isBytes(state));
	if (interpreterProxy->failed()) {
		return null;
	}
	srcSize = (interpreterProxy->slotSizeOf(src)) * 2;
	dstSize = interpreterProxy->slotSizeOf(dst);
	gsmEncode(state + 4, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta);
	if (interpreterProxy->failed()) {
		return null;
	}
	result = interpreterProxy->makePointwithxValueyValue(srcDelta, dstDelta);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(6);
	interpreterProxy->push(result);
}

EXPORT(int) primitiveGSMNewState(void) {
    int stateBytes;
    int state;

	stateBytes = gsmStateBytes();
	state = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), stateBytes);
	gsmInitState(state + 4);
	interpreterProxy->push(state);
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


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SoundCodecPrims_exports[][3] = {
	{"SoundCodecPrims", "primitiveGSMNewState", (void*)primitiveGSMNewState},
	{"SoundCodecPrims", "primitiveGSMEncode", (void*)primitiveGSMEncode},
	{"SoundCodecPrims", "getModuleName", (void*)getModuleName},
	{"SoundCodecPrims", "primitiveGSMDecode", (void*)primitiveGSMDecode},
	{"SoundCodecPrims", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

