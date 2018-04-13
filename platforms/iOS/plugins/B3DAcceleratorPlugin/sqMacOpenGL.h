#ifndef SQ_MAC_OPENGL_H
#define SQ_MAC_OPENGL_H

#define MAX_RENDERER 16
	
# import <OpenGL/gl.h>
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
# import <OpenGL/OpenGL.h>
#else
# import <OpenGL/Opengl.h>
#endif

typedef struct glRendererFramebuffer {
	GLuint handle;
	GLuint texture;
	GLuint depthStencilBuffer;
	
	GLuint resolveFramebuffer;
	GLuint multisampleColorbuffer;
} glRendererFramebuffer;

typedef struct glRenderer {
    /* Required by the common implementation */
	GLint bufferRect[4];
	GLint viewport[4];
    
    int used;

    void* theOpenGLContext;
    unsigned int layerHandle;
    
	// Multi sampling
	int hasMultisampling;
	int sampleCount;
	
	// Depth and stencil buffer
	int hasStencilBuffer;
	GLenum depthStencilFormat;
	
	glRendererFramebuffer framebuffers[2];
	unsigned int backBufferIndex;
    
} glRenderer;

#define GL_RENDERER_DEFINED 1

#endif /* SQ_MAC_OPENGL_H */
