/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqWin32OpenGL.c
*   CONTENT: Win32 specific bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqWin32OpenGL.c,v 1.2 2002/01/28 13:56:58 slosher Exp $
*
*   NOTES:
*
*****************************************************************************/
#include <windows.h>
#include <stdio.h>
#include <GL/gl.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "B3DAcceleratorPlugin.h"

#if defined (B3DX_GL)

#include "sqOpenGLRenderer.h"

#ifndef PFD_GENERIC_ACCELERATED
#define PFD_SWAP_LAYER_BUFFERS      0x00000800
#define PFD_GENERIC_ACCELERATED     0x00001000
#define PFD_SUPPORT_DIRECTDRAW      0x00002000
#endif

/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
# define DPRINTF(vLevel, args) if(vLevel <= verboseLevel) {\
	FILE *fp = fopen("Squeak3D.log", "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}

/* Plugin refs */
extern struct VirtualMachine *interpreterProxy;

static HWND *theSTWindow = NULL; /* a reference to Squeak's main window */

glRenderer *current = NULL;
glRenderer allRenderer[MAX_RENDERER];

static float blackLight[4] = { 0.0f, 0.0f, 0.0f, 0.0f };

/* Verbose level for debugging purposes:
	0 - print NO information ever
	1 - print critical debug errors
	2 - print debug warnings
	3 - print extra information
	4 - print extra warnings
	5 - print information about primitive execution

   10 - print information about each vertex and face
*/
int verboseLevel = 1;

#define ENABLE_FORCED_PFD

#ifdef ENABLE_FORCED_PFD
/* If forcedPFD > 0 then use the n-th accelerated PFD */
static int forcedPFD = -1;
#endif

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
LRESULT WINAPI glWindowProcedure(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  RECT updateRect;
  POINT mousePosition;
  HWND parent;
  PAINTSTRUCT ps;

  if(uMsg == WM_PAINT) {
    /* Process expose events locally */
    GetUpdateRect(hWnd,&updateRect,1);
    BeginPaint(hWnd,&ps);
    EndPaint(hWnd,&ps);
    return 1;
  } else if(uMsg >= WM_MOUSEFIRST && uMsg <= WM_MOUSELAST) {
    /* re-post all mouse messages */
    mousePosition.x = LOWORD(lParam);
    mousePosition.y = HIWORD(lParam);
    parent = GetParent(hWnd);
    MapWindowPoints(hWnd,parent,&mousePosition,1);
    PostMessage(parent,uMsg,wParam, MAKELPARAM(mousePosition.x,mousePosition.y));
    return 1;
  } else return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

static HWND glCreateClientWindow(HWND parentWindow, int x, int y, int w, int h)
{
  WNDCLASS 	windowClass;
  HINSTANCE	hInstance;
  const char *className = "Squeak-OpenGLWindow";

  if(!parentWindow) return NULL;
  hInstance = (HINSTANCE) GetWindowLong((HWND)parentWindow,GWL_HINSTANCE);
  windowClass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
  windowClass.lpfnWndProc = glWindowProcedure;
  windowClass.cbClsExtra = 0;
  windowClass.cbWndExtra = 4;
  windowClass.hInstance = hInstance;
  windowClass.hIcon = NULL;
  windowClass.hCursor = NULL;
  windowClass.hbrBackground = NULL;
  windowClass.lpszMenuName = NULL;
  windowClass.lpszClassName = className;
  RegisterClass(&windowClass);
  return CreateWindow(className,"",
		      WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS |WS_VISIBLE,
		      x,y,w,h,
		      (HWND) parentWindow,
		      0,
		      hInstance,
		      0);
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

static void printPFD(PIXELFORMATDESCRIPTOR *pfd, int lvl)
{
  /* Print the pixel format for information purposes */
  DPRINTF(lvl,(fp,"flags (%d): ", pfd->dwFlags));
  if(pfd->dwFlags & PFD_DRAW_TO_WINDOW) 
    DPRINTF(lvl, (fp, "PFD_DRAW_TO_WINDOW "));
  if(pfd->dwFlags & PFD_DRAW_TO_BITMAP) 
    DPRINTF(lvl, (fp, "PFD_DRAW_TO_BITMAP "));
  if(pfd->dwFlags & PFD_SUPPORT_GDI) 
    DPRINTF(lvl, (fp, "PFD_SUPPORT_GDI "));
  if(pfd->dwFlags & PFD_SUPPORT_OPENGL) 
    DPRINTF(lvl, (fp, "PFD_SUPPORT_OPENGL "));
  if(pfd->dwFlags & PFD_GENERIC_ACCELERATED) 
    DPRINTF(lvl, (fp, "PFD_GENERIC_ACCELERATED "));
  if(pfd->dwFlags & PFD_GENERIC_FORMAT) 
    DPRINTF(lvl, (fp, "PFD_GENERIC_FORMAT "));
  if(pfd->dwFlags & PFD_NEED_PALETTE) 
    DPRINTF(lvl, (fp, "PFD_NEED_PALETTE "));
  if(pfd->dwFlags & PFD_NEED_SYSTEM_PALETTE) 
    DPRINTF(lvl, (fp, "PFD_NEED_SYSTEM_PALETTE "));
  if(pfd->dwFlags & PFD_DOUBLEBUFFER) 
    DPRINTF(lvl, (fp, "PFD_DOUBLEBUFFER "));
  if(pfd->dwFlags & PFD_SWAP_LAYER_BUFFERS) 
    DPRINTF(lvl, (fp, "PFD_SWAP_LAYER_BUFFERS "));
  if(pfd->dwFlags & PFD_SWAP_COPY) 
    DPRINTF(lvl, (fp, "PFD_SWAP_COPY "));
  if(pfd->dwFlags & PFD_SWAP_EXCHANGE) 
    DPRINTF(lvl, (fp, "PFD_SWAP_EXCHANGE "));
  DPRINTF(lvl,(fp,"\n"));

  DPRINTF(lvl,(fp,"pixelType = %s\n",(pfd->iPixelType == PFD_TYPE_RGBA ? "PFD_TYPE_RGBA" : "PFD_TYPE_COLORINDEX")));
  DPRINTF(lvl,(fp,"colorBits = %d\n",pfd->cColorBits));
  DPRINTF(lvl,(fp,"depthBits = %d\n",pfd->cDepthBits));
  DPRINTF(lvl,(fp,"stencilBits = %d\n",pfd->cStencilBits));
  DPRINTF(lvl,(fp,"accumBits = %d\n",pfd->cAccumBits));
  DPRINTF(lvl,(fp,"auxBuffers = %d\n",pfd->cAuxBuffers));
  DPRINTF(lvl,(fp,"layerType = %d\n",pfd->iLayerType));

  DPRINTF(lvl,(fp,"redBits = %d\n",pfd->cRedBits));
  DPRINTF(lvl,(fp,"redShift = %d\n",pfd->cRedShift));
  DPRINTF(lvl,(fp,"greenBits = %d\n",pfd->cGreenBits));
  DPRINTF(lvl,(fp,"greenShift = %d\n",pfd->cGreenShift));
  DPRINTF(lvl,(fp,"blueBits = %d\n",pfd->cBlueBits));
  DPRINTF(lvl,(fp,"blueShift = %d\n",pfd->cBlueShift));
  DPRINTF(lvl,(fp,"alphaBits = %d\n",pfd->cAlphaBits));
  DPRINTF(lvl,(fp,"alphaShift = %d\n",pfd->cAlphaShift));
  
  DPRINTF(lvl,(fp,"accumRedBits = %d\n",pfd->cAccumRedBits));
  DPRINTF(lvl,(fp,"accumGreenBits = %d\n",pfd->cAccumGreenBits));
  DPRINTF(lvl,(fp,"accumBlueBits = %d\n",pfd->cAccumBlueBits));
  DPRINTF(lvl,(fp,"accumAlphaBits = %d\n",pfd->cAccumAlphaBits));
}

int glDestroyRenderer(int handle) {
  glRenderer *renderer = glRendererFromHandle(handle);

  if(!renderer) return 1; /* already destroyed */
  if(!glMakeCurrentRenderer(NULL)) return 0;
  wglDeleteContext(renderer->context);
  ReleaseDC(renderer->hWnd, renderer->hDC);
  DestroyWindow(renderer->hWnd);
  renderer->hWnd = NULL;
  renderer->hDC = NULL;
  renderer->context = NULL;
  renderer->used = 0;
  return 1;
}

#if 0
int glDescribeRenderer(int index, int *desc, int descSize) {
  PIXELFORMATDESCRIPTOR pfd, goodPFD;
  HDC hDC;

  /* req. at least version 0 */
  if(descSize < B3D_PF_SIZE0) return 0;
  if(!*theSTWindow) return 0;
  hDC = GetDC(*theSTWindow);
  if(!hDC) return 0;
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
  pfd.nVersion = 1;
  if(!DescribePixelFormat(hDC, index, sizeof(pfd), &pfd)) {
    return 0;
  }
  desc[0] = B3D_PF_SIZE;
  flags = 0;
  if(pfd.dwFlags & PFD_DRAW_TO_WINDOW) flags |= B3D_PF_WINDOW_FLAG;
  if(pfd.dwFlags & PFD_DRAW_TO_BITMAP) flags |= B3D_PF_BITMAP_FLAG;
  if(pfd.dwFlags & PFD_SUPPORT_GDI) flags |= B3D_PF_NATIVE_GDI_FLAG;
  if(pfd.dwFlags & PFD_SUPPORT_OPENGL) flags |= B3D_PF_NATIVE_API_FLAG;
  if(pfd.dwFlags & PFD_GENERIC_ACCELERATED) flags |= B3D_PF_ACCELERATED_FLAG;
  if((pfd.dwFlags & PFD_GENERIC_FORMAT) == 0) flags |= B3D_PF_ACCELERATED_FLAG;
  if(pfd.dwFlags & PFD_DOUBLEBUFFER) flags |= B3D_PF_DOUBLEBUFFER_FLAG;

  if(pfd.iPixelType == PFD_TYPE_RGBA) flags |= B3D_RGBA_FLAG;
  else flags |= B3D_INDEXED_FLAG;

  desc[B3D_PF_FLAGS] = flags;
  desc[B3D_PF_COLORBITS] = pfd.cColorBits;
  desc[B3D_PF_DEPTHBITS] = pfd.cDepthBits;
  desc[B3D_PF_STENCILBITS] = pfd.cStencilBits;
  desc[B3D_PF_ACCUMBITS] = pfd.cAccumBits;
  desc[B3D_PF_AUXBUFFERS] = pfd.cAuxBuffers;
  desc[B3D_PF_LAYER] = pfd.iLayerType;

  desc[B3D_PF_REDMASK] = ((1 << pfd.cRedBits) - 1) << pfd.cRedShift;
  desc[B3D_PF_GREENMASK] = ((1 << pfd.cGreenBits) - 1) << pfd.cGreenShift;
  desc[B3D_PF_BLUEMASK] = ((1 << pfd.cBlueBits) - 1) << pfd.cBlueShift;
  desc[B3D_PF_ALPHAMASK] = ((1 << pfd.cAlphaBits) - 1) << pfd.cAlphaShift;
  return 1;
}

int glCreateRendererPF(int *pfDesc, int descSize, int x, int y, int w, int h)
{
  PIXELFORMATDESCRIPTOR pfd;
  int depth, i, goodIndex, max, index;
  char *string;
  glRenderer *renderer;

  for(i=0; i < MAX_RENDERER; i++) {
    if(allRenderer[i].used == 0) break;
  }
  if(i >= MAX_RENDERER) {
    DPRINTF(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
    return 0;
  }
  index = i;
  renderer = allRenderer+index;
  renderer->used = 0;
  renderer->context = NULL;
  renderer->hDC = NULL;
  renderer->hWnd = NULL;

  DPRINTF(3,(fp,"---- Initializing OpenGL ----\n\n"));
  renderer->hWnd = glCreateClientWindow(*theSTWindow, x, y, w, h);
  if(renderer->hWnd == NULL) {
    DPRINTF(1, (fp, "Failed to create client window\n"));
    goto FAILED;
  }
  ShowWindow(renderer->hWnd, SW_SHOW);
  UpdateWindow(renderer->hWnd);
  renderer->hDC = GetDC(renderer->hWnd);
  if(!renderer->hDC) {
    DPRINTF(1, (fp, "Failed to obtain client hdc\n"));
    goto FAILED;
  }

  /* Query the native depth so we can choose something appropriate */
  depth = GetDeviceCaps(renderer->hDC, BITSPIXEL);
  max = DescribePixelFormat(renderer->hDC, 1, sizeof(pfd), &pfd);
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
  pfd.nVersion = 1;
  goodPFD.nSize = 0;
  goodIndex = 0;

  for(i=1; i<= max; i++) {
    DescribePixelFormat(renderer->hDC, i, sizeof(pfd), &pfd);
    DPRINTF(3,(fp, "\n#### Checking pixel format %d:\n", i));
    printPFD(&pfd, 3);
    if((pfd.dwFlags & PFD_DRAW_TO_WINDOW) == 0) 
      continue; /* can't draw to window */
    if((pfd.dwFlags & PFD_SUPPORT_OPENGL) == 0) 
      continue; /* can't use OpenGL */
    if((pfd.dwFlags & PFD_DOUBLEBUFFER) == 0) 
      continue;  /* can't double buffer */
    if(pfd.iPixelType != PFD_TYPE_RGBA) 
      continue; /* not an RGBA format */
    if(pfd.cDepthBits < 16) 
      continue; /* no enough z-buffer */
    if(pfd.iLayerType != PFD_MAIN_PLANE) 
      continue; /* overlay/underlay */

    if((pfd.dwFlags & PFD_GENERIC_FORMAT) == 0) {
      /* This indicates an accellerated driver */
      if(!allowHardware) continue;
      DPRINTF(3,(fp,"===> This is an accelerated driver\n"));
#ifdef ENABLE_FORCED_PFD
      if(forcedPFD > 0) {
	if(--forcedPFD == 0) {
	  goodPFD = pfd; goodIndex = i;
	  break;
	}
      }
#endif
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    } else if(pfd.dwFlags & PFD_GENERIC_ACCELERATED) {
      /* This indicates an accellerated mini-driver */
      if(!allowHardware) continue;
      DPRINTF(3,(fp,"===> This is an accelerated mini-driver\n"));
#ifdef ENABLE_FORCED_PFD
      if(forcedPFD > 0) {
	if(--forcedPFD == 0) {
	  goodPFD = pfd; goodIndex = i;
	  break;
	}
      }
#endif
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    }

    if( (pfd.dwFlags & PFD_GENERIC_FORMAT) &&
	((pfd.dwFlags & PFD_GENERIC_ACCELERATED) == 0)) {
      /* this indicates a non-accellerated driver */
      if(!allowSoftware) continue;
	  if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
	  }
    }
  }
  if((goodPFD.nSize == 0) 
#ifdef ENABLE_FORCED_PFD
     || (forcedPFD > 0)
#endif
     ) {
    /* We didn't find an accellerated driver. */
    DPRINTF(3,(fp,"#### WARNING: No accelerated driver found; bailing out\n"));
    goto FAILED;
  }

  /* Now we have found the PFD to use. 
     Try setting the pixel format for the window */
  SetPixelFormat(renderer->hDC, goodIndex, &goodPFD);
  /* Note: SetPixelFormat may fail if the pixel format has been set before.
     Rather than failing here we do ignore the result of the above,
     so that an old pixel format will be used in any case. */
  goodIndex = GetPixelFormat(renderer->hDC);
  DescribePixelFormat(renderer->hDC, goodIndex, sizeof(pfd), &pfd);

  DPRINTF(3,(fp,"\n#### Selected pixel format (%d) ####\n",goodIndex));
  printPFD(&pfd, 3);
  renderer->context = wglCreateContext(renderer->hDC);
  if(!renderer->context) {
    DPRINTF(1, (fp,"Failed to create opengl context\n"));
    goto FAILED;
  }
  /* Make the context current */
  if(!wglMakeCurrent(renderer->hDC, renderer->context)) goto FAILED;

  /* print some information about the context */
  string = (char*) glGetString(GL_VENDOR);
  DPRINTF(3,(fp, "\nOpenGL vendor: %s\n", string));
  string = (char*) glGetString(GL_RENDERER);
  DPRINTF(3,(fp, "OpenGL renderer: %s\n", string));
  string = (char*) glGetString(GL_VERSION);
  DPRINTF(3,(fp, "OpenGL version: %s\n", string));
  string = (char*) glGetString(GL_EXTENSIONS);
  DPRINTF(3,(fp, "OpenGL extensions: %s\n", string));
  
  renderer->used = 1;
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;

  DPRINTF(3, (fp,"### Renderer created!\n"));
  /* setup user context */
  glDisable(GL_LIGHTING);
  glDisable(GL_COLOR_MATERIAL);
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glEnable(GL_DITHER);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_NORMALIZE);
  glDepthFunc(GL_LEQUAL);
  glClearDepth(1.0);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glShadeModel(GL_SMOOTH);
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, blackLight);
  ERROR_CHECK;
  return index;
FAILED:
  /* do necessary cleanup */
  DPRINTF(1,(fp, "OpenGL initialization failed\n"));
  if(renderer->context) wglDeleteContext(renderer->context);
  if(renderer->hDC) ReleaseDC(renderer->hWnd, renderer->hDC);
  if(renderer->hWnd) DestroyWindow(renderer->hWnd);
  return -1;
}
#endif

int glCreateRenderer(int allowSoftware, int allowHardware, int x, int y, int w, int h)
{
  PIXELFORMATDESCRIPTOR pfd, goodPFD;
  int depth, i, goodIndex, max, index;
  char *string;
  glRenderer *renderer;

  for(i=0; i < MAX_RENDERER; i++) {
    if(allRenderer[i].used == 0) break;
  }
  if(i >= MAX_RENDERER) {
    DPRINTF(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
    return 0;
  }
  index = i;
  renderer = allRenderer+index;
  renderer->used = 0;
  renderer->context = NULL;
  renderer->hDC = NULL;
  renderer->hWnd = NULL;

  DPRINTF(3,(fp,"---- Initializing OpenGL ----\n\n"));
  renderer->hWnd = glCreateClientWindow(*theSTWindow, x, y, w, h);
  if(renderer->hWnd == NULL) {
    DPRINTF(1, (fp, "Failed to create client window\n"));
    goto FAILED;
  }
  ShowWindow(renderer->hWnd, SW_SHOW);
  UpdateWindow(renderer->hWnd);
  renderer->hDC = GetDC(renderer->hWnd);
  if(!renderer->hDC) {
    DPRINTF(1, (fp, "Failed to obtain client hdc\n"));
    goto FAILED;
  }

  /* Query the native depth so we can choose something appropriate */
  depth = GetDeviceCaps(renderer->hDC, BITSPIXEL);
  max = DescribePixelFormat(renderer->hDC, 1, sizeof(pfd), &pfd);
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
  pfd.nVersion = 1;
  goodPFD.nSize = 0;
  goodIndex = 0;

  for(i=1; i<= max; i++) {
    DescribePixelFormat(renderer->hDC, i, sizeof(pfd), &pfd);
    DPRINTF(3,(fp, "\n#### Checking pixel format %d:\n", i));
    printPFD(&pfd, 3);
    if((pfd.dwFlags & PFD_DRAW_TO_WINDOW) == 0) 
      continue; /* can't draw to window */
    if((pfd.dwFlags & PFD_SUPPORT_OPENGL) == 0) 
      continue; /* can't use OpenGL */
    if((pfd.dwFlags & PFD_DOUBLEBUFFER) == 0) 
      continue;  /* can't double buffer */
    if(pfd.iPixelType != PFD_TYPE_RGBA) 
      continue; /* not an RGBA format */
    if(pfd.cDepthBits < 16) 
      continue; /* no enough z-buffer */
    if(pfd.iLayerType != PFD_MAIN_PLANE) 
      continue; /* overlay/underlay */

    if((pfd.dwFlags & PFD_GENERIC_FORMAT) == 0) {
      /* This indicates an accellerated driver */
      if(!allowHardware) continue;
      DPRINTF(3,(fp,"===> This is an accelerated driver\n"));
#ifdef ENABLE_FORCED_PFD
      if(forcedPFD > 0) {
	if(--forcedPFD == 0) {
	  goodPFD = pfd; goodIndex = i;
	  break;
	}
      }
#endif
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    } else if(pfd.dwFlags & PFD_GENERIC_ACCELERATED) {
      /* This indicates an accellerated mini-driver */
      if(!allowHardware) continue;
      DPRINTF(3,(fp,"===> This is an accelerated mini-driver\n"));
#ifdef ENABLE_FORCED_PFD
      if(forcedPFD > 0) {
	if(--forcedPFD == 0) {
	  goodPFD = pfd; goodIndex = i;
	  break;
	}
      }
#endif
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    }

    if( (pfd.dwFlags & PFD_GENERIC_FORMAT) &&
	((pfd.dwFlags & PFD_GENERIC_ACCELERATED) == 0)) {
      /* this indicates a non-accellerated driver */
      if(!allowSoftware) continue;
	  if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
	  }
    }
  }
  if((goodPFD.nSize == 0) 
#ifdef ENABLE_FORCED_PFD
     || (forcedPFD > 0)
#endif
     ) {
    /* We didn't find an accellerated driver. */
    DPRINTF(3,(fp,"#### WARNING: No accelerated driver found; bailing out\n"));
    goto FAILED;
  }

  /* Now we have found the PFD to use. 
     Try setting the pixel format for the window */
  SetPixelFormat(renderer->hDC, goodIndex, &goodPFD);
  /* Note: SetPixelFormat may fail if the pixel format has been set before.
     Rather than failing here we do ignore the result of the above,
     so that an old pixel format will be used in any case. */
  goodIndex = GetPixelFormat(renderer->hDC);
  DescribePixelFormat(renderer->hDC, goodIndex, sizeof(pfd), &pfd);

  DPRINTF(3,(fp,"\n#### Selected pixel format (%d) ####\n",goodIndex));
  printPFD(&pfd, 3);
  renderer->context = wglCreateContext(renderer->hDC);
  if(!renderer->context) {
    DPRINTF(1, (fp,"Failed to create opengl context\n"));
    goto FAILED;
  }
  /* Make the context current */
  if(!wglMakeCurrent(renderer->hDC, renderer->context)) goto FAILED;

  /* print some information about the context */
  string = (char*) glGetString(GL_VENDOR);
  DPRINTF(3,(fp, "\nOpenGL vendor: %s\n", string));
  string = (char*) glGetString(GL_RENDERER);
  DPRINTF(3,(fp, "OpenGL renderer: %s\n", string));
  string = (char*) glGetString(GL_VERSION);
  DPRINTF(3,(fp, "OpenGL version: %s\n", string));
  string = (char*) glGetString(GL_EXTENSIONS);
  DPRINTF(3,(fp, "OpenGL extensions: %s\n", string));
  
  renderer->used = 1;
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;

  DPRINTF(3, (fp,"### Renderer created!\n"));
  /* setup user context */
  glDisable(GL_LIGHTING);
  glDisable(GL_COLOR_MATERIAL);
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glEnable(GL_DITHER);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_NORMALIZE);
  glDepthFunc(GL_LEQUAL);
  glClearDepth(1.0);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glShadeModel(GL_SMOOTH);
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, blackLight);
  ERROR_CHECK;
  return index;
