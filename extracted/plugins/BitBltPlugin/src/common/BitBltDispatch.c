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
#include<stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "BitBltDispatch.h"
#include "BitBltArm.h"
#include "BitBltGeneric.h"
#include "BitBltInternal.h"

/** Define this to enable profiling */
//#define PROFILING

#ifdef PROFILING
#include <stdio.h>
#include <sys/time.h>

typedef struct profile_record {
	struct profile_record *next;
	struct profile_record *prev;
	combination_rule_t     combinationRule;
	uint32_t               flags;
	uint32_t               calls;
	uint32_t               time;
} profile_record_t;

static profile_record_t *profile_records;
static bool profile_atexit_set;

static uint32_t profile_unrecorded_cases[9];
#endif

/** Array of the test words for each fast path - avoid taking up 1/3
 *  of the cache with function pointers, most of which we don't want */
typedef struct {
	uint32_t           flags;
	combination_rule_t combinationRule;
} fast_path_test_t;

/** Pointer to heap block containing the fast path tests - not cacheline aligned */
static void             *fastPathTestBlock;

/** This array is word-aligned to minimise the number of cachelines
 *  that need to be loaded during the lookup process */
static fast_path_test_t *fastPathTestList;

/** The corresponding array of fast path function pointers */
static void           (**fastPathFuncList)(operation_t *, uint32_t);

/** Number of enabled fast paths */
static size_t            numFastPaths;

static const unsigned int  maskTable53[4] = { 0x7000, 0x0380, 0x001C, 0x0000 };
static const          int shiftTable53[4] = {     -6,     -4,     -2,      0 };
static const unsigned int  maskTable54[4] = { 0x7800, 0x03C0, 0x001E, 0x0000 };
static const          int shiftTable54[4] = {     -3,     -2,     -1,      0 };
static const unsigned int  maskTable58[4] = { 0x7C00, 0x03E0, 0x001F, 0x0000 };
static const          int shiftTable58[4] = {      9,      6,      3,      0 };
static const unsigned int  maskTable83[4] = { 0xE00000, 0x00E000, 0x0000E0, 0x000000 };
static const          int shiftTable83[4] = {      -15,      -10,       -5,        0 };
static const unsigned int  maskTable84[4] = { 0xF00000, 0x00F000, 0x0000F0, 0x000000 };
static const          int shiftTable84[4] = {      -12,       -8,       -4,        0 };
static const unsigned int  maskTable85[4] = { 0xF80000, 0x00F800, 0x0000F8, 0x000000 };
static const          int shiftTable85[4] = {       -9,       -6,       -3,        0 };

/** The dispatch table for >= 8bpp big-endian compareColors functions */
compare_colors_fn_t compareColorsFns[3*2*3*3];


#ifdef PROFILING
static uint64_t gettime(void)
{
	struct timeval tv;

	gettimeofday (&tv, NULL);
	return tv.tv_sec * 1000000 + tv.tv_usec;
}

static uint32_t clz(uint32_t x)
{
	static const uint8_t table[32] = {
			0, 31, 14, 30, 22, 13, 29, 19,  2, 21, 12, 10, 25, 28, 18,  8,
	        1, 15, 23, 20,  3, 11, 26,  9, 16, 24,  4, 27, 17,  5,  6,  7
	};
	x |= x >> 16;
	if (x == 0)
		return 32;
	x |= x >> 8;
	x |= x >> 4;
	x |= x >> 2;
	x |= x >> 1;
	x = 0x06C9C57D * x + 0x06C9C57D;
	return table[x >> 27];
}

#define BPP_FLAG_TO_BPP(flags, type) (1u << (31 - clz(((flags) / FAST_PATH_##type##_1BPP) & 0x3F)))

