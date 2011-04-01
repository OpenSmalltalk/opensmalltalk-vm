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
sqInt ioShowDisplayOnWindow(
	unsigned char *dispBitsIndex, 
	sqInt width, sqInt height, sqInt depth, 
	sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB,
	sqInt windowIndex)
{
  if (noDisplay)
    return 0;
  else
    return dpy->hostWindowShowDisplay(
      dispBitsIndex, width, height, depth, affectedL, affectedR, affectedT, affectedB, windowIndex);
}


/* ioSizeOfWindow: arg is int windowIndex. Return the size of the specified
 * window in (width<<16 || height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come
 */
int ioSizeOfWindow(int windowIndex)
{
  if (noDisplay)
    return -1;
  else
    return dpy->hostWindowGetSize(windowIndex);
}


/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 || height) format or -1 for failure as above.
 */
int ioSizeOfWindowSetxy(int windowIndex, int w, int h)
{
  if (noDisplay)
    return -1;
  else
    return dpy->hostWindowSetSize(windowIndex, w, h);
}


/* ioPositionOfWindow: arg is int windowIndex. Return the pos of the specified
 * window in (left<<16 || top) format like ioScreenSize.
 * Return -1 (as above) for failure - typically invalid windowIndex
 */
int ioPositionOfWindow(int windowIndex)
{
  if (noDisplay)
    return -1;
  else
    return dpy->hostWindowGetPosition(windowIndex);
}


/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 || top) format or -1 for failure, as above
 */
int ioPositionOfWindowSetxy(int windowIndex, int x, int y)
{
  if (noDisplay)
    return -1;
  else
    return dpy->hostWindowSetPosition(windowIndex, x, y);
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

