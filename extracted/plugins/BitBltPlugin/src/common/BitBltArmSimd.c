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
#include <stdint.h>

#include "BitBltInternal.h"

enum {
	HALFTONE_NONE,
	HALFTONE_SCALAR,
	HALFTONE_VECTOR
};

//typedef void (*armSimdAsmFn)(uint32_t width, uint32_t height, uint32_t *dst, uint32_t dstStride, uint32_t *src, uint32_t srcStride, uint32_t halftone, uint32_t halftoneInfo, uint32_t *colourMap, uint32_t bitPtrs, ...);

#define FAST_PATH(op, src_bpp, dst_bpp, qualifier, halftone_type)                                                                                             \
extern void armSimd##op##src_bpp##_##dst_bpp##qualifier##_wide  (uint32_t width, uint32_t height, uint32_t *dst, uint32_t dstStride, uint32_t *src, uint32_t srcStride, uint32_t halftone, uint32_t halftoneInfo, uint32_t *colourMap, uint32_t bitPtrs, ...); \
extern void armSimd##op##src_bpp##_##dst_bpp##qualifier##_narrow(uint32_t width, uint32_t height, uint32_t *dst, uint32_t dstStride, uint32_t *src, uint32_t srcStride, uint32_t halftone, uint32_t halftoneInfo, uint32_t *colourMap, uint32_t bitPtrs, ...); \
extern void armSimd##op##src_bpp##_##dst_bpp##qualifier##_tiny  (uint32_t width, uint32_t height, uint32_t *dst, uint32_t dstStride, uint32_t *src, uint32_t srcStride, uint32_t halftone, uint32_t halftoneInfo, uint32_t *colourMap, uint32_t bitPtrs, ...); \
static void fastPath##op##src_bpp##_##dst_bpp##qualifier(operation_t *op, uint32_t flags)                                                                     \
{                                                                                                                                                             \
	IGNORE(flags);                                                                                                                                            \
	/* Copy certain parts of the operation structure to locals to help compiler */                                                                            \
	uint32_t *srcBits = op->src.bits;                                                                                                                         \
	uint32_t srcPitch = op->src.pitch / sizeof (uint32_t);                                                                                                    \
	uint32_t srcX     = op->src.x;                                                                                                                            \
	uint32_t srcY     = op->src.y;                                                                                                                            \
	uint32_t *dstBits = op->dest.bits;                                                                                                                        \
	uint32_t dstPitch = op->dest.pitch / sizeof (uint32_t);                                                                                                   \
	uint32_t dstX     = op->dest.x;                                                                                                                           \
	uint32_t dstY     = op->dest.y;                                                                                                                           \
	uint32_t width    = op->width;                                                                                                                            \
	uint32_t height   = op->height;                                                                                                                           \
	uint32_t *cmLookupTable = *op->cmLookupTable;                                                                                                             \
	uint32_t halftoneHeight = op->halftoneHeight;                                                                                                             \
	uint32_t *halftoneBase  = (uint32_t *) *op->halftoneBase;                                                                                                 \
	/* Get pointers to initial words */                                                                                                                       \
	uint32_t *src = 0;                                                                                                                                        \
	if (src_bpp > 0)                                                                                                                                          \
		src = srcBits + srcPitch * srcY + srcX * src_bpp / 32;                                                                                                \
	uint32_t *dst = dstBits + dstPitch * dstY + dstX * dst_bpp / 32;                                                                                          \
	/* Get initial pixel offset within words, mangle into pitch if possible */                                                                                \
	uint32_t bitPtrs = 0;                                                                                                                                     \
	uint32_t srcXpix = 0;                                                                                                                                     \
	if (src_bpp > 0) {                                                                                                                                        \
		srcXpix = srcX & (31 / (src_bpp == 0 ? 1 : src_bpp)); /* ?: to avoid compiler warning on GCC! */                                                      \
		if (src_bpp < 8)                                                                                                                                      \
			bitPtrs = srcXpix << 27;                                                                                                                          \
		else if (src_bpp == 8 || src_bpp == 16)                                                                                                               \
			srcPitch |= srcXpix << 30;                                                                                                                        \
	}                                                                                                                                                         \
	uint32_t dstXpix = dstX & (31/dst_bpp);                                                                                                                   \
	if (dst_bpp < 8)                                                                                                                                          \
		bitPtrs |= dstXpix;                                                                                                                                   \
	else if (dst_bpp == 8 || dst_bpp == 16)                                                                                                                   \
		dstPitch |= dstXpix << 30;                                                                                                                            \
	/* Adjust strides to remove number of words partially or wholly read/written */                                                                           \
	if (src_bpp > 0)                                                                                                                                          \
		srcPitch -= (src_bpp * (srcXpix + width) + 31) / 32;                                                                                                  \
	dstPitch -= (dst_bpp * (dstXpix + width) + 31) / 32;                                                                                                      \
	/* Deal with halftoning */                                                                                                                                \
	uint32_t halftone = 0;                                                                                                                                    \
	uint32_t halftoneInfo = 0;                                                                                                                                \
	if (halftone_type == HALFTONE_SCALAR)                                                                                                                     \
		halftone = halftoneBase[0];                                                                                                                           \
	else if (halftone_type == HALFTONE_VECTOR) {                                                                                                              \
		halftone = (uint32_t) (halftoneBase + halftoneHeight);                                                                                                \
		halftoneInfo = (((dstY % halftoneHeight) - halftoneHeight) << 17) | (-halftoneHeight & 0x7FFF);                                                       \
	}                                                                                                                                                         \
	/* Work out which width class this operation is.                                                                                                          \
	 * Rather than re-evaluate this for each line, we want one choice                                                                                         \
	 * for the whole operation; this means we can't assume anything about                                                                                     \
	 * alignment to sizes larger than 4 bytes, because that's the only                                                                                        \
	 * guarantee we have about line stride. */                                                                                                                \
	if (width > (128-32)/dst_bpp && (((dstXpix-1) ^ (dstXpix+width-(128-32)/dst_bpp)) &~ (31/dst_bpp)))                                                       \
		armSimd##op##src_bpp##_##dst_bpp##qualifier##_wide(width, height, dst, dstPitch, src, srcPitch, halftone, halftoneInfo, cmLookupTable, bitPtrs);      \
	else if (dst_bpp > 8 || (((dstXpix-1) ^ (dstXpix+width)) &~ (31/dst_bpp)))                                                                                \
		armSimd##op##src_bpp##_##dst_bpp##qualifier##_narrow(width, height, dst, dstPitch, src, srcPitch, halftone, halftoneInfo, cmLookupTable, bitPtrs);    \
	else                                                                                                                                                      \
		armSimd##op##src_bpp##_##dst_bpp##qualifier##_tiny(width, height, dst, dstPitch, src, srcPitch, halftone, halftoneInfo, cmLookupTable, bitPtrs);      \
}

