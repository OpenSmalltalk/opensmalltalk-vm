/* sqUnixSound.c -- sound support via Open Sound System
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian Piumarta (ian.piumarta@inria.fr)
 *
 * Last edited: 2001-02-08 09:27:04 by piumarta on rnd10-51.rd.wdi.disney.com
 *
 * Note: OSS-compatible drivers are built into the kernel on Linux.
 * Compatibility libraries are available for many other Unix systems.
 * See <http://www.opensound.com/> for details and downloads.
 */

/* TODO:
 * - allow for arbitrary combinations of AFMT_S16_LE and AFMT_S16_BE
 *   for both platform and sound card, then optimise when platform
 *   and sound card use the same format (Intel and PPC use opposite
 *   byte order).
 */

#include "sq.h"
#include "SoundPlugin.h"


#ifdef HAVE_OSS


/* this is currently only supported for Linux */

# define SOUND_DEVICE		OSS_DEVICE
# define BYTES_PER_SAMPLE	2		/* We IMPOSE 16-bit sound! */

# define	USE_SEMAPHORES		/* wait preferred over delay in SoundPlayer */

# define NUM_FRAGMENTS		4	/* number of buffer fragments */
# define HWM_FRAGMENTS		2	/* play semaphore hysteresis */
# define INT_FRAGMENTS			/* r/w integral fragments only */

# include <stdio.h>
# include <unistd.h>
# include <fcntl.h>
# include <sys/time.h>
# include <sys/ioctl.h>
# include <sys/soundcard.h>

# if !defined(OPEN_SOUND_SYSTEM) && !defined(__FreeBSD__)
#    warning: 
#    warning: sys/soundcard.h did not define OPEN_SOUND_SYSTEM
#    warning: SOUND SUPPORT DISABLED
#    warning: 
#    undef HAVE_OSS
# endif

#endif /* HAVE_OSS */


#if defined(HAVE_OSS)

static unsigned char *auBuf=	0;
extern struct VirtualMachine *interpreterProxy;

static int auFd=		-1;
static int auStereo=		0;
static int auFrameCount=	0;
static int auSampleRate=	0;
static int auPlaySemaIndex=	0;
static int auBufBytes=		0;

static int auSemaWaiting=	0;


/* We assume that there's enough h/w buffer lead to soak up the
 * maximum input polling period in the event loop.  This should be
 * true even on slow machines (e.g. 133Mhz 386).  If not (i.e there
 * are glitches in the sound output even when Squeak is otherwise
 * idle) then #undef USE_SEMAPHORES above, and recompile to force the
 * SoundPlayer to poll every millisecond.  (NOTE: doing this grinds
 * performance into the ground!)
 */
void auPollForIO(void)
{
  struct audio_buf_info info;

  if ((auFd == -1) || (auSemaWaiting == 0))
    return;

  if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) == -1)
    {
      perror("ioctl(SNDCTL_DSP_GETOSPACE)");
      return;
    }
  if (info.fragments > 0)
    {
      auSemaWaiting= false;
      interpreterProxy->signalSemaphoreWithIndex(auPlaySemaIndex);
    }
}


/* reimplemented because ffs() is broken on some machines
 */
static int findFirstBit(int i)
{
  int p;
  for (p= 0; i != 0; i >>= 1)
    ++p;
  return p;
}


/*** exported sound output functions ***/


int snd_Stop(void)
{
  if (auFd == -1)
    return 0;
  close(auFd);
  auFd= -1;
  free(auBuf);
  auBuf= 0;
  auBufBytes= 0;
  return 0;
}


int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
  int bytesPerFrame= (stereo ? 2 * BYTES_PER_SAMPLE : BYTES_PER_SAMPLE);
  int bufferBytes= ((frameCount * bytesPerFrame) / 8) * 8;

# ifdef INT_FRAGMENTS
  /* round down (NOT up!!!) to nearest power of two */
  int bufferPower= findFirstBit(bufferBytes) - 1;
  bufferBytes= 1 << bufferPower;
# endif

  if (auFd != -1)
    {
      snd_Stop();
    }

# ifndef USE_SEMAPHORES
  if (semaIndex != 0)
    {
      return false;	/* refuse to handle the semaphore */
    }
# endif

  auStereo=	   (stereo ? 1 : 0);
  auFrameCount=	   bufferBytes / bytesPerFrame;
  auSampleRate=	   samplesPerSec;
  auPlaySemaIndex= semaIndex;
  auBufBytes=	   bufferBytes;

  if ((auFd= open(SOUND_DEVICE, O_WRONLY, 0)) == -1)
    {
      perror(SOUND_DEVICE);  
      return false;
    }

# ifdef INT_FRAGMENTS
  {
    int arg= (NUM_FRAGMENTS << 16) | (bufferPower);
    if (ioctl(auFd, SNDCTL_DSP_SETFRAGMENT, &arg) == -1)
      {
	perror("ioctl(SNDCTL_DSP_SETFRAGMENT)");
	goto closeAndFail;
      }
  }
# endif

# if 0
  {
    struct audio_buf_info info;
    if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) == -1)
      {
	perror("ioctl(SNDCTL_DSP_GETOSPACE)");
	goto closeAndFail;
      }
  }
