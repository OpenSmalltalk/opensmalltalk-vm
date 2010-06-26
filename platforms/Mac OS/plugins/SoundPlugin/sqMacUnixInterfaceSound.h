/*
 *  sqMacUnixInterfaceSound.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 2/3/05.
 *
 */

       char		*dpyPixels  = 0;
       int		 dpyPitch   = 0;
		int		noSoundMixer = 0;
  int    sound_AvailableSpace(void);
  int    sound_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime);
  int    sound_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex);
  int    sound_PlaySilence(void);
  int    sound_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex);
  int    sound_Stop(void);
  /* input */
  int    sound_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex);
  int    sound_StopRecording(void);
  double sound_GetRecordingSampleRate(void);
  int    sound_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes);
  /* mixer */
  void	 sound_Volume(double *left, double *right);
  void	 sound_SetVolume(double left, double right);
  int    sound_SetRecordLevel(int level);
