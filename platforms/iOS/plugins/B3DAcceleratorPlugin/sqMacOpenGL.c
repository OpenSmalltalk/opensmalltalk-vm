/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqMacOpenGL.c
*   CONTENT: MacOS specific bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqMacOpenGL.c 1367 2006-03-21 06:49:10Z johnmci $
*
*   NOTES:
*
*	Changes May 14th 2001 John M McIntosh Carbon support
*   Changes Jun 2001 JMM browser internal plugin support
* 	Changes Jan 2002 JMM carbon cleanup
*  Feb 26th, 2002, JMM - use carbon get dominate device
*  Apr 3rd, 2003, JMM - use BROWSERPLUGIN
*
*****************************************************************************/
#include <stdio.h>
#include <stdlib.h>

#include <Carbon/Carbon.h>
#include <QuickTime/QTML.h> /* unavailable in 64-bit apps :-( */
#include <QuickTime/QuickTimeComponents.h> /* unavailable in 64-bit apps :-( */
#include <unistd.h>
#include <AGL/agl.h>
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
# include <OpenGL/gl.h>
# define useTempMem (1L << 2) //This declaration is taken from old sdk definition.
#else
# include <AGL/gl.h>
#endif
#include <OpenGL/OpenGL.h>
/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
#include "sqAssert.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"
#include "sqMacUIConstants.h"
#include "B3DAcceleratorPlugin.h"
#include "sqMacOpenGL.h"
#include "sqOpenGLRenderer.h"

#ifdef BROWSERPLUGIN
#include "npapi.h"
#endif

int printRendererInfo(void);
int printFormatInfo(AGLPixelFormat info);

static glRenderer *current = NULL;
static glRenderer allRenderer[MAX_RENDERER];

#ifdef BROWSERPLUGIN
int gPortX,gPortY;
extern NP_Port *getNP_Port(void);
void StartDraw(void);
void EndDraw(void);
#endif
/* N.B. Whether this is built as an internal (SQUEAK_BUILTIN_PLUGIN) or
 * external plugin, we still directly access symbols from the VM.  See the
 * Makefile in this directory and its use of -bundle_loader to check for
 * available exports from the main VM.
 */
typedef void (*windowChangedHook)();
extern windowChangedHook setWindowChangedHook(windowChangedHook hook);
windowChangedHook existingHook = 0;


static float blackLight[4] = { 0.0f, 0.0f, 0.0f, 0.0f };

/*****************************************************************************/
/*****************************************************************************/
/*                      Mac window changed hook                              */
/*****************************************************************************/
/*****************************************************************************/

static void
windowChangedProc(void)
{
	int i;
	AGLDrawable win;
	static WindowPtr oldWindow = NULL;
#ifdef BROWSERPLUGIN
	NP_Port	*anNPPort;
#endif

	if (existingHook)
		existingHook();
	if (!(win = (AGLDrawable) getSTWindow()))
		return;
	if (!oldWindow)
		oldWindow = win;
	for (i = 0; i < MAX_RENDERER; i++) {
		glRenderer *renderer = allRenderer+i;
		if (renderer->used
		 && (renderer->drawable == win
		  || (WindowPtr)(renderer->drawable) == oldWindow)) {
			int		x,y,w,h;
			Rect	portRect;
			GLint 	bufferRect[4];
			CGrafPtr	windowPort;

#ifdef BROWSERPLUGIN
			StartDraw();
			anNPPort = getNP_Port();
			gPortX = anNPPort->portx;
			gPortY = anNPPort->porty;
			x = renderer->bufferRect[0] - gPortX;
			y = renderer->bufferRect[1] - gPortY;
#else
			x = renderer->bufferRect[0];
			y = renderer->bufferRect[1];
#endif
			w = renderer->bufferRect[2];
			h = renderer->bufferRect[3];

			windowPort = GetWindowPort((WindowPtr)win);
			GetPortBounds(windowPort,&portRect);

			bufferRect[0] = x;
			bufferRect[1] = portRect.bottom - portRect.top - (y+h);
			bufferRect[2] = w;
			bufferRect[3] = h;

			// aglSetDrawable(renderer->context,nil);
			renderer->drawable = (AGLDrawable) win;
			aglSetDrawable(renderer->context,windowPort);
			aglSetInteger(renderer->context, AGL_BUFFER_RECT, bufferRect);
			aglUpdateContext(renderer->context);
#ifdef BROWSERPLUGIN
			EndDraw();
#endif
		}
	}
	oldWindow = win;
}

