/*
 *  sqMacHostWindow.m
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *  Copyright Corporate Smalltalk Consulting Ltd 2008. All rights reserved.
 *
	July 15th 2005 add logic to flush QD buffers for os-x 10.4
	 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
	May 15th, 2008 IPhone
	Sept 6th, 2010 Cocoa

 */
/*
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */

#if !defined(SQUEAK_BUILTIN_PLUGIN)
# error "HostWindowPlugin can only be compiled as an internal plugin"
#endif

#include <stdlib.h>
#include <Cocoa/Cocoa.h>
#include "sqVirtualMachine.h"
#include "sqMacHostWindow.h"
#import "sqSqueakScreenAPI.h"
#import "sqSqueakScreenAndWindow.h"

extern struct VirtualMachine *interpreterProxy;

/* WARNING, WARNING, WARNING, Will Robertson!! This is a partial implementation
 * that cannot create new windows.  It simply answers or operates on the main
 * Squeak window, which is all that Terf needs.
 *
 * Regarding coordinate system transformations use recordWindowEvent:window: in
 * platforms/iOS//vm/OSX/sqSqueakOSXApplication+events.m for reference.
 */

#define nsWindowFromIndex(wix) ((__bridge NSWindow *)windowHandleFromIndex(wix))

#define packedDoubleXY(x,y) packedXY((int)(x),(int)(y))

static sqInt
RemoveWindowBlock(windowDescriptorBlock *thisWindow);

sqInt
createWindowWidthheightoriginXyattrlength(sqInt w,sqInt h,sqInt x,sqInt y, char * list, sqInt listLength)
{
	// I *think* in Terf we just resize the main Squeak window, so this doesn't
	// need to be implemented. eem 2020/10/4
	return -1;
}

sqInt
closeWindow(wIndexType windowIndex)
{
	NSWindow *window = nsWindowFromIndex(windowIndex);

	if (!window) 
		return 0;
	windowBlockFromIndex(windowIndex)->context = NULL;
	RemoveWindowBlock(windowBlockFromIndex(windowIndex));	
	[window close];
	return 1;
}

sqInt
ioPositionOfWindow(wIndexType windowIndex)
{
	NSWindow *window = nsWindowFromIndex(windowIndex);

	if (!window)
		return -1;

    NSRect win = [window frame];
	return packedDoubleXY(win.origin.x,
						  yZero() - (win.origin.y + win.size.height));
}

sqInt
ioPositionOfWindowSetxy(wIndexType windowIndex, sqInt x, sqInt y)
{
	if (windowIndex != 1)
		return 0;
	NSWindow *window = nsWindowFromIndex(windowIndex);
    NSRect frame = [window frame];
    frame.origin.x = x;
    frame.origin.y = yZero() - (y + frame.size.height);
    [window setFrame: frame display: YES];    

	return 0;
}

sqInt
ioSizeOfWindow(wIndexType windowIndex)
{
	NSWindow *window = nsWindowFromIndex(windowIndex);

	if (!window)
		return -1;

	NSRect win = [window frame];

	return packedDoubleXY(win.size.width,win.size.height);
}

sqInt
ioSizeOfWindowSetxy(wIndexType windowIndex, sqInt x, sqInt y)
{
	if (windowIndex != 1)
		return 0;

	NSWindow *window = nsWindowFromIndex(windowIndex);
    NSRect frame = [window frame];
    frame.size.width = x;
    frame.size.height = y;
    [window setFrame: frame display: YES];    

	return 0;
}

sqInt
ioSetTitleOfWindow(wIndexType windowIndex, char * newTitle, sqInt sizeOfTitle)
{
	if (windowIndex != 1)
		return 0;

    NSString *title = [[NSString alloc] initWithBytes:newTitle length:sizeOfTitle encoding:NSUTF8StringEncoding];

    [[[NSApplication sharedApplication] mainWindow] setTitle: title];
    RELEASEOBJ(title);

	return 1;
}

/* ioSetIconOfWindow: args are int windowIndex, char* iconPath and
 * int size of new logo path. If one of the function is failing, the logo is not set.
 */
sqInt
ioSetIconOfWindow(wIndexType windowIndex, char * iconPath, sqInt sizeOfPath)
{
	//Not implemented
	return -1;
}

sqInt
ioCloseAllWindows(void) { return 1; }



/* addendum to sqPlatformSpecific.h */
/* multiple host windows stuff */

static windowDescriptorBlock *windowListRoot = NULL;

/* end addendum to sqPlatformSpecific.h */

/* simple linked list management code */
/* window list management */

windowDescriptorBlock *
windowBlockFromIndex(wIndexType windowIndex)
{
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while (entry) {
		if (entry->windowIndex == windowIndex)
			return entry;
		entry = entry->next;
	}
	return NULL;
}

windowDescriptorBlock *
windowBlockFromHandle(wHandleType windowHandle)
{
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while (entry) {
		if (entry->handle == windowHandle)
			return entry;
		entry = entry->next;
	}
	return NULL;
}


wHandleType
windowHandleFromIndex(wIndexType windowIndex) 
{
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while (entry) {
		if (entry->windowIndex == windowIndex)
			return entry->handle;
		entry = entry->next;
	}
	return NULL;
}

wIndexType
windowIndexFromHandle(wHandleType windowHandle)
{
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while (entry) {
		if (entry->handle == windowHandle)
			return entry->windowIndex;
		entry = entry->next;
	}
	return 0;
}

wIndexType
windowIndexFromBlock( windowDescriptorBlock * thisWindow)
{
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while (entry) {
		if (entry == thisWindow)
			return entry->windowIndex;
		entry = entry->next;
	}
	return 0;
}

