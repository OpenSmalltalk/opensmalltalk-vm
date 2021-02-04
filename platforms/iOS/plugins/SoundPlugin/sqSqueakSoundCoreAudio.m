//
//  sqSqueakSoundCoreAudio.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 11/10/08.
//	Extended with the Terf additions in May 2017 by Eliot Miranda
//	Corrected for device addition/removal issues Aug 2020 by Eliot Miranda
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 The end-user documentation included with the redistribution, if any, must
 include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd
  (http://www.smalltalkconsulting.com) and its contributors",
 in the same place and form as other third-party acknowledgments.  Alternately,
 this acknowledgment may appear in the software itself, in the same form and
 location as other such third-party acknowledgments.
 */

#import <CoreAudio/CoreAudio.h>
#include <AVFoundation/AVCaptureDevice.h>

#import "sqSqueakSoundCoreAudio.h"

#import "sqMemoryFence.h"
#import "sqAssert.h"

#define SqueakFrameSize	4	// guaranteed (see class SoundPlayer)
extern struct VirtualMachine* interpreterProxy;

#if defined(MAC_OS_X_VERSION_10_14)
static canAccessMicrophone = false;
static askedToAccessMicrophone = false;

static void
askToAccessMicrophone()
{
	askedToAccessMicrophone = true;
	// Request permission to access the microphone.
	// This API is only available in the 10.14 SDK and subsequent.
	switch ([AVCaptureDevice authorizationStatusForMediaType: AVMediaTypeAudio]) {
		case AVAuthorizationStatusAuthorized:
			// The user has previously granted access to the microphone.
			canAccessMicrophone = true;
			return;
		case AVAuthorizationStatusNotDetermined: {
			// The app hasn't yet asked the user for microphone access.
			__block BOOL gotResponse = false;
			const struct timespec rqt = {0,100000000}; // 1/10th sec
			[AVCaptureDevice
				requestAccessForMediaType: AVMediaTypeAudio
				completionHandler: ^(BOOL granted) {
										gotResponse = true;
										canAccessMicrophone = granted;
									}];
			while (!gotResponse)
				nanosleep(&rqt,0);
			return;
		}
		case AVAuthorizationStatusDenied:
			// The user has previously denied access.
			// One would hope one could to ask again; max once per run.
			// But at least in MacOS X 11.1 one cannot ask again; the request to ask
			// send (requestAccessForMediaType:completionHandler:) is ignored.
		case AVAuthorizationStatusRestricted:
			// The user can't grant access due to restrictions.
			canAccessMicrophone = false;
	}
}
#endif

static __inline bool
ensureMicrophoneAccess()
{
#if defined(MAC_OS_X_VERSION_10_14)
	if (!askedToAccessMicrophone)
		askToAccessMicrophone();
	if (!canAccessMicrophone)
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
	return canAccessMicrophone;
#else
	return true;
#endif
}

static void
MyAudioQueueOutputCallback (sqSqueakSoundCoreAudio *myInstance,
							AudioQueueRef           inAQ,
							AudioQueueBufferRef     inBuffer) {

	soundAtom	*atom = [myInstance.soundOutQueue returnOldest];

	if (!atom) {
		inBuffer->mAudioDataByteSize   = MIN(inBuffer->mAudioDataBytesCapacity,2644);
		memset(inBuffer->mAudioData,0,inBuffer->mAudioDataByteSize);
		//NSLog(@"%i Fill sound buffer with zero %i bytes",ioMSecs(),inBuffer->mAudioDataByteSize);
	}
	else if (inBuffer->mAudioDataBytesCapacity >= atom.byteCount) {
		atom = [myInstance.soundOutQueue returnAndRemoveOldest];
		inBuffer->mAudioDataByteSize = atom.byteCount;
		memcpy(inBuffer->mAudioData,atom.data,atom.byteCount);
		RELEASEOBJ(atom);
		//NSLog(@"%i Fill sound buffer with %i bytesA",ioMSecs(),inBuffer->mAudioDataByteSize);
	}
	else {
		inBuffer->mAudioDataByteSize = MIN(atom.byteCount - atom.startOffset,inBuffer->mAudioDataBytesCapacity);
		memcpy(inBuffer->mAudioData,atom.data+atom.startOffset,inBuffer->mAudioDataByteSize);
		atom.startOffset = atom.startOffset + inBuffer->mAudioDataByteSize;
		if (atom.startOffset == atom.byteCount) {
			atom = [myInstance.soundOutQueue returnAndRemoveOldest]; //ignore now it's empty
			RELEASEOBJ(atom);
		}
//NSLog(@"%i Fill sound buffer with %i bytesB",ioMSecs(),inBuffer->mAudioDataByteSize);
	}
	AudioQueueEnqueueBuffer(inAQ,inBuffer,0,nil);			
	interpreterProxy->signalSemaphoreWithIndex(myInstance.semaIndexForOutput);	
}

static void
MyAudioQueueInputCallback ( void                  *inUserData,
							AudioQueueRef          inAQ,
							AudioQueueBufferRef    inBuffer,
							const AudioTimeStamp  *inStartTime,
							UInt32                 inNumberPacketDescriptions,
							const AudioStreamPacketDescription  *inPacketDescs) {
	sqSqueakSoundCoreAudio *myInstance = (__bridge  sqSqueakSoundCoreAudio *)inUserData;

	if (!myInstance.inputIsRunning) 
		return;

	if (inNumberPacketDescriptions > 0) {
		soundAtom *atom = AUTORELEASEOBJ([[soundAtom alloc] initWith: inBuffer->mAudioData count: inBuffer->mAudioDataByteSize]);
		[myInstance.soundInQueue addItem: atom];
    }

	AudioQueueEnqueueBuffer (inAQ, inBuffer, 0, NULL);
	interpreterProxy->signalSemaphoreWithIndex(myInstance.semaIndexForInput);	
}


/* Rebuild the device list every time the status changes.  Avoid hazards
 * with asynchronous access by using a simple request/acknowledge pair,
 * rebuilding whenever they don't match.
 */
static int rebuildRequest = 0, rebuildCount = -1;

static OSStatus
MyAudioDevicesListener(	AudioObjectID inObjectID,
						UInt32 inNumberAddresses,
						const AudioObjectPropertyAddress *inAddresses,
						void *inClientData)
{
    ++rebuildRequest;
	sqLowLevelMFence();
    return noErr;
}

@implementation soundAtom
@synthesize	data; 
@synthesize	byteCount;
@synthesize	startOffset;

- (instancetype) initWith: (char*) buffer count: (usqInt) bytes {
	data = malloc(bytes);
	memcpy(data,buffer,bytes);
	byteCount = bytes;
	startOffset = 0;
	return self;
}

- (void) dealloc {
	if (data) free(data);
	data = 0;
	byteCount = 0;
	startOffset = 0;
    SUPERDEALLOC
}

@end

@implementation sqSqueakSoundCoreAudio

@synthesize outputAudioQueue;
@synthesize inputAudioQueue;
@synthesize semaIndexForOutput;
@synthesize bufferSizeForOutput;
@synthesize semaIndexForInput;
@synthesize bufferSizeForInput;
@synthesize	inputSampleRate;
@synthesize outputFormat;
@synthesize inputFormat;
@synthesize outputIsRunning;
@synthesize inputIsRunning;
@synthesize soundOutQueue;
@synthesize soundInQueue;
@synthesize	outputBuffers;
@synthesize	inputBuffers;
@synthesize inputChannels;

-	(sqInt) soundInit {
	//NSLog(@"%i sound init",ioMSecs());
	self.outputAudioQueue = nil;
	self.inputAudioQueue = nil;
	self.semaIndexForOutput = 0;
	self.semaIndexForInput = 0;
	self.outputFormat = calloc(1,sizeof(AudioStreamBasicDescription));
	self.inputFormat = calloc(1,sizeof(AudioStreamBasicDescription));
	self.outputBuffers = calloc(kNumberOfBuffers,sizeof(AudioQueueBufferRef));
	self.inputBuffers = calloc(kNumberOfBuffers,sizeof(AudioQueueBufferRef));
	soundOutQueue = [[Queue alloc] init];
	soundInQueue = [[Queue alloc] init];
	numDevices = 0;
	deviceIDs = nil;
	deviceNames = nil;
	deviceUIDs = nil;
	deviceTypes = nil;
	return 1;
}

- (sqInt) soundShutdown {
	//NSLog(@"%i sound shutdown",ioMSecs());
	if (self.outputAudioQueue)
		[self snd_StopAndDispose];
	if (self.inputAudioQueue)
		[self snd_StopRecording];
	return 1;
}

- (sqInt)	snd_Start: (sqInt) frameCount samplesPerSec: (sqInt) samplesPerSec stereo: (sqInt) stereo semaIndex: (sqInt) semaIndex {
	//NSLog(@"%i sound start playing frame count %i samples %i",ioMSecs(),frameCount,samplesPerSec);
	int nChannels = 1 + (int)stereo;

	if (frameCount <= 0 || samplesPerSec <= 0 || stereo < 0 || stereo > 1) 
		return 0; /* Causes primitive failure in primitiveSoundStart[WithSemaphore] */

	self.semaIndexForOutput = semaIndex;
	AudioStreamBasicDescription check;
	bzero(&check,sizeof(AudioStreamBasicDescription));

	check.mSampleRate = (Float64)samplesPerSec;
	check.mFormatID = kAudioFormatLinearPCM;
	check.mFormatFlags = kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsSignedInteger;
	check.mBytesPerPacket   =
	check.mBytesPerFrame    = SqueakFrameSize / (3 - nChannels);
	check.mFramesPerPacket  = 1;
	check.mChannelsPerFrame = nChannels;
	check.mBitsPerChannel   = 16;

	/* we want to create a new audio queue only if we have to */
	if (self.outputAudioQueue != nil
	 && !memcmp(&check,self.outputFormat,sizeof(AudioStreamBasicDescription))) {
		//NSLog(@"%i reuse audioqueue",ioMSecs());
		return 1;
	}
	//NSLog(@"%i create new audioqueue",ioMSecs());
	AudioQueueRef newQueue;
	if (self.outputAudioQueue) 
		[self snd_StopAndDispose];
	*self.outputFormat = check;
	if (AudioQueueNewOutput(self.outputFormat,
							(AudioQueueOutputCallback)&MyAudioQueueOutputCallback,
							(__bridge void*)self, NULL, NULL, 0, &newQueue))

		return 0; /* Causes primitive failure in primitiveSoundStart[WithSemaphore] */
	self.outputAudioQueue = newQueue;

	// The claim on the internet is that each callback must have its own
	// run loop for the callbacks to be called reliably.
	// If these error what can we do?  Simply ignore errors for now.
	AudioObjectPropertyAddress setRunLoop = {
									kAudioHardwarePropertyRunLoop,
									kAudioObjectPropertyScopeGlobal,
									kAudioObjectPropertyElementMaster };
	CFRunLoopRef runLoop = 0;
	if (AudioObjectSetPropertyData(kAudioObjectSystemObject, &setRunLoop,
									 0, nil, sizeof(runLoop), &runLoop))
		warning("SoundPlugin: error setting run loop property");

	// See https://stackoverflow.com/questions/26070058/how-to-get-notification-if-system-preferences-default-sound-changed
	AudioObjectPropertyAddress deviceAddress = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	if (AudioObjectAddPropertyListener(kAudioObjectSystemObject, 
										&deviceAddress,
										MyAudioDevicesListener,
										nil))
		warning("failed to set output device notification");
	deviceAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
	if (AudioObjectAddPropertyListener(kAudioObjectSystemObject, 
									&deviceAddress,
									MyAudioDevicesListener,
									nil))
		warning("failed to set input device notification");

	self.bufferSizeForOutput = SqueakFrameSize * nChannels * frameCount * 2;
	for (int i = 0; i < kNumberOfBuffers; ++i)
		if (AudioQueueAllocateBuffer(self.outputAudioQueue,
									 self.bufferSizeForOutput/16,
									 &self.outputBuffers[i]))
			return 0; /* Causes primitive failure in primitiveSoundStart[WithSemaphore] */

	return 1;
}

- (sqInt) snd_Stop {
	if (!self.outputIsRunning)
		return 1;
	//NSLog(@"%i sound stop",ioMSecs());
	self.outputIsRunning = NO;
	if (!self.outputAudioQueue) 
		return 0;
	OSStatus result = AudioQueueStop (self.outputAudioQueue,true);  //This implicitly invokes AudioQueueReset
	if (result) 
		return 0;
	return 1;
}

- (void) snd_Stop_Force {
	if (!self.outputAudioQueue) 
		return;
	//NSLog(@"%i sound stop force",ioMSecs());
	OSStatus result = AudioQueueStop (self.outputAudioQueue,true);  //This implicitly invokes AudioQueueReset
#pragma unused(result)
}

- (sqInt)	snd_StopAndDispose {
	//NSLog(@"%i sound stopAndDispose",ioMSecs());
	if (!self.outputAudioQueue) 
		return 0;

	[self snd_Stop];
	OSStatus result  = AudioQueueDispose (self.outputAudioQueue,true);
#pragma unused(result)
	self.outputAudioQueue = nil;
	self.soundOutQueue = AUTORELEASEOBJ([[Queue alloc] init]);
	return 1;
}

- (sqInt)	snd_PlaySilence {
	return -1; /* Causes primitive failure in primitiveSoundPlaySilence */
}

- (sqInt)	snd_AvailableSpace {
	if (!self.outputAudioQueue) return -1; /* causes primitive failure in primitiveSoundAvailableSpace */
	if ([self.soundOutQueue pendingElements] > 2) return 0;
	return self.bufferSizeForOutput;
}

- (sqInt)	snd_PlaySamplesFromAtLength: (sqInt) frameCount arrayIndex: (char *) arrayIndex startIndex: (usqInt) startIndex {
	OSStatus result;
	usqInt byteCount= frameCount * SqueakFrameSize;

	if (!self.outputAudioQueue || frameCount <= 0 || startIndex > byteCount) 
		return -1; /* Causes primtive failure in primitiveSoundPlaySamples */
	//NSLog(@"%i sound place samples on queue frames %i startIndex %i count %i",ioMSecs(),frameCount,startIndex,byteCount-startIndex);

	soundAtom *atom = AUTORELEASEOBJ([[soundAtom alloc] initWith: arrayIndex+startIndex count: (unsigned) (byteCount-startIndex)]);
	[self.soundOutQueue addItem: atom];

	if (!self.outputIsRunning) {
		for (int i = 0; i < kNumberOfBuffers; ++i)
			MyAudioQueueOutputCallback(self,self.outputAudioQueue,self.outputBuffers[i]);
		UInt32 outNumberOfFramesPrepared;
		AudioQueuePrime(self.outputAudioQueue,0,&outNumberOfFramesPrepared);
		result = AudioQueueStart (self.outputAudioQueue,NULL);
		//Force it as running
		self.outputIsRunning = YES;
	}
	return 1;
}

- (sqInt)	snd_InsertSamplesFromLeadTime: (sqInt) frameCount srcBufPtr: (char*) srcBufPtr samplesOfLeadTime: (sqInt) samplesOfLeadTime {
	//NOT IMPLEMEMENTED 
	return 0;
}

- (sqInt)	snd_StartRecording: (sqInt) desiredSamplesPerSec stereo: (sqInt) stereo semaIndex: (sqInt) semaIndex {

	if (desiredSamplesPerSec <= 0 || stereo < 0 || stereo > 1) 
		return interpreterProxy->primitiveFailFor(PrimErrBadArgument);

	if (!ensureMicrophoneAccess())
		return -1;

	if (self.inputAudioQueue)
		[self snd_StopRecording];

	self.semaIndexForInput = semaIndex;
	self.inputSampleRate = (float) desiredSamplesPerSec;
	sqInt frameCount = 5288 * desiredSamplesPerSec / 44100;
	self.inputChannels = 1 + stereo;
	self.inputFormat->mSampleRate = (Float64)desiredSamplesPerSec;
	self.inputFormat->mFormatID = kAudioFormatLinearPCM;
	self.inputFormat->mFormatFlags = kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked ;

	self.inputFormat->mBytesPerPacket   = SqueakFrameSize / (3 - self.inputChannels);
	self.inputFormat->mFramesPerPacket  = 1;
	self.inputFormat->mBytesPerFrame    = SqueakFrameSize / (3 - self.inputChannels);
	self.inputFormat->mChannelsPerFrame = self.inputChannels;
	self.inputFormat->mBitsPerChannel   = 16;

	self.bufferSizeForInput = SqueakFrameSize * self.inputChannels * frameCount * 2 / 4;   
	//Currently squeak does this thing where it stops yet leaves data in queue, this causes us to loose data if the buffer is too big

	AudioQueueRef newQueue;

	if (AudioQueueNewInput(self.inputFormat, &MyAudioQueueInputCallback,
						   (__bridge void*)self, NULL, NULL, 0, &newQueue))
		return interpreterProxy->primitiveFail();

	self.inputAudioQueue = newQueue;

	for (int i = 0; i < kNumberOfBuffers; ++i)
		if (AudioQueueAllocateBuffer(self.inputAudioQueue, self.bufferSizeForInput, &self.inputBuffers[i])
		 || AudioQueueEnqueueBuffer(self.inputAudioQueue,self.inputBuffers[i],0,NULL))
			return interpreterProxy->primitiveFail();

	inputIsRunning = 1;
	return AudioQueueStart(self.inputAudioQueue,NULL)
			? interpreterProxy->primitiveFail()
			: 1;
}

- (sqInt)	snd_StopRecording {

	if (!ensureMicrophoneAccess()
	 || !self.inputAudioQueue) 
		return 0;

	self.inputIsRunning = 0;
	OSStatus result = AudioQueueStop (self.inputAudioQueue,true);  //This implicitly invokes AudioQueueReset
	if (result) 
		return 0;
	result = AudioQueueDispose (self.inputAudioQueue,true);
	self.inputAudioQueue = nil;
	self.soundInQueue = AUTORELEASEOBJ([[Queue alloc] init]);
	return 1;
}

- (double) snd_GetRecordingSampleRate {

	if (!ensureMicrophoneAccess()
	 || !self.inputAudioQueue) 
		return interpreterProxy->primitiveFail();

	return inputSampleRate;
}

- (sqInt)	snd_RecordSamplesIntoAtLength: (char*) arrayIndex startSliceIndex: (usqInt) startSliceIndex bufferSizeInBytes: (usqInt) bufferSizeInBytes {

	usqInt	count;

	if (!ensureMicrophoneAccess()
	 || !self.inputAudioQueue
	 || startSliceIndex > bufferSizeInBytes) 
		return interpreterProxy->primitiveFail();

	usqInt    start = startSliceIndex * SqueakFrameSize / 2;
	soundAtom	*atom = [self.soundInQueue returnOldest];
	if (!atom) 
		return 0;
	if (bufferSizeInBytes-start >= atom.byteCount
	 && atom.startOffset == 0) {
		atom = [self.soundInQueue returnAndRemoveOldest];
		memcpy(arrayIndex+start,atom.data,atom.byteCount);
		count= MIN(atom.byteCount, bufferSizeInBytes - start);
        RELEASEOBJ(atom);
		return count / (SqueakFrameSize / 2) / self.inputChannels;
	}
	count= MIN(atom.byteCount-atom.startOffset, bufferSizeInBytes - start);
	memcpy(arrayIndex+start,atom.data+atom.startOffset,count);
	atom.startOffset = atom.startOffset + (count);
	if (atom.startOffset == atom.byteCount) {
		atom = [self.soundInQueue returnAndRemoveOldest]; //ignore now it's empty
		RELEASEOBJ(atom);
	}
	return count / (SqueakFrameSize / 2) / self.inputChannels;
}

// Terf SqSoundVersion 1.2 improvements
// snd_SetRecordBufferFrameCount unused in SoundPlugin
- (sqInt)	snd_SetRecordBufferFrameCount: (sqInt) frameCount { return -1; }

#define IsInput 1
#define IsOutput 2

#define isInput(i) (deviceTypes[i] & IsInput)
#define isOutput(i) (deviceTypes[i] & IsOutput)

#define defaultInputDevice()  getDefaultDevice(IsInput)
#define defaultOutputDevice() getDefaultDevice(IsOutput)


/* Apple supports a default input device and both a default and a system
 * output device.  [More logical would be to have both default and system input
 * and output devices, no?].  This routine answers the default input device
 * and either the default or the system output device, depending on the define.
 *
 * In our experiments the system output device doesn't seem to be meaningful.
 * When we plugged in a headphone set but selected Display Audio for both input
 * and output, the headset remained identified as the System output define.
 * Go figure.  So we default to identifying the default output device.
 */
#if !defined(DeriveDefaultFromSystemOutput)
# define DeriveDefaultFromSystemOutput 0
#endif

static AudioDeviceID
getDefaultDevice(int which)
{
	AudioDeviceID	deviceID;
	UInt32			size = sizeof(deviceID);

	AudioObjectPropertyAddress
		getDefault = {	which == IsInput
							? kAudioHardwarePropertyDefaultInputDevice
#if DeriveDefaultFromSystemOutput
							: kAudioHardwarePropertyDefaultSystemOutputDevice,
#else
							: kAudioHardwarePropertyDefaultOutputDevice,
#endif
						kAudioObjectPropertyScopeGlobal,
						kAudioObjectPropertyElementMaster };
	return
		AudioObjectGetPropertyData(kAudioObjectSystemObject, &getDefault,
									0, nil, &size, &deviceID)
		? (AudioDeviceID)-1
		: deviceID;
}


AudioDeviceID
setDefaultDevice(AudioDeviceID deviceID, int which)
{
	AudioObjectPropertyAddress
		setDefault = {	which == IsInput
							? kAudioHardwarePropertyDefaultInputDevice
							: kAudioHardwarePropertyDefaultOutputDevice,
						kAudioObjectPropertyScopeGlobal,
						kAudioObjectPropertyElementMaster };
	return
		AudioObjectSetPropertyData(kAudioObjectSystemObject, &setDefault,
									0, nil, sizeof(deviceID), &deviceID)
		? (AudioDeviceID)-1
		: deviceID;
}

// See http://stackoverflow.com/questions/11041335/how-do-you-set-the-input-level-gain-on-the-built-in-input-osx-core-audio-au
float
getVolumeOf(AudioDeviceID deviceID, char which)
{
	AudioObjectPropertyAddress	address;
	OSStatus					err1, err2;
	Boolean						hasVolume1, hasVolume2;
	Float32						volume1, volume2;
	UInt32						size = sizeof(Float32);

	// get the input device stereo channels
	address.mSelector = kAudioDevicePropertyVolumeScalar;
	address.mScope = which == IsInput
						? kAudioDevicePropertyScopeInput
						: kAudioDevicePropertyScopeOutput;
	address.mElement = kAudioObjectPropertyElementMaster;

	// If there's a master volume, answer that...
	if (AudioObjectHasProperty(deviceID, &address))
		return AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume1)
			? -1.0f
			: volume1;

	// Otherwise get each channel individually (assuming stereo) and answer average
	address.mElement = 1;
	if ((hasVolume1 = AudioObjectHasProperty(deviceID, &address)))
		err1 = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume1);
	address.mElement = 2;
	if ((hasVolume2 = AudioObjectHasProperty(deviceID, &address)))
		err2 = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume2);

	if (hasVolume1 && hasVolume2)
		return err1 || err2 ? -1.0f : (volume1 + volume2) / 2.0f;

	if (hasVolume1 && !err1)
		return volume1;

	if (hasVolume2 && !err2)
		return volume2;

	return -1.0f;
}

