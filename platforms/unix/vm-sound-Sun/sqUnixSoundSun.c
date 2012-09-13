/* sqUnixSoundSun.c -- sound support for SunOS and Solaris
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *
 *   This file is part of Unix Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 *
 * Authors: Ian.Piumarta@inria.fr, Lex Spoon <lex@cc.gatech.edu>, and
 * 	    Andrew Gaylard <ag@computer.org>
 *
 * This driver is playback-only;  recording sound is not supported at this time.
 * 
 */

#include "sq.h"

#define DEBUG 0

#include "sqaio.h"

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#ifdef HAVE_SYS_AUDIOIO_H
# include <sys/audioio.h>
#else
# include <sun/audioio.h>
#endif
#include <errno.h>
#include <stropts.h>
#include <signal.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

#if DEBUG
#if __STDC_VERSION__ < 199901L
     # if __GNUC__ >= 2
     #  define __func__ __FUNCTION__
     # else
     #  define __func__ "<unknown>"
     # endif
#endif
# define PRINTF(ARGS) 	printf("%s:%d %s ", strrchr(__FILE__, '/') ? 	\
					    strrchr(__FILE__, '/') + 1: \
					    __FILE__,			\
					    __LINE__, __func__); 	\
			printf ARGS ; 					\
			printf("\n")
#else
# define PRINTF(ARGS)
#endif

static sqInt sound_Stop(void);
static int sound_AvailableSpace(void);

static int auFd=	       -1;   /* open on /dev/audio */
static int auCtlFd=	       -1;   /* open on /dev/audioctl */
static sqInt fmtStereo=		0;   /* whether we are playing in stereo or not */
static sqInt auPlaySemaIndex=	0;   /* an index to signal when new data may be played */
static sqInt auBufBytes=	0;   /*  buffer size to use for playback.
					 unfortunately, this bears no relationship to
					 whatever the kernel and soundcard are using  */
static int auBuffersPlayed=	0;
static struct sigaction action, oldAction;

/* The Solaris STREAMS audio driver sends a SIGIO
 * each time it reads the EOF sent by sound_PlaySamplesFromAtLength */
static void auHandle(int sig)
{
  PRINTF(("(sig=%d)", sig));
  if (auFd < 0) return;

  /* Not all SIGIOs are for us */
  if (sound_AvailableSpace() > 0)
    {
      PRINTF(("Signalling semaphore %d", auPlaySemaIndex));
      signalSemaphoreWithIndex(auPlaySemaIndex);
    }
}


/*** exported sound output functions ***/


static sqInt sound_Stop(void)
{
  PRINTF();
  if (auFd == -1) return 0;

  ioctl(auCtlFd, I_SETSIG, 0);

  /* clear any queued sound for immediate silence */
  ioctl(auFd, I_FLUSH, FLUSHW);

  sigaction(SIGIO, &oldAction, NULL);

  close(auFd);    auFd= -1;
  close(auCtlFd); auCtlFd= -1;

  return 0;
}


static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  PRINTF(("(frameCount=%d, samplesPerSec=%d, stereo=%d, semaIndex=%d)",
		frameCount, samplesPerSec, stereo, semaIndex));
  int bytesPerFrame= (stereo ? 4 : 2);
  struct audio_info info;
  int err;

  if (auFd != -1) sound_Stop();
  auPlaySemaIndex= semaIndex;
  fmtStereo= stereo;
  auBufBytes= bytesPerFrame * frameCount;

  if ((auFd= open("/dev/audio", O_WRONLY|O_NONBLOCK)) == -1)
    {
      perror("/dev/audio");
      return false;
    }
  PRINTF(("auFd=%d", auFd));

  if ((auCtlFd= open("/dev/audioctl", O_WRONLY|O_NONBLOCK)) == -1)
    {
      perror("/dev/audioctl");
      return false;
    }
  PRINTF(("auCtlFd=%d", auCtlFd));

  /* set up device */
  if (ioctl(auFd, AUDIO_GETINFO, &info))
    {
      perror("AUDIO_GETINFO");
      goto closeAndFail;
    }
  info.play.gain= 255;
  info.play.precision= 16;
  info.play.encoding= AUDIO_ENCODING_LINEAR;
  info.play.channels= fmtStereo ? 2 : 1;
  info.play.sample_rate= samplesPerSec;

  auBuffersPlayed= info.play.eof;

  while ((err= ioctl(auFd, AUDIO_SETINFO, &info)) && errno == EINTR)
    ;
  if (err)
    {
      perror("AUDIO_SETINFO");
      goto closeAndFail;
    }

  action.sa_handler= auHandle;
  sigemptyset(&action.sa_mask);
  action.sa_flags= 0;
  action.sa_flags|= SA_RESTART;

  if (sigaction(SIGIO, &action, &oldAction) < 0) /* On Solaris, SIGIO == SIGPOLL */
    {
      perror("sigaction(SIGIO, auHandle)");
    }
  if (ioctl(auCtlFd, I_SETSIG, S_MSG))	/* send SIGIO whenever EOF arrives */
    {
      perror("ioctl(auFd, I_SETSIG, S_MSG)");
    }

  return true;

