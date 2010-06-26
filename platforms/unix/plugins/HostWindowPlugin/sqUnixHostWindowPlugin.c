/*  sqUnixHostWindowPlugin.c -- support for multiple host windows
 *
 * Copyright (C) 2009 by Bert Freudenberg and other
 *                             authors/contributors as listed.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

#define AVOID_OPENGL_H	1

#include "sq.h"
#include "SqDisplay.h"
#include "HostWindowPlugin.h"

#define FPRINTF(x) fprintf x

static struct SqDisplay	*dpy= 0;

#define noDisplay ( (!dpy && !(dpy= ioGetDisplayModule())) || (dpy->version < 0x10002) )
 
/* closeWindow: arg is int windowIndex. Fail (return 0) if anything goes wrong
 * - typically the windowIndex invalid or similar
 */
int closeWindow(int index)
{
  if (noDisplay)
    return 0;
  else
    return dpy->hostWindowClose(index); 
}


/* createWindow: takes int width, height and origin x/y plus a char* list of
 * as yet undefined attributes. Returns an int window index or 0 for failure
 * Failure may occur because of an inability to add the window, too many
 * windows already extant (platform dependant), the specified size being
 * unreasonable etc.
 */
int createWindowWidthheightoriginXyattrlength(
	int w, int h, int x, int y, char *list, int attributeListLength)
{
  if (noDisplay)
    return 0;
  else
    return dpy->hostWindowCreate(w, h, x, y, list, attributeListLength);
}


/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the int windowIndex
 * Return true if ok, false if not, but not currently checked
 */
int ioShowDisplayOnWindow(
	unsigned* dispBitsIndex, 
	int width, int height, int depth, 
	int affectedL, int affectedR, int affectedT, int affectedB,
	int windowIndex)
{
  if (noDisplay)
    return 0;
  else
    return dpy->hostWindowShowDisplay(
      dispBitsIndex, width, height, depth, affectedL, affectedR, affectedT, affectedB, windowIndex);
}


#if 0 /* getter printing */
# define DBGGPRINT(args) printf args
#else
# define DBGGPRINT(args) 0
#endif
#if 0 /* setter printing */
# define DBGSPRINT(args) printf args
#else
# define DBGSPRINT(args) 0
#endif

/* ioSizeOfWindow: arg is int windowIndex. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come
 */
int ioSizeOfWindow(int windowIndex)
{
  int r = noDisplay ? -1 : dpy->hostWindowGetSize(windowIndex);
  DBGGPRINT(("ioSizeOfWindow(%d) == %x (%d,%d)\n",
			windowIndex, r, r >> 16, (short)r));
  return r;
}


/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above.
 */
int ioSizeOfWindowSetxy(int windowIndex, int w, int h)
{
  int r = noDisplay ? -1 : dpy->hostWindowSetSize(windowIndex, w, h);
  DBGSPRINT(("ioSizeOfWindowSetxy(%d,%d,%d) == %x (%d,%d)\n",
			windowIndex, w, h, r, r >> 16, (short)r));
  return r;
}


/* ioPositionOfWindow: arg is int windowIndex. Return the pos of the specified
 * window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - typically invalid windowIndex
 */
int ioPositionOfWindow(int windowIndex)
{
  int r = noDisplay ? -1 : dpy->hostWindowGetPosition(windowIndex);
  DBGGPRINT(("ioPositionOfWindow(%d) == %x (%d,%d)\n",
			windowIndex, r, r >> 16, (short)r));
  return r;
}


/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above
 */
int ioPositionOfWindowSetxy(int windowIndex, int x, int y)
{
  int r = noDisplay ? -1 : dpy->hostWindowSetPosition(windowIndex, x, y);
  DBGSPRINT(("ioPositionOfWindowSetxy(%d,%d,%d) == %x (%d,%d)\n",
			windowIndex, x, y, r, r >> 16, (short)r));
  return r;
}


/* ioSetTitleOfWindow: args are int windowIndex, char* newTitle and
 * int size of new title. Fail with -1 if windowIndex is invalid, string is too
 * long for platform etc. Leave previous title in place on failure
 */
int ioSetTitleOfWindow(int windowIndex, char *newTitle, int sizeOfTitle)
{
  if (noDisplay)
    return -1;
  else
    return dpy->hostWindowSetTitle(windowIndex, newTitle, sizeOfTitle);
}


/* ioCloseAllWindows: intended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway.
 */
int ioCloseAllWindows(void)
{
  if (noDisplay)
    return 0;
  else
    return dpy->hostWindowCloseAll();
}


/* eem Mar 22 2010 - new code to come up to level of Qwaq host window support
 * on Mac & Win32.
 */
sqInt ioSetCursorPositionXY(sqInt x, sqInt y)
{
  int r = noDisplay ? -1 : dpy->ioSetCursorPositionXY(x,y);
  DBGSPRINT(("ioSetCursorPositionXY(%d,%d) == %x (%d,%d)\n",
			x, y, r, r >> 16, (short)r));
  return r;
}

/* Return the pixel origin (topleft) of the platform-defined working area
   for the screen containing the given window. */
int ioPositionOfScreenWorkArea(int windowIndex)
{
  int r = noDisplay ? -1 : dpy->ioPositionOfScreenWorkArea(windowIndex);
  DBGGPRINT(("ioPositionOfScreenWorkArea(%d) == %x (%d,%d)\n",
			windowIndex, r, r >> 16, (short)r));
  return r;
}

/* Return the pixel extent of the platform-defined working area
   for the screen containing the given window. */
int ioSizeOfScreenWorkArea(int windowIndex)
{
  int r = noDisplay ? -1 : dpy->ioSizeOfScreenWorkArea(windowIndex);
  DBGGPRINT(("ioSizeOfScreenWorkArea(%d) == %x (%d,%d)\n",
			windowIndex, r, r >> 16, (short)r));
  return r;
}

#if 0 /* this is in sqUnixMain.c */
void *ioGetWindowHandle() { return noDisplay ? 0 : dpy->ioGetWindowHandle(); }
#endif

int ioPositionOfNativeDisplay(unsigned long windowHandle)
{
  int r = noDisplay ? -1 : dpy->ioPositionOfNativeDisplay((void *)windowHandle);
  DBGGPRINT(("ioPositionOfNativeDisplay(%d) == %x (%d,%d)\n",
			windowHandle, r, r >> 16, (short)r));
  return r;
}

int ioSizeOfNativeDisplay(unsigned long windowHandle)
{
  int r = noDisplay ? -1 : dpy->ioSizeOfNativeDisplay((void *)windowHandle);
  DBGGPRINT(("ioSizeOfNativeDisplay(%d) == %x (%d,%d)\n",
			windowHandle, r, r >> 16, (short)r));
  return r;
}

int ioPositionOfNativeWindow(unsigned long windowHandle)
{
  int r = noDisplay ? -1 : dpy->ioPositionOfNativeWindow((void *)windowHandle);
  DBGGPRINT(("ioPositionOfNativeWindow(%d) == %x (%d,%d)\n",
			windowHandle, r, r >> 16, (short)r));
  return r;
}

int ioSizeOfNativeWindow(unsigned long windowHandle)
{
  int r = noDisplay ? -1 : dpy->ioSizeOfNativeWindow((void *)windowHandle);
  DBGGPRINT(("ioSizeOfNativeWindow(%d) == %x (%d,%d)\n",
			windowHandle, r, r >> 16, (short)r));
  return r;
}
