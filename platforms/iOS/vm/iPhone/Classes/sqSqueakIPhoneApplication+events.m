/*
 *  sqSqueakIPhoneApplication+events.m
 *  SqueakNoOGLIPhone
 *
 *  Created by John M McIntosh on 5/16/08.
 *

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

#import "sq.h"
#import "sqSqueakMainApplication+events.h"
#import "sqSqueakIPhoneApplication+events.h"
#import "sqDummyaio.h"
#import "sqMacHostWindow.h"
#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "Queue.h"
#define MillisecondClockMask 536870911

extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;
extern struct	VirtualMachine* interpreterProxy;
sqInt	windowActive=1;


@implementation sqSqueakIPhoneApplication (events) 

- (void ) processAsOldEventOrComplexEvent: (id) event placeIn: (sqInputEvent *) evt {
	if ([event isKindOfClass: [NSData class]]) {
		[super processAsOldEventOrComplexEvent: event placeIn: evt];
		return;
	}
	
	if ([event isKindOfClass: [NSArray class]]) {
		if ([event[0] intValue] == 1) {
			[self buildTouchEventComplexObject: event[2] forType:  event[1] placeIn: (sqComplexEvent *) evt];
			return;
		}
		if ([event[0] intValue] == 2) { // acceleration dataa
			[self buildAccelerationEventComplexObject: event[1] placeIn: (sqComplexEvent *) evt];
			return;
		}
		if ([event[0] intValue] == 3) { // location data error
			[self buildLocationEventComplexObject: event placeIn: (sqComplexEvent *) evt];
			return;
		}
		if ([event[0] intValue] == 4) { // location data 
			[self buildLocationEventComplexObject: event placeIn: (sqComplexEvent *) evt];
			return;
		}
		if ([event[0] intValue] == 5) { // memory warning  
			[self buildApplicationEventComplexObject: event placeIn: (sqComplexEvent *) evt];
			return;
		}
		if ([event[0] intValue] == 6) { // termination warning 
			[self buildApplicationEventComplexObject: event placeIn: (sqComplexEvent *) evt];
			return;
		}
		
		if ([event[0] intValue] == 7) { // keyboard 
			[(NSData *)event[1] getBytes: evt length: sizeof(sqInputEvent)];
			return;
		}

		if ([event[0] intValue] == 8) { // window 
			[(NSData *)event[1] getBytes: evt length: sizeof(sqWindowEvent)];
			return;
		}
	}
}

- (void) recordTouchEvent:(NSSet *) touches type: (UITouchPhase) phase {
    NSMutableArray* data = [NSMutableArray arrayWithCapacity: 3];
	
	[data addObject: @1];
	[data addObject: @((signed) phase)];
	[data addObject: touches];
	[eventQueue addItem: data];
	interpreterProxy->signalSemaphoreWithIndex(gDelegateApp.squeakApplication.inputSemaphoreIndex);
}

- (CGPoint)translateToSmalltalk:(CGPoint)position {
    /*
     * Moves current point to Smalltalk coordinates (Fourth quadrant) 
     */

    //CGSize size = [[UIScreen mainScreen] bounds].size;
    //CGPoint newPosition = CGPointMake(position.x, size.height - position.y);
    //NSLog(@"POS OLD: %f,%f NEW: %f,%f", position.x, position.y, newPosition.x, newPosition.y);
    //NSLog(@"POS OLD: %f,%f", position.x, position.y);
    
    return position;
}

