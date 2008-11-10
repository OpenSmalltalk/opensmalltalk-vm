/* Automatically generated from Squeak on an Array(10 November 2008 3:51:19 pm)
by VMMaker 3.8b6
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif

#include "sqMemoryAccess.h"


/*** Constants ***/
#define AllOnes 4294967295U
#define AlphaIndex 3
#define BBClipHeightIndex 13
#define BBClipWidthIndex 12
#define BBClipXIndex 10
#define BBClipYIndex 11
#define BBColorMapIndex 14
#define BBDestFormIndex 0
#define BBDestXIndex 4
#define BBDestYIndex 5
#define BBHalftoneFormIndex 2
#define BBHeightIndex 7
#define BBRuleIndex 3
#define BBSourceFormIndex 1
#define BBSourceXIndex 8
#define BBSourceYIndex 9
#define BBWarpBase 15
#define BBWidthIndex 6
#define BinaryPoint 14
#define BlueIndex 2
#define ColorMapFixedPart 2
#define ColorMapIndexedPart 4
#define ColorMapNewStyle 8
#define ColorMapPresent 1
#define FixedPt1 16384
#define FormBitsIndex 0
#define FormDepthIndex 3
#define FormHeightIndex 2
#define FormWidthIndex 1
#define GreenIndex 1
#define OpTableSize 42
#define RedIndex 0

/*** Function Prototypes ***/
static sqInt OLDrgbDiffwith(sqInt sourceWord, sqInt destinationWord);
static sqInt OLDtallyIntoMapwith(sqInt sourceWord, sqInt destinationWord);
static sqInt addWordwith(sqInt sourceWord, sqInt destinationWord);
static sqInt affectedBottom(void);
static sqInt affectedLeft(void);
static sqInt affectedRight(void);
static sqInt affectedTop(void);
static sqInt alphaBlendwith(sqInt sourceWord, sqInt destinationWord);
static sqInt alphaBlendConstwith(sqInt sourceWord, sqInt destinationWord);
static sqInt alphaBlendConstwithpaintMode(sqInt sourceWord, sqInt destinationWord, sqInt paintMode);
static sqInt alphaBlendScaledwith(sqInt sourceWord, sqInt destinationWord);
static sqInt alphaPaintConstwith(sqInt sourceWord, sqInt destinationWord);
static sqInt alphaSourceBlendBits16(void);
static sqInt alphaSourceBlendBits32(void);
static sqInt alphaSourceBlendBits8(void);
static sqInt bitAndwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitAndInvertwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertAndwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertAndInvertwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertDestinationwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertOrwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertOrInvertwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertSourcewith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitInvertXorwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitOrwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitOrInvertwith(sqInt sourceWord, sqInt destinationWord);
static sqInt bitXorwith(sqInt sourceWord, sqInt destinationWord);
static sqInt checkSourceOverlap(void);
static sqInt clearWordwith(sqInt source, sqInt destination);
static sqInt clipRange(void);
#pragma export on
EXPORT(sqInt) copyBits(void);
EXPORT(sqInt) copyBitsFromtoat(sqInt startX, sqInt stopX, sqInt yValue);
#pragma export off
static sqInt copyBitsLockedAndClipped(void);
static sqInt copyLoop(void);
static sqInt copyLoopNoSource(void);
static sqInt copyLoopPixMap(void);
static unsigned int * default8To32Table(void);
static sqInt deltaFromtonSteps(sqInt x1, sqInt x2, sqInt n);
static sqInt destMaskAndPointerInit(void);
static sqInt destinationWordwith(sqInt sourceWord, sqInt destinationWord);
static sqInt dither32To16threshold(sqInt srcWord, sqInt ditherValue);
static sqInt drawLoopXY(sqInt xDelta, sqInt yDelta);
static sqInt dstLongAt(sqInt idx);
static sqInt dstLongAtput(sqInt idx, sqInt value);
static sqInt dstLongAtputmask(sqInt idx, sqInt srcValue, sqInt dstMask);
static sqInt expensiveDither32To16threshold(sqInt srcWord, sqInt ditherValue);
static sqInt fetchIntOrFloatofObject(sqInt fieldIndex, sqInt objectPointer);
static sqInt fetchIntOrFloatofObjectifNil(sqInt fieldIndex, sqInt objectPointer, sqInt defaultValue);
static sqInt fixAlphawith(sqInt sourceWord, sqInt destinationWord);
static VirtualMachine * getInterpreter(void);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halftoneAt(sqInt idx);
static sqInt halt(void);
static sqInt ignoreSourceOrHalftone(sqInt formPointer);
static sqInt initBBOpTable(void);
static sqInt initDither8Lookup(void);
#pragma export on
EXPORT(sqInt) initialiseModule(void);
#pragma export off
static sqInt isIdentityMapwith(int * shifts, unsigned int * masks);
static sqInt loadBitBltDestForm(void);
#pragma export on
EXPORT(sqInt) loadBitBltFrom(sqInt bbObj);
#pragma export off
static sqInt loadBitBltFromwarping(sqInt bbObj, sqInt aBool);
static sqInt loadBitBltSourceForm(void);
static sqInt loadColorMap(void);
static void * loadColorMapShiftOrMaskFrom(sqInt mapOop);
static sqInt loadHalftoneForm(void);
static sqInt loadSurfacePlugin(void);
static sqInt loadWarpBltFrom(sqInt bbObj);
static sqInt lockSurfaces(void);
static sqInt mapPixelflags(sqInt sourcePixel, sqInt mapperFlags);
static sqInt mergewith(sqInt sourceWord, sqInt destinationWord);
#pragma export on
EXPORT(sqInt) moduleUnloaded(char * aModuleName);
#pragma export off
static sqInt msg(char * s);
static sqInt partitionedANDtonBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt partitionedAddtonBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt partitionedMaxwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt partitionedMinwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt partitionedMulwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt partitionedSubfromnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts);
static sqInt performCopyLoop(void);
static sqInt pickSourcePixelsflagssrcMaskdestMasksrcShiftIncdstShiftInc(sqInt nPixels, sqInt mapperFlags, sqInt srcMask, sqInt dstMask, sqInt srcShiftInc, sqInt dstShiftInc);
static sqInt pickWarpPixelAtXy(sqInt xx, sqInt yy);
static sqInt pixClearwith(sqInt sourceWord, sqInt destinationWord);
static sqInt pixMaskwith(sqInt sourceWord, sqInt destinationWord);
static sqInt pixPaintwith(sqInt sourceWord, sqInt destinationWord);
static sqInt pixSwapwith(sqInt sourceWord, sqInt destWord);
#pragma export on
EXPORT(sqInt) primitiveCopyBits(void);
EXPORT(sqInt) primitiveDisplayString(void);
EXPORT(sqInt) primitiveDrawLoop(void);
EXPORT(sqInt) primitiveWarpBits(void);
#pragma export off
static sqInt queryDestSurface(sqInt handle);
static sqInt querySourceSurface(sqInt handle);
static sqInt rgbAddwith(sqInt sourceWord, sqInt destinationWord);
static sqInt rgbDiffwith(sqInt sourceWord, sqInt destinationWord);
static sqInt rgbMap16To32(sqInt sourcePixel);
static sqInt rgbMap32To32(sqInt sourcePixel);
static sqInt rgbMapfromto(sqInt sourcePixel, sqInt nBitsIn, sqInt nBitsOut);
static sqInt rgbMapPixelflags(sqInt sourcePixel, sqInt mapperFlags);
static sqInt rgbMaxwith(sqInt sourceWord, sqInt destinationWord);
static sqInt rgbMinwith(sqInt sourceWord, sqInt destinationWord);
static sqInt rgbMinInvertwith(sqInt wordToInvert, sqInt destinationWord);
static sqInt rgbMulwith(sqInt sourceWord, sqInt destinationWord);
static sqInt rgbSubwith(sqInt sourceWord, sqInt destinationWord);
#pragma export on
EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static sqInt setupColorMasks(void);
static sqInt setupColorMasksFromto(sqInt srcBits, sqInt targetBits);
static sqInt showDisplayBits(void);
static sqInt sourceSkewAndPointerInit(void);
static sqInt sourceWordwith(sqInt sourceWord, sqInt destinationWord);
static sqInt srcLongAt(sqInt idx);
static sqInt subWordwith(sqInt sourceWord, sqInt destinationWord);
static sqInt tableLookupat(unsigned int * table, sqInt index);
static sqInt tallyIntoMapwith(sqInt sourceWord, sqInt destinationWord);
static sqInt tallyMapAt(sqInt idx);
static sqInt tallyMapAtput(sqInt idx, sqInt value);
static sqInt tryCopyingBitsQuickly(void);
static sqInt unlockSurfaces(void);
static sqInt warpBits(void);
static sqInt warpLoop(void);
static sqInt warpLoopSetup(void);
static sqInt warpPickSmoothPixelsxDeltahyDeltahxDeltavyDeltavsourceMapsmoothingdstShiftInc(sqInt nPixels, sqInt xDeltah, sqInt yDeltah, sqInt xDeltav, sqInt yDeltav, sqInt sourceMap, sqInt n, sqInt dstShiftInc);
static sqInt warpPickSourcePixelsxDeltahyDeltahxDeltavyDeltavdstShiftIncflags(sqInt nPixels, sqInt xDeltah, sqInt yDeltah, sqInt xDeltav, sqInt yDeltav, sqInt dstShiftInc, sqInt mapperFlags);
/*** Variables ***/
static sqInt affectedB;
static sqInt affectedL;
static sqInt affectedR;
static sqInt affectedT;
static sqInt bbH;
static sqInt bbW;
static sqInt bitBltOop;
static sqInt bitCount;
static sqInt clipHeight;
static sqInt clipWidth;
static sqInt clipX;
static sqInt clipY;
static sqInt cmBitsPerColor;
static sqInt cmFlags;
static unsigned int * cmLookupTable;
static sqInt cmMask;
static unsigned int * cmMaskTable;
static int * cmShiftTable;
static sqInt combinationRule;
static sqInt destBits;
static sqInt destDelta;
static sqInt destDepth;
static sqInt destForm;
static sqInt destHeight;
static sqInt destIndex;
static sqInt destMSB;
static sqInt destMask;
static sqInt destPPW;
static sqInt destPitch;
static sqInt destWidth;
static sqInt destX;
static sqInt destY;
static  unsigned char dither8Lookup[4096];
static const int ditherMatrix4x4[16] = {
0,	8,	2,	10,
12,	4,	14,	6,
3,	11,	1,	9,
15,	7,	13,	5
};
static const int ditherThresholds16[8] = { 0, 2, 4, 6, 8, 12, 14, 16 };
static const int ditherValues16[32] = {
0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
};
static sqInt dstBitShift;
static sqInt dx;
static sqInt dy;
static sqInt hDir;
static sqInt halftoneBase;
static sqInt halftoneForm;
static sqInt halftoneHeight;
static sqInt hasSurfaceLock;
static sqInt height;

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static sqInt isWarping;
static void * lockSurfaceFn;
static sqInt mask1;
static sqInt mask2;
static int maskTable[33] = {
0, 1, 3, 0, 15, 31, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 65535,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
};
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"BitBltPlugin 10 November 2008 (i)"
#else
	"BitBltPlugin 10 November 2008 (e)"
#endif
;
static sqInt nWords;
static sqInt noHalftone;
static sqInt noSource;
static void *opTable[42];
static sqInt preload;
static void * querySurfaceFn;
static sqInt skew;
static sqInt sourceAlpha;
static sqInt sourceBits;
static sqInt sourceDelta;
static sqInt sourceDepth;
static sqInt sourceForm;
static sqInt sourceHeight;
static sqInt sourceIndex;
static sqInt sourceMSB;
static sqInt sourcePPW;
static sqInt sourcePitch;
static sqInt sourceWidth;
static sqInt sourceX;
static sqInt sourceY;
static sqInt srcBitShift;
static sqInt sx;
static sqInt sy;
static void * unlockSurfaceFn;
static sqInt vDir;
static sqInt warpAlignMask;
static sqInt warpAlignShift;
static int warpBitShiftTable[32];
static sqInt warpSrcMask;
static sqInt warpSrcShift;
static sqInt width;



/*	Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, XOR the two and return the number of differing pixels.
	Note that the region is not clipped to bit boundaries, but only to the
	nearest (enclosing) word.  This is because copyLoop does not do
	pre-merge masking.  For accurate results, you must subtract the
	values obtained from the left and right fringes. */

static sqInt OLDrgbDiffwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt diff;
    sqInt pixMask;

	if (destDepth < 16) {
		diff = sourceWord ^ destinationWord;
		pixMask = maskTable[destDepth];
		while (!(diff == 0)) {
			if ((diff & pixMask) != 0) {
				bitCount += 1;
			}
			diff = ((usqInt) diff) >> destDepth;
		}
		return destinationWord;
	}
	if (destDepth == 16) {
		diff = partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 5, 3);
		bitCount = ((bitCount + (diff & 31)) + ((((usqInt) diff) >> 5) & 31)) + ((((usqInt) diff) >> 10) & 31);
		diff = partitionedSubfromnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3);
		bitCount = ((bitCount + (diff & 31)) + ((((usqInt) diff) >> 5) & 31)) + ((((usqInt) diff) >> 10) & 31);
	} else {
		diff = partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 8, 3);
		bitCount = ((bitCount + (diff & 255)) + ((((usqInt) diff) >> 8) & 255)) + ((((usqInt) diff) >> 16) & 255);
	}
	return destinationWord;
}


/*	Tally pixels into the color map.  Note that the source should be 
	specified = destination, in order for the proper color map checks 
	to be performed at setup.
	Note that the region is not clipped to bit boundaries, but only to the
	nearest (enclosing) word.  This is because copyLoop does not do
	pre-merge masking.  For accurate results, you must subtract the
	values obtained from the left and right fringes. */

static sqInt OLDtallyIntoMapwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt shiftWord;
    sqInt pixMask;
    sqInt i;
    sqInt mapIndex;
    sqInt srcPix;
    sqInt d;
    sqInt mask;
    sqInt destPix;
    sqInt srcPix1;
    sqInt d1;
    sqInt mask3;
    sqInt destPix1;
    sqInt srcPix2;
    sqInt d2;
    sqInt mask4;
    sqInt destPix2;

	if (!((cmFlags & (ColorMapPresent | ColorMapIndexedPart)) == (ColorMapPresent | ColorMapIndexedPart))) {
		return destinationWord;
	}
	if (destDepth < 16) {
		pixMask = (maskTable[destDepth]) & cmMask;
		shiftWord = destinationWord;
		for (i = 1; i <= destPPW; i += 1) {
			mapIndex = shiftWord & pixMask;
			cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
			shiftWord = ((usqInt) shiftWord) >> destDepth;
		}
		return destinationWord;
	}
	if (destDepth == 16) {
		/* begin rgbMap:from:to: */
		if ((d = cmBitsPerColor - 5) > 0) {
			mask = (1 << 5) - 1;
			srcPix = (destinationWord & 65535) << d;
			mask = mask << d;
			destPix = srcPix & mask;
			mask = mask << cmBitsPerColor;
			srcPix = srcPix << d;
			mapIndex = (destPix + (srcPix & mask)) + ((srcPix << d) & (mask << cmBitsPerColor));
			goto l1;
		} else {
			if (d == 0) {
				if (5 == 5) {
					mapIndex = (destinationWord & 65535) & 32767;
					goto l1;
				}
				if (5 == 8) {
					mapIndex = (destinationWord & 65535) & 16777215;
					goto l1;
				}
				mapIndex = destinationWord & 65535;
				goto l1;
			}
			if ((destinationWord & 65535) == 0) {
				mapIndex = destinationWord & 65535;
				goto l1;
			}
			d = 5 - cmBitsPerColor;
			mask = (1 << cmBitsPerColor) - 1;
			srcPix = ((usqInt) (destinationWord & 65535)) >> d;
			destPix = srcPix & mask;
			mask = mask << cmBitsPerColor;
			srcPix = ((usqInt) srcPix) >> d;
			destPix = (destPix + (srcPix & mask)) + ((((usqInt) srcPix) >> d) & (mask << cmBitsPerColor));
			if (destPix == 0) {
				mapIndex = 1;
				goto l1;
			}
			mapIndex = destPix;
			goto l1;
		}
	l1:	/* end rgbMap:from:to: */;
		cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
		/* begin rgbMap:from:to: */
		if ((d1 = cmBitsPerColor - 5) > 0) {
			mask3 = (1 << 5) - 1;
			srcPix1 = (((usqInt) destinationWord) >> 16) << d1;
			mask3 = mask3 << d1;
			destPix1 = srcPix1 & mask3;
			mask3 = mask3 << cmBitsPerColor;
			srcPix1 = srcPix1 << d1;
			mapIndex = (destPix1 + (srcPix1 & mask3)) + ((srcPix1 << d1) & (mask3 << cmBitsPerColor));
			goto l2;
		} else {
			if (d1 == 0) {
				if (5 == 5) {
					mapIndex = (((usqInt) destinationWord) >> 16) & 32767;
					goto l2;
				}
				if (5 == 8) {
					mapIndex = (((usqInt) destinationWord) >> 16) & 16777215;
					goto l2;
				}
				mapIndex = ((usqInt) destinationWord) >> 16;
				goto l2;
			}
			if ((((usqInt) destinationWord) >> 16) == 0) {
				mapIndex = ((usqInt) destinationWord) >> 16;
				goto l2;
			}
			d1 = 5 - cmBitsPerColor;
			mask3 = (1 << cmBitsPerColor) - 1;
			srcPix1 = ((usqInt) (((usqInt) destinationWord) >> 16)) >> d1;
			destPix1 = srcPix1 & mask3;
			mask3 = mask3 << cmBitsPerColor;
			srcPix1 = ((usqInt) srcPix1) >> d1;
			destPix1 = (destPix1 + (srcPix1 & mask3)) + ((((usqInt) srcPix1) >> d1) & (mask3 << cmBitsPerColor));
			if (destPix1 == 0) {
				mapIndex = 1;
				goto l2;
			}
			mapIndex = destPix1;
			goto l2;
		}
	l2:	/* end rgbMap:from:to: */;
		cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
	} else {
		/* begin rgbMap:from:to: */
		if ((d2 = cmBitsPerColor - 8) > 0) {
			mask4 = (1 << 8) - 1;
			srcPix2 = destinationWord << d2;
			mask4 = mask4 << d2;
			destPix2 = srcPix2 & mask4;
			mask4 = mask4 << cmBitsPerColor;
			srcPix2 = srcPix2 << d2;
			mapIndex = (destPix2 + (srcPix2 & mask4)) + ((srcPix2 << d2) & (mask4 << cmBitsPerColor));
			goto l3;
		} else {
			if (d2 == 0) {
				if (8 == 5) {
					mapIndex = destinationWord & 32767;
					goto l3;
				}
				if (8 == 8) {
					mapIndex = destinationWord & 16777215;
					goto l3;
				}
				mapIndex = destinationWord;
				goto l3;
			}
			if (destinationWord == 0) {
				mapIndex = destinationWord;
				goto l3;
			}
			d2 = 8 - cmBitsPerColor;
			mask4 = (1 << cmBitsPerColor) - 1;
			srcPix2 = ((usqInt) destinationWord) >> d2;
			destPix2 = srcPix2 & mask4;
			mask4 = mask4 << cmBitsPerColor;
			srcPix2 = ((usqInt) srcPix2) >> d2;
			destPix2 = (destPix2 + (srcPix2 & mask4)) + ((((usqInt) srcPix2) >> d2) & (mask4 << cmBitsPerColor));
			if (destPix2 == 0) {
				mapIndex = 1;
				goto l3;
			}
			mapIndex = destPix2;
			goto l3;
		}
	l3:	/* end rgbMap:from:to: */;
		cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
	}
	return destinationWord;
}

static sqInt addWordwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord + destinationWord;
}

static sqInt affectedBottom(void) {
	return affectedB;
}

static sqInt affectedLeft(void) {
	return affectedL;
}

static sqInt affectedRight(void) {
	return affectedR;
}

static sqInt affectedTop(void) {
	return affectedT;
}


/*	Blend sourceWord with destinationWord, assuming both are 32-bit pixels.
	The source is assumed to have 255*alpha in the high 8 bits of each pixel,
	while the high 8 bits of the destinationWord will be ignored.
	The blend produced is alpha*source + (1-alpha)*dest, with
	the computation being performed independently on each color
	component.  The high byte of the result will be 0. */

