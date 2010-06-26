#include <windows.h>
#include <dmo.h>
#include <Mmsystem.h>
#include <objbase.h>
#include <mediaobj.h>
#include <uuids.h>
#include <propidl.h>
#include <wmcodecdsp.h>

#include <audioclient.h>
#include <MMDeviceApi.h>
#include <AudioEngineEndPoint.h>
#include <DeviceTopology.h>
#include <propkey.h>
#include <strsafe.h>
#include <conio.h>

#include "AecKsbinder.h"

#include "sqVirtualMachine.h"
#include "sqWin32DPRINTF.h"
#include "sqWin32AEC.h"
#include "sqWin32SoundDeviceSelection.h"

#include "qRingBuffer.hpp"

extern "C" {
extern HANDLE hRecEvent;
extern HANDLE hRecThread;
extern int recTerminate;
extern int recSemaphore;
extern int recSampleRate;
extern int recIsStereo;
extern struct VirtualMachine *interpreterProxy;
extern int AEC_ENABLED;
extern int AEC_SUPPORTED;
}
static Qwaq::QRingBuffer *g_aecRingBuffer = NULL;


// We use this class to read data from the DMO
#include "mediabuf.h"
class CStaticMediaBuffer : public CBaseMediaBuffer {
public:
    STDMETHODIMP_(ULONG) AddRef() {return 2;}
    STDMETHODIMP_(ULONG) Release() {return 1;}
    void Init(BYTE *pData, ULONG ulSize, ULONG ulData) {
        m_pData = pData;
        m_ulSize = ulSize;
        m_ulData = ulData;
    }
};


#define SAFE_RELEASE(p) {if (NULL != p) {(p)->Release(); (p) = NULL;}}
#define SAFE_ARRAYDELETE(p) {if (p) delete[] (p); (p) = NULL;}

extern "C" {
	// These are defined in sqWin32Sound.c
	extern DeviceInfoList playerDevices;
	extern DeviceInfoList recorderDevices;
}

IMediaObject *lpDMO;
static const DWORD gBufLen = 32000;  // 16000 samples, 2 bytes each
static BYTE gBuf[gBufLen];


int aec_soundInit(void)
{
	DPRINTF(("Initializing AEC\n"));

	// Always start with echo-cancellation off.
	AEC_ENABLED = 0;

	// Figure out what OS version we're on.  We currently support echo-cancellation
	// only on Windows Vista and 7.  Windows XP has a DirectSound API for echo-cancellation
	// that we may choose to support later.
	OSVERSIONINFOEX osvi;
	ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
	if (!GetVersionEx( (OSVERSIONINFO*)&osvi )) {
		DPRINTF(("\t... cannot determine platform; assuming AEC is unsupported: 0x%lxL\n", GetLastError()));
		AEC_SUPPORTED = 0;
	}
	else if (osvi.dwMajorVersion >= 6) {
		if (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 0) {
			DPRINTF(("\t... AEC is supported on this platform (Windows Vista)\n"));
		}
		else {
			DPRINTF(("\t... AEC is supported on this platform (Windows 7 or later)\n"));
		}
		
		AEC_SUPPORTED = 1;
	}
	else {
		DPRINTF(("\t... AEC is not supported on Windows XP and earlier\n"));
		AEC_SUPPORTED = 0;
	}

	// Set global pointer to NULL;
	lpDMO = NULL;
	return 1;
}


int aec_soundShutdown(void)
{
	return 1;
}


// Check the result value.  On failure:
//     1) log an error message (if debug-logging is enabled)
//     2) set a flag
//     3) goto error handler
#define CHECK_START_RECORDING_HR(hr, errorText) { if (FAILED(hr)) { DPRINTF(errorText); hitAnError = true; goto error; } }