FAILED:
  /* do necessary cleanup */
  DPRINTF(1,(fp, "OpenGL initialization failed\n"));
  if(renderer->context) wglDeleteContext(renderer->context);
  if(renderer->hDC) ReleaseDC(renderer->hWnd, renderer->hDC);
  if(renderer->hWnd) DestroyWindow(renderer->hWnd);
  return -1;
}

/*****************************************************************************/
/*****************************************************************************/

int glGetIntProperty(int handle, int prop)
{
  GLint v;
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

  switch(prop) {
  case 1: /* backface culling */
    if(!glIsEnabled(GL_CULL_FACE)) return 0;
    glGetIntegerv(GL_FRONT_FACE, &v);
    if(v == GL_CW) return 1;
    if(v == GL_CCW) return -1;
    return 0;
  case 2: /* polygon mode */
    glGetIntegerv(GL_POLYGON_MODE, &v);
    ERROR_CHECK;
    return v;
  case 3: /* point size */
    glGetIntegerv(GL_POINT_SIZE, &v);
    ERROR_CHECK;
    return v;
  case 4: /* line width */
    glGetIntegerv(GL_LINE_WIDTH, &v);
    ERROR_CHECK;
    return v;
  }
  return 0;
}

int glSetIntProperty(int handle, int prop, int value)
{
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

  switch(prop) {
  case 1: /* backface culling */
    if(!value) {
      glDisable(GL_CULL_FACE);
      ERROR_CHECK;
      return 1;
    }
    glEnable(GL_CULL_FACE);
    glFrontFace(value == 1 ? GL_CCW : GL_CW);
    ERROR_CHECK;
    return 1;
  case 2: /* polygon mode */
    if(value == 0) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    else if(value == 1) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    else if(value == 2) glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
    else return 0;
    ERROR_CHECK;
    return 1;
  case 3: /* point size */
    glPointSize(value);
    ERROR_CHECK;
    return 1;
  case 4: /* line width */
    glLineWidth(value);
    ERROR_CHECK;
    return 1;
  }
  return 0;
}

