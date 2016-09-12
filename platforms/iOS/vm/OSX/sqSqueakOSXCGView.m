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
#import <QuartzCore/CIImage.h>

//#import <OpenGL/CGLMacro.h>

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

#define max(x, y) (x > y? x: y)

static NSString *stringWithCharacter(unichar character) {
	return [NSString stringWithCharacters: &character length: 1];
}

@implementation sqSqueakOSXCGView
@synthesize squeakTrackingRectForCursor,lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,dragItems,windowLogic,savedScreenBoundsAtTimeOfFullScreen;

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
	NSOpenGLPixelFormatAttribute attrs[] =
    {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFABackingStore,
		0
    };
    return AUTORELEASEOBJ([[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]);
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];

    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];
    
    [self initialize];
    
    return self;
}

- (void)awakeFromNib {
	//self = [self initWithFrame: self.frame pixelFormat: [[self class] defaultPixelFormat] ];
//    self = [self initWithFrame: self.frame];
    [self initialize];
}

- (void)initialize {
	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	dragInProgress = NO;
	dragCount = 0;
	dragItems = NULL;
	clippyIsEmpty = YES;
	colorspace = CGColorSpaceCreateDeviceRGB();
}

- (void) initializeVariables {
}

- (void) preDrawThelayers{
}

- (void) dealloc {
	free(colorMap32);
	CGColorSpaceRelease(colorspace);
    SUPERDEALLOC
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL)isFlipped {
	return  YES;
}

- (BOOL)isOpaque {
	return YES;
}

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

- (void) performDraw: (CGRect)rect {
	sqInt form = interpreterProxy->displayObject(); // Form

    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    int width = interpreterProxy->positive32BitValueOf(interpreterProxy->fetchPointerofObject(1, form));
    int height = interpreterProxy->positive32BitValueOf(interpreterProxy->fetchPointerofObject(2, form));
	sqInt formBits = interpreterProxy->fetchPointerofObject(0, form);	// bits
	void* bits = (void*)interpreterProxy->firstIndexableField(formBits); // bits
    int bitSize = interpreterProxy->byteSizeOf(formBits);
    int bytePerRow = 4*width;
    
    CGRect r = NSRectToCGRect([self frame]);
    int y2 = max(r.size.height - (rect.origin.y), 0);
    int y1 = max(y2 - rect.size.height, 0);
    
    CGRect swapRect = CGRectIntersection(CGRectMake(0, 0, width, height), CGRectMake(rect.origin.x, y1, rect.size.width, y2));
    if ((swapRect.origin.x == INFINITY) || (swapRect.origin.y == INFINITY)) {
        return;
    }
    [self swapColors: bits imageWidth:width clipRect: swapRect];
    
    CGDataProviderRef pref = CGDataProviderCreateWithData (NULL, bits, bitSize, NULL);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGImageRef image = CGImageCreate(width, 
                                     height, 
                                     8, 
                                     32, 
                                     bytePerRow, 
                                     colorspace, 
                                     kCGBitmapByteOrder32Big | kCGImageAlphaLast, 
                                     pref, 
                                     NULL, 
                                     NO, 
                                     kCGRenderingIntentDefault);
    
    CGContextClipToRect(context,rect);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

    [self swapColors:bits imageWidth:width clipRect: swapRect];
    
    CGImageRelease(image);
    CGDataProviderRelease(pref);
    
    CGContextRestoreGState(context);
}

-(void)drawRect:(NSRect)rect
{
    [self performDraw:(clippyIsEmpty? NSRectToCGRect(rect):clippy)];
    clippyIsEmpty = YES;
    syncNeeded = NO;
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)scrollWheel:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordWheelEvent: theEvent fromView: self];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)otherMouseUp:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)mouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}
- (void)otherMouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseEvent: theEvent fromView: self];
}
 
