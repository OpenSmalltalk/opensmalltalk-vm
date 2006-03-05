/*
 *  sqMacHostWindow.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
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
