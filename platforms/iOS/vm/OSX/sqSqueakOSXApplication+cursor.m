//
//  sqSqueakOSXApplication+cursor.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-14.
//  Some code sqUnixQuartz.m -- display via native windows on Mac OS X	-*- ObjC -*-
//  Author: Ian Piumarta <ian.piumarta@squeakland.org>
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
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
#import "sqSqueakOSXApplication.h"
#import "sqSqueakOSXApplication+cursor.h"
extern BOOL gSqueakHeadless;
extern BOOL browserActiveAndDrawingContextOk(void);
BOOL browserActiveAndDrawingContextOkAndInFullScreenMode(void);


@implementation sqSqueakOSXApplication (cursor)

- (void) setCursor: (sqInt)  cursorBitsIndex withMask: (sqInt) cursorMaskIndex
		   offsetX: (sqInt) offsetX offsetY: (sqInt) offsetY {
	/* Set the 16x16 cursor bitmap. If cursorMaskIndex is nil, then make the mask the same as
	 the cursor bitmap. If not, then mask and cursor bits combined determine how cursor is
	 displayed:
	 mask	cursor	effect
	 0		  0		transparent (underlying pixel shows through)
	 1		  1		opaque black
	 1		  0		opaque white
	 0		  1		invert the underlying pixel
	 */

	if (gSqueakHeadless && !browserActiveAndDrawingContextOk()) 
		return;
	@autoreleasepool {
	 
	NSBitmapImageRep *bitmap= AUTORELEASEOBJ([[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:  NULL pixelsWide: 16 pixelsHigh: 16
			 bitsPerSample: 1 samplesPerPixel: 2
			 hasAlpha: YES isPlanar: YES
			 colorSpaceName: NSCalibratedBlackColorSpace
			 bytesPerRow: 2
			 bitsPerPixel: 0]);

    unsigned char*      planes[5];
	[bitmap getBitmapDataPlanes:planes];

	unsigned char*      data;
    unsigned char*      mask;
	NSInteger i;
	data=planes[0];
	mask=planes[1];

	for (i= 0; i < 16; ++i) {
		unsigned int word= ((unsigned int *)pointerForOop(cursorBitsIndex))[i];
		data[i*2 + 0]= (word >> 24) & 0xFF;
		data[i*2 + 1]= (word >> 16) & 0xFF;
		
		if (cursorMaskIndex)
			word= ((unsigned int *)pointerForOop(cursorMaskIndex))[i];
		else 
			word = 0xFFFFFFFF;
		
		mask[i*2 + 0]= (word >> 24) & 0xFF;
		mask[i*2 + 1]= (word >> 16) & 0xFF;
	}

	NSImage *image = AUTORELEASEOBJ([[NSImage alloc] init]);
	[image addRepresentation: bitmap];
	
	
	NSPoint hotSpot= { -offsetX, -offsetY };
	self.squeakCursor = AUTORELEASEOBJ([[NSCursor alloc] initWithImage: image hotSpot: hotSpot]);

/*	if (browserActiveAndDrawingContextOkAndNOTInFullScreenMode())
		browserSetCursor(&macCursor);
*/
#warning what about browser
	
	
	if (!gSqueakHeadless || browserActiveAndDrawingContextOkAndInFullScreenMode()) {
            if ([NSThread isMainThread]) {
                [self.squeakCursor set];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.squeakCursor set];
                });
            }
	}
	}
}

- (sqInt) ioSetCursorARGB: (sqInt) cursorBitsIndex extentX: (sqInt) extentX extentY: (sqInt) extentY
				  offsetX: (sqInt) offsetX offsetY: (sqInt) offsetY {
	if (gSqueakHeadless) 
		return 0;
	if (browserActiveAndDrawingContextOk() && !browserActiveAndDrawingContextOkAndInFullScreenMode()) 
		return 0;
	
	@autoreleasepool {
	
	NSBitmapImageRep *bitmap= AUTORELEASEOBJ([[NSBitmapImageRep alloc]
								initWithBitmapDataPlanes: NULL pixelsWide: extentX pixelsHigh: extentY
								bitsPerSample: 8 samplesPerPixel: 4
								hasAlpha: YES isPlanar: NO
								colorSpaceName: NSCalibratedRGBColorSpace
								bytesPerRow: extentX * 4
								bitsPerPixel: 0]);
	unsigned int *planes[5];
	[bitmap getBitmapDataPlanes: (unsigned char **) planes];
	unsigned int *src= (unsigned int*) pointerForOop(cursorBitsIndex);
	unsigned int *dst= planes[0];
	sqInt i;
	for (i= 0; i < extentX * extentY; ++i, ++dst, ++src) {
#if VMENDIANNESS
		*dst=  ((*src & 0xFF000000) >> 24) | ((*src & 0x00FFFFFF) << 8) ; // ARGB to RGBA
#else
		*dst= (*src & 0xFF00FF00) | ((*src & 0x000000FF) << 16) | ((*src & 0x00FF0000) >> 16); // BGRA to RGBA
#endif
	}
	NSImage  *image= AUTORELEASEOBJ([[NSImage alloc] init]);
	[image addRepresentation: bitmap];
	NSPoint hotSpot= { -offsetX, -offsetY };
	self.squeakCursor = AUTORELEASEOBJ([[NSCursor alloc] initWithImage: image hotSpot: hotSpot]);
    if ([NSThread isMainThread]) {
            [self.squeakCursor set];
    } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.squeakCursor set];
            });
    }
    }
	return 1;
}
@end
