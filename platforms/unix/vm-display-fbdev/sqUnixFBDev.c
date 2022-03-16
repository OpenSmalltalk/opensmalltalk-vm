/* sqUnixFBDev.c -- display driver for the Linux framebuffer
 * 
 * Author: Ian Piumarta <ian.piumarta@squeakland.org>
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003-2005 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
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
 *   last update: 31 Jan 2012 13:38:32 CET; Michael J. Zeder
 */


#include "sq.h"
#include "sqUnixMain.h"
#include "sqUnixGlobals.h"
#include "sqaio.h"

#include "SqDisplay.h"

#if defined(ioMSecs)
# undef ioMSecs
#endif

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

static void failPermissions(const char *who);

static char *msDev=    0;
static char *msProto=  0;
static char *kmPath=   0;
static char *fbDev=    0;
static int   vtLock=   0;
static int   vtSwitch= 0;

struct kb;
struct ms;
struct fb;

static struct ms *ms= 0;
static struct kb *kb= 0;
static struct fb *fb= 0;

#include "sqUnixFBDevUtil.c"
#ifdef NOEVDEV
#include "sqUnixFBDevMouse.c"
#include "sqUnixFBDevKeyboard.c"
#else
#include "sqUnixEvdevKeycodeMap.c"
#include "sqUnixEvdevKeyMouse.c"
#endif
#include "sqUnixFBDevFramebuffer.c"

static void openFramebuffer(void)
{
  fb= fb_new();
  fb_open(fb, kb, fbDev);
}


static void closeFramebuffer(void)
{
  if (fb)
    {
      fb_close(fb);
      fb_delete(fb);
      fb= 0;
    }
}


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

static void openKeyboard(void)
{
  kb= kb_new();
  kb_open(kb, vtSwitch, vtLock);
#ifdef NOEVDEV
  kb_setCallback(kb, enqueueKeyboardEvent);
#endif
}

static void closeKeyboard(void)
{
  if (kb)
    {
#ifdef NOEVDEV
      kb_setCallback(kb, 0);
#endif
      kb_close(kb);
#ifdef NOEVDEV
      kb_delete(kb);
#endif
      kb= 0;
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

static void openMouse(void)
{
  ms= ms_new();
  ms_open(ms, msDev, msProto);
#ifdef NOEVDEV
  ms_setCallback(ms, enqueueMouseEvent);
#endif
}

static void closeMouse(void)
{
  if (ms)
    {
#ifdef NOEVDEV
      ms_setCallback(ms, 0);
#endif
      ms_close(ms);
#ifdef NOEVDEV
      ms_delete(ms);
#endif
      ms= 0;
    }
}


static sqInt display_ioBeep(void)
{
  kb_bell(kb);
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
  // we could match negative depths for little-endian machines here, but:
  //   1. some kinds of BitBlt seem to be broken at depth -8;
  //   2. doing our own conversionis 20% faster than having BitBlt do it.
  return fb_depth(fb);
}


static double display_ioScreenScaleFactor(void)
{
  return fb_scale(fb);
}

static sqInt display_ioScreenSize(void)
{
  return ((fb_width(fb) << 16) | fb_height(fb));
}


static sqInt display_ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
  fb_setCursor(fb, pointerForOop(cursorBitsIndex), pointerForOop(cursorMaskIndex), offsetX, offsetY);
  return 1;
}


static sqInt display_ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
  return 0;
}


static sqInt display_ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth, sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
  if ((depth  != fb_depth(fb)) || (width  != fb_width(fb)) || (height != fb_height(fb))
      || (affectedR < affectedL) || (affectedB < affectedT))
    return 0;
  fb->copyBits(fb, pointerForOop(dispBitsIndex), affectedL, affectedR, affectedT, affectedB);
  return 1;
}


static sqInt display_ioHasDisplayDepth(sqInt i)
{
  DPRINTF("hasDisplayDepth %d (%d) => %d\n", i, fb_depth(fb), (i == fb_depth(fb)));
  return (i == fb_depth(fb));
}


static void openDisplay(void)
{
  DPRINTF("openDisplay\n");
  DPRINTF_REDIRECT(true);
  openMouse();
  openKeyboard();
  openFramebuffer();
  // init mouse after setting graf mode on tty avoids packets being
  // snarfed by gpm
#ifdef NOEVDEV
  ms->init(ms);
#endif
}


static void closeDisplay(void)
{
  DPRINTF("closeDisplay\n");
  closeFramebuffer();
  DPRINTF_REDIRECT(false);
  closeKeyboard();
  closeMouse();
}


static char *display_winSystemName(void)
{
  return "fbdev";
}


static void display_winInit(void)
{
#if defined(AT_EXIT)
  AT_EXIT(closeDisplay);
#else
# warning: cannot release /dev/fb0 on exit!
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
  fprintf(stderr, "cannot open %s\n", who);
  fprintf(stderr, "either:\n");
  fprintf(stderr, "  -  you don't have a framebuffer driver for your graphics card\n");
  fprintf(stderr, "     (you might be able to load one with 'modprobe'; look in\n");
  fprintf(stderr, "     /lib/modules for something called '<your-card>fb.o'\n");
  fprintf(stderr, "  -  you don't have write permission on some of the following\n");
  fprintf(stderr, "       /dev/tty*, /dev/fb*, /dev/input/event?, /dev/input/mouse0\n");
  fprintf(stderr, "  -  you need to run Squeak as root on your machine\n");
  exit(1);
}


