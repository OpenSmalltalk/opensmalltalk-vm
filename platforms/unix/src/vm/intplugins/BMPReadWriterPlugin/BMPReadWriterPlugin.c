/* Automatically generated from Squeak on #(19 March 2005 10:08:38 am) */

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
EXPORT(int) primitiveRead24BmpLine(void);
EXPORT(int) primitiveWrite24BmpLine(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"BMPReadWriterPlugin 19 March 2005 (i)"
#else
	"BMPReadWriterPlugin 19 March 2005 (e)"
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

EXPORT(int) primitiveRead24BmpLine(void) {
    int formBitsOop;
    unsigned char * pixelLine;
    unsigned int * formBits;
    int formBitsSize;
    int formBitsIndex;
    int pixelLineOop;
    int pixelLineSize;
    int width;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	width = interpreterProxy->stackIntegerValue(0);
	formBitsIndex = interpreterProxy->stackIntegerValue(1);
	formBitsOop = interpreterProxy->stackObjectValue(2);
	pixelLineOop = interpreterProxy->stackObjectValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(formBitsOop))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(pixelLineOop))) {
		return interpreterProxy->primitiveFail();
	}
	formBitsSize = interpreterProxy->slotSizeOf(formBitsOop);
	formBits = interpreterProxy->firstIndexableField(formBitsOop);
	pixelLineSize = interpreterProxy->slotSizeOf(pixelLineOop);
	pixelLine = interpreterProxy->firstIndexableField(pixelLineOop);
	if (!(((formBitsIndex + width) <= formBitsSize) && ((width * 3) <= pixelLineSize))) {
		return interpreterProxy->primitiveFail();
	}
	
	formBits += formBitsIndex-1;
	while(width--) {
		unsigned int rgb;
		rgb = (*pixelLine++);
		rgb += (*pixelLine++) << 8;
		rgb += (*pixelLine++) << 16;
		if(rgb) rgb |= 0xFF000000; else rgb |= 0xFF000001;
		*formBits++ = rgb;
	}
	;
	interpreterProxy->pop(4);
}

EXPORT(int) primitiveWrite24BmpLine(void) {
    int formBitsOop;
    unsigned char * pixelLine;
    unsigned int * formBits;
    int formBitsSize;
    int formBitsIndex;
    int pixelLineOop;
    int pixelLineSize;
    int width;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	width = interpreterProxy->stackIntegerValue(0);
	formBitsIndex = interpreterProxy->stackIntegerValue(1);
	formBitsOop = interpreterProxy->stackObjectValue(2);
	pixelLineOop = interpreterProxy->stackObjectValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(formBitsOop))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(pixelLineOop))) {
		return interpreterProxy->primitiveFail();
	}
	formBitsSize = interpreterProxy->slotSizeOf(formBitsOop);
	formBits = interpreterProxy->firstIndexableField(formBitsOop);
	pixelLineSize = interpreterProxy->slotSizeOf(pixelLineOop);
	pixelLine = interpreterProxy->firstIndexableField(pixelLineOop);
	if (!(((formBitsIndex + width) <= formBitsSize) && ((width * 3) <= pixelLineSize))) {
		return interpreterProxy->primitiveFail();
	}
	
	formBits += formBitsIndex-1;

	while(width--) {
		unsigned int rgb;
		rgb = *formBits++;
		(*pixelLine++) = (rgb      ) & 0xFF;
		(*pixelLine++) = (rgb >> 8 ) & 0xFF;
		(*pixelLine++) = (rgb >> 16) & 0xFF;
	}

	;
	interpreterProxy->pop(4);
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


void* BMPReadWriterPlugin_exports[][3] = {
	{"BMPReadWriterPlugin", "primitiveRead24BmpLine", (void*)primitiveRead24BmpLine},
	{"BMPReadWriterPlugin", "getModuleName", (void*)getModuleName},
	{"BMPReadWriterPlugin", "primitiveWrite24BmpLine", (void*)primitiveWrite24BmpLine},
	{"BMPReadWriterPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

