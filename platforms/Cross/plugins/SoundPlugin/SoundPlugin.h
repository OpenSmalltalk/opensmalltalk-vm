/* SoundPlugin.h - header for Sound Plugins :-) tim@sumeru.stanford.edu */

/* module initialization/shutdown */
sqInt soundInit(void);
sqInt soundShutdown(void);

/* sound output */
sqInt snd_AvailableSpace(void);
sqInt snd_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime);
sqInt snd_PlaySamplesFromAtLength(sqInt frameCount, void *srcBufPtr, sqInt startIndex);
sqInt snd_PlaySilence(void);
sqInt snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
sqInt snd_Stop(void);

/* sound input */
void snd_SetRecordLevel(sqInt level);
sqInt snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex);
sqInt snd_StopRecording(void);
double snd_GetRecordingSampleRate(void);
sqInt snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes);
void snd_Volume(double *left, double *right);  /* johnmci@smalltalkconsulting.com Nov 6th 2000 */
void snd_SetVolume(double left, double right); /* johnmci@smalltalkconsulting.com Nov 6th 2000 */

/* mixer interface */
sqInt snd_GetSwitch(sqInt identifier, sqInt captureFlag, sqInt channel);
sqInt snd_SetSwitch(sqInt identifier, sqInt captureFlag, sqInt parameter);
sqInt snd_SetDevice(sqInt identifier, char *name);