float
setVolumeOf(AudioDeviceID deviceID, char which, float volume)
{
	AudioObjectPropertyAddress	address;
	OSStatus					err1, err2;
	Boolean						hasVolume1, hasVolume2;
	Float32						volume1 = volume, volume2 = volume;
	Boolean						settable;

	// get the input device stereo channels
	address.mSelector = kAudioDevicePropertyVolumeScalar;
	address.mScope = which == IsInput
						? kAudioDevicePropertyScopeInput
						: kAudioDevicePropertyScopeOutput;
	address.mElement = kAudioObjectPropertyElementMaster;

	// If there's a master volume control use that...
	if (!AudioObjectIsPropertySettable(deviceID, &address, &settable)
	 && settable)
		return AudioObjectSetPropertyData(deviceID, &address, 0, nil, sizeof(Float32), &volume1)
			? -1.0f
			: volume1;

	// Otherwise set each channel individually (assuming stereo)
	address.mElement = 1;
	if ((hasVolume1 = AudioObjectHasProperty(deviceID, &address)))
		err1 = AudioObjectSetPropertyData(deviceID, &address, 0, nil, sizeof(Float32), &volume1);
	address.mElement = 2;
	if ((hasVolume2 = AudioObjectHasProperty(deviceID, &address)))
		err2 = AudioObjectSetPropertyData(deviceID, &address, 0, nil, sizeof(Float32), &volume2);

	if (hasVolume1 && hasVolume2)
		return err1 || err2 ? -1.0f : (volume1 + volume2) / 2.0f;

	if (hasVolume1 && !err1)
		return volume1;

	if (hasVolume2 && !err2)
		return volume2;

	return -1.0f;
}


