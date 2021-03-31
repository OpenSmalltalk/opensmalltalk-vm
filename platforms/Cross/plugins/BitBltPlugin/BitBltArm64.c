/*
 * Copyright © 2021 RISC OS Open Ltd
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

#define YES(x) x
#define NO(x)

#define LOAD_SRC_512_INTERLEAVE_YES                                  \
                "ld4     {v0.16b-v3.16b}, [%[src]], #512/8     \n\t" \

#define LOAD_SRC_512_INTERLEAVE_NO                                   \
                "ld1     {v0.16b-v3.16b}, [%[src]], #512/8     \n\t" \

#define LOAD_DEST_512_INTERLEAVE_YES                                 \
                "ld4     {v4.16b-v7.16b}, [%[dest]]            \n\t" \
                "prfm    pstl1strm, [%[dest]]                  \n\t" \

#define LOAD_DEST_512_INTERLEAVE_NO                                  \
                "ld1     {v4.16b-v7.16b}, [%[dest]]            \n\t" \
                "prfm    pstl1strm, [%[dest]]                  \n\t" \

#define STORE_DEST_512_INTERLEAVE_YES                                \
                "st4     {v0.16b-v3.16b}, [%[dest]]            \n\t" \

#define STORE_DEST_512_INTERLEAVE_NO                                 \
                "st1     {v0.16b-v3.16b}, [%[dest]]            \n\t" \

#define LOAD_SRC_256_INTERLEAVE_YES                                  \
                "ld4     {v0.8b-v3.8b}, [%[src]], #256/8       \n\t" \

#define LOAD_SRC_256_INTERLEAVE_NO                                   \
                "ld1     {v0.8b-v3.8b}, [%[src]], #256/8       \n\t" \

#define LOAD_DEST_256_INTERLEAVE_YES                                 \
                "ld4     {v4.8b-v7.8b}, [%[dest]]              \n\t" \

#define LOAD_DEST_256_INTERLEAVE_NO                                  \
                "ld1     {v4.8b-v7.8b}, [%[dest]]              \n\t" \

#define STORE_DEST_256_INTERLEAVE_YES                                \
                "st4     {v0.8b-v3.8b}, [%[dest]]              \n\t" \

#define STORE_DEST_256_INTERLEAVE_NO                                 \
                "st1     {v0.8b-v3.8b}, [%[dest]]              \n\t" \

#define UNPACK_YES(sz,rw)                                            \
                "uzp1    v16."#sz"b,  v0."#sz"b,  v1."#sz"b    \n\t" \
                "uzp2    v17."#sz"b,  v0."#sz"b,  v1."#sz"b    \n\t" \
                rw("uzp1 v20."#sz"b,  v4."#sz"b,  v5."#sz"b    \n\t")\
                rw("uzp2 v21."#sz"b,  v4."#sz"b,  v5."#sz"b    \n\t")\
                "uzp1    v18."#sz"b,  v2."#sz"b,  v3."#sz"b    \n\t" \
                "uzp2    v19."#sz"b,  v2."#sz"b,  v3."#sz"b    \n\t" \
                rw("uzp1 v22."#sz"b,  v6."#sz"b,  v7."#sz"b    \n\t")\
                rw("uzp2 v23."#sz"b,  v6."#sz"b,  v7."#sz"b    \n\t")\
                "uzp1     v0."#sz"b, v16."#sz"b, v18."#sz"b    \n\t" \
                "uzp2     v2."#sz"b, v16."#sz"b, v18."#sz"b    \n\t" \
                rw("uzp1  v4."#sz"b, v20."#sz"b, v22."#sz"b    \n\t")\
                rw("uzp2  v6."#sz"b, v20."#sz"b, v22."#sz"b    \n\t")\
                "uzp1     v1."#sz"b, v17."#sz"b, v19."#sz"b    \n\t" \
                "uzp2     v3."#sz"b, v17."#sz"b, v19."#sz"b    \n\t" \
                rw("uzp1  v5."#sz"b, v21."#sz"b, v23."#sz"b    \n\t")\
                rw("uzp2  v7."#sz"b, v21."#sz"b, v23."#sz"b    \n\t")\

#define UNPACK_NO(sz,rw) /* nothing */

#define UNPACK_DEST_YES(sz)                                          \
                "uzp1     v0."#sz"b,  v4."#sz"b,  v5."#sz"b    \n\t" \
                "uzp2     v1."#sz"b,  v4."#sz"b,  v5."#sz"b    \n\t" \
                "uzp1     v2."#sz"b,  v6."#sz"b,  v7."#sz"b    \n\t" \
                "uzp2     v3."#sz"b,  v6."#sz"b,  v7."#sz"b    \n\t" \
                "uzp1     v4."#sz"b,  v0."#sz"b,  v2."#sz"b    \n\t" \
                "uzp2     v6."#sz"b,  v0."#sz"b,  v2."#sz"b    \n\t" \
                "uzp1     v5."#sz"b,  v1."#sz"b,  v3."#sz"b    \n\t" \
                "uzp2     v7."#sz"b,  v1."#sz"b,  v3."#sz"b    \n\t" \

#define UNPACK_DEST_NO(sz) /* nothing */

#define PACK_YES(sz)                                                 \
                "zip1    v4."#sz"b, v0."#sz"b, v2."#sz"b       \n\t" \
                "zip2    v6."#sz"b, v0."#sz"b, v2."#sz"b       \n\t" \
                "zip1    v5."#sz"b, v1."#sz"b, v3."#sz"b       \n\t" \
                "zip2    v7."#sz"b, v1."#sz"b, v3."#sz"b       \n\t" \
                "zip1    v0."#sz"b, v4."#sz"b, v5."#sz"b       \n\t" \
                "zip2    v1."#sz"b, v4."#sz"b, v5."#sz"b       \n\t" \
                "zip1    v2."#sz"b, v6."#sz"b, v7."#sz"b       \n\t" \
                "zip2    v3."#sz"b, v6."#sz"b, v7."#sz"b       \n\t" \

#define PACK_NO(sz) /* nothing */

#define DEFINE_FAST_PATH_0_32(op,interleave,rw)                      \
static void fastPath##op##_0_32(operation_t *o, uint32_t flags)      \
{                                                                    \
    op##_0_32_DECLARE_TEMPORARIES;                                   \
    IGNORE(flags);                                                   \
    COPY_OP_TO_LOCALS(o, uint32_t, uint32_t);                        \
    uint32_t *dest = destBits + destPitch * destY + destX;           \
    destPitch -= width;                                              \
    __asm__ volatile (                                               \
            op##_0_32_INIT                                           \
            ""                                                       \
    : /* Outputs */                                                  \
            [dest]"+r"(dest) /* just so we can handle comma next */  \
            op##_0_32_PASS_TEMPORARIES                               \
    : /* Inputs */                                                   \
            [halftone]"r"(halftoneBase)                              \
    );                                                               \
    do {                                                             \
        uint32_t remain = width;                                     \
        __asm__ volatile (                                           \
                "tst     %[dest], #4                           \n\t" \
                "b.eq    10f                                   \n\t" \
                op##_0_32_32                                         \
                "sub     %[x], %[x], #1                        \n\t" \
                "10:                                           \n\t" \
                "subs    %[x], %[x], #512/32                   \n\t" \
                "b.mi    30f                                   \n\t" \
                "20:                                           \n\t" \
                LOAD_DEST_512_INTERLEAVE_##interleave                \
                op##_0_32_512                                        \
                STORE_DEST_512_INTERLEAVE_##interleave               \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #512/8              \n\t" \
                "subs    %[x], %[x], #512/32                   \n\t" \
                "b.pl    20b                                   \n\t" \
                "30:                                           \n\t" \
                "add     %[x], %[x], #512/32                   \n\t" \
                "cmp     %[x], #32/32                          \n\t" \
                "b.lo    90f                                   \n\t" \
                "cmp     %[x], #256/32                         \n\t" \
                "b.lo    70f                                   \n\t" \
                "b.eq    60f                                   \n\t" \
                "tbz     %[x], #8-5, 8f                        \n\t" \
                "ld1     {v4.16b-v5.16b}, [%[dest]], #256/8    \n\t" \
                "8:                                            \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "ldr     q6, [%[dest]], #128/8                 \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "ldr     d7, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 5f                        \n\t" \
                "ldr     s17, [%[dest]], #32/8                 \n\t" \
                "mov     v7.s[2], v17.s[0]                     \n\t" \
                "5:                                            \n\t" \
                "sub     %[dest], %[dest], %[x], lsl #2        \n\t" \
                UNPACK_DEST_##interleave(16)                         \
                op##_0_32_512                                        \
                PACK_##interleave(16)                                \
                "tbz     %[x], #8-5, 8f                        \n\t" \
                "st1     {v0.16b-v1.16b}, [%[dest]], #256/8    \n\t" \
                "8:                                            \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "str     q2, [%[dest]], #128/8                 \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "str     d3, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 90f                       \n\t" \
                "mov     v3.s[0], v3.s[2]                      \n\t" \
                "str     s3, [%[dest]], #32/8                  \n\t" \
                "b       90f                                   \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], %[x], lsl #2        \n\t" \
                "b       90f                                   \n\t" \
                "60:                                           \n\t" \
                LOAD_DEST_256_INTERLEAVE_##interleave                \
                op##_0_32_256                                        \
                STORE_DEST_256_INTERLEAVE_##interleave               \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #256/8              \n\t" \
                "b       90f                                   \n\t" \
                "70:                                           \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "ld1     {v4.8b-v5.8b}, [%[dest]], #128/8      \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "ldr     d6, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 5f                        \n\t" \
                "ldr     s7, [%[dest]], #32/8                  \n\t" \
                "5:                                            \n\t" \
                "sub     %[dest], %[dest], %[x], lsl #2        \n\t" \
                UNPACK_DEST_##interleave(8)                          \
                op##_0_32_256                                        \
                PACK_##interleave(8)                                 \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "st1     {v0.8b-v1.8b}, [%[dest]], #128/8      \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "str     d2, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 90f                       \n\t" \
                "str     s3, [%[dest]], #32/8                  \n\t" \
                "b       90f                                   \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], %[x], lsl #2        \n\t" \
                "90:                                           \n\t" \
        : /* Outputs */                                              \
                [dest]"+r"(dest),                                    \
                   [x]"+r"(remain)                                   \
                op##_0_32_PASS_TEMPORARIES                           \
        : /* Inputs */                                               \
        : /* Clobbers */                                             \
                "memory"                                             \
        );                                                           \
        dest += destPitch;                                           \
    } while (--height > 0);                                          \
}                                                                    \