/*****************************************************************************/
/*****************************************************************************/
/*                      Renderer creation primitives                         */
/*****************************************************************************/
/*****************************************************************************/

int glDestroyRenderer(int handle)
{
	glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer) return 1; /* already destroyed */

	/* Now really destroy the renderer */
	if(renderer->drawable) {
		/* was a direct drawable */
		aglSetDrawable(renderer->context, NULL);
	}
	if(renderer == current)
		glMakeCurrentRenderer(NULL);
	aglDestroyContext(renderer->context);
	if(renderer->gWorld) {
		UnlockPixels(renderer->pixMap);
		DisposeGWorld(renderer->gWorld);
	}
	renderer->context = (AGLContext) NULL;
	renderer->drawable = (AGLDrawable) NULL;
	renderer->gWorld = NULL;
	renderer->used = 0;
	return 1;
}

/*
 * Is ARB_Multisample supported?
 */
static int glHasARBMultisampling () {

	/* We need an open gl connection in which to test for extensions,
	 * so we setup a throwaway context.
	 */
	GLint attrib[] = { AGL_RGBA, AGL_NONE};
	AGLContext ctx;
	AGLPixelFormat fmt = aglChoosePixelFormat(NULL, 0, attrib);

	if (! fmt) { return 0; }
	ctx = aglCreateContext(fmt, NULL);
	aglDestroyPixelFormat(fmt);
	if (! ctx) {
		return 0;
	}
	aglSetCurrentContext(ctx);
	int result = gluCheckExtension((const GLubyte*) "GL_ARB_multisample", glGetString(GL_EXTENSIONS));
	aglDestroyContext(ctx);

	return result;
}


#if !defined(SQUEAK_BUILTIN_PLUGIN)
/* This beauty is taken from the sqMacSSL plugin.
 * It should be a platform-wide facility.
 */
static int
printf_status(OSStatus status, const char* restrict format, ...)
{
    int ret = 0;
    va_list args;
    va_start(args, format);
    CFErrorRef _e = CFErrorCreate(NULL, kCFErrorDomainOSStatus, status, NULL);
    CFStringRef _sdesc = CFErrorCopyDescription(_e);
    CFStringRef _sreas = CFErrorCopyFailureReason(_e);
    CFStringRef _sreco = CFErrorCopyRecoverySuggestion(_e);
    ret += vprintf(format, args);
    ret += printf("Status (%d): %s (%s): %s\n",
                  (int)status,
                  CFStringGetCStringPtr(_sdesc, kCFStringEncodingUTF8),
                  CFStringGetCStringPtr(_sreas, kCFStringEncodingUTF8),
                  CFStringGetCStringPtr(_sreco, kCFStringEncodingUTF8));
    CFRelease(_sreco);
    CFRelease(_sreas);
    CFRelease(_sdesc);
    CFRelease(_e);
    va_end(args);
    return ret;
}

/* See https://lists.apple.com/archives/mac-opengl/2006/Jun/msg00021.html */
static GDHandle
GetMainDevice()
{	CGDirectDisplayID mainID = CGMainDisplayID();
	GDHandle mainDevice;

	OSErr err = DMGetGDeviceByDisplayID (mainID, &mainDevice, true);

	if (err != noErr) {
		printf_status(err, "DMGetGDeviceByDisplayID(...)\n");
		exit(0);
	}
	return mainDevice;
}
#endif /* SQUEAK_BUILTIN_PLUGIN */


