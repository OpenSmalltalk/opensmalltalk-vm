/* sqUnixSound.c -- sound support for various Unix sound systems
 *
 * Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2003-08-14 01:34:52 by piumarta on emilia.inria.fr
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 *
 * NOTE: The real sound support code is in one of the following files according
 *	 to the output driver selected by `configure':
 * 
 *	   sqUnixSoundOSS.c	(Open Sound System [incl. Linux native & ALSA compat])
 *	   sqUnixSoundNAS.c	(Network Audio System)
 *	   sqUnixSoundSun.c	(SunOS/Solaris)
 *	   sqUnixSoundMacOSX.c	(Mac OS 10 CoreAudio)
 *	   sqUnixSoundNull.c	(sound disabled)
 */

#include "sq.h"
#include "SoundPlugin.h"
#include "SqModule.h"
#include "SqSound.h"

extern int snd_Stop(void);

/*** module initialisation/shutdown ***/

extern struct SqModule *soundModule;
extern struct SqModule *loadModule(char *type, char *name);

static struct SqSound *snd= 0;

int soundInit(void)
{
  if (!soundModule
#    if 0
      && !(soundModule= getenv("SQUEAK_SOUND_OSS")    ? loadModule("sound", "OSS")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_NAS")    ? loadModule("sound", "NAS")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_SUN")    ? loadModule("sound", "Sun")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_MACOSX") ? loadModule("sound", "MacOSX") : 0)
      && !(soundModule= getenv("AUDIOSERVER")         ? loadModule("sound", "NAS")    : 0)
      && !(soundModule= loadModule("sound", "OSS"))
      && !(soundModule= loadModule("sound", "Sun"))
      && !(soundModule= loadModule("sound", "MacOSX"))
      && !(soundModule= loadModule("sound", "null"))
#    endif
      )
    {
      fprintf(stderr, "could not find any sound module\n");
      abort();
    }
  //printf("soundModule   %p %s\n", soundModule, soundModule->name);
  snd= (struct SqSound *)soundModule->makeInterface();
  if (SqSoundVersion != snd->version)
    {
      fprintf(stderr, "module %s interface version %x does not have required version %x\n",
	      soundModule->name, snd->version, SqSoundVersion);
      abort();
    }
  return 1;
}


int soundShutdown(void)
{
  if (snd) snd->snd_Stop();
  return 1;
}


/* output */

int snd_AvailableSpace(void)
{
  return snd->snd_AvailableSpace();
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime)
{
  return snd->snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
}

int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  return snd->snd_PlaySamplesFromAtLength(frameCount, arrayIndex, startIndex);
}

int snd_PlaySilence(void)
{
  return snd->snd_PlaySilence();
}

int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
  return snd->snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
}

int snd_Stop(void)
{
  return snd->snd_Stop();
}

/* input */

int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex)
{
  return snd->snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex);
}

int snd_StopRecording(void)
{
  return snd->snd_StopRecording();
}

double snd_GetRecordingSampleRate(void)
{
  return snd->snd_GetRecordingSampleRate();
}

int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes)
{
  return snd->snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
}

/* mixer */

void snd_Volume(double *left, double *right)	{ snd->snd_Volume(left, right); }
void snd_SetVolume(double left, double right)	{ snd->snd_SetVolume(left, right); }
int  snd_SetRecordLevel(int level)		{ return snd->snd_SetRecordLevel(level); }
