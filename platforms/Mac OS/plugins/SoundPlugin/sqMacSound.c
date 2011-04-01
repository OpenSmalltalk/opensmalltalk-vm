/*
Carbon porting notes:

	Carbon doesn't support the SndPlayDoubleBuffer system routine.
	This is a command you put in the sound channel which repeatedly
	calls a callback routine.
	
	Technote 1198 describes the situation, a work-around and provides
	example code.  I merely added this code to the end of this file
	and plugged it into the existing Squeak code.

Karl Goiser 14/01/01
*/

//johnmci@smalltalkconsulting.com Nov 6th 2000. Added sound volume logic

/* Adjustments for pluginized VM
 *
 * Note: The Mac support files have not yet been fully converted to
 * pluginization. For the time being, it is assumed that they are linked
 * with the VM. When conversion is complete, they will no longer import
 * "sq.h" and they will access all VM functions and variables through
 * the interpreterProxy mechanism.
 */
 
#include "sq.h"
#include "SoundPlugin.h"
#if TARGET_API_MAC_CARBON
	#include <Carbon/Carbon.h>
#else
	#include <Sound.h>
	#include <SoundInput.h>
#endif
extern struct VirtualMachine* interpreterProxy;
 
/* initialize/shutdown */
int soundInit() { return true; }
int soundShutdown() { snd_Stop(); 	return 1;}

/* End of adjustments for pluginized VM */


/******
  Mac Sound Output Notes:

	The Squeak sound code produces 16-bit, stereo sound buffers. The was
	arrived at after experimentation on a PPC 601 at 110 MHz on which I
	found that:
	  a. using 16-bit sound only slightly increased the background CPU burden and
	  b. 16-bit sound yielded vastly superior sound quality.

	My understanding is that SoundManager 3.0 or later supports the 16-bit
	sound interface an all Macs, even if the hardware only supports 8-bits.
	If this is not true, however, change BYTES_PER_SAMPLE to 1. Then, either
	the Squeak code will need to be changed to use 8-bit sound buffers,
	or (preferrably) snd_PlaySamplesFromAtLength will need to do the conversion
	from 16 to 8 bits. I plan to cross that bridge if and when we need to.
	The code as currently written was to support Squeak code that generated
	8-bit sound buffers.

	In earlier versions, I experimented with other sound buffer formats. Here
	are all the sound buffer formats that were used at one point or another:
		1. mono,    8-bits -- packed array of bytes (not currently used)
		2. stereo,  8-bits -- as above, with L and R channels in alternate bytes (not currently used)
		3. stereo, 16-bits -- array of 32-bit words; with L and R channels in high and low half-words

	Note:  8-bit samples are encoded with 0x80 as the center (zero) value
	Note: 16-bit samples are encoded as standard, signed integers (i.e., 2's-complement)
	Note: When the sound drive is operating in "mono", the two stereo channels are mixed
	      together. This feature was added in January, 1998.

	-- John Maloney, July 28, 1996
	-- edited: John Maloney, January 5, 1998

  Mac Sound Input Notes:

	Squeak sound input is currently defined to provide a single (mono) stream
	of signed 16-bit samples for all platforms. Platforms that only support
	8-bit sound input should convert samples to signed 16 bit values, leaving
	the low order bits zero. Since the available sampling rates differ from
	platform to platform, the client may not get the requested sampling rate;
	however, the call snd_GetRecordingSampleRate returns the sampling rate.
	On many platforms, simultaneous record and playback is permitted only if
	the input and output sampling rates are the same.

	-- John Maloney, Aug 22, 1997

******/

#define BYTES_PER_SAMPLE 2

/*** double-buffer state record ***/

typedef struct {
	int open;
	int stereo;
	int frameCount;
	int sampleRate;
	int lastFlipTime;
	int playSemaIndex;
	int bufSizeInBytes;
	int bufState0;
	int bufState1;
	int done;
} PlayStateRec;

/*** possible buffer states ***/

#define BUF_EMPTY	0
#define BUF_FULL	1
#define BUF_PLAYING	2

/*** record buffer state record ***/

/* Note: RECORD_BUFFER_SIZE should be a multiple of 4096 bytes to avoid clicking.
   (The clicking was observed on a Mac 8100; the behavior of other Macs could differ.)
   Note: G3 Series Powerbook requires minimum of 4 * 4096 buffer size for stereo.
*/
#define RECORD_BUFFER_SIZE (4096 * 2)

typedef struct {
	SPB paramBlock;
	int stereo;
        int brokenOSXWasMono;
	int bytesPerSample;
	int recordSemaIndex;
	int readIndex;  /* index of the next sample to read */
	char samples[RECORD_BUFFER_SIZE];
} RecordBufferRec, *RecordBuffer;

#if (defined ( __APPLE__ ) && defined ( __MACH__ )) || TARGET_API_MAC_CARBON
enum {
  dbBufferReady                 = 0x00000001, /*double buffer is filled*/
  dbLastBuffer                  = 0x00000004 /*last double buffer to play*/
};
struct SndDoubleBuffer {
  long                dbNumFrames;
  long                dbFlags;
  long                dbUserInfo[2];
  SInt8               dbSoundData[1];
};


typedef struct SndDoubleBuffer          SndDoubleBuffer;
typedef SndDoubleBuffer *               SndDoubleBufferPtr;
typedef CALLBACK_API( void , SndDoubleBackProcPtr )(SndChannelPtr channel, SndDoubleBufferPtr doubleBufferPtr);
typedef STACK_UPP_TYPE(SndDoubleBackProcPtr)                    SndDoubleBackUPP;

