//
//  sqSqueakCursorAPI.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import "sqSqueakCursorAPI.h"
#import "sqSqueakAppDelegate.h"
#import "sqSqueakMainApplication+cursor.h"
#import "sqSqueakOSXApplication+cursor.h"

extern sqSqueakAppDelegate *gDelegateApp;

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {
	/* Old version; forward to new version. */
	[gDelegateApp.squeakApplication  setCursor: cursorBitsIndex
									  withMask: 0
									   offsetX: offsetX offsetY: offsetY];
	return 0;
}

sqInt ioSetCursorWithMask( sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY) 
{	
	[gDelegateApp.squeakApplication  setCursor: cursorBitsIndex
									  withMask: cursorMaskIndex
									   offsetX: offsetX offsetY: offsetY];
	return 0;
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY) {
	return [(sqSqueakOSXApplication *) gDelegateApp.squeakApplication ioSetCursorARGB: cursorBitsIndex extentX: extentX extentY: extentY
												   offsetX: offsetX offsetY: offsetY];

}