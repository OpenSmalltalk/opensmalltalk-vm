//
//  sqSqueakOSXCGView.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
//  Some code sqUnixQuartz.m -- display via native windows on Mac OS X	-*- ObjC -*-
//  Author: Ian Piumarta <ian.piumarta@squeakland.org>
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
#import <QuartzCore/QuartzCore.h>

#import "sqSqueakOSXCGView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sq.h"
#import "sqVirtualMachine.h"

#import <QuartzCore/QuartzCore.h>

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct VirtualMachine *interpreterProxy;
extern sqInt cannotDeferDisplayUpdates;

@implementation sqSqueakOSXCGView
@synthesize savedScreenBoundsAtTimeOfFullScreen;

#include "SqSqueakOSXView.m.inc"

#pragma mark Initialization / Release

// There is some confusion in Apple's 32-bit code which ends up making CGRect
// incompatible with NSRect, even though they're structurally the same.
// So provide a hack conversion for 32-bits, implemented as a noop for 64-bits.

#if __LP64__ || TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
# define asNSRect(aCGRect) aCGRect
# define asCGRect(aNSRect) aNSRect
#else
# define asNSRect(aCGRect) NSRectFromCGRect(aCGRect)
# define asCGRect(aNSRect) NSRectToCGRect(aNSRect)
#endif

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    [self initialize];
    return self;
}

- (void)awakeFromNib {
    [self initialize];
}

- (void)initialize {

    // NSLog(@"initialize %@", NSStringFromRect([self frame]));
	
	cannotDeferDisplayUpdates = 1;
	
	[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];

	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil]];
	dragInProgress = NO;
	dragCount = 0;
	clippyIsEmpty = YES;
	colorspace = CGColorSpaceCreateDeviceRGB();
	[self initializeSqueakColorMap];

    // macOS 10.5 introduced NSTrackingArea for mouse tracking
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect: [self frame]
    	options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect)
    	owner: self userInfo: nil];
    [self addTrackingArea: trackingArea];
}

- (void) initializeVariables {
}

- (void) preDrawThelayers {
}

- (void) dealloc {
	free(colorMap32);
	CGColorSpaceRelease(colorspace);
    SUPERDEALLOC
}

#pragma mark Testing

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL)isFlipped {
	return YES; // (0,0) is in top-left corner; y axis grows downward
}

- (BOOL)isOpaque {
	return YES;
}

- (NSRect) sqScreenSize {
  return [self convertRectToBacking: [self bounds]];
}


- (NSPoint) sqMousePosition: (NSEvent*)theEvent {
	/* Our client expects the mouse coordinates in Squeak's coordinates,
	 * but theEvent's location is in "user" coords. so we have to convert. */
	NSPoint local_pt = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	NSPoint converted = [self convertPointToBacking: local_pt];
	// Squeak is upside down
	return NSMakePoint(converted.x, -converted.y);
}

- (NSPoint) sqDragPosition: (NSPoint)draggingLocation {
	// TODO: Reuse conversion from sqMousePosition:.
	NSPoint local_pt = [self convertPoint: draggingLocation fromView: nil];
	NSPoint converted = [self convertPointToBacking: local_pt];
	return NSMakePoint(converted.x, -converted.y);
}


#pragma mark Updating callbacks

- (void) viewWillStartLiveResize {
	[[NSCursor arrowCursor] set];
}

