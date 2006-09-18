/* sqUnixSoundALSA.c -- cheap and cheerful sound for Advanced Linux Sound Architecture
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2006-09-17 02:18:19 by piumarta on ubuntu
 *
 *   Copyright (C) 2006 by Ian Piumarta
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
#include <alsa/asoundlib.h>

#define SQ_SND_RESAMPLE			1

#define FAIL(X) { fprintf(stderr, "FAIL: %s:%d: %s\n", __FILE__, __LINE__, __PRETTY_FUNCTION__);  exit(1);  return X; }

#define snd(expr, what)						\
  if ((err= snd_##expr) < 0)					\
    {								\
      fprintf(stderr, "%s: %s\n", what, snd_strerror(err));	\
      success(false);						\
      return 0;							\
    }

extern inline int min(int x, int y) { return (x < y) ? x : y; }

/* output */

#define SQ_SND_PLAY_START_THRESHOLD	7/8
#define SQ_SND_PLAY_AVAIL_MIN		4/8

static snd_pcm_t		*output_handle= 0;
static snd_async_handler_t	*output_handler= 0;
static int			 output_semaphore= 0;
static int			 output_channels= 0;
static int			 output_buffer_frames_size= 0;
static int			 output_buffer_frames_available= 0;

static void output_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(output_semaphore);
  //fprintf(stderr, "-");  fflush(stderr);
  output_buffer_frames_available= 1;
}

static sqInt sound_Stop(void)
{
  if (output_handle)
    {
      snd_pcm_close(output_handle);
      output_handle= 0;
    }
  return 0;
}

static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  snd_pcm_uframes_t	 frames;
  unsigned int		 uval;
  int			 dir;

  fprintf(stderr, "sound_Start: %i %i %i %i\n", frameCount, samplesPerSec, stereo, semaIndex);

  if (output_handle) sound_Stop();

  output_semaphore= semaIndex;
  output_channels= stereo ? 2 : 1;
  snd(pcm_open(&output_handle, "default", SND_PCM_STREAM_PLAYBACK, 0), "startSound: snd_pcm_open");

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(output_handle, hwparams);
  snd_pcm_hw_params_set_access(output_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(output_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(output_handle, hwparams, output_channels);
  uval= samplesPerSec;
  snd_pcm_hw_params_set_rate_near(output_handle, hwparams, &uval, &dir);
  frames= frameCount;
  snd_pcm_hw_params_set_period_size_near(output_handle, hwparams, &frames, &dir);
  snd(pcm_hw_params(output_handle, hwparams), "sound_Start: snd_pcm_hw_params");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(output_handle, swparams), "sound_Start: snd_pcm_sw_params_current");
  snd(pcm_sw_params_set_start_threshold(output_handle, swparams, frameCount * SQ_SND_PLAY_START_THRESHOLD), "sound_Start: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(output_handle, swparams, frameCount * SQ_SND_PLAY_AVAIL_MIN), "sound_Start: snd_pcm_sw_parama_set_avail_min");
  snd(pcm_sw_params_set_xfer_align(output_handle, swparams, 1), "sound_Start: snd_pcm_sw_params_set_xfer_align");
  snd(pcm_sw_params(output_handle, swparams), "sound_Start: snd_pcm_sw_params");

  output_buffer_frames_size= frameCount;
  output_buffer_frames_available= 1;

  snd(pcm_nonblock(output_handle, 1), "sound_Start: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&output_handler, output_handle, output_callback, 0), "soundStart: snd_add_pcm_handler");
  snd(pcm_start(output_handle), "soundStart: snd_pcm_start");

  fprintf(stderr, "ok\n");

  return 1;
}

static sqInt  sound_AvailableSpace(void)
{
  return snd_pcm_avail_update(output_handle);
}

static sqInt  sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)	FAIL(frameCount)

static sqInt  sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)
{
  void *samples= (void *)arrayIndex + startIndex * output_channels * 2;
  int   count=   snd_pcm_writei(output_handle, samples, frameCount);
  //fprintf(stderr, "+");  fflush(stderr);
  if (count < frameCount / 2)
    {
      output_buffer_frames_available= 0;
      //fprintf(stderr, "!");  fflush(stderr);
    }
  if (count < 0)
    {
      if (count == -EPIPE)    /* underrun */
	{
	  int err;
	  snd(pcm_prepare(output_handle), "sound_PlaySamples: snd_pcm_prepare");
	  return 0;
	}
      fprintf(stderr, "snd_pcm_writei returned %i\n", count);
      return 0;
    }
  return count;
}

