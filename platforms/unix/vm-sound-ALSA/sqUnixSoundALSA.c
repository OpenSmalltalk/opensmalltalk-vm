/* sqUnixSoundALSA.c -- cheap and cheerful sound for Advanced Linux Sound Architecture
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2009-12-17 10:26:20 by piumarta on ubuntu
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
#include "SqSound.h"

#include <alsa/asoundlib.h>
#include <errno.h>
#include <signal.h>



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

#if WORK_AROUND_BROKEN_LIBASOUND
static void sigio_save(void);
static void sigio_restore(void);
#endif

#define HARDWIRE_DEFAULT 1

#define DEVICE_NAME_LEN 128

static char sound_device[DEVICE_NAME_LEN]   = "default";
static char sound_playback[DEVICE_NAME_LEN] = "default";
static char sound_capture[DEVICE_NAME_LEN]	= "default";

#define PlaybackSetting 0 /* value for captureFlag */
#define CaptureSetting 1 /* value for captureFlag */

static int hardware_name(int captureFlag, char *name_out); /* e.g. hw:0 */

/* output */

#define SQ_SND_PLAY_START_THRESHOLD	7/8
#define SQ_SND_PLAY_AVAIL_MIN		4/8

static snd_pcm_t		*playback_handle= 0;
static snd_async_handler_t	*playback_handler= 0;
static int			 output_semaphore= 0;
static int			 output_channels= 0;
static snd_pcm_uframes_t	 output_buffer_period_size= 0;
static snd_pcm_uframes_t	 output_buffer_size= 0;
static double			 max_delay_frames= 0;

static int
ensure_playback_handle()
{
	static char playback_handle_device[DEVICE_NAME_LEN] = "bogus";
	char device_name[16];
	int err;

	if (!hardware_name(PlaybackSetting,device_name))
		return -EACCES;

	if (playback_handle) {
		if (!strcmp(sound_playback,playback_handle_device))
			return 0;

		snd_pcm_close(playback_handle);
	}
#if 0
	printf("ensure_playback_handle opening '%s' as '%s'\n",
			sound_playback, device_name);
#endif
	if ((err= snd_pcm_open(&playback_handle, device_name, SND_PCM_STREAM_PLAYBACK, 0)) < 0)
		fprintf(stderr, "ensure_playback_handle snd_pcm_open: %s\n", snd_strerror(err));
	else
		strcpy(playback_handle_device,sound_playback);
	if (!playback_handle) assert(err);
	return err;
}

static void playback_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(output_semaphore);
}

static snd_pcm_t		*capture_handle= 0;
static snd_async_handler_t	*capture_handler= 0;
static int			 input_semaphore= 0;
static int			 input_channels= 0;
static unsigned int		 input_rate= 0;

static int
ensure_capture_handle()
{
	static char capture_handle_device[DEVICE_NAME_LEN] = "bogus";
	char device_name[16];
	int err;

	if (!hardware_name(CaptureSetting,device_name))
		return -EACCES;

	if (capture_handle) {
		if (!strcmp(sound_capture,capture_handle_device))
			return 0;

		snd_pcm_drain(capture_handle);
		snd_pcm_close(capture_handle);
	}
	printf("ensure_capture_handle opening '%s' as '%s'\n",
			sound_capture, device_name);
	if ((err= snd_pcm_open(&capture_handle, device_name, SND_PCM_STREAM_CAPTURE, 0)) < 0)
		fprintf(stderr, "ensure_capture_handle snd_pcm_open: %s\n", snd_strerror(err));
	else
		strcpy(capture_handle_device,sound_capture);
	if (!capture_handle) assert(err);
	return err;
}

static void capture_callback(snd_async_handler_t *handler)
{
  signalSemaphoreWithIndex(input_semaphore);
}


static sqInt sound_Stop(void)
{
	if (playback_handle) {
		snd_pcm_drain(playback_handle);
		snd_pcm_close(playback_handle);
		playback_handle= 0;
#if WORK_AROUND_BROKEN_LIBASOUND
		if (!capture_handle)
			sigio_restore();
#endif
	}
	return 0;
}