# endif

  {
    int format= AFMT_S16_LE;  
    if (ioctl(auFd, SNDCTL_DSP_SETFMT, &format) == -1)
      {
	perror("ioctl(SNDCTL_DSP_SETFMT)");  
	goto closeAndFail;
      }
    if (format != AFMT_S16_LE)
      {  
	fprintf(stderr, "snd_Start: could not select format AFMT_S16_LE\n");
	goto closeAndFail;
      }
  }

  {
    int stereoFlag= auStereo;	/* 0 => mono, 1 => stereo */
    if (ioctl(auFd, SNDCTL_DSP_STEREO, &stereoFlag) == -1)
      {
	perror("ioctl(SNDCTL_DSP_STEREO)");
	goto closeAndFail;
      }
    if (auStereo != stereoFlag)
      {
	fprintf(stderr, "snd_Start: unsupported number of channels\n");
	goto closeAndFail;
      }
  }

  {
    int speed= samplesPerSec;

    if (ioctl(auFd, SNDCTL_DSP_SPEED, &speed) == -1)
      {
	perror("ioctl(SNDCTL_DSP_SPEED)");  
	goto closeAndFail;
      }  

    if (abs(speed - samplesPerSec) > (samplesPerSec / 100))
      {
	/* > 1% sample rate error */
	fprintf(stderr, "snd_Start: using %d samples/second (requested %d)\n",
		speed, samplesPerSec);
      }
  }

  auBuf= (unsigned char *)malloc(bufferBytes);

  if (auBuf != 0)
    {
      /*printf("sound started\n");*/
      return true;
    }

 closeAndFail:
  close(auFd);
  auFd= -1;
  return false;
}


int snd_AvailableSpace(void)
{
  audio_buf_info info;
  if (auFd == -1)
    return -1;

  if (ioctl(auFd, SNDCTL_DSP_GETOSPACE, &info) == -1)
    {
      perror("ioctl(SNDCTL_DSP_GETOSPACE)");
      return 0;
    }
  /*  return (info.bytes > auBufBytes) ? auBufBytes : info.bytes;  */
  /*  return (info.fragments == 0) ? 0 : info.fragsize;  */
  if (info.fragments == 0)
    {
      auSemaWaiting= true;
      return 0;
    }
  else
    {
      return info.fragsize;
    }
}


int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  int framesWritten= 0;

  if (auFd == -1)
    return -1;

# ifdef INT_FRAGMENTS
  if (frameCount < auFrameCount)
    return 0;
# endif

  if (frameCount > auFrameCount)
    framesWritten= auFrameCount;
  else
    framesWritten= frameCount;

  {
    short *src= (short *)(arrayIndex + (startIndex * 4));
    short *end= (short *)(arrayIndex + ((startIndex + framesWritten) * 4));
    unsigned char *dst= auBuf;
    unsigned char *pos= dst;
    if (auStereo)
      {
#       ifdef WORDS_BIGENDIAN
	while (src < end)
	  {
	    short data= *src++;
	    *dst++= (unsigned char)(data & 0xff);		/* lsb first */
	    *dst++= (unsigned char)((data >> 8) & 0xff);
	  }
#       else
	/* elide copy loop for h/w format (little-endian, 16-bit, stereo) */
	dst= (unsigned char *)end;
	pos= (unsigned char *)src;
#       endif
      }
    else
      {
	/* mono: average the left and right channels of the source */
	while (src < end)
	  {
	    int dataL= *src++;
	    int dataR= *src++;
	    short data= (dataL + dataR) >> 1;
	    *dst++= (unsigned char)(data & 0xff);		/* lsb first */
	    *dst++= (unsigned char)((data >> 8) & 0xff);
	  }
      }
    /* write data to device from auBuf to dst */
    {
      int count= dst - pos;
      while (count > 0)
	{
	  int len;
	  len= write(auFd, pos, count);
	  if (len == -1)
	    {
	      perror(SOUND_DEVICE);
	      return 0;
	    }
	  count-= len;
	  pos+= len;
	}
    }
  }
  return framesWritten;
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
  if (auFd == -1)
    return -1;
  /* The image says we're allowed to return 0 here, but the
     SoundPlayer barfs up a subscript bounds error.  Ho hum. */
# if 0
  return 0;	/* this is the CORRECT RESPONSE, but the image barfs */
# else
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
# endif
}


int snd_PlaySilence(void)
{
  if (auFd == -1)
    return -1;
  /* nothing to do */
  return auBufBytes;
}



/*** Recording is not yet implemented.  It's not that it's hard to
     do... I'm just feeling too lazy to do it. ***/


int snd_SetRecordLevel(int level)
{
  return interpreterProxy->success(false);
}


int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
{
  return interpreterProxy->success(false);
}


int snd_StopRecording(void)
{
  return 0;
}


double snd_GetRecordingSampleRate(void)
{
  interpreterProxy->success(false);
  return 0.0;
}


int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex,
				  int bufferSizeInBytes)
{
  interpreterProxy->success(false);
  return 0;
}


void snd_Volume(double *left, double *right)
{
  return;
}


void snd_SetVolume(double left, double right)
{
  return;
}



#else /* !HAVE_OSS */

# warning: SOUND SUPPORT DISABLED

/* dummy definitions for systems without OSS */


void auPollForIO(void)
{
  return;
}

#define FAIL(X) { /*interpreterProxy->success(FALSE);*/ return X; }

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
void snd_Volume(double *left, double *right)
     FAIL(/**/)
void snd_SetVolume(double left, double right)
     FAIL(/**/)


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


#endif /* !HAVE_OSS */



/*** module initialisation/shutdown ***/


typedef void (*soundPollFunction_t)(void);

extern soundPollFunction_t soundPollFunction;

int soundInit(void)
{
  soundPollFunction= auPollForIO;
  return 1;
}

int soundShutdown(void)
{
  snd_Stop();
  return 1;
}
