/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqWin32D3D.c
*   CONTENT: Win32 specific bindings for Direct3D
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*
*****************************************************************************/
#define DIRECTDRAW_VERSION 0x700 /* restrict to DX7 */
#include <windows.h>
#include <ole2.h>
#ifdef __MINGW32__
#define HMONITOR_DECLARED
#undef WINNT
#endif

#include <ddraw.h>
#include <d3d.h>
#include <stdio.h>
#include <math.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "../SurfacePlugin/SurfacePlugin.h"
#include "B3DAcceleratorPlugin.h"

#if defined(B3DX_D3D)

/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
# define DPRINTF3D(vLevel, args) if(vLevel <= verboseLevel) {\
	FILE *fp = fopen("Squeak3D.log", "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}

/* Plugin refs */
extern struct VirtualMachine *interpreterProxy;

/* Verbose level for debugging purposes:
	0 - print NO information ever
	1 - print critical debug errors
	2 - print debug warnings
	3 - print extra information
	4 - print extra warnings
	5 - print information about primitive execution

   10 - print information about each vertex and face
*/
#ifndef B3DX_GL
int verboseLevel = 1;
#else
extern int verboseLevel;
#endif

#define ERROR_CHECK if(FAILED(hRes)) { DPRINTF3D(2, (fp, "Error (%lx) in %s, line %d\n", hRes, __FILE__, __LINE__))}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/* Entry points for the surface manager. Looked up on startup */
static fn_ioRegisterSurface registerSurface = 0;
static fn_ioUnregisterSurface unregisterSurface = 0;
static fn_ioFindSurface findSurface = 0;

/* Global DirectDraw (2D) objects.
   These are unique and exist for Squeak in general. */
static LPDIRECTDRAW7 lpDD = NULL; /* DDraw object */
static LPDIRECTDRAWSURFACE7 lpddPrimary = NULL; /* Primary display */
static LPDIRECTDRAWCLIPPER lpddClipper = NULL; /* Display clipper */

/* Global DirectDraw (3D) objects */
static LPDIRECT3D7 lpD3D = NULL;

/* The current display depth */
static DWORD dwDisplayBitDepth = 0UL;

int fDirectXEnable = 1;      /* DirectX is enabled */

static HWND *theSTWindow = NULL; /* a reference to Squeak's main window */
static RECT stWindowRect;    /* Squeak window rectangle in screen coords */
static int fUseSmartClipper = 1;    /* Use a smart clipper approach */
static int fUpdateClipper = 1;      /* Determine clipper status again */
static int fClipperAttached = 0;    /* Is a clipper currently attached? */
static int fPrintDebugInfo = 1;	   /* Shall we print debugging information?! */
static int fExclusive = 0;          /* Do we have exclusive access?! */
static int fHasSysLock = 1;	    /* Do we use DDLOCK_NOSYSLOCK?! */

typedef struct d3dRenderer {
  int bufferRect[4];
  int viewport[4];

  /* the (offscreen) target surface */
  LPDIRECTDRAWSURFACE7  lpdsTarget;
  LPDIRECTDRAWSURFACE7  lpdsZBuffer;

  /* the surface ID as exposed to Squeak */
  int surfaceID;

  /* device description of renderer */
  int  devFlags; /* device flags from CreateRenderer */
  BOOL fDeviceFound;
  D3DDEVICEDESC7 ddDesc;
  GUID guidDevice;
  char szDeviceDesc[256];
  char szDeviceName[256];

  /* rendering device */
  LPDIRECT3DDEVICE7     lpDevice;

  /* cached texture formats */
  DDPIXELFORMAT	ddpfTextureFormat08;
  DDPIXELFORMAT	ddpfTextureFormat0x5x5x5;
  DDPIXELFORMAT	ddpfTextureFormat1x5x5x5; /* unlikely - HW only */
  DDPIXELFORMAT	ddpfTextureFormat4x4x4x4; /* unlikely - HW only */
  DDPIXELFORMAT	ddpfTextureFormat0x8x8x8;
  DDPIXELFORMAT	ddpfTextureFormat8x8x8x8;
  BOOL fTextureFound08;
  BOOL fTextureFound0x5x5x5;
  BOOL fTextureFound1x5x5x5; /* unlikely - HW only */
  BOOL fTextureFound4x4x4x4; /* unlikely - HW only */
  BOOL fTextureFound0x8x8x8;
  BOOL fTextureFound8x8x8x8;

  /* how many lights are we using? */
  int maxLights;

  /* Flag determining whether we have a scene running */
  BOOL fSceneStarted;
  /* Flag determining if this renderer is actively used */
  BOOL fUsed;
} d3dRenderer;

#define MAX_RENDERER 16
static d3dRenderer *current = NULL;
static d3dRenderer allRenderer[MAX_RENDERER];

#define RELEASE(lp) if(lp) { lp->lpVtbl->Release(lp); lp = NULL; }

d3dRenderer *d3dRendererFromHandle(int handle) {
  DPRINTF3D(7, (fp, "Looking for renderer id: %d\n", handle));
  if(handle < 0 || handle >= MAX_RENDERER) return NULL;
  if(allRenderer[handle].fUsed) return allRenderer+handle;
  return NULL;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/* d3dLock:
   Perform a surface lock operation. This version also checks if 
   DDLOCK_NOSYSLOCK is supported.
*/
static HRESULT d3dLock(LPDIRECTDRAWSURFACE7 lpdd, DDSURFACEDESC2 *ddsd, 
		       int printWarnings)
{
  HRESULT hRes;
  ddsd->dwSize = sizeof(DDSURFACEDESC2);
  hRes = lpdd->lpVtbl->
    Lock(lpdd, NULL, ddsd, 
	 DDLOCK_NOSYSLOCK | DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT, NULL);
  if(!FAILED(hRes)) return DD_OK;
  if(printWarnings)
    DPRINTF3D(3,(fp,"WARNING: Failed to lock surface using DDLOCK_NOSYSLOCK | DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT (errCode=%lX)\n",hRes));
  hRes = lpdd->lpVtbl->
    Lock(lpdd, NULL, ddsd, DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT, NULL);
  if(!FAILED(hRes)) return DD_OK;
  if(printWarnings)
    DPRINTF3D(3,(fp,"WARNING: Failed to lock surface using DDLOCK_SURFACEMEMORYPTR | DDLOCK_WAIT (errCode=%lX)\n",hRes));
  hRes = lpdd->lpVtbl->Lock(lpdd, NULL, ddsd, DDLOCK_WAIT, NULL);
  if(!FAILED(hRes)) return DD_OK;
  if(printWarnings)
    DPRINTF3D(3,(fp,"WARNING: Failed to lock surface using DDLOCK_WAIT (errCode=%lX)\n",hRes));
  /* Wait until the blt completed */
  do {
    hRes = lpdd->lpVtbl->GetBltStatus(lpdd, DDGBS_ISBLTDONE);
  } while(hRes == DDERR_WASSTILLDRAWING);
  if(FAILED(hRes)) {
    DPRINTF3D(3,(fp,"WARNING: Blt not completed on surface (errCode=%lX)\n",hRes));
  }
  hRes = lpdd->lpVtbl->Lock(lpdd, NULL, ddsd, 0, NULL);
  if(!FAILED(hRes)) return DD_OK;
  DPRINTF3D(1,(fp,"ERROR: Failed to lock surface using (errCode=%lX)\n",hRes));
  return hRes;
}

/* d3dGetSurfaceFormat: Return information about the given surface. */
static int d3dGetSurfaceFormat(sqIntptr_t handle, 
			       int* width, int* height, int* depth, int* isMSB)
{
  LPDIRECTDRAWSURFACE7 lpddSurface=(LPDIRECTDRAWSURFACE7) handle;
  DDSURFACEDESC2 desc;
  HRESULT hRes;

  desc.dwSize = sizeof(DDSURFACEDESC2);
  hRes = lpddSurface->lpVtbl->GetSurfaceDesc(lpddSurface, &desc);
  if(FAILED(hRes)) {
    DPRINTF3D(1,(fp,"ERROR: Failed to obtain surface descriptor (d3dGetSurfaceFormat) (errCode=%lX)\n",hRes));
    return 0;
  }
  *width = desc.dwWidth;
  *height = desc.dwHeight;
  *depth = desc.ddpfPixelFormat.dwRGBBitCount;
  *isMSB = 0;
  return 1;
}

/* d3dLockSurface: Lock the bits of the surface for BitBlt. */
static sqIntptr_t d3dLockSurface(sqIntptr_t handle, 
			  int *pitch, int x, int y, int w, int h)
{
  LPDIRECTDRAWSURFACE7 lpddSurface=(LPDIRECTDRAWSURFACE7) handle;
  DDSURFACEDESC2 desc;
  HRESULT hRes;

  hRes = d3dLock(lpddSurface, &desc, 0);
  if(FAILED(hRes)) return 0;
  *pitch = desc.lPitch;
  return (sqIntptr_t) desc.lpSurface;
}

/* d3dUnlockSurface: Unlock the bits of a surface after BitBlt completed. */
static int d3dUnlockSurface(sqIntptr_t handle, 
			    int x, int y, int w, int h)
{
  LPDIRECTDRAWSURFACE7 lpddSurface=(LPDIRECTDRAWSURFACE7) handle;
  HRESULT hRes;

  hRes = lpddSurface->lpVtbl->Unlock(lpddSurface, NULL);
  if(FAILED(hRes)) {
    DPRINTF3D(1,(fp,"ERROR: Failed to unlock surface (d3dUnlockSurface) (errCode=%lX)\n",hRes));
    return 0;
  }
  return 1;
}

/* d3dShowSurface: Blt the modified contents of the surface to the screen. */
static int d3dShowSurface(sqIntptr_t handle, 
			  int x, int y, int w, int h)
{
  /* unsupported */
  return 0;
}

static sqSurfaceDispatch d3dTextureDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) d3dGetSurfaceFormat,
  (fn_lockSurface) d3dLockSurface,
  (fn_unlockSurface) d3dUnlockSurface,
  (fn_showSurface) d3dShowSurface
};

static sqSurfaceDispatch d3dTargetDispatch = {
  1,
  0,
  (fn_getSurfaceFormat) d3dGetSurfaceFormat,
  (fn_lockSurface) d3dLockSurface,
  (fn_unlockSurface) d3dUnlockSurface,
  (fn_showSurface) d3dShowSurface
};


/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

/*
  EnumDeviceCallback
  Enumerate all D3D devices and try to find a suitable hardware
  rasterizer. If none is found use a software rasterizer.
*/