// This API is poor.  The Mac has separate input levels for separate devices.
// For now just answer the input level on the default input device.
// See http://stackoverflow.com/questions/11041335/how-do-you-set-the-input-level-gain-on-the-built-in-input-osx-core-audio-au

// SoundPlugin expects a result in the range 0-1000.
// getVolumeOf answers 0..1 for devices with a volume & -1 for those without.
// So fail the primitive for both no default input device and for a device that
// has no input volume.
- (int)	snd_GetRecordLevel {
	Float32 volume;

	if ((volume = getVolumeOf(defaultInputDevice(), IsInput)) < 0) {
		interpreterProxy->primitiveFail();
		return -1;
	}

	return (int)(volume * 1000.0f);
}
- (void) snd_SetRecordLevel: (sqInt) level  {

	if (setVolumeOf(defaultInputDevice(), IsInput, level / 1000.0f) < 0)
		interpreterProxy->primitiveFail();
}

- (float)	snd_GetOutputLevel {
	Float32 volume;

	if ((volume = getVolumeOf(defaultOutputDevice(), IsOutput)) < 0)
		interpreterProxy->primitiveFail();

	return volume;
}
- (void) snd_SetOutputLevel: (float) level  {

	if (setVolumeOf(defaultOutputDevice(), IsOutput, level) < 0)
		interpreterProxy->primitiveFail();
}