- (NSString *) dealWithOpenStepChars: (NSString *) openStep {
	
	unichar keyChar; 
	static unichar combiningHelpChar[] = {0x003F, 0x20DD};
	
	keyChar = [openStep characterAtIndex: 0]; 
	
//http://unicode.org/Public/MAPPINGS/VENDORS/APPLE/KEYBOARD.TXT
	
	switch (keyChar) { 
		case NSUpArrowFunctionKey: keyChar = 30; break; 
		case NSDownArrowFunctionKey: keyChar = 31; break; 
		case NSLeftArrowFunctionKey: keyChar = 28; break; 
		case NSRightArrowFunctionKey: keyChar = 29; break; 
		case NSInsertFunctionKey: 
		  	return [NSString stringWithCharacters: combiningHelpChar length: 2];
		case NSDeleteFunctionKey: keyChar = 0x2326; break; 
		case NSHomeFunctionKey: keyChar = 1; break; 
		case NSEndFunctionKey: keyChar = 4; break;
		case NSPageUpFunctionKey: 
			keyChar = 0x21DE; break;
		case NSPageDownFunctionKey: 
			keyChar = 0x21DF; break;
		case NSClearLineFunctionKey: keyChar = 0x2327; break;
		case 127: keyChar = 8; break;
		default: 
			if (keyChar >= NSF1FunctionKey && keyChar <= NSF35FunctionKey) { 
				keyChar = 0; 
			}
	}
	return stringWithCharacter(keyChar);
}


-(void)  fakeKeyDownUp: (NSEvent*) theEvent {
	
	//http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CORPCHAR.TXT
	//http://www.internet4classrooms.com/mac_ext.gif
	//http://developer.apple.com/legacy/mac/library/documentation/mac/Text/Text-571.html
	
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	
    NSArray *down = @[theEvent];
	@synchronized(self) {
		lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;

		NSString *possibleConversion = [theEvent characters];
		
		if ([possibleConversion length] > 0) {
			NSString *c = [self dealWithOpenStepChars: possibleConversion];
			[self insertText: c replacementRange: NSMakeRange(NSNotFound, 0)];
		}
		self.lastSeenKeyBoardStrokeDetails = NULL;
		[self keyUp: theEvent]; 
	}
}

-(void)keyDown:(NSEvent*)theEvent {
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	
	NSArray *down = @[theEvent];
//	NSLog(@"sqSqueakOSXCGView.m>>keyDown:");
	@synchronized(self) {
		lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;
		[self interpretKeyEvents: down];
		self.lastSeenKeyBoardStrokeDetails = NULL;
	}
}

-(void)keyUp:(NSEvent*)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyUpEvent: theEvent fromView: self];
}

/* 10.5 seems only to call insertText:, but 10.6 calls insertText:replacementRange: */

- (void)insertText:(id)aString
{
//	NSLog(@"sqSqueakOSXCGView.m>>insertText:");

	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
//	NSLog(@"sqSqueakOSXCGView.m>>insertText:replacementRange:");
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)flagsChanged:(NSEvent *)theEvent {
//	NSLog(@"sqSqueakOSXCGView.m>>flagsChanged -- %d, %d", [theEvent keyCode], [theEvent modifierFlags] );
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	self.lastSeenKeyBoardModifierDetails = aKeyBoardStrokeDetails;
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyDownEvent: theEvent fromView: self];
}

