/* sqUnixSound.c -- sound support for various Unix sound systems
 *
 */



#include "sq.h"

#undef AUDIO_DRIVER_SELECTED   /* will be defined as soon as one sound
				  module matches. */




#if defined(USE_AUDIO_NAS) || defined(USE_AUDIO_OSS)
/** routines for converting samples to different formats **/

/* XXX actually, I don't think NAS will need conversion.  However, SunOS could use it.... */

#include <assert.h>


#define BYTES_PER_SAMPLE	2		/* Squeak always uses 16-bit samples */

#ifdef HAS_MSB_FIRST
#define IS_BIGENDIAN 1
#else
#define IS_BIGENDIAN 0
#endif


/* specification of the output format.
   (Squeak's format is fixed: stereo, 16-bit, host-endian, signed) */

static int fmtBytes=             2;  /* bytes per sample the device is using */
static int fmtSigned=            1;  /* whether the device uses signed samples */
static int fmtStereo=		0;  /* whether the device is in stereo */
static int fmtIsBigendian=       0;  /* whether the device is big-endion */


/* whether the device is differently-ended than Squeak */
#define auSwapBytes (fmtIsBigendian != IS_BIGENDIAN)



/* calculate number of bytes per frame, given the current mode */
static int bytesPerPlayFrame()
{
     int bytes;
     
     bytes = 1;
     bytes *= fmtBytes;
     if(fmtStereo)
	  bytes *= 2;

     return bytes;
}



/* transform samples in the device's format, to squeak's format */
static void cardToSqueak(unsigned char *src,
			 int numSamples,
			 unsigned char *dest)
{
  int samplesConsumed;
  int sample;

#ifdef TRACE
  fprintf(stderr, "convertToSqueak(%p, %d, %p)\n",
	  src, numSamples, dest);
#endif
     
  for(samplesConsumed = 0; samplesConsumed<numSamples; samplesConsumed++) {
    if(fmtBytes == 1) {
      /* 8-bit audio */
      if(fmtSigned) {
	sample = *src;
      } else {
	sample = *src - 128;
      }
      dest[0] = sample;
      dest[1] = sample;

      src += 1;
    }
    else {
      /* 16-bit */
      if(auSwapBytes) {
	dest[0] = src[1];
	dest[1] = src[0];
      }
      else {
	dest[0] = src[0];
	dest[1] = src[1];
      }
	       
      if(!fmtSigned) {
	if(IS_BIGENDIAN)
	  dest[0] -= 128;
	else
	  dest[1] -= 128;
      }

      src += 2;
    }
    dest += 2;
  }
}


/* transform samples from Squeak's format to the sound card's format */
static int squeakToCard(unsigned char *src,
			int numFrames,
			unsigned char *destBuffer)
{
  unsigned char *dest;      /* next byte to write into */
  int halfFramesConsumed = 0; /* number of half-frames used up */
  int bytesWritten = 0;     /* number of bytes written so far */
     

  dest = destBuffer;
     
#if defined(TRACE) || 0
  fprintf(stderr,
	  "(%d)converting %d frames from %p to %p\n",
	  utime(), numFrames, src, dest);
#endif

  while(halfFramesConsumed/2 < numFrames) {
    /* only write odd frames if we are in stereo */
    if(fmtStereo || (halfFramesConsumed%2 == 1)) {
      if(fmtBytes == 1) {
	/* 8-bit sound device; write the MSB only */
	if(IS_BIGENDIAN)
	  *dest = src[0];
	else
	  *dest = src[1];

	/* convert it to unsigned, if necessary */
	if(! fmtSigned)
	  *dest = *dest + 128;
			 
	dest += 1;
	bytesWritten += 1;
      }
      else {
	/* 16-bit sound device.  more fun */
			 
	unsigned char byte0=src[0], byte1=src[1];
			 
	/* convert to unsigned if necessary */
	if(! fmtSigned) {
	  /* add 16384 by adding 128 to the high
	   * byte */
	  if(IS_BIGENDIAN)
	    byte0 += 128;
	  else
	    byte1 += 128;
	}
			 
				   
	/* copy the bytes into the output buffer,
	 * swapping if necessary */
	if(auSwapBytes) {
	  dest[0] = byte1;
	  dest[1] = byte0;
	}
	else {
	  dest[0] = byte0;
	  dest[1] = byte1;
	}

			 
	dest += 2;
	bytesWritten += 2;
      }
    }

    /* even if we only skiped the sample, we have consumed
       another half-frame and 2 bytes of source */
    halfFramesConsumed += 1;
    src += 2;

  }


#ifdef TRACE
  fprintf(stderr,
	  "converted %d halfFrames into %d bytes\n",
	  halfFramesConsumed, bytesWritten);
#endif

  assert(halfFramesConsumed % 2 == 0);

     
  return halfFramesConsumed/2;
}