int
glCreateRendererFlags(int x, int y, int w, int h, int flags)
{
 	int index, i, allowSoftware, allowHardware;
 	GLint          hwAttrib[] = { AGL_STENCIL_SIZE, 0, AGL_RGBA, AGL_DOUBLEBUFFER, AGL_ACCELERATED, AGL_DEPTH_SIZE, 16,
				      AGL_SAMPLE_BUFFERS_ARB, 1, AGL_SAMPLES_ARB, 4, AGL_MULTISAMPLE, AGL_NO_RECOVERY, AGL_NONE};
				      /* Note - we honor antialiasing requests only for hardware renderers. */
 	GLint          swAttrib[] = { AGL_STENCIL_SIZE, 0, AGL_RGBA, AGL_PIXEL_SIZE, 0, AGL_OFFSCREEN, AGL_DEPTH_SIZE, 16, AGL_NONE };
	AGLPixelFormat fmt;
	AGLContext     ctx;
	GLboolean      ok;
	GLenum         err;
	AGLDrawable    win;
	glRenderer     *renderer;
	char *string;
 	long swapInterval = 0;
#ifdef SQUEAK_BUILTIN_PLUGIN
	Rect ignore;
	GDHandle tempGDH;
#endif

#define SUPPORTED_FLAGS (B3D_HARDWARE_RENDERER | B3D_SOFTWARE_RENDERER | B3D_STENCIL_BUFFER | B3D_ANTIALIASING | B3D_STEREO | B3D_SYNCVBL)
	if(flags & ~SUPPORTED_FLAGS) {
		DPRINTF3D(1, ("ERROR: Unsupported renderer flags (%d)\n", flags));
		return -1;
	}
#undef SUPPORTED_FLAGS

	/* interpret renderer flags */
	allowSoftware = (flags & B3D_SOFTWARE_RENDERER) != 0;
	allowHardware = (flags & B3D_HARDWARE_RENDERER) != 0;
	if(flags & B3D_STENCIL_BUFFER) {
		hwAttrib[1] = 1;
		swAttrib[1] = 1;
	}

	/* enable/disable stereo requests */
	if(flags & B3D_STEREO) {
		return -1; /* not supported for now */
	}

	/* Suppress the multisampling flags if antialiasing is not requested (or not supported.) */
	if (! ((flags & B3D_ANTIALIASING) && glHasARBMultisampling())) {
		hwAttrib[7] = AGL_NONE;
	}

	for(index=0; index < MAX_RENDERER; index++) {
		if(allRenderer[index].used == 0) break;
	}
	if(index >= MAX_RENDERER) {
		DPRINTF3D(1, ("ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
		return 0;
	}
	renderer = allRenderer+index;
	renderer->used = 0;
	renderer->finished = 0;
	renderer->context = NULL;
	renderer->drawable = NULL;
	renderer->gWorld = NULL;

#ifdef SQUEAK_BUILTIN_PLUGIN
	if (! getSTWindow())
		return 0;
	GetWindowGreatestAreaDevice(getSTWindow(),kWindowContentRgn,&tempGDH,&ignore);
	if (tempGDH == nil)
		return -1;
	swAttrib[2] = (*(*tempGDH)->gdPMap)->pixelSize;
#else
	swAttrib[2] = (*(*GetMainDevice())->gdPMap)->pixelSize;
#endif
	if(swAttrib[2] < 16) swAttrib[2] = 16;

	/* Choose an rgb pixel format */
	for(i = 0; i<2; i++) {
		if( (i == 0) && !allowHardware) continue;
		if( (i == 1) && !allowSoftware) continue;
		ctx = 0;
		if(i == 0) {
			DPRINTF3D(3, ("### Attempting to find hardware renderer\n"));
			win = (AGLDrawable) getSTWindow();
			if(!win) {
				DPRINTF3D(1, ("ERROR: stWindow is invalid (NULL)\n"));
				goto FAILED;
			}
			fmt = aglChoosePixelFormat(NULL, 0, hwAttrib);
		} else {
			DPRINTF3D(3, ("### Attempting to find software renderer\n"));
			win = NULL;
			fmt = aglChoosePixelFormat(NULL, 0, swAttrib);
		}
		DPRINTF3D(3, ("\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));

		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,("aglGetError - %s\n", aglErrorString(err)));
		if(fmt == NULL) {
			DPRINTF3D(1, ("ERROR: aglChoosePixelFormat failed\n"));
			goto FAILED;
		}

		printFormatInfo(fmt);

		/* Create an AGL context */
		ctx = aglCreateContext(fmt, NULL);
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,("aglGetError - %s\n", aglErrorString(err)));
		/* The pixel format is no longer needed */
		aglDestroyPixelFormat(fmt);
		if(ctx == NULL) {
			DPRINTF3D(1, ("ERROR: aglCreateContext failed\n"));
			goto FAILED;
		}

		if(i == 0) {
			GLint bufferRect[4];
			Rect	portRect;

#ifdef BROWSERPLUGIN
			NP_Port	*anNPPort;

			StartDraw();
 			win = (AGLDrawable) getSTWindow();
 			anNPPort = getNP_Port();

			GetPortBounds(GetWindowPort((WindowPtr)win),&portRect);
			bufferRect[0] = x - anNPPort->portx;
			bufferRect[1] = portRect.bottom - portRect.top - (y+h)  + anNPPort->porty;
			bufferRect[2] = w;
			bufferRect[3] = h;
			EndDraw();
#else
			GetPortBounds(GetWindowPort((WindowPtr)win),&portRect);
			bufferRect[0] = x;
			bufferRect[1] = portRect.bottom - portRect.top - (y+h);
			bufferRect[2] = w;
			bufferRect[3] = h;
#endif

			/* hardware renderer; attach buffer rect and window */
			ok = aglEnable(ctx, AGL_BUFFER_RECT);
			if((err = aglGetError()) != AGL_NO_ERROR)
				DPRINTF3D(3,("aglEnable(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			ok = aglSetInteger(ctx, AGL_BUFFER_RECT, bufferRect);
			if((err = aglGetError()) != AGL_NO_ERROR)
				DPRINTF3D(3,("aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			/* Attach the context to the target */
			ok = aglSetDrawable(ctx,GetWindowPort( (WindowPtr)win));
			if((err = aglGetError()) != AGL_NO_ERROR)
				DPRINTF3D(3,("aglSetDrawable() failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			renderer->drawable = (AGLDrawable) win;

			/* Set VBL SYNC if requested */
			if(flags & B3D_SYNCVBL) swapInterval = 1;
			aglSetInteger(ctx, AGL_SWAP_INTERVAL, &swapInterval);

		} else {
			/* software renderer; attach offscreen buffer to context */
			Rect rect;
			QDErr qdErr;

			renderer->depth = swAttrib[2];
			/* Create the offscreen gworld */
			SetRect(&rect, 0, 0, w, h);
			qdErr = NewGWorld(&renderer->gWorld, (short) renderer->depth, &rect, NULL, NULL, useTempMem);
			if(qdErr || !renderer->gWorld) {
				DPRINTF3D(1,("ERROR: Failed to create new GWorld\n"));
				renderer->gWorld = NULL;
				goto FAILED;
			}
			renderer->pixMap = GetGWorldPixMap(renderer->gWorld);
			LockPixels(renderer->pixMap);
			renderer->pitch = (**(renderer->pixMap)).rowBytes & 0x7FFF;
			renderer->bits = (unsigned char*) GetPixBaseAddr(renderer->pixMap);
			ok = aglSetOffScreen(ctx, w, h, renderer->pitch, renderer->bits);
			if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,("aglGetError - %s\n", aglErrorString(err)));
			if(!ok) {
				DPRINTF3D(1, ("ERROR: aglSetOffScreen failed\n"));
				goto FAILED;
			}
		}
		renderer->context = ctx;
		renderer->used = 1;
		renderer->finished = 0;
		renderer->bufferRect[0] = x;
		renderer->bufferRect[1] = y;
		renderer->bufferRect[2] = w;
		renderer->bufferRect[3] = h;

		/* Make the context the current context */
		glMakeCurrentRenderer(renderer);

		/* finally, try to enable multithreaded OpenGL */
		if (0) /* disable it, because it's broken */
		{
			CGLContextObj cglContext = CGLGetCurrentContext();
			CGLError cglErr =  CGLEnable( cglContext, kCGLCEMPEngine);
			if (cglErr != kCGLNoError ) {
				DPRINTF3D(3,("CGLEnable(kCGLCEMPEngine) failed: cannot set multithreaded OpenGL\n"));
				exit(0);
			}
		}

		/* print some information about the context */
		string = (char*) glGetString(GL_VENDOR);
		DPRINTF3D(3,("\nOpenGL vendor: %s\n", string));
		string = (char*) glGetString(GL_RENDERER);
		DPRINTF3D(3,("OpenGL renderer: %s\n", string));
		string = (char*) glGetString(GL_VERSION);
		DPRINTF3D(3,("OpenGL version: %s\n", string));
		string = (char*) glGetString(GL_EXTENSIONS);
		DPRINTF3D(3,("OpenGL extensions: %s\n", string));
		ERROR_CHECK;

		DPRINTF3D(3, ("### Renderer created! (id = %d)\n", index));
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
		ERROR_CHECK;
		glShadeModel(GL_SMOOTH);
		ERROR_CHECK_1("glShadeModel");
		glLightModelfv(GL_LIGHT_MODEL_AMBIENT, blackLight);
		ERROR_CHECK_1("glLightModelfv");

		return index;
FAILED:
		if(ctx) aglDestroyContext(ctx);
		if(renderer->gWorld) DisposeGWorld(renderer->gWorld);
	}
	return -1;
}

/*****************************************************************************/
/*****************************************************************************/

int glGetIntPropertyOS(int handle, int prop)
{
	GLint v;
	glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

	switch(prop) {
		case -1: /* vertical blank synchronization */
			aglGetInteger(renderer->context, AGL_SWAP_INTERVAL, &v);
			return v;
	}
	return 0;
}

int glSetIntPropertyOS(int handle, int prop, int value)
{
	glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

	switch(prop) {
		case -1: /* vertical blank synchronization */
			aglSetInteger(renderer->context, AGL_SWAP_INTERVAL, (GLint*) &value);
			return 1;
	}
	return 0;
}


glRenderer *glRendererFromHandle(int handle) {
	DPRINTF3D(7, ("Looking for renderer id: %d\n", handle));
	if(handle < 0 || handle >= MAX_RENDERER) return NULL;
	if(allRenderer[handle].used) return allRenderer+handle;
	return NULL;
}

int glSwapBuffers(glRenderer *renderer) {
	GLint err;

	assert(!glErr);
	ERROR_CHECK_1("glErr already set on calling glSwapBuffers");
	if(!renderer) return 0;
	if(!renderer->used || !renderer->context) return 0;
	if(renderer->drawable) {
#ifdef BROWSERPLUGIN
		NP_Port	*anNPPort;

		anNPPort = getNP_Port();
		if (!(anNPPort->portx == gPortX && anNPPort->porty == gPortY)) {
			return 0;
		}
#endif
		aglSwapBuffers(renderer->context);
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,("ERROR (aglSwapBuffers): aglGetError - %s\n", aglErrorString(err)));
		ERROR_CHECK_1("aglSwapBuffers");
	}
	else {
#if 0	/* No CopyBits or QDSwapPort in the Mac OS X 10.9 SDK */
		/* But off screen renderers don't appear to be used.  Fingers crossed. */
		WindowPtr win;
		Rect src, dst, portBounds;
		GrafPtr oldPort,winPort;
		Boolean portChanged;

		/* ensure execution for offscreen contexts */
		glFinish();
		ERROR_CHECK;
		/* Copy the image to the window */

		win =  getSTWindow();
		if(!win) return 0;

		winPort = (GrafPtr) GetWindowPort((WindowRef) win);
# ifdef BROWSERPLUGIN
		StartDraw();
# else
		portChanged = QDSwapPort(winPort, &oldPort);
		GetPortBounds((CGrafPtr) winPort,&portBounds);

//  Draw into the new port here

# endif
		SetRect(&src, 0, 0, renderer->bufferRect[2], renderer->bufferRect[3]);
		SetRect(&dst, renderer->bufferRect[0], renderer->bufferRect[1],
				renderer->bufferRect[0] + renderer->bufferRect[2],
				renderer->bufferRect[1] + renderer->bufferRect[3]);
		CopyBits(GetPortBitMapForCopyBits(renderer->gWorld), GetPortBitMapForCopyBits((CGrafPtr) winPort), &src, &dst, srcCopy, NULL);
# ifdef BROWSERPLUGIN
		EndDraw();
# else
		if (portChanged)
			QDSwapPort(oldPort, NULL);
# endif
#else /* 0 */
		DPRINTF3D(1,("ERROR glSwapBuffers: swapping of off-screen renderers UNIMPLEMENTED!\n"));
#endif
	}
	return 1;
}

int glMakeCurrentRenderer(glRenderer *renderer) {
	GLboolean ok;
	GLint err;

	if(current == renderer) return 1;
	if(renderer)
		if(!renderer->used || !renderer->context) return 0;
	// ERROR_CHECK;
	ok = aglSetCurrentContext(renderer ? renderer->context : NULL);
	if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,("ERROR (glMakeCurrentRenderer): aglGetError - %s\n", aglErrorString(err)));
	if(!ok) {
		DPRINTF3D(1, ("ERROR (glMakeCurrentRenderer): aglSetCurrentContext failed\n"));
		return 0;
	}
	// ERROR_CHECK;
	current = renderer;
	return 1;
}

int glSetBufferRect(int handle, int x, int y, int w, int h) {
	glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	if(renderer->drawable) {
		/* hardware renderer */
		GLboolean ok;
		GLenum err;
		GLint bufferRect[4];
		Rect	portRect;

#ifdef BROWSERPLUGIN
		AGLDrawable	win;
		NP_Port	*anNPPort;

		StartDraw();
		win = (AGLDrawable) getSTWindow();
		anNPPort = getNP_Port();

		GetPortBounds(GetWindowPort((WindowPtr)win),&portRect);
		bufferRect[0] = x - anNPPort->portx;
		bufferRect[1] = portRect.bottom - portRect.top - (y+h)  + anNPPort->porty;
		bufferRect[2] = w;
		bufferRect[3] = h;

		EndDraw();
#else
		GetPortBounds(GetWindowPort((WindowPtr) renderer->drawable),&portRect);
		bufferRect[0] = x;
		bufferRect[1] = portRect.bottom - portRect.top - (y+h);
		bufferRect[2] = w;
		bufferRect[3] = h;
#endif
		ok = aglSetInteger(renderer->context, AGL_BUFFER_RECT, bufferRect);
		if((err = aglGetError()) != AGL_NO_ERROR)
			DPRINTF3D(3,("aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
		if(!ok) return 0;
	} else {
		/* software renderer */
		if(renderer->bufferRect[2] != w && renderer->bufferRect[3] != h) {
			/* do not allow resizing the software renderer */
			return 0;
		}
	}
	renderer->bufferRect[0] = x;
	renderer->bufferRect[1] = y;
	renderer->bufferRect[2] = w;
	renderer->bufferRect[3] = h;
	return 1;
}


int glIsOverlayRenderer(int handle) {
#pragma unused(handle)
  /* we never use overlay renderers */
  return 0;
}

/***************************************************************************
 ***************************************************************************
					Module initializers
 ***************************************************************************
 ***************************************************************************/

int
glInitialize(void)
{
	int i;
	for (i = 0; i < MAX_RENDERER; i++)
		allRenderer[i].used = 0;

	glVerbosityLevel = 5;

	existingHook = setWindowChangedHook(windowChangedProc);
	return 1;
}

int
glShutdown(void)
{
	int i;
	for (i = 0; i < MAX_RENDERER; i++)
		if (allRenderer[i].used)
			glDestroyRenderer(i);
	setWindowChangedHook(existingHook);
	return 1;
}
