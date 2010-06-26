/* sqUnixSoundNull.c -- sound module for no sound
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2008-04-21 14:51:23 by piumarta on emilia
 *
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
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
 */

#include "sq.h"
#include "SqSound.h"


#define FAIL(X) { success(false); return X; }

/* output */
static sqInt  sound_AvailableSpace(void)									FAIL(8192)
static sqInt  sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)	FAIL(frameCount)
static sqInt  sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)		FAIL(8192)
static sqInt  sound_PlaySilence(void)										FAIL(8192)
static sqInt  sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)			FAIL(1)
static sqInt  sound_Stop(void)											FAIL(0)
/* input */
static sqInt  sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)			FAIL(0)
static sqInt  sound_StopRecording(void)										FAIL(0)
static double sound_GetRecordingSampleRate(void)								FAIL(0)
static sqInt  sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)	FAIL(0)
/* mixer */
static void   sound_Volume(double *left, double *right)								{ return; }
static void   sound_SetVolume(double left, double right)							{ return; }
static sqInt  sound_SetRecordLevel(sqInt level)									{ return level; }

static sqInt  sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)					FAIL(-1)
static sqInt  sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)					FAIL(-1)
static sqInt  sound_SetDevice(sqInt id, char *arg)								FAIL(-1)


/* eem Feb 7 2010 after hrs' SoundRecorder extras. */
static sqInt sound_GetRecordLevel(void) { return 0; }

static int sound_GetNumberOfSoundPlayerDevices(void) { return 0; }

static int sound_GetNumberOfSoundRecorderDevices(void) { return 0; }

static char* sound_GetDefaultSoundPlayer(void) { return 0; }

static char* sound_GetDefaultSoundRecorder(void) { return 0; }

static char* sound_GetSoundPlayerDeviceName(int n) { return 0; }

static char* sound_GetSoundRecorderDeviceName(int n) { return 0; }

static void sound_SetDefaultSoundPlayer(char *deviceName) {}

static void sound_SetDefaultSoundRecorder(char *deviceName) {}

#if SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3
/* Acoustic echo-cancellation (AEC) is not supported on Linux yet. */
int sound_SupportsAEC(void)                 { return 0; }

/* Acoustic echo-cancellation (AEC) is not supported on Linux yet. */
int sound_EnableAEC(int trueOrFalse)
{
	if (trueOrFalse) return PrimErrUnsupported;
	else return 0; /* success */
}
#endif /* SqSoundVersionMajor > 1 || SqSoundVersionMinor >= 3 */


SqSoundDefine(null);

#include "SqModule.h"

static void sound_parseEnvironment(void) {}

static int  sound_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nosound")) return 1;
  return 0;
}

static void  sound_printUsage(void) {}
static void  sound_printUsageNotes(void) {}
static void *sound_makeInterface(void) { return &sound_null_itf; }

SqModuleDefine(sound, null);
