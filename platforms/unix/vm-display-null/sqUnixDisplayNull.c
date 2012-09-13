#include "sq.h"
#include "sqaio.h"

#include "SqDisplay.h"
#include "sqUnixGlobals.h"

static char *display_winSystemName(void) { return "none"; }
static void  display_winInit(void) {}
static void  display_winOpen(void) {}
static void  display_winSetName(char *title) {}
static int   display_winImageFind(char *imageName, int size) { return 0; }
static void  display_winImageNotFound(void) {}
static void  display_winExit(void) {}


static sqInt display_ioFormPrint(sqInt b, sqInt w, sqInt h, sqInt d, double hS, double vS, sqInt ls)
{
  return 0;
}

static sqInt display_ioBeep(void) { return 0; }

static sqInt display_ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  aioSleep(microSeconds);
  return 0;
}

static sqInt display_ioProcessEvents(void)
{
  aioPoll(0);
  return 0;
}

static sqInt display_ioScreenDepth(void)
{
  return 1;
}

static sqInt display_ioScreenSize(void)
{
  int sws= getSavedWindowSize();
  return sws ? sws : ((64 << 16) | 64);
}

static sqInt display_ioSetCursorWithMask(sqInt bits, sqInt mask, sqInt x, sqInt y)
{
  return 0;
}

static sqInt display_ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
  return 0;
}

static sqInt display_ioSetFullScreen(sqInt fullScreen)
{
  return 0;
}

static sqInt display_ioForceDisplayUpdate(void)
{
  return 0;
}

static sqInt display_ioShowDisplay(sqInt bits, sqInt w, sqInt h, sqInt d, sqInt l, sqInt r, sqInt t, sqInt b)
{
  return 0;
}

static sqInt display_ioHasDisplayDepth(sqInt i)
{
  return 1;
}

static sqInt display_ioSetDisplayMode(sqInt w, sqInt h, sqInt d, sqInt fullscreenFlag)
{
  setSavedWindowSize((w << 16) + (h & 0xFFFF));
  return 1;
}

static sqInt display_clipboardSize(void)
{
  return 0;
}

static sqInt display_clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  return 0;
}

static sqInt display_clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
  return 0;
}

static char **display_clipboardGetTypeNames(void)
{
  return 0;
}

static sqInt display_clipboardSizeWithType(char *typeName, int nTypeName)
{
  return 0;
}

static void display_clipboardWriteWithType(char *data, size_t ndata, char *typeName, size_t nTypeName, int isDnd, int isClaiming)
{
  return;
}

static sqInt display_dndOutStart(char *types, int ntypes)	{ return 0; }
static void  display_dndOutSend (char *bytes, int nbytes)	{ return  ; }
static sqInt display_dndOutAcceptedType(char *buf, int nbuf)	{ return 0; }

static sqInt display_ioGetButtonState(void)		{ return 0; }
static sqInt display_ioPeekKeystroke(void)		{ return 0; }
static sqInt display_ioGetKeystroke(void)		{ return 0; }
static sqInt display_ioGetNextEvent(sqInputEvent *evt)	{ return 0; }
static sqInt display_ioMousePoint(void)			{ return 0; }

static void  *display_ioGetDisplay(void)									{ return 0; }
static void  *display_ioGetWindow(void)										{ return 0; }
static sqInt  display_ioGLinitialise(void)									{ return 0; }
static sqInt  display_ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags)	{ return 0; }
static sqInt  display_ioGLmakeCurrentRenderer(glRenderer *r)							{ return 0; }
static void   display_ioGLdestroyRenderer(glRenderer *r)							{}
static void   display_ioGLswapBuffers(glRenderer *r)								{}
static void   display_ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h)			{}

static sqInt display_primitivePluginBrowserReady(void)		{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURLStream(void)	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURL(void)		{ return primitiveFail(); }
static sqInt display_primitivePluginPostURL(void)		{ return primitiveFail(); }
static sqInt display_primitivePluginRequestFileHandle(void)	{ return primitiveFail(); }
static sqInt display_primitivePluginDestroyRequest(void)	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestState(void)		{ return primitiveFail(); }

#if (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 2)
static int display_hostWindowClose(int index)                                               { return 0; }
static int display_hostWindowCreate(int w, int h, int x, int y,
  char *list, int attributeListLength)                                                      { return 0; }
static int display_hostWindowShowDisplay(unsigned *dispBitsIndex, int width, int height, int depth,
  int affectedL, int affectedR, int affectedT, int affectedB, int windowIndex)              { return 0; }
static int display_hostWindowGetSize(int windowIndex)                                       { return -1; }
static int display_hostWindowSetSize(int windowIndex, int w, int h)                         { return -1; }
static int display_hostWindowGetPosition(int windowIndex)                                   { return -1; }
static int display_hostWindowSetPosition(int windowIndex, int x, int y)                     { return -1; }
static int display_hostWindowSetTitle(int windowIndex, char *newTitle, int sizeOfTitle)     { return -1; }
static int display_hostWindowCloseAll(void)                                                 { return 0; }
#endif


SqDisplayDefine(null);


#include "SqModule.h"

static void  display_parseEnvironment(void) {}

static int   display_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nodisplay")) return 1;
  if (!strcmp(argv[0], "-headless"))  return 1;
  return 0;
}

static void  display_printUsage(void) {}
static void  display_printUsageNotes(void) {}
static void *display_makeInterface(void) { return &display_null_itf; }

SqModuleDefine(display, null);
