/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Sound.c
*   CONTENT: Sound management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Sound.c 786 2003-11-02 19:52:40Z andreasraab $
*
*   NOTES:   For now we're supporting both, the DirectSound and the win32
*            based interface. In the future we'll switch to DSound exclusively.
*
*   MODIFIED:
*			HRS = howard.stearns@qwaq.com October 24, 2008
*				device iteration and selection, and record level
*
*   TO-DO:
*
*****************************************************************************/

#define _CRT_SECURE_NO_WARNINGS /* eliminates msvc warnings for strcpy, fopen, etc. */
#include <Windows.h>
#include <ShlObj.h>  /* to use SHGetFolderPath to get preference directory. */
#include <mmsystem.h>
#include "sq.h"
#include "SoundPlugin.h"
#include "sqWin32SoundDeviceSelection.h"
#include "sqDSoundClassFactory.h"

#ifndef SQUEAK_BUILTIN_PLUGIN
/* This function is defined in the core VM, but since we're a standalone plugin, 
   we need to define it ourselves. */
void printLastError(TCHAR *prefix)
{ LPVOID lpMsgBuf;
  DWORD lastError;

  lastError = GetLastError();
  FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                (LPTSTR) &lpMsgBuf, 0, NULL );
  warnPrintf(TEXT("%s (%lu) -- %s\n"), prefix, lastError, (char *)lpMsgBuf);
  LocalFree( lpMsgBuf );
}
#endif

extern struct VirtualMachine *interpreterProxy;

#include "sqWin32DPRINTF.h"
#define XPRINT(x) /* nuthin' */
#if ENABLE_AEC
int AEC_SUPPORTED = 0;  // Is AEC supported on this platform.
int AEC_ENABLED = 1;
#else
# define AEC_SUPPORTED 0
# define AEC_ENABLED 0
# define aec_soundInit() 0
# define aec_soundShutdown() 0
# define aec_snd_StartRecording(sps, str, six) 0
# define aec_snd_StopRecording() 0
# define aec_snd_GetRecordingSampleRate() 0
# define aec_snd_RecordSamplesIntoAtLength(b, ssi, bsz) 0
#endif

#ifndef NO_SOUND

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* The new DirectSound based implementation of the sound primitives */
#define _LPCWAVEFORMATEX_DEFINED
#include <dsound.h>

#define mmFAILED(mm) ((mm) != MMSYSERR_NOERROR)

static HWND *theSTWindow = NULL; /* a reference to Squeak's main window */

LPDIRECTSOUND lpdSound = NULL;
LPDIRECTSOUNDBUFFER lpdPrimaryBuffer = NULL;
LPDIRECTSOUNDBUFFER lpdPlayBuffer = NULL;
WAVEFORMATEX waveOutFormat;
HANDLE hPlayEvent = NULL;
HANDLE hPlayThread = NULL;
int playBufferSize = 0;
int playBufferIndex = 0;
int playBufferAvailable = 0;
int playTerminate = 0;
int playSemaphore = -1;

LPDIRECTSOUNDCAPTURE lpdCapture = NULL;
LPDIRECTSOUNDCAPTUREBUFFER lpdRecBuffer = NULL;
WAVEFORMATEX waveInFormat;
HANDLE hRecEvent = NULL;
HANDLE hRecThread = NULL;
int recBufferFrameCount = 640;
/* For 16kHz 16-bit mono sound,this is 1280msecs */
const int totalRecBufferSize = 40960;
int recBufferSize = 0;
int recBufferReadPosition = 0;
int recBufferWritePosition = 0;
int recBufferAvailable = 0;
int recTerminate = 0;
int recSemaphore = -1;
int recSampleRate;
int recIsStereo;

/*******************************************************************************/
/* Default devices: Windows does not provide an API for this. 11/10/08 HRS ... */
/*******************************************************************************/

static FILE *deviceLogFile = NULL;

DeviceInfoList playerDevices;
DeviceInfoList recorderDevices;


static char GUIDString[128];
static char *
printGUID(LPGUID p) 
{ 
	if (!p) return "";
	sprintf(GUIDString, "{%lx, %x, %x, %x %x %x %x %x %x %x %x}@%p",
		p->Data1, p->Data2, p->Data3, p->Data4[0], p->Data4[1], p->Data4[2], p->Data4[3],
		p->Data4[4], p->Data4[5], p->Data4[6], p->Data4[7], p);
	return GUIDString;
}


static void
setDeviceName(DeviceInfo* device, LPCTSTR lpszDesc)
{
	/* Free existing name string, if any. */
	if (device->name) {
		free(device->name);
		device->name = NULL;
	}
	/* Support setting the string to NULL. */
	if (sizeof(lpszDesc[0]) == 1) {
		if (lpszDesc) {
			device->name = _strdup(lpszDesc);
			if (!device->name)
				DPRINTF(("ERROR: setDeviceName() cannot allocate space for name\n"));
		}
	}
	else if (lpszDesc) {
		int sz, n = wcslen(lpszDesc);
		if (!n)
			return;

		device->name = malloc((n + 1) * 4);
		if (!device->name) {
			DPRINTF(("ERROR: setDeviceName() cannot allocate space for name\n"));
			return;
		}
		sz = WideCharToMultiByte(CP_UTF8, 0,
								lpszDesc, n, device->name,
								(n + 1) * 4, NULL, NULL);
		if (sz != n)
			DPRINTF(("ERROR: setDeviceName WideCharToMultiByte converted unexpected number of characters\n"));
		/* remember to null terminate the string */
		device->name[min(sz,(n + 1) * 4 - 1)] = 0;
	}
}

static void
duplicateDeviceName(DeviceInfo* device, char *lpszDesc)
{
	/* Free existing name string, if any. */
	if (device->name) {
		free(device->name);
		device->name = NULL;
	}
	/* Support setting the string to NULL. */
	if (lpszDesc) {
		device->name = _strdup(lpszDesc);
		if (!device->name)
			DPRINTF(("ERROR: setDeviceName() cannot allocate space for name\n"));
	}
}

void
setDeviceGUID(DeviceInfo* device, LPGUID lpGUID)
{
	/* Free existing GUID, if any. */
	if (device->guid) {
		free(device->guid);
		device->guid = NULL;
	}
	/* Support setting the GUID-ptr to NULL. */
	if (!lpGUID)
		return;
	/* Instantiate a new GUID, and copy the old one into it. */
	device->guid = malloc(sizeof(GUID));
	if (!device->guid) {
		/* XXXXX: Not sure what implications this would have, nor how to handle it properly. */
		DPRINTF(("ERROR: setDeviceGUID() cannot allocate space for GUID\n"));
		return;
	}
	memcpy(device->guid, lpGUID, sizeof(GUID));
}

void
clearDeviceInfo(DeviceInfo* device)
{
	setDeviceName(device, NULL);
	setDeviceGUID(device, NULL);
	device->mmID = -1;
}

void
initializeDeviceInfoList(DeviceInfoList* list) 
{
	int i;
	list->deviceCount = list->enumerationCounter = 0;
	list->changed = FALSE;
	/* Just pick one... we'll explicitly assign one anyhow. */
	list->dataflow = DIRECTSOUNDDEVICE_DATAFLOW_RENDER;
	for (i=0; i < DEVICE_MAX; i++) {
		memset(&(list->devices[i]), 0, sizeof(DeviceInfo));
		list->devices[i].mmID = -1;
	}
	memset(&(list->defaultDevice), 0, sizeof(DeviceInfo));
	list->defaultDevice.mmID = -1;
}