struct SndDoubleBufferHeader {
  short               dbhNumChannels;
  short               dbhSampleSize;
  short               dbhCompressionID;
  short               dbhPacketSize;
  UnsignedFixed       dbhSampleRate;
  SndDoubleBufferPtr  dbhBufferPtr[2];
  SndDoubleBackUPP    dbhDoubleBack;
};
typedef struct SndDoubleBufferHeader    SndDoubleBufferHeader;
typedef SndDoubleBufferHeader *         SndDoubleBufferHeaderPtr;
struct SndDoubleBufferHeader2 {
  short               dbhNumChannels;
  short               dbhSampleSize;
  short               dbhCompressionID;
  short               dbhPacketSize;
  UnsignedFixed       dbhSampleRate;
  SndDoubleBufferPtr  dbhBufferPtr[2];
  SndDoubleBackUPP    dbhDoubleBack;
  OSType              dbhFormat;
};
typedef struct SndDoubleBufferHeader2   SndDoubleBufferHeader2;
typedef SndDoubleBufferHeader2 *        SndDoubleBufferHeader2Ptr;
#endif

/*** sound output variables ***/

SndChannelPtr chan;
PlayStateRec bufState = {false, false, 0, 0, 0, 0, 0, 0, 0, true};
SndDoubleBufferHeader dblBufHeader;

/*** sound input variables ***/

RecordBufferRec recordBuffer1, recordBuffer2;
int recordingInProgress;
long soundInputRefNum;

/*** local functions ***/

pascal void DoubleBack(SndChannelPtr chan, SndDoubleBufferPtr buf);
int FillBufferWithSilence(SndDoubleBufferPtr buf);
pascal void FlipRecordBuffers(SPBPtr pb);
int MixInSamples(int count, char *srcBufPtr, int srcStartIndex, char *dstBufPtr, int dstStartIndex);

OSErr CarbonSndPlayDoubleBuffer (SndChannelPtr chan, SndDoubleBufferHeaderPtr theParams);


pascal void DoubleBack(SndChannelPtr chan, SndDoubleBufferPtr buf) {
  /* Switch buffers (at interrupt time). The given buffer just finished playing. */

	PlayStateRec *state;

	#pragma unused(chan)  /* reference argument to avoid compiler warnings */

	state = (PlayStateRec *) buf->dbUserInfo[0];
	if (buf->dbUserInfo[1] == 0) {
		state->bufState0 = BUF_EMPTY;
		state->bufState1 = BUF_PLAYING;
	} else {
		state->bufState0 = BUF_PLAYING;
		state->bufState1 = BUF_EMPTY;
	}

	buf->dbNumFrames = state->frameCount;
	buf->dbFlags = buf->dbFlags | dbBufferReady;
	if (state->done) {
		buf->dbFlags = buf->dbFlags | dbLastBuffer;
	} else {
		interpreterProxy->signalSemaphoreWithIndex(state->playSemaIndex);
	}
	state->lastFlipTime = interpreterProxy->ioMicroMSecs();
	FillBufferWithSilence(buf);  /* avoids ugly stutter if not filled in time */
}

int FillBufferWithSilence(SndDoubleBufferPtr buf) {
	unsigned int *sample, *lastSample;

	sample		= (unsigned int *) &buf->dbSoundData[0];
	lastSample	= (unsigned int *) &buf->dbSoundData[bufState.bufSizeInBytes];

	/* word-fill buffer with silence */
	if (BYTES_PER_SAMPLE == 1) {
		while (sample < lastSample) {
			*sample++ = 0x80808080;  /* Note: 0x80 is zero value for 8-bit samples */
		}
	} else {
		while (sample < lastSample) {
			*sample++ = 0;
		}
	}
	return 0;
}

pascal void FlipRecordBuffers(SPBPtr pb) {
	/* called at interrupt time to exchange the active and inactive record buffers */
	RecordBuffer thisBuffer = (RecordBuffer) pb;
	RecordBuffer nextBuffer = (RecordBuffer) pb->userLong;

	if (pb->error == 0) {
  		/* restart recording using the other buffer */
		SPBRecord(&nextBuffer->paramBlock, true);
		/* reset the read pointer for the buffer that has just been filled */
		thisBuffer->readIndex = 0;
		interpreterProxy->signalSemaphoreWithIndex(nextBuffer->recordSemaIndex);
	}
}

/*** exported sound output functions ***/

int snd_AvailableSpace(void) {
	if (!bufState.open) return -1;
	if ((bufState.bufState0 == BUF_EMPTY) ||
		(bufState.bufState1 == BUF_EMPTY)) {
			return bufState.bufSizeInBytes;
	}
	return 0;
}

int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex) {
	SndDoubleBufferPtr buf;
	int framesWritten;

	if (!bufState.open) return -1;

	if (bufState.bufState0 == BUF_EMPTY) {
		buf = dblBufHeader.dbhBufferPtr[0];
		bufState.bufState0 = BUF_FULL;
	} else {
		if (bufState.bufState1 == BUF_EMPTY) {
			buf = dblBufHeader.dbhBufferPtr[1];
			bufState.bufState1 = BUF_FULL;
		} else {
			return 0;  /* neither buffer is available */
		}
	}

	if (bufState.frameCount < frameCount) {
		framesWritten = bufState.frameCount;
	} else {
		framesWritten = frameCount;
	}

	if (BYTES_PER_SAMPLE == 1) {  /* 8-bit samples */
		unsigned char *src, *dst, *end;
		src = (unsigned char *) (arrayIndex + startIndex);
		end = (unsigned char *) src + (framesWritten * (bufState.stereo ? 2 : 1));
		dst = (unsigned char *) &buf->dbSoundData[0];
		while (src < end) {
			*dst++ = *src++;
		}
	} else {  /* 16-bit samples */
		short int *src, *dst, *end;
		src = (short int *) (arrayIndex + (startIndex * 4));
		end = (short int *) (arrayIndex + ((startIndex + framesWritten) * 4));
		dst = (short int *) &buf->dbSoundData[0];
		if (bufState.stereo) {  /* stereo */
			while (src < end) {
				*dst++ = *src++;
			}
		} else {  /* mono */
			/* if mono, average the left and right channels of the source */
			unsigned int a,b;
			while (src < end) {
				a = *src++;
				b = *src++;
				*dst++ = (a+b) / 2;
			}
		}
	}
	return framesWritten;
}