/*****************************************************************************/
/*****************************************************************************/

glRenderer *glRendererFromHandle(int handle) {
  DPRINTF(7, (fp, "Looking for renderer id: %d\n", handle));
  if(handle < 0 || handle >= MAX_RENDERER) return NULL;
  if(allRenderer[handle].used) return allRenderer+handle;
  return NULL;
}

int glIsOverlayRenderer(int handle) {
  /* we always use overlay renderers */
  return 1;
}

int glSwapBuffers(glRenderer *renderer) {
  if(!renderer) return 0;
  if(!renderer->used || !renderer->context) return 0;
  SwapBuffers(renderer->hDC);
  return 1;
}

int glMakeCurrentRenderer(glRenderer *renderer) {
  if(current == renderer) return 1;
  if(renderer)
    if(!renderer->used || !renderer->context) return 0;
  ERROR_CHECK;
  if(renderer) {
    wglMakeCurrent(renderer->hDC, renderer->context);
  } else {
    wglMakeCurrent(NULL, NULL);
  }
  current = renderer;
  return 1;
}

int glSetBufferRect(int handle, int x, int y, int w, int h) {
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
  SetWindowPos(renderer->hWnd, 
	       NULL, x, y, w, h, 
	       SWP_NOZORDER | SWP_NOREDRAW);
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;
  return 1;
}

