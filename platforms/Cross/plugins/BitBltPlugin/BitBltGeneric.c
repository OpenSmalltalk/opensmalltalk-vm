/*
 * Copyright © 2013 Raspberry Pi Foundation
 * Copyright © 2013 RISC OS Open Ltd
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the copyright holders not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  The copyright holders make no
 * representations about the suitability of this software for any purpose.  It
 * is provided "as is" without express or implied warranty.
 *
 * THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS
 * SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS, IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 *
 */

#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "BitBltInternal.h"


#define ROR(x,s) (((uint32_t)(x))>>(s)|((uint32_t)(x))<<((32-(s))))
#define MAX(a,b) ((a)>(b)?(a):(b))
#define MIN(a,b) ((a)<(b)?(a):(b))

static const uint8_t log2table[33] = { 0, 0, 1, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0,
		                               4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5 };

#ifdef DEBUG
#define dprintf(args) do { check_printf args; } while (0)
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
static int check_printf(char *format, ...)
{
	static bool envChecked;
	static bool debugEnabled;
	int result = 0;
	if (!envChecked) {
		debugEnabled = getenv("DEBUG");
		envChecked = true;
	}
	if (debugEnabled) {
		va_list ap;
		va_start(ap, format);
		result = vprintf(format, ap);
		va_end(ap);
	}
	return result;
}
#else
#define dprintf(args)
#endif


static void fastPathClearWord4(operation_t *op, uint32_t flags)
{
	IGNORE(flags);
	COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
	uint32_t *dest = destBits + destPitch * destY + destX * 4 / 32;
	uint32_t destXbitIndex = (destX * 4) & 31;
	if (32 - (signed) (destXbitIndex + width * 4) >= 0) {
		uint32_t mask = -1u << (32 - (destXbitIndex + 4 * width));
		mask &= mask >> destXbitIndex;
		do {
			*dest = (*dest &~ mask) | (0 & mask);
			dest += destPitch;
		} while (--height > 0);
	} else {
		/* Don't bother rounding up, we won't increment dest for trailing word if any */
		destPitch -= (destXbitIndex + width * 4) / 32;
		do {
			uint32_t x = width;
			if (destXbitIndex > 0) {
				uint32_t mask = -1u >> destXbitIndex;
				*dest = (*dest &~ mask) | (0 & mask);
				dest++;
				x -= (32 - destXbitIndex) / 4;
			}
			uint32_t old_x;
			while (old_x = x, x -= 32/4, old_x >= 32/4) {
				*dest++ = 0;
			}
			if (x & (32/4-1)) {
				uint32_t mask = -1u << (32 - (x & (32/4-1)) * 4);
				*dest = (*dest &~ mask) | (0 & mask);
			}
			dest += destPitch;
		} while (--height > 0);
	}
}

static void fastPathClearWord8(operation_t *op, uint32_t flags)
{
	IGNORE(flags);
	COPY_OP_TO_LOCALS(op, uint32_t, uint8_t);
	uint8_t *dest = destBits + destPitch * destY + (destX &~ 3);
	/* Stride is defined to be an integer number of words, so there's actually
	 * 2 bits spare there - use them to hold the byte offset into first word */
	destPitch = (destPitch >> 2) | (destX << 30);
	if (4 - (signed)((destPitch >> 30) + width) > 0) {
		do {
			/* Lowest address offset at which to write */
			uint32_t offset = 4 - (destPitch >> 30);
			uint32_t data = 0;
			data >>= (destPitch >> 30) * 8;
			uint32_t old_x;
			uint32_t x = width;
			while (old_x = x, x--, old_x >= 1) {
				dest[--offset] = data;
				data >>= 8;
			}
			dest += destPitch << 2;
		} while (--height > 0);
	} else {
		/* Don't bother rounding up, we won't increment dest for trailing word if any */
		destPitch -= ((destPitch >> 30) + width) >> 2;
		do {
			uint32_t x = width;
			uint32_t data = 0;
			if (destPitch >> 30) {
				uint32_t leading_pixels = 4 - (destPitch >> 30);
				if (leading_pixels >= 2) {
					((uint16_t *)dest)[0] = data;
					data >>= 16;
				}
				if (leading_pixels > 2)
					((uint8_t *)dest)[2] = data;
				if (leading_pixels < 2)
					((uint8_t *)dest)[0] = data;
				dest += 4;
				x -= leading_pixels;
			}
			uint32_t old_x;
			while (old_x = x, x -= 32/8, old_x >= 32/8) {
				*(uint32_t *)dest = 0;
				dest += 4;
			}
			uint32_t trailing_pixels = x & 3;
			if (trailing_pixels) {
				uint32_t data = 0;
				data >>= trailing_pixels * 8;
				if (trailing_pixels > 2u) {
					((uint8_t *)dest)[1] = data;
					data >>= 8;
				}
				if (trailing_pixels >= 2u)
					((uint16_t *)dest)[1] = data;
				if (trailing_pixels < 2u)
					((uint8_t *)dest)[3] = data;
			}
			dest += destPitch << 2;
		} while (--height > 0);
	}
}

