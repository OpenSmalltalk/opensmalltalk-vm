extern void *ioGLcreateView(int x, int y, int w, int h, int flags);
extern void *ioGLcreateContext(void *drawable);
extern int   ioGLsetCurrentContext(void *ctx);
extern int   ioGLdestroyContext(void *ctx);
extern int   ioGLdestroyView(void *drawable);
extern int   ioGLflushBuffer(void *drawable, void *ctx);
