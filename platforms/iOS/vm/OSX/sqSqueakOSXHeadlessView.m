//
//  sqSqueakOSXMetalView.h
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
#import "sqVirtualMachine.h"

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

static NSString *stringWithCharacter(unichar character) {
	return [NSString stringWithCharacters: &character length: 1];
}

@implementation sqSqueakOSXHeadlessView
@synthesize lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,windowLogic,savedScreenBoundsAtTimeOfFullScreen;

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
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	dragInProgress = NO;
	dragCount = 0;
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

-(void)drawRect:(NSRect)rect
{
}

#pragma mark Events - Mouse

- (void)mouseEntered:(NSEvent *)theEvent {
}

- (void)mouseExited:(NSEvent *)theEvent {
}

- (void)mouseMoved:(NSEvent *)theEvent {
}

- (void)mouseDragged:(NSEvent *)theEvent {
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
}

- (void)scrollWheel:(NSEvent *)theEvent {
}

- (void)mouseUp:(NSEvent *)theEvent {
}

- (void)rightMouseUp:(NSEvent *)theEvent {
}

- (void)otherMouseUp:(NSEvent *)theEvent {
}

- (void)mouseDown:(NSEvent *)theEvent {
}

- (void)rightMouseDown:(NSEvent *)theEvent {
}
- (void)otherMouseDown:(NSEvent *)theEvent {
}

#pragma mark Events - Keyboard

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


-(void)keyDown:(NSEvent*)theEvent {
}

-(void)keyUp:(NSEvent*)theEvent {
}

/* 10.5 seems only to call insertText:, but 10.6 calls insertText:replacementRange: */

- (void)insertText:(id)aString
{
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
}

/*
 * React to changes in modifiers. We have to maintain states ourselves for
 * rising and falling edges. But then, we can generate up/down events from that.
 */
- (void)flagsChanged:(NSEvent *)theEvent {
}

- (void)doCommandBySelector:(SEL)aSelector {
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    return YES;
}


#pragma mark Events - Keyboard - NSTextInputClient


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

#pragma mark Events - Dragging

- (NSMutableArray *) filterSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info {
	NSMutableArray *results = [NSMutableArray arrayWithCapacity: 0];
	return results;
}


- (NSMutableArray *) filterOutSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info {
	NSMutableArray *results = [NSMutableArray arrayWithCapacity: 0];
	return results;
}

- (NSUInteger) countNumberOfNoneSqueakImageFilesInDraggedFiles: (id<NSDraggingInfo>)info {
	return 0;
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)info {
	return NSDragOperationGeneric;
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)info
{
	return NSDragOperationGeneric;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info {
	return YES;
}

- (NSString*) dragFileNameStringAtIndex: (sqInt) index {
	return NULL;
}

- (BOOL)ignoreModifierKeysWhileDragging {
	return YES;
}

#pragma mark Fullscreen


- (void)  ioSetFullScreen: (sqInt) fullScreen {

}

@end
