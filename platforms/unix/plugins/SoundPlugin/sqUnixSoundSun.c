/* sqUnixSoundSun.c -- sound support for SunOS and Solaris
 *
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
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
 *   2. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 *   You are not allowed to distribute a modified version of this file
 *   under its original name without explicit permission to do so.  If
 *   you change it, rename it.
 *
 * Authors: Ian.Piumarta@inria.fr and Lex Spoon <lex@cc.gatech.edu>
 * 
 * This support is rudimentary and is implemented largely by reading
 * header files and guessing what to do.
 */

#include "sq.h"

#ifdef USE_AUDIO_SUN

#undef	DEBUG

#include "SoundPlugin.h"
#include "aio.h"

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

int snd_Stop(void);

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
  if (snd_AvailableSpace() > 0)
    signalSemaphoreWithIndex(auPlaySemaIndex);
  aioHandle(fd, auHandle, flags);
}


/*** exported sound output functions ***/


int snd_Stop(void)
{
  if (auFd == -1) return;

  aioDisable(auFd);
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
     
  if (auFd != -1) snd_Stop();
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


int snd_AvailableSpace(void)
{
  struct audio_info info;

  if (auFd < 0) return 0;

  if (ioctl(auFd, AUDIO_GETINFO, &info))
    {
      perror("AUDIO_GETINFO");
      snd_Stop();
    }
  return (auBufBytes * (info.play.eof - auBuffersPlayed + 2));
}


int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
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


#endif /* USE_AUDIO_SUN */
