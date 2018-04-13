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
	#include <unistd.h>
	#include <AGL/agl.h>
	#include <AGL/gl.h>
#include <OpenGL/OpenGL.h>
/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
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
typedef int (*eventMessageHook)(EventRecord* event);

#ifdef SQUEAK_BUILTIN_PLUGIN
#ifdef BROWSERPLUGIN
int gPortX,gPortY;
extern NP_Port *getNP_Port(void);
#endif
void StartDraw(void);
void EndDraw(void);
extern WindowPtr getSTWindow(void);
extern int setMessageHook(eventMessageHook theHook);
extern int setPostMessageHook(eventMessageHook theHook);
extern GDHandle getDominateDevice(WindowPtr theWindow,Rect *windRect);
#else
typedef WindowPtr (*getSTWindowFn)(void);
getSTWindowFn getSTWindow = 0;
eventMessageHook setMessageHook = 0;
#endif


/* Verbose level for debugging purposes:
	0 - print NO information ever
	1 - print critical debug errors
	2 - print debug warnings
	3 - print extra information
	4 - print extra warnings
	5 - print information about primitive execution

   10 - print information about each vertex and face
*/
extern int verboseLevel;
/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
#undef DPRINTF3D
# define DPRINTF3D(vLevel, args) if(vLevel <= verboseLevel) {\
	char fileName[DOCUMENT_NAME_SIZE+1]; \
	sqFilenameFromStringOpen(fileName,(sqInt) &"Squeak3D.log", strlen("Squeak3D.log")); \
	FILE *fp = fopen(fileName, "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}
        
/* Plugin refs */
extern struct VirtualMachine *interpreterProxy;
static float blackLight[4] = { 0.0f, 0.0f, 0.0f, 0.0f };

/*****************************************************************************/
/*****************************************************************************/
/*                      Mac event hook                                       */
/*****************************************************************************/
/*****************************************************************************/

static int macEventHook(EventRecord *event) {
	AGLDrawable win;
	int result;
	int i,windowCode;
	Boolean windowHasChanged=false;
	WindowPtr checkMouseDown,checkMouseUp;
	static WindowPtr oldWindow = NULL;

#ifdef BROWSERPLUGIN
	NP_Port	*anNPPort;
	
#endif		

	if (oldWindow == NULL) 
		oldWindow = getSTWindow();
	
	result = 0;
	switch(event->what) {
		case osEvt:
			if (((event->message>>24)& 0xFF) != suspendResumeMessage) return 0;
			DPRINTF3D(5, (fp, "<Mac event: suspendResumeMessage>\n"));
			break;
		case activateEvt:
			DPRINTF3D(5, (fp, "<Mac event: activateEvt>\n"));
			break;
		case updateEvt:
			DPRINTF3D(5, (fp, "<Mac event: updateEvt>\n"));
			break;
		case mouseDown:
			DPRINTF3D(5, (fp, "<Mac event: mouseDown>\n"));
			windowCode = FindWindow(event->where, &checkMouseDown);
			if (windowCode == inContent)
				return 0;

			break;
		case mouseUp:
			DPRINTF3D(5, (fp, "<Mac event: mouseUp>\n"));
			windowCode = FindWindow(event->where, &checkMouseUp);
			if (windowCode == inContent)
				return 0;

			break;
		default: 
			#ifdef BROWSERPLUGIN
			if (oldWindow != getSTWindow()) {																						
				windowHasChanged = true;
			}
			
			anNPPort = getNP_Port();
			if (!(anNPPort->portx == gPortX && anNPPort->porty == gPortY)) {
				windowHasChanged = true;
			}
			
			if (windowHasChanged) 
				break;
			#endif
			
			return 0;
			
	}
	win = (AGLDrawable) getSTWindow();
	if(!win) return 0;
	for(i=0; i< MAX_RENDERER; i++) {
		glRenderer *renderer = allRenderer+i;
		if(renderer->used) {
			if (renderer->drawable == win || (WindowPtr) renderer->drawable == oldWindow) {
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
				windowHasChanged = false;
				#ifdef BROWSERPLUGIN
					EndDraw();
				#endif
			} 
		}
	}
	oldWindow = getSTWindow();
	return result;
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


int glCreateRendererFlags(int x, int y, int w, int h, int flags)
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
	GDHandle tempGDH;
        Rect ignore;
 	long swapInterval = 0;

 #define SUPPORTED_FLAGS (B3D_HARDWARE_RENDERER | B3D_SOFTWARE_RENDERER | B3D_STENCIL_BUFFER | B3D_ANTIALIASING | B3D_STEREO | B3D_SYNCVBL)
         if(flags & ~SUPPORTED_FLAGS) {
             DPRINTF3D(1, (fp, "ERROR: Unsupported renderer flags (%d)\n", flags));
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
		DPRINTF3D(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
		return 0;
	}
	renderer = allRenderer+index;
	renderer->used = 0;
	renderer->finished = 0;
	renderer->context = NULL;
	renderer->drawable = NULL;
	renderer->gWorld = NULL;

#ifdef SQUEAK_BUILTIN_PLUGIN
	if (! getSTWindow()) {
		return 0;
	}
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
			DPRINTF3D(3, (fp, "### Attempting to find hardware renderer\n"));
			win = (AGLDrawable) getSTWindow();
			if(!win) {
				DPRINTF3D(1, (fp, "ERROR: stWindow is invalid (NULL)\n"));
				goto FAILED;
			}
			fmt = aglChoosePixelFormat(NULL, 0, hwAttrib);
		} else {
			DPRINTF3D(3, (fp, "### Attempting to find software renderer\n"));
			win = NULL;
			fmt = aglChoosePixelFormat(NULL, 0, swAttrib);
		}
		DPRINTF3D(3, (fp,"\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));

		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
		if(fmt == NULL) {
			DPRINTF3D(1, (fp, "ERROR: aglChoosePixelFormat failed\n"));
			goto FAILED;
		}

		printFormatInfo(fmt);

		/* Create an AGL context */
		ctx = aglCreateContext(fmt, NULL);
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
		/* The pixel format is no longer needed */
		aglDestroyPixelFormat(fmt);
		if(ctx == NULL) {
			DPRINTF3D(1, (fp, "ERROR: aglCreateContext failed\n"));
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
				DPRINTF3D(3,(fp,"aglEnable(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			ok = aglSetInteger(ctx, AGL_BUFFER_RECT, bufferRect);
			if((err = aglGetError()) != AGL_NO_ERROR) 
				DPRINTF3D(3,(fp,"aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			/* Attach the context to the target */
			ok = aglSetDrawable(ctx,GetWindowPort( (WindowPtr)win));
			if((err = aglGetError()) != AGL_NO_ERROR) 
				DPRINTF3D(3,(fp,"aglSetDrawable() failed: aglGetError - %s\n", aglErrorString(err)));
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
				DPRINTF3D(1,(fp,"ERROR: Failed to create new GWorld\n"));
				renderer->gWorld = NULL;
				goto FAILED;
			}
			renderer->pixMap = GetGWorldPixMap(renderer->gWorld);
			LockPixels(renderer->pixMap);
			renderer->pitch = (**(renderer->pixMap)).rowBytes & 0x7FFF;
			renderer->bits = (unsigned char*) GetPixBaseAddr(renderer->pixMap);
			ok = aglSetOffScreen(ctx, w, h, renderer->pitch, renderer->bits);
			if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
			if(!ok) {
				DPRINTF3D(1, (fp, "ERROR: aglSetOffScreen failed\n"));
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
				DPRINTF3D(3,(fp,"CGLEnable(kCGLCEMPEngine) failed: cannot set multithreaded OpenGL\n"));
				exit(0);
			}
		}

		/* print some information about the context */
		string = (char*) glGetString(GL_VENDOR);
		DPRINTF3D(3,(fp, "\nOpenGL vendor: %s\n", string));
		string = (char*) glGetString(GL_RENDERER);
		DPRINTF3D(3,(fp, "OpenGL renderer: %s\n", string));
		string = (char*) glGetString(GL_VERSION);
		DPRINTF3D(3,(fp, "OpenGL version: %s\n", string));
		string = (char*) glGetString(GL_EXTENSIONS);
		DPRINTF3D(3,(fp, "OpenGL extensions: %s\n", string));
		ERROR_CHECK;

		DPRINTF3D(3, (fp,"### Renderer created! (id = %d)\n", index));
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
	DPRINTF3D(7, (fp, "Looking for renderer id: %d\n", handle));
	if(handle < 0 || handle >= MAX_RENDERER) return NULL;
	if(allRenderer[handle].used) return allRenderer+handle;
	return NULL;
}

int glSwapBuffers(glRenderer *renderer) {
	GLint err;

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
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,(fp,"ERROR (glSwapBuffers): aglGetError - %s\n", aglErrorString(err)));
		ERROR_CHECK;
	} else {
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
#ifdef BROWSERPLUGIN
		StartDraw();
#else
		portChanged = QDSwapPort(winPort, &oldPort);
		GetPortBounds((CGrafPtr) winPort,&portBounds);

//  Draw into the new port here

#endif		
		SetRect(&src, 0, 0, renderer->bufferRect[2], renderer->bufferRect[3]);
		SetRect(&dst, renderer->bufferRect[0], renderer->bufferRect[1], 
				renderer->bufferRect[0] + renderer->bufferRect[2],
				renderer->bufferRect[1] + renderer->bufferRect[3]);
		CopyBits(GetPortBitMapForCopyBits(renderer->gWorld), GetPortBitMapForCopyBits((CGrafPtr) winPort), &src, &dst, srcCopy, NULL);
#ifdef BROWSERPLUGIN
		EndDraw();
#else
		if (portChanged)
			QDSwapPort(oldPort, NULL);
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
	if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF3D(3,(fp,"ERROR (glMakeCurrentRenderer): aglGetError - %s\n", aglErrorString(err)));
	if(!ok) {
		DPRINTF3D(1, (fp, "ERROR (glMakeCurrentRenderer): aglSetCurrentContext failed\n"));
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
			DPRINTF3D(3,(fp,"aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
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

int glSetVerboseLevel(int level) {
	verboseLevel = level;
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

int glInitialize(void)
{
	int i;
	for(i = 0; i < MAX_RENDERER; i++) {
		allRenderer[i].used = 0;
	}
#ifdef SQUEAK_BUILTIN_PLUGIN
	setPostMessageHook(macEventHook);
#else
	getSTWindow = (getSTWindowFn) interpreterProxy->ioLoadFunctionFrom("getSTWindow", "");
	if(!getSTWindow) {
		DPRINTF3D(1,(fp,"ERROR: Failed to look up getSTWindow()\n"));
		return 0;
	}
	setMessageHook = (eventMessageHook) interpreterProxy->ioLoadFunctionFrom("setPostMessageHook", "");
	if(!setMessageHook) {
		DPRINTF3D(1, (fp, "ERROR: Failed to look up setMessageHook()\n"));
		return 0;
	}
	((void (*)(void*))setMessageHook)(macEventHook);
#endif
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