void
shutdownDeviceInfoList(DeviceInfoList* list)
{
	int i;
	for (i=0; i < DEVICE_MAX; i++) {
		clearDeviceInfo(&list->devices[i]);
	}
	clearDeviceInfo(&list->defaultDevice);
}

/* Enumerator for use with DirectSound(Capture)Enumerate(). */
/*	UINT deviceCounter;
	BOOL changed;
	UINT deviceCount;
	char **deviceNames;
	UINT *deviceIDs;
	LPGUID *deviceGUIDs;
	GUID *deviceGUIDBuffers;
	UINT win32deviceCount;
	char **win32deviceNames;	
	*/
BOOL CALLBACK deviceEnumerationCallback(LPGUID lpGUID, LPCTSTR lpszDesc, LPCTSTR lpszDrvName, LPVOID lpContext)
{
	DeviceInfoList* deviceList = (DeviceInfoList*)lpContext;
	DeviceInfo* device;
	UINT index = deviceList->enumerationCounter;
	HRESULT hr;

	/* We can't handle any more devices. */
	if (index > DEVICE_MAX) return FALSE;

	/* No matter what happens from here on, we've "added" a device to the list. */
	deviceList->enumerationCounter++;

	/* Get the most-recent device-info at the current index. */
	device = &(deviceList->devices[index]);

	if (!device->guid && !lpGUID) {
		/* A NULL guid in our info can mean one of two things... either the DeviceInfo
		   represents the default device, or it is uninitialized.  We disambiguate by
		   testing the name... it will be either NULL or something like "Primary Device" */
		if (!device->name) {
			setDeviceName(device, lpszDesc);
			device->mmID = -1;
			deviceList->changed = TRUE;
		}
		return TRUE;
	}
	else if (device->guid && IsEqualGUID(device->guid, lpGUID)) {
		/* Same device, in the same position. We're done. */
		return TRUE;
	}
	
	/* The device at the current index didn't match, so we know the list has changed. */
	deviceList->changed = TRUE;

	/* Set device properties. */
	setDeviceName(device, lpszDesc);
	setDeviceGUID(device, lpGUID);

	/* For some reason, GetWaveDeviceIDFromGUID only works for playback devices.
	   Use workaround to obtain the ID from the device name */
	/* hr = GetWaveDeviceIDFromGUID(lpGUID, deviceList->dataflow, &(device->mmID));  */
	hr = GetWaveDeviceIDFromName(lpszDesc, &(device->mmID));

	if (FAILED(hr)) {
		DPRINTF(("ERROR: failed to obtain waveID from GUID: %s\n", printGUID(lpGUID)));
	}
	else {
		DPRINTF(("NEW DEVICE: %d   NAME: %s  GUID: %s\n", device->mmID, device->name, printGUID(lpGUID)));
	}
	return TRUE;
}


static void *aalloc(size_t s) /* Allocate our standard size array of, of CLEARED element size s. */
{
	void *p = calloc(DEVICE_MAX + 1, s);
	XPRINT(("	allocated %d @ %x\n", s, p));
	return p;
}


/* There are a few places where we ask for line info for, e.g., a speaker, but we would also accept headphones, digital, etc. */
/* Side-effects pmxl->dwComponentType */
MMRESULT flexMixerGetLineInfo(HMIXEROBJ hmxobj, LPMIXERLINE pmxl)
{
	MMRESULT mmResult = mixerGetLineInfo(hmxobj, pmxl, MIXER_OBJECTF_MIXER + MIXER_GETLINEINFOF_COMPONENTTYPE);

	if (mmResult != MIXERR_INVALLINE)
		return mmResult;
	/* Output devices */
	if (pmxl->dwComponentType == MIXERLINE_COMPONENTTYPE_DST_SPEAKERS)
		pmxl->dwComponentType = MIXERLINE_COMPONENTTYPE_DST_HEADPHONES;
	else if (pmxl->dwComponentType == MIXERLINE_COMPONENTTYPE_DST_HEADPHONES)
		pmxl->dwComponentType = MIXERLINE_COMPONENTTYPE_DST_MONITOR;
	else if (pmxl->dwComponentType == MIXERLINE_COMPONENTTYPE_DST_MONITOR)
		pmxl->dwComponentType = MIXERLINE_COMPONENTTYPE_DST_DIGITAL;
	/* Input devices */
	else if (pmxl->dwComponentType == MIXERLINE_COMPONENTTYPE_DST_WAVEIN)
		pmxl->dwComponentType = MIXERLINE_COMPONENTTYPE_DST_LINE;
	else if (pmxl->dwComponentType == MIXERLINE_COMPONENTTYPE_DST_LINE)
		pmxl->dwComponentType = MIXERLINE_COMPONENTTYPE_DST_VOICEIN;
	else
		return mmResult;
	/* Now try again. */
	return flexMixerGetLineInfo(hmxobj, pmxl);
}

	
sqInt
getNumberOfSoundPlayerDevices()
{
	UINT counter;
	HRESULT hr;
	playerDevices.changed = false;
	playerDevices.enumerationCounter = 0;
	hr = DirectSoundEnumerate((LPDSENUMCALLBACK)deviceEnumerationCallback, (VOID*)&playerDevices);
	if (FAILED(hr)) {
		DPRINTF(("player enumeration failed\n"));
		return 0;
	}
	DPRINTF(("player enumeration complete\n"));
	for (counter=playerDevices.enumerationCounter; counter < playerDevices.deviceCount; counter++) {  /* Free excess if the there are now fewer devices. */
		DeviceInfo* device = &(playerDevices.devices[counter]);
		DPRINTF(("player changed in post-enumeration\n"));
		playerDevices.changed = true;
		clearDeviceInfo(device);
		DPRINTF(("	free %d\n", counter));
	}
	playerDevices.deviceCount = playerDevices.enumerationCounter;

	if (playerDevices.changed) {
		char* deviceName = playerDevices.defaultDevice.name;
		if (!deviceName) deviceName = "NULL";
		DPRINTF(("player devices changed... setting default device: %s\n", deviceName));
		setDefaultSoundPlayer(deviceName);
	}
	if (recorderDevices.changed) {
		char* deviceName = recorderDevices.defaultDevice.name;
		if (!deviceName) deviceName = "NULL";
		DPRINTF(("recorder devices changed... setting default device: %s\n", deviceName));
		setDefaultSoundRecorder(deviceName);
	}

	return playerDevices.deviceCount;
}