static void profile_atexit(void)
{
	size_t i;
	logDebug("BitBltDispatch profiling results:\n");
	logDebug("Rule,SrcBpp,SrcBE,DestBpp,DestBE,CM,HT,GC,Ov,Calls,Time\n");
	profile_record_t *rec;
	for (rec = profile_records; rec != NULL; rec = rec->next) {
		logDebug("%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",
				rec->combinationRule,
				BPP_FLAG_TO_BPP(rec->flags, SRC),
				!(rec->flags & FAST_PATH_SRC_LITTLE_ENDIAN),
				BPP_FLAG_TO_BPP(rec->flags, DEST),
				!(rec->flags & FAST_PATH_DEST_LITTLE_ENDIAN),
				rec->flags & FAST_PATH_NO_COLOR_MAP ? 0 :
				rec->flags & FAST_PATH_9BIT_COLOR_MAP ? 9 :
				rec->flags & FAST_PATH_12BIT_COLOR_MAP ? 12 : 15,
				!(rec->flags & FAST_PATH_NO_HALFTONE),
				!!(rec->flags & FAST_PATH_CA_HAS_GAMMA),
				rec->flags & FAST_PATH_NO_OVERLAP ? 0 :
				rec->flags & FAST_PATH_H_OVERLAP ? 1 : 2,
				rec->calls,
				rec->time);
	}
	const char *sep = "Unrecorded cases (hopefully should all be 0):\n";
	for (i = 0; i < sizeof profile_unrecorded_cases / sizeof *profile_unrecorded_cases; i++) {
		logDebug("%s%u", sep, profile_unrecorded_cases[i]);
		sep = ",";
	}
	logDebug("\n");
	logDebug("fast path list\n");
	for (i = 0; i < numFastPaths; i++) {
		logDebug("entry %d %u %X\n",i,  fastPathTestList[i].combinationRule, fastPathTestList[i].flags);
	}

}

static void profile_record(combination_rule_t combinationRule, uint32_t flags, uint32_t time)
{
	if (profile_atexit_set == false) {
		atexit(profile_atexit);
		profile_atexit_set = true;
	}

	/* See if we have a matching record in the list */
	profile_record_t *rec, *prev = NULL;
	for (rec = profile_records; rec != NULL; prev = rec, rec = rec->next) {
		if (rec->combinationRule == combinationRule && rec->flags == flags) {
			/* Move to head of list for efficiency */
			if (prev != NULL) {
				prev->next = rec->next;
				if (rec->next != NULL)
					rec->next->prev = prev;
				rec->next = profile_records;
				rec->prev = NULL;
				profile_records = rec;
			}
			break;
		}
	}
	if (rec == NULL) {
		rec = calloc(1, sizeof *rec);
		if (rec == NULL)
			return;
		rec->next = profile_records;
		rec->combinationRule = combinationRule;
		rec->flags = flags;
		profile_records = rec;
	}
	rec->calls++;
	rec->time += time;
}
#endif


void initialiseCopyBits(void)
{
	addGenericFastPaths();
#ifdef __arm__
	addArmFastPaths();
#endif

}

void addFastPaths(fast_path_t *paths, size_t n)
{
	void *newFastPathTestBlock = malloc((numFastPaths + n) * sizeof (fast_path_test_t) + CACHELINE_LEN);
	void (**newFastPathFuncList)(operation_t *, uint32_t) = malloc((numFastPaths + n) * sizeof *fastPathFuncList);
	if (newFastPathTestBlock == NULL || newFastPathFuncList == NULL) {
		free(newFastPathTestBlock);
		free(newFastPathFuncList);
		return;
	}
	fast_path_test_t *newFastPathTestList = (fast_path_test_t *)(((uintptr_t) newFastPathTestBlock + CACHELINE_LEN - 1) &~ (CACHELINE_LEN - 1));
	if (numFastPaths > 0) {
		/* Place the old fast paths lower down the array */
		memcpy(newFastPathTestList + n, fastPathTestList, numFastPaths * sizeof *fastPathTestList);
		memcpy(newFastPathFuncList + n, fastPathFuncList, numFastPaths * sizeof *fastPathFuncList);
		free(fastPathTestBlock);
		free(fastPathFuncList);
	}
	fastPathTestBlock = newFastPathTestBlock;
	fastPathTestList = newFastPathTestList;
	fastPathFuncList = newFastPathFuncList;
	size_t i;
	for (i = 0; i < n; i++) {
		fastPathTestList[i].combinationRule = paths[i].combinationRule;
		fastPathTestList[i].flags = paths[i].flags;
		fastPathFuncList[i] = paths[i].func;
	}
	numFastPaths += n;
}

