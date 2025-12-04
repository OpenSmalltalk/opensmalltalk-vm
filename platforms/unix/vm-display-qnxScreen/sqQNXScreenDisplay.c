/* sqQNXScreenDisplay.c -- display driver for QNX Screen subsystem
 * 
 * Author: Ken Dickey <Ken.Dickey@Whidbey.COM>
 */

/* 
 * Copyright (C) 2025 Kenneth Alan Dickey
 * All Rights Reserved.
 * 
 * This file is part of the OpenSmalltalk-VM
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/*
  OpenSmalltalk-vm
    https://OpenSmalltalk.org
    https://github.com/OpenSmalltalk/opensmalltalk-vm
  
  QNX free licence & details at
    https://qnx.com/getqnx

  QNX 8.0 Screen Developer Documentation
    https://www.qnx.com/developers/docs/8.0/
    	  com.qnx.doc.screen/topic/manual/cscreen_about.html

  Source cross-compiled on Ubuntu/Mint Linux on x86_64
  for target system: Raspberry Pi 4 (aarch64) + QNX 8.0

  VM Interface
    --  struct SqDisplay = access via ioGetDisplayModule()
    VM/platforms/unix/vm/SqDisplay.h -- struct sqDisplay def
    VM/platforms/Cross/vm/sq.h  -- Display/Keyboard/Mouse + events
    VM/platforms/unix/vm/sqUnixEvent.c -- helpers, e.g. recordMouseEvent()
    VM/platforms/unix/vm-display-custom/sqUnixCustomModule.h -- generic starting point
*/

/* OpenSmalltalk VM */
#include "sq.h"
#include "sqUnixMain.h"
#include "sqUnixGlobals.h"
#include "sqaio.h"

#include "SqDisplay.h"

#if defined(ioMSecs)
# undef ioMSecs
#endif

/* POSIX */
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/select.h>
#include <stdarg.h>
#include <stdbool.h>
#include <assert.h>

/* Splash Screen Display Image: Squeak Balloon */

/* Pixels are kept as 32 bits: uint32_t */
typedef uint32_t pixel_t;
#include "Balloon.h"  /* Squeak Balloon image */
/* Forward declarations */
static void showBalloons( void *bufPtr );
static void showBalloonAt(void *bufPtr, int left, int top);
static inline void putPixel(void *bufPtr, int x, int y, pixel_t pix);

/* QNX */
#include <screen/screen.h>

/* QNX data structures */
screen_context_t screenContext = NULL;
screen_event_t   userEvent;
screen_window_t  window;
screen_session_t keyboardSession;
screen_buffer_t	 buffer;
void* bufPointer; /* buffer pointer */
int   stride;     /* buffer stride (bytes per scan line) */
int   displaySize[2];    /* {width,height} in pixels */
const int alwaysTrue = 1;


/* OVERVIEW:
   - Create a Screen/Graphic Context
   - Create a Render Target
     + Set Render Properties
   - Allocate Pixmap Buffers
   - Render into Buffers
     + Post/Update to (re)draw a Buffer
   - Attache Devices [Keyboard,Mouse/Pointer,MultiTouch,Joystick]
   - Run Event Loop

 Note that microkernel message passing implies copying event data
 from external io managers into local storage.  When an event is
 received, an io manager process dealloctes its event data.

 Here we are staying simple.  Our application (the VM) is assumed
 here with a single Display, a Mouse, and a Keyboard.  Windowing
 is our own Smalltalk Windows/Morphs within a single QNX Window
 which is the size of the single/main Display. Software rendering.

 QNX architects for multiple displays, touch events, joystick, game pad..
 Future projects not addressed here.  Touch events will need VM support.
*/

#if !defined(DEBUG)
# define DEBUG	0
#endif

#if (DEBUG)
static bool DPRINTF_redirecting = false;
typedef struct _debugmsg debugmsg;
struct _debugmsg {
  char* msg;
  debugmsg* next;
};
static debugmsg* DPRINTF_debugmsg = NULL;
static debugmsg* DPRINTF_debugmsg_new(void)
{
  debugmsg* msg = calloc(1, sizeof(debugmsg));
  if (!msg) {
    perror("no mem for redirect");
    exit(1);
  }
  if (!DPRINTF_debugmsg) {
    DPRINTF_debugmsg = msg;
  } else {
    debugmsg* cur = DPRINTF_debugmsg;
    while (cur->next != NULL) {
      cur = cur->next;
    }
    cur->next = msg;
  }
  return msg;
}

