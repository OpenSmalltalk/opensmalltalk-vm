/* Automatically generated from Squeak on #(18 March 2005 7:42:47 pm) */

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
#include "SoundPlugin.h"

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
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveSoundAvailableSpace(void);
EXPORT(int) primitiveSoundGetRecordingSampleRate(void);
EXPORT(int) primitiveSoundGetVolume(void);
EXPORT(int) primitiveSoundInsertSamples(void);
EXPORT(int) primitiveSoundPlaySamples(void);
EXPORT(int) primitiveSoundPlaySilence(void);
EXPORT(int) primitiveSoundRecordSamples(void);
EXPORT(int) primitiveSoundSetLeftVolume(void);
EXPORT(int) primitiveSoundSetRecordLevel(void);
EXPORT(int) primitiveSoundStart(void);
EXPORT(int) primitiveSoundStartRecording(void);
EXPORT(int) primitiveSoundStartWithSemaphore(void);
EXPORT(int) primitiveSoundStop(void);
EXPORT(int) primitiveSoundStopRecording(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off
static int sqAssert(int aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SoundPlugin 18 March 2005 (i)"
#else
	"SoundPlugin 18 March 2005 (e)"
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

EXPORT(int) initialiseModule(void) {
	return soundInit();
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Returns the number of bytes of available sound output buffer space.  This should be (frames*4) if the device is in stereo mode, or (frames*2) otherwise */

EXPORT(int) primitiveSoundAvailableSpace(void) {
	int frames;
	int _return_value;


	/* -1 if sound output not started */

	frames = snd_AvailableSpace();
	interpreterProxy->success(frames >= 0);
	_return_value = interpreterProxy->positive32BitIntegerFor(frames);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	Return a float representing the actual sampling rate during recording. Fail if not currently recording. */

EXPORT(int) primitiveSoundGetRecordingSampleRate(void) {
	double rate;
	int _return_value;


	/* fail if not recording */

	rate = snd_GetRecordingSampleRate();
	_return_value = interpreterProxy->floatObjectOf(rate);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	Set the sound input recording level. */

EXPORT(int) primitiveSoundGetVolume(void) {
	double left;
	double right;
	int results;

	left = 0;
	right = 0;
	snd_Volume((double *) &left,(double *) &right);
	interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(right));
	interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(left));
	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2));
	results = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, results, interpreterProxy->popRemappableOop());
	interpreterProxy->storePointerofObjectwithValue(1, results, interpreterProxy->popRemappableOop());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, results);
	return null;
}


/*	Insert a buffer's worth of sound samples into the currently playing  
	buffer. Used to make a sound start playing as quickly as possible. The  
	new sound is mixed with the previously buffered sampled. */
/*	Details: Unlike primitiveSoundPlaySamples, this primitive always starts  
	with the first sample the given sample buffer. Its third argument  
	specifies the number of samples past the estimated sound output buffer  
	position the inserted sound should start. If successful, it returns the  
	number of samples inserted. */

