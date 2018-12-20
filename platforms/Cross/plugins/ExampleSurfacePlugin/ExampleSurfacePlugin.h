/* example surface plugin header file */
int memInitialize(void);
int memCreateSurfaceWidthHeightDepth(int width, int height, int depth);
int memDestroySurface(int id);
int memGetSurfaceWidth(int id);
int memGetSurfaceHeight(int id);
int memGetSurfaceDepth(int id);

