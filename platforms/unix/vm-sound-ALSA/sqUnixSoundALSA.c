/* sqUnixSoundALSA.c -- cheap and cheerful sound for Advanced Linux Sound Architecture
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2013-04-04 13:59:35 by piumarta on linux32
 *
 *   Copyright (C) 2006 by Ian Piumarta
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
 */

#include "sq.h"
#include <alsa/asoundlib.h>
#include <errno.h>
#include <signal.h>


#define DEVICE_NAME_LEN 128

static char sound_device[DEVICE_NAME_LEN];	/* = "default"; */
static char sound_playback[DEVICE_NAME_LEN];	/* = "Master"; */
static char sound_capture[DEVICE_NAME_LEN];	/* = "Capture"; */


#define FAIL(X)		\
{			\
  success(false);	\
  return X;		\
}

#define snd(expr, what)						\
  if ((err= snd_##expr) < 0)					\
    {								\
      fprintf(stderr, "%s: %s\n", what, snd_strerror(err));	\
      success(false);						\
      return err;						\
    }

#define MIN(X, Y)	((X) < (Y) ? (X) : (Y))
#define MAX(X, Y)	((X) > (Y) ? (X) : (Y))

static void sigio_save(void);
static void sigio_restore(void);


/* output */


#if 0
#define SQ_SND_PLAY_START_THRESHOLD	7/8
#define SQ_SND_PLAY_AVAIL_MIN		4/8
#endif

static snd_pcm_t		*output_handle= 0;
static snd_async_handler_t	*output_handler= 0;
static int			 output_semaphore= 0;
static int			 output_channels= 0;
static int			 output_buffer_frames_available= 0;
static snd_pcm_uframes_t	 output_buffer_period_size= 0;
static snd_pcm_uframes_t	 output_buffer_size= 0;
static double			 max_delay_frames= 0;

static void output_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(output_semaphore);
  output_buffer_frames_available= 1;
}

static sqInt sound_Stop(void)
{
  if (output_handle)
    {
      snd_pcm_close(output_handle);
      output_handle= 0;
      sigio_restore();
    }
  return 0;
}

static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  snd_pcm_uframes_t	 period_size;
  unsigned int		 uval;

  if (output_handle) sound_Stop();

  output_semaphore= semaIndex;
  output_channels= stereo ? 2 : 1;
  snd(pcm_open(&output_handle, sound_device, SND_PCM_STREAM_PLAYBACK, 0), "startSound: snd_pcm_open");

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(output_handle, hwparams);
  snd_pcm_hw_params_set_access(output_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(output_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(output_handle, hwparams, output_channels);
  uval= samplesPerSec;
  snd_pcm_hw_params_set_rate_near(output_handle, hwparams, &uval, 0);
  output_buffer_period_size= frameCount;
  snd_pcm_hw_params_set_period_size_near(output_handle, hwparams, &output_buffer_period_size, 0);
  snd(pcm_hw_params(output_handle, hwparams), "sound_Start: snd_pcm_hw_params");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(output_handle, swparams), "sound_Start: snd_pcm_sw_params_current");
#if 0
  snd(pcm_sw_params_set_start_threshold(output_handle, swparams, frameCount * SQ_SND_PLAY_START_THRESHOLD), "sound_Start: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(output_handle, swparams, frameCount * SQ_SND_PLAY_AVAIL_MIN), "sound_Start: snd_pcm_sw_parama_set_avail_min");
#endif
  snd(pcm_sw_params_set_xfer_align(output_handle, swparams, 1), "sound_Start: snd_pcm_sw_params_set_xfer_align");
  snd(pcm_sw_params(output_handle, swparams), "sound_Start: snd_pcm_sw_params");

  snd(pcm_hw_params_get_period_size(hwparams, &period_size, 0), "sound_Start: pcm_hw_params_get_period_size");
  snd(pcm_hw_params_get_buffer_size(hwparams, &output_buffer_size), "sound_Start: pcm_hw_params_get_buffer_size");
  snd(pcm_sw_params_set_avail_min(output_handle, swparams, period_size), "sound_Start: snd_pcm_sw_parama_set_avail_min");
  snd(pcm_sw_params_set_start_threshold(output_handle, swparams, output_buffer_size), "sound_Start: snd_pcm_sw_params_set_start_threshold");

  output_buffer_frames_available= 1;
  max_delay_frames= output_buffer_period_size * 2;	/* set initial delay frames */

  snd(pcm_nonblock(output_handle, 1), "sound_Start: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&output_handler, output_handle, output_callback, 0), "soundStart: snd_add_pcm_handler");

  if ((err= snd_pcm_start(output_handle)) < 0)
    {
      if (err != -EPIPE)
	{
	  fprintf(stderr, "snd_pcm_start(1): %s\n", snd_strerror(err));
	  success(false);
	  return 0;
	}
    }

  if ((err= snd_pcm_prepare(output_handle)) < 0)
    fprintf(stderr, "snd_pcm_prepare: %s\n", snd_strerror(err));

  if ((err= snd_pcm_start(output_handle)) < 0)
    {
      if (err != -EPIPE)
	{
	  fprintf(stderr, "snd_pcm_start(2): %s\n", snd_strerror(err));
	  success(false);
	  return 0;
	}
    }

  return 1;
}

static sqInt sound_AvailableSpace(void)
{
#if 1
  snd_pcm_sframes_t delay;    /* distance to playback point (in frames) */
  snd_pcm_state_t   state;    /* current state of the stream */
  sqInt             avail= 0; /* available space for the answer (in bytes) */

  if (!output_handle) return 0;

  snd_pcm_delay(output_handle, &delay);
  snd_pcm_avail_update(output_handle);
  state= snd_pcm_state(output_handle);

  /* if underrun causes, max delay is loosened */
  if (state == SND_PCM_STATE_XRUN)
    max_delay_frames=	MIN(max_delay_frames * 1.5, output_buffer_size - output_buffer_period_size);

  /* if the state is not running, new sound is needed because nobody can signal the semaphore */
  if (delay <= max_delay_frames || state != SND_PCM_STATE_RUNNING)
    {
      avail= output_buffer_period_size;
      max_delay_frames= MAX(max_delay_frames * 0.9995, output_buffer_period_size);
    }
  /*fprintf(stderr, "delay=%i, ans_avail=%i, state=%i, real_delay=%.1fms\n", (int) delay, avail, state, 1000 * max_delay_frames / 22050);*/
  return avail * output_channels * 2;	/* bytes */
#else
  if (output_handle)
    {
      int count= snd_pcm_avail_update(output_handle);
      if (count >= 0)
	return count;
      fprintf(stderr, "sound_AvailableSpace: snd_pcm_avail_update: %s\n", snd_strerror(count));
      snd_pcm_prepare(output_handle);
    }
  return 0;
#endif
}

static sqInt  sound_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime)	FAIL(frameCount)

static sqInt  sound_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex)
{
#if 0
  if (output_handle)
    {
      void *samples= srcBufPtr + startIndex * output_channels * 2;
      int   count=   snd_pcm_writei(output_handle, samples, frameCount);
      if (count < frameCount / 2)
	{
	  output_buffer_frames_available= 0;
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
  success(false);
#else
  if (!output_handle)
      success(false);
  else {
      void *samples= srcBufPtr + startIndex * output_channels * 2;
      int   count=   snd_pcm_writei(output_handle, samples, frameCount);

      if (count < frameCount / 2)
	  output_buffer_frames_available= 0;

      if (count >= 0)
	  return count;

      switch (count) {
	  case -EPIPE: {	/* under-run */
	      int err= snd_pcm_prepare(output_handle);
	      if (err < 0) fprintf(stderr, "sound_PlaySamples: can't recover from underrun, snd_pcm_prepare failed: %s", snd_strerror(err));
	      break;
	  }
	  case -ESTRPIPE: {	/* stream suspended */
	      int err;
	      int timeout= 5;	/* half a second */
	      while (-EAGAIN == (err= snd_pcm_resume(output_handle)) && timeout--)
		  usleep(100000);		/* wait 1/10 of a second for suspend flag to be released */
	      if (-EAGAIN == err) break;	/* return to interpreter and try to recover next time around */
	      if (err < 0) err= snd_pcm_prepare(output_handle);
	      if (err < 0) fprintf(stderr, "sound_PlaySamples: can't recover from suspend, snd_pcm_prepare failed: %s", snd_strerror(err));
	      break;
	  }
	  default:
	      fprintf(stderr, "snd_pcm_writei returned %i\n", count);
	      break;
      }
  }
#endif
  return 0;
}

static sqInt  sound_PlaySilence(void)										FAIL(8192)


/* input */


#if 0
#define SQ_SND_REC_START_THRESHOLD	4/8
#define SQ_SND_REC_AVAIL_MIN		4/8
#endif

static snd_pcm_t		*input_handle= 0;
static snd_async_handler_t	*input_handler= 0;
static int			 input_semaphore= 0;
static int			 input_channels= 0;
static unsigned int		 input_rate= 0;

static void input_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(input_semaphore);
}

static sqInt sound_StopRecording(void)
{
  if (input_handle)
    {
      snd_pcm_close(input_handle);
      input_handle= 0;
      sigio_restore();
    }
  return 0;
}

static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  snd_pcm_uframes_t	 frames;
  snd_pcm_uframes_t	 period_size;
  snd_pcm_uframes_t	 buffer_size;

  if (input_handle) sound_StopRecording();

  input_semaphore= semaIndex;
  input_channels= stereo ? 2 : 1;
  snd(pcm_open(&input_handle, sound_device, SND_PCM_STREAM_CAPTURE, 0), "start_SoundRecording: snd_pcm_open");

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(input_handle, hwparams);
  snd_pcm_hw_params_set_access(input_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(input_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(input_handle, hwparams, input_channels);
  input_rate= desiredSamplesPerSec;
  snd_pcm_hw_params_set_rate_near(input_handle, hwparams, &input_rate, 0);
  frames= 4096;
  snd_pcm_hw_params_set_period_size_near(input_handle, hwparams, &frames, 0);
  snd(pcm_hw_params(input_handle, hwparams), "sound_StartRecording: snd_pcm_hw_params");

  snd(pcm_hw_params_get_period_size(hwparams, &period_size, 0), "sound_Start: pcm_hw_params_get_period_size");
  snd(pcm_hw_params_get_buffer_size(hwparams, &buffer_size), "sound_Start: pcm_hw_params_get_buffer_size");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(input_handle, swparams), "sound_StartRecording: snd_pcm_sw_params_current");
#if 0
  snd(pcm_sw_params_set_start_threshold(input_handle, swparams, frames * SQ_SND_REC_START_THRESHOLD), "sound_StartRecording: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(input_handle, swparams, frames * SQ_SND_REC_AVAIL_MIN), "sound_StartRecording: snd_pcm_sw_parama_set_avail_min");
#else
  snd(pcm_sw_params_set_start_threshold(input_handle, swparams, buffer_size), "sound_StartRecording: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(input_handle, swparams, period_size), "sound_StartRecording: snd_pcm_sw_parama_set_avail_min");
#endif
  snd(pcm_sw_params_set_xfer_align(input_handle, swparams, 1), "sound_StartRecording: snd_pcm_sw_params_set_xfer_align");
  snd(pcm_sw_params(input_handle, swparams), "sound_StartRecording: snd_pcm_sw_params");

  snd(pcm_nonblock(input_handle, 1), "sound_StartRecording: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&input_handler, input_handle, input_callback, 0), "sound_StartRecording: snd_add_pcm_handler");
  snd(pcm_start(input_handle), "sound_StartRecording: snd_pcm_start");
  return 1;
}

static double sound_GetRecordingSampleRate(void)
{
  return (double)input_rate;
}

static sqInt sound_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  if (input_handle)
    {
      void *samples=    buf + (startSliceIndex * 2);
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
  success(false);
  return 0;
}


/* mixer */


static int		 sound_nomixer	= 0;
static snd_mixer_t	*mixer_handle	= 0;
static snd_mixer_elem_t	*mixer_element	= 0;


static int mixer_open(char *name)
{
  struct snd_mixer_selem_regopt  smixer_options;
  int				 err;
  snd_mixer_selem_id_t		*sid;

  if (sound_nomixer) return -EACCES;

  smixer_options.device= sound_device;
  snd_mixer_selem_id_alloca(&sid);
  snd_mixer_selem_id_set_name(sid, name);
  snd(mixer_open(&mixer_handle, 0),			"snd_mixer_open");
  snd(mixer_attach(mixer_handle, sound_device),		"snd_mixer_attach");
  snd(mixer_selem_register(mixer_handle, NULL, NULL),	"snd_selem_register");
  snd(mixer_load(mixer_handle),				"snd_mixer_load");

  mixer_element= snd_mixer_find_selem(mixer_handle, sid);

  if (!mixer_element)
    {
      fprintf(stderr, "unable to find control %s, %i\n", snd_mixer_selem_id_get_name(sid), snd_mixer_selem_id_get_index(sid));
      return -ENOENT;
    }

  return 0;
}

static void mixer_close(void)
{
  snd_mixer_close(mixer_handle);
  mixer_handle= 0;
}


static inline void mixer_getVolume(char *name, int captureFlag, double *leftLevel, double *rightLevel)
{
  if (mixer_open(name))
    {
      mixer_close();
      return;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_volume : snd_mixer_selem_has_playback_volume)(mixer_element))
    fprintf(stderr, "%s: no %s volume\n", name, captureFlag ? "capture" : "playback");
  else
    {
      long vmin, vmax;
      int channel= -1;
      (captureFlag ? snd_mixer_selem_get_capture_volume_range : snd_mixer_selem_get_playback_volume_range)(mixer_element, &vmin, &vmax);
      fprintf(stderr, "%s range  %li - %li\n", captureFlag ? "capture" : "playback", vmin, vmax);
      while (++channel <= SND_MIXER_SCHN_LAST)
	if ((captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, channel))
	  {
	    long vol;
	    (captureFlag ? snd_mixer_selem_get_capture_volume : snd_mixer_selem_get_playback_volume)(mixer_element, channel, &vol);
	    *leftLevel= *rightLevel= (double)(vol - vmin) / (double)(vmax - vmin);
	    break;
	  }
      while (++channel <= SND_MIXER_SCHN_LAST)
	if ((captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, channel))
	  {
	    long vol;
	    (captureFlag ? snd_mixer_selem_get_capture_volume : snd_mixer_selem_get_playback_volume)(mixer_element, channel, &vol);
	    *rightLevel= (double)(vol - vmin) / (double)(vmax - vmin);
	    break;
	  }
    }

  mixer_close();
}


static inline void mixer_setVolume(char *name, int captureFlag, double leftLevel, double rightLevel)
{
  if (mixer_open(name))
    {
      mixer_close();
      return;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_volume : snd_mixer_selem_has_playback_volume)(mixer_element))
    fprintf(stderr, "%s: no %s volume\n", name, captureFlag ? "capture" : "playback");
  else
    {
      long vmin, vmax;
      int channel= -1;
      (captureFlag ? snd_mixer_selem_get_capture_volume_range : snd_mixer_selem_get_playback_volume_range)(mixer_element, &vmin, &vmax);
      fprintf(stderr, "playback range  %li - %li\n", vmin, vmax);
      while (++channel <= SND_MIXER_SCHN_LAST)
	if ((captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, channel))
	  {
	    long vol= vmin + (double)(vmax - vmin) * leftLevel;
	    (captureFlag ? snd_mixer_selem_set_capture_volume : snd_mixer_selem_set_playback_volume)(mixer_element, channel, vol);
	    (captureFlag ? snd_mixer_selem_set_capture_switch : snd_mixer_selem_set_playback_switch)(mixer_element, channel, 1);
	    break;
	  }
      while (++channel <= SND_MIXER_SCHN_LAST)
	if ((captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, channel))
	  {
	    long vol= vmin + (double)(vmax - vmin) * rightLevel;
	    (captureFlag ? snd_mixer_selem_set_capture_volume : snd_mixer_selem_set_playback_volume)(mixer_element, channel, vol);
	    (captureFlag ? snd_mixer_selem_set_capture_switch : snd_mixer_selem_set_playback_switch)(mixer_element, channel, 1);
	    break;
	  }
    }

  mixer_close();
}

static int mixer_setSwitch(char *name, int captureFlag, int parameter)
{
  int chn;
  if (mixer_open(name))
    {
      mixer_close();
      return 0;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_switch : snd_mixer_selem_has_playback_switch)(mixer_element))
    {
      mixer_close();
      return 0;
    }

  for (chn= 0;  chn <= SND_MIXER_SCHN_LAST;  ++chn)
    {
      if (!(captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, chn))
	continue;

      if ((captureFlag ? snd_mixer_selem_set_capture_switch : snd_mixer_selem_set_playback_switch)(mixer_element, chn, parameter) < 0)
	continue;
    }

  mixer_close();
  return 1;
}

static int mixer_getSwitch(char *name, int captureFlag, int channel)
{
  int ival;
  if (channel < 0 || channel > SND_MIXER_SCHN_LAST)
    {
      return -1;
    }
      
  if (mixer_open(name))
    {
      mixer_close();
      return -1;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_switch : snd_mixer_selem_has_playback_switch)(mixer_element))
    {
      mixer_close();
      return -1;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer_element, channel))
    {
      mixer_close();
      return -1;
    }

  if ((captureFlag ? snd_mixer_selem_get_capture_switch : snd_mixer_selem_get_playback_switch)(mixer_element, channel, &ival) < 0)
    ival= -1;

  mixer_close();
  return ival;
}

