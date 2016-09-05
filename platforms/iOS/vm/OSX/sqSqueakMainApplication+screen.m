//
//  sqSqueakMainApplication+screen.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/22/08.
//  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
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

#ifdef BUILD_FOR_OSX
#import "SqueakOSXAppDelegate.h"
extern SqueakOSXAppDelegate *gDelegateApp;
#else
#import "SqueakNoOGLIPhoneAppDelegate.h"
SqueakNoOGLIPhoneAppDelegate *gDelegateApp;
#endif
#import "sqSqueakMainApplication+screen.h"
#import "sqMacV2Browser.h"
#import "sqMacV2Window.h"
#import "HostWindowPlugin.h"

extern BOOL gSqueakHeadless;

@implementation sqSqueakMainApplication (screen) 

- (double) ioScreenScaleFactor {
	return 1.0;
}

- (sqInt) ioScreenSize {
	sqInt w, h;
	sqInt browserGetWindowSize(void);
	void makeMainWindow(void);
	sqInt getCurrentIndexInUse(void);
	extern BOOL gSqueakExplicitWindowOpenNeeded;	
	
	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) 
		return ((16 << 16) | 16);
	
	if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
		return browserGetWindowSize();
	
	if (getSTWindow() == NULL && !gSqueakExplicitWindowOpenNeeded) {
		makeMainWindow();
	}
	@synchronized(gDelegateApp.mainView) {
#ifdef BUILD_FOR_OSX
		NSRect
#else
		CGRect
#endif
		screenSize = [gDelegateApp.mainView bounds];
		w = (sqInt) screenSize.size.width;
		h = (sqInt) screenSize.size.height;
	}
	return (w << 16) | (h & 0xFFFF);  /* w is high 16 bits; h is low 16 bits */
	
}

- (void) unionScreenArea: (windowDescriptorBlock *) windowBlock clip: (CGRect *) clip {
	//		printf("\n top %f left %f height %f width %f",clip->origin.y,clip->origin.x,clip->size.height,clip->size.width);
	if (CGRectIsEmpty(windowBlock->updateArea))
		windowBlock->updateArea = *clip;
	else
		windowBlock->updateArea = CGRectUnion(windowBlock->updateArea, *clip);				
}

@end