#endif /* USE_AUDIO_NAS || USE_AUDIO_OSS */


/* NAS is the Network Audio System.  NAS uses a network sound server
 * whose streaming interface meshes very nicely with what Squeak needs
 */
 
#if defined(USE_AUDIO_NAS)
#define AUDIO_DRIVER_SELECTED

#include <audio/audiolib.h>
#include "sqaio.h"

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



#if 0
#define DEBUG
#endif
#ifdef DEBUG
#define dprintf printf
#else
static void dprintf(const char *fmt, ...) {}
#endif


int snd_AvailableSpace(void) 
{
  if(server == NULL)
    return 0;

  return bytesAvail;
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
{
  /* not possible, I don't think using NAS */
  success(false);
  return 0;
}


int snd_Stop(void)
{
  if(server != NULL) {
    aioStopHandling(AuServerConnectionNumber(server));
		    
    AuCloseServer(server);
    server = NULL;
  }

  return 0;
}


     

     
int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  int bytesToPlay;
  int framesToPlay;
  char *buf;   /* buffer to play from; it may not be arrayIndex if a
                  conversion is necessary */
  

  dprintf("PlaySamples(frameCount=%d, arrayIndex=%d, startIndex=%d\n",
	  frameCount, arrayIndex, startIndex);
  
  /* figure out how much to play */
  bytesToPlay = frameCount * bytesPerPlayFrame();
  if(bytesToPlay > bytesAvail)
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

      dprintf("converting\n");
      
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
      
	
  dprintf("writing %d bytes (%d frames)\n", bytesToPlay, framesToPlay);
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
static void handleAudioEvents(void *data, int ignored, int ignored2, int ignored3)
{
  if(!server) {
    dprintf( "handleAudioEvents called while unconnected!\n");
    return;
  }

  /* read events once */
  AuEventsQueued(server, AuEventsQueuedAfterReading);

  /* then loop through the read queue */
  while(AuEventsQueued(server, AuEventsQueuedAlready)) {
    AuEvent event;
    AuNextEvent(server, AuTrue, &event);
    dprintf("event of type %d\n", event.type);
    
    switch(event.type) {
    case 0:
      {
	AuErrorEvent *errEvent = (AuErrorEvent *) &event;
	char errdesc[1000];
      
	AuGetErrorText(server, errEvent->error_code, errdesc, sizeof(errdesc));
	fprintf(stderr, "audio error: %s\n", errdesc);
	snd_Stop();
	return;  /* return, not break, so that we don't
		    process the now-closed server any longer! */
      }
    

    case AuEventTypeElementNotify:
      {
	AuElementNotifyEvent *enEvent = (AuElementNotifyEvent *)&event;

	switch(enEvent->kind) {
	case AuElementNotifyKindLowWater:
	  dprintf("low water event\n");
	  bytesAvail += enEvent->num_bytes;
	  break;
	case AuElementNotifyKindHighWater:
	  dprintf("high water event\n");
	  bytesAvail += enEvent->num_bytes;
	  break;
	case AuElementNotifyKindState:
	  dprintf("state change (%d->%d)\n",
		  enEvent->prev_state,
		  enEvent->cur_state);
	  bytesAvail += enEvent->num_bytes;
	  if(enEvent->cur_state == AuStatePause) {
	       /* if the flow has stopped, then arrange for it to get started again */
	       /* XXX there is probably a more intelligent place to do
                  this, in case there is a real reason it has paused */
	       dprintf("unpausing\n");
	       AuStartFlow(server, flow, NULL);
	       AuFlush(server);
	  }

	  break;
	}
      }
    }
  }

  if(bytesAvail > 0) {
    dprintf("bytesAvail: %d\n", bytesAvail);
    signalSemaphoreWithIndex(semaIndex);
  }
}

int snd_PlaySilence(void) 
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

int snd_Start(int frameCount, int samplesPerSec, int stereo0, int semaIndex0)
{
  AuElement elements[2];  /* first is a client element, second is
			     a device output element */
  AuDeviceID device;        /* ID of the device to play to */
  

  /* open the server */
  dprintf("opening server\n");
  server = AuOpenServer(NULL, 0, NULL, 0, NULL, NULL);
  if(server == NULL) {
    dprintf("failed to open audio server\n");
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
    dprintf("no available device on the server!\n");
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
  dprintf("creating flow\n");
  flow = AuCreateFlow(server, NULL);


  /* create client and device elements to play with */
  dprintf("creating elements(%d,%d)\n",
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
  dprintf("starting flow\n");
  AuStartFlow(server, flow, NULL);
  AuFlush(server);
  

  /* initialize the space indication */
  bytesAvail = 0;

  
  /* arrange to be informed when events come in from the server */
  aioHandle(AuServerConnectionNumber(server), handleAudioEvents, NULL, AIO_RD);



  return true;
}



/* StartRecording: open the device for recording.

   XXX this routine is almost identical to snd_Start().  The two should
   be factored into a single function!
*/
int snd_StartRecording(int desiredSamplesPerSec, int stereo0, int semaIndex0) 
{
  AuElement elements[2];  /* elements for the NAS flow to assemble:
   			        element 0 = physical input
			        element 1 = client export */
  AuDeviceID device;      /* physical device ID to use */
  
  dprintf("StartRecording\n");
  
  snd_Stop();

  dprintf("opening server\n");
  server = AuOpenServer(NULL, 0, NULL, 0, NULL, NULL);
  if(server == NULL) {
    dprintf("failed to open audio server\n");
    return false;
  }

  /* XXX check protocol version of the server */

  semaIndex= semaIndex0;
  stereo= stereo0;
  sampleRate= desiredSamplesPerSec;

  device= choose_nas_device(server, desiredSamplesPerSec, stereo, 1);
  if(device == AuNone) {
    dprintf("no available device on the server!\n");
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
  dprintf("creating flow\n");
  flow = AuCreateFlow(server, NULL);


  /* create client and device elements to record with */
  dprintf("creating elements\n");

  
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
  dprintf("starting flow\n");
  AuStartFlow(server, flow, NULL);
  AuFlush(server);
  

  /* initialize the space indication */
  bytesAvail = 0;

  
  /* arrange to be informed when events come in from the server */
  aioHandle(AuServerConnectionNumber(server), handleAudioEvents, NULL, AIO_RD);

  return true;
}


int snd_StopRecording(void) 
{
     return snd_Stop();
}



double snd_GetRecordingSampleRate(void) 
{
  return sampleRate;
}

     
int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
{
  int bytesToRead;
  int sliceSize= (stereo ? 4 : 2);   /* a "slice" seems to be a "frame": one sample from each channel */
  

  dprintf("RecordSamplesIntoAtLength(buf=%d, startSliceIndex=%d, bufferSizeInBytes=%d\n",
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

  dprintf("reading %d bytes\n", bytesToRead);
  

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
int snd_SetRecordLevel(int level) 
{
     return level;
}



void snd_Volume(double *left, double *right)
{
  return;
}


void snd_SetVolume(double left, double right)
{
  return;
}


#endif



/* OSS - the "Open Sound System".  This is frequently available on
 * Linux, although it can be instaled on other systems as well.
 * See <http://www.opensound.com/> for details and downloads.
 */

 

#if defined(USE_AUDIO_OSS)

#define AUDIO_DRIVER_SELECTED

#define SOUND_DEVICE		OSS_DEVICE

#define NUM_FRAGMENTS		4	/* number of buffer fragments */
#define HWM_FRAGMENTS		2	/* play semaphore hysteresis */

#include "sqaio.h"
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/soundcard.h>

static unsigned char *auBuf=	0;

static int auFd=		-1;    /* fd for /dev/dsp */
static int auReading=           0;     /* whether we are reading or writing */
static int auFrameCount=	0;
static int auSampleRate=	0;
static int auSemaIndex=		0;
static int auBufBytes=		0;


static int auSemaWaiting=	0;

static int mixerFd=            -1;   /* fd for /dev/mixer */





/*** Mixer routines ***/


/* close the mixer, if it is open */
static void close_mixer() 
{
  if(mixerFd >= 0) {
    close(mixerFd);
    mixerFd = -1;
  }
}

/* open the mixer if it isn't already */
static void ensure_mixer_is_open()
{
  if(mixerFd >= 0)
    return;  /* it's already open */

  /* it's not open; try to open it now */
  mixerFd = open("/dev/mixer", O_RDWR);
}


/* query the current play volume */
void snd_Volume(double *left, double *right)
{
  int encodedVolume;
  
  ensure_mixer_is_open();
    
  /* check that the mixer is available */
  if(mixerFd < 0) {
    success(false);
    return;
  }
  

  /* read the volume */
  if(ioctl(mixerFd, SOUND_MIXER_READ_VOLUME, &encodedVolume)) {
    success(false);
    return;
  }
  

  /* decode it */
  *left = (encodedVolume & 0xFF) / 100.0;
  *right = ((unsigned)(encodedVolume & 0xFF00) >> 8) / 100.0;
}


/* helper for snd_SetVolume: clamp a float between two bounds */
static double clampf(double number, double lowerBound, double upperBound)
{
  if(number < lowerBound)
    return lowerBound;
  if(number > upperBound)
    return upperBound;
  return number;
}


void snd_SetVolume(double left, double right)
{
  int encodedVolume;
  double clampedLeft, clampedRight;

  ensure_mixer_is_open();
  
  /* check that the mixer is available */
  if(mixerFd < 0) {
    success(false);
    return;
  }

  /* encode the volume */
  clampedLeft = clampf(left, 0, 1);
  clampedRight = clampf(right, 0, 1);
  encodedVolume = ((clampedRight  * 100) * 256)  +  (clampedLeft * 100);

  /* set the volume */
  if(ioctl(mixerFd, SOUND_MIXER_WRITE_VOLUME, &encodedVolume)) {
    success(false);
    return;
  }
}



/*** /dev/dsp routines ***/



#if 0
/* We assume that there's enough h/w buffer lead to soak up the
 * maximum input polling period in the event loop.  This should be
 * true even on slow machines (e.g. 133Mhz 386).  If not (i.e there
 * are glitches in the sound output even when Squeak is otherwise
 * idle) then #undef USE_SEMAPHORES above, and recompile to force the
 * SoundPlayer to poll every millisecond.
 */
void auPollForIO(void)
{
  struct audio_buf_info info;

  if (auFd < 0) return;

  if(auReading) {
    /* recording mode */
    if(ioctl(auFd, SNDCTL_DSP_GETISPACE, &info) < 0) {
      perror("ioctl(SNDCTL_DSP_GETISPACE");
      return;
    }
    
#ifdef TRACE
    printf("auPollForIO(recording): fragments=%d  fragstotal=%d  fragsize=%d  bytes=%d\n",
	   info.fragments, info.fragstotal, info.fragsize, info.bytes);
#endif
      
    if(info.fragments > 0) {
      signalSemaphoreWithIndex(auSemaIndex);
    }
  }
  else {
    /* play mode */
    if(!auSemaWaiting)
      return;
    
    if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) < 0) {
	 perror("ioctl(SNDCTL_DSP_GETOSPACE)");
	 return;
    }
    else
    if (info.fragments > HWM_FRAGMENTS) {
      auSemaWaiting= false;
      signalSemaphoreWithIndex(auSemaIndex);
    }
  }
}
#endif


static void auHandleDescriptorActivity(void *data,
				       int readFlag, int writeFlag, int exceptionFlag)
{
     if(auReading && readFlag)
	  signalSemaphoreWithIndex(auSemaIndex);
     
     if(!auReading && writeFlag)
	  signalSemaphoreWithIndex(auSemaIndex);
}




/* reimplemented because ffs() is broken on some machines
 */
static int findFirstBit(int i)
{
  int p;
  for (p= 0; i != 0; i >>= 1) ++p;
  return p;
}


/*** exported sound output functions ***/


int snd_Stop(void)
{
  close_mixer();
  
  if (auFd == -1) return 0;

  aioStopHandling(auFd);
  close(auFd);
  auFd= -1;

  free(auBuf);

  auBuf=	0;
  auBufBytes=	0;

  return 0;
}


/* set the input/output format to use, and set the relevant au*
   variables according to what was obtained.  If no suitable format
   was set, return false, else return true. */
static int dsp_set_format() 
{
  int formats;   /* formats available */
  int format;    /* format to use */


  /* obtain the list of available formats */
  if(ioctl(auFd, SNDCTL_DSP_GETFMTS, &formats)) {
    perror("SNDCTL_DSP_GETFMTS");
    return false;
  }
#ifdef TRACE
  fprintf(stderr, "formats = %x\n", formats);
#endif

  /* choose a format from those available */
  if(formats & AFMT_S16_BE)
    format = AFMT_S16_BE;
  else if(formats & AFMT_S16_LE)
    format = AFMT_S16_LE;
  else if(formats & AFMT_U16_BE)
    format =  AFMT_U16_BE;
  else if(formats & AFMT_U16_LE)
    format = AFMT_U16_LE;
  else if(formats & AFMT_S8)
    format = AFMT_S8;
  else if(formats & AFMT_U8)
    format = AFMT_U8;
  else {
    fprintf(stderr, "no supported audio format (%x)\n", formats);
    return false;
  }
  
  /* set the desired format */
  if(ioctl(auFd, SNDCTL_DSP_SETFMT, &format)) {
    perror("SNDCTL_DSP_SETFMT");
    return false;
  }

  
#ifdef TRACE  
  fprintf(stderr, "soundcard format = %d\n", format);
#endif


  /* record info on the format we ended up with */
  switch(format) {
  case AFMT_U16_LE:
    fmtBytes = 2;
    fmtIsBigendian = 0;
    fmtSigned = 0;
    break;

  case AFMT_U16_BE:
    fmtBytes = 2;
    fmtIsBigendian = 1;
    fmtSigned = 0;
    break;
	  
  case AFMT_S16_LE:
    fmtBytes = 2;
    fmtIsBigendian = 0;
    fmtSigned = 1;
    break;

  case AFMT_S16_BE:
    fmtBytes = 2;
    fmtIsBigendian = 1;
    fmtSigned = 1;
    break;

  case AFMT_U8:
    fmtBytes = 1;
    fmtIsBigendian = 42;
    fmtSigned = 0;
    break;

  case AFMT_S8:
    fmtBytes = 1;
    fmtIsBigendian = 42;
    fmtSigned = 1;
    break;

  default:
    /* shouldn't be possible */
    abort();
  }

  

  return true;
}


/* open the dsp device with the given parameters.  Return 0 on
   success, 1 on false.  Sets the au* variables to reflect what has
   happened. */
int dsp_open(int wantReading, int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
     
#ifdef TRACE
  fprintf(stderr, "dsp_open(wantReading=%d, frameCount=%d, samplesPerSec=%d, stereo=%d, semaIndex=%d)\n",
	  wantReading, frameCount, samplesPerSec, stereo, semaIndex);
#endif


  if (auFd != -1) {
    snd_Stop();
  }

  auReading=            wantReading;
  fmtStereo=		(stereo ? 1 : 0);
  auSampleRate=		samplesPerSec;
  auSemaIndex=		semaIndex;


  auFd= open(SOUND_DEVICE, O_NONBLOCK | (wantReading ? O_RDONLY : O_WRONLY), 0);
  if(auFd < 0)  {
    perror(SOUND_DEVICE);  
    return false;
  }

  if(frameCount > 0)
    {
      int bytesPerFrame=	(stereo ? 2 * BYTES_PER_SAMPLE : BYTES_PER_SAMPLE);
      int bufferBytes=	((frameCount * bytesPerFrame) / 8) * 8;
      int arg;
    
      /* round down (NOT up!!!) to nearest power of two */
      int bufferPower=	findFirstBit(bufferBytes) - 1;
      bufferBytes=		1 << bufferPower;

      auFrameCount=		bufferBytes / bytesPerFrame;
      auBufBytes=		bufferBytes;
      arg= (NUM_FRAGMENTS << 16) | (bufferPower);
      if (ioctl(auFd, SNDCTL_DSP_SETFRAGMENT, &arg) == -1) {
	perror("ioctl(SNDCTL_DSP_SETFRAGMENT)");
	goto closeAndFail;
      }

      auBuf= (unsigned char *)malloc(bufferBytes);
    }
  


#if 0
  {
    struct audio_buf_info info;
    if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) == -1) {
      perror("ioctl(SNDCTL_DSP_GETOSPACE)");
      goto closeAndFail;
    }
  }
#endif

  {
    int stereoFlag= fmtStereo;	/* 0 => mono, 1 => stereo */
    if (ioctl(auFd, SNDCTL_DSP_STEREO, &stereoFlag) == -1) {
      perror("ioctl(SNDCTL_DSP_STEREO)");
      goto closeAndFail;
    }
    if (fmtStereo != stereoFlag) {
      fprintf(stderr, "snd_Start: unsupported number of channels\n");
      goto closeAndFail;
    }
  }

  if(! dsp_set_format())
    goto closeAndFail;

  {
    int speed= samplesPerSec;

    if (ioctl(auFd, SNDCTL_DSP_SPEED, &speed) == -1) {
      perror("ioctl(SNDCTL_DSP_SPEED)");  
      goto closeAndFail;
    }  

    if (abs(speed - samplesPerSec) > (samplesPerSec / 100)) {
      /* > 1% sample rate error */
      fprintf(stderr, "snd_Start: using %d samples/second (requested %d)\n",
	      speed, samplesPerSec);
    }

    auSampleRate = speed;
  }


  /* register the sound handler with the aio module */
  {
    int flagsToWatch = AIO_EX;
    if(auReading)
      flagsToWatch |= AIO_RD;
    else
      flagsToWatch |= AIO_WR;
    
    aioHandle(auFd, auHandleDescriptorActivity, NULL, flagsToWatch);
  }
           
  return true;


 closeAndFail:
  close(auFd);
  auFd= -1;
  return false;
}


int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
     return dsp_open(0, frameCount, samplesPerSec, stereo, semaIndex);
}


int snd_AvailableSpace(void)
{
  audio_buf_info info;
  if (auFd < 0) return -1;

  if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) < 0) {
       perror("SNDCTL_DSP_GETOSPACE");
       return 0;
  }
  
  /*  return (info.bytes > auBufBytes) ? auBufBytes : info.bytes;  */
  /*  return (info.fragments == 0) ? 0 : info.fragsize;  */
  if (info.fragments == 0) {
    auSemaWaiting = 1;
    return 0;
  } else {
    int samples;     /* number of samples that may be played */
    int squeakBytes; /* number of "bytes" Squeak wants to see */
    
    
    auSemaWaiting = 0;

    samples= info.fragsize / bytesPerPlayFrame();
    
    if(fmtStereo)
      squeakBytes= samples*4;
    else
      squeakBytes= samples*2;

    return squeakBytes;
  }
}