static sqInt alphaBlendwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt result;
    sqInt unAlpha;
    sqInt shift;
    sqInt colorMask;
    sqInt blend;
    sqInt alpha;


	/* High 8 bits of source pixel */

	alpha = ((usqInt) sourceWord) >> 24;
	if (alpha == 0) {
		return destinationWord;
	}
	if (alpha == 255) {
		return sourceWord;
	}
	unAlpha = 255 - alpha;
	colorMask = 255;

	/* red */

	result = 0;
	shift = 0;
	blend = ((((((((usqInt) sourceWord) >> shift) & colorMask) * alpha) + (((((usqInt) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* green */

	result = result | (blend << shift);
	shift = 8;
	blend = ((((((((usqInt) sourceWord) >> shift) & colorMask) * alpha) + (((((usqInt) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* blue */

	result = result | (blend << shift);
	shift = 16;
	blend = ((((((((usqInt) sourceWord) >> shift) & colorMask) * alpha) + (((((usqInt) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* alpha (pre-multiplied) */

	result = result | (blend << shift);
	shift = 24;
	blend = ((((alpha * 255) + (((((usqInt) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;
	result = result | (blend << shift);
	return result;
}

static sqInt alphaBlendConstwith(sqInt sourceWord, sqInt destinationWord) {
	return alphaBlendConstwithpaintMode(sourceWord, destinationWord, 0);
}


/*	Blend sourceWord with destinationWord using a constant alpha.
	Alpha is encoded as 0 meaning 0.0, and 255 meaning 1.0.
	The blend produced is alpha*source + (1.0-alpha)*dest, with the
	computation being performed independently on each color component.
	This function could eventually blend into any depth destination,
	using the same color averaging and mapping as warpBlt.
	paintMode = true means do nothing if the source pixel value is zero. */
/*	This first implementation works with dest depths of 16 and 32 bits only.
	Normal color mapping will allow sources of lower depths in this case,
	and results can be mapped directly by truncation, so no extra color maps are needed.
	To allow storing into any depth will require subsequent addition of two other
	colormaps, as is the case with WarpBlt. */

static sqInt alphaBlendConstwithpaintMode(sqInt sourceWord, sqInt destinationWord, sqInt paintMode) {
    sqInt destShifted;
    sqInt result;
    sqInt sourceShifted;
    sqInt rgbMask;
    sqInt unAlpha;
    sqInt shift;
    sqInt bitsPerColor;
    sqInt blend;
    sqInt pixMask;
    sqInt sourcePixVal;
    sqInt i;
    sqInt pixBlend;
    sqInt maskShifted;
    sqInt j;
    sqInt destPixVal;

	if (destDepth < 16) {
		return destinationWord;
	}
	unAlpha = 255 - sourceAlpha;
	pixMask = maskTable[destDepth];
	if (destDepth == 16) {
		bitsPerColor = 5;
	} else {
		bitsPerColor = 8;
	}
	rgbMask = (1 << bitsPerColor) - 1;
	maskShifted = destMask;
	destShifted = destinationWord;
	sourceShifted = sourceWord;
	result = destinationWord;
	if (destPPW == 1) {
		if (!(paintMode && (sourceWord == 0))) {
			result = 0;
			for (i = 1; i <= 4; i += 1) {
				shift = (i - 1) * 8;
				blend = ((((((((usqInt) sourceWord) >> shift) & rgbMask) * sourceAlpha) + (((((usqInt) destinationWord) >> shift) & rgbMask) * unAlpha)) + 254) / 255) & rgbMask;
				result = result | (blend << shift);
			}
		}
	} else {
		for (j = 1; j <= destPPW; j += 1) {
			sourcePixVal = sourceShifted & pixMask;
			if (!(((maskShifted & pixMask) == 0) || (paintMode && (sourcePixVal == 0)))) {
				destPixVal = destShifted & pixMask;
				pixBlend = 0;
				for (i = 1; i <= 3; i += 1) {
					shift = (i - 1) * bitsPerColor;
					blend = ((((((((usqInt) sourcePixVal) >> shift) & rgbMask) * sourceAlpha) + (((((usqInt) destPixVal) >> shift) & rgbMask) * unAlpha)) + 254) / 255) & rgbMask;
					pixBlend = pixBlend | (blend << shift);
				}
				if (destDepth == 16) {
					result = (result & (~(pixMask << ((j - 1) * 16)))) | (pixBlend << ((j - 1) * 16));
				} else {
					result = pixBlend;
				}
			}
			maskShifted = ((usqInt) maskShifted) >> destDepth;
			sourceShifted = ((usqInt) sourceShifted) >> destDepth;
			destShifted = ((usqInt) destShifted) >> destDepth;
		}
	}
	return result;
}


/*	Blend sourceWord with destinationWord using the alpha value from sourceWord.
	Alpha is encoded as 0 meaning 0.0, and 255 meaning 1.0.
	In contrast to alphaBlend:with: the color produced is

		srcColor + (1-srcAlpha) * dstColor

	e.g., it is assumed that the source color is already scaled. */

static sqInt alphaBlendScaledwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt a;
    sqInt dstMask;
    sqInt b;
    sqInt g;
    sqInt unAlpha;
    sqInt r;
    sqInt srcMask;


	/* High 8 bits of source pixel */

	unAlpha = 255 - (((usqInt) sourceWord) >> 24);
	dstMask = destinationWord;
	srcMask = sourceWord;
	b = (((usqInt) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (b > 255) {
		b = 255;
	}
	dstMask = ((usqInt) dstMask) >> 8;
	srcMask = ((usqInt) srcMask) >> 8;
	g = (((usqInt) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (g > 255) {
		g = 255;
	}
	dstMask = ((usqInt) dstMask) >> 8;
	srcMask = ((usqInt) srcMask) >> 8;
	r = (((usqInt) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (r > 255) {
		r = 255;
	}
	dstMask = ((usqInt) dstMask) >> 8;
	srcMask = ((usqInt) srcMask) >> 8;
	a = (((usqInt) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (a > 255) {
		a = 255;
	}
	return (((((a << 8) + r) << 8) + g) << 8) + b;
}

static sqInt alphaPaintConstwith(sqInt sourceWord, sqInt destinationWord) {
	if (sourceWord == 0) {
		return destinationWord;
	}
	return alphaBlendConstwithpaintMode(sourceWord, destinationWord, 1);
}


/*	This version assumes 
		combinationRule = 34
		sourcePixSize = 32
		destPixSize = 16
		sourceForm ~= destForm.
	 */

static sqInt alphaSourceBlendBits16(void) {
    sqInt srcAlpha;
    sqInt dstIndex;
    sqInt deltaX;
    sqInt dstMask;
    sqInt ditherBase;
    sqInt deltaY;
    sqInt dstY;
    sqInt ditherIndex;
    sqInt srcY;
    sqInt srcShift;
    sqInt ditherThreshold;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt destWord;
    sqInt addThreshold;
    sqInt addThreshold1;
    sqInt dstValue;
    sqInt dstValue1;


	/* So we can pre-decrement */

	deltaY = bbH + 1;
	srcY = sy;
	dstY = dy;
	srcShift = (dx & 1) * 16;
	if (destMSB) {
		srcShift = 16 - srcShift;
	}

	/* This is the outer loop */

	mask1 = 65535 << (16 - srcShift);
	while ((deltaY -= 1) != 0) {
		srcIndex = (sourceBits + (srcY * sourcePitch)) + (sx * 4);
		dstIndex = (destBits + (dstY * destPitch)) + ((((sqInt) dx >> 1)) * 4);
		ditherBase = (dstY & 3) * 4;

		/* For pre-increment */

		ditherIndex = (sx & 3) - 1;

		/* So we can pre-decrement */

		deltaX = bbW + 1;
		dstMask = mask1;
		if (dstMask == 65535) {
			srcShift = 16;
		} else {
			srcShift = 0;
		}
		while ((deltaX -= 1) != 0) {
			ditherThreshold = ditherMatrix4x4[ditherBase + (ditherIndex = (ditherIndex + 1) & 3)];
			sourceWord = long32At(srcIndex);
			srcAlpha = ((usqInt) sourceWord) >> 24;
			if (srcAlpha == 255) {
				/* begin dither32To16:threshold: */
				addThreshold = ((usqInt) ditherThreshold << 8);
				sourceWord = ((((usqInt) (dither8Lookup[addThreshold + ((((usqInt) sourceWord >> 16)) & 255)]) << 10)) + (((usqInt) (dither8Lookup[addThreshold + ((((usqInt) sourceWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold + (sourceWord & 255)]);
				if (sourceWord == 0) {
					sourceWord = 1 << srcShift;
				} else {
					sourceWord = sourceWord << srcShift;
				}
				/* begin dstLongAt:put:mask: */
				dstValue = long32At(dstIndex);
				dstValue = dstValue & dstMask;
				dstValue = dstValue | sourceWord;
				long32Atput(dstIndex, dstValue);
			} else {
				if (!(srcAlpha == 0)) {
					destWord = long32At(dstIndex);
					destWord = destWord & (~dstMask);

					/* Expand from 16 to 32 bit by adding zero bits */

					destWord = ((usqInt) destWord) >> srcShift;

					/* Mix colors */

					destWord = ((((usqInt) (destWord & 31744) << 9)) | (((usqInt) (destWord & 992) << 6))) | ((((usqInt) (destWord & 31) << 3)) | 4278190080U);

					/* And dither */

					sourceWord = alphaBlendScaledwith(sourceWord, destWord);
					/* begin dither32To16:threshold: */
					addThreshold1 = ((usqInt) ditherThreshold << 8);
					sourceWord = ((((usqInt) (dither8Lookup[addThreshold1 + ((((usqInt) sourceWord >> 16)) & 255)]) << 10)) + (((usqInt) (dither8Lookup[addThreshold1 + ((((usqInt) sourceWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold1 + (sourceWord & 255)]);
					if (sourceWord == 0) {
						sourceWord = 1 << srcShift;
					} else {
						sourceWord = sourceWord << srcShift;
					}
					/* begin dstLongAt:put:mask: */
					dstValue1 = long32At(dstIndex);
					dstValue1 = dstValue1 & dstMask;
					dstValue1 = dstValue1 | sourceWord;
					long32Atput(dstIndex, dstValue1);
				}
			}
			srcIndex += 4;
			if (destMSB) {
				if (srcShift == 0) {
					dstIndex += 4;
				}
			} else {
				if (!(srcShift == 0)) {
					dstIndex += 4;
				}
			}

			/* Toggle between 0 and 16 */

			srcShift = srcShift ^ 16;
			dstMask = ~dstMask;
		}
		srcY += 1;
		dstY += 1;
	}
}


/*	This version assumes 
		combinationRule = 34
		sourcePixSize = destPixSize = 32
		sourceForm ~= destForm.
	Note: The inner loop has been optimized for dealing
		with the special cases of srcAlpha = 0.0 and srcAlpha = 1.0 
	 */

static sqInt alphaSourceBlendBits32(void) {
    sqInt srcAlpha;
    sqInt dstIndex;
    sqInt deltaX;
    sqInt deltaY;
    sqInt dstY;
    sqInt srcY;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt destWord;


	/* So we can pre-decrement */

	deltaY = bbH + 1;
	srcY = sy;

	/* This is the outer loop */

	dstY = dy;
	while ((deltaY -= 1) != 0) {
		srcIndex = (sourceBits + (srcY * sourcePitch)) + (sx * 4);
		dstIndex = (destBits + (dstY * destPitch)) + (dx * 4);

		/* So we can pre-decrement */
		/* This is the inner loop */

		deltaX = bbW + 1;
		while ((deltaX -= 1) != 0) {
			sourceWord = long32At(srcIndex);
			srcAlpha = ((usqInt) sourceWord) >> 24;
			if (srcAlpha == 255) {
				long32Atput(dstIndex, sourceWord);
				srcIndex += 4;

				/* Now copy as many words as possible with alpha = 255 */

				dstIndex += 4;
				while (((deltaX -= 1) != 0) && ((((usqInt) (sourceWord = long32At(srcIndex))) >> 24) == 255)) {
					long32Atput(dstIndex, sourceWord);
					srcIndex += 4;
					dstIndex += 4;
				}
				deltaX += 1;
			} else {
				if (srcAlpha == 0) {
					srcIndex += 4;

					/* Now skip as many words as possible, */

					dstIndex += 4;
					while (((deltaX -= 1) != 0) && ((((usqInt) (sourceWord = long32At(srcIndex))) >> 24) == 0)) {
						srcIndex += 4;
						dstIndex += 4;
					}
					deltaX += 1;
				} else {
					destWord = long32At(dstIndex);
					destWord = alphaBlendScaledwith(sourceWord, destWord);
					long32Atput(dstIndex, destWord);
					srcIndex += 4;
					dstIndex += 4;
				}
			}
		}
		srcY += 1;
		dstY += 1;
	}
}


/*	This version assumes 
		combinationRule = 34
		sourcePixSize = 32
		destPixSize = 8
		sourceForm ~= destForm.
	Note: This is not real blending since we don't have the source colors available.
	 */

static sqInt alphaSourceBlendBits8(void) {
    sqInt srcAlpha;
    sqInt dstIndex;
    sqInt deltaX;
    sqInt dstMask;
    sqInt mapperFlags;
    sqInt adjust;
    sqInt deltaY;
    sqInt dstY;
    sqInt srcY;
    sqInt srcShift;
    unsigned int * mappingTable;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt destWord;
    sqInt pv;
    sqInt val;
    sqInt dstValue;

	mappingTable = default8To32Table();
	mapperFlags = cmFlags & (~ColorMapNewStyle);

	/* So we can pre-decrement */

	deltaY = bbH + 1;
	srcY = sy;
	dstY = dy;
	mask1 = (dx & 3) * 8;
	if (destMSB) {
		mask1 = 24 - mask1;
	}
	mask2 = AllOnes ^ (255 << mask1);
	if ((dx & 1) == 0) {
		adjust = 0;
	} else {
		adjust = 522133279;
	}
	if ((dy & 1) == 0) {
		adjust = adjust ^ 522133279;
	}
	while ((deltaY -= 1) != 0) {
		adjust = adjust ^ 522133279;
		srcIndex = (sourceBits + (srcY * sourcePitch)) + (sx * 4);
		dstIndex = (destBits + (dstY * destPitch)) + ((((sqInt) dx >> 2)) * 4);

		/* So we can pre-decrement */

		deltaX = bbW + 1;
		srcShift = mask1;

		/* This is the inner loop */

		dstMask = mask2;
		while ((deltaX -= 1) != 0) {
			sourceWord = ((long32At(srcIndex)) & (~adjust)) + adjust;
			srcAlpha = ((usqInt) sourceWord) >> 24;
			if (srcAlpha > 31) {
				if (srcAlpha < 224) {
					destWord = long32At(dstIndex);
					destWord = destWord & (~dstMask);
					destWord = ((usqInt) destWord) >> srcShift;
					destWord = mappingTable[destWord];
					sourceWord = alphaBlendScaledwith(sourceWord, destWord);
				}
				/* begin mapPixel:flags: */
				pv = sourceWord;
				if ((mapperFlags & ColorMapPresent) != 0) {
					if ((mapperFlags & ColorMapFixedPart) != 0) {
						/* begin rgbMapPixel:flags: */
						val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourceWord & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourceWord & (cmMaskTable[0])) << (cmShiftTable[0])));
						val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourceWord & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourceWord & (cmMaskTable[1])) << (cmShiftTable[1]))));
						val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourceWord & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourceWord & (cmMaskTable[2])) << (cmShiftTable[2]))));
						pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourceWord & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourceWord & (cmMaskTable[3])) << (cmShiftTable[3]))));
						if ((pv == 0) && (sourceWord != 0)) {
							pv = 1;
						}
					}
					if ((mapperFlags & ColorMapIndexedPart) != 0) {
						pv = cmLookupTable[pv & cmMask];
					}
				}
				sourceWord = pv;

				/* Store back */

				sourceWord = sourceWord << srcShift;
				/* begin dstLongAt:put:mask: */
				dstValue = long32At(dstIndex);
				dstValue = dstValue & dstMask;
				dstValue = dstValue | sourceWord;
				long32Atput(dstIndex, dstValue);
			}
			srcIndex += 4;
			if (destMSB) {
				if (srcShift == 0) {
					dstIndex += 4;
					srcShift = 24;
					dstMask = 16777215;
				} else {
					srcShift -= 8;
					dstMask = (((usqInt) dstMask) >> 8) | 4278190080U;
				}
			} else {
				if (srcShift == 32) {
					dstIndex += 4;
					srcShift = 0;
					dstMask = 4294967040U;
				} else {
					srcShift += 8;
					dstMask = (dstMask << 8) | 255;
				}
			}
			adjust = adjust ^ 522133279;
		}
		srcY += 1;
		dstY += 1;
	}
}

static sqInt bitAndwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord & destinationWord;
}

static sqInt bitAndInvertwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord & (~destinationWord);
}

static sqInt bitInvertAndwith(sqInt sourceWord, sqInt destinationWord) {
	return (~sourceWord) & destinationWord;
}

static sqInt bitInvertAndInvertwith(sqInt sourceWord, sqInt destinationWord) {
	return (~sourceWord) & (~destinationWord);
}

static sqInt bitInvertDestinationwith(sqInt sourceWord, sqInt destinationWord) {
	return ~destinationWord;
}

static sqInt bitInvertOrwith(sqInt sourceWord, sqInt destinationWord) {
	return (~sourceWord) | destinationWord;
}

static sqInt bitInvertOrInvertwith(sqInt sourceWord, sqInt destinationWord) {
	return (~sourceWord) | (~destinationWord);
}

static sqInt bitInvertSourcewith(sqInt sourceWord, sqInt destinationWord) {
	return ~sourceWord;
}

static sqInt bitInvertXorwith(sqInt sourceWord, sqInt destinationWord) {
	return (~sourceWord) ^ destinationWord;
}

static sqInt bitOrwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord | destinationWord;
}

static sqInt bitOrInvertwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord | (~destinationWord);
}

static sqInt bitXorwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord ^ destinationWord;
}


/*	check for possible overlap of source and destination */
/*	ar 10/19/1999: This method requires surfaces to be locked. */

static sqInt checkSourceOverlap(void) {
    sqInt t;

	if ((sourceForm == destForm) && (dy >= sy)) {
		if (dy > sy) {
			vDir = -1;
			sy = (sy + bbH) - 1;
			dy = (dy + bbH) - 1;
		} else {
			if ((dy == sy) && (dx > sx)) {
				hDir = -1;

				/* start at right */

				sx = (sx + bbW) - 1;

				/* and fix up masks */

				dx = (dx + bbW) - 1;
				if (nWords > 1) {
					t = mask1;
					mask1 = mask2;
					mask2 = t;
				}
			}
		}
		destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
		destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	}
}

static sqInt clearWordwith(sqInt source, sqInt destination) {
	return 0;
}


/*	clip and adjust source origin and extent appropriately */
/*	first in x */

static sqInt clipRange(void) {
	if (destX >= clipX) {
		sx = sourceX;
		dx = destX;
		bbW = width;
	} else {
		sx = sourceX + (clipX - destX);
		bbW = width - (clipX - destX);
		dx = clipX;
	}
	if ((dx + bbW) > (clipX + clipWidth)) {
		bbW -= (dx + bbW) - (clipX + clipWidth);
	}
	if (destY >= clipY) {
		sy = sourceY;
		dy = destY;
		bbH = height;
	} else {
		sy = (sourceY + clipY) - destY;
		bbH = height - (clipY - destY);
		dy = clipY;
	}
	if ((dy + bbH) > (clipY + clipHeight)) {
		bbH -= (dy + bbH) - (clipY + clipHeight);
	}
	if (noSource) {
		return null;
	}
	if (sx < 0) {
		dx -= sx;
		bbW += sx;
		sx = 0;
	}
	if ((sx + bbW) > sourceWidth) {
		bbW -= (sx + bbW) - sourceWidth;
	}
	if (sy < 0) {
		dy -= sy;
		bbH += sy;
		sy = 0;
	}
	if ((sy + bbH) > sourceHeight) {
		bbH -= (sy + bbH) - sourceHeight;
	}
}


/*	This function is exported for the Balloon engine */

EXPORT(sqInt) copyBits(void) {
    sqInt done;
    sqInt dxLowBits;
    sqInt pixPerM1;
    sqInt sxLowBits;
    sqInt dWid;
    sqInt t;
    sqInt endBits;
    sqInt pixPerM11;
    sqInt startBits;

	clipRange();
	if ((bbW <= 0) || (bbH <= 0)) {
		affectedL = affectedR = affectedT = affectedB = 0;
		return null;
	}
	if (!(lockSurfaces())) {
		return interpreterProxy->primitiveFail();
	}
	/* begin copyBitsLockedAndClipped */
	/* begin tryCopyingBitsQuickly */
	if (noSource) {
		done = 0;
		goto l1;
	}
	if (!(combinationRule == 34)) {
		done = 0;
		goto l1;
	}
	if (!(sourceDepth == 32)) {
		done = 0;
		goto l1;
	}
	if (sourceForm == destForm) {
		done = 0;
		goto l1;
	}
	if (destDepth < 8) {
		done = 0;
		goto l1;
	}
	if ((destDepth == 8) && ((cmFlags & ColorMapPresent) == 0)) {
		done = 0;
		goto l1;
	}
	if (destDepth == 32) {
		alphaSourceBlendBits32();
	}
	if (destDepth == 16) {
		alphaSourceBlendBits16();
	}
	if (destDepth == 8) {
		alphaSourceBlendBits8();
	}
	affectedL = dx;
	affectedR = dx + bbW;
	affectedT = dy;
	affectedB = dy + bbH;
	done = 1;
l1:	/* end tryCopyingBitsQuickly */;
	if (done) {
		goto l2;
	}
	if ((combinationRule == 30) || (combinationRule == 31)) {
		if ((interpreterProxy->methodArgumentCount()) == 1) {
			sourceAlpha = interpreterProxy->stackIntegerValue(0);
			if (!((!(interpreterProxy->failed())) && ((sourceAlpha >= 0) && (sourceAlpha <= 255)))) {
				interpreterProxy->primitiveFail();
				goto l2;
			}
		} else {
			interpreterProxy->primitiveFail();
			goto l2;
		}
	}
	bitCount = 0;
	/* begin performCopyLoop */
	/* begin destMaskAndPointerInit */
	pixPerM11 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM11);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM11) / destPPW) + 1;
	}
	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	if (noSource) {
		copyLoopNoSource();
	} else {
		/* begin checkSourceOverlap */
		if ((sourceForm == destForm) && (dy >= sy)) {
			if (dy > sy) {
				vDir = -1;
				sy = (sy + bbH) - 1;
				dy = (dy + bbH) - 1;
			} else {
				if ((dy == sy) && (dx > sx)) {
					hDir = -1;
					sx = (sx + bbW) - 1;
					dx = (dx + bbW) - 1;
					if (nWords > 1) {
						t = mask1;
						mask1 = mask2;
						mask2 = t;
					}
				}
			}
			destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
			destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
		}
		if ((sourceDepth != destDepth) || ((cmFlags != 0) || (sourceMSB != destMSB))) {
			copyLoopPixMap();
		} else {
			/* begin sourceSkewAndPointerInit */
			pixPerM1 = destPPW - 1;
			sxLowBits = sx & pixPerM1;
			dxLowBits = dx & pixPerM1;
			if (hDir > 0) {
				dWid = ((bbW < (destPPW - dxLowBits)) ? bbW : (destPPW - dxLowBits));
				preload = (sxLowBits + dWid) > pixPerM1;
			} else {
				dWid = ((bbW < (dxLowBits + 1)) ? bbW : (dxLowBits + 1));
				preload = ((sxLowBits - dWid) + 1) < 0;
			}
			if (sourceMSB) {
				skew = (sxLowBits - dxLowBits) * destDepth;
			} else {
				skew = (dxLowBits - sxLowBits) * destDepth;
			}
			if (preload) {
				if (skew < 0) {
					skew += 32;
				} else {
					skew -= 32;
				}
			}
			sourceIndex = (sourceBits + (sy * sourcePitch)) + ((sx / (32 / sourceDepth)) * 4);
			sourceDelta = (sourcePitch * vDir) - (4 * (nWords * hDir));
			if (preload) {
				sourceDelta -= 4 * hDir;
			}
			copyLoop();
		}
	}
	if ((combinationRule == 22) || (combinationRule == 32)) {
		affectedL = affectedR = affectedT = affectedB = 0;
	}
	if (hDir > 0) {
		affectedL = dx;
		affectedR = dx + bbW;
	} else {
		affectedL = (dx - bbW) + 1;
		affectedR = dx + 1;
	}
	if (vDir > 0) {
		affectedT = dy;
		affectedB = dy + bbH;
	} else {
		affectedT = (dy - bbH) + 1;
		affectedB = dy + 1;
	}
l2:	/* end copyBitsLockedAndClipped */;
	unlockSurfaces();
}


/*	Support for the balloon engine. */

EXPORT(sqInt) copyBitsFromtoat(sqInt startX, sqInt stopX, sqInt yValue) {
	destX = startX;
	destY = yValue;
	sourceX = startX;
	width = stopX - startX;
	copyBits();
	/* begin showDisplayBits */
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
}


/*	Perform the actual copyBits operation.
	Assume: Surfaces have been locked and clipping was performed. */

static sqInt copyBitsLockedAndClipped(void) {
    sqInt done;
    sqInt dxLowBits;
    sqInt pixPerM1;
    sqInt sxLowBits;
    sqInt dWid;
    sqInt t;
    sqInt endBits;
    sqInt pixPerM11;
    sqInt startBits;

	/* begin tryCopyingBitsQuickly */
	if (noSource) {
		done = 0;
		goto l1;
	}
	if (!(combinationRule == 34)) {
		done = 0;
		goto l1;
	}
	if (!(sourceDepth == 32)) {
		done = 0;
		goto l1;
	}
	if (sourceForm == destForm) {
		done = 0;
		goto l1;
	}
	if (destDepth < 8) {
		done = 0;
		goto l1;
	}
	if ((destDepth == 8) && ((cmFlags & ColorMapPresent) == 0)) {
		done = 0;
		goto l1;
	}
	if (destDepth == 32) {
		alphaSourceBlendBits32();
	}
	if (destDepth == 16) {
		alphaSourceBlendBits16();
	}
	if (destDepth == 8) {
		alphaSourceBlendBits8();
	}
	affectedL = dx;
	affectedR = dx + bbW;
	affectedT = dy;
	affectedB = dy + bbH;
	done = 1;
l1:	/* end tryCopyingBitsQuickly */;
	if (done) {
		return null;
	}
	if ((combinationRule == 30) || (combinationRule == 31)) {
		if ((interpreterProxy->methodArgumentCount()) == 1) {
			sourceAlpha = interpreterProxy->stackIntegerValue(0);
			if (!((!(interpreterProxy->failed())) && ((sourceAlpha >= 0) && (sourceAlpha <= 255)))) {
				return interpreterProxy->primitiveFail();
			}
		} else {
			return interpreterProxy->primitiveFail();
		}
	}

	/* Choose and perform the actual copy loop. */

	bitCount = 0;
	/* begin performCopyLoop */
	/* begin destMaskAndPointerInit */
	pixPerM11 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM11);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM11) / destPPW) + 1;
	}
	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	if (noSource) {
		copyLoopNoSource();
	} else {
		/* begin checkSourceOverlap */
		if ((sourceForm == destForm) && (dy >= sy)) {
			if (dy > sy) {
				vDir = -1;
				sy = (sy + bbH) - 1;
				dy = (dy + bbH) - 1;
			} else {
				if ((dy == sy) && (dx > sx)) {
					hDir = -1;
					sx = (sx + bbW) - 1;
					dx = (dx + bbW) - 1;
					if (nWords > 1) {
						t = mask1;
						mask1 = mask2;
						mask2 = t;
					}
				}
			}
			destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
			destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
		}
		if ((sourceDepth != destDepth) || ((cmFlags != 0) || (sourceMSB != destMSB))) {
			copyLoopPixMap();
		} else {
			/* begin sourceSkewAndPointerInit */
			pixPerM1 = destPPW - 1;
			sxLowBits = sx & pixPerM1;
			dxLowBits = dx & pixPerM1;
			if (hDir > 0) {
				dWid = ((bbW < (destPPW - dxLowBits)) ? bbW : (destPPW - dxLowBits));
				preload = (sxLowBits + dWid) > pixPerM1;
			} else {
				dWid = ((bbW < (dxLowBits + 1)) ? bbW : (dxLowBits + 1));
				preload = ((sxLowBits - dWid) + 1) < 0;
			}
			if (sourceMSB) {
				skew = (sxLowBits - dxLowBits) * destDepth;
			} else {
				skew = (dxLowBits - sxLowBits) * destDepth;
			}
			if (preload) {
				if (skew < 0) {
					skew += 32;
				} else {
					skew -= 32;
				}
			}
			sourceIndex = (sourceBits + (sy * sourcePitch)) + ((sx / (32 / sourceDepth)) * 4);
			sourceDelta = (sourcePitch * vDir) - (4 * (nWords * hDir));
			if (preload) {
				sourceDelta -= 4 * hDir;
			}
			copyLoop();
		}
	}
	if ((combinationRule == 22) || (combinationRule == 32)) {
		affectedL = affectedR = affectedT = affectedB = 0;
	}
	if (hDir > 0) {
		affectedL = dx;
		affectedR = dx + bbW;
	} else {
		affectedL = (dx - bbW) + 1;
		affectedR = dx + 1;
	}
	if (vDir > 0) {
		affectedT = dy;
		affectedB = dy + bbH;
	} else {
		affectedT = (dy - bbH) + 1;
		affectedB = dy + 1;
	}
}


/*	This version of the inner loop assumes noSource = false. */

static sqInt copyLoop(void) {
    sqInt mergeWord;
    sqInt hInc;
    sqInt prevWord;
    sqInt halftoneWord;
    sqInt (*mergeFnwith)(sqInt, sqInt);
    sqInt skewWord;
    sqInt word;
    sqInt skewMask;
    sqInt i;
    sqInt notSkewMask;
    sqInt thisWord;
    sqInt unskew;
    sqInt y;
    sqInt destWord;
    sqInt idx;
    sqInt idx1;
    sqInt idx2;
    sqInt idx3;
    sqInt idx4;
    sqInt idx5;
    sqInt idx6;
    sqInt idx7;
    sqInt idx8;
    sqInt idx9;
    sqInt idx10;
    sqInt idx11;
    sqInt idx12;
    sqInt idx13;
    sqInt idx14;

	mergeFnwith = ((sqInt (*)(sqInt, sqInt)) (opTable[combinationRule + 1]));
	mergeFnwith;

	/* Byte delta */
	/* degenerate skew fixed for Sparc. 10/20/96 ikp */

	hInc = hDir * 4;
	if (skew == -32) {
		skew = unskew = skewMask = 0;
	} else {
		if (skew < 0) {
			unskew = skew + 32;
			skewMask = AllOnes << (0 - skew);
		} else {
			if (skew == 0) {
				unskew = 0;
				skewMask = AllOnes;
			} else {
				unskew = skew - 32;
				skewMask = ((usqInt) AllOnes) >> skew;
			}
		}
	}
	notSkewMask = ~skewMask;
	if (noHalftone) {
		halftoneWord = AllOnes;
		halftoneHeight = 0;
	} else {
		halftoneWord = long32At(halftoneBase + ((0 % halftoneHeight) * 4));
	}
	y = dy;
	for (i = 1; i <= bbH; i += 1) {
		if (halftoneHeight > 1) {
			halftoneWord = long32At(halftoneBase + ((y % halftoneHeight) * 4));
			y += vDir;
		}
		if (preload) {
			/* begin srcLongAt: */
			idx = sourceIndex;
			prevWord = long32At(idx);
			sourceIndex += hInc;
		} else {
			prevWord = 0;
		}
		destMask = mask1;
		/* begin srcLongAt: */
		idx12 = sourceIndex;
		thisWord = long32At(idx12);
		sourceIndex += hInc;

		/* 32-bit rotate */

		skewWord = (((unskew < 0) ? ((usqInt) (prevWord & notSkewMask) >> -unskew) : ((usqInt) (prevWord & notSkewMask) << unskew))) | (((skew < 0) ? ((usqInt) (thisWord & skewMask) >> -skew) : ((usqInt) (thisWord & skewMask) << skew)));
		prevWord = thisWord;
		/* begin dstLongAt: */
		idx13 = destIndex;
		destWord = long32At(idx13);
		mergeWord = mergeFnwith(skewWord & halftoneWord, destWord);
		destWord = (destMask & mergeWord) | (destWord & (~destMask));
		/* begin dstLongAt:put: */
		idx14 = destIndex;
		long32Atput(idx14, destWord);

		/* This central horizontal loop requires no store masking */

		destIndex += hInc;
		destMask = AllOnes;
		if (combinationRule == 3) {
			if ((skew == 0) && (halftoneWord == AllOnes)) {
				if (hDir == -1) {
					for (word = 2; word <= (nWords - 1); word += 1) {
						/* begin srcLongAt: */
						idx1 = sourceIndex;
						thisWord = long32At(idx1);
						sourceIndex += hInc;
						/* begin dstLongAt:put: */
						idx2 = destIndex;
						long32Atput(idx2, thisWord);
						destIndex += hInc;
					}
				} else {
					for (word = 2; word <= (nWords - 1); word += 1) {
						/* begin dstLongAt:put: */
						idx3 = destIndex;
						long32Atput(idx3, prevWord);
						destIndex += hInc;
						/* begin srcLongAt: */
						idx4 = sourceIndex;
						prevWord = long32At(idx4);
						sourceIndex += hInc;
					}
				}
			} else {
				for (word = 2; word <= (nWords - 1); word += 1) {
					/* begin srcLongAt: */
					idx5 = sourceIndex;
					thisWord = long32At(idx5);
					sourceIndex += hInc;

					/* 32-bit rotate */

					skewWord = (((unskew < 0) ? ((usqInt) (prevWord & notSkewMask) >> -unskew) : ((usqInt) (prevWord & notSkewMask) << unskew))) | (((skew < 0) ? ((usqInt) (thisWord & skewMask) >> -skew) : ((usqInt) (thisWord & skewMask) << skew)));
					prevWord = thisWord;
					/* begin dstLongAt:put: */
					idx6 = destIndex;
					long32Atput(idx6, skewWord & halftoneWord);
					destIndex += hInc;
				}
			}
		} else {
			for (word = 2; word <= (nWords - 1); word += 1) {
				/* begin srcLongAt: */
				idx7 = sourceIndex;
				thisWord = long32At(idx7);
				sourceIndex += hInc;

				/* 32-bit rotate */

				skewWord = (((unskew < 0) ? ((usqInt) (prevWord & notSkewMask) >> -unskew) : ((usqInt) (prevWord & notSkewMask) << unskew))) | (((skew < 0) ? ((usqInt) (thisWord & skewMask) >> -skew) : ((usqInt) (thisWord & skewMask) << skew)));
				prevWord = thisWord;
				mergeWord = mergeFnwith(skewWord & halftoneWord, dstLongAt(destIndex));
				/* begin dstLongAt:put: */
				idx8 = destIndex;
				long32Atput(idx8, mergeWord);
				destIndex += hInc;
			}
		}
		if (nWords > 1) {
			destMask = mask2;
			/* begin srcLongAt: */
			idx9 = sourceIndex;
			thisWord = long32At(idx9);
			sourceIndex += hInc;

			/* 32-bit rotate */

			skewWord = (((unskew < 0) ? ((usqInt) (prevWord & notSkewMask) >> -unskew) : ((usqInt) (prevWord & notSkewMask) << unskew))) | (((skew < 0) ? ((usqInt) (thisWord & skewMask) >> -skew) : ((usqInt) (thisWord & skewMask) << skew)));
			/* begin dstLongAt: */
			idx10 = destIndex;
			destWord = long32At(idx10);
			mergeWord = mergeFnwith(skewWord & halftoneWord, destWord);
			destWord = (destMask & mergeWord) | (destWord & (~destMask));
			/* begin dstLongAt:put: */
			idx11 = destIndex;
			long32Atput(idx11, destWord);
			destIndex += hInc;
		}
		sourceIndex += sourceDelta;
		destIndex += destDelta;
	}
}


/*	Faster copyLoop when source not used.  hDir and vDir are both
	positive, and perload and skew are unused */

static sqInt copyLoopNoSource(void) {
    sqInt mergeWord;
    sqInt halftoneWord;
    sqInt (*mergeFnwith)(sqInt, sqInt);
    sqInt word;
    sqInt i;
    sqInt destWord;
    sqInt idx;
    sqInt idx1;
    sqInt idx2;
    sqInt idx3;
    sqInt idx4;
    sqInt idx5;
    sqInt idx6;
    sqInt idx7;

	mergeFnwith = ((sqInt (*)(sqInt, sqInt)) (opTable[combinationRule + 1]));
	mergeFnwith;
	for (i = 1; i <= bbH; i += 1) {
		if (noHalftone) {
			halftoneWord = AllOnes;
		} else {
			/* begin halftoneAt: */
			idx = (dy + i) - 1;
			halftoneWord = long32At(halftoneBase + ((idx % halftoneHeight) * 4));
		}
		destMask = mask1;
		/* begin dstLongAt: */
		idx6 = destIndex;
		destWord = long32At(idx6);
		mergeWord = mergeFnwith(halftoneWord, destWord);
		destWord = (destMask & mergeWord) | (destWord & (~destMask));
		/* begin dstLongAt:put: */
		idx7 = destIndex;
		long32Atput(idx7, destWord);

		/* This central horizontal loop requires no store masking */

		destIndex += 4;
		destMask = AllOnes;
		if (combinationRule == 3) {
			destWord = halftoneWord;
			for (word = 2; word <= (nWords - 1); word += 1) {
				/* begin dstLongAt:put: */
				idx1 = destIndex;
				long32Atput(idx1, destWord);
				destIndex += 4;
			}
		} else {
			for (word = 2; word <= (nWords - 1); word += 1) {
				/* begin dstLongAt: */
				idx2 = destIndex;
				destWord = long32At(idx2);
				mergeWord = mergeFnwith(halftoneWord, destWord);
				/* begin dstLongAt:put: */
				idx3 = destIndex;
				long32Atput(idx3, mergeWord);
				destIndex += 4;
			}
		}
		if (nWords > 1) {
			destMask = mask2;
			/* begin dstLongAt: */
			idx4 = destIndex;
			destWord = long32At(idx4);
			mergeWord = mergeFnwith(halftoneWord, destWord);
			destWord = (destMask & mergeWord) | (destWord & (~destMask));
			/* begin dstLongAt:put: */
			idx5 = destIndex;
			long32Atput(idx5, destWord);
			destIndex += 4;
		}
		destIndex += destDelta;
	}
}


/*	This version of the inner loop maps source pixels
	to a destination form with different depth.  Because it is already
	unweildy, the loop is not unrolled as in the other versions.
	Preload, skew and skewMask are all overlooked, since pickSourcePixels
	delivers its destination word already properly aligned.
	Note that pickSourcePixels could be copied in-line at the top of
	the horizontal loop, and some of its inits moved out of the loop. */
/*	ar 12/7/1999:
	The loop has been rewritten to use only one pickSourcePixels call.
	The idea is that the call itself could be inlined. If we decide not
	to inline pickSourcePixels we could optimize the loop instead. */

static sqInt copyLoopPixMap(void) {
    sqInt nPix;
    sqInt endBits;
    sqInt dstShiftLeft;
    sqInt mapperFlags;
    sqInt skewWord;
    sqInt sourcePixMask;
    sqInt srcShift;
    sqInt nSourceIncs;
    sqInt scrStartBits;
    sqInt dstShiftInc;
    sqInt words;
    sqInt destWord;
    sqInt mergeWord;
    sqInt srcShiftInc;
    sqInt destPixMask;
    sqInt halftoneWord;
    sqInt (*mergeFnwith)(sqInt, sqInt);
    sqInt i;
    sqInt dstShift;
    sqInt startBits;
    sqInt idx;
    sqInt value;
    sqInt idx1;
    sqInt idx2;
    sqInt idx3;
    sqInt nPix1;
    sqInt sourcePix;
    sqInt srcShift1;
    sqInt sourceWord;
    sqInt dstShift1;
    sqInt destWord1;
    sqInt destPix;
    sqInt idx4;
    sqInt idx11;
    sqInt idx21;
    sqInt pv;
    sqInt val;

	mergeFnwith = ((sqInt (*)(sqInt, sqInt)) (opTable[combinationRule + 1]));
	mergeFnwith;
	sourcePPW = 32 / sourceDepth;
	sourcePixMask = maskTable[sourceDepth];
	destPixMask = maskTable[destDepth];
	mapperFlags = cmFlags & (~ColorMapNewStyle);
	sourceIndex = (sourceBits + (sy * sourcePitch)) + ((sx / sourcePPW) * 4);
	scrStartBits = sourcePPW - (sx & (sourcePPW - 1));
	if (bbW < scrStartBits) {
		nSourceIncs = 0;
	} else {
		nSourceIncs = ((bbW - scrStartBits) / sourcePPW) + 1;
	}

	/* Note following two items were already calculated in destmask setup! */

	sourceDelta = sourcePitch - (nSourceIncs * 4);
	startBits = destPPW - (dx & (destPPW - 1));
	endBits = (((dx + bbW) - 1) & (destPPW - 1)) + 1;
	if (bbW < startBits) {
		startBits = bbW;
	}
	srcShift = (sx & (sourcePPW - 1)) * sourceDepth;
	dstShift = (dx & (destPPW - 1)) * destDepth;
	srcShiftInc = sourceDepth;
	dstShiftInc = destDepth;
	dstShiftLeft = 0;
	if (sourceMSB) {
		srcShift = (32 - sourceDepth) - srcShift;
		srcShiftInc = 0 - srcShiftInc;
	}
	if (destMSB) {
		dstShift = (32 - destDepth) - dstShift;
		dstShiftInc = 0 - dstShiftInc;
		dstShiftLeft = 32 - destDepth;
	}
	for (i = 1; i <= bbH; i += 1) {
		if (noHalftone) {
			halftoneWord = AllOnes;
		} else {
			/* begin halftoneAt: */
			idx2 = (dy + i) - 1;
			halftoneWord = long32At(halftoneBase + ((idx2 % halftoneHeight) * 4));
		}
		srcBitShift = srcShift;
		dstBitShift = dstShift;
		destMask = mask1;

		/* Here is the horizontal loop... */

		nPix = startBits;
		words = nWords;
		do {
			/* begin pickSourcePixels:flags:srcMask:destMask:srcShiftInc:dstShiftInc: */
			/* begin srcLongAt: */
			idx21 = sourceIndex;
			sourceWord = long32At(idx21);
			destWord1 = 0;
			srcShift1 = srcBitShift;
			dstShift1 = dstBitShift;
			nPix1 = nPix;
			if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
				do {
					sourcePix = (((usqInt) sourceWord) >> srcShift1) & sourcePixMask;
					destPix = tableLookupat(cmLookupTable, sourcePix & cmMask);
					destWord1 = destWord1 | ((destPix & destPixMask) << dstShift1);
					dstShift1 += dstShiftInc;
					if (!(((srcShift1 += srcShiftInc) & 4294967264U) == 0)) {
						if (sourceMSB) {
							srcShift1 += 32;
						} else {
							srcShift1 -= 32;
						}
						/* begin srcLongAt: */
						idx4 = sourceIndex += 4;
						sourceWord = long32At(idx4);
					}
				} while(!((nPix1 -= 1) == 0));
			} else {
				do {
					sourcePix = (((usqInt) sourceWord) >> srcShift1) & sourcePixMask;
					/* begin mapPixel:flags: */
					pv = sourcePix;
					if ((mapperFlags & ColorMapPresent) != 0) {
						if ((mapperFlags & ColorMapFixedPart) != 0) {
							/* begin rgbMapPixel:flags: */
							val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
							val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
							val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
							pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
							if ((pv == 0) && (sourcePix != 0)) {
								pv = 1;
							}
						}
						if ((mapperFlags & ColorMapIndexedPart) != 0) {
							pv = cmLookupTable[pv & cmMask];
						}
					}
					destPix = pv;
					destWord1 = destWord1 | ((destPix & destPixMask) << dstShift1);
					dstShift1 += dstShiftInc;
					if (!(((srcShift1 += srcShiftInc) & 4294967264U) == 0)) {
						if (sourceMSB) {
							srcShift1 += 32;
						} else {
							srcShift1 -= 32;
						}
						/* begin srcLongAt: */
						idx11 = sourceIndex += 4;
						sourceWord = long32At(idx11);
					}
				} while(!((nPix1 -= 1) == 0));
			}
			srcBitShift = srcShift1;
			skewWord = destWord1;
			dstBitShift = dstShiftLeft;
			if (destMask == AllOnes) {
				mergeWord = mergeFnwith(skewWord & halftoneWord, dstLongAt(destIndex));
				/* begin dstLongAt:put: */
				idx = destIndex;
				value = destMask & mergeWord;
				long32Atput(idx, value);
			} else {
				/* begin dstLongAt: */
				idx3 = destIndex;
				destWord = long32At(idx3);
				mergeWord = mergeFnwith(skewWord & halftoneWord, destWord & destMask);
				destWord = (destMask & mergeWord) | (destWord & (~destMask));
				/* begin dstLongAt:put: */
				idx1 = destIndex;
				long32Atput(idx1, destWord);
			}
			destIndex += 4;
			if (words == 2) {
				destMask = mask2;
				nPix = endBits;
			} else {
				destMask = AllOnes;
				nPix = destPPW;
			}
		} while(!((words -= 1) == 0));
		sourceIndex += sourceDelta;
		destIndex += destDelta;
	}
}


/*	Return the default translation table from 1..8 bit indexed colors to 32bit */
/*	The table has been generated by the following statements */
/*	| pvs hex |
	String streamContents:[:s|
		s nextPutAll:'static unsigned int theTable[256] = { '.
		pvs := (Color colorMapIfNeededFrom: 8 to: 32) asArray.
		1 to: pvs size do:[:i|
			i > 1 ifTrue:[s nextPutAll:', '].
			(i-1 \\ 8) = 0 ifTrue:[s cr].
			s nextPutAll:'0x'.
			hex := (pvs at: i) printStringBase: 16.
			s nextPutAll: (hex copyFrom: 4 to: hex size).
		].
		s nextPutAll:'};'.
	]. */

static unsigned int * default8To32Table(void) {
    static unsigned int theTable[256] = { 
0x0, 0xFF000001, 0xFFFFFFFF, 0xFF808080, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFF00FFFF, 
0xFFFFFF00, 0xFFFF00FF, 0xFF202020, 0xFF404040, 0xFF606060, 0xFF9F9F9F, 0xFFBFBFBF, 0xFFDFDFDF, 
0xFF080808, 0xFF101010, 0xFF181818, 0xFF282828, 0xFF303030, 0xFF383838, 0xFF484848, 0xFF505050, 
0xFF585858, 0xFF686868, 0xFF707070, 0xFF787878, 0xFF878787, 0xFF8F8F8F, 0xFF979797, 0xFFA7A7A7, 
0xFFAFAFAF, 0xFFB7B7B7, 0xFFC7C7C7, 0xFFCFCFCF, 0xFFD7D7D7, 0xFFE7E7E7, 0xFFEFEFEF, 0xFFF7F7F7, 
0xFF000001, 0xFF003300, 0xFF006600, 0xFF009900, 0xFF00CC00, 0xFF00FF00, 0xFF000033, 0xFF003333, 
0xFF006633, 0xFF009933, 0xFF00CC33, 0xFF00FF33, 0xFF000066, 0xFF003366, 0xFF006666, 0xFF009966, 
0xFF00CC66, 0xFF00FF66, 0xFF000099, 0xFF003399, 0xFF006699, 0xFF009999, 0xFF00CC99, 0xFF00FF99, 
0xFF0000CC, 0xFF0033CC, 0xFF0066CC, 0xFF0099CC, 0xFF00CCCC, 0xFF00FFCC, 0xFF0000FF, 0xFF0033FF, 
0xFF0066FF, 0xFF0099FF, 0xFF00CCFF, 0xFF00FFFF, 0xFF330000, 0xFF333300, 0xFF336600, 0xFF339900, 
0xFF33CC00, 0xFF33FF00, 0xFF330033, 0xFF333333, 0xFF336633, 0xFF339933, 0xFF33CC33, 0xFF33FF33, 
0xFF330066, 0xFF333366, 0xFF336666, 0xFF339966, 0xFF33CC66, 0xFF33FF66, 0xFF330099, 0xFF333399, 
0xFF336699, 0xFF339999, 0xFF33CC99, 0xFF33FF99, 0xFF3300CC, 0xFF3333CC, 0xFF3366CC, 0xFF3399CC, 
0xFF33CCCC, 0xFF33FFCC, 0xFF3300FF, 0xFF3333FF, 0xFF3366FF, 0xFF3399FF, 0xFF33CCFF, 0xFF33FFFF, 
0xFF660000, 0xFF663300, 0xFF666600, 0xFF669900, 0xFF66CC00, 0xFF66FF00, 0xFF660033, 0xFF663333, 
0xFF666633, 0xFF669933, 0xFF66CC33, 0xFF66FF33, 0xFF660066, 0xFF663366, 0xFF666666, 0xFF669966, 
0xFF66CC66, 0xFF66FF66, 0xFF660099, 0xFF663399, 0xFF666699, 0xFF669999, 0xFF66CC99, 0xFF66FF99, 
0xFF6600CC, 0xFF6633CC, 0xFF6666CC, 0xFF6699CC, 0xFF66CCCC, 0xFF66FFCC, 0xFF6600FF, 0xFF6633FF, 
0xFF6666FF, 0xFF6699FF, 0xFF66CCFF, 0xFF66FFFF, 0xFF990000, 0xFF993300, 0xFF996600, 0xFF999900, 
0xFF99CC00, 0xFF99FF00, 0xFF990033, 0xFF993333, 0xFF996633, 0xFF999933, 0xFF99CC33, 0xFF99FF33, 
0xFF990066, 0xFF993366, 0xFF996666, 0xFF999966, 0xFF99CC66, 0xFF99FF66, 0xFF990099, 0xFF993399, 
0xFF996699, 0xFF999999, 0xFF99CC99, 0xFF99FF99, 0xFF9900CC, 0xFF9933CC, 0xFF9966CC, 0xFF9999CC, 
0xFF99CCCC, 0xFF99FFCC, 0xFF9900FF, 0xFF9933FF, 0xFF9966FF, 0xFF9999FF, 0xFF99CCFF, 0xFF99FFFF, 
0xFFCC0000, 0xFFCC3300, 0xFFCC6600, 0xFFCC9900, 0xFFCCCC00, 0xFFCCFF00, 0xFFCC0033, 0xFFCC3333, 
0xFFCC6633, 0xFFCC9933, 0xFFCCCC33, 0xFFCCFF33, 0xFFCC0066, 0xFFCC3366, 0xFFCC6666, 0xFFCC9966, 
0xFFCCCC66, 0xFFCCFF66, 0xFFCC0099, 0xFFCC3399, 0xFFCC6699, 0xFFCC9999, 0xFFCCCC99, 0xFFCCFF99, 
0xFFCC00CC, 0xFFCC33CC, 0xFFCC66CC, 0xFFCC99CC, 0xFFCCCCCC, 0xFFCCFFCC, 0xFFCC00FF, 0xFFCC33FF, 
0xFFCC66FF, 0xFFCC99FF, 0xFFCCCCFF, 0xFFCCFFFF, 0xFFFF0000, 0xFFFF3300, 0xFFFF6600, 0xFFFF9900, 
0xFFFFCC00, 0xFFFFFF00, 0xFFFF0033, 0xFFFF3333, 0xFFFF6633, 0xFFFF9933, 0xFFFFCC33, 0xFFFFFF33, 
0xFFFF0066, 0xFFFF3366, 0xFFFF6666, 0xFFFF9966, 0xFFFFCC66, 0xFFFFFF66, 0xFFFF0099, 0xFFFF3399, 
0xFFFF6699, 0xFFFF9999, 0xFFFFCC99, 0xFFFFFF99, 0xFFFF00CC, 0xFFFF33CC, 0xFFFF66CC, 0xFFFF99CC, 
0xFFFFCCCC, 0xFFFFFFCC, 0xFFFF00FF, 0xFFFF33FF, 0xFFFF66FF, 0xFFFF99FF, 0xFFFFCCFF, 0xFFFFFFFF};;

	return theTable;
}


/*	Utility routine for computing Warp increments. */

static sqInt deltaFromtonSteps(sqInt x1, sqInt x2, sqInt n) {
	if (x2 > x1) {
		return (((x2 - x1) + FixedPt1) / (n + 1)) + 1;
	} else {
		if (x2 == x1) {
			return 0;
		}
		return 0 - ((((x1 - x2) + FixedPt1) / (n + 1)) + 1);
	}
}


/*	Compute masks for left and right destination words */

static sqInt destMaskAndPointerInit(void) {
    sqInt endBits;
    sqInt pixPerM1;
    sqInt startBits;


	/* A mask, assuming power of two */
	/* how many pixels in first word */

	pixPerM1 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM1);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM1) / destPPW) + 1;
	}

	/* defaults for no overlap with source */
	/* calculate byte addr and delta, based on first word of data */
	/* Note pitch is bytes and nWords is longs, not bytes */

	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
}

static sqInt destinationWordwith(sqInt sourceWord, sqInt destinationWord) {
	return destinationWord;
}


/*	Dither the given 32bit word to 16 bit. Ignore alpha. */

static sqInt dither32To16threshold(sqInt srcWord, sqInt ditherValue) {
    sqInt addThreshold;

	addThreshold = ((usqInt) ditherValue << 8);
	return ((((usqInt) (dither8Lookup[addThreshold + ((((usqInt) srcWord >> 16)) & 255)]) << 10)) + (((usqInt) (dither8Lookup[addThreshold + ((((usqInt) srcWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold + (srcWord & 255)]);
}


/*	This is the primitive implementation of the line-drawing loop.
	See the comments in BitBlt>>drawLoopX:Y: */

static sqInt drawLoopXY(sqInt xDelta, sqInt yDelta) {
    sqInt affL;
    sqInt affB;
    sqInt affR;
    sqInt P;
    sqInt i;
    sqInt affT;
    sqInt dx1;
    sqInt px;
    sqInt dy1;
    sqInt py;

	if (xDelta > 0) {
		dx1 = 1;
	} else {
		if (xDelta == 0) {
			dx1 = 0;
		} else {
			dx1 = -1;
		}
	}
	if (yDelta > 0) {
		dy1 = 1;
	} else {
		if (yDelta == 0) {
			dy1 = 0;
		} else {
			dy1 = -1;
		}
	}
	px = abs(yDelta);
	py = abs(xDelta);

	/* init null rectangle */

	affL = affT = 9999;
	affR = affB = -9999;
	if (py > px) {
		P = ((sqInt) py >> 1);
		for (i = 1; i <= py; i += 1) {
			destX += dx1;
			if ((P -= px) < 0) {
				destY += dy1;
				P += py;
			}
			if (i < py) {
				copyBits();
				if (interpreterProxy->failed()) {
					return null;
				}
				if ((affectedL < affectedR) && (affectedT < affectedB)) {
					affL = ((affL < affectedL) ? affL : affectedL);
					affR = ((affR < affectedR) ? affectedR : affR);
					affT = ((affT < affectedT) ? affT : affectedT);
					affB = ((affB < affectedB) ? affectedB : affB);
					if (((affR - affL) * (affB - affT)) > 4000) {
						affectedL = affL;
						affectedR = affR;
						affectedT = affT;
						affectedB = affB;
						/* begin showDisplayBits */
						interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);

						/* init null rectangle */

						affL = affT = 9999;
						affR = affB = -9999;
					}
				}
			}
		}
	} else {
		P = ((sqInt) px >> 1);
		for (i = 1; i <= px; i += 1) {
			destY += dy1;
			if ((P -= py) < 0) {
				destX += dx1;
				P += px;
			}
			if (i < px) {
				copyBits();
				if (interpreterProxy->failed()) {
					return null;
				}
				if ((affectedL < affectedR) && (affectedT < affectedB)) {
					affL = ((affL < affectedL) ? affL : affectedL);
					affR = ((affR < affectedR) ? affectedR : affR);
					affT = ((affT < affectedT) ? affT : affectedT);
					affB = ((affB < affectedB) ? affectedB : affB);
					if (((affR - affL) * (affB - affT)) > 4000) {
						affectedL = affL;
						affectedR = affR;
						affectedT = affT;
						affectedB = affB;
						/* begin showDisplayBits */
						interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);

						/* init null rectangle */

						affL = affT = 9999;
						affR = affB = -9999;
					}
				}
			}
		}
	}
	affectedL = affL;
	affectedR = affR;
	affectedT = affT;

	/* store destX, Y back */

	affectedB = affB;
	interpreterProxy->storeIntegerofObjectwithValue(BBDestXIndex, bitBltOop, destX);
	interpreterProxy->storeIntegerofObjectwithValue(BBDestYIndex, bitBltOop, destY);
}

static sqInt dstLongAt(sqInt idx) {
	return long32At(idx);
}

static sqInt dstLongAtput(sqInt idx, sqInt value) {
	return long32Atput(idx, value);
}


/*	Store the given value back into destination form, using dstMask
	to mask out the bits to be modified. This is an essiantial
	read-modify-write operation on the destination form. */

static sqInt dstLongAtputmask(sqInt idx, sqInt srcValue, sqInt dstMask) {
    sqInt dstValue;

	dstValue = long32At(idx);
	dstValue = dstValue & dstMask;
	dstValue = dstValue | srcValue;
	long32Atput(idx, dstValue);
}


/*	Dither the given 32bit word to 16 bit. Ignore alpha. */

static sqInt expensiveDither32To16threshold(sqInt srcWord, sqInt ditherValue) {
    sqInt value;
    sqInt out;
    sqInt pv;
    sqInt threshold;

	pv = srcWord & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((usqInt) pv >> 3)];
	if (ditherValue < threshold) {
		out = value + 1;
	} else {
		out = value;
	}
	pv = (((usqInt) srcWord >> 8)) & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((usqInt) pv >> 3)];
	if (ditherValue < threshold) {
		out = out | (((usqInt) (value + 1) << 5));
	} else {
		out = out | (((usqInt) value << 5));
	}
	pv = (((usqInt) srcWord >> 16)) & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((usqInt) pv >> 3)];
	if (ditherValue < threshold) {
		out = out | (((usqInt) (value + 1) << 10));
	} else {
		out = out | (((usqInt) value << 10));
	}
	return out;
}


/*	Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers. */

static sqInt fetchIntOrFloatofObject(sqInt fieldIndex, sqInt objectPointer) {
    double  floatValue;
    sqInt fieldOop;

	fieldOop = interpreterProxy->fetchPointerofObject(fieldIndex, objectPointer);
	if ((fieldOop & 1)) {
		return (fieldOop >> 1);
	}
	floatValue = interpreterProxy->floatValueOf(fieldOop);
	if (!((-2.147483648e9 <= floatValue) && (floatValue <= 2.147483647e9))) {
		interpreterProxy->primitiveFail();
		return 0;
	}
	return ((sqInt) floatValue );
}


/*	Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers. */

static sqInt fetchIntOrFloatofObjectifNil(sqInt fieldIndex, sqInt objectPointer, sqInt defaultValue) {
    double  floatValue;
    sqInt fieldOop;

	fieldOop = interpreterProxy->fetchPointerofObject(fieldIndex, objectPointer);
	if ((fieldOop & 1)) {
		return (fieldOop >> 1);
	}
	if (fieldOop == (interpreterProxy->nilObject())) {
		return defaultValue;
	}
	floatValue = interpreterProxy->floatValueOf(fieldOop);
	if (!((-2.147483648e9 <= floatValue) && (floatValue <= 2.147483647e9))) {
		interpreterProxy->primitiveFail();
		return 0;
	}
	return ((sqInt) floatValue );
}


/*	For any non-zero pixel value in destinationWord with zero alpha channel take the alpha from sourceWord and fill it in. Intended for fixing alpha channels left at zero during 16->32 bpp conversions. */

static sqInt fixAlphawith(sqInt sourceWord, sqInt destinationWord) {
	if (!(destDepth == 32)) {
		return destinationWord;
	}
	if (destinationWord == 0) {
		return 0;
	}
	if (!((destinationWord & 4278190080U) == 0)) {
		return destinationWord;
	}
	return destinationWord | (sourceWord & 4278190080U);
}


/*	Note: This is coded so that plugins can be run from Squeak. */

static VirtualMachine * getInterpreter(void) {
	return interpreterProxy;
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}


/*	Return a value from the halftone pattern. */

static sqInt halftoneAt(sqInt idx) {
	return long32At(halftoneBase + ((idx % halftoneHeight) * 4));
}

static sqInt halt(void) {
	;
}

static sqInt ignoreSourceOrHalftone(sqInt formPointer) {
	if (formPointer == (interpreterProxy->nilObject())) {
		return 1;
	}
	if (combinationRule == 0) {
		return 1;
	}
	if (combinationRule == 5) {
		return 1;
	}
	if (combinationRule == 10) {
		return 1;
	}
	if (combinationRule == 15) {
		return 1;
	}
	return 0;
}

static sqInt initBBOpTable(void) {
	opTable[0+1] = (void *)clearWordwith;
	opTable[1+1] = (void *)bitAndwith;
	opTable[2+1] = (void *)bitAndInvertwith;
	opTable[3+1] = (void *)sourceWordwith;
	opTable[4+1] = (void *)bitInvertAndwith;
	opTable[5+1] = (void *)destinationWordwith;
	opTable[6+1] = (void *)bitXorwith;
	opTable[7+1] = (void *)bitOrwith;
	opTable[8+1] = (void *)bitInvertAndInvertwith;
	opTable[9+1] = (void *)bitInvertXorwith;
	opTable[10+1] = (void *)bitInvertDestinationwith;
	opTable[11+1] = (void *)bitOrInvertwith;
	opTable[12+1] = (void *)bitInvertSourcewith;
	opTable[13+1] = (void *)bitInvertOrwith;
	opTable[14+1] = (void *)bitInvertOrInvertwith;
	opTable[15+1] = (void *)destinationWordwith;
	opTable[16+1] = (void *)destinationWordwith;
	opTable[17+1] = (void *)destinationWordwith;
	opTable[18+1] = (void *)addWordwith;
	opTable[19+1] = (void *)subWordwith;
	opTable[20+1] = (void *)rgbAddwith;
	opTable[21+1] = (void *)rgbSubwith;
	opTable[22+1] = (void *)OLDrgbDiffwith;
	opTable[23+1] = (void *)OLDtallyIntoMapwith;
	opTable[24+1] = (void *)alphaBlendwith;
	opTable[25+1] = (void *)pixPaintwith;
	opTable[26+1] = (void *)pixMaskwith;
	opTable[27+1] = (void *)rgbMaxwith;
	opTable[28+1] = (void *)rgbMinwith;
	opTable[29+1] = (void *)rgbMinInvertwith;
	opTable[30+1] = (void *)alphaBlendConstwith;
	opTable[31+1] = (void *)alphaPaintConstwith;
	opTable[32+1] = (void *)rgbDiffwith;
	opTable[33+1] = (void *)tallyIntoMapwith;
	opTable[34+1] = (void *)alphaBlendScaledwith;
	opTable[35+1] = (void *)alphaBlendScaledwith;
	opTable[36+1] = (void *)alphaBlendScaledwith;
	opTable[37+1] = (void *)rgbMulwith;
	opTable[38+1] = (void *)pixSwapwith;
	opTable[39+1] = (void *)pixClearwith;
	opTable[40+1] = (void *)fixAlphawith;
}

static sqInt initDither8Lookup(void) {
    sqInt b;
    sqInt value;
    sqInt t;
    sqInt value1;
    sqInt out;
    sqInt pv;
    sqInt threshold;

	for (b = 0; b <= 255; b += 1) {
		for (t = 0; t <= 15; t += 1) {
			/* begin expensiveDither32To16:threshold: */
			pv = b & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((usqInt) pv >> 3)];
			if (t < threshold) {
				out = value1 + 1;
			} else {
				out = value1;
			}
			pv = (((usqInt) b >> 8)) & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((usqInt) pv >> 3)];
			if (t < threshold) {
				out = out | (((usqInt) (value1 + 1) << 5));
			} else {
				out = out | (((usqInt) value1 << 5));
			}
			pv = (((usqInt) b >> 16)) & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((usqInt) pv >> 3)];
			if (t < threshold) {
				out = out | (((usqInt) (value1 + 1) << 10));
			} else {
				out = out | (((usqInt) value1 << 10));
			}
			value = out;
			dither8Lookup[(t << 8) + b] = value;
		}
	}
}

EXPORT(sqInt) initialiseModule(void) {
	initBBOpTable();
	initDither8Lookup();
	return 1;
}


/*	Return true if shiftTable/maskTable define an identity mapping. */

static sqInt isIdentityMapwith(int * shifts, unsigned int * masks) {
	if ((shifts == null) || (masks == null)) {
		return 1;
	}
	if (((shifts[RedIndex]) == 0) && (((shifts[GreenIndex]) == 0) && (((shifts[BlueIndex]) == 0) && (((shifts[AlphaIndex]) == 0) && (((masks[RedIndex]) == 16711680) && (((masks[GreenIndex]) == 65280) && (((masks[BlueIndex]) == 255) && ((masks[AlphaIndex]) == 4278190080U)))))))) {
		return 1;
	}
	return 0;
}


/*	Load the dest form for BitBlt. Return false if anything is wrong, true otherwise. */

static sqInt loadBitBltDestForm(void) {
    sqInt destBitsSize;

	destBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, destForm);
	destWidth = interpreterProxy->fetchIntegerofObject(FormWidthIndex, destForm);
	destHeight = interpreterProxy->fetchIntegerofObject(FormHeightIndex, destForm);
	if (!((destWidth >= 0) && (destHeight >= 0))) {
		return 0;
	}
	destDepth = interpreterProxy->fetchIntegerofObject(FormDepthIndex, destForm);
	destMSB = destDepth > 0;
	if (destDepth < 0) {
		destDepth = 0 - destDepth;
	}
	if ((destBits & 1)) {
		if (!(queryDestSurface((destBits >> 1)))) {
			return 0;
		}
		destPPW = 32 / destDepth;
		destBits = destPitch = 0;
	} else {
		destPPW = 32 / destDepth;
		destPitch = ((destWidth + (destPPW - 1)) / destPPW) * 4;
		destBitsSize = interpreterProxy->byteSizeOf(destBits);
		if (!((interpreterProxy->isWordsOrBytes(destBits)) && (destBitsSize == (destPitch * destHeight)))) {
			return 0;
		}
		destBits = oopForPointer(interpreterProxy->firstIndexableField(destBits));
	}
	return 1;
}


/*	Load BitBlt from the oop.
	This function is exported for the Balloon engine. */

EXPORT(sqInt) loadBitBltFrom(sqInt bbObj) {
	return loadBitBltFromwarping(bbObj, 0);
}


/*	Load context from BitBlt instance.  Return false if anything is amiss */
/*	NOTE this should all be changed to minX/maxX coordinates for simpler clipping
		-- once it works! */

static sqInt loadBitBltFromwarping(sqInt bbObj, sqInt aBool) {
    sqInt ok;
    sqInt sourceBitsSize;
    sqInt formPointer;
    sqInt formPointer1;
    sqInt destBitsSize;
    sqInt halftoneBits;
    sqInt cmSize;
    sqInt cmOop;
    sqInt oop;
    sqInt oldStyle;
    sqInt mapOop;
    sqInt mapOop1;

	bitBltOop = bbObj;
	isWarping = aBool;
	combinationRule = interpreterProxy->fetchIntegerofObject(BBRuleIndex, bitBltOop);
	if ((interpreterProxy->failed()) || ((combinationRule < 0) || (combinationRule > (OpTableSize - 2)))) {
		return 0;
	}
	if ((combinationRule >= 16) && (combinationRule <= 17)) {
		return 0;
	}
	sourceForm = interpreterProxy->fetchPointerofObject(BBSourceFormIndex, bitBltOop);
	/* begin ignoreSourceOrHalftone: */
	formPointer = sourceForm;
	if (formPointer == (interpreterProxy->nilObject())) {
		noSource = 1;
		goto l2;
	}
	if (combinationRule == 0) {
		noSource = 1;
		goto l2;
	}
	if (combinationRule == 5) {
		noSource = 1;
		goto l2;
	}
	if (combinationRule == 10) {
		noSource = 1;
		goto l2;
	}
	if (combinationRule == 15) {
		noSource = 1;
		goto l2;
	}
	noSource = 0;
l2:	/* end ignoreSourceOrHalftone: */;
	halftoneForm = interpreterProxy->fetchPointerofObject(BBHalftoneFormIndex, bitBltOop);
	/* begin ignoreSourceOrHalftone: */
	formPointer1 = halftoneForm;
	if (formPointer1 == (interpreterProxy->nilObject())) {
		noHalftone = 1;
		goto l3;
	}
	if (combinationRule == 0) {
		noHalftone = 1;
		goto l3;
	}
	if (combinationRule == 5) {
		noHalftone = 1;
		goto l3;
	}
	if (combinationRule == 10) {
		noHalftone = 1;
		goto l3;
	}
	if (combinationRule == 15) {
		noHalftone = 1;
		goto l3;
	}
	noHalftone = 0;
l3:	/* end ignoreSourceOrHalftone: */;
	destForm = interpreterProxy->fetchPointerofObject(BBDestFormIndex, bbObj);
	if (!((interpreterProxy->isPointers(destForm)) && ((interpreterProxy->slotSizeOf(destForm)) >= 4))) {
		return 0;
	}
	/* begin loadBitBltDestForm */
	destBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, destForm);
	destWidth = interpreterProxy->fetchIntegerofObject(FormWidthIndex, destForm);
	destHeight = interpreterProxy->fetchIntegerofObject(FormHeightIndex, destForm);
	if (!((destWidth >= 0) && (destHeight >= 0))) {
		ok = 0;
		goto l4;
	}
	destDepth = interpreterProxy->fetchIntegerofObject(FormDepthIndex, destForm);
	destMSB = destDepth > 0;
	if (destDepth < 0) {
		destDepth = 0 - destDepth;
	}
	if ((destBits & 1)) {
		if (!(queryDestSurface((destBits >> 1)))) {
			ok = 0;
			goto l4;
		}
		destPPW = 32 / destDepth;
		destBits = destPitch = 0;
	} else {
		destPPW = 32 / destDepth;
		destPitch = ((destWidth + (destPPW - 1)) / destPPW) * 4;
		destBitsSize = interpreterProxy->byteSizeOf(destBits);
		if (!((interpreterProxy->isWordsOrBytes(destBits)) && (destBitsSize == (destPitch * destHeight)))) {
			ok = 0;
			goto l4;
		}
		destBits = oopForPointer(interpreterProxy->firstIndexableField(destBits));
	}
	ok = 1;
l4:	/* end loadBitBltDestForm */;
	if (!(ok)) {
		return 0;
	}
	destX = fetchIntOrFloatofObjectifNil(BBDestXIndex, bitBltOop, 0);
	destY = fetchIntOrFloatofObjectifNil(BBDestYIndex, bitBltOop, 0);
	width = fetchIntOrFloatofObjectifNil(BBWidthIndex, bitBltOop, destWidth);
	height = fetchIntOrFloatofObjectifNil(BBHeightIndex, bitBltOop, destHeight);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (noSource) {
		sourceX = sourceY = 0;
	} else {
		if (!((interpreterProxy->isPointers(sourceForm)) && ((interpreterProxy->slotSizeOf(sourceForm)) >= 4))) {
			return 0;
		}
		/* begin loadBitBltSourceForm */
		sourceBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, sourceForm);
		sourceWidth = fetchIntOrFloatofObject(FormWidthIndex, sourceForm);
		sourceHeight = fetchIntOrFloatofObject(FormHeightIndex, sourceForm);
		if (!((sourceWidth >= 0) && (sourceHeight >= 0))) {
			ok = 0;
			goto l1;
		}
		sourceDepth = interpreterProxy->fetchIntegerofObject(FormDepthIndex, sourceForm);
		sourceMSB = sourceDepth > 0;
		if (sourceDepth < 0) {
			sourceDepth = 0 - sourceDepth;
		}
		if ((sourceBits & 1)) {
			if (!(querySourceSurface((sourceBits >> 1)))) {
				ok = 0;
				goto l1;
			}
			sourcePPW = 32 / sourceDepth;
			sourceBits = sourcePitch = 0;
		} else {
			sourcePPW = 32 / sourceDepth;
			sourcePitch = ((sourceWidth + (sourcePPW - 1)) / sourcePPW) * 4;
			sourceBitsSize = interpreterProxy->byteSizeOf(sourceBits);
			if (!((interpreterProxy->isWordsOrBytes(sourceBits)) && (sourceBitsSize == (sourcePitch * sourceHeight)))) {
				ok = 0;
				goto l1;
			}
			sourceBits = oopForPointer(interpreterProxy->firstIndexableField(sourceBits));
		}
		ok = 1;
	l1:	/* end loadBitBltSourceForm */;
		if (!(ok)) {
			return 0;
		}
		/* begin loadColorMap */
		cmFlags = cmMask = cmBitsPerColor = 0;
		cmShiftTable = null;
		cmMaskTable = null;
		cmLookupTable = null;
		cmOop = interpreterProxy->fetchPointerofObject(BBColorMapIndex, bitBltOop);
		if (cmOop == (interpreterProxy->nilObject())) {
			ok = 1;
			goto l8;
		}
		cmFlags = ColorMapPresent;
		oldStyle = 0;
		if (interpreterProxy->isWords(cmOop)) {
			cmSize = interpreterProxy->slotSizeOf(cmOop);
			cmLookupTable = interpreterProxy->firstIndexableField(cmOop);
			oldStyle = 1;
		} else {
			if (!((interpreterProxy->isPointers(cmOop)) && ((interpreterProxy->slotSizeOf(cmOop)) >= 3))) {
				ok = 0;
				goto l8;
			}
			/* begin loadColorMapShiftOrMaskFrom: */
			mapOop = interpreterProxy->fetchPointerofObject(0, cmOop);
			if (mapOop == (interpreterProxy->nilObject())) {
				cmShiftTable = null;
				goto l6;
			}
			if ((mapOop & 1)) {
				interpreterProxy->primitiveFail();
				cmShiftTable = null;
				goto l6;
			}
			if (!((interpreterProxy->isWords(mapOop)) && ((interpreterProxy->slotSizeOf(mapOop)) == 4))) {
				interpreterProxy->primitiveFail();
				cmShiftTable = null;
				goto l6;
			}
			cmShiftTable = interpreterProxy->firstIndexableField(mapOop);
		l6:	/* end loadColorMapShiftOrMaskFrom: */;
			/* begin loadColorMapShiftOrMaskFrom: */
			mapOop1 = interpreterProxy->fetchPointerofObject(1, cmOop);
			if (mapOop1 == (interpreterProxy->nilObject())) {
				cmMaskTable = null;
				goto l7;
			}
			if ((mapOop1 & 1)) {
				interpreterProxy->primitiveFail();
				cmMaskTable = null;
				goto l7;
			}
			if (!((interpreterProxy->isWords(mapOop1)) && ((interpreterProxy->slotSizeOf(mapOop1)) == 4))) {
				interpreterProxy->primitiveFail();
				cmMaskTable = null;
				goto l7;
			}
			cmMaskTable = interpreterProxy->firstIndexableField(mapOop1);
		l7:	/* end loadColorMapShiftOrMaskFrom: */;
			oop = interpreterProxy->fetchPointerofObject(2, cmOop);
			if (oop == (interpreterProxy->nilObject())) {
				cmSize = 0;
			} else {
				if (!(interpreterProxy->isWords(oop))) {
					ok = 0;
					goto l8;
				}
				cmSize = interpreterProxy->slotSizeOf(oop);
				cmLookupTable = interpreterProxy->firstIndexableField(oop);
			}
			cmFlags = cmFlags | ColorMapNewStyle;
		}
		if (!((cmSize & (cmSize - 1)) == 0)) {
			ok = 0;
			goto l8;
		}
		cmMask = cmSize - 1;
		cmBitsPerColor = 0;
		if (cmSize == 512) {
			cmBitsPerColor = 3;
		}
		if (cmSize == 4096) {
			cmBitsPerColor = 4;
		}
		if (cmSize == 32768) {
			cmBitsPerColor = 5;
		}
		if (cmSize == 0) {
			cmLookupTable = null;
			cmMask = 0;
		} else {
			cmFlags = cmFlags | ColorMapIndexedPart;
		}
		if (oldStyle) {
			setupColorMasks();
		}
		if (isIdentityMapwith(cmShiftTable, cmMaskTable)) {
			cmMaskTable = null;
			cmShiftTable = null;
		} else {
			cmFlags = cmFlags | ColorMapFixedPart;
		}
		ok = 1;
	l8:	/* end loadColorMap */;
		if (!(ok)) {
			return 0;
		}
		if ((cmFlags & ColorMapNewStyle) == 0) {
			setupColorMasks();
		}
		sourceX = fetchIntOrFloatofObjectifNil(BBSourceXIndex, bitBltOop, 0);
		sourceY = fetchIntOrFloatofObjectifNil(BBSourceYIndex, bitBltOop, 0);
	}
	/* begin loadHalftoneForm */
	if (noHalftone) {
		halftoneBase = null;
		ok = 1;
		goto l5;
	}
	if ((interpreterProxy->isPointers(halftoneForm)) && ((interpreterProxy->slotSizeOf(halftoneForm)) >= 4)) {
		halftoneBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, halftoneForm);
		halftoneHeight = interpreterProxy->fetchIntegerofObject(FormHeightIndex, halftoneForm);
		if (!(interpreterProxy->isWords(halftoneBits))) {
			noHalftone = 1;
		}
	} else {
		if (!((!(interpreterProxy->isPointers(halftoneForm))) && (interpreterProxy->isWords(halftoneForm)))) {
			ok = 0;
			goto l5;
		}
		halftoneBits = halftoneForm;
		halftoneHeight = interpreterProxy->slotSizeOf(halftoneBits);
	}
	halftoneBase = oopForPointer(interpreterProxy->firstIndexableField(halftoneBits));
	ok = 1;
l5:	/* end loadHalftoneForm */;
	if (!(ok)) {
		return 0;
	}
	clipX = fetchIntOrFloatofObjectifNil(BBClipXIndex, bitBltOop, 0);
	clipY = fetchIntOrFloatofObjectifNil(BBClipYIndex, bitBltOop, 0);
	clipWidth = fetchIntOrFloatofObjectifNil(BBClipWidthIndex, bitBltOop, destWidth);
	clipHeight = fetchIntOrFloatofObjectifNil(BBClipHeightIndex, bitBltOop, destHeight);
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (clipX < 0) {
		clipWidth += clipX;
		clipX = 0;
	}
	if (clipY < 0) {
		clipHeight += clipY;
		clipY = 0;
	}
	if ((clipX + clipWidth) > destWidth) {
		clipWidth = destWidth - clipX;
	}
	if ((clipY + clipHeight) > destHeight) {
		clipHeight = destHeight - clipY;
	}
	return 1;
}


/*	Load the source form for BitBlt. Return false if anything is wrong, true otherwise. */

static sqInt loadBitBltSourceForm(void) {
    sqInt sourceBitsSize;

	sourceBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, sourceForm);
	sourceWidth = fetchIntOrFloatofObject(FormWidthIndex, sourceForm);
	sourceHeight = fetchIntOrFloatofObject(FormHeightIndex, sourceForm);
	if (!((sourceWidth >= 0) && (sourceHeight >= 0))) {
		return 0;
	}
	sourceDepth = interpreterProxy->fetchIntegerofObject(FormDepthIndex, sourceForm);
	sourceMSB = sourceDepth > 0;
	if (sourceDepth < 0) {
		sourceDepth = 0 - sourceDepth;
	}
	if ((sourceBits & 1)) {
		if (!(querySourceSurface((sourceBits >> 1)))) {
			return 0;
		}
		sourcePPW = 32 / sourceDepth;
		sourceBits = sourcePitch = 0;
	} else {
		sourcePPW = 32 / sourceDepth;
		sourcePitch = ((sourceWidth + (sourcePPW - 1)) / sourcePPW) * 4;
		sourceBitsSize = interpreterProxy->byteSizeOf(sourceBits);
		if (!((interpreterProxy->isWordsOrBytes(sourceBits)) && (sourceBitsSize == (sourcePitch * sourceHeight)))) {
			return 0;
		}
		sourceBits = oopForPointer(interpreterProxy->firstIndexableField(sourceBits));
	}
	return 1;
}


/*	ColorMap, if not nil, must be longWords, and 
	2^N long, where N = sourceDepth for 1, 2, 4, 8 bits, 
	or N = 9, 12, or 15 (3, 4, 5 bits per color) for 16 or 32 bits. */

static sqInt loadColorMap(void) {
    sqInt cmSize;
    sqInt cmOop;
    sqInt oop;
    sqInt oldStyle;
    sqInt mapOop;
    sqInt mapOop1;

	cmFlags = cmMask = cmBitsPerColor = 0;
	cmShiftTable = null;
	cmMaskTable = null;
	cmLookupTable = null;
	cmOop = interpreterProxy->fetchPointerofObject(BBColorMapIndex, bitBltOop);
	if (cmOop == (interpreterProxy->nilObject())) {
		return 1;
	}

	/* even if identity or somesuch - may be cleared later */

	cmFlags = ColorMapPresent;
	oldStyle = 0;
	if (interpreterProxy->isWords(cmOop)) {
		cmSize = interpreterProxy->slotSizeOf(cmOop);
		cmLookupTable = interpreterProxy->firstIndexableField(cmOop);
		oldStyle = 1;
	} else {
		if (!((interpreterProxy->isPointers(cmOop)) && ((interpreterProxy->slotSizeOf(cmOop)) >= 3))) {
			return 0;
		}
		/* begin loadColorMapShiftOrMaskFrom: */
		mapOop = interpreterProxy->fetchPointerofObject(0, cmOop);
		if (mapOop == (interpreterProxy->nilObject())) {
			cmShiftTable = null;
			goto l1;
		}
		if ((mapOop & 1)) {
			interpreterProxy->primitiveFail();
			cmShiftTable = null;
			goto l1;
		}
		if (!((interpreterProxy->isWords(mapOop)) && ((interpreterProxy->slotSizeOf(mapOop)) == 4))) {
			interpreterProxy->primitiveFail();
			cmShiftTable = null;
			goto l1;
		}
		cmShiftTable = interpreterProxy->firstIndexableField(mapOop);
	l1:	/* end loadColorMapShiftOrMaskFrom: */;
		/* begin loadColorMapShiftOrMaskFrom: */
		mapOop1 = interpreterProxy->fetchPointerofObject(1, cmOop);
		if (mapOop1 == (interpreterProxy->nilObject())) {
			cmMaskTable = null;
			goto l2;
		}
		if ((mapOop1 & 1)) {
			interpreterProxy->primitiveFail();
			cmMaskTable = null;
			goto l2;
		}
		if (!((interpreterProxy->isWords(mapOop1)) && ((interpreterProxy->slotSizeOf(mapOop1)) == 4))) {
			interpreterProxy->primitiveFail();
			cmMaskTable = null;
			goto l2;
		}
		cmMaskTable = interpreterProxy->firstIndexableField(mapOop1);
	l2:	/* end loadColorMapShiftOrMaskFrom: */;
		oop = interpreterProxy->fetchPointerofObject(2, cmOop);
		if (oop == (interpreterProxy->nilObject())) {
			cmSize = 0;
		} else {
			if (!(interpreterProxy->isWords(oop))) {
				return 0;
			}
			cmSize = interpreterProxy->slotSizeOf(oop);
			cmLookupTable = interpreterProxy->firstIndexableField(oop);
		}
		cmFlags = cmFlags | ColorMapNewStyle;
	}
	if (!((cmSize & (cmSize - 1)) == 0)) {
		return 0;
	}
	cmMask = cmSize - 1;
	cmBitsPerColor = 0;
	if (cmSize == 512) {
		cmBitsPerColor = 3;
	}
	if (cmSize == 4096) {
		cmBitsPerColor = 4;
	}
	if (cmSize == 32768) {
		cmBitsPerColor = 5;
	}
	if (cmSize == 0) {
		cmLookupTable = null;
		cmMask = 0;
	} else {
		cmFlags = cmFlags | ColorMapIndexedPart;
	}
	if (oldStyle) {
		setupColorMasks();
	}
	if (isIdentityMapwith(cmShiftTable, cmMaskTable)) {
		cmMaskTable = null;
		cmShiftTable = null;
	} else {
		cmFlags = cmFlags | ColorMapFixedPart;
	}
	return 1;
}

static void * loadColorMapShiftOrMaskFrom(sqInt mapOop) {
	if (mapOop == (interpreterProxy->nilObject())) {
		return null;
	}
	if ((mapOop & 1)) {
		interpreterProxy->primitiveFail();
		return null;
	}
	if (!((interpreterProxy->isWords(mapOop)) && ((interpreterProxy->slotSizeOf(mapOop)) == 4))) {
		interpreterProxy->primitiveFail();
		return null;
	}
	return interpreterProxy->firstIndexableField(mapOop);
}


/*	Load the halftone form */

static sqInt loadHalftoneForm(void) {
    sqInt halftoneBits;

	if (noHalftone) {
		halftoneBase = null;
		return 1;
	}
	if ((interpreterProxy->isPointers(halftoneForm)) && ((interpreterProxy->slotSizeOf(halftoneForm)) >= 4)) {
		halftoneBits = interpreterProxy->fetchPointerofObject(FormBitsIndex, halftoneForm);
		halftoneHeight = interpreterProxy->fetchIntegerofObject(FormHeightIndex, halftoneForm);
		if (!(interpreterProxy->isWords(halftoneBits))) {
			noHalftone = 1;
		}
	} else {
		if (!((!(interpreterProxy->isPointers(halftoneForm))) && (interpreterProxy->isWords(halftoneForm)))) {
			return 0;
		}
		halftoneBits = halftoneForm;
		halftoneHeight = interpreterProxy->slotSizeOf(halftoneBits);
	}
	halftoneBase = oopForPointer(interpreterProxy->firstIndexableField(halftoneBits));
	return 1;
}


/*	Load the surface support plugin */

static sqInt loadSurfacePlugin(void) {
	querySurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioGetSurfaceFormat", "SurfacePlugin");
	lockSurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioLockSurface", "SurfacePlugin");
	unlockSurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioUnlockSurface", "SurfacePlugin");
	return (querySurfaceFn != 0) && ((lockSurfaceFn != 0) && (unlockSurfaceFn != 0));
}

static sqInt loadWarpBltFrom(sqInt bbObj) {
	return loadBitBltFromwarping(bbObj, 1);
}


/*	Get a pointer to the bits of any OS surfaces. */
/*	Notes: 
	* For equal source/dest handles only one locking operation is performed.
	This is to prevent locking of overlapping areas which does not work with
	certain APIs (as an example, DirectDraw prevents locking of overlapping areas). 
	A special case for non-overlapping but equal source/dest handle would 
	be possible but we would have to transfer this information over to 
	unlockSurfaces somehow (currently, only one unlock operation is 
	performed for equal source and dest handles). Also, this would require
	a change in the notion of ioLockSurface() which is right now interpreted
	as a hint and not as a requirement to lock only the specific portion of
	the surface.

	* The arguments in ioLockSurface() provide the implementation with
	an explicit hint what area is affected. It can be very useful to
	know the max. affected area beforehand if getting the bits requires expensive
	copy operations (e.g., like a roundtrip to the X server or a glReadPixel op).
	However, the returned pointer *MUST* point to the virtual origin of the surface
	and not to the beginning of the rectangle. The promise made by BitBlt
	is to never access data outside the given rectangle (aligned to 4byte boundaries!)
	so it is okay to return a pointer to the virtual origin that is actually outside
	the valid memory area.

	* The area provided in ioLockSurface() is already clipped (e.g., it will always
	be inside the source and dest boundingBox) but it is not aligned to word boundaries
	yet. It is up to the support code to compute accurate alignment if necessary.

	* Warping always requires the entire source surface to be locked because
	there is no beforehand knowledge about what area will actually be traversed.

	 */

static sqInt lockSurfaces(void) {
    sqInt sourceHandle;
    sqInt l;
    sqInt b;
    sqInt destHandle;
    sqInt r;
    sqInt (*fn)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt);
    sqInt t;

	hasSurfaceLock = 0;
	if (destBits == 0) {
		if (lockSurfaceFn == 0) {
			if (!(loadSurfacePlugin())) {
				return null;
			}
		}
		fn = ((sqInt (*)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt)) lockSurfaceFn);
		destHandle = interpreterProxy->fetchIntegerofObject(FormBitsIndex, destForm);
		if ((sourceBits == 0) && (!noSource)) {

			/* Handle the special case of equal source and dest handles */

			sourceHandle = interpreterProxy->fetchIntegerofObject(FormBitsIndex, sourceForm);
			if (sourceHandle == destHandle) {
				if (isWarping) {
					l = ((sx < dx) ? sx : dx);
					r = (((sx < dx) ? dx : sx)) + bbW;
					t = ((sy < dy) ? sy : dy);
					b = (((sy < sy) ? sy : sy)) + bbH;
					sourceBits = fn(sourceHandle, &sourcePitch, l, t, r-l, b-t);
				} else {
					sourceBits = fn(sourceHandle, &sourcePitch, 0,0, sourceWidth, sourceHeight);
				}
				destBits = sourceBits;
				destPitch = sourcePitch;
				hasSurfaceLock = 1;
				return destBits != 0;
			}
		}
		destBits = fn(destHandle, &destPitch, dx, dy, bbW, bbH);
		hasSurfaceLock = 1;
	}
	if ((sourceBits == 0) && (!noSource)) {
		sourceHandle = interpreterProxy->fetchIntegerofObject(FormBitsIndex, sourceForm);
		if (lockSurfaceFn == 0) {
			if (!(loadSurfacePlugin())) {
				return null;
			}
		}

		/* Warping requiring the entire surface */

		fn = ((sqInt (*)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt)) lockSurfaceFn);
		if (isWarping) {
			sourceBits = fn(sourceHandle, &sourcePitch, 0, 0, sourceWidth, sourceHeight);
		} else {
			sourceBits = fn(sourceHandle, &sourcePitch, sx, sy, bbW, bbH);
		}
		hasSurfaceLock = 1;
	}
	return (destBits != 0) && ((sourceBits != 0) || (noSource));
}


/*	Color map the given source pixel. */

static sqInt mapPixelflags(sqInt sourcePixel, sqInt mapperFlags) {
    sqInt pv;
    sqInt val;

	pv = sourcePixel;
	if ((mapperFlags & ColorMapPresent) != 0) {
		if ((mapperFlags & ColorMapFixedPart) != 0) {
			/* begin rgbMapPixel:flags: */
			val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePixel & (cmMaskTable[0])) << (cmShiftTable[0])));
			val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePixel & (cmMaskTable[1])) << (cmShiftTable[1]))));
			val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePixel & (cmMaskTable[2])) << (cmShiftTable[2]))));
			pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePixel & (cmMaskTable[3])) << (cmShiftTable[3]))));
			if ((pv == 0) && (sourcePixel != 0)) {
				pv = 1;
			}
		}
		if ((mapperFlags & ColorMapIndexedPart) != 0) {
			pv = cmLookupTable[pv & cmMask];
		}
	}
	return pv;
}