HRESULT WINAPI
EnumDeviceCallback(LPSTR            lpszDeviceDesc,
                   LPSTR            lpszDeviceName,
                   LPD3DDEVICEDESC7 lpDeviceDesc,
                   LPVOID           lpUserArg)
{
  LPD3DPRIMCAPS	triCaps;
  DWORD depth;
  BOOL  fIsHardware;
  d3dRenderer *renderer = (d3dRenderer*)lpUserArg;

  /* see if this is a hardware device */
  fIsHardware = lpDeviceDesc->dwDevCaps & D3DDEVCAPS_HWRASTERIZATION;

  /* Check the triangle capabilities of this device */
  triCaps = &lpDeviceDesc->dpcTriCaps;

  DPRINTF3D(3,(fp, "\n#### Checking new device\n"));
  DPRINTF3D(3,(fp, "Device name: %s\n", lpszDeviceName));
  DPRINTF3D(3,(fp, "Device description: %s\n", lpszDeviceDesc));
  DPRINTF3D(3,(fp, "Hardware accelerated: %s\n", fIsHardware ? "YES" : "NO"));
  DPRINTF3D(3,(fp, "Available render depths: "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_1) DPRINTF3D(3,(fp, "1 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_2) DPRINTF3D(3,(fp, "2 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_4) DPRINTF3D(3,(fp, "4 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_8) DPRINTF3D(3,(fp, "8 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_16) DPRINTF3D(3,(fp, "16 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_24) DPRINTF3D(3,(fp, "24 "));
  if(lpDeviceDesc->dwDeviceRenderBitDepth & DDBD_32) DPRINTF3D(3,(fp, "32 "));
  DPRINTF3D(3,(fp, "\n"));

  DPRINTF3D(3,(fp, "Available Z-buffer depths: "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_1) DPRINTF3D(3,(fp, "1 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_2) DPRINTF3D(3,(fp, "2 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_4) DPRINTF3D(3,(fp, "4 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_8) DPRINTF3D(3,(fp, "8 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_16) DPRINTF3D(3,(fp, "16 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_24) DPRINTF3D(3,(fp, "24 "));
  if(lpDeviceDesc->dwDeviceZBufferBitDepth & DDBD_32) DPRINTF3D(3,(fp, "32 "));
  DPRINTF3D(3,(fp, "\n"));

  DPRINTF3D(3,(fp, "Z-buffer tests: "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_NEVER) DPRINTF3D(3,(fp, "NEVER "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_LESS) DPRINTF3D(3,(fp, "LESS "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_EQUAL) DPRINTF3D(3,(fp, "EQUAL "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_LESSEQUAL) DPRINTF3D(3,(fp, "LESSEQUAL "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_GREATER) DPRINTF3D(3,(fp, "GREATER "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_NOTEQUAL) DPRINTF3D(3,(fp, "NOTEQUAL "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_GREATEREQUAL) DPRINTF3D(3,(fp, "GREATEREQUAL "));
  if(triCaps->dwZCmpCaps & D3DPCMPCAPS_ALWAYS) DPRINTF3D(3,(fp, "ALWAYS "));
  DPRINTF3D(3,(fp, "\n"));

  DPRINTF3D(3,(fp, "Gouraud shading (RGB): %s\n",
	     (triCaps->dwShadeCaps & D3DPSHADECAPS_COLORGOURAUDRGB) ? "YES" : "NO"));
  DPRINTF3D(3,(fp, "Texture perspective correction: %s\n",
	     (triCaps->dwTextureCaps & D3DPTEXTURECAPS_PERSPECTIVE) ? "YES" : "NO"));
  DPRINTF3D(3,(fp, "Bilinear texture interpolation: %s\n",
	     (triCaps->dwTextureFilterCaps & D3DPTFILTERCAPS_LINEAR) ? "YES" : "NO"));

  DPRINTF3D(3, (fp, "Dithering: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_DITHER) ? "YES" : "NO"));

  DPRINTF3D(3, (fp, "Range based fog: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_FOGRANGE) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "Pixel based fog: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_FOGTABLE) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "Vertex based fog: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_FOGVERTEX) ? "YES" : "NO"));

  DPRINTF3D(3, (fp, "W-Buffering: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_WBUFFER) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "W-based fog: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_WFOG) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "Z-based fog: %s\n",
    (triCaps->dwRasterCaps & D3DPRASTERCAPS_ZFOG) ? "YES" : "NO"));

  DPRINTF3D(3, (fp, "Flat fog: %s\n",
    (triCaps->dwShadeCaps & D3DPSHADECAPS_FOGFLAT) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "Gouraud fog: %s\n",
    (triCaps->dwShadeCaps & D3DPSHADECAPS_FOGGOURAUD) ? "YES" : "NO"));
  DPRINTF3D(3, (fp, "Phong fog: %s\n",
    (triCaps->dwShadeCaps & D3DPSHADECAPS_FOGPHONG) ? "YES" : "NO"));

  /* The device must support the current display depth */
  if(!(lpDeviceDesc->dwDeviceRenderBitDepth & dwDisplayBitDepth))
    return D3DENUMRET_OK;

  /* The device must have a z-buffer >= 16bit */
  depth = lpDeviceDesc->dwDeviceZBufferBitDepth;
  if( !(depth & DDBD_16) && !(depth & DDBD_24) && !(depth & DDBD_32))
    return D3DENUMRET_OK;

  /* The device must support less or less-equal depth comparison */
  if(!(triCaps->dwZCmpCaps & D3DPCMPCAPS_LESS) &&
     !(triCaps->dwZCmpCaps & D3DPCMPCAPS_LESSEQUAL))
    return D3DENUMRET_OK;

  /* The device must support gouraud shaded triangles */
  if(!(triCaps->dwShadeCaps & D3DPSHADECAPS_COLORGOURAUDMONO) &&
     !(triCaps->dwShadeCaps & D3DPSHADECAPS_COLORGOURAUDRGB))
    return D3DENUMRET_OK;

  /* The device must support perspective corrected textures */
  if(!(triCaps->dwTextureCaps & D3DPTEXTURECAPS_PERSPECTIVE))
    return D3DENUMRET_OK;

  /* The device must support texture interpolation */
  if(!(triCaps->dwTextureFilterCaps & D3DPTFILTERCAPS_LINEAR))
    return D3DENUMRET_OK;

  /* The device must match hw/sw constraints from the renderer */
  if(fIsHardware) {
    if(!(renderer->devFlags & B3D_HARDWARE_RENDERER)) return D3DENUMRET_OK;
  } else {
    if(!(renderer->devFlags & B3D_HARDWARE_RENDERER)) return D3DENUMRET_OK;
  }

  /* this is a device we're interested in */
  if(renderer->fDeviceFound) {
    /* we had one already, check the details */
    if(renderer->ddDesc.dwDevCaps & D3DDEVCAPS_HWRASTERIZATION) {
      /* we have already a hardware renderer */
      if(!fIsHardware) return D3DENUMRET_OK;
    }
  }
  CopyMemory(&renderer->guidDevice, &lpDeviceDesc->deviceGUID, sizeof(GUID));
  CopyMemory(&renderer->ddDesc, lpDeviceDesc, sizeof(D3DDEVICEDESC7));
  strcpy(renderer->szDeviceDesc, lpszDeviceDesc);
  strcpy(renderer->szDeviceName, lpszDeviceName);
  renderer->fDeviceFound = 1;

  return D3DENUMRET_OK;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

HRESULT CALLBACK EnumZBufferCallback(DDPIXELFORMAT *ddpf, LPVOID lParam)
{
  DDPIXELFORMAT* dest = (DDPIXELFORMAT*)lParam;

  DPRINTF3D(3,(fp, "### New Z-Buffer format:\n"));
  DPRINTF3D(3,(fp, "flags: %lx\n", ddpf->dwFlags));
  DPRINTF3D(3,(fp, "depth: %ld\n", ddpf->dwZBufferBitDepth));
  if(ddpf->dwFlags != DDPF_ZBUFFER) 
    D3DENUMRET_OK; /* not a z-buffer */
  if(!dest->dwSize) {
    /* this is the first z-buffer we found */
    memcpy(dest, ddpf, sizeof(DDPIXELFORMAT));
    return D3DENUMRET_OK;
  }
  /* more than one choice; try picking a 16bit z-buffer */
  if(dest->dwZBufferBitDepth == 16) 
    return D3DENUMRET_OK;
  if(ddpf->dwZBufferBitDepth == 16) {
    memcpy(dest, ddpf, sizeof(DDPIXELFORMAT));
    return D3DENUMRET_OK;
  }
  /* none of the two is a 16bit z-buffer; just take the larger one */
  if(ddpf->dwZBufferBitDepth > dest->dwZBufferBitDepth) {
    memcpy(dest, ddpf, sizeof(DDPIXELFORMAT));
  }
  return D3DENUMRET_OK;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

HRESULT CALLBACK EnumTextureCallback(DDPIXELFORMAT *ddpf, LPVOID lParam)
{
  d3dRenderer *renderer = (d3dRenderer*)lParam;

  /* Check for a 8 bit palette indexed texture */
  if(ddpf->dwFlags & DDPF_PALETTEINDEXED8) {
    DPRINTF3D(3,(fp, "\nTexture: 8bit palette indexed\n"));
    CopyMemory(&renderer->ddpfTextureFormat08, ddpf, sizeof(*ddpf));
    renderer->fTextureFound08 = TRUE;
    return DDENUMRET_OK;
  }
  /* Check for 16 bit textures */
  if((ddpf->dwRGBBitCount == 16) && (ddpf->dwFlags & DDPF_RGB)) {
    DPRINTF3D(3,(fp, "\nTexture: 16bit RGB\n"));
    DPRINTF3D(3,(fp, "Red mask: %lx\n", ddpf->dwRBitMask));
    DPRINTF3D(3,(fp, "Green mask: %lx\n", ddpf->dwGBitMask));
    DPRINTF3D(3,(fp, "Blue mask: %lx\n", ddpf->dwBBitMask));
    DPRINTF3D(3,(fp, "Alpha mask: %lx\n", ddpf->dwRGBAlphaBitMask));
    if((ddpf->dwFlags & DDPF_ALPHAPIXELS) && 
       ddpf->dwRBitMask	== 0x0F00 && 
       ddpf->dwGBitMask	== 0x00F0 && 
       ddpf->dwBBitMask	== 0x000F &&
       ddpf->dwRGBAlphaBitMask == 0xF000) {
      DPRINTF3D(3,(fp, "[Note: Perfect 4x4x4x4 texture format]\n"));
      CopyMemory(&renderer->ddpfTextureFormat4x4x4x4, ddpf, sizeof(*ddpf));
      renderer->fTextureFound4x4x4x4 = TRUE;
      return DDENUMRET_OK;
    }
    if(ddpf->dwRBitMask == 0x7C00 && 
       ddpf->dwGBitMask == 0x03E0 && 
       ddpf->dwBBitMask == 0x001F) {
      if(ddpf->dwFlags & DDPF_ALPHAPIXELS) {
	if(ddpf->dwRGBAlphaBitMask == 0x8000) {
	  DPRINTF3D(3,(fp, "[Note: Perfect 1x5x5x5 texture format]\n"));
	  CopyMemory(&renderer->ddpfTextureFormat1x5x5x5, ddpf, sizeof(*ddpf));
	  renderer->fTextureFound1x5x5x5 = TRUE;
	}
      } else {
	DPRINTF3D(3,(fp, "[Note: Perfect 0x5x5x5 texture format]\n"));
	CopyMemory(&renderer->ddpfTextureFormat0x5x5x5, ddpf, sizeof(*ddpf));
	renderer->fTextureFound0x5x5x5 = TRUE;
      }
    } else {
      if(ddpf->dwFlags & DDPF_ALPHAPIXELS) {
	DPRINTF3D(3,(fp, "[Note: Lousy 1x5x5x5 texture format]\n"));
	if(renderer->fTextureFound1x5x5x5) return DDENUMRET_OK;
	CopyMemory(&renderer->ddpfTextureFormat1x5x5x5, ddpf, sizeof(*ddpf));
	renderer->fTextureFound1x5x5x5 = TRUE;
      } else {
	DPRINTF3D(3,(fp, "[Note: Lousy 0x5x5x5 texture format]\n"));
	if(renderer->fTextureFound0x5x5x5) return DDENUMRET_OK;
	CopyMemory(&renderer->ddpfTextureFormat0x5x5x5, ddpf, sizeof(*ddpf));
	renderer->fTextureFound0x5x5x5 = TRUE;
      }
    }
  }
  /* Check for 32bit textures */
  if( (ddpf->dwRGBBitCount == 32) && (ddpf->dwFlags & DDPF_RGB)) {
    DPRINTF3D(3,(fp, "\nTexture: 32bit RGB\n"));
    DPRINTF3D(3,(fp, "Red mask: %lx\n", ddpf->dwRBitMask));
    DPRINTF3D(3,(fp, "Green mask: %lx\n", ddpf->dwGBitMask));
    DPRINTF3D(3,(fp, "Blue mask: %lx\n", ddpf->dwBBitMask));
    DPRINTF3D(3,(fp, "Alpha mask: %lx\n", ddpf->dwRGBAlphaBitMask));
    if(ddpf->dwRBitMask == 0x00FF0000 && 
       ddpf->dwGBitMask == 0x0000FF00 && 
       ddpf->dwBBitMask == 0x000000FF) {
      if(ddpf->dwFlags & DDPF_ALPHAPIXELS) {
	if(ddpf->dwRGBAlphaBitMask == 0xFF000000) {
	  DPRINTF3D(3,(fp, "[Note: Perfect 8x8x8x8 texture format]\n"));
	  CopyMemory(&renderer->ddpfTextureFormat8x8x8x8, ddpf, sizeof(*ddpf));
	  renderer->fTextureFound8x8x8x8 = TRUE;
	}
      } else {
	DPRINTF3D(3,(fp, "[Note: Perfect 0x8x8x8 texture format]\n"));
	CopyMemory(&renderer->ddpfTextureFormat0x8x8x8, ddpf, sizeof(*ddpf));
	renderer->fTextureFound0x8x8x8 = TRUE;
      }
    } else {
      if(ddpf->dwFlags & DDPF_ALPHAPIXELS) {
	DPRINTF3D(3,(fp, "[Note: Lousy 8x8x8x8 texture format]\n"));
	if(renderer->fTextureFound8x8x8x8) return DDENUMRET_OK;
	CopyMemory(&renderer->ddpfTextureFormat8x8x8x8, ddpf, sizeof(*ddpf));
	renderer->fTextureFound0x8x8x8 = TRUE;
      } else {
	DPRINTF3D(3,(fp, "[Note: Lousy 0x8x8x8 texture format]\n"));
	if(renderer->fTextureFound0x5x5x5) return DDENUMRET_OK;
	CopyMemory(&renderer->ddpfTextureFormat0x8x8x8, ddpf, sizeof(*ddpf));
	renderer->fTextureFound0x8x8x8 = TRUE;
      }
    }
  }

  return DDENUMRET_OK;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/* Get information about the available memory */
static void d3dPrintMemoryInformation(void)
{
  HRESULT hRes;
  DWORD dwTotal, dwFree;
  DDSCAPS2 ddsCaps;

  dwTotal = dwFree = 0;
  ddsCaps.dwCaps = DDSCAPS_VIDEOMEMORY;
  hRes = lpDD->lpVtbl->GetAvailableVidMem(lpDD, &ddsCaps, &dwTotal, &dwFree);
  ERROR_CHECK;
  DPRINTF3D(3,(fp,"Video memory: %lu (available total) %lu (available free)\n",
	     dwTotal, dwFree));
  dwTotal = dwFree = 0;
  ddsCaps.dwCaps = DDSCAPS_TEXTURE;
  hRes = lpDD->lpVtbl->GetAvailableVidMem(lpDD, &ddsCaps, &dwTotal, &dwFree);
  ERROR_CHECK;
  DPRINTF3D(3,(fp,"Texture memory: %lu (available total) %lu (available free)\n",
	     dwTotal, dwFree));
  dwTotal = dwFree = 0;
  ddsCaps.dwCaps = DDSCAPS_ZBUFFER;
  hRes = lpDD->lpVtbl->GetAvailableVidMem(lpDD, &ddsCaps, &dwTotal, &dwFree);
  ERROR_CHECK;
  DPRINTF3D(3,(fp,"Z-Buffer memory: %lu (available total) %lu (available free)\n",
	     dwTotal, dwFree));
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int d3dInitializePrimary(void) {
  HRESULT hRes;
  DPRINTF3D(5,(fp, "[Initializing primary surface]\n"));
  if(!lpDD) {
    DPRINTF3D(5,(fp, "[Creating DDraw object]\n"));
    hRes = CoCreateInstance(&CLSID_DirectDraw,
			    NULL, 
			    CLSCTX_INPROC_SERVER,
			    &IID_IDirectDraw7,
			    (void**)&lpDD);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
    if(!lpDD) {
      DPRINTF3D(1,(fp,"ERROR: Could not create IDirectDraw7\n"));
      return 0;
    }
    DPRINTF3D(5,(fp, "[Initializing DDraw object]\n"));
    hRes = lpDD->lpVtbl->Initialize(lpDD, NULL);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
    DPRINTF3D(5,(fp, "[Setting cooperation level]\n"));
    hRes = lpDD->lpVtbl->
      SetCooperativeLevel(lpDD, *theSTWindow, 
			  DDSCL_NORMAL | DDSCL_FPUPRESERVE);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
  }
  if(!lpD3D) {
    /* query for the direct3d object */
    DPRINTF3D(5,(fp, "[Querying for IDirect3D7]\n"));
    hRes = lpDD->lpVtbl->QueryInterface(lpDD,&IID_IDirect3D7, (LPVOID*)&lpD3D);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
    if(!lpD3D) {
      DPRINTF3D(1,(fp,"ERROR: Could not retrieve IDirect3D7\n"));
      return 0;
    }
  }
  if(!lpddPrimary) {
    /* create the primary surface */
    DDSURFACEDESC2 ddsd;
    ZeroMemory( &ddsd, sizeof(DDSURFACEDESC2) );
    ddsd.dwSize         = sizeof(DDSURFACEDESC2);
    ddsd.dwFlags        = DDSD_CAPS;
    ddsd.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;

    DPRINTF3D(5,(fp, "[Creating primary surface]\n"));
    hRes = lpDD->lpVtbl->CreateSurface( lpDD, &ddsd, &lpddPrimary, NULL );
    ERROR_CHECK;
    if (FAILED(hRes)) return 0;
    if(!lpddPrimary) {
      DPRINTF3D(1,(fp,"ERROR: Could not create primary surface\n"));
      return 0;
    }
  }

  /*
   * Create the clipper. We bind the application's window to the
   * clipper and attach it to the primary. This ensures then when we
   * blit from the rendering surface to the primary we don't write
   * outside the visible region of the window.
   */
  if(!lpddClipper) {
    DPRINTF3D(5,(fp, "[Creating clipper]\n"));
    hRes = lpDD->lpVtbl->CreateClipper(lpDD, 0UL, &lpddClipper, NULL);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
    if(!lpddClipper) {
      DPRINTF3D(1,(fp,"ERROR: Could not create clipper\n"));
      return 0;
    }
    hRes = lpddClipper->lpVtbl->SetHWnd(lpddClipper, 0UL, *theSTWindow);
    ERROR_CHECK;
    if(FAILED(hRes)) return 0;
    hRes = lpddPrimary->lpVtbl->SetClipper(lpddPrimary, lpddClipper);
    ERROR_CHECK;
    if (FAILED(hRes)) return 0;
    fClipperAttached = 1;
  }
  /* successful initialization */
  return 1;
}

int d3dReleasePrimary(void) {
	RELEASE(lpddClipper);
	RELEASE(lpddPrimary);
	RELEASE(lpD3D);
	RELEASE(lpDD);
	return 1;
}

int d3dInitializeRenderer(d3dRenderer *renderer) {
  HRESULT hRes;
  DDSURFACEDESC2 ddsd;
  DDPIXELFORMAT ddpfZBuffer;
  LPDIRECT3DDEVICE7    lpDevice    = NULL;
  LPDIRECTDRAWSURFACE7 lpdsTarget  = NULL;
  LPDIRECTDRAWSURFACE7 lpdsZBuffer = NULL;
  DDSURFACEDESC2 displayDesc;

  /* Get the current display mode */
  ZeroMemory(&displayDesc, sizeof(displayDesc));
  displayDesc.dwSize = sizeof(displayDesc);
  hRes = lpDD->lpVtbl->GetDisplayMode(lpDD, &displayDesc);
  if(FAILED(hRes)) {
    DPRINTF3D(1,(fp, "ERROR: Failed to get current display mode (errCode=%lX)\n",hRes));
    goto cleanup;
  }
  DPRINTF3D(3,(fp,"Current display width: %lu\n",displayDesc.dwWidth));
  DPRINTF3D(3,(fp,"Current display height: %lu\n",displayDesc.dwHeight));
  DPRINTF3D(3,(fp,"Current display depth: %lu\n",displayDesc.ddpfPixelFormat.dwRGBBitCount));
  /* Set the display depth bit */
  switch(displayDesc.ddpfPixelFormat.dwRGBBitCount) {
  case 16: dwDisplayBitDepth = DDBD_16; break;
  case 32: dwDisplayBitDepth = DDBD_32; break;
  default:
    DPRINTF3D(1,(fp, "ERROR: Display depth %lu is not supported\n", 
	       displayDesc.ddpfPixelFormat.dwRGBBitCount));
    goto cleanup; /* we only deal with 16-32 bit */
  };

  /* Print us some memory information */
  d3dPrintMemoryInformation();

  /* enumerate all available devices and find a nice one */
  renderer->fDeviceFound = 0;
  hRes = lpD3D->lpVtbl->
    EnumDevices(lpD3D, EnumDeviceCallback, renderer);
  ERROR_CHECK;

  /* see if we have a device */
  if(!renderer->fDeviceFound) {
    return 0;
  }

  DPRINTF3D(3, (fp, "### Using %s\n(%s)\n", 
	      renderer->szDeviceName, renderer->szDeviceDesc));

  /* enumerate z-buffer formats and find a nice one */
  memset(&ddpfZBuffer, 0, sizeof(ddpfZBuffer));
  hRes = lpD3D->lpVtbl->
    EnumZBufferFormats(lpD3D, &renderer->guidDevice, EnumZBufferCallback, &ddpfZBuffer);

  /* see if we have a z-buffer format */
  if(FAILED(hRes) || ddpfZBuffer.dwSize == 0) {
    return 0;
  }

  /* create the rendering surface */
  ZeroMemory(&ddsd, sizeof(DDSURFACEDESC2));
  ddsd.dwSize = sizeof(DDSURFACEDESC2);
  ddsd.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_CAPS;
  ddsd.ddsCaps.dwCaps = 
    DDSCAPS_OFFSCREENPLAIN | DDSCAPS_3DDEVICE | DDSCAPS_VIDEOMEMORY;
  ddsd.dwWidth  = renderer->bufferRect[2];
  ddsd.dwHeight = renderer->bufferRect[3];
  hRes = lpDD->lpVtbl->CreateSurface(lpDD, &ddsd, &lpdsTarget, NULL);
  ERROR_CHECK;
  if(FAILED(hRes)) goto cleanup;

  /* create the z-buffer */
  ZeroMemory(&ddsd, sizeof(ddsd));
  ddsd.dwSize = sizeof(ddsd);
  ddsd.dwFlags = DDSD_CAPS | DDSD_WIDTH  | DDSD_HEIGHT | DDSD_PIXELFORMAT;
  memcpy(&ddsd.ddpfPixelFormat, &ddpfZBuffer, sizeof(DDPIXELFORMAT));

  /* make sure HW z-buffer ends up in video and SW z-buffer in system memory */
  if(renderer->ddDesc.dwDevCaps & D3DDEVCAPS_HWRASTERIZATION) {
    ddsd.ddsCaps.dwCaps    = DDSCAPS_ZBUFFER | DDSCAPS_VIDEOMEMORY;
  } else {
    ddsd.ddsCaps.dwCaps    = DDSCAPS_ZBUFFER | DDSCAPS_SYSTEMMEMORY;
  }
  ddsd.dwWidth           = renderer->bufferRect[2];
  ddsd.dwHeight          = renderer->bufferRect[3];

  hRes = lpDD->lpVtbl->CreateSurface(lpDD, &ddsd, &lpdsZBuffer, NULL);
  if (FAILED(hRes)) {
    /* Scond try in system memory */
    DPRINTF3D(2,(fp,"WARNING: Failed to create VRAM z-buffer (errCode=%lX)\n",hRes));
    ddsd.ddsCaps.dwCaps = DDSCAPS_ZBUFFER | DDSCAPS_SYSTEMMEMORY;
    hRes = lpDD->lpVtbl->CreateSurface(lpDD, &ddsd, &lpdsZBuffer, NULL);
  }
  ERROR_CHECK;
  if(FAILED(hRes)) goto cleanup;

  /* attach z-buffer to rendering target */
  hRes = lpdsTarget->lpVtbl->AddAttachedSurface(lpdsTarget, lpdsZBuffer);
  ERROR_CHECK;
  if(FAILED(hRes)) goto cleanup;

  /* create the rendering device */
  hRes = lpD3D->lpVtbl->CreateDevice(lpD3D, &renderer->guidDevice,
				     lpdsTarget, &lpDevice);
  ERROR_CHECK;
  if(FAILED(hRes)) goto cleanup;

  /* enumerate available texture formats */
  hRes = lpDevice->lpVtbl->EnumTextureFormats(lpDevice, EnumTextureCallback, renderer);
  ERROR_CHECK;

  /* install the default render states */
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_ZENABLE, D3DZB_TRUE);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_CULLMODE, D3DCULL_NONE);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_DITHERENABLE, TRUE);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_NORMALIZENORMALS, TRUE);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetTextureStageState(lpDevice, 0, D3DTSS_MINFILTER, D3DTFN_LINEAR);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetTextureStageState(lpDevice, 0, D3DTSS_MAGFILTER, D3DTFG_LINEAR);
  ERROR_CHECK;

  renderer->lpdsZBuffer = lpdsZBuffer;
  renderer->lpdsTarget = lpdsTarget;
  renderer->lpDevice = lpDevice;
  return 1;

cleanup:
  RELEASE(lpdsZBuffer);
  RELEASE(lpdsTarget);
  RELEASE(lpDevice);
  return 0;
}

int d3dReleaseRenderer(d3dRenderer *renderer) {
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;

  lpDevice = renderer->lpDevice;
  /* Reset texture */
  hRes = lpDevice->lpVtbl->SetTexture(lpDevice, 0, NULL);
  ERROR_CHECK;
  /* And release interfaces */
  RELEASE(renderer->lpDevice);
  RELEASE(renderer->lpdsZBuffer);
  RELEASE(renderer->lpdsTarget);
  renderer->fUsed = 0;
  /* and unregister exposed surface */
  if(renderer->surfaceID >= 0)
    (*unregisterSurface)(renderer->surfaceID);
  renderer->fUsed = 0;
  return 1;
}
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int d3dDestroyRenderer(int handle) {
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 1; /* already destroyed */
  d3dReleaseRenderer(renderer);
  return 1;
}

#define SUPPORTED_FLAGS (\
    B3D_HARDWARE_RENDERER \
  | B3D_SOFTWARE_RENDERER)

int d3dCreateRendererFlags(int x, int y, int w, int h, int flags) {
  int i, index;
  d3dRenderer *renderer;

  if(flags & ~SUPPORTED_FLAGS) {
    DPRINTF3D(1, (fp, "ERROR: Unsupported flags requested( %d)\n", flags));
    return -1;
  }

  DPRINTF3D(3, (fp, "---- Initializing D3D ----\n"));
  for(i=0; i < MAX_RENDERER; i++) {
    if(allRenderer[i].fUsed == 0) break;
  }
  if(i >= MAX_RENDERER) {
    DPRINTF3D(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
    return -1;
  }
  index = i;
  renderer = allRenderer+index;
  memset(renderer, 0, sizeof(d3dRenderer));
  renderer->surfaceID = -1;
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;
  renderer->devFlags = flags;
  if(!d3dInitializePrimary()) {
    /* disable DX if we cannot create the primary objects */
    fDirectXEnable = 0;
    return -1;
  }
  /* create and initialize the renderer */
  if(!d3dInitializeRenderer(renderer)) {
    return -1;
  }
  /* register the exposed surface */
  if(!(*registerSurface)((sqIntptr_t)renderer->lpdsTarget, 
			 &d3dTargetDispatch, &renderer->surfaceID)) {
    d3dReleaseRenderer(renderer);
    DPRINTF3D(1,(fp,"ERROR: Failed to register rendering target\n"));
    return -1;
  }
  /* all fine now */
  renderer->fUsed = 1;
  return index;
}

int d3dGetRendererSurfaceHandle(int handle) {
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return -1;
  return renderer->surfaceID;
}

/* convenience function */
static DDSURFACEDESC2 *d3dGetRendererDesc(int handle) {
  static DDSURFACEDESC2 desc;
  LPDIRECTDRAWSURFACE7 lpdsTarget;
  HRESULT hRes;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return NULL;
  /* Check if the renderer was registered as a valid display surface.
     Note: This information could be obtained from the renderer 
     directly but it's safer to see if the surface has really been
     registered. */
  if(!(*findSurface)(renderer->surfaceID, &d3dTargetDispatch, (sqIntptr_t*) (&lpdsTarget))) {
    return NULL;
  }
  /* But make sure we're talking about the right surface here */
  if(lpdsTarget != renderer->lpdsTarget) {
    return NULL;
  }

  desc.dwSize = sizeof(desc);
  hRes = lpdsTarget->lpVtbl->GetSurfaceDesc(lpdsTarget, &desc);
  ERROR_CHECK;
  return &desc;
}

int d3dGetRendererSurfaceWidth(int handle) {
  DDSURFACEDESC2 *desc = d3dGetRendererDesc(handle);
  if(!desc) return -1;
  return desc->dwWidth;
}

int d3dGetRendererSurfaceHeight(int handle) {
  DDSURFACEDESC2 *desc = d3dGetRendererDesc(handle);
  if(!desc) return -1;
  return desc->dwHeight;
}

int d3dGetRendererSurfaceDepth(int handle) {
  DDSURFACEDESC2 *desc = d3dGetRendererDesc(handle);
  if(!desc) return -1;
  return desc->ddpfPixelFormat.dwRGBBitCount;
}

int d3dGetRendererColorMasks(int handle, int *masks) {
  DDSURFACEDESC2 *desc = d3dGetRendererDesc(handle);
  if(!desc) return 0;

  masks[0] = desc->ddpfPixelFormat.dwRBitMask;
  masks[1] = desc->ddpfPixelFormat.dwGBitMask;
  masks[2] = desc->ddpfPixelFormat.dwBBitMask;
  masks[3] = desc->ddpfPixelFormat.dwRGBAlphaBitMask;
  return 1;

}

int d3dIsOverlayRenderer(int handle) {
  /* all D3D rendering is done offscreen */
  return 0;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int d3dSetVerboseLevel(int level) {
  verboseLevel = level;
  return 1;
}

int d3dSetBufferRect(int handle, int x, int y, int w, int h) {
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  /* do not allow resizing offscreen buffers */
  if( (renderer->bufferRect[2] != w) || (renderer->bufferRect[3] != h) )
    return 0;
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;
  return 1;
}

int d3dGetIntProperty(int handle, int prop)
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;
  DWORD dwState;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;

  lpDevice = renderer->lpDevice;

  switch(prop) {
  case 1: /* backface culling */
    hRes = lpDevice->lpVtbl->
      GetRenderState(lpDevice, D3DRENDERSTATE_CULLMODE , &dwState);
    ERROR_CHECK;
    if(dwState == D3DCULL_NONE) return 0;
    if(dwState == D3DCULL_CW) return 1;
    if(dwState == D3DCULL_CCW) return -1;
    return 0;
  case 2: /* polygon mode */
    hRes = lpDevice->lpVtbl->
      GetRenderState(lpDevice, D3DRENDERSTATE_FILLMODE, &dwState);
    ERROR_CHECK;
    if(dwState == D3DFILL_SOLID) return 0;
    if(dwState == D3DFILL_WIREFRAME) return 1;
    if(dwState == D3DFILL_POINT) return 2;
    return 0;
  case 3: /* point size */
    return 1;
  case 4: /* line width */
    return 1;
  case 5: /* blend enable */
     hRes = lpDevice->lpVtbl->
      GetRenderState(lpDevice, D3DRENDERSTATE_ALPHABLENDENABLE, &dwState);
     ERROR_CHECK;
     return dwState;
  case 6: /* blend source factor */
  case 7: /* blend dest factor */
    if(prop == 6) {
      hRes = lpDevice->lpVtbl->
	GetRenderState(lpDevice, D3DRENDERSTATE_SRCBLEND, &dwState);
    } else {
      hRes = lpDevice->lpVtbl->
	GetRenderState(lpDevice, D3DRENDERSTATE_DESTBLEND, &dwState);
    }
    ERROR_CHECK;
    switch(dwState) {
        case D3DBLEND_ZERO: return 0;
        case D3DBLEND_ONE: return 1;
        case D3DBLEND_SRCCOLOR: return 2;
        case D3DBLEND_INVSRCCOLOR: return 3;
        case D3DBLEND_DESTCOLOR: return 4;
        case D3DBLEND_INVDESTCOLOR: return 5;
        case D3DBLEND_SRCALPHA: return 6;
        case D3DBLEND_INVSRCALPHA: return 7;
        case D3DBLEND_DESTALPHA: return 8;
        case D3DBLEND_INVDESTALPHA: return 9;
        case D3DBLEND_SRCALPHASAT: return 10;
        default: return -1;
      }
  }
  return 0;
}

int d3dSetIntProperty(int handle, int prop, int value)
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;
  DWORD dwState;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;

  lpDevice = renderer->lpDevice;

  switch(prop) {
  case 1: /* backface culling */
    dwState = 0;
    if(value == 0) dwState = D3DCULL_NONE;
    if(value == 1) dwState = D3DCULL_CW;
    if(value == -1)dwState = D3DCULL_CCW;
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_CULLMODE , dwState);
    ERROR_CHECK;
    return 1;
  case 2: /* polygon mode */
    if(value == 0) dwState = D3DFILL_SOLID;
    if(value == 1) dwState = D3DFILL_WIREFRAME;
    if(value == 2) dwState = D3DFILL_POINT;
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_FILLMODE, dwState);
    ERROR_CHECK;
    return 1;
  case 3: /* point size */
    return 1;
  case 4: /* line width */
    return 1;
  case 5: /* blend enable */
    dwState = value ? TRUE : FALSE;
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_ALPHABLENDENABLE, dwState);
    ERROR_CHECK;
    return 1;
  case 6: /* blend source factor */
  case 7: /* blend dest factor */
      switch(value) {
        case 0: dwState = D3DBLEND_ZERO; break;
        case 1: dwState = D3DBLEND_ONE; break;
        case 2: dwState = D3DBLEND_SRCCOLOR; break;
        case 3: dwState = D3DBLEND_INVSRCCOLOR; break;
        case 4: dwState = D3DBLEND_DESTCOLOR; break;
        case 5: dwState = D3DBLEND_INVDESTCOLOR; break;
        case 6: dwState = D3DBLEND_SRCALPHA; break;
        case 7: dwState = D3DBLEND_INVSRCALPHA; break;
        case 8: dwState = D3DBLEND_DESTALPHA; break;
        case 9: dwState = D3DBLEND_INVDESTALPHA; break;
        case 10: dwState = D3DBLEND_SRCALPHASAT; break;
        default: return 0;
      }
      if(prop == 6) {
	hRes = lpDevice->lpVtbl->
	  SetRenderState(lpDevice, D3DRENDERSTATE_SRCBLEND, dwState);
      } else {
	hRes = lpDevice->lpVtbl->
	  SetRenderState(lpDevice, D3DRENDERSTATE_DESTBLEND, dwState);
      }
      ERROR_CHECK;
      return 1;
  }
  return 0;
}
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

/* texture support */
int d3dAllocateTexture(int handle, int w, int h, int d) /* return handle or -1 on error */
{
  HRESULT hRes;
  DDSURFACEDESC2 ddsd;
  LPDIRECT3DDEVICE7 lpDevice;
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  int surfaceID = -1;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  lpDevice = renderer->lpDevice;

  if(w & (w-1)) return -1; /* not power of two */
  if(h & (h-1)) return -1; /* not power of two */
  DPRINTF3D(5, (fp, "### Allocating new texture (w = %d, h = %d, d = %d)\n", w, h, d));

  /* fill in basic surface structure */
  ZeroMemory( &ddsd, sizeof(DDSURFACEDESC2) );
  ddsd.dwSize          = sizeof(DDSURFACEDESC2);
  ddsd.dwFlags         = 
    DDSD_CAPS|DDSD_HEIGHT|DDSD_WIDTH|DDSD_PIXELFORMAT|DDSD_TEXTURESTAGE;
  ddsd.ddsCaps.dwCaps  = DDSCAPS_TEXTURE;
  ddsd.dwWidth         = w;
  ddsd.dwHeight        = h;

  /* fill in pixel format */
  if(renderer->fTextureFound8x8x8x8) {
    ddsd.ddpfPixelFormat = renderer->ddpfTextureFormat8x8x8x8;
  } else if(renderer->fTextureFound4x4x4x4) {
    ddsd.ddpfPixelFormat = renderer->ddpfTextureFormat4x4x4x4;
  } else if(renderer->fTextureFound0x8x8x8) {
    ddsd.ddpfPixelFormat = renderer->ddpfTextureFormat0x8x8x8;
  } else return -1;

  /* enable texture management */
  if(renderer->ddDesc.dwDevCaps & D3DDEVCAPS_HWRASTERIZATION)
    ddsd.ddsCaps.dwCaps2 = DDSCAPS2_TEXTUREMANAGE;
  else
    ddsd.ddsCaps.dwCaps |= DDSCAPS_SYSTEMMEMORY;

  /* create texture surface */
  hRes = lpDD->lpVtbl->CreateSurface(lpDD, &ddsd, &lpdsTexture, NULL);
  ERROR_CHECK;
  if(FAILED(hRes)) {
    return -1;
  }

  /* register texture */
  if(!(*registerSurface)((sqIntptr_t)lpdsTexture, &d3dTextureDispatch, &surfaceID)) {
    RELEASE(lpdsTexture);
    DPRINTF3D(1,(fp,"ERROR: Failed to register texture\n"));
    return -1;
  }
  return surfaceID;
}

int d3dDestroyTexture(int rendererHandle, int handle) /* return true on success, false on error */
{
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  LPDIRECT3DDEVICE7 lpDevice;
  d3dRenderer *renderer = d3dRendererFromHandle(rendererHandle);

  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  /* Look if the surface was registered as D3D surface */
  if(!(*findSurface)(handle, &d3dTextureDispatch, (sqIntptr_t*) (&lpdsTexture)))
    return 0;

  /* release and unregister texture */
  lpDevice->lpVtbl->SetTexture(lpDevice, 0, NULL);
  RELEASE(lpdsTexture);
  (*unregisterSurface)(handle);
  return 1;
}

int d3dActualTextureDepth(int rendererHandle, int handle) /* return depth or <0 on error */
{
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  DDSURFACEDESC2 desc;
  HRESULT hRes;
  /* Look if the surface was registered as D3D surface */
  if(!(*findSurface)(handle, &d3dTextureDispatch, (sqIntptr_t*) (&lpdsTexture)))
    return -1;
  desc.dwSize = sizeof(desc);
  hRes = lpdsTexture->lpVtbl->GetSurfaceDesc(lpdsTexture, &desc);
  if(FAILED(hRes)) {
    return -1;
  }
  return desc.ddpfPixelFormat.dwRGBBitCount;
}

int d3dTextureColorMasks(int rendererHandle, int handle, int masks[4])  /* return true on success, false on error */
{
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  DDSURFACEDESC2 desc;
  HRESULT hRes;
  /* Look if the surface was registered as D3D surface */
  if(!(*findSurface)(handle, &d3dTextureDispatch, (sqIntptr_t*) (&lpdsTexture)))
    return 0;
  desc.dwSize = sizeof(desc);
  hRes = lpdsTexture->lpVtbl->GetSurfaceDesc(lpdsTexture, &desc);
  ERROR_CHECK;
  masks[0] = desc.ddpfPixelFormat.dwRBitMask;
  masks[1] = desc.ddpfPixelFormat.dwGBitMask;
  masks[2] = desc.ddpfPixelFormat.dwBBitMask;
  masks[3] = desc.ddpfPixelFormat.dwRGBAlphaBitMask;
  return 1;
}

int d3dTextureByteSex(int rendererHandle, int handle) /* return > 0 if MSB, = 0 if LSB, < 0 if error */
{
  return 0;
}

int d3dTextureSurfaceHandle(int rendererHandle, int handle) {
  /* d3dTextures alias the texture and the surface handle */
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  /* Look if the surface was registered as D3D surface */
  if(!(*findSurface)(handle, &d3dTextureDispatch, (sqIntptr_t*) (&lpdsTexture))) {
    DPRINTF3D(3, (fp, "WARNING: Texture (%d) not registered\n", handle));
    return -1;
  }
  return handle;
}

/* following fails since we support direct blitting to texture surfaces */
int d3dUploadTexture(int rendererHandle, int handle, int w, int h, int d, void* bits)
{
  return 1;
}

/* following fails since we support direct blitting to render target */
int d3dCompositeTexture(int rendererHandle, int handle, int x, int y, int w, int h, int translucent)
{
  return 1;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int d3dSetViewport(int handle, int x, int y, int w, int h) /* return true on success, false on error */
{
  HRESULT hRes;
  D3DVIEWPORT7 d3dViewport;
  LPDIRECT3DDEVICE7 lpDevice;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  DPRINTF3D(5, (fp, "### New Viewport\n"));
  DPRINTF3D(5, (fp, "\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));
  renderer->viewport[0] = x;
  renderer->viewport[1] = y;
  renderer->viewport[2] = w;
  renderer->viewport[3] = h;
  x -= renderer->bufferRect[0];
  y -= renderer->bufferRect[1];
  d3dViewport.dwX = x;
  d3dViewport.dwY = y;
  d3dViewport.dwWidth = w;
  d3dViewport.dwHeight = h;
  d3dViewport.dvMinZ = 0;
  d3dViewport.dvMaxZ = 1;
  hRes = lpDevice->lpVtbl->SetViewport(lpDevice, &d3dViewport);
  ERROR_CHECK;
  return 1;
}

int d3dClearDepthBuffer(int handle)/* return true on success, false on error */
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;
  hRes = lpDevice->lpVtbl->Clear(lpDevice, 0, NULL, D3DCLEAR_ZBUFFER, 
				 0, 1.0, 0);
  ERROR_CHECK;
  return 1;
}

int d3dClearViewport(int handle, unsigned int rgba, unsigned int pv) /* return true on success, false on error */
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;
  hRes = lpDevice->lpVtbl->Clear(lpDevice, 0, NULL, D3DCLEAR_TARGET, 
				 rgba, 0.0, 0);
  ERROR_CHECK;
  return 1;
}

int d3dFinishRenderer(int handle) /* return true on success, false on error */
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;
  LPDIRECTDRAWSURFACE7 lpdsTarget;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;
  lpdsTarget = renderer->lpdsTarget;

  if(renderer->fSceneStarted) {
    DPRINTF3D(5,(fp,"Ending current scene\n"));
    hRes = lpDevice->lpVtbl->EndScene(lpDevice);
    ERROR_CHECK;
    renderer->fSceneStarted = 0;
  }
  do {
    hRes = lpdsTarget->lpVtbl->GetBltStatus(lpdsTarget, DDGBS_ISBLTDONE);
  } while(hRes == DDERR_WASSTILLDRAWING);
  ERROR_CHECK;
  return 1;
}

int d3dFlushRenderer(int handle) /* return true on success, false on error */
{
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  if(renderer->fSceneStarted) {
    DPRINTF3D(5,(fp,"Ending current scene\n"));
    hRes = lpDevice->lpVtbl->EndScene(lpDevice);
    ERROR_CHECK;
    renderer->fSceneStarted = 0;
  }
  return 1;
}

int d3dSwapRendererBuffers(int handle) /* return true on success, false on error */
{
  LPDIRECTDRAWSURFACE7 lpddSurface;
  HRESULT hRes;
  RECT dxRect;
  RECT dstRect;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  int x, y, w, h;

  if(!renderer) return 0;

  /* make sure scene has ended */
  if(renderer->fSceneStarted)
    d3dFinishRenderer(handle);
  lpddSurface = renderer->lpdsTarget;
  x = renderer->bufferRect[0];
  y = renderer->bufferRect[1];
  w = renderer->bufferRect[2];
  h = renderer->bufferRect[3];

  /* Check the clip status.

     NOTE: Using a clipper is usually a simple way to ensure 
     that we don't draw over any occluded areas. It is, however,
     also quite a bit slower since we cannot use BltFast
     if a clipper is attached to the primary surface.
     (BltFast is on my machine about a factor of two faster).
     Thus, we're trying to do a smart check to see if clipping
     is actually required. Later on we might do this check
     only occasionally, in particular if we're running in
     full screen mode.

  */
  if(fUseSmartClipper /* && fUpdateClipper */) {
    static DWORD dwSize = 1024;
    static char clb[1024];
    static LPRGNDATA rgnData = (LPRGNDATA) clb;

    /* Query the current clip list */
    hRes = lpddClipper->lpVtbl->
      GetClipList(lpddClipper, NULL, rgnData, &dwSize);
    if(hRes == DD_OK) {
      /* Check if the clip list has no entry (e.g., entire region invisible) */
      if(rgnData->rdh.nCount == 0)
	return 1;
      /* Check if the clip list has one entry.
	 If so, detach the clipper so we can use BltFast */
      if(rgnData->rdh.nCount > 1) {
	/* More than one entry -- attach the clipper */
	if(!fClipperAttached) {
	  hRes = lpddPrimary->lpVtbl->SetClipper(lpddPrimary, lpddClipper);
	  if(FAILED(hRes)) {
	    DPRINTF3D(2,(fp,"WARNING: Failed to attach clipper (errCode=%lX)\n",hRes));
	  } else {
	    fClipperAttached = 1;
	  }
	}
      } else {
	/* One entry. Detach the clipper. */
	if(fClipperAttached) {
	  hRes = lpddPrimary->lpVtbl->SetClipper(lpddPrimary, NULL);
	  if(FAILED(hRes)) {
	    DPRINTF3D(2,(fp,"WARNING: Failed to detach clipper (errCode=%lX)\n",hRes));
	  } else {
	    fClipperAttached = 0;
	  }
	}
      }
    } else if(hRes == DDERR_REGIONTOOSMALL && !fClipperAttached) {
      /* We have no clipper but the region is too small
	 (meaning there's lots of stuff to clip). Attach it. */
      hRes = lpddPrimary->lpVtbl->SetClipper(lpddPrimary, lpddClipper);
      if(FAILED(hRes)) {
	DPRINTF3D(2,(fp,"WARNING: Failed to attach clipper (errCode=%lX)\n",hRes));
      } else {
	fClipperAttached = 1;
      }
    } else return 0;
    /* After detaching the clipper, set the affected region so
       we don't accidentally blt outside the window */
    if(rgnData->rdh.nCount == 1 && !fClipperAttached) {
      int dx, dy;
      /* Compute the inset of clip rect into stWindowRect */
      dx = rgnData->rdh.rcBound.left - stWindowRect.left;
      dy = rgnData->rdh.rcBound.top - stWindowRect.top;
      if(x < dx) x = dx;
      if(y < dy) y = dy;
      /* Compute the distance of the clip rect from stWindowRect origin */
      dx = rgnData->rdh.rcBound.right - stWindowRect.left;
      dy = rgnData->rdh.rcBound.bottom - stWindowRect.top;
      if((x+w) > dx) w = dx-x;
      if((y+h) > dy) h = dy-y;
    }
    fUpdateClipper = 0; /* wait until something happens */
  }

  /* Finally, copy the stuff out */
#if 0
  dxRect.left = x;
  dxRect.right = x+w;
  dxRect.top = y;
  dxRect.bottom = y+h;
#else
  dxRect.left = 0;
  dxRect.right = w;
  dxRect.top = 0;
  dxRect.bottom = h;
#endif

  if(fExclusive) {
    /* Exclusive means fullscreen */
    dstRect.left   = x;
    dstRect.top    = y;
    dstRect.right  = x + w;
    dstRect.bottom = y + h;
  } else {
    dstRect.left   = stWindowRect.left + x;
    dstRect.top    = stWindowRect.top  + y;
    dstRect.right  = stWindowRect.left + x + w;
    dstRect.bottom = stWindowRect.top  + y + h;
  }
  if(!fClipperAttached) {
    /* No clipper attached. We can use the BltFast method
       which is usually quite a bit faster than anything else. */
    hRes = lpddPrimary->lpVtbl->
      BltFast(lpddPrimary, dstRect.left, dstRect.top, 
	      lpddSurface, &dxRect, DDBLTFAST_WAIT | DDBLTFAST_NOCOLORKEY);
    if(FAILED(hRes)) {
      DPRINTF3D(2,(fp,"WARNING: IDirectDrawSurface::BltFast() failed (errCode=%lX)\n",hRes));
    }
  }
  if(fClipperAttached || FAILED(hRes)) {
    /* If we have a clipper attached or BltFast went
       wrong do it the normal way. */
    hRes = lpddPrimary->lpVtbl->
      Blt(lpddPrimary,&dstRect,lpddSurface, &dxRect, DDBLT_WAIT, NULL);
  }
  if(FAILED(hRes)) {
    DPRINTF3D(1,(fp,"ERROR: Failed to blt to primary surface (errCode=%lX)\n",hRes));
    return 0;
  }
#if 0
  /* Wait until the blt completed */
  do {
    hRes = lpddSurface->lpVtbl->GetBltStatus(lpddSurface, DDGBS_ISBLTDONE);
  } while(hRes == DDERR_WASSTILLDRAWING);
  if(FAILED(hRes)) return hRes;
#endif
  return 1;
}

static D3DMATRIX d3dIdentity = {
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
};

int d3dSetTransform(int handle, float *modelViewMatrix, float *projectionMatrix) {
  HRESULT hRes;
  LPDIRECT3DDEVICE7 lpDevice;
  D3DMATRIX d;
  float *m;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);
  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  DPRINTF3D(5, (fp, "### Installing new transformations\n"));
  if(modelViewMatrix) {
    m = modelViewMatrix;
    d._11 = *m++; d._21 = *m++; d._31 = *m++; d._41 = *m++;
    d._12 = *m++; d._22 = *m++; d._32 = *m++; d._42 = *m++;
    d._13 = *m++; d._23 = *m++; d._33 = *m++; d._43 = *m++;
    d._14 = *m++; d._24 = *m++; d._34 = *m++; d._44 = *m++;
  } else {
    d = d3dIdentity;
  }
  hRes = lpDevice->lpVtbl->
    SetTransform(lpDevice, D3DTRANSFORMSTATE_WORLD, &d);
  ERROR_CHECK;

  if(projectionMatrix) {
    m = projectionMatrix;
    d._11 = *m++; d._21 = *m++; d._31 = *m++; d._41 = *m++;
    d._12 = *m++; d._22 = *m++; d._32 = *m++; d._42 = *m++;
    d._13 = *m++; d._23 = *m++; d._33 = *m++; d._43 = *m++;
    d._14 = *m++; d._24 = *m++; d._34 = *m++; d._44 = *m++;
  } else {
    d = d3dIdentity;
  }
  hRes = lpDevice->lpVtbl->
    SetTransform(lpDevice, D3DTRANSFORMSTATE_PROJECTION, &d);
  ERROR_CHECK;
#if 0
  DPRINTF3D(1, (fp, "Projection matrix before:\n"));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._11, d._12,d._13,d._14));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._21, d._22,d._23,d._24));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._31, d._32,d._33,d._34));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._41, d._42,d._43,d._44));
  hRes = lpDevice->lpVtbl->
    GetTransform(lpDevice, D3DTRANSFORMSTATE_PROJECTION, &d);
  ERROR_CHECK;
  DPRINTF3D(1, (fp, "Projection matrix after:\n"));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._11, d._12,d._13,d._14));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._21, d._22,d._23,d._24));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._31, d._32,d._33,d._34));
  DPRINTF3D(1, (fp, "\t%g\t%g\t%g\t%g\n", d._41, d._42,d._43,d._44));
#endif
  return 1;
}