/* write a buffer fully out to a FD, even if it takes multiple write()
   calls.  Returns 0 on success, or -1 on failure */
static int writeFully(int fd, unsigned char *buf, int count) {
  while (count > 0) {
    int len;
    len= write(auFd, buf, count);
    if (len == -1) {
      if(errno != EINTR && errno != EAGAIN) {
	perror("write");
	return -1;
      }
    }
    else {
      count-= len;
      buf+= len;
    }
  }

  return 0;
}


/* play some samples out to the sound card */
int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  int cardBytesAvail;
  int cardFramesAvail;
  int framesToPlay;


  cardBytesAvail = snd_AvailableSpace();
  cardFramesAvail = cardBytesAvail / bytesPerPlayFrame();

  framesToPlay = frameCount;
  if(framesToPlay > cardFramesAvail)
    framesToPlay = cardFramesAvail;

  {
    unsigned char playBuf[framesToPlay * bytesPerPlayFrame()];

    /* convert the samples */
    squeakToCard((unsigned char *)(arrayIndex + 4*startIndex),
		 framesToPlay,
		 playBuf);

    
    /* write the samples out */
    if(writeFully(auFd, playBuf, sizeof(playBuf))) {
      success(false);
      snd_Stop();
      return 0;
    }
  }
  

  return framesToPlay;
}