// Helper function for aec_snd_StartRecording().
// Search through the list of devices for one with a matching DirectSound GUID.
static HRESULT aec_findDeviceWithGUID(IMMDeviceCollection* deviceCollection, LPGUID guid, IMMDevice** resultDevice, int *resultIndex)
{
	UINT index, deviceCount;
	HRESULT hr;
	bool hitAnError = false;

	// Clear results... we'll set them later if we actually find a matching device.
	*resultDevice = NULL;
	*resultIndex = -2;
	IMMDevice* device = NULL;
	IPropertyStore* deviceProperties = NULL;

	// Sanity check... ensure that we're provided with a guid to match against.
	if (!guid) {
		hr = E_FAIL;
		CHECK_START_RECORDING_HR(hr,("FAILED: no GUID provided to findDeviceWithGUID()\n"));
	}

	// Obtain the number of devices to iterate over.
	hr = deviceCollection->GetCount(&deviceCount);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot get number of devices\n", hr));
	
	// Iterate over the devices, trying to find a match.
	for (index = 0; index < deviceCount; index++) {
		GUID enumGUID;

		// Get the next device.
		hr = deviceCollection->Item(index, &device);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot obtain device #%d\n", hr, index));

		// Prepare to read the device properties.
		hr = device->OpenPropertyStore(STGM_READ, &deviceProperties);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot open device properties\n", hr));
	
		// Get the device's DirectSound GUID.  
		// The API returns a string that we must convert to a GUID. 
		PROPVARIANT value;
		PropVariantInit(&value);
		hr = deviceProperties->GetValue(PKEY_AudioEndpoint_GUID, &value);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot obtain device GUID from properties\n", hr));
		hr = IIDFromString(value.pwszVal, &enumGUID);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): unable to obtain device GUID from string\n", hr));
		PropVariantClear(&value);

		// Regardless of what happens next, we don't need these any longer.
		SAFE_RELEASE(deviceProperties);

		// Check if the GUIDs match.
		if (IsEqualIID(enumGUID, *guid)) {
			// Success!
			*resultDevice = device;
			*resultIndex = index;
			hr = S_OK;

			// If we wanted to print out the name of the device found, we would use
			// something like this to convert from a wide-string to something we can
			// use with DPRINTF().
			//	WideCharToMultiByte(
			//		CP_UTF8, 
			//		0, // no flags
			//		captureDeviceInfo[i].szDeviceName,
			//		-1, // input string length... -1 means assume null-termination
			//		outputName,
			//		1000,
			//		NULL,
			//		NULL);

			break;  // exit loop so we can clean up after ourselves, and then return.
		}
		else {
			// This isn't the device we're looking for.  Release it and move on.
			SAFE_RELEASE(device); 
		}
	}

error:
	if (hitAnError) { 
		SAFE_RELEASE(device);
		SAFE_RELEASE(deviceProperties);
	}

	return hr;
}


int aec_snd_StartRecording(int samplesPerSec, int stereo, int semaIndex)
{
	// Stash these in case we need to stop and restart recording with the
	// same parameters as requested this time.
	recSampleRate = samplesPerSec;
	recIsStereo = stereo;
	recSemaphore = semaIndex;

	if (g_aecRingBuffer) {
		aec_snd_StopRecording();
	}
	DPRINTF(("snd_StartRec: beginning DMO AEC audio capture\n"));
	DPRINTF(("\tsamplingRate: %d   stereo: %d   sem-index: %d\n", samplesPerSec, stereo, semaIndex));


	// Allocate a ring-buffer with enoug room for 1280msecs of 16kHz 16-bit sound."
	g_aecRingBuffer = new Qwaq::QRingBuffer(40960);
	if (!g_aecRingBuffer) {
		DPRINTF(("aec_snd_StartRecording: failed to allocate ring-buffer\n"));
		return 0;
	}

	// We don't support stereo for now.  IMPORTANT: if we change this, we also
	// need to change aec_snd_RecordSamplesIntoAtLength(), which assumes 2 bytes/sample.
	if (stereo) {
		DPRINTF(("aec_snd_StartRecording: stereo not supported; recording not started\n"));
		return 0;
	}

	IMMDeviceEnumerator* enumerator = NULL;
	IMMDeviceCollection* deviceCollection = NULL;
	IMMDevice* device = NULL;
	IPropertyStore* dmoProperties = NULL;
	IPropertyStore* deviceProperties = NULL;
	bool isArrayDevice;
	LPGUID renderGUID = playerDevices.defaultDevice.guid;
	LPGUID captureGUID = recorderDevices.defaultDevice.guid;
	int renderDeviceIndex = -1;
	int captureDeviceIndex = -1;
	HRESULT hr;
	bool hitAnError = false;

	hr = CoCreateInstance(CLSID_CWMAudioAEC, NULL, CLSCTX_INPROC_SERVER, IID_IMediaObject, (void**)&lpDMO);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot instantiate the DMO\n", hr));

	hr = lpDMO->QueryInterface(IID_IPropertyStore, (void**)&dmoProperties);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot obtain DMO's property-store\n", hr));

	// Get interface-ref to enumerator object.
	// I hate to use the Microsoft-specific __uuidof() operator, but it wouldn't
	// link if I tried CLSID_MMDeviceEnumerator and IID_IMMDeviceEnumerator.
	hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_INPROC_SERVER, __uuidof(IMMDeviceEnumerator), (void**)&enumerator);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot instantiate device-enumerator\n", hr));

	// Find the audio endpoint matching the GUID of the current DirectSound player device.
	hr = enumerator->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, &deviceCollection);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot enumerate audio-playback endpoints\n", hr));
	hr = aec_findDeviceWithGUID(deviceCollection, playerDevices.defaultDevice.guid, &device, &renderDeviceIndex);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot find matching audio-playback device\n", hr));
	SAFE_RELEASE(deviceCollection);
	SAFE_RELEASE(device);
