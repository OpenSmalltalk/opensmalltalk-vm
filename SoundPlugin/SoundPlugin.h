/* SoundPlugin.h - header for Sound Plugins :-) tim@sumeru.stanford.edu */

/* module initialization/shutdown */
int soundInit(void);
int soundShutdown(void);

/* sound output */
int snd_AvailableSpace(void);
int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime);
int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex);
int snd_PlaySilence(void);
int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex);
int snd_Stop(void);

/* sound input */
int snd_SetRecordLevel(int level);
int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex);
int snd_StopRecording(void);
double snd_GetRecordingSampleRate(void);
int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes);
void snd_Volume(double *left, double *right); //johnmci@smalltalkconsulting.com Nov 6th 2000
void snd_SetVolume(double left, double right);//johnmci@smalltalkconsulting.com Nov 6th 2000