int d3dDisableLights(int handle) {
  LPDIRECT3DDEVICE7 lpDevice;
  HRESULT hRes;
  int i;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);

  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;
  DPRINTF3D(5, (fp, "### Disabling all lights\n"));
  
  for(i = 0; i <= renderer->maxLights; i++) {
    hRes = lpDevice->lpVtbl->LightEnable(lpDevice, i, FALSE);
    ERROR_CHECK;
  }
  renderer->maxLights = -1;
  return 1;
}

int d3dLoadMaterial(int handle, B3DPrimitiveMaterial *mat)
{
  HRESULT hRes;
  D3DMATERIAL7 d3dMat;
  LPDIRECT3DDEVICE7 lpDevice;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);

  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  DPRINTF3D(5, (fp, "### New Material\n"));
  if(!mat) {
    DPRINTF3D(5, (fp, "\tOFF (material == nil)\n"));
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_LIGHTING, FALSE);
    ERROR_CHECK;
    return 1;
  }
  DPRINTF3D(5, (fp, "\tambient  : %g, %g, %g, %g\n",
	      mat->ambient[0], mat->ambient[1], 
	      mat->ambient[2], mat->ambient[3]));
  DPRINTF3D(5, (fp, "\tdiffuse  : %g, %g, %g, %g\n",
	      mat->diffuse[0], mat->diffuse[1], 
	      mat->diffuse[2], mat->diffuse[3]));
  DPRINTF3D(5, (fp, "\tspecular : %g, %g, %g, %g\n",
	      mat->specular[0], mat->specular[1], 
	      mat->specular[2], mat->specular[3]));
  DPRINTF3D(5, (fp, "\temission : %g, %g, %g, %g\n",
	      mat->emission[0], mat->emission[1], 
	      mat->emission[2], mat->emission[3]));
  DPRINTF3D(5, (fp, "\tshininess: %g\n", mat->shininess));

  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_LIGHTING, TRUE);

  d3dMat.ambient.r = mat->ambient[0];
  d3dMat.ambient.g = mat->ambient[1];
  d3dMat.ambient.b = mat->ambient[2];
  d3dMat.ambient.a = mat->ambient[3];
  d3dMat.diffuse.r = mat->diffuse[0];
  d3dMat.diffuse.g = mat->diffuse[1];
  d3dMat.diffuse.b = mat->diffuse[2];
  d3dMat.diffuse.a = mat->diffuse[3];
  d3dMat.specular.r = mat->specular[0];
  d3dMat.specular.g = mat->specular[1];
  d3dMat.specular.b = mat->specular[2];
  d3dMat.specular.a = mat->specular[3];
  d3dMat.emissive.r = mat->emission[0];
  d3dMat.emissive.g = mat->emission[1];
  d3dMat.emissive.b = mat->emission[2];
  d3dMat.emissive.a = mat->emission[3];
  d3dMat.power = mat->shininess;

  hRes = lpDevice->lpVtbl->SetMaterial(lpDevice, &d3dMat);
  ERROR_CHECK;
  return 1;
}

