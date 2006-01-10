/*
 *  sqMacHostWindow.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
 */

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif
#include "HostWindowPlugin.h"

/* window handle type */
#define wHandleType WindowPtr
#define wIndexType int 

typedef struct windowDescriptorBlock {
	struct windowDescriptorBlock * next;
	wHandleType		handle;
	wIndexType		windowIndex;
	/* extra fields to support your platform needs */
#if TARGET_API_MAC_CARBON
	CGContextRef context;
	int rememberTicker;
	int dirty;
	int sync;
	int	width;
	int	height;
#endif
} windowDescriptorBlock;

windowDescriptorBlock *windowBlockFromHandle(wHandleType windowHandle);
int windowIndexFromBlock( windowDescriptorBlock * thisWindow);
int windowIndexFromHandle(wHandleType windowHandle);
wHandleType windowHandleFromIndex(wIndexType windowIndex);
windowDescriptorBlock *AddWindowBlock(void);
windowDescriptorBlock *windowBlockFromIndex(int windowIndex);
int getCurrentIndexInUse(void);