int MixInSamples(int count, char *srcBufPtr, int srcStartIndex, char *dstBufPtr, int dstStartIndex) {
	int sample;

	if (BYTES_PER_SAMPLE == 1) {  /* 8-bit samples */
		unsigned char *src, *dst, *end;
		src = (unsigned char *) srcBufPtr + srcStartIndex;
		end = (unsigned char *) srcBufPtr + (count * (bufState.stereo ? 2 : 1));
		dst = (unsigned char *) dstBufPtr + dstStartIndex;
		while (src < end) {
			sample = *dst + (*src++ - 128);
			if (sample > 255) sample = 255;
			if (sample < 0) sample = 0;
			*dst++ = sample;
		}
	} else {  /* 16-bit samples */
		short int *src, *dst, *end;
		src = (short int *) (srcBufPtr + (srcStartIndex * 4));
		end = (short int *) (srcBufPtr + ((srcStartIndex + count) * 4));
		if (bufState.stereo) {  /* stereo */
			dst = (short int *) (dstBufPtr + (dstStartIndex * 4));
			while (src < end) {
				sample = *dst + *src++;
				if (sample > 32767) sample = 32767;
				if (sample < -32767) sample = -32767;
				*dst++ = sample;
			}
		} else {  /* mono */
			/* if mono, average the left and right channels of the source */
			unsigned int a,b;
			dst = (short int *) (dstBufPtr + (dstStartIndex * 2));
			while (src < end) {
				a = *src++;
				b = *src++;
				sample = *dst + ((a+b) / 2);
				if (sample > 32767) sample = 32767;
				if (sample < -32767) sample = -32767;
				*dst++ = sample;
			}
		}
	}
	return 0;
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime) {
	SndDoubleBufferPtr bufPlaying, otherBuf;
	int samplesInserted, startSample, count;

	if (!bufState.open) return -1;

	if (bufState.bufState0 == BUF_PLAYING) {
		bufPlaying = dblBufHeader.dbhBufferPtr[0];
		otherBuf = dblBufHeader.dbhBufferPtr[1];
	} else {
		bufPlaying = dblBufHeader.dbhBufferPtr[1];
		otherBuf = dblBufHeader.dbhBufferPtr[0];
	}

	samplesInserted = 0;

	/* mix as many samples as can fit into the remainder of the currently playing buffer */
	startSample =
		((bufState.sampleRate * (interpreterProxy->ioMicroMSecs() - bufState.lastFlipTime)) / 1000) + samplesOfLeadTime;
	if (startSample < bufState.frameCount) {
		count = bufState.frameCount - startSample;
		if (count > frameCount) count = frameCount;
		MixInSamples(count, (char *) srcBufPtr, 0, (char *) &bufPlaying->dbSoundData[0], startSample);
		samplesInserted = count;
	}

	/* mix remaining samples into the inactive buffer */
	count = bufState.frameCount;
	if (count > (frameCount - samplesInserted)) {
		count = frameCount - samplesInserted;
	}
	MixInSamples(count, (char *) srcBufPtr, samplesInserted, (char *) &otherBuf->dbSoundData[0], 0);
	return samplesInserted + count;
}

int snd_PlaySilence(void) {
	if (!bufState.open) return -1;

	if (bufState.bufState0 == BUF_EMPTY) {
		FillBufferWithSilence(dblBufHeader.dbhBufferPtr[0]);
		bufState.bufState0 = BUF_FULL;
	} else {
		if (bufState.bufState1 == BUF_EMPTY) {
			FillBufferWithSilence(dblBufHeader.dbhBufferPtr[1]);
			bufState.bufState1 = BUF_FULL;
		} else {
			return 0;  /* neither buffer is available */
		}
	}
	return bufState.bufSizeInBytes;
}

int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex) {
	OSErr				err;
	SndDoubleBufferPtr	buffer;
	int					bytesPerFrame, bufferBytes, i;

	bytesPerFrame			= stereo ? 2 * BYTES_PER_SAMPLE : BYTES_PER_SAMPLE;
	bufferBytes				= ((frameCount * bytesPerFrame) / 8) * 8;
		/* Note: Must round bufferBytes down to an 8-byte boundary to avoid clicking!!! */

	if (bufState.open) {
		/* still open from last time; clean up before continuing */
		snd_Stop();
	}

	bufState.open			= false;  /* set to true if successful */
	bufState.stereo			= stereo;
	bufState.frameCount		= bufferBytes / bytesPerFrame;
	bufState.sampleRate		= samplesPerSec;
	bufState.lastFlipTime	= interpreterProxy->ioMicroMSecs();
	bufState.playSemaIndex	= semaIndex;
	bufState.bufSizeInBytes	= bufferBytes;
	bufState.bufState0		= BUF_EMPTY;
	bufState.bufState1		= BUF_EMPTY;
	bufState.done			= false;

	dblBufHeader.dbhNumChannels		= stereo ? 2 : 1;
	dblBufHeader.dbhSampleSize		= BYTES_PER_SAMPLE * 8;
	dblBufHeader.dbhCompressionID	= 0;
	dblBufHeader.dbhPacketSize		= 0;
	dblBufHeader.dbhSampleRate		= samplesPerSec << 16; /* convert to fixed point */
#if TARGET_API_MAC_CARBON
	dblBufHeader.dbhDoubleBack		= nil;
#else
	dblBufHeader.dbhDoubleBack		= NewSndDoubleBackProc(DoubleBack);
#endif

	chan = NULL;
	err = SndNewChannel(&chan, sampledSynth, 0, NULL);
	if (err != noErr) return false; /* could not open sound channel */

	for (i = 0; i < 2; i++) {
		buffer = (SndDoubleBufferPtr) NewPtrClear(sizeof(SndDoubleBuffer) + bufState.bufSizeInBytes);
		if (buffer == NULL) {   /* could not allocate memory for a buffer; clean up and abort */
			SndDisposeChannel(chan, true);
#if !TARGET_API_MAC_CARBON
			DisposeRoutineDescriptor(dblBufHeader.dbhDoubleBack);
#endif
			if (i == 1) {  /* free the first buffer */
				DisposePtr((char *) dblBufHeader.dbhBufferPtr[1]);
				dblBufHeader.dbhBufferPtr[1] = NULL;
			}
			return false;
		}
		buffer->dbNumFrames		= bufState.frameCount;
		buffer->dbFlags			= dbBufferReady;
		buffer->dbUserInfo[0]	= (long) &bufState;
		buffer->dbUserInfo[1]	= i;
		FillBufferWithSilence(buffer);

		dblBufHeader.dbhBufferPtr[i] = buffer;
	}

#if TARGET_API_MAC_CARBON
	err = CarbonSndPlayDoubleBuffer(chan, &dblBufHeader);
#else
	err = SndPlayDoubleBuffer(chan, &dblBufHeader);
#endif
	if (err != noErr) return false; /* could not play double buffer */

	bufState.open = true;
	return true;
}

