/* sqUnixSoundPulseAudio.c -- sound module for Pulse Audio
 *
 * Author: Derek O'Connell <doc@doconnel.f9.co.uk>
 * 
 *   Copyright (C) 2009--2010 by Derek O'Connell
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Last edited: 2014-03-07 08:25:10 by piumarta on emilia.local
 */

/* ========== */
/* INCLUDES   */
/* ========== */

#include "sq.h"
#include <errno.h>
#include <signal.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>
#include <sys/mman.h>
#include <string.h>
#include <unistd.h>

/*
#include <glib.h>
*/
#include <pthread.h>

#include <pulse/simple.h>
#include <pulse/error.h>
/*
#include <pulse/gccmacro.h>
*/

/* ========== */
/* MACROS     */
/* ========== */

#define FAIL(X)   \
{     \
	success(false); \
	return X;   \
}

#define snd(expr, what)						\
  if ((rc = snd_##expr) < 0)					\
    {								\
      fprintf(stderr, "%s: %s\n", what, snd_strerror(rc));	\
      success(false);						\
      return rc;						\
    }


/* ================================== DEBUGGING  */

#define xDBG

#ifdef DBG
	#define DBG_MSG_MAX_LEN 128

	char *dbg_msg[DBG_MSG_MAX_LEN];

	#define DBGMSG(M) { \
		printf("DBG: sqUnixSoundMaemo: %s (%d, %s)\n", M, errno, strerror (errno)); \
		errno = 0; \
	}

	#define DBGERR(M, E) { \
		sprintf(*dbg_msg, M, E); \
		DBGMSG(dbg_msg); \
	}

#else
	#define DBGMSG(M) 
	#define DBGERR(M, E)
#endif


/* ================================== TYPES */

typedef struct {
	short *buffer;
	unsigned long samples;
	int isFree;
} audioBuffer_t;

typedef struct {
	pthread_mutex_t *mutex;
	pthread_cond_t 	*cond;
	unsigned int count;
} gen_sig_t;

typedef struct {
	/* Left in for debugging >>> */
	const char *dbgName;
	const char *device;
	/* <<< */
	
	int open;
	
	unsigned long maxSamples;
	unsigned long maxWords;
	unsigned long maxBytes;
	
	audioBuffer_t *buffer;
	
	int maxBuffers;
	int buffersAllocated;
	int bufferFree;
	int bufferNext;
	int bufferCount;
	int bufferFull;
	
	pthread_mutex_t *bufferMutex;
	
	void *		threadFunc;
	pthread_t thread;

	gen_sig_t sigRun;
	gen_sig_t sigStalled;
	
	int running;
	int exit;
	int stall;
	int sqSemaphore;
	
	int rateID;
	int bytesPerFrame;
	
	/* PULSE, Simple API parameters */
	pa_simple *pa_conn;
	int dummy;
  pa_sample_spec pa_spec;
 } audioIO_t;


/* ================================== FUNCTION PROTOTYPES */

static int rate(int rateID);
static int rateID(int rate);

static inline unsigned short _swapw(unsigned short v); /* From io.h */

static int devInputReady(int dev_fd);

static void sigWait(gen_sig_t *sig);
static void sigReset(gen_sig_t *sig);
static void sigSignal(gen_sig_t *sig);

static void ioThreadWaitToRun(audioIO_t *audioIO);
static void ioThreadExit(audioIO_t *audioIO);
static int  ioThreadStart(audioIO_t *audioIO);
static int  ioThreadIsRunning(audioIO_t *audioIO);
static void ioThreadStall(audioIO_t *audioIO);

static void ioZeroBuffers(audioIO_t *audioIO);
static void ioFreeBuffers(audioIO_t *audioIO);
static int  ioFreeBytes(audioIO_t *audioIO);
static int  ioIsFull(audioIO_t *audioIO);
static int  ioAddPlayBuffer(void *buffer, int frameCount);
static int  ioGetRecordBuffer(void *buffer, int bufferBytes);
static int  ioAllocBuffers(audioIO_t *audioIO, int frameCount);
static int  ioGetBufferData(audioIO_t *audioIO, void **buffer, int *frames);
static int  ioNextBuffer(audioIO_t *audioIO);

static void *writerThread(void *ptr);
static void *readerThread(void *ptr);

static int  ioInit();

/* SQUEAK INTERFACE */

static int trace();

static sqInt sound_AvailableSpace(void);
static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime);
static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, void *arrayIndex, sqInt startIndex);
static sqInt sound_PlaySilence(void);
static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
static sqInt sound_Stop(void);

static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex);
static sqInt sound_StopRecording(void);
static double sound_GetRecordingSampleRate(void);
static sqInt sound_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes);