void (*lookupFastPath(combination_rule_t combinationRule, uint32_t flags))(operation_t *, uint32_t)
{
	size_t i;
	for (i = 0; i < numFastPaths; i++) {
		if ((fastPathTestList[i].flags & flags) == 0 &&
		    (fastPathTestList[i].combinationRule == combinationRule ||
		     fastPathTestList[i].combinationRule == CR_any))
		{
			return fastPathFuncList[i];
		}
	}
	return NULL;
}

void copyBitsDispatch(operation_t *op)
{
	/* Quick check for zero-size operations here saves lookup overhead on no-ops,
	 * and saves us from having to cope with them in the fast paths */
	if (op->width == 0 || op->height == 0)
		return;

	static const uint32_t bppToFlag[33] = {
			0, FAST_PATH_SRC_1BPP, FAST_PATH_SRC_2BPP, 0, FAST_PATH_SRC_4BPP, 0, 0, 0,
			FAST_PATH_SRC_8BPP, 0, 0, 0, 0, 0, 0, 0,
			FAST_PATH_SRC_16BPP, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0,
			FAST_PATH_SRC_32BPP
	};
	uint32_t flags;
	if (op->noSource) {
		flags = FAST_PATH_SRC_0BPP | FAST_PATH_NO_OVERLAP;
	} else {
		/* A shame the depth isn't a log2 value, or we could have used a shift here instead of a lookup */
		flags = bppToFlag[op->src.depth];
		if (op->src.depth < 32) {
			if (op->src.msb)
				flags |= FAST_PATH_SRC_BIG_ENDIAN;
			else
				flags |= FAST_PATH_SRC_LITTLE_ENDIAN;
		}
		if (op->dest.bits == op->src.bits) {
			if (op->dest.y == op->src.y) {
				if (op->dest.x > op->src.x && op->dest.x < op->src.x + (signed) op->width)
					flags |= FAST_PATH_H_OVERLAP;
				else
					flags |= FAST_PATH_NO_OVERLAP;
			} else if (op->dest.y > op->src.y && op->dest.y < op->src.y + (signed) op->height)
				flags |= FAST_PATH_V_OVERLAP;
			else
				flags |= FAST_PATH_NO_OVERLAP;
		} else
			flags |= FAST_PATH_NO_OVERLAP;
	}
	flags |= bppToFlag[op->dest.depth] * (FAST_PATH_DEST_1BPP / FAST_PATH_SRC_1BPP);
	if (op->dest.depth < 32) {
		if (op->dest.msb)
			flags |= FAST_PATH_DEST_BIG_ENDIAN;
		else
			flags |= FAST_PATH_DEST_LITTLE_ENDIAN;
	}

	if (!op->noSource) {
		/* Sanity check on colour map parameters - can it be removed? */
		if (((op->cmFlags & ColorMapIndexedPart) == 0) != (op->cmLookupTable == NULL) ||
		    ((op->cmFlags & ColorMapFixedPart) == 0) != (op->cmMaskTable == NULL) ||
		    ((op->cmFlags & ColorMapFixedPart) == 0) != (op->cmShiftTable == NULL)) {
			/* Unsupported case  0 */
			copyBitsFallback(op, 0);
#ifdef PROFILING
			profile_unrecorded_cases[0]++;
#endif
			return;
		}

		if (op->cmFlags & ColorMapIndexedPart) {
			if (op->cmFlags & ColorMapFixedPart) {
				if (op->src.depth == 32) {
					if (op->cmMask == 0x7FFF && memcmp(op->cmMaskTable, maskTable85, sizeof maskTable85) == 0 && memcmp(op->cmShiftTable, shiftTable85, sizeof shiftTable85) == 0)
						flags |= FAST_PATH_15BIT_COLOR_MAP;
					else if (op->cmMask == 0xFFF && memcmp(op->cmMaskTable, maskTable84, sizeof maskTable84) == 0 && memcmp(op->cmShiftTable, shiftTable84, sizeof shiftTable84) == 0)
						flags |= FAST_PATH_12BIT_COLOR_MAP;
					else if (op->cmMask == 0x1FF && memcmp(op->cmMaskTable, maskTable83, sizeof maskTable83) == 0 && memcmp(op->cmShiftTable, shiftTable83, sizeof shiftTable83) == 0)
						flags |= FAST_PATH_9BIT_COLOR_MAP;
					else {
						/* Unsupported case 1 */
						copyBitsFallback(op, 0);
#ifdef PROFILING
						profile_unrecorded_cases[1]++;
#endif
						return;
					}
				} else if (op->src.depth == 16) {
					if (op->cmMask == 0xFFF && memcmp(op->cmMaskTable, maskTable54, sizeof maskTable54) == 0 && memcmp(op->cmShiftTable, shiftTable54, sizeof shiftTable54) == 0)
						flags |= FAST_PATH_12BIT_COLOR_MAP;
					else if (op->cmMask == 0x1FF && memcmp(op->cmMaskTable, maskTable53, sizeof maskTable53) == 0 && memcmp(op->cmShiftTable, shiftTable53, sizeof shiftTable53) == 0)
						flags |= FAST_PATH_9BIT_COLOR_MAP;
					else {
						/* Unsupported case 2 */
						copyBitsFallback(op, 0);
#ifdef PROFILING
						profile_unrecorded_cases[2]++;
#endif
						return;
					}
				} else {
					/* Unsupported case 3 */
					copyBitsFallback(op, 0);
#ifdef PROFILING
					profile_unrecorded_cases[3]++;
#endif
					return;
				}
			} else {
				if ((op->src.depth < 16 && op->cmMask == (1u << op->src.depth) - 1) ||
						(op->src.depth == 16 && op->cmMask == 0x7FFF))
					flags |= FAST_PATH_DIRECT_COLOR_MAP;
				else {
					/* Unsupported case 4 */
					copyBitsFallback(op, 0);
#ifdef PROFILING
					profile_unrecorded_cases[4]++;
#endif
					return;
				}
			}
		} else {
			if (op->cmFlags & ColorMapFixedPart) {
				if ((op->dest.depth == 32 && op->src.depth == 16 && memcmp(op->cmMaskTable, maskTable58, sizeof maskTable58) == 0 && memcmp(op->cmShiftTable, shiftTable58, sizeof shiftTable58) == 0) ||
						(op->dest.depth == 16 && op->src.depth == 32 && memcmp(op->cmMaskTable, maskTable85, sizeof maskTable85) == 0 && memcmp(op->cmShiftTable, shiftTable85, sizeof shiftTable85) == 0))
					flags |= FAST_PATH_NO_COLOR_MAP;
				else {
					/* Unsupported case 5 */
					copyBitsFallback(op, 0);
#ifdef PROFILING
					profile_unrecorded_cases[5]++;
#endif
					return;
				}
			} else {
				if (op->dest.depth == op->src.depth)
					flags |= FAST_PATH_NO_COLOR_MAP;
				else {
					/* Unsupported case 6 */
					copyBitsFallback(op, 0);
#ifdef PROFILING
					profile_unrecorded_cases[6]++;
#endif
					return;
				}
			}
		}
	}

	if (op->noHalftone)
		flags |= FAST_PATH_NO_HALFTONE;
	else if (op->halftoneHeight == 1)
		flags |= FAST_PATH_SCALAR_HALFTONE;
	else
		flags |= FAST_PATH_VECTOR_HALFTONE;

	if (op->combinationRule == CR_rgbComponentAlpha) {
		if ((op->opt.componentAlpha.gammaLookupTable == NULL) != (op->opt.componentAlpha.ungammaLookupTable == NULL)) {
			/* Unsupported case 7 */
			copyBitsFallback(op, 0);
#ifdef PROFILING
			profile_unrecorded_cases[7]++;
#endif
			return;
		}
		if (op->opt.componentAlpha.gammaLookupTable)
			flags |= FAST_PATH_CA_HAS_GAMMA;
		else
			flags |= FAST_PATH_CA_NO_GAMMA;
	}

	/* Remember the fast path function to accelerate the common case
	 * where we're performing the same operation more than once in a row */
	static combination_rule_t storedCombinationRule = CR_any; // guaranteed not to match the first time
	static uint32_t           storedFlags;
	static void             (*storedFunc)(operation_t *, uint32_t);

	if (op->combinationRule != storedCombinationRule || flags != storedFlags) {
		storedCombinationRule = op->combinationRule;
		storedFlags = flags;
		storedFunc = lookupFastPath(op->combinationRule, flags);
		if (storedFunc == NULL) {
			/* Unsupported case 8 */
#ifdef PROFILING
			profile_unrecorded_cases[8]++;
#endif
			storedFunc = copyBitsFallback;
		}
	}
#ifdef PROFILING
	uint32_t before = gettime();
#endif

	storedFunc(op, storedFlags);
#ifdef PROFILING
	uint32_t after = gettime();
	profile_record(storedCombinationRule, storedFlags, after - before);
#endif
}

