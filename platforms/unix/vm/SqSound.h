#ifndef __sq_SqSound_h
#define __sq_SqSound_h


#define SqSoundVersionMajor	1
#define SqSoundVersionMinor	1
#define SqSoundVersion		((SqSoundVersionMajor << 16) | (SqSoundVersionMinor))


struct SqSound
{
  int    version;
  /* output */
  sqInt  (*snd_AvailableSpace)(void);
  sqInt  (*snd_InsertSamplesFromLeadTime)(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime);
  sqInt  (*snd_PlaySamplesFromAtLength)(sqInt frameCount, void *arrayIndex, sqInt startIndex);
  sqInt  (*snd_PlaySilence)(void);
  sqInt  (*snd_Start)(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
  sqInt  (*snd_Stop)(void);
  /* input */
  sqInt  (*snd_StartRecording)(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex);
  sqInt  (*snd_StopRecording)(void);
  double (*snd_GetRecordingSampleRate)(void);
  sqInt  (*snd_RecordSamplesIntoAtLength)(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes);
  /* mixer */
  void   (*snd_Volume)(double *left, double *right);
  void   (*snd_SetVolume)(double left, double right);
  void   (*snd_SetRecordLevel)(sqInt level);
  sqInt  (*snd_GetSwitch)(int id, int captureFlag, int channel);
  sqInt  (*snd_SetSwitch)(int id, int captureFlag, int parameter);
  sqInt  (*snd_SetDevice)(int id, char *name);
};


#define SqSoundDefine(NAME)			\
static struct SqSound sound_##NAME##_itf= {	\
  SqSoundVersion,				\
  sound_AvailableSpace,				\
  sound_InsertSamplesFromLeadTime,		\
  sound_PlaySamplesFromAtLength,		\
  sound_PlaySilence,				\
  sound_Start,					\
  sound_Stop,					\
  sound_StartRecording,				\
  sound_StopRecording,				\
  sound_GetRecordingSampleRate,			\
  sound_RecordSamplesIntoAtLength,		\
  sound_Volume,					\
  sound_SetVolume,				\
  sound_SetRecordLevel,				\
  sound_GetSwitch,				\
  sound_SetSwitch,				\
  sound_SetDevice				\
}


#endif /* __sq_SqSound_h */
