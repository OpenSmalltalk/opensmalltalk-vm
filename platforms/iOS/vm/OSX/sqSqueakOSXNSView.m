//
//  sqSqueakOSXNSView.m
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

#import "sqSqueakOSXNSView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sq.h"
#import "sqVirtualMachine.h"

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

@implementation sqSqueakOSXNSView
@synthesize squeakTrackingRectForCursor,lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,dragItems,windowLogic,savedScreenBoundsAtTimeOfFullScreen;

static NSString *stringWithCharacter(unichar character) {
	return [NSString stringWithCharacters: &character length: 1];
}


static void MyProviderReleaseData (
								   void *info,
								   const void *data,
								   size_t size
								   ) {
	free((void*)data);
}

- (void) initializeVariables {
	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
//	NSLog(@"registerForDraggedTypes");
	dragInProgress = NO;
	dragCount = 0;
	dragItems = NULL;
	colorspace = CGColorSpaceCreateDeviceRGB();
	[self setWantsLayer:YES];
	[self initializeSqueakColorMap];
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize: newSize];
	
	int dividedWidthInteger = dividedWidth = (newSize.width/4.0);
	int dividedHeightInteger= dividedHeight = (newSize.height/4.0);
	
	int lastTileWidth = newSize.width - dividedWidthInteger*3;
	int lastTileHeight = newSize.height - dividedHeightInteger*3;
	
	CALayer *setupLayer = [CALayer layer];
	[setupLayer setOpaque: YES];
	setupLayer.frame = CGRectMake(0.0f,0.0f, newSize.width, newSize.height);
	[self setLayer: setupLayer];

	int h,v;
	for (v=0;v<4;v++) {
		for (h=0;h<4;h++) {
			setupLayer = [CALayer layer];
			[setupLayer setOpaque: YES];
			
			CGFloat usableWidth = dividedWidthInteger;
			CGFloat usableHeight = dividedHeightInteger;
			if (v == 0) 
				usableHeight = lastTileHeight;
			if (h == 3) 
				usableWidth = lastTileWidth;
			
			setupLayer.frame = frameForQuartz[v][h] = CGRectMake(dividedWidthInteger*h,dividedHeightInteger*(3-v), usableWidth, usableHeight);
//			NSLog(@" vhxywh %i %i %f %f %f %f",v,h,setupLayer.frame.origin.x,setupLayer.frame.origin.y,setupLayer.frame.size.width,setupLayer.frame.size.height);
			[self.layer addSublayer: setupLayer];
			myLayer[v][h] = setupLayer;
			dirty[v][h] = NO;
		}
	}
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self initializeVariables];
	}
    return self;
}

- (void) dealloc {
    [super dealloc];
	free(colorMap32);
	CGColorSpaceRelease(colorspace);
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
//	[self.window setShowsResizeIndicator: YES];
	[[NSCursor arrowCursor] set];
}

