#ifndef SQ_OPENGL_RENDERER_H
#define SQ_OPENGL_RENDERER_H

#if defined(macintoshSqueak)
# include "sqMacOpenGL.h"
#elif defined(WIN32)
# include "sqWin32OpenGL.h"
#elif defined(UNIX)
# include "sqUnixOpenGL.h"
#endif

#if !defined(GL_RENDERER_DEFINED)
typedef struct glRenderer {
	GLint bufferRect[4];
	GLint viewport[4];
} glRenderer;
#endif

struct glRenderer *glRendererFromHandle(int rendererHandle);
int glMakeCurrentRenderer(struct glRenderer *renderer);
int glSwapBuffers(struct glRenderer *renderer);


/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
static int glErr = GL_NO_ERROR; /* this is only for debug purposes */

static char *glErrString(void) {
	static char errString[50];

	switch(glErr) {
		case 0x0500: return "GL_INVALID_ENUM";
		case 0x0501: return "GL_INVALID_VALUE";
		case 0x0502: return "GL_INVALID_OPERATION";
		case 0x0503: return "GL_STACK_OVERFLOW";
		case 0x0504: return "GL_STACK_UNDERFLOW";
		case 0x0505: return "GL_OUT_OF_MEMORY";
	}
	sprintf(errString, "error code %d", glErr);
	return errString;
}

#define ERROR_CHECK_2(glFn, sqFn) \
	{ if( (glErr = glGetError()) != GL_NO_ERROR) DPRINTF3D(1, (fp,"ERROR (%s): %s failed -- %s\n", sqFn, glFn, glErrString())); }

#define ERROR_CHECK_1(glFn) \
	{ if( (glErr = glGetError()) != GL_NO_ERROR) DPRINTF3D(1, (fp,"ERROR (file %s, line %d): %s failed -- %s\n", __FILE__, __LINE__, glFn, glErrString())); }

#define ERROR_CHECK ERROR_CHECK_1("a GL function")

/* Verbose level for debugging purposes:
	0 - print NO information ever
	1 - print critical debug errors
	2 - print debug warnings
	3 - print extra information
	4 - print per-frame statistics
	5 - print information about textures, lights, materials, and primitives
	6 - print information about background synchronization

   10 - print information about each vertex and face
*/
extern int verboseLevel;

/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
#undef DPRINTF3D
# define DPRINTF3D(vLevel, args) if(vLevel <= verboseLevel) {\
	FILE *fp = fopen("Squeak3D.log", "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}


#endif /* sqOpenGLRenderer.h */
