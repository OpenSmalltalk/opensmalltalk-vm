// sqMacDeviceList.c
//
// Enumeration of audio devices.
// Supports the device-enumeration API's (SoundPlugin.h)
//
// Ensures a consistent result from public device-listing API's
// in the image-side SoundRecorder and SoundPlayer,
//	 by caching the table of names+ID's when asked how-many,
//   and using that table to answer the names.
//
// The image side is responsible to implement the device-listing api's
// so that each result is constructed from
//		- one call to get the number of input or output devices
//		- the indicated number of calls to get the names for those.
//
// Adapted from earlier (HRS) versions in sqUnixSoundMacOSXJMM.c

#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioConverter.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include "sq.h"
#include "SoundPlugin.h"

int numberOfChannels(Boolean isInput, UInt16 deviceID);

// Shutdown cleanup (see also sqMacUnixInterfaceSound.c)

void clearDeviceCache();


// Private cache records.

#define MAXNAME_LEN 512

typedef struct qSoundDeviceRecordStruct{
	UInt32 deviceID;				// The device's ID in the AudioHardware API's.
	char   deviceName[MAXNAME_LEN];	// Friendly name, unique in its gender.
} qSoundDeviceRecord;

typedef qSoundDeviceRecord * pSoundDevice_t ;

// Private local functions.

static void setDefaultDevice(char *deviceName, Boolean isInput, AudioHardwarePropertyID propertyID);
static OSStatus getMacAudioDevices( Ptr * devices, UInt16 * devicesAvailable );
static OSStatus enumerateDevices (pSoundDevice_t *pList, int* pSize, bool isInput);
static char * getDefaultDeviceName(Boolean isInput);
static char * getDeviceNameOfID(Boolean isInput, UInt32 deviceID);

// Error->stderr util.
static void eprintf(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
}

// Device-list caches.

static pSoundDevice_t gInputDevices = NULL;	// Array, realloc'd to size
static pSoundDevice_t gOutputDevices = NULL;	// 

static int gNumInputDevices = 0;	// Size of above array.
static int gNumOutputDevices = 0;	// 

// Empty and release the given cache array.
// pList / pCount are one of the combinations:
//		gInputDevices / gNumInputDevices 
//		gOutputDevices / gNumOutputDevices

static void clearDeviceList (pSoundDevice_t * pList, int* pCount) 
{
	if (*pList) {
		free (*pList);
	};
	*pList = NULL;
	*pCount = 0;
}

// Grow the given cache array by one, and add the specified device.
// (The list may be the input-device cache, or the output-device cache.)
// Only do this with non-null deviceName and valid devID.
// pList / pCount are one of the combinations:
//		gInputDevices / gNumInputDevices 
//		gOutputDevices / gNumOutputDevices

static void addOneDevice (pSoundDevice_t *pList, int* pCount, char* devName, UInt32 devID) 
{
	pSoundDevice_t list = *pList;
	int count = *pCount;
	
	// (Yes, Virginia, realloc works when list is NULL, for the first add in a cycle.)

	(*pCount) = count = (count + 1);
	(*pList) = list = realloc (list, (count * sizeof(qSoundDeviceRecord)));
	
	strlcpy (list[count-1].deviceName, devName, MAXNAME_LEN);
	list[count-1].deviceID = devID;
}

// Public entry used to clean up on shutdown. (Just storage recovery.)

void clearDeviceCache() {
	clearDeviceList (&gInputDevices, &gNumInputDevices);
	clearDeviceList (&gOutputDevices, &gNumOutputDevices);
}

// The following two primitives 
// answer the number of audio devices of the requested gender.
// Any argument to getDeviceName must be less than the most recent result from this.
//
// These are the first-entry calls which set the cache of named devices.
// The image side calls these, and then
// calls the per-device get name queries, 
// to assemble the lists of input and output devices.


// See above.  First-entry for the image-side 'playerDevices' listing API.
int getNumberOfSoundPlayerDevices() 
{ 
	clearDeviceList (&gOutputDevices, &gNumOutputDevices);
	if (enumerateDevices (&gOutputDevices, &gNumOutputDevices, false) == noErr) {
		return gNumOutputDevices;
	} else {
		return -1;
	}
}

// See above.  First-entry for the image-side 'recorderDevices' listing API.
int getNumberOfSoundRecorderDevices() 
{
	clearDeviceList (&gInputDevices, &gNumInputDevices);
	if (enumerateDevices (& gInputDevices, & gNumInputDevices, true) == noErr) {
		return gNumInputDevices;
	} else {
		return -1;
	}
}

// Primitive support for building the device-list based on the size gotten above.
// Return the i'th entry's name from the player cache.

char * getSoundPlayerDeviceName (int i) { 
	if (i < 0 || i >= gNumOutputDevices) {
		return NULL;
	}
	return gOutputDevices[i].deviceName;
}

// Return the i'th entry's name from the recorder cache.

char * getSoundRecorderDeviceName (int i) 
{ 
	if (i < 0 || i > gNumInputDevices) {
		return NULL;
	}
	return gInputDevices[i].deviceName;
}

// The meat of device enumeration.
// Populate the given sound-device cache array with the current devices of the given gender.
// Return -1 if the listing could not be made, 0 otherwise.

