
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
#import "SqueakUIViewCALayer.h"
#import "SqueakUIViewOpenGL.h"

extern struct	VirtualMachine* interpreterProxy;
SqueakNoOGLIPhoneAppDelegate *gDelegateApp;

@interface SqueakNoOGLIPhoneAppDelegate()
@property(nonatomic, retain) UIWebView *webView;
@end

@implementation SqueakNoOGLIPhoneAppDelegate

@synthesize window;
@synthesize mainView;
@synthesize scrollView;
@synthesize viewController;
@synthesize screenAndWindow;

- (sqSqueakMainApplication *) makeApplicationInstance {
	return [[sqSqueakIPhoneApplication alloc] init];
}

- (BOOL)application: (UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary*) launchOptions {
#error JMM notes not tested after integration yet 2015 May 7th
	gDelegateApp = self;	
	mainView = null;
	scrollView = null;
	application.idleTimerDisabled = YES;
	
	squeakApplication = [self makeApplicationInstance];
	screenAndWindow =  [[sqiPhoneScreenAndWindow alloc] init];
	[self.squeakApplication setupEventQueue];
    if ([self.info useWorkerThread] || [self.info useWebViewAsUI]) {
        [self workerThreadStart];
    } else {
        [self singleThreadStart];
    }
}

- (void)loadUrl:(NSString *)aString {
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:aString]]];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.mainView;
}

- (id) createPossibleWindow {
	if (gDelegateApp.mainView == nil) {
		@autoreleasepool {
            [gDelegateApp makeMainWindowOnMainThread];
		}	
	}
	return self.window;
}

- (void) zoomToOrientation:(UIInterfaceOrientation)o animated:(BOOL)animated {
	/* 
	 Magic eToys code, leave this here to be nice.. Don't use unless you know what you are doing?
	 
	 CGRect zoomRect;
	 zoomRect.origin.x = 0;
	 zoomRect.origin.y = 0;
	 if (UIInterfaceOrientationIsPortrait(o)) {
	 zoomRect.size.width  = 1200 * 4 / 3;
	 } else {
	 zoomRect.size.width  = 1200 * 3 / 4;
	 }
	 zoomRect.size.height = zoomRect.size.width * 3 / 4;
	 [self.scrollView zoomToRect: zoomRect animated: animated];
	 */
}

- (Class) whatRenderCanWeUse {
//  Ok the proper way is to get the glGetString() extensions, but at this point open/gl is not setup. 
//  So bail and decide on operating system version.. 
//	BOOL hasGL_APPLE_texture_2D_limited_npot = (0 != strstr((char *)glGetString(GL_EXTENSIONS), "GL_APPLE_texture_2D_limited_npot"));
//	return  (hasGL_APPLE_texture_2D_limited_npot) ? [SqueakUIViewOpenGL class] : [SqueakUIViewCALayer class];

    // The device must be running running iOS 3.2 or later.
    //Esteban >>
    /*
    NSString *reqSysVer = @"3.2";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	return  (osVersionSupported) ? [SqueakUIViewOpenGL class] : [SqueakUIViewCALayer class];
    */
     return [SqueakUIViewCALayer class];
    //Esteban <<
}

- (void) makeMainWindowOnMainThread

//This is fired via a cross thread message send from logic that checks to see if the window exists in the squeak thread.

{
		
	// Set up content view
	// The application frame includes the status area if needbe. 

	CGRect mainScreenSize = [[UIScreen mainScreen] applicationFrame];
	    
    self.viewController = [SqueakUIController new];
    [window setRootViewController:self.viewController];
        
	BOOL useScrollingView = [self.info useScrollingView];
	if (useScrollingView) {
		scrollView = [[UIScrollView alloc ] initWithFrame: mainScreenSize];

		//Now setup the true view size as the width/height * 2.0  so we can have a larger squeak window and zoom in/out. 
		CGRect fakeScreenSize = mainScreenSize;
		fakeScreenSize.origin.x = 0;
		fakeScreenSize.origin.y = 0;
		fakeScreenSize.size.width *= 2.0; 
		fakeScreenSize.size.height *= 2.0;
		/* eToys setup 
		 fakeScreenSize.size.width = 1200; 
		 fakeScreenSize.size.height = 900;
		*/
		mainView = [[[self whatRenderCanWeUse] alloc] initWithFrame: fakeScreenSize];
		mainView.backgroundColor = [UIColor blackColor];
		mainView.multipleTouchEnabled = YES;
		mainView.autoresizingMask = UIViewAutoresizingNone;
		self.mainView.clearsContextBeforeDrawing = NO;
		
		//Setup the scroll view which wraps the mainView
		self.scrollView.scrollEnabled = useScrollingView;
		self.scrollView.clearsContextBeforeDrawing = NO;
		self.scrollView.canCancelContentTouches = NO;
		self.scrollView.minimumZoomScale = 0.5; 
		self.scrollView.maximumZoomScale = 4.0;
		self.scrollView.delegate = self;
		self.scrollView.backgroundColor = [UIColor blackColor];
		self.scrollView.autoresizesSubviews=YES;
		self.scrollView.autoresizingMask=(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);	

		self.viewController.view = self.scrollView;		
		
		
		[self zoomToOrientation: UIInterfaceOrientationPortrait animated: NO];
		[self.scrollView addSubview: self.mainView];
		[window addSubview: self.scrollView];
		
	} else {
		CGRect fakeScreenSize = mainScreenSize;
		mainView = [[[self whatRenderCanWeUse] alloc] initWithFrame: fakeScreenSize];
		self.mainView.clearsContextBeforeDrawing = NO;
		[self.mainView setMultipleTouchEnabled: YES];
		self.viewController.view = self.mainView;
		[window addSubview: self.mainView];
	}
    
    if ([self.info useWebViewAsUI]) {
        [self prepareWebView];
    }
    
	[window makeKeyAndVisible];	
}

- (void)prepareWebView {
    self.webView = [[[UIWebView alloc] initWithFrame: [window bounds]] autorelease];
    [self.webView setAutoresizingMask:
        UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleLeftMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleWidth ];
    
    [self.viewController setView:self.webView];
    [window addSubview:self.webView];
}

- (sqSqueakIPhoneInfoPlistInterface *)info {
    return (sqSqueakIPhoneInfoPlistInterface *)self.squeakApplication.infoPlistInterfaceLogic;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	NSMutableArray* data = [NSMutableArray arrayWithCapacity:2];
	
	[data addObject: @2];
	[data addObject: acceleration];
	[[[self squeakApplication] eventQueue] addItem: data];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSMutableArray* data = [NSMutableArray arrayWithCapacity:3];

	[data addObject: @3];
	[data addObject: manager];
	[data addObject: error];
	[[[self squeakApplication] eventQueue] addItem: data];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSMutableArray* data = [NSMutableArray arrayWithCapacity: 4];

	[data addObject: @4];
	[data addObject: manager];
	[data addObject: newLocation];
	[data addObject: oldLocation];
	[[[self squeakApplication] eventQueue] addItem: data];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	// try to clean up as much memory as possible. next step is to terminate app
	/* Actually sending the message to the image is nice, but it's impossible to clean up things here 
	 on the VM level. It could be some Object-C thing is going on, like URL fetching, or JPEG rendering,
	 if so the squeak application can decide what to do, or ignore it which leads to death in a few seconds */
	
	NSMutableArray* data = [NSMutableArray arrayWithCapacity:2];
	
	[data addObject: @5];
	[[[self squeakApplication] eventQueue] addItem: data];
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
