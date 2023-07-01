//
//  sqSqueakOSXHeadlessView.m
//  SqueakPureObjc
//
//  Created by Ronie Salgado on 25-03-19.
/*
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

#import "sqSqueakOSXHeadlessView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sq.h"

extern SqueakOSXAppDelegate *gDelegateApp;

@implementation sqSqueakOSXHeadlessView
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

- (void) viewWillStartLiveResize {
}

- (void) viewDidEndLiveResize {
}

#pragma mark Drawing
- (void) drawImageUsingClip: (CGRect) clip {
}

- (void) drawThelayers {
    extern BOOL gSqueakHeadless;
	if (gSqueakHeadless) {
        firstDrawCompleted = YES;
        return;
    }
}

- (void)swapColors:(void *)bits imageWidth:(int)width clipRect:(CGRect)rect {
}

- (void) performDraw: (CGRect)rect {
}

-(void)drawRect:(NSRect)rect {
}

#pragma mark Fullscreen


- (void)  ioSetFullScreen: (sqInt) fullScreen {
}

@end
