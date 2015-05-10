//
//  sqSqueakSoundCoreAudio.h
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

#import "sq.h"
#import "Queue.h"

#import <AudioToolbox/AudioToolbox.h>

static const int kNumberOfBuffers=4;

@interface sqSqueakSoundCoreAudio : NSObject {
	AudioQueueRef	inputAudioQueue;
	sqInt			semaIndexForInput;
	UInt32			bufferSizeForInput;
	sqInt			inputIsRunning;
	double			inputSampleRate;
	sqInt			inputChannels;
	AudioStreamBasicDescription *inputFormat;
	AudioQueueBufferRef *inputBuffers;
	AudioQueueRef	outputAudioQueue;
	Queue*			soundInQueue;
	sqInt			semaIndexForOutput;
	UInt32			bufferSizeForOutput;
	BOOL			outputIsRunning;
	AudioStreamBasicDescription *outputFormat;
	AudioQueueBufferRef *outputBuffers;
	Queue*			soundOutQueue;
}
- (sqInt)	soundInit;
- (sqInt)	soundShutdown;
- (sqInt)	snd_Start: (sqInt) frameCount samplesPerSec: (sqInt) samplesPerSec stereo: (sqInt) stereo semaIndex: (sqInt) semaIndex;
- (sqInt)	snd_Stop;
- (void)	snd_Stop_Force;
- (sqInt)	snd_StopAndDispose;
- (sqInt)	snd_PlaySilence;
- (sqInt)	snd_AvailableSpace;
- (sqInt)	snd_PlaySamplesFromAtLength: (sqInt) frameCount arrayIndex: (char *) arrayIndex startIndex: (usqInt) startIndex;
- (sqInt)	snd_InsertSamplesFromLeadTime: (sqInt) frameCount srcBufPtr: (char*) srcBufPtr samplesOfLeadTime: (sqInt) samplesOfLeadTime;
- (sqInt)	snd_StartRecording: (sqInt) desiredSamplesPerSec stereo: (sqInt) stereo semaIndex: (sqInt) semaIndex;
- (sqInt)	snd_RecordSamplesIntoAtLength: (char*) arrayIndex startSliceIndex: (usqInt) startSliceIndex bufferSizeInBytes: (usqInt) bufferSizeInBytes;
- (sqInt)	snd_StopRecording;
- (double)	snd_GetRecordingSampleRate;

@property (nonatomic) AudioQueueRef	outputAudioQueue;
@property (nonatomic) AudioQueueRef	inputAudioQueue;
@property (nonatomic) sqInt	semaIndexForOutput;
@property (nonatomic) UInt32 bufferSizeForOutput;
@property (nonatomic) sqInt	semaIndexForInput;
@property (nonatomic) UInt32 bufferSizeForInput;
@property (nonatomic) sqInt inputChannels;
@property (nonatomic) sqInt inputIsRunning;
@property (nonatomic) BOOL outputIsRunning;
@property (nonatomic) double inputSampleRate;
@property (nonatomic) AudioStreamBasicDescription* outputFormat;
@property (nonatomic) AudioStreamBasicDescription* inputFormat;
@property (nonatomic) AudioQueueBufferRef * outputBuffers;
@property (nonatomic) AudioQueueBufferRef * inputBuffers;
@property (nonatomic,strong) Queue* soundOutQueue;
@property (nonatomic,strong) Queue* soundInQueue;
@end

@interface soundAtom : NSObject {
	char	*data; 
	usqInt	byteCount;
	usqInt	startOffset;
}
- (instancetype) initWith: (char*) buffer count: (usqInt) bytes;

@property (nonatomic,assign) char *	data;
@property (nonatomic,assign) usqInt byteCount;
@property (nonatomic,assign) usqInt startOffset;
@end

