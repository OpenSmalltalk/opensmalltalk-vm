/* sqUnixSndioSound.c -- sound module for sndio sound system
 *
 * Last edited: 
 * 2019-12-11 by Christian Kellermann  <ckeen@pestilenz.org>
 *
 * This is a driver for the OpenBSD sndio sound drivers for Squeak.
 *
 */

#include "sq.h"
#include "sqaio.h"

#include <stdio.h>
#include <sndio.h>

#if defined (DEBUG)
#define trace() fprintf(stderr, "%s:%d %s\n", __FILE__, __LINE__, __FUNCTION__)
#else
#define trace() while(0){};
#endif

struct sio_hdl *snd;
struct sio_par par;
int opened = false;

/*** sound output ***/


static sqInt sound_AvailableSpace(void)
{
  trace();
  return  par.bufsz * par.bps * par.pchan;
}

static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)
{
  trace();
  return success(false);
}

static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)
{
  size_t bytes_played;
  trace();
  bytes_played = sio_write(snd, pointerForOop(arrayIndex) + startIndex * (par.bps * par.pchan), frameCount * par.bps * par.pchan);
  if (bytes_played < 0)
    return 0;
  return bytes_played / (par.bps * par.pchan);
}

static sqInt sound_PlaySilence(void)
{
  trace();
  return 8192;
}

static int semaphore = 0;

static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int channels = stereo + 1;

  trace();
  fprintf(stderr, "%ld frames, %ld samplesPerSec, %ld stereo, %ld semaIndex\n",
          frameCount,
          samplesPerSec,
          stereo,
          semaIndex);

  if (opened && snd){
    sio_close(snd);
    snd = NULL;
  }
  snd = sio_open(SIO_DEVANY, SIO_PLAY, 0); /* blocking */
  if (! snd) {
    fprintf(stderr, "Unable to open sound device!\n");
    return false;
  }
  opened = true;

  sio_initpar(&par);

  par.bps = 2; /* Always 2 bytes per sample */
  par.sig = 1;
  par.pchan = channels;
  par.le = 1;
  par.rate = samplesPerSec; /* that should be the same as frames per second(!?) */
  par.appbufsz = frameCount * 2 * channels;
  par.rchan = 0;
  par.xrun = SIO_SYNC;

  if (! sio_setpar(snd, &par)){
    fprintf(stderr, "Unable to set snd dev parameters\n");
    return false;
  }

  if (! sio_getpar(snd, &par)){
    fprintf(stderr, "Unable to set snd dev parameters\n");
    return false;
  }

  if (!sio_start(snd)) {
    fprintf(stderr, "Unable to set device into start mode\n");
    return false;
  }

  semaphore = semaIndex;

  return true;
}

sqInt sound_Stop(void){
  trace();
  if (opened) {
    if (!sio_stop(snd)){
      fprintf(stderr, "Unable to stop device\n");
      return false;
    }
    sio_close(snd); snd = NULL;
    opened = false;
  }

  return true;
}


/*** sound input ***/


sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  trace();
  return 0;
}

sqInt sound_StopRecording(void)
{
  trace();
  return 0;
}

double sound_GetRecordingSampleRate(void)
{
  trace();
  return 8192;
}

sqInt sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  trace();
  return 8192;
}

/*** sound mixer ***/

void sound_Volume(double *left, double *right)
{
  trace();
  *left= 1.0;
  *right= 1.0;
}

void sound_SetVolume(double left, double right)
{
  trace();
}

sqInt sound_SetRecordLevel(sqInt level)
{
  trace();
  return level;
}

sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)   { return success(true); }

sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter) { return success(true); }

sqInt sound_SetDevice(sqInt id, char *name)      { return success(true); }


#include "SqSound.h"

SqSoundDefine(sndio);				/* must match name in makeInterface() below */

#include "SqModule.h"

static void sound_parseEnvironment(void) {}

static int sound_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nosound")) return 1;
  return 0;
}

static void  sound_printUsage(void)		{}
static void  sound_printUsageNotes(void)	{}

static void *sound_makeInterface(void)
{
  return &sound_sndio_itf;			/* must match name in SqSoundDefine() above */
}

SqModuleDefine(sound, sndio);			/* must match name in sqUnixMain.c's moduleDescriptions */
