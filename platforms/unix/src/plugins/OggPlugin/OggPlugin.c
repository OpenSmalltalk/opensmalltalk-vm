/* Automatically generated from Squeak on an Array(10 November 2008 3:51:44 pm)
by VMMaker 3.8b6
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
#include "OggPlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
static sqInt msg(char * s);
static SqOggPtr * oggInstanceOf(sqInt oggOop);
#pragma export on
EXPORT(sqInt) primitiveClose(void);
EXPORT(sqInt) primitiveExtractMono(void);
EXPORT(sqInt) primitiveGetChannels(void);
EXPORT(sqInt) primitiveGetComment(void);
EXPORT(sqInt) primitiveGetCommentSize(void);
EXPORT(sqInt) primitiveGetRate(void);
EXPORT(sqInt) primitiveGetState(void);
EXPORT(sqInt) primitiveGetVendor(void);
EXPORT(sqInt) primitiveOpen(void);
EXPORT(sqInt) primitivePacketFlush(void);
EXPORT(sqInt) primitiveRead(void);
EXPORT(sqInt) primitiveReadSize(void);
EXPORT(sqInt) primitiveSetChannels(void);
EXPORT(sqInt) primitiveSetQuality(void);
EXPORT(sqInt) primitiveSetRate(void);
EXPORT(sqInt) primitiveVersion(void);
EXPORT(sqInt) primitiveWrite(void);
EXPORT(sqInt) primitiveWriteEOS(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static sqInt sqAssert(sqInt aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"OggPlugin 10 November 2008 (i)"
#else
	"OggPlugin 10 November 2008 (e)"
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

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Convert from Squeak pointer to SqOggPtr */

static SqOggPtr * oggInstanceOf(sqInt oggOop) {
	SqOggPtr * oggp;

	interpreterProxy->success((interpreterProxy->isBytes(oggOop)) && ((interpreterProxy->byteSizeOf(oggOop)) == (sizeof(SqOggPtr))));
	oggp = ((SqOggPtr *) (interpreterProxy->firstIndexableField(oggOop)));
	return oggp;
}

