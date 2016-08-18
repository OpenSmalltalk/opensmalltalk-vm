//
//  sqMacV2Browser.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/17/08.
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

#import "sq.h"
#import "sqMacV2Browser.h"

BOOL		gSqueakBrowserSubProcess=false,gSqueakBrowserWasHeadlessButMadeFullScreen=false;
void		*SharedBrowserBitMapContextRef=NULL;

extern sqInt getFullScreenFlag(void);  //This is VM callback


BOOL b(void) {
	return gSqueakBrowserWasHeadlessButMadeFullScreen;
}

BOOL browserActiveAndDrawingContextOk(void) {
	return gSqueakBrowserSubProcess && SharedBrowserBitMapContextRef;
}

BOOL browserActiveAndDrawingContextOkAndInFullScreenMode(void) {
	return browserActiveAndDrawingContextOk() && browserWasHeadlessButMadeFullScreen() && getFullScreenFlag();
}

BOOL browserActiveAndDrawingContextOkAndNOTInFullScreenMode(void) {
	return browserActiveAndDrawingContextOk() && !getFullScreenFlag();
}

sqInt browserGetWindowSize(void) {
	return 0;
}

double browserGetWindowScaleFactor(voud) {
	return 1.0;
}

BOOL browserWasHeadlessButMadeFullScreen() {
	return gSqueakBrowserWasHeadlessButMadeFullScreen;
}