- (void) ensureDeviceList {
	AudioObjectPropertyAddress
	getName = {	kAudioObjectPropertyName,
				kAudioObjectPropertyScopeGlobal,
				kAudioObjectPropertyElementMaster },
#if TerfVM
	getUID = {	kAudioDevicePropertyDeviceUID,
				kAudioObjectPropertyScopeGlobal,
				kAudioObjectPropertyElementMaster },
#endif
	getDevices = {	kAudioHardwarePropertyDevices,
					kAudioObjectPropertyScopeGlobal,
					kAudioObjectPropertyElementMaster },
	getInputStreams = {	kAudioDevicePropertyStreams,
						kAudioDevicePropertyScopeInput,
						kAudioObjectPropertyElementMaster },
	getOutputStreams = {	kAudioDevicePropertyStreams,
							kAudioDevicePropertyScopeOutput,
							kAudioObjectPropertyElementMaster },
	setCallback = {					kAudioStreamPropertyAvailablePhysicalFormats,
									kAudioObjectPropertyScopeGlobal,
									kAudioObjectPropertyElementMaster };
	int i;

	if (deviceIDs
	 && rebuildRequest == rebuildCount)
		return;

	if (deviceIDs) {
		free(deviceIDs);
		for (i = 0; i < numDevices; i++)
			free(deviceNames[i]);
#if TerfVM
		for (i = 0; i < numDevices; i++)
			free(deviceUIDs[i]);
		free(deviceUIDs);
#endif
		free(deviceNames);
		free(deviceTypes);
		deviceIDs = 0;
		deviceNames = 0;
		deviceTypes = 0;
		numDevices = 0;
	}
	rebuildCount = rebuildRequest;

	// First get the device IDs and compute numDevices
	UInt32 datasize = 0;
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject,
										&getDevices, 0, nil, &datasize))
		return;
	numDevices = datasize / sizeof(AudioDeviceID);
	if (numDevices == 0
	 || !(deviceIDs = calloc(numDevices, sizeof(AudioDeviceID)))) {
		numDevices = 0;
		return;
	}
	if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &getDevices,
								   0, nil, &datasize, (AudioDeviceID *)deviceIDs)

	 || !(deviceNames = calloc(numDevices, sizeof(char *)))