FAST_PATH(SourceWord,1,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,1,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,2,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,1,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,2,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,4,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,1,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,2,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,4,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,8,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,1,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,2,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,4,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,8,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,16,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,1,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,2,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,4,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,8,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,16,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,32,32,,HALFTONE_NONE)

FAST_PATH(SourceWord,2,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,4,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,8,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,16,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,32,16,,HALFTONE_NONE)

FAST_PATH(SourceWord,4,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,8,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,16,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,32,8,,HALFTONE_NONE)

FAST_PATH(SourceWord,8,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,16,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,32,4,,HALFTONE_NONE)

FAST_PATH(SourceWord,16,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,32,2,,HALFTONE_NONE)

FAST_PATH(SourceWord,32,1,,HALFTONE_NONE)

FAST_PATH(SourceWord,0,1,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,1,_scalar,HALFTONE_SCALAR)
FAST_PATH(SourceWord,0,2,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,2,_scalar,HALFTONE_SCALAR)
FAST_PATH(SourceWord,0,4,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,4,_scalar,HALFTONE_SCALAR)
FAST_PATH(SourceWord,0,8,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,8,_scalar,HALFTONE_SCALAR)
FAST_PATH(SourceWord,0,16,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,16,_scalar,HALFTONE_SCALAR)
FAST_PATH(SourceWord,0,32,,HALFTONE_NONE)
FAST_PATH(SourceWord,0,32,_scalar,HALFTONE_SCALAR)

