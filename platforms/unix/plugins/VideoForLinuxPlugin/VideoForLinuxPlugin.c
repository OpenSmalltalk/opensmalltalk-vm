/* Automatically generated from Squeak on #(7 March 2007 2:25:53 pm) */

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
#include "VideoForLinuxPlugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
static int clipPixel(int pixel);
static int copyFrominto16destSizebrightnesscontrast(unsigned char* src2, unsigned char* dest2, int destSize, double brightness, double contrast);
static int copyFrominto32destSizebrightnesscontrast(unsigned char* src2, unsigned char* dest2, int destSize, double brightness, double contrast);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int height(Device device);
static int msg(char *s);
static int pixelbrightness256contrastFactor2(int pixel, int brightness, int contrastFactor);
#pragma export on
EXPORT(int) primitiveDeviceClose(void);
EXPORT(int) primitiveDeviceCreate(void);
EXPORT(int) primitiveDeviceDescribe(void);
EXPORT(int) primitiveDeviceGetHeight(void);
EXPORT(int) primitiveDeviceGetWidth(void);
EXPORT(int) primitiveDeviceNextFrameIntoBrightnessContrastFormDepth(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static int storeRedgreenbluebrightness256contrastFactor2into16Bits(int red, int green, int blue, int brig256, int contInteger, unsigned char* dest);
static int storeRedgreenbluebrightness256contrastFactor2into32Bits(int red, int green, int blue, int brig256, int contInteger, unsigned char* dest);
static int storeRedgreenblueinto16Bits(int red, int green, int blue, unsigned char* dest);
static int storeRedgreenblueinto32Bits(int red, int green, int blue, unsigned char* dest);
static int width(Device device);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"VideoForLinuxPlugin 7 March 2007 (i)"
#else
	"VideoForLinuxPlugin 7 March 2007 (e)"
#endif
;


static int clipPixel(int pixel) {
    int result;

	result = ((pixel < 0) ? 0 : pixel);
	return ((result < 255) ? result : 255);
}

static int copyFrominto16destSizebrightnesscontrast(unsigned char* src2, unsigned char* dest2, int destSize, double brightness, double contrast) {
    unsigned char* dest;
    unsigned char* final;
    int brig256;
    unsigned char* src;
    int contInteger;
    double cont;

	dest = dest2;
	src = src2;
	final = dest + (destSize * 2);
	if ((contrast == 0.0) && (brightness == 0.0)) {
		while (dest < final) {
			storeRedgreenblueinto16Bits(src[0], src[1], src[2], dest);
			dest += 2;
			src += 3;
		}
	} else {
		brig256 = ((int) (brightness * 256) );
		cont = 1.0 + contrast;
		contInteger = ((int) ((cont * cont) * 32767) );
		while (dest < final) {
			storeRedgreenbluebrightness256contrastFactor2into16Bits(src[0], src[1], src[2], brig256, contInteger, dest);
			dest += 2;
			src += 3;
		}
	}
}

static int copyFrominto32destSizebrightnesscontrast(unsigned char* src2, unsigned char* dest2, int destSize, double brightness, double contrast) {
    unsigned char* dest;
    unsigned char* final;
    int brig256;
    unsigned char* src;
    int contInteger;
    double cont;

	dest = dest2;
	src = src2;
	final = dest + (destSize * 4);
	if ((contrast == 0.0) && (brightness == 0.0)) {
		while (dest < final) {
			storeRedgreenblueinto32Bits(src[0], src[1], src[2], dest);
			dest += 4;
			src += 3;
		}
	} else {
		brig256 = ((int) (brightness * 256) );
		cont = 1.0 + contrast;
		contInteger = ((int) ((cont * cont) * 32767) );
		while (dest < final) {
			storeRedgreenbluebrightness256contrastFactor2into32Bits(src[0], src[1], src[2], brig256, contInteger, dest);
			dest += 4;
			src += 3;
		}
	}
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

static int height(Device device) {
	return device->vwindow.height;
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

static int pixelbrightness256contrastFactor2(int pixel, int brightness, int contrastFactor) {
    int result;

	result = ((((int) ((pixel - 128) * (contrastFactor / 32767.0)) )) + 128) + brightness;
	return result;
}

EXPORT(int) primitiveDeviceClose(void) {
    Device device;

	device = ((Device) (interpreterProxy->stackIntegerValue(0)));
	closeDevice(device);
	interpreterProxy->pop(1);
}

EXPORT(int) primitiveDeviceCreate(void) {
    int devicePointer;
    int deviceID;
    int palette;
    int height;
    int width;

	palette = interpreterProxy->stackIntegerValue(0);
	height = interpreterProxy->stackIntegerValue(1);
	width = interpreterProxy->stackIntegerValue(2);

	/*  */

	deviceID = interpreterProxy->stackIntegerValue(3);
	devicePointer = (int) createDevice(deviceID, width, height, palette);
	if (devicePointer <= 0) {
		return interpreterProxy->primitiveFail();
	}
	interpreterProxy->popthenPush(5, ((devicePointer << 1) | 1));
}

EXPORT(int) primitiveDeviceDescribe(void) {
    int deviceID;
    int deviceNameSize;
    int deviceName;
    char* deviceNamePointer;

	deviceName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(deviceName))) {
		return interpreterProxy->primitiveFail();
	}
	deviceNamePointer = interpreterProxy->firstIndexableField(deviceName);
	deviceNameSize = interpreterProxy->byteSizeOf(deviceName);
	if (!(deviceNameSize == 32)) {
		return interpreterProxy->primitiveFail();
	}
	deviceID = interpreterProxy->stackIntegerValue(1);
	describeDevice(deviceID, deviceNamePointer);
	interpreterProxy->pop(2);
}

EXPORT(int) primitiveDeviceGetHeight(void) {
    Device device;
    int result;

	device = ((Device) (interpreterProxy->stackIntegerValue(0)));
	result = device->vwindow.height;
	interpreterProxy->popthenPush(2, ((result << 1) | 1));
}

EXPORT(int) primitiveDeviceGetWidth(void) {
    Device device;
    int result;

	device = ((Device) (interpreterProxy->stackIntegerValue(0)));
	result = device->vwindow.width;
	interpreterProxy->popthenPush(2, ((result << 1) | 1));
}

EXPORT(int) primitiveDeviceNextFrameIntoBrightnessContrastFormDepth(void) {
    int formDepth;
    double brightness;
    Device device;
    unsigned char* src;
    int bitsArrayPointer;
    double contrast;

	formDepth = interpreterProxy->stackIntegerValue(0);
	contrast = interpreterProxy->stackFloatValue(1);
	contrast = ((contrast < 1.0) ? contrast : 1.0);
	contrast = ((contrast < -1.0) ? -1.0 : contrast);
	brightness = interpreterProxy->stackFloatValue(2);
	brightness = ((brightness < 1.0) ? brightness : 1.0);
	brightness = ((brightness < -1.0) ? -1.0 : brightness);
	bitsArrayPointer = interpreterProxy->stackValue(3);
	interpreterProxy->success(!(interpreterProxy->isPointers(bitsArrayPointer)));
	if (interpreterProxy->failed()) {
		return null;
	}

	/* Capture */

	device = ((Device) (interpreterProxy->stackIntegerValue(4)));
	if (!(captureFrameFromDevice(device))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(convertBufferTo24(device))) {
		return interpreterProxy->primitiveFail();
	}

	/* Convert */

	src = device->buffer24;
	if (formDepth == 16) {
		copyFrominto16destSizebrightnesscontrast(src, ((unsigned char*) (interpreterProxy->firstIndexableField(bitsArrayPointer))), (width(device)) * (height(device)), brightness, contrast);
	} else {
		copyFrominto32destSizebrightnesscontrast(src, ((unsigned char*) (interpreterProxy->firstIndexableField(bitsArrayPointer))), (width(device)) * (height(device)), brightness, contrast);
	}
	interpreterProxy->pop(5);
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

static int storeRedgreenbluebrightness256contrastFactor2into16Bits(int red, int green, int blue, int brig256, int contInteger, unsigned char* dest) {
    int sr;
    int sg;
    int sb;
    int r;
    int g;
    int b;
    int result;
    int result1;
    int result2;
    int result3;
    int result4;
    int result5;

	/* begin pixel:brightness256:contrastFactor2: */
	result = ((((int) ((red - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	r = result;
	/* begin clipPixel: */
	result1 = ((r < 0) ? 0 : r);
	r = ((result1 < 255) ? result1 : 255);
	/* begin pixel:brightness256:contrastFactor2: */
	result2 = ((((int) ((green - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	g = result2;
	/* begin clipPixel: */
	result3 = ((g < 0) ? 0 : g);
	g = ((result3 < 255) ? result3 : 255);
	/* begin pixel:brightness256:contrastFactor2: */
	result4 = ((((int) ((blue - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	b = result4;
	/* begin clipPixel: */
	result5 = ((b < 0) ? 0 : b);
	b = ((result5 < 255) ? result5 : 255);
	sr = ((unsigned) r >> 3);
	sg = ((unsigned) g >> 3);
	sb = ((unsigned) b >> 3);
	dest[0] = ((((unsigned) sg << 5)) | sb);
	dest[1] = (((((unsigned) sr << 2)) | (((unsigned) sg >> 3))) | 128);
}

static int storeRedgreenbluebrightness256contrastFactor2into32Bits(int red, int green, int blue, int brig256, int contInteger, unsigned char* dest) {
    int r;
    int g;
    int b;
    int result;
    int result1;
    int result2;
    int result3;
    int result4;
    int result5;

	/* begin pixel:brightness256:contrastFactor2: */
	result3 = ((((int) ((red - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	r = result3;
	/* begin clipPixel: */
	result = ((r < 0) ? 0 : r);
	r = ((result < 255) ? result : 255);
	/* begin pixel:brightness256:contrastFactor2: */
	result4 = ((((int) ((green - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	g = result4;
	/* begin clipPixel: */
	result1 = ((g < 0) ? 0 : g);
	g = ((result1 < 255) ? result1 : 255);
	/* begin pixel:brightness256:contrastFactor2: */
	result5 = ((((int) ((blue - 128) * (contInteger / 32767.0)) )) + 128) + brig256;
	b = result5;
	/* begin clipPixel: */
	result2 = ((b < 0) ? 0 : b);
	b = ((result2 < 255) ? result2 : 255);
	dest[0] = b;
	dest[1] = g;
	dest[2] = r;
	dest[3] = 255;
}

static int storeRedgreenblueinto16Bits(int red, int green, int blue, unsigned char* dest) {
    int sr;
    int sg;
    int sb;

	sr = ((unsigned) red >> 3);
	sg = ((unsigned) green >> 3);
	sb = ((unsigned) blue >> 3);
	dest[0] = ((((unsigned) sg << 5)) | sb);
	dest[1] = (((((unsigned) sr << 2)) | (((unsigned) sg >> 3))) | 128);
}

static int storeRedgreenblueinto32Bits(int red, int green, int blue, unsigned char* dest) {
	dest[0] = blue;
	dest[1] = green;
	dest[2] = red;
	dest[3] = 255;
}

static int width(Device device) {
	return device->vwindow.width;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* VideoForLinuxPlugin_exports[][3] = {
	{"VideoForLinuxPlugin", "primitiveDeviceClose", (void*)primitiveDeviceClose},
	{"VideoForLinuxPlugin", "primitiveDeviceGetHeight", (void*)primitiveDeviceGetHeight},
	{"VideoForLinuxPlugin", "primitiveDeviceNextFrameIntoBrightnessContrastFormDepth", (void*)primitiveDeviceNextFrameIntoBrightnessContrastFormDepth},
	{"VideoForLinuxPlugin", "primitiveDeviceDescribe", (void*)primitiveDeviceDescribe},
	{"VideoForLinuxPlugin", "primitiveDeviceCreate", (void*)primitiveDeviceCreate},
	{"VideoForLinuxPlugin", "getModuleName", (void*)getModuleName},
	{"VideoForLinuxPlugin", "primitiveDeviceGetWidth", (void*)primitiveDeviceGetWidth},
	{"VideoForLinuxPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