EXPORT(sqInt) primitiveClose(void) {
	char *oggPtr;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggClose((SqOggPtr *) oggPtr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveExtractMono(void) {
	sqInt channel;
	short * dest;
	sqInt size;
	sqInt i;
	short * src;
	sqInt srcOop;
	sqInt destOop;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}

	/* output buffer */

	destOop = interpreterProxy->stackObjectValue(3);

	/* source buffer */

	srcOop = interpreterProxy->stackObjectValue(2);

	/* frame size (word size of dest) */

	size = interpreterProxy->stackIntegerValue(1);

	/* channel number */

	channel = interpreterProxy->stackIntegerValue(0);
	dest = ((short *) (interpreterProxy->firstIndexableField(destOop)));
	src = ((short *) (interpreterProxy->firstIndexableField(srcOop)));
	for (i = 0; i <= (size - 1); i += 1) {
		dest[i] = (src[(i * 2) + channel]);
	}
	return interpreterProxy->pop(4);
}

EXPORT(sqInt) primitiveGetChannels(void) {
	char *oggPtr;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetChannels((SqOggPtr *) oggPtr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetComment(void) {
	char *oggPtr;
	char *buffer;
	sqInt size;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	buffer = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	size = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetComment((SqOggPtr *) oggPtr, buffer, size)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetCommentSize(void) {
	char *oggPtr;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetCommentSize((SqOggPtr *) oggPtr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetRate(void) {
	char *oggPtr;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetRate((SqOggPtr *) oggPtr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetState(void) {
	char *oggPtr;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetState((SqOggPtr *) oggPtr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveGetVendor(void) {
	char *oggPtr;
	char *buffer;
	sqInt size;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(2)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(2))));
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	buffer = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	size = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggGetVendor((SqOggPtr *) oggPtr, buffer, size)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(sqInt) primitiveOpen(void) {
	SqOggPtr * oggp;
	sqInt oggOop;
	sqInt mode;

	mode = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	oggOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), sizeof(SqOggPtr));
	oggp = ((SqOggPtr *) (interpreterProxy->firstIndexableField(oggOop)));
	SqOggOpen(mode, oggp);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, oggOop);
	return null;
}

EXPORT(sqInt) primitivePacketFlush(void) {
	char *oggPtr;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggPacketFlush((SqOggPtr *) oggPtr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(sqInt) primitiveRead(void) {
	SqOggPtr * oggp;
	sqInt bufferOop;
	sqInt size;
	char * buffer;
	sqInt result;
	sqInt oggOop;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	size = interpreterProxy->stackIntegerValue(0);
	bufferOop = interpreterProxy->stackObjectValue(1);
	buffer = ((char *) (interpreterProxy->firstIndexableField(bufferOop)));
	oggOop = interpreterProxy->stackObjectValue(2);
	oggp = oggInstanceOf(oggOop);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(bufferOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	result = SqOggRead(oggp, buffer, size);
	interpreterProxy->pop(4);
	return interpreterProxy->pushInteger(result);
}

EXPORT(sqInt) primitiveReadSize(void) {
	char *oggPtr;
	sqInt _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = interpreterProxy->integerObjectOf((SqOggReadSize((SqOggPtr *) oggPtr)));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(sqInt) primitiveSetChannels(void) {
	char *oggPtr;
	sqInt value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	value = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggSetChannels((SqOggPtr *) oggPtr, value);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveSetQuality(void) {
	char *oggPtr;
	double value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	value = interpreterProxy->stackFloatValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggSetQuality((SqOggPtr *) oggPtr, value);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveSetRate(void) {
	char *oggPtr;
	sqInt value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	value = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggSetRate((SqOggPtr *) oggPtr, value);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(sqInt) primitiveVersion(void) {
	sqInt _return_value;

	_return_value = interpreterProxy->integerObjectOf(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	Write to the buffer. It is written traditional InterpreterPlugin way
	because the second buffer can be words or bytes array */

EXPORT(sqInt) primitiveWrite(void) {
	sqInt size;
	sqInt chunkSize;
	sqInt result;
	sqInt bufSize;
	SqOggPtr * oggp;
	sqInt i;
	char * buffer;
	sqInt bufferOop;
	sqInt oggOop;

	bufSize = 4096;
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	size = interpreterProxy->stackIntegerValue(0);
	bufferOop = interpreterProxy->stackObjectValue(1);
	buffer = ((char *) (interpreterProxy->firstIndexableField(bufferOop)));
	oggOop = interpreterProxy->stackObjectValue(2);
	oggp = oggInstanceOf(oggOop);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(bufferOop));
	if (interpreterProxy->failed()) {
		return null;
	}
	for (i = 0; i <= (size - 1); i += bufSize) {
		if ((i + bufSize) < size) {
			chunkSize = bufSize;
		} else {
			chunkSize = size - i;
		}
		result = SqOggWrite(oggp, buffer + i, chunkSize);
	}
	interpreterProxy->pop(4);
	return interpreterProxy->pushInteger(result);
}

EXPORT(sqInt) primitiveWriteEOS(void) {
	char *oggPtr;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	oggPtr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	SqOggWriteEOS((SqOggPtr *) oggPtr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
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

static sqInt sqAssert(sqInt aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* OggPlugin_exports[][3] = {
	{"OggPlugin", "primitiveWriteEOS", (void*)primitiveWriteEOS},
	{"OggPlugin", "primitiveGetCommentSize", (void*)primitiveGetCommentSize},
	{"OggPlugin", "primitivePacketFlush", (void*)primitivePacketFlush},
	{"OggPlugin", "setInterpreter", (void*)setInterpreter},
	{"OggPlugin", "primitiveClose", (void*)primitiveClose},
	{"OggPlugin", "primitiveVersion", (void*)primitiveVersion},
	{"OggPlugin", "getModuleName", (void*)getModuleName},
	{"OggPlugin", "primitiveGetVendor", (void*)primitiveGetVendor},
	{"OggPlugin", "primitiveSetQuality", (void*)primitiveSetQuality},
	{"OggPlugin", "primitiveReadSize", (void*)primitiveReadSize},
	{"OggPlugin", "primitiveExtractMono", (void*)primitiveExtractMono},
	{"OggPlugin", "primitiveGetChannels", (void*)primitiveGetChannels},
	{"OggPlugin", "primitiveOpen", (void*)primitiveOpen},
	{"OggPlugin", "primitiveSetChannels", (void*)primitiveSetChannels},
	{"OggPlugin", "primitiveWrite", (void*)primitiveWrite},
	{"OggPlugin", "primitiveRead", (void*)primitiveRead},
	{"OggPlugin", "primitiveGetComment", (void*)primitiveGetComment},
	{"OggPlugin", "primitiveSetRate", (void*)primitiveSetRate},
	{"OggPlugin", "primitiveGetRate", (void*)primitiveGetRate},
	{"OggPlugin", "primitiveGetState", (void*)primitiveGetState},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

