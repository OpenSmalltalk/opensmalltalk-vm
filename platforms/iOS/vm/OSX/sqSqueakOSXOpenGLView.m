//
//  sqSqueakOSXOpenGLView.m
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

#import "sqSqueakOSXOpenGLView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sq.h"
#import "sqVirtualMachine.h"

//#import <OpenGL/CGLMacro.h>
# import <OpenGL/gl.h>
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
# import <OpenGL/OpenGL.h>
#else
# import <OpenGL/Opengl.h>
#endif

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;

static NSString *stringWithCharacter(unichar character) {
	return [NSString stringWithCharacters: &character length: 1];
}

@interface sqSqueakOSXOpenGLView ()
@property (nonatomic,assign) NSRect lastFrameSize;
@property (nonatomic,assign) BOOL fullScreenInProgress;
@property (nonatomic,assign) void* fullScreendispBitsIndex;
@end

@implementation sqSqueakOSXOpenGLView
@synthesize squeakTrackingRectForCursor,lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,dragItems,windowLogic,lastFrameSize,fullScreenInProgress,fullScreendispBitsIndex;

+ (NSOpenGLPixelFormat *)defaultPixelFormat {
	NSOpenGLPixelFormatAttribute attrs[] =
    {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFABackingStore,
		NSOpenGLPFAAllowOfflineRenderers, // Enables automatic graphics card switching
		0
    };
    return AUTORELEASEOBJ([[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]);
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [self initWithFrame:frameRect pixelFormat:[[self class] defaultPixelFormat]];
    [self initialize];
    return self;
}

- (void)awakeFromNib {
    [self initialize];
}

- (void)initialize {
       [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
       [self setAutoresizesSubviews:YES];

	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	//NSLog(@"registerForDraggedTypes %@",self);
	dragInProgress = NO;
	dragCount = 0;
	dragItems = NULL;
	clippyIsEmpty = YES;
    fullScreenInProgress = NO;
	colorspace = CGColorSpaceCreateDeviceRGB();
	[self initializeSqueakColorMap];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(didEnterFullScreen:) name:@"NSWindowDidEnterFullScreenNotification" object:nil];

}

- (void) didEnterFullScreen: (NSNotification*) aNotification {
    //NSLog(@"Notification didEnterFullScreen");
    [self setupFullScreendispBitsIndex];
    self.fullScreenInProgress = NO;
}

- (void) initializeVariables {
}

- (void) dealloc {
	free(colorMap32);
	CGColorSpaceRelease(colorspace);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    //NSLog(@"viewWillStartLiveResize");
    self.fullScreenInProgress = YES;
	[[NSCursor arrowCursor] set];
}

- (void) viewDidEndLiveResize {
    //NSLog(@"viewDidEndLiveResize");
    dispatch_async(dispatch_get_main_queue(), ^{
        [((sqSqueakOSXApplication*) gDelegateApp.squeakApplication).squeakCursor  set];
     });

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
    if (syncNeeded) {
		[self drawRect: NSRectFromCGRect(clippy)];
		syncNeeded = NO;
		clippyIsEmpty = YES;
//		CGL_MACRO_DECLARE_VARIABLES();
		glFlush();
		[[self openGLContext] flushBuffer];  
	}
	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
        extern sqInt getFullScreenFlag(void);
		if (getFullScreenFlag() == 0) {
			[self.window makeKeyAndOrderFront: self];
        }
	}
}

-(void)setupOpenGL {	
//	CGL_MACRO_DECLARE_VARIABLES();
// Enable the multithreading
    //NSLog(@"setupOpenGL runs");
	CGLContextObj ctx = [[self openGLContext] CGLContextObj];
	CGLEnable( ctx, kCGLCEMPEngine);

//	GLint newSwapInterval = 1;
//	CGLSetParameter(cgl_ctx, kCGLCPSwapInterval, &newSwapInterval);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glClearColor(1.0, 1.0, 1.0, 1.0);
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	glDisable(GL_DITHER);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	glDisable (GL_SCISSOR_TEST);
    glDisable (GL_CULL_FACE);
	glStencilMask(0);
	glPixelZoom(1.0,1.0);
	
	glEnable(GL_TEXTURE_RECTANGLE_ARB);
 	glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_PRIORITY, 0.0);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
 	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei( GL_UNPACK_ROW_LENGTH, self.frame.size.width );
	GLuint dt = 1;
	glDeleteTextures(1, &dt);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 1);
	syncNeeded = NO;
}

- (void)loadTexturesFrom: (void*) lastBitsIndex subRectangle: (NSRect) subRect { 
//	CGL_MACRO_DECLARE_VARIABLES();
	static void *previousLastBitsIndex=null;
    
    NSRect r = self.frame;
    
    if (!NSEqualRects(lastFrameSize,r)) {
        //NSLog(@"old %f %f %f %f new %f %f %f %f",lastFrameSize.origin.x,lastFrameSize.origin.y,lastFrameSize.size.width,lastFrameSize.size.height,self.frame.origin.x,r.origin.y,r.size.width,r.size.height);
        lastFrameSize = r;
        glPixelStorei( GL_UNPACK_ROW_LENGTH, r.size.width );
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        [[self openGLContext] update];
    }

    if (!(previousLastBitsIndex == lastBitsIndex)) {
        //NSLog(@"previousLastBitsIndex %#010x changed to %#010x",previousLastBitsIndex,lastBitsIndex);
		previousLastBitsIndex = lastBitsIndex;
		glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_ARB, r.size.width*r.size.height*4,lastBitsIndex);		
	}
		
	glViewport( subRect.origin.x,subRect.origin.y, subRect.size.width,subRect.size.height );
	char *subimg = ((char*)lastBitsIndex) + (unsigned int)(subRect.origin.x + (r.size.height-subRect.origin.y-subRect.size.height)*r.size.width)*4;
	glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, subRect.size.width, subRect.size.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, subimg );
		//NSLog(@" glTexImage2D %f %f %f %f",subRect.origin.x,subRect.origin.y,subRect.size.width,subRect.size.height);
}

