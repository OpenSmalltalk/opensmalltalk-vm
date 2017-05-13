/**
 * Author: Ronie Salgado <roniesalg@gmail.com>
 * License: MIT
 * Based loosely on the previous implementation by Andreas Raab.
 *
 * Offscreen based glRenderer for the B3DAcceleratorPlugin. This uses the OpenGL
 * framebuffer object facility to render into a offscreen texture that is
 * shared with the OpenGL context of the main window. This is implemented in
 * this way with the objective to cooperate with the OpenGL context of the main
 * window by using a custom layering system.
 */
#include <stdio.h>
#include <stdlib.h>

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
#include "sqAssert.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"
#include "B3DAcceleratorPlugin.h"
#include "sqMacOpenGL.h"
#include "sqOpenGLRenderer.h"

static glRenderer *currentGLRenderer = NULL;
static glRenderer allRenderer[MAX_RENDERER];

extern NSOpenGLContext *getMainWindowOpenGLContext(void);
extern unsigned int createOpenGLTextureLayerHandle(void);
extern void destroyOpenGLTextureLayerHandle(unsigned int handle);
extern void setOpenGLTextureLayerContent(unsigned int handle, GLuint texture, int x, int y, int w, int h);

static float blackLight[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
    
int
glIsOverlayRenderer(int handle)
{
  return 0;
}

glRenderer *
glRendererFromHandle(int handle) {
    if(handle < 0 || handle >= MAX_RENDERER) return NULL;
    if(allRenderer[handle].used) return &allRenderer[handle];
    return NULL;
}

/*****************************************************************************/
/*****************************************************************************/
/*                      Renderer creation primitives                         */
/*****************************************************************************/
/*****************************************************************************/

static int
hasExtension(const char *extensionName) {
    return strstr((const char*)glGetString(GL_EXTENSIONS), extensionName) != NULL;
}

static NSOpenGLPixelFormat *
createPixelFormat(int flags)
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers, // Enables automatic graphics card switching
        NSOpenGLPFADepthSize, 0,
        NSOpenGLPFAStencilSize, 0,
        0
    };
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
};

static void
createTextureStorage(glRenderer *renderer, GLuint texture, int w, int h)
{
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
}

static void
createRenderbuffersStorage(glRenderer *renderer, glRendererFramebuffer *framebuffer, int w, int h)
{
    if(renderer->hasMultisampling) {
        glBindRenderbufferEXT(GL_RENDERBUFFER, framebuffer->multisampleColorbuffer);
        glRenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, renderer->sampleCount, GL_RGBA, w, h);

        glBindRenderbufferEXT(GL_RENDERBUFFER, framebuffer->depthStencilBuffer);
        glRenderbufferStorageMultisampleEXT(GL_RENDERBUFFER, renderer->sampleCount, renderer->depthStencilFormat, w, h);
    } else {
        glBindRenderbufferEXT(GL_RENDERBUFFER, framebuffer->depthStencilBuffer);
        glRenderbufferStorageEXT(GL_RENDERBUFFER, renderer->depthStencilFormat, w, h);
    }
}

static void
createRendererFramebuffer(glRenderer *renderer, glRendererFramebuffer *framebuffer, int w, int h)
{
    if(!framebuffer->handle) {
        // Create the handles
        glGenFramebuffersEXT(1, &framebuffer->handle);
        glGenTextures(1, &framebuffer->texture);
        glGenRenderbuffers(1, &framebuffer->depthStencilBuffer);
        if(renderer->hasMultisampling) {
            glGenFramebuffersEXT(1, &framebuffer->resolveFramebuffer);
            glGenRenderbuffers(1, &framebuffer->multisampleColorbuffer);
        }
        
        // Create the texture storage
        createTextureStorage(renderer, framebuffer->texture, w, h);
        
        // Create the render buffer storage
        createRenderbuffersStorage(renderer, framebuffer, w, h);
        
        if(renderer->hasMultisampling) {
            // Link the texture with the resolve framebuffer
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer->resolveFramebuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, framebuffer->texture, 0);
            
            // Link the framebuffer with the multi-sample render buffers.
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer->handle);
            glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_RENDERBUFFER_EXT, framebuffer->multisampleColorbuffer);
        } else {
            // Link the texture with the framebuffer
            glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer->handle);
            glFramebufferTexture2D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, framebuffer->texture, 0);
        }

        // Link the depth stencil buffer
        if(renderer->hasStencilBuffer)
            glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_STENCIL_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, framebuffer->depthStencilBuffer);
        glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, framebuffer->depthStencilBuffer);
    } else {
        // Recreate the sizes
        createTextureStorage(renderer, framebuffer->texture, w, h);
        createRenderbuffersStorage(renderer, framebuffer, w, h);
    }
    
    if(renderer->hasMultisampling) {
        // Check the framebuffer status.
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer->resolveFramebuffer);
        GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
        if(status != GL_FRAMEBUFFER_COMPLETE_EXT) {
            fprintf(stderr, "OpenGL resolve FBO is not complete: %04x\n", status);
        }
    }
    
    // Check the framebuffer status.
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer->handle);
    GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    if(status != GL_FRAMEBUFFER_COMPLETE_EXT) {
        fprintf(stderr, "OpenGL FBO is not complete: %04x\n", status);
    }
}

