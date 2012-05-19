/* sqUnixSoundSun.c -- sound support for SunOS and Solaris
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
 *
 * Authors: Ian.Piumarta@inria.fr and Lex Spoon <lex@cc.gatech.edu>
 * 
 * This support is rudimentary and is implemented largely by reading
 * header files and guessing what to do.
 */

#include "sq.h"

#undef	DEBUG

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

#ifdef DEBUG
# define PRINTF(ARGS) printf ARGS
# define TRACE 1
#elsen
# define PRINTF(ARGS)
#endif

static int sound_Stop(void);
static int sound_AvailableSpace(void);

static int auFd=	       -1;   /* open on /dev/dsp */
static int fmtStereo=		0;   /* whether we are playing in stereo or not */
static int auPlaySemaIndex=	0;   /* an index to signal when new data may be played */
static int auBufBytes=		0;   /*  buffer size to use for playback.
					 unfortunately, this bears no relationship to
					 whatever the kernel and soundcard are using  */
static int auBuffersPlayed=	0;


static void auHandle(int fd, void *data, int flags)
{
  if (auFd < 0) return;
  if (sound_AvailableSpace() > 0)
    signalSemaphoreWithIndex(auPlaySemaIndex);
  aioHandle(fd, auHandle, flags);
}


/*** exported sound output functions ***/


static int sound_Stop(void)
{
  if (auFd == -1) return;

  aioDisable(auFd);
  close(auFd);
  auFd= -1;

  return 0;
}


static int sound_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
  int bytesPerFrame=	(stereo ? 4 : 2);
  int bufferBytes=	((frameCount * bytesPerFrame) / 8) * 8;
  struct audio_info info;
  int err;
     
  if (auFd != -1) sound_Stop();
  auPlaySemaIndex= semaIndex;
  fmtStereo= stereo;
  auBufBytes= bytesPerFrame * frameCount;

  if ((auFd= open("/dev/audio", O_WRONLY)) == -1)
    {
      perror("/dev/audio");
      return false;
    }
  /* set up device */
  if (ioctl(auFd, AUDIO_GETINFO, &info))
    {
      perror("AUDIO_GETINFO");
      goto closeAndFail;
    }
  info.play.gain= 100;
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
  aioEnable(auFd, 0, 0);
  aioHandle(auFd, auHandle, AIO_RX);
  return true;
  
 closeAndFail:
  close(auFd);
  auFd= -1;
  return false;
}


static int sound_AvailableSpace(void)
{
  struct audio_info info;

  if (auFd < 0) return 0;

  if (ioctl(auFd, AUDIO_GETINFO, &info))
    {
      perror("AUDIO_GETINFO");
      sound_Stop();
    }
  return (auBufBytes * (info.play.eof - auBuffersPlayed + 2));
}


static int sound_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  short *src= (short *) (arrayIndex + 4*startIndex);
  short buf[2*frameCount];
  int i;
  int bytes;

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
  /* add an eof marker */
  write(auFd, buf, 0);
  auBuffersPlayed += 1;
  
  return frameCount;
}


static int sound_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int samplesOfLeadTime)
{
  return 0;
}


static int sound_PlaySilence(void)
{
     return 0;
}


/** recording not supported **/
static int sound_SetRecordLevel(int level)
{
  success(false);
  return;
}


static int sound_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
{
  success(false);
  return;
}


static int sound_StopRecording(void)
{
  return;
}


static double sound_GetRecordingSampleRate(void)
{
  success(false);
  return 0.0;
}


static int sound_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes)
{
  success(false);
  return 0;
}



static void sound_Volume(double *left, double *right)
{
  success(false);
  return;
}


static void sound_SetVolume(double left, double right)
{
  success(false);
  return;
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)
{
  return -1;
}

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)
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

static void  sound_parseEnvironment(void) {}
static int   sound_parseArgument(int argc, char **argv) { return 0; }
static void  sound_printUsage(void) {}
static void  sound_printUsageNotes(void) {}
static void *sound_makeInterface(void) { return &sound_Sun_itf; }

SqModuleDefine(sound, Sun);
