/* Header file for 3D accelerator plugin */

/* Vertex buffer flags */
#define B3D_VB_TRACK_AMBIENT 1
#define B3D_VB_TRACK_DIFFUSE 2
#define B3D_VB_TRACK_SPECULAR 4
#define B3D_VB_TRACK_EMISSION 8

#define B3D_VB_HAS_NORMALS 16
#define B3D_VB_HAS_TEXTURES 32

#define B3D_VB_TWO_SIDED 64
#define B3D_VB_LOCAL_VIEWER 128

typedef struct B3DPrimitiveVertex {
	float position[3];
	float normal[3];
	float texCoord[2];
	float rasterPos[4];
	int pixelValue32;
	int clipFlags;
	int windowPos[2];
} B3DPrimitiveVertex;

typedef struct B3DPrimitiveMaterial {
	float ambient[4];
	float diffuse[4];
	float specular[4];
	float emission[4];
	float shininess;
} B3DPrimitiveMaterial;

/* Light type flags */
#define B3D_LIGHT_POSITIONAL 0x0001
#define B3D_LIGHT_DIRECTIONAL 0x0002
#define B3D_LIGHT_ATTENUATED 0x0004
#define B3D_LIGHT_HAS_SPOT 0x0008

/* Light color flags */
#define B3D_LIGHT_AMBIENT 0x0100
#define B3D_LIGHT_DIFFUSE 0x0200
#define B3D_LIGHT_SPECULAR 0x0400

typedef struct B3DPrimitiveLight {
	float ambient[4];
	float diffuse[4];
	float specular[4];

	float position[3];
	float direction[3];
	float attenuation[3];
	int flags;

	float spotMinCos;
	float spotMaxCos;
	float spotDeltaCos;
	float spotExponent;
} B3DPrimitiveLight;

/* Win32 defaults to D3D everyone else to OpenGL */
#if defined(WIN32) && !defined(WIN32_NO_D3D)
#define B3DX_D3D
#else
#define B3DX_GL
#endif

#if defined(B3DX_GL)
#define b3dxInitialize            glInitialize
#define b3dxShutdown              glShutdown

#define b3dxAllocateTexture       glAllocateTexture
#define b3dxDestroyTexture        glDestroyTexture
#define b3dxActualTextureDepth    glActualTextureDepth
#define b3dxTextureColorMasks     glTextureColorMasks
#define b3dxUploadTexture         glUploadTexture
#define b3dxTextureByteSex        glTextureByteSex
#define b3dxTextureSurfaceHandle glTextureSurfaceHandle
#define b3dxCompositeTexture      glCompositeTexture

#define b3dxCreateRenderer        glCreateRenderer
#define b3dxDestroyRenderer        glDestroyRenderer
#define b3dxIsOverlayRenderer     glIsOverlayRenderer
#define b3dxGetRendererSurfaceHandle glGetRendererSurfaceHandle
#define b3dxGetRendererSurfaceWidth glGetRendererSurfaceWidth
#define b3dxGetRendererSurfaceHeight glGetRendererSurfaceHeight
#define b3dxGetRendererSurfaceDepth glGetRendererSurfaceDepth
#define b3dxGetRendererColorMasks glGetRendererColorMasks
#define b3dxSetBufferRect           glSetBufferRect

#define b3dxSetViewport           glSetViewport
#define b3dxClearDepthBuffer      glClearDepthBuffer
#define b3dxClearViewport          glClearViewport
#define b3dxRenderVertexBuffer   glRenderVertexBuffer
#define b3dxSetTransform          glSetTransform
#define b3dxDisableLights          glDisableLights
#define b3dxLoadLight             glLoadLight
#define b3dxLoadMaterial          glLoadMaterial
#define b3dxFlushRenderer        glFlushRenderer
#define b3dxFinishRenderer       glFinishRenderer
#define b3dxSwapRendererBuffers glSwapRendererBuffers
#define b3dxGetIntProperty       glGetIntProperty
#define b3dxSetIntProperty       glSetIntProperty
#define b3dxSetVerboseLevel     glSetVerboseLevel
#define b3dxSetFog               glSetFog
#endif

#if defined(B3DX_D3D)
#define b3dxInitialize            d3dInitialize
#define b3dxShutdown              d3dShutdown

#define b3dxAllocateTexture       d3dAllocateTexture
#define b3dxDestroyTexture        d3dDestroyTexture
#define b3dxActualTextureDepth    d3dActualTextureDepth
#define b3dxTextureColorMasks     d3dTextureColorMasks
#define b3dxUploadTexture         d3dUploadTexture
#define b3dxTextureByteSex        d3dTextureByteSex
#define b3dxTextureSurfaceHandle d3dTextureSurfaceHandle
#define b3dxCompositeTexture      d3dCompositeTexture