#define DEFINE_FAST_PATH_32_32(op,interleave,rw)                     \
static void fastPath##op##_32_32(operation_t *o, uint32_t flags)     \
{                                                                    \
    op##_32_32_DECLARE_STACK;                                        \
    op##_32_32_DECLARE_TEMPORARIES;                                  \
    IGNORE(flags);                                                   \
    COPY_OP_TO_LOCALS(o, uint32_t, uint32_t);                        \
    uint32_t *src = srcBits + srcPitch * srcY + srcX;                \
    uint32_t *dest = destBits + destPitch * destY + destX;           \
    uint32_t *clut = *cmLookupTable;                                 \
    srcPitch -= width;                                               \
    destPitch -= width;                                              \
    __asm__ volatile (                                               \
            op##_32_32_INIT                                          \
            ""                                                       \
    : /* Outputs */                                                  \
            [clut]"+r"(clut)                                         \
            op##_32_32_PASS_TEMPORARIES                              \
    : /* Inputs */                                                   \
            [halftone]"r"(halftoneBase)                              \
            op##_32_32_PASS_STACK                                    \
    : /* Clobbers */                                                 \
            "memory"                                                 \
    );                                                               \
    do {                                                             \
        uint32_t remain = width;                                     \
        __asm__ volatile (                                           \
                "tst     %[dest], #4                           \n\t" \
                "b.eq    10f                                   \n\t" \
                op##_32_32_32                                        \
                "sub     %[x], %[x], #1                        \n\t" \
                "10:                                           \n\t" \
                "subs    %[x], %[x], #512/32                   \n\t" \
                "b.mi    30f                                   \n\t" \
                "20:                                           \n\t" \
                LOAD_SRC_512_INTERLEAVE_##interleave                 \
                rw(LOAD_DEST_512_INTERLEAVE_##interleave)            \
                op##_32_32_512                                       \
                STORE_DEST_512_INTERLEAVE_##interleave               \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #512/8              \n\t" \
                "subs    %[x], %[x], #512/32                   \n\t" \
                "b.pl    20b                                   \n\t" \
                "30:                                           \n\t" \
                "add     %[x], %[x], #512/32                   \n\t" \
                "cmp     %[x], #32/32                          \n\t" \
                "b.lo    90f                                   \n\t" \
                "b.eq    80f                                   \n\t" \
                "cmp     %[x], #256/32                         \n\t" \
                "b.lo    70f                                   \n\t" \
                "b.eq    60f                                   \n\t" \
                "tbz     %[x], #8-5, 8f                        \n\t" \
                "ld1     {v0.16b-v1.16b}, [%[src]], #256/8     \n\t" \
                rw("ld1  {v4.16b-v5.16b}, [%[dest]], #256/8    \n\t")\
                "8:                                            \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "ldr     q2, [%[src]], #128/8                  \n\t" \
                rw("ldr  q6, [%[dest]], #128/8                 \n\t")\
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "ldr     d3, [%[src]], #64/8                   \n\t" \
                rw("ldr  d7, [%[dest]], #64/8                  \n\t")\
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 5f                        \n\t" \
                "ldr     s16, [%[src]], #32/8                  \n\t" \
                rw("ldr  s17, [%[dest]], #32/8                 \n\t")\
                "mov     v3.s[2], v16.s[0]                     \n\t" \
                rw("mov  v7.s[2], v17.s[0]                     \n\t")\
                "5:                                            \n\t" \
                rw("sub  %[dest], %[dest], %[x], lsl #2        \n\t")\
                UNPACK_##interleave(16,rw)                           \
                op##_32_32_512                                       \
                PACK_##interleave(16)                                \
                "tbz     %[x], #8-5, 8f                        \n\t" \
                "st1     {v0.16b-v1.16b}, [%[dest]], #256/8    \n\t" \
                "8:                                            \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "str     q2, [%[dest]], #128/8                 \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "str     d3, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 90f                       \n\t" \
                "mov     v3.s[0], v3.s[2]                      \n\t" \
                "str     s3, [%[dest]], #32/8                  \n\t" \
                "b       90f                                   \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], %[x], lsl #2        \n\t" \
                "b       90f                                   \n\t" \
                "60:                                           \n\t" \
                LOAD_SRC_256_INTERLEAVE_##interleave                 \
                rw(LOAD_DEST_256_INTERLEAVE_##interleave)            \
                op##_32_32_256                                       \
                STORE_DEST_256_INTERLEAVE_##interleave               \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #256/8              \n\t" \
                "b       90f                                   \n\t" \
                "70:                                           \n\t" \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "ld1     {v0.8b-v1.8b}, [%[src]], #128/8       \n\t" \
                rw("ld1  {v4.8b-v5.8b}, [%[dest]], #128/8      \n\t")\
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "ldr     d2, [%[src]], #64/8                   \n\t" \
                rw("ldr  d6, [%[dest]], #64/8                  \n\t")\
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 5f                        \n\t" \
                "ldr     s3, [%[src]], #32/8                   \n\t" \
                rw("ldr  s7, [%[dest]], #32/8                  \n\t")\
                "5:                                            \n\t" \
                rw("sub  %[dest], %[dest], %[x], lsl #2        \n\t")\
                UNPACK_##interleave(8,rw)                            \
                op##_32_32_256                                       \
                PACK_##interleave(8)                                 \
                "tbz     %[x], #7-5, 7f                        \n\t" \
                "st1     {v0.8b-v1.8b}, [%[dest]], #128/8      \n\t" \
                "7:                                            \n\t" \
                "tbz     %[x], #6-5, 6f                        \n\t" \
                "str     d2, [%[dest]], #64/8                  \n\t" \
                "6:                                            \n\t" \
                "tbz     %[x], #5-5, 90f                       \n\t" \
                "str     s3, [%[dest]], #32/8                  \n\t" \
                "b       90f                                   \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], %[x], lsl #2        \n\t" \
                "b       90f                                   \n\t" \
                "80:                                           \n\t" \
                op##_32_32_32                                        \
                "90:                                           \n\t" \
        : /* Outputs */                                              \
                 [src]"+r"(src),                                     \
                [dest]"+r"(dest),                                    \
                   [x]"+r"(remain)                                   \
                op##_32_32_PASS_TEMPORARIES                          \
        : /* Inputs */                                               \
        : /* Clobbers */                                             \
                "memory"                                             \
        );                                                           \
        src += srcPitch;                                             \
        dest += destPitch;                                           \
    } while (--height > 0);                                          \
    __asm__ volatile (                                               \
            op##_32_32_FINAL                                         \
            ""                                                       \
    : /* Outputs */                                                  \
    : /* Inputs */                                                   \
            [unused]"I"(0)                                           \
            op##_32_32_PASS_STACK                                    \
    );                                                               \
}                                                                    \

#define DEFINE_FAST_PATH(op, src_dst, interleave, rw) DEFINE_FAST_PATH_##src_dst(op, interleave, rw)

/******************************************************************************/

#define BitAnd_32_32_DECLARE_STACK

#define BitAnd_32_32_PASS_STACK

#define BitAnd_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitAnd_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitAnd_32_32_INIT

#define BitAnd_32_32_FINAL

#define BitAnd_32_32_32                                              \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "and     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitAnd_32_32_256                                             \
                "and     v0.8b, v0.8b, v4.8b                   \n\t" \
                "and     v1.8b, v1.8b, v5.8b                   \n\t" \
                "and     v2.8b, v2.8b, v6.8b                   \n\t" \
                "and     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitAnd_32_32_512                                             \
                "and     v0.16b, v0.16b, v4.16b                \n\t" \
                "and     v1.16b, v1.16b, v5.16b                \n\t" \
                "and     v2.16b, v2.16b, v6.16b                \n\t" \
                "and     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitAnd, 32_32, NO, YES)

/******************************************************************************/

#define BitAndInvert_32_32_DECLARE_STACK

#define BitAndInvert_32_32_PASS_STACK

#define BitAndInvert_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitAndInvert_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitAndInvert_32_32_INIT

#define BitAndInvert_32_32_FINAL

#define BitAndInvert_32_32_32                                        \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "bic     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitAndInvert_32_32_256                                       \
                "bic     v0.8b, v0.8b, v4.8b                   \n\t" \
                "bic     v1.8b, v1.8b, v5.8b                   \n\t" \
                "bic     v2.8b, v2.8b, v6.8b                   \n\t" \
                "bic     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitAndInvert_32_32_512                                       \
                "bic     v0.16b, v0.16b, v4.16b                \n\t" \
                "bic     v1.16b, v1.16b, v5.16b                \n\t" \
                "bic     v2.16b, v2.16b, v6.16b                \n\t" \
                "bic     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitAndInvert, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertAnd_32_32_DECLARE_STACK

#define BitInvertAnd_32_32_PASS_STACK

#define BitInvertAnd_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitInvertAnd_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitInvertAnd_32_32_INIT

#define BitInvertAnd_32_32_FINAL

#define BitInvertAnd_32_32_32                                        \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "bic     %w[tmp0], %w[tmp1], %w[tmp0]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitInvertAnd_32_32_256                                       \
                "bic     v0.8b, v4.8b, v0.8b                   \n\t" \
                "bic     v1.8b, v5.8b, v1.8b                   \n\t" \
                "bic     v2.8b, v6.8b, v2.8b                   \n\t" \
                "bic     v3.8b, v7.8b, v3.8b                   \n\t" \

#define BitInvertAnd_32_32_512                                       \
                "bic     v0.16b, v4.16b, v0.16b                \n\t" \
                "bic     v1.16b, v5.16b, v1.16b                \n\t" \
                "bic     v2.16b, v6.16b, v2.16b                \n\t" \
                "bic     v3.16b, v7.16b, v3.16b                \n\t" \

DEFINE_FAST_PATH(BitInvertAnd, 32_32, NO, YES)

/******************************************************************************/

#define BitXor_32_32_DECLARE_STACK

#define BitXor_32_32_PASS_STACK

#define BitXor_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitXor_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitXor_32_32_INIT

#define BitXor_32_32_FINAL

#define BitXor_32_32_32                                              \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "eor     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitXor_32_32_256                                             \
                "eor     v0.8b, v0.8b, v4.8b                   \n\t" \
                "eor     v1.8b, v1.8b, v5.8b                   \n\t" \
                "eor     v2.8b, v2.8b, v6.8b                   \n\t" \
                "eor     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitXor_32_32_512                                             \
                "eor     v0.16b, v0.16b, v4.16b                \n\t" \
                "eor     v1.16b, v1.16b, v5.16b                \n\t" \
                "eor     v2.16b, v2.16b, v6.16b                \n\t" \
                "eor     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitXor, 32_32, NO, YES)

/******************************************************************************/

#define BitOr_32_32_DECLARE_STACK

#define BitOr_32_32_PASS_STACK

#define BitOr_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitOr_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitOr_32_32_INIT

#define BitOr_32_32_FINAL

#define BitOr_32_32_32                                               \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "orr     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitOr_32_32_256                                              \
                "orr     v0.8b, v0.8b, v4.8b                   \n\t" \
                "orr     v1.8b, v1.8b, v5.8b                   \n\t" \
                "orr     v2.8b, v2.8b, v6.8b                   \n\t" \
                "orr     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitOr_32_32_512                                              \
                "orr     v0.16b, v0.16b, v4.16b                \n\t" \
                "orr     v1.16b, v1.16b, v5.16b                \n\t" \
                "orr     v2.16b, v2.16b, v6.16b                \n\t" \
                "orr     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitOr, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertAndInvert_32_32_DECLARE_STACK

#define BitInvertAndInvert_32_32_PASS_STACK

#define BitInvertAndInvert_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitInvertAndInvert_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitInvertAndInvert_32_32_INIT

#define BitInvertAndInvert_32_32_FINAL

#define BitInvertAndInvert_32_32_32                                  \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "orr     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "mvn     %w[tmp0], %w[tmp0]                    \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitInvertAndInvert_32_32_256                                 \
                "orr     v0.8b, v0.8b, v4.8b                   \n\t" \
                "orr     v1.8b, v1.8b, v5.8b                   \n\t" \
                "orr     v2.8b, v2.8b, v6.8b                   \n\t" \
                "orr     v3.8b, v3.8b, v7.8b                   \n\t" \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "mvn     v1.8b, v1.8b                          \n\t" \
                "mvn     v2.8b, v2.8b                          \n\t" \
                "mvn     v3.8b, v3.8b                          \n\t" \

#define BitInvertAndInvert_32_32_512                                 \
                "orr     v0.16b, v0.16b, v4.16b                \n\t" \
                "orr     v1.16b, v1.16b, v5.16b                \n\t" \
                "orr     v2.16b, v2.16b, v6.16b                \n\t" \
                "orr     v3.16b, v3.16b, v7.16b                \n\t" \
                "mvn     v0.16b, v0.16b                        \n\t" \
                "mvn     v1.16b, v1.16b                        \n\t" \
                "mvn     v2.16b, v2.16b                        \n\t" \
                "mvn     v3.16b, v3.16b                        \n\t" \

