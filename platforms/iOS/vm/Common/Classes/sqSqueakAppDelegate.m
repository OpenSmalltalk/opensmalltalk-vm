//
//  sqSqueakAppDelegate.m
//  
//
//  Created by John M McIntosh on 6/14/08.
//
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
#import "sqMacHostWindow.h"

@implementation sqSqueakAppDelegate
@synthesize squeakApplication,squeakThread;

- (void)dealloc {
    RELEASEOBJ(squeakApplication);
    SUPERDEALLOC
}

- (void) makeMainWindow {
	
	/*Beware creating a main window must be done on main thread it will not work from this interpreter squeak thread */
	
	sqInt width,height;
	windowDescriptorBlock *windowBlock;
	
	NSObject * createdWindow = [self createPossibleWindow];
	
	extern sqInt getSavedWindowSize(void); //This is VM Callback
	extern sqInt setSavedWindowSize(sqInt value); //This is VM Callback
	
	/* get old window size */
	width  = ((unsigned) getSavedWindowSize()) >> 16;
	height = getSavedWindowSize() & 0xFFFF;
	windowBlock = AddWindowBlock();
	windowBlock->handle =   (__bridge void*) createdWindow;
	windowBlock->context = nil;
	windowBlock->updateArea = CGRectZero;
	width  = (usqInt) ioScreenSize() >> 16;
	height = ioScreenSize() & 0xFFFF;
	
	setSavedWindowSize( (width << 16) |(height & 0xFFFF));
	windowBlock->width = width;
	windowBlock->height = height; 	
	extern sqInt getFullScreenFlag(void);
	ioSetFullScreen(getFullScreenFlag());

}

- (sqSqueakMainApplication *) makeApplicationInstance {
	return nil;
}

- (NSTimeInterval) squeakUIFlushPrimaryDeferNMilliseconds {
	return 0.0333f;
}

- (void) makeMainWindowOnMainThread {};

- (id) createPossibleWindow { return NULL;};

- (void) workerThreadStart {
	// Run the squeak process in a worker thread
	squeakThread = [[NSThread alloc] initWithTarget: self.squeakApplication
												 selector: @selector(runSqueak)
												   object:nil];
#if COGVM
	[squeakThread setStackSize: [squeakThread stackSize]*4];
#endif
	
	[squeakThread start];
}

- (void) singleThreadStart {
	/* This the carbon logic model 
	 described by http://developer.apple.com/qa/qa2001/qa1061.html */
	
	[[NSRunLoop mainRunLoop] performSelector: @selector(runSqueak) 
									  target: self.squeakApplication
									argument: nil 
									   order: 1 
									   modes: @[NSDefaultRunLoopMode]];		
}



@end