int snd_Stop(void) {
	OSErr				err;
	SndDoubleBufferPtr	buffer;
	SCStatus			status;
	long				i, junk;

	if (!bufState.open) return 0;
	bufState.open = false;

	bufState.done = true;
	while (true) {
		err = SndChannelStatus(chan, sizeof(status), &status);
		if (err != noErr) break; /* could not get channel status */
		if (!status.scChannelBusy) break;
		Delay(1, (void *) &junk);
	}
	SndDisposeChannel(chan, true);
#if !TARGET_API_MAC_CARBON
	DisposeRoutineDescriptor(dblBufHeader.dbhDoubleBack);
#endif

	for (i = 0; i < 2; i++) {
		buffer = dblBufHeader.dbhBufferPtr[i];
		if (buffer != NULL) {
			DisposePtr((char *) buffer);
		}
		dblBufHeader.dbhBufferPtr[i] = NULL;
	}
	bufState.open = false;
	return 0;
}

/*** exported sound input functions ***/

int snd_SetRecordLevel(int level) {
	/* set the recording level to a value between 0 (minimum gain) and 1000. */
	Fixed inputGainArg;
	int err;

	if (!recordingInProgress || (level < 0) || (level > 1000)) {
		interpreterProxy->success(false);
		return 0;  /* noop if not recording */
	}

	inputGainArg = ((500 + level) << 16) / 1000;  /* gain is Fixed between 0.5 and 1.5 */
	err = SPBSetDeviceInfo(soundInputRefNum, siInputGain, &inputGainArg);
	/* don't fail on error; hardware may not support setting the gain */
	return 0;
}

int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex) {
	/* turn on sound recording, trying to use a sampling rate close to
	   the one specified. semaIndex is the index in the exportedObject
	   array of a semaphore to be signalled when input data is available. */
	Str255 deviceName = "\p";
	short automaticGainControlArg;
	Fixed inputGainArg;
	long  compressionTypeArg;
	short continuousArg;
	short sampleSizeArg;
	short channelCountArg;
	UnsignedFixed sampleRateArg;
	int err;
        long 	brokenOSXWasMono=0;
        
	err = SPBOpenDevice(deviceName, siWritePermission, &soundInputRefNum);
	if (err != noErr) {
		interpreterProxy->success(false);
		return 0;
	}

	channelCountArg = stereo ? 2 : 1;
	err = SPBSetDeviceInfo(soundInputRefNum, siNumberChannels, &channelCountArg);
	if (err == notEnoughHardwareErr) {
            stereo = 1;
            brokenOSXWasMono = 1;
            channelCountArg = stereo ? 2 : 1;
            err = SPBSetDeviceInfo(soundInputRefNum, siNumberChannels, &channelCountArg);
        }
        if (err != noErr) {
                interpreterProxy->success(false);
                SPBCloseDevice(soundInputRefNum);
                return 0;
        }

	/* try to initialize some optional parameters, but don't fail if we can't */
	automaticGainControlArg = false;
	SPBSetDeviceInfo(soundInputRefNum, siAGCOnOff, &automaticGainControlArg);
	inputGainArg = 1 << 16;  /* 1.0 in Fixed */
	SPBSetDeviceInfo(soundInputRefNum, siInputGain, &inputGainArg);
	compressionTypeArg = 'NONE';
	SPBSetDeviceInfo(soundInputRefNum, siCompressionType, &compressionTypeArg);

	continuousArg = true;
	err = SPBSetDeviceInfo(soundInputRefNum, siContinuous, &continuousArg);
	if (err != noErr) {
		interpreterProxy->success(false);
		SPBCloseDevice(soundInputRefNum);
		return 0;
	}

	sampleSizeArg = 16;
	err = SPBSetDeviceInfo(soundInputRefNum, siSampleSize, &sampleSizeArg);
	if (err != noErr) {
		/* use 8-bit samples */
		sampleSizeArg = 8;
		err = SPBSetDeviceInfo(soundInputRefNum, siSampleSize, &sampleSizeArg);
		if (err != noErr) {
			interpreterProxy->success(false);
			SPBCloseDevice(soundInputRefNum);
			return 0;
		}
	}

	/* try to set the client's desired sample rate */
	sampleRateArg = desiredSamplesPerSec << 16;
	err = SPBSetDeviceInfo(soundInputRefNum, siSampleRate, &sampleRateArg);
	if (err != noErr) {
		/* if client's rate fails, try the nearest common sampling rates in {11025, 22050, 44100} */
		if (desiredSamplesPerSec <= 16538) {
			sampleRateArg = 11025 << 16;
		} else {
			if (desiredSamplesPerSec <= 33075) {
				sampleRateArg = 22050 << 16;
			} else {
				sampleRateArg = 44100 << 16;
			}
		}
		/* even if following fails, recording can go on at the default sample rate */
		SPBSetDeviceInfo(soundInputRefNum, siSampleRate, &sampleRateArg);
	}

 	recordBuffer1.paramBlock.inRefNum = soundInputRefNum;
	recordBuffer1.paramBlock.count = RECORD_BUFFER_SIZE;
	recordBuffer1.paramBlock.milliseconds = 0;
	recordBuffer1.paramBlock.bufferLength = RECORD_BUFFER_SIZE;
	recordBuffer1.paramBlock.bufferPtr = recordBuffer1.samples;
#if TARGET_API_MAC_CARBON
	recordBuffer1.paramBlock.completionRoutine = NewSICompletionUPP(FlipRecordBuffers);
#else
	recordBuffer1.paramBlock.completionRoutine = NewSICompletionProc(FlipRecordBuffers);
#endif
	recordBuffer1.paramBlock.interruptRoutine = nil;
	recordBuffer1.paramBlock.userLong = (long) &recordBuffer2;  /* pointer to other buffer */
	recordBuffer1.paramBlock.error = noErr;
	recordBuffer1.paramBlock.unused1 = 0;
	recordBuffer1.stereo = stereo;
        recordBuffer1.brokenOSXWasMono = brokenOSXWasMono;
	recordBuffer1.bytesPerSample = sampleSizeArg == 8 ? 1 : 2;
	recordBuffer1.recordSemaIndex = semaIndex;
	recordBuffer1.readIndex = RECORD_BUFFER_SIZE;

	recordBuffer2.paramBlock.inRefNum = soundInputRefNum;
	recordBuffer2.paramBlock.count = RECORD_BUFFER_SIZE;
	recordBuffer2.paramBlock.milliseconds = 0;
	recordBuffer2.paramBlock.bufferLength = RECORD_BUFFER_SIZE;
	recordBuffer2.paramBlock.bufferPtr = recordBuffer2.samples;
#if TARGET_API_MAC_CARBON
	recordBuffer2.paramBlock.completionRoutine = NewSICompletionUPP(FlipRecordBuffers);
#else
	recordBuffer2.paramBlock.completionRoutine = NewSICompletionProc(FlipRecordBuffers);
#endif
	recordBuffer2.paramBlock.interruptRoutine = nil;
	recordBuffer2.paramBlock.userLong = (long) &recordBuffer1;  /* pointer to other buffer */
	recordBuffer2.paramBlock.error = noErr;
	recordBuffer2.paramBlock.unused1 = 0;
	recordBuffer2.stereo = stereo;
        recordBuffer2.brokenOSXWasMono = brokenOSXWasMono;
	recordBuffer2.bytesPerSample = sampleSizeArg == 8 ? 1 : 2;
	recordBuffer2.recordSemaIndex = semaIndex;
	recordBuffer2.readIndex = RECORD_BUFFER_SIZE;

        err = SPBRecord(&recordBuffer1.paramBlock, true);
	if (err != noErr) {
		interpreterProxy->success(false);
		SPBCloseDevice(soundInputRefNum);
		return 0;
	}

	recordingInProgress = true;
	return 0;
}