static int mixer_open(char *name);
static void mixer_close(void);
static inline void mixer_getVolume(char *name, int captureFlag, double *leftLevel, double *rightLevel);
static inline void mixer_setVolume(char *name, int captureFlag, double leftLevel, double rightLevel);
static int mixer_setSwitch(char *name, int captureFlag, int parameter);
static int mixer_getSwitch(char *name, int captureFlag, int channel);
static void sound_Volume(double *left, double *right);
static void sound_SetVolume(double left, double right);
static sqInt sound_SetRecordLevel(sqInt level);
static sqInt sound_SetDevice(sqInt id, char *arg);
static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel);
static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter);


/* ==================== 				*/
/* ==================== GLOBALS */
/* ==================== 				*/

/* Left in but not used >>> */
#define SQ_SND_PLAY_START_THRESHOLD	7/8
#define SQ_SND_PLAY_AVAIL_MIN		4/8
/* <<< */

/* Arbitrary (apart from minmising latency) >>> */
#define MAX_INPUT_BUFFERS 10
#define MAX_OUTPUT_BUFFERS 2
/* <<< */

audioBuffer_t iBuffer[MAX_INPUT_BUFFERS];
audioBuffer_t oBuffer[MAX_OUTPUT_BUFFERS];

/* STATICALLY INITIALISED SO AUTO-DESTROYED (ON CRASHING FOR INSTANCE) >>> */

/* input */

pthread_mutex_t audioInBufferMutex		= PTHREAD_MUTEX_INITIALIZER;

pthread_mutex_t audioInRunMutex				= PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t 	audioInRunCond				= PTHREAD_COND_INITIALIZER;

pthread_mutex_t audioInStalledMutex		= PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t 	audioInStalledCond		= PTHREAD_COND_INITIALIZER;

/* output */

pthread_mutex_t audioOutBufferMutex		= PTHREAD_MUTEX_INITIALIZER;

pthread_mutex_t audioOutRunMutex			= PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t 	audioOutRunCond				= PTHREAD_COND_INITIALIZER;

pthread_mutex_t audioOutStalledMutex	= PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t 	audioOutStalledCond		= PTHREAD_COND_INITIALIZER;

/* <<< */


audioIO_t audioIn, audioOut;

int initDone = false;

/* EXTRA FOR ALSA BUT UNUSED >>> */
/*
static int		output_buffer_frames_available = 1;
static double	max_delay_frames = 0;
*/
/* <<< */


/* ================================== UTILS */

/* RATE CONVERSION: from dsp code but not used (yet). Maybe not needed at all with AlSA */
/* RATE CONVERSION: fixed preset rates are used. TBD: choose nearest to requested */
/*
static int rate(int rateID) {
	if (SAMPLE_RATE_8KHZ	  	== rateID) return  8000;
	if (SAMPLE_RATE_16KHZ	  	== rateID) return 16000;
	if (SAMPLE_RATE_11_025KHZ == rateID) return 11025;
	if (SAMPLE_RATE_22_05KHZ  == rateID) return 22050;
	if (SAMPLE_RATE_44_1KHZ	  == rateID) return 44100;
	return -1;
}

static int rateID(int rate) {
	if ( 8000 == rate) return SAMPLE_RATE_8KHZ;
	if ( 8192 == rate) return SAMPLE_RATE_8KHZ;
	if (16000 == rate) return SAMPLE_RATE_16KHZ;
	if (11025 == rate) return SAMPLE_RATE_11_025KHZ;
	if (22050 == rate) return SAMPLE_RATE_22_05KHZ;
	if (44100 == rate) return SAMPLE_RATE_44_1KHZ;
	return -1;
}
*/

/* From io.h because recorded data has to be Big Endian */
static inline unsigned short _swapw(unsigned short v) {
	return ((v << 8) | (v >> 8));
}


/* Not used but maybe useful */
/*
static int devInputReady(int dev_fd) {
	struct pollfd pfd;
	pfd.fd = dev_fd;
	pfd.events = POLLIN;
	if (poll (&pfd,1,0)>0) return true;
	return false;
}
*/

static void printPALatency() {
	pa_usec_t latency;
	int error;
	
	if ((latency = pa_simple_get_latency(audioOut.pa_conn, &error)) == (pa_usec_t) -1)
		fprintf(stderr, __FILE__": pa_simple_get_latency() failed: %s\n", pa_strerror(error));
	else
		fprintf(stderr, "%0.0f usec    \r", (float)latency);
}

/* ================================== Signal Ops */

static void sigWait(gen_sig_t *sig) {
	pthread_mutex_lock(sig->mutex);
		while( !sig->count )
			pthread_cond_wait(sig->cond, sig->mutex);
		sig->count -= 1;
	pthread_mutex_unlock(sig->mutex);
}

static void sigReset(gen_sig_t *sig) {
	pthread_mutex_lock(sig->mutex);
		sig->count = 0;
	pthread_mutex_unlock(sig->mutex);
}