static void sound_Volume(double *left, double *right)
{
  mixer_getVolume(sound_playback, 0, left, right);
}

static void sound_SetVolume(double left, double right)
{
  mixer_setVolume(sound_playback, 0, left, right);
  if (strcmp("Master", sound_playback))
    {
      /* unmute the master volume */
      mixer_getVolume("Master", 0, &left, &right);
      mixer_setVolume("Master", 0,  left,  right);
    }
}

static void sound_SetRecordLevel(sqInt level)
{
  mixer_setVolume(sound_capture, 1, (double)level / 100.0, (double)level / 100.0);
}

static sqInt sound_SetDevice(sqInt id, char *arg)
{
  char *dest= NULL; 
  if (id == 0)
    {
      if (arg == NULL)
	{
	  arg= "default";
	}
      dest= sound_device;
    }
  else if (id == 1)
    {
      if (arg == NULL)
	{
	  arg= "Master";
	}
      dest= sound_playback;
    }
  else if (id == 2)
    {
      if (arg == NULL)
	{
	  arg= "Capture";
	}
      dest= sound_capture;
    }
  
  if (dest)
    {
      strncpy(dest, arg, DEVICE_NAME_LEN-1);
      return 1;
    }
  return -1;
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)
{
  if (id == 1)
    {
    return mixer_getSwitch(sound_playback, captureFlag, channel);
    }
  else if (id == 2)
    {
      return mixer_getSwitch(sound_capture, captureFlag, channel);
    }
  return -1;
}

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)
{
  if (id == 1)
    {
      return mixer_setSwitch(sound_playback, captureFlag, parameter);
  }
  else if (id == 2)
    {
      return mixer_setSwitch(sound_capture, captureFlag, parameter);
    }
  return -1;
}