static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  unsigned int		 uval;
  int			 dir;

  if (playback_handle) sound_Stop();

  output_semaphore= semaIndex;
  output_channels= stereo ? 2 : 1;
  printf("sound_Start(%s)\n", sound_playback);
  if ((err = ensure_playback_handle())) {
		success(false);
		return err;
  }

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(playback_handle, hwparams);
  snd_pcm_hw_params_set_access(playback_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(playback_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(playback_handle, hwparams, output_channels);
  uval= samplesPerSec;
  snd_pcm_hw_params_set_rate_near(playback_handle, hwparams, &uval, &dir);
  output_buffer_period_size= frameCount;
  snd_pcm_hw_params_set_period_size_near(playback_handle, hwparams, &output_buffer_period_size, &dir);
  snd(pcm_hw_params(playback_handle, hwparams), "sound_Start: snd_pcm_hw_params");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(playback_handle, swparams), "sound_Start: snd_pcm_sw_params_current");
  snd(pcm_sw_params_set_start_threshold(playback_handle, swparams, frameCount * SQ_SND_PLAY_START_THRESHOLD), "sound_Start: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(playback_handle, swparams, frameCount * SQ_SND_PLAY_AVAIL_MIN), "sound_Start: snd_pcm_sw_parama_set_avail_min");
#if 0 // snd_pcm_sw_params_set_xfer_align is deprecated
  snd(pcm_sw_params_set_xfer_align(playback_handle, swparams, 1), "sound_Start: snd_pcm_sw_params_set_xfer_align");
#endif
  snd(pcm_sw_params(playback_handle, swparams), "sound_Start: snd_pcm_sw_params");
  snd(pcm_hw_params_get_buffer_size(hwparams, &output_buffer_size), "sound_Start: pcm_hw_params_get_buffer_size");
  max_delay_frames= output_buffer_period_size * 2;	/* set initial delay frames */

  snd(pcm_nonblock(playback_handle, 1), "sound_Start: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&playback_handler, playback_handle, playback_callback, 0), "soundStart: snd_add_pcm_handler");

  if ((err= snd_pcm_start(playback_handle)) < 0)
    {
      if (err != -EPIPE)
	{
	  fprintf(stderr, "snd_pcm_start(1): %s\n", snd_strerror(err));
	  success(false);
	  return 0;
	}
    }

  if ((err= snd_pcm_prepare(playback_handle)) < 0)
    fprintf(stderr, "snd_pcm_prepare: %s\n", snd_strerror(err));

  if ((err= snd_pcm_start(playback_handle)) < 0)
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

  if (!playback_handle) return 0;

  snd_pcm_delay(playback_handle, &delay);
  snd_pcm_avail_update(playback_handle);
  state= snd_pcm_state(playback_handle);

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
  if (playback_handle)
    {
      int count= snd_pcm_avail_update(playback_handle);
      if (count >= 0)
	return count;
      fprintf(stderr, "sound_AvailableSpace: snd_pcm_avail_update: %s\n", snd_strerror(count));
      snd_pcm_prepare(playback_handle);
    }
  return 0;
#endif
}

static sqInt  sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)	FAIL(frameCount)

static sqInt  sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)
{
  if (playback_handle)
    {
      void *samples= (void *)arrayIndex + startIndex * output_channels * 2;
      int   count=   snd_pcm_writei(playback_handle, samples, frameCount);
      if (count < 0)
	{
	  if (count == -EPIPE)    /* underrun */
	    {
	      int err;
	      snd(pcm_prepare(playback_handle), "sound_PlaySamples: snd_pcm_prepare");
	      return 0;
	    }
	  fprintf(stderr, "snd_pcm_writei returned %i\n", count);
	  return 0;
	}
      return count;
    }
  success(false);
  return 0;
}

static sqInt  sound_PlaySilence(void)	FAIL(8192)


/* input */


#define SQ_SND_REC_START_THRESHOLD	4/8
#define SQ_SND_REC_AVAIL_MIN		4/8

static sqInt sound_StopRecording(void)
{
	if (capture_handle) {
		/*snd_pcm_drain(capture_handle);*/
		snd_pcm_close(capture_handle);
		capture_handle= 0;
#if WORK_AROUND_BROKEN_LIBASOUND
		if (!playback_handle)
			sigio_restore();
#endif
	}
	return 0;
}