static void sigSignal(gen_sig_t *sig) {
	pthread_mutex_lock(sig->mutex);
		sig->count += 1;
		pthread_cond_signal(sig->cond);
	pthread_mutex_unlock(sig->mutex);
}

/* Here for debugging but direct calls would be ok >>> */
static void signalSqueak(audioIO_t *audioIO) {
/*	printf("@%d",audioIO->sqSemaphore);
*/
	if (0 < audioIO->sqSemaphore)
		signalSemaphoreWithIndex(audioIO->sqSemaphore);
}
/* <<< */


/* ================================== Thread Ops */

static void ioThreadExit(audioIO_t *audioIO) {
	if (!audioIO->thread) return;
	audioIO->exit = 1;
	sigSignal(&audioIO->sigRun);
	pthread_join(audioIO->thread, NULL);
	audioIO->thread = 0;
}

static int ioThreadStart(audioIO_t *audioIO) {
	int rc;
	if (audioIO->thread) return true;
	rc = pthread_create(&audioIO->thread, NULL, audioIO->threadFunc, NULL);
	if (0 != rc) DBGERR("ioThreadStart(): %d", rc);
	return rc;
}

static int ioThreadIsRunning(audioIO_t *audioIO) {
	return audioIO->running;
}

static void ioThreadStall(audioIO_t *audioIO) {
	audioIO->stall = true;
	sigSignal(&audioIO->sigRun);
	sigWait(&audioIO->sigStalled);
}

/* Don't attempt to signal Sq here as we may not have a semaphore! */
static void ioThreadWaitToRun(audioIO_t *audioIO) {
	sigSignal(&audioIO->sigStalled);
	
	pthread_mutex_lock(audioIO->sigRun.mutex);
		audioIO->running = false;
		
		if (audioIO->stall) audioIO->sigRun.count = 0;
		audioIO->stall = false;
		
		while( !audioIO->sigRun.count )
			pthread_cond_wait(audioIO->sigRun.cond, audioIO->sigRun.mutex);
		audioIO->sigRun.count -= 1;
	
		audioIO->running = true;
	pthread_mutex_unlock(audioIO->sigRun.mutex);
	
	sigReset(&audioIO->sigStalled);		
}

/* ================================== Buffer ops */

static void ioZeroBuffers(audioIO_t *audioIO) {
	int i;
	for(i=0; i < audioIO->maxBuffers; i++) {
		audioIO->buffer[i].samples = 0;
		audioIO->buffer[i].isFree  = true;
	}
}

static void ioFreeBuffers(audioIO_t *audioIO) {
	int i;
	for(i=0; i < audioIO->maxBuffers; i++) {
		free(audioIO->buffer[i].buffer);
		audioIO->buffer[i].buffer  = 0;
		audioIO->buffer[i].samples = 0;
	}
	audioIO->bufferFree  = audioIO->bufferNext = 0;
	/* audioIO->bufferCount differs for play/record */
}

/* Only used for playing, not for recording */
static int ioFreeBytes(audioIO_t *audioIO) {
	int freeBytes;
	pthread_mutex_lock(audioIO->bufferMutex);
		freeBytes = audioIO->maxBytes * audioIO->bufferCount;
	pthread_mutex_unlock(audioIO->bufferMutex);
	return freeBytes;
}

static int ioAllocBuffers(audioIO_t *audioIO, int frameCount) {
	int i;
	
	/* Not preserving buffers when play/record stopped */
	/* Choosing memory conservation over speed of starting play/record */
	
	ioFreeBuffers(audioIO);
	audioIO->maxSamples = frameCount;
	audioIO->maxBytes   = audioIO->maxSamples * audioIO->bytesPerFrame;
	audioIO->maxWords   = audioIO->maxBytes >> 1;
	for(i=0; i < audioIO->maxBuffers; i++) {
		audioIO->buffer[i].buffer = (short *)calloc(audioIO->maxBytes, 1);
		audioIO->buffer[i].isFree = true;
	}
	audioIO->buffersAllocated = true;
}

static int ioIsFull(audioIO_t *audioIO) {
	pthread_mutex_lock(audioIO->bufferMutex);
		audioIO->bufferFull = (0 < audioIO->buffer[audioIO->bufferFree].samples);
	pthread_mutex_unlock(audioIO->bufferMutex);
	return audioIO->bufferFull;
}

/* Could combine some of the following but makes debugging difficult */

static int ioAddPlayBuffer(void *buffer, int frameCount) {
	long bytes;
	if (ioIsFull(&audioOut)) return 0;
	pthread_mutex_lock(audioOut.bufferMutex);
		bytes = MIN(audioOut.maxBytes, frameCount * audioOut.bytesPerFrame);
		memcpy(audioOut.buffer[audioOut.bufferFree].buffer, buffer, bytes);
		audioOut.buffer[audioOut.bufferFree].samples = frameCount;
		audioOut.buffer[audioOut.bufferFree].isFree  = false;
		audioOut.bufferFree = (audioOut.bufferFree + 1) % audioOut.maxBuffers;
		audioOut.bufferCount -= 1;
	pthread_mutex_unlock(audioOut.bufferMutex);
	return bytes;
}

