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
      && !(soundModule= getenv("SQUEAK_SOUND_ALSA")   ? loadModule("sound", "ALSA")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_OSS")    ? loadModule("sound", "OSS")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_NAS")    ? loadModule("sound", "NAS")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_SUN")    ? loadModule("sound", "Sun")    : 0)
      && !(soundModule= getenv("SQUEAK_SOUND_MACOSX") ? loadModule("sound", "MacOSX") : 0)
      && !(soundModule= getenv("AUDIOSERVER")         ? loadModule("sound", "NAS")    : 0)
      && !(soundModule= loadModule("sound", "ALSA"))
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

int snd_InsertSamplesFromLeadTime(int frameCount, void *srcBufPtr, int samplesOfLeadTime)
{
  return snd->snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
}

int snd_PlaySamplesFromAtLength(int frameCount, void *srcBufPtr, int startIndex)
{
  return snd->snd_PlaySamplesFromAtLength(frameCount, srcBufPtr, startIndex);
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

int snd_RecordSamplesIntoAtLength(void *buf, int startSliceIndex, int bufferSizeInBytes)
{
  return snd->snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
}

/* mixer */

void snd_Volume(double *left, double *right)			{	 snd->snd_Volume(left, right); }
void snd_SetVolume(double left, double right)			{	 snd->snd_SetVolume(left, right); }
void  snd_SetRecordLevel(int level)				{ snd->snd_SetRecordLevel(level); }
int  snd_GetSwitch(int id, int captureFlag, int channel)	{ return snd->snd_GetSwitch(id, captureFlag, channel); }
int  snd_SetSwitch(int id, int captureFlag, int parameter)	{ return snd->snd_SetSwitch(id, captureFlag, parameter); }
int  snd_SetDevice(int id, char *name)				{ return snd->snd_SetDevice(id, name); }


#if SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 2
int snd_SetRecordBufferFrameCount(int frameCount) { return 0; }

/* unimplemented stubs */
int snd_GetRecordLevel(void)                   { return snd->snd_GetRecordLevel(); }
int getNumberOfSoundPlayerDevices(void)        { return snd->snd_GetNumberOfSoundPlayerDevices(); }
int getNumberOfSoundRecorderDevices(void)      { return snd->snd_GetNumberOfSoundRecorderDevices(); }
char* getDefaultSoundPlayer(void)       { return snd->snd_GetDefaultSoundPlayer(); }
char* getDefaultSoundRecorder(void)     { return snd->snd_GetDefaultSoundRecorder(); }
char* getSoundPlayerDeviceName(int i)   { return snd->snd_GetSoundPlayerDeviceName(i); }
char* getSoundRecorderDeviceName(int i) { return snd->snd_GetSoundRecorderDeviceName(i); }
void setDefaultSoundPlayer(char *deviceName)   { snd->snd_SetDefaultSoundPlayer(deviceName); }
void setDefaultSoundRecorder(char *deviceName) { snd->snd_SetDefaultSoundRecorder(deviceName); }
#endif /* SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 2 */

#if SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3
int snd_SupportsAEC(void)                 { return snd->snd_SupportsAEC(); }
int snd_EnableAEC(int flag)               { return snd->snd_EnableAEC(flag); }
#endif /* SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3 */
