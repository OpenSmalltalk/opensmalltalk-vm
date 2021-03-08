//
//  sqSqueakOSXOpenMetalView.m
//  SqueakPureObjc
//
//  Created by Ronie Salgado on 10-11-18.
//  Event code taken from sqSqueakOSXOpenGLView.m
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

#ifdef USE_METAL
#import <QuartzCore/QuartzCore.h>

#import "sqSqueakOSXMetalView.h"
#import "sqSqueakOSXScreenAndWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqSqueakOSXApplication+events.h"
#import "sqSqueakOSXInfoPlistInterface.h"
#import "sq.h"
#import "sqVirtualMachine.h"

extern SqueakOSXAppDelegate *gDelegateApp;
extern struct VirtualMachine* interpreterProxy;

static sqSqueakOSXMetalView *mainMetalView;

#define STRINGIFY_SHADER(src) #src
static const char *squeakMainShadersSrc =
#include "SqueakMainShaders.metal"
;

typedef struct
{
	float x, y, z, w, s, t;
} ScreenQuadVertex;

static ScreenQuadVertex screenQuadVertices[] = {
	{-1.0f, -1.0f, 0.0f, 1.0f, 0.0f, 0.0f},
	{ 1.0f, -1.0f, 0.0f, 1.0f, 1.0f, 0.0f},
	{-1.0f,  1.0f, 0.0f, 1.0f, 0.0f, 1.0f},
	{ 1.0f,  1.0f, 0.0f, 1.0f, 1.0f, 1.0f},
};

#define MAX_NUMBER_OF_EXTRA_LAYERS 16

typedef struct LayerTransformation
{
    float scaleX, scaleY;
    float translationX, translationY;
} LayerTransformation;

@interface sqSqueakOSXMetalViewExtraDrawingLayer : NSObject {
	id<MTLTexture> texture;
	int x, y;
	int w, h;	
}

@property (nonatomic,assign) int x;
@property (nonatomic,assign) int y;
@property (nonatomic,assign) int w;
@property (nonatomic,assign) int h;
@property (nonatomic,strong) id<MTLTexture> texture;
@end

@implementation sqSqueakOSXMetalViewExtraDrawingLayer
@synthesize x, y, w, h, texture;
@end

static NSString *stringWithCharacter(unichar character) {
	return [NSString stringWithCharacters: &character length: 1];
}

@interface sqSqueakOSXMetalView ()
@property (nonatomic,assign) CGSize lastFrameSize;
@property (nonatomic,assign) BOOL fullScreenInProgress;
@property (nonatomic,assign) void* fullScreendispBitsIndex;
@property (nonatomic,strong) id<MTLCommandQueue> graphicsCommandQueue;
@end

@implementation sqSqueakOSXMetalView
@synthesize squeakTrackingRectForCursor,lastSeenKeyBoardStrokeDetails,
lastSeenKeyBoardModifierDetails,dragInProgress,dragCount,windowLogic,lastFrameSize,fullScreenInProgress,fullScreendispBitsIndex,graphicsCommandQueue;

+ (BOOL) isMetalViewSupported {
	// Try to create the MTL system device.
	id<MTLDevice> device = MTLCreateSystemDefaultDevice();
	if(!device)
		return NO;
		
	// Try to compile the shader library.
	id<MTLLibrary> library = [self compileShaderLibraryForDevice: device];
	if(!library)
		return NO;

	RELEASEOBJ(library);
	RELEASEOBJ(device);
	return YES;
}

#pragma mark Initialization / Release

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];

    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setAutoresizesSubviews:YES];

    [self initialize];

    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
    [self initialize];
}

- (void)initialize {
	mainMetalView = self;
	
	self.paused = YES;
	self.enableSetNeedsDisplay = NO;
	
	NSMutableArray *drawingLayers = [NSMutableArray arrayWithCapacity: MAX_NUMBER_OF_EXTRA_LAYERS];
	for(int i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS; ++i) {
		[drawingLayers addObject: [sqSqueakOSXMetalViewExtraDrawingLayer new]];
	}
	extraDrawingLayers = drawingLayers;

	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	metalInitialized = NO;
	displayTexture = nil;
	displayTextureWidth = 0;
	displayTextureHeight = 0;
	
	dragInProgress = NO;
	dragCount = 0;
	clippyIsEmpty = YES;
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

#pragma mark Drawing

- (void) setupFullScreendispBitsIndex {
    self.fullScreendispBitsIndex = displayBits;
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
		[self draw];
	}
	
	if (!firstDrawCompleted) {
		firstDrawCompleted = YES;
		extern sqInt getFullScreenFlag(void);
		if (getFullScreenFlag() == 0) {
			[self.window makeKeyAndOrderFront: self];
        }
	}
}