EXPORT(int) primitiveSoundInsertSamples(void) {
	int framesPlayed;
	int frameCount;
	unsigned *buf;
	int leadTime;
	int _return_value;

	frameCount = interpreterProxy->stackIntegerValue(2);
	interpreterProxy->success(interpreterProxy->isWords(interpreterProxy->stackValue(1)));
	buf = ((unsigned *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	leadTime = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(frameCount <= (interpreterProxy->slotSizeOf(((int) (buf) -4))));
	if (!(interpreterProxy->failed())) {
		framesPlayed = snd_InsertSamplesFromLeadTime(frameCount, (int)buf, leadTime);
		interpreterProxy->success(framesPlayed >= 0);
	}
	_return_value = interpreterProxy->positive32BitIntegerFor(framesPlayed);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	Output a buffer's worth of sound samples. */

EXPORT(int) primitiveSoundPlaySamples(void) {
	int framesPlayed;
	int frameCount;
	unsigned *buf;
	int startIndex;
	int _return_value;

	frameCount = interpreterProxy->stackIntegerValue(2);
	interpreterProxy->success(interpreterProxy->isWords(interpreterProxy->stackValue(1)));
	buf = ((unsigned *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	startIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success((startIndex >= 1) && (((startIndex + frameCount) - 1) <= (interpreterProxy->slotSizeOf(((int) (buf) -4)))));
	if (!(interpreterProxy->failed())) {
		framesPlayed = snd_PlaySamplesFromAtLength(frameCount, (int)buf, startIndex - 1);
		interpreterProxy->success(framesPlayed >= 0);
	}
	_return_value = interpreterProxy->positive32BitIntegerFor(framesPlayed);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	Output a buffer's worth of silence. Returns the number of sample frames played. */

EXPORT(int) primitiveSoundPlaySilence(void) {
	int framesPlayed;
	int _return_value;


	/* -1 if sound output not started */

	framesPlayed = snd_PlaySilence();
	interpreterProxy->success(framesPlayed >= 0);
	_return_value = interpreterProxy->positive32BitIntegerFor(framesPlayed);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	Record a buffer's worth of 16-bit sound samples. */

EXPORT(int) primitiveSoundRecordSamples(void) {
	int bufSizeInBytes;
	int samplesRecorded;
	unsigned *buf;
	int startWordIndex;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isWords(interpreterProxy->stackValue(1)));
	buf = ((unsigned *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	startWordIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->failed())) {
		bufSizeInBytes = (interpreterProxy->slotSizeOf(((int) (buf) -4))) * 4;
		interpreterProxy->success((startWordIndex >= 1) && (((startWordIndex - 1) * 2) < bufSizeInBytes));
	}
	if (!(interpreterProxy->failed())) {
		samplesRecorded = snd_RecordSamplesIntoAtLength((int)buf, startWordIndex - 1, bufSizeInBytes);
	}
	_return_value = interpreterProxy->positive32BitIntegerFor(samplesRecorded);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	Set the sound input recording level. */

EXPORT(int) primitiveSoundSetLeftVolume(void) {
	double aLeftVolume;
	double aRightVolume;

	aLeftVolume = interpreterProxy->stackFloatValue(1);
	aRightVolume = interpreterProxy->stackFloatValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->failed())) {
		snd_SetVolume(aLeftVolume,aRightVolume);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}


/*	Set the sound input recording level. */

EXPORT(int) primitiveSoundSetRecordLevel(void) {
	int level;

	level = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->failed())) {
		snd_SetRecordLevel(level);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}


/*	Start the double-buffered sound output with the given buffer size, sample rate, and stereo flag. */

EXPORT(int) primitiveSoundStart(void) {
	int bufFrames;
	int samplesPerSec;
	int stereoFlag;

	bufFrames = interpreterProxy->stackIntegerValue(2);
	samplesPerSec = interpreterProxy->stackIntegerValue(1);
	stereoFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(snd_Start(bufFrames, samplesPerSec, stereoFlag, 0));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}


/*	Start recording sound with the given parameters. */

EXPORT(int) primitiveSoundStartRecording(void) {
	int desiredSamplesPerSec;
	int stereoFlag;
	int semaIndex;

	desiredSamplesPerSec = interpreterProxy->stackIntegerValue(2);
	stereoFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	snd_StartRecording(desiredSamplesPerSec, stereoFlag, semaIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}


/*	Start the double-buffered sound output with the given buffer size, sample rate, stereo flag, and semaphore index. */

EXPORT(int) primitiveSoundStartWithSemaphore(void) {
	int bufFrames;
	int samplesPerSec;
	int stereoFlag;
	int semaIndex;

	bufFrames = interpreterProxy->stackIntegerValue(3);
	samplesPerSec = interpreterProxy->stackIntegerValue(2);
	stereoFlag = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(1));
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->success(snd_Start(bufFrames, samplesPerSec, stereoFlag, semaIndex));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}


/*	Stop double-buffered sound output. */

EXPORT(int) primitiveSoundStop(void) {
	snd_Stop();
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}


/*	Stop recording sound. */

EXPORT(int) primitiveSoundStopRecording(void) {
	snd_StopRecording();
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
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

EXPORT(int) shutdownModule(void) {
	return soundShutdown();
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SoundPlugin_exports[][3] = {
	{"SoundPlugin", "primitiveSoundAvailableSpace", (void*)primitiveSoundAvailableSpace},
	{"SoundPlugin", "primitiveSoundStartWithSemaphore", (void*)primitiveSoundStartWithSemaphore},
	{"SoundPlugin", "primitiveSoundStopRecording", (void*)primitiveSoundStopRecording},
	{"SoundPlugin", "primitiveSoundSetRecordLevel", (void*)primitiveSoundSetRecordLevel},
	{"SoundPlugin", "primitiveSoundGetRecordingSampleRate", (void*)primitiveSoundGetRecordingSampleRate},
	{"SoundPlugin", "primitiveSoundSetLeftVolume", (void*)primitiveSoundSetLeftVolume},
	{"SoundPlugin", "primitiveSoundPlaySamples", (void*)primitiveSoundPlaySamples},
	{"SoundPlugin", "primitiveSoundInsertSamples", (void*)primitiveSoundInsertSamples},
	{"SoundPlugin", "initialiseModule", (void*)initialiseModule},
	{"SoundPlugin", "shutdownModule", (void*)shutdownModule},
	{"SoundPlugin", "primitiveSoundStop", (void*)primitiveSoundStop},
	{"SoundPlugin", "primitiveSoundStartRecording", (void*)primitiveSoundStartRecording},
	{"SoundPlugin", "primitiveSoundRecordSamples", (void*)primitiveSoundRecordSamples},
	{"SoundPlugin", "primitiveSoundPlaySilence", (void*)primitiveSoundPlaySilence},
	{"SoundPlugin", "primitiveSoundStart", (void*)primitiveSoundStart},
	{"SoundPlugin", "primitiveSoundGetVolume", (void*)primitiveSoundGetVolume},
	{"SoundPlugin", "getModuleName", (void*)getModuleName},
	{"SoundPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