static void
destroyRendererFramebuffer(glRenderer *renderer, glRendererFramebuffer *framebuffer)
{
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glBindRenderbuffer(GL_RENDERBUFFER_EXT, 0);
    glDeleteFramebuffersEXT(1, &framebuffer->handle);
    if(renderer->hasMultisampling)
        glDeleteFramebuffersEXT(1, &framebuffer->resolveFramebuffer);

    glDeleteTextures(1, &framebuffer->texture);
    glDeleteRenderbuffers(1, &framebuffer->depthStencilBuffer);
    if(renderer->hasMultisampling)
        glDeleteRenderbuffers(1, &framebuffer->multisampleColorbuffer);
}

static void
createRendererFramebuffers(glRenderer *renderer, int w, int h)
{
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
    createRendererFramebuffer(renderer, &renderer->framebuffers[0], w, h);
    createRendererFramebuffer(renderer, &renderer->framebuffers[1], w, h);
    
    glBindFramebufferEXT(GL_FRAMEBUFFER, renderer->framebuffers[renderer->backBufferIndex].handle);
}

int
glCreateRendererFlags(int x, int y, int w, int h, int flags)
{    
    // Get the main opengl context
    NSOpenGLContext *mainOpenGLContext = getMainWindowOpenGLContext();
    if(!mainOpenGLContext)
        return -1;
        
    // Find a free renderer slot.
    int handle;
    for(handle=0; handle < MAX_RENDERER; handle++) {
        if(allRenderer[handle].used == 0)
            break;
    }
    if(handle >= MAX_RENDERER)
        return -1;
    
    // Allocate the layer, for compositing.    
    glRenderer *renderer = &allRenderer[handle];
    memset(renderer, 0, sizeof(glRenderer));
    renderer->layerHandle = createOpenGLTextureLayerHandle();
    if(!renderer->layerHandle)
        return -1;
    
    // Create the OpenGL context.
    NSOpenGLPixelFormat *pixelFormat = createPixelFormat(flags);
    
    NSOpenGLContext *theContext = [[NSOpenGLContext alloc] initWithFormat: pixelFormat shareContext: mainOpenGLContext];
    [pixelFormat dealloc];
    
    // Make sure that the context is created successfully.
    if(!theContext) {
        destroyOpenGLTextureLayerHandle(renderer->layerHandle);
        return -1;
    }
    
    renderer->theOpenGLContext = theContext;
    renderer->used = 1;
    renderer->bufferRect[0] = x;
    renderer->bufferRect[1] = y;
    renderer->bufferRect[2] = w;
    renderer->bufferRect[3] = h;
    
    // Activate the context
    [theContext makeCurrentContext];

    renderer->hasMultisampling = (flags & B3D_ANTIALIASING) && hasExtension("GL_ARB_multisample") && hasExtension("GL_EXT_framebuffer_multisample"); 
    renderer->sampleCount = 4;
    renderer->hasStencilBuffer = (flags & B3D_STENCIL_BUFFER) != 0;
    renderer->depthStencilFormat = renderer->hasStencilBuffer ? GL_DEPTH24_STENCIL8_EXT : GL_DEPTH_COMPONENT16;
    
    // Print some information about the context
    DPRINTF3D(3,("\nOpenGL vendor: %s\n", (const char*)glGetString(GL_VENDOR)));
    DPRINTF3D(3,("OpenGL renderer: %s\n", (const char*)glGetString(GL_RENDERER)));
    DPRINTF3D(3,("OpenGL version: %s\n", (const char*)glGetString(GL_VERSION)));
    DPRINTF3D(3,("OpenGL extensions: %s\n", (const char*)glGetString(GL_EXTENSIONS)));
    
    createRendererFramebuffers(renderer, w, h);
    
    // Setup the context
    glViewport(0, 0, w, h);
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
    if(renderer->hasMultisampling)
        glEnable(GL_MULTISAMPLE_ARB);

    return handle;
}

