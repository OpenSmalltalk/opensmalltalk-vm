//
//  sqSqueakOSXDropAPI.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-27.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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
#import "sqSqueakOSXScreenAndWindow.h"
#include "sqMacHostWindow.h"
#include "sq.h"
#import "sqSqueakOSXOpenGLView.h"

extern wHandleType windowHandleFromIndex(sqInt windowIndex);
extern struct VirtualMachine* interpreterProxy;

sqInt dropInit(void) {
	return 1;
};

sqInt dropShutdown(void) { 
	return 1;
};

char* dropRequestFileName(sqInt dropIndex) {
	/* return name of file or NULL if error */
	sqSqueakOSXOpenGLView *view = [((sqSqueakOSXScreenAndWindow*)((__bridge NSWindow *)windowHandleFromIndex(1)).delegate) getMainViewOnWindow];
	NSString *fileNameString = [view dragFileNameStringAtIndex: dropIndex];
	return (char *) [fileNameString UTF8String];
}

/* note: dropRequestFileHandle needs to bypass plugin security checks when implemented */
sqInt dropRequestFileHandle(sqInt dropIndex) {

	/* return READ-ONLY file handle OOP or nilObject if error */

	char *fileName = dropRequestFileName(dropIndex);
	if (!fileName)
		return 0;

	void *fn = interpreterProxy->ioLoadFunctionFrom("fileOpenNamesizewritesecure", "FilePlugin");
	if (fn == NULL) {
		/* begin primitiveFail */
        interpreterProxy->success(false);
		return 0;
	}
	sqInt result = ((sqInt (*) (char * nameIndex, sqInt nameSize, sqInt writeFlag, sqInt secureFlag)) fn)(fileName,(sqInt) strlen(fileName), 0,0);
	return result;
}

sqInt sqSecFileAccessCallback(void *ptr) { 
	return 0; 
}
