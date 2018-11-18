/**
 * Author: Ronie Salgado <roniesalg@gmail.com>
 * License: MIT
 */
 
#import <Metal/Metal.h>
#include "B3DAcceleratorPlugin.h"
#include "sqMetalStructures.h"
 
#define MAX_NUMBER_OF_RENDERERS 16

@interface sqB3DMetalRenderBuffer : NSObject {
    int width, height;
    id<MTLTexture> colorBuffer;
    id<MTLTexture> depthStencilBuffer;
}

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, strong) id<MTLTexture> colorBuffer;
@property (nonatomic, strong) id<MTLTexture> depthStencilBuffer;

+ (sqB3DMetalRenderBuffer*) createFor: (id<MTLDevice>)device width: (int)width height: (int) height flags: (int)flags;
@end

/**
  * B3D Metal renderer
 */
@interface sqB3DMetalRenderer : NSObject {
    id<MTLDevice> device;
    int windowSurfaceLayerHandle;
    
    int surfaceX, surfaceY;
    int surfaceWidth, surfaceHeight;
    int surfaceFlags;
    
    sqB3DMetalRenderBuffer *renderBuffers[2];
    int currentRenderBufferIndex;
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