-(void)setupMetal
{
	if(metalInitialized)
		return;
	metalInitialized = YES;
	if(self.device == nil)
		self.device = MTLCreateSystemDefaultDevice();
		
	[self buildPipelines];
	[self createScreenQuad];

	// Create the command queue.
	graphicsCommandQueue = [self.device newCommandQueue];
}

+ (id<MTLLibrary>) compileShaderLibraryForDevice: (id<MTLDevice>) device {
	NSString *shaderSource = [NSString stringWithCString: squeakMainShadersSrc encoding: NSUTF8StringEncoding];
	MTLCompileOptions* compileOptions = [ MTLCompileOptions new ];
	NSError *libraryError = nil;
	id<MTLLibrary> shaderLibrary = [device newLibraryWithSource: shaderSource options: compileOptions error: &libraryError];
	RELEASEOBJ(shaderSource);
	RELEASEOBJ(compileOptions);
	if(!shaderLibrary)
		NSLog(@"Shader library error: %@", libraryError.localizedDescription);

	return shaderLibrary;
}

- (void) buildPipelines {
	id<MTLLibrary> shaderLibrary = [[self class] compileShaderLibraryForDevice: self.device ];
	screenQuadPipelineState = [self buildPipelineWithLibrary: shaderLibrary vertexFunction: @"screenQuadFlipVertexShader" fragmentFunction: @"screenQuadFragmentShader" translucent: NO];
	layerScreenQuadPipelineState = [self buildPipelineWithLibrary: shaderLibrary vertexFunction: @"layerScreenQuadVertexShader" fragmentFunction: @"screenQuadFragmentShader" translucent: NO];
	RELEASEOBJ(shaderLibrary);
}

- (id<MTLRenderPipelineState>) buildPipelineWithLibrary: (id<MTLLibrary>)shaderLibrary vertexFunction: (NSString*)vertexFunctionName fragmentFunction: (NSString*)fragmentFunctionName translucent: (BOOL)translucent{
	// Retrieve the shaders from the shader libary.
	id<MTLFunction> vertexShader = [shaderLibrary newFunctionWithName: vertexFunctionName];
	id<MTLFunction> fragmentShader = [shaderLibrary newFunctionWithName: fragmentFunctionName];
	if(!vertexShader || !fragmentShader)
	{
		RELEASEOBJ(shaderLibrary);
		return nil;
	}

	// Create the screen quad pipeline.
	MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
	pipelineDescriptor.vertexFunction = vertexShader;
	pipelineDescriptor.fragmentFunction = fragmentShader;
	pipelineDescriptor.inputPrimitiveTopology = MTLPrimitiveTopologyClassTriangle;
	MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor = pipelineDescriptor.colorAttachments[0];
	attachmentDescriptor.pixelFormat = self.colorPixelFormat;
	if(translucent) {
		attachmentDescriptor.blendingEnabled = YES;
		attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
		attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
		attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
		attachmentDescriptor.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	}
	
	NSError *pipelineError = NULL;
	id<MTLRenderPipelineState> pipeline = [self.device newRenderPipelineStateWithDescriptor: pipelineDescriptor error: &pipelineError];
	RELEASEOBJ(shaderLibrary);
	RELEASEOBJ(vertexShader);
	RELEASEOBJ(fragmentShader);
	if(!pipeline)
	{
		NSLog(@"Pipeline state creation error: %@", pipelineError.localizedDescription);
		return nil;
	}
	
	return pipeline;
}

- (void) createScreenQuad {
	screenQuadVertexBuffer = [self.device
		newBufferWithBytes: screenQuadVertices
		length: sizeof(screenQuadVertices)
		options: MTLResourceStorageModeManaged];
}

