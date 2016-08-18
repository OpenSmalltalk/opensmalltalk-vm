/****************************************************************************
*   FILE:    sqWin32OpenGL.c
*   CONTENT: Win32 specific bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
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

/* Constants for wgl ARB - not in usual headers. */

#define WGL_DRAW_TO_WINDOW_ARB			0x2001
#define WGL_ACCELERATION_ARB			0x2003
#define WGL_SUPPORT_OPENGL_ARB			0x2010
#define WGL_DOUBLE_BUFFER_ARB			0x2011
#define WGL_STEREO_ARB				0x2012
#define WGL_PIXEL_TYPE_ARB			0x2013
#define WGL_COLOR_BITS_ARB			0x2014
#define WGL_RED_BITS_ARB			0x2015
#define WGL_RED_SHIFT_ARB			0x2016
#define WGL_GREEN_BITS_ARB			0x2017
#define WGL_GREEN_SHIFT_ARB			0x2018
#define WGL_BLUE_BITS_ARB			0x2019
#define WGL_BLUE_SHIFT_ARB			0x201A
#define WGL_ALPHA_BITS_ARB			0x201B
#define WGL_ALPHA_SHIFT_ARB			0x201C
#define WGL_ACCUM_BITS_ARB			0x201D
#define WGL_ACCUM_RED_BITS_ARB			0x201E
#define WGL_ACCUM_GREEN_BITS_ARB		0x201F
#define WGL_ACCUM_BLUE_BITS_ARB			0x2020
#define WGL_ACCUM_ALPHA_BITS_ARB		0x2021
#define WGL_DEPTH_BITS_ARB			0x2022
#define WGL_STENCIL_BITS_ARB			0x2023
#define WGL_AUX_BUFFERS_ARB			0x2024
#define WGL_NO_ACCELERATION_ARB			0x2025
#define WGL_GENERIC_ACCELERATION_ARB		0x2026
#define WGL_FULL_ACCELERATION_ARB		0x2027
#define WGL_SWAP_EXCHANGE_ARB			0x2028
#define WGL_SWAP_COPY_ARB			0x2029
#define WGL_SWAP_UNDEFINED_ARB			0x202A
#define WGL_TYPE_RGBA_ARB			0x202B
#define WGL_TYPE_COLORINDEX_ARB			0x202C
#define WGL_SAMPLE_BUFFERS_ARB			0x2041
#define	WGL_SAMPLES_ARB				0x2042

/* WGL function types */
typedef int (__stdcall * PFN_WGLCHOOSEPIXELFORMAT) (
		HDC hdc, 
		const int *piAttribIList,
		const FLOAT *pfAttribFList, 
		UINT nMaxFormats, int *piFormats, UINT *nNumFormats);
 
typedef int (__stdcall * PFN_WGLSWAPINTERVALEXT) (int interval);

