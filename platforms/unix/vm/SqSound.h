#ifndef __sq_SqSound_h
#define __sq_SqSound_h


#define SqSoundVersionMajor	1
#define SqSoundVersionMinor	1
#define SqSoundVersion		((SqSoundVersionMajor << 16) | (SqSoundVersionMinor))


struct SqSound
{
  int    version;
  /* output */
  int	 (*snd_AvailableSpace)(void);
  int	 (*snd_InsertSamplesFromLeadTime)(int frameCount, int srcBufPtr, int samplesOfLeadTime);
  int	 (*snd_PlaySamplesFromAtLength)(int frameCount, int arrayIndex, int startIndex);
  int	 (*snd_PlaySilence)(void);
  int	 (*snd_Start)(int frameCount, int samplesPerSec, int stereo, int semaIndex);
  int	 (*snd_Stop)(void);
  /* input */
  int	 (*snd_StartRecording)(int desiredSamplesPerSec, int stereo, int semaIndex);
  int	 (*snd_StopRecording)(void);
  double (*snd_GetRecordingSampleRate)(void);
  int	 (*snd_RecordSamplesIntoAtLength)(int buf, int startSliceIndex, int bufferSizeInBytes);
  /* mixer */
  void	 (*snd_Volume)(double *left, double *right);
  void	 (*snd_SetVolume)(double left, double right);
  int    (*snd_SetRecordLevel)(int level);
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
  sound_SetRecordLevel				\
}


#endif /* __sq_SqSound_h */