-(void)defineQuad:(NSRect)r
{

//	CGL_MACRO_DECLARE_VARIABLES();
	 glBegin(GL_QUADS);
	 glTexCoord2f(0.0f, 0.0f);					glVertex2f(-1.0f, 1.0f);
	 glTexCoord2f(0.0f, r.size.height);			glVertex2f(-1.0f, -1.0f);
	 glTexCoord2f(r.size.width, r.size.height);  glVertex2f(1.0f, -1.0f);
	 glTexCoord2f(r.size.width, 0.0f);			glVertex2f(1.0f, 1.0f);
	 glEnd();
}

- (void) setupFullScreendispBitsIndex {
    sqInt formObj = interpreterProxy->displayObject();
    sqInt formPtrOop = interpreterProxy->fetchPointerofObject(0, formObj);
    self.fullScreendispBitsIndex = interpreterProxy->firstIndexableField(formPtrOop);
}

-(void)drawRect:(NSRect)rect
{
    if (self.fullScreenInProgress) {
        sqInt formObj = interpreterProxy->displayObject();
        sqInt formPtrOop = interpreterProxy->fetchPointerofObject(0, formObj);
        void* dispBitsIndex = interpreterProxy->firstIndexableField(formPtrOop);
        if (self.fullScreendispBitsIndex == dispBitsIndex) {
            [self clearScreen];
            //NSLog(@"drawRect but fullScreenInProgress %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
            return;
        }
        self.fullScreenInProgress = NO;
    }
    
	//NSLog(@" draw %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
	NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];
	
    [self setupFullScreendispBitsIndex];
    
    if ( fullScreendispBitsIndex ) {
		[[self openGLContext] makeCurrentContext];
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            [self setupOpenGL];
        });
		[self loadTexturesFrom:fullScreendispBitsIndex subRectangle: rect];
		[self defineQuad:rect];
    }
    
    if (oldContext != nil) {
        [oldContext makeCurrentContext];
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
	
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	
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
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
	[(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordCharEvent: aString fromView: self];
}

- (void)flagsChanged:(NSEvent *)theEvent {
	keyBoardStrokeDetails *aKeyBoardStrokeDetails = AUTORELEASEOBJ([[keyBoardStrokeDetails alloc] init]);
	aKeyBoardStrokeDetails.keyCode = [theEvent keyCode];
	aKeyBoardStrokeDetails.modifierFlags = [theEvent modifierFlags];
	self.lastSeenKeyBoardModifierDetails = aKeyBoardStrokeDetails;
#if PharoVM
    [(sqSqueakOSXApplication *) gDelegateApp.squeakApplication recordKeyDownEvent: theEvent fromView: self];
#endif
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
//    NSLog(@"draggingEntered %@",info);

	if (self.dragInProgress) 
		return NSDragOperationNone;
	dragInProgress = YES;
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
	self.dragItems = NULL;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info {
//    NSLog(@"performDragOperation %@",info);
	if (self.dragCount) {
		self.dragItems = [self filterOutSqueakImageFilesFromDraggedFiles: info];
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

- (NSString*) dragFileNameStringAtIndex: (sqInt) index {
	if (!self.dragItems) 
		return NULL;
	if (index < 1 || index > [self.dragItems count])
		return NULL;
	NSString *filePath = (self.dragItems)[(NSUInteger) index - 1];
	return filePath;
}


- (BOOL)ignoreModifierKeysWhileDragging {
	return YES;
}

- (void) clearScreen {
    NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];
    [self.openGLContext makeCurrentContext];
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glFlush();
    if (oldContext != nil) {
        [oldContext makeCurrentContext];
    }

}

- (void)  ioSetFullScreen: (sqInt) fullScreen {
	
	if ([self isInFullScreenMode] == YES && (fullScreen == 1)) 
		return;
	if ([self isInFullScreenMode] == NO && (fullScreen == 0))
		return;
	
	if ([self isInFullScreenMode] == NO && (fullScreen == 1)) {
       self.fullScreenInProgress = YES;
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:
				NSApplicationPresentationHideDock |
				NSApplicationPresentationHideMenuBar ],
			NSFullScreenModeApplicationPresentationOptions, nil];
		[self enterFullScreenMode:[NSScreen mainScreen] withOptions:options];
	}
	
	if ([self isInFullScreenMode] == YES && (fullScreen == 0)) {
        self.fullScreenInProgress = YES;
		[self exitFullScreenModeWithOptions: NULL];
		if ([self.window isKeyWindow] == NO) {
			[self.window makeKeyAndOrderFront: self];
		}
	}
}

- (void) preDrawThelayers {
}


@end
