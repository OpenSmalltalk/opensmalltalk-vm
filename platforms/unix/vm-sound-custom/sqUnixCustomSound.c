/* sqUnixCustomSound.c -- sound module for custom sound system
 *
 * Last edited: 2005-04-06 05:44:40 by piumarta on pauillac.hpl.hp.com
 *
 * This is a template for creating your own sound drivers for Squeak:
 * 
 *   - copy the entire contents of this directory to some other name
 *   - rename this file to be something more appropriate
 *   - modify acinclude.m4, Makefile.in, and ../vm/sqUnixMain accordingly
 *   - implement all the stubs in this file that currently do nothing
 */

#include "sq.h"
#include "sqaio.h"

#include <stdio.h>


#define trace() fprintf(stderr, "%s:%d %s\n", __FILE__, __LINE__, __FUNCTION__)


/*** sound output ***/


static sqInt sound_AvailableSpace(void)
{
  trace();
  return 8192;
}

static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)
{
  trace();
  return frameCount;
}

static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)
{
  trace();
  return frameCount;
}

static sqInt sound_PlaySilence(void)
{
  trace();
  return 8192;
}

static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  trace();
  return true;
}

static sqInt sound_Stop(void)
{
  trace();
  return 0;
}


/*** sound input ***/


static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  trace();
  return 0;
}

static sqInt sound_StopRecording(void)
{
  trace();
  return 0;
}

static double sound_GetRecordingSampleRate(void)
{
  trace();
  return 8192;
}

static sqInt sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  trace();
  return 8192;
}

/*** sound mixer ***/

static void sound_Volume(double *left, double *right)
{
  trace();
  *left= 1.0;
  *right= 1.0;
}

static void sound_SetVolume(double left, double right)
{
  trace();
}

static sqInt sound_SetRecordLevel(sqInt level)
{
  trace();
  return level;
}


#include "SqSound.h"

SqSoundDefine(custom);				/* must match name in makeInterface() below */

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
  return &sound_custom_itf;			/* must match name in SqSoundDefine() above */
}

SqModuleDefine(sound, custom);			/* must match name in sqUnixMain.c's moduleDescriptions */
