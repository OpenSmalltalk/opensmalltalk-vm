#ifndef __sqUnixOpenGL_h
#define __sqUnixOpenGL_h

#include "config.h"

typedef struct glRenderer
{
  int	  bufferRect[4];
  int	  viewport[4];
  int	  used;
  void	 *drawable;
  void	 *context;
} glRenderer;

#if defined(USE_X11_GLX) || defined (USE_QUARTZ_CGL)

# define GL_RENDERER_DEFINED	 1
# define MAX_RENDERER		16

# if defined(HAVE_GL_GL_H)
#   include <GL/gl.h>
# else
#   if defined(HAVE_OPENGL_GL_H)
#     include <OpenGL/gl.h>
#   else
#     error *** cannot find gl.h
#   endif
# endif

#endif

extern int  ioGLinitialise(void);
extern int  ioGLcreateRenderer(glRenderer *r, int x, int y, int w, int h, int flags);
extern void ioGLdestroyRenderer(glRenderer *r);
extern int  ioGLmakeCurrentRenderer(glRenderer *r);
extern void ioGLswapBuffers(glRenderer *r);
extern void ioGLsetBufferRect(glRenderer *r, int x, int y, int w, int h);

#define glErrorCheck()	ERROR_CHECK


#endif /* __sqUnixOpenGL_h */