/*	Sender warpLoop is too big to include this in-line */

static sqInt mergewith(sqInt sourceWord, sqInt destinationWord) {
    sqInt (*mergeFnwith)(sqInt, sqInt);

	mergeFnwith = ((sqInt (*)(sqInt, sqInt)) (opTable[combinationRule + 1]));
	mergeFnwith;
	return mergeFnwith(sourceWord, destinationWord);
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(sqInt) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SurfacePlugin")) == 0) {
		querySurfaceFn = lockSurfaceFn = unlockSurfaceFn = 0;
	}
}

static sqInt msg(char * s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	AND word1 to word2 as nParts partitions of nBits each.
	Any field of word1 not all-ones is treated as all-zeroes.
	Used for erasing, eg, brush shapes prior to ORing in a color */

static sqInt partitionedANDtonBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt result;
    sqInt i;
    sqInt mask;


	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= nParts; i += 1) {
		if ((word1 & mask) == mask) {
			result = result | (word2 & mask);
		}

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}


/*	Add word1 to word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors */

static sqInt partitionedAddtonBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt sum;
    sqInt result;
    sqInt i;
    sqInt mask;


	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= nParts; i += 1) {
		sum = (word1 & mask) + (word2 & mask);
		if (sum <= mask) {
			result = result | sum;
		} else {
			result = result | mask;
		}

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}


