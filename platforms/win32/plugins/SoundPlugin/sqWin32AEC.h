#ifndef __SQ_WIN32_AEC_H__
#define __SQ_WIN32_AEC_H__

#ifdef __cplusplus
extern "C" {
#endif 


int aec_soundInit(void);
int aec_soundShutdown(void);
int aec_snd_StartRecording(int samplesPerSec, int stereo, int semaIndex);
int aec_snd_StopRecording(void);
int aec_snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes);
int aec_snd_GetRecordingSampleRate(void);

DWORD WINAPI aecRecThreadFunc(LPVOID ignored);

#ifdef __cplusplus
}; /* extern "C" { */
#endif 

#endif /* #ifndef __SQ_WIN32_AEC_H__ */