// Find the audio endpoint matching the GUID of the current DirectSound capture device.
	hr = enumerator->EnumAudioEndpoints(eCapture, DEVICE_STATE_ACTIVE, &deviceCollection);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot enumerate audio-capture endpoints\n", hr));
	hr = aec_findDeviceWithGUID(deviceCollection, recorderDevices.defaultDevice.guid, &device, &captureDeviceIndex);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot find matching audio-capture device\n", hr));
	// I was going to avoid a dependency on AecKsBinder, but got lazy...
	// why transcribe the code into something even more verbose without
	// smart-pointers?
	hr = EndpointIsMicArray(device, isArrayDevice);
	CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): unable to determine whether device is a mic-array\n", hr));
	// These would get cleaned up at the end, anyway, but it's tidier to clean up 
	// as soon as we're finished with them.
	SAFE_RELEASE(deviceCollection);
	SAFE_RELEASE(device);

	if (captureDeviceIndex < 0 || renderDeviceIndex < 0) {
		DPRINTF(("FAILED: could not obtain capture and render device indices (%d/%d)\n", captureDeviceIndex, renderDeviceIndex));
		goto error;
	}
	DPRINTF(("Matched render and capture devices, %d and %d\n", renderDeviceIndex, captureDeviceIndex));
	DPRINTF(("Capture device %s a microphone array\n", (isArrayDevice ? "is" : "is not")));

	// Set the AEC-MicArray DMO system mode
	{
		PROPVARIANT systemMode;
		PropVariantInit(&systemMode);
		systemMode.vt = VT_I4;
		if (isArrayDevice) {
			DPRINTF(("Found microphone array, so using mode: OPTIBEAM_ARRAY_AND_AEC\n"));
			systemMode.lVal = (LONG)OPTIBEAM_ARRAY_AND_AEC;

			// This crap is still sketchy.  Here's my experience with various modes:
			// - ADAPTIVE_ARRAY_AND_AEC: failed with code 0x80004005 in AllocateStreamingResources()
			// - ADAPTIVE_ARRAY_ONLY: ditto
			// - MODE_NOT_SET: ditto
			// - OPTIBEAM_ARRAY_AND_AEC: periodic high-pitched squeaks
			// - OPTIBEAM_ARRAY_ONLY: echoes like hell
			// So, it appears like the only one that works decently on my machine
			// is SINGLE_CHANNEL_AEC (which, luckily, would seem to be the safest
			// choice for a range of machines.
			DPRINTF(("For safety/compatibility, forcing mode: SINGLE_CHANNEL_AEC\n"));
			systemMode.lVal = (LONG)SINGLE_CHANNEL_AEC;
		}
		else {
			DPRINTF(("Found single-channel microphone, so using mode: SINGLE_CHANNEL_AEC\n"));
			systemMode.lVal = (LONG)SINGLE_CHANNEL_AEC;
		}
		hr = dmoProperties->SetValue(MFPKEY_WMAAECMA_SYSTEM_MODE, systemMode);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): could not set system mode\n", hr));
		hr = dmoProperties->GetValue(MFPKEY_WMAAECMA_SYSTEM_MODE, &systemMode);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): readback of system mode failed\n", hr));
		PropVariantClear(&systemMode);
	}

	// Set the capture and render devices for the DMO to use
	{
		PROPVARIANT deviceIDs;
        PropVariantInit(&deviceIDs);
        deviceIDs.vt = VT_I4;
        deviceIDs.lVal = (unsigned long)(renderDeviceIndex<<16) + (unsigned long)(0x0000ffff & captureDeviceIndex);
        hr = dmoProperties->SetValue(MFPKEY_WMAAECMA_DEVICE_INDEXES, deviceIDs);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): could not set device IDs\n", hr));
        hr = dmoProperties->GetValue(MFPKEY_WMAAECMA_DEVICE_INDEXES, &deviceIDs);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): readback of deviceIDs failed\n", hr));
        PropVariantClear(&deviceIDs);
	}

	// Turn off additional feature modes.
	{
		PROPVARIANT shouldEnableExtraFeatures;
		PropVariantInit(&shouldEnableExtraFeatures);
		shouldEnableExtraFeatures.vt = VT_BOOL;
		shouldEnableExtraFeatures.boolVal = (VARIANT_BOOL)0;
		hr = dmoProperties->SetValue(MFPKEY_WMAAECMA_FEATURE_MODE, shouldEnableExtraFeatures);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot disable extra features\n", hr));
		hr = dmoProperties->GetValue(MFPKEY_WMAAECMA_FEATURE_MODE, &shouldEnableExtraFeatures);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot tell if extra features are enabled\n", hr));
		PropVariantClear(&shouldEnableExtraFeatures);
	}

	// Set the DMO output format.
	{
		// I guess this means to only initialize the struct's first member
		DMO_MEDIA_TYPE mediaType = {0};
		WAVEFORMATEX wfxOut = {WAVE_FORMAT_PCM, 1, recSampleRate, recSampleRate*2, 2, 16, 0};

		hr = MoInitMediaType(&mediaType, sizeof(WAVEFORMATEX));
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot init media-type object\n", hr));
	
		mediaType.majortype = MEDIATYPE_Audio;
		mediaType.subtype = MEDIASUBTYPE_PCM;
		mediaType.bFixedSizeSamples = TRUE;
		mediaType.bTemporalCompression = FALSE;
		mediaType.lSampleSize = 0;  // copied from AEC example code
		mediaType.formattype = FORMAT_WaveFormatEx;
		memcpy(mediaType.pbFormat, &wfxOut, sizeof(WAVEFORMATEX));

		hr = lpDMO->SetOutputType(0, &mediaType, 0);
		MoFreeMediaType(&mediaType);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot set DMO output type\n", hr));
	}

	// Final DMO preparations...
	{
		// Would be called automatically, but we need to call it explicitly
		// if we want to determing the frame size being used.
		hr = lpDMO->AllocateStreamingResources();
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot AllocateStreamingResources()\n", hr));
	
		PROPVARIANT frameSize;
		PropVariantInit(&frameSize);
		hr = dmoProperties->GetValue(MFPKEY_WMAAECMA_FEATR_FRAME_SIZE, &frameSize);
		CHECK_START_RECORDING_HR(hr, ("FAILED(0x%lxL): cannot get audio frame-size\n", hr));
		DPRINTF(("Read frame size: %d\n", frameSize.lVal));
		PropVariantClear(&frameSize);
	}

	// Create the thread
	hRecThread = CreateThread(NULL, 128*1024, aecRecThreadFunc, NULL, STACK_SIZE_PARAM_IS_A_RESERVATION, NULL);
	if (!hRecThread) {
		CHECK_START_RECORDING_HR(E_FAIL, ("FAILED: CreateThread() in aec_snd_StartRecording()\n"));
	}
	if (!SetThreadPriority(hRecThread, THREAD_PRIORITY_HIGHEST)) {
		DPRINTF(("WARNING: SetThreadPriority failed() in aec_snd_StartRecording()\n"));
	}

