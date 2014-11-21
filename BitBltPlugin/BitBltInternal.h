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

#ifndef BITBLTINTERNAL_H_
#define BITBLTINTERNAL_H_

#include "BitBltDispatch.h"

#define IGNORE(x) (void)(x)
#define CACHELINE_LEN (32)

/* These flags are named after properties that the operation has.
 * In the fast path table, the set bits are the flags that must *not*
 * be set. So if none of a group of related flag bits are set, then
 * the fast can handle any setting. If it can handle only one setting
 * within that group, then all other bits in that group are set (there
 * are some macros lower down to simplify specifying such fast paths).
 */

enum {
	FAST_PATH_SRC_0BPP           = 1u<<0,
	FAST_PATH_SRC_1BPP           = 1u<<1,
	FAST_PATH_SRC_2BPP           = 1u<<2,
	FAST_PATH_SRC_4BPP           = 1u<<3,
	FAST_PATH_SRC_8BPP           = 1u<<4,
	FAST_PATH_SRC_16BPP          = 1u<<5,
	FAST_PATH_SRC_32BPP          = 1u<<6,

	FAST_PATH_SRC_BIG_ENDIAN     = 1u<<7,
	FAST_PATH_SRC_LITTLE_ENDIAN  = 1u<<8,

	FAST_PATH_DEST_1BPP          = 1u<<9,
	FAST_PATH_DEST_2BPP          = 1u<<10,
	FAST_PATH_DEST_4BPP          = 1u<<11,
	FAST_PATH_DEST_8BPP          = 1u<<12,
	FAST_PATH_DEST_16BPP         = 1u<<13,
	FAST_PATH_DEST_32BPP         = 1u<<14,

	FAST_PATH_DEST_BIG_ENDIAN    = 1u<<15,
	FAST_PATH_DEST_LITTLE_ENDIAN = 1u<<16,

	FAST_PATH_NO_COLOR_MAP       = 1u<<17,
	FAST_PATH_9BIT_COLOR_MAP     = 1u<<18,
	FAST_PATH_12BIT_COLOR_MAP    = 1u<<19,
	FAST_PATH_15BIT_COLOR_MAP    = 1u<<20,
	FAST_PATH_DIRECT_COLOR_MAP   = FAST_PATH_15BIT_COLOR_MAP, /* for use with <16bpp */

	FAST_PATH_NO_HALFTONE        = 1u<<21,
	FAST_PATH_SCALAR_HALFTONE    = 1u<<22,
	FAST_PATH_VECTOR_HALFTONE    = 1u<<23,

	FAST_PATH_CA_NO_GAMMA        = 1u<<24,
	FAST_PATH_CA_HAS_GAMMA       = 1u<<25,

	FAST_PATH_NO_OVERLAP         = 1u<<26,
	FAST_PATH_H_OVERLAP          = 1u<<27,
	FAST_PATH_V_OVERLAP          = 1u<<28,
};

/* These are the derived macros for use in specifying fast paths. */

#define ONLY_SRC_0BPP           (FAST_PATH_SRC_1BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_8BPP | FAST_PATH_SRC_16BPP | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_1BPP           (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_8BPP | FAST_PATH_SRC_16BPP | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_2BPP           (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_8BPP | FAST_PATH_SRC_16BPP | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_4BPP           (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_8BPP | FAST_PATH_SRC_16BPP | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_8BPP           (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_16BPP | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_16BPP          (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_8BPP  | FAST_PATH_SRC_32BPP)
#define ONLY_SRC_32BPP          (FAST_PATH_SRC_0BPP | FAST_PATH_SRC_1BPP | FAST_PATH_SRC_2BPP | FAST_PATH_SRC_4BPP | FAST_PATH_SRC_8BPP  | FAST_PATH_SRC_16BPP)

#define ONLY_SRC_BIG_ENDIAN     (FAST_PATH_SRC_LITTLE_ENDIAN)
#define ONLY_SRC_LITTLE_ENDIAN  (FAST_PATH_SRC_LITTLE_ENDIAN)

