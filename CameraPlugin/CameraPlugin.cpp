/* Automatically generated from Squeak on (29 April 2009 6:59:14 am) */

#if defined(WIN32) || defined(_WIN32) || defined(Win32)
 #ifdef __cplusplus
  #define DLLEXPORT extern "C" __declspec(dllexport)
 #else
  #define DLLEXPORT __declspec(dllexport)
 #endif /* C++ */
#else
 #define DLLEXPORT
#endif /* WIN32 */

#include "sqVirtualMachine.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

#include "cameraOps.h"
#include <string.h>


/*** Variables ***/
struct VirtualMachine* interpreterProxy;
const char *moduleName = "CameraPlugin 29 April 2009 (e)";

/*** Functions ***/
DLLEXPORT int primCameraName(void);
DLLEXPORT int primCloseCamera(void);
DLLEXPORT int primFrameExtent(void);
DLLEXPORT int primGetFrame(void);
DLLEXPORT int primGetParam(void);
DLLEXPORT int primOpenCamera(void);
DLLEXPORT int setInterpreter(struct VirtualMachine* anInterpreter);

DLLEXPORT int primCameraName(void) {
	char* nameStr;
	int i;
	int count;
	int resultOop;
	int cameraNum;
	char* dst;

	cameraNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return 0;
	}
	nameStr = CameraName(cameraNum);
	if (nameStr == 0) {
		interpreterProxy->success(0);
		return 0;
	}
	count = (int) strlen(nameStr);
	resultOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), count);
	dst = ((char *) (interpreterProxy->firstIndexableField(resultOop)));
	for (i = 0; i <= (count - 1); i += 1) {
		dst[i] = (nameStr[i]);
	}
	interpreterProxy->popthenPush(2, resultOop);
	return 0;
}

DLLEXPORT int primCloseCamera(void) {
	int cameraNum;

	cameraNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return 0;
	}
	CameraClose(cameraNum);
	interpreterProxy->pop(1);
	return 0;
}

DLLEXPORT int primFrameExtent(void) {
	int cameraNum;
	int e;

	cameraNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return 0;
	}
	e = CameraExtent(cameraNum);
	interpreterProxy->popthenPush(2, ((e << 1) | 1));
	return 0;
}

DLLEXPORT int primGetFrame(void) {
	int cameraNum;
	int bitmapOop;
	unsigned char *bitmap;
	int pixCount;
	int result;

	cameraNum = interpreterProxy->stackIntegerValue(1);
	bitmapOop = interpreterProxy->stackValue(0);
	if (((bitmapOop & 1)) || (!(interpreterProxy->isWords(bitmapOop)))) {
		interpreterProxy->success(0);
		return 0;
	}
	bitmap = ((unsigned char *) (interpreterProxy->firstIndexableField(bitmapOop)));
	pixCount = interpreterProxy->stSizeOf(bitmapOop);
	result = CameraGetFrame(cameraNum, bitmap, pixCount);
	if (result < 0) {
		interpreterProxy->success(0);
		return 0;
	}
	interpreterProxy->popthenPush(3, ((result << 1) | 1));
	return 0;
}

DLLEXPORT int primGetParam(void) {
	int cameraNum;
	int result;
	int paramNum;

	cameraNum = interpreterProxy->stackIntegerValue(1);
	paramNum = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return 0;
	}
	result = CameraGetParam(cameraNum, paramNum);
	interpreterProxy->popthenPush(3, ((result << 1) | 1));
	return 0;
}

DLLEXPORT int primOpenCamera(void) {
	int cameraNum;
	int desiredFrameWidth;
	int ok;
	int desiredFrameHeight;

	cameraNum = interpreterProxy->stackIntegerValue(2);
	desiredFrameWidth = interpreterProxy->stackIntegerValue(1);
	desiredFrameHeight = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return 0;
	}
	ok = CameraOpen(cameraNum, desiredFrameWidth, desiredFrameHeight);
	if (ok == 0) {
		interpreterProxy->success(0);
		return 0;
	}
	interpreterProxy->pop(3);
	return 0;
}

DLLEXPORT int setInterpreter(struct VirtualMachine* anInterpreter) {
	int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}