FAST_PATH(PixPaint,1,1,,HALFTONE_NONE)
FAST_PATH(PixPaint,2,2,,HALFTONE_NONE)
FAST_PATH(PixPaint,4,4,,HALFTONE_NONE)
FAST_PATH(PixPaint,8,8,,HALFTONE_NONE)
FAST_PATH(PixPaint,16,16,,HALFTONE_NONE)
FAST_PATH(PixPaint,32,32,,HALFTONE_NONE)

FAST_PATH(AlphaBlend,32,32,,HALFTONE_NONE)

FAST_PATH(BitAnd,1,1,,HALFTONE_NONE)
FAST_PATH(BitAnd,2,2,,HALFTONE_NONE)
FAST_PATH(BitAnd,4,4,,HALFTONE_NONE)
FAST_PATH(BitAnd,8,8,,HALFTONE_NONE)
FAST_PATH(BitAnd,16,16,,HALFTONE_NONE)
FAST_PATH(BitAnd,32,32,,HALFTONE_NONE)

static fast_path_t fastPaths[] = {
		{ fastPathSourceWord1_32,        CR_sourceWord, STD_FLAGS(1,32,DIRECT,NO) },

		{ fastPathSourceWord1_16,        CR_sourceWord, STD_FLAGS(1,16,DIRECT,NO) },
		{ fastPathSourceWord2_32,        CR_sourceWord, STD_FLAGS(2,32,DIRECT,NO) },

		{ fastPathSourceWord1_8,         CR_sourceWord, STD_FLAGS(1,8,DIRECT,NO) },
		{ fastPathSourceWord2_16,        CR_sourceWord, STD_FLAGS(2,16,DIRECT,NO) },
		{ fastPathSourceWord4_32,        CR_sourceWord, STD_FLAGS(4,32,DIRECT,NO) },

		{ fastPathSourceWord1_4,         CR_sourceWord, STD_FLAGS(1,4,DIRECT,NO) },
		{ fastPathSourceWord2_8,         CR_sourceWord, STD_FLAGS(2,8,DIRECT,NO) },
		{ fastPathSourceWord4_16,        CR_sourceWord, STD_FLAGS(4,16,DIRECT,NO) },
		{ fastPathSourceWord8_32,        CR_sourceWord, STD_FLAGS(8,32,DIRECT,NO) },

		{ fastPathSourceWord1_2,         CR_sourceWord, STD_FLAGS(1,2,DIRECT,NO) },
		{ fastPathSourceWord2_4,         CR_sourceWord, STD_FLAGS(2,4,DIRECT,NO) },
		{ fastPathSourceWord4_8,         CR_sourceWord, STD_FLAGS(4,8,DIRECT,NO) },
		{ fastPathSourceWord8_16,        CR_sourceWord, STD_FLAGS(8,16,DIRECT,NO) },
		{ fastPathSourceWord16_32,       CR_sourceWord, STD_FLAGS(16,32,NO,NO) },

		{ fastPathSourceWord1_1,         CR_sourceWord, STD_FLAGS(1,1,NO,NO) },
		{ fastPathSourceWord2_2,         CR_sourceWord, STD_FLAGS(2,2,NO,NO) },
		{ fastPathSourceWord4_4,         CR_sourceWord, STD_FLAGS(4,4,NO,NO) },
		{ fastPathSourceWord8_8,         CR_sourceWord, STD_FLAGS(8,8,NO,NO) },
		{ fastPathSourceWord16_16,       CR_sourceWord, STD_FLAGS(16,16,NO,NO) },
		{ fastPathSourceWord32_32,       CR_sourceWord, STD_FLAGS(32,32,NO,NO) },

		{ fastPathSourceWord2_1,         CR_sourceWord, STD_FLAGS(2,1,DIRECT,NO) },
		{ fastPathSourceWord4_2,         CR_sourceWord, STD_FLAGS(4,2,DIRECT,NO) },
		{ fastPathSourceWord8_4,         CR_sourceWord, STD_FLAGS(8,4,DIRECT,NO) },
		{ fastPathSourceWord16_8,        CR_sourceWord, STD_FLAGS(16,8,DIRECT,NO) },
		{ fastPathSourceWord32_16,       CR_sourceWord, STD_FLAGS(32,16,NO,NO) },

		{ fastPathSourceWord4_1,         CR_sourceWord, STD_FLAGS(4,1,DIRECT,NO) },
		{ fastPathSourceWord8_2,         CR_sourceWord, STD_FLAGS(8,2,DIRECT,NO) },
		{ fastPathSourceWord16_4,        CR_sourceWord, STD_FLAGS(16,4,DIRECT,NO) },
		{ fastPathSourceWord32_8,        CR_sourceWord, STD_FLAGS(32,8,15BIT,NO) },

		{ fastPathSourceWord8_1,         CR_sourceWord, STD_FLAGS(8,1,DIRECT,NO) },
		{ fastPathSourceWord16_2,        CR_sourceWord, STD_FLAGS(16,2,DIRECT,NO) },
		{ fastPathSourceWord32_4,        CR_sourceWord, STD_FLAGS(32,4,15BIT,NO) },

		{ fastPathSourceWord16_1,        CR_sourceWord, STD_FLAGS(16,1,DIRECT,NO) },
		{ fastPathSourceWord32_2,        CR_sourceWord, STD_FLAGS(32,2,15BIT,NO) },

		{ fastPathSourceWord32_1,        CR_sourceWord, STD_FLAGS(32,1,15BIT,NO) },

		{ fastPathSourceWord0_1,         CR_sourceWord, STD_FLAGS_NO_SOURCE(1,NO) },
		{ fastPathSourceWord0_1_scalar,  CR_sourceWord, STD_FLAGS_NO_SOURCE(1,SCALAR) },
		{ fastPathSourceWord0_2,         CR_sourceWord, STD_FLAGS_NO_SOURCE(2,NO) },
		{ fastPathSourceWord0_2_scalar,  CR_sourceWord, STD_FLAGS_NO_SOURCE(2,SCALAR) },
		{ fastPathSourceWord0_4,         CR_sourceWord, STD_FLAGS_NO_SOURCE(4,NO) },
		{ fastPathSourceWord0_4_scalar,  CR_sourceWord, STD_FLAGS_NO_SOURCE(4,SCALAR) },
		{ fastPathSourceWord0_8,         CR_sourceWord, STD_FLAGS_NO_SOURCE(8,NO) },
		{ fastPathSourceWord0_8_scalar,  CR_sourceWord, STD_FLAGS_NO_SOURCE(8,SCALAR) },
		{ fastPathSourceWord0_16,        CR_sourceWord, STD_FLAGS_NO_SOURCE(16,NO) },
		{ fastPathSourceWord0_16_scalar, CR_sourceWord, STD_FLAGS_NO_SOURCE(16,SCALAR) },
		{ fastPathSourceWord0_32,        CR_sourceWord, STD_FLAGS_NO_SOURCE(32,NO) },
		{ fastPathSourceWord0_32_scalar, CR_sourceWord, STD_FLAGS_NO_SOURCE(32,SCALAR) },

		{ fastPathPixPaint1_1,           CR_pixPaint,   STD_FLAGS(1,1,NO,NO) },
		{ fastPathPixPaint2_2,           CR_pixPaint,   STD_FLAGS(2,2,NO,NO) },
		{ fastPathPixPaint4_4,           CR_pixPaint,   STD_FLAGS(4,4,NO,NO) },
		{ fastPathPixPaint8_8,           CR_pixPaint,   STD_FLAGS(8,8,NO,NO) },
		{ fastPathPixPaint16_16,         CR_pixPaint,   STD_FLAGS(16,16,NO,NO) },
		{ fastPathPixPaint32_32,         CR_pixPaint,   STD_FLAGS(32,32,NO,NO) },

		{ fastPathAlphaBlend32_32,       CR_alphaBlend, STD_FLAGS(32,32,NO,NO) },

		{ fastPathBitAnd1_1,             CR_bitAnd,     STD_FLAGS(1,1,NO,NO) },
		{ fastPathBitAnd2_2,             CR_bitAnd,     STD_FLAGS(2,2,NO,NO) },
		{ fastPathBitAnd4_4,             CR_bitAnd,     STD_FLAGS(4,4,NO,NO) },
		{ fastPathBitAnd8_8,             CR_bitAnd,     STD_FLAGS(8,8,NO,NO) },
		{ fastPathBitAnd16_16,           CR_bitAnd,     STD_FLAGS(16,16,NO,NO) },
		{ fastPathBitAnd32_32,           CR_bitAnd,     STD_FLAGS(32,32,NO,NO) },
};

