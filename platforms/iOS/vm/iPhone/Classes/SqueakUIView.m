//
//  SqueakUIView.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/20/08.
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
#import "SqueakUIView.h"
#import "sqSqueakMainApplication.h"
#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "sqSqueakIPhoneApplication+events.h"
#import "sqiPhoneScreenAndWindow.h"
#import "sq.h"

extern struct	VirtualMachine* interpreterProxy;
extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;
SInt32 undoCounter=1, oldValue=0;  // jdr undo support

@implementation SqueakUIView : UIView ;
@synthesize squeakTheDisplayBits;

- (instancetype)initWithFrame:(CGRect) aFrame {
	self = [super initWithFrame: aFrame];
	self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	colorspace = CGColorSpaceCreateDeviceRGB();
    
    // jdr - hack cmd-z undo support
    self.arrowsNames = @[UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputUpArrow, UIKeyInputDownArrow];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setUndoFlag: undoCounter];
    });
	return self;
}


- (void) preDrawThelayers{
}

- (void) drawThelayers {
}

- (void) drawImageUsingClip: (CGRect) clip {
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Called by Main Thread, beware of calling Squeak routines in Squeak Thread
	[(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseBegan];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{  
	//Called by Main Thread, beware of calling Squeak routines in Squeak Thread
	[(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseMoved];
	
}

// Handles the end of a touch event.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	//Called by Main Thread, beware of calling Squeak routines in Squeak Thread
	[(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseEnded];
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event {
	//Called by Main Thread, beware of calling Squeak routines in Squeak Thread
	[(sqSqueakIPhoneApplication *) gDelegateApp.squeakApplication recordTouchEvent: touches type: UITouchPhaseCancelled];
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

// jdr - extra bluetooth keyboard support

- (void)sendCharCode: (sqInt) charCode pressCode: (sqInt) pressCode mod: (sqInt) mod uni: (sqInt) u  {
    sqKeyboardEvent evt;
    evt.type = EventTypeKeyboard;
    evt.timeStamp = (int) ioMSecs();
    evt.pressCode = pressCode;
    evt.modifiers = mod;
    evt.charCode = charCode;
    evt.utf32Code = u;
    evt.reserved1 = 0;
    evt.windowIndex = 1;
    [self pushEventToQueue: (sqInputEvent *)&evt];
}

- (void)sendTriplet:(sqInt)u mod: (sqInt)mod{
    sqInt cc = [self figureOutKeyCode: u];
    [self sendCharCode: cc pressCode: EventKeyDown mod: mod  uni: 0];
    [self sendCharCode: u pressCode: EventKeyChar mod: mod uni: u];
    [self sendCharCode: cc pressCode: EventKeyUp mod: mod uni: 0];
}

- (void)sendCmdTriplet:(sqInt)u {
    [self sendTriplet: u mod: CommandKeyBit];
}

- (void)sendShiftCmdTriplet:(sqInt)u {
    [self sendTriplet: u mod: CommandKeyBit | ShiftKeyBit];
}

- (void)sendCtrlTriplet:(sqInt)u {
    [self sendTriplet: u mod: CtrlKeyBit];
}

- (void)handleShortcutCmd:(UIKeyCommand *)keyCommand {
    NSString *input = [keyCommand input];
    sqInt u = (sqInt)[input characterAtIndex:0];
    [self sendCmdTriplet: u];
}

- (void)handleShortcutShiftCmd:(UIKeyCommand *)keyCommand {
    NSString *input = [keyCommand input];
    sqInt u = (sqInt)[input characterAtIndex:0]-32; // upper case
    [self sendShiftCmdTriplet: u];
}

- (void)handleShortcutCtrl:(UIKeyCommand *)keyCommand {
    NSString *input = [keyCommand input];
    sqInt u = (sqInt)[input characterAtIndex:0]-96; // convert to ctrl character
    [self sendCtrlTriplet: u];
}

- (void)handleArrows:(UIKeyCommand *)keyCommand {
    sqInt u = (sqInt)[self.arrowsNames indexOfObject: [keyCommand input]];
    [self sendTriplet: u+28 mod:0]; // fs gs rs us
}

- (void)handleCmdArrows:(UIKeyCommand *)keyCommand {
    sqInt u = (sqInt)[self.arrowsNames indexOfObject: [keyCommand input]];
    [self sendTriplet: u+28 mod:CommandKeyBit];
}

- (void)cut:(id)sender {
    [self sendCmdTriplet: 'x'];
}

- (void)copy:(id)sender {
    [self sendCmdTriplet: 'c'];
}

- (void)paste:(id)sender {
    [self sendCmdTriplet: 'v'];
}

- (void)selectAll:(id)sender {
    [self sendCmdTriplet: 'a'];
}

- (void)toggleItalics:(id)sender {
    [self sendCmdTriplet: 'i']; // inspect
}

- (void)toggleBoldface:(id)sender {
    [self sendCmdTriplet: 'b']; // browse
}

- (void)toggleUnderline:(id)sender {
    [self sendCmdTriplet: 'u']; // align
}

// hack to use cmd-z
- (void)setUndoFlag:(int)newValue {
//    printf("%i %i\n", oldValue, newValue);
    if (newValue == oldValue) { // undo
        [self sendCmdTriplet: 'z'];
        undoCounter++;
        oldValue=undoCounter-1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUndoFlag: undoCounter];
        });

    }
    else {
        [[self.undoManager prepareWithInvocationTarget:self] setUndoFlag: oldValue];
    }
}

// extra - shake generate a Cmd-.
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        // User was shaking the device.
        [self sendCharCode: 46 pressCode: EventKeyChar mod: CommandKeyBit uni: 0];
    }
}