- (void) viewDidEndLiveResize {
//	[self.window setShowsResizeIndicator: NO];
	[((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor performSelectorOnMainThread: @selector(set) withObject: nil waitUntilDone: NO];	
}

/* 
 if (depth == 32) {
 return [super createImageFrom: dispBitsIndex 
 depth: depth 
 colorspace: colorspace 
 pitch: pitch 
 affectedT: affectedT 
 affectedB: affectedB 
 affectedL: affectedL 
 affectedR: affectedR 
 height: height 
 width: width];
 } else {
 return [[self getMainView] computeBitmapFromBitsIndex: dispBitsIndex
 width:width
 height:height
 depth:depth
 left:affectedL
 right:affectedR
 top:affectedT
 bottom:affectedB];
 }

 */


- (CGImageRef) createImageFrom: (void *) dispBitsIndex affectedT: (int) affectedT affectedB: (int) affectedB affectedL: (int) affectedL 
					 affectedR: (int) affectedR height: (int) height width: (int) width {
	const size_t depth = 32;
	void *tempMemory;
	
	size_t 	pitch = ((((width)*(depth) + 31) >> 5) << 2);
	
	size_t totalSize = pitch * (affectedB-affectedT)-affectedL*4;
	tempMemory = malloc(totalSize);
	memcpy(tempMemory,(void*)dispBitsIndex+ pitch*affectedT + affectedL*4,totalSize);
	CGDataProviderRef provider =  CGDataProviderCreateWithData (NULL,tempMemory,(size_t) totalSize,MyProviderReleaseData);
	
	CGImageRef image = CGImageCreate((size_t) affectedR-affectedL,(size_t) affectedB-affectedT, (size_t) 8 /* bitsPerComponent */,
									 (size_t) depth /* bitsPerPixel */, 
									 (size_t) pitch, colorspace, 
									 (CGBitmapInfo) kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host , 
									 provider, NULL, (bool) 0, kCGRenderingIntentDefault);
	
	CGDataProviderRelease(provider);
//	NSLog(@"cif pitch %i T %i L %i B %i R %i h %i w %i",pitch,affectedT,affectedL,affectedB,affectedR,height,width);
	return image;
}


- (void) drawImageUsingClip: (CGRect) clip {
		int h,v;
	for (v=0;v<4;v++) {
		for (h=0;h<4;h++) {
			dirty[v][h] = dirty[v][h] || CGRectIntersectsRect(myLayer[v][h].frame,clip);
		}
	}
}


- (void) drawThelayers {	
	sqInt formObj = interpreterProxy->displayObject();
	sqInt formPtrOop = interpreterProxy->fetchPointerofObject(0, formObj);	
	void* dispBitsIndex = interpreterProxy->firstIndexableField(formPtrOop);
	CGRect rect;
	[CATransaction begin];
	[CATransaction setValue: (id)kCFBooleanTrue forKey: kCATransactionDisableActions];
	int h,v;
	for (v=0;v<4;v++) {
		for (h=0;h<4;h++) {
			if (dirty[v][h]) {
				CGRect ff = myLayer[v][h].frame;
				
				rect.origin.x = myLayer[v][h].frame.origin.x;
				rect.origin.y = self.frame.size.height-myLayer[v][h].frame.origin.y-myLayer[v][h].frame.size.height;
				rect.size.height = myLayer[v][h].frame.size.height;
				rect.size.width = myLayer[v][h].frame.size.width;
				
//				NSLog(@" dtl vhxywh %i %i %f %f %f %f",v,h,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
				CGImageRef x= [self createImageFrom: dispBitsIndex 
										  affectedT: rect.origin.y 
										  affectedB: rect.origin.y+rect.size.height 
										  affectedL: rect.origin.x 
										  affectedR: rect.origin.x+rect.size.width 
											 height: (int) self.frame.size.height
											  width: (int) self.frame.size.width];
				myLayer[v][h].contents = (id)x; 
				CGImageRelease(x);
				dirty[v][h] = NO;
			}
		}
	}
	[CATransaction commit];
	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
		if (getFullScreenFlag() == 0)
			[self.window makeKeyAndOrderFront: self];
	}
	
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
	
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = [[keyBoardStrokeDetails alloc] init];
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	
	NSArray *down = [[NSArray alloc] initWithObjects: theEvent,nil];
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
	[down release];
}

-(void)keyDown:(NSEvent*)theEvent {
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = [[keyBoardStrokeDetails alloc] init];
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	
	NSArray *down = [[NSArray alloc] initWithObjects: theEvent,nil];
	@synchronized(self) {
		lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;
		[self interpretKeyEvents: down];
		self.lastSeenKeyBoardStrokeDetails = NULL;
	}
	[down release];
}

-(void)keyUp:(NSEvent*)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyUpEvent: theEvent fromView: self];
}

/* 10.5 seems only to call insertText:, but 10.6 calls insertText:replacementRange: */

