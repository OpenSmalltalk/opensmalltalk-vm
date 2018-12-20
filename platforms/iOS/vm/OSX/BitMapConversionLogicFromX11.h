/*
 *  BitMapConversionLogicFromX11.h
 *  SqueakPureObjc
 *
 *  Created by John M McIntosh on 09-12-08.
 *  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *
 *	This code is comes from the sqUnixX11.c logic to convert Squeak Forms to 32bit image data
 */

#define bytesPerLine(width, depth)	((((width)*(depth) + 31) >> 5) << 2)
#define bytesPerLineRD(width, depth)	((((width)*(depth)) >> 5) << 2)


void copyImage16To32(short *fromImageData, int *toImageData, int width, int height,
					 int affectedL, int affectedT, int affectedR, int affectedB);

void copyImage8To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int *colorMap);

void copyImage4To32(int *fromImageData, int *toImageData, int width, int height,
                    int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors);

void copyImage2To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors);

void copyImage1To32(int *fromImageData, int *toImageData, int width, int height,
					int affectedL, int affectedT, int affectedR, int affectedB, unsigned int * stColors);