int d3dLoadLight(int handle, int idx, B3DPrimitiveLight *light)
{
  D3DLIGHT7 d3dLight;
  LPDIRECT3DDEVICE7 lpDevice;
  D3DMATRIX m;
  HRESULT hRes;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);

  if(!renderer) return 0;
  if(idx < 0) return 0;
  lpDevice = renderer->lpDevice;

  DPRINTF3D(5, (fp, "### New Light (%d)\n", idx));

  if(!light) {
    DPRINTF3D(5, (fp, "\tDISABLED\n"));
    hRes = lpDevice->lpVtbl->LightEnable(lpDevice, idx, FALSE);
    ERROR_CHECK;
    return 1;
  }

  if(idx > renderer->maxLights) renderer->maxLights = idx;

  DPRINTF3D(5, (fp, "\tambient       : %g, %g, %g, %g\n",
	      light->ambient[0], light->ambient[1], 
	      light->ambient[2], light->ambient[3]));
  DPRINTF3D(5, (fp, "\tdiffuse       : %g, %g, %g, %g\n",
	      light->diffuse[0], light->diffuse[1], 
	      light->diffuse[2], light->diffuse[3]));
  DPRINTF3D(5, (fp, "\tspecular      : %g, %g, %g, %g\n",
	      light->specular[0], light->specular[1], 
	      light->specular[2], light->specular[3]));
  DPRINTF3D(5, (fp, "\tposition      : %g, %g, %g\n",
	      light->position[0], light->position[1], light->position[2]));
  DPRINTF3D(5, (fp, "\tdirection     : %g, %g, %g\n",
	      light->direction[0], light->direction[1], light->direction[2]));
  DPRINTF3D(5, (fp, "\tattenuation   : %g, %g, %g\n",
	      light->attenuation[0], light->attenuation[1], 
	      light->attenuation[2]));
  DPRINTF3D(5, (fp, "\tflags [%d]:", light->flags));
  if(light->flags & B3D_LIGHT_AMBIENT) 
    DPRINTF3D(5,(fp," B3D_LIGHT_AMBIENT"));
  if(light->flags & B3D_LIGHT_DIFFUSE) 
    DPRINTF3D(5,(fp," B3D_LIGHT_DIFFUSE"));
  if(light->flags & B3D_LIGHT_SPECULAR) 
    DPRINTF3D(5,(fp," B3D_LIGHT_SPECULAR"));
  if(light->flags & B3D_LIGHT_POSITIONAL) 
    DPRINTF3D(5,(fp," B3D_LIGHT_POSITIONAL"));
  if(light->flags & B3D_LIGHT_DIRECTIONAL) 
    DPRINTF3D(5,(fp," B3D_LIGHT_DIRECTIONAL"));
  if(light->flags & B3D_LIGHT_ATTENUATED) 
    DPRINTF3D(5,(fp," B3D_LIGHT_ATTENUATED"));
  if(light->flags & B3D_LIGHT_HAS_SPOT) 
    DPRINTF3D(5,(fp," B3D_LIGHT_HAS_SPOT"));
  DPRINTF3D(5, (fp, "\n"));
  DPRINTF3D(5, (fp, "\tspot exponent : %g\n", light->spotExponent));

  DPRINTF3D(5, (fp, "### Installing Light (%d)\n", idx));
  memset(&d3dLight, 0, sizeof(d3dLight));
  if(light->flags & B3D_LIGHT_AMBIENT) {
    DPRINTF3D(5, (fp, "\tambient  : %g, %g, %g, %g\n",
		light->ambient[0], light->ambient[1], 
		light->ambient[2], light->ambient[3]));
    d3dLight.dcvAmbient.r = light->ambient[0];
    d3dLight.dcvAmbient.g = light->ambient[1];
    d3dLight.dcvAmbient.b = light->ambient[2];
    d3dLight.dcvAmbient.a = light->ambient[3];
  } else {
    DPRINTF3D(5, (fp, "\tambient  : OFF (0, 0, 0, 1)\n"));
  }

  if(light->flags & B3D_LIGHT_DIFFUSE) {
    DPRINTF3D(5, (fp, "\tdiffuse  : %g, %g, %g, %g\n",
		light->diffuse[0], light->diffuse[1], 
		light->diffuse[2], light->diffuse[3]));
    d3dLight.dcvDiffuse.r = light->diffuse[0];
    d3dLight.dcvDiffuse.g = light->diffuse[1];
    d3dLight.dcvDiffuse.b = light->diffuse[2];
    d3dLight.dcvDiffuse.a = light->diffuse[3];
  } else {
    DPRINTF3D(5, (fp, "\tdiffuse  : OFF (0, 0, 0, 1)\n"));
  }

  if(light->flags & B3D_LIGHT_SPECULAR) {
    DPRINTF3D(5, (fp, "\tspecular : %g, %g, %g, %g\n",
		light->specular[0], light->specular[1], 
		light->specular[2], light->specular[3]));
    d3dLight.dcvSpecular.r = light->specular[0];
    d3dLight.dcvSpecular.g = light->specular[1];
    d3dLight.dcvSpecular.b = light->specular[2];
    d3dLight.dcvSpecular.a = light->specular[3];
  } else {
    DPRINTF3D(5, (fp, "\tspecular : OFF (0, 0, 0, 1)\n"));
  }

  if(light->flags & B3D_LIGHT_POSITIONAL) {
    DPRINTF3D(5, (fp, "\tposition : %g, %g, %g\n",
		light->position[0], light->position[1], light->position[2]));
    d3dLight.dltType = D3DLIGHT_POINT;
    d3dLight.dvPosition.x = light->position[0];
    d3dLight.dvPosition.y = light->position[1];
    d3dLight.dvPosition.z = light->position[2];
  } else {
    if(light->flags & B3D_LIGHT_DIRECTIONAL) {
      DPRINTF3D(5, (fp, "\tdirection: %g, %g, %g\n",
		  light->direction[0], light->direction[1], 
		  light->direction[2]));
      d3dLight.dltType = D3DLIGHT_DIRECTIONAL;
      d3dLight.dvDirection.x = light->direction[0];
      d3dLight.dvDirection.y = light->direction[1];
      d3dLight.dvDirection.z = light->direction[2];
    }
  }

  if(light->flags & B3D_LIGHT_ATTENUATED) {
    DPRINTF3D(5, (fp, "\tattenuation: %g, %g, %g\n",
		light->attenuation[0], light->attenuation[1], 
		light->attenuation[2]));
    d3dLight.dvAttenuation0 = light->attenuation[0];
    d3dLight.dvAttenuation1 = light->attenuation[1];
    d3dLight.dvAttenuation2 = light->attenuation[2];
  } else {
    DPRINTF3D(5, (fp, "\tattenuation: OFF (1, 0, 0)\n"));
    d3dLight.dvAttenuation0 = 1.0;
  }

  if(light->flags & B3D_LIGHT_HAS_SPOT) {
    DPRINTF3D(5, (fp, "\tspot exponent : %g\n", light->spotExponent));
    DPRINTF3D(5, (fp, "\tspot cutoff   : ???\n"));
    DPRINTF3D(5, (fp, "\tspot direction: %g, %g, %g\n",
		light->direction[0], light->direction[1], 
		light->direction[2]));
    d3dLight.dltType = D3DLIGHT_SPOT;
    d3dLight.dvDirection.x = light->direction[0];
    d3dLight.dvDirection.y = light->direction[1];
    d3dLight.dvDirection.z = light->direction[2];
    d3dLight.dvFalloff = light->spotExponent;
    d3dLight.dvPhi = (float) acos(light->spotMinCos);
    d3dLight.dvTheta = (float) acos(light->spotMaxCos);
    DPRINTF3D(5, (fp, "\tdvPhi: %g\n", d3dLight.dvPhi));
    DPRINTF3D(5, (fp, "\tdvTheta: %g\n", d3dLight.dvTheta));
  }

  d3dLight.dvRange = D3DLIGHT_RANGE_MAX;
  /* Reset transform since Squeak pretransforms the light */
  hRes = lpDevice->lpVtbl->
    GetTransform(lpDevice, D3DTRANSFORMSTATE_WORLD, &m);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetTransform(lpDevice, D3DTRANSFORMSTATE_WORLD, &d3dIdentity);
  ERROR_CHECK;
  /* Set light parameters */
  hRes = lpDevice->lpVtbl->SetLight(lpDevice, idx, &d3dLight);
  ERROR_CHECK;
  /* Enable the light */
  hRes = lpDevice->lpVtbl->LightEnable(lpDevice, idx, TRUE);
  ERROR_CHECK;
  /* Install world transform again */
  hRes = lpDevice->lpVtbl->
    SetTransform(lpDevice, D3DTRANSFORMSTATE_WORLD, &m);
  ERROR_CHECK;
  return 1;
}