sqInt compareColorsDispatch(const compare_operation_t *op)
{
    uint32_t log2bppA;
    uint32_t log2bppB;
    const compare_operation_t *op2 = op;
    compare_operation_t myOp;
    if (op->srcA.depth > op->srcB.depth && op->matchRule != MR_notAmatchB)
    {
        /* The other two rules are commutative, so we only need implement
         * the differing colour depth cases one way round */
        myOp = *op;
        op2 = &myOp;
        myOp.srcA = op->srcB;
        myOp.srcB = op->srcA;
        myOp.colorA = op->colorB;
        myOp.colorB = op->colorA;
    }
    switch (op2->srcA.depth)
    {
    case 1:  log2bppA = 0; break;
    case 2:  log2bppA = 1; break;
    case 4:  log2bppA = 2; break;
    case 8:  log2bppA = 3; break;
    case 16: log2bppA = 4; break;
    case 32:
        log2bppA = 5;
        if (op2->colorA != 0)
        {
            /* Non-transparent colors in the framebuffer are always present with
             * the alpha bits set, but that may not be the case with the constant
             * comparison color
             */
            if (op2 == op)
            {
                myOp = *op;
                op2 = &myOp;
            }
            myOp.colorA |= 0xFF000000;
        }
        break;
    default: abort();
    }
    switch (op2->srcB.depth)
    {
    case 1:  log2bppB = 0; break;
    case 2:  log2bppB = 1; break;
    case 4:  log2bppB = 2; break;
    case 8:  log2bppB = 3; break;
    case 16: log2bppB = 4; break;
    case 32:
        log2bppB = 5;
        if (op2->colorB != 0)
        {
            /* Non-transparent colors in the framebuffer are always present with
             * the alpha bits set, but that may not be the case with the constant
             * comparison color
             */
            if (op2 == op)
            {
                myOp = *op;
                op2 = &myOp;
            }
            myOp.colorB |= 0xFF000000;
        }
        break;
    default: abort();
    }
    if (log2bppA < 3 || log2bppB < 3 || !op2->srcA.msb || !op2->srcB.msb)
        /* These cases aren't catered for by the function table */
        return genericCompareColors(op2, log2bppA, log2bppB);
    else
        return compareColorsFns[(((op2->matchRule * 2) + op2->tally) * 3 + (log2bppA - 3)) * 3 + (log2bppB - 3)](op2, log2bppA, log2bppB);
}