/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
# define DPRINTF3D(vLevel, args) if(vLevel <= verboseLevel) {\
	FILE *fp = fopen("Squeak3D.log", "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}

/* Plugin refs */
extern struct VirtualMachine *interpreterProxy;

static HWND *theSTWindow = NULL; /* a reference to Squeak's main window */

static glRenderer *current = NULL;
static glRenderer allRenderer[MAX_RENDERER];

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
  hInstance = (HINSTANCE) GetWindowLongPtr((HWND)parentWindow,GWLP_HINSTANCE);
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
  DPRINTF3D(lvl,(fp,"flags (%lu): ", pfd->dwFlags));
  if(pfd->dwFlags & PFD_DRAW_TO_WINDOW) 
    DPRINTF3D(lvl, (fp, "PFD_DRAW_TO_WINDOW "));
  if(pfd->dwFlags & PFD_DRAW_TO_BITMAP) 
    DPRINTF3D(lvl, (fp, "PFD_DRAW_TO_BITMAP "));
  if(pfd->dwFlags & PFD_SUPPORT_GDI) 
    DPRINTF3D(lvl, (fp, "PFD_SUPPORT_GDI "));
  if(pfd->dwFlags & PFD_SUPPORT_OPENGL) 
    DPRINTF3D(lvl, (fp, "PFD_SUPPORT_OPENGL "));
  if(pfd->dwFlags & PFD_GENERIC_ACCELERATED) 
    DPRINTF3D(lvl, (fp, "PFD_GENERIC_ACCELERATED "));
  if(pfd->dwFlags & PFD_GENERIC_FORMAT) 
    DPRINTF3D(lvl, (fp, "PFD_GENERIC_FORMAT "));
  if(pfd->dwFlags & PFD_NEED_PALETTE) 
    DPRINTF3D(lvl, (fp, "PFD_NEED_PALETTE "));
  if(pfd->dwFlags & PFD_NEED_SYSTEM_PALETTE) 
    DPRINTF3D(lvl, (fp, "PFD_NEED_SYSTEM_PALETTE "));
  if(pfd->dwFlags & PFD_DOUBLEBUFFER) 
    DPRINTF3D(lvl, (fp, "PFD_DOUBLEBUFFER "));
  if(pfd->dwFlags & PFD_SWAP_LAYER_BUFFERS) 
    DPRINTF3D(lvl, (fp, "PFD_SWAP_LAYER_BUFFERS "));
  if(pfd->dwFlags & PFD_SWAP_COPY) 
    DPRINTF3D(lvl, (fp, "PFD_SWAP_COPY "));
  if(pfd->dwFlags & PFD_SWAP_EXCHANGE) 
    DPRINTF3D(lvl, (fp, "PFD_SWAP_EXCHANGE "));
  DPRINTF3D(lvl,(fp,"\n"));

  DPRINTF3D(lvl,(fp,"pixelType = %s\n",(pfd->iPixelType == PFD_TYPE_RGBA ? "PFD_TYPE_RGBA" : "PFD_TYPE_COLORINDEX")));
  DPRINTF3D(lvl,(fp,"colorBits = %d\n",pfd->cColorBits));
  DPRINTF3D(lvl,(fp,"depthBits = %d\n",pfd->cDepthBits));
  DPRINTF3D(lvl,(fp,"stencilBits = %d\n",pfd->cStencilBits));
  DPRINTF3D(lvl,(fp,"accumBits = %d\n",pfd->cAccumBits));
  DPRINTF3D(lvl,(fp,"auxBuffers = %d\n",pfd->cAuxBuffers));
  DPRINTF3D(lvl,(fp,"layerType = %d\n",pfd->iLayerType));

  DPRINTF3D(lvl,(fp,"redBits = %d\n",pfd->cRedBits));
  DPRINTF3D(lvl,(fp,"redShift = %d\n",pfd->cRedShift));
  DPRINTF3D(lvl,(fp,"greenBits = %d\n",pfd->cGreenBits));
  DPRINTF3D(lvl,(fp,"greenShift = %d\n",pfd->cGreenShift));
  DPRINTF3D(lvl,(fp,"blueBits = %d\n",pfd->cBlueBits));
  DPRINTF3D(lvl,(fp,"blueShift = %d\n",pfd->cBlueShift));
  DPRINTF3D(lvl,(fp,"alphaBits = %d\n",pfd->cAlphaBits));
  DPRINTF3D(lvl,(fp,"alphaShift = %d\n",pfd->cAlphaShift));
  
  DPRINTF3D(lvl,(fp,"accumRedBits = %d\n",pfd->cAccumRedBits));
  DPRINTF3D(lvl,(fp,"accumGreenBits = %d\n",pfd->cAccumGreenBits));
  DPRINTF3D(lvl,(fp,"accumBlueBits = %d\n",pfd->cAccumBlueBits));
  DPRINTF3D(lvl,(fp,"accumAlphaBits = %d\n",pfd->cAccumAlphaBits));
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

/* Weak gl extension check - good enough for WGL_ARB_multisample */
static int glExtensionExists(const char *extension)
{
	const char *glExtensions = (const char*)glGetString(GL_EXTENSIONS);
	if (!glExtensions)
	  return 0;
	return (strstr(glExtensions,extension) != NULL);
}

/* Find a pixel format with antialiasing support. */
static int findAAPixelFormat (HDC hdc)
{
  int pixelFormat;
  BOOL bStatus;
  UINT numFormats;
  float fAttributes[] = {0,0};
  int iAttributes[] = { 
    WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
    WGL_SUPPORT_OPENGL_ARB, GL_TRUE,
    WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB,
    WGL_COLOR_BITS_ARB, 24,
    WGL_ALPHA_BITS_ARB, 8,
    WGL_DEPTH_BITS_ARB, 12,
    WGL_STENCIL_BITS_ARB, 8,
    WGL_DOUBLE_BUFFER_ARB, GL_TRUE,
    WGL_SAMPLE_BUFFERS_ARB, 1,
    WGL_SAMPLES_ARB, 4,
    0, 0};

  /* Find the extension routine. */
  PFN_WGLCHOOSEPIXELFORMAT wglChoosePixelFormatARB = 
    (PFN_WGLCHOOSEPIXELFORMAT) 
       wglGetProcAddress("wglChoosePixelFormatARB");

  if (!wglChoosePixelFormatARB) {
    DPRINTF3D(3, (fp, "Cannot find function wglChoosePixelFormatARB"));
    return -1;
  }

  /* Make sure the basic extension is also supported. */
  if (!glExtensionExists("GL_ARB_multisample")) {
    DPRINTF3D(3, (fp, "Cannot find extension GL_ARB_multisample"));
    return -1;
  }

  bStatus = wglChoosePixelFormatARB(hdc, iAttributes,
              fAttributes, 1, &pixelFormat, &numFormats);
  if ((bStatus == GL_TRUE) && (numFormats > 0))
  {
    DPRINTF3D(3, (fp, "Found 4-sample pixel format %d", pixelFormat));
    return pixelFormat;   
  }

  /* That failed, try using 2 samples now instead of 4 */
  iAttributes[19] = 2;
  bStatus = wglChoosePixelFormatARB(hdc, iAttributes,
              fAttributes, 1, &pixelFormat, &numFormats);
  if ((bStatus == GL_TRUE) && (numFormats > 0))
  {
    DPRINTF3D(3, (fp, "Found 2-sample pixel format %d", pixelFormat));
    return pixelFormat;
  }

  DPRINTF3D(3, (fp, "Cannot find a multisample pixel format."));
  return -1;
}

static int enableVSync(int value) {
  PFN_WGLSWAPINTERVALEXT wglSwapIntervalEXT = 
    (PFN_WGLSWAPINTERVALEXT) wglGetProcAddress("wglSwapIntervalEXT");

  if(!glExtensionExists("WGL_EXT_swap_control")){
    DPRINTF3D(3, (fp, "WGL_EXT_swap_control not found"));
    return -1;
  }

  if(!wglSwapIntervalEXT) {
    DPRINTF3D(3, (fp, "wglSwapIntervalEXT not found"));
    return -1;
  }
  wglSwapIntervalEXT(value);
  return value;
}

/* Create the renderer window and context; returns 0 on failure. */
static int setupWindow(glRenderer * renderer, int x, int y, int w, int h) {
  renderer->hWnd = glCreateClientWindow(*theSTWindow, x, y, w, h);
  if(renderer->hWnd == NULL) {
    DPRINTF3D(1, (fp, "Failed to create client window\n"));
    return 0;
  }
  ShowWindow(renderer->hWnd, SW_SHOW);
  UpdateWindow(renderer->hWnd);
  renderer->hDC = GetDC(renderer->hWnd);
  if(!renderer->hDC) {
    DPRINTF3D(1, (fp, "Failed to obtain client hdc\n"));
    return 0;
  }
  return 1;
}


#define SUPPORTED_FLAGS (\
    B3D_HARDWARE_RENDERER \
  | B3D_SOFTWARE_RENDERER \
  | B3D_STENCIL_BUFFER \
  | B3D_ANTIALIASING \
  | B3D_STEREO \
  | B3D_SYNCVBL \
)