int d3dSetFog(int handle, int fogType, double density, 
              double fogRangeStart, double fogRangeEnd, int rgba) {
  LPDIRECT3DDEVICE7 lpDevice;
  HRESULT hRes;
  float floatValue;
  int pFog, vFog, rFog, wFog;
  DWORD fogMode;
  d3dRenderer *renderer = d3dRendererFromHandle(handle);

  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGTABLEMODE, D3DFOG_NONE);
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGENABLE, FALSE);
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGVERTEXMODE, D3DFOG_NONE);
  ERROR_CHECK;
  if(fogType == 0) {
    return 1;
  }
  /* figure out what we can use */
  /* pixel fog? */
  pFog = renderer->ddDesc.dpcTriCaps.dwRasterCaps & D3DPRASTERCAPS_FOGTABLE;
  /* vertex fog? */
  vFog = renderer->ddDesc.dpcTriCaps.dwRasterCaps & D3DPRASTERCAPS_FOGVERTEX;
  /* w-based fog? */
  wFog = renderer->ddDesc.dpcTriCaps.dwRasterCaps & D3DPRASTERCAPS_WFOG;
  /* range-based fog? */
  rFog = renderer->ddDesc.dpcTriCaps.dwRasterCaps & D3DPRASTERCAPS_FOGRANGE;

  if(!vFog && !pFog) return 0; /* neither vertex nor pixel fog */

  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGENABLE, TRUE);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGCOLOR, rgba);
  ERROR_CHECK;

  fogMode = D3DFOG_NONE;
  if(fogType == 1) fogMode = D3DFOG_LINEAR;
  if(fogType == 2) fogMode = D3DFOG_EXP;
  if(fogType == 3) fogMode = D3DFOG_EXP2;
  if(!pFog || (!wFog && fogType == 1)) {
    /* if we don't have pixel fog use vertex fog instead */
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_FOGVERTEXMODE, fogMode);
    /* but enable range based fog if available */
    if(rFog) {
      ERROR_CHECK;
      hRes = lpDevice->lpVtbl->
	SetRenderState(lpDevice, D3DRENDERSTATE_RANGEFOGENABLE, TRUE);
    }
  } else {
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, D3DRENDERSTATE_FOGTABLEMODE, fogMode);
  }
  ERROR_CHECK;
  floatValue = (float) fogRangeStart;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGSTART,*(DWORD*)(&floatValue));
  ERROR_CHECK;
  floatValue = (float) fogRangeEnd;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGEND,*(DWORD*)(&floatValue));
  ERROR_CHECK;
  floatValue = (float) density;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_FOGDENSITY,*(DWORD*)(&floatValue));
  ERROR_CHECK;
  return 1;
}

