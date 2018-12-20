/*
 *  sqMacHostWindow.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Tue Jul 20 2004.
 *
 
   3.8.15b3  Feb 19th, 2007 JMM add cursor set logic
   Altered for IPhone

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

#include "HostWindowPlugin.h"
#ifdef BUILD_FOR_OSX
#include <ApplicationServices/ApplicationServices.h>
#define wHandleType  NSWindow *
#else
#include <CoreGraphics/CoreGraphics.h>
#define wHandleType  UIWindow *
#endif
/* window handle type */
#define wIndexType sqInt

typedef struct windowDescriptorBlock {
	struct windowDescriptorBlock * next;
	__unsafe_unretained wHandleType		handle;
	wIndexType		windowIndex;
	/* extra fields to support your platform needs */
	void * context;
	CGRect	updateArea;
	sqInt	width;
	sqInt	height;
} windowDescriptorBlock;

windowDescriptorBlock *windowBlockFromHandle(wHandleType windowHandle);
sqInt windowIndexFromBlock( windowDescriptorBlock * thisWindow);
sqInt windowIndexFromHandle(wHandleType windowHandle);
wHandleType windowHandleFromIndex(wIndexType windowIndex);
windowDescriptorBlock *AddWindowBlock(void);
windowDescriptorBlock *windowBlockFromIndex(sqInt windowIndex);
sqInt getCurrentIndexInUse(void);
