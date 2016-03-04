/*
 *  sqMacHostWindow.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
 
   3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
	eem 12/2/2014 16:47 MouseTrackingRef => HIViewTrackingAreaRef

 */

#include <Carbon/Carbon.h>
#include "HostWindowPlugin.h"

/* window handle type */
#define wHandleType WindowPtr
#define wIndexType sqInt

typedef struct windowDescriptorBlock {
	struct windowDescriptorBlock * next;
	wHandleType		handle;
	wIndexType		windowIndex;
	/* extra fields to support your platform needs */
	CGContextRef context;
	HIViewTrackingAreaRef windowTrackingRef;
	long width;
	long height;
	long rememberTicker;
	char dirty;
	char sync;
	char locked;
	char isInvisible;
} windowDescriptorBlock;

windowDescriptorBlock *windowBlockFromHandle(wHandleType windowHandle);
sqInt windowIndexFromBlock(windowDescriptorBlock * thisWindow);
sqInt windowIndexFromHandle(wHandleType windowHandle);
wHandleType windowHandleFromIndex(wIndexType windowIndex);
windowDescriptorBlock *AddWindowBlock(void);
windowDescriptorBlock *windowBlockFromIndex(sqInt windowIndex);
sqInt getCurrentIndexInUse(void);
void SetUpCarbonEventForWindowIndex(sqInt index);
void setWindowTrackingRgn(sqInt windowIndex);