int snd_StopRecording(void) {
	/* turn off sound recording */
	int err;

	if (!recordingInProgress) return 0;  /* noop if not recording */

	err = SPBStopRecording(soundInputRefNum);
	if (err != noErr) interpreterProxy->success(false);
	SPBCloseDevice(soundInputRefNum);

#if TARGET_API_MAC_CARBON
	DisposeSICompletionUPP(recordBuffer1.paramBlock.completionRoutine);
#else
	DisposeRoutineDescriptor(recordBuffer1.paramBlock.completionRoutine);
#endif
	recordBuffer1.paramBlock.completionRoutine = nil;
#if TARGET_API_MAC_CARBON
	DisposeSICompletionUPP(recordBuffer2.paramBlock.completionRoutine);
#else
	DisposeRoutineDescriptor(recordBuffer2.paramBlock.completionRoutine);
#endif
	recordBuffer2.paramBlock.completionRoutine = nil;

	recordBuffer1.recordSemaIndex = 0;
	recordBuffer2.recordSemaIndex = 0;
	recordingInProgress = false;
	return 0;
}

double snd_GetRecordingSampleRate(void) {
	/* return the actual recording rate; fail if not currently recording */
	UnsignedFixed sampleRateArg;
	int err;

	if (!recordingInProgress) {
		interpreterProxy->success(false);
		return 0.0;
	}

	err = SPBGetDeviceInfo(soundInputRefNum, siSampleRate, &sampleRateArg);
	if (err != noErr) {
		interpreterProxy->success(false);
		return 0.0;
	}
	return  (double) ((sampleRateArg >> 16) & 0xFFFF) +
			((double) (sampleRateArg & 0xFFFF) / 65536.0);
}

int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) {
	/* if data is available, copy as many sample slices as possible into the
	   given buffer starting at the given slice index. do not write past the
	   end of the buffer, which is buf + bufferSizeInBytes. return the number
	   of slices (not bytes) copied. a slice is one 16-bit sample in mono
	   or two 16-bit samples in stereo. */
	int bytesPerSlice = (recordBuffer1.brokenOSXWasMono) ? 2 : ((recordBuffer1.stereo) ? 4 : 2);
	char *nextBuf = (char *) buf + (startSliceIndex * bytesPerSlice);
	char *bufEnd = (char *) buf + bufferSizeInBytes;
	char *src, *srcEnd;
	RecordBuffer recBuf = nil;
	int bytesCopied;

	if (!recordingInProgress) {
		interpreterProxy->success(false);
		return 0;
	}

	/* select the buffer with unread samples, if any */
	recBuf = nil;
	if (recordBuffer1.readIndex < RECORD_BUFFER_SIZE) recBuf = &recordBuffer1;
	if (recordBuffer2.readIndex < RECORD_BUFFER_SIZE) recBuf = &recordBuffer2;
	if (recBuf == nil) return 0;  /* no samples available */

	/* copy samples into the client's buffer */
	src = &recBuf->samples[0] + recBuf->readIndex;
	srcEnd = &recBuf->samples[RECORD_BUFFER_SIZE];
	if (recBuf->bytesPerSample == 1) {
		while ((src < srcEnd) && (nextBuf < bufEnd)) {
			/* convert 8-bit sample to 16-bit sample */
			*nextBuf++ = (*src++) - 128;  /* convert from [0-255] to [-128-127] */
			*nextBuf++ = 0;  /* low-order byte is zero */
		}
	} else {
		if (recordBuffer1.brokenOSXWasMono) {
                    src++;src++;
                     while ((src < srcEnd) && (nextBuf < bufEnd)) {
			*nextBuf++ = *src++; 
 			*nextBuf++ = *src++; 
                        src++;src++;
                    }
                } else {
                    while ((src < srcEnd) && (nextBuf < bufEnd)) {
			*nextBuf++ = *src++;
                    }
                }
	}
	recBuf->readIndex = src - &recBuf->samples[0];  /* update read index */

	/* return the number of slices copied */
	bytesCopied = (int) nextBuf - (buf + (startSliceIndex * bytesPerSlice));
	return bytesCopied / bytesPerSlice;
}


