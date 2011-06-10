/*
 *  sqMacHostWindow.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
	July 15th 2005 add logic to flush QD buffers for os-x 10.4
	 3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
	4.1.0b2  set window title via cfstring
 */

#include "sqVirtualMachine.h"
#include "sqMacHostWindow.h"
#include "sqMacWindow.h"

extern struct VirtualMachine *interpreterProxy;
int RemoveWindowBlock(windowDescriptorBlock * thisWindow);

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
	windowBlock->isInvisible = !MacIsWindowVisible(window);
	SetUpCarbonEventForWindowIndex(index);
	QDBeginCGContext(GetWindowPort(windowBlock->handle),&windowBlock->context); 
//	CreateCGContextForPort(GetWindowPort(windowBlock->handle),&windowBlock->context); 
	windowBlock->width = w;
	windowBlock->height = h; 
	
	sqShowWindow(index);
	return index;
}

void setWindowTrackingRgn(int windowIndex) {
		
	Rect rgnRect;
	RgnHandle rgn = NewRgn();
	MouseTrackingRegionID id;
	windowDescriptorBlock *windowBlock = windowBlockFromIndex(windowIndex);
	
	if (!windowBlock) 
		return;
		
	if (windowBlock->windowTrackingRef) {
		GetWindowBounds(windowBlock->handle, kWindowContentRgn, &rgnRect);	
		SetRectRgn( rgn, rgnRect.left, rgnRect.top, rgnRect.right, rgnRect.bottom );
		ChangeMouseTrackingRegion(windowBlock->windowTrackingRef,rgn, NULL);
		DisposeRgn( rgn );	
		return;
	}

	GetWindowBounds(windowBlock->handle, kWindowContentRgn, &rgnRect);	
	SetRectRgn( rgn, rgnRect.left, rgnRect.top, rgnRect.right, rgnRect.bottom );
		
	id.signature = 'FAST';
	id.id = windowIndex;
		
	OSStatus err = CreateMouseTrackingRegion(windowBlock->handle, rgn, NULL, kMouseTrackingOptionsGlobalClip,
						id, NULL, NULL, &windowBlock->windowTrackingRef);
	if ( noErr == err ) {
		RetainMouseTrackingRegion( windowBlock->windowTrackingRef);
		err = SetMouseTrackingRegionEnabled( windowBlock->windowTrackingRef, TRUE );
	}
		
	DisposeRgn( rgn );	
}


int closeWindow(int windowIndex) {
	wHandleType	windowHandle;
	windowHandle = windowHandleFromIndex(windowIndex);
	if(windowHandle == NULL) 
		return 0;
	if (windowBlockFromIndex(windowIndex)->context)
		QDEndCGContext(GetWindowPort(windowBlockFromIndex(windowIndex)->handle),&windowBlockFromIndex(windowIndex)->context);
		//CGContextRelease(windowBlockFromIndex(windowIndex)->context);
	

	if (windowBlockFromIndex(windowIndex)->windowTrackingRef) {
		ReleaseMouseTrackingRegion(windowBlockFromIndex(windowIndex)->windowTrackingRef );
		windowBlockFromIndex(windowIndex)->windowTrackingRef = NULL;
	}

	windowBlockFromIndex(windowIndex)->context = NULL;
	RemoveWindowBlock(windowBlockFromIndex(windowIndex));	
	DisposeWindow(windowHandle);
	return 1;
}

int ioPositionOfWindow(wIndexType windowIndex)
{
	Rect portRect;
	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;
		
	GetPortBounds(GetWindowPort(windowHandleFromIndex(windowIndex)),&portRect);
 	QDLocalToGlobalRect(GetWindowPort(windowHandleFromIndex(windowIndex)), &portRect);
	return (portRect.left << 16) | (portRect.top & 0xFFFF);  /* left is high 16 bits; top is low 16 bits */
}

int ioPositionOfWindowSetxy(wIndexType windowIndex, int x, int y)
{
	void *giLocker;
	int return_value=0;
	if (windowHandleFromIndex(windowIndex) == nil)
		return -1;

	giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		sqInt foo[7];
		foo[0] = 4;
		foo[1] = (sqInt) MoveWindow;
		foo[2] = (sqInt) windowHandleFromIndex(windowIndex);
		foo[3] = x;
		foo[4] = y;
		foo[5] = true;
		foo[6] = 0;
		((sqInt (*) (void *)) giLocker)(foo);
		return_value = interpreterProxy->positive32BitIntegerFor(foo[6]);
	}
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
	giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
	if (giLocker != 0) {
		sqInt foo[7];
		foo[0] = 4;
		foo[1] = (sqInt) SizeWindow;
		foo[2] = (sqInt) windowHandleFromIndex(windowIndex);
		foo[3] = x;
		foo[4] = y;
		foo[5] = true;
		foo[6] = 0;
		((sqInt (*) (void *)) giLocker)(foo);
		return_value = interpreterProxy->positive32BitIntegerFor(foo[6]);
	}
	setWindowTrackingRgn(windowIndex);
	return ioSizeOfWindow(windowIndex);
}

int ioSetTitleOfWindow(int windowIndex, char * newTitle, int sizeOfTitle) {
	char string[256];
	if (sizeOfTitle > 255) 
		return -1;

	memcpy(string,newTitle,sizeOfTitle);
	string[sizeOfTitle] = 0x00;
	
	CFStringRef windowTitleCFString = CFStringCreateWithCString (nil,string,kCFStringEncodingUTF8);

	SetWindowTitleWithCFString (windowHandleFromIndex(windowIndex),windowTitleCFString);
	
	CFRelease(windowTitleCFString);
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
	return 0;
}

int windowIndexFromBlock( windowDescriptorBlock * thisWindow) {
windowDescriptorBlock *entry;
	entry = windowListRoot;
	while(entry) {
		if(entry == thisWindow) return entry->windowIndex;
		entry = entry->next;
	}
	return 0;
}

static int nextIndex = 1; 

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
 int RemoveWindowBlock(windowDescriptorBlock * thisWindow) {
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

int getCurrentIndexInUse(void) {
	return nextIndex-1;
}
