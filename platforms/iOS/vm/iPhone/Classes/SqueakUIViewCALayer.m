//
//  SqueakUIViewCALayer.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 10-09-09.
//  Copyright 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
/*
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

#import "SqueakUIViewCALayer.h"
#import <QuartzCore/QuartzCore.h>
#import "sq.h"
extern struct	VirtualMachine* interpreterProxy;

static void MyProviderReleaseData (
								   void *info,
								   const void *data,
								   size_t size
								   ) {
}


@implementation SqueakUIViewCALayer

- (void)layoutSubviews {
	CGRect aFrame = self.bounds;
	dividedWidth = aFrame.size.width/4.0;
	dividedHeight = aFrame.size.height/4.0;
	for (int v=0;v<4;v++) {
		for (int h=0;h<4;h++) {
			CALayer *setupLayer = [CALayer layer];
			[setupLayer setOpaque: YES];
			setupLayer.frame = CGRectMake(dividedWidth*h, dividedHeight*v, dividedWidth, dividedHeight);
			if (myLayer[v][h]) {
				[self.layer replaceSublayer: myLayer[v][h] with: setupLayer];
				myLayer[v][h] = setupLayer;
			} else {
				myLayer[v][h] = setupLayer;
				[self.layer addSublayer: setupLayer];
			}
			frameForQuartz[v][h] = CGRectMake(dividedWidth*h,dividedHeight*(3-v), dividedWidth, dividedHeight);
			dirty[v][h] = NO;
		}
	}
}

- (CGImageRef) allocImageFrom: (void *) dispBitsIndex affectedT: (int) affectedT affectedB: (int) affectedB affectedL: (int) affectedL affectedR: (int) affectedR height: (int) height width: (int) width {
	const size_t depth = 32;
	size_t 	pitch = ((((width)*(depth) + 31) >> 5) << 2);
	
	size_t totalSize = pitch * (affectedB-affectedT)-affectedL*4;
	CGDataProviderRef provider =  CGDataProviderCreateWithData (NULL,(void*)dispBitsIndex+ pitch*affectedT + affectedL*4,(size_t) totalSize,MyProviderReleaseData);
	
	CGImageRef image = CGImageCreate((size_t) affectedR-affectedL,(size_t) affectedB-affectedT, (size_t) 8 /* bitsPerComponent */,
									 (size_t) depth /* bitsPerPixel */, 
									 (size_t) pitch, colorspace, 
									 (CGBitmapInfo) kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host , 
									 provider, NULL, (bool) 0, kCGRenderingIntentDefault);
	
	CGDataProviderRelease(provider);
	return image;
}


- (void) drawImageUsingClip: (CGRect) clip {
	for (int v=0;v<4;v++) {
		for (int h=0;h<4;h++) {
			dirty[v][h] = dirty[v][h] || CGRectIntersectsRect(frameForQuartz[v][h],clip);
		}
	}
}


- (void) preDrawThelayers{
    sqInt formObj = interpreterProxy->displayObject();
	sqInt formPtrOop = interpreterProxy->fetchPointerofObject(0, formObj);
	void* dispBitsIndex = interpreterProxy->firstIndexableField(formPtrOop);
	squeakTheDisplayBits = (void*) dispBitsIndex;
}


- (void) drawThelayers {
	[CATransaction begin];
	[CATransaction setValue: @YES forKey: kCATransactionDisableActions];
	for (int v=0;v<4;v++) {
		for (int h=0;h<4;h++) {
			if (dirty[v][h]) {
				CGRect rect = myLayer[v][h].frame;
				CGImageRef x= [self allocImageFrom: squeakTheDisplayBits
										  affectedT: rect.origin.y 
										  affectedB: rect.origin.y+rect.size.height 
										  affectedL: rect.origin.x 
										  affectedR: rect.origin.x+rect.size.width 
											 height: (int) dividedHeight*4 
											  width: (int) dividedWidth*4];
				myLayer[v][h].contents = (id)CFBridgingRelease(x);
				dirty[v][h] = NO;
			}
		}
	}
	[CATransaction commit];
}

@end
