/* module initialization support */
int b3dxInitialize(void); /* return true on success, false on error */
int b3dxShutdown(void); /* return true on success, false on error */

/* Texture support primitives */
int b3dxAllocateTexture(int renderer, int w, int h, int d); /* return handle or -1 on error */
int b3dxDestroyTexture(int renderer, int handle); /* return true on success, false on error */
int b3dxActualTextureDepth(int renderer, int handle); /* return depth or <0 on error */
int b3dxTextureColorMasks(int renderer, int handle, unsigned int masks[4]);  /* return true on success, false on error */
int b3dxUploadTexture(int renderer, int handle, int w, int h, int d, void* bits); /* return true on success, false on error */
int b3dxTextureByteSex(int renderer, int handle); /* return > 0 for MSB, = 0 for LSB, < 0 for error */
int b3dxTextureSurfaceHandle(int renderer, int handle); /* return handle or <0 if error */
int b3dxCompositeTexture(int renderer, int handle, int x, int y, int w, int h, int translucent); /* return true on success; else false */

/* Renderer primitives */
int b3dxCreateRendererFlags(int x, int y, int w, int h, int flags); /* return handle or -1 on error */
int b3dxDestroyRenderer(int handle); /* return true on success, else false */
int b3dxIsOverlayRenderer(int handle); /* return true/false */
int b3dxSetBufferRect(int handle, int x, int y, int w, int h); /* return true on success, false on error */
int b3dxGetRendererSurfaceHandle(int handle); /* return handle or <0 if error */
int b3dxGetRendererSurfaceWidth(int handle); /* return width or <0 if error */
int b3dxGetRendererSurfaceHeight(int handle); /* return height or <0 if error */
int b3dxGetRendererSurfaceDepth(int handle); /* return depth or <0 if error */
int b3dxGetRendererColorMasks(int handle, unsigned int *masks); /* return true on success, false on error */

int b3dxSetViewport(int handle, int x, int y, int w, int h); /* return true on success, false on error */
int b3dxClearDepthBuffer(int handle); /* return true on success, false on error */
int b3dxClearViewport(int handle, unsigned int rgba, unsigned int pv); /* return true on success, else false */
int b3dxSetTransform(int handle, float *modelView, float *projection);
int b3dxDisableLights(int handle);
int b3dxLoadLight(int handle, int index, B3DPrimitiveLight *light);
int b3dxLoadMaterial(int handle, B3DPrimitiveMaterial *material);
int b3dxRenderVertexBuffer(int handle, int primType, int flags, int texHandle, float *vtxArray, int vtxSize, int *idxArray, int idxSize); /* return true on success, false on error */
int b3dxFlushRenderer(int handle);
int b3dxFinishRenderer(int handle);
int b3dxSwapRendererBuffers(int handle);
int b3dxGetIntProperty(int handle, int prop);
int b3dxSetIntProperty(int handle, int prop, int value);
int b3dxGetIntPropertyOS(int handle, int prop);
int b3dxSetIntPropertyOS(int handle, int prop, int value);
int b3dxSetVerboseLevel(int level);
int b3dxSetFog(int handle, int fogType, double density, double rangeStart, double rangeEnd, int rgba);