static void fastPathClearWord32(operation_t *op, uint32_t flags)
{
	IGNORE(flags);
	COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
	uint32_t *dest = destBits + destPitch * destY + destX;
	do {
		memset(dest, 0, width * sizeof (uint32_t));
		dest += destPitch;
	} while (--height > 0);
}

static void fastPathSourceWord0_32_scalar(operation_t *op, uint32_t flags)
{
	IGNORE(flags);
	COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
	uint32_t halftoneScalar = (*op->halftoneBase)[0];
	uint32_t *dest = destBits + destPitch * destY + destX;
	do {
		uint32_t x = width;
		do
			*dest++ = halftoneScalar;
		while (--x > 0);
		dest += destPitch - width;
	} while (--height > 0);
}

static void fastPathSourceWord32_32(operation_t *op, uint32_t flags)
{
	IGNORE(flags);
	COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
	uint32_t *src = srcBits + srcPitch * srcY + srcX;
	uint32_t *dest = destBits + destPitch * destY + destX;
	do {
		memmove(dest, src, width * sizeof (uint32_t));
		src += srcPitch;
		dest += destPitch;
	} while (--height > 0);
}


static void fastPathRightToLeft(operation_t *op, uint32_t flags)
{
	/* To enable the majority of fast path implementations to forget about
	 * having to handle this case, we handle it by the use of a temporary
	 * buffer on the stack. This will live in the L1 cache most of the
	 * time and so not be as bad as it sounds. To further mitigate this
	 * overhead, we try to match the word-alignment of the source data to
	 * that of the destination data during the copy to the temporary buffer,
	 * and split the data across buffers at destination cacheline boundaries.
	 * We can make certain assumptions: the stride, colour depth and
	 * endianness of source and destination should be the same.
	 */
	uint32_t flagsToDest = (flags &~ ONLY_NO_OVERLAP) | FAST_PATH_NO_OVERLAP;
	uint32_t flagsFromSrc = (flagsToDest &~ (ONLY_NO_COLOR_MAP | ONLY_NO_HALFTONE | FAST_PATH_CA_NO_GAMMA | FAST_PATH_CA_HAS_GAMMA))
	                                       | FAST_PATH_NO_COLOR_MAP | FAST_PATH_NO_HALFTONE;
	void (*funcToDest)(operation_t *, uint32_t), (*funcFromSrc)(operation_t *, uint32_t);
	funcToDest = lookupFastPath(op->combinationRule, flagsToDest);
	if (funcToDest == NULL) {

		copyBitsFallback(op, flags);
		return;
	}
	if (op->combinationRule == CR_sourceWord && flagsToDest == flagsFromSrc)
		funcFromSrc = funcToDest;
	else {
		funcFromSrc = lookupFastPath(CR_sourceWord, flagsFromSrc);
		if (funcFromSrc == NULL) {

			copyBitsFallback(op, flags);
			return;
		}
	}

	operation_t opFromSrc = *op;
	operation_t opToDest = *op;
	uint32_t shift = log2table[op->src.depth];
	uint32_t stride = op->src.pitch;
	uint32_t line = (uint32_t) ((usqIntptr_t)op->src.bits & 0xFFFFFFFFU);
	/* Convert to pixels. It doesn't matter if we lose the MS bits of
	 * addresses, since they're passed down as pixel offsets anyway */
	if (shift > 3) {
		stride >>= shift - 3;
		line >>= shift - 3;
	} else if (shift < 3) {
		stride <<= 3 - shift;
		line <<= 3 - shift;
	}
	line += stride * op->src.y;
	uint32_t cacheline_len = (CACHELINE_LEN*8) >> shift;
	uint32_t src_x = op->src.x;
	uint32_t dest_x = op->dest.x;
	uint32_t width = op->width;
	uint32_t height = op->height;

	uint8_t tempBuffer[CACHELINE_LEN * 64];
#define BUFFER_LEN_PIXELS (cacheline_len * (sizeof tempBuffer / CACHELINE_LEN))
	opFromSrc.dest.bits = tempBuffer;
	opFromSrc.dest.y = 0;
	opFromSrc.height = 1;
	opFromSrc.cmFlags = 0;
	opFromSrc.cmMask = 0;
	opFromSrc.cmLookupTable = NULL;
	opFromSrc.noHalftone = true;
	opFromSrc.halftoneBase = NULL;
	opToDest.src.bits = tempBuffer;
	opToDest.src.y = 0;
	opToDest.height = 1;

	do {
		uint32_t firstCacheline = (line + dest_x) & -cacheline_len;
		uint32_t lastPixelRemaining = line + dest_x + width;
		uint32_t chunkBase = ((lastPixelRemaining + cacheline_len - 1) & -cacheline_len) - BUFFER_LEN_PIXELS;
		/* Working from the right, process buffer-size chunks, breaking
		 * at cacheline boundaries. The slightly unusual comparison is
		 * to handle address wrapping since we may have shifted some
		 * address bits off the top of the word (having more than 2
		 * million pixels on one line is rather less likely). */
		opFromSrc.dest.x = opToDest.src.x = 0;
		while ((int32_t)(chunkBase - firstCacheline) > 0) {
			opToDest.dest.x = chunkBase - line;
			opFromSrc.src.x = src_x - dest_x + opToDest.dest.x;
			opFromSrc.width = opToDest.width = lastPixelRemaining - chunkBase;
			funcFromSrc(&opFromSrc, flagsFromSrc);
			funcToDest(&opToDest, flagsToDest);
			lastPixelRemaining = chunkBase;
			chunkBase -= BUFFER_LEN_PIXELS;
		}
		/* In general, the dest below won't start cacheline-aligned,
		 * but if we maintain the offset from its cacheline then we at
		 * least ensure no word skew in the second operation. */
		opFromSrc.dest.x  = opToDest.src.x = line + dest_x - firstCacheline;
		opToDest.dest.x = dest_x;
		opFromSrc.src.x = src_x;
		opFromSrc.width = opToDest.width = lastPixelRemaining - (line + dest_x);
		funcFromSrc(&opFromSrc, flagsFromSrc);
		funcToDest(&opToDest, flagsToDest);

		line += stride;
		opFromSrc.src.y = ++opToDest.dest.y;
	} while (--height > 0);
}