sqInt
getNumberOfSoundRecorderDevices()
{
	UINT counter;
	HRESULT hr;
	recorderDevices.changed = false;
	recorderDevices.enumerationCounter = 0;
	hr = DirectSoundCaptureEnumerate((LPDSENUMCALLBACK)deviceEnumerationCallback, (VOID*)&recorderDevices);
	if (FAILED(hr)) {
		DPRINTF(("recorder enumeration failed\n"));
		return 0;
	}
	DPRINTF(("recorder enumeration complete\n"));
	for (counter=recorderDevices.enumerationCounter; counter < recorderDevices.deviceCount; counter++) {  /* Free excess if the there are now fewer devices. */
		DeviceInfo* device = &(recorderDevices.devices[counter]);
		recorderDevices.changed = true;
		clearDeviceInfo(device);
		DPRINTF(("	free %d\n", counter));
	}
	recorderDevices.deviceCount = recorderDevices.enumerationCounter;

	if (playerDevices.changed) {
		char* deviceName = playerDevices.defaultDevice.name;
		if (!deviceName) deviceName = "NULL";
		DPRINTF(("player devices changed... setting default device: %s\n", deviceName));
		setDefaultSoundPlayer(deviceName);
	}
	if (recorderDevices.changed) {
		char* deviceName = recorderDevices.defaultDevice.name;
		if (!deviceName) deviceName = "NULL";
		DPRINTF(("recorder devices changed... setting default device: %s\n", deviceName));
		setDefaultSoundRecorder(deviceName);
	}
	return recorderDevices.deviceCount;
}

char *
getSoundPlayerDeviceName(sqInt index)
{
	if (!playerDevices.deviceCount)
		getNumberOfSoundPlayerDevices();
	return (unsigned)index < playerDevices.deviceCount
			? playerDevices.devices[index].name
			: (char *)0;
} 

char *
getSoundRecorderDeviceName(sqInt index)
{
	if (!recorderDevices.deviceCount)
		getNumberOfSoundRecorderDevices();
	return (unsigned)index < recorderDevices.deviceCount
			? recorderDevices.devices[index].name
			: (char *)0;
} 

void
logDeviceNames(void);

void
setDefaultSoundPlayer(char *deviceName)
{
	int counter, max;
	if (!deviceName) return;
	max = getNumberOfSoundPlayerDevices();	/* ensures fresh data */
	for (counter=0; counter<max; counter++) {
		DeviceInfo* device = &(playerDevices.devices[counter]);
		if (!strcmp(device->name, deviceName)) {
			DPRINTF(("setDefaultSoundPlayer('%s')\n", deviceName));
			duplicateDeviceName(&playerDevices.defaultDevice, device->name);
			setDeviceGUID(&playerDevices.defaultDevice, device->guid);
			playerDevices.defaultDevice.mmID = device->mmID;
			return;
		}
	}
	DPRINTF(("Unable to setDefaultSoundPlayer('%s')\n", deviceName));
	clearDeviceInfo(&playerDevices.defaultDevice);
	return;
} 

void
setDefaultSoundRecorder(char *deviceName)
{
	int counter, max;
	if (!deviceName) return;
	max = getNumberOfSoundRecorderDevices(); /* ensures fresh data */
	for (counter=0; counter<max; counter++) {
		DeviceInfo* device = &(recorderDevices.devices[counter]);
		if (!strcmp(device->name, deviceName)) {
			DPRINTF(("setDefaultSoundRecorder('%s')\n", deviceName));
			duplicateDeviceName(&recorderDevices.defaultDevice, device->name);
			setDeviceGUID(&recorderDevices.defaultDevice, device->guid);
			recorderDevices.defaultDevice.mmID = device->mmID;
			return;
		}
	}
	DPRINTF(("unable to setDefaultSoundRecorder('%s')\n", deviceName));
	clearDeviceInfo(&recorderDevices.defaultDevice);
} 

char *
getDefaultSoundPlayer()
{
	if (playerDevices.defaultDevice.name) {
		// Force enumeration to verify that default device is still available.
		getNumberOfSoundPlayerDevices();
	}
	return playerDevices.defaultDevice.name;
}

char *
getDefaultSoundRecorder()
{
	if (recorderDevices.defaultDevice.name) {
		// Force enumeration to verify that default device is still available.
		getNumberOfSoundRecorderDevices();
	}
	return recorderDevices.defaultDevice.name;
}

/* For debugging a system: opens a log file and records all the names of devices seen by DirectX and by win32. */

#if 0
/* As of this writing (June 2008) MinGW doesn't support SHGetFolderPath(), requiring the old-style LoadLibrary(). */
static HRESULT (__stdcall *shGetFolderPath)(HWND, int, HANDLE, DWORD, CHAR*);
#endif
static char logName[MAX_PATH];

void 
logDeviceNames()
{
	HRESULT hres;
	DeviceInfo* defaultPlayer = &playerDevices.defaultDevice;
	DeviceInfo* defaultRecorder = &recorderDevices.defaultDevice;
	int i;

#if 0
	if (!shGetFolderPath) {
		DPRINTF(("GetFolderPath dynamic lookup\n"));
		shGetFolderPath = (void*)GetProcAddress(LoadLibrary("SHFolder.dll"), "SHGetFolderPathA");
		hres = shGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, logName); 

		DPRINTF(("func@%lx, result=%x, (E_INVALIDARG=%x), logName='%s'\n", shGetFolderPath, hres, E_INVALIDARG, logName));
		if (logName[strlen(logName)-1] != '\\') strcat(logName, "\\");
		strcat(logName, "QwaqCroquet\\logs\\device.log");
	}
#endif

	DPRINTF(("logDeviceNames() to '%s'\n", logName[0] ? logName : stdout));

	deviceLogFile = logName[0]
						? fopen(logName, "wt")
						: stdout;
	if (!deviceLogFile) {
		DPRINTF(("Could not open '%s' (code %x)\n", logName, errno));
		return;
	}

	DPRINTF(("writing log file to '%s'\n", logName));

	getNumberOfSoundPlayerDevices(); 
	getNumberOfSoundRecorderDevices();
	fprintf(deviceLogFile, "Input devices: %d Output devices: %d\n",
			recorderDevices.deviceCount, playerDevices.deviceCount);

	fprintf(deviceLogFile, "Input (recording) devices:\n");
	fprintf(deviceLogFile, "default %p: %s'%s'\n", defaultRecorder->guid, printGUID(defaultRecorder->guid), defaultRecorder->name);
	for (i = 0; i < recorderDevices.deviceCount; i++)
		fprintf(deviceLogFile, "device %d: %s'%s'\n", i,
				printGUID(recorderDevices.devices[i].guid),
				recorderDevices.devices[i].name);

	fprintf(deviceLogFile, "\nOutput (playing) devices:\n");
	fprintf(deviceLogFile, "default %p: %s '%s' \n", defaultPlayer->guid, printGUID(defaultPlayer->guid), defaultPlayer->name);
	for (i = 0; i < playerDevices.deviceCount; i++)
		fprintf(deviceLogFile, "device %d: %s'%s'\n", i,
				printGUID(playerDevices.devices[i].guid),
				playerDevices.devices[i].name);

	fprintf(deviceLogFile, "using direct sound %d, use direct sound %d, sound %p, capture %p\n", 
		1, 1, lpdSound, lpdCapture);

	fclose(deviceLogFile);

	deviceLogFile = NULL;

	DPRINTF(("logDeviceNames() complete\n"));
}


static double
closeDevs(HMIXER hmx, HWAVEIN hwaveIn, HWAVEOUT hwaveOut)
{ 
	if (!!hmx) mixerClose(hmx); 
	if (!!hwaveIn) waveInClose(hwaveIn);
	if (!!hwaveOut) waveOutClose(hwaveOut);
	return -1.0; 
}


