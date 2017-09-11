#include "sq.h"
#include "sqaio.h"

#include "SqDisplay.h"
#include "sqUnixGlobals.h"

static char *display_winSystemName(void) { return "none"; }
static void  display_winInit(void) {}
static void  display_winOpen(void) {}
static void  display_winSetName(char *title) {}
static long  display_winImageFind(char *imageName, long size) { return 0; }
static void  display_winImageNotFound(void) {}
static void  display_winExit(void) {}


static sqInt display_ioFormPrint(sqInt b, sqInt w, sqInt h, sqInt d, double hS, double vS, sqInt ls)
{
  return 0;
}

static sqInt display_ioBeep(void) { return 0; }

static sqInt display_ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  aioSleepForUsecs(microSeconds);
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

static double display_ioScreenScaleFactor(void)
{
  return 1.0;
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
  setFullScreenFlag(fullScreen);
  return 1;
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

static sqInt display_ioSetDisplayMode(sqInt w, sqInt h, sqInt d, sqInt fullScreen)
{
  setSavedWindowSize((w << 16) + (h & 0xFFFF));
  setFullScreenFlag(fullScreen);
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
static sqInt display_dndReceived(char *fileName)	{ return 0; }

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
static long display_hostWindowClose(long index)             { return 0; }
static long display_hostWindowCreate(long w, long h, long x, long y,
  char *list, long attributeListLength)                     { return 0; }
static long display_hostWindowShowDisplay(unsigned *dispBitsIndex, long width, long height, long depth,
  long affectedL, long affectedR, long affectedT, long affectedB, long windowIndex)              { return 0; }
static long display_hostWindowGetSize(long windowIndex)     { return -1; }
static long display_hostWindowSetSize(long windowIndex, long w, long h) { return -1; }
static long display_hostWindowGetPosition(long windowIndex) { return -1; }
static long display_hostWindowSetPosition(long windowIndex, long x, long y) { return -1; }
static long display_hostWindowSetTitle(long windowIndex, char *newTitle, long sizeOfTitle)     { return -1; }
static long display_hostWindowCloseAll(void)                { return 0; }
#endif

#if (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3)

long display_ioSetCursorPositionXY(long x, long y) { return 0; }

long display_ioPositionOfScreenWorkArea (long windowIndex) { return -1; }

long display_ioSizeOfScreenWorkArea (long windowIndex) { return -1; }

void *display_ioGetWindowHandle() { return 0; }

long display_ioPositionOfNativeDisplay(void *windowHandle) { return -1; }

long display_ioSizeOfNativeDisplay(void *windowHandle) { return -1; }

long display_ioPositionOfNativeWindow(void *windowHandle) { return -1; }

long display_ioSizeOfNativeWindow(void *windowHandle) { return -1; }

#endif /* (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3) */

SqDisplayDefine(null);


#include "SqModule.h"

static void  display_parseEnvironment(void) {}

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
#else
# define VMOPTION(arg) "-"arg
#endif

static int   display_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], VMOPTION("nodisplay"))) return 1;
  if (!strcmp(argv[0], VMOPTION("headless")))  return 1;
  return 0;
}

static void  display_printUsage(void) {}
static void  display_printUsageNotes(void) {}
static void *display_makeInterface(void) { return &display_null_itf; }

SqModuleDefine(display, null);