#define ONLY_DEST_1BPP          (FAST_PATH_DEST_2BPP | FAST_PATH_DEST_4BPP | FAST_PATH_DEST_8BPP | FAST_PATH_DEST_16BPP | FAST_PATH_DEST_32BPP)
#define ONLY_DEST_2BPP          (FAST_PATH_DEST_1BPP | FAST_PATH_DEST_4BPP | FAST_PATH_DEST_8BPP | FAST_PATH_DEST_16BPP | FAST_PATH_DEST_32BPP)
#define ONLY_DEST_4BPP          (FAST_PATH_DEST_1BPP | FAST_PATH_DEST_2BPP | FAST_PATH_DEST_8BPP | FAST_PATH_DEST_16BPP | FAST_PATH_DEST_32BPP)
#define ONLY_DEST_8BPP          (FAST_PATH_DEST_1BPP | FAST_PATH_DEST_2BPP | FAST_PATH_DEST_4BPP | FAST_PATH_DEST_16BPP | FAST_PATH_DEST_32BPP)
#define ONLY_DEST_16BPP         (FAST_PATH_DEST_1BPP | FAST_PATH_DEST_2BPP | FAST_PATH_DEST_4BPP | FAST_PATH_DEST_8BPP  | FAST_PATH_DEST_32BPP)
#define ONLY_DEST_32BPP         (FAST_PATH_DEST_1BPP | FAST_PATH_DEST_2BPP | FAST_PATH_DEST_4BPP | FAST_PATH_DEST_8BPP  | FAST_PATH_DEST_16BPP)

#define ONLY_DEST_BIG_ENDIAN    (FAST_PATH_DEST_LITTLE_ENDIAN)
#define ONLY_DEST_LITTLE_ENDIAN (FAST_PATH_DEST_LITTLE_ENDIAN)

#define ONLY_NO_COLOR_MAP       (FAST_PATH_9BIT_COLOR_MAP | FAST_PATH_12BIT_COLOR_MAP | FAST_PATH_15BIT_COLOR_MAP)
#define ONLY_9BIT_COLOR_MAP     (FAST_PATH_NO_COLOR_MAP   | FAST_PATH_12BIT_COLOR_MAP | FAST_PATH_15BIT_COLOR_MAP)
#define ONLY_12BIT_COLOR_MAP    (FAST_PATH_NO_COLOR_MAP   | FAST_PATH_9BIT_COLOR_MAP  | FAST_PATH_15BIT_COLOR_MAP)
#define ONLY_15BIT_COLOR_MAP    (FAST_PATH_NO_COLOR_MAP   | FAST_PATH_9BIT_COLOR_MAP  | FAST_PATH_12BIT_COLOR_MAP)
#define ONLY_DIRECT_COLOR_MAP   ONLY_15BIT_COLOR_MAP /* for use with <16bpp */

#define ONLY_NO_HALFTONE        (FAST_PATH_SCALAR_HALFTONE | FAST_PATH_VECTOR_HALFTONE)
#define ONLY_SCALAR_HALFTONE    (FAST_PATH_NO_HALFTONE     | FAST_PATH_VECTOR_HALFTONE)
#define ONLY_VECTOR_HALFTONE    (FAST_PATH_NO_HALFTONE     | FAST_PATH_SCALAR_HALFTONE)

#define ONLY_CA_NO_GAMMA        (FAST_PATH_CA_HAS_GAMMA)
#define ONLY_CA_HAS_GAMMA       (FAST_PATH_CA_NO_GAMMA)

#define ONLY_NO_OVERLAP         (FAST_PATH_H_OVERLAP  | FAST_PATH_V_OVERLAP)
#define ONLY_H_OVERLAP          (FAST_PATH_NO_OVERLAP | FAST_PATH_V_OVERLAP)
#define ONLY_V_OVERLAP          (FAST_PATH_NO_OVERLAP | FAST_PATH_H_OVERLAP)

#define STD_FLAGS(src_bpp, dest_bpp, map_type, halftone_type) (ONLY_SRC_##src_bpp##BPP | ONLY_SRC_BIG_ENDIAN | ONLY_DEST_##dest_bpp##BPP | ONLY_DEST_BIG_ENDIAN | ONLY_##map_type##_COLOR_MAP | ONLY_##halftone_type##_HALFTONE | ONLY_NO_OVERLAP)
#define STD_FLAGS_NO_SOURCE(dest_bpp, halftone_type)          (ONLY_SRC_0BPP | ONLY_DEST_##dest_bpp##BPP | ONLY_DEST_BIG_ENDIAN | ONLY_##halftone_type##_HALFTONE)

/** This macro basically tells the compiler that the pointer to the
 * "op" structure doesn't alias with any other pointers. I'd use the
 * restrict keyword instead, but Squeak is built C89. */
