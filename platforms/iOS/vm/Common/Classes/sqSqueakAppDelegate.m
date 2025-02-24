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

extern sqSqueakAppDelegate *gDelegateApp;

void *runBlock(void *arg) {
    @autoreleasepool {
        // Retrieve the block
        void (^block)(void) = (__bridge_transfer void (^)(void))arg;
        // Execute the block
        block();
    }
    return NULL;
}

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

    extern sqInt getFullScreenFlag(void);
    if (!getFullScreenFlag())
        [self placeMainWindowOnLargerScreenGivenWidth: width height: height];

	windowBlock = AddWindowBlock();
	windowBlock->handle =   (__bridge void*) createdWindow;
	windowBlock->context = nil;
	windowBlock->updateArea = CGRectZero;

	setSavedWindowSize((width << 16) | (height & 0xFFFF));
	windowBlock->width = width;
	windowBlock->height = height; 	

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

- (void) placeMainWindowOnLargerScreenWidth: (sqInt) width height: (sqInt) height {};

- (void) workerThreadStart {
    


 /*   pthread_t thread;
    pthread_attr_t attr;
    size_t stackSize = 64 * 1024 * 1024; // Set stack size to 16 MB

    // Initialize thread attributes
    pthread_attr_init(&attr);
    // Set the stack size attribute
    pthread_attr_setstacksize(&attr, stackSize);

    // Define the block to be executed on the thread
    void (^block)(void) = ^{
        [self.squeakApplication runSqueak];
    };

    // Create the thread with the block as an argument
    pthread_create(&thread, &attr, runBlock, (__bridge_retained void *)block);
    if (true)
        return;
    
    /*     // Dispatch a task to the custom serial queue
     dispatch_queue_t mySerialQueue = dispatch_queue_create("org.squeak.interpreter", DISPATCH_QUEUE_SERIAL);
     dispatch_async(mySerialQueue, ^{
         [self.squeakApplication runSqueak];
     });
    if (true)
        return;
    
/*    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.squeakApplication runSqueak];
    });
    if (true)
        return;
*/
    
	// Run the squeak process in a worker thread
	squeakThread = [[NSThread alloc] initWithTarget: self.squeakApplication
												 selector: @selector(runSqueak)
												   object:nil];
#if COGVM
	[squeakThread setStackSize: [squeakThread stackSize]*4];
    squeakThread.name = @"org.squeak.interpreter";
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


- (void)runBlockOnMainThread:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        // If we are already on the main thread, execute the block directly
        block();
    } else {
        // If we are not on the main thread, dispatch the block to the main queue
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end

