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

#if USE_X11_GLX || USE_QUARTZ_CGL

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

extern sqInt ioGLinitialise(void);
extern sqInt ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags);
extern void  ioGLdestroyRenderer(glRenderer *r);
extern sqInt ioGLmakeCurrentRenderer(glRenderer *r);
extern void  ioGLswapBuffers(glRenderer *r);
extern void  ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h);

#define glErrorCheck()	ERROR_CHECK


#endif /* __sqUnixOpenGL_h */
