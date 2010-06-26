/* sqUnixSoundNAS.c -- sound support for the Network Audio System
 *
 * Author: Lex Spoon <lex@cc.gatech.edu>
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
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
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

#include "sq.h"
#include "sqaio.h"

#include <audio/audiolib.h>
#include <assert.h>

#ifdef DEBUG
# define DPRINTF printf
#else
  static void DPRINTF(char *fmt, ...) {}
#endif


#ifdef WORDS_BIGENDIAN
# define AU_FORMAT	AuFormatLinearSigned16MSB
#else
# define AU_FORMAT	AuFormatLinearSigned16LSB
#endif


static int sound_Stop(void);

/** routines for converting samples to different formats **/

/* XXX actually, I don't think NAS will need conversion.  However,
   SunOS could use it... */

#define BYTES_PER_SAMPLE	2		/* Squeak always uses 16-bit samples */

#ifdef HAS_MSB_FIRST
# define IS_BIGENDIAN 1
#else
# define IS_BIGENDIAN 0
#endif


/* specification of the output format.  (Squeak's format is fixed:
   stereo, 16-bit, host-endian, signed) */

static int fmtBytes=             2;  /* bytes per sample the device is using */
static int fmtSigned=            1;  /* whether the device uses signed samples */
static int fmtStereo=		 0;  /* whether the device is in stereo */
static int fmtIsBigendian=       0;  /* whether the device is big-endion */


/* whether the device is differently-ended than Squeak */

#define auSwapBytes (fmtIsBigendian != IS_BIGENDIAN)


/* calculate number of bytes per frame, given the current mode */

static int bytesPerPlayFrame(void)
{
#if 1		/* ikp doesn't understand why this ... */
  int bytes= 1;
  bytes *= fmtBytes;
  if (fmtStereo)
    bytes *= 2;
  return bytes;
#else		/* ... doesn't look like this */
  return fmtBytes * (fmtStereo ? 2 : 1);
#endif
}


#define FAIL(X) { success(false); return X; }

static AuServer *server = NULL;   /* the audio server to write to */
static int recording=0;        /* whether this module is recording
				  or playing.  Only valid if
				  server!= NULL . */
static AuFlowID flow;          /* the NAS flow being used */
static int semaIndex;          /* the semaphore to signal Squeak with */
static int stereo;             /* whether Squeak sees stereo or not */
static int bytesAvail;         /* current number of bytes that may be written
				  or read from the server */
static int sampleRate;         /* the sample rate of the device.
				  Currently not accurate. */


static int sound_AvailableSpace(void) 
{
  if(server == NULL)
    return 0;

  return bytesAvail;
}

static int sound_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
{
  /* not possible, I don't think using NAS */
  success(false);
  return 0;
}


static int sound_Stop(void)
{
  if(server != NULL) {
    aioDisable(AuServerConnectionNumber(server));
		    
    AuCloseServer(server);
    server = NULL;
  }

  return 0;
}


     

     
static int sound_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  int bytesToPlay;
  int framesToPlay;
  char *buf;   /* buffer to play from; it may not be arrayIndex if a
                  conversion is necessary */

  DPRINTF("PlaySamples(frameCount=%d, arrayIndex=%d, startIndex=%d\n",
	  frameCount, arrayIndex, startIndex);
  
  /* figure out how much to play */
  bytesToPlay = frameCount * bytesPerPlayFrame();
  if (bytesToPlay > bytesAvail)
    bytesToPlay = bytesAvail;
  
  framesToPlay = bytesToPlay / bytesPerPlayFrame();

  /* convert the buffer when not in stereo; when playing back, Squeak
     will send mono data as stereo, where the right channel is to be
     ignored */
  if(stereo)
    {
      buf= (char *) (arrayIndex + 4*startIndex);
    }
  else
    {
      int i;
      short *sbuf;  /* the buffer, as short's instead of char's */

      DPRINTF("converting\n");
      
      buf= malloc(2 * frameCount);
      if(buf == NULL)
	{
	  fprintf(stderr, "out of memory\n");
	  return 0;
	}
      sbuf= (short *) buf;
      

      for(i=0; i<frameCount; i++)
	{
	  sbuf[i]= ((short *) (arrayIndex + 4*startIndex)) [2*i];
	}
    }
      
	
  DPRINTF("writing %d bytes (%d frames)\n", bytesToPlay, framesToPlay);
  AuWriteElement(server, flow, 0,
		 bytesToPlay,
		 buf,
		 AuFalse,
		 NULL);
  AuFlush(server);
  

  bytesAvail -= bytesToPlay;

  if(!stereo)
    {
      free(buf);
    }
  
  return framesToPlay;
}


/* Process audio events from the NAS server.  The same routine is used
   whether we are recording or playing back */