static sqInt  sound_PlaySilence(void)										FAIL(8192)

/* input */

#define SQ_SND_REC_START_THRESHOLD	4/8
#define SQ_SND_REC_AVAIL_MIN		4/8

static snd_pcm_t		*input_handle= 0;
static snd_async_handler_t	*input_handler= 0;
static int			 input_semaphore= 0;
static int			 input_channels= 0;
static unsigned int		 input_rate= 0;

static void input_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(input_semaphore);
  fprintf(stderr, "+");  fflush(stderr);
}

static sqInt sound_StopRecording(void)
{
  if (input_handle)
    {
      snd_pcm_close(input_handle);
      input_handle= 0;
    }
  return 0;
}

static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  snd_pcm_uframes_t	 frames;
  unsigned int		 uval;
  int			 dir;

  fprintf(stderr, "sound_StartRecording: %i %i %i %i\n", desiredSamplesPerSec, stereo, semaIndex);

  if (input_handle) sound_StopRecording();

  input_semaphore= semaIndex;
  input_channels= stereo ? 2 : 1;
  snd(pcm_open(&input_handle, "default", SND_PCM_STREAM_CAPTURE, 0), "start_SoundRecording: snd_pcm_open");

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(input_handle, hwparams);
  snd_pcm_hw_params_set_access(input_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(input_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(input_handle, hwparams, input_channels);
  input_rate= desiredSamplesPerSec;
  snd_pcm_hw_params_set_rate_near(input_handle, hwparams, &input_rate, &dir);
  frames= 4096;
  snd_pcm_hw_params_set_period_size_near(input_handle, hwparams, &frames, &dir);
  snd(pcm_hw_params(input_handle, hwparams), "sound_StartRecording: snd_pcm_hw_params");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(input_handle, swparams), "sound_StartRecording: snd_pcm_sw_params_current");
  snd(pcm_sw_params_set_start_threshold(input_handle, swparams, frames * SQ_SND_REC_START_THRESHOLD), "sound_StartRecording: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(input_handle, swparams, frames * SQ_SND_REC_AVAIL_MIN), "sound_StartRecording: snd_pcm_sw_parama_set_avail_min");
  snd(pcm_sw_params_set_xfer_align(input_handle, swparams, 1), "sound_StartRecording: snd_pcm_sw_params_set_xfer_align");
  snd(pcm_sw_params(input_handle, swparams), "sound_StartRecording: snd_pcm_sw_params");

  snd(pcm_nonblock(input_handle, 1), "sound_StartRecording: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&input_handler, input_handle, input_callback, 0), "sound_StartRecording: snd_add_pcm_handler");
  snd(pcm_start(input_handle), "sound_StartRecording: snd_pcm_start");

  fprintf(stderr, "ok\n");

}

static double sound_GetRecordingSampleRate(void)
{
  return (double)input_rate;
}

static sqInt sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  void *samples=    (void *)buf + (startSliceIndex * 2);
  int   frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / input_channels;
  int   count=      snd_pcm_readi(input_handle, samples, frameCount);
  if (count < 0)
    {    
      if (count == -EPIPE)
	snd_pcm_prepare(input_handle);
      else if (count != -EAGAIN)
	fprintf(stderr, "snd_pcm_readi returned %i\n", count);
      return 0;
    }
  return count * input_channels;
}

/* mixer */

static void   sound_Volume(double *left, double *right)								{ return; }

static void   sound_SetVolume(double left, double right)							{ return; }

static sqInt  sound_SetRecordLevel(sqInt level)									{ return level; }

#include "SqSound.h"

SqSoundDefine(ALSA);

#include "SqModule.h"

static void sound_parseEnvironment(void) {}

static int  sound_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nosound")) return 1;
  return 0;
}

static void  sound_printUsage(void) {}
static void  sound_printUsageNotes(void) {}
static void *sound_makeInterface(void) { return &sound_ALSA_itf; }

SqModuleDefine(sound, ALSA);