- (void)insertText:(id)aString
{
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)flagsChanged:(NSEvent *)theEvent {
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = [[keyBoardStrokeDetails alloc] init];
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	self.lastSeenKeyBoardModifierDetails = aKeyBoardStrokeDetails;
	[aKeyBoardStrokeDetails release];
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
	
	encode(  8, 51, deleteBackward:)
	else encode( 8, 51, deleteWordBackward:) 
		else encode(127, 51, deleteForward:)
			else encode(127, 51, deleteWordForward:)
				else encode( 8, 51, deleteBackwardByDecomposingPreviousCharacter:) 
				
				
				else encode( (isFunctionKey ? 3: 13), (isFunctionKey ? 76: 36), insertNewline:) 
					else encode( 13, 36, insertLineBreak:) 
						else encode( 13, 36, insertNewlineIgnoringFieldEditor:) 
							
							else encode(  9, 48, insertTab:)
								else encode(  9, 48, insertBacktab:)
									else encode(  9, 48, insertTabIgnoringFieldEditor:)
										
										else encode( 28, 123,  moveLeft:)
											else encode( 29, 124, moveRight:)
												else encode( 30, 126, moveUp:)
													else encode( 31, 125, moveDown:)
																
														else encode( 30, 126, moveBackward:)
															else encode( 31, 125, moveForward:)
																else encode( 28, 123, moveLeftAndModifySelection:)
																	else encode( 29, 124, moveRightAndModifySelection:)
																
																		else encode( 30, 126, moveUpAndModifySelection:)
																			else encode( 31, 125, moveDownAndModifySelection:)
																				else encode( 28, 123, moveWordLeftAndModifySelection:)
																					else encode( 29, 124, moveWordRightAndModifySelection:)
																
																						else encode( 28, 123, moveWordLeft:)
																							else encode( 29, 124, moveWordRight:)
																								else encode( 30, 126, moveParagraphBackwardAndModifySelection:)
																									else encode( 31, 125, moveParagraphForwardAndModifySelection:)
																										
																										else encode( 11, 116, pageUp:)
																											else encode( 12, 121, pageDown:)
																
																												else encode( 11, 116, pageUpAndModifySelection:)
																													else encode( 12, 121, pageDownAndModifySelection:)
																
																														else encode( (isFunctionKey ? 11 : 30), (isFunctionKey ? 116 : 126), scrollPageUp:)
																															else encode( (isFunctionKey ? 12 : 31), (isFunctionKey ? 121 : 125), scrollPageDown:)
																																
																																else encode(  1, 115, moveToBeginningOfDocument:)
																																	else encode(  4, 119, moveToEndOfDocument:)
																
																																		else encode(  (isFunctionKey ? 1 : 28), (isFunctionKey ? 115 : 123), moveToLeftEndOfLine:)
																																			else encode(  (isFunctionKey ? 4 : 29), (isFunctionKey ? 119 : 124), moveToRightEndOfLine:)

																																				else encode(  1, 115, scrollToBeginningOfDocument:)
																																					else encode(  4, 119, scrollToEndOfDocument:)
																
																																				else encode(  1, 115, moveToBeginningOfDocumentAndModifySelection:)
																																					else encode(  4, 119, moveToEndOfDocumentAndModifySelection:)
																																						
			 																																			
																																						else encode( 27, 53, cancelOperation:)
																																							else encode( 27, 53, cancel:)
																																								else encode( 27, 53, complete:)
																																									else encode( 27, 71, delete:)
																																								else 
																																									return;
	
	@synchronized(self) {
		keyBoardStrokeDetails *aKeyBoardStrokeDetails = [[keyBoardStrokeDetails alloc] init];
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
	
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: DragEnter numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex];
	
	return NSDragOperationGeneric;
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)info
{
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: DragMove numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex];
	return NSDragOperationGeneric;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: DragLeave numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex];
	self.dragCount = 0;
	self.dragInProgress = NO;
	self.dragItems = NULL;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info {
	if (self.dragCount) {
		self.dragItems = [self filterOutSqueakImageFilesFromDraggedFiles: info];
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: DragDrop numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex];
	} else {
		NSArray *images = [self filterSqueakImageFilesFromDraggedFiles: info];
		if ([images count] > 0) {
			for (NSString *item in images ){
				NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
				LSLaunchURLSpec launchSpec;
				launchSpec.appURL = (CFURLRef)url;
				launchSpec.passThruParams = NULL;
				launchSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObject:[NSURL fileURLWithPath: item]];
				launchSpec.launchFlags = kLSLaunchDefaults | kLSLaunchNewInstance;
				launchSpec.asyncRefCon = NULL;
				
				OSErr err = LSOpenFromURLSpec(&launchSpec, NULL);
			}
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
		[self fadeOut];
		[self enterFullScreenMode:[NSScreen mainScreen] withOptions: nil];
		extern struct	VirtualMachine* interpreterProxy;
		interpreterProxy->fullDisplayUpdate();
		[self fadeIn];
	}
	
	if ([self isInFullScreenMode] == YES && (fullScreen == 0)) {
		[self fadeOut];
		[self exitFullScreenModeWithOptions: NULL];
		[self fadeIn];
		if ([self.window isKeyWindow] == NO) {
			[self.window makeKeyAndOrderFront: self];
			//	NOT SURE IF THIS IS NEEDED, MORE TESTING	[self.window setContentSize: self.savedScreenBoundsAtTimeOfFullScreen.size];
		}
	}
}

- (void)fadeOut {
	CGDisplayErr    err;
	
	err = CGAcquireDisplayFadeReservation((CGDisplayReservationInterval)kCGMaxDisplayReservationInterval,
										  &fadeToken);
	if (err == kCGErrorSuccess) {
		CGDisplayFade(fadeToken,
					  1.5f,
					  (CGDisplayBlendFraction)kCGDisplayBlendNormal,
					  (CGDisplayBlendFraction)kCGDisplayBlendSolidColor,
					  0.0f,
					  0.0f,
					  0.0f,
					  TRUE);
	} 
} 

- (void)fadeIn {
	CGDisplayErr    err;
	
	err = CGDisplayFade(fadeToken,
						3.5f,
						(CGDisplayBlendFraction)kCGDisplayBlendSolidColor,
						(CGDisplayBlendFraction)kCGDisplayBlendNormal,
						0.0f,
						0.0f,
						0.0f,
						FALSE);
	if (err == kCGErrorSuccess) {
		CGReleaseDisplayFadeReservation(fadeToken);
	} 
}

@end
