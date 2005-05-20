/*
 *  sqMacHostWindow.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
 */

#include "sqVirtualMachine.h"
#include "sqMacHostWindow.h"
#include "sqMacWindow.h"

extern struct VirtualMachine *interpreterProxy;
static int RemoveWindowBlock(windowDescriptorBlock * thisWindow);
int SetUpCarbonEventForWindowIndex(int index);

int createWindowWidthheightoriginXyattrlength(int w,int h,int x,int y,  char * list, int listLength) {
	int index;
	long windowClass,windowAttributes;
	WindowPtr window;
	windowDescriptorBlock *windowBlock;
	if (listLength != 8) return -1;
	
	memmove(&windowClass, list, 4);
	memmove(&windowAttributes, list+4, 4);

	window = SetUpWindow(y,x,y+h,x+w,windowClass,windowAttributes);
	if (window == 0) return -1;
	
	windowBlock = AddWindowBlock();
	windowBlock->handle = (wHandleType) window;
	index = windowBlock->windowIndex;
#if I_AM_CARBON_EVENT
	SetUpCarbonEventForWindowIndex(index);
#endif
#ifndef BROWSERPLUGIN
	sqShowWindow(index);
#endif
	return index;
}

int closeWindow(int windowIndex) {
	wHandleType	windowHandle;
	windowHandle = windowHandleFromIndex(windowIndex);
	if(windowHandle == NULL) 
		return 0;
	RemoveWindowBlock(windowBlockFromIndex(windowIndex));
	DisposeWindow(windowHandle);
	return 1;
}

int ioPositionOfWindow(wIndexType windowIndex)
{
	Rect portRect;
	GrafPtr oldPort;
	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;
		
	GetPort(&oldPort);
	SetPortWindowPort(windowHandleFromIndex(windowIndex));
	GetPortBounds(GetWindowPort(windowHandleFromIndex(windowIndex)),&portRect);
 	LocalToGlobal((Point *) &portRect);
	SetPort(oldPort);
	return (portRect.left << 16) | (portRect.top & 0xFFFF);  /* left is high 16 bits; top is low 16 bits */
}

int ioPositionOfWindowSetxy(wIndexType windowIndex, int x, int y)
{
	void *giLocker;
	int return_value=0;
	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;
#if TARGET_API_MAC_CARBON
	giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		long *foo;
		foo = malloc(sizeof(long)*7);
		foo[0] = 4;
		foo[1] = (int) MoveWindow;
		foo[2] = (long) windowHandleFromIndex(windowIndex);
		foo[3] = x;
		foo[4] = y;
		foo[5] = true;
		foo[6] = 0;
		((int (*) (void *)) giLocker)(foo);
		return_value = interpreterProxy->positive32BitIntegerFor(foo[6]);
		free(foo);
	}
#else
	MoveWindow(windowHandleFromIndex(windowIndex),x,y,true);
#endif
	return ioPositionOfWindow(windowIndex);
}

int ioSizeOfWindow(wIndexType windowIndex)
{
	Rect portRect;
	int w, h;

	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;


	GetPortBounds(GetWindowPort(windowHandleFromIndex(windowIndex)),&portRect);
	w =  portRect.right -  portRect.left;
	h =  portRect.bottom - portRect.top;
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
}

int ioSizeOfWindowSetxy(wIndexType windowIndex, int x, int y)
{
	void * giLocker;
	int return_value=0;
	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;
#if TARGET_API_MAC_CARBON
	giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		long *foo;
		foo = malloc(sizeof(long)*7);
		foo[0] = 4;
		foo[1] = (int) SizeWindow;
		foo[2] = (long) windowHandleFromIndex(windowIndex);
		foo[3] = x;
		foo[4] = y;
		foo[5] = true;
		foo[6] = 0;
		((int (*) (void *)) giLocker)(foo);
		return_value = interpreterProxy->positive32BitIntegerFor(foo[6]);
		free(foo);
	}
#else
	SizeWindow(windowHandleFromIndex(windowIndex),x,y,true);
#endif
	return ioSizeOfWindow(windowIndex);
}

int ioSetTitleOfWindow(int windowIndex, char * newTitle, int sizeOfTitle) {
	char string[256];
	if (sizeOfTitle > 255) 
		return -1;
	memcpy(string,newTitle,sizeOfTitle);
	string[sizeOfTitle] = 0x00;
	SetWindowTitle(windowIndex,string);
return 1;
}

int ioCloseAllWindows(void) {
	return 1;
}



/* addendum to sqPlatformSpecific.h */
/* multiple host windows stuff */

static windowDescriptorBlock *windowListRoot = NULL;

/* end addendum to sqPlatformSpecific.h */

/* simple linked list management code */
/* window list management */

windowDescriptorBlock *windowBlockFromIndex(int windowIndex) {
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


wHandleType windowHandleFromIndex(int windowIndex)  {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->windowIndex == windowIndex) return entry->handle;
		entry = entry->next;
	}
	return NULL;
}

int windowIndexFromHandle(wHandleType windowHandle) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry->handle == windowHandle) return entry->windowIndex;
		entry = entry->next;
	}
	return NULL;
}

int windowIndexFromBlock( windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry == thisWindow) return entry->windowIndex;
		entry = entry->next;
	}
	return NULL;
}

windowDescriptorBlock *AddWindowBlock(void) {
/* create a new entry in the linkedlist of windows.
 * If the calloc fails, return NULL which will then go back to the
 * prim and fail it cleanly.
 * Initialize the block to a sensible state
 */
static int nextIndex = 1; 
windowDescriptorBlock *thisWindow;
	thisWindow = (windowDescriptorBlock*) calloc(1, sizeof(windowDescriptorBlock));
	if ( thisWindow == NULL) {
		return NULL;
	}
	thisWindow->next = windowListRoot;
	thisWindow->windowIndex = nextIndex++;
	thisWindow->handle = NULL;
	/* additional platform init code here */
	windowListRoot = thisWindow;
	return windowListRoot;
}

/*
 * RemoveWindowBlock:
 * Remove the given entry from the list of windows.
 * free it, if found.
 */
static int RemoveWindowBlock(windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *prevEntry;

	/* Unlink the entry from the module chain */
	if(thisWindow == windowListRoot) {
		windowListRoot = thisWindow->next;
	} else {
		prevEntry = windowListRoot;
		while(prevEntry->next != thisWindow) {
			prevEntry = prevEntry->next;
			if (prevEntry == NULL) return NULL;
		}
		prevEntry->next = thisWindow->next;
	}
	free(thisWindow);
	return 1;
}

