/* Automatically generated from Squeak on #(20 August 2006 10:45:45 am) */

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


/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"VideoForLinuxPlugin 20 August 2006 (i)"
#else
	"VideoForLinuxPlugin 20 August 2006 (e)"
#endif
;

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int height(Device device);
static int msg(char *s);
static int pixelbrightnesscontrast(int pixel, double brightness, double contrast);
#pragma export on
EXPORT(int) primitiveDeviceClose(void);
EXPORT(int) primitiveDeviceCreate(void);
EXPORT(int) primitiveDeviceDescribe(void);
EXPORT(int) primitiveDeviceGetHeight(void);
EXPORT(int) primitiveDeviceGetWidth(void);
EXPORT(int) primitiveDeviceNextFrameIntoBrightnessAndContrast(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static int width(Device device);


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

static int pixelbrightnesscontrast(int pixel, double brightness, double contrast) {
    double c;
    int result;

	c = 1.0 + contrast;
	c = c * c;

	/* brightness */

	result = ((pixel - 0.5) * c) + 0.5;

	/* bound checking */

	result += ((int) (brightness * 256) );
	if (result < 0) {
		result = 0;
	}
	if (result > 255) {
		result = 255;
	}
	return ((int) result );
}

EXPORT(int) primitiveDeviceClose(void) {
    Device device;

	device = ((Device) (interpreterProxy->stackIntegerValue(0)));
	closeDevice(device);
	interpreterProxy->pop(1);
}

EXPORT(int) primitiveDeviceCreate(void) {
    int height;
    int width;
    int palette;
    int devicePointer;
    int deviceID;

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
    int deviceName;
    void* deviceNamePointer;
    int deviceNameSize;
    int deviceID;

	deviceName = interpreterProxy->stackValue(0);
	if (!(interpreterProxy->isBytes(deviceName))) {
		return interpreterProxy->primitiveFail();
	}
	deviceNamePointer = interpreterProxy->firstIndexableField(deviceName);
	deviceNameSize = interpreterProxy->byteSizeOf(deviceName);
	if (!(deviceNameSize == 32)) {
		return interpreterProxy->primitiveFail();
	}

	/*  */

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


/*	set the capture extent and pixel format to use */

EXPORT(int) primitiveDeviceNextFrameIntoBrightnessAndContrast(void) {
    double brightness;
    double contrast;
    unsigned char* src;
    int imageSize;
    int bitsArraySize;
    int result;
    int red;
    unsigned char* dest;
    int bitsArrayPointer;
    unsigned char* final;
    int blue;
    Device device;
    int green;

	contrast = interpreterProxy->stackFloatValue(0);
	brightness = interpreterProxy->stackFloatValue(1);
	brightness = ((brightness < 1.0) ? brightness : 1.0);
	brightness = ((brightness < -1.0) ? -1.0 : brightness);
	contrast = ((contrast < 1.0) ? contrast : 1.0);

	/*  */

	contrast = ((contrast < -1.0) ? -1.0 : contrast);
	bitsArrayPointer = interpreterProxy->stackValue(2);
	interpreterProxy->success(!(interpreterProxy->isPointers(bitsArrayPointer)));
	if (interpreterProxy->failed()) {
		return null;
	}

	/*  */

	bitsArraySize = interpreterProxy->byteSizeOf(bitsArrayPointer);

	/*  */

	device = ((Device) (interpreterProxy->stackIntegerValue(3)));
	result = nextFrameFromDevice(device);
	if (!(result)) {
		return interpreterProxy->primitiveFail();
	}
	dest = ((unsigned char*) (interpreterProxy->firstIndexableField(bitsArrayPointer)));

	/*  */

	src = device->buffer24;
	imageSize = ((width(device)) * (height(device))) * 4;

	/*  */

	final = dest + (((imageSize < bitsArraySize) ? imageSize : bitsArraySize));
	while (dest < final) {
		blue = pixelbrightnesscontrast(src[2], brightness, contrast);
		dest[0] = blue;
		green = pixelbrightnesscontrast(src[1], brightness, contrast);
		dest[1] = green;
		red = pixelbrightnesscontrast(src[0], brightness, contrast);
		dest[2] = red;
		dest[3] = 255;
		dest += 4;
		src += 3;
	}
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

static int width(Device device) {
	return device->vwindow.width;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* VideoForLinuxPlugin_exports[][3] = {
	{"VideoForLinuxPlugin", "primitiveDeviceClose", (void*)primitiveDeviceClose},
	{"VideoForLinuxPlugin", "primitiveDeviceGetHeight", (void*)primitiveDeviceGetHeight},
	{"VideoForLinuxPlugin", "primitiveDeviceDescribe", (void*)primitiveDeviceDescribe},
	{"VideoForLinuxPlugin", "primitiveDeviceCreate", (void*)primitiveDeviceCreate},
	{"VideoForLinuxPlugin", "primitiveDeviceNextFrameIntoBrightnessAndContrast", (void*)primitiveDeviceNextFrameIntoBrightnessAndContrast},
	{"VideoForLinuxPlugin", "getModuleName", (void*)getModuleName},
	{"VideoForLinuxPlugin", "primitiveDeviceGetWidth", (void*)primitiveDeviceGetWidth},
	{"VideoForLinuxPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

