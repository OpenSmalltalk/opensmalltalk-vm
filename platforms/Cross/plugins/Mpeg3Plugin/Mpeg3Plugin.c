/* Automatically generated from Squeak on #(9 November 2000 11:09:16 am) */

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
#include "Mpeg3Plugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

/*** Variables ***/
struct VirtualMachine* interpreterProxy;
int maximumNumberOfFilesToWatch;
const char *moduleName = "Mpeg3Plugin 9 November 2000 (e)";
mpeg3_t *mpegFiles[1024+1];

/*** Function Prototypes ***/
static int checkFileEntry(mpeg3_t * aMpegFile);
#pragma export on
EXPORT(const char*) getModuleName(void);
EXPORT(int) initialiseModule(void);
#pragma export off
static int makeFileEntry(mpeg3_t * aMpegFile);
static mpeg3_t * mpeg3tValueOf(int mpeg3tHandle);
#pragma export on
EXPORT(int) primitiveMPEG3AudioChannels(void);
EXPORT(int) primitiveMPEG3AudioSamples(void);
EXPORT(int) primitiveMPEG3CheckSig(void);
EXPORT(int) primitiveMPEG3Close(void);
EXPORT(int) primitiveMPEG3DropFrames(void);
EXPORT(int) primitiveMPEG3EndOfAudio(void);
EXPORT(int) primitiveMPEG3EndOfVideo(void);
EXPORT(int) primitiveMPEG3FrameRate(void);
EXPORT(int) primitiveMPEG3GenerateToc(void);
EXPORT(int) primitiveMPEG3GetFrame(void);
EXPORT(int) primitiveMPEG3GetSample(void);
EXPORT(int) primitiveMPEG3GetTime(void);
EXPORT(int) primitiveMPEG3HasAudio(void);
EXPORT(int) primitiveMPEG3HasVideo(void);
EXPORT(int) primitiveMPEG3Open(void);
EXPORT(int) primitiveMPEG3PreviousFrame(void);
EXPORT(int) primitiveMPEG3ReReadAudio(void);
EXPORT(int) primitiveMPEG3ReadAudio(void);
EXPORT(int) primitiveMPEG3ReadFrame(void);
EXPORT(int) primitiveMPEG3SampleRate(void);
EXPORT(int) primitiveMPEG3SeekPercentage(void);
EXPORT(int) primitiveMPEG3SetCpus(void);
EXPORT(int) primitiveMPEG3SetFrame(void);
EXPORT(int) primitiveMPEG3SetMmx(void);
EXPORT(int) primitiveMPEG3SetSample(void);
EXPORT(int) primitiveMPEG3TellPercentage(void);
EXPORT(int) primitiveMPEG3TotalAStreams(void);
EXPORT(int) primitiveMPEG3TotalVStreams(void);
EXPORT(int) primitiveMPEG3VideoFrames(void);
EXPORT(int) primitiveMPEG3VideoHeight(void);
EXPORT(int) primitiveMPEG3VideoWidth(void);
#pragma export off
static int removeFileEntry(mpeg3_t * aMpegFile);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off

static int checkFileEntry(mpeg3_t * aMpegFile) {
	int i;

	for (i = 1; i <= maximumNumberOfFilesToWatch; i += 1) {
		if ((mpegFiles[i]) == aMpegFile) {
			return 1;
		}
	}
	return 0;
}

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

EXPORT(int) initialiseModule(void) {
	int i;

	maximumNumberOfFilesToWatch = 1024;
	for (i = 1; i <= maximumNumberOfFilesToWatch; i += 1) {
		mpegFiles[i] = 0;
	}
	return true;
}

static int makeFileEntry(mpeg3_t * aMpegFile) {
	int i;

	for (i = 1; i <= maximumNumberOfFilesToWatch; i += 1) {
		if ((mpegFiles[i]) == 0) {
			mpegFiles[i] = aMpegFile;
			return 1;
		}
	}
	return 0;
}

static mpeg3_t * mpeg3tValueOf(int mpeg3tHandle) {
	int check;
	mpeg3_t ** index;

	interpreterProxy->success((interpreterProxy->isBytes(mpeg3tHandle)) && ((interpreterProxy->byteSizeOf(mpeg3tHandle)) == 4));
	if (interpreterProxy->failed()) {
		return null;
	} else {
		index = ((mpeg3_t **) (interpreterProxy->firstIndexableField(mpeg3tHandle)));
		check = checkFileEntry(*index);
		if (check == 0) {
			return null;
		}
		return *index;
	}
}