static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int			 err;
  snd_pcm_hw_params_t	*hwparams;
  snd_pcm_sw_params_t	*swparams;
  snd_pcm_uframes_t	 frames;
  int			 dir;

  if (capture_handle) sound_StopRecording();

  input_semaphore= semaIndex;
  input_channels= stereo ? 2 : 1;
  printf("sound_StartRecording(%s)\n", sound_capture);
  if ((err = ensure_capture_handle())) {
		success(false);
		return err;
  }

  snd_pcm_hw_params_alloca(&hwparams);
  snd_pcm_hw_params_any(capture_handle, hwparams);
  snd_pcm_hw_params_set_access(capture_handle, hwparams, SND_PCM_ACCESS_RW_INTERLEAVED);
  snd_pcm_hw_params_set_format(capture_handle, hwparams, SND_PCM_FORMAT_S16_LE);
  snd_pcm_hw_params_set_channels(capture_handle, hwparams, input_channels);
  input_rate= desiredSamplesPerSec;
  snd_pcm_hw_params_set_rate_near(capture_handle, hwparams, &input_rate, &dir);
  frames= 4096;
  snd_pcm_hw_params_set_period_size_near(capture_handle, hwparams, &frames, &dir);
  snd(pcm_hw_params(capture_handle, hwparams), "sound_StartRecording: snd_pcm_hw_params");

  snd_pcm_sw_params_alloca(&swparams);
  snd(pcm_sw_params_current(capture_handle, swparams), "sound_StartRecording: snd_pcm_sw_params_current");
  snd(pcm_sw_params_set_start_threshold(capture_handle, swparams, frames * SQ_SND_REC_START_THRESHOLD), "sound_StartRecording: snd_pcm_sw_params_set_start_threshold");
  snd(pcm_sw_params_set_avail_min(capture_handle, swparams, frames * SQ_SND_REC_AVAIL_MIN), "sound_StartRecording: snd_pcm_sw_parama_set_avail_min");
#if 0 // snd_pcm_sw_params_set_xfer_align is deprecated
  snd(pcm_sw_params_set_xfer_align(capture_handle, swparams, 1), "sound_StartRecording: snd_pcm_sw_params_set_xfer_align");
#endif
  snd(pcm_sw_params(capture_handle, swparams), "sound_StartRecording: snd_pcm_sw_params");

  snd(pcm_nonblock(capture_handle, 1), "sound_StartRecording: snd_pcm_nonblock");
  snd(async_add_pcm_handler(&capture_handler, capture_handle, capture_callback, 0), "sound_StartRecording: snd_add_pcm_handler");
  snd(pcm_start(capture_handle), "sound_StartRecording: snd_pcm_start");
  return 1;
}

static double sound_GetRecordingSampleRate(void)
{
  return (double)input_rate;
}

#define PROTECT_RECORD_SAMPLES 0

#if PROTECT_RECORD_SAMPLES
# include <sys/types.h>
# include <sys/time.h>

static sqInt
protected_sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
	/* see git://android.git.kernel.org/platform/hardware/alsa_sound.git/
	 *		AudioStreamInALSA.cpp: AudioStreamInALSA::read
	 */
	if (capture_handle) {
		void *samples=    (void *)buf + (startSliceIndex * 2);
# if 1
		int   frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / input_channels;
# else
		int   bytes = bufferSizeInBytes - (startSliceIndex * 2);
		int   frameCount= snd_pcm_bytes_to_frames(capture_handle, bytes);
# endif
		int   count;

		do {
			count = snd_pcm_readi(capture_handle, samples, frameCount);
			if (count < frameCount) {    
				int old_count = count;
				if (capture_handle) {
#define SILENT 1
#define REPORT 0
					if (count < 0)
						count = snd_pcm_recover(capture_handle, count, REPORT);
#undef SILENT
#undef REPORT
					else
						count = snd_pcm_prepare(capture_handle);
					printf("\tsnd_pcm_readi(%d) %d -> %d\n", frameCount, old_count, count);
					return count * input_channels;
				}
			}
		}
		while (count == -EAGAIN);
		printf("\tsnd_pcm_readi(%d) %d\n", frameCount, count);
		return count * input_channels;
	}
	success(false);
	return 0;
}
#endif /* PROTECT_RECORD_SAMPLES */

static sqInt sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
#if 0
  if (capture_handle)
    {
      void *samples=    (void *)buf + (startSliceIndex * 2);
      int   frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / input_channels;
      int   count=      snd_pcm_readi(capture_handle, samples, frameCount);
      if (count < 0)
	{    
	  if (count == -EPIPE)
	    snd_pcm_prepare(capture_handle);
	  else if (count != -EAGAIN)
	    fprintf(stderr, "snd_pcm_readi returned %i\n", count);
	  return 0;
	}
      return count * input_channels;
    }
  success(false);
  return 0;
