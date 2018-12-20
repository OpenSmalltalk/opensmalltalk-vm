/*
 *  sqMacUnixInterfaceSound.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 2/3/05.
 *
 */

 sqInt    sound_AvailableSpace(void);
  sqInt    sound_InsertSamplesFromLeadTime(sqInt frameCount, void* srcBufPtr, sqInt samplesOfLeadTime);
  sqInt    sound_PlaySamplesFromAtLength(sqInt frameCount, void* srcBufPtr, sqInt startIndex);
  sqInt    sound_PlaySilence(void);
  sqInt    sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
  sqInt    sound_Stop(void);
  /* input */
  sqInt    sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex);
  sqInt    sound_StopRecording(void);
  double sound_GetRecordingSampleRate(void);
  sqInt    sound_RecordSamplesIntoAtLength(void * buf, sqInt startSliceIndex, sqInt bufferSizeInBytes);
  /* mixer */
  void	 sound_Volume(double *left, double *right);
  void	 sound_SetVolume(double left, double right);
  sqInt    sound_SetRecordLevel(sqInt level);