/* This primitive is impossible to implement, since the OSS is doing
 * all the necessary buffering for us and there's no way to rewrite
 * data already written.
 *
 * (We could go the whole hog and use direct DMA access to the sound
 * drivers which would allow us to mix into a buffer already partially
 * played - but: (1) OSS only supports DMA on Linux and FreeBSD
 * derivatives, (2) direct access imposes the hardware's byte order
 * and sound format, and (3) the insertSamples call is due to vanish
 * in the near future.)
 */
int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
{
  if (auFd == -1) return -1;
  /* The image says we're allowed to return 0 here, but the
     SoundPlayer barfs up a subscript bounds error.  Ho hum. */
#if 0
  return 0;	/* this is the CORRECT RESPONSE, but the image barfs */
#else
  {
    /* interim solution: play at leasy one buffer's worth of sound
       immediately, suspending the current sound activity.  This is
       a compromise between discarding a buffer's worth of sound
       in every cases except the very first sound to be played, and
       introducing a slight hiccup when a sound is started over the
       top of another one.  The latter is the lesser of the two
       evils. */
    int n= snd_PlaySamplesFromAtLength(frameCount, srcBufPtr, 1);
    frameCount-= n;
    if (frameCount > 0)
      n+= snd_PlaySamplesFromAtLength(frameCount, srcBufPtr, 1 + n);
    return n;
  }
#endif
}


