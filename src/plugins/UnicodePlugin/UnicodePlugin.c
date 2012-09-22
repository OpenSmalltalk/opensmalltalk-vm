/* Automatically generated from Squeak on 22 September 2012 12:36:13 pm 
   by VMMaker 4.10.3
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
#include "UnicodePlugin.h"

#include "sqMemoryAccess.h"


/*** Constants ***/

/*** Function Prototypes ***/
static char * asCString(sqInt stringOop);
static void * cWordsPtrminSize(sqInt oop, sqInt minSize);
static sqInt copyStringintomax(sqInt stringOop, char *stringPtr, sqInt maxChars);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
#pragma export on
EXPORT(sqInt) primitiveClipboardGet(void);
EXPORT(sqInt) primitiveClipboardPut(void);
EXPORT(sqInt) primitiveClipboardSize(void);
EXPORT(sqInt) primitiveDrawString(void);
EXPORT(sqInt) primitiveGetFontList(void);
EXPORT(sqInt) primitiveGetXRanges(void);
EXPORT(sqInt) primitiveMeasureString(void);
EXPORT(sqInt) primitiveSetColors(void);
EXPORT(sqInt) primitiveSetFont(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"UnicodePlugin 22 September 2012 (i)"
#else
	"UnicodePlugin 22 September 2012 (e)"
#endif
;



/*	Return a C char * pointer into the given Squeak string object. */
/*	Warning: A Squeak string is not necessarily null-terminated. */
/*	Warning: the resulting pointer may become invalid after the next garbage collection and should only be using during the current primitive call. */

static char * asCString(sqInt stringOop) {
	if (((stringOop & 1)) || (!(interpreterProxy->isBytes(stringOop)))) {
		interpreterProxy->success(0);
		return 0;
	}
	return ((char *) (interpreterProxy->firstIndexableField(stringOop)));
}


/*	Return a C pointer to the first indexable field of oop, which must be a words object of at least the given size. */
/*	Warning: the resulting pointer may become invalid after the next garbage collection and should only be using during the current primitive call. */

static void * cWordsPtrminSize(sqInt oop, sqInt minSize) {
	interpreterProxy->success((!((oop & 1))) && ((interpreterProxy->isWords(oop)) && ((interpreterProxy->stSizeOf(oop)) >= minSize)));
	if (interpreterProxy->failed()) {
		return 0;
	}
	return ((void *) (interpreterProxy->firstIndexableField(oop)));
}


/*	Copy the Squeak string into a temporary buffer and add a terminating null byte. Fail if there is not sufficent space in the buffer. */

static sqInt copyStringintomax(sqInt stringOop, char *stringPtr, sqInt maxChars) {
    sqInt count;
    sqInt i;
    char *srcPtr;

	if (((stringOop & 1)) || (!(interpreterProxy->isBytes(stringOop)))) {
		interpreterProxy->success(0);
		return 0;
	}
	count = interpreterProxy->stSizeOf(stringOop);
	if (!(count < maxChars)) {
		interpreterProxy->success(0);
		return 0;
	}
	srcPtr = ((char *) (interpreterProxy->firstIndexableField(stringOop)));
	for (i = 1; i <= count; i += 1) {
		*stringPtr++ = *srcPtr++;
	}
	*stringPtr = 0;
	return 0;
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


/*	Read the clipboard into the given UTF16 string.. */

EXPORT(sqInt) primitiveClipboardGet(void) {
    sqInt count;
    unsigned short *utf16;
    sqInt utf16Length;
    sqInt utf16Oop;

	utf16Oop = interpreterProxy->stackValue(0);
	if (((utf16Oop & 1)) || (!(interpreterProxy->isWords(utf16Oop)))) {
		interpreterProxy->success(0);
	}
	if (interpreterProxy->failed()) {
		return 0;
	}
	utf16 = ((unsigned short *) (interpreterProxy->firstIndexableField(utf16Oop)));
	utf16Length = 2 * (interpreterProxy->stSizeOf(utf16Oop));
	count = unicodeClipboardGet(utf16, utf16Length);
	interpreterProxy->popthenPush(2, ((count << 1) | 1));
	return 0;
}


/*	Set the clipboard to a UTF16 string.. */

EXPORT(sqInt) primitiveClipboardPut(void) {
    sqInt count;
    sqInt strOop;
    unsigned short *utf16;
    sqInt utf16Length;

	strOop = interpreterProxy->stackValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (((strOop & 1)) || (!(interpreterProxy->isWords(strOop)))) {
		interpreterProxy->success(0);
	}
	if (interpreterProxy->failed()) {
		return 0;
	}
	utf16 = ((unsigned short *) (interpreterProxy->firstIndexableField(strOop)));
	utf16Length = 2 * (interpreterProxy->stSizeOf(strOop));
	if ((count >= 0) && (count < utf16Length)) {
		utf16Length = count;
	}
	unicodeClipboardPut(utf16, utf16Length);
	interpreterProxy->pop(2);
	return 0;
}

EXPORT(sqInt) primitiveClipboardSize(void) {
    sqInt count;

	count = unicodeClipboardSize();
	interpreterProxy->popthenPush(1, ((count << 1) | 1));
	return 0;
}

EXPORT(sqInt) primitiveDrawString(void) {
    sqInt bitmapOop;
    void *bitmapPtr;
    sqInt h;
    sqInt result;
    char *utf8;
    sqInt utf8Length;
    sqInt utf8Oop;
    sqInt w;

	utf8Oop = interpreterProxy->stackValue(3);
	utf8 = asCString(utf8Oop);
	w = interpreterProxy->stackIntegerValue(2);
	h = interpreterProxy->stackIntegerValue(1);
	bitmapOop = interpreterProxy->stackValue(0);
	bitmapPtr = cWordsPtrminSize(bitmapOop, w * h);
	if (interpreterProxy->failed()) {
		return null;
	}
	utf8Length = interpreterProxy->stSizeOf(utf8Oop);
	unicodeDrawString(utf8, utf8Length, &w, &h, bitmapPtr);
	result = interpreterProxy->makePointwithxValueyValue(w, h);
	interpreterProxy->popthenPush(5, result);
	return 0;
}

EXPORT(sqInt) primitiveGetFontList(void) {
    sqInt count;
    char *str;
    sqInt strLength;
    sqInt strOop;

	strOop = interpreterProxy->stackValue(0);
	str = asCString(strOop);
	if (interpreterProxy->failed()) {
		return null;
	}
	strLength = interpreterProxy->stSizeOf(strOop);
	count = unicodeGetFontList(str, strLength);
	interpreterProxy->popthenPush(2, ((count << 1) | 1));
	return 0;
}

EXPORT(sqInt) primitiveGetXRanges(void) {
    sqInt count;
    sqInt resultLength;
    sqInt resultOop;
    int *resultPtr;
    char *utf8;
    sqInt utf8Length;
    sqInt utf8Oop;

	utf8Oop = interpreterProxy->stackValue(1);
	utf8 = asCString(utf8Oop);
	resultOop = interpreterProxy->stackValue(0);
	resultPtr = cWordsPtrminSize(resultOop, 0);
	if (interpreterProxy->failed()) {
		return null;
	}
	utf8Length = interpreterProxy->stSizeOf(utf8Oop);
	resultLength = interpreterProxy->stSizeOf(resultOop);
	count = unicodeGetXRanges(utf8, utf8Length, resultPtr, resultLength);
	interpreterProxy->popthenPush(3, ((count << 1) | 1));
	return 0;
}

EXPORT(sqInt) primitiveMeasureString(void) {
    sqInt h;
    sqInt result;
    char *utf8;
    sqInt utf8Length;
    sqInt utf8Oop;
    sqInt w;

	utf8Oop = interpreterProxy->stackValue(0);
	utf8 = asCString(utf8Oop);
	if (interpreterProxy->failed()) {
		return null;
	}
	w = (h = 0);
	utf8Length = interpreterProxy->stSizeOf(utf8Oop);
	unicodeMeasureString(utf8, utf8Length, &w, &h);
	result = interpreterProxy->makePointwithxValueyValue(w, h);
	interpreterProxy->popthenPush(2, result);
	return 0;
}

EXPORT(sqInt) primitiveSetColors(void) {
    sqInt bgBlue;
    sqInt bgGreen;
    sqInt bgRed;
    sqInt fgBlue;
    sqInt fgGreen;
    sqInt fgRed;
    sqInt mapBGToTransparent;

	fgRed = interpreterProxy->stackIntegerValue(6);
	fgGreen = interpreterProxy->stackIntegerValue(5);
	fgBlue = interpreterProxy->stackIntegerValue(4);
	bgRed = interpreterProxy->stackIntegerValue(3);
	bgGreen = interpreterProxy->stackIntegerValue(2);
	bgBlue = interpreterProxy->stackIntegerValue(1);
	mapBGToTransparent = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	unicodeSetColors(fgRed, fgGreen, fgBlue, bgRed, bgGreen, bgBlue, mapBGToTransparent);
	interpreterProxy->pop(7);
	return 0;
}

EXPORT(sqInt) primitiveSetFont(void) {
    sqInt antiAliasFlag;
    sqInt boldFlag;
    char fontName[200];
    sqInt fontSize;
    sqInt italicFlag;

	copyStringintomax(interpreterProxy->stackValue(4), fontName, 200);
	fontSize = interpreterProxy->stackIntegerValue(3);
	boldFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(2));
	italicFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	antiAliasFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	unicodeSetFont(fontName, fontSize, boldFlag, italicFlag, antiAliasFlag);
	interpreterProxy->pop(5);
	return 0;
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


#ifdef SQUEAK_BUILTIN_PLUGIN


void* UnicodePlugin_exports[][3] = {
	{"UnicodePlugin", "primitiveClipboardSize", (void*)primitiveClipboardSize},
	{"UnicodePlugin", "primitiveSetFont", (void*)primitiveSetFont},
	{"UnicodePlugin", "primitiveSetColors", (void*)primitiveSetColors},
	{"UnicodePlugin", "primitiveClipboardPut", (void*)primitiveClipboardPut},
	{"UnicodePlugin", "primitiveGetFontList", (void*)primitiveGetFontList},
	{"UnicodePlugin", "primitiveMeasureString", (void*)primitiveMeasureString},
	{"UnicodePlugin", "primitiveGetXRanges", (void*)primitiveGetXRanges},
	{"UnicodePlugin", "setInterpreter", (void*)setInterpreter},
	{"UnicodePlugin", "primitiveDrawString", (void*)primitiveDrawString},
	{"UnicodePlugin", "primitiveClipboardGet", (void*)primitiveClipboardGet},
	{"UnicodePlugin", "getModuleName", (void*)getModuleName},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