/*	Answers the volume (as a double [0, 1]) of the first line of deviceID that has the specified lineType.
	If inLevel is between [0, 1], sets the volume before reading it. 
	A negative deviceID means to use the default waveIn/Out device (based on lineType arg). */
double
accessMixerVolume(UINT deviceID, DWORD lineType, double inLevel) 
{
	double outLevel;
	UINT v;
	
	MMRESULT result;
	HMIXER hmx = NULL;

	MIXERLINE mmLine;

	MIXERLINECONTROLS mmControls;
	MIXERCONTROL mmControl[1];  /* That ought to be enough. :-) */
	MIXERCONTROLDETAILS_UNSIGNED mmValue[4]; /* Up to four channels. */
	MIXERCONTROLDETAILS mmDetails;	

	/* For default devices, use wave. */
	HWAVEIN hwaveIn = NULL; HWAVEOUT hwaveOut = NULL;
	WAVEFORMATEX wfx;
	int bytesPerSample, bytesPerFrame, desiredSamplesPerSec;

	DPRINTF(("accessMixerVolume(id:%u, type:%x, level:%g) \n", deviceID, lineType, inLevel));

	if ((int)deviceID < 0) {
		/* Make up some data. */
		bytesPerSample = 2;
		bytesPerFrame = bytesPerSample;
		desiredSamplesPerSec = 44100;
		wfx.wFormatTag = WAVE_FORMAT_PCM;
		wfx.nChannels = 1;
		wfx.nSamplesPerSec = desiredSamplesPerSec;
		wfx.nAvgBytesPerSec = desiredSamplesPerSec * bytesPerFrame;
		wfx.nBlockAlign = bytesPerFrame;
		wfx.wBitsPerSample = 8 * bytesPerSample;

		if (lineType == MIXERLINE_COMPONENTTYPE_DST_WAVEIN) {
			result = waveInOpen(&hwaveIn, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL);
			DPRINTF(("	waveInOpen=>%d (BADFORMAT=%d, BADFLAG=%d), hwave=%lx\n", result, WAVERR_BADFORMAT, MMSYSERR_INVALFLAG, hwaveIn));
			if (mmFAILED(result)) return -1;
			result = mixerOpen(&hmx, (UINT) hwaveIn, 0, 0, MIXER_OBJECTF_HWAVEIN);
		} else {
			result = waveOutOpen(&hwaveOut, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL);
			DPRINTF(("	waveInOpen=>%d (BADFORMAT=%d, BADFLAG=%d), hwave=%lx\n", result, WAVERR_BADFORMAT, MMSYSERR_INVALFLAG, hwaveOut));
			if (mmFAILED(result)) return -1;
			result = mixerOpen(&hmx, (UINT) hwaveOut, 0, 0, MIXER_OBJECTF_HWAVEOUT);
		}
	} else {
		result = mixerOpen(&hmx, deviceID, 0, 0, MIXER_OBJECTF_MIXER);
	}
	XPRINT(("	mixerOpen=>%x (BADDEVICEID=%d), handle=%lx\n", result, MMSYSERR_BADDEVICEID, hmx));
	if (mmFAILED(result)) {
		DPRINTF(("accessMixerVolume(): failed to open mixer device (error code: %d)\n", result));
		return closeDevs(hmx, hwaveIn, hwaveOut);
	}
	/* Find the right line on this device. */
	mmLine.cbStruct = sizeof(MIXERLINE);
	mmLine.dwComponentType = lineType;

	result = flexMixerGetLineInfo((HMIXEROBJ) hmx, &mmLine);
	XPRINT(("	mixerGetLineInfo=>%x, source %u, destinatation %u, type %x, %d channels, %d controls\n", result, 
			mmLine.dwSource,  mmLine.dwDestination, mmLine.dwComponentType, mmLine.cChannels, mmLine.cControls));
	if (mmFAILED(result)) {
		DPRINTF(("accessMixerVolume(): failed to get line info (error code: %d)\n", result));
		return closeDevs(hmx, hwaveIn, hwaveOut);
	}

	/* Find the volume control */
	mmControls.cbStruct = sizeof(MIXERLINECONTROLS);
	mmControls.cControls = 1;
	mmControls.dwLineID = mmLine.dwDestination;
	mmControls.cbmxctrl = sizeof(MIXERCONTROL);
	mmControls.dwControlType = MIXERCONTROL_CONTROLTYPE_VOLUME;
	mmControls.pamxctrl = mmControl;
	result = mixerGetLineControls((HMIXEROBJ) hmx, &mmControls, MIXER_OBJECTF_HMIXER | MIXER_GETLINECONTROLSF_ONEBYTYPE);
	XPRINT(("	mixerGetLineControls(any volume control)=>%x, min=%u, max=%u for control %u\n", 
			result, mmControl[0].Bounds.dwMinimum, mmControl[0].Bounds.dwMaximum, mmControl[0].dwControlID));
	if (mmFAILED(result)) {
		DPRINTF(("accessMixerVolume(): failed to get line controls (error code: %d)\n", result));
		return closeDevs(hmx, hwaveIn, hwaveOut);
	}

	/* access the control */
	mmDetails.paDetails = mmValue;
	mmDetails.dwControlID = mmControl[0].dwControlID;
	mmDetails.cChannels = 1; /* Get set all channels as if they were uniform, rather than individually with mmLine.cChannels */
	mmDetails.cbStruct = sizeof(MIXERCONTROLDETAILS);
	mmDetails.cbDetails = sizeof(MIXERCONTROLDETAILS_UNSIGNED) /** mmLine.cChannels*/;
	mmDetails.cMultipleItems = 0;
	if (inLevel < 0) {
		result = mixerGetControlDetails((HMIXEROBJ) hmx, &mmDetails, MIXER_OBJECTF_HMIXER | MIXER_GETCONTROLDETAILSF_VALUE);
		XPRINT(("	got result=%x, val=%x\n", result, mmValue[0].dwValue));
	} else {
		v = (mmControl[0].Bounds.dwMaximum - mmControl[0].Bounds.dwMinimum);
		v = (UINT) (v * inLevel);
		v += mmControl[0].Bounds.dwMinimum;
		mmValue[0].dwValue = v;
		result = mixerSetControlDetails((HMIXEROBJ) hmx, &mmDetails, MIXER_OBJECTF_HMIXER | MIXER_SETCONTROLDETAILSF_VALUE);
		XPRINT(("	set %x, result=%x, val=%x\n", v, result, mmValue[0].dwValue));
	}
	if (mmFAILED(result)) {
		DPRINTF(("accessMixerVolume(): failed to get or set line control details (error code: %d)\n", result));
		return closeDevs(hmx, hwaveIn, hwaveOut);
	}
	outLevel = ((double) mmValue[0].dwValue - mmControl[0].Bounds.dwMinimum) / (mmControl[0].Bounds.dwMaximum - mmControl[0].Bounds.dwMinimum);
	closeDevs(hmx, hwaveIn, hwaveOut);
	return outLevel;
}

sqInt
dx_snd_SetRecordLevel(sqInt level) 
{ return 1000.0L * accessMixerVolume(recorderDevices.defaultDevice.mmID, MIXERLINE_COMPONENTTYPE_DST_WAVEIN, level / 1000.0L); }

int
snd_GetRecordLevel() 
{ return 1000.0L * accessMixerVolume(recorderDevices.defaultDevice.mmID, MIXERLINE_COMPONENTTYPE_DST_WAVEIN, -1.0); }

