#ifndef SQ_UNIX_OPENGL_H
#define SQ_UNIX_OPENGL_H

#define MAX_RENDERER 16

typedef struct glRenderer {
  GLint bufferRect[4];
  GLint viewport[4];

  Bool used;
  Window window;
  GLXContext context;
} glRenderer;

#define GL_RENDERER_DEFINED 1

#endif /* SQ_UNIX_OPENGL_H */