/*	Max word1 to word2 as nParts partitions of nBits each */

static sqInt partitionedMaxwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt result;
    sqInt i;
    sqInt mask;


	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= nParts; i += 1) {
		result = result | ((((word2 & mask) < (word1 & mask)) ? (word1 & mask) : (word2 & mask)));

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}


/*	Min word1 to word2 as nParts partitions of nBits each */

static sqInt partitionedMinwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt result;
    sqInt i;
    sqInt mask;


	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= nParts; i += 1) {
		result = result | ((((word2 & mask) < (word1 & mask)) ? (word2 & mask) : (word1 & mask)));

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}


/*	Multiply word1 with word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors.
	Bug in loop version when non-white background */

static sqInt partitionedMulwithnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt result;
    sqInt sMask;
    sqInt product;
    sqInt dMask;


	/* partition mask starts at the right */

	sMask = maskTable[nBits];
	dMask = sMask << nBits;

	/* optimized first step */

	result = ((usqInt) (((((word1 & sMask) + 1) * ((word2 & sMask) + 1)) - 1) & dMask)) >> nBits;
	product = (((((((usqInt) word1) >> nBits) & sMask) + 1) * (((((usqInt) word2) >> nBits) & sMask) + 1)) - 1) & dMask;
	result = result | (product & dMask);
	product = (((((((usqInt) word1) >> (2 * nBits)) & sMask) + 1) * (((((usqInt) word2) >> (2 * nBits)) & sMask) + 1)) - 1) & dMask;
	result = result | ((product & dMask) << nBits);
	return result;
}