#elif 1
	if (capture_handle) {
		void *samples=    (void *)buf + (startSliceIndex * 2);
		int   frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / input_channels;
		int   count;

		do {
			count = snd_pcm_readi(capture_handle, samples, frameCount);
			if (count < 0) {    
				if (count == -EINTR) {
					fprintf(stderr,".");
					continue;
				}
				if (count == -EPIPE)
					snd_pcm_prepare(capture_handle);
				else if (count != -EAGAIN)
					fprintf(stderr, "snd_pcm_readi returned %i\n", count);
				return 0;
			}
		}
		while (count < 0);
		return count * input_channels;
	}
	success(false);
	return 0;
#elif 0
	/* see git://android.git.kernel.org/platform/hardware/alsa_sound.git/
	 *		AudioStreamInALSA.cpp: AudioStreamInALSA::read
	 */
	if (capture_handle) {
		void *samples=    (void *)buf + (startSliceIndex * 2);
# if 0
		int   frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / input_channels;
# else
		int   bytes = bufferSizeInBytes - (startSliceIndex * 2);
		int   frameCount= snd_pcm_bytes_to_frames(capture_handle, bytes);
# endif
		int   count;

		do {
			count = snd_pcm_readi(capture_handle, samples, frameCount);
			if (count < frameCount) {    
				if (capture_handle) {
#define SILENT 1
#define REPORT 0
					if (count < 0)
						count = snd_pcm_recover(capture_handle, count, REPORT);
#undef SILENT
#undef REPORT
					else
						count = snd_pcm_prepare(capture_handle);
					return count * input_channels;
				}
			}
		}
		while (count == -EAGAIN);
		return count * input_channels;
	}
	success(false);
	return 0;
#elif PROTECT_RECORD_SAMPLES
	struct itimerval saved_itimer, disable;
	int result;

	timerclear(&disable.it_value);
	(void)setitimer(ITIMER_REAL, &disable, &saved_itimer);

	result = protected_sound_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);

	(void)setitimer(ITIMER_REAL, &saved_itimer, 0);
	return result;
#else
# error you must choose at least one version fo StartRecording
#endif
}


/* mixer */


static int		 sound_nomixer	= 0;

/*
Notes:
Cache output mixer handle with output handle?
Cache input mixer handle with input handle?

Filter out from devices those that have no controls.
e.g. hw:1 has no controls so why include it in the list of devices?
We can do an enumerate over devices at some point (but how do we discover
whether a new device is inserted?  The Smalltalk layer contnues to poll
occasionally so not out problem).  We can set a bit in a flag word to exclude
devices.
*/
typedef struct {
	int					error;
	snd_mixer_t			*handle;
} mixer;

static int
numDevicesOfType(int stream_type);
static char *
nameOfNthDeviceOfType(int n, int stream_type);

#define SND_PCM_STREAM_ANY (SND_PCM_STREAM_CAPTURE+SND_PCM_STREAM_PLAYBACK+1)

static int
hardware_name(int captureFlag, char *name_out) /* i.e. default hw:0 hw:1 etc */
{
	char *device_name = captureFlag ? sound_capture : sound_playback;
	int i, n;

	if (!strcmp(device_name,"default")) {
		strcpy(name_out,"default");
		return 1;
	}

	for (i = 0, n = numDevicesOfType(SND_PCM_STREAM_ANY); i < n; i++)
		if (!strcmp(device_name,nameOfNthDeviceOfType(i,SND_PCM_STREAM_ANY))) {
			sprintf(name_out,"hw:%d", i);
			return 1;
		}

	return 0;
}

