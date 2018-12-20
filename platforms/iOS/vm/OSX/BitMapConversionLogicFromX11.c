/*
 *  BitMapConversionLogicFromX11.c
 *  SqueakPureObjc
 *
 *  Created by John M McIntosh on 09-12-08.
 *  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *	This code is comes from the sqUnixX11.c logic to convert Squeak Forms to 32bit image data
 *
 */
/* sqUnixX11.c -- support for display via the X Window System.
 * 
 *   Copyright (C) 1996-2008 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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
 */

#include "BitMapConversionLogicFromX11.h"

//#define DEBUG
#include <stdio.h>

void copyImage16To32(short *fromImageData, int *toImageData, int width, int height,
					 int affectedL, int affectedT, int affectedR, int affectedB)
{
	long scanLine16, firstWord16, lastWord16;
	long scanLine32, firstWord32;
	int line;
	register unsigned int col;

#if defined(DEBUG)
	fprintf(stderr, "copyImg16to32 %p -> %p (%d %d) %d %d %d %d\n",
			fromImageData, toImageData, width, height,
			affectedT, affectedL, affectedB, affectedR);
#endif
	
#define map16To32(w) (col= (w), \
(((col >> 10) & 0x1f) << 3) | \
(((col >> 5)  & 0x1f) << 11) | \
((col & 0x1f) << 19))
	
	scanLine16= bytesPerLine(width, 16);
	firstWord16= scanLine16*affectedT + bytesPerLineRD(affectedL, 16);
	lastWord16= scanLine16*affectedT + bytesPerLine(affectedR, 16);
	scanLine32= bytesPerLine(width, 32);
	firstWord32= 0;
	
	for (line= affectedT; line < affectedB; line++)
    {
		register unsigned short *from= (unsigned short *)((long)fromImageData+firstWord16);
		register unsigned short *limit= (unsigned short *)((long)fromImageData+lastWord16);
		register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
		while (from < limit)
		{
#	 if defined(WORDS_BIGENDIAN)
			to[0]= map16To32(from[0]);
			to[1]= map16To32(from[1]);
#	 else
			to[0]= map16To32(from[1]);
			to[1]= map16To32(from[0]);
#	 endif
			from+= 2;
			to+= 2;
		}
		firstWord16+= scanLine16;
		lastWord16+= scanLine16;
		firstWord32+= scanLine32;
    }
#undef map16To32
}

void copyImage8To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors)
{
	long scanLine8, firstWord8, lastWord8;
	long scanLine32, firstWord32;
	int line;
	
	scanLine8= bytesPerLine(width, 8);
	firstWord8= scanLine8*affectedT + bytesPerLineRD(affectedL, 8);
	lastWord8= scanLine8*affectedT + bytesPerLine(affectedR, 8);
	scanLine32= bytesPerLine(width, 32);
	firstWord32= 0;
	
	for (line= affectedT; line < affectedB; line++)
    {
		register unsigned char *from= (unsigned char *)((long)fromImageData+firstWord8);
		register unsigned char *limit= (unsigned char *)((long)fromImageData+lastWord8);
		register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
		while (from < limit)
		{
#	 if defined(WORDS_BIGENDIAN)
			to[0]= stColors[from[0]];
			to[1]= stColors[from[1]];
			to[2]= stColors[from[2]];
			to[3]= stColors[from[3]];
#	 else
			to[0]= stColors[from[3]];
			to[1]= stColors[from[2]];
			to[2]= stColors[from[1]];
			to[3]= stColors[from[0]];
#	 endif
			from+= 4;
			to+= 4;
		}
		firstWord8+= scanLine8;
		lastWord8+= scanLine8;
		firstWord32+= scanLine32;
    }
}

void copyImage4To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors)
{
	int scanLine4, firstWord4, firstShift4;
	long scanLine32, firstWord32, lastWord32;
	long line;
	
	scanLine4= bytesPerLine(width, 4);
	firstWord4= scanLine4*affectedT + bytesPerLineRD(affectedL, 4);
	firstShift4= 28 - ((affectedL & 7) * 4);
	
	scanLine32= bytesPerLine(width, 32);
	firstWord32= 0;
	lastWord32= bytesPerLineRD(affectedR, 32);
	
	for (line= affectedT; line < affectedB; line++)
    {
		register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord4);
		register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
		register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
		register int shift= firstShift4;
		while (to < limit)
		{
			*to= stColors[(*from >> shift) & 15];
			to++;
			shift-= 4;
			if (shift < 0)
			{
				shift= 28;
				from++;
			}
		}
		firstWord4+= scanLine4;
		firstWord32+= scanLine32;
		lastWord32+= scanLine32;
    }
}

void copyImage2To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors)
{
	long scanLine2, firstWord2, firstShift2;
	long scanLine32, firstWord32, lastWord32;
	int line;
	
	scanLine2= bytesPerLine(width, 2);
	firstWord2= scanLine2*affectedT + bytesPerLineRD(affectedL, 2);
	firstShift2= 30 - ((affectedL & 15) * 2);
	
	scanLine32= bytesPerLine(width, 32);
	firstWord32= 0;
	lastWord32= bytesPerLineRD(affectedR, 32);
	
	for (line= affectedT; line < affectedB; line++)
    {
		register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord2);
		register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
		register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
		register int shift= firstShift2;
		while (to < limit)
		{
			*to= stColors[(*from >> shift) & 3];
			to++;
			shift-= 2;
			if (shift < 0)
			{
				shift= 30;
				from++;
			}
		}
		firstWord2+= scanLine2;
		firstWord32+= scanLine32;
		lastWord32+= scanLine32;
    }
}

void copyImage1To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors)
{
	long scanLine1, firstWord1, firstShift1;
	long scanLine32, firstWord32, lastWord32;
	int line;
	
	scanLine1= bytesPerLine(width, 1);
	firstWord1= scanLine1*affectedT + bytesPerLineRD(affectedL, 1);
	firstShift1= 31 - (affectedL & 31);
	
	scanLine32= bytesPerLine(width, 32);
	firstWord32= 0;
	lastWord32= bytesPerLine(affectedR, 32);
	
	for (line= affectedT; line < affectedB; line++)
    {
		register unsigned int *from= (unsigned int *)((long)fromImageData+firstWord1);
		register unsigned int *to= (unsigned int *)((long)toImageData+firstWord32);
		register unsigned int *limit= (unsigned int *)((long)toImageData+lastWord32);
		register int shift= firstShift1;
		while (to < limit)
		{
			*to= stColors[(*from >> shift) & 1];
			to++;
			shift--;
			if (shift < 0)
			{
				shift= 31;
				from++;
			}
		}
		firstWord1+= scanLine1;
		firstWord32+= scanLine32;
		lastWord32+= scanLine32;
    }
}
