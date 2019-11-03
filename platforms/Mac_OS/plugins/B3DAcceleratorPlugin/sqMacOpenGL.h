#ifndef SQ_MAC_OPENGL_H
#define SQ_MAC_OPENGL_H

#define MAX_RENDERER 16
	
#if defined(__MWERKS__) 
#include <agl.h>
#include <gl.h>
#else
#include <AGL/agl.h>
#include <AGL/gl.h>
#endif
typedef struct glRenderer {
	GLint bufferRect[4];
	GLint viewport[4];

	int used;
	int finished;
	AGLContext context;

	/* hardware attributes */
	AGLDrawable drawable;

	/* software attributes */
	GWorldPtr gWorld;
	PixMapHandle pixMap;
	int depth;
	int pitch;
	unsigned char *bits;
} glRenderer;

#define GL_RENDERER_DEFINED 1

#endif /* SQ_MAC_OPENGL_H */
