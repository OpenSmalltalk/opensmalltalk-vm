/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqMacOpenGL.c
*   CONTENT: MacOS specific bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqMacOpenGL.c,v 1.1 2001/10/24 23:13:25 rowledge Exp $
* 
*   NOTES:
*
*	Changes May 14th 2001 John M McIntosh Carbon support
*   Changes Jun 2001 JMM browser internal plugin support
*
*****************************************************************************/
#include <stdio.h>
#include <stdlib.h>

#include <QuickDraw.h>
#include <Windows.h>
#if !defined ( __APPLE__ ) && !defined ( __MACH__ )
#include <GL/gl.h>
#else
#include <gl.h>
#endif
#include <agl.h> 
#include <Events.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "B3DAcceleratorPlugin.h"
#include "sqMacOpenGL.h"
#include "sqOpenGLRenderer.h"

//#define PLUGIN
#ifdef PLUGIN
	#define BROWSERPLUGIN
#endif

#define INTERNAL

#ifdef BROWSERPLUGIN
#include "npapi.h"
#endif

#if TARGET_API_MAC_CARBON
#else
        inline Rect *GetPortBounds(CGrafPtr w,Rect *r) { *r = w->portRect; return &w->portRect;}  
        inline BitMap * GetPortBitMapForCopyBits (CGrafPtr w) { return &((GrafPtr)w)->portBits;}
#endif

int printRendererInfo(void);
int printFormatInfo(AGLPixelFormat info);

glRenderer *current = NULL;
static int fUseSoftwareRenderer = 1;
glRenderer allRenderer[MAX_RENDERER];
typedef int (*eventMessageHook)(EventRecord* event);

#ifdef INTERNAL
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
#undef DPRINTF
# define DPRINTF(vLevel, args) if(vLevel <= verboseLevel) {\
	FILE *fp = fopen("Squeak3D.log", "at");\
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
			DPRINTF(5, (fp, "<Mac event: suspendResumeMessage>\n"));
			break;
		case activateEvt:
			DPRINTF(5, (fp, "<Mac event: activateEvt>\n"));
			break;
		case updateEvt:
			DPRINTF(5, (fp, "<Mac event: updateEvt>\n"));
			break;
		case mouseDown:
			DPRINTF(5, (fp, "<Mac event: mouseDown>\n"));
			windowCode = FindWindow(event->where, &checkMouseDown);
			if (windowCode == inContent)
				return 0;

			break;
		case mouseUp:
			DPRINTF(5, (fp, "<Mac event: mouseUp>\n"));
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

				aglSetDrawable(renderer->context,nil);
				renderer->drawable = (AGLDrawable) win;		
				aglSetInteger(renderer->context, AGL_BUFFER_RECT, bufferRect);
				aglUpdateContext(renderer->context);
				aglSetDrawable(renderer->context,windowPort);
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

