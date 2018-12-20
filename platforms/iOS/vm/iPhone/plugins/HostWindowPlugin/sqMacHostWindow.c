/*
 *  sqMacHostWindow.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *  Copyright Corporate Smalltalk Consulting Ltd 2008. All rights reserved.
 *
	July 15th 2005 add logic to flush QD buffers for os-x 10.4
	 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
	May 15th, 2008 IPhone

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

//

#include "sqVirtualMachine.h"
#include "sqMacHostWindow.h"
#include <stdlib.h>

extern struct VirtualMachine *interpreterProxy;
sqInt RemoveWindowBlock(windowDescriptorBlock * thisWindow);

sqInt createWindowWidthheightoriginXyattrlength(sqInt w,sqInt h,sqInt x,sqInt y,  char * list, sqInt listLength) {
	return -1;
}

sqInt closeWindow(sqInt windowIndex) {
	return 1;
}

sqInt ioPositionOfWindow(wIndexType windowIndex)
{
	if (windowHandleFromIndex(windowIndex) == NULL)
		return -1;
	return (0 << 16) | (0 & 0xFFFF);  /* left is high 16 bits; top is low 16 bits */
}

sqInt ioPositionOfWindowSetxy(wIndexType windowIndex, sqInt x, sqInt y)
{
	return -1;
}

sqInt ioSizeOfWindow(wIndexType windowIndex)
{
	sqInt w=0, h=0;
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

sqInt ioPositionOfNativeDisplay(unsigned long windowHandle)
{
	sqInt w=0, h=0;
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

sqInt ioSizeOfWindowSetxy(wIndexType windowIndex, sqInt x, sqInt y)
{
	return (0);  /* w is high 16 bits; h is low 16 bits */
}

sqInt ioSetTitleOfWindow(sqInt windowIndex, char * newTitle, sqInt sizeOfTitle) {
	return 1;
}

sqInt ioCloseAllWindows(void) {
	return 1;
}



/* addendum to sqPlatformSpecific.h */
/* multiple host windows stuff */

static windowDescriptorBlock *windowListRoot = NULL;

/* end addendum to sqPlatformSpecific.h */

/* simple linked list management code */
/* window list management */

windowDescriptorBlock *windowBlockFromIndex(sqInt windowIndex) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->windowIndex == windowIndex) return entry;
		entry = entry->next;
	}
	return NULL;
}

windowDescriptorBlock *windowBlockFromHandle(wHandleType windowHandle) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->handle == windowHandle) return entry;
		entry = entry->next;
	}
	return NULL;
}


wHandleType windowHandleFromIndex(sqInt windowIndex)  {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->windowIndex == windowIndex) return entry->handle;
		entry = entry->next;
	}
	return NULL;
}

sqInt windowIndexFromHandle(wHandleType windowHandle) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->handle == windowHandle) return entry->windowIndex;
		entry = entry->next;
	}
	return 0;
}

sqInt windowIndexFromBlock( windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry == thisWindow) return entry->windowIndex;
		entry = entry->next;
	}
	return 0;
}

static sqInt nextIndex = 1; 

windowDescriptorBlock *AddWindowBlock(void) {
/* create a new entry in the linkedlist of windows.
 * If the calloc fails, return NULL which will then go back to the
 * prim and fail it cleanly.
 * Initialize the block to a sensible state
 */
windowDescriptorBlock *thisWindow;

	thisWindow = (windowDescriptorBlock*) calloc(1, sizeof(windowDescriptorBlock));
	if ( thisWindow == NULL) {
		return NULL;
	}
	thisWindow->next = windowListRoot;
	thisWindow->windowIndex = nextIndex++;
	thisWindow->handle = NULL;
	windowListRoot = thisWindow;

	return windowListRoot;
}

/*
 * RemoveWindowBlock:
 * Remove the given entry from the list of windows.
 * free it, if found.
 */
 sqInt RemoveWindowBlock(windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *prevEntry;


	/* Unlink the entry from the module chain */
	if(thisWindow == windowListRoot) {
		windowListRoot = thisWindow->next;
	} else {
		prevEntry = windowListRoot;
		while(prevEntry->next != thisWindow) {
			prevEntry = prevEntry->next;
			if (prevEntry == NULL) {
				return 0;
			}
		}
		prevEntry->next = thisWindow->next;
	}
	free(thisWindow);
	return 1;
}

sqInt getCurrentIndexInUse(void) {
	return nextIndex-1;
}