static void DPRINTF(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  if (DPRINTF_redirecting) {
    debugmsg* new = DPRINTF_debugmsg_new();
    vasprintf(&(new->msg), fmt, ap);
  } else {
    vprintf(fmt, ap);
  }
  va_end(ap);
}

static void DPRINTF_REDIRECT(bool flag)
{
  if (flag) {
    printf("DEBUG: saving incoming debug messages\n");
    fflush(stdout);
    fflush(stderr);
    DPRINTF_redirecting = true;
  } else {
    DPRINTF_redirecting = false;
    fflush(stdout);
    fflush(stderr);
    printf("DEBUG: replaying saved debug messages\n");
    debugmsg* cur = DPRINTF_debugmsg;
    while (cur != NULL) {
      printf("%s", cur->msg);
      debugmsg* next = cur->next;
      free(cur);
      cur=next;
    }
    fflush(stdout);
    fflush(stderr);
  }
}
#else
#define DPRINTF(fmt, ...)
#define DPRINTF_REDIRECT(b)
#endif

static void fatalError(const char *who)
{
  perror(who);
  exit(1);
}

static void fatal(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\n");
  exit(1);
}

static void outOfMemory(void)
{
  fatal("out of memory");
}


#include "sqUnixEvent.c"

static inline int min(int a, int b) { return a < b ? a : b; }
static inline int max(int a, int b) { return a > b ? a : b; }

/* Forward */
static void failPermissions(const char *who);


static void enqueueKeyboardEvent(int key, int up, int modifiers)
{
  DPRINTF("KEY %3d %02x %c %s mod %02x\n",
	  key, key, ((key > 32) && (key < 127)) ? key : ' ',
	  up ? "UP" : "DOWN", modifiers);

  modifierState= modifiers;
  if (up)
    {
      recordKeyboardEvent(key, EventKeyUp, modifiers, key);
    }
  else
    {
      recordKeyboardEvent(key, EventKeyDown, modifiers, key);
      recordKeyboardEvent(key, EventKeyChar, modifiers, key);
    }
}


static void enqueueMouseEvent(int b, int dx, int dy)
{
  fb_advanceCursor(fb, dx, dy);
  buttonState= b;
  mousePosition= fb->cursorPosition;
  if (b)
    DPRINTF("mouse %02x at %4d,%4d mod %02x\n",
	    b, mousePosition.x, mousePosition.y, modifierState);
  recordMouseEvent();
}


static sqInt display_ioBeep(void)
{
  /* @@FIXME: NYI@@ */
  return 0;
}


static sqInt display_ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  aioSleepForUsecs(microSeconds);
  return 0;
}


static sqInt display_ioProcessEvents(void)
{
#ifdef NOEVDEV
  aioPoll(0);
#else
  processLibEvdevMouseEvents();
  processLibEvdevKeyEvents(); /* sets modifier bits */
  processLibEvdevMouseEvents();
#endif
  return 0;
}


static sqInt display_ioScreenDepth(void)
{
  return 32; /* bits per pixel @@REVISIT: dynamic ask QNX? @@ */
}


static double display_ioScreenScaleFactor(void)
{
  return 1;
}

static sqInt display_ioScreenSize(void)
{ /* QNX Screen: displaySize[2] => {width, height} */
  return (displaySize[0] << 16) | displaySize[1]);
}


static sqInt display_ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  react();
  return 0;
}


static sqInt display_ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
  return 0;
}


static sqInt display_ioShowDisplay(sqInt dispBitsIndex,
				   sqInt width, sqInt height,
				   sqInt depth,
				   sqInt affectedL, sqInt affectedR,
				   sqInt affectedT, sqInt affectedB)
{
  if ((depth  != display_ioScreenDepth())
      || (width  != displaySize[0])
      || (height != displaySize[1])
      || (affectedR < affectedL)
      || (affectedB < affectedT))
    return 0;
/* @@FIXME: NYI@@
   fb->copyBits(fb, pointerForOop(dispBitsIndex), affectedL, affectedR, affectedT, affectedB); */
/*   return 1; */
  return 0;
}


static sqInt display_ioHasDisplayDepth(sqInt i)
{
  DPRINTF("hasDisplayDepth %d (%d) => %d\n", i, fb_depth(fb), (i == fb_depth(fb)));
  return (i == fb_depth(fb));
}