//Nov 6th 2000
void snd_Volume(double *left, double *right) {
	double temp;
	SndCommand cmd;
    long   results;
	OSErr  err;
	
	*left = 1.0;
	*right = 1.0;
	cmd.cmd = getVolumeCmd;
	cmd.param1 = 0;
	cmd.param2 = (long) &results;
	err = -1;
	if (chan != null)
	    err = SndDoImmediate(chan,&cmd);
	    
	if (err != noErr) {
	   err = GetDefaultOutputVolume(&results);
	}
	if (err != noErr) 
	    return;
	temp  = (results & 0xFFFF);
	*left = temp/256.0;
	
	temp = (results >> 16);
	*right = temp/256.0;
}

void snd_SetVolume(double left, double right) {
	unsigned long tempLeft,tempRight;
	SndCommand cmd;
	OSErr  err;
	
	tempLeft = left*256.0 + 0.5;
	tempLeft = tempLeft & 0xFFFF;
	tempRight = right*256.0 + 0.5;
	tempRight= tempRight & 0xFFFF;
	cmd.cmd = volumeCmd;
	cmd.param1 = 0;
	cmd.param2 = (tempRight << 16) | tempLeft;
	err = -1;
	if (chan != null)
	    err= SndDoImmediate(chan,&cmd);
	if (err != noErr) {
	   err = SetDefaultOutputVolume(cmd.param2);
	}
}



/*
	File:		CarbonSndPlayDB.c
	
	Description:Routines demonstrating how to create a function that works
				much like the original SndPlayDoubleBuffer but is Carbon compatible
				(which SndPlayDoubleBuffer isn't).

	Author:		MC

	Copyright: 	© Copyright 1999-2000 Apple Computer, Inc. All rights reserved.
	
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):

*/

/* Requirements for using this shim code:

	1) The sound channel's queue must be empty before you call CarbonSndPlayDoubleBuffer
	2) You cannot call MySndDoImmediate until CarbonSndPlayDoubleBuffer returns.  Be
	   careful about calling MySndDoImmediate at interrupt time with a quietCmd.

*/

/*
Some code is commented out becuase knowing who calls it and how allows shortcuts

Karl Goiser 14/01/01
*/
#if TARGET_API_MAC_CARBON
#undef UNNECESSARY_FOR_SQUEAK

#if UNNECESSARY_FOR_SQUEAK
static	pascal	void	CarbonSndPlayDoubleBufferCleanUpProc (SndChannelPtr theChannel, SndCommand * theCallBackCmd);
#endif
static  pascal  void	CarbonSndPlayDoubleBufferCallBackProc (SndChannelPtr theChannel, SndCommand * theCallBackCmd);
static			void	InsertSndDoCommand (SndChannelPtr chan, SndCommand * theCmd);
static	pascal	void	NMResponseProc (NMRecPtr nmReqPtr);

#define kBufSize					2048

// Structs
struct PerChanInfo {
	QElemPtr 						qLink;						/* next queue entry */
	short 							qType;						/* queue type = 0 */
	short							stopping;
	#if DEBUG
		OSType						magic;
	#endif
	SndCallBackUPP 					usersCallBack;
	SndDoubleBufferHeaderPtr		theParams;
	CmpSoundHeader					soundHeader;
};
typedef struct PerChanInfo			PerChanInfo;
typedef struct PerChanInfo *		PerChanInfoPtr;

// Globals
	Boolean							gNMRecBusy;
	NMRecPtr						gNMRecPtr;
	QHdrPtr							gFreeList;
	Ptr								gSilenceTwos;
	Ptr								gSilenceOnes;
static SndCallBackUPP				gCarbonSndPlayDoubleBufferCallBackUPP = nil;
static SndCallBackUPP				gCarbonSndPlayDoubleBufferCleanUpUPP = nil;

#if UNNECESSARY_FOR_SQUEAK
// Remember this routine could be called at interrupt time, so don't allocate or deallocate memory.
OSErr	MySndDoImmediate (SndChannelPtr chan, SndCommand * cmd) {
	PerChanInfoPtr					perChanInfoPtr;

	// Is this being called on one of the sound channels we are manipulating?
	// If so, we need to pull our callback out of the way so that the user's commands run
	if (gCarbonSndPlayDoubleBufferCallBackUPP == chan->callBack) {
		if (quietCmd == cmd->cmd || flushCmd == cmd->cmd) {
			// We know that our callBackCmd is the first item in the queue if this is our channel
			perChanInfoPtr = (PerChanInfoPtr)(chan->queue[chan->qHead].param2);
			#if DEBUG
				if (perChanInfoPtr->magic != 'SANE') DebugStr("\pBAD in MySndDoImmediate");
			#endif
			perChanInfoPtr->stopping = true;
			Enqueue ((QElemPtr)perChanInfoPtr, gFreeList);
			if (! OTAtomicSetBit (&gNMRecBusy, 0)) {
				NMInstall (gNMRecPtr);
			}
			chan->callBack = perChanInfoPtr->usersCallBack;
		}
	}

	return (SndDoImmediate (chan, cmd));
}
#endif /* UNNECESSARY_FOR_SQUEAK */


