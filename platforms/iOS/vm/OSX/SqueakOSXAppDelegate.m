//
//  SqueakOSXAppDelegate.m
//  SqueakOSXApp
//
//  Created by John M McIntosh on 09-11-10.
//
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "sqMacHostWindow.h"
#import "sqSqueakOSXInfoPlistInterface.h"
//Crashlytics code commented out; usefuil to those that use it...
//#import <Fabric/Fabric.h>
//#import <Crashlytics/Crashlytics.h>

#ifdef USE_METAL
#  import "sqSqueakOSXMetalView.h"
#endif

#ifdef USE_CORE_GRAPHICS
#  import "sqSqueakOSXCGView.h"
#endif

#import "sqSqueakOSXOpenGLView.h"

SqueakOSXAppDelegate *gDelegateApp;

@implementation SqueakOSXAppDelegate

@synthesize window,mainView,possibleImageNameAtLaunchTime,checkForFileNameOnFirstParm,windowHandler,dragItems;

- (sqSqueakMainApplication *) makeApplicationInstance {
	return AUTORELEASEOBJ([[sqSqueakOSXApplication alloc] init]);
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	self.checkForFileNameOnFirstParm = YES;
	dragItems = NULL;
	
	NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
	[appleEventManager setEventHandler:self
					   andSelector:@selector(handleGetURLEvent:withReplyEvent:)
					 forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	//Crashlytics code commented out; usefuil to those that use it...
    //   [Crashlytics startWithAPIKey:@"add501476623fc20212a60334cd537d16dfd566f"];
    //[Fabric with:@[[Crashlytics class]]];

    @autoreleasepool {
		gDelegateApp = self;	
		self.squeakApplication = [self makeApplicationInstance];
		[self.squeakApplication setupEventQueue];
		// Push the startup schema and open file events into the event queue.
		if(self.dragItems && [self.dragItems count] > 0)
			[(sqSqueakOSXApplication *) self.squeakApplication recordURLEvent: SQDragDrop numberOfFiles: [self.dragItems count]];
		[self singleThreadStart];
//	[self workerThreadStart];
	}
    
#ifdef PharoVM
     [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString* urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString: urlString];
	dragItems = [NSMutableArray arrayWithCapacity: 1];
	[dragItems addObject: url];
	
	if(self.squeakApplication)
		[(sqSqueakOSXApplication *) self.squeakApplication recordURLEvent: SQDragDrop numberOfFiles: 1];
}

- (NSURL*) dragURIAtIndex: (sqInt) index {
	if (!self.dragItems || index < 1 || index > [self.dragItems count])
		return NULL;
	
	return (self.dragItems)[(NSUInteger) index - 1];
}

#ifdef PharoVM
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}
#endif

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	[self.window performClose: self.window];
	return NSTerminateCancel;
}

- (void) initializeTheWindowHandler {
    [windowHandler mainViewOnWindow: self.mainView];
    self.mainView.windowLogic = windowHandler;
    windowHandler.windowIndex = 1;
    [windowHandler.getMainViewOnWindow initializeVariables];
    self.window.delegate =  windowHandler;
    self.window.contentView = self.mainView;
}

