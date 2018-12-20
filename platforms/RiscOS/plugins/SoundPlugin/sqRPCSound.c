//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCSound.c
// It provides Squeak with access to the RISC OS sound system as
// implemented by John Duffell's very neat SharedSoundBuffer/StreamManager
// modules. Furthermore, my understanding of how to make use of John's modules
// relied on reading Andrew Sellors excellent code for !RDPClient.
// Thank you both.

// #define DEBUG

#include "sq.h"
#include "SoundPlugin.h"
#include "kernel.h"
#include "sqRPCSound.h"



extern struct		VirtualMachine * interpreterProxy;
static unsigned		sound_initialised = false;
static int			sound_handle = 0;
static int			sound_stream = 0;
static unsigned		sound_volume = 0; // this ought to be queriable from system
static unsigned char *sound_global_buffer_data = NULL;
static int			sound_global_buffer_length = 0;
static int			sound_buffersize = 0;
static unsigned int * soundPollWordAddr = 0;
static int			soundPollBit = 0;
extern int			setupSoundSignalling(unsigned int ** addr, int * flagBit, int semIndex);


/*********************/
/* internal routines */
/*********************/


static void ssb_closestream(int handle) {
	_kernel_swi_regs r;
	PRINTF(("ssb close %d\n", handle));

	r.r[0] = (int)handle;

	_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_CloseStream, &r, &r);
}

static unsigned ssb_openstream(char *name, unsigned set_expected_size, int expected_size, int *handle) {
	_kernel_swi_regs r;
	unsigned success = false;
	int flags = 0;

	PRINTF(("ssb open %s expected size: %d", name, expected_size));

	if(set_expected_size)
		flags = flags | 0x2;

	r.r[0] = (int)flags;
	r.r[1] = (int)name;
	r.r[2] = expected_size; // might be 0, see flag setting above

	if(_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_OpenStream, &r, &r) == NULL)
		success = true;

	*handle = (unsigned int)r.r[0];

	if (success) {
		PRINTF((" - suceeded with handle: %d\n", handle));
	} else {
		PRINTF((" failed\n"));
	};
	return(success);
}

static void ssb_pause(int handle, unsigned pause) {
	_kernel_swi_regs r;

	r.r[0] = (int)handle;
	r.r[1] = (int)(pause ? 0 : 1);

	if (pause) {PRINTF(("ssb pause\n"));} else {PRINTF(("ssb un-pause\n"));}

	_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_Pause, &r, &r);
}

static unsigned ssb_returnstreamhandle(int handle, int *stream) {
	_kernel_swi_regs r;

	*stream = 0;
	r.r[0] = (int)handle;
	if(_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_ReturnStreamHandle, &r, &r) == 0) {
		*stream = r.r[0];
		PRINTF(("ssb returnstreamhandle: %d\n", *stream));
		return true;
	}
	PRINTF(("ssb returnstreamhandle: failed\n"));

	return false;
}

static void ssb_samplerate(int handle, int samplerate) {
	_kernel_swi_regs r;

	r.r[0] = (int)handle;
	r.r[1] = (int)samplerate;

	PRINTF(("ssb setsamplerate: %d\n", samplerate>>10));
	_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_SampleRate, &r, &r);
}

static void ssb_streamend(int handle) {
// closes the stream but allows the buffers already filled to play out
	PRINTF(("ssb_streamend %08X\n", handle));
	_kernel_swi_regs r;

	r.r[0] = (int)handle;

	_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_StreamEnd, &r, &r);
}

static void ssb_volume(int handle, unsigned int volume) {
	_kernel_swi_regs r;

	r.r[0] = (int)handle;
	r.r[1] = (int)volume;

	PRINTF(("ssb setsvolume\n"));
	_kernel_swi(SWI_XOS_Bit | SWI_SharedSoundBuffer_Volume, &r, &r);
}

static unsigned ssb_getvolume(int handle) {
// this really needs to be done with a query SWI. Currently not implemented though
	PRINTF(("ssb getvolume\n"));
	return sound_volume;
}

static unsigned sm_addblock(int stream, unsigned char *block, int length) {
	_kernel_swi_regs r;

	r.r[0] = (int)stream;
	r.r[1] = (int)block;
	r.r[2] = (int)length;

	if(_kernel_swi(SWI_XOS_Bit | SWI_StreamManager_AddBlock, &r, &r) == NULL) {
		PRINTF(("sm addblock on stream: %d length: %d\n", stream, length));
		return true;
	}
	PRINTF(("sm addblock: failed\n"));

	return false;
}