/* General dummy for Squeak's primitive faces */
typedef int B3DInputFace;

int d3dRenderVertexBuffer(int handle, int primType, int flags, int texHandle, float *vtxArray, int vtxSize, int *idxArray, int idxSize)
{
  B3DPrimitiveVertex *vtxPointer = (B3DPrimitiveVertex*) vtxArray;
  B3DInputFace *facePtr = (B3DInputFace*) idxArray;
  D3DDRAWPRIMITIVESTRIDEDDATA d3dStrideData;
  LPDIRECT3DDEVICE7 lpDevice;
  LPDIRECTDRAWSURFACE7 lpdsTexture;
  HRESULT hRes;

  int tracking;
  int nVertices = vtxSize;
  int nFaces = 0;
  int i, vtxFlags;
  unsigned short *idxPtr = (unsigned short*)idxArray;

  d3dRenderer *renderer = d3dRendererFromHandle(handle);

  if(!renderer) return 0;
  lpDevice = renderer->lpDevice;

  if(!renderer->fSceneStarted) {
    hRes = lpDevice->lpVtbl->BeginScene(lpDevice);
    if(FAILED(hRes)) {
      return 0;
    }
    renderer->fSceneStarted = 1;
  }

  DPRINTF3D(5, (fp,"### Primitive : %d\n", primType));
  DPRINTF3D(5, (fp,"\ttexHandle   : %d\n", texHandle));
  DPRINTF3D(5, (fp,"\tcolor flags :"));
  if(flags & B3D_VB_TRACK_AMBIENT) DPRINTF3D(5,(fp," B3D_VB_TRACK_AMBIENT"));
  if(flags & B3D_VB_TRACK_DIFFUSE) DPRINTF3D(5,(fp," B3D_VB_TRACK_DIFFUSE"));
  if(flags & B3D_VB_TRACK_SPECULAR) DPRINTF3D(5,(fp," B3D_VB_TRACK_SPECULAR"));
  if(flags & B3D_VB_TRACK_EMISSION) DPRINTF3D(5,(fp," B3D_VB_TRACK_EMISSION"));
  DPRINTF3D(5, (fp,"\n\tlight flags :"));
  if(flags & B3D_VB_LOCAL_VIEWER) DPRINTF3D(5,(fp," B3D_VB_LOCAL_VIEWER"));
  if(flags & B3D_VB_TWO_SIDED) DPRINTF3D(5,(fp," B3D_VB_TWO_SIDED"));
  DPRINTF3D(5, (fp,"\n\tvertex flags:"));
  if(flags & B3D_VB_HAS_NORMALS) DPRINTF3D(5,(fp," B3D_VB_HAS_NORMALS"));
  if(flags & B3D_VB_HAS_TEXTURES) DPRINTF3D(5,(fp," B3D_VB_HAS_TEXTURES"));
  DPRINTF3D(5, (fp, "\n"));

  /* process VB flags */
  tracking = FALSE;
  if(flags & B3D_VB_TRACK_AMBIENT) {
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, 
		     D3DRENDERSTATE_AMBIENTMATERIALSOURCE, 
		     D3DMCS_COLOR1);
    ERROR_CHECK;
    tracking = TRUE;
  }
  if(flags & B3D_VB_TRACK_DIFFUSE) {
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, 
		     D3DRENDERSTATE_DIFFUSEMATERIALSOURCE, 
		     D3DMCS_COLOR1);
    ERROR_CHECK;
    tracking = TRUE;
  }
  if(flags & B3D_VB_TRACK_SPECULAR) {
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, 
		     D3DRENDERSTATE_SPECULARMATERIALSOURCE, 
		     D3DMCS_COLOR1);
    ERROR_CHECK;
    tracking = TRUE;
  }
  if(flags & B3D_VB_TRACK_EMISSION) {
    hRes = lpDevice->lpVtbl->
      SetRenderState(lpDevice, 
		     D3DRENDERSTATE_EMISSIVEMATERIALSOURCE, 
		     D3DMCS_COLOR1);
    ERROR_CHECK;
    tracking = TRUE;
  }
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_COLORVERTEX, tracking);
  ERROR_CHECK;
  hRes = lpDevice->lpVtbl->
    SetRenderState(lpDevice, D3DRENDERSTATE_LOCALVIEWER,
		   (flags & B3D_VB_LOCAL_VIEWER) ? TRUE : FALSE);
  ERROR_CHECK;

  /* @@@ TODO: What about two-sided lighting? */

  if(texHandle >= 0 && (flags & B3D_VB_HAS_TEXTURES)) {
    /* Look if the surface was registered as D3D surface */
    if(!(*findSurface)(texHandle, &d3dTextureDispatch, (sqIntptr_t*) (&lpdsTexture))) {
      DPRINTF3D(4, (fp,"WARNING: Texture (%d) not registered\n", texHandle));
      lpdsTexture = NULL;
    }
  } else {
    lpdsTexture = NULL;
  }
  hRes = lpDevice->lpVtbl->SetTexture(lpDevice, 0, lpdsTexture);
  ERROR_CHECK;

  /* setup flexible vertex format flags */
  vtxFlags = D3DFVF_XYZ;
  if(tracking)
    vtxFlags |= D3DFVF_DIFFUSE;
  if(flags & B3D_VB_HAS_NORMALS)
    vtxFlags |= D3DFVF_NORMAL;
  if(flags & B3D_VB_HAS_TEXTURES)
    vtxFlags |= D3DFVF_TEX1 | D3DFVF_TEXCOORDSIZE2(0);

  /* fill in stride data */
  d3dStrideData.position.lpvData = vtxPointer->position;
  d3dStrideData.position.dwStride = sizeof(B3DPrimitiveVertex);
  d3dStrideData.normal.lpvData = vtxPointer->normal;
  d3dStrideData.normal.dwStride = sizeof(B3DPrimitiveVertex);
  d3dStrideData.diffuse.lpvData = &vtxPointer->pixelValue32;
  d3dStrideData.diffuse.dwStride = sizeof(B3DPrimitiveVertex);
  d3dStrideData.specular.lpvData = &vtxPointer->pixelValue32;
  d3dStrideData.specular.dwStride = sizeof(B3DPrimitiveVertex);
  for(i=0; i < D3DDP_MAXTEXCOORD; i++) {
    d3dStrideData.textureCoords[i].lpvData = vtxPointer->texCoord;
    d3dStrideData.textureCoords[i].dwStride = sizeof(B3DPrimitiveVertex);
  }

  /* now submit vertex buffer */
  switch(primType) {
  case 1: /* points */
    hRes = lpDevice->lpVtbl->
      DrawPrimitiveStrided(lpDevice, 
			   D3DPT_POINTLIST, 
			   vtxFlags, 
			   &d3dStrideData, 
			   nVertices, 
			   0);
    break;
  case 2: /* lines */
    hRes = lpDevice->lpVtbl->
      DrawPrimitiveStrided(lpDevice, 
			   D3DPT_LINELIST, 
			   vtxFlags, 
			   &d3dStrideData, 
			   nVertices, 
			   0);
    break;
  case 3: /* polygon */
    hRes = lpDevice->lpVtbl->
      DrawPrimitiveStrided(lpDevice, 
			   D3DPT_TRIANGLEFAN, 
			   vtxFlags, 
			   &d3dStrideData, 
			   nVertices, 
			   0);
    break;
  case 4: /* indexed lines */
    nFaces = idxSize / 2;
    for(i = 0; i < nFaces; i++) {
      B3DInputFace *face = facePtr + (2*i);
      if(face[0] && face[1]) {
	*idxPtr++ = face[0]-1;
	*idxPtr++ = face[1]-1;
      }
    }
    hRes = lpDevice->lpVtbl->
      DrawIndexedPrimitiveStrided(lpDevice, 
				  D3DPT_LINELIST, 
				  vtxFlags, 
				  &d3dStrideData,
				  nVertices,
				  (LPWORD)facePtr,
				  (LPWORD)idxPtr - (LPWORD)facePtr,
				  0);
    break;
  case 5: /* indexed triangles */
    nFaces = idxSize / 3;
    for(i = 0; i < nFaces; i++) {
      B3DInputFace *face = facePtr + (3*i);
      if(face[0] && face[1] && face[2]) {
	*idxPtr++ = face[0]-1;
	*idxPtr++ = face[1]-1;
	*idxPtr++ = face[2]-1;
      }
    }
    hRes = lpDevice->lpVtbl->
      DrawIndexedPrimitiveStrided(lpDevice, 
				  D3DPT_TRIANGLELIST, 
				  vtxFlags, 
				  &d3dStrideData,
				  nVertices,
				  (LPWORD)facePtr,
				  (LPWORD)idxPtr - (LPWORD)facePtr,
				  0);
    break;
  case 6: /* indexed quads */
    /* NOTE: Following fits into face array because idxPtr is short */
    nFaces = idxSize / 4;
    for(i = 0; i < nFaces; i++) {
      B3DInputFace *face = facePtr + (4*i);
      if(face[0] && face[1] && face[2] && face[3]) {
	*idxPtr++ = face[0]-1;
	*idxPtr++ = face[1]-1;
	*idxPtr++ = face[2]-1;
	*idxPtr++ = face[2]-1;
	*idxPtr++ = face[3]-1;
	*idxPtr++ = face[0]-1;
      }
    }
    hRes = lpDevice->lpVtbl->
      DrawIndexedPrimitiveStrided(lpDevice, 
				  D3DPT_TRIANGLELIST, 
				  vtxFlags, 
				  &d3dStrideData,
				  nVertices,
				  (LPWORD)facePtr,
				  (LPWORD)idxPtr - (LPWORD)facePtr,
				  0);
    break;
  }
  ERROR_CHECK;
  return 1;
}


