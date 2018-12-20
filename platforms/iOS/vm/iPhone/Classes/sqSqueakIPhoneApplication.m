//
//  sqSqueakIPhoneApplication.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 6/19/08.
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
//

#import "sqSqueakIPhoneApplication.h"
#import "sqSqueakAppDelegate.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"

usqInt	gMaxHeapSize=32*1024*1024;
extern sqSqueakAppDelegate *gDelegateApp;

@implementation sqSqueakIPhoneApplication
- (sqSqueakFileDirectoryInterface *) newFileDirectoryInterfaceInstance {
	return [[sqSqueakIPhoneFileDirectoryInterface alloc] init];
}

- (sqSqueakInfoPlistInterface *) newSqSqueakInfoPlistInterfaceCreation {
	return [[sqSqueakIPhoneInfoPlistInterface alloc] init];
}

- (void) doMemorySetup {
	gMaxHeapSize =  [(sqSqueakIPhoneInfoPlistInterface*) self.infoPlistInterfaceLogic memorySize];
	if (gMaxHeapSize == 0) // NO IDEA is this a 4.1 bug? 
		gMaxHeapSize = 32*1024*1024;
		
}

- (void) fetchPreferences {
	[super fetchPreferences];
	extern char gSqueakUntrustedDirectoryName[];
	extern char gSqueakTrustedDirectoryName[];
	strlcpy(gSqueakUntrustedDirectoryName, "/foobar/tooBar/forSqueak/bogus/",PATH_MAX);
	strlcpy(gSqueakTrustedDirectoryName, "/foobar/tooBar/forSqueak/bogus/",PATH_MAX);
}

@end


/* Profiling. */
void  ioProfileStatus(sqInt *running, void **exestartpc, void **exelimitpc,
					  void **vmhst, long *nvmhbin, void **eahst, long *neahbin) {};
void  ioControlProfile(int on, void **vhp, long *nvb, void **ehp, long *neb) {};
long  ioControlNewProfile(int on, unsigned long buffer_size) {return 0;};
void  ioNewProfileStatus(sqInt *running, long *buffersize) {};
long  ioNewProfileSamplesInto(void *sampleBuffer) {return 0;};
void  ioClearProfile(void) {};