static mixer
mixer_open(int captureFlag)
{
  mixer mixer;
  int err;
  char device_name[16];

  memset(&mixer,0,sizeof(mixer));
  if (sound_nomixer) {
	mixer.error = EACCES;
	return mixer;
  }
  if (!hardware_name(captureFlag,device_name)) {
    fprintf(stderr, "mixer_open: can't find device %s\n", device_name);
	mixer.error = EACCES;
	return mixer;
  }

#define mix(expr, what)										\
  if ((err= snd_##expr) < 0) {								\
      fprintf(stderr, "%s: %s\n", what, snd_strerror(err));	\
      success(false);										\
      mixer.error = err;									\
      return mixer;											\
  }

  mix(mixer_open(&mixer.handle, 0),			"snd_mixer_open");
  mix(mixer_attach(mixer.handle, device_name),	"snd_mixer_attach");
  mix(mixer_selem_register(mixer.handle,0,0),"snd_mixer_selem_register");
  mix(mixer_load(mixer.handle),				"snd_mixer_load");

  return mixer;
}

static void
mixer_close(mixer *mixer)
{
  if (mixer->handle)
	snd_mixer_close(mixer->handle);
  else
	fprintf(stderr, "mixer_close: mixer already closed\n");
  mixer->handle= 0;
}

/* hardwired likely master control names.  This from HP EliteBook 8530p.
 * Built-in hw:0 has "Master" playback volume/switch.
 * Built-in hw:0 has "PCM" playbac what it says  volume/switch.
 * Plugin USB headset hw:2 has "Speaker" playback volume/switch.
 * Built-in hw:0 has "Capture" (4 & 5) capture volume/switch. but only 4 seems to work
 * Plugin USB headset hw:2 has "Mic" capture volume/switch.
 * USB plays back at 8 x tempo (but not 8 x freq)
 */
static char *playback_controls[] = { "PCM" };
static char *capture_controls[] = { "Capture" };


static inline int
names_contains(char *names[], int n, const char *name)
{
	while (--n >= 0)
		if (!strcmp(names[n], name))
			return 1;
	return 0;
}

/* Enumerate over the mixer elements for the current sound_playback or 
 * sound_capture device, as selected by captureFlag, and either return its
 * volume as a value in the range 0.0 to 1.0 through *get, if set, or set
 * its volume as a value in the range 0.0 to 1.0 if *get is null.
 * Answer 0 on success or an alsa error on failure.
 */
static int
mixer_default_volume_get_set(int captureFlag, double *get, double set)
{
	int turn_on = set > 0.001, result = 0;
	snd_mixer_elem_t *elem;
	char **controls = captureFlag ? capture_controls : playback_controls;
	int num_controls = (captureFlag
							? sizeof(capture_controls)
							: sizeof(playback_controls)) / sizeof(char *);
	int (*has_volume)(snd_mixer_elem_t *) = captureFlag
										? snd_mixer_selem_has_capture_volume
										: snd_mixer_selem_has_playback_volume;
	int (*get_volume_range)(snd_mixer_elem_t *,long *,long *) = captureFlag
									? snd_mixer_selem_get_capture_volume_range
									: snd_mixer_selem_get_playback_volume_range;
	int (*set_volume_all)(snd_mixer_elem_t *, long) = captureFlag
									? snd_mixer_selem_set_capture_volume_all
									: snd_mixer_selem_set_playback_volume_all;
	int (*set_switch_all)(snd_mixer_elem_t *, int) = captureFlag
									? snd_mixer_selem_set_capture_switch_all
									: snd_mixer_selem_set_playback_switch_all;
	int (*get_volume)(snd_mixer_elem_t *, snd_mixer_selem_channel_id_t, long *) = captureFlag
									? snd_mixer_selem_get_capture_volume
									: snd_mixer_selem_get_playback_volume;

	mixer mixer = mixer_open(captureFlag);

	if (mixer.error) {
		mixer_close(&mixer);
		return;
	}

	/* Iterate over all mixer controls */
	for (elem = snd_mixer_first_elem(mixer.handle);
		 elem;
		 elem = snd_mixer_elem_next(elem)) {
		long range_min, range_max, value;
		const char *elem_name;
		int ret;

#define DEFAULT_CHANNEL SND_MIXER_SCHN_MONO  /** Mono (Front left alias) */
						/* SND_MIXER_SCHN_MONO = SND_MIXER_SCHN_FRONT_LEFT */

		if (!snd_mixer_selem_is_active(elem))
			continue;

		elem_name = snd_mixer_selem_get_name(elem);

		if (names_contains(controls, num_controls, elem_name)) {
			ret = get_volume_range(elem, &range_min, &range_max);
			if (ret < 0) {
				fprintf(stderr,"get_volume_range error: %s", snd_strerror(ret));
				result = -ret;
			}
			assert(has_volume(elem));
			if (!get) {
				long vol = (range_max - range_min) * set + range_min;
#if 0
				if (vol < range_min)
					vol = range_min;
				else if (vol > range_max)
					vol = range_max;
#endif
				ret = set_volume_all(elem, vol);
				if (ret < 0) {
					fprintf(stderr,"set_volume_all error: %s", snd_strerror(ret));
					result = -ret;
				}
				else {
					ret = set_switch_all(elem, turn_on);
					if (ret < 0) {
						fprintf(stderr,"set_switch_all error: %s", snd_strerror(ret));
						result = -ret;
					}
				}
			}
			else {
				get_volume(elem, DEFAULT_CHANNEL, &value);
				*get = (double)(value - range_min)
					 / (double)(range_max - range_min);
			}
			mixer_close(&mixer);
			return result;
		}
	}
	mixer_close(&mixer);
	return result;
}

static int mixer_setSwitch(char *name, int captureFlag, int parameter)
{
#if 0
  int chn;
  mixer mixer = mixer_open(captureFlag);

  if (mixer.error) {
      mixer_close(&mixer);
      return;
  }

  if (!(captureFlag ? snd_mixer_selem_has_capture_switch : snd_mixer_selem_has_playback_switch)(mixer.element))
    {
      mixer_close(&mixer);
      return 0;
    }

  for (chn= 0;  chn <= SND_MIXER_SCHN_LAST;  ++chn)
    {
      if (!(captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer.element, chn))
	continue;

      if ((captureFlag ? snd_mixer_selem_set_capture_switch : snd_mixer_selem_set_playback_switch)(mixer.element, chn, parameter) < 0)
	continue;
    }

  mixer_close(&mixer);
  return 1;
#else
	return -1;
#endif
}

static int mixer_getSwitch(char *name, int captureFlag, int channel)
{
#if 0
  int ival;
  mixer mixer;

  if (channel < 0 || channel > SND_MIXER_SCHN_LAST)
      return -1;

  mixer = mixer_open(captureFlag);
  if (mixer.error) {
      mixer_close(&mixer);
      return;
  }

  if (!(captureFlag ? snd_mixer_selem_has_capture_switch : snd_mixer_selem_has_playback_switch)(mixer.element))
    {
      mixer_close(&mixer);
      return -1;
    }

  if (!(captureFlag ? snd_mixer_selem_has_capture_channel : snd_mixer_selem_has_playback_channel)(mixer.element, channel))
    {
      mixer_close(&mixer);
      return -1;
    }

  if ((captureFlag ? snd_mixer_selem_get_capture_switch : snd_mixer_selem_get_playback_switch)(mixer.element, channel, &ival) < 0)
    ival= -1;

  mixer_close(&mixer);
  return ival;
#else
	return -1;
#endif
}

/* Squeak Prim: Return sound as array of doubles left then right channel, range
 * is 0.0 to 1.0 but may be overdriven.
 */
static void sound_Volume(double *left, double *right)
{
	double level;
	mixer_default_volume_get_set(PlaybackSetting, &level, 0.0);

	*left = *right = level;
}

/* Squeak Prim: Set sound pass in float 0.0-1.0 for left and right channel,
 * with possible 2.0 or higher to overdrive sound channel.
 */
static void sound_SetVolume(double left, double right)
{
  mixer_default_volume_get_set(PlaybackSetting, 0, (left + right) / 2.0);
}

/* Squeak Prim: Set the recording level to the given value in the range 0-1000,
 * where 0 is the lowest recording level and 1000 is the maximum.  Do nothing
 * if the sound input hardware does not support changing the recording level.
 */
static sqInt sound_SetRecordLevel(sqInt level)
{
	mixer_default_volume_get_set(CaptureSetting, 0, (double)level / 1000.0);
	return 1;
}

/* Squeak Prim: Get the recording level to the given value in the range 0-1000,
 * where 0 is the lowest recording level and 1000 is the maximum.  Do nothing
 * if the sound input hardware does not support changing the recording level.
 */
static sqInt sound_GetRecordLevel(void) /* eem Feb 7 2010 after hrs' SoundRecorder extras. */
{ double level = 0.0;

  mixer_default_volume_get_set(CaptureSetting, &level, 0.0);
  return level * 1000.0L;
}

static sqInt sound_SetDevice(sqInt id, char *arg)
{ 
#if  HARDWIRE_DEFAULT 
	return 1;
#else
  char *dest= NULL; 
  printf("sound_SetDevice(%d,%s)\n", id, arg);
  if (!arg)
	arg = "default";
  if (id == 0)
      dest= sound_device;
  else if (id == 1)
      dest= sound_playback;
  else if (id == 2)
      dest= sound_capture;

  if (dest) {
      strncpy(dest, arg, DEVICE_NAME_LEN);
      return 1;
    }
  return -1;
#endif
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)
{
  if (id == 0)
    return mixer_getSwitch(sound_device, captureFlag, channel);
  if (id == 1)
    return mixer_getSwitch(sound_playback, captureFlag, channel);
  if (id == 2)
      return mixer_getSwitch(sound_capture, captureFlag, channel);
  return -1;
}

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)
{
  if (id == 0)
      return mixer_setSwitch(sound_device, captureFlag, parameter);
  if (id == 1)
      return mixer_setSwitch(sound_playback, captureFlag, parameter);
  if (id == 2)
      return mixer_setSwitch(sound_capture, captureFlag, parameter);
  return -1;
}