void
dx_snd_SetVolume(double left, double right)
{ accessMixerVolume(playerDevices.defaultDevice.mmID, MIXERLINE_COMPONENTTYPE_DST_SPEAKERS, (left>right)?left:right); }

void
dx_snd_Volume(double *left, double *right)
{
	*left = accessMixerVolume(playerDevices.defaultDevice.mmID, MIXERLINE_COMPONENTTYPE_DST_SPEAKERS, -1.0);
	*right = *left;
}

/**************************************/
/* End of default device stuff by HRS */
/**************************************/

/* module initialization/shutdown */
sqInt
dx_soundInit(void) {
  initializeDeviceInfoList(&playerDevices);
  initializeDeviceInfoList(&recorderDevices);
  playerDevices.dataflow = DIRECTSOUNDDEVICE_DATAFLOW_RENDER;
  recorderDevices.dataflow = DIRECTSOUNDDEVICE_DATAFLOW_CAPTURE;

  theSTWindow = (HWND*) interpreterProxy->ioLoadFunctionFrom("stWindow","");
  if (!theSTWindow) {
    DPRINTF(("ERROR: Failed to look up stWindow\n"));
    return 0;
  }

  if (!dsound_InitClassFactory()) {
	  return 0;
  }

  hRecEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  hPlayEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  return 1;
}

sqInt dx_snd_StopPlaying(void);
sqInt dx_snd_StopRecording(void);

sqInt
dx_soundShutdown(void) {
  DPRINTF(("dx_soundShutDown\n"));
  dx_snd_StopPlaying();
  dx_snd_StopRecording();
  dsound_ShutdownClassFactory();
  CloseHandle(hPlayEvent);
  CloseHandle(hRecEvent);
  shutdownDeviceInfoList(&playerDevices);
  shutdownDeviceInfoList(&recorderDevices);
  return 1;
}

sqInt
dx_snd_StopPlaying(void) {
  playTerminate = 0;
  if (lpdPlayBuffer) {
    DPRINTF(("Shutting down DSound\n"));
    IDirectSoundBuffer_Stop(lpdPlayBuffer);
    IDirectSoundBuffer_Release(lpdPlayBuffer);
    lpdPlayBuffer = NULL;
  }
  if (lpdPrimaryBuffer) {
    IDirectSoundBuffer_Release(lpdPrimaryBuffer);
    lpdPrimaryBuffer = NULL;
  }
  if (lpdSound) {
    IDirectSound_Release(lpdSound);
    lpdSound = NULL;
  }
  if (hPlayThread) {
    ResetEvent(hPlayEvent);
    playTerminate = 1;
    SetEvent(hPlayEvent);
    WaitForSingleObject(hPlayThread, 100); /* wait until terminated */
    hPlayThread = NULL;
    playTerminate = 0;
  }
  ResetEvent(hPlayEvent);
  return 1;
}

DWORD WINAPI playCallback( LPVOID ignored ) {
  while (1) {
    if (WaitForSingleObject(hPlayEvent, INFINITE) == WAIT_OBJECT_0) {
      if (playTerminate) {
        hPlayThread = NULL;
        DPRINTF(("playCallback shutdown\n"));
        dx_snd_StopPlaying();
        return 0; /* done playing */
      }
      playBufferAvailable = 1;
      playBufferIndex = ++playBufferIndex & 1;
      interpreterProxy->signalSemaphoreWithIndex(playSemaphore);
    }
  }
}

DWORD WINAPI dxRecCallback( LPVOID ignored ) {
  while (1) {
    if (WaitForSingleObject(hRecEvent, INFINITE) == WAIT_OBJECT_0) {
      if (recTerminate) return 0; /* done playing */
	  recBufferWritePosition = (recBufferWritePosition + recBufferSize) % totalRecBufferSize; 
	  recBufferAvailable += recBufferSize;
	  if (recBufferAvailable >= totalRecBufferSize) {
	    /* Keep the read position always one buffer ahead of the write position.
	       Otherwise we end up having race conditions when reading the buffer
	       that is currently being written to. */
	    recBufferReadPosition = (recBufferWritePosition+recBufferSize)  % totalRecBufferSize;;
	    recBufferAvailable = totalRecBufferSize - recBufferSize;
	  }
      interpreterProxy->signalSemaphoreWithIndex(recSemaphore);
    }
  }
}


/* sound output */
sqInt
dx_snd_AvailableSpace(void) { return playBufferAvailable ? playBufferSize : 0; }

sqInt
dx_snd_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime)
{
  /* currently not supported */
  return 0;
}

sqInt
dx_snd_PlaySamplesFromAtLength(sqInt frameCount, void *arrayIndex, sqInt startIndex)
{
  HRESULT hRes;
  int bytesWritten;
  DWORD dstLen;
  void *dstPtr;

  bytesWritten = waveOutFormat.nBlockAlign  * frameCount;

  if (bytesWritten > playBufferSize)
    bytesWritten = playBufferSize;

  if (bytesWritten < playBufferSize)
    return 0;

  DPRINTF(("[%d", frameCount));

  hRes = IDirectSoundBuffer_Lock(lpdPlayBuffer, 
				 playBufferSize * playBufferIndex,
				 playBufferSize, 
				 &dstPtr, &dstLen, 
				 NULL, NULL, 
				 0);
  if (FAILED(hRes)) {
    DPRINTF(("snd_Play: IDirectSoundBuffer_Lock failed (errCode: %x)\n", hRes));
    return 0;
  }
  /* mix in stuff */
  { 
    DWORD i;
    short *shortSrc = (short*)((char *)arrayIndex+startIndex);
    short *shortDst = (short*)dstPtr;
    dstLen /= 2;
    DPRINTF(("|%d", dstLen));
    for (i=0;i<dstLen;i++)
      *shortDst++ = *(shortSrc++);
  }
  IDirectSoundBuffer_Unlock(lpdPlayBuffer, dstPtr, dstLen, NULL, 0);
  DPRINTF(("]"));
  playBufferAvailable = 0;
  return bytesWritten / waveOutFormat.nBlockAlign;
}

sqInt
dx_snd_PlaySilence(void) { /* no longer supported */ return -1; }