static int ioGetRecordBuffer(void *buffer, int bufferBytes) {
	long samples, sampleBytes;
	
	if (bufferBytes <= 0) return 0;
/*	if (audioIn.buffer[audioIO->bufferNext].samples <=0) return 0;
*/	
	if (audioIn.buffer[audioIn.bufferNext].isFree) return 0;
	
	pthread_mutex_lock(audioIn.bufferMutex);
		samples = audioIn.buffer[audioIn.bufferNext].samples;
		sampleBytes = MIN(2 * audioIn.pa_spec.channels * samples, bufferBytes);
		memcpy(buffer, (char *)audioIn.buffer[audioIn.bufferNext].buffer, sampleBytes);
	/* DMOC 090909 1800: Hmmmm, what if Squeak does not read whole buffer? ATM remaining buffer data lost since */
	/*   ioGetRecordBuffer() frees the buffer after single visit. Needs more work */
		audioIn.buffer[audioIn.bufferNext].samples = 0;
		audioIn.buffer[audioIn.bufferNext].isFree = true;
		audioIn.bufferNext = (audioIn.bufferNext + 1) % audioIn.maxBuffers;
		audioIn.bufferCount -= 1;
	pthread_mutex_unlock(audioIn.bufferMutex);
	return sampleBytes;
}

static int ioGetBufferData(audioIO_t *audioIO, void **buffer, int *frames) {
	if (audioIO->buffer[audioIO->bufferNext].isFree) return false;
	pthread_mutex_lock(audioIO->bufferMutex);
		*buffer = (void *)(audioIO->buffer[audioIO->bufferNext].buffer);
		*frames = audioIO->buffer[audioIO->bufferNext].samples;
	pthread_mutex_unlock(audioIO->bufferMutex);
	return true;
}

static int ioNextPlayBuffer() {
	pthread_mutex_lock(audioOut.bufferMutex);
		audioOut.buffer[audioOut.bufferNext].samples = 0;
		audioOut.buffer[audioOut.bufferNext].isFree  = true;
		audioOut.bufferNext = (audioOut.bufferNext + 1) % audioOut.maxBuffers;
		audioOut.stall = (audioOut.bufferNext == audioOut.bufferFree);
		audioOut.bufferCount += 1;
	pthread_mutex_unlock(audioOut.bufferMutex);
}

static int ioNextRecordBuffer() {
	pthread_mutex_lock(audioIn.bufferMutex);
		audioIn.buffer[audioIn.bufferNext].isFree  = false;
		audioIn.bufferFree = (audioIn.bufferNext + 1) % audioIn.maxBuffers;
		audioIn.stall = (audioIn.bufferNext == audioIn.bufferFree);
		audioIn.bufferCount += 1;
	pthread_mutex_unlock(audioIn.bufferMutex);
}

/* ================================== IO THREADS */

static void *writerThread(void *ptr) {
	struct timespec tm = {0, 1000 * 1000};
	int rc;
	int nextBuffer, frames;
	void *buffer;
	
	DBGMSG("[writerThread: started]");
	
	audioOut.exit = 0;

	for (;;) {
		DBGMSG("[writerThread: waiting]");
		
		/* No point signalling squeak *before* running as there may not be a semaphore */
		ioThreadWaitToRun(&audioOut);

		if (audioOut.exit) break;
		if (!audioOut.open || audioOut.stall) continue;
		
		DBGMSG("[writerThread: running]");
		
		for (;;) {
			if (!audioOut.open || audioOut.stall || audioOut.exit) break;

			if (!ioGetBufferData(&audioOut, &buffer, &frames)) {
				signalSqueak(&audioOut);
				break;
			}
			
/*printf("writerThread: buffer: %d, frames %d\n", audioOut.bufferNext, frames);
*/
			
			while (frames > 0) {
				if (!audioOut.open || audioOut.stall || audioOut.exit) break;
/*				if ((rc = snd_pcm_writei(audioOut.alsaHandle, buffer, frames)) < frames) {
*/
        
        /* PA: Have to assume for now that all frames were written */
        if (pa_simple_write(audioOut.pa_conn, buffer, (size_t) (frames * audioOut.bytesPerFrame), &rc) < 0) {
          fprintf(stderr, __FILE__": pa_simple_write() failed: %s\n", pa_strerror(rc));
/*					printf("writerThread: sent %d, actual %d\n", frames, rc);
*/
					break;
				}
				
        /* PA: Have to assume for now that all frames were written */
/*				buffer = (short *)((char *)buffer + rc * audioOut.bytesPerFrame);
				frames -= rc;
*/
				/* *** SO FOLLOWING CODE *AND* THE ENCLOSING WHILE-LOOP REDUNDANT!!! (so just break out of loop) *** */
/*				buffer = (short *)((char *)buffer + frames * audioOut.bytesPerFrame);
				frames -= frames;
*/
				break;
			} /* while */
			
			if (!audioOut.open || audioOut.stall || audioOut.exit) break;
			ioNextPlayBuffer();	
			if (!audioOut.open || audioOut.stall || audioOut.exit) break;
			
			signalSqueak(&audioOut);
		}
		
		if (audioOut.exit) break;
	}

	DBGMSG("[writerThread: stopped]");

}