- (void) viewDidEndLiveResize {
	[((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor performSelectorOnMainThread: @selector(set) withObject: nil waitUntilDone: NO];	
}

#pragma mark Drawing


- (void) drawImageUsingClip: (CGRect) clip {

	/* The argument clip is in window coordinates (i.e., bottom-left is (0,0))
	 * but still in backing scale. Thus, flip the y-axis and convert to user
     * coordinates.
     */
    float d = [self window] ? [self window].backingScaleFactor : 1.0;
    CGRect userClip = CGRectMake(clip.origin.x / d,
                                 [self frame].size.height - (clip.origin.y + clip.size.height) / d,
                                 clip.size.width / d,
                                 clip.size.height / d);
//    if(!syncNeeded) {
//        syncNeeded = YES;
		[self setNeedsDisplayInRect: asNSRect(userClip)];
//    }

	/* Note that after this, drawThelayers will be called directly.
	 * See primitiveShowDisplayRect, which will directly call ioForceDisplayUpdate.
	 */
}

- (void) drawThelayers {
    extern BOOL gSqueakHeadless;
	if (gSqueakHeadless) {
        firstDrawCompleted = YES;
        return;
    }

    /* The drawing loop will call display automatically due to our use of
     * setNeedsDisplayInRect above. We don't have to do it.
     */
	// if (syncNeeded) { [self display]; }

	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
        extern sqInt getFullScreenFlag(void);
		if (getFullScreenFlag() == 0) {
			[self.window makeKeyAndOrderFront: self];
        }
	}
}

/* Now the displayBits is known and likely pinned, couldn't we cache the bitmap
 * that this method creates?  Yes its contents need to be updated, but it
 * doesn't need to be created all the time does it?  Or is the object created
 * by CGImageCreate merely a wrapper around the bits?
 * eem 2017/05/12
 *
 * Yes, the displayBits are directly accessed when shown on screen.
 * mt 2022/03/30
 */
- (void) performDraw: (CGRect)rect {
	if(!displayBits) {
		// Init guard for fullscreen mode
		return;
	}

	CGContextRef context;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1010 && defined(NSFoundationVersionNumber10_10)
	if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber10_10) {
		context = [[NSGraphicsContext currentContext] CGContext];
	} else { // Deprecated in OSX 10.10
		context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	}
#else
	context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
#endif
    CGContextSaveGState(context);
    CGAffineTransform  deviceTransform = CGContextGetUserSpaceToDeviceSpaceTransform(context);
    int bitSize = interpreterProxy->byteSizeOf(displayBits - BaseHeaderSize);
    int bytePerRow = displayWidth * displayDepth / 8;

    CGDataProviderRef pRef = CGDataProviderCreateWithData(NULL, displayBits, bitSize, NULL);
    CGImageRef image = CGImageCreate(displayWidth,
                                     displayHeight,
                                     8,
                                     32,
                                     bytePerRow,
                                     colorspace,
            /* BGRA */				 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst,
                                     pRef,
                                     NULL,
                                     NO,
                                     kCGRenderingIntentDefault);
    CGContextClipToRect(context, rect);

    // displayBits are upside down, match isFlipped for this view
    CGContextTranslateCTM(context, 0, displayHeight / deviceTransform.d);
    CGContextScaleCTM(context, 1 , -1);
//    CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorClear));
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, asCGRect([self frame]));
//    CGContextSetAlpha(context, 1.0);
    CGContextDrawImage(context, asCGRect([self frame]), image);

    CGImageRelease(image);
    CGDataProviderRelease(pRef);
    CGContextRestoreGState(context);
    // CGContextSaveGState(context);
    // CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorClear));
    // CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    // CGContextStrokeRect(context, rect);
    // CGContextRestoreGState(context);

}

-(void)drawRect:(NSRect)rect
{
    /* We recorded damage in drawImageUsingClip:. Cocoa possibly accumulated
     * and now we can draw the rect the system wants us to.
	 */
	[self performDraw: asCGRect(rect)];
    syncNeeded = NO;
}

#pragma mark Fullscreen

- (void)  ioSetFullScreen: (sqInt) fullScreen {
	
	if ([self isInFullScreenMode] == YES && (fullScreen == 1))
		return;
	if ([self isInFullScreenMode] == NO && (fullScreen == 0))
		return;
	
	if ([self isInFullScreenMode] == NO && (fullScreen == 1)) {
		self.savedScreenBoundsAtTimeOfFullScreen = (NSRect) [self bounds];
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO],
			NSFullScreenModeAllScreens,
			[NSNumber numberWithInt:
				NSApplicationPresentationHideDock |
				NSApplicationPresentationHideMenuBar ],
			NSFullScreenModeApplicationPresentationOptions, nil];
		[self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];
		extern struct	VirtualMachine* interpreterProxy;
		interpreterProxy->fullDisplayUpdate();
	}
	
	if ([self isInFullScreenMode] == YES && (fullScreen == 0)) {
		[self exitFullScreenModeWithOptions: NULL];
		if ([self.window isKeyWindow] == NO) {
			[self.window makeKeyAndOrderFront: self];
			//	NOT SURE IF THIS IS NEEDED, MORE TESTING	[self.window setContentSize: self.savedScreenBoundsAtTimeOfFullScreen.size];
		}
	}
}

@end
