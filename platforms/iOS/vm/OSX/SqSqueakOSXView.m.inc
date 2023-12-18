//
//  SqSqueakOSXView.m.inc
//  SqueakPureObjc
//
//  Created by Eliot Miranda 2023/6/13
//
// This file contains the event input code common to sqSqueakOSXMetalView et al,
// included by each backend.
//
// The key architectural constraint for the somewhat complex keyboard event
// processing chain is explained in the comment before keyDown: below.
//
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

@synthesize lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,windowLogic;

#pragma mark Events - Mouse

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
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
}

- (void)otherMouseUp:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
}

- (void)mouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
}
- (void)otherMouseDown:(NSEvent *)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordMouseButtonEvent: theEvent fromView: self];
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
	return [NSString stringWithCharacters: &keyChar length: 1];
}


// keyDown: invokes interpretKeyEvents:, provided by the NSResponder class,
// to do input composition for keyless characters (ä,ë,ï,ö,ü et al).
// Quoting from the documentation:
//
// interpretKeyEvents: Handles a series of key events.
//
// This method, which is invoked by subclasses from the keyDown: method,
// sends the character input in eventArray to the system input manager for
// interpretation as text to insert or commands to perform. The input manager
// responds to the request by sending insertText: and doCommandBySelector:
// messages back to the invoker of this method. Subclasses shouldn't override
// this method.
//
// [& this is us again]. Hence see insertText: and doCommandBySelector: below
//
-(void)keyDown:(NSEvent*)theEvent {
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];

	NSArray *down = @[theEvent];
	@synchronized(self) {
		self.lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;
		[self interpretKeyEvents: down];
		self.lastSeenKeyBoardStrokeDetails = NULL;
	}
}

-(void)keyUp:(NSEvent*)theEvent {
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyUpEvent: theEvent fromView: self];
}

/* 10.5 seems only to call insertText:, but 10.6 calls insertText:replacementRange: */

// See the comment before keyDown: above