#if TerfVM
	 || !(deviceUIDs  = calloc(numDevices, sizeof(char *)))
#endif
	 || !(deviceTypes = calloc(numDevices, sizeof(char)))) {
		free(deviceIDs);
		if (deviceNames)
			free(deviceNames);
		if (deviceUIDs)
			free(deviceUIDs);
		deviceIDs = 0;
		deviceNames = 0;
		deviceUIDs = 0;
		numDevices = 0;
		return;
	}

	// Then get the names and types, and register the device changed listener.
	for (i = 0; i < numDevices; i++) {
		CFStringRef nameRef;
        CFIndex length;

        if (AudioObjectGetPropertyDataSize(deviceIDs[i], &getName,
											0, nil, &datasize)
		 || AudioObjectGetPropertyData    (deviceIDs[i], &getName,
											0, nil, &datasize, &nameRef))
			error("could not get sound device name");

        length = CFStringGetLength(nameRef) + 1;
        deviceNames[i] = (char *)malloc(length);
        CFStringGetCString(nameRef, deviceNames[i], length, kCFStringEncodingUTF8);
		deviceNames[i][length - 1] = 0;
#if TerfVM
        if (AudioObjectGetPropertyDataSize(deviceIDs[i], &getUID,
											0, nil, &datasize)
		 || AudioObjectGetPropertyData    (deviceIDs[i], &getUID,
											0, nil, &datasize, &nameRef))
			error("could not get sound device UID");

        length = CFStringGetLength(nameRef) + 1;
        deviceUIDs[i] = (char *)malloc(length);
        CFStringGetCString(nameRef, deviceUIDs[i], length, kCFStringEncodingUTF8);
		deviceUIDs[i][length - 1] = 0;
#endif
    	if (AudioObjectGetPropertyDataSize(deviceIDs[i], &getInputStreams,
											0, NULL, &datasize))
			error("could not get sound device input stream info");
		if (datasize > 0)
			deviceTypes[i] = IsInput;

    	if (AudioObjectGetPropertyDataSize(deviceIDs[i], &getOutputStreams,
											0, NULL, &datasize))
			error("could not get sound device output stream info");
		if (datasize > 0)
			deviceTypes[i] |= IsOutput;

		// Since this is done every time the device list is rebuilt, and since it
		// errors if done more than once, we ignore errors.  If anyone knows how
		// to query the existing listener then please modify this to check if a
		// listener needs to be added.
		(void)AudioObjectAddPropertyListener(deviceIDs[i], &setCallback,
											 MyAudioDevicesListener, 0);
	}
}