DEFINE_FAST_PATH(BitInvertAndInvert, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertXor_32_32_DECLARE_STACK

#define BitInvertXor_32_32_PASS_STACK

#define BitInvertXor_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitInvertXor_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitInvertXor_32_32_INIT

#define BitInvertXor_32_32_FINAL

#define BitInvertXor_32_32_32                                        \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "mvn     %w[tmp0], %w[tmp0]                    \n\t" \
                "eor     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitInvertXor_32_32_256                                       \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "mvn     v1.8b, v1.8b                          \n\t" \
                "mvn     v2.8b, v2.8b                          \n\t" \
                "mvn     v3.8b, v3.8b                          \n\t" \
                "eor     v0.8b, v0.8b, v4.8b                   \n\t" \
                "eor     v1.8b, v1.8b, v5.8b                   \n\t" \
                "eor     v2.8b, v2.8b, v6.8b                   \n\t" \
                "eor     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitInvertXor_32_32_512                                       \
                "mvn     v0.16b, v0.16b                        \n\t" \
                "mvn     v1.16b, v1.16b                        \n\t" \
                "mvn     v2.16b, v2.16b                        \n\t" \
                "mvn     v3.16b, v3.16b                        \n\t" \
                "eor     v0.16b, v0.16b, v4.16b                \n\t" \
                "eor     v1.16b, v1.16b, v5.16b                \n\t" \
                "eor     v2.16b, v2.16b, v6.16b                \n\t" \
                "eor     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitInvertXor, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertDestination_0_32_DECLARE_STACK

#define BitInvertDestination_0_32_PASS_STACK

#define BitInvertDestination_0_32_DECLARE_TEMPORARIES uint64_t tmp

#define BitInvertDestination_0_32_PASS_TEMPORARIES , [tmp]"=&r"(tmp)

#define BitInvertDestination_0_32_INIT

#define BitInvertDestination_0_32_FINAL

#define BitInvertDestination_0_32_32                                 \
                "ldr     %w[tmp], [%[dest]]                    \n\t" \
                "mvn     %w[tmp], %w[tmp]                      \n\t" \
                "str     %w[tmp], [%[dest]], #4                \n\t" \

#define BitInvertDestination_0_32_256                                \
                "mvn     v0.8b, v4.8b                          \n\t" \
                "mvn     v1.8b, v5.8b                          \n\t" \
                "mvn     v2.8b, v6.8b                          \n\t" \
                "mvn     v3.8b, v7.8b                          \n\t" \

#define BitInvertDestination_0_32_512                                \
                "mvn     v0.16b, v4.16b                        \n\t" \
                "mvn     v1.16b, v5.16b                        \n\t" \
                "mvn     v2.16b, v6.16b                        \n\t" \
                "mvn     v3.16b, v7.16b                        \n\t" \

DEFINE_FAST_PATH(BitInvertDestination, 0_32, NO, YES)

/******************************************************************************/

#define BitOrInvert_32_32_DECLARE_STACK

#define BitOrInvert_32_32_PASS_STACK

#define BitOrInvert_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitOrInvert_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitOrInvert_32_32_INIT

#define BitOrInvert_32_32_FINAL

#define BitOrInvert_32_32_32                                         \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "orn     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitOrInvert_32_32_256                                        \
                "orn     v0.8b, v0.8b, v4.8b                   \n\t" \
                "orn     v1.8b, v1.8b, v5.8b                   \n\t" \
                "orn     v2.8b, v2.8b, v6.8b                   \n\t" \
                "orn     v3.8b, v3.8b, v7.8b                   \n\t" \

#define BitOrInvert_32_32_512                                        \
                "orn     v0.16b, v0.16b, v4.16b                \n\t" \
                "orn     v1.16b, v1.16b, v5.16b                \n\t" \
                "orn     v2.16b, v2.16b, v6.16b                \n\t" \
                "orn     v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(BitOrInvert, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertSource_32_32_DECLARE_STACK

#define BitInvertSource_32_32_PASS_STACK

#define BitInvertSource_32_32_DECLARE_TEMPORARIES uint64_t tmp

#define BitInvertSource_32_32_PASS_TEMPORARIES , [tmp]"=&r"(tmp)

#define BitInvertSource_32_32_INIT

#define BitInvertSource_32_32_FINAL

#define BitInvertSource_32_32_32                                     \
                "ldr     %w[tmp], [%[src]], #4                 \n\t" \
                "mvn     %w[tmp], %w[tmp]                      \n\t" \
                "str     %w[tmp], [%[dest]], #4                \n\t" \

#define BitInvertSource_32_32_256                                    \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "mvn     v1.8b, v1.8b                          \n\t" \
                "mvn     v2.8b, v2.8b                          \n\t" \
                "mvn     v3.8b, v3.8b                          \n\t" \

#define BitInvertSource_32_32_512                                    \
                "mvn     v0.16b, v0.16b                        \n\t" \
                "mvn     v1.16b, v1.16b                        \n\t" \
                "mvn     v2.16b, v2.16b                        \n\t" \
                "mvn     v3.16b, v3.16b                        \n\t" \

DEFINE_FAST_PATH(BitInvertSource, 32_32, NO, NO)

/******************************************************************************/

#define BitInvertOr_32_32_DECLARE_STACK

#define BitInvertOr_32_32_PASS_STACK

#define BitInvertOr_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitInvertOr_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitInvertOr_32_32_INIT

#define BitInvertOr_32_32_FINAL

#define BitInvertOr_32_32_32                                         \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "orn     %w[tmp0], %w[tmp1], %w[tmp0]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitInvertOr_32_32_256                                        \
                "orn     v0.8b, v4.8b, v0.8b                   \n\t" \
                "orn     v1.8b, v5.8b, v1.8b                   \n\t" \
                "orn     v2.8b, v6.8b, v2.8b                   \n\t" \
                "orn     v3.8b, v7.8b, v3.8b                   \n\t" \

#define BitInvertOr_32_32_512                                        \
                "orn     v0.16b, v4.16b, v0.16b                \n\t" \
                "orn     v1.16b, v5.16b, v1.16b                \n\t" \
                "orn     v2.16b, v6.16b, v2.16b                \n\t" \
                "orn     v3.16b, v7.16b, v3.16b                \n\t" \

DEFINE_FAST_PATH(BitInvertOr, 32_32, NO, YES)

/******************************************************************************/

#define BitInvertOrInvert_32_32_DECLARE_STACK

#define BitInvertOrInvert_32_32_PASS_STACK

#define BitInvertOrInvert_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define BitInvertOrInvert_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define BitInvertOrInvert_32_32_INIT

#define BitInvertOrInvert_32_32_FINAL

#define BitInvertOrInvert_32_32_32                                   \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "and     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "mvn     %w[tmp0], %w[tmp0]                    \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define BitInvertOrInvert_32_32_256                                  \
                "and     v0.8b, v0.8b, v4.8b                   \n\t" \
                "and     v1.8b, v1.8b, v5.8b                   \n\t" \
                "and     v2.8b, v2.8b, v6.8b                   \n\t" \
                "and     v3.8b, v3.8b, v7.8b                   \n\t" \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "mvn     v1.8b, v1.8b                          \n\t" \
                "mvn     v2.8b, v2.8b                          \n\t" \
                "mvn     v3.8b, v3.8b                          \n\t" \

#define BitInvertOrInvert_32_32_512                                  \
                "and     v0.16b, v0.16b, v4.16b                \n\t" \
                "and     v1.16b, v1.16b, v5.16b                \n\t" \
                "and     v2.16b, v2.16b, v6.16b                \n\t" \
                "and     v3.16b, v3.16b, v7.16b                \n\t" \
                "mvn     v0.16b, v0.16b                        \n\t" \
                "mvn     v1.16b, v1.16b                        \n\t" \
                "mvn     v2.16b, v2.16b                        \n\t" \
                "mvn     v3.16b, v3.16b                        \n\t" \

DEFINE_FAST_PATH(BitInvertOrInvert, 32_32, NO, YES)

/******************************************************************************/

#define AddWord_32_32_DECLARE_STACK

#define AddWord_32_32_PASS_STACK

#define AddWord_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define AddWord_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define AddWord_32_32_INIT

#define AddWord_32_32_FINAL

#define AddWord_32_32_32                                             \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "add     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define AddWord_32_32_256                                            \
                "add     v0.2s, v0.2s, v4.2s                   \n\t" \
                "add     v1.2s, v1.2s, v5.2s                   \n\t" \
                "add     v2.2s, v2.2s, v6.2s                   \n\t" \
                "add     v3.2s, v3.2s, v7.2s                   \n\t" \

#define AddWord_32_32_512                                            \
                "add     v0.4s, v0.4s, v4.4s                   \n\t" \
                "add     v1.4s, v1.4s, v5.4s                   \n\t" \
                "add     v2.4s, v2.4s, v6.4s                   \n\t" \
                "add     v3.4s, v3.4s, v7.4s                   \n\t" \

DEFINE_FAST_PATH(AddWord, 32_32, NO, YES)

/******************************************************************************/

#define SubWord_32_32_DECLARE_STACK

#define SubWord_32_32_PASS_STACK

#define SubWord_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define SubWord_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define SubWord_32_32_INIT

#define SubWord_32_32_FINAL

#define SubWord_32_32_32                                             \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "ldr     %w[tmp1], [%[dest]]                   \n\t" \
                "sub     %w[tmp0], %w[tmp0], %w[tmp1]          \n\t" \
                "str     %w[tmp0], [%[dest]], #4               \n\t" \

#define SubWord_32_32_256                                            \
                "sub     v0.2s, v0.2s, v4.2s                   \n\t" \
                "sub     v1.2s, v1.2s, v5.2s                   \n\t" \
                "sub     v2.2s, v2.2s, v6.2s                   \n\t" \
                "sub     v3.2s, v3.2s, v7.2s                   \n\t" \

#define SubWord_32_32_512                                            \
                "sub     v0.4s, v0.4s, v4.4s                   \n\t" \
                "sub     v1.4s, v1.4s, v5.4s                   \n\t" \
                "sub     v2.4s, v2.4s, v6.4s                   \n\t" \
                "sub     v3.4s, v3.4s, v7.4s                   \n\t" \

DEFINE_FAST_PATH(SubWord, 32_32, NO, YES)

/******************************************************************************/

#define RgbAdd_32_32_DECLARE_STACK

#define RgbAdd_32_32_PASS_STACK

#define RgbAdd_32_32_DECLARE_TEMPORARIES

#define RgbAdd_32_32_PASS_TEMPORARIES

#define RgbAdd_32_32_INIT

#define RgbAdd_32_32_FINAL

#define RgbAdd_32_32_32                                              \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "uqadd   v0.8b, v0.8b, v4.8b                   \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define RgbAdd_32_32_256                                             \
                "uqadd   v0.8b, v0.8b, v4.8b                   \n\t" \
                "uqadd   v1.8b, v1.8b, v5.8b                   \n\t" \
                "uqadd   v2.8b, v2.8b, v6.8b                   \n\t" \
                "uqadd   v3.8b, v3.8b, v7.8b                   \n\t" \

#define RgbAdd_32_32_512                                             \
                "uqadd   v0.16b, v0.16b, v4.16b                \n\t" \
                "uqadd   v1.16b, v1.16b, v5.16b                \n\t" \
                "uqadd   v2.16b, v2.16b, v6.16b                \n\t" \
                "uqadd   v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(RgbAdd, 32_32, NO, YES)

/******************************************************************************/

#define RgbSub_32_32_DECLARE_STACK

#define RgbSub_32_32_PASS_STACK

#define RgbSub_32_32_DECLARE_TEMPORARIES

#define RgbSub_32_32_PASS_TEMPORARIES

#define RgbSub_32_32_INIT

#define RgbSub_32_32_FINAL

#define RgbSub_32_32_32                                              \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "uabd    v0.8b, v0.8b, v4.8b                   \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define RgbSub_32_32_256                                             \
                "uabd    v0.8b, v0.8b, v4.8b                   \n\t" \
                "uabd    v1.8b, v1.8b, v5.8b                   \n\t" \
                "uabd    v2.8b, v2.8b, v6.8b                   \n\t" \
                "uabd    v3.8b, v3.8b, v7.8b                   \n\t" \

#define RgbSub_32_32_512                                             \
                "uabd    v0.16b, v0.16b, v4.16b                \n\t" \
                "uabd    v1.16b, v1.16b, v5.16b                \n\t" \
                "uabd    v2.16b, v2.16b, v6.16b                \n\t" \
                "uabd    v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(RgbSub, 32_32, NO, YES)

/******************************************************************************/

#define AlphaBlend_32_32_DECLARE_STACK

#define AlphaBlend_32_32_PASS_STACK

#define AlphaBlend_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define AlphaBlend_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define AlphaBlend_32_32_INIT                                        \
                "movi    v31.16b, #0xFF                        \n\t" \
                "ldr     s30, =0xFF000000                      \n\t" \

#define AlphaBlend_32_32_FINAL

#define AlphaBlend_32_32_32                                          \
                "ldrb    %w[tmp0], [%[src], #3]                \n\t" \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "cbz     %[tmp0], 2f                           \n\t" \
                "cmp     %[tmp0], #0xFF                        \n\t" \
                "b.eq    1f                                    \n\t" \
                "ldr     s1, [%[dest]]                         \n\t" \
                "orr     v2.8b, v30.8b, v0.8b                  \n\t" \
                "mvn     v3.8b, v0.8b                          \n\t" \
                "dup     v0.8b, v0.b[3]                        \n\t" \
                "dup     v3.8b, v3.b[3]                        \n\t" \
                "umull   v0.8h, v2.8b, v0.8b                   \n\t" \
                "umlal   v0.8h, v1.8b, v3.8b                   \n\t" \
                "cmtst   v1.4h, v0.4h, v31.4h                  \n\t" \
                "usra    v0.4h, v0.4h, #8                      \n\t" \
                "sub     v0.8b, v0.8b, v1.8b                   \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "1:                                            \n\t" \
                "str     s0, [%[dest]]                         \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #4                  \n\t" \

#define AlphaBlend_32_32_256                                         \
                "mov     %[tmp0], v3.d[0]                      \n\t" \
                "cbz     %[tmp0], 2f                           \n\t" \
                "cmp     %[tmp0], #-1                          \n\t" \
                "b.eq    1f                                    \n\t" \
                "mvn     v16.8b, v3.8b                         \n\t" \
                "umull   v0.8h, v0.8b, v3.8b                   \n\t" \
                "umlal   v0.8h, v4.8b, v16.8b                  \n\t" \
                "umull   v1.8h, v1.8b, v3.8b                   \n\t" \
                "umlal   v1.8h, v5.8b, v16.8b                  \n\t" \
                "umull   v2.8h, v2.8b, v3.8b                   \n\t" \
                "umlal   v2.8h, v6.8b, v16.8b                  \n\t" \
                "umull   v3.8h, v31.8b, v3.8b                  \n\t" \
                "umlal   v3.8h, v7.8b, v16.8b                  \n\t" \
                "cmtst   v4.8h, v0.8h, v31.8h                  \n\t" \
                "cmtst   v5.8h, v1.8h, v31.8h                  \n\t" \
                "cmtst   v6.8h, v2.8h, v31.8h                  \n\t" \
                "cmtst   v7.8h, v3.8h, v31.8h                  \n\t" \
                "usra    v0.8h, v0.8h, #8                      \n\t" \
                "usra    v1.8h, v1.8h, #8                      \n\t" \
                "usra    v2.8h, v2.8h, #8                      \n\t" \
                "usra    v3.8h, v3.8h, #8                      \n\t" \
                "sub     v0.16b, v0.16b, v4.16b                \n\t" \
                "sub     v1.16b, v1.16b, v5.16b                \n\t" \
                "sub     v2.16b, v2.16b, v6.16b                \n\t" \
                "sub     v3.16b, v3.16b, v7.16b                \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "shrn    v1.8b, v1.8h, #8                      \n\t" \
                "shrn    v2.8b, v2.8h, #8                      \n\t" \
                "shrn    v3.8b, v3.8h, #8                      \n\t" \
                "1:                                            \n\t" \

#define AlphaBlend_32_32_512                                         \
                "mov     %[tmp0], v3.d[0]                      \n\t" \
                "mov     %[tmp1], v3.d[1]                      \n\t" \
                "cmp     %[tmp0], #0                           \n\t" \
                "ccmp    %[tmp1], #0, #0, eq                   \n\t" \
                "b.eq    2f                                    \n\t" \
                "cmn     %[tmp0], #1                           \n\t" \
                "ccmn    %[tmp1], #1, #0, eq                   \n\t" \
                "b.eq    1f                                    \n\t" \
                "mvn     v16.16b, v3.16b                       \n\t" \
                "umull   v20.8h, v0.8b, v3.8b                  \n\t" \
                "umlal   v20.8h, v4.8b, v16.8b                 \n\t" \
                "umull2  v21.8h, v0.16b, v3.16b                \n\t" \
                "umlal2  v21.8h, v4.16b, v16.16b               \n\t" \
                "umull   v22.8h, v1.8b, v3.8b                  \n\t" \
                "umlal   v22.8h, v5.8b, v16.8b                 \n\t" \
                "umull2  v23.8h, v1.16b, v3.16b                \n\t" \
                "umlal2  v23.8h, v5.16b, v16.16b               \n\t" \
                "umull   v24.8h, v2.8b, v3.8b                  \n\t" \
                "umlal   v24.8h, v6.8b, v16.8b                 \n\t" \
                "umull2  v25.8h, v2.16b, v3.16b                \n\t" \
                "umlal2  v25.8h, v6.16b, v16.16b               \n\t" \
                "umull   v26.8h, v31.8b, v3.8b                 \n\t" \
                "umlal   v26.8h, v7.8b, v16.8b                 \n\t" \
                "umull2  v27.8h, v31.16b, v3.16b               \n\t" \
                "umlal2  v27.8h, v7.16b, v16.16b               \n\t" \
                "cmtst   v0.8h, v20.8h, v31.8h                 \n\t" \
                "cmtst   v1.8h, v21.8h, v31.8h                 \n\t" \
                "cmtst   v2.8h, v22.8h, v31.8h                 \n\t" \
                "cmtst   v3.8h, v23.8h, v31.8h                 \n\t" \
                "cmtst   v4.8h, v24.8h, v31.8h                 \n\t" \
                "cmtst   v5.8h, v25.8h, v31.8h                 \n\t" \
                "cmtst   v6.8h, v26.8h, v31.8h                 \n\t" \
                "cmtst   v7.8h, v27.8h, v31.8h                 \n\t" \
                "usra    v20.8h, v20.8h, #8                    \n\t" \
                "usra    v21.8h, v21.8h, #8                    \n\t" \
                "usra    v22.8h, v22.8h, #8                    \n\t" \
                "usra    v23.8h, v23.8h, #8                    \n\t" \
                "usra    v24.8h, v24.8h, #8                    \n\t" \
                "usra    v25.8h, v25.8h, #8                    \n\t" \
                "usra    v26.8h, v26.8h, #8                    \n\t" \
                "usra    v27.8h, v27.8h, #8                    \n\t" \
                "sub     v0.16b, v20.16b, v0.16b               \n\t" \
                "sub     v1.16b, v21.16b, v1.16b               \n\t" \
                "sub     v2.16b, v22.16b, v2.16b               \n\t" \
                "sub     v3.16b, v23.16b, v3.16b               \n\t" \
                "sub     v4.16b, v24.16b, v4.16b               \n\t" \
                "sub     v5.16b, v25.16b, v5.16b               \n\t" \
                "sub     v6.16b, v26.16b, v6.16b               \n\t" \
                "sub     v7.16b, v27.16b, v7.16b               \n\t" \
                "shrn    v0.8b,  v0.8h, #8                     \n\t" \
                "shrn    v20.8b, v1.8h, #8                     \n\t" \
                "shrn    v1.8b,  v2.8h, #8                     \n\t" \
                "shrn    v21.8b, v3.8h, #8                     \n\t" \
                "shrn    v2.8b,  v4.8h, #8                     \n\t" \
                "shrn    v22.8b, v5.8h, #8                     \n\t" \
                "shrn    v3.8b,  v6.8h, #8                     \n\t" \
                "shrn    v23.8b, v7.8h, #8                     \n\t" \
                "mov     v0.d[1], v20.d[0]                     \n\t" \
                "mov     v1.d[1], v21.d[0]                     \n\t" \
                "mov     v2.d[1], v22.d[0]                     \n\t" \
                "mov     v3.d[1], v23.d[0]                     \n\t" \
                "1:                                            \n\t" \

DEFINE_FAST_PATH(AlphaBlend, 32_32, YES, YES)

/******************************************************************************/

#define PixPaint_32_32_DECLARE_STACK

#define PixPaint_32_32_PASS_STACK

#define PixPaint_32_32_DECLARE_TEMPORARIES uint64_t tmp0, tmp1

#define PixPaint_32_32_PASS_TEMPORARIES , [tmp0]"=&r"(tmp0), [tmp1]"=&r"(tmp1)

#define PixPaint_32_32_INIT

#define PixPaint_32_32_FINAL

#define PixPaint_32_32_32                                            \
                "ldr     %w[tmp0], [%[src]], #4                \n\t" \
                "cbz     %[tmp0], 2f                           \n\t" \
                "str     %w[tmp0], [%[dest]]                   \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #4                  \n\t" \

#define PixPaint_32_32_256                                           \
                "orr     v16.8b, v0.8b, v1.8b                  \n\t" \
                "orr     v17.8b, v2.8b, v3.8b                  \n\t" \
                "orr     v16.8b, v16.8b, v17.8b                \n\t" \
                "mov     %[tmp0], v16.d[0]                     \n\t" \
                "cbz     %[tmp0], 2f                           \n\t" \
                "cmeq    v16.2s, v0.2s, #0                     \n\t" \
                "cmeq    v17.2s, v1.2s, #0                     \n\t" \
                "cmeq    v18.2s, v2.2s, #0                     \n\t" \
                "cmeq    v19.2s, v3.2s, #0                     \n\t" \
                "bit     v0.8b, v4.8b, v16.8b                  \n\t" \
                "bit     v1.8b, v5.8b, v17.8b                  \n\t" \
                "bit     v2.8b, v6.8b, v18.8b                  \n\t" \
                "bit     v3.8b, v7.8b, v19.8b                  \n\t" \

#define PixPaint_32_32_512                                           \
                "orr     v16.16b, v0.16b, v1.16b               \n\t" \
                "orr     v17.16b, v2.16b, v3.16b               \n\t" \
                "orr     v16.16b, v16.16b, v17.16b             \n\t" \
                "mov     %[tmp0], v16.d[0]                     \n\t" \
                "mov     %[tmp1], v16.d[1]                     \n\t" \
                "orr     %[tmp0], %[tmp0], %[tmp1]             \n\t" \
                "cbz     %[tmp0], 2f                           \n\t" \
                "cmeq    v16.4s, v0.4s, #0                     \n\t" \
                "cmeq    v17.4s, v1.4s, #0                     \n\t" \
                "cmeq    v18.4s, v2.4s, #0                     \n\t" \
                "cmeq    v19.4s, v3.4s, #0                     \n\t" \
                "bit     v0.16b, v4.16b, v16.16b               \n\t" \
                "bit     v1.16b, v5.16b, v17.16b               \n\t" \
                "bit     v2.16b, v6.16b, v18.16b               \n\t" \
                "bit     v3.16b, v7.16b, v19.16b               \n\t" \

DEFINE_FAST_PATH(PixPaint, 32_32, NO, YES)

/******************************************************************************/

#define PixMask_32_32_DECLARE_STACK

#define PixMask_32_32_PASS_STACK

#define PixMask_32_32_DECLARE_TEMPORARIES uint64_t tmp

#define PixMask_32_32_PASS_TEMPORARIES , [tmp]"=&r"(tmp)

#define PixMask_32_32_INIT

#define PixMask_32_32_FINAL

#define PixMask_32_32_32                                             \
                "ldr     %w[tmp], [%[src]], #4                 \n\t" \
                "cbz     %[tmp], 2f                            \n\t" \
                "str     wzr, [%[dest]]                        \n\t" \
                "2:                                            \n\t" \
                "add     %[dest], %[dest], #4                  \n\t" \

#define PixMask_32_32_256                                            \
                "cmeq    v16.2s, v0.2s, #0                     \n\t" \
                "cmeq    v17.2s, v1.2s, #0                     \n\t" \
                "cmeq    v18.2s, v2.2s, #0                     \n\t" \
                "cmeq    v19.2s, v3.2s, #0                     \n\t" \
                "movi    v0.8b, #0                             \n\t" \
                "movi    v1.8b, #0                             \n\t" \
                "movi    v2.8b, #0                             \n\t" \
                "movi    v3.8b, #0                             \n\t" \
                "bit     v0.8b, v4.8b, v16.8b                  \n\t" \
                "bit     v1.8b, v5.8b, v17.8b                  \n\t" \
                "bit     v2.8b, v6.8b, v18.8b                  \n\t" \
                "bit     v3.8b, v7.8b, v19.8b                  \n\t" \

#define PixMask_32_32_512                                            \
                "cmeq    v16.4s, v0.4s, #0                     \n\t" \
                "cmeq    v17.4s, v1.4s, #0                     \n\t" \
                "cmeq    v18.4s, v2.4s, #0                     \n\t" \
                "cmeq    v19.4s, v3.4s, #0                     \n\t" \
                "movi    v0.16b, #0                            \n\t" \
                "movi    v1.16b, #0                            \n\t" \
                "movi    v2.16b, #0                            \n\t" \
                "movi    v3.16b, #0                            \n\t" \
                "bit     v0.16b, v4.16b, v16.16b               \n\t" \
                "bit     v1.16b, v5.16b, v17.16b               \n\t" \
                "bit     v2.16b, v6.16b, v18.16b               \n\t" \
                "bit     v3.16b, v7.16b, v19.16b               \n\t" \

DEFINE_FAST_PATH(PixMask, 32_32, NO, YES)

/******************************************************************************/

#define RgbMax_32_32_DECLARE_STACK

#define RgbMax_32_32_PASS_STACK

#define RgbMax_32_32_DECLARE_TEMPORARIES

#define RgbMax_32_32_PASS_TEMPORARIES

#define RgbMax_32_32_INIT

#define RgbMax_32_32_FINAL

#define RgbMax_32_32_32                                              \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "umax    v0.8b, v0.8b, v4.8b                   \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define RgbMax_32_32_256                                             \
                "umax    v0.8b, v0.8b, v4.8b                   \n\t" \
                "umax    v1.8b, v1.8b, v5.8b                   \n\t" \
                "umax    v2.8b, v2.8b, v6.8b                   \n\t" \
                "umax    v3.8b, v3.8b, v7.8b                   \n\t" \

#define RgbMax_32_32_512                                             \
                "umax    v0.16b, v0.16b, v4.16b                \n\t" \
                "umax    v1.16b, v1.16b, v5.16b                \n\t" \
                "umax    v2.16b, v2.16b, v6.16b                \n\t" \
                "umax    v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(RgbMax, 32_32, NO, YES)

/******************************************************************************/

#define RgbMin_32_32_DECLARE_STACK

#define RgbMin_32_32_PASS_STACK

#define RgbMin_32_32_DECLARE_TEMPORARIES

#define RgbMin_32_32_PASS_TEMPORARIES

#define RgbMin_32_32_INIT

#define RgbMin_32_32_FINAL

#define RgbMin_32_32_32                                              \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "umin    v0.8b, v0.8b, v4.8b                   \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define RgbMin_32_32_256                                             \
                "umin    v0.8b, v0.8b, v4.8b                   \n\t" \
                "umin    v1.8b, v1.8b, v5.8b                   \n\t" \
                "umin    v2.8b, v2.8b, v6.8b                   \n\t" \
                "umin    v3.8b, v3.8b, v7.8b                   \n\t" \

#define RgbMin_32_32_512                                             \
                "umin    v0.16b, v0.16b, v4.16b                \n\t" \
                "umin    v1.16b, v1.16b, v5.16b                \n\t" \
                "umin    v2.16b, v2.16b, v6.16b                \n\t" \
                "umin    v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(RgbMin, 32_32, NO, YES)

/******************************************************************************/

#define RgbMinInvert_32_32_DECLARE_STACK

#define RgbMinInvert_32_32_PASS_STACK

#define RgbMinInvert_32_32_DECLARE_TEMPORARIES

#define RgbMinInvert_32_32_PASS_TEMPORARIES

#define RgbMinInvert_32_32_INIT

#define RgbMinInvert_32_32_FINAL

#define RgbMinInvert_32_32_32                                        \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "umin    v0.8b, v0.8b, v4.8b                   \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define RgbMinInvert_32_32_256                                       \
                "mvn     v0.8b, v0.8b                          \n\t" \
                "mvn     v1.8b, v1.8b                          \n\t" \
                "mvn     v2.8b, v2.8b                          \n\t" \
                "mvn     v3.8b, v3.8b                          \n\t" \
                "umin    v0.8b, v0.8b, v4.8b                   \n\t" \
                "umin    v1.8b, v1.8b, v5.8b                   \n\t" \
                "umin    v2.8b, v2.8b, v6.8b                   \n\t" \
                "umin    v3.8b, v3.8b, v7.8b                   \n\t" \

#define RgbMinInvert_32_32_512                                       \
                "mvn     v0.16b, v0.16b                        \n\t" \
                "mvn     v1.16b, v1.16b                        \n\t" \
                "mvn     v2.16b, v2.16b                        \n\t" \
                "mvn     v3.16b, v3.16b                        \n\t" \
                "umin    v0.16b, v0.16b, v4.16b                \n\t" \
                "umin    v1.16b, v1.16b, v5.16b                \n\t" \
                "umin    v2.16b, v2.16b, v6.16b                \n\t" \
                "umin    v3.16b, v3.16b, v7.16b                \n\t" \

DEFINE_FAST_PATH(RgbMinInvert, 32_32, NO, YES)

/******************************************************************************/

#define AlphaBlendConst_32_32_DECLARE_STACK

#define AlphaBlendConst_32_32_PASS_STACK

#define AlphaBlendConst_32_32_DECLARE_TEMPORARIES uint32_t alpha = o->opt.sourceAlpha, unAlpha = alpha ^ 0xFF

#define AlphaBlendConst_32_32_PASS_TEMPORARIES , [alpha]"+r"(alpha), [unAlpha]"+r"(unAlpha)

#define AlphaBlendConst_32_32_INIT                                   \
                "dup     v28.16b, %w[alpha]                    \n\t" \
                "dup     v29.16b, %w[unAlpha]                  \n\t" \
                "movi    v31.16b, #0xFF                        \n\t" \

#define AlphaBlendConst_32_32_FINAL

#define AlphaBlendConst_32_32_32                                     \
                "ldr     s0, [%[src]], #4                      \n\t" \
                "ldr     s4, [%[dest]]                         \n\t" \
                "umull   v16.8h, v0.8b, v28.8b                 \n\t" \
                "umlal   v16.8h, v4.8b, v29.8b                 \n\t" \
                "cmtst   v0.8h, v16.8h, v31.8h                 \n\t" \
                "usra    v16.8h, v16.8h, #8                    \n\t" \
                "sub     v0.16b, v16.16b, v0.16b               \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "str     s0, [%[dest]], #4                     \n\t" \

#define AlphaBlendConst_32_32_256                                    \
                "umull   v16.8h, v0.8b, v28.8b                 \n\t" \
                "umlal   v16.8h, v4.8b, v29.8b                 \n\t" \
                "umull   v17.8h, v1.8b, v28.8b                 \n\t" \
                "umlal   v17.8h, v5.8b, v29.8b                 \n\t" \
                "umull   v18.8h, v2.8b, v28.8b                 \n\t" \
                "umlal   v18.8h, v6.8b, v29.8b                 \n\t" \
                "umull   v19.8h, v3.8b, v28.8b                 \n\t" \
                "umlal   v19.8h, v7.8b, v29.8b                 \n\t" \
                "cmtst   v0.8h, v16.8h, v31.8h                 \n\t" \
                "cmtst   v1.8h, v17.8h, v31.8h                 \n\t" \
                "cmtst   v2.8h, v18.8h, v31.8h                 \n\t" \
                "cmtst   v3.8h, v19.8h, v31.8h                 \n\t" \
                "usra    v16.8h, v16.8h, #8                    \n\t" \
                "usra    v17.8h, v17.8h, #8                    \n\t" \
                "usra    v18.8h, v18.8h, #8                    \n\t" \
                "usra    v19.8h, v19.8h, #8                    \n\t" \
                "sub     v0.16b, v16.16b, v0.16b               \n\t" \
                "sub     v1.16b, v17.16b, v1.16b               \n\t" \
                "sub     v2.16b, v18.16b, v2.16b               \n\t" \
                "sub     v3.16b, v19.16b, v3.16b               \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "shrn    v1.8b, v1.8h, #8                      \n\t" \
                "shrn    v2.8b, v2.8h, #8                      \n\t" \
                "shrn    v3.8b, v3.8h, #8                      \n\t" \

#define AlphaBlendConst_32_32_512                                    \
                "umull   v16.8h, v0.8b,  v28.8b                \n\t" \
                "umlal   v16.8h, v4.8b,  v29.8b                \n\t" \
                "umull2  v17.8h, v0.16b, v28.16b               \n\t" \
                "umlal2  v17.8h, v4.16b, v29.16b               \n\t" \
                "umull   v18.8h, v1.8b,  v28.8b                \n\t" \
                "umlal   v18.8h, v5.8b,  v29.8b                \n\t" \
                "umull2  v19.8h, v1.16b, v28.16b               \n\t" \
                "umlal2  v19.8h, v5.16b, v29.16b               \n\t" \
                "umull   v20.8h, v2.8b,  v28.8b                \n\t" \
                "umlal   v20.8h, v6.8b,  v29.8b                \n\t" \
                "umull2  v21.8h, v2.16b, v28.16b               \n\t" \
                "umlal2  v21.8h, v6.16b, v29.16b               \n\t" \
                "umull   v22.8h, v3.8b,  v28.8b                \n\t" \
                "umlal   v22.8h, v7.8b,  v29.8b                \n\t" \
                "umull2  v23.8h, v3.16b, v28.16b               \n\t" \
                "umlal2  v23.8h, v7.16b, v29.16b               \n\t" \
                "cmtst   v0.8h, v16.8h, v31.8h                 \n\t" \
                "cmtst   v1.8h, v17.8h, v31.8h                 \n\t" \
                "cmtst   v2.8h, v18.8h, v31.8h                 \n\t" \
                "cmtst   v3.8h, v19.8h, v31.8h                 \n\t" \
                "cmtst   v4.8h, v20.8h, v31.8h                 \n\t" \
                "cmtst   v5.8h, v21.8h, v31.8h                 \n\t" \
                "cmtst   v6.8h, v22.8h, v31.8h                 \n\t" \
                "cmtst   v7.8h, v23.8h, v31.8h                 \n\t" \
                "usra    v16.8h, v16.8h, #8                    \n\t" \
                "usra    v17.8h, v17.8h, #8                    \n\t" \
                "usra    v18.8h, v18.8h, #8                    \n\t" \
                "usra    v19.8h, v19.8h, #8                    \n\t" \
                "usra    v20.8h, v20.8h, #8                    \n\t" \
                "usra    v21.8h, v21.8h, #8                    \n\t" \
                "usra    v22.8h, v22.8h, #8                    \n\t" \
                "usra    v23.8h, v23.8h, #8                    \n\t" \
                "sub     v0.16b, v16.16b, v0.16b               \n\t" \
                "sub     v1.16b, v17.16b, v1.16b               \n\t" \
                "sub     v2.16b, v18.16b, v2.16b               \n\t" \
                "sub     v3.16b, v19.16b, v3.16b               \n\t" \
                "sub     v4.16b, v20.16b, v4.16b               \n\t" \
                "sub     v5.16b, v21.16b, v5.16b               \n\t" \
                "sub     v6.16b, v22.16b, v6.16b               \n\t" \
                "sub     v7.16b, v23.16b, v7.16b               \n\t" \
                "shrn    v0.8b,  v0.8h, #8                     \n\t" \
                "shrn    v16.8b, v1.8h, #8                     \n\t" \
                "shrn    v1.8b,  v2.8h, #8                     \n\t" \
                "shrn    v17.8b, v3.8h, #8                     \n\t" \
                "shrn    v2.8b,  v4.8h, #8                     \n\t" \
                "shrn    v18.8b, v5.8h, #8                     \n\t" \
                "shrn    v3.8b,  v6.8h, #8                     \n\t" \
                "shrn    v19.8b, v7.8h, #8                     \n\t" \
                "mov     v0.d[1], v16.d[0]                     \n\t" \
                "mov     v1.d[1], v17.d[0]                     \n\t" \
                "mov     v2.d[1], v18.d[0]                     \n\t" \
                "mov     v3.d[1], v19.d[0]                     \n\t" \

DEFINE_FAST_PATH(AlphaBlendConst, 32_32, NO, YES)

/******************************************************************************/

static void fastPathSourceWord_1_32(operation_t *op, uint32_t flags)
{
    IGNORE(flags);
    COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
    const unsigned srcBPP = 1;
    const unsigned destBPP = 32;
    uint32_t *src = srcBits + srcPitch * srcY + srcX * srcBPP / 32;
    uint32_t *dest = destBits + destPitch * destY + destX;

    uint32_t *clut = *cmLookupTable;
    __asm__ volatile (
            "ldr     d6, =0x10000000001                        \n\t"
            "ld1r    {v16.4s}, [%[clut]], #4                   \n\t"
            "ld1r    {v17.4s}, [%[clut]]                       \n\t"
            "ldr     q18, =0x10000000200000004000000080000000  \n\t"
            "ldr     q19, =0x01000000020000000400000008000000  \n\t"
    : /* Outputs */
            [clut]"+r"(clut)
    );

    do {
        uint32_t *s = src;
        /* Aim to end the inner loop at a 64-bit boundary in destination image. */
        uint32_t trailing_dest_bits = ((uintptr_t) dest * 8 + width * destBPP) & 63;
        uint32_t remain = width - trailing_dest_bits / destBPP;
        /* The inner loop works in chunks of 256 bits at the destination image. */
        /* Find the number of pixels that precede the first iteration of the inner loop. */
        uint32_t leading_src_bits = (remain & (256/destBPP-1)) * srcBPP;
        /* We define skew as the number of bits into the first or only source image
         * word (counting from the MS bit) corresponding to the first pixel of an
         * iteration of the inner loop. Where the ratio between source and destination
         * depths is greater than 8, this number will change between iterations. */
        uint32_t skew = (srcX * srcBPP + leading_src_bits) & 31;
        uint32_t unskew = (-skew) & 31;

        /* Handle leading pixels, if any */
        uint32_t data, carry;
        if (leading_src_bits == 0) {
            if (skew == 0)
                carry = 0;
            else
                carry = *s++ << skew;
            __asm__ volatile (
                    "mov     v4.s[1], %w[carry]                \n\t"
            : /* Outputs */
            : /* Inputs */
                    [carry]"r"(carry)
            );
        } else {
            if (skew == 0) {
                data = *s++;
                carry = 0;
            }
            else if (leading_src_bits > skew) {
                data = *s++ << skew;
                carry = *s++;
                data |= carry >> unskew;
                carry <<= skew;
            } else {
                carry = *s++;
                data = carry >> unskew;
                carry <<= skew;
            }
            data <<= 32 - leading_src_bits;

            __asm__ volatile (
                    "mov     v4.s[0], %w[data]                 \n\t"
                    "mov     v4.s[1], %w[carry]                \n\t"

                    /* Process 1..7 pixels */
                    "dup     v3.4s, v4.s[0]                    \n\t"
                    "cmtst   v0.4s, v3.4s, v18.4s              \n\t"
                    "cmtst   v1.4s, v3.4s, v19.4s              \n\t"
                    "bsl     v0.16b, v17.16b, v16.16b          \n\t"
                    "bsl     v1.16b, v17.16b, v16.16b          \n\t"
                    "tst     %[bits], #4                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     q0, [%[dest]], #16                \n\t"
                    "mov     v0.16b, v1.16b                    \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #2                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     d0, [%[dest]], #8                 \n\t"
                    "mov     v0.d[0], v0.d[1]                  \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #1                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     s0, [%[dest]], #4                 \n\t"
                    "1:                                        \n\t"
            : /* Outputs */
                     [dest]"+r"(dest)
            : /* Inputs */
                     [data]"r"(data),
                    [carry]"r"(carry),
                     [bits]"r"(leading_src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );
        }

        uint32_t src_bits = srcBPP*256/destBPP;
        uint32_t unskew2 = -(unskew & (src_bits - 1));
        uint32_t skew2 = src_bits + unskew2;
        __asm__ volatile (
                "mov     v5.s[0], %w[unskew2]                  \n\t"
                "mov     v5.s[1], %w[skew2]                    \n\t"
        : /* Outputs */
        : /* Inputs */
                [unskew2]"r"(unskew2),
                  [skew2]"r"(skew2)
        );

        /* Inner loop */
        for (; remain >= 256/destBPP; remain -= 256/destBPP) {
            __asm__ volatile (
                    /* Load source word (if necessary) and shuffle */
                    "cmp     %[unskew], %[src_bits]            \n\t"
                    "b.hs    1f                                \n\t"
                    "ushr    d0, d4, #32                       \n\t"
                    "ld1r    {v4.2s}, [%[s]], #4               \n\t"
                    "ushl    v4.2s, v4.2s, v5.2s               \n\t"
                    "orr     v4.8b, v4.8b, v0.8b               \n\t"
                    "b       2f                                \n\t"
                    "1:                                        \n\t"
                    "mul     v4.2s, v6.2s, v4.s[1]             \n\t"
                    "2:                                        \n\t"

                    /* Process 8 pixels */
                    "dup     v3.4s, v4.s[0]                    \n\t"
                    "cmtst   v0.4s, v3.4s, v18.4s              \n\t"
                    "cmtst   v1.4s, v3.4s, v19.4s              \n\t"
                    "bsl     v0.16b, v17.16b, v16.16b          \n\t"
                    "bsl     v1.16b, v17.16b, v16.16b          \n\t"
                    "st1     {v0.16b-v1.16b}, [%[dest]], #32   \n\t"
            : /* Outputs */
                       [s]"+r"(s),
                    [dest]"+r"(dest)
            : /* Inputs */
                      [unskew]"r"(unskew),
                    [src_bits]"I"(src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );
            unskew = (unskew - src_bits) & 31;
        }

        /* Handle trailing pixel, if any */
        if (trailing_dest_bits) {
            if (unskew == 0)
                data = *s++;
            else
                __asm__ volatile (
                        "mov     %w[data], v4.s[1]             \n\t"
                : /* Outputs */
                        [data]"=r"(data)
                );
            *dest++ = (*cmLookupTable)[data >> 31];
        }

        src += srcPitch;
        dest += destPitch - width;
    } while (--height > 0);
}

/******************************************************************************/

static void fastPathSourceWord_2_32(operation_t *op, uint32_t flags)
{
    IGNORE(flags);
    COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
    const unsigned srcBPP = 2;
    const unsigned destBPP = 32;
    uint32_t *src = srcBits + srcPitch * srcY + srcX * srcBPP / 32;
    uint32_t *dest = destBits + destPitch * destY + destX;

    uint32_t *clut = *cmLookupTable;
    __asm__ volatile (
            "ldr     d6, =0x1000000000001                      \n\t"
            "ld4     {v16.b-v19.b}[0], [%[clut]], #4           \n\t"
            "ld4     {v16.b-v19.b}[1], [%[clut]], #4           \n\t"
            "ld4     {v16.b-v19.b}[2], [%[clut]], #4           \n\t"
            "ld4     {v16.b-v19.b}[3], [%[clut]]               \n\t"
            "ldr     d20, =0x00FEFCFA00FEFCFA                  \n\t"
            "ldr     d21, =0x0303030303030303                  \n\t"
    : /* Outputs */
            [clut]"+r"(clut)
    );

    do {
        uint32_t *s = src;
        /* Aim to end the inner loop at a 64-bit boundary in destination image. */
        uint32_t trailing_dest_bits = ((uintptr_t) dest * 8 + width * destBPP) & 63;
        uint32_t remain = width - trailing_dest_bits / destBPP;
        /* The inner loop works in chunks of 256 bits at the destination image. */
        /* Find the number of pixels that precede the first iteration of the inner loop. */
        uint32_t leading_src_bits = (remain & (256/destBPP-1)) * srcBPP;
        /* We define skew as the number of bits into the first or only source image
         * word (counting from the MS bit) corresponding to the first pixel of an
         * iteration of the inner loop. Where the ratio between source and destination
         * depths is greater than 8, this number will change between iterations. */
        uint32_t skew = (srcX * srcBPP + leading_src_bits) & 31;
        uint32_t unskew = (-skew) & 31;

        /* Handle leading pixels, if any */
        uint32_t data, carry;
        if (leading_src_bits == 0) {
            if (skew == 0)
                carry = 0;
            else
                carry = *s++ << skew;
            __asm__ volatile (
                    "mov     v4.s[1], %w[carry]                \n\t"
            : /* Outputs */
            : /* Inputs */
                    [carry]"r"(carry)
            );
        } else {
            if (skew == 0) {
                data = *s++;
                carry = 0;
            }
            else if (leading_src_bits > skew) {
                data = *s++ << skew;
                carry = *s++;
                data |= carry >> unskew;
                carry <<= skew;
            } else {
                carry = *s++;
                data = carry >> unskew;
                carry <<= skew;
            }
            data <<= 32 - leading_src_bits;

            __asm__ volatile (
                    "mov     v4.s[0], %w[data]                 \n\t"
                    "mov     v4.s[1], %w[carry]                \n\t"

                    /* Process 1..7 pixels */
                    "dup     v2.8b, v4.b[3]                    \n\t"
                    "dup     v3.8b, v4.b[2]                    \n\t"
                    "ext     v3.8b, v2.8b, v3.8b, #4           \n\t"
                    "ushl    v3.8b, v3.8b, v20.8b              \n\t"
                    "and     v3.8b, v3.8b, v21.8b              \n\t"
                    "tbl     v0.8b, {v16.16b}, v3.8b           \n\t"
                    "tbl     v1.8b, {v17.16b}, v3.8b           \n\t"
                    "tbl     v2.8b, {v18.16b}, v3.8b           \n\t"
                    "tbl     v3.8b, {v19.16b}, v3.8b           \n\t"
                    "zip1    v24.8b, v0.8b, v2.8b              \n\t"
                    "zip2    v26.8b, v0.8b, v2.8b              \n\t"
                    "zip1    v25.8b, v1.8b, v3.8b              \n\t"
                    "zip2    v27.8b, v1.8b, v3.8b              \n\t"
                    "zip1    v0.8b, v24.8b, v25.8b             \n\t"
                    "zip2    v1.8b, v24.8b, v25.8b             \n\t"
                    "zip1    v2.8b, v26.8b, v27.8b             \n\t"
                    "zip2    v3.8b, v26.8b, v27.8b             \n\t"
                    "tst     %[bits], #8                       \n\t"
                    "b.eq    1f                                \n\t"
                    "st1     {v0.8b-v1.8b}, [%[dest]], #16     \n\t"
                    "mov     v0.8b, v2.8b                      \n\t"
                    "mov     v1.8b, v3.8b                      \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #4                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     d0, [%[dest]], #8                 \n\t"
                    "mov     v0.8b, v1.8b                      \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #2                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     s0, [%[dest]], #4                 \n\t"
                    "1:                                        \n\t"
            : /* Outputs */
                     [dest]"+r"(dest)
            : /* Inputs */
                     [data]"r"(data),
                    [carry]"r"(carry),
                     [bits]"r"(leading_src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );
        }

        uint32_t src_bits = srcBPP*256/destBPP;
        uint32_t unskew2 = -(unskew & (src_bits - 1));
        uint32_t skew2 = src_bits + unskew2;
        __asm__ volatile (
                "mov     v5.s[0], %w[unskew2]                  \n\t"
                "mov     v5.s[1], %w[skew2]                    \n\t"
        : /* Outputs */
        : /* Inputs */
                [unskew2]"r"(unskew2),
                  [skew2]"r"(skew2)
        );

        /* Inner loop */
        for (; remain >= 256/destBPP; remain -= 256/destBPP) {
            __asm__ volatile (
                    /* Load source word (if necessary) and shuffle */
                    "cmp     %[unskew], %[src_bits]            \n\t"
                    "b.hs    1f                                \n\t"
                    "ushr    d0, d4, #32                       \n\t"
                    "ld1r    {v4.2s}, [%[s]], #4               \n\t"
                    "ushl    v4.2s, v4.2s, v5.2s               \n\t"
                    "orr     v4.8b, v4.8b, v0.8b               \n\t"
                    "b       2f                                \n\t"
                    "1:                                        \n\t"
                    "mul     v4.2s, v6.2s, v4.s[1]             \n\t"
                    "2:                                        \n\t"

                    /* Process 8 pixels */
                    "dup     v2.8b, v4.b[3]                    \n\t"
                    "dup     v3.8b, v4.b[2]                    \n\t"
                    "ext     v3.8b, v2.8b, v3.8b, #4           \n\t"
                    "ushl    v3.8b, v3.8b, v20.8b              \n\t"
                    "and     v3.8b, v3.8b, v21.8b              \n\t"
                    "tbl     v0.8b, {v16.16b}, v3.8b           \n\t"
                    "tbl     v1.8b, {v17.16b}, v3.8b           \n\t"
                    "tbl     v2.8b, {v18.16b}, v3.8b           \n\t"
                    "tbl     v3.8b, {v19.16b}, v3.8b           \n\t"
                    "st4     {v0.8b-v3.8b}, [%[dest]], #32     \n\t"
            : /* Outputs */
                       [s]"+r"(s),
                    [dest]"+r"(dest)
            : /* Inputs */
                      [unskew]"r"(unskew),
                    [src_bits]"I"(src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );
            unskew = (unskew - src_bits) & 31;
        }

        /* Handle trailing pixel, if any */
        if (trailing_dest_bits) {
            if (unskew == 0)
                data = *s++;
            else
                __asm__ volatile (
                        "mov     %w[data], v4.s[1]             \n\t"
                : /* Outputs */
                        [data]"=r"(data)
                );
            *dest++ = (*cmLookupTable)[data >> 30];
        }

        src += srcPitch;
        dest += destPitch - width;
    } while (--height > 0);
}

/******************************************************************************/

static void fastPathSourceWord_4_32(operation_t *op, uint32_t flags)
{
    IGNORE(flags);
    COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
    const unsigned srcBPP = 4;
    const unsigned destBPP = 32;
    uint32_t *src = srcBits + srcPitch * srcY + srcX * srcBPP / 32;
    uint32_t *dest = destBits + destPitch * destY + destX;

    uint32_t *clut = *cmLookupTable;
    __asm__ volatile (
            "ld4     {v16.16b-v19.16b}, [%[clut]]              \n\t"
            "ldr     s20, =0x10101010                          \n\t"
            "ldr     d21, =0x00FC00FC00FC00FC                  \n\t"
    : /* Outputs */
            [clut]"+r"(clut)
    );

    do {
        uint32_t *s = src;
        /* Aim to end the inner loop at a 64-bit boundary in destination image. */
        uint32_t trailing_dest_bits = ((uintptr_t) dest * 8 + width * destBPP) & 63;
        uint32_t remain = width - trailing_dest_bits / destBPP;
        /* The inner loop works in chunks of 256 bits at the destination image. */
        /* Find the number of pixels that precede the first iteration of the inner loop. */
        uint32_t leading_src_bits = (remain & (256/destBPP-1)) * srcBPP;
        /* We define skew as the number of bits into the first or only source image
         * word (counting from the MS bit) corresponding to the first pixel of an
         * iteration of the inner loop. Where the ratio between source and destination
         * depths is greater than 8, this number will change between iterations. */
        uint32_t skew = (srcX * srcBPP + leading_src_bits) & 31;
        uint32_t unskew = (-skew) & 31;

        /* Handle leading pixels, if any */
        uint32_t data, carry;
        if (leading_src_bits == 0) {
            if (skew == 0)
                carry = 0;
            else
                carry = *s++ << skew;
            __asm__ volatile (
                    "mov     v4.s[1], %w[carry]                \n\t"
            : /* Outputs */
            : /* Inputs */
                    [carry]"r"(carry)
            );
        } else {
            if (skew == 0) {
                data = *s++;
                carry = 0;
            }
            else if (leading_src_bits > skew) {
                data = *s++ << skew;
                carry = *s++;
                data |= carry >> unskew;
                carry <<= skew;
            } else {
                carry = *s++;
                data = carry >> unskew;
                carry <<= skew;
            }
            data <<= 32 - leading_src_bits;

            __asm__ volatile (
                    "mov     v4.s[0], %w[data]                 \n\t"
                    "mov     v4.s[1], %w[carry]                \n\t"

                    /* Process 1..7 pixels */
                    "umull   v3.8h, v4.8b, v20.8b              \n\t"
                    "ushl    v3.8b, v3.8b, v21.8b              \n\t"
                    "rev64   v3.8b, v3.8b                      \n\t"
                    "tbl     v0.8b, {v16.16b}, v3.8b           \n\t"
                    "tbl     v1.8b, {v17.16b}, v3.8b           \n\t"
                    "tbl     v2.8b, {v18.16b}, v3.8b           \n\t"
                    "tbl     v3.8b, {v19.16b}, v3.8b           \n\t"
                    "zip1    v24.8b, v0.8b, v2.8b              \n\t"
                    "zip2    v26.8b, v0.8b, v2.8b              \n\t"
                    "zip1    v25.8b, v1.8b, v3.8b              \n\t"
                    "zip2    v27.8b, v1.8b, v3.8b              \n\t"
                    "zip1    v0.8b, v24.8b, v25.8b             \n\t"
                    "zip2    v1.8b, v24.8b, v25.8b             \n\t"
                    "zip1    v2.8b, v26.8b, v27.8b             \n\t"
                    "zip2    v3.8b, v26.8b, v27.8b             \n\t"
                    "tst     %[bits], #16                      \n\t"
                    "b.eq    1f                                \n\t"
                    "st1     {v0.8b-v1.8b}, [%[dest]], #16     \n\t"
                    "mov     v0.8b, v2.8b                      \n\t"
                    "mov     v1.8b, v3.8b                      \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #8                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     d0, [%[dest]], #8                 \n\t"
                    "mov     v0.8b, v1.8b                      \n\t"
                    "1:                                        \n\t"
                    "tst     %[bits], #4                       \n\t"
                    "b.eq    1f                                \n\t"
                    "str     s0, [%[dest]], #4                 \n\t"
                    "1:                                        \n\t"
            : /* Outputs */
                     [dest]"+r"(dest)
            : /* Inputs */
                     [data]"r"(data),
                    [carry]"r"(carry),
                     [bits]"r"(leading_src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );
        }

        uint32_t src_bits = srcBPP*256/destBPP;
        uint32_t unskew2 = -(unskew & (src_bits - 1));
        uint32_t skew2 = src_bits + unskew2;
        __asm__ volatile (
                "mov     v5.s[0], %w[unskew2]                  \n\t"
                "mov     v5.s[1], %w[skew2]                    \n\t"
        : /* Outputs */
        : /* Inputs */
                [unskew2]"r"(unskew2),
                  [skew2]"r"(skew2)
        );

        /* Inner loop */
        for (; remain >= 256/destBPP; remain -= 256/destBPP) {
            __asm__ volatile (
                    /* Load source word and shuffle */
                    "ushr    d0, d4, #32                       \n\t"
                    "ld1r    {v4.2s}, [%[s]], #4               \n\t"
                    "ushl    v4.2s, v4.2s, v5.2s               \n\t"
                    "orr     v4.8b, v4.8b, v0.8b               \n\t"

                    /* Process 8 pixels */
                    "umull   v3.8h, v4.8b, v20.8b              \n\t"
                    "ushl    v3.8b, v3.8b, v21.8b              \n\t"
                    "rev64   v3.8b, v3.8b                      \n\t"
                    "tbl     v0.8b, {v16.16b}, v3.8b           \n\t"
                    "tbl     v1.8b, {v17.16b}, v3.8b           \n\t"
                    "tbl     v2.8b, {v18.16b}, v3.8b           \n\t"
                    "tbl     v3.8b, {v19.16b}, v3.8b           \n\t"
                    "st4     {v0.8b-v3.8b}, [%[dest]], #32     \n\t"
            : /* Outputs */
                       [s]"+r"(s),
                    [dest]"+r"(dest)
            : /* Inputs */
                      [unskew]"r"(unskew)
            : /* Clobbers */
                    "memory", "cc"
            );
        }

        /* Handle trailing pixel, if any */
        if (trailing_dest_bits) {
            if (unskew == 0)
                data = *s++;
            else
                __asm__ volatile (
                        "mov     %w[data], v4.s[1]             \n\t"
                : /* Outputs */
                        [data]"=r"(data)
                );
            *dest++ = (*cmLookupTable)[data >> 28];
        }

        src += srcPitch;
        dest += destPitch - width;
    } while (--height > 0);
}

/******************************************************************************/

static void fastPathSourceWord_16_32(operation_t *op, uint32_t flags)
{
    IGNORE(flags);
    COPY_OP_TO_LOCALS(op, uint32_t, uint32_t);
    const unsigned srcBPP = 16;
    const unsigned destBPP = 32;
    uint32_t *src = srcBits + srcPitch * srcY + srcX * srcBPP / 32;
    uint32_t *dest = destBits + destPitch * destY + destX;

    __asm__ volatile (
            "ldr     q16, =0x00F800F800F800F800F800F800F800F8  \n\t"
            "ldr     q17, =0xF800F800F800F800F800F800F800F800  \n\t"
            "ldr     q18, =0x80008000800080008000800080008000  \n\t"
            "ldr     q19, =0x00010001000100010001000100010001  \n\t"
    );

    do {
        uint32_t *s = src;
        /* Aim to end the inner loop at a 64-bit boundary in destination image. */
        uint32_t trailing_dest_bits = ((uintptr_t) dest * 8 + width * destBPP) & 63;
        uint32_t remain = width - trailing_dest_bits / destBPP;
        /* The inner loop works in chunks of 256 bits at the destination image. */
        /* Find the number of pixels that precede the first iteration of the inner loop. */
        uint32_t leading_src_bits = (remain & (256/destBPP-1)) * srcBPP;
        /* We define skew as the number of bits into the first or only source image
         * word (counting from the MS bit) corresponding to the first pixel of an
         * iteration of the inner loop. Where the ratio between source and destination
         * depths is greater than 8, this number will change between iterations. */
        uint32_t skew = (srcX * srcBPP + leading_src_bits) & 31;

        if (skew == 0) {
            __asm__ volatile (
                    /* Load leading pixels */
                    "cbz     %w[bits], 10f                     \n\t"
                    "tbz     %w[bits], #4, 1f                  \n\t"
                    "ld1     {v4.s}[0], [%[s]], #4             \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #5, 1f                  \n\t"
                    "ld1     {v4.s}[1], [%[s]], #4             \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #6, 1f                  \n\t"
                    "ld1     {v4.d}[1], [%[s]], #8             \n\t"
                    "1:                                        \n\t"
                    "rev32   v4.8h, v4.8h                      \n\t"

                    /* Process 1..7 pixels */
                    "shl     v0.8h, v4.8h, #3                  \n\t"
                    "shl     v1.8h, v4.8h, #6                  \n\t"
                    "ushr    v2.8h, v4.8h, #7                  \n\t"
                    "cmeq    v3.8h, v4.8h, v18.8h              \n\t"
                    "and     v0.16b, v0.16b, v16.16b           \n\t"
                    "and     v1.16b, v1.16b, v17.16b           \n\t"
                    "bit     v0.16b, v19.16b, v3.16b           \n\t"
                    "and     v2.16b, v2.16b, v16.16b           \n\t"
                    "orr     v3.16b, v0.16b, v1.16b            \n\t"
                    "zip1    v0.8h, v3.8h, v2.8h               \n\t"
                    "zip2    v1.8h, v3.8h, v2.8h               \n\t"

                    /* Store leading pixels */
                    "tbz     %w[bits], #4, 1f                  \n\t"
                    "st1     {v0.s}[1], [%[dest]], #4          \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #5, 1f                  \n\t"
                    "st1     {v0.d}[1], [%[dest]], #8          \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #6, 10f                 \n\t"
                    "st1     {v1.16b}, [%[dest]], #16          \n\t"
                    "10:                                       \n\t"
            : /* Outputs */
                       [s]"+r"(s),
                    [dest]"+r"(dest)
            : /* Inputs */
                    [bits]"r"(leading_src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );

            /* Inner loop */
            for (; remain >= 256/destBPP; remain -= 256/destBPP) {
                __asm__ volatile (
                        /* Load pixels */
                        "ld1     {v4.16b}, [%[s]], #16         \n\t"
                        "rev32   v4.8h, v4.8h                  \n\t"

                        /* Process 8 pixels */
                        "shl     v0.8h, v4.8h, #3              \n\t"
                        "shl     v1.8h, v4.8h, #6              \n\t"
                        "ushr    v2.8h, v4.8h, #7              \n\t"
                        "cmeq    v3.8h, v4.8h, v18.8h          \n\t"
                        "and     v0.16b, v0.16b, v16.16b       \n\t"
                        "and     v1.16b, v1.16b, v17.16b       \n\t"
                        "bit     v0.16b, v19.16b, v3.16b       \n\t"
                        "and     v2.16b, v2.16b, v16.16b       \n\t"
                        "orr     v3.16b, v0.16b, v1.16b        \n\t"
                        "zip1    v0.8h, v3.8h, v2.8h           \n\t"
                        "zip2    v1.8h, v3.8h, v2.8h           \n\t"

                        /* Store pixels */
                        "st1     {v0.16b-v1.16b}, [%[dest]], #32 \n\t"
                : /* Outputs */
                           [s]"+r"(s),
                        [dest]"+r"(dest)
                : /* Inputs */
                : /* Clobbers */
                        "memory", "cc"
                );
            }

            /* Handle trailing pixel, if any */
            if (trailing_dest_bits) {
                uint32_t in = *s;
                uint32_t r = (in >> 7)  & 0xF80000;
                uint32_t g = (in >> 10) & 0xF800;
                uint32_t b = (in >> 13) & 0xF8;
                *dest++ = r | g | b | ((in >> 16) == 0x8000);
            }

        } else {
            __asm__ volatile (
                    /* Load leading pixels */
                    "ld1r    {v4.4s}, [%[s]], #4               \n\t"
                    "tbz     %w[bits], #5, 1f                  \n\t"
                    "ld1r    {v5.4s}, [%[s]], #4               \n\t"
                    "ext     v4.16b, v4.16b, v5.16b, #12       \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #6, 1f                  \n\t"
                    "ld1     {v4.d}[1], [%[s]], #8             \n\t"
                    "1:                                        \n\t"
                    "rev32   v5.8h, v4.8h                      \n\t"
                    "ext     v4.16b, v5.16b, v5.16b, #14       \n\t"
                    "cbz      %w[bits], 10f                    \n\t"

                    /* Process 1..7 pixels */
                    "shl     v0.8h, v4.8h, #3                  \n\t"
                    "shl     v1.8h, v4.8h, #6                  \n\t"
                    "ushr    v2.8h, v4.8h, #7                  \n\t"
                    "cmeq    v3.8h, v4.8h, v18.8h              \n\t"
                    "and     v0.16b, v0.16b, v16.16b           \n\t"
                    "and     v1.16b, v1.16b, v17.16b           \n\t"
                    "bit     v0.16b, v19.16b, v3.16b           \n\t"
                    "and     v2.16b, v2.16b, v16.16b           \n\t"
                    "orr     v3.16b, v0.16b, v1.16b            \n\t"
                    "zip1    v0.8h, v3.8h, v2.8h               \n\t"
                    "zip2    v1.8h, v3.8h, v2.8h               \n\t"

                    /* Store leading pixels */
                    "tbz     %w[bits], #4, 1f                  \n\t"
                    "st1     {v0.s}[1], [%[dest]], #4          \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #5, 1f                  \n\t"
                    "st1     {v0.d}[1], [%[dest]], #8          \n\t"
                    "1:                                        \n\t"
                    "tbz     %w[bits], #6, 10f                 \n\t"
                    "st1     {v1.16b}, [%[dest]], #16          \n\t"
                    "10:                                       \n\t"
            : /* Outputs */
                       [s]"+r"(s),
                    [dest]"+r"(dest)
            : /* Inputs */
                    [skew]"r"(skew),
                    [bits]"r"(leading_src_bits)
            : /* Clobbers */
                    "memory", "cc"
            );

            /* Inner loop */
            for (; remain >= 256/destBPP; remain -= 256/destBPP) {
                __asm__ volatile (
                        /* Load pixels */
                        "mov     v4.16b, v5.16b                \n\t"
                        "ld1     {v5.16b}, [%[s]], #16         \n\t"
                        "rev32   v5.8h, v5.8h                  \n\t"
                        "ext     v4.16b, v4.16b, v5.16b, #14   \n\t"

                        /* Process 8 pixels */
                        "shl     v0.8h, v4.8h, #3              \n\t"
                        "shl     v1.8h, v4.8h, #6              \n\t"
                        "ushr    v2.8h, v4.8h, #7              \n\t"
                        "cmeq    v3.8h, v4.8h, v18.8h          \n\t"
                        "and     v0.16b, v0.16b, v16.16b       \n\t"
                        "and     v1.16b, v1.16b, v17.16b       \n\t"
                        "bit     v0.16b, v19.16b, v3.16b       \n\t"
                        "and     v2.16b, v2.16b, v16.16b       \n\t"
                        "orr     v3.16b, v0.16b, v1.16b        \n\t"
                        "zip1    v0.8h, v3.8h, v2.8h           \n\t"
                        "zip2    v1.8h, v3.8h, v2.8h           \n\t"

                        /* Store pixels */
                        "st1     {v0.16b-v1.16b}, [%[dest]], #32 \n\t"
                : /* Outputs */
                           [s]"+r"(s),
                        [dest]"+r"(dest)
                : /* Inputs */
                : /* Clobbers */
                        "memory", "cc"
                );
            }

            /* Handle trailing pixel, if any */
            if (trailing_dest_bits) {
                uint32_t in;
                __asm__ volatile (
                        "mov     %w[in], v5.s[3]               \n\t"
                : /* Outputs */
                        [in]"=r"(in)
                );
                uint32_t r = (in >> 7)  & 0xF80000;
                uint32_t g = (in >> 10) & 0xF800;
                uint32_t b = (in >> 13) & 0xF8;
                *dest++ = r | g | b | ((in >> 16) == 0x8000);
            }

        }

        src += srcPitch;
        dest += destPitch - width;
    } while (--height > 0);
}

/******************************************************************************/

#define AlphaBlend_scalar_0_32_DECLARE_TEMPORARIES

#define AlphaBlend_scalar_0_32_PASS_TEMPORARIES

#define AlphaBlend_scalar_0_32_INIT                                  \
                "ld4r    {v20.16b-v23.16b}, [%[halftone]]      \n\t" \
                "movi    v18.16b, #0xFF                        \n\t" \
                "mvn     v19.16b, v23.16b                      \n\t" \
                "umull   v20.8h, v20.8b, v23.8b                \n\t" \
                "umull   v21.8h, v21.8b, v23.8b                \n\t" \
                "umull   v22.8h, v22.8b, v23.8b                \n\t" \
                "umull   v23.8h, v18.8b, v23.8b                \n\t" \

#define AlphaBlend_scalar_0_32_32                                    \
                "ld4     {v4.b-v7.b}[0], [%[dest]]             \n\t" \
                AlphaBlend_scalar_0_32_256                           \
                "st4     {v0.b-v3.b}[0], [%[dest]], #4         \n\t" \

#define AlphaBlend_scalar_0_32_256                                   \
                "umull   v24.8h, v4.8b,  v19.8b                \n\t" \
                "umull   v25.8h, v5.8b,  v19.8b                \n\t" \
                "umull   v26.8h, v6.8b,  v19.8b                \n\t" \
                "umull   v27.8h, v7.8b,  v19.8b                \n\t" \
                "add     v24.8h, v24.8h, v20.8h                \n\t" \
                "add     v25.8h, v25.8h, v21.8h                \n\t" \
                "add     v26.8h, v26.8h, v22.8h                \n\t" \
                "add     v27.8h, v27.8h, v23.8h                \n\t" \
                "cmtst   v0.8h, v24.8h, v18.8h                 \n\t" \
                "cmtst   v1.8h, v25.8h, v18.8h                 \n\t" \
                "cmtst   v2.8h, v26.8h, v18.8h                 \n\t" \
                "cmtst   v3.8h, v27.8h, v18.8h                 \n\t" \
                "usra    v24.8h, v24.8h, #8                    \n\t" \
                "usra    v25.8h, v25.8h, #8                    \n\t" \
                "usra    v26.8h, v26.8h, #8                    \n\t" \
                "usra    v27.8h, v27.8h, #8                    \n\t" \
                "sub     v0.16b, v24.16b, v0.16b               \n\t" \
                "sub     v1.16b, v25.16b, v1.16b               \n\t" \
                "sub     v2.16b, v26.16b, v2.16b               \n\t" \
                "sub     v3.16b, v27.16b, v3.16b               \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "shrn    v1.8b, v1.8h, #8                      \n\t" \
                "shrn    v2.8b, v2.8h, #8                      \n\t" \
                "shrn    v3.8b, v3.8h, #8                      \n\t" \

#define AlphaBlend_scalar_0_32_512                                   \
                "umull   v24.8h, v4.8b,  v19.8b                \n\t" \
                "umull2  v25.8h, v4.16b, v19.16b               \n\t" \
                "umull   v26.8h, v5.8b,  v19.8b                \n\t" \
                "umull2  v27.8h, v5.16b, v19.16b               \n\t" \
                "umull   v28.8h, v6.8b,  v19.8b                \n\t" \
                "umull2  v29.8h, v6.16b, v19.16b               \n\t" \
                "umull   v30.8h, v7.8b,  v19.8b                \n\t" \
                "umull2  v31.8h, v7.16b, v19.16b               \n\t" \
                "add     v24.8h, v24.8h, v20.8h                \n\t" \
                "add     v25.8h, v25.8h, v20.8h                \n\t" \
                "add     v26.8h, v26.8h, v21.8h                \n\t" \
                "add     v27.8h, v27.8h, v21.8h                \n\t" \
                "add     v28.8h, v28.8h, v22.8h                \n\t" \
                "add     v29.8h, v29.8h, v22.8h                \n\t" \
                "add     v30.8h, v30.8h, v23.8h                \n\t" \
                "add     v31.8h, v31.8h, v23.8h                \n\t" \
                "cmtst   v0.8h, v24.8h, v18.8h                 \n\t" \
                "cmtst   v1.8h, v25.8h, v18.8h                 \n\t" \
                "cmtst   v2.8h, v26.8h, v18.8h                 \n\t" \
                "cmtst   v3.8h, v27.8h, v18.8h                 \n\t" \
                "cmtst   v4.8h, v28.8h, v18.8h                 \n\t" \
                "cmtst   v5.8h, v29.8h, v18.8h                 \n\t" \
                "cmtst   v6.8h, v30.8h, v18.8h                 \n\t" \
                "cmtst   v7.8h, v31.8h, v18.8h                 \n\t" \
                "usra    v24.8h, v24.8h, #8                    \n\t" \
                "usra    v25.8h, v25.8h, #8                    \n\t" \
                "usra    v26.8h, v26.8h, #8                    \n\t" \
                "usra    v27.8h, v27.8h, #8                    \n\t" \
                "usra    v28.8h, v28.8h, #8                    \n\t" \
                "usra    v29.8h, v29.8h, #8                    \n\t" \
                "usra    v30.8h, v30.8h, #8                    \n\t" \
                "usra    v31.8h, v31.8h, #8                    \n\t" \
                "sub     v0.16b, v24.16b, v0.16b               \n\t" \
                "sub     v1.16b, v25.16b, v1.16b               \n\t" \
                "sub     v2.16b, v26.16b, v2.16b               \n\t" \
                "sub     v3.16b, v27.16b, v3.16b               \n\t" \
                "sub     v4.16b, v28.16b, v4.16b               \n\t" \
                "sub     v5.16b, v29.16b, v5.16b               \n\t" \
                "sub     v6.16b, v30.16b, v6.16b               \n\t" \
                "sub     v7.16b, v31.16b, v7.16b               \n\t" \
                "shrn    v0.8b,  v0.8h, #8                     \n\t" \
                "shrn    v24.8b, v1.8h, #8                     \n\t" \
                "shrn    v1.8b,  v2.8h, #8                     \n\t" \
                "shrn    v25.8b, v3.8h, #8                     \n\t" \
                "shrn    v2.8b,  v4.8h, #8                     \n\t" \
                "shrn    v26.8b, v5.8h, #8                     \n\t" \
                "shrn    v3.8b,  v6.8h, #8                     \n\t" \
                "shrn    v27.8b, v7.8h, #8                     \n\t" \
                "mov     v0.d[1], v24.d[0]                     \n\t" \
                "mov     v1.d[1], v25.d[0]                     \n\t" \
                "mov     v2.d[1], v26.d[0]                     \n\t" \
                "mov     v3.d[1], v27.d[0]                     \n\t" \

DEFINE_FAST_PATH(AlphaBlend_scalar, 0_32, YES, YES)

/******************************************************************************/

#define AlphaBlend_map1_scalar_32_32_DECLARE_STACK uint64_t save[3]

#define AlphaBlend_map1_scalar_32_32_PASS_STACK , [save]"r"(save)

#define AlphaBlend_map1_scalar_32_32_DECLARE_TEMPORARIES

#define AlphaBlend_map1_scalar_32_32_PASS_TEMPORARIES

#define AlphaBlend_map1_scalar_32_32_INIT                            \
                "str     d13, [%[save], #0]                    \n\t" \
                "stp     d14, d15, [%[save], #8]               \n\t" \
                "ld4r    {v24.16b-v27.16b}, [%[clut]], #4      \n\t" \
                "ld4r    {v28.16b-v31.16b}, [%[clut]]          \n\t" \
                "ld4r    {v16.16b-v19.16b}, [%[halftone]]      \n\t" \
                "movi    v13.16b, #0xFF                        \n\t" \
                "and     v24.8b,  v24.8b,  v16.8b              \n\t" \
                "and     v25.8b,  v25.8b,  v17.8b              \n\t" \
                "and     v26.8b,  v26.8b,  v18.8b              \n\t" \
                "and     v27.16b, v27.16b, v19.16b             \n\t" \
                "and     v28.8b,  v28.8b,  v16.8b              \n\t" \
                "and     v29.8b,  v29.8b,  v17.8b              \n\t" \
                "and     v30.8b,  v30.8b,  v18.8b              \n\t" \
                "and     v31.16b, v31.16b, v19.16b             \n\t" \
                "mvn     v14.16b, v27.16b                      \n\t" \
                "mvn     v15.16b, v31.16b                      \n\t" \
                "umull   v24.8h, v24.8b, v27.8b                \n\t" \
                "umull   v25.8h, v25.8b, v27.8b                \n\t" \
                "umull   v26.8h, v26.8b, v27.8b                \n\t" \
                "umull   v27.8h, v13.8b, v27.8b                \n\t" \
                "umull   v28.8h, v28.8b, v31.8b                \n\t" \
                "umull   v29.8h, v29.8b, v31.8b                \n\t" \
                "umull   v30.8h, v30.8b, v31.8b                \n\t" \
                "umull   v31.8h, v13.8b, v31.8b                \n\t" \

#define AlphaBlend_map1_scalar_32_32_FINAL                           \
                "ldr     d13, [%[save], #0]                    \n\t" \
                "ldp     d14, d15, [%[save], #8]               \n\t" \

#define AlphaBlend_map1_scalar_32_32_32                              \
                "ldr     s1, [%[src]], #4                      \n\t" \
                "ld4     {v4.b-v7.b}[0], [%[dest]]             \n\t" \
                "cmtst   v0.2s,  v1.2s, v13.2s                 \n\t" \
                "cmtst   v16.2s, v1.2s, v13.2s                 \n\t" \
                "cmtst   v17.2s, v1.2s, v13.2s                 \n\t" \
                "cmtst   v18.2s, v1.2s, v13.2s                 \n\t" \
                "cmtst   v19.2s, v1.2s, v13.2s                 \n\t" \
                "bsl     v0.8b, v15.8b, v14.8b                 \n\t" \
                "bsl     v16.8b, v28.8b, v24.8b                \n\t" \
                "bsl     v17.8b, v29.8b, v25.8b                \n\t" \
                "bsl     v18.8b, v30.8b, v26.8b                \n\t" \
                "bsl     v19.8b, v31.8b, v27.8b                \n\t" \
                "umlal   v16.8h, v4.8b,  v0.8b                 \n\t" \
                "umlal   v17.8h, v5.8b,  v0.8b                 \n\t" \
                "umlal   v18.8h, v6.8b,  v0.8b                 \n\t" \
                "umlal   v19.8h, v7.8b,  v0.8b                 \n\t" \
                "cmtst   v0.4h, v16.4h, v13.4h                 \n\t" \
                "cmtst   v1.4h, v17.4h, v13.4h                 \n\t" \
                "cmtst   v2.4h, v18.4h, v13.4h                 \n\t" \
                "cmtst   v3.4h, v19.4h, v13.4h                 \n\t" \
                "usra    v16.4h, v16.4h, #8                    \n\t" \
                "usra    v17.4h, v17.4h, #8                    \n\t" \
                "usra    v18.4h, v18.4h, #8                    \n\t" \
                "usra    v19.4h, v19.4h, #8                    \n\t" \
                "sub     v0.8b, v16.8b, v0.8b                  \n\t" \
                "sub     v1.8b, v17.8b, v1.8b                  \n\t" \
                "sub     v2.8b, v18.8b, v2.8b                  \n\t" \
                "sub     v3.8b, v19.8b, v3.8b                  \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "shrn    v1.8b, v1.8h, #8                      \n\t" \
                "shrn    v2.8b, v2.8h, #8                      \n\t" \
                "shrn    v3.8b, v3.8h, #8                      \n\t" \
                "st4     {v0.b-v3.b}[0], [%[dest]], #4         \n\t" \

#define AlphaBlend_map1_scalar_32_32_256                             \
                "orr     v0.8b, v0.8b, v1.8b                   \n\t" \
                "orr     v2.8b, v2.8b, v3.8b                   \n\t" \
                "orr     v0.8b, v0.8b, v2.8b                   \n\t" \
                "cmtst   v0.8b, v0.8b, v13.8b                  \n\t" \
                "sxtl    v16.8h, v0.8b                         \n\t" \
                "sxtl    v17.8h, v0.8b                         \n\t" \
                "sxtl    v18.8h, v0.8b                         \n\t" \
                "sxtl    v19.8h, v0.8b                         \n\t" \
                "bsl     v0.8b, v15.8b, v14.8b                 \n\t" \
                "bsl     v16.16b, v28.16b, v24.16b             \n\t" \
                "bsl     v17.16b, v29.16b, v25.16b             \n\t" \
                "bsl     v18.16b, v30.16b, v26.16b             \n\t" \
                "bsl     v19.16b, v31.16b, v27.16b             \n\t" \
                "umlal   v16.8h, v4.8b, v0.8b                  \n\t" \
                "umlal   v17.8h, v5.8b, v0.8b                  \n\t" \
                "umlal   v18.8h, v6.8b, v0.8b                  \n\t" \
                "umlal   v19.8h, v7.8b, v0.8b                  \n\t" \
                "cmtst   v0.8h, v16.8h, v13.8h                 \n\t" \
                "cmtst   v1.8h, v17.8h, v13.8h                 \n\t" \
                "cmtst   v2.8h, v18.8h, v13.8h                 \n\t" \
                "cmtst   v3.8h, v19.8h, v13.8h                 \n\t" \
                "usra    v16.8h, v16.8h, #8                    \n\t" \
                "usra    v17.8h, v17.8h, #8                    \n\t" \
                "usra    v18.8h, v18.8h, #8                    \n\t" \
                "usra    v19.8h, v19.8h, #8                    \n\t" \
                "sub     v0.16b, v16.16b, v0.16b               \n\t" \
                "sub     v1.16b, v17.16b, v1.16b               \n\t" \
                "sub     v2.16b, v18.16b, v2.16b               \n\t" \
                "sub     v3.16b, v19.16b, v3.16b               \n\t" \
                "shrn    v0.8b, v0.8h, #8                      \n\t" \
                "shrn    v1.8b, v1.8h, #8                      \n\t" \
                "shrn    v2.8b, v2.8h, #8                      \n\t" \
                "shrn    v3.8b, v3.8h, #8                      \n\t" \

#define AlphaBlend_map1_scalar_32_32_512                             \
                "orr     v0.16b, v0.16b, v1.16b                \n\t" \
                "orr     v2.16b, v2.16b, v3.16b                \n\t" \
                "orr     v0.16b, v0.16b, v2.16b                \n\t" \
                "cmtst   v0.16b, v0.16b, v13.16b               \n\t" \
                "sxtl    v16.8h, v0.8b                         \n\t" \
                "sxtl2   v17.8h, v0.16b                        \n\t" \
                "sxtl    v18.8h, v0.8b                         \n\t" \
                "sxtl2   v19.8h, v0.16b                        \n\t" \
                "sxtl    v20.8h, v0.8b                         \n\t" \
                "sxtl2   v21.8h, v0.16b                        \n\t" \
                "sxtl    v22.8h, v0.8b                         \n\t" \
                "sxtl2   v23.8h, v0.16b                        \n\t" \
                "bsl     v0.16b, v15.16b, v14.16b              \n\t" \
                "bsl     v16.16b, v28.16b, v24.16b             \n\t" \
                "bsl     v17.16b, v28.16b, v24.16b             \n\t" \
                "bsl     v18.16b, v29.16b, v25.16b             \n\t" \
                "bsl     v19.16b, v29.16b, v25.16b             \n\t" \
                "bsl     v20.16b, v30.16b, v26.16b             \n\t" \
                "bsl     v21.16b, v30.16b, v26.16b             \n\t" \
                "bsl     v22.16b, v31.16b, v27.16b             \n\t" \
                "bsl     v23.16b, v31.16b, v27.16b             \n\t" \
                "umlal   v16.8h, v4.8b,  v0.8b                 \n\t" \
                "umlal2  v17.8h, v4.16b, v0.16b                \n\t" \
                "umlal   v18.8h, v5.8b,  v0.8b                 \n\t" \
                "umlal2  v19.8h, v5.16b, v0.16b                \n\t" \
                "umlal   v20.8h, v6.8b,  v0.8b                 \n\t" \
                "umlal2  v21.8h, v6.16b, v0.16b                \n\t" \
                "umlal   v22.8h, v7.8b,  v0.8b                 \n\t" \
                "umlal2  v23.8h, v7.16b, v0.16b                \n\t" \
                "cmtst   v0.8h, v16.8h, v13.8h                 \n\t" \
                "cmtst   v1.8h, v17.8h, v13.8h                 \n\t" \
                "cmtst   v2.8h, v18.8h, v13.8h                 \n\t" \
                "cmtst   v3.8h, v19.8h, v13.8h                 \n\t" \
                "cmtst   v4.8h, v20.8h, v13.8h                 \n\t" \
                "cmtst   v5.8h, v21.8h, v13.8h                 \n\t" \
                "cmtst   v6.8h, v22.8h, v13.8h                 \n\t" \
                "cmtst   v7.8h, v23.8h, v13.8h                 \n\t" \
                "usra    v16.8h, v16.8h, #8                    \n\t" \
                "usra    v17.8h, v17.8h, #8                    \n\t" \
                "usra    v18.8h, v18.8h, #8                    \n\t" \
                "usra    v19.8h, v19.8h, #8                    \n\t" \
                "usra    v20.8h, v20.8h, #8                    \n\t" \
                "usra    v21.8h, v21.8h, #8                    \n\t" \
                "usra    v22.8h, v22.8h, #8                    \n\t" \
                "usra    v23.8h, v23.8h, #8                    \n\t" \
                "sub     v0.16b, v16.16b, v0.16b               \n\t" \
                "sub     v1.16b, v17.16b, v1.16b               \n\t" \
                "sub     v2.16b, v18.16b, v2.16b               \n\t" \
                "sub     v3.16b, v19.16b, v3.16b               \n\t" \
                "sub     v4.16b, v20.16b, v4.16b               \n\t" \
                "sub     v5.16b, v21.16b, v5.16b               \n\t" \
                "sub     v6.16b, v22.16b, v6.16b               \n\t" \
                "sub     v7.16b, v23.16b, v7.16b               \n\t" \
                "shrn    v0.8b,  v0.8h, #8                     \n\t" \
                "shrn    v16.8b, v1.8h, #8                     \n\t" \
                "shrn    v1.8b,  v2.8h, #8                     \n\t" \
                "shrn    v17.8b, v3.8h, #8                     \n\t" \
                "shrn    v2.8b,  v4.8h, #8                     \n\t" \
                "shrn    v18.8b, v5.8h, #8                     \n\t" \
                "shrn    v3.8b,  v6.8h, #8                     \n\t" \
                "shrn    v19.8b, v7.8h, #8                     \n\t" \
                "mov     v0.d[1], v16.d[0]                     \n\t" \
                "mov     v1.d[1], v17.d[0]                     \n\t" \
                "mov     v2.d[1], v18.d[0]                     \n\t" \
                "mov     v3.d[1], v19.d[0]                     \n\t" \

DEFINE_FAST_PATH(AlphaBlend_map1_scalar, 32_32, YES, YES)

/******************************************************************************/

static fast_path_t fastPaths[] = {
        { fastPathAlphaBlend_32_32,             CR_alphaBlend,           STD_FLAGS(32,32,NO,NO) },
        { fastPathPixPaint_32_32,               CR_pixPaint,             STD_FLAGS(32,32,NO,NO) },

        { fastPathSourceWord_1_32,              CR_sourceWord,           STD_FLAGS(1,32,DIRECT,NO) },
        { fastPathSourceWord_2_32,              CR_sourceWord,           STD_FLAGS(2,32,DIRECT,NO) },
        { fastPathSourceWord_4_32,              CR_sourceWord,           STD_FLAGS(4,32,DIRECT,NO) },
        { fastPathSourceWord_16_32,             CR_sourceWord,           STD_FLAGS(16,32,NO,NO) },

        { fastPathAlphaBlend_scalar_0_32,       CR_alphaBlend,           STD_FLAGS_NO_SOURCE(32,SCALAR) },
        { fastPathAlphaBlend_map1_scalar_32_32, CR_alphaBlend,           STD_FLAGS(32,32,1BIT,SCALAR) },

        { fastPathBitAnd_32_32,                 CR_bitAnd,               STD_FLAGS(32,32,NO,NO) },
        { fastPathBitAndInvert_32_32,           CR_bitAndInvert,         STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertAnd_32_32,           CR_bitInvertAnd,         STD_FLAGS(32,32,NO,NO) },
        { fastPathBitXor_32_32,                 CR_bitXor,               STD_FLAGS(32,32,NO,NO) },
        { fastPathBitOr_32_32,                  CR_bitOr,                STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertAndInvert_32_32,     CR_bitInvertAndInvert,   STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertXor_32_32,           CR_bitInvertXor,         STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertDestination_0_32,    CR_bitInvertDestination, STD_FLAGS_NO_SOURCE(32,NO) },
        { fastPathBitOrInvert_32_32,            CR_bitOrInvert,          STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertSource_32_32,        CR_bitInvertSource,      STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertOr_32_32,            CR_bitInvertOr,          STD_FLAGS(32,32,NO,NO) },
        { fastPathBitInvertOrInvert_32_32,      CR_bitInvertOrInvert,    STD_FLAGS(32,32,NO,NO) },
        { fastPathAddWord_32_32,                CR_addWord,              STD_FLAGS(32,32,NO,NO) },
        { fastPathSubWord_32_32,                CR_subWord,              STD_FLAGS(32,32,NO,NO) },
        { fastPathRgbAdd_32_32,                 CR_rgbAdd,               STD_FLAGS(32,32,NO,NO) },
        { fastPathRgbSub_32_32,                 CR_rgbSub,               STD_FLAGS(32,32,NO,NO) },
        { fastPathPixMask_32_32,                CR_pixMask,              STD_FLAGS(32,32,NO,NO) },
        { fastPathRgbMax_32_32,                 CR_rgbMax,               STD_FLAGS(32,32,NO,NO) },
        { fastPathRgbMin_32_32,                 CR_rgbMin,               STD_FLAGS(32,32,NO,NO) },
        { fastPathRgbMinInvert_32_32,           CR_rgbMinInvert,         STD_FLAGS(32,32,NO,NO) },
        { fastPathAlphaBlendConst_32_32,        CR_alphaBlendConst,      STD_FLAGS(32,32,NO,NO) },
};

void addArm64FastPaths(void)
{
    addFastPaths(fastPaths, sizeof fastPaths / sizeof *fastPaths);
}
