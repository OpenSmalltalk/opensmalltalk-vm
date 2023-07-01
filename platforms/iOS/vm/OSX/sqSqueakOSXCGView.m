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
extern struct	VirtualMachine* interpreterProxy;

@implementation sqSqueakOSXCGView
@synthesize savedScreenBoundsAtTimeOfFullScreen;

#include "SqSqueakOSXView.m.inc"

#pragma mark Initialization / Release

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];

    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];

    [self initialize];

    return self;
}

- (void)awakeFromNib {
    [self initialize];
}

- (void)initialize {
	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil]];
	dragInProgress = NO;
	dragCount = 0;
	clippyIsEmpty = YES;
	colorspace = CGColorSpaceCreateDeviceRGB();
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
	return  YES;
}

- (BOOL)isOpaque {
	return YES;
}

#pragma mark Updating callbacks

- (void)viewDidMoveToWindow {
	if (self.squeakTrackingRectForCursor)
		[self removeTrackingRect: self.squeakTrackingRectForCursor];
	
	self.squeakTrackingRectForCursor = [self addTrackingRect: [self bounds] owner: self userData:NULL assumeInside: NO];
}

- (void) updateTrackingAreas {
	[super updateTrackingAreas];
	[self removeTrackingRect: self.squeakTrackingRectForCursor];
	self.squeakTrackingRectForCursor = [self addTrackingRect: [self bounds] owner: self userData:NULL assumeInside: NO];
}

- (void) viewWillStartLiveResize {
	[[NSCursor arrowCursor] set];
}

- (void) viewDidEndLiveResize {
	[((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor performSelectorOnMainThread: @selector(set) withObject: nil waitUntilDone: NO];	
}

#pragma mark Drawing


- (void) drawImageUsingClip: (CGRect) clip {
	
	if (clippyIsEmpty){
		clippy = clip;
		clippyIsEmpty = NO;
	} else {
		clippy = CGRectUnion(clippy, clip);
	}
	syncNeeded = YES;
}

- (void) drawThelayers {
    extern BOOL gSqueakHeadless;
	if (gSqueakHeadless) {
        firstDrawCompleted = YES;
        return;
    }
	if (syncNeeded) {
		[self display];
    }
	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
        extern sqInt getFullScreenFlag(void);
		if (getFullScreenFlag() == 0) {
			[self.window makeKeyAndOrderFront: self];
        }
	}
}

- (void)swapColors:(void *)bits imageWidth:(int)width clipRect:(CGRect)rect {
    int *bitsAsWord = (int *)bits;

    for (int i = rect.origin.y; i < (rect.origin.y + rect.size.height); i++) {
        for (int j = rect.origin.x; j < (rect.origin.x + rect.size.width); j++) {
            int pos = (i * width) + j;
            int swap = bitsAsWord[pos];
            int swapBlue = (swap & 0xff) << 16;
            int swapRed = (swap & 0xff0000) >> 16;
            bitsAsWord[pos] = (swap & 0xff00ff00) | swapBlue | swapRed ;
        }
    }
}

/* Now the displayBits is known and likely pinned, couldn't we cache the bitmap
 * that this method creates?  Yes its contents need to be updated, but it
 * doesn't need to be created all the time does it?  Or is the object created
 * by CGImageCreate merely a wrapper around the bits?
 * eem 2017/05/12
 */

- (void) performDraw: (CGRect)rect {

    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);

    int bitSize = interpreterProxy->byteSizeOf(displayBits - BaseHeaderSize);
    int bytePerRow = displayWidth * displayDepth / 8;

    CGRect r = NSRectToCGRect([self frame]);
    int y2 = MAX(r.size.height - (rect.origin.y), 0);
    int y1 = MAX(y2 - rect.size.height, 0);

    CGRect swapRect = CGRectIntersection(
							CGRectMake(0, 0, displayWidth, displayHeight),
							CGRectMake(rect.origin.x, y1, rect.size.width, y2));
    if (swapRect.origin.x == INFINITY || swapRect.origin.y == INFINITY) {
        return;
    }
    [self swapColors: displayBits imageWidth: displayWidth clipRect: swapRect];

    CGDataProviderRef pRef = CGDataProviderCreateWithData (NULL, displayBits, bitSize, NULL);
    CGContextTranslateCTM(context, 0, displayHeight);
    CGContextScaleCTM(context, 1, -1);
    CGImageRef image = CGImageCreate(displayWidth,
                                     displayHeight,
                                     8,
                                     32,
                                     bytePerRow,
                                     colorspace,
                                     kCGBitmapByteOrder32Big | kCGImageAlphaLast,
                                     pRef,
                                     NULL,
                                     NO,
                                     kCGRenderingIntentDefault);

    CGContextClipToRect(context,rect);
    CGContextDrawImage(context, CGRectMake(0, 0, displayWidth, displayHeight), image);

    [self swapColors: displayBits imageWidth: displayWidth clipRect: swapRect];

    CGImageRelease(image);
    CGDataProviderRelease(pRef);

    CGContextRestoreGState(context);
}

-(void)drawRect:(NSRect)rect
{
    [self performDraw:(clippyIsEmpty? NSRectToCGRect(rect):clippy)];
    clippyIsEmpty = YES;
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