- (sqInt) getNumberOfSoundPlayerDevices {
	[self ensureDeviceList];
	int n = 0;
	for (int i = 0; i < numDevices; i++)
		if (isOutput(i))
			++n;
	return n;
}

- (sqInt) getNumberOfSoundRecorderDevices {
	[self ensureDeviceList];
	int n = 0;
	for (int i = 0; i < numDevices; i++)
		if (isInput(i))
			++n;
	return n;
}

- (char *) getDefaultSoundPlayer {

	[self ensureDeviceList];
	AudioObjectID deviceID = defaultOutputDevice();

	for (int i = 0; i < numDevices; i++)
		if (deviceIDs[i] == deviceID
		 && isOutput(i))
			return deviceNames[i];

	return 0;
}

- (char *) getDefaultSoundRecorder {

	[self ensureDeviceList];
	AudioObjectID deviceID = defaultInputDevice();

	for (int i = 0; i < numDevices; i++)
		if (deviceIDs[i] == deviceID
		 && isInput(i))
			return deviceNames[i];

	return 0;
}

- (char *) getSoundPlayerDeviceName: (sqInt) di {
	[self ensureDeviceList];
	for (int i = 0, n = 0; i < numDevices; i++)
		if (isOutput(i)
		 && n++ == di)
			return deviceNames[i];
	return 0;
}

