/*
 *  sqMacHostWindow.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
 
   3.8.15b3  Feb 19th, 2007 JMM add cursor set logic

 */

#include <Carbon/Carbon.h>
#include "HostWindowPlugin.h"

/* window handle type */
#define wHandleType WindowPtr
#define wIndexType int 

typedef struct windowDescriptorBlock {
	struct windowDescriptorBlock * next;
	wHandleType		handle;
	wIndexType		windowIndex;
	/* extra fields to support your platform needs */
	CGContextRef context;
	MouseTrackingRef windowTrackingRef;
	int rememberTicker;
	int dirty;
	int sync;
	int locked;
	int	width;
	int	height;
	int isInvisible;
} windowDescriptorBlock;

windowDescriptorBlock *windowBlockFromHandle(wHandleType windowHandle);
int windowIndexFromBlock( windowDescriptorBlock * thisWindow);
int windowIndexFromHandle(wHandleType windowHandle);
wHandleType windowHandleFromIndex(wIndexType windowIndex);
windowDescriptorBlock *AddWindowBlock(void);
windowDescriptorBlock *windowBlockFromIndex(int windowIndex);
int getCurrentIndexInUse(void);
void SetUpCarbonEventForWindowIndex(int index);
void setWindowTrackingRgn(int windowIndex);