static void fastPathBottomToTop(operation_t *op, uint32_t flags)
{
	uint32_t flags2 = (flags &~ FAST_PATH_V_OVERLAP) | FAST_PATH_NO_OVERLAP;
	void (*func)(operation_t *, uint32_t) = lookupFastPath(op->combinationRule, flags2);
	if (func == NULL) {

		copyBitsFallback(op, flags);}
	else {
		/* As long as vector halftone isn't in use, this is just a matter of
		 * processing the scanlines in the opposite order */
		operation_t op2 = *op;
		op2.src.bits = (uint8_t *) op->src.bits + (op->src.y + op->height - 1) * op->src.pitch;
		op2.src.y = 0;
		op2.dest.bits = (uint8_t *) op->dest.bits + (op->dest.y + op->height - 1) * op->dest.pitch;
		op2.dest.y = 0;
		op2.src.pitch = -op->src.pitch;
		op2.dest.pitch = -op->dest.pitch;
		func(&op2, flags2);
	}
}

static void fastPathDepthConv(operation_t *op, uint32_t flags)
{
	uint32_t flagsToDest = (flags &~ (ONLY_SRC_0BPP | ONLY_NO_COLOR_MAP)) |
			((flags & (FAST_PATH_DEST_1BPP | ONLY_DEST_1BPP)) / (FAST_PATH_DEST_1BPP / FAST_PATH_SRC_1BPP)) |
			FAST_PATH_NO_COLOR_MAP;
	uint32_t flagsFromSrc = (flags &~ ONLY_NO_HALFTONE) | FAST_PATH_NO_HALFTONE;
	void (*funcToDest)(operation_t *, uint32_t), (*funcFromSrc)(operation_t *, uint32_t);
	funcToDest = lookupFastPath(op->combinationRule, flagsToDest);
	if (funcToDest == NULL) {
		copyBitsFallback(op, flags);
		return;
	}
	if (op->combinationRule == CR_sourceWord) {
		/* This trick requires independent implementations of each
		 * colour depth conversion using the sourceWord combinationRule.
		 * On platforms where these are not available, we end up here,
		 * but the lookup below would cause infinite recursion, so bail
		 * out beforehand. */
		copyBitsFallback(op, flags);
		return;
	}
	funcFromSrc = lookupFastPath(CR_sourceWord, flagsFromSrc);
	if (funcFromSrc == NULL) {
		copyBitsFallback(op, flags);
		return;
	}

	operation_t opFromSrc = *op;
	operation_t opToDest = *op;
	uint32_t shift = log2table[op->dest.depth];
	uint32_t stride = op->src.pitch;
	uint32_t line = (uint32_t) ((usqIntptr_t)op->dest.bits & 0xFFFFFFFFU);
	/* Convert to pixels. It doesn't matter if we lose the MS bits of
	 * addresses, since they're passed down as pixel offsets anyway */
	if (shift > 3) {
		stride >>= shift - 3;
		line >>= shift - 3;
	} else if (shift < 3) {
		stride <<= 3 - shift;
		line <<= 3 - shift;
	}
	line += stride * op->dest.y;
	uint32_t cacheline_len = (CACHELINE_LEN*8) >> shift;
	uint32_t src_x = op->src.x;
	uint32_t dest_x = op->dest.x;
	uint32_t width = op->width;
	uint32_t height = op->height;

	uint8_t tempBuffer[CACHELINE_LEN * 64];
#define BUFFER_LEN_PIXELS (cacheline_len * (sizeof tempBuffer / CACHELINE_LEN))
	opFromSrc.combinationRule = CR_sourceWord;
	opFromSrc.dest.bits = tempBuffer;
	opFromSrc.dest.y = 0;
	opFromSrc.height = 1;
	opToDest.src.bits = tempBuffer;
	opToDest.src.depth = op->dest.depth;
	opToDest.src.pitch = op->dest.pitch;
	opToDest.src.y = 0;
	opToDest.height = 1;
	opToDest.cmFlags = 0;
	opToDest.cmMask = 0;
	opToDest.cmLookupTable = NULL;
	opToDest.noHalftone = true;
	opToDest.halftoneBase = NULL;

	do {
		/* Working from left to right, process chunks of the size of
		 * the temporary buffer (measured in pixels at a depth that
		 * matches the depth of the destination), breaking at pixels
		 * that correspond to cacheline boundaries at the destination. */
		uint32_t lastPixel = (line + dest_x + width);
		uint32_t chunkBase = (line + dest_x) & -cacheline_len;
		uint32_t chunkLimit = chunkBase + BUFFER_LEN_PIXELS;
		opFromSrc.src.x = src_x;
		opToDest.dest.x = dest_x;
		opFromSrc.width = opToDest.width = chunkLimit - (line + dest_x);
		opFromSrc.dest.x = opToDest.src.x = BUFFER_LEN_PIXELS - opFromSrc.width;
		while ((int32_t)(chunkLimit - lastPixel) < 0) {
			funcFromSrc(&opFromSrc, flagsFromSrc);
			funcToDest(&opToDest, flagsToDest);
			chunkBase = chunkLimit;
			chunkLimit = chunkBase + BUFFER_LEN_PIXELS;
			opFromSrc.src.x += opFromSrc.width;
			opToDest.dest.x += opFromSrc.width;
			opFromSrc.width = opToDest.width = BUFFER_LEN_PIXELS;
			opFromSrc.dest.x = opToDest.src.x = 0;
		}
		/* In general, the dest below won't start cacheline-aligned,
		 * but if we maintain the offset from its cacheline then we at
		 * least ensure no word skew in the second operation. */
		opFromSrc.dest.x = opToDest.src.x = opToDest.dest.x & (cacheline_len - 1);
		opFromSrc.width = opToDest.width = lastPixel - (line + opToDest.dest.x);
		funcFromSrc(&opFromSrc, flagsFromSrc);
		funcToDest(&opToDest, flagsToDest);

		line += stride;
		++opFromSrc.src.y;
		++opToDest.dest.y;
	} while (--height > 0);
}

