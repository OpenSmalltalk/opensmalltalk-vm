/* Automatically generated from Squeak on #(19 March 2005 10:08:52 am) */

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

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


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
static int OLDrgbDiffwith(int sourceWord, int destinationWord);
static int OLDtallyIntoMapwith(int sourceWord, int destinationWord);
static int addWordwith(int sourceWord, int destinationWord);
static int affectedBottom(void);
static int affectedLeft(void);
static int affectedRight(void);
static int affectedTop(void);
static int alphaBlendwith(int sourceWord, int destinationWord);
static int alphaBlendConstwith(int sourceWord, int destinationWord);
static int alphaBlendConstwithpaintMode(int sourceWord, int destinationWord, int paintMode);
static int alphaBlendScaledwith(int sourceWord, int destinationWord);
static int alphaPaintConstwith(int sourceWord, int destinationWord);
static int alphaSourceBlendBits16(void);
static int alphaSourceBlendBits32(void);
static int alphaSourceBlendBits8(void);
static int bitAndwith(int sourceWord, int destinationWord);
static int bitAndInvertwith(int sourceWord, int destinationWord);
static int bitInvertAndwith(int sourceWord, int destinationWord);
static int bitInvertAndInvertwith(int sourceWord, int destinationWord);
static int bitInvertDestinationwith(int sourceWord, int destinationWord);
static int bitInvertOrwith(int sourceWord, int destinationWord);
static int bitInvertOrInvertwith(int sourceWord, int destinationWord);
static int bitInvertSourcewith(int sourceWord, int destinationWord);
static int bitInvertXorwith(int sourceWord, int destinationWord);
static int bitOrwith(int sourceWord, int destinationWord);
static int bitOrInvertwith(int sourceWord, int destinationWord);
static int bitXorwith(int sourceWord, int destinationWord);
static int checkSourceOverlap(void);
static int clearWordwith(int source, int destination);
static int clipRange(void);
#pragma export on
EXPORT(int) copyBits(void);
EXPORT(int) copyBitsFromtoat(int startX, int stopX, int yValue);
#pragma export off
static int copyBitsLockedAndClipped(void);
static int copyLoop(void);
static int copyLoopNoSource(void);
static int copyLoopPixMap(void);
static unsigned int * default8To32Table(void);
static int deltaFromtonSteps(int x1, int x2, int n);
static int destMaskAndPointerInit(void);
static int destinationWordwith(int sourceWord, int destinationWord);
static int dither32To16threshold(int srcWord, int ditherValue);
static int drawLoopXY(int xDelta, int yDelta);
static int dstLongAt(int idx);
static int dstLongAtput(int idx, int value);
static int dstLongAtputmask(int idx, int srcValue, int dstMask);
static int expensiveDither32To16threshold(int srcWord, int ditherValue);
static int fetchIntOrFloatofObject(int fieldIndex, int objectPointer);
static int fetchIntOrFloatofObjectifNil(int fieldIndex, int objectPointer, int defaultValue);
static int fixAlphawith(int sourceWord, int destinationWord);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halftoneAt(int idx);
static int halt(void);
static int ignoreSourceOrHalftone(int formPointer);
static int initBBOpTable(void);
static int initDither8Lookup(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int isIdentityMapwith(int *shifts, unsigned int *masks);
static int loadBitBltDestForm(void);
#pragma export on
EXPORT(int) loadBitBltFrom(int bbObj);
#pragma export off
static int loadBitBltFromwarping(int bbObj, int aBool);
static int loadBitBltSourceForm(void);
static int loadColorMap(void);
static void * loadColorMapShiftOrMaskFrom(int mapOop);
static int loadHalftoneForm(void);
static int loadSurfacePlugin(void);
static int loadWarpBltFrom(int bbObj);
static int lockSurfaces(void);
static int mapPixelflags(int sourcePixel, int mapperFlags);
static int mergewith(int sourceWord, int destinationWord);
#pragma export on
EXPORT(int) moduleUnloaded(char * aModuleName);
#pragma export off
static int msg(char *s);
static int partitionedANDtonBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int partitionedAddtonBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int partitionedMaxwithnBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int partitionedMinwithnBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int partitionedMulwithnBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int partitionedSubfromnBitsnPartitions(int word1, int word2, int nBits, int nParts);
static int performCopyLoop(void);
static int pickSourcePixelsflagssrcMaskdestMasksrcShiftIncdstShiftInc(int nPixels, int mapperFlags, int srcMask, int dstMask, int srcShiftInc, int dstShiftInc);
static int pickWarpPixelAtXy(int xx, int yy);
static int pixClearwith(int sourceWord, int destinationWord);
static int pixMaskwith(int sourceWord, int destinationWord);
static int pixPaintwith(int sourceWord, int destinationWord);
static int pixSwapwith(int sourceWord, int destWord);
#pragma export on
EXPORT(int) primitiveCopyBits(void);
EXPORT(int) primitiveDisplayString(void);
EXPORT(int) primitiveDrawLoop(void);
EXPORT(int) primitiveWarpBits(void);
#pragma export off
static int queryDestSurface(int handle);
static int querySourceSurface(int handle);
static int rgbAddwith(int sourceWord, int destinationWord);
static int rgbDiffwith(int sourceWord, int destinationWord);
static int rgbMap16To32(int sourcePixel);
static int rgbMap32To32(int sourcePixel);
static int rgbMapfromto(int sourcePixel, int nBitsIn, int nBitsOut);
static int rgbMapPixelflags(int sourcePixel, int mapperFlags);
static int rgbMaxwith(int sourceWord, int destinationWord);
static int rgbMinwith(int sourceWord, int destinationWord);
static int rgbMinInvertwith(int wordToInvert, int destinationWord);
static int rgbMulwith(int sourceWord, int destinationWord);
static int rgbSubwith(int sourceWord, int destinationWord);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static int setupColorMasks(void);
static int setupColorMasksFromto(int srcBits, int targetBits);
static int showDisplayBits(void);
static int sourceSkewAndPointerInit(void);
static int sourceWordwith(int sourceWord, int destinationWord);
static int srcLongAt(int idx);
static int subWordwith(int sourceWord, int destinationWord);
static int tableLookupat(unsigned int * table, int index);
static int tallyIntoMapwith(int sourceWord, int destinationWord);
static int tallyMapAt(int idx);
static int tallyMapAtput(int idx, int value);
static int tryCopyingBitsQuickly(void);
static int unlockSurfaces(void);
static int warpBits(void);
static int warpLoop(void);
static int warpLoopSetup(void);
static int warpPickSmoothPixelsxDeltahyDeltahxDeltavyDeltavsourceMapsmoothingdstShiftInc(int nPixels, int xDeltah, int yDeltah, int xDeltav, int yDeltav, int sourceMap, int n, int dstShiftInc);
static int warpPickSourcePixelsxDeltahyDeltahxDeltavyDeltavdstShiftIncflags(int nPixels, int xDeltah, int yDeltah, int xDeltav, int yDeltav, int dstShiftInc, int mapperFlags);
/*** Variables ***/
static int affectedB;
static int affectedL;
static int affectedR;
static int affectedT;
static int bbH;
static int bbW;
static int bitBltOop;
static int bitCount;
static int clipHeight;
static int clipWidth;
static int clipX;
static int clipY;
static int cmBitsPerColor;
static int cmFlags;
static unsigned int *cmLookupTable;
static int cmMask;
static unsigned int *cmMaskTable;
static int *cmShiftTable;
static int combinationRule;
static int destBits;
static int destDelta;
static int destDepth;
static int destForm;
static int destHeight;
static int destIndex;
static int destMSB;
static int destMask;
static int destPPW;
static int destPitch;
static int destWidth;
static int destX;
static int destY;
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
static int dstBitShift;
static int dx;
static int dy;
static int hDir;
static int halftoneBase;
static int halftoneForm;
static int halftoneHeight;
static int hasSurfaceLock;
static int height;

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static int isWarping;
static int lockSurfaceFn;
static int mask1;
static int mask2;
static int maskTable[33] = {
0, 1, 3, 0, 15, 31, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 65535,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
};
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"BitBltPlugin 19 March 2005 (i)"
#else
	"BitBltPlugin 19 March 2005 (e)"
#endif
;
static int nWords;
static int noHalftone;
static int noSource;
static int opTable[42];
static int preload;
static int querySurfaceFn;
static int skew;
static int sourceAlpha;
static int sourceBits;
static int sourceDelta;
static int sourceDepth;
static int sourceForm;
static int sourceHeight;
static int sourceIndex;
static int sourceMSB;
static int sourcePPW;
static int sourcePitch;
static int sourceWidth;
static int sourceX;
static int sourceY;
static int srcBitShift;
static int sx;
static int sy;
static int unlockSurfaceFn;
static int vDir;
static int warpAlignMask;
static int warpAlignShift;
static int warpBitShiftTable[32];
static int warpSrcMask;
static int warpSrcShift;
static int width;



/*	Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, XOR the two and return the number of differing pixels.
	Note that the region is not clipped to bit boundaries, but only to the
	nearest (enclosing) word.  This is because copyLoop does not do
	pre-merge masking.  For accurate results, you must subtract the
	values obtained from the left and right fringes. */

static int OLDrgbDiffwith(int sourceWord, int destinationWord) {
    int diff;
    int pixMask;

	if (destDepth < 16) {
		diff = sourceWord ^ destinationWord;
		pixMask = maskTable[destDepth];
		while (!(diff == 0)) {
			if ((diff & pixMask) != 0) {
				bitCount += 1;
			}
			diff = ((unsigned) diff) >> destDepth;
		}
		return destinationWord;
	}
	if (destDepth == 16) {
		diff = partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 5, 3);
		bitCount = ((bitCount + (diff & 31)) + ((((unsigned) diff) >> 5) & 31)) + ((((unsigned) diff) >> 10) & 31);
		diff = partitionedSubfromnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3);
		bitCount = ((bitCount + (diff & 31)) + ((((unsigned) diff) >> 5) & 31)) + ((((unsigned) diff) >> 10) & 31);
	} else {
		diff = partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 8, 3);
		bitCount = ((bitCount + (diff & 255)) + ((((unsigned) diff) >> 8) & 255)) + ((((unsigned) diff) >> 16) & 255);
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

