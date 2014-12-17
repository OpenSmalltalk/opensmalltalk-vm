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

#ifndef BITBLTDISPATCH_H_
#define BITBLTDISPATCH_H_

#include <stdbool.h>
#include "sqVirtualMachine.h"

#ifndef ColorMapPresent
#define ColorMapPresent     1
#define ColorMapFixedPart   2
#define ColorMapIndexedPart 4
#endif

typedef enum {
	CR_clearWord,             /* 0 */
	CR_bitAnd,                /* 1 */
	CR_bitAndInvert,          /* 2 */
	CR_sourceWord,            /* 3 */
	CR_bitInvertAnd,          /* 4 */
	CR_destinationWord,       /* 5 */
	CR_bitXor,                /* 6 */
	CR_bitOr,                 /* 7 */
	CR_bitInvertAndInvert,    /* 8 */
	CR_bitInvertXor,          /* 9 */
	CR_bitInvertDestination,  /* 10 */
	CR_bitOrInvert,           /* 11 */
	CR_bitInvertSource,       /* 12 */
	CR_bitInvertOr,           /* 13 */
	CR_bitInvertOrInvert,     /* 14 */
	CR_destinationWord_alt1,  /* 15 */
	CR_destinationWord_alt2,  /* 16 */
	CR_destinationWord_alt3,  /* 17 */
	CR_addWord,               /* 18 */
	CR_subWord,               /* 19 */
	CR_rgbAdd,                /* 20 */
	CR_rgbSub,                /* 21 */
	CR_OLDrgbDiff,            /* 22 */
	CR_OLDtallyIntoMap,       /* 23 */
	CR_alphaBlend,            /* 24 */
	CR_pixPaint,              /* 25 */
	CR_pixMask,               /* 26 */
	CR_rgbMax,                /* 27 */
	CR_rgbMin,                /* 28 */
	CR_rgbMinInvert,          /* 29 */
	CR_alphaBlendConst,       /* 30 */
	CR_alphaPaintConst,       /* 31 */
	CR_rgbDiff,               /* 32 */
	CR_tallyIntoMap,          /* 33 */
	CR_alphaBlendScaled,      /* 34 */
	CR_alphaBlendScaled_alt1, /* 35 */
	CR_alphaBlendScaled_alt2, /* 36 */
	CR_rgbMul,                /* 37 */
	CR_pixSwap,               /* 38 */
	CR_pixClear,              /* 39 */
	CR_fixAlpha,              /* 40 */
	CR_rgbComponentAlpha,     /* 41 */
	CR_any = -1u
}
combination_rule_t;

typedef enum {
    MR_pixelMatch, /* 0 */
    MR_notAnotB,   /* 1 */
    MR_notAmatchB, /* 2 */
}
match_rule_t;

typedef struct {
	void  *bits;
	usqInt depth;
	usqInt pitch;
	bool   msb;
	sqInt  x;
	sqInt  y;
}
src_or_dest_t;

typedef struct {
	combination_rule_t      combinationRule;
	bool                    noSource;
	src_or_dest_t           src;
	src_or_dest_t           dest;
	usqInt                  width;
	usqInt                  height;
	sqInt                   cmFlags;
	int                   (*cmShiftTable)[4];
	unsigned int          (*cmMaskTable)[4];
	usqInt                  cmMask;
	unsigned int          (*cmLookupTable)[];
	bool                    noHalftone;
	usqInt                  halftoneHeight;
	sqInt                 (*halftoneBase)[];
	union {
		sqInt               sourceAlpha;
		struct {
			sqInt           componentAlphaModeColor;
			sqInt           componentAlphaModeAlpha;
			unsigned char (*gammaLookupTable)[256];
			unsigned char (*ungammaLookupTable)[256];
		} componentAlpha;
	} opt;
}
operation_t;

typedef struct {
    match_rule_t  matchRule;
    bool          tally;
    src_or_dest_t srcA;
    src_or_dest_t srcB;
    usqInt        width;
    usqInt        height;
    usqInt        colorA;
    usqInt        colorB;
}
compare_operation_t;

typedef usqInt (*compare_colors_fn_t)(const compare_operation_t *op, usqInt log2bppA, usqInt log2bppB);

extern compare_colors_fn_t compareColorsFns[3*2*3*3];

void initialiseCopyBits(void);
void copyBitsDispatch(operation_t *op);
sqInt compareColorsDispatch(const compare_operation_t *op);

#endif /* BITBLTDISPATCH_H_ */