int snd_PlaySilence(void)
{
  if (auFd == -1) return -1;
  /* nothing to do */
  return auBufBytes;
}




int snd_SetRecordLevel(int level)
{
  if(auFd < 0 || !auReading) {
    success(false);
    return false;
  }
  
  return true;
}


int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
{
  int on;
  
  if(!dsp_open(1, -1, desiredSamplesPerSec, stereo, semaIndex))
    return false;
  

  on = 0;
  if(ioctl(auFd, SNDCTL_DSP_SETTRIGGER, &on)) {
    perror("SNDCTL_DSP_SETTRIGGER");
    return snd_Stop();
  }
     

  on = PCM_ENABLE_INPUT;
  if(ioctl(auFd, SNDCTL_DSP_SETTRIGGER, &on)){
    perror("SNDCTL_DSP_SETTRIGGER");
    return snd_Stop();
  }

  return true;
}


int snd_StopRecording(void)
{
  snd_Stop();
  return true; 
}


double snd_GetRecordingSampleRate(void)
{
  if(auFd < 0 || !auReading) {
    success(false);
    return 0.0;
  }
  
  return auSampleRate;
}




/* return the number of bytes that are available to be read from auFd */
static int bytesAvailableToRead() 
{
  struct audio_buf_info info;
  
  if(ioctl(auFd, SNDCTL_DSP_GETISPACE, &info) < 0) {
      perror("ioctl(SNDCTL_DSP_GETISPACE");
      return -1;
  }

  return info.bytes;
}



