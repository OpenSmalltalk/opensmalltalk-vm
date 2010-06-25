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

extern sqInt interpret(void);  //This is a VM Callback

- (void) setupFloat {
}

- (void) setupErrorRecovery {
	signal(SIGSEGV, sigsegv);
}

- (sqSqueakInfoPlistInterface *) newSqSqueakInfoPlistInterfaceCreation {
	return [sqSqueakInfoPlistInterface new];
}

- (void) fetchPreferences {
	infoPlistInterfaceLogic = [self newSqSqueakInfoPlistInterfaceCreation];
	[infoPlistInterfaceLogic parseInfoPlist]; 
	currentVMEncoding = NSUTF8StringEncoding;
}

- (void) doHeadlessSetup {
	gSqueakHeadless = false;
}

- (void) doMemorySetup {
}

- (void) parseUnixArgs {
}

- (void) setupMenus {
}

- (void) setupTimers {
	extern void SetUpTimers(void);
	SetUpTimers();
}

- (void) setupAIO {
	void aioInit(void);
	aioInit();
}

- (void) setupEventQueue {
	eventQueue = [Queue new];
}

- (void) setupBrowserLogic {
}

- (void) setupSoundLogic {
	soundInterfaceLogic = [sqSqueakSoundCoreAudio new];
}

- (sqSqueakFileDirectoryInterface *) newFileDirectoryInterfaceInstance {
	return [sqSqueakFileDirectoryInterface new];
}

- (void) runSqueak {
	NSAutoreleasePool * pool = [NSAutoreleasePool new]; //Needed since this is a worker thread, see comments in NSAutoreleasePool Class Reference about Threads
	
	[self setupFloat];  //JMM We have code for intel and powerpc float, but arm? 
	[self setupErrorRecovery];
	[self fetchPreferences];
	
	fileDirectoryLogic = [self newFileDirectoryInterfaceInstance];
	[self setVMPathFromApplicationDirectory];
	if (![self.fileDirectoryLogic setWorkingDirectory]) {
		[pool drain];
		return;
	}
	
	[self parseUnixArgs];
	
	//JMM here we parse the unixArgs
	//JMM now we wait for the open document apple events (normally)
	
	[self doHeadlessSetup];
	//JMM after wait normally if headless and no imageName then exit -42
	
	[self doMemorySetup];
	
	if ([self ImageNameIsEmpty]) 
		[self findImageViaBundleOrPreferences];
	
	if ([self ImageNameIsEmpty]) {
		[pool drain];
		return;
	}
	
	if (![self readImageIntoMemory]) {
		[pool drain];
		return;
	}
	
	[self setupMenus];
	[self setupTimers];
	[self setupAIO];
	[self setupBrowserLogic];
	[self setupSoundLogic];
	[gDelegateApp makeMainWindow];
	
	interpret();
	[pool drain];  //may not return here, could call exit() via quit image
	[self release];
}

- (void) MenuBarRestore {
}

void sqMacMemoryFree(void);

- (void) ioExit {
		
	ioShutdownAllModules();
	[self MenuBarRestore];
	exit(0);  //Will not return
}

- (void)dealloc {
	[infoPlistInterfaceLogic release];
	[soundInterfaceLogic release];
	[vmPathStringURL release];
	[imageNameURL release];
	[fileDirectoryLogic release];
	[eventQueue release];
	sqMacMemoryFree();
	[super dealloc];
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
	//IM
	NSTimeInterval dateDifference;
	static NSDate *squeakEpoch=NULL;
	
	if (!givenDate) 
		return 0;
	
	if (squeakEpoch == NULL) {
		NSDateComponents *comps = [NSDateComponents new];
		NSCalendar *calenderEnglishUSA = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar]; //Use USA english calender versus user choosen china calender
		//NSTimeZone* zone =[NSTimeZone timeZoneForSecondsFromGMT: 0];
		//[calenderEnglishUSA setTimeZone: zone];  THIS appears not to be needed?
		[comps setYear: 1901];
		[comps setMonth: 1];
		[comps setDay: 1];
		[comps setHour: 0];
		[comps setMinute: 0];
		[comps setSecond: 0];
		 
		squeakEpoch = [calenderEnglishUSA  dateFromComponents: comps];
		[squeakEpoch retain];
		[comps release];
		[calenderEnglishUSA release];
	}

	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970 */
	dateDifference = [givenDate timeIntervalSinceDate: squeakEpoch];
	return (sqInt) (usqInt) dateDifference;
}

