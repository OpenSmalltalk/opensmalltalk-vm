/*
 *  sqSqueakScreenAPI.m
 *  
 *
 *  Created by John M McIntosh on 5/15/08.
 *
 */
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
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

#import "sq.h"
#import "sqSqueakScreenAPI.h"
#import "sqSqueakScreenAndWindow.h"

#ifdef BUILD_FOR_OSX
# import "sqMacHostWindow.h"
#else
# include "SqueakNoOGLIPhoneAppDelegate.h"
extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;
#endif


sqSqueakNullScreenAndWindow *getMainWindowDelegate() {
#ifdef BUILD_FOR_OSX
	return ((__bridge NSWindow *) windowHandleFromIndex(1)).delegate;
#else
	return [gDelegateApp screenAndWindow];
#endif
}

double ioScreenScaleFactor(void) {
	//API Documented
		 
	return [getMainWindowDelegate() ioScreenScaleFactor];
}

sqInt ioScreenSize(void) {
	//API Documented
		 
	return [getMainWindowDelegate() ioScreenSize];
}

sqInt ioScreenDepth(void) {
	//API Documented
	return [getMainWindowDelegate() ioScreenDepth];
}

sqInt ioHasDisplayDepth(sqInt depth) {
	//API Documented
	return [getMainWindowDelegate() ioHasDisplayDepth: depth];
}


sqInt ioForceDisplayUpdate(void){
	//API Documented
	[getMainWindowDelegate() ioForceDisplayUpdate];
	return 0;
}

sqInt ioSetFullScreen(sqInt fullScreen) {
	//API Documented
	[getMainWindowDelegate() ioSetFullScreen: fullScreen];
	extern sqInt setFullScreenFlag(sqInt fullScreen);
	setFullScreenFlag(fullScreen);
	return 0;
}


sqInt ioShowDisplay(
				  sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
				  sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB) {

	//API Documented
	
	ioShowDisplayOnWindow((unsigned char *)pointerForOop(dispBitsIndex),  width,  height,  depth, affectedL,  affectedR,  affectedT,  affectedB, 1);
	return 1;
}


sqInt
ioShowDisplayOnWindow(unsigned char* dispBitsIndex, sqInt width, 
						  sqInt height, sqInt depth, sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB, 
						  sqIntptr_t windowIndex) {
	//API Documented
	return [getMainWindowDelegate()  
	 ioShowDisplayOnWindow: dispBitsIndex
	 width: (int) width 
	 height: (int) height
	 depth: (int) depth
	 affectedL: (int) affectedL
	 affectedR: (int) affectedR
	 affectedT: (int) affectedT
	 affectedB: (int) affectedB
	 windowIndex:  (int) windowIndex];
}


char *ioGetWindowLabel(void)
{
    return [getMainWindowDelegate() ioGetTitle];
}

sqInt ioSetWindowLabelOfSize(void *lblIndex, sqInt sz)
{
    [getMainWindowDelegate() ioSetTitle: lblIndex length: sz];
	return 1;
}

sqInt ioGetWindowWidth(void) { return 0; }

sqInt ioGetWindowHeight(void) { return 0; }

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h) { return 0; }

sqInt ioIsWindowObscured(void) { return 0; }

/* This is invoked when the GC moves the display bitmap.  For now do nothing. */
void  ioNoteDisplayChangedwidthheightdepth(void *bits, int w, int h, int d) {};