/* eem Feb 7 2010 after hrs' SoundRecorder extras. */
static int
numDevicesOfType(int stream_type)
{
	/* derived from aplay.c in alsa-utils-1.0.22 */
	snd_ctl_t *handle;
	int card = -1, err, count = 0;
	snd_ctl_card_info_t *info;
	snd_pcm_info_t *pcminfo;
	snd_ctl_card_info_alloca(&info);
	snd_pcm_info_alloca(&pcminfo);

	if (snd_card_next(&card) < 0 || card < 0)
		return 0;

	while (card >= 0) {
		int dev = -1;
		char name[32];

		sprintf(name, "hw:%d", card);
		if ((err = snd_ctl_open(&handle, name, 0)) < 0) {
			fprintf(stderr,"control open (%i): %s\n", card, snd_strerror(err));
			goto next_card;
		}
		if ((err = snd_ctl_card_info(handle, info)) < 0) {
			fprintf(stderr,"control hardware info (%i): %s\n", card, snd_strerror(err));
			snd_ctl_close(handle);
			goto next_card;
		}
		while (1) {
			if (snd_ctl_pcm_next_device(handle, &dev)<0)
				fprintf(stderr,"snd_ctl_pcm_next_device\n");
			if (dev < 0)
				break;
			if (stream_type != SND_PCM_STREAM_ANY) {
				/* if looking for a specific stream type then
				 * dig deeper to see if that type is supported */
				snd_pcm_info_set_device(pcminfo, dev);
				snd_pcm_info_set_subdevice(pcminfo, 0);
				snd_pcm_info_set_stream(pcminfo, stream_type);
				if ((err = snd_ctl_pcm_info(handle, pcminfo)) < 0) {
					if (err != -ENOENT)
						fprintf(stderr,"snd_ctl_pcm_info (%i): %s\n",
								card, snd_strerror(err));
					continue;
				}
			}
			count += 1;
		}
		snd_ctl_close(handle);
	next_card:
		if (snd_card_next(&card) < 0) {
			fprintf(stderr,"snd_card_next\n");
			break;
		}
	}
	return count;
}