sqInt
dx_snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex) {
  DSBUFFERDESC dsbd;
  DSBPOSITIONNOTIFY  posNotify[2];
  LPDIRECTSOUNDNOTIFY lpdNotify = NULL;
  HRESULT hRes;
  DWORD threadID;
  int bytesPerFrame;
  int bufferSize;

  /* round up the size of the play buffers to multiple of 16 bytes*/
  bytesPerFrame = stereo ? 4 : 2;
  bufferSize = ((bytesPerFrame * frameCount + 15) / 16) * 16;
  if ((bufferSize != playBufferSize) || 
     (samplesPerSec != waveOutFormat.nSamplesPerSec) || 
     ((stereo == 0) != (waveOutFormat.nChannels == 1))) {
    /* format change */
    DPRINTF(("DXSound format change (%d, %d, %s)\n", frameCount, samplesPerSec, (stereo ? "stereo" : "mono")));
    dx_snd_StopPlaying();
  }

  if (lpdPlayBuffer) {
    /* keep playing */
    playTerminate = 0;
    playSemaphore = semaIndex; /* might have changed */
    DPRINTF(("Continuing DSound\n"));
    return 1;
  }
 
  DPRINTF(("Starting DSound\n"));
   if (!lpdSound) {
    /* Initialize DirectSound */
    DPRINTF(("# Creating lpdSound\n"));
    hRes = CoCreateInstance(&CLSID_DirectSound,
			    NULL, 
			    CLSCTX_INPROC_SERVER,
			    &IID_IDirectSound,
			    (void**)&lpdSound);
    if (FAILED(hRes)) { return 0; }
    DPRINTF(("# Initializing lpdSound\n"));
    hRes = IDirectSound_Initialize(lpdSound, playerDevices.defaultDevice.guid);
    if (FAILED(hRes)) { return 0; }
    /* set the cooperative level (DSSCL_PRIORITY is recommended) */
    hRes = IDirectSound_SetCooperativeLevel(lpdSound, *theSTWindow, DSSCL_PRIORITY);
    if (FAILED(hRes)) {
      DPRINTF(("sndStart: IDirectSound_SetCooperativeLevel failed (errCode: %x)\n", hRes));
      /* for now don't fail because of lack in cooperation */
    }
    /* grab the primary sound buffer for handling format changes */
    ZeroMemory(&dsbd, sizeof(dsbd));
    dsbd.dwSize = sizeof(dsbd);
    dsbd.dwFlags = DSBCAPS_PRIMARYBUFFER;
    DPRINTF(("# Creating primary buffer\n"));
    hRes = IDirectSound_CreateSoundBuffer(lpdSound, &dsbd, &lpdPrimaryBuffer, NULL);
    if (FAILED(hRes)) {
      DPRINTF(("sndStart: Failed to create primary buffer (errCode: %x)\n", hRes));
    }
  }

  playSemaphore = semaIndex;

  if (!hPlayThread) {
    /* create the playback notification thread */
    DPRINTF(("# Creating playback thread\n"));
    hPlayThread = CreateThread(NULL, 128*1024, playCallback, NULL, 
			       STACK_SIZE_PARAM_IS_A_RESERVATION, &threadID);
    if (hPlayThread == 0) { return 0; }
	if (!SetThreadPriority(hPlayThread, THREAD_PRIORITY_HIGHEST)) 
      printLastError(TEXT("SetThreadPriority() failed"));
  }

  /* since we start from buffer 0 the first play index is one */
  playBufferIndex = 1; 

  /* round up the size of the play buffers to multiple of 16 bytes*/
  bytesPerFrame = stereo ? 4 : 2;
  playBufferSize = ((bytesPerFrame * frameCount + 15) / 16) * 16;

  /* create the secondary sound buffer */
  dsbd.dwSize = sizeof(dsbd);
  dsbd.dwFlags = 
    DSBCAPS_CTRLPOSITIONNOTIFY |   /* position notification */
    DSBCAPS_GETCURRENTPOSITION2 |  /* accurate positioning */
    DSBCAPS_LOCSOFTWARE |          /* software buffers please */
    DSBCAPS_GLOBALFOCUS;           /* continue playing */
  dsbd.dwBufferBytes = 2 * playBufferSize;
  dsbd.dwReserved = 0;
    waveOutFormat.wFormatTag = WAVE_FORMAT_PCM;
    waveOutFormat.nChannels = stereo ? 2 : 1;
    waveOutFormat.nSamplesPerSec = samplesPerSec;
    waveOutFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
    waveOutFormat.nBlockAlign = bytesPerFrame;
    waveOutFormat.wBitsPerSample = 16;
  dsbd.lpwfxFormat = &waveOutFormat;

  /* set the primary buffer format */
  if (lpdPrimaryBuffer) {
    hRes = IDirectSoundBuffer_SetFormat(lpdPrimaryBuffer, &waveOutFormat);
    if (FAILED(hRes)) {
      DPRINTF(("sndStart: Failed to set primary buffer format (errCode: %x)\n", hRes));
    }
  }

  DPRINTF(("# Creating play buffer\n"));
  hRes = IDirectSound_CreateSoundBuffer(lpdSound, &dsbd, &lpdPlayBuffer, NULL);
  if (FAILED(hRes)) { return 0; }

  /* setup notifications */
  hRes = IDirectSoundBuffer_QueryInterface(lpdPlayBuffer,
					   &IID_IDirectSoundNotify, 
					   (void**)&lpdNotify );
  if (FAILED(hRes)) { return 0; }
  posNotify[0].dwOffset = 1 * playBufferSize - 1;
  posNotify[1].dwOffset = 2 * playBufferSize - 1;
  posNotify[0].hEventNotify = hPlayEvent;
  posNotify[1].hEventNotify = hPlayEvent;
  DPRINTF(("# Setting notifications\n"));
  hRes = IDirectSoundNotify_SetNotificationPositions(lpdNotify, 2, posNotify);
  IDirectSoundNotify_Release(lpdNotify);
  if (FAILED(hRes)) { return 0; }

  DPRINTF(("# Starting to play buffer\n"));
  hRes = IDirectSoundBuffer_Play(lpdPlayBuffer, 0, 0, DSBPLAY_LOOPING);
  if (FAILED(hRes)) { return 0; }
  return 1;
}

sqInt
dx_snd_Stop(void) { dx_snd_StopPlaying(); return 1; }

/* sound input */