/*	Subtract word1 from word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors */

static sqInt partitionedSubfromnBitsnPartitions(sqInt word1, sqInt word2, sqInt nBits, sqInt nParts) {
    sqInt result;
    sqInt p1;
    sqInt i;
    sqInt mask;
    sqInt p2;


	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= nParts; i += 1) {
		p1 = word1 & mask;
		p2 = word2 & mask;
		if (p1 < p2) {
			result = result | (p2 - p1);
		} else {
			result = result | (p1 - p2);
		}

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}


/*	Based on the values provided during setup choose and
	perform the appropriate inner loop function. */

static sqInt performCopyLoop(void) {
    sqInt dxLowBits;
    sqInt pixPerM1;
    sqInt sxLowBits;
    sqInt dWid;
    sqInt t;
    sqInt endBits;
    sqInt pixPerM11;
    sqInt startBits;

	/* begin destMaskAndPointerInit */
	pixPerM11 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM11);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM11) / destPPW) + 1;
	}
	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	if (noSource) {
		copyLoopNoSource();
	} else {
		/* begin checkSourceOverlap */
		if ((sourceForm == destForm) && (dy >= sy)) {
			if (dy > sy) {
				vDir = -1;
				sy = (sy + bbH) - 1;
				dy = (dy + bbH) - 1;
			} else {
				if ((dy == sy) && (dx > sx)) {
					hDir = -1;
					sx = (sx + bbW) - 1;
					dx = (dx + bbW) - 1;
					if (nWords > 1) {
						t = mask1;
						mask1 = mask2;
						mask2 = t;
					}
				}
			}
			destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
			destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
		}
		if ((sourceDepth != destDepth) || ((cmFlags != 0) || (sourceMSB != destMSB))) {
			copyLoopPixMap();
		} else {
			/* begin sourceSkewAndPointerInit */
			pixPerM1 = destPPW - 1;
			sxLowBits = sx & pixPerM1;
			dxLowBits = dx & pixPerM1;
			if (hDir > 0) {
				dWid = ((bbW < (destPPW - dxLowBits)) ? bbW : (destPPW - dxLowBits));
				preload = (sxLowBits + dWid) > pixPerM1;
			} else {
				dWid = ((bbW < (dxLowBits + 1)) ? bbW : (dxLowBits + 1));
				preload = ((sxLowBits - dWid) + 1) < 0;
			}
			if (sourceMSB) {
				skew = (sxLowBits - dxLowBits) * destDepth;
			} else {
				skew = (dxLowBits - sxLowBits) * destDepth;
			}
			if (preload) {
				if (skew < 0) {
					skew += 32;
				} else {
					skew -= 32;
				}
			}
			sourceIndex = (sourceBits + (sy * sourcePitch)) + ((sx / (32 / sourceDepth)) * 4);
			sourceDelta = (sourcePitch * vDir) - (4 * (nWords * hDir));
			if (preload) {
				sourceDelta -= 4 * hDir;
			}
			copyLoop();
		}
	}
}