/* signal support */


static void *sigio_handler= 0;

static void sigio_save(void)
{
  if (!sigio_handler)
    {
      sigio_handler= signal(SIGIO, SIG_IGN);
      signal(SIGIO, sigio_handler);
    }
}

static void sigio_restore(void)
{ 
  if (sigio_handler && !output_handle && !input_handle)
    signal(SIGIO, sigio_handler);
}


/* module */


#include "SqSound.h"

SqSoundDefine(ALSA);

#include "SqModule.h"

static void sound_parseEnvironment(void)
{
  char *ev= 0;

  sound_SetDevice(0, NULL);
  sound_SetDevice(1, NULL);
  sound_SetDevice(2, NULL);

  if (     getenv("SQUEAK_NOMIXER"   ))	sound_nomixer= 1;
  if ((ev= getenv("SQUEAK_SOUNDCARD")))	sound_SetDevice(0, ev);
  if ((ev= getenv("SQUEAK_PLAYBACK" )))	sound_SetDevice(1, ev);
  if ((ev= getenv("SQUEAK_CAPTURE"  )))	sound_SetDevice(2, ev);
}

static int  sound_parseArgument(int argc, char **argv)
{
  if     (!strcmp(argv[0], "-nomixer"  )) { sound_nomixer= 1;		return 1; }
  else if (argv[1])
    {
      if (!strcmp(argv[0], "-soundcard")) { sound_SetDevice(0, argv[1]);	return 2; }
      if (!strcmp(argv[0], "-playback" )) { sound_SetDevice(1, argv[1]);	return 2; }
      if (!strcmp(argv[0], "-capture"  )) { sound_SetDevice(2, argv[1]);	return 2; }
    }
  return 0;
}

static void  sound_printUsage(void)
{
  printf("\nALSA <option>s:\n");
  printf("  -nomixer              disable mixer (volume) adjustment\n");
  printf("  -soundcard <name>     open the named sound card (default: %s)\n", sound_device);
  printf("  -playback <name>      play to the named sound device (default: %s)\n", sound_playback);
  printf("  -capture <name>       record from the named sound device (default: %s)\n", sound_capture);
}

static void  sound_printUsageNotes(void) {}

static void *sound_makeInterface(void)
{
  sigio_save();
  return &sound_ALSA_itf;
}

SqModuleDefine(sound, ALSA);
