#include "sq.h"
#include "aio.h"

#include "SqDisplay.h"

static char *display_winSystemName(void) { return "none"; }
static void  display_winInit(void) {}
static void  display_winOpen(void) {}
static void  display_winSetName(char *title) {}
static int   display_winImageFind(char *imageName, int size) { return 0; }
static void  display_winImageNotFound(void) {}
static void  display_winExit(void) {}


static int   display_ioFormPrint(int b, int w, int h, int d,
				 double hS, double vS, int ls)
{
  return 0;
}

static int   display_ioBeep(void) { return 0; }

static int   display_ioRelinquishProcessorForMicroseconds(int microSeconds)
{
  aioPoll(microSeconds);
  return 0;
}

static int   display_ioProcessEvents(void)
{
  aioPoll(0);
  return 0;
}

static int   display_ioScreenDepth(void)
{
  return 1;
}

static int   display_ioScreenSize(void)
{
  int sws= getSavedWindowSize();
  return sws ? sws : ((64 << 16) | 64);
}

static int   display_ioSetCursorWithMask(int bits, int mask, int x, int y)
{
  return 0;
}

static int   display_ioSetFullScreen(int fullScreen)
{
  return 0;
}

static int   display_ioForceDisplayUpdate(void)
{
  return 0;
}

static int   display_ioShowDisplay(int bits, int w, int h, int d,
				   int l, int r, int t, int b)
{
  return 0;
}

static int   display_ioHasDisplayDepth(int i)
{
  return 1;
}

static int   display_ioSetDisplayMode(int w, int h, int d, int fullscreenFlag)
{
  return 0;
}

static int   display_clipboardSize(void)
{
  return 0;
}

static int   display_clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex)
{
  return 0;
}

static int   display_clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex)
{
  return 0;
}

static int   display_ioGetButtonState(void)		{ return 0; }
static int   display_ioPeekKeystroke(void)		{ return 0; }
static int   display_ioGetKeystroke(void)		{ return 0; }
static int   display_ioGetNextEvent(sqInputEvent *evt)	{ return 0; }
static int   display_ioMousePoint(void)			{ return 0; }

static void  *display_ioGetDisplay(void)			{ return 0; }
static void  *display_ioGetWindow(void)				{ return 0; }
static  int   display_ioGLinitialise(void)			{ return 0; }
static  int   display_ioGLcreateRenderer(glRenderer *r, int x, int y, int w, int h, int flags) { return 0; }
static  int   display_ioGLmakeCurrentRenderer(glRenderer *r)	{ return 0; }
static  void  display_ioGLdestroyRenderer(glRenderer *r)	{}
static  void  display_ioGLswapBuffers(glRenderer *r)		{}
static  void  display_ioGLsetBufferRect(glRenderer *r, int x, int y, int w, int h) {}

static int display_primitivePluginBrowserReady(void)		{ return primitiveFail(); }
static int display_primitivePluginRequestURLStream(void)	{ return primitiveFail(); }
static int display_primitivePluginRequestURL(void)		{ return primitiveFail(); }
static int display_primitivePluginPostURL(void)			{ return primitiveFail(); }
static int display_primitivePluginRequestFileHandle(void)	{ return primitiveFail(); }
static int display_primitivePluginDestroyRequest(void)		{ return primitiveFail(); }
static int display_primitivePluginRequestState(void)		{ return primitiveFail(); }

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
