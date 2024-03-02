/* sqUnixSound.c -- sound support for various Unix sound systems
 *
 * Provide functions that redirect sound calls to specific sound systems.
 *
 * Author: Ian.Piumarta@inria.fr
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

extern sqInt snd_Stop(void);

/*** module initialisation/shutdown ***/

extern struct SqModule *soundModule;
extern struct SqModule *loadModule(char *type, char *name);

static struct SqSound *snd= 0;

sqInt
soundInit(void)
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


sqInt
soundShutdown(void)
{
  if (snd) snd->snd_Stop();
  return 1;
}


/* output */

sqInt
snd_AvailableSpace(void) { return snd->snd_AvailableSpace(); }

sqInt
snd_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime)
{ return snd->snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime); }

sqInt
snd_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex)
{ return snd->snd_PlaySamplesFromAtLength(frameCount, srcBufPtr, startIndex); }

sqInt
snd_PlaySilence(void) { return snd->snd_PlaySilence(); }

sqInt
snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{ return snd->snd_Start(frameCount, samplesPerSec, stereo, semaIndex); }

sqInt
snd_Stop(void) { return snd->snd_Stop(); }

/* input */

sqInt
snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{ return snd->snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex); }

sqInt
snd_StopRecording(void)
{ return snd->snd_StopRecording(); }

double
snd_GetRecordingSampleRate(void)
{ return snd->snd_GetRecordingSampleRate(); }

sqInt
snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{ return snd->snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes); }

/* mixer */

void
snd_Volume(double *left, double *right)  { snd->snd_Volume(left, right); }

void
snd_SetVolume(double left, double right) { snd->snd_SetVolume(left, right); }

void
snd_SetRecordLevel(sqInt level)          { snd->snd_SetRecordLevel(level); }

sqInt
snd_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)   { return snd->snd_GetSwitch(id, captureFlag, channel); }

sqInt
snd_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter) { return snd->snd_SetSwitch(id, captureFlag, parameter); }

sqInt
snd_SetDevice(sqInt id, char *name)      { return snd->snd_SetDevice(id, name); }

/* Terf SqSoundVersion 1.2 improvements */

#if SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 2
sqInt
snd_SetRecordBufferFrameCount(sqInt frameCount) { return snd->snd_SetRecordBufferFrameCount(frameCount); }

int
snd_GetRecordLevel(void)                   { return snd->snd_GetRecordLevel(); }

sqInt
getNumberOfSoundPlayerDevices(void)        { return snd->snd_GetNumberOfSoundPlayerDevices(); }

sqInt
getNumberOfSoundRecorderDevices(void)      { return snd->snd_GetNumberOfSoundRecorderDevices(); }

char *
getDefaultSoundPlayer(void)       { return snd->snd_GetDefaultSoundPlayer(); }

char *
getDefaultSoundRecorder(void)     { return snd->snd_GetDefaultSoundRecorder(); }

char *
getSoundPlayerDeviceName(sqInt i)   { return snd->snd_GetSoundPlayerDeviceName(i); }

char *
getSoundRecorderDeviceName(sqInt i) { return snd->snd_GetSoundRecorderDeviceName(i); }

void
setDefaultSoundPlayer(char *deviceName)   { snd->snd_SetDefaultSoundPlayer(deviceName); }

void
setDefaultSoundRecorder(char *deviceName) { snd->snd_SetDefaultSoundRecorder(deviceName); }

#else
sqInt snd_SetRecordBufferFrameCount(sqInt frameCount) { return -1; }
int   snd_GetRecordLevel(void)                      { return -1; }
sqInt getNumberOfSoundPlayerDevices(void)           { return -1; }
sqInt getNumberOfSoundRecorderDevices(void)         { return -1; }
char *getDefaultSoundPlayer(void)                   { return NULL; }
char *getDefaultSoundRecorder(void)                 { return NULL; }
char *getSoundPlayerDeviceName(sqInt i)             { return NULL; }
char *getSoundRecorderDeviceName(sqInt i)           { return NULL; }
void  setDefaultSoundPlayer(char *deviceName)       { return ; }
void  setDefaultSoundRecorder(char *deviceName)     { return ; }
#endif /* SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 2 */

#if SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3
sqInt
snd_SupportsAEC(void)                 { return snd->snd_SupportsAEC(); }

sqInt
snd_EnableAEC(sqInt flag)             { return snd->snd_EnableAEC(flag); }

char *
getSoundPlayerDeviceUID(sqInt i)   { return 0; /* for now */ }

char *
getSoundRecorderDeviceUID(sqInt i) { return 0; /* for now */ }

#else
sqInt snd_SupportsAEC(void)           { return 0; }
sqInt snd_EnableAEC(sqInt flag)       { return -1; }
#endif /* SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3 */
