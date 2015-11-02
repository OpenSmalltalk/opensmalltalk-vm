//
//  sqSqueakSoundCoreAudio.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 11/10/08.
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
 Software is furnished to do so, subject to the following
 conditions:
 
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
 
 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */

#import "sqSqueakSoundCoreAudio.h"

#define SqueakFrameSize	4	// guaranteed (see class SoundPlayer)
extern struct VirtualMachine* interpreterProxy;

void MyAudioQueueOutputCallback (sqSqueakSoundCoreAudio *inUserData,
AudioQueueRef        inAQ,
								 AudioQueueBufferRef  inBuffer);

void MyAudioQueueOutputCallback (sqSqueakSoundCoreAudio *myInstance,
								 AudioQueueRef        inAQ,
								 AudioQueueBufferRef  inBuffer) {
	
	soundAtom	*atom = [myInstance.soundOutQueue returnOldest];
	
	if (!atom) {
		inBuffer->mAudioDataByteSize   = MIN(inBuffer->mAudioDataBytesCapacity,2644);
		memset(inBuffer->mAudioData,0,inBuffer->mAudioDataByteSize);
//NSLog(@"%i Fill sound buffer with zero %i bytes",ioMSecs(),inBuffer->mAudioDataByteSize);
	} else {
		if (inBuffer->mAudioDataBytesCapacity >= atom.byteCount) {
			atom = [myInstance.soundOutQueue returnAndRemoveOldest];
			inBuffer->mAudioDataByteSize = (int) atom.byteCount;
			memcpy(inBuffer->mAudioData,atom.data,atom.byteCount);
            RELEASEOBJ(atom);
//NSLog(@"%i Fill sound buffer with %i bytesA",ioMSecs(),inBuffer->mAudioDataByteSize);
		} else {
			inBuffer->mAudioDataByteSize = (int) MIN(atom.byteCount - atom.startOffset,inBuffer->mAudioDataBytesCapacity);
			memcpy(inBuffer->mAudioData,atom.data+atom.startOffset,inBuffer->mAudioDataByteSize);
			atom.startOffset = atom.startOffset + inBuffer->mAudioDataByteSize;
			if (atom.startOffset == atom.byteCount) {
				atom = [myInstance.soundOutQueue returnAndRemoveOldest]; //ignore now it's empty
                RELEASEOBJ(atom);
			}
//NSLog(@"%i Fill sound buffer with %i bytesB",ioMSecs(),inBuffer->mAudioDataByteSize);
		}
	}
	AudioQueueEnqueueBuffer(inAQ,inBuffer,0,nil);			
	interpreterProxy->signalSemaphoreWithIndex(myInstance.semaIndexForOutput);	
	
}
void	MyAudioQueuePropertyListenerProc (  void *              inUserData,
											AudioQueueRef           inAQ,
										  AudioQueuePropertyID    inID);