static void fastPathNoOp(operation_t *op, uint32_t flags)
{
	IGNORE(op);
	IGNORE(flags);
}

static fast_path_t fastPaths[] = {
		{ fastPathClearWord4,            CR_clearWord,       STD_FLAGS_NO_SOURCE(4,NO) },
		{ fastPathClearWord8,            CR_clearWord,       STD_FLAGS_NO_SOURCE(8,NO) },
		{ fastPathClearWord32,           CR_clearWord,       STD_FLAGS_NO_SOURCE(32,NO) },
		{ fastPathSourceWord0_32_scalar, CR_sourceWord,      STD_FLAGS_NO_SOURCE(32,SCALAR) },

		{ fastPathSourceWord32_32,       CR_sourceWord,      STD_FLAGS(32,32,NO,NO) &~ FAST_PATH_H_OVERLAP },
		{ fastPathNoOp,                  CR_destinationWord, 0 },

		/* Some special fast paths to extend the abilities of the others in corner cases */
		{ fastPathRightToLeft,           CR_any,             FAST_PATH_VECTOR_HALFTONE | ONLY_H_OVERLAP },
		{ fastPathBottomToTop,           CR_any,             FAST_PATH_VECTOR_HALFTONE | ONLY_V_OVERLAP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_32BPP | ONLY_DEST_32BPP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_16BPP | ONLY_DEST_16BPP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_8BPP  | ONLY_DEST_8BPP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_4BPP  | ONLY_DEST_4BPP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_2BPP  | ONLY_DEST_2BPP },
		{ fastPathDepthConv,             CR_any,             FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP  | ONLY_DEST_1BPP },
};