/* in the libasound source include/sound/asound.h defines the max len as 80 */
#define MAX_NAME_LEN 128
static char devname[MAX_NAME_LEN];

static char *
nameOfNthDeviceOfType(int n, int stream_type)
{
	/* derived from aplay.c in alsa-utils-1.0.22 */
	snd_ctl_t *handle;
	int card = -1, err, count = 0;
	snd_ctl_card_info_t *info;
	snd_pcm_info_t *pcminfo;
	snd_ctl_card_info_alloca(&info);
	snd_pcm_info_alloca(&pcminfo);

	if (snd_card_next(&card) < 0 || card < 0)
		return 0;

	while (card >= 0) {
		int dev = -1;
		char name[32];

		sprintf(name, "hw:%d", card);
		if ((err = snd_ctl_open(&handle, name, 0)) < 0) {
			fprintf(stderr,"control open (%i): %s\n", card, snd_strerror(err));
			goto next_card;
		}
		if ((err = snd_ctl_card_info(handle, info)) < 0) {
			fprintf(stderr,"control hardware info (%i): %s\n", card, snd_strerror(err));
			snd_ctl_close(handle);
			goto next_card;
		}
		while (1) {
			if (snd_ctl_pcm_next_device(handle, &dev)<0)
				fprintf(stderr,"snd_ctl_pcm_next_device\n");
			if (dev < 0)
				break;
			if (stream_type != SND_PCM_STREAM_ANY) {
				/* if looking for a specific stream type then
				 * dig deeper to see if that type is supported */
				snd_pcm_info_set_device(pcminfo, dev);
				snd_pcm_info_set_subdevice(pcminfo, 0);
				snd_pcm_info_set_stream(pcminfo, stream_type);
				if ((err = snd_ctl_pcm_info(handle, pcminfo)) < 0) {
					if (err != -ENOENT)
						fprintf(stderr,"snd_ctl_pcm_info (%i): %s\n",
								card, snd_strerror(err));
					continue;
				}
			}
			if (n == count) {
				strncpy(devname,snd_ctl_card_info_get_name(info),MAX_NAME_LEN);
#if 0
				printf("snd_name '%s' -> dev_name '%s'\n",
						snd_ctl_card_info_get_name(info),
						devname);
#endif
				return devname;
			}
			count += 1;
		}
		snd_ctl_close(handle);
	next_card:
		if (snd_card_next(&card) < 0) {
			fprintf(stderr,"snd_card_next\n");
			break;
		}
	}
	return 0;
}