error:
	if (hitAnError) { aec_snd_StopRecording(); }
	SAFE_RELEASE(dmoProperties);
	SAFE_RELEASE(enumerator);
	SAFE_RELEASE(deviceCollection);
	SAFE_RELEASE(device);
	SAFE_RELEASE(deviceProperties);
	return 0;
}
#undef CHECK_START_RECORDING_HR


int aec_snd_StopRecording(void)
{
	if (hRecThread) {
		recTerminate = 1;
		SetEvent(hRecEvent); // end the record-loop ASAP.
		if (WaitForSingleObject(hRecThread, 1000) == WAIT_TIMEOUT) {
			DPRINTF(("WARNING: timed out after waiting 1 second for record thread to finish\n"));
		};
		hRecThread = NULL;
	}
	if (g_aecRingBuffer) {
		delete g_aecRingBuffer;
		g_aecRingBuffer = NULL;
	}
	SAFE_RELEASE(lpDMO);
	ResetEvent(hRecEvent);
	recTerminate = 0;
	return 0;
}

int aec_snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) 
{
	if (!g_aecRingBuffer) {
		// Not currently recording
		return 0;
	}

	// Offset is specified in 16-bit samples, so multiply by 2 to get # of bytes
	int startByteOffset = startSliceIndex * 2;
	char* dstPtr = (char*)(buf + startByteOffset);
	int bytesToCopy = bufferSizeInBytes - startByteOffset;
	if (bytesToCopy > g_aecRingBuffer->dataSize()) {
		bytesToCopy = g_aecRingBuffer->dataSize();
	}
	g_aecRingBuffer->get(dstPtr, bytesToCopy); 
	
	return bytesToCopy / 2; // return number of 16-bit samples
}

