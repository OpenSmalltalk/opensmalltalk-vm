/* sqUnixSoundNone.c -- stubs for dummy (unimplemented) sound support
 *
 * Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2002-10-26 14:40:54 by piumarta on emilia.inria.fr
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
 */

#include "sq.h"

#ifdef USE_AUDIO_NONE

#include "SoundPlugin.h"

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


#endif /* USE_AUDIO_NONE */