int glSetVerboseLevel(int level) {
  verboseLevel = level;
  return 1;
}

/***************************************************************************
 ***************************************************************************
					Module initializers
 ***************************************************************************
 ***************************************************************************/

int glInitialize(void)
{
  int i;
  theSTWindow = (HWND*) interpreterProxy->ioLoadFunctionFrom("stWindow","");
  if(!theSTWindow) {
    DPRINTF(1,(fp,"ERROR: Failed to look up stWindow\n"));
    return 0;
  }
  for(i = 0; i < MAX_RENDERER; i++) {
    allRenderer[i].used = 0;
  }
  return 1;
}

int glShutdown(void)
{
  int i;
  for(i=0; i< MAX_RENDERER; i++) {
    if(allRenderer[i].used)
      glDestroyRenderer(i);
  }
  return 1;
}

#ifdef ENABLE_FORCED_PFD
int win32SetForcedPFD(void) {
  int pfdIndex;
  if(interpreterProxy->methodArgumentCount() != 1)
    return interpreterProxy->primitiveFail();
  pfdIndex = interpreterProxy->stackIntegerValue(0);
  if(interpreterProxy->failed()) return 0;
  forcedPFD = pfdIndex;
  interpreterProxy->pop(1);
}
#endif

#endif /* defined(B3DX_GL) */
