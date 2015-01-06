/*
 *  sqSqueakSoundCoreAudioAPI.c
 *  SqueakNoOGLIPhone
 *
  Created by John M McIntosh on 11/10/08.
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
//

#import "sqSqueakSoundCoreAudioAPI.h"
#import "sqSqueakAppDelegate.h"

extern sqSqueakAppDelegate *gDelegateApp;

sqInt soundInit(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic soundInit];
}

sqInt soundShutdown(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic soundShutdown];
}

/* sound output */
sqInt snd_AvailableSpace(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_AvailableSpace];
}
sqInt snd_InsertSamplesFromLeadTime(sqInt frameCount, void * srcBufPtr, sqInt samplesOfLeadTime){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_InsertSamplesFromLeadTime: frameCount srcBufPtr: (char *)srcBufPtr samplesOfLeadTime: samplesOfLeadTime];
}
sqInt snd_PlaySamplesFromAtLength(sqInt frameCount, void * arrayIndex, sqInt startIndex){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_PlaySamplesFromAtLength: frameCount arrayIndex: (char*) arrayIndex startIndex: (usqInt) startIndex];
}
sqInt snd_PlaySilence(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_PlaySilence];
}
sqInt snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_Start: frameCount samplesPerSec: samplesPerSec stereo: stereo semaIndex: semaIndex];
}
sqInt snd_Stop(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_Stop];
}

/* sound input */
void snd_SetRecordLevel(sqInt level){}

sqInt snd_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_StartRecording:desiredSamplesPerSec stereo: stereo semaIndex: semaIndex ];
}
sqInt snd_StopRecording(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_StopRecording];
}
double snd_GetRecordingSampleRate(void){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_GetRecordingSampleRate];
}
sqInt snd_RecordSamplesIntoAtLength(void * buf, sqInt startSliceIndex, sqInt bufferSizeInBytes){
	return [gDelegateApp.squeakApplication.soundInterfaceLogic snd_RecordSamplesIntoAtLength:(char *) buf startSliceIndex: (usqInt) startSliceIndex bufferSizeInBytes: (usqInt) bufferSizeInBytes];
}


void snd_Volume(double *left, double *right){} 
void snd_SetVolume(double left, double right){}