static OSStatus enumerateDevices (pSoundDevice_t *pList, int* pSize, bool isInput)
{
	AudioDeviceID	* 	devices = NULL;
	UInt16				devicesAvailable = 0;
	UInt16				loopCount = 0;
	OSStatus	err;

	// The list of available devices
	if ( (err = getMacAudioDevices ((Ptr*)&devices, &devicesAvailable)) != noErr) {
		return err;
	}
	
	// Select the devices that match this gender (i.e. have channels in the direction)
	// and that have a DeviceName; add them to the device-list cache.
	for (loopCount = 0; loopCount < devicesAvailable; loopCount++)
	{
		char 		buffer[1024];
		UInt32 		outSize;
		AudioDeviceID deviceID = devices[loopCount];
		if (numberOfChannels(isInput, deviceID) <= 0) { 
			continue;
		}
		outSize = sizeof(buffer);
		err = AudioDeviceGetProperty (deviceID, 0, isInput, kAudioDevicePropertyDeviceName, &outSize, buffer);
		if (err != noErr) {
			continue;
		}
		addOneDevice (pList, pSize, buffer, deviceID);
	}
	if (devices) free(devices);
	return noErr;
}

// Find the ID of a device in the listing cache, given a device name.  

static UInt32 findDeviceID (Boolean isInput, char* deviceName)
{
	pSoundDevice_t list = isInput ? gInputDevices : gOutputDevices;
	int size = isInput ? gNumInputDevices : gNumOutputDevices;
	
	int i = 0;
	for (i = 0; i < size; i++) {
		if ( strcmp(deviceName, list[i].deviceName) == 0) {
			return list[i].deviceID;
		}
	}
	return 0;
}

// Find the name of a device, given the deviceID.
// These match the names in the cache listing.

static char * getDeviceNameOfID(Boolean isInput, UInt32 deviceID)
{
	if (!deviceID) return NULL;
	
	pSoundDevice_t list = isInput ? gInputDevices : gOutputDevices;
	int size = isInput ? gNumInputDevices : gNumOutputDevices;
	int i = 0;
	for (i = 0; i < size; i++) {
		if (list[i].deviceID == deviceID) {
			return list[i].deviceName;
		}
	}
	return NULL;
}

// System current-default-device API's.
// These go to the Audio library at time of call 
// (we don't capture which device is default in the listing caches... yet.)

// Ask the system which output is currently the default.

char *	getDefaultSoundPlayer() { 
	return getDefaultDeviceName(false); 
}

// Ask the system which input is currently the default.

char *	getDefaultSoundRecorder() { 
	return getDefaultDeviceName(true); 
}

// Tell the system to use the named device as the default player device.

void setDefaultSoundPlayer(char *deviceName) 
{ 
	if (! gNumOutputDevices) {
		getNumberOfSoundPlayerDevices();	// Seed the table.
	}
	return setDefaultDevice(deviceName, false, kAudioHardwarePropertyDefaultOutputDevice);
}

// Tell the system to use the named device as the default recorder device.

void setDefaultSoundRecorder(char *deviceName) 
{
	if (! gNumInputDevices) {
		getNumberOfSoundRecorderDevices();	// Seed the table.
	}
	return setDefaultDevice(deviceName, true, kAudioHardwarePropertyDefaultInputDevice);
}

// Arrange for deviceName to be used when we next open an audio device 
// of the input/output kind specified by isInput.

static void setDefaultDevice(char *deviceName, Boolean isInput, AudioHardwarePropertyID propertyID)
{
	UInt32	deviceID = findDeviceID(isInput, deviceName);
	if (!deviceID) {
		eprintf("Sound setDefaultDevice: unknown device: %s\n", deviceName);
		return;
	}
	OSStatus err = AudioHardwareSetProperty(propertyID, sizeof(AudioDeviceID), &deviceID);
	if (err != noErr) {
		eprintf("Sound setDefaultDevice: error for %s (%ld)\n", deviceName, err);
	}
}

// Answer the name of the device that will be used when we next open.

static char * getDefaultDeviceName(Boolean isInput)
{
	AudioDeviceID deviceID= 0;
	if (!getDefaultDevice(&deviceID, isInput)) {
			return NULL;
	}
	return getDeviceNameOfID(isInput, deviceID);
}

// From OS-X sample code.
// Make the system calls to get the raw array of audio device identifiers 
// From this we'll determine the current list
// of either players or recorders.

static OSStatus getMacAudioDevices( Ptr * devices, UInt16 * devicesAvailable )
{
    OSStatus	err = noErr;
    UInt32 		outSize;
    Boolean		outWritable;
    
    // find out how many audio devices there are, if any
    err = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &outSize, &outWritable);	
    if ( err != noErr ) {
		eprintf ("Cannot determine number of audio devices %ld\n", err);
		return err;
	}
   
    // calculate the number of device available
	*devicesAvailable = outSize / sizeof(AudioDeviceID);						
    if ( *devicesAvailable < 1 )
	{
		eprintf("No audio devices found.\n" );
		return noErr;
	}
    
    // make space for the devices we are about to get
    *devices = (Ptr) malloc(outSize);		
    	
    memset( *devices, 0, outSize );			
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &outSize, (void *) *devices);	
    if (err != noErr ) {
		eprintf("Cannot list audio devices %ld\n", err);
		return err;
	}
    return noErr;
}

/********************************************************/
