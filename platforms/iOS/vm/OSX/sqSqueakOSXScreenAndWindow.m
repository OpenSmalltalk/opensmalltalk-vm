//
//  sqSqueakOSXScreenAndWindow.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqMacHostWindow.h"
#import "sqMacV2Browser.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "SqViewBitmapConversion.h"
#import "sqSqueakOSXApplication+events.h"

extern SqueakOSXAppDelegate *gDelegateApp;

static void dispatchWindowChangedHook(void);

@interface sqSqueakOSXScreenAndWindow()
    @property (nonatomic,strong) NSView <sqSqueakOSXView> * mainViewOnWindow;
@end

@implementation sqSqueakOSXScreenAndWindow
@synthesize mainViewOnWindow;

-(id) getMainView {
	return self.mainViewOnWindow;
}

- (void) mainViewOnWindow: (NSView <sqSqueakOSXView> *) aView {
    self.mainViewOnWindow = aView;
}

- (NSView <sqSqueakOSXView> *) getMainViewOnWindow {
    return self.mainViewOnWindow;
}

- (void) dealloc {
    RELEASEOBJ(mainViewOnWindow);
    SUPERDEALLOC
}

- (void)  ioSetFullScreen: (sqInt) fullScreen {
	[[self getMainView] ioSetFullScreen: fullScreen];
}

- (BOOL)windowShouldClose:(id)window {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordWindowEvent: WindowEventClose window: window];
	return NO;
}

#if DEBUG_WINDOW_CHANGED_HOOK
# define windowResizeMethod(msg) - (void)msg (NSNotification *)notification { \
	printf( #msg "\n"); \
}
#else
# define windowResizeMethod(msg) - (void)msg (NSNotification *)notification { \
	dispatchWindowChangedHook(); \
}
#endif

windowResizeMethod(windowDidResize:)
windowResizeMethod(windowDidMiniaturize:)
windowResizeMethod(windowDidDeminiaturize:)
//These two not needed since windowDidResize: is also dispatched
//windowResizeMethod(windowDidEnterFullScreen:)
//windowResizeMethod(windowDidExitFullScreen:)
//This one is dispatched when entering/exiting true full screen mode
windowResizeMethod(windowDidChangeScreen:)

@end

void *
getSTWindow(void)
{
	extern BOOL gSqueakHeadless;

	return (gSqueakHeadless && !browserActiveAndDrawingContextOk())
			? 0
			: windowHandleFromIndex(1);
}

/* A "chain" of windowChangedHooks, using the Unix signal convention; it is the
 * responsibility of the caller to remember any previous hook and chain it from
 * their own windowChangedHook.  Hence setWindowChangedHook answers the previous
 * windowChangedHook.
 */
static windowChangedHook hookLine = 0;

static void
dispatchWindowChangedHook()
{	if (hookLine) hookLine(); }

windowChangedHook
getWindowChangedHook() { return hookLine; }

windowChangedHook
setWindowChangedHook(windowChangedHook hook)
{	windowChangedHook prevHook = hookLine;
	hookLine = hook;
	return prevHook;
}