static void openDisplay(void)
{
  int sessionVisible = SCREEN_PROPERTY_VISIBLE; /* => active */
  int usage          = SCREEN_USAGE_NATIVE;
  int eventType	     = 0;
  int objectType     = 0;
  
  DPRINTF("openDisplay\n");
  DPRINTF_REDIRECT(true);
  if (screen_create_context(&screenContext,SCREEN_APPLICATION_CONTEXT) < 0) {
    perror("QNX: Cannot create Screen Context");
    exit(errno);
  }

  if (screen_create_window_type(&window,
				screenContext,
				(SCREEN_APPLICATION_WINDOW |SCREEN_ROOT_WINDOW)) < 0) {
    perror("QNX: Cannot create QNX Display Window");
    exit(errno);
  }

  if (screen_create_window_buffers(window, 1) < 0) {
    perror("QNX: Cannot create Window Buffer");
    exit(errno);
  } 

  /* Render Setup */
  screen_set_window_property_iv(window, SCREEN_PROPERTY_FORMAT,
	(const int[]){ SCREEN_FORMAT_RGBX8888 });
  screen_set_window_property_iv(window, SCREEN_PROPERTY_USAGE,
	(const int[]) { SCREEN_USAGE_READ | SCREEN_USAGE_WRITE });
  screen_get_window_property_iv(window, SCREEN_PROPERTY_BUFFER_SIZE,size);
  screen_get_window_property_pv(window, SCREEN_PROPERTY_BUFFERS, (void **)&buffer);
  screen_get_buffer_property_pv(buffer, SCREEN_PROPERTY_POINTER, &bufPointer);
  screen_get_buffer_property_iv(buffer, SCREEN_PROPERTY_STRIDE,  &stride);

  screen_fill(screenContext,
	      buffer,			      /* Color white */
	      (const int[]){ SCREEN_BLIT_COLOR, 0x00000000, SCREEN_BLIT_END });

  screen_set_window_property_iv(window, SCREEN_PROPERTY_VISIBLE, &alwaysTrue);

  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  showBalloons(bufPointer);
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 3 ); /* Let the user see splash screen */
  
  /* FOR THE USER */
  
  if (screen_create_event(&userEvent) != 0) {
    perror("QNX: Cannot create User Event holder");
    exit(errno);
  }
}


static void closeDisplay(void)
{
  DPRINTF("closeDisplay\n");
  DPRINTF_REDIRECT(false);
  screen_destroy_window( window );
  screen_destroy_context( screenContext );
}


static char *display_winSystemName(void)
{
  return "qnxScreenDisplay";
}


static void display_winInit(void)
{
#if defined(AT_EXIT)
  AT_EXIT(closeDisplay);
#else
# endif

  (void)recordMouseEvent;
  (void)recordKeyboardEvent;
  (void)recordKeystroke;
  (void)recordDragEvent;
  (void)recordWindowEvent;
}


static void display_winOpen(int argc, char *dropFiles[])
{
  openDisplay();
}


static void failPermissions(const char *who)
{
  fprintf(stderr, "Cannot open %s\n", who);
  fprintf(stderr, "You should be running QNX on a Raspberry Pi 4/5\n");
  fprintf(stderr, "  with a Display, Keyboard, & Mouse\n");
  fprintf(stderr, "Check sources at github.com/OpenSmalltalk/opensmalltalk-vm\n");
  fprintf(stderr, "  /platforms/unix/vm-display-qnxScreen\n");
  fprintf(stderr, "Ask/Report on  vm-dev@lists.squeakfoundation.org\n");
  exit(1);
}


static void display_printUsage(void)
{
  printf("\nNO currently used QNX Display options\n");
}


static void display_printUsageNotes(void)
{
  ; /* skip */
}


static void display_parseEnvironment(void)
{
  /*  Currently NO Environment Variables Used */

  /* How2:
  char *ev= 0;
  if ((ev= getenv("SQUEAK_FBDEV")))	fbDev=    strdup(ev);
  if ((ev= getenv("SQUEAK_KBMAP")))	kmPath=   strdup(ev);
  */
}


static int display_parseArgument(int argc, char **argv)
{
  /* Currently NO Arguments Used */

  /* how2: */
  /* int n= 1; */
  /* char *arg= argv[0]; */

  /* if      (!strcmp(arg, "-vtlock"))	 vtLock=   1; */
  /* else if (!strcmp(arg, "-vtswitch"))	 vtSwitch= 1; */
  /* else if (argv[1])	/\* option requires an argument *\/ */
  /*   { */
  /*     n= 2; */
  /*     if      (!strcmp(arg, "-fbdev"))	 fbDev=   argv[1]; */
  /*     else if (!strcmp(arg, "-kbmap"))	 kmPath=  argv[1]; */
  /*     else if (!strcmp(arg, "-msdev"))	 msDev=   argv[1]; */
  /*     else if (!strcmp(arg, "-kbdev"))	 kbDev.kbName=   argv[1];  */
  /*     else if (!strcmp(arg, "-msproto")) msProto= argv[1]; */
  /*     else */
  /* 	n= 0;	/\* not recognised *\/ */
  /*   } */
  /* else */
  /*   n= 0; */
  /* return n; */

  return( 0 ) ;
}

