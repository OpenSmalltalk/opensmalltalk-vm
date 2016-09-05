#ifndef SQ_WIN32_OPENGL_H
#define SQ_WIN32_OPENGL_H

#define MAX_RENDERER 16

#include <GL/gl.h>

typedef struct glRenderer {
  GLint bufferRect[4];
  GLint viewport[4];

  int used;
  HWND  hWnd;
  HGLRC context;
  HDC   hDC;

  void (APIENTRY *glDrawRangeElements) (GLenum, GLuint, GLuint, GLsizei, GLenum, const GLvoid*);

} glRenderer;

#define GL_RENDERER_DEFINED 1

#endif /* SQ_WIN32_OPENGL_H */