- (void)insertText:(id)aString
{
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

/*
 * React to changes in modifiers. We have to maintain states ourselves for
 * rising and falling edges. But then, we can generate up/down events from that.
 */
- (void)flagsChanged:(NSEvent *)theEvent {
    NSEventModifierFlags oldFlags = self.lastSeenKeyBoardModifierDetails.modifierFlags;
    // Detects rising edge.
    BOOL isUp = (oldFlags & NSEventModifierFlagDeviceIndependentFlagsMask)
                > ([theEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask);

    keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	self.lastSeenKeyBoardModifierDetails = aKeyBoardStrokeDetails;

    @synchronized(self) {
        NSEvent* syntheticEvent = [NSEvent keyEventWithType:(isUp ? NSEventTypeKeyUp : NSEventTypeKeyDown)
                                                   location:[theEvent locationInWindow]
                                              modifierFlags:(isUp ? oldFlags : [theEvent modifierFlags])
                                                  timestamp:[theEvent timestamp]
                                               windowNumber:[theEvent windowNumber]
                                                    context:nil
                                                 characters:@""
                                charactersIgnoringModifiers:@""
                                                  isARepeat:NO
                                                    keyCode:[theEvent keyCode]];
        if (isUp) {
            [(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyUpEvent: syntheticEvent fromView: self];
        } else {
            [(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyDownEvent: syntheticEvent fromView: self];
        }
    }
}

// See the comment before keyDown: above

- (void)doCommandBySelector:(SEL)aSelector {
	unichar unicode;
	unsigned short keyCode;
	BOOL isFunctionKey = self.lastSeenKeyBoardModifierDetails
						&& (self.lastSeenKeyBoardModifierDetails.modifierFlags & NSEventModifierFlagFunction) == NSEventModifierFlagFunction;

#define encode(c, k,  s) 		 if (aSelector == @selector(s)) { unicode = c; keyCode = k; }
//http://developer.apple.com/documentation/mac/Text/Text-571.html

		 encode( 8, 51,     deleteBackward:)
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

	NSString *unicodeString = [NSString stringWithCharacters: &unicode length: 1];
	@synchronized(self) {
		keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
		aKeyBoardStrokeDetails.keyCode = keyCode;
		aKeyBoardStrokeDetails.modifierFlags = self.lastSeenKeyBoardModifierDetails.modifierFlags;
		self.lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;

		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: unicodeString fromView: self];
		self.lastSeenKeyBoardStrokeDetails = NULL;
	}
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    if ([theEvent type] != NSEventTypeKeyDown /* don't handle Up here */
        || ([theEvent modifierFlags] & NSEventModifierFlagFunction) /* Better handled in doCommandBySelector: */
        ) {
        return NO;
    }

    // FIXME: Maybe #charactersIgnoringModifiers: ?
    NSString* unicodeString = [theEvent characters];
    if ([unicodeString length] > 0) {
        unicodeString = [self dealWithOpenStepChars: unicodeString];
    }

    @synchronized(self) {
        keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
        aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
        aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
        self.lastSeenKeyBoardStrokeDetails = aKeyBoardStrokeDetails;

        [(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: unicodeString fromView: self];
        self.lastSeenKeyBoardStrokeDetails = NULL;
    }
    return YES;
}


#pragma mark Events - Keyboard - NSTextInputClient


- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {
	inputMark= NSMakeRange(0, 1);
	inputSelection= NSMakeRange(NSNotFound, 0);
}

- (void)unmarkText {
	inputMark= NSMakeRange(NSNotFound, 0);
}

- (BOOL)hasMarkedText {
	return inputMark.location != NSNotFound;
}

- (NSInteger)conversationIdentifier	{
	return (NSInteger )self;
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
	return nil;
}

- (NSRange)markedRange {
	return inputMark;
}

- (NSRange)selectedRange {
	return inputSelection;
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
	return NSMakeRect(0,0, 0,0);
}

- (NSUInteger)characterIndexForPoint: (NSPoint)thePoint {
	return 0;
}

- (NSArray *)validAttributesForMarkedText {
	return nil;
}

- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex {
	return NO;
}

#pragma mark Events - Dragging

- (NSMutableArray *) filterSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info include: (BOOL)doInclude {
    NSPasteboard *pboard= [info draggingPasteboard];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity: 10];
    if ([[pboard types] containsObject: NSPasteboardTypeFileURL]) {
        NSArray *urlClasses = [NSArray arrayWithObject:[NSURL class]];
        NSDictionary *pbOptions = [NSDictionary dictionaryWithObject:
                                 [NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];
        NSArray *files = [pboard readObjectsForClasses:urlClasses options:pbOptions];
        for (NSURL *fileRefURL in files) {
            /*
             * Although we already have an URL, it is a file-refernce-type URL
             * of the form 'file:///.file/id=6571367.25595293' with numbers
             * apparently identifying the file. However, this does not say
             * anything about file names and such, which we rely on.
             */
            NSURL* fileURL = fileRefURL.filePathURL;
            if ([((sqSqueakOSXApplication*) gDelegateApp.squeakApplication) isImageFile: [fileURL path]] == doInclude)
                [results addObject: fileURL];
        }
    }
    return results;
}
- (NSMutableArray *) filterSqueakImageFilesFromDraggedFiles: (id<NSDraggingInfo>)info {
    return [self filterSqueakImageFilesFromDraggedFiles: info include: YES];
}

- (NSMutableArray *) filterOutSqueakImageFilesFromDraggedURIs: (id<NSDraggingInfo>)info {
    return [self filterSqueakImageFilesFromDraggedFiles: info include: NO];
}

- (NSUInteger) countNumberOfNoneSqueakImageFilesInDraggedFiles: (id<NSDraggingInfo>)info {
	NSArray *files = [self filterOutSqueakImageFilesFromDraggedURIs: info];
	return [files count];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)info {
//    NSLog(@"draggingEntered %@",info);

	if (self.dragInProgress)
		return NSDragOperationNone;
	dragInProgress = YES;
	gDelegateApp.dragItems = [self filterOutSqueakImageFilesFromDraggedURIs: info];
	self.dragCount = (int) [self countNumberOfNoneSqueakImageFilesInDraggedFiles: info];

	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragEnter numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex view: self];

	return NSDragOperationGeneric;
}

- (NSDragOperation) draggingUpdated: (id<NSDraggingInfo>)info
{
//    NSLog(@"draggingUpdated %@",info);
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragMove numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex view: self];
	return NSDragOperationGeneric;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
//    NSLog(@"draggingExited %@",info);
	if (self.dragCount)
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragLeave numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex view: self];
	self.dragCount = 0;
	self.dragInProgress = NO;
	gDelegateApp.dragItems = NULL;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info {
//    NSLog(@"performDragOperation %@",info);
	if (self.dragCount) {
		[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordDragEvent: SQDragDrop numberOfFiles: self.dragCount where: [info draggingLocation] windowIndex: self.windowLogic.windowIndex view: self];
	}

	NSArray *images = [self filterSqueakImageFilesFromDraggedFiles: info];
	if ([images count] > 0) {
		for (NSString *item in images ){
			NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
			LSLaunchURLSpec launchSpec;
			launchSpec.appURL = (CFURLRef)CFBridgingRetain(url);
			launchSpec.passThruParams = NULL;
			launchSpec.itemURLs = (__bridge CFArrayRef) @[[NSURL fileURLWithPath: item]];
			launchSpec.launchFlags = kLSLaunchDefaults | kLSLaunchNewInstance;
			launchSpec.asyncRefCon = NULL;

			OSErr err = LSOpenFromURLSpec(&launchSpec, NULL);
#pragma unused(err)
		}
	}

	dragInProgress = NO;
	return YES;
}

- (BOOL)ignoreModifierKeysWhileDragging {
	return YES;
}