- (char *) getSoundRecorderDeviceName: (sqInt) di {
	[self ensureDeviceList];
	for (int i = 0, n = 0; i < numDevices; i++)
		if (isInput(i)
		 && n++ == di)
			return deviceNames[i];
	return 0;
}

#if TerfVM
- (char *) getSoundPlayerDeviceUID: (sqInt) di {
	[self ensureDeviceList];
	for (int i = 0, n = 0; i < numDevices; i++)
		if (isOutput(i)
		 && n++ == di)
			return deviceUIDs[i];
	return 0;
}

- (char *) getSoundRecorderDeviceUID: (sqInt) di {
	[self ensureDeviceList];
	for (int i = 0, n = 0; i < numDevices; i++)
		if (isInput(i)
		 && n++ == di)
			return deviceUIDs[i];
	return 0;
}
#endif // TerfVM

- (void) setDefaultSoundPlayer: (char *) deviceName {
	[self ensureDeviceList];

	for (int i = 0; i < numDevices; i++)
		if (isOutput(i)
		 && !strcmp(deviceName, deviceNames[i])) {
			if (setDefaultDevice(deviceIDs[i], IsOutput) != deviceIDs[i])
				interpreterProxy->primitiveFail();
			return;
		}
}

- (void) setDefaultSoundRecorder: (char *) deviceName {
	[self ensureDeviceList];

	for (int i = 0; i < numDevices; i++)
		if (isInput(i)
		 && !strcmp(deviceName, deviceNames[i])) {
			if (setDefaultDevice(deviceIDs[i], IsInput) != deviceIDs[i])
				interpreterProxy->primitiveFail();
			return;
		}
}

// For now simply don't attempt AEC. The web discussion is spotty and confusing.
// So far we've only found AGC (automatic gain control) support.
- (sqInt) snd_SupportsAEC { return 0; }

- (sqInt) snd_EnableAEC: (sqInt) flag { return -1; }

@end