#define TALLY_FAST_PATH(op, srcA_bpp, srcB_bpp)                                                                                                 \
extern uint32_t armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_wide  (uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
extern uint32_t armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_narrow(uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
extern uint32_t armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_tiny  (uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
static uint32_t tallyFastPath##op##srcA_bpp##_##srcB_bpp(const compare_operation_t *op, uint32_t log2bppA, uint32_t log2bppB)                   \
{                                                                                                                                               \
    IGNORE(log2bppA);                                                                                                                           \
    IGNORE(log2bppB);                                                                                                                           \
    COPY_COMPARE_OP_TO_LOCALS(op, uint32_t, uint32_t);                                                                                          \
    /* Get pointers to initial words */                                                                                                         \
    const uint32_t *srcA = srcABits + srcAPitch * srcAY + srcAX * srcA_bpp / 32;                                                                \
    const uint32_t *srcB = srcBBits + srcBPitch * srcBY + srcBX * srcB_bpp / 32;                                                                \
    /* Get initial pixel offset within words, mangle into pitch if possible */                                                                  \
    uint32_t bitPtrs = 0;                                                                                                                       \
    uint32_t srcAXpix = srcAX & (31 / srcA_bpp);                                                                                                \
    if (srcA_bpp < 8)                                                                                                                           \
        bitPtrs = srcAXpix;                                                                                                                     \
    else if (srcA_bpp == 8 || srcA_bpp == 16)                                                                                                   \
        srcAPitch |= srcAXpix << 30;                                                                                                            \
    uint32_t srcBXpix = srcBX & (31 / srcB_bpp);                                                                                                \
    if (srcB_bpp < 8)                                                                                                                           \
        bitPtrs |= srcBXpix << 27;                                                                                                              \
    else if (srcB_bpp == 8 || srcB_bpp == 16)                                                                                                   \
        srcBPitch |= srcBXpix << 30;                                                                                                            \
    /* Adjust strides to remove number of words partially or wholly read/written */                                                             \
    srcAPitch -= (srcA_bpp * (srcAXpix + width) + 31) / 32;                                                                                     \
    srcBPitch -= (srcB_bpp * (srcBXpix + width) + 31) / 32;                                                                                     \
    /* Work out which width class this operation is.                                                                                            \
     * Rather than re-evaluate this for each line, we want one choice                                                                           \
     * for the whole operation; this means we can't assume anything about                                                                       \
     * alignment to sizes larger than 4 bytes, because that's the only                                                                          \
     * guarantee we have about line stride. */                                                                                                  \
    if (width > (128-32)/srcA_bpp && (((srcAXpix-1) ^ (srcAXpix+width-(128-32)/srcA_bpp)) &~ (31/srcA_bpp)))                                    \
        return armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_wide(width, height, srcA, srcAPitch, srcB, srcBPitch, colorA, colorB, 0, bitPtrs);   \
    else if (srcA_bpp > 8 || (((srcAXpix-1) ^ (srcAXpix+width)) &~ (31/srcA_bpp)))                                                              \
        return armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_narrow(width, height, srcA, srcAPitch, srcB, srcBPitch, colorA, colorB, 0, bitPtrs); \
    else                                                                                                                                        \
        return armSimd##op##Tally##srcB_bpp##_##srcA_bpp##_tiny(width, height, srcA, srcAPitch, srcB, srcBPitch, colorA, colorB, 0, bitPtrs);   \
}

#define TEST_FAST_PATH(op, srcA_bpp, srcB_bpp)                                                                                                  \
extern uint32_t armSimd##op##Test##srcB_bpp##_##srcA_bpp##_wide  (uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
extern uint32_t armSimd##op##Test##srcB_bpp##_##srcA_bpp##_narrow(uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
extern uint32_t armSimd##op##Test##srcB_bpp##_##srcA_bpp##_tiny  (uint32_t width, uint32_t height, const uint32_t *srcA, uint32_t srcAStride, const uint32_t *srcB, uint32_t srcBStride, uint32_t colorA, uint32_t colorB, void *unused, uint32_t bitPtrs); \
static uint32_t testFastPath##op##srcA_bpp##_##srcB_bpp(const compare_operation_t *op, uint32_t log2bppA, uint32_t log2bppB)                    \
{                                                                                                                                               \
    IGNORE(log2bppA);                                                                                                                           \
    IGNORE(log2bppB);                                                                                                                           \
    COPY_COMPARE_OP_TO_LOCALS(op, uint32_t, uint32_t);                                                                                          \
    /* Early termination is most likely in the centre, so start from the      */                                                                \
    /* middle and work outwards                                               */                                                                \
    const uint32_t *srcAUp = srcABits + srcAPitch * (srcAY + (height >> 1)) + srcAX * srcA_bpp / 32;                                            \
    const uint32_t *srcBUp = srcBBits + srcBPitch * (srcBY + (height >> 1)) + srcBX * srcB_bpp / 32;                                            \
    const uint32_t *srcADown = srcAUp;                                                                                                          \
    const uint32_t *srcBDown = srcBUp;                                                                                                          \
    /* Get initial pixel offset within words, mangle into pitch if possible   */                                                                \
    uint32_t bitPtrs = 0;                                                                                                                       \
    uint32_t srcAXpix = srcAX & (31 / srcA_bpp);                                                                                                \
    if (srcA_bpp < 8)                                                                                                                           \
        bitPtrs = srcAXpix;                                                                                                                     \
    else if (srcA_bpp == 8 || srcA_bpp == 16)                                                                                                   \
        srcAPitch |= srcAXpix << 30;                                                                                                            \
    uint32_t srcBXpix = srcBX & (31 / srcB_bpp);                                                                                                \
    if (srcB_bpp < 8)                                                                                                                           \
        bitPtrs |= srcBXpix << 27;                                                                                                              \
    else if (srcB_bpp == 8 || srcB_bpp == 16)                                                                                                   \
        srcBPitch |= srcBXpix << 30;                                                                                                            \
    /* Work out which width class this operation is.                          */                                                                \
    /* Rather than re-evaluate this for each line, we want one choice for the */                                                                \
    /* whole operation; this means we can't assume anything about alignment   */                                                                \
    /* to sizes larger than 4 bytes, because that's the only guarantee we     */                                                                \
    /* have about line stride.                                                */                                                                \
    uint32_t (*testRow)(uint32_t, uint32_t, const uint32_t *, uint32_t, const uint32_t *, uint32_t, uint32_t, uint32_t, void *, uint32_t);      \
    if (width > (128-32)/srcA_bpp && (((srcAXpix-1) ^ (srcAXpix+width-(128-32)/srcA_bpp)) &~ (31/srcA_bpp)))                                    \
        testRow = armSimd##op##Test##srcB_bpp##_##srcA_bpp##_wide;                                                                              \
    else if (srcA_bpp > 8 || (((srcAXpix-1) ^ (srcAXpix+width)) &~ (31/srcA_bpp)))                                                              \
        testRow = armSimd##op##Test##srcB_bpp##_##srcA_bpp##_narrow;                                                                            \
    else                                                                                                                                        \
        testRow = armSimd##op##Test##srcB_bpp##_##srcA_bpp##_tiny;                                                                              \
    if (height & 1)                                                                                                                             \
    {                                                                                                                                           \
        height++;                                                                                                                               \
        goto odd_number_of_rows_remain;                                                                                                         \
    }                                                                                                                                           \
    while (height != 0)                                                                                                                         \
    {                                                                                                                                           \
        srcADown -= srcAPitch;                                                                                                                  \
        srcBDown -= srcBPitch;                                                                                                                  \
        if (testRow(width, 1, srcADown, srcAPitch, srcBDown, srcBPitch, colorA, colorB, 0, bitPtrs))                                            \
            return 1;                                                                                                                           \
        odd_number_of_rows_remain:                                                                                                              \
        if (testRow(width, 1, srcAUp, srcAPitch, srcBUp, srcBPitch, colorA, colorB, 0, bitPtrs))                                                \
            return 1;                                                                                                                           \
        srcAUp += srcAPitch;                                                                                                                    \
        srcBUp += srcBPitch;                                                                                                                    \
        height -= 2;                                                                                                                            \
    }                                                                                                                                           \
    return 0;                                                                                                                                   \
}

#define ADD_TALLY_FN(op, srcA_bpp, srcB_bpp)                     \
    do { compareColorsFns[(((MR_##op * 2) + 1) * 3 +             \
            (srcA_bpp == 8 ? 0 : srcA_bpp == 16 ? 1 : 2)) * 3 +  \
            (srcB_bpp == 8 ? 0 : srcB_bpp == 16 ? 1 : 2)] =      \
            tallyFastPath##op##srcA_bpp##_##srcB_bpp; } while(0)

#define ADD_TEST_FN(op, srcA_bpp, srcB_bpp)                      \
    do { compareColorsFns[(((MR_##op * 2) + 0) * 3 +             \
            (srcA_bpp == 8 ? 0 : srcA_bpp == 16 ? 1 : 2)) * 3 +  \
            (srcB_bpp == 8 ? 0 : srcB_bpp == 16 ? 1 : 2)] =      \
            testFastPath##op##srcA_bpp##_##srcB_bpp; } while(0)

TALLY_FAST_PATH(pixelMatch, 32, 32)
TALLY_FAST_PATH(notAnotB,   32, 32)
TALLY_FAST_PATH(notAmatchB, 32, 32)
TEST_FAST_PATH(pixelMatch, 32, 32)
TEST_FAST_PATH(notAnotB,   32, 32)
TEST_FAST_PATH(notAmatchB, 32, 32)

TALLY_FAST_PATH(pixelMatch, 16, 16)
TALLY_FAST_PATH(notAnotB,   16, 16)
TALLY_FAST_PATH(notAmatchB, 16, 16)
TEST_FAST_PATH(pixelMatch, 16, 16)
TEST_FAST_PATH(notAnotB,   16, 16)
TEST_FAST_PATH(notAmatchB, 16, 16)

TALLY_FAST_PATH(pixelMatch, 16, 32)
TALLY_FAST_PATH(notAnotB,   16, 32)
TALLY_FAST_PATH(notAmatchB, 16, 32)
TEST_FAST_PATH(pixelMatch, 16, 32)
TEST_FAST_PATH(notAnotB,   16, 32)
TEST_FAST_PATH(notAmatchB, 16, 32)

TALLY_FAST_PATH(notAmatchB, 32, 16)
TEST_FAST_PATH(notAmatchB, 32, 16)

TALLY_FAST_PATH(pixelMatch, 8, 8)
TALLY_FAST_PATH(notAnotB,   8, 8)
TALLY_FAST_PATH(notAmatchB, 8, 8)
TEST_FAST_PATH(pixelMatch, 8, 8)
TEST_FAST_PATH(notAnotB,   8, 8)
TEST_FAST_PATH(notAmatchB, 8, 8)

void addArmSimdFastPaths(void)
{
	addFastPaths(fastPaths, sizeof fastPaths / sizeof *fastPaths);

    ADD_TALLY_FN(pixelMatch, 32, 32);
    ADD_TALLY_FN(notAnotB,   32, 32);
    ADD_TALLY_FN(notAmatchB, 32, 32);
    ADD_TEST_FN(pixelMatch, 32, 32);
    ADD_TEST_FN(notAnotB,   32, 32);
    ADD_TEST_FN(notAmatchB, 32, 32);

    ADD_TALLY_FN(pixelMatch, 16, 16);
    ADD_TALLY_FN(notAnotB,   16, 16);
    ADD_TALLY_FN(notAmatchB, 16, 16);
    ADD_TEST_FN(pixelMatch, 16, 16);
    ADD_TEST_FN(notAnotB,   16, 16);
    ADD_TEST_FN(notAmatchB, 16, 16);

    ADD_TALLY_FN(pixelMatch, 16, 32);
    ADD_TALLY_FN(notAnotB,   16, 32);
    ADD_TALLY_FN(notAmatchB, 16, 32);
    ADD_TEST_FN(pixelMatch, 16, 32);
    ADD_TEST_FN(notAnotB,   16, 32);
    ADD_TEST_FN(notAmatchB, 16, 32);

    ADD_TALLY_FN(notAmatchB, 32, 16);
    ADD_TEST_FN(notAmatchB, 32, 16);

    ADD_TALLY_FN(pixelMatch, 8, 8);
    ADD_TALLY_FN(notAnotB,   8, 8);
    ADD_TALLY_FN(notAmatchB, 8, 8);
    ADD_TEST_FN(pixelMatch, 8, 8);
    ADD_TEST_FN(notAnotB,   8, 8);
    ADD_TEST_FN(notAmatchB, 8, 8);
}
