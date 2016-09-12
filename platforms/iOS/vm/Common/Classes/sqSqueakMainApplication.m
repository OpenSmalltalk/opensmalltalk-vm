//
//  sqSqueakMainApplication.m
//  
//
//  Created by John M McIntosh on 5/15/08.
//
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
 V1.05b1 fix various issues with memory allocation/free, rework logic so you can free entire interpreter loop on quit. 
 */

//

#import <Foundation/Foundation.h>

#import "sqSqueakMainApplication.h"
#import "sqSqueakMainApp.h"
#import "sqSqueakAppDelegate.h"

#import "sq.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"
#import "sqSqueakMainApplication+imageReadWrite.h"
#import	"sqSqueakSoundCoreAudio.h"
#import "Queue.h"

extern BOOL gSqueakHeadless;
extern sqSqueakAppDelegate *gDelegateApp;

@implementation sqSqueakMainApplication;
@synthesize vmPathStringURL;
@synthesize imageNameURL;
@synthesize inputSemaphoreIndex;
@synthesize currentVMEncoding;
@synthesize eventQueue;
@synthesize fileDirectoryLogic;
@synthesize infoPlistInterfaceLogic;
@synthesize soundInterfaceLogic;
@synthesize argsArguments;
@synthesize commandLineArguments;
@synthesize noHandlers;

extern sqInt interpret(void);  //This is a VM Callback

- (id) init {
    self = [super init];
    if (self) {
        [self setNoHandlers: NO];
    }
    return self;
}

- (void) setupFloat {
}

- (void) setupErrorRecovery {
	signal(SIGSEGV, sigsegv);
}

- (void) setInfoPlistInterfaceLogic:(sqSqueakInfoPlistInterface *)anObject {
    infoPlistInterfaceLogic = anObject;
}

- (sqSqueakInfoPlistInterface *) infoPlistInterfaceLogic {
    if (!infoPlistInterfaceLogic) {
        [self fetchPreferences];
    }
    
    return infoPlistInterfaceLogic;
}

- (sqSqueakInfoPlistInterface *) newSqSqueakInfoPlistInterfaceCreation {
	return [[sqSqueakInfoPlistInterface alloc] init];
}

- (void) fetchPreferences {
	self.infoPlistInterfaceLogic = [self newSqSqueakInfoPlistInterfaceCreation];
	[infoPlistInterfaceLogic parseInfoPlist]; 
	currentVMEncoding = NSUTF8StringEncoding;
}

- (void) doHeadlessSetup {
#ifndef PharoVM
    gSqueakHeadless = false;
#endif
}

- (void) doMemorySetup {
}

- (void) parseUnixArgs {
}

- (void) setupMenus {
//    nothing to do so far since the menu is setup in the MainMenu.nib file
}

- (void) setupTimers {
	extern void SetUpTimers(void);
	SetUpTimers();
}

- (void) setupAIO {
	void aioInit(void);
	aioInit();
	#if STACKVM || COGVM
	ioInitThreads();
	#endif
}

- (void) setupEventQueue {
	eventQueue = [[Queue alloc] init];
}

- (void) setupBrowserLogic {
}

- (void) setupSoundLogic {
	soundInterfaceLogic = [[sqSqueakSoundCoreAudio alloc] init];
}

- (sqSqueakFileDirectoryInterface *) newFileDirectoryInterfaceInstance {
	return [[sqSqueakFileDirectoryInterface alloc] init];
}

- (void) runSqueak {
    @autoreleasepool {
	extern BOOL gQuitNowRightNow;
	gQuitNowRightNow=false;

	[self setupFloat];  //JMM We have code for intel and powerpc float, but arm? 
	[self setupErrorRecovery];
	[self fetchPreferences];
	
	fileDirectoryLogic = [self newFileDirectoryInterfaceInstance];
	[self setVMPathFromApplicationDirectory];
	if (![self.fileDirectoryLogic setWorkingDirectory]) {
		return;
	}
	
	[self parseUnixArgs];
	attachToSignals();
    
	//JMM here we parse the unixArgs
	//JMM now we wait for the open document apple events (normally)
	   
	[self doMemorySetup];
	
	if ([self ImageNameIsEmpty]) {
		[self findImageViaBundleOrPreferences];
	}

	if ([self ImageNameIsEmpty]) {
		return;
	}
	
	[self setupTimers];

	if (![self readImageIntoMemory]) {
		return;
	}
	
    // The headless setup is now after the image setup on purpose. This is in order to be
    // able to select an image with the popup even when running headless
	[self doHeadlessSetup];

    
    [self setupMenus];
	[self setupAIO];
	[self setupBrowserLogic];
	[self setupSoundLogic];
	[gDelegateApp makeMainWindow];
	
	interpret();
    }
}


- (void) MenuBarRestore {
    //    nothing to do so far since the menu is setup in the MainMenu.nib file
    
}

#ifndef SPURVM
#if COGVM
    void sqMacMemoryFree();
#else
    void sqMacMemoryFree(void);
#endif
#endif

- (void) ioExit {
	[self ioExitWithErrorCode: 0];
}

- (void) ioExitWithErrorCode: (int) ec {
	ioShutdownAllModules();
	[self MenuBarRestore];
	exit(ec);  //Will not return
}

- (void)dealloc {
	sqMacMemoryFree();
    SUPERDEALLOC
}

@end

int plugInTimeToReturn(void);
int plugInTimeToReturn(void) {
	extern BOOL	gQuitNowRightNow;
	
	if (gQuitNowRightNow)
		return true;
	return false;
}


sqInt convertToSqueakTime(NSDate *givenDate)
{
	
	time_t unixTime = [givenDate timeIntervalSince1970];
	
#ifdef HAVE_TM_GMTOFF
	unixTime+= localtime(&unixTime)->tm_gmtoff;
#else
# ifdef HAVE_TIMEZONE
	unixTime+= ((daylight) * 60*60) - timezone;
# else
#  error: cannot determine timezone correction
# endif
#endif
	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
	return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL);
}