void	MyAudioQueuePropertyListenerProc (  void *              inUserData,
										  AudioQueueRef           inAQ,
										  AudioQueuePropertyID    inID)
{
	sqInt	isRunning;
	UInt32 size = sizeof(isRunning);
	sqSqueakSoundCoreAudio * myInstance = (__bridge  sqSqueakSoundCoreAudio *)inUserData;

	AudioQueueGetProperty (inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
	myInstance.outputIsRunning = isRunning;
	//NSLog(@"%i Is Running %i",ioMSecs(),isRunning);

}

void MyAudioQueueInputCallback (
								void                                *inUserData,
								AudioQueueRef                       inAQ,
								AudioQueueBufferRef                 inBuffer,
								const AudioTimeStamp                *inStartTime,
								UInt32                              inNumberPacketDescriptions,
								const AudioStreamPacketDescription  *inPacketDescs);

void MyAudioQueueInputCallback (
								void                                *inUserData,
								AudioQueueRef                       inAQ,
								AudioQueueBufferRef                 inBuffer,
								const AudioTimeStamp                *inStartTime,
								UInt32                              inNumberPacketDescriptions,
								const AudioStreamPacketDescription  *inPacketDescs) {
	
	sqSqueakSoundCoreAudio * myInstance = (__bridge  sqSqueakSoundCoreAudio *)inUserData;
	
	if (!myInstance.inputIsRunning) 
		return;
	
	if (inNumberPacketDescriptions > 0) {
		soundAtom *atom = AUTORELEASEOBJ([[soundAtom alloc] initWith: inBuffer->mAudioData count: inBuffer->mAudioDataByteSize]);
		[myInstance.soundInQueue addItem: atom];
    }
	
	AudioQueueEnqueueBuffer (inAQ,
								 inBuffer,
								 0,
								 NULL
								 );
	interpreterProxy->signalSemaphoreWithIndex(myInstance.semaIndexForInput);	
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

- (void)dealloc {
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
	self.outputBuffers = calloc((unsigned)kNumberOfBuffers,sizeof(AudioQueueBufferRef));
	self.inputBuffers = calloc((unsigned) kNumberOfBuffers,sizeof(AudioQueueBufferRef));
	soundOutQueue = [[Queue alloc] init];
	soundInQueue = [[Queue alloc] init];
	return 1;
}

- (sqInt) soundShutdown {
	//NSLog(@"%i sound shutdown",ioMSecs());
	if (self.outputAudioQueue) {
		[self snd_StopAndDispose];
	}
	if (self.inputAudioQueue) {
		[self snd_StopRecording];
	}
	return 1;
}

- (sqInt)	snd_Start: (sqInt) frameCount samplesPerSec: (sqInt) samplesPerSec stereo: (sqInt) stereo semaIndex: (sqInt) semaIndex {
	//NSLog(@"%i sound start playing frame count %i samples %i",ioMSecs(),frameCount,samplesPerSec);
	OSStatus result;
	int nChannels= 1 + (int)stereo;
	
	if (frameCount <= 0 || samplesPerSec <= 0 || stereo < 0 || stereo > 1) 
		return interpreterProxy->primitiveFail();

	self.semaIndexForOutput = semaIndex;
	AudioStreamBasicDescription check;
	bzero(&check,sizeof(AudioStreamBasicDescription));
	
	check.mSampleRate = (Float64)samplesPerSec;
	check.mFormatID = kAudioFormatLinearPCM;
	check.mFormatFlags = kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsSignedInteger;
	check.mBytesPerPacket   = SqueakFrameSize / (3 - nChannels);
	check.mFramesPerPacket  = 1;
	check.mBytesPerFrame    = SqueakFrameSize / (3 - nChannels);
	check.mChannelsPerFrame = nChannels;
	check.mBitsPerChannel   = 16;
	
	/* we want to create a new audio queue only if we have to */
	
	if (self.outputAudioQueue == nil || (memcmp(&check,self.outputFormat,(size_t)(sizeof(AudioStreamBasicDescription) != 0)))) {	
		AudioQueueRef newQueue;
		//NSLog(@"%i create new audioqueue",ioMSecs());
		if (self.outputAudioQueue) 
			[self snd_StopAndDispose];
		*self.outputFormat = check;
		result =  AudioQueueNewOutput (self.outputFormat, (void*) &MyAudioQueueOutputCallback,
								   (__bridge void*) self,
								   NULL,
								   NULL,
								   0,
								   &newQueue);
	
		if (result) 
			return interpreterProxy->primitiveFail();
		self.outputAudioQueue = newQueue;
	
		AudioQueueAddPropertyListener (self.outputAudioQueue, kAudioQueueProperty_IsRunning, MyAudioQueuePropertyListenerProc, (__bridge void *)(self));
	
		self.bufferSizeForOutput = (unsigned) (SqueakFrameSize * nChannels * frameCount * 2);
		int i;
		for (i = 0; i < kNumberOfBuffers; ++i) {
			result = AudioQueueAllocateBuffer(self.outputAudioQueue, self.bufferSizeForOutput/16, &self.outputBuffers[i]);
			if(result)
				return interpreterProxy->primitiveFail();
		}
	} else {
		//NSLog(@"%i reuse audioqueue",ioMSecs());
	}
		
	return 1;
}

- (sqInt)	snd_Stop {
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
	//NSLog(@"%i sound play silence",ioMSecs());
	interpreterProxy->success(false);
	return 8192;
	
}

- (sqInt)	snd_AvailableSpace {
	if (!self.outputAudioQueue) return interpreterProxy->primitiveFail();
	if ([self.soundOutQueue pendingElements] > 2) return 0;
	return self.bufferSizeForOutput;
}

- (sqInt)	snd_PlaySamplesFromAtLength: (sqInt) frameCount arrayIndex: (char *) arrayIndex startIndex: (usqInt) startIndex {
	OSStatus result;
	usqInt byteCount= frameCount * SqueakFrameSize;
	
	if (!self.outputAudioQueue) 
		return interpreterProxy->primitiveFail();
	if (frameCount <= 0 || startIndex > byteCount) 
		return interpreterProxy->primitiveFail();
	//NSLog(@"%i sound place samples on queue frames %i startIndex %i count %i",ioMSecs(),frameCount,startIndex,byteCount-startIndex);
		
	soundAtom *atom = AUTORELEASEOBJ([[soundAtom alloc] initWith: arrayIndex+startIndex count: (unsigned) (byteCount-startIndex)]);
	[self.soundOutQueue addItem: atom];
	
	if (!self.outputIsRunning) {
		int i;
		for (i = 0; i < kNumberOfBuffers; ++i) {
			MyAudioQueueOutputCallback (self,self.outputAudioQueue,self.outputBuffers[i]);
		}
		UInt32 outNumberOfFramesPrepared;
		AudioQueuePrime(self.outputAudioQueue,0,&outNumberOfFramesPrepared);
		result =  AudioQueueStart (self.outputAudioQueue,NULL);
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
		return interpreterProxy->primitiveFail();

	if (self.inputAudioQueue) {
		[self snd_StopRecording];
	}
	
	self.semaIndexForInput = semaIndex;
	self.inputSampleRate = (float) desiredSamplesPerSec;
	sqInt frameCount = 5288 * desiredSamplesPerSec / 44100;
	self.inputChannels = 1 + stereo;
	self.inputFormat->mSampleRate = (Float64)desiredSamplesPerSec;
	self.inputFormat->mFormatID = kAudioFormatLinearPCM;
	self.inputFormat->mFormatFlags = kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsSignedInteger 
		| kAudioFormatFlagIsPacked ;
	
	self.inputFormat->mBytesPerPacket   = (int) SqueakFrameSize / (3 - (int)self.inputChannels);
	self.inputFormat->mFramesPerPacket  = 1;
	self.inputFormat->mBytesPerFrame    =(int)  SqueakFrameSize / (3 - (int)self.inputChannels);
	self.inputFormat->mChannelsPerFrame =(int) self.inputChannels;
	self.inputFormat->mBitsPerChannel   = 16;
	
	self.bufferSizeForInput = (unsigned) (SqueakFrameSize * self.inputChannels * frameCount * 2/4);   
	//Currently squeak does this thing where it stops yet leaves data in queue, this causes us to lose dota if the buffer is too big

	AudioQueueRef newQueue;
	
	OSStatus result =  AudioQueueNewInput (self.inputFormat, &MyAudioQueueInputCallback,
								   (__bridge void*) self,
								   NULL,
								   NULL,
								   0,
								   &newQueue);
	
	if (result) 
		return interpreterProxy->primitiveFail();

	self.inputAudioQueue = newQueue;

	int i;
	for (i = 0; i < kNumberOfBuffers; ++i) {
		result = AudioQueueAllocateBuffer(self.inputAudioQueue, self.bufferSizeForInput, &self.inputBuffers[i]);
		if(result)
			return interpreterProxy->primitiveFail();
		result = AudioQueueEnqueueBuffer(self.inputAudioQueue,self.inputBuffers[i],0,NULL);			
		if(result) 
			return interpreterProxy->primitiveFail();	
	}
	inputIsRunning = 1;
	result =  AudioQueueStart (self.inputAudioQueue,NULL);
	if(result) 
		return interpreterProxy->primitiveFail();	
	return 1;
}

- (sqInt)	snd_StopRecording {
	if (!self.inputAudioQueue) 
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
	if (!self.inputAudioQueue) 
		return interpreterProxy->primitiveFail();

	return inputSampleRate;
}

- (sqInt)	snd_RecordSamplesIntoAtLength: (char*) arrayIndex startSliceIndex: (usqInt) startSliceIndex bufferSizeInBytes: (usqInt) bufferSizeInBytes {
	
	usqInt	count;
	
	if (!self.inputAudioQueue) 
		return interpreterProxy->primitiveFail();
	if (startSliceIndex > bufferSizeInBytes) 
		return interpreterProxy->primitiveFail();

	usqInt    start= startSliceIndex * SqueakFrameSize / 2;
	soundAtom	*atom = [self.soundInQueue returnOldest];
	if (atom == nil) 
		return 0;
	if (bufferSizeInBytes-start >= atom.byteCount && atom.startOffset == 0) {
		atom = [self.soundInQueue returnAndRemoveOldest];
		memcpy(arrayIndex+start,atom.data,atom.byteCount);
		count= MIN(atom.byteCount, bufferSizeInBytes - start);
        RELEASEOBJ(atom);
		return count / (SqueakFrameSize / 2) / self.inputChannels;
	} else {
		count= MIN(atom.byteCount-atom.startOffset, bufferSizeInBytes - start);
		memcpy(arrayIndex+start,atom.data+atom.startOffset,count);
		atom.startOffset = atom.startOffset + (count);
		if (atom.startOffset == atom.byteCount) {
			atom = [self.soundInQueue returnAndRemoveOldest]; //ignore now it's empty
            RELEASEOBJ(atom);
		}
		return count / (SqueakFrameSize / 2) / self.inputChannels;
	}
		
}

@end