#define COPY_OP_TO_LOCALS(op, src_type, dest_type)                             \
	combination_rule_t combinationRule  = op->combinationRule;                 \
	bool               noSource         = op->noSource;                        \
	src_type          *srcBits          = op->src.bits;                        \
	uint32_t           srcDepth         = op->src.depth;                       \
	uint32_t           srcPitch         = op->src.pitch / sizeof (src_type);   \
	bool               srcMSB           = op->src.msb;                         \
	uint32_t           srcX             = op->src.x;                           \
	uint32_t           srcY             = op->src.y;                           \
	dest_type         *destBits         = op->dest.bits;                       \
	uint32_t           destDepth        = op->dest.depth;                      \
	uint32_t           destPitch        = op->dest.pitch / sizeof (dest_type); \
	bool               destMSB          = op->dest.msb;                        \
	uint32_t           destX            = op->dest.x;                          \
	uint32_t           destY            = op->dest.y;                          \
	uint32_t           width            = op->width;                           \
	uint32_t           height           = op->height;                          \
	uint32_t           cmFlags          = op->cmFlags;                         \
	int32_t          (*cmShiftTable)[4] = op->cmShiftTable;                    \
	uint32_t         (*cmMaskTable)[4]  = op->cmMaskTable;                     \
	uint32_t           cmMask           = op->cmMask;                          \
	uint32_t         (*cmLookupTable)[] = op->cmLookupTable;                   \
	bool               noHalftone       = op->noHalftone;                      \
	uint32_t           halftoneHeight   = op->halftoneHeight;                  \
	uint32_t         (*halftoneBase)[]  = (uint32_t (*)[]) op->halftoneBase;   \
	IGNORE(combinationRule); \
	IGNORE(noSource);        \
	IGNORE(srcBits);         \
	IGNORE(srcDepth);        \
	IGNORE(srcPitch);        \
	IGNORE(srcMSB);          \
	IGNORE(srcX);            \
	IGNORE(srcY);            \
	IGNORE(destBits);        \
	IGNORE(destDepth);       \
	IGNORE(destPitch);       \
	IGNORE(destMSB);         \
	IGNORE(destX);           \
	IGNORE(destY);           \
	IGNORE(width);           \
	IGNORE(height);          \
	IGNORE(cmFlags);         \
	IGNORE(cmShiftTable);    \
	IGNORE(cmMaskTable);     \
	IGNORE(cmMask);          \
	IGNORE(cmLookupTable);   \
	IGNORE(noHalftone);      \
	IGNORE(halftoneHeight);  \
	IGNORE(halftoneBase);    \

#define COPY_COMPARE_OP_TO_LOCALS(op, srcA_type, srcB_type)                    \
    match_rule_t       matchRule        = op->matchRule;                       \
    bool               tally            = op->tally;                           \
    srcA_type         *srcABits         = op->srcA.bits;                       \
    uint32_t           srcADepth        = op->srcA.depth;                      \
    uint32_t           srcAPitch        = op->srcA.pitch / sizeof (srcA_type); \
    bool               srcAMSB          = op->srcA.msb;                        \
    uint32_t           srcAX            = op->srcA.x;                          \
    uint32_t           srcAY            = op->srcA.y;                          \
    srcB_type         *srcBBits         = op->srcB.bits;                       \
    uint32_t           srcBDepth        = op->srcB.depth;                      \
    uint32_t           srcBPitch        = op->srcB.pitch / sizeof (srcB_type); \
    bool               srcBMSB          = op->srcB.msb;                        \
    uint32_t           srcBX            = op->srcB.x;                          \
    uint32_t           srcBY            = op->srcB.y;                          \
    uint32_t           width            = op->width;                           \
    uint32_t           height           = op->height;                          \
    uint32_t           colorA           = op->colorA;                          \
    uint32_t           colorB           = op->colorB;                          \
    IGNORE(matchRule); \
    IGNORE(tally);     \
    IGNORE(srcABits);  \
    IGNORE(srcADepth); \
    IGNORE(srcAPitch); \
    IGNORE(srcAMSB);   \
    IGNORE(srcAX);     \
    IGNORE(srcAY);     \
    IGNORE(srcBBits);  \
    IGNORE(srcBDepth); \
    IGNORE(srcBPitch); \
    IGNORE(srcBMSB);   \
    IGNORE(srcBX);     \
    IGNORE(srcBY);     \
    IGNORE(width);     \
    IGNORE(height);    \
    IGNORE(colorA);    \
    IGNORE(colorB);    \


typedef struct {
	void             (*func)(operation_t *, uint32_t);
	combination_rule_t combinationRule;
	uint32_t           flags;
} fast_path_t;

void addFastPaths(fast_path_t *paths, size_t n);
void (*lookupFastPath(combination_rule_t combinationRule, uint32_t flags))(operation_t *, uint32_t);
void copyBitsFallback(operation_t *op, uint32_t flags);

#endif /* BITBLTINTERNAL_H_ */