static void *readerThread(void *ptr) {
	int rc;
	int wc;
	unsigned short *p;

	DBGMSG("[readerThread: started]");
	
	audioIn.exit = 0;
	
	for (;;) {
		DBGMSG("[readerThread: waiting]");
		
		ioThreadWaitToRun(&audioIn);
		
		if (audioIn.exit) break;
		if (!audioIn.open || audioIn.stall) continue;

		DBGMSG("[readerThread: running]");
		
		for (;;) {
			if (!audioIn.open || audioIn.stall || audioIn.exit) break;
			
			/* NB: PA Simple API does not return number of bytes/samples recorded */
			/*   (so have to assume full buffer everytime (poss padded if less than requested) */
			
/*			rc = snd_pcm_readi(audioIn.alsaHandle, audioIn.alsaBuffer, audioIn.alsaFrames);
*/			
			if (pa_simple_read(audioIn.pa_conn, (char *)(audioIn.buffer[audioIn.bufferFree].buffer), audioIn.maxBytes, &rc) < 0) {
				fprintf(stderr, __FILE__": pa_simple_read() failed: %s\n", pa_strerror(rc));
				continue;
			}

			if (!audioIn.open || audioIn.stall || audioIn.exit) break;
			
			/* PA: Assume max buffer frames returned... */
			rc = audioIn.maxSamples;
			
			/* EPIPE means overrun */
/*			
			if (rc == -EPIPE) {
				printf("readerThread: overrun occurred\n");
				snd_pcm_prepare(audioIn.alsaHandle);
				continue;
			} 
			
			if (rc < 0) {
				printf("readerThread: error from read: %s\n", snd_strerror(rc));
				continue;
			} 
			
			if (rc != (int)audioIn.alsaFrames) {
				printf("readerThread: short read, read %d frames\n", rc);
				continue;
			}
*/			
			if (!audioIn.buffer[audioIn.bufferFree].isFree) {
				printf("readerThread: No free buffers!\n");
				continue;
			}
						
			if (!audioIn.open || audioIn.stall || audioIn.exit) break;

			/* PA: Complete buffer should be returned so skipping check and moving guts to end of loop */
/*
			if ((audioIn.buffer[audioIn.bufferFree].samples + rc) > audioIn.maxSamples) {
				ioNextRecordBuffer();
				if (!audioIn.open || audioIn.stall || audioIn.exit) break;
				signalSqueak(&audioIn);
			}
*/

/* Next won't get called anyway because of "stall" in ioNextRecordBuffer() */
/* Left here in case needed for debugging */
/*
			if (!audioIn.buffer[audioIn.bufferFree].isFree) {
				printf("readerThread: No free buffers!\n");
				continue;
			}
*/
				
			/* PA: Endian swap may not be needed... */

			/* Endian Swap (rc = frames = Word Count in this case) */
/*			
			p = (unsigned short *)(audioIn.buffer[audioIn.bufferFree].buffer);
			wc = rc;
			while (wc--)
				*p = _swapw(*p);
*/
	
			/* PA: No copy required since record buffer used directly... */
/*	
			memcpy((char *)(audioIn.buffer[audioIn.bufferFree].buffer) + 2 * audioIn.buffer[audioIn.bufferFree].samples, audioIn.alsaBuffer, rc*2);
			audioIn.buffer[audioIn.bufferFree].samples += rc;
*/
			
			/* PA: No indication of actual bytes/samples read so assuming full buffer read (or padded)... */
			audioIn.buffer[audioIn.bufferFree].samples = audioIn.maxSamples;
			
			if (!audioIn.open || audioIn.stall || audioIn.exit) break;
		
			/* PA: These three lines moved from above (since assuming full buffers are read every time) */
			ioNextRecordBuffer();
			if (!audioIn.open || audioIn.stall || audioIn.exit) break;
			signalSqueak(&audioIn);
			
		}
		if (audioIn.exit) break;
	}
DBGMSG("[readerThread: stopped]");
}


/* ================================== IO INIT */