static void handleAudioEvents(int fd, void *data, int flags)
{
  if(!server) {
    DPRINTF( "handleAudioEvents called while unconnected!\n");
    return;
  }

  /* read events once */
  AuEventsQueued(server, AuEventsQueuedAfterReading);

  /* then loop through the read queue */
  while(AuEventsQueued(server, AuEventsQueuedAlready)) {
    AuEvent event;
    AuNextEvent(server, AuTrue, &event);
    DPRINTF("event of type %d\n", event.type);
    
    switch(event.type) {
    case 0:
      {
	AuErrorEvent *errEvent = (AuErrorEvent *) &event;
	char errdesc[1000];
      
	AuGetErrorText(server, errEvent->error_code, errdesc, sizeof(errdesc));
	fprintf(stderr, "audio error: %s\n", errdesc);
	sound_Stop();
	return;  /* return, not break, so that we don't
		    process the now-closed server any longer! */
      }
    

    case AuEventTypeElementNotify:
      {
	AuElementNotifyEvent *enEvent = (AuElementNotifyEvent *)&event;

	switch(enEvent->kind) {
	case AuElementNotifyKindLowWater:
	  DPRINTF("low water event\n");
	  bytesAvail += enEvent->num_bytes;
	  break;
	case AuElementNotifyKindHighWater:
	  DPRINTF("high water event\n");
	  bytesAvail += enEvent->num_bytes;
	  break;
	case AuElementNotifyKindState:
	  DPRINTF("state change (%d->%d)\n",
		  enEvent->prev_state,
		  enEvent->cur_state);
	  bytesAvail += enEvent->num_bytes;
	  if(enEvent->cur_state == AuStatePause) {
	       /* if the flow has stopped, then arrange for it to get started again */
	       /* XXX there is probably a more intelligent place to do
                  this, in case there is a real reason it has paused */
	       DPRINTF("unpausing\n");
	       AuStartFlow(server, flow, NULL);
	       AuFlush(server);
	  }

	  break;
	}
      }
    }
  }

  if(bytesAvail > 0) {
    DPRINTF("bytesAvail: %d\n", bytesAvail);
    signalSemaphoreWithIndex(semaIndex);
  }

  aioHandle(fd, handleAudioEvents, flags & AIO_RW);
}

static int sound_PlaySilence(void) 
{
     return 0;
}


static AuDeviceID choose_nas_device(AuServer *server, int samplesPerSec, int stereo, int recording) 
{
  int desiredDeviceKind=
    recording ?
       AuComponentKindPhysicalInput :
       AuComponentKindPhysicalOutput;
  int desired_channels= stereo ? 2 : 1;
  int i;
  
  /* look for a physical device of the proper kind, with the proper number of channels */
  for (i = 0; i < AuServerNumDevices(server); i++) {
    if((AuDeviceKind(AuServerDevice(server, i))
	==  desiredDeviceKind)
       && (AuDeviceNumTracks(AuServerDevice(server, i))
	   ==  desired_channels))
	 return AuDeviceIdentifier(AuServerDevice(server, i));
  }



  /* look for a physical device of the proper kind; ignore number of channels */
  for (i = 0; i < AuServerNumDevices(server); i++) {
    if(AuDeviceKind(AuServerDevice(server, i))
       ==  desiredDeviceKind)
	 return AuDeviceIdentifier(AuServerDevice(server, i));
  }



  return AuNone;
}

static int sound_Start(int frameCount, int samplesPerSec, int stereo0, int semaIndex0)
{
  AuElement elements[2];  /* first is a client element, second is
			     a device output element */
  AuDeviceID device;        /* ID of the device to play to */
  

  /* open the server */
  DPRINTF("opening server\n");
  server = AuOpenServer(NULL, 0, NULL, 0, NULL, NULL);
  if(server == NULL) {
    DPRINTF("failed to open audio server\n");
    return false;
  }

  /* XXX should check the protocol version! */

  /* record requested info */
  semaIndex = semaIndex0;
  stereo = stereo0;
  sampleRate= samplesPerSec;
  
  /* pick a device to play to */ 
  device = choose_nas_device(server, samplesPerSec, stereo, 0);
  if(device == AuNone) {
    DPRINTF("no available device on the server!\n");
    AuCloseServer(server);
    server = NULL;
    return false;
  }

  /* set up output parameters */
  fmtBytes=2;
  fmtSigned=1;
  fmtStereo=stereo;
  fmtIsBigendian=0;
  recording=0;
  


  /* create a flow to write on */
  DPRINTF("creating flow\n");
  flow = AuCreateFlow(server, NULL);


  /* create client and device elements to play with */
  DPRINTF("creating elements(%d,%d)\n",
	 frameCount, frameCount / 4);
  AuMakeElementImportClient(&elements[0],
			    samplesPerSec,
			    AuFormatLinearSigned16LSB,  /* XXX this should be chosen based on the platform */
			    stereo ? 2 : 1,
			    AuTrue,
			    2*frameCount,   /* max: 2 buffers */
			    frameCount,   /* low */
			    0, NULL);
	
  AuMakeElementExportDevice(&elements[1],
			    0,
			    device,
			    samplesPerSec,
			    AuUnlimitedSamples,
			    0, NULL);

  /* set up the flow with these elements */
  AuSetElements(server,	flow,
		AuTrue,
		2, elements,
		NULL);

  /* start her up */
  DPRINTF("starting flow\n");
  AuStartFlow(server, flow, NULL);
  AuFlush(server);
  

  /* initialize the space indication */
  bytesAvail = 0;

  
  /* arrange to be informed when events come in from the server */
  aioEnable(AuServerConnectionNumber(server), 0, AIO_EXT);
  aioHandle(AuServerConnectionNumber(server), handleAudioEvents, AIO_R);



  return true;
}