static int OLDtallyIntoMapwith(int sourceWord, int destinationWord) {
    int shiftWord;
    int pixMask;
    int i;
    int mapIndex;
    int srcPix;
    int d;
    int mask;
    int destPix;
    int srcPix1;
    int d1;
    int mask3;
    int destPix1;
    int srcPix2;
    int d2;
    int mask4;
    int destPix2;

	if (!((cmFlags & (ColorMapPresent | ColorMapIndexedPart)) == (ColorMapPresent | ColorMapIndexedPart))) {
		return destinationWord;
	}
	if (destDepth < 16) {
		pixMask = (maskTable[destDepth]) & cmMask;
		shiftWord = destinationWord;
		for (i = 1; i <= destPPW; i += 1) {
			mapIndex = shiftWord & pixMask;
			cmLookupTable[mapIndex & cmMask] = ((cmLookupTable[mapIndex & cmMask]) + 1);
			shiftWord = ((unsigned) shiftWord) >> destDepth;
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
			srcPix = ((unsigned) (destinationWord & 65535)) >> d;
			destPix = srcPix & mask;
			mask = mask << cmBitsPerColor;
			srcPix = ((unsigned) srcPix) >> d;
			destPix = (destPix + (srcPix & mask)) + ((((unsigned) srcPix) >> d) & (mask << cmBitsPerColor));
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
			srcPix1 = (((unsigned) destinationWord) >> 16) << d1;
			mask3 = mask3 << d1;
			destPix1 = srcPix1 & mask3;
			mask3 = mask3 << cmBitsPerColor;
			srcPix1 = srcPix1 << d1;
			mapIndex = (destPix1 + (srcPix1 & mask3)) + ((srcPix1 << d1) & (mask3 << cmBitsPerColor));
			goto l2;
		} else {
			if (d1 == 0) {
				if (5 == 5) {
					mapIndex = (((unsigned) destinationWord) >> 16) & 32767;
					goto l2;
				}
				if (5 == 8) {
					mapIndex = (((unsigned) destinationWord) >> 16) & 16777215;
					goto l2;
				}
				mapIndex = ((unsigned) destinationWord) >> 16;
				goto l2;
			}
			if ((((unsigned) destinationWord) >> 16) == 0) {
				mapIndex = ((unsigned) destinationWord) >> 16;
				goto l2;
			}
			d1 = 5 - cmBitsPerColor;
			mask3 = (1 << cmBitsPerColor) - 1;
			srcPix1 = ((unsigned) (((unsigned) destinationWord) >> 16)) >> d1;
			destPix1 = srcPix1 & mask3;
			mask3 = mask3 << cmBitsPerColor;
			srcPix1 = ((unsigned) srcPix1) >> d1;
			destPix1 = (destPix1 + (srcPix1 & mask3)) + ((((unsigned) srcPix1) >> d1) & (mask3 << cmBitsPerColor));
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
			srcPix2 = ((unsigned) destinationWord) >> d2;
			destPix2 = srcPix2 & mask4;
			mask4 = mask4 << cmBitsPerColor;
			srcPix2 = ((unsigned) srcPix2) >> d2;
			destPix2 = (destPix2 + (srcPix2 & mask4)) + ((((unsigned) srcPix2) >> d2) & (mask4 << cmBitsPerColor));
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

static int addWordwith(int sourceWord, int destinationWord) {
	return sourceWord + destinationWord;
}

static int affectedBottom(void) {
	return affectedB;
}

static int affectedLeft(void) {
	return affectedL;
}

static int affectedRight(void) {
	return affectedR;
}

static int affectedTop(void) {
	return affectedT;
}


/*	Blend sourceWord with destinationWord, assuming both are 32-bit pixels.
	The source is assumed to have 255*alpha in the high 8 bits of each pixel,
	while the high 8 bits of the destinationWord will be ignored.
	The blend produced is alpha*source + (1-alpha)*dest, with
	the computation being performed independently on each color
	component.  The high byte of the result will be 0. */

static int alphaBlendwith(int sourceWord, int destinationWord) {
    int result;
    int unAlpha;
    int shift;
    int colorMask;
    int blend;
    int alpha;


	/* High 8 bits of source pixel */

	alpha = ((unsigned) sourceWord) >> 24;
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
	blend = ((((((((unsigned) sourceWord) >> shift) & colorMask) * alpha) + (((((unsigned) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* green */

	result = result | (blend << shift);
	shift = 8;
	blend = ((((((((unsigned) sourceWord) >> shift) & colorMask) * alpha) + (((((unsigned) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* blue */

	result = result | (blend << shift);
	shift = 16;
	blend = ((((((((unsigned) sourceWord) >> shift) & colorMask) * alpha) + (((((unsigned) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;

	/* alpha (pre-multiplied) */

	result = result | (blend << shift);
	shift = 24;
	blend = ((((alpha * 255) + (((((unsigned) destinationWord) >> shift) & colorMask) * unAlpha)) + 254) / 255) & colorMask;
	result = result | (blend << shift);
	return result;
}

static int alphaBlendConstwith(int sourceWord, int destinationWord) {
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

static int alphaBlendConstwithpaintMode(int sourceWord, int destinationWord, int paintMode) {
    int destShifted;
    int result;
    int sourceShifted;
    int rgbMask;
    int unAlpha;
    int shift;
    int bitsPerColor;
    int blend;
    int pixMask;
    int sourcePixVal;
    int i;
    int pixBlend;
    int maskShifted;
    int j;
    int destPixVal;

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
				blend = ((((((((unsigned) sourceWord) >> shift) & rgbMask) * sourceAlpha) + (((((unsigned) destinationWord) >> shift) & rgbMask) * unAlpha)) + 254) / 255) & rgbMask;
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
					blend = ((((((((unsigned) sourcePixVal) >> shift) & rgbMask) * sourceAlpha) + (((((unsigned) destPixVal) >> shift) & rgbMask) * unAlpha)) + 254) / 255) & rgbMask;
					pixBlend = pixBlend | (blend << shift);
				}
				if (destDepth == 16) {
					result = (result & (~(pixMask << ((j - 1) * 16)))) | (pixBlend << ((j - 1) * 16));
				} else {
					result = pixBlend;
				}
			}
			maskShifted = ((unsigned) maskShifted) >> destDepth;
			sourceShifted = ((unsigned) sourceShifted) >> destDepth;
			destShifted = ((unsigned) destShifted) >> destDepth;
		}
	}
	return result;
}


/*	Blend sourceWord with destinationWord using the alpha value from sourceWord.
	Alpha is encoded as 0 meaning 0.0, and 255 meaning 1.0.
	In contrast to alphaBlend:with: the color produced is

		srcColor + (1-srcAlpha) * dstColor

	e.g., it is assumed that the source color is already scaled. */

static int alphaBlendScaledwith(int sourceWord, int destinationWord) {
    int a;
    int dstMask;
    int b;
    int g;
    int unAlpha;
    int r;
    int srcMask;


	/* High 8 bits of source pixel */

	unAlpha = 255 - (((unsigned) sourceWord) >> 24);
	dstMask = destinationWord;
	srcMask = sourceWord;
	b = (((unsigned) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (b > 255) {
		b = 255;
	}
	dstMask = ((unsigned) dstMask) >> 8;
	srcMask = ((unsigned) srcMask) >> 8;
	g = (((unsigned) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (g > 255) {
		g = 255;
	}
	dstMask = ((unsigned) dstMask) >> 8;
	srcMask = ((unsigned) srcMask) >> 8;
	r = (((unsigned) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (r > 255) {
		r = 255;
	}
	dstMask = ((unsigned) dstMask) >> 8;
	srcMask = ((unsigned) srcMask) >> 8;
	a = (((unsigned) ((dstMask & 255) * unAlpha)) >> 8) + (srcMask & 255);
	if (a > 255) {
		a = 255;
	}
	return (((((a << 8) + r) << 8) + g) << 8) + b;
}

static int alphaPaintConstwith(int sourceWord, int destinationWord) {
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

static int alphaSourceBlendBits16(void) {
    int srcAlpha;
    int dstIndex;
    int deltaX;
    int dstMask;
    int ditherBase;
    int deltaY;
    int dstY;
    int ditherIndex;
    int srcY;
    int srcShift;
    int ditherThreshold;
    int srcIndex;
    int sourceWord;
    int destWord;
    int addThreshold;
    int addThreshold1;
    int dstValue;
    int dstValue1;


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
		dstIndex = (destBits + (dstY * destPitch)) + ((((int) dx >> 1)) * 4);
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
			sourceWord = longAt(srcIndex);
			srcAlpha = ((unsigned) sourceWord) >> 24;
			if (srcAlpha == 255) {
				/* begin dither32To16:threshold: */
				addThreshold = ((unsigned) ditherThreshold << 8);
				sourceWord = ((((unsigned) (dither8Lookup[addThreshold + ((((unsigned) sourceWord >> 16)) & 255)]) << 10)) + (((unsigned) (dither8Lookup[addThreshold + ((((unsigned) sourceWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold + (sourceWord & 255)]);
				if (sourceWord == 0) {
					sourceWord = 1 << srcShift;
				} else {
					sourceWord = sourceWord << srcShift;
				}
				/* begin dstLongAt:put:mask: */
				dstValue = longAt(dstIndex);
				dstValue = dstValue & dstMask;
				dstValue = dstValue | sourceWord;
				longAtput(dstIndex, dstValue);
			} else {
				if (!(srcAlpha == 0)) {
					destWord = longAt(dstIndex);
					destWord = destWord & (~dstMask);

					/* Expand from 16 to 32 bit by adding zero bits */

					destWord = ((unsigned) destWord) >> srcShift;

					/* Mix colors */

					destWord = ((((unsigned) (destWord & 31744) << 9)) | (((unsigned) (destWord & 992) << 6))) | ((((unsigned) (destWord & 31) << 3)) | 4278190080U);

					/* And dither */

					sourceWord = alphaBlendScaledwith(sourceWord, destWord);
					/* begin dither32To16:threshold: */
					addThreshold1 = ((unsigned) ditherThreshold << 8);
					sourceWord = ((((unsigned) (dither8Lookup[addThreshold1 + ((((unsigned) sourceWord >> 16)) & 255)]) << 10)) + (((unsigned) (dither8Lookup[addThreshold1 + ((((unsigned) sourceWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold1 + (sourceWord & 255)]);
					if (sourceWord == 0) {
						sourceWord = 1 << srcShift;
					} else {
						sourceWord = sourceWord << srcShift;
					}
					/* begin dstLongAt:put:mask: */
					dstValue1 = longAt(dstIndex);
					dstValue1 = dstValue1 & dstMask;
					dstValue1 = dstValue1 | sourceWord;
					longAtput(dstIndex, dstValue1);
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

static int alphaSourceBlendBits32(void) {
    int srcAlpha;
    register int dstIndex;
    register int deltaX;
    int deltaY;
    int dstY;
    int srcY;
    register int srcIndex;
    register int sourceWord;
    int destWord;


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
			sourceWord = longAt(srcIndex);
			srcAlpha = ((unsigned) sourceWord) >> 24;
			if (srcAlpha == 255) {
				longAtput(dstIndex, sourceWord);
				srcIndex += 4;

				/* Now copy as many words as possible with alpha = 255 */

				dstIndex += 4;
				while (((deltaX -= 1) != 0) && ((((unsigned) (sourceWord = longAt(srcIndex))) >> 24) == 255)) {
					longAtput(dstIndex, sourceWord);
					srcIndex += 4;
					dstIndex += 4;
				}
				deltaX += 1;
			} else {
				if (srcAlpha == 0) {
					srcIndex += 4;

					/* Now skip as many words as possible, */

					dstIndex += 4;
					while (((deltaX -= 1) != 0) && ((((unsigned) (sourceWord = longAt(srcIndex))) >> 24) == 0)) {
						srcIndex += 4;
						dstIndex += 4;
					}
					deltaX += 1;
				} else {
					destWord = longAt(dstIndex);
					destWord = alphaBlendScaledwith(sourceWord, destWord);
					longAtput(dstIndex, destWord);
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

static int alphaSourceBlendBits8(void) {
    int srcAlpha;
    int dstIndex;
    int deltaX;
    int dstMask;
    int mapperFlags;
    int adjust;
    int deltaY;
    int dstY;
    int srcY;
    int srcShift;
    unsigned int *mappingTable;
    int srcIndex;
    int sourceWord;
    int destWord;
    int pv;
    int val;
    int dstValue;

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
		dstIndex = (destBits + (dstY * destPitch)) + ((((int) dx >> 2)) * 4);

		/* So we can pre-decrement */

		deltaX = bbW + 1;
		srcShift = mask1;

		/* This is the inner loop */

		dstMask = mask2;
		while ((deltaX -= 1) != 0) {
			sourceWord = ((longAt(srcIndex)) & (~adjust)) + adjust;
			srcAlpha = ((unsigned) sourceWord) >> 24;
			if (srcAlpha > 31) {
				if (srcAlpha < 224) {
					destWord = longAt(dstIndex);
					destWord = destWord & (~dstMask);
					destWord = ((unsigned) destWord) >> srcShift;
					destWord = mappingTable[destWord];
					sourceWord = alphaBlendScaledwith(sourceWord, destWord);
				}
				/* begin mapPixel:flags: */
				pv = sourceWord;
				if ((mapperFlags & ColorMapPresent) != 0) {
					if ((mapperFlags & ColorMapFixedPart) != 0) {
						/* begin rgbMapPixel:flags: */
						val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourceWord & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourceWord & (cmMaskTable[0])) << (cmShiftTable[0])));
						val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourceWord & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourceWord & (cmMaskTable[1])) << (cmShiftTable[1]))));
						val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourceWord & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourceWord & (cmMaskTable[2])) << (cmShiftTable[2]))));
						pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourceWord & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourceWord & (cmMaskTable[3])) << (cmShiftTable[3]))));
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
				dstValue = longAt(dstIndex);
				dstValue = dstValue & dstMask;
				dstValue = dstValue | sourceWord;
				longAtput(dstIndex, dstValue);
			}
			srcIndex += 4;
			if (destMSB) {
				if (srcShift == 0) {
					dstIndex += 4;
					srcShift = 24;
					dstMask = 16777215;
				} else {
					srcShift -= 8;
					dstMask = (((unsigned) dstMask) >> 8) | 4278190080U;
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

static int bitAndwith(int sourceWord, int destinationWord) {
	return sourceWord & destinationWord;
}

static int bitAndInvertwith(int sourceWord, int destinationWord) {
	return sourceWord & (~destinationWord);
}

static int bitInvertAndwith(int sourceWord, int destinationWord) {
	return (~sourceWord) & destinationWord;
}

static int bitInvertAndInvertwith(int sourceWord, int destinationWord) {
	return (~sourceWord) & (~destinationWord);
}

static int bitInvertDestinationwith(int sourceWord, int destinationWord) {
	return ~destinationWord;
}

static int bitInvertOrwith(int sourceWord, int destinationWord) {
	return (~sourceWord) | destinationWord;
}

static int bitInvertOrInvertwith(int sourceWord, int destinationWord) {
	return (~sourceWord) | (~destinationWord);
}

static int bitInvertSourcewith(int sourceWord, int destinationWord) {
	return ~sourceWord;
}

static int bitInvertXorwith(int sourceWord, int destinationWord) {
	return (~sourceWord) ^ destinationWord;
}

static int bitOrwith(int sourceWord, int destinationWord) {
	return sourceWord | destinationWord;
}

static int bitOrInvertwith(int sourceWord, int destinationWord) {
	return sourceWord | (~destinationWord);
}

static int bitXorwith(int sourceWord, int destinationWord) {
	return sourceWord ^ destinationWord;
}


/*	check for possible overlap of source and destination */
/*	ar 10/19/1999: This method requires surfaces to be locked. */

static int checkSourceOverlap(void) {
    int t;

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

static int clearWordwith(int source, int destination) {
	return 0;
}


/*	clip and adjust source origin and extent appropriately */
/*	first in x */

static int clipRange(void) {
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

EXPORT(int) copyBits(void) {
    int done;
    int dxLowBits;
    int pixPerM1;
    int sxLowBits;
    int dWid;
    int t;
    int endBits;
    int pixPerM11;
    int startBits;

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
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

EXPORT(int) copyBitsFromtoat(int startX, int stopX, int yValue) {
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

static int copyBitsLockedAndClipped(void) {
    int done;
    int dxLowBits;
    int pixPerM1;
    int sxLowBits;
    int dWid;
    int t;
    int endBits;
    int pixPerM11;
    int startBits;

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
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

static int copyLoop(void) {
    int nWordsMinusOne;
    int skewWord;
    int vDirLocal;
    int word;
    int skewMask;
    int notSkewMask;
    int thisWord;
    int y;
    int destWord;
    int hDirLocal;
    int mergeWord;
    int hInc;
    int prevWord;
    int halftoneWord;
    int skewLocal;
    int (*mergeFnwith)(int, int);
    int i;
    int unskew;
    int sourceIndexLocal;
    int destIndexLocal;

	mergeFnwith = ((int (*)(int, int)) (opTable[combinationRule + 1]));
	mergeFnwith;
	hInc = hDir * 4;
	skewLocal = skew;
	sourceIndexLocal = sourceIndex;
	destIndexLocal = destIndex;
	vDirLocal = vDir;
	hDirLocal = hDir;

	/* Byte delta */
	/* degenerate skew fixed for Sparc. 10/20/96 ikp */

	nWordsMinusOne = nWords - 1;
	if (skewLocal == -32) {
		skewLocal = unskew = skewMask = 0;
	} else {
		if (skewLocal < 0) {
			unskew = skewLocal + 32;
			skewMask = AllOnes << (0 - skewLocal);
		} else {
			if (skewLocal == 0) {
				unskew = 0;
				skewMask = AllOnes;
			} else {
				unskew = skewLocal - 32;
				skewMask = ((unsigned) AllOnes) >> skewLocal;
			}
		}
	}
	notSkewMask = ~skewMask;
	if (noHalftone) {
		halftoneWord = AllOnes;
		halftoneHeight = 0;
	} else {
		halftoneWord = longAt(halftoneBase + ((0 % halftoneHeight) * 4));
	}
	y = dy;
	for (i = 1; i <= bbH; i += 1) {
		if (halftoneHeight > 1) {
			halftoneWord = longAt(halftoneBase + ((y % halftoneHeight) * 4));
			y += vDirLocal;
		}
		if (preload) {
			prevWord = longAt(sourceIndexLocal);
			sourceIndexLocal += hInc;
		} else {
			prevWord = 0;
		}
		destMask = mask1;

		/* pick up next word */

		thisWord = longAt(sourceIndexLocal);
		sourceIndexLocal += hInc;

		/* 32-bit rotate */

		skewWord = (((unskew < 0) ? ((unsigned) (prevWord & notSkewMask) >> -unskew) : ((unsigned) (prevWord & notSkewMask) << unskew))) | (((skewLocal < 0) ? ((unsigned) (thisWord & skewMask) >> -skewLocal) : ((unsigned) (thisWord & skewMask) << skewLocal)));
		prevWord = thisWord;
		destWord = longAt(destIndexLocal);
		mergeWord = mergeFnwith(skewWord & halftoneWord, destWord);
		destWord = (destMask & mergeWord) | (destWord & (~destMask));
		longAtput(destIndexLocal, destWord);

		/* This central horizontal loop requires no store masking */

		destIndexLocal += hInc;
		destMask = AllOnes;
		if (combinationRule == 3) {
			if ((skewLocal == 0) && (halftoneWord == AllOnes)) {
				if (hDirLocal == -1) {
					for (word = 2; word <= nWordsMinusOne; word += 1) {
						thisWord = longAt(sourceIndexLocal);
						sourceIndexLocal += hInc;
						longAtput(destIndexLocal, thisWord);
						destIndexLocal += hInc;
					}
				} else {
					for (word = 2; word <= nWordsMinusOne; word += 1) {
						longAtput(destIndexLocal, prevWord);
						destIndexLocal += hInc;
						prevWord = longAt(sourceIndexLocal);
						sourceIndexLocal += hInc;
					}
				}
			} else {
				for (word = 2; word <= nWordsMinusOne; word += 1) {
					thisWord = longAt(sourceIndexLocal);
					sourceIndexLocal += hInc;

					/* 32-bit rotate */

					skewWord = (((unskew < 0) ? ((unsigned) (prevWord & notSkewMask) >> -unskew) : ((unsigned) (prevWord & notSkewMask) << unskew))) | (((skewLocal < 0) ? ((unsigned) (thisWord & skewMask) >> -skewLocal) : ((unsigned) (thisWord & skewMask) << skewLocal)));
					prevWord = thisWord;
					longAtput(destIndexLocal, skewWord & halftoneWord);
					destIndexLocal += hInc;
				}
			}
		} else {
			for (word = 2; word <= nWordsMinusOne; word += 1) {

				/* pick up next word */

				thisWord = longAt(sourceIndexLocal);
				sourceIndexLocal += hInc;

				/* 32-bit rotate */

				skewWord = (((unskew < 0) ? ((unsigned) (prevWord & notSkewMask) >> -unskew) : ((unsigned) (prevWord & notSkewMask) << unskew))) | (((skewLocal < 0) ? ((unsigned) (thisWord & skewMask) >> -skewLocal) : ((unsigned) (thisWord & skewMask) << skewLocal)));
				prevWord = thisWord;
				mergeWord = mergeFnwith(skewWord & halftoneWord, longAt(destIndexLocal));
				longAtput(destIndexLocal, mergeWord);
				destIndexLocal += hInc;
			}
		}
		if (nWords > 1) {
			destMask = mask2;

			/* pick up next word */

			thisWord = longAt(sourceIndexLocal);
			sourceIndexLocal += hInc;

			/* 32-bit rotate */

			skewWord = (((unskew < 0) ? ((unsigned) (prevWord & notSkewMask) >> -unskew) : ((unsigned) (prevWord & notSkewMask) << unskew))) | (((skewLocal < 0) ? ((unsigned) (thisWord & skewMask) >> -skewLocal) : ((unsigned) (thisWord & skewMask) << skewLocal)));
			destWord = longAt(destIndexLocal);
			mergeWord = mergeFnwith(skewWord & halftoneWord, destWord);
			destWord = (destMask & mergeWord) | (destWord & (~destMask));
			longAtput(destIndexLocal, destWord);
			destIndexLocal += hInc;
		}
		sourceIndexLocal += sourceDelta;
		destIndexLocal += destDelta;
	}
}


/*	Faster copyLoop when source not used. hDir and vDir are both  
	positive, and perload and skew are unused */

static int copyLoopNoSource(void) {
    int mergeWord;
    int nWordsMinusOne;
    int halftoneWord;
    int (*mergeFnwith)(int, int);
    int word;
    int i;
    int destWord;
    int destIndexLocal;

	mergeFnwith = ((int (*)(int, int)) (opTable[combinationRule + 1]));
	mergeFnwith;
	destIndexLocal = destIndex;
	nWordsMinusOne = nWords - 1;
	for (i = 1; i <= bbH; i += 1) {
		if (noHalftone) {
			halftoneWord = AllOnes;
		} else {
			halftoneWord = longAt(halftoneBase + ((((dy + i) - 1) % halftoneHeight) * 4));
		}
		destMask = mask1;
		destWord = longAt(destIndexLocal);
		mergeWord = mergeFnwith(halftoneWord, destWord);
		destWord = (destMask & mergeWord) | (destWord & (~destMask));
		longAtput(destIndexLocal, destWord);

		/* This central horizontal loop requires no store masking */

		destIndexLocal += 4;
		destMask = AllOnes;
		if (combinationRule == 3) {
			destWord = halftoneWord;
			for (word = 2; word <= nWordsMinusOne; word += 1) {
				longAtput(destIndexLocal, destWord);
				destIndexLocal += 4;
			}
		} else {
			for (word = 2; word <= nWordsMinusOne; word += 1) {
				destWord = longAt(destIndexLocal);
				mergeWord = mergeFnwith(halftoneWord, destWord);
				longAtput(destIndexLocal, mergeWord);
				destIndexLocal += 4;
			}
		}
		if (nWords > 1) {
			destMask = mask2;
			destWord = longAt(destIndexLocal);
			mergeWord = mergeFnwith(halftoneWord, destWord);
			destWord = (destMask & mergeWord) | (destWord & (~destMask));
			longAtput(destIndexLocal, destWord);
			destIndexLocal += 4;
		}
		destIndexLocal += destDelta;
	}
}


/*	This version of the inner loop maps source pixels  
	to a destination form with different depth. Because it is already  
	unweildy, the loop is not unrolled as in the other versions.  
	Preload, skew and skewMask are all overlooked, since pickSourcePixels  
	delivers its destination word already properly aligned.  
	Note that pickSourcePixels could be copied in-line at the top of  
	the horizontal loop, and some of its inits moved out of the loop. */
/*	ar 12/7/1999:  
	The loop has been rewritten to use only one pickSourcePixels call.  
	The idea is that the call itself could be inlined. If we decide not  
	to inline pickSourcePixels we could optimize the loop instead. */

static int copyLoopPixMap(void) {
    int nPix;
    int endBits;
    int dstShiftLeft;
    int mapperFlags;
    int skewWord;
    int sourcePixMask;
    int srcShift;
    int nSourceIncs;
    int scrStartBits;
    int dstShiftInc;
    int words;
    int destWord;
    int mergeWord;
    int srcShiftInc;
    int destPixMask;
    int halftoneWord;
    int (*mergeFnwith)(int, int);
    int i;
    int dstShift;
    int startBits;
    int destIndexLocal;
    int nPix1;
    int sourcePix;
    int srcShift1;
    int sourceWord;
    int dstShift1;
    int destWord1;
    int destPix;
    int idx;
    int idx1;
    int pv;
    int val;

	mergeFnwith = ((int (*)(int, int)) (opTable[combinationRule + 1]));
	mergeFnwith;

	/* Additional inits peculiar to unequal source and dest pix size... */

	destIndexLocal = destIndex;
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
			halftoneWord = longAt(halftoneBase + ((((dy + i) - 1) % halftoneHeight) * 4));
		}
		srcBitShift = srcShift;
		dstBitShift = dstShift;
		destMask = mask1;

		/* Here is the horizontal loop... */

		nPix = startBits;
		words = nWords;
		do {
			/* begin pickSourcePixels:flags:srcMask:destMask:srcShiftInc:dstShiftInc: */
			sourceWord = longAt(sourceIndex);
			destWord1 = 0;
			srcShift1 = srcBitShift;
			dstShift1 = dstBitShift;
			nPix1 = nPix;
			if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
				do {
					sourcePix = (((unsigned) sourceWord) >> srcShift1) & sourcePixMask;
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
						idx = sourceIndex += 4;
						sourceWord = longAt(idx);
					}
				} while(!((nPix1 -= 1) == 0));
			} else {
				do {
					sourcePix = (((unsigned) sourceWord) >> srcShift1) & sourcePixMask;
					/* begin mapPixel:flags: */
					pv = sourcePix;
					if ((mapperFlags & ColorMapPresent) != 0) {
						if ((mapperFlags & ColorMapFixedPart) != 0) {
							/* begin rgbMapPixel:flags: */
							val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
							val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
							val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
							pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
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
						idx1 = sourceIndex += 4;
						sourceWord = longAt(idx1);
					}
				} while(!((nPix1 -= 1) == 0));
			}
			srcBitShift = srcShift1;
			skewWord = destWord1;
			dstBitShift = dstShiftLeft;
			if (destMask == AllOnes) {
				mergeWord = mergeFnwith(skewWord & halftoneWord, longAt(destIndexLocal));
				longAtput(destIndexLocal, destMask & mergeWord);
			} else {
				destWord = longAt(destIndexLocal);
				mergeWord = mergeFnwith(skewWord & halftoneWord, destWord & destMask);
				destWord = (destMask & mergeWord) | (destWord & (~destMask));
				longAtput(destIndexLocal, destWord);
			}
			destIndexLocal += 4;
			if (words == 2) {
				destMask = mask2;
				nPix = endBits;
			} else {
				destMask = AllOnes;
				nPix = destPPW;
			}
		} while(!((words -= 1) == 0));
		sourceIndex += sourceDelta;
		destIndexLocal += destDelta;
	}
}


/*	Return the default translation table from 1..8 bit indexed colors to 32bit */
/*	The table has been generated by the following statements */
/*	| pvs hex |
	String streamContents:[:s|
		s nextPutAll:'static unsigned int theTable[256] = { '.
		pvs _ (Color colorMapIfNeededFrom: 8 to: 32) asArray.
		1 to: pvs size do:[:i|
			i > 1 ifTrue:[s nextPutAll:', '].
			(i-1 \\ 8) = 0 ifTrue:[s cr].
			s nextPutAll:'0x'.
			hex _ (pvs at: i) printStringBase: 16.
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

static int deltaFromtonSteps(int x1, int x2, int n) {
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

static int destMaskAndPointerInit(void) {
    int endBits;
    int pixPerM1;
    int startBits;


	/* A mask, assuming power of two */
	/* how many pixels in first word */

	pixPerM1 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM1);
	if (destMSB) {
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

static int destinationWordwith(int sourceWord, int destinationWord) {
	return destinationWord;
}


/*	Dither the given 32bit word to 16 bit. Ignore alpha. */

static int dither32To16threshold(int srcWord, int ditherValue) {
    int addThreshold;

	addThreshold = ((unsigned) ditherValue << 8);
	return ((((unsigned) (dither8Lookup[addThreshold + ((((unsigned) srcWord >> 16)) & 255)]) << 10)) + (((unsigned) (dither8Lookup[addThreshold + ((((unsigned) srcWord >> 8)) & 255)]) << 5))) + (dither8Lookup[addThreshold + (srcWord & 255)]);
}


/*	This is the primitive implementation of the line-drawing loop.
	See the comments in BitBlt>>drawLoopX:Y: */

static int drawLoopXY(int xDelta, int yDelta) {
    int affL;
    int affB;
    int affR;
    int P;
    int i;
    int affT;
    int dx1;
    int px;
    int dy1;
    int py;

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
		P = ((int) py >> 1);
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
		P = ((int) px >> 1);
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

static int dstLongAt(int idx) {
	return longAt(idx);
}

static int dstLongAtput(int idx, int value) {
	return longAtput(idx, value);
}


/*	Store the given value back into destination form, using dstMask
	to mask out the bits to be modified. This is an essiantial
	read-modify-write operation on the destination form. */

static int dstLongAtputmask(int idx, int srcValue, int dstMask) {
    int dstValue;

	dstValue = longAt(idx);
	dstValue = dstValue & dstMask;
	dstValue = dstValue | srcValue;
	longAtput(idx, dstValue);
}


/*	Dither the given 32bit word to 16 bit. Ignore alpha. */

static int expensiveDither32To16threshold(int srcWord, int ditherValue) {
    int value;
    int out;
    int pv;
    int threshold;

	pv = srcWord & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((unsigned) pv >> 3)];
	if (ditherValue < threshold) {
		out = value + 1;
	} else {
		out = value;
	}
	pv = (((unsigned) srcWord >> 8)) & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((unsigned) pv >> 3)];
	if (ditherValue < threshold) {
		out = out | (((unsigned) (value + 1) << 5));
	} else {
		out = out | (((unsigned) value << 5));
	}
	pv = (((unsigned) srcWord >> 16)) & 255;
	threshold = ditherThresholds16[pv & 7];
	value = ditherValues16[((unsigned) pv >> 3)];
	if (ditherValue < threshold) {
		out = out | (((unsigned) (value + 1) << 10));
	} else {
		out = out | (((unsigned) value << 10));
	}
	return out;
}


/*	Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers. */

static int fetchIntOrFloatofObject(int fieldIndex, int objectPointer) {
    double floatValue;
    int fieldOop;

	fieldOop = interpreterProxy->fetchPointerofObject(fieldIndex, objectPointer);
	if ((fieldOop & 1)) {
		return (fieldOop >> 1);
	}
	floatValue = interpreterProxy->floatValueOf(fieldOop);
	if (!((-2.147483648e9 <= floatValue) && (floatValue <= 2.147483647e9))) {
		interpreterProxy->primitiveFail();
		return 0;
	}
	return ((int) floatValue );
}


/*	Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers. */

static int fetchIntOrFloatofObjectifNil(int fieldIndex, int objectPointer, int defaultValue) {
    double floatValue;
    int fieldOop;

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
	return ((int) floatValue );
}


/*	For any non-zero pixel value in destinationWord with zero alpha channel take the alpha from sourceWord and fill it in. Intended for fixing alpha channels left at zero during 16->32 bpp conversions. */

static int fixAlphawith(int sourceWord, int destinationWord) {
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


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}


/*	Return a value from the halftone pattern. */

static int halftoneAt(int idx) {
	return longAt(halftoneBase + ((idx % halftoneHeight) * 4));
}

static int halt(void) {
	;
}

static int ignoreSourceOrHalftone(int formPointer) {
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

static int initBBOpTable(void) {
	opTable[0+1] = (int)clearWordwith;
	opTable[1+1] = (int)bitAndwith;
	opTable[2+1] = (int)bitAndInvertwith;
	opTable[3+1] = (int)sourceWordwith;
	opTable[4+1] = (int)bitInvertAndwith;
	opTable[5+1] = (int)destinationWordwith;
	opTable[6+1] = (int)bitXorwith;
	opTable[7+1] = (int)bitOrwith;
	opTable[8+1] = (int)bitInvertAndInvertwith;
	opTable[9+1] = (int)bitInvertXorwith;
	opTable[10+1] = (int)bitInvertDestinationwith;
	opTable[11+1] = (int)bitOrInvertwith;
	opTable[12+1] = (int)bitInvertSourcewith;
	opTable[13+1] = (int)bitInvertOrwith;
	opTable[14+1] = (int)bitInvertOrInvertwith;
	opTable[15+1] = (int)destinationWordwith;
	opTable[16+1] = (int)destinationWordwith;
	opTable[17+1] = (int)destinationWordwith;
	opTable[18+1] = (int)addWordwith;
	opTable[19+1] = (int)subWordwith;
	opTable[20+1] = (int)rgbAddwith;
	opTable[21+1] = (int)rgbSubwith;
	opTable[22+1] = (int)OLDrgbDiffwith;
	opTable[23+1] = (int)OLDtallyIntoMapwith;
	opTable[24+1] = (int)alphaBlendwith;
	opTable[25+1] = (int)pixPaintwith;
	opTable[26+1] = (int)pixMaskwith;
	opTable[27+1] = (int)rgbMaxwith;
	opTable[28+1] = (int)rgbMinwith;
	opTable[29+1] = (int)rgbMinInvertwith;
	opTable[30+1] = (int)alphaBlendConstwith;
	opTable[31+1] = (int)alphaPaintConstwith;
	opTable[32+1] = (int)rgbDiffwith;
	opTable[33+1] = (int)tallyIntoMapwith;
	opTable[34+1] = (int)alphaBlendScaledwith;
	opTable[35+1] = (int)alphaBlendScaledwith;
	opTable[36+1] = (int)alphaBlendScaledwith;
	opTable[37+1] = (int)rgbMulwith;
	opTable[38+1] = (int)pixSwapwith;
	opTable[39+1] = (int)pixClearwith;
	opTable[40+1] = (int)fixAlphawith;
}

static int initDither8Lookup(void) {
    int b;
    int value;
    int t;
    int value1;
    int out;
    int pv;
    int threshold;

	for (b = 0; b <= 255; b += 1) {
		for (t = 0; t <= 15; t += 1) {
			/* begin expensiveDither32To16:threshold: */
			pv = b & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((unsigned) pv >> 3)];
			if (t < threshold) {
				out = value1 + 1;
			} else {
				out = value1;
			}
			pv = (((unsigned) b >> 8)) & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((unsigned) pv >> 3)];
			if (t < threshold) {
				out = out | (((unsigned) (value1 + 1) << 5));
			} else {
				out = out | (((unsigned) value1 << 5));
			}
			pv = (((unsigned) b >> 16)) & 255;
			threshold = ditherThresholds16[pv & 7];
			value1 = ditherValues16[((unsigned) pv >> 3)];
			if (t < threshold) {
				out = out | (((unsigned) (value1 + 1) << 10));
			} else {
				out = out | (((unsigned) value1 << 10));
			}
			value = out;
			dither8Lookup[(t << 8) + b] = value;
		}
	}
}

EXPORT(int) initialiseModule(void) {
	initBBOpTable();
	initDither8Lookup();
	return 1;
}


/*	Return true if shiftTable/maskTable define an identity mapping. */

static int isIdentityMapwith(int *shifts, unsigned int *masks) {
	if ((shifts == null) || (masks == null)) {
		return 1;
	}
	if (((shifts[RedIndex]) == 0) && (((shifts[GreenIndex]) == 0) && (((shifts[BlueIndex]) == 0) && (((shifts[AlphaIndex]) == 0) && (((masks[RedIndex]) == 16711680) && (((masks[GreenIndex]) == 65280) && (((masks[BlueIndex]) == 255) && ((masks[AlphaIndex]) == 4278190080U)))))))) {
		return 1;
	}
	return 0;
}


/*	Load the dest form for BitBlt. Return false if anything is wrong, true otherwise. */

static int loadBitBltDestForm(void) {
    int destBitsSize;

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
		destBits = ((int) (interpreterProxy->firstIndexableField(destBits)));
	}
	return 1;
}


/*	Load BitBlt from the oop.
	This function is exported for the Balloon engine. */

EXPORT(int) loadBitBltFrom(int bbObj) {
	return loadBitBltFromwarping(bbObj, 0);
}


/*	Load context from BitBlt instance.  Return false if anything is amiss */
/*	NOTE this should all be changed to minX/maxX coordinates for simpler clipping
		-- once it works! */

static int loadBitBltFromwarping(int bbObj, int aBool) {
    int ok;
    int sourceBitsSize;
    int formPointer;
    int formPointer1;
    int destBitsSize;
    int halftoneBits;
    int cmSize;
    int cmOop;
    int oop;
    int oldStyle;
    int mapOop;
    int mapOop1;

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
		destBits = ((int) (interpreterProxy->firstIndexableField(destBits)));
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
			sourceBits = ((int) (interpreterProxy->firstIndexableField(sourceBits)));
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
	halftoneBase = ((int) (interpreterProxy->firstIndexableField(halftoneBits)));
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

static int loadBitBltSourceForm(void) {
    int sourceBitsSize;

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
		sourceBits = ((int) (interpreterProxy->firstIndexableField(sourceBits)));
	}
	return 1;
}


/*	ColorMap, if not nil, must be longWords, and 
	2^N long, where N = sourceDepth for 1, 2, 4, 8 bits, 
	or N = 9, 12, or 15 (3, 4, 5 bits per color) for 16 or 32 bits. */

static int loadColorMap(void) {
    int cmSize;
    int cmOop;
    int oop;
    int oldStyle;
    int mapOop;
    int mapOop1;

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

static void * loadColorMapShiftOrMaskFrom(int mapOop) {
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

static int loadHalftoneForm(void) {
    int halftoneBits;

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
	halftoneBase = ((int) (interpreterProxy->firstIndexableField(halftoneBits)));
	return 1;
}


/*	Load the surface support plugin */

static int loadSurfacePlugin(void) {
	querySurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioGetSurfaceFormat", "SurfacePlugin");
	lockSurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioLockSurface", "SurfacePlugin");
	unlockSurfaceFn = interpreterProxy->ioLoadFunctionFrom("ioUnlockSurface", "SurfacePlugin");
	return (querySurfaceFn != 0) && ((lockSurfaceFn != 0) && (unlockSurfaceFn != 0));
}

static int loadWarpBltFrom(int bbObj) {
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

static int lockSurfaces(void) {
    int sourceHandle;
    int l;
    int b;
    int destHandle;
    int r;
    int (*fn)(int, int*, int, int, int, int);
    int t;

	hasSurfaceLock = 0;
	if (destBits == 0) {
		if (lockSurfaceFn == 0) {
			if (!(loadSurfacePlugin())) {
				return null;
			}
		}
		fn = ((int (*)(int, int*, int, int, int, int)) lockSurfaceFn);
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

		fn = ((int (*)(int, int*, int, int, int, int)) lockSurfaceFn);
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

static int mapPixelflags(int sourcePixel, int mapperFlags) {
    int pv;
    int val;

	pv = sourcePixel;
	if ((mapperFlags & ColorMapPresent) != 0) {
		if ((mapperFlags & ColorMapFixedPart) != 0) {
			/* begin rgbMapPixel:flags: */
			val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePixel & (cmMaskTable[0])) << (cmShiftTable[0])));
			val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePixel & (cmMaskTable[1])) << (cmShiftTable[1]))));
			val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePixel & (cmMaskTable[2])) << (cmShiftTable[2]))));
			pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePixel & (cmMaskTable[3])) << (cmShiftTable[3]))));
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

static int mergewith(int sourceWord, int destinationWord) {
    int (*mergeFnwith)(int, int);

	mergeFnwith = ((int (*)(int, int)) (opTable[combinationRule + 1]));
	mergeFnwith;
	return mergeFnwith(sourceWord, destinationWord);
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(int) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SurfacePlugin")) == 0) {
		querySurfaceFn = lockSurfaceFn = unlockSurfaceFn = 0;
	}
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	AND word1 to word2 as nParts partitions of nBits each.
	Any field of word1 not all-ones is treated as all-zeroes.
	Used for erasing, eg, brush shapes prior to ORing in a color */

static int partitionedANDtonBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int result;
    int i;
    int mask;


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

static int partitionedAddtonBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int sum;
    int result;
    int i;
    int mask;


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

static int partitionedMaxwithnBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int result;
    int i;
    int mask;


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

static int partitionedMinwithnBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int result;
    int i;
    int mask;


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

static int partitionedMulwithnBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int result;
    int sMask;
    int product;
    int dMask;


	/* partition mask starts at the right */

	sMask = maskTable[nBits];
	dMask = sMask << nBits;

	/* optimized first step */

	result = ((unsigned) (((((word1 & sMask) + 1) * ((word2 & sMask) + 1)) - 1) & dMask)) >> nBits;
	product = (((((((unsigned) word1) >> nBits) & sMask) + 1) * (((((unsigned) word2) >> nBits) & sMask) + 1)) - 1) & dMask;
	result = result | (product & dMask);
	product = (((((((unsigned) word1) >> (2 * nBits)) & sMask) + 1) * (((((unsigned) word2) >> (2 * nBits)) & sMask) + 1)) - 1) & dMask;
	result = result | ((product & dMask) << nBits);
	return result;
}


/*	Subtract word1 from word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors */

static int partitionedSubfromnBitsnPartitions(int word1, int word2, int nBits, int nParts) {
    int result;
    int p1;
    int i;
    int mask;
    int p2;


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

static int performCopyLoop(void) {
    int dxLowBits;
    int pixPerM1;
    int sxLowBits;
    int dWid;
    int t;
    int endBits;
    int pixPerM11;
    int startBits;

	/* begin destMaskAndPointerInit */
	pixPerM11 = destPPW - 1;
	startBits = destPPW - (dx & pixPerM11);
	if (destMSB) {
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM11) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

static int pickSourcePixelsflagssrcMaskdestMasksrcShiftIncdstShiftInc(int nPixels, int mapperFlags, int srcMask, int dstMask, int srcShiftInc, int dstShiftInc) {
    int nPix;
    int sourcePix;
    int srcShift;
    int sourceWord;
    int dstShift;
    int destWord;
    int destPix;
    int idx;
    int idx1;
    int pv;
    int val;

	sourceWord = longAt(sourceIndex);
	destWord = 0;

	/* Hint: Keep in register */

	srcShift = srcBitShift;

	/* Hint: Keep in register */

	dstShift = dstBitShift;

	/* always > 0 so we can use do { } while(--nPix); */

	nPix = nPixels;
	if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
		do {
			sourcePix = (((unsigned) sourceWord) >> srcShift) & srcMask;
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
				sourceWord = longAt(idx);
			}
		} while(!((nPix -= 1) == 0));
	} else {
		do {
			sourcePix = (((unsigned) sourceWord) >> srcShift) & srcMask;
			/* begin mapPixel:flags: */
			pv = sourcePix;
			if ((mapperFlags & ColorMapPresent) != 0) {
				if ((mapperFlags & ColorMapFixedPart) != 0) {
					/* begin rgbMapPixel:flags: */
					val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
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
				sourceWord = longAt(idx1);
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

static int pickWarpPixelAtXy(int xx, int yy) {
    int sourcePix;
    int x;
    int srcIndex;
    int sourceWord;
    int y;

	if ((xx < 0) || ((yy < 0) || (((x = ((unsigned) xx) >> BinaryPoint) >= sourceWidth) || ((y = ((unsigned) yy) >> BinaryPoint) >= sourceHeight)))) {
		return 0;
	}
	srcIndex = (sourceBits + (y * sourcePitch)) + ((((unsigned) x) >> warpAlignShift) * 4);

	/* Extract pixel from word */

	sourceWord = longAt(srcIndex);
	srcBitShift = warpBitShiftTable[x & warpAlignMask];
	sourcePix = (((unsigned) sourceWord) >> srcBitShift) & warpSrcMask;
	return sourcePix;
}


/*	Clear all pixels in destinationWord for which the pixels of sourceWord have the same values. Used to clear areas of some constant color to zero. */

static int pixClearwith(int sourceWord, int destinationWord) {
    int result;
    int nBits;
    int pv;
    int i;
    int mask;

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

static int pixMaskwith(int sourceWord, int destinationWord) {
    int result;
    int i;
    int mask;

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

static int pixPaintwith(int sourceWord, int destinationWord) {
	if (sourceWord == 0) {
		return destinationWord;
	}
	return sourceWord | (partitionedANDtonBitsnPartitions(~sourceWord, destinationWord, destDepth, destPPW));
}


/*	Swap the pixels in destWord */

static int pixSwapwith(int sourceWord, int destWord) {
    int lowMask;
    int result;
    int shift;
    int i;
    int highMask;

	if (destPPW == 1) {
		return destWord;
	}
	result = 0;

	/* mask low pixel */

	lowMask = (1 << destDepth) - 1;

	/* mask high pixel */

	highMask = lowMask << ((destPPW - 1) * destDepth);
	shift = 32 - destDepth;
	result = result | (((destWord & lowMask) << shift) | (((unsigned) (destWord & highMask)) >> shift));
	if (destPPW <= 2) {
		return result;
	}
	for (i = 2; i <= (((int) destPPW >> 1)); i += 1) {
		lowMask = lowMask << destDepth;
		highMask = ((unsigned) highMask) >> destDepth;
		shift -= destDepth * 2;
		result = result | (((destWord & lowMask) << shift) | (((unsigned) (destWord & highMask)) >> shift));
	}
	return result;
}


/*	Invoke the copyBits primitive. If the destination is the display, then copy it to the screen. */

EXPORT(int) primitiveCopyBits(void) {
    int rcvr;

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

EXPORT(int) primitiveDisplayString(void) {
    int maxGlyph;
    int glyphMap;
    unsigned char * sourcePtr;
    int charIndex;
    int sourceString;
    int quickBlt;
    int stopIndex;
    int left;
    int bbObj;
    int startIndex;
    int glyphIndex;
    int kernDelta;
    int ascii;
    int xTable;
    int endBits;
    int pixPerM1;
    int startBits;

	if (!((interpreterProxy->methodArgumentCount()) == 6)) {
		return interpreterProxy->primitiveFail();
	}
	kernDelta = interpreterProxy->stackIntegerValue(0);
	xTable = interpreterProxy->stackObjectValue(1);
	glyphMap = interpreterProxy->stackObjectValue(2);
	if (!((interpreterProxy->isArray(xTable)) && (interpreterProxy->isArray(glyphMap)))) {
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
		ascii = byteAt((sourcePtr + charIndex) - 1);
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
					mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
				} else {
					mask1 = AllOnes << (32 - (startBits * destDepth));
				}
				endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
				if (destMSB) {
					mask2 = AllOnes << (32 - (endBits * destDepth));
				} else {
					mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

EXPORT(int) primitiveDrawLoop(void) {
    int yDelta;
    int xDelta;
    int rcvr;
    int affL;
    int affB;
    int affR;
    int P;
    int i;
    int affT;
    int dx1;
    int px;
    int dy1;
    int py;

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
			P = ((int) py >> 1);
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
			P = ((int) px >> 1);
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

EXPORT(int) primitiveWarpBits(void) {
    int rcvr;
    int ns;
    int endBits;
    int pixPerM1;
    int startBits;

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
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

static int queryDestSurface(int handle) {
	if (querySurfaceFn == 0) {
		if (!(loadSurfacePlugin())) {
			return 0;
		}
	}
	return  ((int (*) (int, int*, int*, int*, int*))querySurfaceFn)
		(handle, &destWidth, &destHeight, &destDepth, &destMSB);
}


/*	Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	Note: Moved to a separate function for better inlining of the caller. */

static int querySourceSurface(int handle) {
	if (querySurfaceFn == 0) {
		if (!(loadSurfacePlugin())) {
			return 0;
		}
	}
	return  ((int (*) (int, int*, int*, int*, int*))querySurfaceFn)
		(handle, &sourceWidth, &sourceHeight, &sourceDepth, &sourceMSB);
}

static int rgbAddwith(int sourceWord, int destinationWord) {
	if (destDepth < 16) {
		return partitionedAddtonBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedAddtonBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedAddtonBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedAddtonBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}


/*	Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, return the number of differing pixels. */

static int rgbDiffwith(int sourceWord, int destinationWord) {
    int destShifted;
    int diff;
    int sourceShifted;
    int rgbMask;
    int bitsPerColor;
    int pixMask;
    int sourcePixVal;
    int i;
    int maskShifted;
    int destPixVal;

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
				diff = ((diff & rgbMask) + ((((unsigned) diff) >> bitsPerColor) & rgbMask)) + ((((unsigned) (((unsigned) diff) >> bitsPerColor)) >> bitsPerColor) & rgbMask);
			}
			bitCount += diff;
		}
		maskShifted = ((unsigned) maskShifted) >> destDepth;
		sourceShifted = ((unsigned) sourceShifted) >> destDepth;
		destShifted = ((unsigned) destShifted) >> destDepth;
	}
	return destinationWord;
}


/*	Convert the given 16bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats. */

static int rgbMap16To32(int sourcePixel) {
	return (((sourcePixel & 31) << 3) | ((sourcePixel & 992) << 6)) | ((sourcePixel & 31744) << 9);
}


/*	Convert the given 32bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats. */

static int rgbMap32To32(int sourcePixel) {
	return sourcePixel;
}


/*	Convert the given pixel value with nBitsIn bits for each color component to a pixel value with nBitsOut bits for each color component. Typical values for nBitsIn/nBitsOut are 3, 5, or 8. */

static int rgbMapfromto(int sourcePixel, int nBitsIn, int nBitsOut) {
    int srcPix;
    int d;
    int mask;
    int destPix;

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
		srcPix = ((unsigned) sourcePixel) >> d;
		destPix = srcPix & mask;
		mask = mask << nBitsOut;
		srcPix = ((unsigned) srcPix) >> d;
		destPix = (destPix + (srcPix & mask)) + ((((unsigned) srcPix) >> d) & (mask << nBitsOut));
		if (destPix == 0) {
			return 1;
		}
		return destPix;
	}
}


/*	Perform the RGBA conversion for the given source pixel */

static int rgbMapPixelflags(int sourcePixel, int mapperFlags) {
    int val;

	val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePixel & (cmMaskTable[0])) << (cmShiftTable[0])));
	val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePixel & (cmMaskTable[1])) << (cmShiftTable[1]))));
	val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePixel & (cmMaskTable[2])) << (cmShiftTable[2]))));
	return val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePixel & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePixel & (cmMaskTable[3])) << (cmShiftTable[3]))));
}

static int rgbMaxwith(int sourceWord, int destinationWord) {
    int result;
    int i;
    int mask;
    int result1;
    int i1;
    int mask3;

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
		return (partitionedMaxwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMaxwithnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
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

static int rgbMinwith(int sourceWord, int destinationWord) {
    int result;
    int i;
    int mask;
    int result1;
    int i1;
    int mask3;

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
		return (partitionedMinwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMinwithnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
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

static int rgbMinInvertwith(int wordToInvert, int destinationWord) {
    int sourceWord;
    int result;
    int i;
    int mask;
    int result1;
    int i1;
    int mask3;

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
		return (partitionedMinwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMinwithnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
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

static int rgbMulwith(int sourceWord, int destinationWord) {
	if (destDepth < 16) {
		return partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedMulwithnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedMulwithnBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}

static int rgbSubwith(int sourceWord, int destinationWord) {
	if (destDepth < 16) {
		return partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, destDepth, destPPW);
	}
	if (destDepth == 16) {
		return (partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 5, 3)) + ((partitionedSubfromnBitsnPartitions(((unsigned) sourceWord) >> 16, ((unsigned) destinationWord) >> 16, 5, 3)) << 16);
	} else {
		return partitionedSubfromnBitsnPartitions(sourceWord, destinationWord, 8, 3);
	}
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
    int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


/*	WARNING: For WarpBlt w/ smoothing the source depth is wrong here! */

static int setupColorMasks(void) {
    int bits;
    int targetBits;

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

static int setupColorMasksFromto(int srcBits, int targetBits) {
    static unsigned int masks[4] = {0, 0, 0, 0};
    int mask;
    int deltaBits;
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

static int showDisplayBits(void) {
	interpreterProxy->showDisplayBitsLeftTopRightBottom(destForm, affectedL, affectedT, affectedR, affectedB);
}


/*	This is only used when source and dest are same depth,
	ie, when the barrel-shift copy loop is used. */

static int sourceSkewAndPointerInit(void) {
    int dxLowBits;
    int pixPerM1;
    int sxLowBits;
    int dWid;


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

static int sourceWordwith(int sourceWord, int destinationWord) {
	return sourceWord;
}

static int srcLongAt(int idx) {
	return longAt(idx);
}

static int subWordwith(int sourceWord, int destinationWord) {
	return sourceWord - destinationWord;
}


/*	Note: Nasty coercion only necessary for the non-inlined version of this method in C. Duh? Oh well, here's the full story. The code below will definitely be inlined so everything that calls this method is fine. But... the translator doesn't quite prune this method so it generates a C function that tries to attempt an array access on an int - and most compilers don't like this. If you don't know what I'm talking about try to remove the C coercion and you'll see what happens when you try to compile a new VM... */

static int tableLookupat(unsigned int * table, int index) {
	return table[index];
}


/*	Tally pixels into the color map.  Those tallied are exactly those
	in the destination rectangle.  Note that the source should be 
	specified == destination, in order for the proper color map checks 
	to be performed at setup. */

static int tallyIntoMapwith(int sourceWord, int destinationWord) {
    int destShifted;
    int pixMask;
    int i;
    int pixVal;
    int maskShifted;
    int mapIndex;
    int srcPix;
    int d;
    int mask;
    int destPix;
    int srcPix1;
    int d1;
    int mask3;
    int destPix1;

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
						srcPix = ((unsigned) pixVal) >> d;
						destPix = srcPix & mask;
						mask = mask << cmBitsPerColor;
						srcPix = ((unsigned) srcPix) >> d;
						destPix = (destPix + (srcPix & mask)) + ((((unsigned) srcPix) >> d) & (mask << cmBitsPerColor));
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
						srcPix1 = ((unsigned) pixVal) >> d1;
						destPix1 = srcPix1 & mask3;
						mask3 = mask3 << cmBitsPerColor;
						srcPix1 = ((unsigned) srcPix1) >> d1;
						destPix1 = (destPix1 + (srcPix1 & mask3)) + ((((unsigned) srcPix1) >> d1) & (mask3 << cmBitsPerColor));
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
		maskShifted = ((unsigned) maskShifted) >> destDepth;
		destShifted = ((unsigned) destShifted) >> destDepth;
	}
	return destinationWord;
}


/*	Return the word at position idx from the colorMap */

static int tallyMapAt(int idx) {
	return cmLookupTable[idx & cmMask];
}


/*	Store the word at position idx in the colorMap */

static int tallyMapAtput(int idx, int value) {
	return cmLookupTable[idx & cmMask] = value;
}


/*	Shortcut for stuff that's being run from the balloon engine.
	Since we do this at each scan line we should avoid the expensive 
	setup for source and destination. */

static int tryCopyingBitsQuickly(void) {
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

static int unlockSurfaces(void) {
    int sourceHandle;
    int destHandle;
    int (*fn)(int, int, int, int, int);
    int destLocked;

	if (hasSurfaceLock) {
		if (unlockSurfaceFn == 0) {
			if (!(loadSurfacePlugin())) {
				return null;
			}
		}
		fn = ((int (*)(int, int, int, int, int)) unlockSurfaceFn);
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

static int warpBits(void) {
    int ns;
    int endBits;
    int pixPerM1;
    int startBits;

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
		mask1 = ((unsigned) AllOnes) >> (32 - (startBits * destDepth));
	} else {
		mask1 = AllOnes << (32 - (startBits * destDepth));
	}
	endBits = (((dx + bbW) - 1) & pixPerM1) + 1;
	if (destMSB) {
		mask2 = AllOnes << (32 - (endBits * destDepth));
	} else {
		mask2 = ((unsigned) AllOnes) >> (32 - (endBits * destDepth));
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

static int warpLoop(void) {
    int nPix;
    int endBits;
    int pAx;
    int deltaP43x;
    int dstShiftLeft;
    int mapperFlags;
    int yDelta;
    int xDelta;
    int pBy;
    int skewWord;
    int dstShiftInc;
    int words;
    int deltaP12y;
    int smoothingCount;
    int destWord;
    int mergeWord;
    int pBx;
    int sourceMapOop;
    int nSteps;
    int halftoneWord;
    int pAy;
    int deltaP43y;
    int (*mergeFnwith)(int, int);
    int deltaP12x;
    int i;
    int startBits;
    int nPix1;
    int sourcePix;
    int dstMask;
    int destWord1;
    int destPix;
    int i1;
    int words1;
    int sourcePix1;
    int x;
    int srcIndex;
    int sourceWord;
    int y;
    int sourcePix2;
    int x1;
    int srcIndex1;
    int sourceWord1;
    int y1;
    int pv;
    int val;

	mergeFnwith = ((int (*)(int, int)) (opTable[combinationRule + 1]));
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
			sourceMapOop = ((int) (interpreterProxy->firstIndexableField(sourceMapOop)));
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
		words1 = ((unsigned) words1) >> 1;
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
			halftoneWord = longAt(halftoneBase + ((((dy + i) - 1) % halftoneHeight) * 4));
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
						if ((sx < 0) || ((sy < 0) || (((x = ((unsigned) sx) >> BinaryPoint) >= sourceWidth) || ((y = ((unsigned) sy) >> BinaryPoint) >= sourceHeight)))) {
							sourcePix = 0;
							goto l7;
						}
						srcIndex = (sourceBits + (y * sourcePitch)) + ((((unsigned) x) >> warpAlignShift) * 4);
						sourceWord = longAt(srcIndex);
						srcBitShift = warpBitShiftTable[x & warpAlignMask];
						sourcePix1 = (((unsigned) sourceWord) >> srcBitShift) & warpSrcMask;
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
						if ((sx < 0) || ((sy < 0) || (((x1 = ((unsigned) sx) >> BinaryPoint) >= sourceWidth) || ((y1 = ((unsigned) sy) >> BinaryPoint) >= sourceHeight)))) {
							sourcePix = 0;
							goto l8;
						}
						srcIndex1 = (sourceBits + (y1 * sourcePitch)) + ((((unsigned) x1) >> warpAlignShift) * 4);
						sourceWord1 = longAt(srcIndex1);
						srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
						sourcePix2 = (((unsigned) sourceWord1) >> srcBitShift) & warpSrcMask;
						sourcePix = sourcePix2;
					l8:	/* end pickWarpPixelAtX:y: */;
						/* begin mapPixel:flags: */
						pv = sourcePix;
						if ((mapperFlags & ColorMapPresent) != 0) {
							if ((mapperFlags & ColorMapFixedPart) != 0) {
								/* begin rgbMapPixel:flags: */
								val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
								val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
								val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
								pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
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
				mergeWord = mergeFnwith(skewWord & halftoneWord, longAt(destIndex));
				longAtput(destIndex, destMask & mergeWord);
			} else {
				destWord = longAt(destIndex);
				mergeWord = mergeFnwith(skewWord & halftoneWord, destWord & destMask);
				destWord = (destMask & mergeWord) | (destWord & (~destMask));
				longAtput(destIndex, destWord);
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

static int warpLoopSetup(void) {
    int i;
    int words;

	warpSrcShift = 0;

	/* recycle temp */

	words = sourceDepth;
	while (!(words == 1)) {
		warpSrcShift += 1;
		words = ((unsigned) words) >> 1;
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

static int warpPickSmoothPixelsxDeltahyDeltahxDeltavyDeltavsourceMapsmoothingdstShiftInc(int nPixels, int xDeltah, int yDeltah, int xDeltav, int yDeltav, int sourceMap, int n, int dstShiftInc) {
    int nPix;
    int a;
    int k;
    int rgb;
    int xdh;
    int r;
    int j;
    int y;
    int destWord;
    int xx;
    int yy;
    int dstMask;
    int b;
    int g;
    int ydv;
    int i;
    int x;
    int ydh;
    int xdv;
    int sourcePix;
    int x1;
    int srcIndex;
    int sourceWord;
    int y1;
    int pv;
    int val;

	dstMask = maskTable[destDepth];
	destWord = 0;
	if (n == 2) {
		xdh = ((int) xDeltah >> 1);
		ydh = ((int) yDeltah >> 1);
		xdv = ((int) xDeltav >> 1);
		ydv = ((int) yDeltav >> 1);
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
				if ((xx < 0) || ((yy < 0) || (((x1 = ((unsigned) xx) >> BinaryPoint) >= sourceWidth) || ((y1 = ((unsigned) yy) >> BinaryPoint) >= sourceHeight)))) {
					rgb = 0;
					goto l1;
				}
				srcIndex = (sourceBits + (y1 * sourcePitch)) + ((((unsigned) x1) >> warpAlignShift) * 4);
				sourceWord = longAt(srcIndex);
				srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
				sourcePix = (((unsigned) sourceWord) >> srcBitShift) & warpSrcMask;
				rgb = sourcePix;
			l1:	/* end pickWarpPixelAtX:y: */;
				if (!((combinationRule == 25) && (rgb == 0))) {
					nPix += 1;
					if (sourceDepth < 16) {
						rgb = longAt(sourceMap + (rgb << 2));
					} else {
						if (sourceDepth == 16) {
							rgb = (((rgb & 31) << 3) | ((rgb & 992) << 6)) | ((rgb & 31744) << 9);
						} else {
							rgb = rgb;
						}
					}
					b += rgb & 255;
					g += (((unsigned) rgb) >> 8) & 255;
					r += (((unsigned) rgb) >> 16) & 255;
					a += ((unsigned) rgb) >> 24;
				}
				xx += xdh;
				yy += ydh;
			} while(!((k -= 1) == 0));
			x += xdv;
			y += ydv;
		} while(!((j -= 1) == 0));
		if ((nPix == 0) || ((combinationRule == 25) && (nPix < (((int) (n * n) >> 1))))) {

			/* All pixels were 0, or most were transparent */

			rgb = 0;
		} else {
			if (nPix == 4) {
				r = ((unsigned) r) >> 2;
				g = ((unsigned) g) >> 2;
				b = ((unsigned) b) >> 2;
				a = ((unsigned) a) >> 2;
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
					val = (((cmShiftTable[0]) < 0) ? ((unsigned) (rgb & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (rgb & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (rgb & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (rgb & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (rgb & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (rgb & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (rgb & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (rgb & (cmMaskTable[3])) << (cmShiftTable[3]))));
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

static int warpPickSourcePixelsxDeltahyDeltahxDeltavyDeltavdstShiftIncflags(int nPixels, int xDeltah, int yDeltah, int xDeltav, int yDeltav, int dstShiftInc, int mapperFlags) {
    int nPix;
    int sourcePix;
    int dstMask;
    int destWord;
    int destPix;
    int sourcePix1;
    int x;
    int srcIndex;
    int sourceWord;
    int y;
    int sourcePix2;
    int x1;
    int srcIndex1;
    int sourceWord1;
    int y1;
    int pv;
    int val;

	dstMask = maskTable[destDepth];
	destWord = 0;
	nPix = nPixels;
	if (mapperFlags == (ColorMapPresent | ColorMapIndexedPart)) {
		do {
			/* begin pickWarpPixelAtX:y: */
			if ((sx < 0) || ((sy < 0) || (((x = ((unsigned) sx) >> BinaryPoint) >= sourceWidth) || ((y = ((unsigned) sy) >> BinaryPoint) >= sourceHeight)))) {
				sourcePix = 0;
				goto l1;
			}
			srcIndex = (sourceBits + (y * sourcePitch)) + ((((unsigned) x) >> warpAlignShift) * 4);
			sourceWord = longAt(srcIndex);
			srcBitShift = warpBitShiftTable[x & warpAlignMask];
			sourcePix1 = (((unsigned) sourceWord) >> srcBitShift) & warpSrcMask;
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
			if ((sx < 0) || ((sy < 0) || (((x1 = ((unsigned) sx) >> BinaryPoint) >= sourceWidth) || ((y1 = ((unsigned) sy) >> BinaryPoint) >= sourceHeight)))) {
				sourcePix = 0;
				goto l2;
			}
			srcIndex1 = (sourceBits + (y1 * sourcePitch)) + ((((unsigned) x1) >> warpAlignShift) * 4);
			sourceWord1 = longAt(srcIndex1);
			srcBitShift = warpBitShiftTable[x1 & warpAlignMask];
			sourcePix2 = (((unsigned) sourceWord1) >> srcBitShift) & warpSrcMask;
			sourcePix = sourcePix2;
		l2:	/* end pickWarpPixelAtX:y: */;
			/* begin mapPixel:flags: */
			pv = sourcePix;
			if ((mapperFlags & ColorMapPresent) != 0) {
				if ((mapperFlags & ColorMapFixedPart) != 0) {
					/* begin rgbMapPixel:flags: */
					val = (((cmShiftTable[0]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[0])) >> -(cmShiftTable[0])) : ((unsigned) (sourcePix & (cmMaskTable[0])) << (cmShiftTable[0])));
					val = val | ((((cmShiftTable[1]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[1])) >> -(cmShiftTable[1])) : ((unsigned) (sourcePix & (cmMaskTable[1])) << (cmShiftTable[1]))));
					val = val | ((((cmShiftTable[2]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[2])) >> -(cmShiftTable[2])) : ((unsigned) (sourcePix & (cmMaskTable[2])) << (cmShiftTable[2]))));
					pv = val | ((((cmShiftTable[3]) < 0) ? ((unsigned) (sourcePix & (cmMaskTable[3])) >> -(cmShiftTable[3])) : ((unsigned) (sourcePix & (cmMaskTable[3])) << (cmShiftTable[3]))));
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
	{"BitBltPlugin", "primitiveDrawLoop", (void*)primitiveDrawLoop},
	{"BitBltPlugin", "initialiseModule", (void*)initialiseModule},
	{"BitBltPlugin", "copyBitsFromtoat", (void*)copyBitsFromtoat},
	{"BitBltPlugin", "loadBitBltFrom", (void*)loadBitBltFrom},
	{"BitBltPlugin", "primitiveWarpBits", (void*)primitiveWarpBits},
	{"BitBltPlugin", "copyBits", (void*)copyBits},
	{"BitBltPlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"BitBltPlugin", "primitiveCopyBits", (void*)primitiveCopyBits},
	{"BitBltPlugin", "getModuleName", (void*)getModuleName},
	{"BitBltPlugin", "primitiveDisplayString", (void*)primitiveDisplayString},
	{"BitBltPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