- (void)doCommandBySelector:(SEL)aSelector {
	unichar unicode;
	unsigned short keyCode;
	NSString *unicodeString;
	BOOL isFunctionKey = NO;
	
	if (self.lastSeenKeyBoardModifierDetails) {
		isFunctionKey = (self.lastSeenKeyBoardModifierDetails.modifierFlags & NSFunctionKeyMask) == NSFunctionKeyMask;
	}
	
#define encode(c, k,  s) 		 if (aSelector == @selector(s)) { unicode = c; keyCode = k; unicodeString = [NSString stringWithCharacters: &unicode length: 1]; } 
//http://developer.apple.com/documentation/mac/Text/Text-571.html
	
	encode(  8, 51,         deleteBackward:)
	else encode( 8, 51,     deleteWordBackward:) 
    else encode(127, 51,    deleteForward:)
    else encode(127, 51,    deleteWordForward:)
    else encode( 8, 51,     deleteBackwardByDecomposingPreviousCharacter:) 
    else encode( (isFunctionKey ? 3: 13), (isFunctionKey ? 76: 36), insertNewline:) 
    else encode( 13, 36,    insertLineBreak:) 
    else encode( 13, 36,    insertNewlineIgnoringFieldEditor:) 
    else encode(  9, 48,    insertTab:)
    else encode(  9, 48,    insertBacktab:)
    else encode(  9, 48,    insertTabIgnoringFieldEditor:)
    else encode( 28, 123,   moveLeft:)
    else encode( 29, 124,   moveRight:)
    else encode( 30, 126,   moveUp:)
    else encode( 31, 125,   moveDown:)
    else encode( 30, 126,   moveBackward:)
    else encode( 31, 125,   moveForward:)
    else encode( 28, 123,   moveLeftAndModifySelection:)
    else encode( 29, 124,   moveRightAndModifySelection:)
    else encode( 30, 126,   moveUpAndModifySelection:)
    else encode( 31, 125,   moveDownAndModifySelection:)
    else encode( 28, 123,   moveWordLeftAndModifySelection:)
    else encode( 29, 124,   moveWordRightAndModifySelection:)
    else encode( 28, 123,   moveWordLeft:)
    else encode( 29, 124,   moveWordRight:)
    else encode( 30, 126,   moveParagraphBackwardAndModifySelection:)
    else encode( 31, 125,   moveParagraphForwardAndModifySelection:)																										
    else encode( 11, 116,   pageUp:)
    else encode( 12, 121,   pageDown:)
    else encode( 11, 116,   pageUpAndModifySelection:)
    else encode( 12, 121,   pageDownAndModifySelection:)
    else encode( (isFunctionKey ? 11 : 30), (isFunctionKey ? 116 : 126), scrollPageUp:)
    else encode( (isFunctionKey ? 12 : 31), (isFunctionKey ? 121 : 125), scrollPageDown:)
    else encode(  1, 115,   moveToBeginningOfDocument:)
    else encode(  4, 119,   moveToEndOfDocument:)
    else encode(  (isFunctionKey ? 1 : 28), (isFunctionKey ? 115 : 123), moveToLeftEndOfLine:)
    else encode(  (isFunctionKey ? 4 : 29), (isFunctionKey ? 119 : 124), moveToRightEndOfLine:)
    else encode(  (isFunctionKey ? 1 : 28), (isFunctionKey ? 115 : 123), moveToLeftEndOfLineAndModifySelection:)
    else encode(  (isFunctionKey ? 4 : 29), (isFunctionKey ? 119 : 124), moveToRightEndOfLineAndModifySelection:)
    else encode(  1, 115,   scrollToBeginningOfDocument:)
    else encode(  4, 119,   scrollToEndOfDocument:)
    else encode(  1, 115,   moveToBeginningOfDocumentAndModifySelection:)
    else encode(  4, 119,   moveToEndOfDocumentAndModifySelection:)
    else encode( 27, 53,    cancelOperation:)
    else encode( 27, 53,    cancel:)
    else encode( 27, 53,    complete:)
    else encode( 27, 71,    delete:)

    else encode(  1, 115,   moveToBeginningOfLine:)
    else encode(  1, 115,   moveToBeginningOfLineAndModifySelection:)
    else encode(  4, 119,   moveToEndOfLine:)
    else encode(  4, 119,   moveToEndOfLineAndModifySelection:)
    else return;
	
	@synchronized(self) {
		keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
		aKeyBoardStrokeDetails.keyCode = keyCode;
		aKeyBoardStrokeDetails.modifierFlags = self.lastSeenKeyBoardModifierDetails.modifierFlags;
		lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;
			
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: unicodeString fromView: self];
		self.lastSeenKeyBoardStrokeDetails = NULL;
	}
}


- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {
	inputMark= NSMakeRange(0, 1);
	inputSelection= NSMakeRange(NSNotFound, 0);
}

