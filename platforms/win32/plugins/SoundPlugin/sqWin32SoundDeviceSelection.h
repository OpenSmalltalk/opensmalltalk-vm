#ifndef __SQ_WIN32_SOUND_DEVICE_SELECTION_H__
#define __SQ_WIN32_SOUND_DEVICE_SELECTION_H__

#include <dsound.h>
#include <dsconf.h>

typedef struct {
	char *name;
	DWORD mmID;
	LPGUID guid;
} DeviceInfo;

#define DEVICE_MAX 24   /* How many devices can we handle? */
typedef struct {
	UINT deviceCount;
	BOOL changed;
	UINT enumerationCounter;
	DIRECTSOUNDDEVICE_DATAFLOW dataflow; /* recording or playback? */
	DeviceInfo defaultDevice;
	DeviceInfo devices[DEVICE_MAX];
} DeviceInfoList;

#ifdef __cplusplus
extern "C" {
#endif 

/* Given a DirectX device identified by "lpGUID", find the corresponding wave device ID and return it in "waveID" */
HRESULT GetWaveDeviceIDFromGUID(LPGUID lpGUID, DIRECTSOUNDDEVICE_DATAFLOW dataflowType, DWORD* waveID);

/* Given a DirectX device identified by "lpszDesc", find the corresponding wave device ID and return it in "waveID".
   This is a hack that we use because GetWaveDeviceIDFromGUID() only works for playback devices (not capture devices). */
HRESULT GetWaveDeviceIDFromName(LPCTSTR lpszDesc, DWORD* waveID);

#ifdef __cplusplus
} /* extern "C" { */
#endif 



#endif /* #ifndef __SQ_WIN32_SOUND_DEVICE_SELECTION_H__ */
