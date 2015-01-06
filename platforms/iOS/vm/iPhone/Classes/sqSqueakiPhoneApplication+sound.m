//
//  sqSqueakIPhoneApplication+sound.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/31/08.
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


/* Note iphone mic is 8 Khz mono, question is where the audio comes froms and goes to 
 technically has two speakers, telephone receiver, speaker, plus headphones, plus bluetooth
 plus to a doc and audio out, or USB out!  note the ringer controlls and volme controls 
 
 Lots of this is user interaction, don't want the user to manage things if they fiddle with 
 hardware plug in/out adjust switchs
 
 ipod can play in background, where is audio routed 
 
 Oh and ipod touch and iphone are different, iphone has many audio paths/routings
 
 interrupt listener, begin/end when alarm, begin on phone start, but app then gets terminated so you don't get end
 
 look for audio session current hardware settings to see what the hardware has, ie 44khz input or 8kHz input?
 look for audio route changing, you get audio route change notification
 
 */


#import "sqSqueakIPhoneApplication+sound.h"
#import <AudioToolbox/AudioToolbox.h> 
#import <UIKit/UIKit.h>

@implementation sqSqueakIPhoneApplication (sound)
- (void) ioBeep {
#if TARGET_OS_IPHONE
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
#else	
	AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert);
#endif
	/*Note:System-suppliedalertsoundsandsystem-supplieduser-interfacesoundeffectsarenotavailable 
	 iniPhoneOS.Forexample,usingthekSystemSoundID_UserPreferredAlertconstantasaparameter 
	 totheAudioServicesPlayAlertSoundfunctionwillnotplayanything. */
#warning this does nothing on the iPod Touch 
}

@end