// This must be called at task time.
OSErr	CarbonSndPlayDoubleBuffer (SndChannelPtr chan, SndDoubleBufferHeaderPtr theParams) {
	OSErr							err;
	CompressionInfo					compInfo;
	PerChanInfoPtr					perChanInfoPtr;
	SndCommand						playCmd;
	SndCommand						callBack;

	if (nil == chan)		return badChannel;
	if (nil == theParams)	return paramErr;

	if (nil == gFreeList) {
		// This can't ever be disposed since we don't know when we might need to use it (at interrupt time)
		gFreeList = (QHdrPtr)NewPtrClear (sizeof (QHdr));
		err = MemError ();
		if (noErr != err) goto exit;
	}

	if (nil == gSilenceOnes) {
		short		i;
		// This can't ever be disposed since we don't know when we might need to use it (at interrupt time)
		gSilenceOnes = NewPtr (kBufSize);
		err = MemError ();
		if (noErr != err) goto exit;
		for (i = 0; i < kBufSize; i++)
			*gSilenceOnes++ = (char)0x80;
	}

	if (nil == gSilenceTwos) {
		// This can't ever be disposed since we don't know when we might need to use it (at interrupt time)
		gSilenceTwos = NewPtrClear (kBufSize);
		err = MemError ();
		if (noErr != err) goto exit;
	}

	if (nil == gNMRecPtr) {
		// This can't ever be disposed since we don't know when we might need to use it (at interrupt time)
		gNMRecPtr = (NMRecPtr)NewPtr (sizeof (NMRec));
		err = MemError ();
		if (noErr != err) goto exit;

		// Set up our NMProc info that will dispose of most (but not all) of our memory
		gNMRecPtr->qLink = nil;
		gNMRecPtr->qType = 8;
		gNMRecPtr->nmFlags = 0;
		gNMRecPtr->nmPrivate = 0;
		gNMRecPtr->nmReserved = 0;
		gNMRecPtr->nmMark = nil;
		gNMRecPtr->nmIcon = nil;
		gNMRecPtr->nmSound = nil;
		gNMRecPtr->nmStr = nil;
		gNMRecPtr->nmResp = NewNMUPP (NMResponseProc);
		gNMRecPtr->nmRefCon = 0;
	}

	perChanInfoPtr = (PerChanInfoPtr)NewPtr (sizeof (PerChanInfo));
	err = MemError ();
	if (noErr != err) goto exit;

	// Init basic per channel information
	perChanInfoPtr->qLink = nil;
	perChanInfoPtr->qType = 0;				// not used
	perChanInfoPtr->stopping = 0;
	#if DEBUG
		perChanInfoPtr->magic = 'SANE';
	#endif
	
	perChanInfoPtr->theParams = theParams;
	// Have to remember the user's callback function from the sound because
	// we are going to overwrite it with our own callback function.
	perChanInfoPtr->usersCallBack = chan->callBack;

	// Set up the sound header for the bufferCmd that will be used to play
	// the buffers passed in by the SndPlayDoubleBuffer call.
	perChanInfoPtr->soundHeader.samplePtr = (Ptr)(theParams->dbhBufferPtr[0]->dbSoundData);
	perChanInfoPtr->soundHeader.numChannels = theParams->dbhNumChannels;
	perChanInfoPtr->soundHeader.sampleRate = theParams->dbhSampleRate;
	perChanInfoPtr->soundHeader.loopStart = 0;
	perChanInfoPtr->soundHeader.loopEnd = 0;
	perChanInfoPtr->soundHeader.encode = cmpSH;
	perChanInfoPtr->soundHeader.baseFrequency = kMiddleC;
	perChanInfoPtr->soundHeader.numFrames = (unsigned long)theParams->dbhBufferPtr[0]->dbNumFrames;
	//	perChanInfoPtr->soundHeader.AIFFSampleRate = 0;				// unused
	perChanInfoPtr->soundHeader.markerChunk = nil;
	perChanInfoPtr->soundHeader.futureUse2 = nil;
	perChanInfoPtr->soundHeader.stateVars = nil;
	perChanInfoPtr->soundHeader.leftOverSamples = nil;
	perChanInfoPtr->soundHeader.compressionID = theParams->dbhCompressionID;
	perChanInfoPtr->soundHeader.packetSize = (unsigned short)theParams->dbhPacketSize;
	perChanInfoPtr->soundHeader.snthID = 0;
	perChanInfoPtr->soundHeader.sampleSize = (unsigned short)theParams->dbhSampleSize;
	perChanInfoPtr->soundHeader.sampleArea[0] = 0;

	// Is the sound compressed?  If so, we need to treat theParams as a SndDoubleBufferHeader2Ptr.
	if (0 != theParams->dbhCompressionID) {
		// Sound is compressed
		err = GetCompressionInfo (theParams->dbhCompressionID,
								((SndDoubleBufferHeader2Ptr)theParams)->dbhFormat,
								theParams->dbhNumChannels,
								theParams->dbhSampleSize,
								&compInfo);
		if (noErr != err) goto exitDispose;

		perChanInfoPtr->soundHeader.format = compInfo.format;
	} else {
		// Sound is not compressed
		perChanInfoPtr->soundHeader.format = kSoundNotCompressed;
	}

	playCmd.cmd = bufferCmd;
	playCmd.param1 = 0;							// unused
	playCmd.param2 = (long)&perChanInfoPtr->soundHeader;

	callBack.cmd = callBackCmd;
	callBack.param1 = 0;						// which buffer to fill, 0 buffer, 1, 0, ...
	callBack.param2 = (long)perChanInfoPtr;

	// Install our callback function pointer straight into the sound channel structure
	if (nil == gCarbonSndPlayDoubleBufferCallBackUPP) {
		gCarbonSndPlayDoubleBufferCallBackUPP = NewSndCallBackUPP(CarbonSndPlayDoubleBufferCallBackProc);
	}

	chan->callBack = gCarbonSndPlayDoubleBufferCallBackUPP;

#if UNNECESSARY_FOR_SQUEAK
	if (gCarbonSndPlayDoubleBufferCleanUpUPP == nil) {
			gCarbonSndPlayDoubleBufferCleanUpUPP = NewSndCallBackProc (CarbonSndPlayDoubleBufferCleanUpProc);
	}
#endif /* UNNECESSARY_FOR_SQUEAK */

	err = SndDoCommand (chan, &playCmd, true);
	if (noErr != err) goto exitDispose;

	err = SndDoCommand (chan, &callBack, true);
	if (noErr != err) goto exitDispose;

exit:
	return err;

exitDispose:
	if (nil != perChanInfoPtr)
		DisposePtr ((Ptr)perChanInfoPtr);
	goto exit;
}