sqInt
dx_snd_StartRecording(sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
	DSCBUFFERDESC dscb;
	DSCCAPS dsccaps;
	DSBPOSITIONNOTIFY  posNotify[32]; /* see 'numNotificationPoints' below */
	LPDIRECTSOUNDNOTIFY lpdNotify = NULL;
	HRESULT hRes;
	DWORD threadID;
	int bytesPerFrame;
	int i; /* loop index */
	/* 'Notification Points' tell DirectSound when to call a callback to notify us that sound has been recorded.*/
	int numNotificationPoints;

	// Stash these in case we need to stop and restart recording with the
	// same parameters as requested this time.
	recSampleRate = samplesPerSec;
	recIsStereo = stereo;
	recSemaphore = semaIndex;

	if (lpdRecBuffer) {
		snd_StopRecording();
	}

	DPRINTF(("snd_StartRec: beginning DirectSound audio capture\n"));
	DPRINTF(("\tsamplingRate: %d   stereo: %d   sem-index: %d\n", samplesPerSec, stereo, semaIndex));

	if (!lpdCapture) {
		hRes = CoCreateInstance(&CLSID_DirectSoundCapture8,
			NULL, 
			CLSCTX_INPROC_SERVER,
			&IID_IDirectSoundCapture,
			(void**)&lpdCapture);
		if (FAILED(hRes)) {
			DPRINTF(("snd_StartRec: CoCreateInstance() failed (errCode: %x)\n", hRes));
			return 0;
		}
		if (!recorderDevices.defaultDevice.guid) {
			// Just to let us know; it will still work if the GUID is NULL.
			DPRINTF(("snd_StartRec: default GUID is NULL (just FYI)\n"));
		}
		hRes = IDirectSoundCapture_Initialize(lpdCapture, recorderDevices.defaultDevice.guid);
		if (FAILED(hRes)) {
			DPRINTF(("snd_StartRec: IDirectSoundCapture_Initialize() failed (errCode: %x)\n", hRes));
			lpdCapture = NULL;
			return 0;
		}
	}

	dsccaps.dwSize = sizeof(dsccaps);
	hRes = IDirectSoundCapture_GetCaps(lpdCapture, &dsccaps);
	if (FAILED(hRes)) {
		DPRINTF(("snd_StartRec: IDirectSoundCapture_GetCaps() failed (errCode: %x)\n", hRes));
	}
	else {
#	define isCertified (dsccaps.dwFlags & DSCCAPS_CERTIFIED) ? "yes" : "no"
#	define isEmulated (dsccaps.dwFlags & DSCCAPS_EMULDRIVER) ? "yes" : "no"
#	define hasMulticapture (dsccaps.dwFlags & DSCCAPS_MULTIPLECAPTURE) ? "yes" : "no"
		DPRINTF(("snd_StartRec: using capture-device with capabilities:  certified: %s  emulated: %s  multicapture: %s  formats: 0x%lx  channels: %d\n", isCertified, isEmulated, hasMulticapture, dsccaps.dwFormats, dsccaps.dwChannels));
	}

	/* create the recording notification thread */
	hRecThread = CreateThread(NULL, 128*1024, dxRecCallback, NULL, 
		STACK_SIZE_PARAM_IS_A_RESERVATION, &threadID);
	if (hRecThread == 0) {
		printLastError("snd_StartRec: CreateThread failed");
		snd_StopRecording();
		return 0;
	}
	if (!SetThreadPriority(hRecThread, THREAD_PRIORITY_HIGHEST))
		printLastError(TEXT("SetThreadPriority() failed"));

	recBufferReadPosition = recBufferWritePosition = recBufferAvailable = 0;

	/* round up the size of the record buffers to multiple of 16 bytes*/
	bytesPerFrame = stereo ? 4 : 2;
	recBufferSize = ((bytesPerFrame * recBufferFrameCount + 15) / 16) * 16;

	/* This computation assumes that totalRecBufferSize is 20480 bytes. */
	numNotificationPoints = totalRecBufferSize / recBufferSize;
	if (numNotificationPoints > 32) {
		printLastError(TEXT("snd_StartRec: frame size must be >= 1280 bytes"));
		snd_StopRecording();
		return 0;
	}

	/* create the secondary sound buffer */
	dscb.dwSize = sizeof(dscb);
	dscb.dwFlags = DSCBCAPS_WAVEMAPPED;
	dscb.dwBufferBytes = numNotificationPoints * recBufferSize;
	dscb.dwReserved = 0;
	waveInFormat.wFormatTag = WAVE_FORMAT_PCM;
	waveInFormat.nChannels = stereo ? 2 : 1;
	waveInFormat.nSamplesPerSec = samplesPerSec;
	waveInFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
	waveInFormat.nBlockAlign = bytesPerFrame;
	waveInFormat.wBitsPerSample = 16;
	dscb.lpwfxFormat = &waveInFormat;
#if 0 // these appear to be obsolete
	dscb.dwFXCount = 0;
	dscb.lpDSCFXDesc = NULL;
#endif
	hRes = IDirectSoundCapture_CreateCaptureBuffer(lpdCapture, &dscb, &lpdRecBuffer, NULL);
	if (FAILED(hRes)) {
		DPRINTF(("snd_StartRec: IDirectSoundCapture_CreateCaptureBuffer() failed (errCode: %x)\n", hRes));
		DPRINTF(("\tchannels: %d  frequency: %dHz\n", waveInFormat.nChannels, samplesPerSec));
		return 0;
	}
	hRes = IDirectSoundCaptureBuffer_QueryInterface(lpdRecBuffer,
		&IID_IDirectSoundNotify, 
		(void**)&lpdNotify );
	if (FAILED(hRes)) {
		DPRINTF(("snd_StartRec: QueryInterface(IDirectSoundNotify) failed (errCode: %x)\n"));
		snd_StopRecording();
		return 0;
	}
	for (i=1; i <= numNotificationPoints; i++) {
		posNotify[i-1].dwOffset = i * recBufferSize - 1;
		posNotify[i-1].hEventNotify = hRecEvent;
	}
	hRes = IDirectSoundNotify_SetNotificationPositions(lpdNotify, numNotificationPoints, posNotify);
	IDirectSoundNotify_Release(lpdNotify);
	if (FAILED(hRes)) {
		DPRINTF(("snd_StartRec: IDirectSoundNotify_SetNotificationPositions() failed (errCode: %x)\n", hRes));
		snd_StopRecording();
		return 0;
	}
	hRes = IDirectSoundCaptureBuffer_Start(lpdRecBuffer, DSCBSTART_LOOPING);
	if (FAILED(hRes)) {
		DPRINTF(("snd_StartRec: IDirectSoundCaptureBuffer_Start() failed (errCode: %x)\n", hRes));
		snd_StopRecording();
		return 0;
	}

	return 0;
}

sqInt
dx_snd_StopRecording(void) {
  if (lpdRecBuffer) {
    IDirectSoundCaptureBuffer_Stop(lpdRecBuffer);
    IDirectSoundCaptureBuffer_Release(lpdRecBuffer);
    lpdRecBuffer = NULL;
  }
  if (lpdCapture) {
    IDirectSoundCapture_Release(lpdCapture);
    lpdCapture = NULL;
  }
  if (hRecThread) {
    ResetEvent(hRecEvent);
    recTerminate = 1;
    SetEvent(hRecEvent);
    WaitForSingleObject(hRecThread, 100); /* wait until terminated */
    hRecThread = NULL;
    recTerminate = 0;
  }
  ResetEvent(hRecEvent);

  return 0;
}

double
dx_snd_GetRecordingSampleRate(void) {
  if (!lpdRecBuffer) return 0.0;
  return (double) waveInFormat.nSamplesPerSec;
}