static sqInt nextIndex = 1; 

/* Create a new entry in the linkedlist of windows.
 * If the calloc fails, return NULL which will then go back to the
 * prim and fail it cleanly.
 * Initialize the block to a sensible state
 */
windowDescriptorBlock *
AddWindowBlock(void)
{
windowDescriptorBlock *thisWindow;

	thisWindow = (windowDescriptorBlock*) calloc(1, sizeof(windowDescriptorBlock));
	if (!thisWindow)
		return NULL;
	thisWindow->next = windowListRoot;
	thisWindow->windowIndex = nextIndex++;
	thisWindow->handle = NULL;
	windowListRoot = thisWindow;

	return windowListRoot;
}

/* Remove the given entry from the list of windows. Free it, if found.
 */
static sqInt
RemoveWindowBlock(windowDescriptorBlock * thisWindow)
{
windowDescriptorBlock *prevEntry;

	/* Unlink the entry from the module chain */
	if (thisWindow == windowListRoot)
		windowListRoot = thisWindow->next;
	else {
		prevEntry = windowListRoot;
		while (prevEntry->next != thisWindow) {
			prevEntry = prevEntry->next;
			if (!prevEntry)
				return 0;
		}
		prevEntry->next = thisWindow->next;
	}
	free(thisWindow);
	return 1;
}

sqInt
getCurrentIndexInUse(void) { return nextIndex - 1; }

#if TerfVM
void *
ioGetWindowHandle(void)
{
	extern void *getSTWindow();
	return getSTWindow();
}

sqInt
ioPositionOfNativeWindow(usqIntptr_t windowHandle)
{
	if (!windowHandle)
		return -1;

	NSWindow *window = (__bridge NSWindow *)(void *)windowHandle;
    NSRect win = [window frame];

	return packedDoubleXY(win.origin.x,
						  yZero() - (win.origin.y + win.size.height));
}

sqInt
ioSizeOfNativeWindow(usqIntptr_t windowHandle)
{
	if (!windowHandle)
		return -1;

	NSWindow *window = (__bridge NSWindow *)(void *)windowHandle;
	NSRect win = [window frame];

	return packedDoubleXY(win.size.width,win.size.height);
}

static int
titlebarHeight(NSWindow *window,NSRect win)
{
    NSSize contentSize = [window contentRectForFrameRect: win].size;

    return win.size.height - contentSize.height;
}

/* ioPositionOfNativeDisplay answers the origin of the client rectangle,
 * in screen coordinates of the specified window handle, i.e. of the
 * rectangle below the title bar.
 */
sqInt
ioPositionOfNativeDisplay(usqIntptr_t windowHandle)
{
	if (!windowHandle)
		return -1;

	NSWindow *window = (__bridge NSWindow *)(void *)windowHandle;
    NSRect win = [window frame];

	return packedDoubleXY(win.origin.x,
						  yZero() + titlebarHeight(window,win)
						  - (win.origin.y + win.size.height));
}

/* ioSizeOfNativeDisplay answers the extent of the client rectangle,
 * in screen coordinates of the specified window handle, i.e. of the
 * rectangle below the title bar.
 */
sqInt
ioSizeOfNativeDisplay(usqIntptr_t windowHandle)
{
	if (!windowHandle)
		return -1;

	NSWindow *window = (__bridge NSWindow *)(void *)windowHandle;
    NSRect win = [window frame];

	return packedDoubleXY(win.size.width,
						  win.size.height-titlebarHeight(window,win));
}

/* Return the pixel origin (topleft) of the platform-defined working area
   for the screen containing the given window. */
/* copied from platforms/unix/vm-display-X11/sqUnixX11.c */
sqInt
ioPositionOfScreenWorkArea(sqIntptr_t windowIndex)
{
    NSScreen *screen = [[[NSApplication sharedApplication] mainWindow] screen];
    NSRect frame = [screen visibleFrame];
	// 0@36 last we looked...
	return packedDoubleXY(frame.origin.x,
						  yZero() - (frame.origin.y + frame.size.height));
}

/* Return the pixel extent of the platform-defined working area
   for the screen containing the given window. */
sqInt
ioSizeOfScreenWorkArea(sqIntptr_t windowIndex)
{
    NSScreen *screen = [[[NSApplication sharedApplication] mainWindow] screen];
    NSRect frame = [screen visibleFrame];
	return packedDoubleXY(frame.size.width,frame.size.height);
}

/* Answer an Array of screen coordinates as pairs of packed points, origin,
 * extent for each screen. So if there is one monitor the array has two entries.
 */
sqInt
ioScreenRectangles(void)
{
	NSArray *screens = NSScreen.screens;
	int n = [screens count];
	sqInt a = instantiateClassindexableSize(classArray(),n * 2);

	if (a)
		for (int i = 0; i < n; i++) {
			NSRect f = [screens[i] visibleFrame];
			(void)storeIntegerofObjectwithValue
					(i * 2, a, packedDoubleXY(f.origin.x,
											  yZero() - (f.origin.y + f.size.height)));
			(void)storeIntegerofObjectwithValue
					(i * 2 + 1, a, packedDoubleXY(f.size.width,f.size.height));
		}
	return  a;
}
#endif // TerfVM

/* What happens with multiple monitors? There's a unified address space that
 * covers all displays.
 */
sqInt
ioSetCursorPositionXY(long x, long y)
{
	CGPoint point;
	point.x = x; point.y = y;
	CGError err = CGWarpMouseCursorPosition(point);
	if (err != kCGErrorSuccess)
		err = CGDisplayMoveCursorToPoint(CGMainDisplayID(),point);
	return err == kCGErrorSuccess ? 0 : -1;
}