static int ioInit() {
	if (initDone) return true;
	initDone = true; 
	
	/* AUDIO OUT */
	
/* NOT USED >>> */
	audioOut.dbgName = "play";
	audioOut.device = "pa-simple"; 
/* <<< */

	audioOut.open = false;
	
	audioOut.maxSamples	= 0;
	audioOut.maxWords		= 0;
	audioOut.maxBytes		= 0;
	
	audioOut.maxBuffers		= MAX_OUTPUT_BUFFERS;
	audioOut.buffer				= oBuffer;
	audioOut.bufferFree		= 0;
	audioOut.bufferNext		= 0;
	audioOut.bufferCount	= audioOut.maxBuffers;
	audioOut.bufferFull		= 0;
	audioOut.bufferMutex	= &audioOutBufferMutex;
	audioOut.buffersAllocated = false;
	
	audioOut.threadFunc = writerThread;
	audioOut.thread			= 0;

	audioOut.sigRun.mutex	= &audioOutRunMutex;
	audioOut.sigRun.cond	= &audioOutRunCond;
	sigReset(&audioOut.sigRun);
	
	audioOut.sigStalled.mutex = &audioOutStalledMutex;
	audioOut.sigStalled.cond  = &audioOutStalledCond;
	sigReset(&audioOut.sigStalled);
	
	audioOut.running	= 0;
	audioOut.exit			= 0;
	audioOut.stall		= 0;
	
	audioOut.sqSemaphore = 0;
	
	audioOut.rateID = 0;
	audioOut.bytesPerFrame = 4; /* Stereo S16LE */

	audioOut.pa_conn = null;
	
	ioThreadStart(&audioOut);
	
	/* AUDIO IN */
	
	audioIn.dbgName = "rec";
	
/* NOT USED >>> */
	audioIn.device = "pa-simple"; 
/* <<< */
	
	audioIn.open = false;
	
	audioIn.maxSamples	= 0;
	audioIn.maxWords		= 0;
	audioIn.maxBytes		= 0;
	
	audioIn.maxBuffers	= MAX_INPUT_BUFFERS;
	audioIn.buffer			= iBuffer;
	audioIn.bufferFree	= 0;
	audioIn.bufferNext	= 0;
	audioIn.bufferCount	= 0; /* No buffers yet. Was audioIn.maxBuffers; */
	audioIn.bufferFull	= 0;
	audioIn.bufferMutex	= &audioInBufferMutex;
	audioIn.buffersAllocated = false;
	
	audioIn.threadFunc= readerThread;
	audioIn.thread		= 0;
	
	audioIn.sigRun.mutex		 	= &audioInRunMutex;
	audioIn.sigRun.cond		 		= &audioInRunCond;
	sigReset(&audioIn.sigRun);
	
	audioIn.sigStalled.mutex	= &audioInStalledMutex;
	audioIn.sigStalled.cond		= &audioInStalledCond;
	sigReset(&audioIn.sigStalled);
	
	audioIn.running	= 0;
	audioIn.exit		= 0;
	audioIn.stall		= 0;
	
	audioIn.sqSemaphore	= 0;
	
	audioIn.rateID = 0;
	audioIn.bytesPerFrame = 2; /* Mono S16LE */
	
	audioIn.pa_conn = null;
	
	ioThreadStart(&audioIn);
}

/* ============================================ */
/* ================================== VM PLUGIN */
/* ============================================ */

static int trace() {
}

/* ================================== AUDIO OUT */

static sqInt sound_AvailableSpace(void) {
	return ioFreeBytes(&audioOut);
}

static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime) {
DBGMSG(">sound_InsertSamplesFromLeadTime()");
	return 0; /* or maxBytes? */
}


static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex) {
	unsigned int bufferNext, samples, sampleBytes;

	if (0 >= frameCount) return 0;
	
	samples = MIN(audioOut.maxSamples, frameCount);
	
	if (0 == (sampleBytes = ioAddPlayBuffer(srcBufPtr + startIndex * 2 * audioOut.pa_spec.channels, samples)))
		DBGMSG("sound_PlaySamplesFromAtLength(): No free buffers!");
	
	sigSignal(&audioOut.sigRun);
	
	return samples;
}

static sqInt sound_PlaySilence(void) {
DBGMSG(">sound_PlaySilence()");
	ioThreadStall(&audioOut);
	return 0; /* or maxBytes? */
}


static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex) {
	int rc;
	
DBGMSG(">sound_Start()");

#ifdef DBG
printf("\tframeCount: %d, samplesPerSec: %d, stereo: %d, semaIndex: %d\n", frameCount, samplesPerSec, stereo, semaIndex);
#endif

	if (audioOut.open) return true;
	
  audioOut.pa_spec.format = PA_SAMPLE_S16LE;
  audioOut.pa_spec.rate = samplesPerSec; /* rate(SAMPLE_RATE_22_05KHZ) for Squeak */
  audioOut.pa_spec.channels = stereo ? 2 : 1;
  audioOut.pa_conn = NULL;

	/* Create a new playback stream */
	if (!(audioOut.pa_conn = pa_simple_new(NULL, "Scratch", PA_STREAM_PLAYBACK, NULL, "playback", &audioOut.pa_spec, NULL, NULL, &rc))) {
			fprintf(stderr, __FILE__": pa_simple_new() failed: %s\n", pa_strerror(rc));
			success(false);
			return false;
	}
  
	ioAllocBuffers(&audioOut, frameCount);
	audioOut.bufferCount = audioOut.maxBuffers; /* Has to be reset everytime */
	
	audioOut.sqSemaphore = semaIndex;

	audioOut.open = true;
	
	sigSignal(&audioOut.sigRun);
	
	/* error possibly left over from dsp-protocol.c code */
	/* dsp-protocol.c in current ALSA not capturing EINTR/EAGAIN */
	/* EINTR/EAGAIN from dsp-protocol.c not raised up to ALSA so not caught by ALSA */
	/* Clearing errno here to see if Squeak can continue regardless */
	errno = 0; 
	
DBGMSG("<sound_Start()");
	return true;
}


