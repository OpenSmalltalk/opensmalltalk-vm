//
//  sqSqueakIPhoneApplication+clipboard.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 10-01-02.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import "sqSqueakIPhoneApplication+clipboard.h"

static char * clipboard=NULL;

@implementation sqSqueakIPhoneApplication (clipboard)

/* Cheat, we always call clipboardSize before clipboardRead, so obviously we can do the read when asking for the size */

- (sqInt) clipboardSize {
	UIPasteboard *pboard= [UIPasteboard generalPasteboard];
	if (clipboard) free(clipboard);
	clipboard = NULL;
	NSString *possibleData = pboard.string;
	if (!possibleData) 
		return 0;
	const char *contents= [[possibleData precomposedStringWithCanonicalMapping] UTF8String];
	if (contents != nil)
		clipboard= strdup(contents);
	return clipboard ? (sqInt) strlen(clipboard) : 0;
}

//Evil assumption is that clipboardSize size <= byteArrayIndex size

- (void) clipboardRead: (sqInt) count into: (char *)byteArrayIndex  startingAt: (sqInt) startIndex {
	if (clipboard){
		memcpy((char *)byteArrayIndex + startIndex, clipboard, count);  //use memcpy versus strlcpy, targets is not null terminated. 
    }
}

- (void) clipboardWrite: (sqInt) count from: (char *)byteArrayIndex  startingAt:  (sqInt) startIndex {
	UIPasteboard      *pboard= [UIPasteboard generalPasteboard];
	NSString * string = [[NSString alloc] initWithBytes: byteArrayIndex length:(NSUInteger)count encoding: NSUTF8StringEncoding];
	pboard.string = string;
	[string release];
}

@end