- (void) buildTouchEventComplexObject:(NSSet *) touches forType: (NSNumber *) aType placeIn: (sqComplexEvent *) evt {
	
	sqInt count = [touches count];
    sqInt arrayIndex=0;
    sqInt squeakMSTimeNow = ioMSecs();
    sqInt action;
	UITouch *touch;
	sqInt previousLocationInViewX;
    sqInt previousLocationInViewY;
    sqInt locationInViewX;
    sqInt locationInViewY;
    sqInt squeakMSTime;
    sqInt view;
    sqInt window;
    sqInt tapCount;
    sqInt phase;
    sqInt timeStamp;
    sqInt storageArea;
    sqInt containerArray;
    sqInt touchId;
    
	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), count));
    for (touch in touches) {
        CGPoint location = [touch locationInView:[gDelegateApp mainView]];
        CGPoint previousLocation = [touch previousLocationInView:[gDelegateApp mainView]];
        
        interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 11));
        interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(squeakMSTimeNow));
        interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf([touch timestamp]));
        interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf((signed)[touch phase]));
        interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf((signed)[touch tapCount]));
        interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor((sqLong)[touch window]));
        interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor((sqLong)[touch view]));
        interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(location.x));
        interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(location.y));
        interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(previousLocation.x));
        interpreterProxy->pushRemappableOop(interpreterProxy->floatObjectOf(previousLocation.y));
        interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor((sqLong)touch));
        touchId = interpreterProxy->popRemappableOop();
        previousLocationInViewY = interpreterProxy->popRemappableOop();
        previousLocationInViewX = interpreterProxy->popRemappableOop();
        locationInViewY = interpreterProxy->popRemappableOop();
        locationInViewX = interpreterProxy->popRemappableOop();
        view = interpreterProxy->popRemappableOop();
        window = interpreterProxy->popRemappableOop();
        tapCount = interpreterProxy->popRemappableOop();
        phase = interpreterProxy->popRemappableOop();
        timeStamp = interpreterProxy->popRemappableOop();
        squeakMSTime = interpreterProxy->popRemappableOop();
        storageArea = interpreterProxy->popRemappableOop();
        containerArray = interpreterProxy->popRemappableOop();
        interpreterProxy->storePointerofObjectwithValue(0, storageArea, squeakMSTime);
        interpreterProxy->storePointerofObjectwithValue(1, storageArea, timeStamp);
        interpreterProxy->storePointerofObjectwithValue(2, storageArea, phase);
        interpreterProxy->storePointerofObjectwithValue(3, storageArea, tapCount);
        interpreterProxy->storePointerofObjectwithValue(4, storageArea, window);
        interpreterProxy->storePointerofObjectwithValue(5, storageArea, view);
        interpreterProxy->storePointerofObjectwithValue(6, storageArea, locationInViewX);
        interpreterProxy->storePointerofObjectwithValue(7, storageArea, locationInViewY);
        interpreterProxy->storePointerofObjectwithValue(8, storageArea, previousLocationInViewX);
        interpreterProxy->storePointerofObjectwithValue(9, storageArea, previousLocationInViewY);
        interpreterProxy->storePointerofObjectwithValue(10, storageArea, touchId);
        interpreterProxy->storePointerofObjectwithValue(arrayIndex++, containerArray, storageArea);
        interpreterProxy->pushRemappableOop(containerArray);
    }
	
	evt->type = EventTypeComplex;  //This is read as an integer and converted to an oop by interp.c
	
	evt->timeStamp = interpreterProxy->integerObjectOf(squeakMSTimeNow);
	switch ([aType integerValue]) {
		case UITouchPhaseBegan:
			action = ComplexEventTypeTouchsDown;
			break;
		case UITouchPhaseEnded:
			action = ComplexEventTypeTouchsUp;
			break;
		case UITouchPhaseMoved:
			action = ComplexEventTypeTouchsMoved;
			break;
		case UITouchPhaseStationary:
			action = ComplexEventTypeTouchsStationary;
			break;
		case UITouchPhaseCancelled:
			action = ComplexEventTypeTouchsCancelled;
			break;
		default:
			action = 0;
			break;
	}
	evt->action = interpreterProxy->integerObjectOf(action);
	containerArray = interpreterProxy->popRemappableOop();	
	evt->objectPointer = containerArray;
	evt->unused1 =interpreterProxy->integerObjectOf(0);
	evt->unused2 = interpreterProxy->integerObjectOf(0);
	evt->unused3 =interpreterProxy->integerObjectOf(0);
	evt->windowIndex = interpreterProxy->integerObjectOf(windowActive);
}

- (void) buildAccelerationEventComplexObject: (UIAcceleration *) acceleration placeIn: (sqComplexEvent *) evt {
	sqInt squeakMSTimeNow = ioMSecs();
	
	interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor(((usqInt) acceleration)));
	
	evt->type = EventTypeComplex;  //This is read as an integer and converted to an oop by interp.c
	evt->timeStamp = interpreterProxy->integerObjectOf(squeakMSTimeNow);
	evt->action = interpreterProxy->integerObjectOf(ComplexEventTypeAccelerationData);
	evt->objectPointer = interpreterProxy->popRemappableOop();
	evt->unused1 =interpreterProxy->integerObjectOf(0);
	evt->unused2 = interpreterProxy->integerObjectOf(0);
	evt->unused3 =interpreterProxy->integerObjectOf(0);
	evt->windowIndex = interpreterProxy->integerObjectOf(windowActive);
}

- (void) buildLocationEventComplexObject: (NSMutableArray *) event placeIn: (sqComplexEvent *) evt {
	sqInt squeakMSTimeNow = ioMSecs();

	interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor(((usqInt) event)));

	evt->type = EventTypeComplex;  //This is read as an integer and converted to an oop by interp.c
	evt->timeStamp = interpreterProxy->integerObjectOf(squeakMSTimeNow);
	evt->action = interpreterProxy->integerObjectOf(ComplexEventTypeLocationData);
	evt->objectPointer = interpreterProxy->popRemappableOop();
	evt->unused1 =interpreterProxy->integerObjectOf(0);
	evt->unused2 = interpreterProxy->integerObjectOf(0);
	evt->unused3 =interpreterProxy->integerObjectOf(0);
	evt->windowIndex = interpreterProxy->integerObjectOf(windowActive);
}

- (void) buildApplicationEventComplexObject: (NSMutableArray *) event placeIn: (sqComplexEvent *) evt {
	sqInt squeakMSTimeNow = ioMSecs();

	interpreterProxy->pushRemappableOop(interpreterProxy->positive64BitIntegerFor(((usqInt) event)));

	evt->type = EventTypeComplex;  //This is read as an integer and converted to an oop by interp.c
	evt->timeStamp = interpreterProxy->integerObjectOf(squeakMSTimeNow);
	evt->action = interpreterProxy->integerObjectOf(ComplexEventTypeApplicationData);
	evt->objectPointer = interpreterProxy->popRemappableOop();
	evt->unused1 =interpreterProxy->integerObjectOf(0);
	evt->unused2 = interpreterProxy->integerObjectOf(0);
	evt->unused3 =interpreterProxy->integerObjectOf(0);
	evt->windowIndex = interpreterProxy->integerObjectOf(windowActive);
}

@end
