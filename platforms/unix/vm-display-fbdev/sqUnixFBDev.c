/* sqUnixFBDev.c -- display driver for the Linux framebuffer
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-08-20 01:15:03 by piumarta on felina.inria.fr
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
 * 
 *    You are NOT ALLOWED to distribute modified versions of this file
 *    under its original name.  If you want to modify it and then make
 *    your modifications available publicly, rename the file first.
 * 
 * This file is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * You may use and/or distribute this file under the terms of the Squeak
 * License as described in `LICENSE' in the base of this distribution,
 * subject to the following additional restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software.  If you use this software
 *    in a product, an acknowledgment to the original author(s) (and any
 *    other contributors mentioned herein) in the product documentation
 *    would be appreciated but is not required.
 * 
 * 2. You must not distribute (or make publicly available by any
 *    means) a modified copy of this file unless you first rename it.
 * 
 * 3. This notice must not be removed or altered in any source distribution.
 */


#include "sq.h"
#include "sqUnixMain.h"
#include "sqUnixGlobals.h"
#include "aio.h"

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
#include <assert.h>

#define DEBUG	1

#if (DEBUG)
  static void dprintf(const char *fmt, ...)
  {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
  }
#else
  static void dprintf(const char *fmt, ...) {}
#endif

#define fatal(M)	do { fprintf(stderr, "%s\n", M); exit(1); } while (0)
#define fatalError(M)	do { perror(M); exit(1); } while (0)

#include "sqUnixEvent.c"

static inline int min(int a, int b) { return a < b ? a : b; }
static inline int max(int a, int b) { return a > b ? a : b; }

static void failPermissions(const char *who);

#include "sqUnixFBDevUtil.c"
#include "sqUnixFBDevFramebuffer.c"
#include "sqUnixFBDevKeyboard.c"
#include "sqUnixFBDevMouse.c"

static char *fbDev= 0;
static char *msDev= 0;

static struct fb *fb= 0;
static struct kb *kb= 0;
static struct ms *ms= 0;


static void failPermissions(const char *who)
{
  fprintf(stderr, "cannot open %s\n", who);
  fprintf(stderr, "either:\n");
  fprintf(stderr, "  -  you don't have a framebuffer driver for your graphics card\n");
  fprintf(stderr, "     (you might be able to load one with 'modprobe'; look in\n");
  fprintf(stderr, "     /lib/modules for something called '<your-card>fb.o'\n");
  fprintf(stderr, "  -  you don't have write permission on some of the following\n");
  fprintf(stderr, "       /dev/tty*, /dev/fb*, /dev/psaux, /dev/input/mice\n");
  fprintf(stderr, "  -  you need to run Squeak as root on your machine\n");
  exit(1);
}


static void openConsole(void)
{
  fb= fb_new();
  fb_open(fb, fbDev);
}

static void closeConsole(void)
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
  modifierState= modifiers;
  if (up)
    {
      recordKeyboardEvent(key, EventKeyUp, modifiers);
    }
  else
    {
      recordKeyboardEvent(key, EventKeyDown, modifiers);
      recordKeyboardEvent(key, EventKeyChar, modifiers);
    }
}

static void openKeyboard(void)
{
  kb= kb_new();
  kb_open(kb, fb);
  kb_setCallback(kb, enqueueKeyboardEvent);
}

static void closeKeyboard(void)
{
  if (kb)
    {
      kb_setCallback(kb, 0);
      kb_close(kb);
      kb_delete(kb);
      kb= 0;
    }
}


static void enqueueMouseEvent(int b, int dx, int dy)
{
  fb_advanceCursor(fb, dx, dy);
  buttonState= b;
  mousePosition= fb->cursorPosition;
  recordMouseEvent();
}

static void openMouse(void)
{
  ms= ms_new();
  ms_open(ms, msDev);
  ms_setCallback(ms, enqueueMouseEvent);
}

static void closeMouse(void)
{
  if (ms)
    {
      ms_setCallback(ms, 0);
      ms_close(ms);
      ms_delete(ms);
      ms= 0;
    }
}


#define missing(N)	fprintf(stderr, "%s: MISSING\n", __FUNCTION__); return N


static int display_clipboardSize(void)
{
  missing(0);
}


static int display_clipboardWriteFromAt(int count, int byteArrayIndex, int startIndex)
{
  missing(0);
}


static int display_clipboardReadIntoAt(int count, int byteArrayIndex, int startIndex)
{
  missing(0);
}


static int display_ioFormPrint(int bitsAddr, int width, int height, int depth,
			       double hScale, double vScale, int landscapeFlag)
{
  missing(0);
}


static int display_ioBeep(void)
{
  kb_bell(kb);
  return 0;
}


static int display_ioRelinquishProcessorForMicroseconds(int microSeconds)
{
  aioPoll(microSeconds);
  return 0;
}


static int display_ioProcessEvents(void)
{
  aioPoll(0);
  return 0;
}


static int display_ioScreenDepth(void)
{
  missing(0);
}


static int display_ioScreenSize(void)
{
  assert(fb);
  return ((fb_width(fb) << 16) | fb_height(fb));
}