static sqInt sound_Stop(void) {
	int rc;
	
DBGMSG(">sound_Stop()");

	if (!audioOut.open) return true;
	audioOut.open = false;
	
	if (NULL == audioOut.pa_conn) return true;
	
	ioThreadStall(&audioOut);

	if (pa_simple_drain(audioOut.pa_conn, &rc) < 0) {
		fprintf(stderr, __FILE__": pa_simple_drain() failed: %s\n", pa_strerror(rc));
	}

  if (NULL != audioOut.pa_conn)
     pa_simple_free(audioOut.pa_conn);
	
	ioFreeBuffers(&audioOut);

	audioOut.pa_conn = NULL;
	audioOut.sqSemaphore = 0;

DBGMSG("<sound_Stop()");
	return true;
}



/* ================================== AUDIO IN */

static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex) {
	int rc;
	pa_buffer_attr pa_buffer_metrics; /* For recording */

DBGMSG(">sound_StartRecording()");

	if (audioIn.open) return true;
	
	audioIn.pa_spec.format = PA_SAMPLE_S16LE;
	audioIn.pa_spec.rate = desiredSamplesPerSec;
	audioIn.pa_spec.channels = stereo ? 2 : 1;
	audioIn.pa_conn = NULL;
    
	pa_buffer_metrics.maxlength	= (uint32_t) -1;
	pa_buffer_metrics.tlength	= (uint32_t) -1; /* playback only */
	pa_buffer_metrics.prebuf	= (uint32_t) -1; /* playback only */ 
	pa_buffer_metrics.minreq	= (uint32_t) -1; /* playback only */
	pa_buffer_metrics.fragsize	= pa_usec_to_bytes(20*1000, &audioIn.pa_spec); 

	/* Create the recording stream */
	if (!(audioIn.pa_conn = pa_simple_new(	NULL, 
											"Scratch", 
											PA_STREAM_RECORD, 
											NULL, 
											"record", 
											&audioIn.pa_spec, 
											NULL, 
											&pa_buffer_metrics, 
											&rc)))
	{
			fprintf(stderr, __FILE__": pa_simple_new() failed: %s\n", pa_strerror(rc));
			success(false);
			return false;
	}

  /* Only rate supported on the N810 (atm) is 8000 */
/*  
  audioIn.alsaRate = 8000; 
*/
  
  /* 20Hz update freq for Squeak sounds reasonable, so... */
  audioIn.maxSamples = audioIn.pa_spec.rate / 20;
	
  /* Use a buffer large enough to hold one period (assuming 2 bytes/sample) */
/*  
  audioIn.alsaBufferSize = audioIn.maxSamples * 2 * audioIn.pa_spec.channels; 
  audioIn.alsaBuffer = (char *) malloc(audioIn.alsaBufferSize);
*/

	/* Buffers will be filled before signalling Squeak. So rate & buffer size determined signalling freq... */
	ioAllocBuffers(&audioIn, audioIn.pa_spec.rate / 20 ); /* for Sq signalling rate of 20Hz */
	audioIn.bufferCount	= 0; /* Has to be reset everytime */

	audioIn.sqSemaphore = semaIndex;
	
	audioIn.open = true;
	
	sigSignal(&audioIn.sigRun);
		
DBGMSG("<sound_StartRecording()");
	return true;
}

static sqInt sound_StopRecording(void) {
DBGMSG(">sound_StopRecording()");

	if (!audioIn.open) return 0;
	audioIn.open = false;
	
	if (NULL == audioIn.pa_conn) return 1;
	
	ioThreadStall(&audioIn);

  pa_simple_free(audioIn.pa_conn);
  
	ioFreeBuffers(&audioIn);
	
	audioIn.pa_conn = NULL;
	
	audioIn.sqSemaphore = 0;

DBGMSG("<sound_StopRecording()");
	return true;
}

static double sound_GetRecordingSampleRate(void) {
	return (double)audioIn.pa_spec.rate;
}

