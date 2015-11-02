
/*

File: Queue.m

Abstract: Implementation file for the Queue class. This class makes use
of the NSMutableArray to define and maintain a standard queue data
structure to hold Cocoa objects. Objects can be added & removed from the
queue as desired and their order at insertion time is maintained.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

/* Arc version */

#import "Queue.h"


@implementation Queue

// Initialize a empty mutable array for queue items
// which we can fill
- (instancetype) init
{
	self = [super init];
	{
		mItemArray = [[NSMutableArray alloc] initWithCapacity :10];
	}
	
	return self;
}

- (void) dealloc
{
    RELEASEOBJ(mItemArray);
    SUPERDEALLOC
}

// Returns (and removes) the oldest item in the queue
-(id)returnAndRemoveOldest
{
	id anObject = nil;
	@synchronized(self) {	

	anObject = [mItemArray lastObject];
	if (anObject)
	{
        RETAINOBJ(anObject);
		[mItemArray removeLastObject];		
	}
		}
	return anObject;	
}

// Returns the oldest item in the queue or nil
-(id)returnOldest
{
	id anObject = nil;
	@synchronized(self) {		
	
	anObject = [mItemArray lastObject];
	}
	return anObject;	
}


// Adds the specified item to the queue
-(void)addItem:(id)anItem
{
	@synchronized(self) {	
		[mItemArray insertObject:anItem atIndex:0];
	}
}

-(NSUInteger) pendingElements {
	return [mItemArray count];
}

- (NSArray *) elements {
	return mItemArray;
}


@end