static int display_ioSetCursorWithMask(int cursorBitsIndex, int cursorMaskIndex,
				       int offsetX, int offsetY)
{
  fb_setCursor(fb, (char *)cursorBitsIndex, (char *)cursorMaskIndex, offsetX, offsetY);
  return 1;
}


static int display_ioSetFullScreen(int fullScreen)
{
  return 0;
}


static int display_ioForceDisplayUpdate(void)
{
  return 0;
}


static int display_ioShowDisplay(int dispBitsIndex,
				 int width, int height, int depth,
				 int affectedL, int affectedR,
				 int affectedT, int affectedB)
{
  if ((depth  != fb_depth(fb)) || (width  != fb_width(fb)) || (height != fb_height(fb))
      || (affectedR < affectedL) || (affectedB < affectedT))
    return 0;
  fb->copyBits(fb, (char *)dispBitsIndex, affectedL, affectedR, affectedT, affectedB);
  return 1;
}


static int display_ioHasDisplayDepth(int i)
{
  dprintf("hasDisplayDepth %d (%d) => %d\n", i, fb_depth(fb), (i == fb_depth(fb)));
  return (i == fb_depth(fb));
}


static int display_ioSetDisplayMode(int width, int height, int depth, int fullscreenFlag)
{
  missing(0);
}


static void display_winSetName(char *imageName)
{
  missing(;);
}


static void openDisplay(void)
{
  dprintf("openDisplay\n");
  openConsole();
  openKeyboard();
  openMouse();
}


static void closeDisplay(void)
{
  dprintf("closeDisplay\n");
  closeMouse();
  closeKeyboard();
  closeConsole();
}


/* ---------------------------------------------------------------- */

/* OSPP */

#if 1
void openXDisplay(void) {}
void closeXDisplay(void) {}
void synchronizeXDisplay(void) {}
void forgetXDisplay(void) {}
#endif

static void *display_ioGetDisplay(void)	{ return (void *)0; }
static void *display_ioGetWindow(void)	{ return (void *)0; }

/* OpenGL */

static int   display_ioGLinitialise(void) { return 0; }
static int   display_ioGLcreateRenderer(glRenderer *r, int x, int y, int w, int h, int flags) { return 0; }
static void  display_ioGLdestroyRenderer(glRenderer *r) {}
static void  display_ioGLswapBuffers(glRenderer *r) {}
static int   display_ioGLmakeCurrentRenderer(glRenderer *r) { return 0; }
static void  display_ioGLsetBufferRect(glRenderer *r, int x, int y, int w, int h) {}

/* Mozilla */

static int   display_primitivePluginBrowserReady()	{ return primitiveFail(); }
static int   display_primitivePluginRequestURLStream()	{ return primitiveFail(); }
static int   display_primitivePluginRequestURL()	{ return primitiveFail(); }
static int   display_primitivePluginPostURL()		{ return primitiveFail(); }
static int   display_primitivePluginRequestFileHandle()	{ return primitiveFail(); }
static int   display_primitivePluginDestroyRequest()	{ return primitiveFail(); }
static int   display_primitivePluginRequestState()	{ return primitiveFail(); }

/* ---------------------------------------------------------------- */


static char *display_winSystemName(void)
{
  return "fbdev";
}


static void display_winInit(void)
{
#if defined(AT_EXIT)
  AT_EXIT(closeDisplay);
#else
# warning: cannot release /dev/fb on exit!
# endif

  (void)recordMouseEvent;
  (void)recordKeyboardEvent;
  (void)recordKeystroke;
  (void)recordDragEvent;
}


static void display_winOpen(void)
{
  openDisplay();
}


static void display_winExit(void)
{
}


static int  display_winImageFind(char *buf, int len)	{ return 0; }
static void display_winImageNotFound(void)		{}


static void display_printUsage(void)
{
#if 0
  printf("\FBDev <option>s:\n");
  printf("  -fbdev <dev>          use framebuffer device <dev> (default: /dev/fb)\n");
  printf("  -msdev <dev>          use mouse device <dev> (default: /dev/psaux)\n");
#endif
}


static void display_printUsageNotes(void)
{
}


static void display_parseEnvironment(void)
{
  char *ev= 0;
  if ((ev= getenv("SQUEAK_FBDEV")))	fbDev= strdup(ev);
  if ((ev= getenv("SQUEAK_MSDEV")))	msDev= strdup(ev);
}


static int display_parseArgument(int argc, char **argv)
{
  int n= 1;
  char *arg= argv[0];

  if (argv[1])	/* option requires an argument */
    {
      n= 2;
      if      (!strcmp(arg, "-fbdev"))	 fbDev= argv[1];
      else if (!strcmp(arg, "-msdev"))	 msDev= argv[1];
      else
	n= 0;	/* not recognised */
    }
  else
    n= 0;
  return n;
}


#include "SqModule.h"

SqDisplayDefine(fbdev);

static void *display_makeInterface(void)
{
  return &display_fbdev_itf;
}

SqModuleDefine(display,	fbdev);