/*	Pick nPix pixels starting at srcBitIndex from the source, map by the
	color map, and justify them according to dstBitIndex in the resulting destWord. */

static sqInt pickSourcePixelsflagssrcMaskdestMasksrcShiftIncdstShiftInc(sqInt nPixels, sqInt mapperFlags, sqInt srcMask, sqInt dstMask, sqInt srcShiftInc, sqInt dstShiftInc) {
    sqInt nPix;
    sqInt sourcePix;
    sqInt srcShift;
    sqInt sourceWord;
    sqInt dstShift;
    sqInt destWord;
    sqInt destPix;
    sqInt idx;
    sqInt idx1;
    sqInt idx2;
    sqInt pv;
    sqInt val;

	/* begin srcLongAt: */
	idx2 = sourceIndex;
	sourceWord = long32At(idx2);
	destWord = 0;

	/* Hint: Keep in register */

	srcShift = srcBitShift;

	/* Hint: Keep in register */

	dstShift = dstBitShift;

	/* always > 0 so we can use do { } while(--nPix); */

	nPix = nPixels;
	if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
		do {
			sourcePix = (((usqInt) sourceWord) >> srcShift) & srcMask;
			destPix = tableLookupat(cmLookupTable, sourcePix & cmMask);

			/* adjust dest pix index */

			destWord = destWord | ((destPix & dstMask) << dstShift);

			/* adjust source pix index */

			dstShift += dstShiftInc;
			if (!(((srcShift += srcShiftInc) & 4294967264U) == 0)) {
				if (sourceMSB) {
					srcShift += 32;
				} else {
					srcShift -= 32;
				}
				/* begin srcLongAt: */
				idx = sourceIndex += 4;
				sourceWord = long32At(idx);
			}
		} while(!((nPix -= 1) == 0));
	} else {
		do {
			sourcePix = (((usqInt) sourceWord) >> srcShift) & srcMask;
			/* begin mapPixel:flags: */
			pv = sourcePix;
			if ((mapperFlags & ColorMapPresent) != 0) {
				if ((mapperFlags & ColorMapFixedPart) != 0) {
					/* begin rgbMapPixel:flags: */
					val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
					if ((pv == 0) && (sourcePix != 0)) {
						pv = 1;
					}
				}
				if ((mapperFlags & ColorMapIndexedPart) != 0) {
					pv = cmLookupTable[pv & cmMask];
				}
			}
			destPix = pv;

			/* adjust dest pix index */

			destWord = destWord | ((destPix & dstMask) << dstShift);

			/* adjust source pix index */

			dstShift += dstShiftInc;
			if (!(((srcShift += srcShiftInc) & 4294967264U) == 0)) {
				if (sourceMSB) {
					srcShift += 32;
				} else {
					srcShift -= 32;
				}
				/* begin srcLongAt: */
				idx1 = sourceIndex += 4;
				sourceWord = long32At(idx1);
			}
		} while(!((nPix -= 1) == 0));
	}

	/* Store back */

	srcBitShift = srcShift;
	return destWord;
}


/*	Pick a single pixel from the source for WarpBlt.
	Note: This method is crucial for WarpBlt speed w/o smoothing
	and still relatively important when smoothing is used. */

static sqInt pickWarpPixelAtXy(sqInt xx, sqInt yy) {
    sqInt sourcePix;
    sqInt x;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt y;

	if ((xx < 0) || ((yy < 0) || (((x = ((usqInt) xx) >> BinaryPoint) >= sourceWidth) || ((y = ((usqInt) yy) >> BinaryPoint) >= sourceHeight)))) {
		return 0;
	}
	srcIndex = (sourceBits + (y * sourcePitch)) + ((((usqInt) x) >> warpAlignShift) * 4);

	/* Extract pixel from word */

	sourceWord = long32At(srcIndex);
	srcBitShift = warpBitShiftTable[x & warpAlignMask];
	sourcePix = (((usqInt) sourceWord) >> srcBitShift) & warpSrcMask;
	return sourcePix;
}


/*	Clear all pixels in destinationWord for which the pixels of sourceWord have the same values. Used to clear areas of some constant color to zero. */

static sqInt pixClearwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt result;
    sqInt nBits;
    sqInt pv;
    sqInt i;
    sqInt mask;

	if (destDepth == 32) {
		if (sourceWord == destinationWord) {
			return 0;
		} else {
			return destinationWord;
		}
	}
	nBits = destDepth;

	/* partition mask starts at the right */

	mask = maskTable[nBits];
	result = 0;
	for (i = 1; i <= destPPW; i += 1) {
		pv = destinationWord & mask;
		if ((sourceWord & mask) == pv) {
			pv = 0;
		}
		result = result | pv;

		/* slide left to next partition */

		mask = mask << nBits;
	}
	return result;
}

static sqInt pixMaskwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt result;
    sqInt i;
    sqInt mask;

	/* begin partitionedAND:to:nBits:nPartitions: */
	mask = maskTable[destDepth];
	result = 0;
	for (i = 1; i <= destPPW; i += 1) {
		if (((~sourceWord) & mask) == mask) {
			result = result | (destinationWord & mask);
		}
		mask = mask << destDepth;
	}
	return result;
}

static sqInt pixPaintwith(sqInt sourceWord, sqInt destinationWord) {
	if (sourceWord == 0) {
		return destinationWord;
	}
	return sourceWord | (partitionedANDtonBitsnPartitions(~sourceWord, destinationWord, destDepth, destPPW));
}


/*	Swap the pixels in destWord */

static sqInt pixSwapwith(sqInt sourceWord, sqInt destWord) {
    sqInt lowMask;
    sqInt result;
    sqInt shift;
    sqInt i;
    sqInt highMask;

	if (destPPW == 1) {
		return destWord;
	}
	result = 0;

	/* mask low pixel */

	lowMask = (1 << destDepth) - 1;

	/* mask high pixel */

	highMask = lowMask << ((destPPW - 1) * destDepth);
	shift = 32 - destDepth;
	result = result | (((destWord & lowMask) << shift) | (((usqInt) (destWord & highMask)) >> shift));
	if (destPPW <= 2) {
		return result;
	}
	for (i = 2; i <= (((sqInt) destPPW >> 1)); i += 1) {
		lowMask = lowMask << destDepth;
		highMask = ((usqInt) highMask) >> destDepth;
		shift -= destDepth * 2;
		result = result | (((destWord & lowMask) << shift) | (((usqInt) (destWord & highMask)) >> shift));
	}
	return result;
}


/*	Invoke the copyBits primitive. If the destination is the display, then copy it to the screen. */

EXPORT(sqInt) primitiveCopyBits(void) {
    sqInt rcvr;

	rcvr = interpreterProxy->stackValue(interpreterProxy->methodArgumentCount());
	if (!(loadBitBltFromwarping(rcvr, 0))) {
		return interpreterProxy->primitiveFail();
	}
	copyBits();
	if (interpreterProxy->failed()) {
		return null;
	}
	/* begin showDisplayBits */
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(interpreterProxy->methodArgumentCount());
	if ((combinationRule == 22) || (combinationRule == 32)) {
		interpreterProxy->pop(1);
		return interpreterProxy->pushInteger(bitCount);
	}
}

EXPORT(sqInt) primitiveDisplayString(void) {
    sqInt maxGlyph;
    sqInt glyphMap;
    char * sourcePtr;
    sqInt charIndex;
    sqInt sourceString;
    sqInt quickBlt;
    sqInt stopIndex;
    sqInt left;
    sqInt bbObj;
    sqInt startIndex;
    sqInt glyphIndex;
    sqInt kernDelta;
    sqInt ascii;
    sqInt xTable;
    sqInt endBits;
    sqInt pixPerM1;
    sqInt startBits;

	if (!((interpreterProxy->methodArgumentCount()) == 6)) {
		return interpreterProxy->primitiveFail();
	}
	kernDelta = interpreterProxy->stackIntegerValue(0);
	xTable = interpreterProxy->stackObjectValue(1);
	glyphMap = interpreterProxy->stackObjectValue(2);
	if (!(((interpreterProxy->fetchClassOf(xTable)) == (interpreterProxy->classArray())) && ((interpreterProxy->fetchClassOf(glyphMap)) == (interpreterProxy->classArray())))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->slotSizeOf(glyphMap)) == 256)) {
		return interpreterProxy->primitiveFail();
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	maxGlyph = (interpreterProxy->slotSizeOf(xTable)) - 2;
	stopIndex = interpreterProxy->stackIntegerValue(3);
	startIndex = interpreterProxy->stackIntegerValue(4);
	sourceString = interpreterProxy->stackObjectValue(5);
	if (!(interpreterProxy->isBytes(sourceString))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((startIndex > 0) && ((stopIndex > 0) && (stopIndex <= (interpreterProxy->byteSizeOf(sourceString)))))) {
		return interpreterProxy->primitiveFail();
	}
	bbObj = interpreterProxy->stackObjectValue(6);
	if (!(loadBitBltFromwarping(bbObj, 0))) {
		return interpreterProxy->primitiveFail();
	}
	if ((combinationRule == 30) || (combinationRule == 31)) {
		return interpreterProxy->primitiveFail();
	}
	quickBlt = (destBits != 0) && ((sourceBits != 0) && ((noSource == 0) && ((sourceForm != destForm) && ((cmFlags != 0) || ((sourceMSB != destMSB) || (sourceDepth != destDepth))))));
	left = destX;
	sourcePtr = interpreterProxy->firstIndexableField(sourceString);
	for (charIndex = startIndex; charIndex <= stopIndex; charIndex += 1) {
		ascii = byteAtPointer((sourcePtr + charIndex) - 1);
		glyphIndex = interpreterProxy->fetchIntegerofObject(ascii, glyphMap);
		if ((glyphIndex < 0) || (glyphIndex > maxGlyph)) {
			return interpreterProxy->primitiveFail();
		}
		sourceX = interpreterProxy->fetchIntegerofObject(glyphIndex, xTable);
		width = (interpreterProxy->fetchIntegerofObject(glyphIndex + 1, xTable)) - sourceX;
		if (interpreterProxy->failed()) {
			return null;
		}
		clipRange();
		if ((bbW > 0) && (bbH > 0)) {
			if (quickBlt) {
				/* begin destMaskAndPointerInit */
				pixPerM1 = destPPW - 1;
				startBits = destPPW - (dx & pixPerM1);
				if (destMSB) {
					mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
				} else {
					mask1 = AllOnes << (32 - (startBits * destDepth));
				}
				endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
				if (destMSB) {
					mask2 = AllOnes << (32 - (endBits * destDepth));
				} else {
					mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
				}
				if (bbW < startBits) {
					mask1 = mask1 & mask2;
					mask2 = 0;
					nWords = 1;
				} else {
					nWords = (((bbW - startBits) + pixPerM1) / destPPW) + 1;
				}
				hDir = vDir = 1;
				destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
				destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
				copyLoopPixMap();
				affectedL = dx;
				affectedR = dx + bbW;
				affectedT = dy;
				affectedB = dy + bbH;
			} else {
				copyBits();
			}
		}
		if (interpreterProxy->failed()) {
			return null;
		}
		destX = (destX + width) + kernDelta;
	}
	affectedL = left;
	/* begin showDisplayBits */
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
	interpreterProxy->pop(6);
}


/*	Invoke the line drawing primitive. */

EXPORT(sqInt) primitiveDrawLoop(void) {
    sqInt yDelta;
    sqInt xDelta;
    sqInt rcvr;
    sqInt affL;
    sqInt affB;
    sqInt affR;
    sqInt P;
    sqInt i;
    sqInt affT;
    sqInt dx1;
    sqInt px;
    sqInt dy1;
    sqInt py;

	rcvr = interpreterProxy->stackValue(2);
	xDelta = interpreterProxy->stackIntegerValue(1);
	yDelta = interpreterProxy->stackIntegerValue(0);
	if (!(loadBitBltFromwarping(rcvr, 0))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->failed())) {
		/* begin drawLoopX:Y: */
		if (xDelta > 0) {
			dx1 = 1;
		} else {
			if (xDelta == 0) {
				dx1 = 0;
			} else {
				dx1 = -1;
			}
		}
		if (yDelta > 0) {
			dy1 = 1;
		} else {
			if (yDelta == 0) {
				dy1 = 0;
			} else {
				dy1 = -1;
			}
		}
		px = abs(yDelta);
		py = abs(xDelta);
		affL = affT = 9999;
		affR = affB = -9999;
		if (py > px) {
			P = ((sqInt) py >> 1);
			for (i = 1; i <= py; i += 1) {
				destX += dx1;
				if ((P -= px) < 0) {
					destY += dy1;
					P += py;
				}
				if (i < py) {
					copyBits();
					if (interpreterProxy->failed()) {
						goto l1;
					}
					if ((affectedL < affectedR) && (affectedT < affectedB)) {
						affL = ((affL < affectedL) ? affL : affectedL);
						affR = ((affR < affectedR) ? affectedR : affR);
						affT = ((affT < affectedT) ? affT : affectedT);
						affB = ((affB < affectedB) ? affectedB : affB);
						if (((affR - affL) * (affB - affT)) > 4000) {
							affectedL = affL;
							affectedR = affR;
							affectedT = affT;
							affectedB = affB;
							/* begin showDisplayBits */
							interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
							affL = affT = 9999;
							affR = affB = -9999;
						}
					}
				}
			}
		} else {
			P = ((sqInt) px >> 1);
			for (i = 1; i <= px; i += 1) {
				destY += dy1;
				if ((P -= py) < 0) {
					destX += dx1;
					P += px;
				}
				if (i < px) {
					copyBits();
					if (interpreterProxy->failed()) {
						goto l1;
					}
					if ((affectedL < affectedR) && (affectedT < affectedB)) {
						affL = ((affL < affectedL) ? affL : affectedL);
						affR = ((affR < affectedR) ? affectedR : affR);
						affT = ((affT < affectedT) ? affT : affectedT);
						affB = ((affB < affectedB) ? affectedB : affB);
						if (((affR - affL) * (affB - affT)) > 4000) {
							affectedL = affL;
							affectedR = affR;
							affectedT = affT;
							affectedB = affB;
							/* begin showDisplayBits */
							interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
							affL = affT = 9999;
							affR = affB = -9999;
						}
					}
				}
			}
		}
		affectedL = affL;
		affectedR = affR;
		affectedT = affT;
		affectedB = affB;
		interpreterProxy->storeIntegerofObjectwithValue(BBDestXIndex, bitBltOop, destX);
		interpreterProxy->storeIntegerofObjectwithValue(BBDestYIndex, bitBltOop, destY);
	l1:	/* end drawLoopX:Y: */;
		/* begin showDisplayBits */
		interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(2);
	}
}


/*	Invoke the warpBits primitive. If the destination is the display, then copy it to the screen. */

EXPORT(sqInt) primitiveWarpBits(void) {
    sqInt rcvr;
    sqInt ns;
    sqInt endBits;
    sqInt pixPerM1;
    sqInt startBits;

	rcvr = interpreterProxy->stackValue(interpreterProxy->methodArgumentCount());
	if (!(loadBitBltFromwarping(rcvr, 1))) {
		return interpreterProxy->primitiveFail();
	}
	/* begin warpBits */
	ns = noSource;
	noSource = 1;
	clipRange();
	noSource = ns;
	if (noSource || ((bbW <= 0) || (bbH <= 0))) {
		affectedL = affectedR = affectedT = affectedB = 0;
		goto l1;
	}
	lockSurfaces();
	/* begin destMaskAndPointerInit */
	pixPerM1 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM1);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM1) / destPPW) + 1;
	}
	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	warpLoop();
	if (hDir > 0) {
		affectedL = dx;
		affectedR = dx + bbW;
	} else {
		affectedL = (dx - bbW) + 1;
		affectedR = dx + 1;
	}
	if (vDir > 0) {
		affectedT = dy;
		affectedB = dy + bbH;
	} else {
		affectedT = (dy - bbH) + 1;
		affectedB = dy + 1;
	}
	unlockSurfaces();
l1:	/* end warpBits */;
	if (interpreterProxy->failed()) {
		return null;
	}
	/* begin showDisplayBits */
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(interpreterProxy->methodArgumentCount());
}


/*	Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	Note: Moved to a separate function for better inlining of the caller. */

static sqInt queryDestSurface(sqInt handle) {
	if (querySurfaceFn == 0) {
		if (!(loadSurfacePlugin())) {
			return 0;
		}
	}
	return  ((sqInt (*) (sqInt, sqInt*, sqInt*, sqInt*, sqInt*))querySurfaceFn)
		(handle, &destWidth, &destHeight, &destDepth, &destMSB);
}


/*	Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	Note: Moved to a separate function for better inlining of the caller. */

static sqInt querySourceSurface(sqInt handle) {
	if (querySurfaceFn == 0) {
		if (!(loadSurfacePlugin())) {
			return 0;
		}
	}
	return  ((sqInt (*) (sqInt, sqInt*, sqInt*, sqInt*, sqInt*))querySurfaceFn)
		(handle, &sourceWidth, &sourceHeight, &sourceDepth, &sourceMSB);
}

