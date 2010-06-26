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
int snd_GetRecordLevel(void);	// howard.stearns@qwaq.com October 24 2008
int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex);
int snd_StopRecording(void);
double snd_GetRecordingSampleRate(void);
int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes);
void snd_Volume(double *left, double *right); //johnmci@smalltalkconsulting.com Nov 6th 2000
void snd_SetVolume(double left, double right);//johnmci@smalltalkconsulting.com Nov 6th 2000
int snd_EnableAEC(int trueOrFalse); //josh.gargus@teleplace.com  March 23 2010
int snd_SupportsAEC(); //josh.gargus@teleplace.com  March 24 2010

int getNumberOfSoundPlayerDevices(void);	// howard.stearns@qwaq.com October 20 2008 ...
int getNumberOfSoundRecorderDevices(void);
char * getDefaultSoundPlayer(void);					
char * getDefaultSoundRecorder(void);
char * getSoundPlayerDeviceName(int i);
char * getSoundRecorderDeviceName(int i);
void setDefaultSoundPlayer(char *deviceName);	
void setDefaultSoundRecorder(char *deviceName);

/* mixer interface */
int snd_GetSwitch(int id, int captureFlag, int channel);
int snd_SetSwitch(int id, int captureFlag, int parameter);
int snd_SetDevice(int id, char *name);