static uint32_t genericCompareRow(uint32_t        width,
                                  const uint32_t *ptrA,
                                  const uint32_t *ptrB,
                                  uint32_t        colorA,
                                  uint32_t        colorB,
                                  uint32_t        pixelIndexes,
                                  match_rule_t    matchRule,
                                  bool            tally,
                                  uint32_t        bppA,
                                  uint32_t        bppB,
                                  uint32_t        ppwA,
                                  uint32_t        ppwB,
                                  bool            msbA,
                                  bool            msbB)
{
    uint32_t count = 0;
    uint32_t a32 = *ptrA++;
    uint32_t b32 = *ptrB++;
    if (msbA)
        a32 <<= bppA * (pixelIndexes & 0x1F);
    else
        a32 >>= bppA * (pixelIndexes & 0x1F);
    if (msbB)
        b32 <<= bppB * (pixelIndexes >> 27);
    else
        b32 >>= bppB * (pixelIndexes >> 27);
    while (width > 0)
    {
        uint32_t a = msbA ? a32 >> (32-bppA) : a32 & ((1<<bppA)-1);
        uint32_t b = msbB ? b32 >> (32-bppB) : b32 & ((1<<bppB)-1);
        uint32_t nextPixelIndexes;
        if (matchRule == MR_pixelMatch)
            count += a == colorA && b == colorB;
        else if (matchRule == MR_notAnotB)
            count += a != colorA && b != colorB;
        else // MR_notAmatchB
            count += a != colorA && b == colorB;
        if (count && !tally)
            return count;
        if (--width == 0)
            break;
        nextPixelIndexes = pixelIndexes + 1 + (1<<27);
        if (nextPixelIndexes & ppwA)
        {
            a32 = *ptrA++;
            nextPixelIndexes -= ppwA;
        }
        else
            a32 <<= bppA;
        if (ppwB == 32)
        {
            if (nextPixelIndexes < pixelIndexes)
                b32 = *ptrB++;
            else
                b32 <<= 1;
        }
        else
        {
            if (nextPixelIndexes & (ppwB<<27))
            {
                b32 = *ptrB++;
                nextPixelIndexes -= ppwB<<27;
            }
            else
                b32 <<= bppB;
        }
        pixelIndexes = nextPixelIndexes;
    }
    return count;
}

usqInt genericCompareColors(const compare_operation_t *op, usqInt log2bppA, usqInt log2bppB)
{
    uint32_t count = 0;
    uint32_t pixelIndexes;
    uint32_t ppwA = 32 >> log2bppA;
    uint32_t ppwB = 32 >> log2bppB;
    COPY_COMPARE_OP_TO_LOCALS(op, uint32_t, uint32_t);
    srcABits += srcAY * srcAPitch + (srcAX >> (5 - log2bppA));
    srcBBits += srcBY * srcBPitch + (srcBX >> (5 - log2bppB));
    pixelIndexes = (srcAX & (ppwA - 1)) + ((srcBX & (ppwB - 1)) << 27);
    /* This routine is never going to be especially fast, so just use a simple loop */
    while (height--)
    {
        count += genericCompareRow(width, srcABits, srcBBits, colorA, colorB, pixelIndexes,
                    matchRule, tally, srcADepth, srcBDepth, ppwA, ppwB, srcAMSB, srcBMSB);
        if (count && !tally)
            return count;
        srcABits += srcAPitch;
        srcBBits += srcBPitch;
    }
    return count;
}

void addGenericFastPaths(void)
{
    unsigned int i;
	addFastPaths(fastPaths, sizeof fastPaths / sizeof *fastPaths);
	for (i = 0; i < sizeof compareColorsFns / sizeof *compareColorsFns; i++)
	    compareColorsFns[i] = genericCompareColors;
}