/*****************************************************************************/
/*****************************************************************************/
/* Win32 specific handling                                                   */
/*****************************************************************************/
/*****************************************************************************/
static messageHook *preMessageHook = NULL;
static messageHook nextPreMessageHook = NULL;

/* Message hook for processing Windows messages sent to stWindow */
static int d3dMessageHook(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
  int result = 0;

  /* Call the original pre-message hook */
  if(nextPreMessageHook)
    result = (*nextPreMessageHook)(hwnd, message,wParam, lParam);

  /* Note: We need to intercept certain messages regardless of
     whether they are handled or not. */

  if(hwnd != *theSTWindow) return result; /* not sent to stWindow */
  if(message == WM_WINDOWPOSCHANGED) {
    /* When the window position changed we need to update the clipper */
    fUpdateClipper = 1;
    /* And to recompute the stWindow rectangle */
    GetClientRect(*theSTWindow,&stWindowRect);
    /* Record the global stWindowRect for DirectX */
    MapWindowPoints(*theSTWindow, NULL, (LPPOINT)&stWindowRect, 2);
  }
  return result; /* of former msg hook */
}

/***************************************************************************
 ***************************************************************************
					Module initializers
 ***************************************************************************
 ***************************************************************************/

int d3dInitialize(void)
{
  int i;
  HRESULT hRes;

  for(i=0; i<MAX_RENDERER; i++) {
    allRenderer[i].fUsed = 0;
  }

  hRes = CoInitialize(NULL);
  if(FAILED(hRes)) {
    DPRINTF3D(1, (fp, "ERROR: Failed to CoInitialize\n"));
    return 0;
  }
  /* lookup the necessary things from interpreter */
  theSTWindow = (HWND*) interpreterProxy->ioLoadFunctionFrom("stWindow","");
  if(!theSTWindow) {
    DPRINTF3D(1,(fp,"ERROR: Failed to look up stWindow\n"));
    return 0;
  }
  registerSurface = (fn_ioRegisterSurface) 
    interpreterProxy->ioLoadFunctionFrom("ioRegisterSurface","SurfacePlugin");
  if(!registerSurface) {
    DPRINTF3D(1,(fp,"ERROR: Failed to look up ioRegisterSurface()\n"));
    return 0;
  }
  unregisterSurface = (fn_ioUnregisterSurface)
    interpreterProxy->ioLoadFunctionFrom("ioUnregisterSurface","SurfacePlugin");
  if(!unregisterSurface) {
    DPRINTF3D(1,(fp,"ERROR: Failed to look up ioUnregisterSurface()\n"));
    return 0;
  }
  findSurface = (fn_ioFindSurface)
    interpreterProxy->ioLoadFunctionFrom("ioFindSurface","SurfacePlugin");
  if(!findSurface) {
    DPRINTF3D(1,(fp,"ERROR: Failed to look up ioFindSurface()\n"));
    return 0;
  }
  preMessageHook = (messageHook*)
    interpreterProxy->ioLoadFunctionFrom("preMessageHook","");
  if(!preMessageHook) {
    DPRINTF3D(1,(fp,"ERROR: Failed to look up preMessageHook()\n"));
    return 0;
  }
  nextPreMessageHook = *preMessageHook;
  *preMessageHook = (messageHook) d3dMessageHook;

  /* Recompute the stWindow rectangle */
  GetClientRect(*theSTWindow,&stWindowRect);
  /* Record the global stWindowRect for DirectX */
  MapWindowPoints(*theSTWindow, NULL, (LPPOINT)&stWindowRect, 2);

  return 1;
}

int d3dShutdown(void)
{
  int i;
  for(i=0; i<MAX_RENDERER;i++) {
    if(allRenderer[i].fUsed)
      d3dDestroyRenderer(i);
  }
  d3dReleasePrimary();
  CoUninitialize();
  return 1;
}


#endif /* defined(B3DX_D3D) */