closeAndFail:
  close(auFd);    auFd= -1;
  close(auCtlFd); auCtlFd= -1;
  return false;
}


static sqInt sound_AvailableSpace(void)
{
  PRINTF();
  struct audio_info info;
  int avail;

  if (auFd < 0) return 0;

  if (ioctl(auFd, AUDIO_GETINFO, &info))
    {
      perror("AUDIO_GETINFO");
      sound_Stop();
    }

  avail= auBufBytes * (info.play.eof - auBuffersPlayed + 2);
  PRINTF(("auBufBytes=%d, info.play.eof=%d, auBuffersPlayed=%d, avail=%d",
		auBufBytes, info.play.eof, auBuffersPlayed, avail));

  return avail;
}


static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex)
{
  PRINTF(("(frameCount=%d, arrayIndex=%d, startIndex=%d)",
		frameCount, arrayIndex, startIndex));
  short *src= (short *) (srcBufPtr + 4*startIndex);
  short buf[2*frameCount];
  int i;
  int bytes;
  PRINTF(("src=%p", src));

  if (auFd < 0) return -1;

  if (fmtStereo)
    {
      bytes= 4 * frameCount;
      for (i= 0;  i < 2 * frameCount;  i++)
	buf[i]= src[i];
    }
  else
    {
      bytes= 2 * frameCount;
      for (i= 0;  i < frameCount;  i++)
	buf[i]= src[2*i];
    }
  /* write data to device from auBuf to dst */
  while (bytes > 0)
    {
      int len;
      char *pos= (char *) buf;

      len= write(auFd, pos, bytes);
      if (len < 0)
	{
	  perror("/dev/audio");
	  return 0;
	}
      bytes -= len;
      pos += len;
    }
  /* add an EOF marker */
  write(auFd, buf, 0);
  auBuffersPlayed += 1;

  return frameCount;
}


static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime)
{
  PRINTF(("(frameCount=%d, srcBufPtr=%d, samplesOfLeadTime=%d)",
		frameCount, srcBufPtr, samplesOfLeadTime));
  return 0;
}


static sqInt sound_PlaySilence(void)
{
  PRINTF();
  success(false);
  return 0;
}


/** recording not supported **/
static sqInt sound_SetRecordLevel(sqInt level)
{
  PRINTF();
  success(false);
  return 0;
}


static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  PRINTF();
  success(false);
  return 0;
}


static sqInt sound_StopRecording(void)
{
  PRINTF();
  return 0;
}


static double sound_GetRecordingSampleRate(void)
{
  PRINTF();
  success(false);
  return 0.0;
}


static sqInt sound_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  PRINTF();
  success(false);
  return 0;
}



static void sound_Volume(double *left, double *right)
{
  PRINTF();
  success(false);
  return;
}


static void sound_SetVolume(double left, double right)
{
  PRINTF();
  success(false);
  return;
}

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)
{
  return -1;
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)
{
  return -1;
}

static sqInt sound_SetDevice(sqInt id, char *arg)
{
  return -1;
}

#include "SqSound.h"

SqSoundDefine(Sun);


#include "SqModule.h"

static void  sound_parseEnvironment(void) { PRINTF(); }
static int   sound_parseArgument(int argc, char **argv) { PRINTF(("(argc=%d)", argc)); return 0; }
static void  sound_printUsage(void) { PRINTF(); }
static void  sound_printUsageNotes(void) { PRINTF(); }
static void *sound_makeInterface(void) { PRINTF(); return &sound_Sun_itf; }

SqModuleDefine(sound, Sun);