int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
{
  int samplesDesired;
  int cardBytesDesired;
  int cardBytesAvailable;
  int cardBytesToRead;

#ifdef TRACE
  fprintf(stderr, "recordSamples(startSliceIndex=%d, bufferSize=%d)\n",
	  startSliceIndex, bufferSizeInBytes);
#endif
  
  if(auFd < 0 || !auReading)
    return success(false);

  samplesDesired = bufferSizeInBytes / 2 - startSliceIndex;
  cardBytesDesired = samplesDesired * fmtBytes;

  /* don't read more than is available */
  cardBytesAvailable = bytesAvailableToRead();
  if(cardBytesAvailable < 0)
    return success(false);
  
  if(cardBytesAvailable < cardBytesDesired)
    cardBytesToRead = cardBytesAvailable;
  else
    cardBytesToRead = cardBytesDesired;
  

  {
    char cardBuf[cardBytesToRead];
    int cardBytes;                  /* bytes read in */
    int cardSamples;                /* number of samples that were actually read */

    /* read in the bytes */
    cardBytes = read(auFd, cardBuf, sizeof(cardBuf));
    
    
    if(cardBytes < 0) {
      /* read failure of some kind */
      if(errno == EINTR || errno == EAGAIN) {
      /* temporary error -- return later */
	return 0;
      }
      
      perror("read(auFd)");
      return success(false);
    }

    /* copy the bytes into Squeak's buffer */
    cardSamples = cardBytes / fmtBytes;
    cardToSqueak(cardBuf, cardSamples, (char *) (buf + 2*startSliceIndex));

    return cardSamples;
  }
}

