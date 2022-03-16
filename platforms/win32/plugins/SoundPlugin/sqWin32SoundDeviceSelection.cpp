#include "sqWin32SoundDeviceSelection.h"
#include "sqDSoundClassFactory.h"
#include "sq.h"
#include "sqWin32DPRINTF.h"

#define mmFAILED(mm) ((mm) != MMSYSERR_NOERROR)

// Helper function for GetWaveDeviceIDFromName()
// same as !!strstr(a, b), but dealing with near/far and char/wchar
static BOOL
stringMatchIn(const TCHAR *a, const TCHAR *b)
{
	if (!a || !b)
		return FALSE;
	while (*a && *b)
		if (*a++ != *b++)
			return FALSE;
	return !*b;   /* still true if a is not done */
}


// Given a DirectX device identified by "guid", 
// find the corresponding wave device ID and return it in "waveID".
// Inspired by DirectSoundEnumeratorDlg.cpp on chrisnet.net (via google.com/codesearch) 
HRESULT GetWaveDeviceIDFromGUID(LPGUID lpGUID, DIRECTSOUNDDEVICE_DATAFLOW dataflowType, DWORD* waveID)
{
	HRESULT hr;
	LPKSPROPERTYSET propSet = NULL;
	DSPROPERTY_DIRECTSOUNDDEVICE_DESCRIPTION_DATA deviceDescription;
	PDSPROPERTY_DIRECTSOUNDDEVICE_DESCRIPTION_DATA deviceDescriptionPtr = NULL;
	ULONG ulBytesReturned = 0;

	/* If we're passed a NULL GUID-ptr, we assume it's on purpose. */
	if (!lpGUID) {
		*waveID = -1;
		return S_OK;
	}

	/* Assume we're going to fail.  If we succeed, this will be overwritten. */
	*waveID = -666;

	IClassFactory *factory = dsound_GetClassFactory(CLSID_DirectSoundPrivate);
	if (!factory) {
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID():  cannot obtain class factory\n"));
		hr = CLASS_E_CLASSNOTAVAILABLE;
		goto error;
	}

	hr = factory->CreateInstance(NULL, IID_IKsPropertySet,(LPVOID *)&propSet);
	if (FAILED(hr)) {
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID():  cannot instantiate property-set\n"));
		goto error;
	}

	// An anonymous DirectX team member tipped off Mr. Chrisnet.net that it's
	// necessary to call Get() twice.  Good to know.
	memset(&deviceDescription, 0, sizeof(deviceDescription));
	deviceDescription.DeviceId = *lpGUID;
	deviceDescription.DataFlow = dataflowType;
	deviceDescription.WaveDeviceId = 666; // so we can see if it's changed.
	// On the first call the final size is unknown so pass the size of the struct in order to receive
    // "Type" and "DataFlow" values, ulBytesReturned will be populated with bytes required for struct+strings.
    hr = propSet->Get(DSPROPSETID_DirectSoundDevice,
					DSPROPERTY_DIRECTSOUNDDEVICE_DESCRIPTION,
					NULL,
					0,
					&deviceDescription,
					sizeof(deviceDescription),
					&ulBytesReturned
				);
	if (FAILED(hr)) {
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID():  property-get 1 failed\n"));
		goto error;
	}
	if (!ulBytesReturned) {
		// I don't know what to make of this situation... why would the return code
		// be successful, but the byte-count be zero?  Oh well, it may never happen.
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID(): failed to get byte-size for description\n"));
		hr = ERROR_INVALID_HANDLE; // not sure what the correct error-value; this is in the ballpark
		goto error;
	}
	// On the first call it notifies us of the required amount of memory in order to receive the strings.
    // Allocate the required memory, the strings will be pointed to the memory space directly after the struct.
	deviceDescriptionPtr = (PDSPROPERTY_DIRECTSOUNDDEVICE_DESCRIPTION_DATA)malloc(ulBytesReturned);
	if (!deviceDescriptionPtr) {
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID(): failed to dynamically allocate for description\n"));
		hr = ERROR_NOT_ENOUGH_MEMORY;
		goto error;
	}
	*deviceDescriptionPtr = deviceDescription;
    hr = propSet->Get(DSPROPSETID_DirectSoundDevice,
					DSPROPERTY_DIRECTSOUNDDEVICE_DESCRIPTION,
					NULL,
					0,
					deviceDescriptionPtr,
					ulBytesReturned,
					&ulBytesReturned
				);
	if (FAILED(hr)) {
		DPRINTF(("ERROR GetWaveDeviceIDFromGUID():  property-get 2 failed\n"));
		goto error;
	}
	
	DPRINTF(("OBTAINED DEVICE INFO: \n\ttype/waveID:  %d/%d\n\tdescription:   %s\n\tmodule:   %s\n\tinterface:   %s\n", deviceDescriptionPtr->Type, deviceDescriptionPtr->WaveDeviceId, deviceDescriptionPtr->Description, deviceDescriptionPtr->Module, deviceDescriptionPtr->Interface));

	// All of that bullshit for one little integer.
	*waveID = deviceDescriptionPtr->WaveDeviceId;
	hr = S_OK;

error:
	if (propSet) { propSet->Release(); }
	if (factory) { factory->Release(); }
	if (deviceDescriptionPtr) { free(deviceDescriptionPtr); }
	return hr; // return the last result, which should be appropriate
}


/* Given a DirectX device identified by "lpszDesc", find the corresponding wave device ID and return it in "waveID".
   This is a hack that we use because GetWaveDeviceIDFromGUID() only works for playback devices (not capture devices). */
HRESULT GetWaveDeviceIDFromName(LPCTSTR lpszDesc, DWORD* waveID)
{
	UINT totalDevices = mixerGetNumDevs();
	UINT currentDevice;
	MIXERCAPS mmCaps;
	MMRESULT mmResult;

	for (currentDevice = 0; currentDevice < totalDevices; currentDevice++) {
		mmResult = mixerGetDevCaps(currentDevice, &mmCaps, sizeof(mmCaps));
		if (mmFAILED(mmResult)) {
			// We couldn't get mixer-caps for this device.  This isn't good, but
			// let's persevere and try the rest of the devices.
			DPRINTF(("ERROR GetWaveDeviceIDFromName() failed to get dev-caps for index %d\n", currentDevice));
		}
		else if (stringMatchIn(lpszDesc, mmCaps.szPname)) {
			// Success!!  We've found a device with a matching name, so grab its
			// device-ID and return triumphantly.
			*waveID = currentDevice;
			return S_OK;
		}
	}
	// Failure.  We couldn't find a matching device.
	*waveID = -1;
	return ERROR_INVALID_DATA;
}
