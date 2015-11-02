//
//  sqSqueakOSXApplication+clipboard.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-23.
//  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
//  Some code sqUnixQuartz.m -- display via native windows on Mac OS X	-*- ObjC -*-
//  Author: Ian Piumarta <ian.piumarta@squeakland.org>
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

#import "sqSqueakOSXApplication+clipboard.h"


static char * clipboard=NULL;

@implementation sqSqueakOSXApplication (clipboard)

/* Cheat, we always call clipboardSize before clipboardRead, so obviously we can do the read when asking for the size */

- (sqInt) clipboardSize {
	NSPasteboard *pboard= [NSPasteboard generalPasteboard];
	NSString     *type= [pboard availableTypeFromArray: @[NSStringPboardType]];
	if (clipboard) free(clipboard);
	clipboard = NULL;
	if (type != NULL) {
		NSString *possibleData = [pboard stringForType: type];
		if (!possibleData) 
			return 0;
		const char *contents= [[possibleData precomposedStringWithCanonicalMapping] UTF8String];
		if (contents != nil)
			clipboard= strdup(contents);
    }
	return clipboard ? (sqInt) strlen(clipboard) : 0;
}

//Evil assumption is that clipboardSize size <= byteArrayIndex size

- (void) clipboardRead: (sqInt) count into: (char *)byteArrayIndex  startingAt: (sqInt) startIndex {
	if (clipboard){
		memcpy((char *)byteArrayIndex + startIndex, clipboard, count);  //use memcpy versus strlcpy, targets is not null terminated. 
    }
}

- (void) clipboardWrite: (sqInt) count from: (char *)byteArrayIndex  startingAt:  (sqInt) startIndex {
	NSPasteboard      *pboard= [NSPasteboard generalPasteboard];
	NSString * string = AUTORELEASEOBJ([[NSString alloc] initWithBytes: byteArrayIndex length:(NSUInteger)count encoding: NSUTF8StringEncoding]);
	[pboard declareTypes: @[NSStringPboardType] owner: nil];
	[pboard setString: string forType: NSStringPboardType];
}

@end