static void display_printUsage(void)
{
  printf("\nFBDev <option>s:\n");
  printf("  -fbdev <dev>          use framebuffer device <dev> (default: /dev/fb0)\n");
  printf("  -kbmap <file>         load keymap from <file> \n");
  printf("   [Make file by: 'dumpkeys -f -n --keys-only > squeak-kb.map' ]\n");
  printf("  -msdev <dev>          use mouse device <dev> (default: /dev/input/event1)\n");
  printf("  -kbdev <dev>          use keyboard device <dev> (default: /dev/input/event0)\n");
  /*  printf("  -vtlock               disallow all vt switching (for any reason)\n");
      printf("  -vtswitch             enable keyboard vt switching (Alt+FNx)\n"); */
}


static void display_printUsageNotes(void)
{
  printf("  -vtlock disables keyboard vt switching even when -vtswitch is enabled\n");
}


static void display_parseEnvironment(void)
{
  char *ev= 0;
  if ((ev= getenv("SQUEAK_FBDEV")))	fbDev=    strdup(ev);
  if ((ev= getenv("SQUEAK_KBMAP")))	kmPath=   strdup(ev);
  if ((ev= getenv("SQUEAK_MSDEV")))	msDev=    strdup(ev);
  if ((ev= getenv("SQUEAK_KBDEV")))	kbDev.kbName=    strdup(ev);
  if ((ev= getenv("SQUEAK_MSPROTO")))	msProto=  strdup(ev);
  if ((ev= getenv("SQUEAK_VTLOCK")))	vtLock=   1;
  if ((ev= getenv("SQUEAK_VTSWITCH")))	vtSwitch= 1;
}


static int display_parseArgument(int argc, char **argv)
{
  int n= 1;
  char *arg= argv[0];

  if      (!strcmp(arg, "-vtlock"))	 vtLock=   1;
  else if (!strcmp(arg, "-vtswitch"))	 vtSwitch= 1;
  else if (argv[1])	/* option requires an argument */
    {
      n= 2;
      if      (!strcmp(arg, "-fbdev"))	 fbDev=   argv[1];
      else if (!strcmp(arg, "-kbmap"))	 kmPath=  argv[1];
      else if (!strcmp(arg, "-msdev"))	 msDev=   argv[1];
      else if (!strcmp(arg, "-kbdev"))	 kbDev.kbName=   argv[1]; 
      else if (!strcmp(arg, "-msproto")) msProto= argv[1];
      else
	n= 0;	/* not recognised */
    }
  else
    n= 0;
  return n;
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
static sqInt display_ioSetFullScreen(sqInt fullScreen)							{ return 0; }
static sqInt display_ioForceDisplayUpdate(void)								{ return 0; }
static sqInt display_ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)		{ return 0; }
static void display_winSetName(char *imageName)								{ return  ; }
static void display_winExit(void)									{ return  ; }
static long  display_winImageFind(char *buf, int len)							{ return 0; }
static void display_winImageNotFound(void)								{ return  ; }


//----------------------------------------------------------------

// OSPP

void openXDisplay(void)		{}
void closeXDisplay(void)	{}
void synchronizeXDisplay(void)	{}
void forgetXDisplay(void)	{}

static void *display_ioGetDisplay(void)	{ return 0; }
static void *display_ioGetWindow(void)	{ return 0; }

// OpenGL

static sqInt  display_ioGLinitialise(void)								{ return 0; }
static sqInt  display_ioGLcreateRenderer(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h, sqInt flags)	{ return 0; }
static void  display_ioGLdestroyRenderer(glRenderer *r)							{ return  ; }
static void  display_ioGLswapBuffers(glRenderer *r)							{ return  ; }
static sqInt  display_ioGLmakeCurrentRenderer(glRenderer *r)						{ return 0; }
static void  display_ioGLsetBufferRect(glRenderer *r, sqInt x, sqInt y, sqInt w, sqInt h)			{ return  ; }

// Mozilla

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
static long display_hostWindowShowDisplay(unsigned *dispBitsIndex, long width, long height, long depth,
  long affectedL, long affectedR, long affectedT, long affectedB, sqIntptr_t windowIndex)              { return 0; }
static long display_hostWindowGetSize(long windowIndex)                                       { return -1; }
static long display_hostWindowSetSize(long windowIndex, long w, long h)                         { return -1; }
static long display_hostWindowGetPosition(long windowIndex)                                   { return -1; }
static long display_hostWindowSetPosition(long windowIndex, long x, long y)                     { return -1; }
static long display_hostWindowSetTitle(long windowIndex, char *newTitle, long sizeOfTitle)     { return -1; }
static long display_hostWindowCloseAll(void)                                                 { return 0; }
#endif



// new stubs for the CogVM
long display_ioSetCursorPositionXY(long x, long y) { return 0; }
long display_ioPositionOfScreenWorkArea (long windowIndex) { return -1; }
long display_ioSizeOfScreenWorkArea (long windowIndex) { return -1; }
void *display_ioGetWindowHandle() { return 0; }
long display_ioPositionOfNativeDisplay(void *windowHandle) { return -1; }
long display_ioSizeOfNativeDisplay(void *windowHandle) { return -1; }
long display_ioPositionOfNativeWindow(void *windowHandle) { return -1; }
long display_ioSizeOfNativeWindow(void *windowHandle) { return -1; }



//----------------------------------------------------------------


#include "SqModule.h"

SqDisplayDefine(fbdev);

static void *display_makeInterface(void)
{
  return &display_fbdev_itf;
}

SqModuleDefine(display,	fbdev);
