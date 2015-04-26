//
//  sqSqueakOSXSoundCoreAudio.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-27.
/* Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 //  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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
 *///

#import "sqSqueakOSXSoundCoreAudio.h"


@implementation sqSqueakOSXSoundCoreAudio
-	(sqInt) soundInit {
	return 1;
}

-	(sqInt) soundInitOverride {
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

@end