static int sm_bufferstats(int stream) {
	_kernel_swi_regs r;
	int bytes_left = 0;

	r.r[0] = (int)stream;

	if(_kernel_swi(SWI_XOS_Bit | SWI_StreamManager_BufferStats, &r, &r) == 0)
		bytes_left = r.r[0] - r.r[1];
	PRINTF(("sm bufferstats: %d\n", bytes_left));

	/* This doesn't match the supposed doc
	* r0 = added
	* r1 = played
	* r2 = freed
	*/

	return(bytes_left);
}

static void sm_setbuffer(int stream, int max_bytes) {
	_kernel_swi_regs r;

	r.r[0] = (int)stream;
	r.r[1] = (int)max_bytes;
	PRINTF(("sm setbuffer\n"));

	_kernel_swi(SWI_XOS_Bit | SWI_StreamManager_SetBuffer, &r, &r);
}

static void sm_setdalimits(int da_max_bytes, int heap_max_bytes) {
	_kernel_swi_regs r;

	r.r[0] = (int)da_max_bytes;
	r.r[1] = (int)heap_max_bytes;
	PRINTF(("sm setdalimits da: %d heap: %d\n", da_max_bytes, heap_max_bytes));

	_kernel_swi(SWI_XOS_Bit | SWI_StreamManager_SetDALimits, &r, &r);
}

static int * sm_srcpollword(int stream, int flags, unsigned int * pollwordptr, int bittoset) {
	_kernel_swi_regs r;

	r.r[0] = stream;
	r.r[1] = flags; // only bit 0 has any effect
	r.r[2] = (int)pollwordptr;
	r.r[3] = bittoset;
	PRINTF(("sm set src pollword stream: %d flag: %d ptr: %08X bit: %d\n", r.r[0], r.r[1], (int)(r.r[2]), r.r[3]));

	_kernel_swi(SWI_XOS_Bit | SWI_StreamManager_SrcPollWord, &r, &r);
	return (int *)r.r[0];
}

/**********************************/
/* module initialization/shutdown */
/**********************************/

sqInt soundInit(void) {
// make sure all state variables are setup ok
	sound_initialised = false;
	sound_handle = 0;
	sound_stream = 0;
	sound_global_buffer_data = NULL;
	sound_global_buffer_length = 0;
	sound_buffersize = 0;

	PRINTF(("soundInit\n"));
	return true;
}

sqInt soundShutdown(void) {
// close down the streams etc
	PRINTF(("soundShutdown\n"));

	if(sound_initialised){
		setupSoundSignalling(NULL, NULL, NULL);
		ssb_closestream(sound_handle);
		sound_initialised = false;
	}
	return true;
}

/****************/
/* sound output */
/****************/

sqInt snd_AvailableSpace(void) {

// Returns the number of bytes of available sound output buffer space.
// This should be (frames*4) if the device is in stereo mode,
// or (frames*2) otherwise
// Note that we are not supporting non-stereo anyway
	if (!sound_initialised) {
		PRINTF(("snd_availableSpace failed - sound not initialised\n"));
		return -1;
	}
	PRINTF(("snd_availableSpace: \n")); // sm_bufferstats prints the number
	return (sound_buffersize - sm_bufferstats(sound_stream));
}

sqInt snd_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime) {

/*	Insert a buffer's worth of sound samples into the currently playing
	buffer. Used to make a sound start playing as quickly as possible. The
	new sound is mixed with the previously buffered sampled. */
/*	Details: Unlike primitiveSoundPlaySamples, this primitive always starts
	with the first sample the given sample buffer. Its third argument
	specifies the number of samples past the estimated sound output buffer
	position the inserted sound should start. If successful, it returns the
	number of samples inserted. */
	PRINTF(("snd_InsertSamplesFromLeadTime - not supported\n"));
	return 0;
}

