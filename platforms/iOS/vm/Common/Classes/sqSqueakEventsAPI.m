//
//  sqSqueakEventsAPI.m
//  
//
//  Created by John M McIntosh on 6/14/08.
//
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
#import "sqSqueakAppDelegate.h"
#import "sqSqueakEventsAPI.h"
#import "sqSqueakMainApplication+events.h"
#import "sqSqueakNullScreenAndWindow.h"
#import "sqaio.h"

# import <OpenGL/gl.h>
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
# import <OpenGL/OpenGL.h>
#else
# import <OpenGL/Opengl.h>
#endif

extern sqSqueakAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;
extern BOOL gQuitNowRightNow;
extern sqSqueakNullScreenAndWindow *getMainWindowDelegate();

void vmIOProcessEvents(void) {
	//API Documented

    if ([[NSThread currentThread] isCancelled]) {
        gQuitNowRightNow = YES;
        ioExit();  //This might not return, might call exittoshell
    }

	if ([getMainWindowDelegate() forceUpdateFlush]) {
		[getMainWindowDelegate() ioForceDisplayUpdate];
	}

	/* THIS SHOULD BE COMMENTED TO EXPLAIN WHAT ARE THE TWO CONTEXTS IN WHICH
	 * THIS IS INVOKED.  THIS SEEMS SUPER DANGEROUS BECAUSE WHETHER THERE IS
	 * A PRIMITIVE INDEX OR NOT DEPENDS ON WHETHER THIS IS INVOKED WITHIN A
	 * PRIMITIVE OR NOT.  IF INVOKED IN PARALLEL TO THE VM IT IS ARBITRARY.
	 * SO PLEASE, WHOEVER UNDERATANDS WHAT'S GOING ON, REPLACE MY CAPS WITH
	 * A COGENT EXPLANATION ASAP.
	 */
	if (interpreterProxy->methodPrimitiveIndex() == 0) {
		[gDelegateApp.squeakApplication pumpRunLoopEventSendAndSignal:YES];
    } else {
		[gDelegateApp.squeakApplication pumpRunLoop];
	}

	if (gQuitNowRightNow) {
		ioExit();  //This might not return, might call exittoshell
	}
}

void (*ioProcessEventsHandler) (void) = vmIOProcessEvents;

extern void setIoProcessEventsHandler(void * handler) {
    ioProcessEventsHandler = (void(*)()) handler;
}

sqInt ioProcessEvents(void) {
    aioPoll(0);

	// We need to restore the opengl context to whatever the image was
	// already using. This is required by SDL2 in Pharo.
	NSOpenGLContext *oldContext = [NSOpenGLContext currentContext];

	// We need to run the vmIOProcessEvents even if we are using SDL2,
	// otherwise we end with some double free errors in an autorelease pool.
	vmIOProcessEvents();
    if(ioProcessEventsHandler && ioProcessEventsHandler != vmIOProcessEvents)
        ioProcessEventsHandler();

	NSOpenGLContext *newContext = [NSOpenGLContext currentContext];
	if(oldContext != newContext) {
		if (oldContext != nil) {
			[oldContext makeCurrentContext];
		} else {
			[NSOpenGLContext clearCurrentContext];
		}
	}

    return 0;
}

sqInt ioSetInputSemaphore(sqInt semaIndex) {
	//API Documented
	
	gDelegateApp.squeakApplication.inputSemaphoreIndex = semaIndex;
	return 0;
}

sqInt ioGetNextEvent( sqInputEvent *evt) {
	//API Documented
	[gDelegateApp.squeakApplication ioGetNextEvent: evt];
/*	if (evt->type != 0) {
		NSLog(@"evt.type %i keyboard pc %i cc %i uc %i m %i",evt->type,((sqKeyboardEvent *)evt)->pressCode,((sqKeyboardEvent *) evt)->charCode,((sqKeyboardEvent *) evt)->utf32Code,((sqKeyboardEvent *) evt)->modifiers);
	} */
	return 0;
}

#if NewspeakVM
/* For now this is only here to make the linker happy;
   the function really does something interesting only on Windows.
 */
void
ioDrainEventQueue() {}
#endif /* NewspeakVM */