int glCreateRendererFlags(int x, int y, int w, int h, int flags)
{
  PIXELFORMATDESCRIPTOR pfd, goodPFD, matchPFD;
  int depth, i, goodIndex, max, index;
  char *string;
  glRenderer *renderer;

  if(flags & ~SUPPORTED_FLAGS) {
    DPRINTF3D(1, (fp, "ERROR: Unsupported flags requested( %d)\n", flags));
    return -1;
  }

  for(i=0; i < MAX_RENDERER; i++) {
    if(allRenderer[i].used == 0) break;
  }
  if(i >= MAX_RENDERER) {
    DPRINTF3D(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
    return -1;
  }
  index = i;
  renderer = allRenderer+index;
  memset(renderer, 0, sizeof(glRenderer));
  DPRINTF3D(3,(fp,"---- Initializing OpenGL ----\n\n"));
  if (! setupWindow(renderer, x, y, w, h)) {
    goto FAILED;
  }

  /* Query the native depth so we can choose something appropriate */
  depth = GetDeviceCaps(renderer->hDC, BITSPIXEL);
  max = DescribePixelFormat(renderer->hDC, 1, sizeof(pfd), &pfd);
  pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
  pfd.nVersion = 1;
  goodPFD.nSize = 0;
  goodIndex = 0;

  /* setup the matching PFD */
  matchPFD.dwFlags = 0;
  /* standard requirements */
  matchPFD.dwFlags |= PFD_DRAW_TO_WINDOW;
  matchPFD.dwFlags |= PFD_SUPPORT_OPENGL;
  matchPFD.dwFlags |= PFD_TYPE_RGBA;
  matchPFD.dwFlags |= PFD_DOUBLEBUFFER;

  for(i=1; i<= max; i++) {
    DescribePixelFormat(renderer->hDC, i, sizeof(pfd), &pfd);
    DPRINTF3D(3,(fp, "\n#### Checking pixel format %d:\n", i));
    printPFD(&pfd, 3);

    if((pfd.dwFlags & matchPFD.dwFlags) != matchPFD.dwFlags)
      continue; /* one of the basic requirements didn't work */

    if(pfd.iPixelType != PFD_TYPE_RGBA) 
      continue; /* not an RGBA format */

    if(pfd.cDepthBits < 12)
      continue; /* no enough z-buffer */

    if(pfd.iLayerType != PFD_MAIN_PLANE) 
      continue; /* overlay/underlay */

    if(flags & B3D_STENCIL_BUFFER)
      if(pfd.cStencilBits == 0)
	continue; /* need stencil bits */

    if(flags & B3D_STEREO)
      if((pfd.dwFlags & PFD_STEREO) == 0)
	continue; /* need stereo caps */

    if((pfd.dwFlags & PFD_GENERIC_FORMAT) == 0) {
      /* This indicates an accellerated driver */
      if((flags & B3D_HARDWARE_RENDERER) == 0) continue;
      DPRINTF3D(3,(fp,"===> This is an accelerated driver\n"));
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    } else if(pfd.dwFlags & PFD_GENERIC_ACCELERATED) {
      /* This indicates an accellerated mini-driver */
      if((flags & B3D_HARDWARE_RENDERER) == 0) continue;
      DPRINTF3D(3,(fp,"===> This is an accelerated mini-driver\n"));

      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      } else if(goodPFD.cColorBits == depth) {
        goodPFD = pfd; goodIndex = i;
      }
    }

    if( (pfd.dwFlags & PFD_GENERIC_FORMAT) &&
	((pfd.dwFlags & PFD_GENERIC_ACCELERATED) == 0)) {
      /* this indicates a non-accellerated driver */
      if((flags & B3D_SOFTWARE_RENDERER) == 0) continue;
      if(goodPFD.nSize == 0) {
        goodPFD = pfd; goodIndex = i;
      }
    }
  }
  if(goodPFD.nSize == 0) {
    /* We didn't find an accellerated driver. */
    DPRINTF3D(3,(fp,"#### WARNING: No accelerated driver found; bailing out\n"));
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

  DPRINTF3D(3,(fp,"\n#### Selected pixel format (%d) ####\n", goodIndex));
  printPFD(&pfd, 3);
  renderer->context = wglCreateContext(renderer->hDC);
  if(!renderer->context) {
    DPRINTF3D(1, (fp,"Failed to create opengl context\n"));
    goto FAILED;
  }
  /* Make the context current */
  if(!wglMakeCurrent(renderer->hDC, renderer->context)) goto FAILED;

  /* Now we have a context; check for antialiasing support. */
  if (flags & B3D_ANTIALIASING) {
    int aaIndex = findAAPixelFormat (renderer->hDC);
    if (aaIndex > 0) {
	/* To set an AA pixel format, we have to start with a new window. */
	DescribePixelFormat(renderer->hDC, aaIndex, sizeof(pfd), &pfd);
	/* Take down the old window */
	wglMakeCurrent(NULL, NULL);
	wglDeleteContext(renderer->context);
	ReleaseDC (renderer->hWnd, renderer->hDC);
	DestroyWindow (renderer->hWnd);
	renderer->hWnd = NULL;
	renderer->hDC = NULL;
	renderer->context = NULL;

        if (! setupWindow(renderer, x, y, w, h)) {
	  goto FAILED;
	}
  	/* Set the new pixel format. */
  	SetPixelFormat(renderer->hDC, aaIndex, &pfd);
  	goodIndex = GetPixelFormat(renderer->hDC);
  	DescribePixelFormat(renderer->hDC, goodIndex, sizeof(pfd), &pfd);
	DPRINTF3D(3,(fp,"\n#### AA pixel format (%d) ####\n", goodIndex));
  	printPFD(&pfd, 3);
  	renderer->context = wglCreateContext(renderer->hDC);
	if (!wglMakeCurrent(renderer->hDC, renderer->context)) goto FAILED;
    }
  }

  /* Enable vsync if requested */
  if(flags & B3D_SYNCVBL) enableVSync(1);

  /* print some information about the context */
  string = (char*) glGetString(GL_VENDOR);
  DPRINTF3D(3,(fp, "\nOpenGL vendor: %s\n", string));
  string = (char*) glGetString(GL_RENDERER);
  DPRINTF3D(3,(fp, "OpenGL renderer: %s\n", string));
  string = (char*) glGetString(GL_VERSION);
  DPRINTF3D(3,(fp, "OpenGL version: %s\n", string));
  string = (char*) glGetString(GL_EXTENSIONS);
  DPRINTF3D(3,(fp, "OpenGL extensions: %s\n", string));
  
  renderer->used = 1;
  renderer->bufferRect[0] = x;
  renderer->bufferRect[1] = y;
  renderer->bufferRect[2] = w;
  renderer->bufferRect[3] = h;

  DPRINTF3D(3, (fp,"### Renderer created!\n"));
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
  DPRINTF3D(1,(fp, "OpenGL initialization failed\n"));
  if(renderer->context) wglDeleteContext(renderer->context);
  if(renderer->hDC) ReleaseDC(renderer->hWnd, renderer->hDC);
  if(renderer->hWnd) DestroyWindow(renderer->hWnd);
  return -1;
}

/*****************************************************************************/
/*****************************************************************************/

int glGetIntPropertyOS(int handle, int prop)
{
  /* No platform-specific properties supported */
  return 0;
}

int glSetIntPropertyOS(int handle, int prop, int value)
{
  /* No platform-specific properties supported */
  return 0;
}

/*****************************************************************************/
/*****************************************************************************/

glRenderer *glRendererFromHandle(int handle) {
  DPRINTF3D(7, (fp, "Looking for renderer id: %d\n", handle));
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
    DPRINTF3D(1,(fp,"ERROR: Failed to look up stWindow\n"));
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

#endif /* defined(B3DX_GL) */