static sqInt rgbAddwith(sqInt sourceWord, sqInt destinationWord) {
	if (destDepth < 16) {
		return partitionedAddtonBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedAddtonBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedAddtonBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedAddtonBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}


/*	Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, return the number of differing pixels. */

static sqInt rgbDiffwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt destShifted;
    sqInt diff;
    sqInt sourceShifted;
    sqInt rgbMask;
    sqInt bitsPerColor;
    sqInt pixMask;
    sqInt sourcePixVal;
    sqInt i;
    sqInt maskShifted;
    sqInt destPixVal;

	pixMask = maskTable[destDepth];
	if (destDepth == 16) {
		bitsPerColor = 5;
		rgbMask = 31;
	} else {
		bitsPerColor = 8;
		rgbMask = 255;
	}
	maskShifted = destMask;
	destShifted = destinationWord;
	sourceShifted = sourceWord;
	for (i = 1; i <= destPPW; i += 1) {
		if ((maskShifted & pixMask) > 0) {
			destPixVal = destShifted & pixMask;
			sourcePixVal = sourceShifted & pixMask;
			if (destDepth < 16) {
				if (sourcePixVal == destPixVal) {
					diff = 0;
				} else {
					diff = 1;
				}
			} else {
				diff = partitionedSubfromnBitsnPartitions(sourcePixVal, destPixVal, bitsPerColor, 3);
				diff = ((diff & rgbMask) + ((((usqInt) diff) >> bitsPerColor) & rgbMask)) + ((((usqInt) (((usqInt) diff) >> bitsPerColor)) >> bitsPerColor) & rgbMask);
			}
			bitCount += diff;
		}
		maskShifted = ((usqInt) maskShifted) >> destDepth;
		sourceShifted = ((usqInt) sourceShifted) >> destDepth;
		destShifted = ((usqInt) destShifted) >> destDepth;
	}
	return destinationWord;
}


/*	Convert the given 16bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats. */

static sqInt rgbMap16To32(sqInt sourcePixel) {
	return (((sourcePixel & 31) << 3) | ((sourcePixel & 992) << 6)) | ((sourcePixel & 31744) << 9);
}


/*	Convert the given 32bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats. */

static sqInt rgbMap32To32(sqInt sourcePixel) {
	return sourcePixel;
}


/*	Convert the given pixel value with nBitsIn bits for each color component to a pixel value with nBitsOut bits for each color component. Typical values for nBitsIn/nBitsOut are 3, 5, or 8. */

static sqInt rgbMapfromto(sqInt sourcePixel, sqInt nBitsIn, sqInt nBitsOut) {
    sqInt srcPix;
    sqInt d;
    sqInt mask;
    sqInt destPix;

	if ((d = nBitsOut - nBitsIn) > 0) {

		/* Transfer mask */

		mask = (1 << nBitsIn) - 1;
		srcPix = sourcePixel << d;
		mask = mask << d;
		destPix = srcPix & mask;
		mask = mask << nBitsOut;
		srcPix = srcPix << d;
		return (destPix + (srcPix & mask)) + ((srcPix << d) & (mask << nBitsOut));
	} else {
		if (d == 0) {
			if (nBitsIn == 5) {
				return sourcePixel & 32767;
			}
			if (nBitsIn == 8) {
				return sourcePixel & 16777215;
			}
			return sourcePixel;
		}
		if (sourcePixel == 0) {
			return sourcePixel;
		}
		d = nBitsIn - nBitsOut;

		/* Transfer mask */

		mask = (1 << nBitsOut) - 1;
		srcPix = ((usqInt) sourcePixel) >> d;
		destPix = srcPix & mask;
		mask = mask << nBitsOut;
		srcPix = ((usqInt) srcPix) >> d;
		destPix = (destPix + (srcPix & mask)) + ((((usqInt) srcPix) >> d) & (mask << nBitsOut));
		if (destPix == 0) {
			return 1;
		}
		return destPix;
	}
}


/*	Perform the RGBA conversion for the given source pixel */

static sqInt rgbMapPixelflags(sqInt sourcePixel, sqInt mapperFlags) {
    sqInt val;

	val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePixel & (cmMaskTable[0])) << (cmShiftTable[0])));
	val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePixel & (cmMaskTable[1])) << (cmShiftTable[1]))));
	val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePixel & (cmMaskTable[2])) << (cmShiftTable[2]))));
	return val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePixel & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePixel & (cmMaskTable[3])) << (cmShiftTable[3]))));
}

static sqInt rgbMaxwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt result;
    sqInt i;
    sqInt mask;
    sqInt result1;
    sqInt i1;
    sqInt mask3;

	if (destDepth < 16) {
		/* begin partitionedMax:with:nBits:nPartitions: */
		mask = maskTable[destDepth];
		result = 0;
		for (i = 1; i <= destPPW; i += 1) {
			result = result | ((((destinationWord & mask) < (sourceWord & mask)) ? (sourceWord & mask) : (destinationWord & mask)));
			mask = mask << destDepth;
		}
		return result;
	}
	if (destDepth == 16) {
		return (partitionedMaxwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMaxwithnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		/* begin partitionedMax:with:nBits:nPartitions: */
		mask3 = maskTable[8];
		result1 = 0;
		for (i1 = 1; i1 <= 3; i1 += 1) {
			result1 = result1 | ((((destinationWord & mask3) < (sourceWord & mask3)) ? (sourceWord & mask3) : (destinationWord & mask3)));
			mask3 = mask3 << 8;
		}
		return result1;
	}
}

static sqInt rgbMinwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt result;
    sqInt i;
    sqInt mask;
    sqInt result1;
    sqInt i1;
    sqInt mask3;

	if (destDepth < 16) {
		/* begin partitionedMin:with:nBits:nPartitions: */
		mask = maskTable[destDepth];
		result = 0;
		for (i = 1; i <= destPPW; i += 1) {
			result = result | ((((destinationWord & mask) < (sourceWord & mask)) ? (destinationWord & mask) : (sourceWord & mask)));
			mask = mask << destDepth;
		}
		return result;
	}
	if (destDepth == 16) {
		return (partitionedMinwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMinwithnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		/* begin partitionedMin:with:nBits:nPartitions: */
		mask3 = maskTable[8];
		result1 = 0;
		for (i1 = 1; i1 <= 3; i1 += 1) {
			result1 = result1 | ((((destinationWord & mask3) < (sourceWord & mask3)) ? (destinationWord & mask3) : (sourceWord & mask3)));
			mask3 = mask3 << 8;
		}
		return result1;
	}
}

