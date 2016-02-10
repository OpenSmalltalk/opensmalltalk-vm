/*
 *  sqMacV2Window.m
 *  SqueakNoOGLIPhone
 *
 *  Created by John M McIntosh on 5/16/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *
 */
/* Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *  
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */
//

#import "sq.h"
#import "sqMacV2Window.h"
#import "sqMacHostWindow.h"
#import "SqueakOSXAppDelegate.h"
#import "sqMacV2Browser.h"

extern BOOL gSqueakHeadless;
extern SqueakOSXAppDelegate *gDelegateApp;

void * getSTWindow(void) {
	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) return NULL;	
	return  windowHandleFromIndex(1);
}

void makeMainWindow(void) { 
	sqInt width,height;
	windowDescriptorBlock *windowBlock;
	extern sqInt getSavedWindowSize(void); //This is VM Callback
	extern sqInt setSavedWindowSize(sqInt value); //This is VM Callback
	
	/* get old window size */
	width  = (unsigned) getSavedWindowSize() >> 16;
	height = getSavedWindowSize() & 0xFFFF;
	windowBlock = AddWindowBlock();
	windowBlock-> handle = gDelegateApp.window;
	windowBlock->context = nil;
	windowBlock->updateArea = CGRectZero;
	width  = (usqInt) ioScreenSize() >> 16;
	height = ioScreenSize() & 0xFFFF;
	
	setSavedWindowSize( (width << 16) |(height & 0xFFFF));
	windowBlock->width = width;
	windowBlock->height = height; 
}

