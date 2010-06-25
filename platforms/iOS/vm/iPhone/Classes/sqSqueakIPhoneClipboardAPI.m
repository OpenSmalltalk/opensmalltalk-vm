//
//  sqSqueakIPhoneClipboardAPI.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 01-02-10.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import "sqSqueakIPhoneClipboardAPI.h"

#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "sqSqueakIPhoneApplication+clipboard.h"

extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;

/* Clipboard (cut/copy/paste). */
sqInt clipboardSize(void) {
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	sqInt value = [(sqSqueakIPhoneApplication*)(SqueakNoOGLIPhoneAppDelegate *)gDelegateApp.squeakApplication clipboardSize];
	[pool drain];
	return value;
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex){
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	[(sqSqueakIPhoneApplication*)(SqueakNoOGLIPhoneAppDelegate *)gDelegateApp.squeakApplication clipboardRead: count into: (char *) pointerForOop((usqInt)byteArrayIndex)  startingAt: startIndex];
	[pool drain];
	return 0;
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex){
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	[(sqSqueakIPhoneApplication*)(SqueakNoOGLIPhoneAppDelegate *)gDelegateApp.squeakApplication clipboardWrite: count from: (char *)pointerForOop((usqInt)byteArrayIndex)  startingAt: startIndex];
	[pool drain];
	return 0;
}