-(void) setupWindow {
    extern BOOL gSqueakHeadless;
    if (gSqueakHeadless) {
        self.windowHandler = AUTORELEASEOBJ([[sqSqueakNullScreenAndWindow alloc] init]);
        [self initializeTheWindowHandler];
        return;
    } else {
        self.windowHandler = AUTORELEASEOBJ([[sqSqueakOSXScreenAndWindow alloc] init]);
    }
    
  
    [self initializeTheWindowHandler];
    self.window.contentResizeIncrements = NSMakeSize(8.0f,8.0f);

    //I setup the window with all the right properties. Some of them are depending on image information.
    
	sqInt width,height;
	extern sqInt getSavedWindowSize(void); //This is VM Callback
	width  = ((unsigned) getSavedWindowSize()) >> 16;
	height = getSavedWindowSize() & 0xFFFF;
	width = (sqInt) ((width*4)/32.0f+0.5)*8.0;  //JMM OPEN/GL THOUGHTS FOR PERFORMANCE
	NSSize sizeOfWindowContent;
	sizeOfWindowContent.width = width;
	sizeOfWindowContent.height = height;
	
	[gDelegateApp.window setContentSize: sizeOfWindowContent];
	NSRect resetFrame;
	resetFrame.origin.x = 0.0f;
	resetFrame.origin.y	= 0.0f;
	resetFrame.size.width = width;
	resetFrame.size.height = height;
    [self.window setAcceptsMouseMovedEvents: YES];
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_9
	[self.window useOptimizedDrawing: YES];
#endif
	[self.window setTitle: [[[[self squeakApplication] imageNameURL] path] lastPathComponent]];
	[self.window setRepresentedURL: [[self squeakApplication] imageNameURL]];
	[self.window setInitialFirstResponder: [self mainView]];
	[self.window setShowsResizeIndicator: NO];
}

-(void) setupMainView {
    extern BOOL gSqueakHeadless;
    if (gSqueakHeadless) {
        return;
    }
    //Creates and sets the contentView for our window.
    //It can right now, I have two implementations to pick (CoreGraphics or OpenGL), muy more/different could be added 
    //in the future. 
    
}

- (id) createPossibleWindow {
    // Creates the window
    [self setupWindow];
    [self setupMainView];
    return [self window];
}

- (void) placeMainWindowOnLargerScreenGivenWidth: (sqInt) width height: (sqInt) height {
#if SQ_HOST64 /* This API is 64-bits only :-( */
        for (NSScreen *screen in [NSScreen screens]) {
                CGSize screenSize = screen.visibleFrame.size;
                if ((height <= screenSize.height) && (width <= screenSize.width)) {
                    self.window.frameOrigin = screen.visibleFrame.origin;
                    break;
                }
        }
#endif
}

- (BOOL) isImageFile: (NSString *) filePath
{
 	NSFileManager *dfm = [NSFileManager defaultManager];
	BOOL isDirectory;

	[dfm fileExistsAtPath: filePath isDirectory: &isDirectory];

	if (isDirectory) 
		return NO;

	BOOL fileIsReadable = [[NSFileManager defaultManager] isReadableFileAtPath: filePath];

	if (fileIsReadable == NO)
		return NO;

	if ([[[filePath lastPathComponent] pathExtension] compare: @"image" options: NSCaseInsensitiveSearch] ==   NSOrderedSame)
		return YES;

	return NO;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)fileName {
	if([self isImageFile: fileName] == YES) {
		if (self.checkForFileNameOnFirstParm == YES) {
			self.checkForFileNameOnFirstParm = NO;
			self.possibleImageNameAtLaunchTime = fileName;
			return YES;
		} else {
			NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
			LSLaunchURLSpec launchSpec;
			launchSpec.appURL = (CFURLRef)CFBridgingRetain(url);
			launchSpec.passThruParams = NULL;
			launchSpec.itemURLs = (__bridge CFArrayRef)@[[NSURL fileURLWithPath: fileName]];
			launchSpec.launchFlags = kLSLaunchDefaults | kLSLaunchNewInstance;
			launchSpec.asyncRefCon = NULL;
		
			OSErr err = LSOpenFromURLSpec(&launchSpec, NULL);
//			NSLog(@"error %i",err);
#pragma unused(err)
		}
	}
	else
	{
		NSURL *url = [NSURL fileURLWithPath: fileName];
		dragItems = [NSMutableArray arrayWithCapacity: 1];
		[dragItems addObject: url];
		
		if(self.squeakApplication)
			[(sqSqueakOSXApplication *) self.squeakApplication recordURLEvent: SQDragDrop numberOfFiles: 1];
		return YES;
	}
	
	return NO;
}

- (NSTimeInterval) squeakUIFlushPrimaryDeferNMilliseconds {
	return ((sqSqueakOSXInfoPlistInterface*) self.squeakApplication.infoPlistInterfaceLogic).SqueakUIFlushPrimaryDeferNMilliseconds;
}


@end