- (void)		 unmarkText {
	inputMark= NSMakeRange(NSNotFound, 0); 
}

- (BOOL)		 hasMarkedText { 
	return inputMark.location != NSNotFound; 
}

- (NSInteger)		 conversationIdentifier	{ 
	return (NSInteger )self; 
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange { 
	return nil; 
}

- (NSRange)		 markedRange { 
	return inputMark; 
}

- (NSRange)		 selectedRange { 
	return inputSelection; 
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
	return NSMakeRect(0,0, 0,0); 
}

- (NSUInteger) characterIndexForPoint: (NSPoint)thePoint {
	return 0; 
}

- (NSArray *) validAttributesForMarkedText { 
	return nil;
}

- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex {
	return NO;
}

- (NSMutableArray *) filterSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info {
	NSPasteboard *pboard= [info draggingPasteboard];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity: 10];
	if ([[pboard types] containsObject: NSFilenamesPboardType]) {
		NSArray *files= [pboard propertyListForType: NSFilenamesPboardType];
		NSString *fileName;
		for (fileName in files) {
			if ([((sqSqueakOSXApplication*) gDelegateApp.squeakApplication) isImageFile: fileName] == YES)
				[results addObject: fileName];
		}
	}
	return results;
}


- (NSMutableArray *) filterOutSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info {
	NSPasteboard *pboard= [info draggingPasteboard];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity: 10];
	if ([[pboard types] containsObject: NSFilenamesPboardType]) {
		NSArray *files= [pboard propertyListForType: NSFilenamesPboardType];
		NSString *fileName;
		for (fileName in files) {
			if ([((sqSqueakOSXApplication*) gDelegateApp.squeakApplication) isImageFile: fileName] == NO)
				[results addObject: fileName];
		}
	}
	return results;
}

- (NSUInteger) countNumberOfNoneSqueakImageFilesInDraggedFiles: (id<NSDraggingInfo>)info {
	NSArray *files = [self filterOutSqueakImageFilesFromDraggedFiles: info];
	return [files count];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)info {
	if (self.dragInProgress) 
		return NSDragOperationNone;
	dragInProgress = YES;
	self.dragCount = (int) [self countNumberOfNoneSqueakImageFilesInDraggedFiles: info];
	
	if [(self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragEnter numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex] view: self];
	
	return NSDragOperationGeneric;
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)info
{
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragMove numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex  view: self];
	return NSDragOperationGeneric;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragLeave numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex  view: self];
	self.dragCount = 0;
	self.dragInProgress = NO;
	self.dragItems = NULL;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info {
	if (self.dragCount) {
		self.dragItems = [self filterOutSqueakImageFilesFromDraggedFiles: info];
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragDrop numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex  view: self];
	} 
	
	NSArray *images = [self filterSqueakImageFilesFromDraggedFiles: info];
	if ([images count] > 0) {
		for (NSString *item in images ){
			NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
			LSLaunchURLSpec launchSpec;
			launchSpec.appURL = (__bridge CFURLRef)url;
			launchSpec.passThruParams = NULL;
			launchSpec.itemURLs = (__bridge CFArrayRef) [NSArray arrayWithObject:[NSURL fileURLWithPath: item]];
			launchSpec.launchFlags = kLSLaunchDefaults | kLSLaunchNewInstance;
			launchSpec.asyncRefCon = NULL;
			
			OSErr err = LSOpenFromURLSpec(&launchSpec, NULL);
#pragma unused(err)
		}
	}
		

	
	dragInProgress = NO;
	return YES;
}

- (NSString*) dragFileNameStringAtIndex: (sqInt) index {
	if (!self.dragItems) 
		return NULL;
	if (index < 1 || index > [self.dragItems count])
		return NULL;
	NSString *filePath = [self.dragItems objectAtIndex: (NSUInteger) index - 1];
	return filePath;
}


- (BOOL)ignoreModifierKeysWhileDragging {
	return YES;
}

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
