/**
 * Author: Ronie Salgado <roniesalg@gmail.com>
 * License: MIT
 */
 
#import <Metal/Metal.h>
#include "B3DAcceleratorPlugin.h"
#include "sqMetalStructures.h"
 
#define MAX_NUMBER_OF_RENDERERS 16
#define MAX_NUMBER_OF_TEXTURES 2048

@interface sqB3DMetalRenderBuffer : NSObject {
    int width, height;
    int flags;
    id<MTLTexture> colorBuffer;
    id<MTLTexture> depthStencilBuffer;
}

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int flags;
@property (nonatomic, strong) id<MTLTexture> colorBuffer;
@property (nonatomic, strong) id<MTLTexture> depthStencilBuffer;

+ (sqB3DMetalRenderBuffer*) createFor: (id<MTLDevice>)device width: (int)width height: (int) height flags: (int)flags;
@end

/**
 * B3D Metal texture handle implementation.
 */
@interface sqB3DMetalTexture : NSObject {
    int width, height, depth;
    id<MTLTexture> handle;
}

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int depth;
@property (nonatomic, strong) id<MTLTexture> handle;

@end

/**
 * B3D Metal renderer
 */
@interface sqB3DMetalRenderer : NSObject {
    id<MTLDevice> device;
    int windowSurfaceLayerHandle;
    
    // Surface
    int surfaceX, surfaceY;
    int surfaceWidth, surfaceHeight;
    int surfaceFlags;
    
    // Render buffers
    sqB3DMetalRenderBuffer *renderBuffers[2];
    int currentRenderBufferIndex;
    
    // Textures
    sqB3DMetalTexture *textures[MAX_NUMBER_OF_TEXTURES];

    // Viewport
    MTLViewport viewport;    
    
    // Rendering commands
    id<MTLCommandQueue> commandQueue;
    id<MTLCommandBuffer> activeCommandBuffer;
    id<MTLRenderCommandEncoder> activeRenderEncoder;

    // Render buffer clearing.
    BOOL shouldClearDepthStencil;
    BOOL shouldClearColorBuffer;
    MTLClearColor currentClearColor;
    
    B3DMetalLightingState lightingState;
    BOOL hasValidLightingState;
    
    B3DMetalMaterialState materialState;
    BOOL hasValidMaterialState;

    B3DMetalTransformationState transformationState;
    BOOL hasValidTransformationState;
    
    // Some pipeline states.
    id<MTLRenderPipelineState> solidColorPipeline;
    id<MTLRenderPipelineState> texturedPipeline;
    id<MTLDepthStencilState> defaultDepthStencilState;
}

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, assign) int surfaceX;
@property (nonatomic, assign) int surfaceY;
@property (nonatomic, assign) int surfaceWidth;
@property (nonatomic, assign) int surfaceHeight;

- (BOOL) setupSurfaceX: (int)x y: (int)y w: (int)w h: (int)h flags: (int)flags;
- (void) destroy;

- (BOOL) viewportX: (int)x y: (int)y width: (int)width height: (int)height;
- (BOOL) clearDepthBuffer;
- (BOOL) clearViewportWithRGBA: (unsigned int) rgba;
- (BOOL) setModelView: (float*)newModelView projection: (float*)newProjection;
- (BOOL) disableLights;
- (BOOL) loadMaterial: (B3DPrimitiveMaterial*) material;
- (BOOL) loadLight: (B3DPrimitiveLight*) light index: (int)index;
- (BOOL) renderPrimitive: (int)primType flags: (int)flags texHandle: (int)textureHandle
    vertexArray: (float*)vertexArray vertexCount: (int) vertexCount
    indexArray: (int*)indexArray indexCount: (int)indexCount;
- (BOOL) flush;
- (BOOL) finish;
- (BOOL) swapBuffers;
@end

/**
 * Common module level data.
 */ 
@interface sqB3DMetalModule : NSObject {
    id<MTLDevice> device;
    id<MTLLibrary> shaderLibrary;
    sqB3DMetalRenderer *renderers[MAX_NUMBER_OF_RENDERERS];
}

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> shaderLibrary;

+ (sqB3DMetalRenderer*)getRendererFromHandle: (int)handle;
- (sqB3DMetalRenderer*)getRendererFromHandle: (int)handle;
- (int) createRendererX: (int)x y: (int)y w: (int)w h: (int)h flags: (int)flags;
- (int) destroyRendererWithHandle: (int)handle;
@end