/* StartRecording: open the device for recording.

   XXX this routine is almost identical to snd_Start().  The two should
   be factored into a single function!
*/
static int sound_StartRecording(int desiredSamplesPerSec, int stereo0, int semaIndex0)
{
  AuElement elements[2];  /* elements for the NAS flow to assemble:
   			        element 0 = physical input
			        element 1 = client export */
  AuDeviceID device;      /* physical device ID to use */
  
  DPRINTF("StartRecording\n");
  
  sound_Stop();

  DPRINTF("opening server\n");
  server = AuOpenServer(NULL, 0, NULL, 0, NULL, NULL);
  if(server == NULL) {
    DPRINTF("failed to open audio server\n");
    return false;
  }

  /* XXX check protocol version of the server */

  semaIndex= semaIndex0;
  stereo= stereo0;
  sampleRate= desiredSamplesPerSec;

  device= choose_nas_device(server, desiredSamplesPerSec, stereo, 1);
  if(device == AuNone) {
    DPRINTF("no available device on the server!\n");
    AuCloseServer(server);
    server = NULL;
    return false;
  }

  /* record format info */
  fmtBytes=2;
  fmtSigned=1;
  fmtStereo=stereo;
  fmtIsBigendian=0;
  recording=1;


  

  /* create a flow to read from */
  DPRINTF("creating flow\n");
  flow = AuCreateFlow(server, NULL);


  /* create client and device elements to record with */
  DPRINTF("creating elements\n");

  
  AuMakeElementImportDevice(&elements[0],
			    desiredSamplesPerSec,  /* XXX should use the actual sampling rate of device */
			    device,
			    AuUnlimitedSamples,
			    0, NULL);

  AuMakeElementExportClient(&elements[1],
			    0,
			    desiredSamplesPerSec,
			    AuFormatLinearSigned16LSB,  /* XXX this should be chosen based on the platform */
			    stereo ? 2 : 1,
			    AuTrue,
			    1000000,  /* was AuUnlimitedSamples */
			    1000, /* water mark: go ahead and send frequently! */
			    0, NULL);
	


  /* set up the flow with these elements */
  AuSetElements(server,	flow,
		AuTrue,
		2, elements,
		NULL);

  /* start her up */
  DPRINTF("starting flow\n");
  AuStartFlow(server, flow, NULL);
  AuFlush(server);
  

  /* initialize the space indication */
  bytesAvail = 0;

  
  /* arrange to be informed when events come in from the server */
  aioEnable(AuServerConnectionNumber(server), NULL, AIO_EXT);
  aioHandle(AuServerConnectionNumber(server), handleAudioEvents, AIO_W);

  return true;
}


static int sound_StopRecording(void) 
{
     return sound_Stop();
}



static double sound_GetRecordingSampleRate(void) 
{
  return sampleRate;
}

     
static int sound_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
{
  int bytesToRead;
  int sliceSize= (stereo ? 4 : 2);   /* a "slice" seems to be a "frame": one sample from each channel */
  

  DPRINTF("RecordSamplesIntoAtLength(buf=%d, startSliceIndex=%d, bufferSizeInBytes=%d\n",
	  buf, startSliceIndex, bufferSizeInBytes);
  
  
  /* sanity checks */
  if(server==NULL || !recording) {
    success(false);
    return 0;
  }

  if(bytesAvail <= 0)
    return 0;

  /* figure out how much to read */
  bytesToRead= bufferSizeInBytes - (startSliceIndex * sliceSize);
  if(bytesToRead > bytesAvail)
    bytesToRead= bytesAvail;

  DPRINTF("reading %d bytes\n", bytesToRead);
  

  /* read it */
  AuReadElement(server,
		flow,
		1,     /* element 1 is the client export */
		bytesToRead,
		(char *) (buf + startSliceIndex*sliceSize),
		NULL);

  bytesAvail -= bytesToRead;
  
  return bytesToRead/sliceSize;  /* return number of samples read (or slices?!) */
}




/* mixer settings */
static int sound_SetRecordLevel(int level) 
{
  return level;
}



static void sound_Volume(double *left, double *right)
{
  return;
}


static void sound_SetVolume(double left, double right)
{
  return;
}


#include "SqSound.h"

SqSoundDefine(NAS);


#include "SqModule.h"

static void  sound_parseEnvironment(void) {}

static int   sound_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nas")) return 1;
  return 0;
}

static void  sound_printUsage(void) {}
static void  sound_printUsageNotes(void) {}
static void *sound_makeInterface(void) { return &sound_NAS_itf; }

SqModuleDefine(sound, NAS);