int aec_snd_GetRecordingSampleRate(void)
{
	return recSampleRate;
}

DWORD WINAPI aecRecThreadFunc( LPVOID ignored )
{
	DPRINTF(("Entering aecRecThreadFunc()\n"));

	CStaticMediaBuffer mediaBuffer;
	mediaBuffer.Init((byte*)gBuf, gBufLen, 0);
	DMO_OUTPUT_DATA_BUFFER dmoBuffer = {0};
	dmoBuffer.pBuffer = &mediaBuffer;

	int loopin = 0;
	while(1) {	
		
		DWORD waitResult = WaitForSingleObject(hRecEvent, 40);
		if (recTerminate) return 0;  // done recording
		if (waitResult == WAIT_FAILED) {
			DPRINTF(("Record-loop wait failed with status: 0x%lxL\n", GetLastError() ));
		}
		else {
			// Reset the buffers before we attempt to read into them.
			mediaBuffer.SetLength(0);		
			dmoBuffer.dwStatus = 0;

			HRESULT hr;
			DWORD dataLength = 0;
			DWORD ignored; // currently reserved... will always be zero
			hr = lpDMO->ProcessOutput(0, 1, &dmoBuffer, &ignored);
			if (FAILED(hr)) {
				DPRINTF(("DMO->ProcessOutput() failed: 0x%lxL\n", hr));
			}
			else if (hr == S_FALSE) {
				// Didn't read any data this time around.  No problemo.
				DPRINTF(("no data for you, hombre\n", hr));
			}
			else {
				hr = mediaBuffer.GetBufferAndLength(NULL, &dataLength);
				if (FAILED(hr)) { 
					// This cannot fail, but test it anyway since the
					// method returns a result-code.
					DPRINTF(("Failed to get data length\n")); 
				}
				else {
					try { g_aecRingBuffer->put(gBuf, dataLength); }
					catch (std::string ex) {
						DPRINTF(("Failed to stash microphone input into ring-buffer\n"));
					}
				}
				// We don't bother checking dmoBuffer.dwStatus... the only value
				// that might be relevant is DMO_OUTPUT_DATA_BUFFERF_INCOMPLETE,
				// and if we get this then we'll be reading the data next "tick"
				// anyway.
				interpreterProxy->signalSemaphoreWithIndex(recSemaphore);
			}
		}
	}
	DPRINTF(("Exiting aecRecThreadFunc()\n"));
}
