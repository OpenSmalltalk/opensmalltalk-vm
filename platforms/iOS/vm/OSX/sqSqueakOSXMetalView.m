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

extern SqueakOSXAppDelegate *gDelegateApp;

static sqSqueakOSXMetalView *mainMetalView;
extern sqInt cannotDeferDisplayUpdates;

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

@interface sqSqueakOSXMetalView ()
@property (nonatomic,assign) CGSize lastFrameSize;
@property (nonatomic,strong) id<MTLCommandQueue> graphicsCommandQueue;
@end

@implementation sqSqueakOSXMetalView
@synthesize lastFrameSize,graphicsCommandQueue;

#include "SqSqueakOSXView.m.inc"

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
	self.enableSetNeedsDisplay = YES;
	cannotDeferDisplayUpdates = 1;
	
	NSMutableArray *drawingLayers = [NSMutableArray arrayWithCapacity: MAX_NUMBER_OF_EXTRA_LAYERS];
	for(int i = 0; i < MAX_NUMBER_OF_EXTRA_LAYERS; ++i) {
		[drawingLayers addObject: [sqSqueakOSXMetalViewExtraDrawingLayer new]];
	}
	extraDrawingLayers = drawingLayers;

	inputMark = NSMakeRange(NSNotFound, 0);
	inputSelection = NSMakeRange(0, 0);
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil]];
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

    // macOS 10.5 introduced NSTrackingArea for mouse tracking
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect: [self frame]
    	options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect)
    	owner: self userInfo: nil];
    [self addTrackingArea: trackingArea];
}

- (void) didEnterFullScreen: (NSNotification*) aNotification {
    //NSLog(@"Notification didEnterFullScreen");
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


#pragma mark Drawing

- (void) drawImageUsingClip: (CGRect) clip {

	if (clippyIsEmpty){
		clippy = clip;
		clippyIsEmpty = NO;
	} else {
		clippy = CGRectUnion(clippy, clip);
	}

	/* After updating clippy, tell the application to issue a display event.
	 * We do this via setNeedsDisplayInRect: for the entire frame but only
	 * once to avoid unnecessary updates. See initialize() where we pause
	 * the Metal loop and enableSetNeedsDisplay.
	 *
	 * Note that we do not have to communicate clippy in some way because
	 * drawRect: will always be called with the entire frame during event
	 * processing, whether we tell it to do so or not.
	 */
	if(!syncNeeded) {
		syncNeeded = YES;
		[self setNeedsDisplayInRect: [self frame]];
	}
}

- (void) drawThelayers /* via ioForceDisplayUpdate() */{
    extern BOOL gSqueakHeadless;
	if (gSqueakHeadless) {
        firstDrawCompleted = YES;
        return;
    }
	
	/* Documentation only. DO NOT draw here but rely the application's event
	 * loop such as through image-side pumping. See ioProcessEvents().
	 *
	 * Note that we MUST NOT check deferDisplayUpdates because its semantics
	 * expect an extra display buffer which we do not have. We just record
	 * clippy without preserving the particular bits from displayBits. That
	 * is, relying on the application's event loop to "defer" display updates
	 * is not the same. Instead, it is about who manages the extra buffer if
	 * needed.
     */
	// NO: if (syncNeeded) { [self draw]; }
    // NO: if (!deferDisplayUpdates && syncNeeded) { [self draw]; }

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

    /* Only draw if we have valid access to displayBits and if we have
     * something new communicated via clippy. During window resizing, we can
     * just ignore this as the framework will stretch the current contents as
     * preview. We might want to avoid this and show blank contents instead.
     * Just check clippyIsEmpty to decide whether to update rect, typically
     * the full frame, with something else or not.
     */
    if ( !displayBits ) { return; }
    if ( clippyIsEmpty ) { return; }
    
	// Always try to fill the texture with the pixels.
	[self loadTexturesSubRectangle: NSRectFromCGRect(clippy)];
	clippyIsEmpty = YES;
	syncNeeded = NO;
	
	MTLRenderPassDescriptor *renderPassDescriptor = self.currentRenderPassDescriptor;
	if(renderPassDescriptor != nil && self.currentDrawable)
	{
		currentCommandBuffer = [graphicsCommandQueue commandBuffer];
		currentRenderEncoder = [currentCommandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
		
		// Set the viewport.
		[currentRenderEncoder setViewport: (MTLViewport){0.0, 0.0, self.drawableSize.width, self.drawableSize.height}];

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

- (void)loadTexturesSubRectangle: (NSRect) subRect {
	void  *displayStorage = displayBits;
	CGSize drawableSize = CGSizeMake(displayWidth, displayHeight);
    
    if ( !CGSizeEqualToSize(lastFrameSize,drawableSize)
    	|| !displayTexture
    	|| currentDisplayStorage != displayStorage) {
		// NSLog(@"old %f %f new %f %f", lastFrameSize.width,lastFrameSize.height,drawableSize.width,drawableSize.height);
        lastFrameSize = drawableSize;
		currentDisplayStorage = displayStorage;
		[self updateDisplayTextureStorage: drawableSize];
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
	
	unsigned int sourcePitch = displayTextureWidth * 4;

	//char *source = ((char*)displayStorage) + (unsigned int)(subRect.origin.x + subRect.origin.y*displayTextureWidth)*4;
	char *source = ((char*)displayStorage) + (unsigned int)(subRect.origin.x + (displayTextureHeight-subRect.origin.y-subRect.size.height)*displayTextureWidth)*4;
	[displayTexture replaceRegion: region mipmapLevel: 0 withBytes: source bytesPerRow: sourcePitch];
}

-(void) updateDisplayTextureStorage: (CGSize) drawableSize {
	displayTextureWidth = drawableSize.width;
	displayTextureHeight = drawableSize.height;
	displayTexturePitch = displayTextureWidth * 4;

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


#pragma mark Fullscreen

- (void) ioSetFullScreen: (sqInt) fullScreen {
	if ((self.window.styleMask & NSFullScreenWindowMask) != (fullScreen == 1)) {
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