-(void)drawRect:(NSRect)rect
{
	[self setupMetal];
    [self setupFullScreendispBitsIndex];

	// Always try to fill the texture with the pixels.
	if ( fullScreendispBitsIndex ) {
		[self loadTexturesFrom: fullScreendispBitsIndex subRectangle: (clippyIsEmpty ? rect : NSRectFromCGRect(clippy))];
		//[self loadTexturesFrom: fullScreendispBitsIndex subRectangle: rect];
		clippyIsEmpty = YES;
	    syncNeeded = NO;
	}
	
	MTLRenderPassDescriptor *renderPassDescriptor = self.currentRenderPassDescriptor;
	if(renderPassDescriptor != nil && self.currentDrawable)
	{
		currentCommandBuffer = [graphicsCommandQueue commandBuffer];
		currentRenderEncoder = [currentCommandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
		
		// Set the viewport.
		CGSize drawableSize = self.drawableSize;
		[currentRenderEncoder setViewport: (MTLViewport){0.0, 0.0, drawableSize.width, drawableSize.height}];

		// Draw the screen rectangle.
		[self drawScreenRect: rect];
		
		unsigned int drawnExtraDrawingLayerMask = 0;
		for(unsigned int i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS && drawnExtraDrawingLayerMask != allocatedExtraDrawingLayers; ++i) {
			if(allocatedExtraDrawingLayers & (1 << i)) {
				[self drawExtraDrawingLayer: i];
				drawnExtraDrawingLayerMask |= 1 << i;
			}
		}
		
		[currentRenderEncoder endEncoding];
		[currentCommandBuffer presentDrawable: self.currentDrawable];
		[currentCommandBuffer commit];
		
		currentCommandBuffer = nil;
		currentRenderEncoder = nil;
	}
}

- (CGSize) screenSizeForTexture {
	CGRect screenRect = [self bounds];
	CGSize screenSize;
	screenSize.width = (sqInt)screenRect.size.width;
	screenSize.height = (sqInt)screenRect.size.height;
	return screenSize;
}
 
- (void)loadTexturesFrom: (void*) displayStorage subRectangle: (NSRect) subRect {
	CGSize drawableSize = [self screenSizeForTexture];
    if (!CGSizeEqualToSize(lastFrameSize,drawableSize) || !displayTexture ||
		currentDisplayStorage != displayStorage) {
		//NSLog(@"old %f %f %f %f new %f %f %f %f",lastFrameSize.origin.x,lastFrameSize.origin.y,lastFrameSize.size.width,lastFrameSize.size.height,self.frame.origin.x,r.origin.y,r.size.width,r.size.height);
        lastFrameSize = drawableSize;
		currentDisplayStorage = displayStorage;
		[self updateDisplayTextureStorage];
    }
	
	// Clip the subrect against the texture bounds, to avoid an edge condition
	// that ends crashing the VM.
	subRect = NSIntersectionRect(subRect, NSMakeRect(0, 0, displayTextureWidth, displayTextureHeight));
	if(NSIsEmptyRect(subRect))
	{
		// Discard the update of empty texture regions.
		return;
	}
	
	MTLRegion region = MTLRegionMake2D(subRect.origin.x, displayTextureHeight - subRect.origin.y - subRect.size.height, subRect.size.width, subRect.size.height);
	
	unsigned int sourcePitch = displayTextureWidth*4;

	//char *source = ((char*)displayStorage) + (unsigned int)(subRect.origin.x + subRect.origin.y*displayTextureWidth)*4;
	char *source = ((char*)displayStorage) + (unsigned int)(subRect.origin.x + (displayTextureHeight-subRect.origin.y-subRect.size.height)*displayTextureWidth)*4;
	[displayTexture replaceRegion: region mipmapLevel: 0 withBytes: source bytesPerRow: sourcePitch];
}

-(void) updateDisplayTextureStorage {
	CGSize drawableSize = [self screenSizeForTexture];
	displayTextureWidth = drawableSize.width;
	displayTextureHeight = drawableSize.height;
	displayTexturePitch = displayTextureWidth*4;

	if(displayTexture)
	{
		RELEASEOBJ(displayTexture);
		displayTexture = nil;
	}
	
	MTLTextureDescriptor *descriptor = [MTLTextureDescriptor
		texture2DDescriptorWithPixelFormat: MTLPixelFormatBGRA8Unorm
		width: displayTextureWidth
		height: displayTextureHeight
		mipmapped: NO];
	displayTexture = [self.device newTextureWithDescriptor: descriptor];
}

-(void)drawScreenRect:(NSRect)rect {
	if(displayTexture == nil || screenQuadPipelineState == nil || screenQuadVertexBuffer == nil)
		return;
	
	[currentRenderEncoder setRenderPipelineState: screenQuadPipelineState];
	
	[currentRenderEncoder setVertexBuffer: screenQuadVertexBuffer offset: 0 atIndex: 0];
	[currentRenderEncoder setFragmentTexture: displayTexture atIndex: 0];
	
	// Draw the the 4 vertices of the of the screen quad.
	[currentRenderEncoder drawPrimitives: MTLPrimitiveTypeTriangleStrip
		vertexStart: 0
		vertexCount: 4];
}

- (void) drawExtraDrawingLayer: (unsigned int) extraDrawingLayerIndex {
	sqSqueakOSXMetalViewExtraDrawingLayer *layer = extraDrawingLayers[extraDrawingLayerIndex];
	if(!layer.texture)
		return;
		
	if(layerScreenQuadPipelineState == nil || screenQuadVertexBuffer == nil)
		return;
	
	[currentRenderEncoder setRenderPipelineState: layerScreenQuadPipelineState];
	
	NSRect screenRect = self.frame;
	LayerTransformation transformation;
	transformation.scaleX = (float)layer.w / screenRect.size.width;
	transformation.scaleY = (float)layer.h / screenRect.size.height;
	transformation.translationX = (2.0f*layer.x + layer.w) / screenRect.size.width - 1.0f;
	transformation.translationY = 1.0f - (2.0f*layer.y + layer.h) / screenRect.size.height;

	[currentRenderEncoder setVertexBuffer: screenQuadVertexBuffer offset: 0 atIndex: 0];
	[currentRenderEncoder setVertexBytes: &transformation length: sizeof(transformation) atIndex: 1];
	[currentRenderEncoder setFragmentTexture: layer.texture atIndex: 0];
	
	// Draw the the 4 vertices of the of the screen quad.
	[currentRenderEncoder drawPrimitives: MTLPrimitiveTypeTriangleStrip
		vertexStart: 0
		vertexCount: 4];
}

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
	return stringWithCharacter(keyChar);
}


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
    BOOL isUp = (oldFlags & NSDeviceIndependentModifierFlagsMask)
                > ([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

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

- (void)doCommandBySelector:(SEL)aSelector {
	unichar unicode;
	unsigned short keyCode;
	NSString *unicodeString;
	BOOL isFunctionKey = NO;

	if (self.lastSeenKeyBoardModifierDetails) {
		isFunctionKey = (self.lastSeenKeyBoardModifierDetails.modifierFlags & NSEventModifierFlagFunction) == NSEventModifierFlagFunction;
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

- (NSMutableArray *) filterOutSqueakImageFilesFromDraggedURIs: (id<NSDraggingInfo>)info {
	NSPasteboard *pboard= [info draggingPasteboard];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity: 10];
	if ([[pboard types] containsObject: NSFilenamesPboardType]) {
		NSArray *files= [pboard propertyListForType: NSFilenamesPboardType];
		NSString *fileName;
		for (fileName in files) {
			if ([((sqSqueakOSXApplication*) gDelegateApp.squeakApplication) isImageFile: fileName] == NO)
			{
				[results addObject: [NSURL fileURLWithPath: fileName]];
			}
		}
	}

	return results;
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
		gDelegateApp.dragItems = [self filterOutSqueakImageFilesFromDraggedURIs: info];
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

#pragma mark Fullscreen

- (void) ioSetFullScreen: (sqInt) fullScreen {
	if ((self.window.styleMask & NSFullScreenWindowMask) != (fullScreen == 1)) {
		self.fullScreenInProgress = YES;
        [self.window toggleFullScreen: nil];
	}
}

- (void) preDrawThelayers {
}

- (unsigned int) createTextureLayerHandle {
	unsigned int i;
	unsigned int bit;
	for(i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS; ++i) {
		bit = 1<<i;
		if(!(allocatedExtraDrawingLayers & bit)) {
			allocatedExtraDrawingLayers |= bit;
			return i + 1;
		}
	}
	return 0;
}

- (void) destroyTextureLayerHandle: (unsigned int) handle {
	unsigned int bit = 1 << (handle - 1);
	if(allocatedExtraDrawingLayers & bit) {
		sqSqueakOSXMetalViewExtraDrawingLayer *layer = extraDrawingLayers[handle - 1];
		if(layer.texture) {
			RELEASEOBJ(layer.texture);
			layer.texture = nil;
		}
		
		allocatedExtraDrawingLayers &= ~bit;
		
		// Redraw the screen.
		[self draw];
	}	
}

- (void) setExtraLayer: (unsigned int) handle texture: (id<MTLTexture>) texture x: (int) x y: (int) y w: (int) w h: (int) h {
	unsigned int bit = 1 << (handle - 1);
	if(allocatedExtraDrawingLayers & bit) {
		sqSqueakOSXMetalViewExtraDrawingLayer *layer = extraDrawingLayers[handle - 1];
		RETAINOBJ(texture);
		if(layer.texture)
			RELEASEOBJ(texture);
		layer.texture = texture;
		layer.x = x;
		layer.y = y;
		layer.w = w;
		layer.h = h;
		
		// Swap the buffers
		if(mainMetalView)
			[mainMetalView draw];
	}
}

@end

id<MTLDevice>
getMainWindowMetalDevice(void) {
	return mainMetalView ? mainMetalView.device : nil;
}

id<MTLCommandQueue>
getMainWindowMetalCommandQueue(void) {
	return mainMetalView ? mainMetalView.graphicsCommandQueue : nil;	
}

unsigned int
createMetalTextureLayerHandle(void) {
	return mainMetalView ? [ mainMetalView createTextureLayerHandle ] : 0;
}

void
destroyMetalTextureLayerHandle(unsigned int handle) {
	if(!mainMetalView)
	 	return;

	[ mainMetalView destroyTextureLayerHandle: handle ];
}

void
setMetalTextureLayerContent(unsigned int handle, id<MTLTexture> texture, int x, int y, int w, int h) {
	if(!mainMetalView)
	 	return;
	
	[ mainMetalView setExtraLayer: handle texture: texture x: x y: y w: w h: h];
}

#endif // USE_METAL