int glCreateRenderer(int allowSoftware, int allowHardware, int x, int y, int w, int h)
{
	int index, i;
	GLint          hwAttrib[] = { AGL_RGBA, AGL_DOUBLEBUFFER, AGL_ACCELERATED, AGL_DEPTH_SIZE, 16, AGL_NONE };
	GLint          swAttrib[] = { AGL_RGBA, AGL_PIXEL_SIZE, 0, AGL_OFFSCREEN, AGL_DEPTH_SIZE, 16, AGL_NONE };
	AGLPixelFormat fmt;
	AGLContext     ctx;
	GLboolean      ok;
	GLenum         err;
	AGLDrawable    win;
	glRenderer	   *renderer;
	char *string;
	GDHandle tempGDH;
    Rect ignore;

	for(index=0; index < MAX_RENDERER; index++) {
		if(allRenderer[index].used == 0) break;
	}
	if(index >= MAX_RENDERER) {
		DPRINTF(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\n", MAX_RENDERER));
		return 0;
	}
	renderer = allRenderer+index;
	renderer->used = 0;
	renderer->finished = 0;
	renderer->context = NULL;
	renderer->drawable = NULL;
	renderer->gWorld = NULL;

#ifdef INTERNAL
    tempGDH = getDominateDevice(getSTWindow(),&ignore);
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
			DPRINTF(3, (fp, "### Attempting to find hardware renderer\n"));
			win = (AGLDrawable) getSTWindow();
			if(!win) {
				DPRINTF(1, (fp, "ERROR: stWindow is invalid (NULL)\n"));
				goto FAILED;
			}
			fmt = aglChoosePixelFormat(NULL, 0, hwAttrib);
		} else {
			DPRINTF(3, (fp, "### Attempting to find software renderer\n"));
			win = NULL;
			fmt = aglChoosePixelFormat(NULL, 0, swAttrib);
		}
		DPRINTF(3, (fp,"\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));

		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
		if(fmt == NULL) {
			DPRINTF(1, (fp, "ERROR: aglChoosePixelFormat failed\n"));
			goto FAILED;
		}

		printFormatInfo(fmt);

		/* Create an AGL context */
		ctx = aglCreateContext(fmt, NULL);
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
		/* The pixel format is no longer needed */
		aglDestroyPixelFormat(fmt);
		if(ctx == NULL) {
			DPRINTF(1, (fp, "ERROR: aglCreateContext failed\n"));
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
				DPRINTF(3,(fp,"aglEnable(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			ok = aglSetInteger(ctx, AGL_BUFFER_RECT, bufferRect);
			if((err = aglGetError()) != AGL_NO_ERROR) 
				DPRINTF(3,(fp,"aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			/* Attach the context to the target */
			ok = aglSetDrawable(ctx,GetWindowPort( (WindowPtr)win));
			if((err = aglGetError()) != AGL_NO_ERROR) 
				DPRINTF(3,(fp,"aglSetDrawable() failed: aglGetError - %s\n", aglErrorString(err)));
			if(!ok) goto FAILED;
			renderer->drawable = (AGLDrawable) win;
		} else {
			/* software renderer; attach offscreen buffer to context */
			Rect rect;
			QDErr qdErr;

			renderer->depth = swAttrib[2];
			/* Create the offscreen gworld */
			SetRect(&rect, 0, 0, w, h);
			qdErr = NewGWorld(&renderer->gWorld, (short) renderer->depth, &rect, NULL, NULL, useTempMem);
			if(qdErr || !renderer->gWorld) {
				DPRINTF(1,(fp,"ERROR: Failed to create new GWorld\n"));
				renderer->gWorld = NULL;
				goto FAILED;
			}
			renderer->pixMap = GetGWorldPixMap(renderer->gWorld);
			LockPixels(renderer->pixMap);
			renderer->pitch = (**(renderer->pixMap)).rowBytes & 0x7FFF;
			renderer->bits = (unsigned char*) GetPixBaseAddr(renderer->pixMap);
			ok = aglSetOffScreen(ctx, w, h, renderer->pitch, renderer->bits);
			if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF(3,(fp,"aglGetError - %s\n", aglErrorString(err)));
			if(!ok) {
				DPRINTF(1, (fp, "ERROR: aglSetOffScreen failed\n"));
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

		/* print some information about the context */
		string = (char*) glGetString(GL_VENDOR);
		DPRINTF(3,(fp, "\nOpenGL vendor: %s\n", string));
		string = (char*) glGetString(GL_RENDERER);
		DPRINTF(3,(fp, "OpenGL renderer: %s\n", string));
		string = (char*) glGetString(GL_VERSION);
		DPRINTF(3,(fp, "OpenGL version: %s\n", string));
		string = (char*) glGetString(GL_EXTENSIONS);
		DPRINTF(3,(fp, "OpenGL extensions: %s\n", string));
		ERROR_CHECK;

		DPRINTF(3, (fp,"### Renderer created! (id = %d)\n", index));
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

int glGetIntProperty(int handle, int prop)
{
	GLint v;
	glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

	switch(prop) {
		case -1: /* vertical blank synchronization */
			aglGetInteger(renderer->context, AGL_SWAP_INTERVAL, &v);
			return v;
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
		case -1: /* vertical blank synchronization */
			aglSetInteger(renderer->context, AGL_SWAP_INTERVAL, (GLint*) &value);
			return 1;
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


glRenderer *glRendererFromHandle(int handle) {
	DPRINTF(7, (fp, "Looking for renderer id: %d\n", handle));
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
		if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF(3,(fp,"ERROR (glSwapBuffers): aglGetError - %s\n", aglErrorString(err)));
		ERROR_CHECK;
	} else {
		WindowPtr win;
		Rect src, dst, portBounds;
		GrafPtr oldPort;
		
		/* ensure execution for offscreen contexts */
		glFinish();
		ERROR_CHECK;
		/* Copy the image to the window */
		
		win =  getSTWindow();
		if(!win) return 0;
		
#ifdef BROWSERPLUGIN
		StartDraw();
#else
		GetPort(&oldPort);
		SetPortWindowPort(win);
		GetPortBounds((CGrafPtr) win,&portBounds);
#endif		
		SetRect(&src, 0, 0, renderer->bufferRect[2], renderer->bufferRect[3]);
		SetRect(&dst, renderer->bufferRect[0], renderer->bufferRect[1], 
				renderer->bufferRect[0] + renderer->bufferRect[2],
				renderer->bufferRect[1] + renderer->bufferRect[3]);
		CopyBits(GetPortBitMapForCopyBits(renderer->gWorld), GetPortBitMapForCopyBits(GetWindowPort(win)), &src, &dst, srcCopy, NULL);
#ifdef BROWSERPLUGIN
		EndDraw();
#else
		SetPort(oldPort);
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
	ERROR_CHECK;
	ok = aglSetCurrentContext(renderer ? renderer->context : NULL);
	if((err = aglGetError()) != AGL_NO_ERROR) DPRINTF(3,(fp,"ERROR (glMakeCurrentRenderer): aglGetError - %s\n", aglErrorString(err)));
	if(!ok) {
		DPRINTF(1, (fp, "ERROR (glMakeCurrentRenderer): aglSetCurrentContext failed\n"));
		return 0;
	}
	ERROR_CHECK;
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
			DPRINTF(3,(fp,"aglSetInteger(AGL_BUFFER_RECT) failed: aglGetError - %s\n", aglErrorString(err)));
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
#ifdef INTERNAL
	setPostMessageHook(macEventHook);
#else
	getSTWindow = (getSTWindowFn) interpreterProxy->ioLoadFunctionFrom("getSTWindow", "");
	if(!getSTWindow) {
		DPRINTF(1,(fp,"ERROR: Failed to look up getSTWindow()\n"));
		return 0;
	}
	setMessageHook = (eventMessageHook) interpreterProxy->ioLoadFunctionFrom("setPostMessageHook", "");
	if(!setMessageHook) {
		DPRINTF(1, (fp, "ERROR: Failed to look up setMessageHook()\n"));
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

