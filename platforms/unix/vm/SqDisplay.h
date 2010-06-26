#ifndef __sq_SqDisplay_h
#define __sq_SqDisplay_h

#define USE_VM_STRUCT 1

extern int    uxDropFileCount;
extern char **uxDropFileNames;

#define SqDisplayVersionMajor	1
#define SqDisplayVersionMinor	4
#define SqDisplayVersion	((SqDisplayVersionMajor << 16) | (SqDisplayVersionMinor))

#if (AVOID_OPENGL_H)
  typedef struct glRenderer glRenderer;
#else
# include "sqUnixOpenGL.h"
#endif

struct SqDisplay
{
  int     version;
  /* system attributes */
  char  *(*winSystemName)(void);
  /* window startup/shutown */
  void 	 (*winInit)(void);
  void 	 (*winOpen)(int argc, char *dropFiles[]);
  void 	 (*winSetName)(char *title);
  int  	 (*winImageFind)(char *imageName, int size);
  void 	 (*winImageNotFound)(void);
  void 	 (*winExit)(void);
  /* display primitives */
  sqInt  (*ioFormPrint)(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hScale, double vScale, sqInt landscapeFlag);
  sqInt  (*ioBeep)(void);
  sqInt  (*ioRelinquishProcessorForMicroseconds)(sqInt microSeconds);
  sqInt  (*ioProcessEvents)(void);
  sqInt  (*ioScreenDepth)(void);
  sqInt  (*ioScreenSize)(void);
  sqInt  (*ioSetCursorWithMask)(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY);
  sqInt  (*ioSetCursorARGB)(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
  sqInt  (*ioSetFullScreen)(sqInt fullScreen);
  sqInt  (*ioForceDisplayUpdate)(void);
  sqInt  (*ioShowDisplay)(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth, sqInt l, sqInt r, sqInt t, sqInt b);
  sqInt  (*ioHasDisplayDepth)(sqInt i);
  sqInt  (*ioSetDisplayMode)(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag);
  sqInt  (*clipboardSize)(void);
  sqInt  (*clipboardWriteFromAt)(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
  sqInt  (*clipboardReadIntoAt)(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
  char **(*clipboardGetTypeNames)(void);
  sqInt  (*clipboardSizeWithType)(char *typeName, int ntypeName);
  void   (*clipboardWriteWithType)(char *data, size_t nData, char *typeName, size_t nTypeName, int isDnd, int isClaiming);
  sqInt  (*dndOutStart)(char *types, int ntypes);
  sqInt  (*dndOutAcceptedType)(char *type, int ntype);
  void   (*dndOutSend)(char *bytes, int nbytes);
  sqInt  (*dndReceived)(char *fileName);
  sqInt  (*ioGetButtonState)(void);
  sqInt  (*ioPeekKeystroke)(void);
  sqInt  (*ioGetKeystroke)(void);
  sqInt  (*ioGetNextEvent)(sqInputEvent *evt);
  sqInt  (*ioMousePoint)(void);
  /* OpenGL */
  void  *(*ioGetDisplay)(void);
  void  *(*ioGetWindow)(void);
  sqInt  (*ioGLinitialise)(void);
  sqInt  (*ioGLcreateRenderer)(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags);
  sqInt  (*ioGLmakeCurrentRenderer)(glRenderer *r);
  void   (*ioGLdestroyRenderer)(glRenderer *r);
  void   (*ioGLswapBuffers)(glRenderer *r);
  void   (*ioGLsetBufferRect)(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h);
  /* browser plugin */
  sqInt  (*primitivePluginBrowserReady)(void);
  sqInt  (*primitivePluginRequestURLStream)(void);
  sqInt  (*primitivePluginRequestURL)(void);
  sqInt  (*primitivePluginPostURL)(void);
  sqInt  (*primitivePluginRequestFileHandle)(void);
  sqInt  (*primitivePluginDestroyRequest)(void);
  sqInt  (*primitivePluginRequestState)(void);
  /* host window support */
  int    (*hostWindowClose)(int index);
  int    (*hostWindowCreate)(int w, int h, int x, int y, char * list, int attributeListLength);
  int    (*hostWindowShowDisplay)(unsigned* dispBitsIndex, int width, int height, int depth, int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex);
  int    (*hostWindowGetSize)(int windowIndex);
  int    (*hostWindowSetSize)(int windowIndex, int w, int h);
  int    (*hostWindowGetPosition)(int windowIndex);
  int    (*hostWindowSetPosition)(int windowIndex, int x, int y);
  int    (*hostWindowSetTitle)(int windowIndex, char * newTitle, int sizeOfTitle);
  int    (*hostWindowCloseAll)(void);

  int    (*ioPositionOfScreenWorkArea)(int windowIndex);
  int    (*ioSizeOfScreenWorkArea)(int windowIndex);
  sqInt  (*ioSetCursorPositionXY)(sqInt x, sqInt y);

  void  *(*ioGetWindowHandle)(void);
  int    (*ioPositionOfNativeDisplay)(void *);
  int    (*ioSizeOfNativeDisplay)(void *);
  int    (*ioPositionOfNativeWindow)(void *);
  int    (*ioSizeOfNativeWindow)(void *);
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
  display_ioSetCursorARGB,			\
  display_ioSetFullScreen,			\
  display_ioForceDisplayUpdate,			\
  display_ioShowDisplay,			\
  display_ioHasDisplayDepth,			\
  display_ioSetDisplayMode,			\
  display_clipboardSize,			\
  display_clipboardWriteFromAt,			\
  display_clipboardReadIntoAt,			\
  display_clipboardGetTypeNames,		\
  display_clipboardSizeWithType,		\
  display_clipboardWriteWithType,		\
  display_dndOutStart,				\
  display_dndOutAcceptedType,  			\
  display_dndOutSend,				\
  display_dndReceived,				\
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
  display_primitivePluginRequestState,		\
  display_hostWindowClose,			\
  display_hostWindowCreate,			\
  display_hostWindowShowDisplay,		\
  display_hostWindowGetSize,			\
  display_hostWindowSetSize,			\
  display_hostWindowGetPosition,		\
  display_hostWindowSetPosition,		\
  display_hostWindowSetTitle,			\
  display_hostWindowCloseAll,			\
  display_ioPositionOfScreenWorkArea,	\
  display_ioSizeOfScreenWorkArea,		\
  display_ioSetCursorPositionXY,		\
  display_ioGetWindowHandle,			\
  display_ioPositionOfNativeDisplay,	\
  display_ioSizeOfNativeDisplay,	\
  display_ioPositionOfNativeWindow,	\
  display_ioSizeOfNativeWindow	\
}


extern struct SqDisplay *ioGetDisplayModule(void);


#endif /* __sq_SqDisplay_h */