static sqInt sound_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes) {
	unsigned int bufferNext, bufferBytes, sampleBytes;

	bufferBytes = MAX(0, bufferSizeInBytes - (startSliceIndex * 2));
	if (0 == bufferBytes) {
		printf("***(%d) sound_RecordSamplesIntoAtLength(): No space in Squeak buffer!\n", startSliceIndex);
		return 0;
	}
	
	/* DMOC 090909 1800: Hmmmm, what if Squeak does not read whole buffer? ATM remaining buffer data lost since */
	/*   ioGetRecordBuffer() frees the buffer after single visit. Needs more work */
	
	bufferNext = audioIn.bufferNext; /* preserved for debug output */
	sampleBytes = ioGetRecordBuffer((void *)(buf + (startSliceIndex * 2)), bufferBytes);
/*
	if (0 < sampleBytes)
		printf("   sound_RecordSamplesIntoAtLength(%d, %d, %d) %d, %d\n", buf, startSliceIndex, bufferSizeInBytes, bufferNext, sampleBytes);
	else
		printf("***sound_RecordSamplesIntoAtLength(%d, %d, %d) %d, %d\n", buf, startSliceIndex, bufferSizeInBytes, bufferNext, sampleBytes);
*/	
	return MAX(0, sampleBytes)/(2 * audioIn.pa_spec.channels);
}


/* ================================== sound mixer */

/*
static int     sound_nomixer  = 0;
static snd_mixer_t  *mixer_handle = 0;
static snd_mixer_elem_t *mixer_element  = 0;
*/

static int mixer_open(char *name) {
  trace();
  return -EACCES;
}

static void mixer_close(void) {
  trace();
}

static inline void mixer_getVolume(char *name, int captureFlag, double *leftLevel, double *rightLevel) {
  trace();
}

static inline void mixer_setVolume(char *name, int captureFlag, double leftLevel, double rightLevel) {
  trace();
}

static int mixer_setSwitch(char *name, int captureFlag, int parameter) {
  trace();
  return 0;
}

static int mixer_getSwitch(char *name, int captureFlag, int channel) {
  trace();
  return -1;
}

static void sound_Volume(double *left, double *right) {
  trace();
  *left= 1.0;
  *right= 1.0;
}

static void sound_SetVolume(double left, double right) {
  trace();
}

static sqInt sound_SetRecordLevel(sqInt level) {
  trace();
  return 1;
  return level;
}

static sqInt sound_SetDevice(sqInt id, char *arg) {
  trace();
  return -1;
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel) {
  trace();
  return -1;
}

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter) {
  trace();
  return -1;
}


/* module */

#include "SqSound.h"

SqSoundDefine(PA);

#include "SqModule.h"

static void sound_parseEnvironment(void) {
/*
  char *ev= 0;

  sound_SetDevice(0, NULL);
  sound_SetDevice(1, NULL);
  sound_SetDevice(2, NULL);

  if (     getenv("SQUEAK_NOMIXER"   )) sound_nomixer= 1;
  if ((ev= getenv("SQUEAK_SOUNDCARD"))) sound_SetDevice(0, ev);
  if ((ev= getenv("SQUEAK_PLAYBACK" ))) sound_SetDevice(1, ev);
  if ((ev= getenv("SQUEAK_CAPTURE"  ))) sound_SetDevice(2, ev);
*/
}

static int sound_parseArgument(int argc, char **argv) {
/*
  if     (!strcmp(argv[0], "-nomixer"  )) { sound_nomixer= 1;   return 1; }
  else if (argv[1])
    {
      if (!strcmp(argv[0], "-soundcard")) { sound_SetDevice(0, argv[1]);  return 2; }
      if (!strcmp(argv[0], "-playback" )) { sound_SetDevice(1, argv[1]);  return 2; }
      if (!strcmp(argv[0], "-capture"  )) { sound_SetDevice(2, argv[1]);  return 2; }
    }
*/
  return 0;
}

static void  sound_printUsage(void) {
  printf("\nPulseAudio <option>s: <none>\n");
/*
  printf("  -nomixer              disable mixer (volume) adjustment\n");
  printf("  -soundcard <name>     open the named sound card (default: %s)\n", sound_device);
  printf("  -playback <name>      play to the named sound device (default: %s)\n", sound_playback);
  printf("  -capture <name>       record from the named sound device (default: %s)\n", sound_capture);
*/
}

static void  sound_printUsageNotes(void) {
}

static void *sound_makeInterface(void) {
/*#ifdef NEWSIG
//  sigalrm_save(); // DMOC: Being here assumes old handler same for run duration! Same for sigio handler.
//#else
// DMOC: Rethink: Signal captured once, preserved and restored when/where necessary?
//  sigio_save();
//#endif
*/
	
#ifdef USE_RESOURCE_MANAGER
printf("USE_RESOURCE_MANAGER\n");
#endif
	
	ioInit();
	
  return &sound_PA_itf;
}

SqModuleDefine(sound, pulse);