#define b3dxCreateRenderer        d3dCreateRenderer
#define b3dxDestroyRenderer        d3dDestroyRenderer
#define b3dxGetRendererSurfaceHandle d3dGetRendererSurfaceHandle
#define b3dxGetRendererSurfaceWidth d3dGetRendererSurfaceWidth
#define b3dxGetRendererSurfaceHeight d3dGetRendererSurfaceHeight
#define b3dxGetRendererSurfaceDepth d3dGetRendererSurfaceDepth
#define b3dxGetRendererColorMasks d3dGetRendererColorMasks
#define b3dxIsOverlayRenderer    d3dIsOverlayRenderer
#define b3dxSetBufferRect           d3dSetBufferRect

#define b3dxSetViewport           d3dSetViewport
#define b3dxClearDepthBuffer      d3dClearDepthBuffer
#define b3dxClearViewport          d3dClearViewport
#define b3dxRenderVertexBuffer   d3dRenderVertexBuffer
#define b3dxSetTransform          d3dSetTransform
#define b3dxDisableLights          d3dDisableLights
#define b3dxLoadLight             d3dLoadLight
#define b3dxLoadMaterial          d3dLoadMaterial
#define b3dxFlushRenderer        d3dFlushRenderer
#define b3dxFinishRenderer       d3dFinishRenderer
#define b3dxSwapRendererBuffers d3dSwapRendererBuffers
#define b3dxGetIntProperty       d3dGetIntProperty
#define b3dxSetIntProperty       d3dSetIntProperty
#define b3dxSetVerboseLevel     d3dSetVerboseLevel
#define b3dxSetFog               d3dSetFog
#endif

/* module initialization support */
int b3dxInitialize(void); /* return true on success, false on error */
int b3dxShutdown(void); /* return true on success, false on error */

/* Texture support primitives */
int b3dxAllocateTexture(int renderer, int w, int h, int d); /* return handle or -1 on error */
int b3dxDestroyTexture(int renderer, int handle); /* return true on success, false on error */
int b3dxActualTextureDepth(int renderer, int handle); /* return depth or <0 on error */
int b3dxTextureColorMasks(int renderer, int handle, int masks[4]);  /* return true on success, false on error */
int b3dxUploadTexture(int renderer, int handle, int w, int h, int d, void* bits); /* return true on success, false on error */
int b3dxTextureByteSex(int renderer, int handle); /* return > 0 for MSB, = 0 for LSB, < 0 for error */
int b3dxTextureSurfaceHandle(int renderer, int handle); /* return handle or <0 if error */
int b3dxCompositeTexture(int renderer, int handle, int x, int y, int w, int h, int translucent); /* return true on success; else false */

/* Renderer primitives */
int b3dxCreateRenderer(int allowSoftware, int allowHardware, int x, int y, int w, int h); /* return handle or -1 on error */
int b3dxDestroyRenderer(int handle); /* return true on success, else false */
int b3dxIsOverlayRenderer(int handle); /* return true/false */
int b3dxSetBufferRect(int handle, int x, int y, int w, int h); /* return true on success, false on error */
int b3dxGetRendererSurfaceHandle(int handle); /* return handle or <0 if error */
int b3dxGetRendererSurfaceWidth(int handle); /* return width or <0 if error */
int b3dxGetRendererSurfaceHeight(int handle); /* return height or <0 if error */
int b3dxGetRendererSurfaceDepth(int handle); /* return depth or <0 if error */
int b3dxGetRendererColorMasks(int handle, int *masks); /* return true on success, false on error */

int b3dxSetViewport(int handle, int x, int y, int w, int h); /* return true on success, false on error */
int b3dxClearDepthBuffer(int handle); /* return true on success, false on error */
int b3dxClearViewport(int handle, unsigned int rgba, unsigned int pv); /* return true on success, else false */
int b3dxSetTransform(int handle, float *modelView, float *projection);
int b3dxDisableLights(int handle);
int b3dxLoadLight(int handle, int index, B3DPrimitiveLight *light);
int b3dxLoadMaterial(int handle, B3DPrimitiveMaterial *material);
int b3dxRenderVertexBuffer(int handle, int primType, int flags, int texHandle, float *vtxArray, int vtxSize, int *idxArray, int idxSize); /* return true on success, false on error */
int b3dxFlushRenderer(int handle);
int b3dxFinishRenderer(int handle);
int b3dxSwapRendererBuffers(int handle);
int b3dxGetIntProperty(int handle, int prop);
int b3dxSetIntProperty(int handle, int prop, int value);
int b3dxSetVerboseLevel(int level);
int b3dxSetFog(int handle, int fogType, double density, double rangeStart, double rangeEnd, int rgba);

