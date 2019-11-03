
//  nsPoolManagement.m
//  CoreVM
//
//  Created by Brad Fowlow on 10/15/09.
//  Copyright (c) 2013 3D Immersive Collaboration Consulting, LLC.

#import "interp.h"
#import "sqMemoryAccess.h" /* for sqInt ?!?!? */

#import "nsPoolManagement.h"
#import <Cocoa/Cocoa.h>

extern sqInt inIOProcessEvents;

#if COGMTVM
static pthread_key_t nsPoolIndex = 0;

// We have one autorelease pool per thread.
// It is cycled for autorelease in ioProcessEevents to allow objective-c memory
// recovery in all the normally-threaded plugin activity.

void
sqCycleMainAutoreleasePool (void) 
{
	NSAutoreleasePool *nsPool;

	/* Only safe to drain the pool at the outermost level. */
	if (inIOProcessEvents > 1) {
		assert(nsPoolIndex);
		assert(pthread_getspecific(nsPoolIndex));
		return;
	}
	if (!nsPoolIndex) {
		int err = pthread_key_create(&nsPoolIndex,0);
		if (err)
			error("pthread_key_create");
	}
	if ((nsPool = (NSAutoreleasePool *)pthread_getspecific(nsPoolIndex)))
		[ nsPool drain ];
	nsPool = [[NSAutoreleasePool alloc] init];
	pthread_setspecific(nsPoolIndex,nsPool);
}
#else /* COGMTVM */
static NSAutoreleasePool * gNSPool = nil;

// We have one autorelease pool to rule them all.
// It is cycled for autorelease in the main-thread ioProcessEvents of the VM,
// to allow objective-c recovery in all the normally-threaded plugin activity.

void
sqCycleMainAutoreleasePool (void) 
{
	/* Only safe to drain the pool at the outermost level. */
	if (inIOProcessEvents > 1) {
		assert(gNSPool);
		return;
	}
	if (gNSPool)
		[ gNSPool drain ];
	gNSPool = [[NSAutoreleasePool alloc] init];
}
#endif /* COGMTVM */