#endif /* USE_AUDIO_OSS */


/* SUN -- SunOS and Solaris's /dev/dsp interface.
 *
 * This support is rudimentary, and is implemented largely by reading
 * header files and guessing.
 */
#if defined(USE_AUDIO_SUN)
#define AUDIO_DRIVER_SELECTED



/* basic playback support for SunOS and Solaris  */

#include "sqaio.h"


#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#ifdef HAVE_SYS_AUDIOIO_H   /* darn, this file is in a different place between SunOS and Solaris */
#include <sys/audioio.h>
#else
#include <sun/audioio.h>
#endif
#include <errno.h>


static int auFd=		-1;  /* open on /dev/dsp */
static int fmtStereo=		0;   /* whether we are playing in stereo or not */
static int auPlaySemaIndex=	0;   /* an index to signal when new data may be played */
static int auBufBytes=		0;   /*  buffer size to use for playback.  unfortunately, this bears no relationship to whatever the kernal and soundcard are using  */


static int auBuffersPlayed;


static void auPollForIO(void)
{
  if (auFd < 0) return;

  if (snd_AvailableSpace() > 0) {
    signalSemaphoreWithIndex(auPlaySemaIndex);
  }

}

static void auHandleDescriptorActivity(void *data,
				       int readFlag, int writeFlag, int exceptionFlag)
{
  auPollForIO();
}


/*** exported sound output functions ***/


int snd_Stop(void)
{
  if (auFd == -1) return;

  aioStopHandling(auFd);
  close(auFd);
  auFd= -1;

  return 0;
}


