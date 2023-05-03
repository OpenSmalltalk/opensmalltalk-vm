/* Header file for 3D accelerator plugin */
#ifndef B3D_ACCELERATOR_PLUGIN_H
#define B3D_ACCELERATOR_PLUGIN_H

#ifdef USE_METAL

#else
#  ifdef _WIN32
#   include <Windows.h>
#  endif
#  if defined(BUILD_FOR_OSX) || (MAC_OS_X_VERSION_MAX_ALLOWED >= 1070) || defined(TARGET_API_MAC_CARBON)
#   include <OpenGL/gl.h>
#  else
#   include <GL/gl.h>
#  endif
#endif

/* Primitive types */
#define B3D_PRIMITIVE_TYPE_POINTS 1
#define B3D_PRIMITIVE_TYPE_LINES 2
#define B3D_PRIMITIVE_TYPE_POLYGON 3
#define B3D_PRIMITIVE_TYPE_INDEXED_LINES 4
#define B3D_PRIMITIVE_TYPE_INDEXED_TRIANGLES 5
#define B3D_PRIMITIVE_TYPE_INDEXED_QUADS 6

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

/* Renderer creation flags:
   B3D_SOFTWARE_RENDERER: Enable use of software renderers
   B3D_HARDWARE_RENDERER: Enable use of hardware renderers
   B3D_STENCIL_BUFFER:    Request stencil buffer
   B3D_ANTIALIASING:      Request antialiasing in the renderer.
   B3D_STEREO:            Request stereo visual from the renderer
   B3D_SYNCVBL:           Request VBL sync
   More flags may be added - if they are not supported by the platform
   code the creation primitive should fail.
*/
#define B3D_SOFTWARE_RENDERER 0x0001
#define B3D_HARDWARE_RENDERER 0x0002
#define B3D_STENCIL_BUFFER    0x0004
#define B3D_ANTIALIASING      0x0008
#define B3D_STEREO            0x0010
#define B3D_SYNCVBL           0x0020

/* Win32 defaults to DUAL D3D/GL interface everyone else to OpenGL */
#ifdef USE_METAL
# define B3DX_METAL
#else
# if defined(_WIN32)
#  if defined(_WIN32_PURE_D3D)
#   define B3DX_D3D
#  elif defined(_WIN32_PURE_GL)
#   define B3DX_GL
#  else
#   define B3DX_DUAL
#  endif
# else
#  define B3DX_GL
# endif
#endif

/* b3dxCreateRenderer is now obsolete but older plugin sources may still use it */
#define b3dxCreateRenderer(sw,hw,x,y,w,h) b3dxCreateRendererFlags(x,y,w,h, (sw ? B3D_SOFTWARE_RENDERER : 0) | (hw ? B3D_HARDWARE_RENDERER : 0))


#if defined(B3DX_METAL)
#include "B3DMetal.h"
#include "B3Dx.h"
#endif

#if defined(B3DX_GL)
#include "B3DOpenGL.h"
#include "B3Dx.h"
#endif

#if defined(B3DX_D3D)
#include "B3DDirect3D.h"
#include "B3Dx.h"
#endif

/* module initialization support */
int b3dLoadClientState(int, float *, int, float *, int, float *, int, float *, int);

/* Qwaq primitives */
int b3dDrawArrays(int handle, int mode, int minIdx, int maxIdx);
int b3dDrawElements(int handle, int mode, int nFaces, unsigned int *facePtr);
int b3dDrawRangeElements(int handle, int mode, int minIdx, int maxIdx, int nFaces, unsigned int *facePtr);

#if defined(B3DX_DUAL)

#define B3DX_GL
#include "B3DOpenGL.h"
#include "B3Dx.h"
#include "B3DxUndef.h"

#define B3DX_D3D
#include "B3DDirect3D.h"
#include "B3Dx.h"
#include "B3DxUndef.h"

extern int glMode;

#if 0 /* initializer is special since it decides what to use */
#define b3dxInitialize() \
  (glMode ? glInitialize() : d3dInitialize())
#endif
int b3dxInitialize(void);

#define b3dxShutdown() \
  (glMode ? glShutdown() : d3dShutdown())
#define b3dxAllocateTexture(r,w,h,d) \
  (glMode ? glAllocateTexture(r,w,h,d) : d3dAllocateTexture(r,w,h,d))
#define b3dxDestroyTexture(r,h) \
  (glMode ? glDestroyTexture(r,h) : d3dDestroyTexture(r,h))
#define b3dxActualTextureDepth(r,h) \
  (glMode ? glActualTextureDepth(r,h) : d3dActualTextureDepth(r,h))
#define b3dxTextureColorMasks(r,h,m) \
  (glMode ? glTextureColorMasks(r,h,m) : d3dTextureColorMasks(r,h,m))
