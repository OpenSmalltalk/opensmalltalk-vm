#ifndef __sq_SqDisplay_h
#define __sq_SqDisplay_h

#define USE_VM_STRUCT 1

extern int    uxDropFileCount;
extern char **uxDropFileNames;

#define SqDisplayVersionMajor	1
#define SqDisplayVersionMinor	1
#define SqDisplayVersion	((SqDisplayVersionMajor << 16) | (SqDisplayVersionMinor))

#include "sqUnixOpenGL.h"

struct SqDisplay
{
  int     version;
  /* system attributes */
  char *(*winSystemName)(void);
  /* window startup/shutown */
  void 	(*winInit)(void);
  void 	(*winOpen)(void);
  void 	(*winSetName)(char *title);
  int  	(*winImageFind)(char *imageName, int size);
  void 	(*winImageNotFound)(void);
  void 	(*winExit)(void);
  /* display primitives */
  int 	(*ioFormPrint)(int bitsAddr, int width, int height, int depth, double hScale, double vScale, int landscapeFlag);
  int 	(*ioBeep)(void);
  int 	(*ioRelinquishProcessorForMicroseconds)(int microSeconds);
  int 	(*ioProcessEvents)(void);
  int 	(*ioScreenDepth)(void);
  int 	(*ioScreenSize)(void);
  int 	(*ioSetCursorWithMask)(int cursorBitsIndex, int cursorMaskIndex, int offsetX, int offsetY);
  int 	(*ioSetFullScreen)(int fullScreen);
  int 	(*ioForceDisplayUpdate)(void);
  int 	(*ioShowDisplay)(int dispBitsIndex, int width, int height, int depth, int l, int r, int t, int b);
  int 	(*ioHasDisplayDepth)(int i);
  int 	(*ioSetDisplayMode)(int width, int height, int depth, int fullscreenFlag);
  int   (*clipboardSize)(void);
  int   (*clipboardWriteFromAt)(int count, int byteArrayIndex, int startIndex);
  int   (*clipboardReadIntoAt)(int count, int byteArrayIndex, int startIndex);
  int   (*ioGetButtonState)(void);
  int   (*ioPeekKeystroke)(void);
  int   (*ioGetKeystroke)(void);
  int   (*ioGetNextEvent)(sqInputEvent *evt);
  int   (*ioMousePoint)(void);
  /* OpenGL */
  void *(*ioGetDisplay)(void);
  void *(*ioGetWindow)(void);
  int   (*ioGLinitialise)(void);
  int   (*ioGLcreateRenderer)(glRenderer *r, int x, int y, int w, int h, int flags);
  int   (*ioGLmakeCurrentRenderer)(glRenderer *r);
  void  (*ioGLdestroyRenderer)(glRenderer *r);
  void  (*ioGLswapBuffers)(glRenderer *r);
  void  (*ioGLsetBufferRect)(glRenderer *r, int x, int y, int w, int h);
  /* browser plugin */
  int   (*primitivePluginBrowserReady)(void);
  int   (*primitivePluginRequestURLStream)(void);
  int   (*primitivePluginRequestURL)(void);
  int   (*primitivePluginPostURL)(void);
  int   (*primitivePluginRequestFileHandle)(void);
  int   (*primitivePluginDestroyRequest)(void);
  int   (*primitivePluginRequestState)(void);
};


#define SqDisplayDefine(NAME)			\
static struct SqDisplay display_##NAME##_itf= {	\
  SqDisplayVersion,				\
  display_winSystemName,			\
  display_winInit,				\
  display_winOpen,				\
  display_winSetName,				\
  display_winImageFind,				\
  display_winImageNotFound,			\
  display_winExit,				\
  display_ioFormPrint,				\
  display_ioBeep,				\
  display_ioRelinquishProcessorForMicroseconds,	\
  display_ioProcessEvents,			\
  display_ioScreenDepth,			\
  display_ioScreenSize,				\
  display_ioSetCursorWithMask,			\
  display_ioSetFullScreen,			\
  display_ioForceDisplayUpdate,			\
  display_ioShowDisplay,			\
  display_ioHasDisplayDepth,			\
  display_ioSetDisplayMode,			\
  display_clipboardSize,			\
  display_clipboardWriteFromAt,			\
  display_clipboardReadIntoAt,			\
  display_ioGetButtonState,			\
  display_ioPeekKeystroke,			\
  display_ioGetKeystroke,			\
  display_ioGetNextEvent,			\
  display_ioMousePoint,				\
  display_ioGetDisplay,				\
  display_ioGetWindow,				\
  display_ioGLinitialise,			\
  display_ioGLcreateRenderer,			\
  display_ioGLmakeCurrentRenderer,		\
  display_ioGLdestroyRenderer,			\
  display_ioGLswapBuffers,			\
  display_ioGLsetBufferRect,			\
  display_primitivePluginBrowserReady,		\
  display_primitivePluginRequestURLStream,	\
  display_primitivePluginRequestURL,		\
  display_primitivePluginPostURL,		\
  display_primitivePluginRequestFileHandle,	\
  display_primitivePluginDestroyRequest,	\
  display_primitivePluginRequestState		\
}


extern struct SqDisplay *ioGetDisplayModule(void);


#endif /* __sq_SqDisplay_h */