// =====================================

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)text {
	[self recordCharEvent: text];
}

- (void)deleteBackward {
	unichar delete[1];
	delete[0] =  0x08;

	[self recordCharEvent:[NSString stringWithCharacters: delete length: 1]];
}

- (void) pushEventToQueue: (sqInputEvent *) evt {	
	NSMutableArray* data = [NSMutableArray arrayWithCapacity: 2];
	[data addObject: @7];
	[data addObject: [NSData  dataWithBytes:(const void *) evt length: sizeof(sqInputEvent)]];
	[[gDelegateApp.squeakApplication eventQueue]  addItem: data];
}

- (int) figureOutKeyCode: (unichar) unicode {
	static int unicodeToKeyCode[] = {54, 115, 11, 52, 119, 114, 3, 5, 51, 48, 38, 116, 121, 36, 45, 31, 
		96, 12, 15, 1, 17, 32, 9, 13, 7, 16, 6, 53, 123, 124, 126, 125, 49, 18, 39, 20, 21, 23, 26, 39, 
		25, 29, 67, 69, 43, 27, 47, 44, 29, 18, 19, 20, 21, 23, 22, 26, 28, 25, 41, 41, 43, 24, 47, 
		44, 19, 0, 11, 8, 2, 14, 3, 5, 4, 34, 38, 40, 37, 46, 45, 31, 35, 12, 15, 1, 17, 32, 9, 13, 
		7, 16, 6, 33, 42, 30, 22, 27, 50, 0, 11, 8, 2, 14, 3, 5, 4, 34, 38, 40, 37, 46, 45, 31, 35, 
		12, 15, 1, 17, 32, 9, 13, 7, 16, 6, 33, 42, 30, 50, 117};
	if (unicode > 127) 
		return 0;
	return unicodeToKeyCode[unicode];
	
}

- (void) recordCharEvent:(NSString *) unicodeString {
	sqKeyboardEvent evt;
	unichar unicode;
	unsigned char macRomanCharacter;
	NSInteger	i;
	NSRange picker;
	NSUInteger totaLength;
	
	evt.type = EventTypeKeyboard;
	evt.timeStamp = (int) ioMSecs();
	picker.location = 0;
	picker.length = 1;
	totaLength = [unicodeString length];
	for (i=0;i < totaLength;i++) {
		
		unicode = [unicodeString characterAtIndex: i];
		NSString *lookupString = [[NSString alloc] initWithCharacters: &unicode length: 1];
		[lookupString getBytes: &macRomanCharacter maxLength: 1 usedLength: NULL encoding: NSMacOSRomanStringEncoding
					   options: 0 range: picker remainingRange: NULL];
		
		// LF -> CR
		if (macRomanCharacter == 10) {
			unicode = 13;
            macRomanCharacter = 13;
        }
		
		evt.pressCode = EventKeyDown;
		BOOL isUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember: unicode];
		evt.modifiers = isUppercase ? ShiftKeyBit : 0;
		evt.charCode = [self figureOutKeyCode: unicode];

		unsigned int keyCodeRemembered = evt.charCode;
		evt.utf32Code = 0;
		evt.reserved1 = 0;
		evt.windowIndex = 1;
		[self pushEventToQueue: (sqInputEvent *)&evt];
		
		evt.charCode =	macRomanCharacter;
		evt.pressCode = EventKeyChar;
		evt.modifiers = evt.modifiers;
		if ((evt.modifiers & CommandKeyBit) && (evt.modifiers & ShiftKeyBit)) {  /* command and shift */
            if ((unicode >= 97) && (unicode <= 122)) {
				/* convert ascii code of command-shift-letter to upper case */
				unicode = unicode - 32;
            }
		}
		
		evt.utf32Code = unicode;
		evt.timeStamp++; 
		[self pushEventToQueue: (sqInputEvent *) &evt];
		if (YES) {
			evt.pressCode = EventKeyUp;
			evt.charCode = keyCodeRemembered;
			evt.utf32Code = 0;
			evt.timeStamp++; 
			[self pushEventToQueue: (sqInputEvent *) &evt];
		}
	}
	
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
	
}
 
@end

