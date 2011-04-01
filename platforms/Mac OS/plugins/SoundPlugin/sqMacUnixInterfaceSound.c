/*
 *  sqMacUnixInterfaceSound.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 2/3/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */


#include "sq.h"
#include "sqMacUnixInterfaceSound.h"
#include "SoundPlugin.h"
#include "SqModule.h"
#include "SqSound.h"

extern sqInt sound_Stop(void);

sqInt soundInit(void)
{
  return 1;
}


sqInt soundShutdown(void)
{
  sound_StopRecording();
  return 1;
}


/* output */

sqInt snd_AvailableSpace(void)
{
  return sound_AvailableSpace();
}

sqInt snd_InsertSamplesFromLeadTime(sqInt frameCount, void* srcBufPtr, sqInt samplesOfLeadTime)
{
  return sound_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
}

sqInt snd_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex)
{
  return sound_PlaySamplesFromAtLength(frameCount, srcBufPtr, startIndex);
}

sqInt snd_PlaySilence(void)
{
  return sound_PlaySilence();
}

sqInt snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  return sound_Start(frameCount, samplesPerSec, stereo, semaIndex);
}

sqInt snd_Stop(void)
{
  return sound_Stop();
}

/* input */

sqInt snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  return sound_StartRecording(desiredSamplesPerSec, stereo, semaIndex);
}

sqInt snd_StopRecording(void)
{
  return sound_StopRecording();
}

double snd_GetRecordingSampleRate(void)
{
  return sound_GetRecordingSampleRate();
}

sqInt snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  return sound_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
}

/* mixer */

void snd_Volume(double *left, double *right)	{ 
	sound_Volume(left, right); }
void snd_SetVolume(double left, double right)	{ 
	sound_SetVolume(left, right); }
void  snd_SetRecordLevel(sqInt level)		{ 
	 sound_SetRecordLevel(level); }