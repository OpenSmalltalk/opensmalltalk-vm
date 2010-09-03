//
//  SqueakNoOGLIPhoneAppDelegate.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/15/08.
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
#import <UIKit/UIKit.h>

#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "sqSqueakIPhoneApplication.h"
#import "sqiPhoneScreenAndWindow.h"
#import "sqSqueakIPhoneInfoPlistInterface.h"

extern struct	VirtualMachine* interpreterProxy;
SqueakNoOGLIPhoneAppDelegate *gDelegateApp;

@implementation SqueakNoOGLIPhoneAppDelegate

@synthesize window;
@synthesize mainView;
@synthesize scrollView;
@synthesize viewController;
@synthesize screenAndWindow;

- (sqSqueakMainApplication *) makeApplicationInstance {
	return [sqSqueakIPhoneApplication new];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
#warning this is wrong, need to get shared application
	gDelegateApp = self;	
	mainView = null;
	scrollView = null;
	
	squeakApplication = [self makeApplicationInstance];
	screenAndWindow =  [sqiPhoneScreenAndWindow new];
	[self.squeakApplication setupEventQueue];
	[self singleThreadStart];
	//[self workerThreadStart];

}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.mainView;
}

- (id) createPossibleWindow {
	if (gDelegateApp.mainView == nil) {
		NSAutoreleasePool * pool = [NSAutoreleasePool new];
		NSMethodSignature * methodSignature = [gDelegateApp methodSignatureForSelector:@selector(makeMainWindowOnMainThread)];
		NSInvocation *redrawInv = [NSInvocation invocationWithMethodSignature: methodSignature];
		[redrawInv setTarget: gDelegateApp];
		[redrawInv setSelector:@selector(makeMainWindowOnMainThread)];
		[redrawInv performSelectorOnMainThread: @selector(invoke) withObject: nil waitUntilDone: YES];				
		[pool drain];	
	}
	return self.window;
}

- (void) makeMainWindowOnMainThread

//This is fired via a cross thread message send from logic that checks to see if the window exists in the squeak thread.

{
		
	// Set up content view
	// The application frame includes the status area if needbe. 
#warning TODO we need an option to let the user decide to dispose of the status bar
	
	CGRect mainScreenSize = [[UIScreen mainScreen] applicationFrame];
	
	BOOL useScrollingView = [(sqSqueakIPhoneInfoPlistInterface*)self.squeakApplication.infoPlistInterfaceLogic useScrollingView];
	
	if (useScrollingView) {
		scrollView = [[UIScrollView alloc ] initWithFrame: mainScreenSize];
		
		//Now setup the true view size as the width/height * 2.0  so we can have a larger squeak window and zoom in/out. 
		
		CGRect fakeScreenSize = mainScreenSize	;
		fakeScreenSize.origin.x = 0;
		fakeScreenSize.origin.y = 0;
		fakeScreenSize.size.width *= 2.0; 
		fakeScreenSize.size.height *= 2.0;
		mainView = [[SqueakUIView alloc] initWithFrame: fakeScreenSize];
		self.mainView.clearsContextBeforeDrawing = NO;
		
		//Setup the scroll view which wraps the mainView
		
		self.scrollView.clearsContextBeforeDrawing = NO;
		self.scrollView.canCancelContentTouches = NO;
		self.scrollView.contentSize = [self.mainView bounds].size; 
		self.scrollView.minimumZoomScale = 0.5; 
		self.scrollView.maximumZoomScale = 4.0;
		self.scrollView.delegate = self;
		self.viewController = [SqueakUIController new];
		self.viewController.view = self.scrollView;
		
		//  no idea if needed
		//	self.scrollView.autoresizesSubviews=YES;
		//	self.scrollView.autoresizingMask=(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);	
		
		[self.scrollView addSubview: self.mainView];
		[window addSubview: self.scrollView];
		
	} else {
		
		CGRect fakeScreenSize = mainScreenSize	;
		mainView = [[SqueakUIView alloc] initWithFrame: fakeScreenSize];
		self.mainView.clearsContextBeforeDrawing = NO;
		self.viewController = [SqueakUIController new];
		self.viewController.view = self.mainView;
		[window addSubview: self.mainView];
	}
	
	[window makeKeyAndVisible];
	
}

- (void)dealloc {
	[mainView release];
	[scrollView release];
	[viewController release];
	[window release];
	[screenAndWindow release];
	[super dealloc];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	NSMutableArray* data = [NSMutableArray new];
	
	[acceleration retain]; 
	[data addObject: [NSNumber numberWithInteger: 2]];
	[data addObject: acceleration];
	[[[self squeakApplication] eventQueue] addItem: data];
	[data release];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSMutableArray* data = [NSMutableArray new];

	[manager retain]; 
	[error retain]; 
	[data addObject: [NSNumber numberWithInteger: 3]];
	[data addObject: manager];
	[data addObject: error];
	[[[self squeakApplication] eventQueue] addItem: data];
	[data release];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSMutableArray* data = [NSMutableArray new];

	[manager retain]; 
	[newLocation retain]; 
	[oldLocation retain]; 
	[data addObject: [NSNumber numberWithInteger: 4]];
	[data addObject: manager];
	[data addObject: newLocation];
	[data addObject: oldLocation];
	[[[self squeakApplication] eventQueue] addItem: data];
	[data release];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	// try to clean up as much memory as possible. next step is to terminate app
	/* Actually sending the message to the image is nice, but it's impossible to clean up things here 
	 on the VM level. It could be some Object-C thing is going on, like URL fetching, or JPEG rendering,
	 if so the squeak application can decide what to do, or ignore it which leads to death in a few seconds */
	
	NSMutableArray* data = [NSMutableArray new];
	
	[data addObject: [NSNumber numberWithInteger: 5]];
	[[[self squeakApplication] eventQueue] addItem: data];
	[data release];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[NSNotificationCenter defaultCenter] postNotificationName: @"ApplicationWillTerminate" object: self];
}


@end

/* unableToReadImageError and others, where do they go? */

/*
> kCLLocationAccuracyBest = -1.0
> kCLLocationAccuracyNearestTenMeters = 10.0
> kCLLocationAccuracyHundredMeters = 100.0
> kCLLocationAccuracyKilometer = 1000.0
> kCLLocationAccuracyThreeKilometers = 3000.0
 */