#if HARDWIRE_DEFAULT
static int sound_GetNumberOfSoundPlayerDevices(void) { return 1; }

static int sound_GetNumberOfSoundRecorderDevices(void) { return 1; }

static char* sound_GetDefaultSoundPlayer(void) { return "default"; }

static char* sound_GetDefaultSoundRecorder(void) { return "default"; }

static char* sound_GetSoundPlayerDeviceName(int n) { return "default"; }

static char* sound_GetSoundRecorderDeviceName(int n) { return "default"; }

#else /* HARDWIRE_DEFAULT */
static int sound_GetNumberOfSoundPlayerDevices(void)
{
	return numDevicesOfType(SND_PCM_STREAM_PLAYBACK);
}

static int sound_GetNumberOfSoundRecorderDevices(void)
{
	return numDevicesOfType(SND_PCM_STREAM_CAPTURE);
}

static char* sound_GetDefaultSoundPlayer(void)
{
	return sound_playback;
}

static char* sound_GetDefaultSoundRecorder(void)
{
	return sound_capture;
}

static char* sound_GetSoundPlayerDeviceName(int n)
{
	return nameOfNthDeviceOfType(n, SND_PCM_STREAM_PLAYBACK);
}

static char* sound_GetSoundRecorderDeviceName(int n)
{
	return nameOfNthDeviceOfType(n, SND_PCM_STREAM_CAPTURE);
}
#endif /* HARDWIRE_DEFAULT */

static void sound_SetDefaultSoundPlayer(char *deviceName)
{
	printf("sound_SetDefaultSoundPlayer(%s)\n", deviceName);
	// a.k.a. sound_SetDevice(1 /* playback */,deviceName);
	strncpy(sound_playback, deviceName, DEVICE_NAME_LEN);
}

static void sound_SetDefaultSoundRecorder(char *deviceName)
{
	printf("sound_SetDefaultSoundRecorder(%s)\n", deviceName);
	// a.k.a. sound_SetDevice(2 /* capture */,deviceName);
	strncpy(sound_capture, deviceName, DEVICE_NAME_LEN);
}

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


/* signal support */
/* At least up until version 1.0.22 libasound/ALSO is badly broken w.r.t. signal
 * handling.
 * The library as it is usually built (i.e. without SND_ASYNC_RT_SIGNAL)
 * installs a SIGIO signal handler as part of snd_async_add_handler and
 * uninstalls it as part of snd_async_del_handler.  Any previous handler
 * is ignored. There are two bugs here.
 *
 * 1. once snd_async_add_handler has been invoked any previous SIGIO handler
 * is not invoked.
 *
 * 2. the sequence of snd_async_add_handler followed by snd_async_del_handler
 * always restores SIGIO hanbdling to SIG_DLF which is to terminate the
 * program.  So if one has an X comnection open the program will exit after
 * snd_async_del_handler removes the last handler.
 *
 * There is an inadequate work-around implemented here to install the previous
 * handler ASAP.  But we prefer to build our own libasound with the issue fixed
 * in unixbuild/third-party/alsa-lib-1.0.17a/src/async.h.
 */
#if WORK_AROUND_BROKEN_LIBASOUND
static void *previous_sigio_handler= 0;

static void sigio_save(void)
{
  if (!previous_sigio_handler) {
	/* Discover the existing sigio handler before libasound installs its own
	 * so that we can restore it on unload/close.
	 */
    previous_sigio_handler= signal(SIGIO, SIG_IGN);
    signal(SIGIO, previous_sigio_handler);
  }
}

static void sigio_restore(void)
{ 
  if (previous_sigio_handler)
    signal(SIGIO, previous_sigio_handler);
}
#endif /* WORK_AROUND_BROKEN_LIBASOUND */


/* module */


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
#if WORK_AROUND_BROKEN_LIBASOUND
  sigio_save();
#endif
  return &sound_ALSA_itf;
}

SqModuleDefine(sound, ALSA);
