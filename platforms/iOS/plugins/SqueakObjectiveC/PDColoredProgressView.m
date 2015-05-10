//
//  PDColoredProgressView.m
//  PDColoredProgressViewDemo
//
//  Created by Pascal Widdershoven on 03-01-09.
//  Copyright 2009 P-development. All rights reserved.
//
//	This software is provided 'as-is', without any express or implied 
//	warranty. In no event will the authors be held liable for any damages 
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose, 
//	including commercial applications, and to alter it and redistribute it 
//	freely, subject to the following restrictions:
//
//     1. The origin of this software must not be misrepresented; you must 
//        not claim that you wrote the original software. If you use this 
//        software in a product, an acknowledgment in the product 
//        documentation (and/or about box) would be appreciated but is not 
//        required.
//
//     2. Altered source versions must be plainly marked as such, and must
//        not be misrepresented as being the original software.
//
//     3. This notice may not be removed or altered from any source 
//        distribution.
//    

#import "PDColoredProgressView.h"
#import "drawing.m"


@implementation PDColoredProgressView

- (void)drawRect:(CGRect)rect {
	if([self progressViewStyle] == UIProgressViewStyleDefault)
	{
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		
		//draw first white layer
		addRoundedRectToPath(ctx, rect, 4, 4);
		CGContextClip(ctx);
		
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
		CGContextFillRect(ctx, rect);
		
		//draw lower gray line
		CGContextSetRGBStrokeColor(ctx, 178.0/255.0, 178.0/255.0, 178.0/255.0, 0.9);
		CGContextSetLineWidth(ctx, 2);
		CGContextMoveToPoint(ctx, 2.2, rect.size.height);
		CGContextAddLineToPoint(ctx, rect.size.width - 2.2, rect.size.height);
		CGContextStrokePath(ctx);
		
		//fill upperhalf with light grey
		CGRect upperhalf = rect;
		upperhalf.size.height /= 1.75;
		upperhalf.origin.y = 0;
		
		CGContextSetRGBFillColor(ctx, 202.0/255.0, 202.0/255.0, 202.0/255.0, 0.9);
		CGContextFillRect(ctx, upperhalf);
		
		//fill a part of the upper half with a somewhat darker grey
		CGRect upperhalfTop = upperhalf;
		upperhalfTop.size.height /= 2.7;
		CGContextSetRGBFillColor(ctx, 163.0/255.0, 163.0/255.0, 163.0/255.0, 0.8);
		CGContextFillRect(ctx, upperhalfTop);
		
		//fill the progress part with our tintcolor
		if(_tintColor == nil)
			_tintColor = [[UIColor alloc]initWithRed: 43.0/255.0 green: 134.0/255.0 blue: 225.0/255.0 alpha: 1];
		
		CGRect progressRect = rect;
		progressRect.size.width *= [self progress];
		
		addRoundedRectToPath(ctx, progressRect, 4, 4);
		CGContextClip(ctx);
		
		CGContextSetFillColorWithColor(ctx, [_tintColor CGColor]);
		CGContextFillRect(ctx, progressRect);
		
		progressRect.size.width -= 1.25;
		progressRect.origin.x += 0.625;
		progressRect.size.height -= 1.25;
		progressRect.origin.y += 0.625;
		
		addRoundedRectToPath(ctx, progressRect, 4, 4);
		CGContextClip(ctx);
		CGContextSetLineWidth(ctx, 1);
		CGContextSetRGBStrokeColor(ctx, 20.0/255.0, 20.0/255.0, 20.0/255.0, 0.6);
		CGContextStrokeRect(ctx, progressRect);
		
		//draw white linear gradient over upperhalf
		CGFloat colors[8] = {
			1, 1, 1, 0.45,
			1, 1, 1, 0.75
		};
		
		fillRectWithLinearGradient(ctx, upperhalf, colors, 2, nil);
	}
	else
	{
		[super drawRect: rect];
	}
}

- (void) setTintColor: (UIColor *) aColor {
	_tintColor = aColor;
}




@end