static sqInt rgbMinInvertwith(sqInt wordToInvert, sqInt destinationWord) {
    sqInt sourceWord;
    sqInt result;
    sqInt i;
    sqInt mask;
    sqInt result1;
    sqInt i1;
    sqInt mask3;

	sourceWord = ~wordToInvert;
	if (destDepth < 16) {
		/* begin partitionedMin:with:nBits:nPartitions: */
		mask = maskTable[destDepth];
		result = 0;
		for (i = 1; i <= destPPW; i += 1) {
			result = result | ((((destinationWord & mask) < (sourceWord & mask)) ? (destinationWord & mask) : (sourceWord & mask)));
			mask = mask << destDepth;
		}
		return result;
	}
	if (destDepth == 16) {
		return (partitionedMinwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMinwithnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		/* begin partitionedMin:with:nBits:nPartitions: */
		mask3 = maskTable[8];
		result1 = 0;
		for (i1 = 1; i1 <= 3; i1 += 1) {
			result1 = result1 | ((((destinationWord & mask3) < (sourceWord & mask3)) ? (destinationWord & mask3) : (sourceWord & mask3)));
			mask3 = mask3 << 8;
		}
		return result1;
	}
}

static sqInt rgbMulwith(sqInt sourceWord, sqInt destinationWord) {
	if (destDepth < 16) {
		return partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMulwithnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}

static sqInt rgbSubwith(sqInt sourceWord, sqInt destinationWord) {
	if (destDepth < 16) {
		return partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedSubfromnBitsnPartitions(((usqInt) sourceWord) >> 16, ((usqInt) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine* anInterpreter) {
    sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


/*	WARNING: For WarpBlt w/ smoothing the source depth is wrong here! */

static sqInt setupColorMasks(void) {
    sqInt bits;
    sqInt targetBits;

	bits = targetBits = 0;
	if (sourceDepth <= 8) {
		return null;
	}
	if (sourceDepth == 16) {
		bits = 5;
	}
	if (sourceDepth == 32) {
		bits = 8;
	}
	if (cmBitsPerColor == 0) {
		if (destDepth <= 8) {
			return null;
		}
		if (destDepth == 16) {
			targetBits = 5;
		}
		if (destDepth == 32) {
			targetBits = 8;
		}
	} else {
		targetBits = cmBitsPerColor;
	}
	setupColorMasksFromto(bits, targetBits);
}


/*	Setup color masks for converting an incoming RGB pixel value from srcBits to targetBits. */

static sqInt setupColorMasksFromto(sqInt srcBits, sqInt targetBits) {
    static unsigned int masks[4] = {0, 0, 0, 0};
    sqInt mask;
    sqInt deltaBits;
    static int shifts[4] = {0, 0, 0, 0};

	;
	deltaBits = targetBits - srcBits;
	if (deltaBits == 0) {
		return 0;
	}
	if (deltaBits <= 0) {

		/* Mask for extracting a color part of the source */

		mask = (1 << targetBits) - 1;
		masks[RedIndex] = (mask << ((srcBits * 2) - deltaBits));
		masks[GreenIndex] = (mask << (srcBits - deltaBits));
		masks[BlueIndex] = (mask << (0 - deltaBits));
		masks[AlphaIndex] = 0;
	} else {

		/* Mask for extracting a color part of the source */

		mask = (1 << srcBits) - 1;
		masks[RedIndex] = (mask << (srcBits * 2));
		masks[GreenIndex] = (mask << srcBits);
		masks[BlueIndex] = mask;
	}
	shifts[RedIndex] = (deltaBits * 3);
	shifts[GreenIndex] = (deltaBits * 2);
	shifts[BlueIndex] = deltaBits;
	shifts[AlphaIndex] = 0;
	cmShiftTable = shifts;
	cmMaskTable = masks;
	cmFlags = cmFlags | (ColorMapPresent | ColorMapFixedPart);
}

static sqInt showDisplayBits(void) {
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
}


/*	This is only used when source and dest are same depth,
	ie, when the barrel-shift copy loop is used. */

static sqInt sourceSkewAndPointerInit(void) {
    sqInt dxLowBits;
    sqInt pixPerM1;
    sqInt sxLowBits;
    sqInt dWid;


	/* A mask, assuming power of two */

	pixPerM1 = destPPW - 1;
	sxLowBits = sx & pixPerM1;

	/* check if need to preload buffer
	(i.e., two words of source needed for first word of destination) */

	dxLowBits = dx & pixPerM1;
	if (hDir > 0) {
		dWid = ((bbW < (destPPW - dxLowBits)) ? bbW : (destPPW - dxLowBits));
		preload = (sxLowBits + dWid) > pixPerM1;
	} else {
		dWid = ((bbW < (dxLowBits + 1)) ? bbW : (dxLowBits + 1));
		preload = ((sxLowBits - dWid) + 1) < 0;
	}
	if (sourceMSB) {
		skew = (sxLowBits - dxLowBits) * destDepth;
	} else {
		skew = (dxLowBits - sxLowBits) * destDepth;
	}
	if (preload) {
		if (skew < 0) {
			skew += 32;
		} else {
			skew -= 32;
		}
	}

	/* calculate increments from end of 1 line to start of next */

	sourceIndex = (sourceBits + (sy * sourcePitch)) + ((sx / (32 / sourceDepth)) * 4);
	sourceDelta = (sourcePitch * vDir) - (4 * (nWords * hDir));
	if (preload) {
		sourceDelta -= 4 * hDir;
	}
}

static sqInt sourceWordwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord;
}

static sqInt srcLongAt(sqInt idx) {
	return long32At(idx);
}

static sqInt subWordwith(sqInt sourceWord, sqInt destinationWord) {
	return sourceWord - destinationWord;
}


/*	Note: Nasty coercion only necessary for the non-inlined version of this method in C. Duh? Oh well, here's the full story. The code below will definitely be inlined so everything that calls this method is fine. But... the translator doesn't quite prune this method so it generates a C function that tries to attempt an array access on an int - and most compilers don't like this. If you don't know what I'm talking about try to remove the C coercion and you'll see what happens when you try to compile a new VM... */

static sqInt tableLookupat(unsigned int * table, sqInt index) {
	return table[index];
}


/*	Tally pixels into the color map.  Those tallied are exactly those
	in the destination rectangle.  Note that the source should be 
	specified == destination, in order for the proper color map checks 
	to be performed at setup. */

static sqInt tallyIntoMapwith(sqInt sourceWord, sqInt destinationWord) {
    sqInt destShifted;
    sqInt pixMask;
    sqInt i;
    sqInt pixVal;
    sqInt maskShifted;
    sqInt mapIndex;
    sqInt srcPix;
    sqInt d;
    sqInt mask;
    sqInt destPix;
    sqInt srcPix1;
    sqInt d1;
    sqInt mask3;
    sqInt destPix1;

	if (!((cmFlags & (ColorMapPresent | ColorMapIndexedPart)) == (ColorMapPresent | ColorMapIndexedPart))) {
		return destinationWord;
	}
	pixMask = maskTable[destDepth];
	destShifted = destinationWord;
	maskShifted = destMask;
	for (i = 1; i <= destPPW; i += 1) {
		if (!((maskShifted & pixMask) == 0)) {
			pixVal = destShifted & pixMask;
			if (destDepth < 16) {
				mapIndex = pixVal;
			} else {
				if (destDepth == 16) {
					/* begin rgbMap:from:to: */
					if ((d = cmBitsPerColor - 5) > 0) {
						mask = (1 << 5) - 1;
						srcPix = pixVal << d;
						mask = mask << d;
						destPix = srcPix & mask;
						mask = mask << cmBitsPerColor;
						srcPix = srcPix << d;
						mapIndex = (destPix + (srcPix & mask)) + ((srcPix << d) & (mask << cmBitsPerColor));
						goto l1;
					} else {
						if (d == 0) {
							if (5 == 5) {
								mapIndex = pixVal & 32767;
								goto l1;
							}
							if (5 == 8) {
								mapIndex = pixVal & 16777215;
								goto l1;
							}
							mapIndex = pixVal;
							goto l1;
						}
						if (pixVal == 0) {
							mapIndex = pixVal;
							goto l1;
						}
						d = 5 - cmBitsPerColor;
						mask = (1 << cmBitsPerColor) - 1;
						srcPix = ((usqInt) pixVal) >> d;
						destPix = srcPix & mask;
						mask = mask << cmBitsPerColor;
						srcPix = ((usqInt) srcPix) >> d;
						destPix = (destPix + (srcPix & mask)) + ((((usqInt) srcPix) >> d) & (mask << cmBitsPerColor));
						if (destPix == 0) {
							mapIndex = 1;
							goto l1;
						}
						mapIndex = destPix;
						goto l1;
					}
				l1:	/* end rgbMap:from:to: */;
				} else {
					/* begin rgbMap:from:to: */
					if ((d1 = cmBitsPerColor - 8) > 0) {
						mask3 = (1 << 8) - 1;
						srcPix1 = pixVal << d1;
						mask3 = mask3 << d1;
						destPix1 = srcPix1 & mask3;
						mask3 = mask3 << cmBitsPerColor;
						srcPix1 = srcPix1 << d1;
						mapIndex = (destPix1 + (srcPix1 & mask3)) + ((srcPix1 << d1) & (mask3 << cmBitsPerColor));
						goto l2;
					} else {
						if (d1 == 0) {
							if (8 == 5) {
								mapIndex = pixVal & 32767;
								goto l2;
							}
							if (8 == 8) {
								mapIndex = pixVal & 16777215;
								goto l2;
							}
							mapIndex = pixVal;
							goto l2;
						}
						if (pixVal == 0) {
							mapIndex = pixVal;
							goto l2;
						}
						d1 = 8 - cmBitsPerColor;
						mask3 = (1 << cmBitsPerColor) - 1;
						srcPix1 = ((usqInt) pixVal) >> d1;
						destPix1 = srcPix1 & mask3;
						mask3 = mask3 << cmBitsPerColor;
						srcPix1 = ((usqInt) srcPix1) >> d1;
						destPix1 = (destPix1 + (srcPix1 & mask3)) + ((((usqInt) srcPix1) >> d1) & (mask3 << cmBitsPerColor));
						if (destPix1 == 0) {
							mapIndex = 1;
							goto l2;
						}
						mapIndex = destPix1;
						goto l2;
					}
				l2:	/* end rgbMap:from:to: */;
				}
			}
			cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
		}
		maskShifted = ((usqInt) maskShifted) >> destDepth;
		destShifted = ((usqInt) destShifted) >> destDepth;
	}
	return destinationWord;
}


/*	Return the word at position idx from the colorMap */

static sqInt tallyMapAt(sqInt idx) {
	return cmLookupTable[idx & cmMask];
}


/*	Store the word at position idx in the colorMap */

static sqInt tallyMapAtput(sqInt idx, sqInt value) {
	return cmLookupTable[idx & cmMask] = value;
}


/*	Shortcut for stuff that's being run from the balloon engine.
	Since we do this at each scan line we should avoid the expensive 
	setup for source and destination. */

static sqInt tryCopyingBitsQuickly(void) {
	if (noSource) {
		return 0;
	}
	if (!(combinationRule == 34)) {
		return 0;
	}
	if (!(sourceDepth == 32)) {
		return 0;
	}
	if (sourceForm == destForm) {
		return 0;
	}
	if (destDepth < 8) {
		return 0;
	}
	if ((destDepth == 8) && ((cmFlags & ColorMapPresent) == 0)) {
		return 0;
	}
	if (destDepth == 32) {
		alphaSourceBlendBits32();
	}
	if (destDepth == 16) {
		alphaSourceBlendBits16();
	}
	if (destDepth == 8) {
		alphaSourceBlendBits8();
	}
	affectedL = dx;
	affectedR = dx + bbW;
	affectedT = dy;
	affectedB = dy + bbH;
	return 1;
}


/*	Unlock the bits of any OS surfaces. */
/*	See the comment in lockSurfaces. Similar rules apply. That is, the area provided in ioUnlockSurface can be used to determine the dirty region after drawing. If a source is unlocked, then the area will be (0,0,0,0) to indicate that no portion is dirty. */

static sqInt unlockSurfaces(void) {
    sqInt sourceHandle;
    sqInt destHandle;
    sqInt (*fn)(sqInt, sqInt, sqInt, sqInt, sqInt);
    sqInt destLocked;

	if (hasSurfaceLock) {
		if (unlockSurfaceFn == 0) {
			if (!(loadSurfacePlugin())) {
				return null;
			}
		}
		fn = ((sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt)) unlockSurfaceFn);
		destLocked = 0;
		destHandle = interpreterProxy->fetchPointerofObject(FormBitsIndex, destForm);
		if ((destHandle & 1)) {

			/* The destBits are always assumed to be dirty */

			destHandle = (destHandle >> 1);
			fn(destHandle, affectedL, affectedT, affectedR-affectedL, affectedB-affectedT);
			destBits = destPitch = 0;
			destLocked = 1;
		}
		if (!(noSource)) {
			sourceHandle = interpreterProxy->fetchPointerofObject(FormBitsIndex, sourceForm);
			if ((sourceHandle & 1)) {

				/* Only unlock sourceHandle if different from destHandle */

				sourceHandle = (sourceHandle >> 1);
				if (!(destLocked && (sourceHandle == destHandle))) {
					fn(sourceHandle, 0, 0, 0, 0);
				}
				sourceBits = sourcePitch = 0;
			}
		}
		hasSurfaceLock = 0;
	}
}

static sqInt warpBits(void) {
    sqInt ns;
    sqInt endBits;
    sqInt pixPerM1;
    sqInt startBits;

	ns = noSource;
	noSource = 1;
	clipRange();
	noSource = ns;
	if (noSource || ((bbW <= 0) || (bbH <= 0))) {
		affectedL = affectedR = affectedT = affectedB = 0;
		return null;
	}
	lockSurfaces();
	/* begin destMaskAndPointerInit */
	pixPerM1 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM1);
	if (destMSB) {
		mask1 = ((usqInt) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((usqInt) AllOnes) >> (32 - (endBits * destDepth));
	}
	if (bbW < startBits) {
		mask1 = mask1 & mask2;
		mask2 = 0;
		nWords = 1;
	} else {
		nWords = (((bbW - startBits) + pixPerM1) / destPPW) + 1;
	}
	hDir = vDir = 1;
	destIndex = (destBits + (dy * destPitch)) + ((dx / destPPW) * 4);
	destDelta = (destPitch * vDir) - (4 * (nWords * hDir));
	warpLoop();
	if (hDir > 0) {
		affectedL = dx;
		affectedR = dx + bbW;
	} else {
		affectedL = (dx - bbW) + 1;
		affectedR = dx + 1;
	}
	if (vDir > 0) {
		affectedT = dy;
		affectedB = dy + bbH;
	} else {
		affectedT = (dy - bbH) + 1;
		affectedB = dy + 1;
	}
	unlockSurfaces();
}


/*	This version of the inner loop traverses an arbirary quadrilateral
	source, thus producing a general affine transformation. */

static sqInt warpLoop(void) {
    sqInt nPix;
    sqInt endBits;
    sqInt pAx;
    sqInt deltaP43x;
    sqInt dstShiftLeft;
    sqInt mapperFlags;
    sqInt yDelta;
    sqInt xDelta;
    sqInt pBy;
    sqInt skewWord;
    sqInt dstShiftInc;
    sqInt words;
    sqInt deltaP12y;
    sqInt smoothingCount;
    sqInt destWord;
    sqInt mergeWord;
    sqInt pBx;
    sqInt sourceMapOop;
    sqInt nSteps;
    sqInt halftoneWord;
    sqInt pAy;
    sqInt deltaP43y;
    sqInt (*mergeFnwith)(sqInt, sqInt);
    sqInt deltaP12x;
    sqInt i;
    sqInt startBits;
    sqInt idx;
    sqInt nPix1;
    sqInt sourcePix;
    sqInt dstMask;
    sqInt destWord1;
    sqInt destPix;
    sqInt idx1;
    sqInt value;
    sqInt idx2;
    sqInt idx3;
    sqInt i1;
    sqInt words1;
    sqInt xx;
    sqInt yy;
    sqInt sourcePix1;
    sqInt x;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt y;
    sqInt xx1;
    sqInt yy1;
    sqInt sourcePix2;
    sqInt x1;
    sqInt srcIndex1;
    sqInt sourceWord1;
    sqInt y1;
    sqInt pv;
    sqInt val;

	mergeFnwith = ((sqInt (*)(sqInt, sqInt)) (opTable[combinationRule + 1]));
	mergeFnwith;
	if (!((interpreterProxy->slotSizeOf(bitBltOop)) >= (BBWarpBase + 12))) {
		return interpreterProxy->primitiveFail();
	}
	nSteps = height - 1;
	if (nSteps <= 0) {
		nSteps = 1;
	}
	pAx = fetchIntOrFloatofObject(BBWarpBase, bitBltOop);
	words = fetchIntOrFloatofObject(BBWarpBase + 3, bitBltOop);
	/* begin deltaFrom:to:nSteps: */
	if (words > pAx) {
		deltaP12x = (((words - pAx) + FixedPt1) / (nSteps + 1)) + 1;
		goto l3;
	} else {
		if (words == pAx) {
			deltaP12x = 0;
			goto l3;
		}
		deltaP12x = 0 - ((((pAx - words) + FixedPt1) / (nSteps + 1)) + 1);
		goto l3;
	}
l3:	/* end deltaFrom:to:nSteps: */;
	if (deltaP12x < 0) {
		pAx = words - (nSteps * deltaP12x);
	}
	pAy = fetchIntOrFloatofObject(BBWarpBase + 1, bitBltOop);
	words = fetchIntOrFloatofObject(BBWarpBase + 4, bitBltOop);
	/* begin deltaFrom:to:nSteps: */
	if (words > pAy) {
		deltaP12y = (((words - pAy) + FixedPt1) / (nSteps + 1)) + 1;
		goto l4;
	} else {
		if (words == pAy) {
			deltaP12y = 0;
			goto l4;
		}
		deltaP12y = 0 - ((((pAy - words) + FixedPt1) / (nSteps + 1)) + 1);
		goto l4;
	}
l4:	/* end deltaFrom:to:nSteps: */;
	if (deltaP12y < 0) {
		pAy = words - (nSteps * deltaP12y);
	}
	pBx = fetchIntOrFloatofObject(BBWarpBase + 9, bitBltOop);
	words = fetchIntOrFloatofObject(BBWarpBase + 6, bitBltOop);
	/* begin deltaFrom:to:nSteps: */
	if (words > pBx) {
		deltaP43x = (((words - pBx) + FixedPt1) / (nSteps + 1)) + 1;
		goto l5;
	} else {
		if (words == pBx) {
			deltaP43x = 0;
			goto l5;
		}
		deltaP43x = 0 - ((((pBx - words) + FixedPt1) / (nSteps + 1)) + 1);
		goto l5;
	}
l5:	/* end deltaFrom:to:nSteps: */;
	if (deltaP43x < 0) {
		pBx = words - (nSteps * deltaP43x);
	}
	pBy = fetchIntOrFloatofObject(BBWarpBase + 10, bitBltOop);
	words = fetchIntOrFloatofObject(BBWarpBase + 7, bitBltOop);
	/* begin deltaFrom:to:nSteps: */
	if (words > pBy) {
		deltaP43y = (((words - pBy) + FixedPt1) / (nSteps + 1)) + 1;
		goto l6;
	} else {
		if (words == pBy) {
			deltaP43y = 0;
			goto l6;
		}
		deltaP43y = 0 - ((((pBy - words) + FixedPt1) / (nSteps + 1)) + 1);
		goto l6;
	}
l6:	/* end deltaFrom:to:nSteps: */;
	if (deltaP43y < 0) {
		pBy = words - (nSteps * deltaP43y);
	}
	if (interpreterProxy->failed()) {
		return 0;
	}
	if ((interpreterProxy->methodArgumentCount()) == 2) {
		smoothingCount = interpreterProxy->stackIntegerValue(1);
		sourceMapOop = interpreterProxy->stackValue(0);
		if (sourceMapOop == (interpreterProxy->nilObject())) {
			if (sourceDepth < 16) {
				return interpreterProxy->primitiveFail();
			}
		} else {
			if ((interpreterProxy->slotSizeOf(sourceMapOop)) < (1 << sourceDepth)) {
				return interpreterProxy->primitiveFail();
			}
			sourceMapOop = oopForPointer(interpreterProxy->firstIndexableField(sourceMapOop));
		}
	} else {
		smoothingCount = 1;
		sourceMapOop = interpreterProxy->nilObject();
	}
	nSteps = width - 1;
	if (nSteps <= 0) {
		nSteps = 1;
	}
	startBits = destPPW - (dx & (destPPW - 1));
	endBits = (((dx + bbW) - 1) & (destPPW - 1)) + 1;
	if (bbW < startBits) {
		startBits = bbW;
	}
	if (destY < clipY) {
		pAx += (clipY - destY) * deltaP12x;
		pAy += (clipY - destY) * deltaP12y;
		pBx += (clipY - destY) * deltaP43x;
		pBy += (clipY - destY) * deltaP43y;
	}
	/* begin warpLoopSetup */
	warpSrcShift = 0;
	words1 = sourceDepth;
	while (!(words1 == 1)) {
		warpSrcShift += 1;
		words1 = ((usqInt) words1) >> 1;
	}
	warpSrcMask = maskTable[sourceDepth];
	warpAlignShift = 5 - warpSrcShift;
	warpAlignMask = (1 << warpAlignShift) - 1;
	for (i1 = 0; i1 <= warpAlignMask; i1 += 1) {
		if (sourceMSB) {
			warpBitShiftTable[i1] = (32 - ((i1 + 1) << warpSrcShift));
		} else {
			warpBitShiftTable[i1] = (i1 << warpSrcShift);
		}
	}
	if ((smoothingCount > 1) && ((cmFlags & ColorMapNewStyle) == 0)) {
		if (cmLookupTable == null) {
			if (destDepth == 16) {
				setupColorMasksFromto(8, 5);
			}
		} else {
			setupColorMasksFromto(8, cmBitsPerColor);
		}
	}
	mapperFlags = cmFlags & (~ColorMapNewStyle);
	if (destMSB) {
		dstShiftInc = 0 - destDepth;
		dstShiftLeft = 32 - destDepth;
	} else {
		dstShiftInc = destDepth;
		dstShiftLeft = 0;
	}
	for (i = 1; i <= bbH; i += 1) {
		/* begin deltaFrom:to:nSteps: */
		if (pBx > pAx) {
			xDelta = (((pBx - pAx) + FixedPt1) / (nSteps + 1)) + 1;
			goto l1;
		} else {
			if (pBx == pAx) {
				xDelta = 0;
				goto l1;
			}
			xDelta = 0 - ((((pAx - pBx) + FixedPt1) / (nSteps + 1)) + 1);
			goto l1;
		}
	l1:	/* end deltaFrom:to:nSteps: */;
		if (xDelta >= 0) {
			sx = pAx;
		} else {
			sx = pBx - (nSteps * xDelta);
		}
		/* begin deltaFrom:to:nSteps: */
		if (pBy > pAy) {
			yDelta = (((pBy - pAy) + FixedPt1) / (nSteps + 1)) + 1;
			goto l2;
		} else {
			if (pBy == pAy) {
				yDelta = 0;
				goto l2;
			}
			yDelta = 0 - ((((pAy - pBy) + FixedPt1) / (nSteps + 1)) + 1);
			goto l2;
		}
	l2:	/* end deltaFrom:to:nSteps: */;
		if (yDelta >= 0) {
			sy = pAy;
		} else {
			sy = pBy - (nSteps * yDelta);
		}
		if (destMSB) {
			dstBitShift = 32 - (((dx & (destPPW - 1)) + 1) * destDepth);
		} else {
			dstBitShift = (dx & (destPPW - 1)) * destDepth;
		}
		if (destX < clipX) {
			sx += (clipX - destX) * xDelta;
			sy += (clipX - destX) * yDelta;
		}
		if (noHalftone) {
			halftoneWord = AllOnes;
		} else {
			/* begin halftoneAt: */
			idx = (dy + i) - 1;
			halftoneWord = long32At(halftoneBase + ((idx % halftoneHeight) * 4));
		}
		destMask = mask1;

		/* Here is the inner loop... */

		nPix = startBits;
		words = nWords;
		do {
			if (smoothingCount == 1) {
				/* begin warpPickSourcePixels:xDeltah:yDeltah:xDeltav:yDeltav:dstShiftInc:flags: */
				dstMask = maskTable[destDepth];
				destWord1 = 0;
				nPix1 = nPix;
				if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
					do {
						/* begin pickWarpPixelAtX:y: */
						xx = sx;
						yy = sy;
						if ((xx < 0) || ((yy < 0) || (((x = ((usqInt) xx) >> BinaryPoint) >= sourceWidth) || ((y = ((usqInt) yy) >> BinaryPoint) >= sourceHeight)))) {
							sourcePix = 0;
							goto l7;
						}
						srcIndex = (sourceBits + (y * sourcePitch)) + ((((usqInt) x) >> warpAlignShift) * 4);
						sourceWord = long32At(srcIndex);
						srcBitShift = warpBitShiftTable[x & warpAlignMask];
						sourcePix1 = (((usqInt) sourceWord) >> srcBitShift) & warpSrcMask;
						sourcePix = sourcePix1;
					l7:	/* end pickWarpPixelAtX:y: */;
						destPix = cmLookupTable[sourcePix & cmMask];
						destWord1 = destWord1 | ((destPix & dstMask) << dstBitShift);
						dstBitShift += dstShiftInc;
						sx += xDelta;
						sy += yDelta;
					} while(!((nPix1 -= 1) == 0));
				} else {
					do {
						/* begin pickWarpPixelAtX:y: */
						xx1 = sx;
						yy1 = sy;
						if ((xx1 < 0) || ((yy1 < 0) || (((x1 = ((usqInt) xx1) >> BinaryPoint) >= sourceWidth) || ((y1 = ((usqInt) yy1) >> BinaryPoint) >= sourceHeight)))) {
							sourcePix = 0;
							goto l8;
						}
						srcIndex1 = (sourceBits + (y1 * sourcePitch)) + ((((usqInt) x1) >> warpAlignShift) * 4);
						sourceWord1 = long32At(srcIndex1);
						srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
						sourcePix2 = (((usqInt) sourceWord1) >> srcBitShift) & warpSrcMask;
						sourcePix = sourcePix2;
					l8:	/* end pickWarpPixelAtX:y: */;
						/* begin mapPixel:flags: */
						pv = sourcePix;
						if ((mapperFlags & ColorMapPresent) != 0) {
							if ((mapperFlags & ColorMapFixedPart) != 0) {
								/* begin rgbMapPixel:flags: */
								val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
								val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
								val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
								pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
								if ((pv == 0) && (sourcePix != 0)) {
									pv = 1;
								}
							}
							if ((mapperFlags & ColorMapIndexedPart) != 0) {
								pv = cmLookupTable[pv & cmMask];
							}
						}
						destPix = pv;
						destWord1 = destWord1 | ((destPix & dstMask) << dstBitShift);
						dstBitShift += dstShiftInc;
						sx += xDelta;
						sy += yDelta;
					} while(!((nPix1 -= 1) == 0));
				}
				skewWord = destWord1;
			} else {
				skewWord = warpPickSmoothPixelsxDeltahyDeltahxDeltavyDeltavsourceMapsmoothingdstShiftInc(nPix, xDelta, yDelta, deltaP12x, deltaP12y, sourceMapOop, smoothingCount, dstShiftInc);
			}
			dstBitShift = dstShiftLeft;
			if (destMask == AllOnes) {
				mergeWord = mergeFnwith(skewWord & halftoneWord, dstLongAt(destIndex));
				/* begin dstLongAt:put: */
				idx1 = destIndex;
				value = destMask & mergeWord;
				long32Atput(idx1, value);
			} else {
				/* begin dstLongAt: */
				idx2 = destIndex;
				destWord = long32At(idx2);
				mergeWord = mergeFnwith(skewWord & halftoneWord, destWord & destMask);
				destWord = (destMask & mergeWord) | (destWord & (~destMask));
				/* begin dstLongAt:put: */
				idx3 = destIndex;
				long32Atput(idx3, destWord);
			}
			destIndex += 4;
			if (words == 2) {
				destMask = mask2;
				nPix = endBits;
			} else {
				destMask = AllOnes;
				nPix = destPPW;
			}
		} while(!((words -= 1) == 0));
		pAx += deltaP12x;
		pAy += deltaP12y;
		pBx += deltaP43x;
		pBy += deltaP43y;
		destIndex += destDelta;
	}
}


/*	Setup values for faster pixel fetching. */

static sqInt warpLoopSetup(void) {
    sqInt i;
    sqInt words;

	warpSrcShift = 0;

	/* recycle temp */

	words = sourceDepth;
	while (!(words == 1)) {
		warpSrcShift += 1;
		words = ((usqInt) words) >> 1;
	}

	/* warpAlignShift: Shift for aligning x position to word boundary */

	warpSrcMask = maskTable[sourceDepth];

	/* warpAlignMask: Mask for extracting the pixel position from an x position */

	warpAlignShift = 5 - warpSrcShift;

	/* Setup the lookup table for source bit shifts */
	/* warpBitShiftTable: given an sub-word x value what's the bit shift? */

	warpAlignMask = (1 << warpAlignShift) - 1;
	for (i = 0; i <= warpAlignMask; i += 1) {
		if (sourceMSB) {
			warpBitShiftTable[i] = (32 - ((i + 1) << warpSrcShift));
		} else {
			warpBitShiftTable[i] = (i << warpSrcShift);
		}
	}
}


/*	Pick n (sub-) pixels from the source form, mapped by sourceMap,
	average the RGB values, map by colorMap and return the new word.
	This version is only called from WarpBlt with smoothingCount > 1 */

static sqInt warpPickSmoothPixelsxDeltahyDeltahxDeltavyDeltavsourceMapsmoothingdstShiftInc(sqInt nPixels, sqInt xDeltah, sqInt yDeltah, sqInt xDeltav, sqInt yDeltav, sqInt sourceMap, sqInt n, sqInt dstShiftInc) {
    sqInt nPix;
    sqInt a;
    sqInt k;
    sqInt rgb;
    sqInt xdh;
    sqInt r;
    sqInt j;
    sqInt y;
    sqInt destWord;
    sqInt xx;
    sqInt yy;
    sqInt dstMask;
    sqInt b;
    sqInt g;
    sqInt ydv;
    sqInt i;
    sqInt x;
    sqInt ydh;
    sqInt xdv;
    sqInt sourcePix;
    sqInt x1;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt y1;
    sqInt pv;
    sqInt val;

	dstMask = maskTable[destDepth];
	destWord = 0;
	if (n == 2) {
		xdh = ((sqInt) xDeltah >> 1);
		ydh = ((sqInt) yDeltah >> 1);
		xdv = ((sqInt) xDeltav >> 1);
		ydv = ((sqInt) yDeltav >> 1);
	} else {
		xdh = xDeltah / n;
		ydh = yDeltah / n;
		xdv = xDeltav / n;
		ydv = yDeltav / n;
	}
	i = nPixels;
	do {
		x = sx;
		y = sy;

		/* Pick and average n*n subpixels */

		a = r = g = b = 0;

		/* actual number of pixels (not clipped and not transparent) */

		nPix = 0;
		j = n;
		do {
			xx = x;
			yy = y;
			k = n;
			do {
				/* begin pickWarpPixelAtX:y: */
				if ((xx < 0) || ((yy < 0) || (((x1 = ((usqInt) xx) >> BinaryPoint) >= sourceWidth) || ((y1 = ((usqInt) yy) >> BinaryPoint) >= sourceHeight)))) {
					rgb = 0;
					goto l1;
				}
				srcIndex = (sourceBits + (y1 * sourcePitch)) + ((((usqInt) x1) >> warpAlignShift) * 4);
				sourceWord = long32At(srcIndex);
				srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
				sourcePix = (((usqInt) sourceWord) >> srcBitShift) & warpSrcMask;
				rgb = sourcePix;
			l1:	/* end pickWarpPixelAtX:y: */;
				if (!((combinationRule == 25) && (rgb == 0))) {
					nPix += 1;
					if (sourceDepth < 16) {
						rgb = long32At(sourceMap + (rgb << 2));
					} else {
						if (sourceDepth == 16) {
							rgb = (((rgb & 31) << 3) | ((rgb & 992) << 6)) | ((rgb & 31744) << 9);
						} else {
							rgb = rgb;
						}
					}
					b += rgb & 255;
					g += (((usqInt) rgb) >> 8) & 255;
					r += (((usqInt) rgb) >> 16) & 255;
					a += ((usqInt) rgb) >> 24;
				}
				xx += xdh;
				yy += ydh;
			} while(!((k -= 1) == 0));
			x += xdv;
			y += ydv;
		} while(!((j -= 1) == 0));
		if ((nPix == 0) || ((combinationRule == 25) && (nPix < (((sqInt) (n * n) >> 1))))) {

			/* All pixels were 0, or most were transparent */

			rgb = 0;
		} else {
			if (nPix == 4) {
				r = ((usqInt) r) >> 2;
				g = ((usqInt) g) >> 2;
				b = ((usqInt) b) >> 2;
				a = ((usqInt) a) >> 2;
			} else {
				r = r / nPix;
				g = g / nPix;
				b = b / nPix;
				a = a / nPix;
			}

			/* map the pixel */

			rgb = (((a << 24) + (r << 16)) + (g << 8)) + b;
			if (rgb == 0) {
				if ((((r + g) + b) + a) > 0) {
					rgb = 1;
				}
			}
			/* begin mapPixel:flags: */
			pv = rgb;
			if ((cmFlags & ColorMapPresent) != 0) {
				if ((cmFlags & ColorMapFixedPart) != 0) {
					/* begin rgbMapPixel:flags: */
					val = (((cmShiftTable[0]) < 0) ? ((usqInt) (rgb & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (rgb & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (rgb & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (rgb & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (rgb & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (rgb & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (rgb & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (rgb & (cmMaskTable[3])) << (cmShiftTable[3]))));
					if ((pv == 0) && (rgb != 0)) {
						pv = 1;
					}
				}
				if ((cmFlags & ColorMapIndexedPart) != 0) {
					pv = cmLookupTable[pv & cmMask];
				}
			}
			rgb = pv;
		}
		destWord = destWord | ((rgb & dstMask) << dstBitShift);
		dstBitShift += dstShiftInc;
		sx += xDeltah;
		sy += yDeltah;
	} while(!((i -= 1) == 0));
	return destWord;
}


/*	Pick n pixels from the source form,
	map by colorMap and return aligned by dstBitShift.
	This version is only called from WarpBlt with smoothingCount = 1 */

static sqInt warpPickSourcePixelsxDeltahyDeltahxDeltavyDeltavdstShiftIncflags(sqInt nPixels, sqInt xDeltah, sqInt yDeltah, sqInt xDeltav, sqInt yDeltav, sqInt dstShiftInc, sqInt mapperFlags) {
    sqInt nPix;
    sqInt sourcePix;
    sqInt dstMask;
    sqInt destWord;
    sqInt destPix;
    sqInt xx;
    sqInt yy;
    sqInt sourcePix1;
    sqInt x;
    sqInt srcIndex;
    sqInt sourceWord;
    sqInt y;
    sqInt xx1;
    sqInt yy1;
    sqInt sourcePix2;
    sqInt x1;
    sqInt srcIndex1;
    sqInt sourceWord1;
    sqInt y1;
    sqInt pv;
    sqInt val;

	dstMask = maskTable[destDepth];
	destWord = 0;
	nPix = nPixels;
	if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
		do {
			/* begin pickWarpPixelAtX:y: */
			xx = sx;
			yy = sy;
			if ((xx < 0) || ((yy < 0) || (((x = ((usqInt) xx) >> BinaryPoint) >= sourceWidth) || ((y = ((usqInt) yy) >> BinaryPoint) >= sourceHeight)))) {
				sourcePix = 0;
				goto l1;
			}
			srcIndex = (sourceBits + (y * sourcePitch)) + ((((usqInt) x) >> warpAlignShift) * 4);
			sourceWord = long32At(srcIndex);
			srcBitShift = warpBitShiftTable[x & warpAlignMask];
			sourcePix1 = (((usqInt) sourceWord) >> srcBitShift) & warpSrcMask;
			sourcePix = sourcePix1;
		l1:	/* end pickWarpPixelAtX:y: */;
			destPix = cmLookupTable[sourcePix & cmMask];
			destWord = destWord | ((destPix & dstMask) << dstBitShift);
			dstBitShift += dstShiftInc;
			sx += xDeltah;
			sy += yDeltah;
		} while(!((nPix -= 1) == 0));
	} else {
		do {
			/* begin pickWarpPixelAtX:y: */
			xx1 = sx;
			yy1 = sy;
			if ((xx1 < 0) || ((yy1 < 0) || (((x1 = ((usqInt) xx1) >> BinaryPoint) >= sourceWidth) || ((y1 = ((usqInt) yy1) >> BinaryPoint) >= sourceHeight)))) {
				sourcePix = 0;
				goto l2;
			}
			srcIndex1 = (sourceBits + (y1 * sourcePitch)) + ((((usqInt) x1) >> warpAlignShift) * 4);
			sourceWord1 = long32At(srcIndex1);
			srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
			sourcePix2 = (((usqInt) sourceWord1) >> srcBitShift) & warpSrcMask;
			sourcePix = sourcePix2;
		l2:	/* end pickWarpPixelAtX:y: */;
			/* begin mapPixel:flags: */
			pv = sourcePix;
			if ((mapperFlags & ColorMapPresent) != 0) {
				if ((mapperFlags & ColorMapFixedPart) != 0) {
					/* begin rgbMapPixel:flags: */
					val = (((cmShiftTable[0]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((usqInt) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((usqInt) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((usqInt) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((usqInt) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((usqInt) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
					if ((pv == 0) && (sourcePix != 0)) {
						pv = 1;
					}
				}
				if ((mapperFlags & ColorMapIndexedPart) != 0) {
					pv = cmLookupTable[pv & cmMask];
				}
			}
			destPix = pv;
			destWord = destWord | ((destPix & dstMask) << dstBitShift);
			dstBitShift += dstShiftInc;
			sx += xDeltah;
			sy += yDeltah;
		} while(!((nPix -= 1) == 0));
	}
	return destWord;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* BitBltPlugin_exports[][3] = {
	{"BitBltPlugin", "primitiveWarpBits", (void*)primitiveWarpBits},
	{"BitBltPlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"BitBltPlugin", "copyBits", (void*)copyBits},
	{"BitBltPlugin", "primitiveCopyBits", (void*)primitiveCopyBits},
	{"BitBltPlugin", "initialiseModule", (void*)initialiseModule},
	{"BitBltPlugin", "setInterpreter", (void*)setInterpreter},
	{"BitBltPlugin", "copyBitsFromtoat", (void*)copyBitsFromtoat},
	{"BitBltPlugin", "loadBitBltFrom", (void*)loadBitBltFrom},
	{"BitBltPlugin", "getModuleName", (void*)getModuleName},
	{"BitBltPlugin", "primitiveDrawLoop", (void*)primitiveDrawLoop},
	{"BitBltPlugin", "primitiveDisplayString", (void*)primitiveDisplayString},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

