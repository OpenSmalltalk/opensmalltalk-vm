/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCSound.c                                     */
/*  hook up to RiscOS sound stuff - eventually                            */
/**************************************************************************/

/* To recompile this reliably you will need    */
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */

#include "sq.h"
#include "SoundPlugin.h"


extern struct VirtualMachine * interpreterProxy;

/* module initialization/shutdown */
int soundInit(void) {
// anything to do ?
}

int soundShutdown(void) {
// anything to do?
	return 0;
}

/****************/
/* sound output */
/****************/

int snd_AvailableSpace(void) {

/*	Returns the number of bytes of available sound output buffer space.  This should be (frames*4) if the device is in stereo mode, or (frames*2) otherwise */
	return 0;
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime) {

/*	Insert a buffer's worth of sound samples into the currently playing
	buffer. Used to make a sound start playing as quickly as possible. The
	new sound is mixed with the previously buffered sampled. */
/*	Details: Unlike primitiveSoundPlaySamples, this primitive always starts
	with the first sample the given sample buffer. Its third argument
	specifies the number of samples past the estimated sound output buffer
	position the inserted sound should start. If successful, it returns the
	number of samples inserted. */
	return 0;
}

int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex) {
/*	Output a buffer's worth of sound samples. */
	return 0;
}

int snd_PlaySilence(void) {


/*	Output a buffer's worth of silence. Returns the number of sample frames played. */
	return 0;
}

int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex) {

/*	Start the double-buffered sound output with the given buffer size, sample rate, stereo flag and semaphore index. */
	interpreterProxy->primitiveFail();
	return null;
}

int snd_Stop(void) {

/*	Stop double-buffered sound output. */
}

/***************/
/* sound input */
/***************/


int snd_SetRecordLevel(int level) {;
	return null;
}

int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex) {
	return null;
}

int snd_StopRecording(void) {
	return null;
}

double snd_GetRecordingSampleRate(void) {
	return (double)1.0;
}

int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) {
	return null;
}

void snd_Volume(double *left, double *right) {
// used to GET the volume settings
}

void snd_SetVolume(double left, double right) {
// used to SET the volume settings
	interpreterProxy->primitiveFail();
}
