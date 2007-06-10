/*
 *  NSCursorWrappers.m
 *  SqueakVMUNIXPATHS
 *
 *  Created by John M McIntosh on 4/26/07.
 *  Copyright 2007 Corporate Smalltalk Consulting Ltd All rights reserved.
 *  Licensed under the Squeak-L, and MIT license
 *
 */
 
 
 /* Some parts. 
 * 
 * Author: Ian Piumarta <ian.piumarta@squeakland.org>
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 * 
 * Last edited: 2006-10-18 10:01:37 by piumarta on emilia.local
 */
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

#include "sq.h"
#include "sqMacNSPluginUILogic2.h"

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);
void SetCursorBackToSomething(void);
int amIOSX102X(void);

NSCursor         *cursor= 0;
Boolean			biggerCursorActive=false;
extern Cursor macCursor;

void SetCursorBackToSomething() {
	if (biggerCursorActive) {
		[cursor set];
	}
	else
		SetCursor(&macCursor);
}

sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
extern Boolean gSqueakHeadless;
extern Boolean gSqueakHasCursor;
	
	if (gSqueakHeadless) return 0;
	if (browserActiveAndDrawingContextOk() && !browserActiveAndDrawingContextOkAndInFullScreenMode()) 
		return 0;
	if (amIOSX102X()) 
		return 0;
// ? and what does the browser plugin do? We do not have code to manage big cursors.

      NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init];
      NSBitmapImageRep *bitmap= 0;
      NSImage          *image=  0;

	static BOOL		firstTime	= YES;
	
	if ( firstTime )
	{
		//	Must first call [[[NSWindow alloc] init] release] to get the NSWindow machinery set up so that NSCursor can use a window to cache the cursor image
		[[[NSWindow alloc] init] release];
		firstTime = NO;
	}
	biggerCursorActive = true;
	gSqueakHasCursor = true;

	bitmap= [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes: 0 pixelsWide: extentX pixelsHigh: extentY
		bitsPerSample: 8 samplesPerPixel: 4
		hasAlpha: YES isPlanar: NO
		colorSpaceName: NSCalibratedRGBColorSpace
		bytesPerRow: extentX * 4
		bitsPerPixel: 0];
      {
	unsigned *planes[5];
	[bitmap getBitmapDataPlanes: planes];
	unsigned* src= (unsigned*)cursorBitsIndex;
	unsigned* dst= planes[0];
	int i;
	for (i= 0; i < extentX * extentY; ++i, ++dst, ++src) {
#if VMENDIANNESS
		*dst=  ((*src & 0xFF000000) >> 24) | ((*src & 0x00FFFFFF) << 8) ; // ARGB to RGBA
#else
		*dst= (*src & 0xFF00FF00) | ((*src & 0x000000FF) << 16) | ((*src & 0x00FF0000) >> 16); // BGRA to RGBA
#endif
	}
      }
      image= [[NSImage alloc] init];
      [image addRepresentation: bitmap];
      {
	NSPoint hotSpot= { -offsetX, -offsetY };
	if (cursor) 
		[cursor release];
	cursor= [[NSCursor alloc] initWithImage: image hotSpot: hotSpot];
      }
      [cursor set];
	   // [NSCursor unhide];
      [pool release];

  return 1;
}


// Code below is example stuff 

/*
	File:		NSCursorWrappers.m
 
	Abstract:	Provide Carbon wrapper functions around the Cocoa NSCursor methods we
				use to handle our cursor support.
	
 
	Version:	1.0
 
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under Apple's
 copyrights in this original Apple software (the "Apple Software"), to use,
 reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions of
 the Apple Software.  Neither the name, trademarks, service marks or logos of
 Apple Computer, Inc. may be used to endorse or promote products derived from the
 Apple Software without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or implied,
 are granted by Apple herein, including but not limited to any patent rights that
 may be infringed by your derivative works or by other works in which the Apple
 Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
						GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
 OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
 (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
	Copyright © 2006 Apple Computer, Inc., All Rights Reserved
 */

/* 
#import <Cocoa/Cocoa.h>
#import "NSCursorWrappers.h"

//	From "Cocoa Drawing Guide: Working with Images"
NSImage	*CreateNSImageFromCGImage( CGImageRef image )
{
	NSRect			imageRect		= NSMakeRect(0.0, 0.0, 0.0, 0.0);

	// Get the image dimensions.
	imageRect.size.height = CGImageGetHeight(image);
	imageRect.size.width = CGImageGetWidth(image);

	// Create a new image to receive the Quartz image data.
	NSImage	*newImage = [[NSImage alloc] initWithSize:imageRect.size]; 
	[newImage lockFocus];

	// Get the Quartz context and draw.
	CGContextRef	imageContext = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	CGContextDrawImage( imageContext, *(CGRect*)&imageRect, image );
	[newImage unlockFocus];

	return( newImage );
}

//	C-based style wrapper routines around NSCursor
CursorRef	CreateCocoaCursor( CGImageRef cgImageRef, float hotSpotX, float hotSpotY )
{
	static BOOL		firstTime	= YES;
	
	if ( firstTime )
	{
		//	Must first call [[[NSWindow alloc] init] release] to get the NSWindow machinery set up so that NSCursor can use a window to cache the cursor image
		[[[NSWindow alloc] init] release];
		firstTime = NO;
	}
	
	NSImage		*nsImage	= CreateNSImageFromCGImage( cgImageRef );
	NSCursor	*cursor		= [[NSCursor alloc] initWithImage:nsImage hotSpot:NSMakePoint( hotSpotX, hotSpotY )];
	
	[nsImage release];
	
	return( (CursorRef)cursor );
}

void	ReleaseCocoaCursor( CursorRef cursor )
{
	[(NSCursor *)cursor release];
}

void	SetCocoaCursor( CursorRef cursor )
{
	[(NSCursor *)cursor set];
}

void	HideCocoaCursor()
{
	[NSCursor hide];
}

void	ShowCocoaCursor()
{
	[NSCursor unhide];
}
*/