#if UNNECESSARY_FOR_SQUEAK
static pascal void	CarbonSndPlayDoubleBufferCleanUpProc(
								SndChannelPtr theChannel, SndCommand * theCallBackCmd)
{
	PerChanInfoPtr	perChanInfoPtr;

	perChanInfoPtr = (PerChanInfoPtr)(theCallBackCmd->param2);
#if DEBUG
		if (perChanInfoPtr->magic != 'SANE') DebugStr("\pBAD in CarbonSndPlayDoubleBufferCleanUpProc");
#endif

	// Put our per channel data on the free queue so we can clean up later
	Enqueue ((QElemPtr)perChanInfoPtr, gFreeList);
	// Have to install our Notification Manager routine so that we can clean up the gFreeList
	if (! OTAtomicSetBit (&gNMRecBusy, 0)) {
		NMInstall (gNMRecPtr);
	}
	// Have to put the user's callback proc back so they get called when the next buffer finishes
	theChannel->callBack = perChanInfoPtr->usersCallBack;
}
#endif /* UNNECESSARY_FOR_SQUEAK */


static pascal void	CarbonSndPlayDoubleBufferCallBackProc (SndChannelPtr theChannel, SndCommand * theCallBackCmd) {
	SndDoubleBufferHeaderPtr		theParams;
	SndDoubleBufferPtr				emptyBuf;
	SndDoubleBufferPtr				nextBuf;
	PerChanInfoPtr					perChanInfoPtr;
	SndCommand						playCmd;

	perChanInfoPtr = (PerChanInfoPtr)(theCallBackCmd->param2);
	#if DEBUG
		if (perChanInfoPtr->magic != 'SANE') DebugStr("\pBAD in CarbonSndPlayDoubleBufferCallBackProc");
	#endif
	if (true == perChanInfoPtr->stopping) goto exit;

	theParams = perChanInfoPtr->theParams;

	// The buffer that just played and needs to be filled
	emptyBuf = theParams->dbhBufferPtr[theCallBackCmd->param1];

	// Clear the ready flag
	emptyBuf->dbFlags ^= dbBufferReady;

	// This is the buffer to play now
	nextBuf = theParams->dbhBufferPtr[!theCallBackCmd->param1];

	// Check to see if it is ready, or if we have to wait a bit
	if (nextBuf->dbFlags & dbBufferReady) {
		perChanInfoPtr->soundHeader.numFrames = (unsigned long)nextBuf->dbNumFrames;
		perChanInfoPtr->soundHeader.samplePtr = (Ptr)(nextBuf->dbSoundData);

		// Flip the bit telling us which buffer is next
		theCallBackCmd->param1 = !theCallBackCmd->param1;

		// If this isn't the last buffer, call the user's fill routine
		if (!(nextBuf->dbFlags & dbLastBuffer)) {
				// Declare a function pointer to the user's double back proc
				void (*doubleBackProc)(SndChannel*, SndDoubleBuffer*);

				// Call user's double back proc
				doubleBackProc = (void*)DoubleBack;
				(*doubleBackProc) (theChannel, emptyBuf);
		} else {
			// Call our clean up proc when the last buffer finishes
			theChannel->callBack = gCarbonSndPlayDoubleBufferCleanUpUPP;
		}
	} else {
		// We have to wait for the buffer to become ready.
		// The real SndPlayDoubleBuffer would play a short bit of silence waiting for
		// the user to read the audio from disk, so that's what we do here.
		#if DEBUG
			DebugStr ("\p buffer is not ready!");
		#endif
		// Play a short section of silence so that we can check the ready flag again
		if (theParams->dbhSampleSize == 8) {
			perChanInfoPtr->soundHeader.numFrames = (UInt32)(kBufSize / theParams->dbhNumChannels);
			perChanInfoPtr->soundHeader.samplePtr = gSilenceOnes;
		} else {
			perChanInfoPtr->soundHeader.numFrames = (UInt32)(kBufSize / (theParams->dbhNumChannels * (theParams->dbhSampleSize / 8)));
			perChanInfoPtr->soundHeader.samplePtr = gSilenceTwos;
		}
	}

	// Insert our callback command
	InsertSndDoCommand (theChannel, theCallBackCmd);

	// Play the next buffer
	playCmd.cmd = bufferCmd;
	playCmd.param1 = 0;
	playCmd.param2 = (long)&(perChanInfoPtr->soundHeader);
	InsertSndDoCommand (theChannel, &playCmd);

exit:
	return;
}

static void	InsertSndDoCommand (SndChannelPtr chan, SndCommand * newCmd) {
	if (-1 == chan->qHead) {
		chan->qHead = chan->qTail;
	}

	if (1 <= chan->qHead) {
		chan->qHead--;
	} else {
		chan->qHead = chan->qTail;
	}

	chan->queue[chan->qHead] = *newCmd;
}

static pascal void NMResponseProc (NMRecPtr nmReqPtr) {
	PerChanInfoPtr					perChanInfoPtr;
	OSErr							err;

	NMRemove (nmReqPtr);
	gNMRecBusy = false;

	do {
		perChanInfoPtr = (PerChanInfoPtr)gFreeList->qHead;
		if (nil != perChanInfoPtr) {
			err = Dequeue ((QElemPtr)perChanInfoPtr, gFreeList);
			if (noErr == err) {
				DisposePtr ((Ptr)perChanInfoPtr);
			}
		}
	} while (nil != perChanInfoPtr && noErr == err);
}

#endif /* TARGET_API_MAC_CARBON */