#define b3dxUploadTexture(r,hh,w,h,d,b) \
  (glMode ? glUploadTexture(r,hh,w,h,d,b) : d3dUploadTexture(r,hh,w,h,d,b))
#define b3dxTextureByteSex(r,h) \
  (glMode ? glTextureByteSex(r,h) : d3dTextureByteSex(r,h))
#define b3dxTextureSurfaceHandle(r,h) \
  (glMode ? glTextureSurfaceHandle(r,h) : d3dTextureSurfaceHandle(r,h))
#define b3dxCompositeTexture(r,hh,x,y,w,h,t) \
  (glMode ? glCompositeTexture(r,hh,x,y,w,h,t) : d3dCompositeTexture(r,hh,x,y,w,h,t))
#define b3dxCreateRendererFlags(x,y,w,h,f) \
  (glMode ? glCreateRendererFlags(x,y,w,h,f) : d3dCreateRendererFlags(x,y,w,h,f))
#define b3dxDestroyRenderer(h) \
  (glMode ? glDestroyRenderer(h) : d3dDestroyRenderer(h))
#define b3dxIsOverlayRenderer(h) \
  (glMode ? glIsOverlayRenderer(h) : d3dIsOverlayRenderer(h))
#define b3dxSetBufferRect(hh,x,y,w,h) \
  (glMode ? glSetBufferRect(hh, x, y, w, h) : d3dSetBufferRect(hh,x,y,w,h))
#define b3dxGetRendererSurfaceHandle(h) \
  (glMode ? glGetRendererSurfaceHandle(h) : d3dGetRendererSurfaceHandle(h))
#define b3dxGetRendererSurfaceWidth(h) \
  (glMode ? glGetRendererSurfaceWidth(h) : d3dGetRendererSurfaceWidth(h))
#define b3dxGetRendererSurfaceHeight(h) \
  (glMode ? glGetRendererSurfaceHeight(h) : d3dGetRendererSurfaceHeight(h))
#define b3dxGetRendererSurfaceDepth(h) \
  (glMode ? glGetRendererSurfaceDepth(h) : d3dGetRendererSurfaceDepth(h))
#define b3dxGetRendererColorMasks(h,m) \
  (glMode ? glGetRendererColorMasks(h,m) : d3dGetRendererColorMasks(h,m))

#define b3dxSetViewport(hh,x,y,w,h) \
  (glMode ? glSetViewport(hh,x,y,w,h) : d3dSetViewport(hh,x,y,w,h))
#define b3dxClearDepthBuffer(h) \
  (glMode ? glClearDepthBuffer(h) : d3dClearDepthBuffer(h))
#define b3dxClearViewport(h,rgba,pv) \
  (glMode ? glClearViewport(h,rgba, pv) : d3dClearViewport(h,rgba,pv))

#define b3dxSetTransform(h,mv,p) \
  (glMode ? glSetTransform(h,mv,p) : d3dSetTransform(h,mv,p))
#define b3dxDisableLights(h) \
  (glMode ? glDisableLights(h) : d3dDisableLights(h))
#define b3dxLoadLight(h,i,l) \
  (glMode ? glLoadLight(h,i,l) : d3dLoadLight(h,i,l))
#define b3dxLoadMaterial(h,m) \
  (glMode ? glLoadMaterial(h,m) : d3dLoadMaterial(h,m))
#define b3dxRenderVertexBuffer(h,p,f,t,va,vs,ia,is) \
  (glMode ? glRenderVertexBuffer(h,p,f,t,va,vs,ia,is) : d3dRenderVertexBuffer(h,p,f,t,va,vs,ia,is))
#define b3dxFlushRenderer(h) \
  (glMode ? glFlushRenderer(h) : d3dFlushRenderer(h))
#define b3dxFinishRenderer(h) \
  (glMode ? glFinishRenderer(h) : d3dFinishRenderer(h))
#define b3dxSwapRendererBuffers(h) \
  (glMode ? glSwapRendererBuffers(h) : d3dSwapRendererBuffers(h))
#define b3dxGetIntProperty(h,p) \
  (glMode ? glGetIntProperty(h,p) : d3dGetIntProperty(h,p))
#define b3dxSetIntProperty(h,p,v) \
  (glMode ? glSetIntProperty(h,p,v) : d3dSetIntProperty(h,p,v))
#define b3dxSetVerboseLevel(l) \
  (glMode ? glSetVerboseLevel(l) : d3dSetVerboseLevel(l))
#define b3dxSetFog(h,t,d,s,e,rgba) \
  (glMode ? glSetFog(h,t,d,s,e,rgba) : d3dSetFog(h,t,d,s,e,rgba))
#endif

#endif /*B3D_ACCELERATOR_PLUGIN_H*/