static sqInt display_clipboardSize(void)									{ return 0; }
static sqInt display_clipboardWriteFromAt(sqInt n, sqInt ptr, sqInt off)					{ return 0; }
static sqInt display_clipboardReadIntoAt(sqInt n, sqInt ptr, sqInt off)					{ return 0; }
static char **display_clipboardGetTypeNames(void)								{ return 0; }
static sqInt  display_clipboardSizeWithType(char *typeName, int ntypeName)					{ return 0; }

static void  display_clipboardWriteWithType(char *data, size_t ndata, char *typeName, size_t ntypeName, int isDnd, int isClaiming) {}

static sqInt display_dndOutStart(char *types, int ntypes)	{ return 0; }
static void  display_dndOutSend(char *bytes, int nbytes)	{ return  ; }
/* UNUSED static void  display_dndLaunchFile(char *fileName)	{ return ; }  */
static sqInt display_dndOutAcceptedType(char * buf, int nbuf)	{ return 0; }
static sqInt display_dndReceived(char *fileName)	{ return 0; }

static sqInt display_ioFormPrint(sqInt bits, sqInt w, sqInt h, sqInt d, double hs, double vs, sqInt l)	{ return 0; }

static sqInt display_ioSetFullScreen(sqInt fullScreen)							{ return 0; } /* Our 1 window is already fullscreen */

static sqInt display_ioForceDisplayUpdate(void)
{
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);
  return 0;
}

static sqInt display_ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)		{ return 0; }
static void display_winSetName(char *imageName)								{ return  ; }
static void display_winExit(void)									{ return  ; }
static long  display_winImageFind(char *buf, int len)							{ return 0; }
static void display_winImageNotFound(void)								{ return  ; }


//----------------------------------------------------------------

// OSPP
static void *display_ioGetDisplay(void)	{ return 0; }
static void *display_ioGetWindow(void)	{ return 0; }


static sqInt display_primitivePluginBrowserReady()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURLStream()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestURL()	{ return primitiveFail(); }
static sqInt display_primitivePluginPostURL()		{ return primitiveFail(); }
static sqInt display_primitivePluginRequestFileHandle()	{ return primitiveFail(); }
static sqInt display_primitivePluginDestroyRequest()	{ return primitiveFail(); }
static sqInt display_primitivePluginRequestState()	{ return primitiveFail(); }

// Host Windows

#if (SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 2)
static long display_hostWindowClose(long index)                                               { return 0; }
static long display_hostWindowCreate(long w, long h, long x, long y,
  char *list, long attributeListLength)                                                      { return 0; }
static long display_hostWindowShowDisplay(unsigned char *dispBitsIndex, long width, long height, long depth,
  long affectedL, long affectedR, long affectedT, long affectedB, sqIntptr_t windowIndex)              { return 0; }
static long display_hostWindowGetSize(long windowIndex)                                       { return -1; }
static long display_hostWindowSetSize(long windowIndex, long w, long h)                         { return -1; }
static long display_hostWindowGetPosition(long windowIndex)                                   { return -1; }
static long display_hostWindowSetPosition(long windowIndex, long x, long y)                     { return -1; }
static long display_hostWindowSetTitle(long windowIndex, char *newTitle, long sizeOfTitle)     { return -1; }
static long display_hostWindowCloseAll(void)                                                 { return 0; }
#endif


// new stubs for the CogVM
#if SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3
static long display_ioSetCursorPositionXY(long x, long y) { return 0; }
static long display_ioPositionOfScreenWorkArea (long windowIndex) { return -1; }
static long display_ioSizeOfScreenWorkArea (long windowIndex) { return -1; }
static void *display_ioGetWindowHandle() { return 0; }
static long display_ioPositionOfNativeDisplay(void *windowHandle) { return -1; }
static long display_ioSizeOfNativeDisplay(void *windowHandle) { return -1; }
static long display_ioPositionOfNativeWindow(void *windowHandle) { return -1; }
static long display_ioSizeOfNativeWindow(void *windowHandle) { return -1; }
#if SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 7
static long display_ioScreenRectangles(void) { return 0; }
#endif // SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 7
#endif // SqDisplayVersionMajor >= 1 && SqDisplayVersionMinor >= 3



//----------------------------------------------------------------


#include "SqModule.h"

SqDisplayDefine(qnxScreen);

static void *display_makeInterface(void)
{
  return &display_qnxScreen_itf;
}

SqModuleDefine(display,	qnxScreen);