EXPORT(int) primitiveMPEG3AudioChannels(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber >= (mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_audio_channels(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3AudioSamples(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_audio_samples(file,aNumber);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3CheckSig(void) {
	char storage[1024] ;
	int result;
	int sz;
	char *path;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	path = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	sz = interpreterProxy->byteSizeOf(((int) (path) -4));
	sqFilenameFromStringOpen(storage, path, sz);
	//strncpy(storage,path,sz);
	//storage[sz] = 0;
	result = mpeg3_check_sig(storage);
	_return_value = (result? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3Close(void) {
	mpeg3_t ** index;
	mpeg3_t * file;
	int fileHandle;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	removeFileEntry(file); mpeg3_close(file);
	index = ((mpeg3_t **) (interpreterProxy->firstIndexableField(fileHandle)));
	*index = 0;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveMPEG3DropFrames(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aFrameNumber;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(2);
	aFrameNumber = interpreterProxy->stackIntegerValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	result = mpeg3_drop_frames(file,aFrameNumber,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3EndOfAudio(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_end_of_audio(file,aNumber);
	_return_value = (result? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3EndOfVideo(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_end_of_video(file,aNumber);
	_return_value = (result? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3FrameRate(void) {
	mpeg3_t * file;
	double result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result =  mpeg3_frame_rate(file,aNumber);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3GenerateToc(void) {
	mpeg3_t * file;
	int bufferSize;
	int fileHandle;
	int timecode;
	int streams;
	char *aString;

	fileHandle = interpreterProxy->stackValue(3);
	timecode = interpreterProxy->stackIntegerValue(2);
	streams = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	aString = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	bufferSize = interpreterProxy->slotSizeOf(interpreterProxy->stackValue(0));
	mpeg3_generate_toc_for_Squeak(file,timecode,streams,aString,bufferSize);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}

EXPORT(int) primitiveMPEG3GetFrame(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_get_frame(file,aNumber);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3GetSample(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_get_sample(file,aNumber);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3GetTime(void) {
	mpeg3_t * file;
	double result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	result = mpeg3_get_time(file);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3HasAudio(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	result = mpeg3_has_audio(file);
	_return_value = (result? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3HasVideo(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	result = mpeg3_has_video(file);
	_return_value = (result? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3Open(void) {
	char storage[1024];
	int mpeg3Oop;
	int sz;
	mpeg3_t ** index;
	char *path;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	path = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	sz = interpreterProxy->byteSizeOf(((int) (path) -4));
	sqFilenameFromStringOpen(storage, path, sz);
        //strncpy(storage,path,sz);
	//storage[sz] = 0;
	mpeg3Oop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), 4);
	index = ((mpeg3_t **) (interpreterProxy->firstIndexableField(mpeg3Oop)));
	*index = mpeg3_open(storage); makeFileEntry(*index);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, mpeg3Oop);
	return null;
}

EXPORT(int) primitiveMPEG3PreviousFrame(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (file == null) {
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_previous_frame(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3ReReadAudio(void) {
	mpeg3_t * file;
	int result;
	short * arrayBase;
	int fileHandle;
	int *anArray;
	int aChannelNumber;
	int aSampleNumber;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(4);
	interpreterProxy->success(interpreterProxy->isIndexable(interpreterProxy->stackValue(3)));
	anArray = ((int *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(3))));
	aChannelNumber = interpreterProxy->stackIntegerValue(2);
	aSampleNumber = interpreterProxy->stackIntegerValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(6, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(6, 0);
		return null;
	}
	arrayBase = ((short *) anArray);
	if (interpreterProxy->failed()) {
		return null;
	}
	result = mpeg3_reread_audio(file,(float *) NULL,arrayBase,aChannelNumber,aSampleNumber,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(6, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3ReadAudio(void) {
	mpeg3_t * file;
	int result;
	short * arrayBase;
	int fileHandle;
	int *anArray;
	int aChannelNumber;
	int aSampleNumber;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(4);
	interpreterProxy->success(interpreterProxy->isIndexable(interpreterProxy->stackValue(3)));
	anArray = ((int *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(3))));
	aChannelNumber = interpreterProxy->stackIntegerValue(2);
	aSampleNumber = interpreterProxy->stackIntegerValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(6, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(6, 0);
		return null;
	}
	arrayBase = ((short *) anArray);
	if (interpreterProxy->failed()) {
		return null;
	}
	result = mpeg3_read_audio(file,(float *) NULL,arrayBase,aChannelNumber,aSampleNumber,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(6, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3ReadFrame(void) {
	mpeg3_t * file;
	int result;
	int i;
	unsigned char  ** outputRowsPtr;
	unsigned char *bufferBaseAddr;
	int fileHandle;
	unsigned *aBuffer;
	int xNumber;
	int yNumber;
	int width;
	int height;
	int outWidth;
	int outHeight;
	int model;
	int aNumber;
	int aByteNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(10);
	interpreterProxy->success(interpreterProxy->isWords(interpreterProxy->stackValue(9)));
	aBuffer = ((unsigned *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(9))));
	xNumber = interpreterProxy->stackIntegerValue(8);
	yNumber = interpreterProxy->stackIntegerValue(7);
	width = interpreterProxy->stackIntegerValue(6);
	height = interpreterProxy->stackIntegerValue(5);
	outWidth = interpreterProxy->stackIntegerValue(4);
	outHeight = interpreterProxy->stackIntegerValue(3);
	model = interpreterProxy->stackIntegerValue(2);
	aNumber = interpreterProxy->stackIntegerValue(1);
	aByteNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(12, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(12, 0);
		return null;
	}
	bufferBaseAddr = ((unsigned char *) aBuffer);
	outputRowsPtr = (unsigned char **) memoryAllocate(1,sizeof(unsigned char*) * outHeight);
	for (i = 0; i <= (outHeight - 1); i += 1) {
		outputRowsPtr[i] = (bufferBaseAddr + (aByteNumber * i));
	}
	result = mpeg3_read_frame(file,outputRowsPtr,xNumber,yNumber,width,height,outWidth,outHeight,model,aNumber);
	memoryFree(outputRowsPtr);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(12, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3SampleRate(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_sample_rate(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3SeekPercentage(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	double aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackFloatValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (aNumber < 0.0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber > 1.0) {
		interpreterProxy->success(0);
		return null;
	}
	if (file == null) {
		return null;
	}
	result = mpeg3_seek_percentage(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3SetCpus(void) {
	mpeg3_t * file;
	int fileHandle;
	int cpus;

	fileHandle = interpreterProxy->stackValue(1);
	cpus = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (cpus < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (file == null) {
		return null;
	}
	mpeg3_set_cpus(file,cpus);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(int) primitiveMPEG3SetFrame(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	double aFrameNumber;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(2);
	aFrameNumber = interpreterProxy->stackFloatValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	result = mpeg3_set_frame(file,(long) aFrameNumber,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3SetMmx(void) {
	mpeg3_t * file;
	int fileHandle;
	int mmx;

	fileHandle = interpreterProxy->stackValue(1);
	mmx = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	mpeg3_set_mmx(file,mmx);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}

EXPORT(int) primitiveMPEG3SetSample(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	double aSampleNumber;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(2);
	aSampleNumber = interpreterProxy->stackFloatValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_astreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(4, 0);
		return null;
	}
	if (aSampleNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	result = mpeg3_set_sample(file,aSampleNumber,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3TellPercentage(void) {
	mpeg3_t * file;
	double result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	result = mpeg3_tell_percentage(file);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3TotalAStreams(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, 0);
		return null;
	}
	result = mpeg3_total_astreams(file);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3TotalVStreams(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		return null;
	}
	result = mpeg3_total_vstreams(file);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3VideoFrames(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_video_frames(file,aNumber);
	_return_value = interpreterProxy->floatObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3VideoHeight(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_video_height(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

EXPORT(int) primitiveMPEG3VideoWidth(void) {
	mpeg3_t * file;
	int result;
	int fileHandle;
	int aNumber;
	int _return_value;

	fileHandle = interpreterProxy->stackValue(1);
	aNumber = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	file = mpeg3tValueOf(fileHandle);
	if (file == null) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	if (aNumber < 0) {
		interpreterProxy->success(0);
		return null;
	}
	if (aNumber >= (result = mpeg3_total_vstreams(file))) {
		interpreterProxy->success(0);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, 0);
		return null;
	}
	result = mpeg3_video_width(file,aNumber);
	_return_value = interpreterProxy->integerObjectOf(result);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}

static int removeFileEntry(mpeg3_t * aMpegFile) {
	int i;

	for (i = 1; i <= maximumNumberOfFilesToWatch; i += 1) {
		if ((mpegFiles[i]) == aMpegFile) {
			mpegFiles[i] = 0;
			return 1;
		}
	}
	return 0;
}

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
	int i;

	for (i = 1; i <= maximumNumberOfFilesToWatch; i += 1) {
		if ((mpegFiles[i]) != 0) {
			mpeg3_close(mpegFiles[i]);
			mpegFiles[i] = 0;
		}
	}
	return true;
}