sqInt snd_PlaySamplesFromAtLength(sqInt frameCount, void *arrayIndex, sqInt startIndex) {
// Output a frameCount sound samplesfrom the passed in array, starting from startIndex.
// return the number actually 'played'; though no one uses it
	if (!sound_initialised) {
		interpreterProxy->success(false);
		PRINTF(("snd_PlatSamplesFrom failed - sound not initialised\n"));
		return false;
	}
	PRINTF(("snd_PlaySamplesFrom: %d At: %d Length: %d", arrayIndex, startIndex, frameCount));
	sm_addblock(sound_stream, (unsigned char *)((int)arrayIndex + startIndex), BYTESFROMSAMPLES(frameCount));
	ssb_pause(sound_handle, false);
	return frameCount;
}

sqInt snd_PlaySilence(void) {
/*	Output a buffer's worth of silence. Returns the number of sample frames played. */
// What? Doesn't appear to be used, has no readily apparent purpose
	PRINTF(("snd_PlaySilence\n"));
	interpreterProxy->success(false);
	return 42;
}

sqInt snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex) {
// Start the buffered sound output with the given buffer size, sample rate, stereo flag and semaphore index.
	extern char sqTaskName[];

	PRINTF(("snd_Start"));

	// looks a bit strange but first thing we do is shut down any pre-existing sound stream
	soundShutdown();
	if(!sound_initialised) {
		PRINTF((" initialising sound setup\n"));
		// before bothering the sound sysem we check that RISC OS is ready for it
		if ( !setupSoundSignalling(&soundPollWordAddr,&soundPollBit, semaIndex)) {
			return false;
		}
		sm_setdalimits(SOUND_DA_MAX_SIZE, SOUND_HEAP_MAX_SIZE);
		if(ssb_openstream(sqTaskName, true,BYTESFROMSAMPLES(frameCount), &sound_handle)) {
			if(ssb_returnstreamhandle(sound_handle, &sound_stream)) {
				sound_buffersize =  SOUND_BUFFER_SIZE(frameCount);
				sm_setbuffer(sound_stream, sound_buffersize);
				ssb_volume(sound_handle, 0xFFFFFFFF);
				ssb_samplerate(sound_handle, samplesPerSec << 10);// uses 1/1024Hz units
				sm_srcpollword(sound_stream, 0, soundPollWordAddr, soundPollBit);
				ssb_pause(sound_handle, true);
				sound_initialised = true;
			}
			else {
				ssb_closestream(sound_handle);
			}
		}
		if(!sound_initialised){
			sound_handle = 0;
			sound_stream = 0;
			setupSoundSignalling(NULL, NULL, NULL);
			PRINTF(("snd_Start failed to init\n"));
			return false;
		}
	}
	PRINTF(("snd_Start initialised OK\n"));

	return true;
}

sqInt snd_Stop(void) {
	PRINTF(("snd_Stop\n"));
	// cancel any further signalling
	//	setupSoundSignalling(NULL, NULL, NULL);
	//	// let the stream get to its end and then close
	//	if ( sound_initialised) {
	//		ssb_streamend(sound_handle);
	//		sound_handle = 0;
	//		sound_stream = 0;
	//		sound_initialised = false;
	//	}
	soundShutdown();
	return null;
}


void snd_Volume(double *left, double *right) {
// used to GET the volume settings
unsigned int leftVol, rightVol;
// get the volume and make doubles out if it
// there ought to be a SWI for this but currently we have to simply record it manually
	leftVol = sound_volume >> 16;
	rightVol = sound_volume & 0xFFFF;
	*left = leftVol  / 65535.0;
	*right = rightVol / 65535.0;
	PRINTF(("snd_Volume %f:%f\n", *left, *right));
}

void snd_SetVolume(double left, double right) {
// used to SET the volume settings
unsigned int leftVol, rightVol;

	leftVol = (unsigned int)((left > 1.0 ? 1.0 : left) * 0xFFFF) & 0xFFFF;
	rightVol = (unsigned int)((right > 1.0 ? 1.0 : right) * 0xFFFF) & 0xFFFF;
	sound_volume = (leftVol << 16) | rightVol;
	PRINTF(("snd_SetVolume %f:%f\n", left, right));
	if (sound_initialised) {
		ssb_volume(sound_handle, sound_volume) ;
	}
}

/***************/
/* sound input */
/***************/


void snd_SetRecordLevel(sqInt level) {
	return;
}

sqInt snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex) {
	return null;
}

sqInt snd_StopRecording(void) {
	return null;
}

double snd_GetRecordingSampleRate(void) {
	return (double)1.0;
}

sqInt snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes) {
	return null;
}
