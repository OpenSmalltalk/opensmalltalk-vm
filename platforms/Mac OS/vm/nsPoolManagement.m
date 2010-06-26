
//  nsPoolManagement.m
//  CoreVM
//
//  Created by Brad Fowlow on 10/15/09.
//  Copyright 2009 Teleplace, Inc. All rights reserved.

#import "nsPoolManagement.h"
#import <Cocoa/Cocoa.h>

static NSAutoreleasePool * gNSPool = nil;

// We have one autorelease pool to rule them all.
// It is cycled for autorelease in the main-thread main-loop of the VM,
// to allow objective-c recovery in all the normally-threaded plugin activity.

void sqCycleMainAutoreleasePool (void) 
{
	if (gNSPool) { 
		[ gNSPool drain ];
	}
	gNSPool = [[NSAutoreleasePool alloc] init];
}