sqInt
dx_snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes) {
  /* if data is available, copy as many sample slices as possible into the
     given buffer starting at the given slice index. do not write past the
     end of the buffer, which is buf + bufferSizeInBytes. return the number
     of slices (not bytes) copied. a slice is one 16-bit sample in mono
     or two 16-bit samples in stereo. */
  int bytesPerSlice = waveInFormat.nChannels * 2;
  sqInt bytesCopied;
  char *srcPtr, *srcPtr2, *dstPtr;
  HRESULT hRes;
  DWORD srcLen, srcLen2;

  if (!lpdRecBuffer) {
    /* not recording */
    return 0;
  }
  if (!recBufferAvailable) {
    /* no data available */
    return 0;
  }

  if (recBufferReadPosition == recBufferWritePosition) {
    /* We are confused. We should never read the buffer being recorded.
       Note the problem and move on. */
    warnPrintf("sqWin32Sound.c: read position = write position (available: %d)\n", recBufferAvailable);
    recBufferAvailable = 0;
    return 0;
  }

  /* Figure out how much data we want to copy (don't overflow either the source or destination buffers. */
  bytesCopied = bufferSizeInBytes - (startSliceIndex * bytesPerSlice);
  if (bytesCopied > recBufferAvailable) 
    bytesCopied = recBufferAvailable;

  /* Lock the portion of the DirectSound buffer that we will copy data from. */
  hRes = IDirectSoundCaptureBuffer_Lock(lpdRecBuffer,
					recBufferReadPosition,
					bytesCopied,
					(void*)&srcPtr, &srcLen,
					(void*)&srcPtr2, &srcLen2,
					0);
  if (FAILED(hRes)) {
    DPRINTF(("snd_Rec: IDirectSoundCaptureBuffer_Lock() failed (errCode: %x)\n", hRes));
	DPRINTF(("\taddr: %x  readPos: %d  srcPtr: %x/%d  srcPtr2: x/%d    \n", lpdRecBuffer, recBufferReadPosition, bytesCopied, srcPtr, srcLen, srcPtr2, srcLen2));
	return 0;
  } 

  /* Copy the audio data into the buffer passed in by Squeak*/
  dstPtr = (char*)buf + startSliceIndex * bytesPerSlice;
  memcpy(dstPtr, srcPtr, srcLen);
  /* Clear out old samples. The intent is to detect eventual overflow issues
     more easily which would otherwise use the samples from the last time
     the buffer was filled. This leads to weird effects that are hard to
     classify ('choppy' sound) and which are not obvious at all when looking
     at the recorded samples. It should be much easier to find such issues
     when the buffer is all zero to begin with.*/
  memset(srcPtr, 0, srcLen);

  if (srcPtr2) {
	memcpy(dstPtr + srcLen, srcPtr2, srcLen2);
	/* see above comment */
	memset(srcPtr2, 0, srcLen2);
  }

  /* Sanity check: print out error msg if we fail */
  if (bytesCopied != srcLen+srcLen2) {
	DPRINTF(("snd_Rec: total locked buffer size does not match expected/requested value\n"));
  }

  /* Update the position within the DirectSound buffer that we will read from next.
          If there are no more bytes available to read, set a flag to say so. */
  recBufferReadPosition = (recBufferReadPosition + bytesCopied) % totalRecBufferSize;
  recBufferAvailable -= bytesCopied;
 
  /* We're finished with the DirectSound buffer; unlock it. */
  hRes = IDirectSoundCaptureBuffer_Unlock(lpdRecBuffer,
					  srcPtr, srcLen,
					  srcPtr2, srcLen2);
  if (FAILED(hRes)) {
    DPRINTF(("snd_Rec: IDirectSoundCaptureBuffer_Unlock() failed (errCode: %x)\n", hRes));
  }

  return bytesCopied / bytesPerSlice;
}


/* NOTE: Both of the below functions use the default wave out device */
#ifdef OLD
void dx_snd_Volume(double *left, double *right)
{
  DWORD volume = (DWORD)-1;
  waveOutGetVolume((HWAVEOUT)0, &volume);
  *left = (volume & 0xFFFF) / 65535.0;
  *right = (volume >> 16) / 65535.0;
}

void dx_snd_SetVolume(double left, double right)
{
  DWORD volume;

  if (left < 0.0) left = 0.0;
  if (left > 1.0) left = 1.0;
  volume = (int)(left * 0xFFFF);
  if (right < 0.0) right = 0.0;
  if (right > 1.0) right = 1.0;
  volume |= ((int)(right *0xFFFF)) << 16;

  waveOutSetVolume((HWAVEOUT) 0, volume);
}
#endif /* old */

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* HACK! Define LPWAVEFORMAT as LPWAVEFORMATEX for WinVER >= 4 */
#if WINVER >= 0x0400
#define LPWAVEFORMAT LPWAVEFORMATEX
#endif

/* number of buffers used */
#define NUM_BUFFERS 4
/* initial buffer size */
#define BUFFER_SIZE 4096

/* Note: NUM_BUFFERS and BUFFER_SIZE should be carefully chosen.
   You better not touch it unless you know what you're doing, but
   ALWAYS use a multiple of 2 for NUM_BUFFERS. BUFFER_SIZE affects 
   only sound input. The output buffer size is determined by Squeak.
*/

HWAVEOUT hWaveOut = 0;
HWAVEIN hWaveIn = 0;
WAVEFORMATEX waveOutFormat;
WAVEFORMATEX waveInFormat;




/*******************************************************************/
/*  Sound output functions                                         */
/*******************************************************************/




/*******************************************************************/
/*  Sound input functions                                          */
/*******************************************************************/


/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* module initialization/shutdown */
sqInt
soundInit(void) {
  dx_soundInit();
  aec_soundInit();
  return 1;
}

sqInt
soundShutdown(void) {
  dx_soundShutdown();
  aec_soundShutdown();
  return 1;
}

/* sound output */
sqInt
snd_AvailableSpace(void) { return dx_snd_AvailableSpace(); }

sqInt
snd_InsertSamplesFromLeadTime(sqInt frameCount, void *srcBufPtr, sqInt samplesOfLeadTime) {
    return dx_snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
}

sqInt
snd_PlaySamplesFromAtLength(sqInt frameCount, void *arrayIndex, sqInt startIndex) {
    return dx_snd_PlaySamplesFromAtLength(frameCount, arrayIndex, startIndex);
}

sqInt
snd_PlaySilence(void) { return dx_snd_PlaySilence(); }

sqInt
snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex) {
    return dx_snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
}

sqInt
snd_Stop(void) { return dx_snd_Stop(); }

/* sound input */
void snd_SetRecordLevel(sqInt level) { (void)dx_snd_SetRecordLevel(level); }

sqInt
snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex) {
	return AEC_ENABLED
		? aec_snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex)
		: dx_snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex);
}

sqInt
snd_StopRecording(void) {
	return AEC_ENABLED ? aec_snd_StopRecording() : dx_snd_StopRecording();
}

double
snd_GetRecordingSampleRate(void) {
	return AEC_ENABLED
		? aec_snd_GetRecordingSampleRate()
		: dx_snd_GetRecordingSampleRate();
}

sqInt
snd_RecordSamplesIntoAtLength(void *buf, sqInt startSliceIndex, sqInt bufferSizeInBytes) {
	return AEC_ENABLED
		? aec_snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes)
		: dx_snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
}

void
snd_Volume(double *left, double *right) { dx_snd_Volume(left, right); }

void
snd_SetVolume(double left, double right) { dx_snd_SetVolume(left, right); }

sqInt
snd_EnableAEC(sqInt trueOrFalse)
{
# if ENABLE_AEC
	int wasRecording;

	// Fail primitive if we're trying to turn AEC on but it's not 
	// supported on this platform.
	if (trueOrFalse && !AEC_SUPPORTED) {
		DPRINTF(("AEC is not supported on this platform\n"));
		return PrimErrUnsupported; 
	}
	// If we're already in the requested state, there's nothing to do;
	// return successfully.
	if (!!trueOrFalse == !!AEC_ENABLED) {
		DPRINTF(("No change was requested to AEC state\n"));
		return 0; 
	}
	// If we're already recording, we must stop, change state, and restart.
	wasRecording = hRecThread ? 1 : 0;
	if (wasRecording) { snd_StopRecording(); }
	DPRINTF(("Set AEC state to %d\n", trueOrFalse));
	AEC_ENABLED = trueOrFalse;
	if (wasRecording) { 
		snd_StartRecording(recSampleRate, recIsStereo, recSemaphore); 
	}
	return 0; // success
#else
	return PrimErrUnsupported; 
#endif
}

sqInt
snd_SupportsAEC() { return AEC_SUPPORTED; }

#endif /* NO_SOUND */