void
deleteRendererResources(glRenderer *renderer)
{
    destroyOpenGLTextureLayerHandle(renderer->layerHandle);
    destroyRendererFramebuffer(renderer, &renderer->framebuffers[0]);
    destroyRendererFramebuffer(renderer, &renderer->framebuffers[1]);
}

int
glDestroyRenderer(int handle)
{
    glRenderer *renderer = glRendererFromHandle(handle);

    if(!renderer) {
        return 1; /* already destroyed */
    }
    
    NSOpenGLContext *context = (NSOpenGLContext*)renderer->theOpenGLContext;
    
    // Delete the potentially shared resources
    [context makeCurrentContext];
    deleteRendererResources(renderer);
    
    // Destroy the context.
    [NSOpenGLContext clearCurrentContext];
    [context release];
    
    currentGLRenderer = NULL;
    renderer->used = 0;
    return 1;
}

int
glMakeCurrentRenderer(glRenderer *renderer) {
    if(currentGLRenderer == renderer)
        return 1;
        
    if(renderer) {
        if(!renderer->used || !renderer->theOpenGLContext)
            return 0;
    }
    
    NSOpenGLContext *context = (NSOpenGLContext*)renderer->theOpenGLContext;
    [context makeCurrentContext];
    currentGLRenderer = renderer;
    
    return 1;
}

int
glSetBufferRect(int handle, int x, int y, int w, int h)
{
	glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer))
        return 0;
    
    // Do we need to resize the framebuffers?
    if(renderer->bufferRect[2] != w || renderer->bufferRect[3] != h) {
        createRendererFramebuffers(renderer, w, h);
    }
    
    renderer->bufferRect[0] = x;
    renderer->bufferRect[1] = y;
    renderer->bufferRect[2] = w;
    renderer->bufferRect[3] = h;
    return 1;
}

int
glGetIntPropertyOS(int handle, int prop)
{
    //TODO: Retrieve the swap interval
    return 0;
}

int
glSetIntPropertyOS(int handle, int prop, int value)
{
    //TODO: Set the swap interval
	return 0;
}

int glSwapBuffers(glRenderer *renderer)
{
	if(!renderer || !glMakeCurrentRenderer(renderer))
        return 0;
        
    // Resolve the multi-sampling.
    if(renderer->hasMultisampling) {
        int w = renderer->bufferRect[2];
        int h = renderer->bufferRect[3];
        glRendererFramebuffer *framebuffer = &renderer->framebuffers[renderer->backBufferIndex];
        glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, framebuffer->handle);
        glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, framebuffer->resolveFramebuffer);
        glBlitFramebufferEXT(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    }
        
    // Swap the buffer.
    int frontBuffer = renderer->backBufferIndex;
    renderer->backBufferIndex = (renderer->backBufferIndex + 1) % 2;
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, renderer->framebuffers[renderer->backBufferIndex].handle);
    glFlush();
    
    // Flush the new front buffer.
    setOpenGLTextureLayerContent(renderer->layerHandle, renderer->framebuffers[frontBuffer].texture,
        renderer->bufferRect[0], renderer->bufferRect[1], renderer->bufferRect[2], renderer->bufferRect[3]);
    return 1;
}

/***************************************************************************
 ***************************************************************************
					Module initializers
 ***************************************************************************
 ***************************************************************************/

int
glInitialize(void)
{
    memset(allRenderer, 0, sizeof(allRenderer));
    glVerbosityLevel = 5;
    return 1;
}

int
glShutdown(void)
{
	int i;
	for (i = 0; i < MAX_RENDERER; i++) {
		if (allRenderer[i].used) {
			glDestroyRenderer(i);
        }
    }
    return 1;
}
