#ifndef SQ_OPENGL_RENDERER_H
#define SQ_OPENGL_RENDERER_H

#if defined(macintoshSqueak)
# include "sqMacOpenGL.h"
#elif defined(_WIN32)
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


/***************************************************************************/
/***************************************************************************/
/* Debug Logging/Error Reporting to Squeak3D.log in the image's directory. */
/***************************************************************************/
/***************************************************************************/

#define ERROR_CHECK_2(glFn, sqFn) \
	{ if( (glErr = glGetError()) != GL_NO_ERROR) DPRINTF3D(1, ("ERROR (%s): %s failed -- %s\n", sqFn, glFn, glErrString())); }

#define ERROR_CHECK_1(glFn) \
	{ if( (glErr = glGetError()) != GL_NO_ERROR) DPRINTF3D(1, ("ERROR (file %s, line %d): %s failed -- %s\n", __FILE__, __LINE__, glFn, glErrString())); }

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
extern int glVerbosityLevel;
extern int glErr;
extern char *glErrString(void);

/* Note: Print this stuff into a file in case we lock up */
extern int print3Dlog(char *fmt, ...);

/* define forceFlush if we should fflush() after each write */
#define forceFlush 1

#define DPRINTF3D(v,a) do { if ((v) <= glVerbosityLevel) print3Dlog a; } while (0)

#endif /* sqOpenGLRenderer.h */