int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
     int bytesPerFrame=	(stereo ? 4 : 2);
     int bufferBytes=	((frameCount * bytesPerFrame) / 8) * 8;
     struct audio_info info;
     int err;
     
  
     if (auFd != -1) {
	  snd_Stop();
     }


     auPlaySemaIndex=	semaIndex;
     fmtStereo = stereo;


     auBufBytes = bytesPerFrame * frameCount;
     

  
     if ((auFd= open("/dev/audio", O_WRONLY)) == -1) {
	  perror("/dev/audio");
	  return false;
     }


     /* set up device */
     if(ioctl(auFd, AUDIO_GETINFO, &info)) {
	  perror("AUDIO_GETINFO");
	  goto closeAndFail;
     }
     info.play.gain = 100;
     info.play.precision = 16;
     info.play.encoding = AUDIO_ENCODING_LINEAR;
     info.play.channels = fmtStereo ? 2 : 1;
     info.play.sample_rate = samplesPerSec;

     auBuffersPlayed = info.play.eof;
  

     while((err = ioctl(auFd, AUDIO_SETINFO, &info)) && errno == EINTR)
	  ;
     

     if(err) {
	  perror("AUDIO_SETINFO");
	  goto closeAndFail;
     }

     aioHandle(auFd, auHandleDescriptorActivity, NULL, AIO_WR|AIO_EX);
    
     return true;
  
closeAndFail:
     close(auFd);
     auFd= -1;
     return false;
}


int snd_AvailableSpace(void)
{
  struct audio_info info;
  int ans;
  

  if(auFd < 0)
       return 0;
  
  if(ioctl(auFd, AUDIO_GETINFO, &info)) {
       perror("AUDIO_GETINFO");
       snd_Stop();
  }

  ans = (auBufBytes * (info.play.eof - auBuffersPlayed + 2));


  return ans;
  
}


int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
     short *src = (short *) (arrayIndex + 4*startIndex);
     short buf[2*frameCount];
     int i;
     int bytes;
 

     if (auFd < 0) return -1;

     if(fmtStereo) {
	  bytes = 4 * frameCount;
	  for(i=0; i<2*frameCount; i++) {
	       buf[i] = src[i];
	  }
     }
     else {
	  bytes = 2 * frameCount;
	  for(i=0; i<frameCount; i++)
	       buf[i] = src[2*i];
     }
  
  
    
     /* write data to device from auBuf to dst */
     while (bytes > 0) {
	  int len;
	  char *pos = (char *) buf;
	  
	  len= write(auFd, pos, bytes);
	  if (len < 0) {
	       perror("/dev/audio");
	       return 0;
	  }
	  bytes-= len;
	  pos+= len;
     }

     /* add an eof marker */
     write(auFd, buf, 0);
     auBuffersPlayed += 1;
  
     return frameCount;
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
{
  return 0;
}


int snd_PlaySilence(void)
{
     return 0;
}


/** recording not supported **/
int snd_SetRecordLevel(int level)
{
  success(false);
  return;
}


int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
{
  success(false);
  return;
}


int snd_StopRecording(void)
{
  return;
}


double snd_GetRecordingSampleRate(void)
{
  success(false);
  return 0.0;
}


int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
{
  success(false);
  return 0;
}



void snd_Volume(double *left, double *right)
{
  success(false);
  return;
}


void snd_SetVolume(double left, double right)
{
  success(false);
  return;
}

#endif  /* USE_AUDIO_SUN */



/* NO -- a null device; all primitives simply fail */
#if defined USE_AUDIO_NO
#define AUDIO_DRIVER_SELECTED


#define FAIL(X) { success(false); return X; }

/* sound output */

int snd_AvailableSpace(void)
     FAIL(8192)
int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
     FAIL(frameCount)
int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
     FAIL(8192)
int snd_PlaySilence(void)
     FAIL(8192)
int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
     FAIL(1)
int snd_Stop(void)
     FAIL(0)

/* sound input */

int snd_SetRecordLevel(int level)
     FAIL(0)
int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
     FAIL(0)
int snd_StopRecording(void)
     FAIL(0)
double snd_GetRecordingSampleRate(void)
     FAIL(0)
int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
     FAIL(0)


void snd_Volume(double *left, double *right)
{
  return;
}


void snd_SetVolume(double left, double right)
{
  return;
}

#endif /* USE_AUDIO_NO */


#if !defined(AUDIO_DRIVER_SELECTED)
#error no audio device was selected -- perhaps it was mispelled in the configure command line?
#endif


/*** module initialisation/shutdown ***/


int soundInit(void)
{
  return 1;
}

int soundShutdown(void)
{
  snd_Stop();
  return 1;
}

