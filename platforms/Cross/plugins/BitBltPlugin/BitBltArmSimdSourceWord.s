;
; Copyright © 2013 Raspberry Pi Foundation
; Copyright © 2013 RISC OS Open Ltd
;
; Permission to use, copy, modify, distribute, and sell this software and its
; documentation for any purpose is hereby granted without fee, provided that
; the above copyright notice appear in all copies and that both that
; copyright notice and this permission notice appear in supporting
; documentation, and that the name of the copyright holders not be used in
; advertising or publicity pertaining to distribution of the software without
; specific, written prior permission.  The copyright holders make no
; representations about the suitability of this software for any purpose.  It
; is provided "as is" without express or implied warranty.
;
; THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS
; SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
; FITNESS, IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
; SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
; AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
; OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
; SOFTWARE.
;

; Debug options
                GBLL    DebugData
;DebugData       SETL    {TRUE}
                GBLL    DebugPld
;DebugPld        SETL    {TRUE}
                GBLL    VerboseBuild
;VerboseBuild    SETL    {TRUE}

        GET     BitBltArmSimdAsm.hdr

        AREA    |BitBltArmSimdSourceWord$$Code|, CODE, READONLY
        ARM

; ********************************************************************

        MACRO
        SourceWord1_32_init
        LDR     ht, [map]
        LDR     ht_info, [map, #4]
        MEND

        MACRO
        SourceWord1_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOVS    $wk0, $wk0, LSL #1
        STRCC   ht, [dst], #4
        STRCS   ht_info, [dst], #4
        MEND

        MACRO
        SourceWord1_32_64bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MSR     CPSR_f, $wk0
        MOV     $wk0, $wk0, LSL #2
        MOVPL   $wk1, ht
        MOVMI   $wk1, ht_info
        MOVNE   $wk2, ht
        MOVEQ   $wk2, ht_info
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord1_32_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord1_32_128bits_tail $src
        ASSERT  $src = $wk0
        MSR     CPSR_f, $wk0
        MOV     $wk0, $wk0, LSL #4
        MOVPL   $wk1, ht
        MOVMI   $wk1, ht_info
        MOVNE   $wk2, ht
        MOVEQ   $wk2, ht_info
        MOVCC   $wk3, ht
        MOVCS   $wk3, ht_info
        MOVVC   $wk4, ht
        MOVVS   $wk4, ht_info
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 32,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 4, \
  "stride_s,map,bitptrs,orig_w,scratch", \
  "x,stride_s,bitptrs", orig_w,, init ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord1_16_init
        LDRH    ht, [map]
        LDRH    ht_info, [map, #4]
        MEND

        MACRO
        SourceWord1_16_16bits $src, $dst, $fixed_skew
        MOVS    $src, $src, LSL #1
        ORRCC   $dst, ht, $dst, LSL #16
        ORRCS   $dst, ht_info, $dst, LSL #16
        MEND

        MACRO
        SourceWord1_16_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MSR     CPSR_f, $wk0
        MOV     $wk0, $wk0, LSL #2
        MOVPL   $wk1, ht
        MOVMI   $wk1, ht_info
        ORRNE   $wk1, ht, $wk1, LSL #16
        ORREQ   $wk1, ht_info, $wk1, LSL #16
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord1_16_4pixels $src, $dst0, $dst1
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        MOVPL   $dst0, ht
        MOVCC   $dst1, ht
        MOVMI   $dst0, ht_info
        MOVCS   $dst1, ht_info
        ORRNE   $dst0, ht, $dst0, LSL #16
        ORRVC   $dst1, ht, $dst1, LSL #16
        ORREQ   $dst0, ht_info, $dst0, LSL #16
        ORRVS   $dst1, ht_info, $dst1, LSL #16
        MEND

        MACRO
        SourceWord1_16_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord1_16_4pixels $wk0, $wk1, $wk2
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord1_16_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord1_16_128bits_tail $src
        ASSERT  $src = $wk0
        SourceWord1_16_4pixels $wk0, $wk1, $wk2
        SourceWord1_16_4pixels $wk0, $wk3, $wk4
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 16,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_s,map,bitptrs,orig_w,scratch", \
  "x,stride_s,bitptrs", orig_w,, init ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord2_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk1, $wk0, #3
        LDR     $wk1, [map, $wk1, LSL #2]
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord2_32_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk1, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
          AND     $wk2, $wk0, #3
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord2_32_128bits_head $src, $fixed_skew, $intra_preloads
        ASSERT  $src = $wk0
        MEND

        MACRO
        SourceWord2_32_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk1, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
          AND     $wk2, $wk0, #3
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk3, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
          AND     $wk4, $wk0, #3
        LDR     $wk3, [map, $wk3, LSL #2]
          LDR     $wk4, [map, $wk4, LSL #2]
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 32,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "ht,ht_info,bitptrs,orig_w,scratch", \
  "x,bitptrs", orig_w ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord1_8_init
        LDRB    ht, [map]
        LDRB    ht_info, [map, #4]
        MEND

        MACRO
        SourceWord1_8_8bits $src, $dst, $fixed_skew
        MOVS    $src, $src, LSL #1
        ORRCC   $dst, ht, $dst, LSL #8
        ORRCS   $dst, ht_info, $dst, LSL #8
        MEND

        MACRO
        SourceWord1_8_16bits $src, $dst, $fixed_skew
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #2
        ORRPL   $dst, ht, $dst, LSL #8
        ORRMI   $dst, ht_info, $dst, LSL #8
        ORRNE   $dst, ht, $dst, LSL #8
        ORREQ   $dst, ht_info, $dst, LSL #8
        MEND

        MACRO
        SourceWord1_8_4pixels $src, $dst
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        ORRPL   $dst, ht, $dst, LSL #8
        ORRMI   $dst, ht_info, $dst, LSL #8
        ORRNE   $dst, ht, $dst, LSL #8
        ORREQ   $dst, ht_info, $dst, LSL #8
        ORRCC   $dst, ht, $dst, LSL #8
        ORRCS   $dst, ht_info, $dst, LSL #8
        ORRVC   $dst, ht, $dst, LSL #8
        ORRVS   $dst, ht_info, $dst, LSL #8
        MEND

        MACRO
        SourceWord1_8_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord1_8_4pixels $wk0, $wk1
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord1_8_64bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord1_8_4pixels $wk0, $wk1
        SourceWord1_8_4pixels $wk0, $wk2
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord1_8_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord1_8_128bits_tail $src
        ASSERT  $src = $wk0
        SourceWord1_8_4pixels $wk0, $wk1
        SourceWord1_8_4pixels $wk0, $wk2
        SourceWord1_8_4pixels $wk0, $wk3
        SourceWord1_8_4pixels $wk0, $wk4
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_s,map,bitptrs,orig_w,scratch", \
  "x,stride_s,bitptrs", orig_w,, init ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord2_16_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2-2
        AND     $wk5, $src, #&C
        LDRH    $wk6, [map, $wk5]
        MOV     $src, $src, ROR #2
        ORR     $dst, $wk6, $dst, LSL #16
        MEND

        MACRO
        SourceWord2_16_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2-2
        AND     $wk5, $wk0, #&C
          MOV     $wk0, $wk0, ROR #32-2
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&C
          LDRH    $wk6, [map, $wk5]
        MOV     $wk0, $wk0, ROR #2
          ORR     $wk1, $wk6, $wk1, LSL #16
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord2_16_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2-2
        AND     $wk5, $wk0, #&C
          MOV     $wk0, $wk0, ROR #32-2
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&C
            MOV     $wk0, $wk0, ROR #32-2
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&C
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk1, $wk6, $wk1, LSL #16
            LDRH    $wk2, [map, $wk5]
              AND     $wk5, $wk0, #&C
              LDRH    $wk6, [map, $wk5]
        MOV     $wk0, $wk0, ROR #2
              ORR     $wk2, $wk6, $wk2, LSL #16
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord2_16_128bits_head $src, $fixed_skew, $intra_preloads
        ASSERT  $src = $wk0
        MEND

        MACRO
        SourceWord2_16_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-2-2
        AND     $wk5, $wk0, #&C
          MOV     $wk0, $wk0, ROR #32-2
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&C
            MOV     $wk0, $wk0, ROR #32-2
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&C
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk1, $wk6, $wk1, LSL #16
            LDRH    $wk2, [map, $wk5]
              AND     $wk5, $wk0, #&C
        MOV     $wk0, $wk0, ROR #32-2
              LDRH    $wk6, [map, $wk5]
        AND     $wk5, $wk0, #&C
          MOV     $wk0, $wk0, ROR #32-2
              ORR     $wk2, $wk6, $wk2, LSL #16
        LDRH    $wk3, [map, $wk5]
          AND     $wk5, $wk0, #&C
            MOV     $wk0, $wk0, ROR #32-2
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&C
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk3, $wk6, $wk3, LSL #16
            LDRH    $wk4, [map, $wk5]
              AND     $wk5, $wk0, #&C
              LDRH    $wk6, [map, $wk5]
        MOV     $wk0, $wk0, ROR #2
              ORR     $wk4, $wk6, $wk4, LSL #16
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 16,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", ht_info ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord4_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk1, $wk0, #&F
        LDR     $wk1, [map, $wk1, LSL #2]
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord4_32_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk1, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
          AND     $wk2, $wk0, #&F
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord4_32_128bits_head $src, $fixed_skew, $intra_preloads
        ASSERT  $src = $wk0
        MEND

        MACRO
        SourceWord4_32_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk1, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
          AND     $wk2, $wk0, #&F
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk3, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
          AND     $wk4, $wk0, #&F
        LDR     $wk3, [map, $wk3, LSL #2]
          LDR     $wk4, [map, $wk4, LSL #2]
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 32,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 3, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", ht_info ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord1_4_init
        LDR     ht, [map]
        LDR     ht_info, [map, #4]
        AND     ht, ht, #&F
        AND     ht_info, ht_info, #&F
        MEND

        MACRO
        SourceWord1_4_4bits $src, $dst, $fixed_skew
        MOVS    $src, $src, LSL #1
        ORRCC   $dst, ht, $dst, LSL #4
        ORRCS   $dst, ht_info, $dst, LSL #4
        MEND

        MACRO
        SourceWord1_4_8bits $src, $dst, $fixed_skew
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #2
        ORRPL   $dst, ht, $dst, LSL #4
        ORRMI   $dst, ht_info, $dst, LSL #4
        ORRNE   $dst, ht, $dst, LSL #4
        ORREQ   $dst, ht_info, $dst, LSL #4
        MEND

        MACRO
        SourceWord1_4_16bits $src, $dst, $fixed_skew
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        ORRPL   $dst, ht, $dst, LSL #4
        ORRMI   $dst, ht_info, $dst, LSL #4
        ORRNE   $dst, ht, $dst, LSL #4
        ORREQ   $dst, ht_info, $dst, LSL #4
        ORRCC   $dst, ht, $dst, LSL #4
        ORRCS   $dst, ht_info, $dst, LSL #4
        ORRVC   $dst, ht, $dst, LSL #4
        ORRVS   $dst, ht_info, $dst, LSL #4
        MEND

        MACRO
        SourceWord1_4_8pixels $src, $dst
        LCLA    counter
counter SETA    0
        WHILE   counter < 8
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        ORRPL   $dst, ht, $dst, LSL #4
        ORRMI   $dst, ht_info, $dst, LSL #4
        ORRNE   $dst, ht, $dst, LSL #4
        ORREQ   $dst, ht_info, $dst, LSL #4
        ORRCC   $dst, ht, $dst, LSL #4
        ORRCS   $dst, ht_info, $dst, LSL #4
        ORRVC   $dst, ht, $dst, LSL #4
        ORRVS   $dst, ht_info, $dst, LSL #4
counter SETA    counter + 4
        WEND
        MEND

        MACRO
        SourceWord1_4_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord1_4_8pixels $wk0, $wk1
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord1_4_64bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord1_4_8pixels $wk0, $wk1
        SourceWord1_4_8pixels $wk0, $wk2
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord1_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read1Word src, 4, carry, $fixed_skew, skew, $wk0
        MEND

        MACRO
        SourceWord1_4_128bits_tail $src
        SourceWord1_4_8pixels $wk4, $wk0
        SourceWord1_4_8pixels $wk4, $wk1
        SourceWord1_4_8pixels $wk4, $wk2
        SourceWord1_4_8pixels $wk4, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 4,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_s,map,bitptrs,orig_w,scratch", \
  "x,stride_s,bitptrs", orig_w,, init ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord2_8_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk5, $src, #3
        LDRB    $wk6, [map, $wk5, LSL #2]
        ORR     $dst, $wk6, $dst, LSL #8
        MEND

        MACRO
        SourceWord2_8_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk5, $src, #3
          MOV     $src, $src, ROR #32-2
        LDRB    $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $src, #3
        ORR     $dst, $wk6, $dst, LSL #8
          LDRB    $wk6, [map, $wk5, LSL #2]
          ORR     $dst, $wk6, $dst, LSL #8
        MEND

        MACRO
        SourceWord2_8_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
        LDRB    $wk1, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk1, $wk6, $wk1, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
            ORR     $wk1, $wk6, $wk1, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
              ORR     $wk1, $wk6, $wk1, LSL #8
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord2_8_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
        LDRB    $wk1, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk1, $wk6, $wk1, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
        MOV     $wk0, $wk0, ROR #32-2
            ORR     $wk1, $wk6, $wk1, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
              ORR     $wk1, $wk6, $wk1, LSL #8
        LDRB    $wk2, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk2, $wk6, $wk2, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
            ORR     $wk2, $wk6, $wk2, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
              ORR     $wk2, $wk6, $wk2, LSL #8
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord2_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read1Word src, 0, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord2_8_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
        LDRB    $wk1, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk1, $wk6, $wk1, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
        MOV     $wk0, $wk0, ROR #32-2
            ORR     $wk1, $wk6, $wk1, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
              ORR     $wk1, $wk6, $wk1, LSL #8
        LDRB    $wk2, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk2, $wk6, $wk2, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
        MOV     $wk0, $wk0, ROR #32-2
            ORR     $wk2, $wk6, $wk2, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
              ORR     $wk2, $wk6, $wk2, LSL #8
        LDRB    $wk3, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk3, $wk6, $wk3, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
        MOV     $wk0, $wk0, ROR #32-2
            ORR     $wk3, $wk6, $wk3, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
              ORR     $wk3, $wk6, $wk3, LSL #8
        LDRB    $wk4, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          ORR     $wk4, $wk6, $wk4, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
            ORR     $wk4, $wk6, $wk4, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
              ORR     $wk4, $wk6, $wk4, LSL #8
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", ht_info ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord4_16_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4-2
        AND     $wk5, $src, #&3C
        LDRH    $wk6, [map, $wk5]
        MOV     $src, $src, ROR #2
        ORR     $dst, $wk6, $dst, LSL #16
        MEND

        MACRO
        SourceWord4_16_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-4-2
        AND     $wk5, $wk0, #&3C
          MOV     $wk0, $wk0, ROR #32-4
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&3C
          LDRH    $wk6, [map, $wk5]
        MOV     $wk0, $wk0, ROR #2
          ORR     $wk1, $wk6, $wk1, LSL #16
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord4_16_64bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-4-2
        AND     $wk5, $wk0, #&3C
          MOV     $wk0, $wk0, ROR #32-4
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&3C
            MOV     $wk0, $wk0, ROR #32-4
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&3C
              MOV     $wk0, $wk0, ROR #32-4
          ORR     $wk1, $wk6, $wk1, LSL #16
            LDRH    $wk2, [map, $wk5]
              AND     $wk5, $wk0, #&3C
              LDRH    $wk6, [map, $wk5]
        MOV     $wk0, $wk0, ROR #2
              ORR     $wk2, $wk6, $wk2, LSL #16
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord4_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read1Word src, 0, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord4_16_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-4-2
        AND     $wk5, $wk0, #&3C
          MOV     $wk0, $wk0, ROR #32-4
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&3C
            MOV     $wk0, $wk0, ROR #32-4
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&3C
              MOV     $wk0, $wk0, ROR #32-4
          ORR     $wk1, $wk6, $wk1, LSL #16
            LDRH    $wk2, [map, $wk5]
              AND     $wk5, $wk0, #&3C
        MOV     $wk0, $wk0, ROR #32-4
              LDRH    $wk6, [map, $wk5]
        AND     $wk5, $wk0, #&3C
          MOV     $wk0, $wk0, ROR #32-4
              ORR     $wk2, $wk6, $wk2, LSL #16
        LDRH    $wk3, [map, $wk5]
          AND     $wk5, $wk0, #&3C
            MOV     $wk0, $wk0, ROR #32-4
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk0, #&3C
              MOV     $wk0, $wk0, ROR #32-4
          ORR     $wk3, $wk6, $wk3, LSL #16
            LDRH    $wk4, [map, $wk5]
              AND     $wk5, $wk0, #&3C
              LDRH    $wk6, [map, $wk5]
              ORR     $wk4, $wk6, $wk4, LSL #16
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 16,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", ht_info ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord8_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk1, $wk0, #&FF
        LDR     $wk1, [map, $wk1, LSL #2]
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord8_32_64bits $src, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk1, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
          AND     $wk2, $wk0, #&FF
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        Write2Words dst, 1
        MEND

        MACRO
        SourceWord8_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        MEND

        MACRO
        SourceWord8_32_128bits_tail $src
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk1, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
          AND     $wk2, $wk0, #&FF
        LDR     $wk1, [map, $wk1, LSL #2]
          LDR     $wk2, [map, $wk2, LSL #2]
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk3, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
          AND     $wk4, $wk0, #&FF
        LDR     $wk3, [map, $wk3, LSL #2]
          LDR     $wk4, [map, $wk4, LSL #2]
        Write4Words dst, 1
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 32,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY, 2, \
  "ht,ht_info,bitptrs,skew,scratch", \
  "", skew ; leading_pixels_reg=wk3

; ********************************************************************

        MACRO
        SourceWord1_2_init
        LDR     ht, [map]
        LDR     ht_info, [map, #4]
        AND     ht, ht, #3
        AND     ht_info, ht_info, #3
        MEND

        MACRO
        SourceWord1_2_2bits $src, $dst, $fixed_skew
        MOVS    $src, $src, LSL #1
        ORRCC   $dst, ht, $dst, LSL #2
        ORRCS   $dst, ht_info, $dst, LSL #2
        MEND

        MACRO
        SourceWord1_2_4bits $src, $dst, $fixed_skew
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #2
        ORRPL   $dst, ht, $dst, LSL #2
        ORRMI   $dst, ht_info, $dst, LSL #2
        ORRNE   $dst, ht, $dst, LSL #2
        ORREQ   $dst, ht_info, $dst, LSL #2
        MEND

        MACRO
        SourceWord1_2_8bits $src, $dst, $fixed_skew
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        ORRPL   $dst, ht, $dst, LSL #2
        ORRMI   $dst, ht_info, $dst, LSL #2
        ORRNE   $dst, ht, $dst, LSL #2
        ORREQ   $dst, ht_info, $dst, LSL #2
        ORRCC   $dst, ht, $dst, LSL #2
        ORRCS   $dst, ht_info, $dst, LSL #2
        ORRVC   $dst, ht, $dst, LSL #2
        ORRVS   $dst, ht_info, $dst, LSL #2
        MEND

        MACRO
        SourceWord1_2_16bits $src, $dst, $fixed_skew
        LCLA    counter
counter SETA    0
        WHILE   counter < 8
        MSR     CPSR_f, $src
        MOV     $src, $src, LSL #4
        ORRPL   $dst, ht, $dst, LSL #2
        ORRMI   $dst, ht_info, $dst, LSL #2
        ORRNE   $dst, ht, $dst, LSL #2
        ORREQ   $dst, ht_info, $dst, LSL #2
        ORRCC   $dst, ht, $dst, LSL #2
        ORRCS   $dst, ht_info, $dst, LSL #2
        ORRVC   $dst, ht, $dst, LSL #2
        ORRVS   $dst, ht_info, $dst, LSL #2
counter SETA    counter + 4
        WEND
        MEND

        MACRO
        SourceWord1_2_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        LCLA    counter
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk0
        MOV     $wk0, $wk0, LSL #4
        ORRPL   $wk1, ht, $wk1, LSL #2
        ORRMI   $wk1, ht_info, $wk1, LSL #2
        ORRNE   $wk1, ht, $wk1, LSL #2
        ORREQ   $wk1, ht_info, $wk1, LSL #2
        ORRCC   $wk1, ht, $wk1, LSL #2
        ORRCS   $wk1, ht_info, $wk1, LSL #2
        ORRVC   $wk1, ht, $wk1, LSL #2
        ORRVS   $wk1, ht_info, $wk1, LSL #2
counter SETA    counter + 4
        WEND
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord1_2_64bits $src, $fixed_skew
        Read1Word src, 2, carry, $fixed_skew, skew, $wk0
        LCLA    counter
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk2
        MOV     $wk2, $wk2, LSL #4
        ORRPL   $wk0, ht, $wk0, LSL #2
        ORRMI   $wk0, ht_info, $wk0, LSL #2
        ORRNE   $wk0, ht, $wk0, LSL #2
        ORREQ   $wk0, ht_info, $wk0, LSL #2
        ORRCC   $wk0, ht, $wk0, LSL #2
        ORRCS   $wk0, ht_info, $wk0, LSL #2
        ORRVC   $wk0, ht, $wk0, LSL #2
        ORRVS   $wk0, ht_info, $wk0, LSL #2
counter SETA    counter + 4
        WEND
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk2
        MOV     $wk2, $wk2, LSL #4
        ORRPL   $wk1, ht, $wk1, LSL #2
        ORRMI   $wk1, ht_info, $wk1, LSL #2
        ORRNE   $wk1, ht, $wk1, LSL #2
        ORREQ   $wk1, ht_info, $wk1, LSL #2
        ORRCC   $wk1, ht, $wk1, LSL #2
        ORRCS   $wk1, ht_info, $wk1, LSL #2
        ORRVC   $wk1, ht, $wk1, LSL #2
        ORRVS   $wk1, ht_info, $wk1, LSL #2
counter SETA    counter + 4
        WEND
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord1_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 3, carry, $fixed_skew, skew, $wk0
        MEND

        MACRO
        SourceWord1_2_128bits_tail $src
        LCLA    counter
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk3
        MOV     $wk3, $wk3, LSL #4
        ORRPL   $wk0, ht, $wk0, LSL #2
        ORRMI   $wk0, ht_info, $wk0, LSL #2
        ORRNE   $wk0, ht, $wk0, LSL #2
        ORREQ   $wk0, ht_info, $wk0, LSL #2
        ORRCC   $wk0, ht, $wk0, LSL #2
        ORRCS   $wk0, ht_info, $wk0, LSL #2
        ORRVC   $wk0, ht, $wk0, LSL #2
        ORRVS   $wk0, ht_info, $wk0, LSL #2
counter SETA    counter + 4
        WEND
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk3
        MOV     $wk3, $wk3, LSL #4
        ORRPL   $wk1, ht, $wk1, LSL #2
        ORRMI   $wk1, ht_info, $wk1, LSL #2
        ORRNE   $wk1, ht, $wk1, LSL #2
        ORREQ   $wk1, ht_info, $wk1, LSL #2
        ORRCC   $wk1, ht, $wk1, LSL #2
        ORRCS   $wk1, ht_info, $wk1, LSL #2
        ORRVC   $wk1, ht, $wk1, LSL #2
        ORRVS   $wk1, ht_info, $wk1, LSL #2
counter SETA    counter + 4
        WEND
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk4
        MOV     $wk4, $wk4, LSL #4
        ORRPL   $wk2, ht, $wk2, LSL #2
        ORRMI   $wk2, ht_info, $wk2, LSL #2
        ORRNE   $wk2, ht, $wk2, LSL #2
        ORREQ   $wk2, ht_info, $wk2, LSL #2
        ORRCC   $wk2, ht, $wk2, LSL #2
        ORRCS   $wk2, ht_info, $wk2, LSL #2
        ORRVC   $wk2, ht, $wk2, LSL #2
        ORRVS   $wk2, ht_info, $wk2, LSL #2
counter SETA    counter + 4
        WEND
counter SETA    0
        WHILE   counter < 16
        MSR     CPSR_f, $wk4
        MOV     $wk4, $wk4, LSL #4
        ORRPL   $wk3, ht, $wk3, LSL #2
        ORRMI   $wk3, ht_info, $wk3, LSL #2
        ORRNE   $wk3, ht, $wk3, LSL #2
        ORREQ   $wk3, ht_info, $wk3, LSL #2
        ORRCC   $wk3, ht, $wk3, LSL #2
        ORRCS   $wk3, ht_info, $wk3, LSL #2
        ORRVC   $wk3, ht, $wk3, LSL #2
        ORRVS   $wk3, ht_info, $wk3, LSL #2
counter SETA    counter + 4
        WEND
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 2,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 3, \
  "stride_d,stride_s,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", orig_w,, init ;wk3

; ********************************************************************

        MACRO
        SourceWord2_4_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk5, $src, #3
        LDR     $wk6, [map, $wk5, LSL #2]
        AND     $wk6, $wk6, #&F
        ORR     $dst, $wk6, $dst, LSL #4
        MEND

        MACRO
        SourceWord2_4_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk5, $src, #3
          MOV     $src, $src, ROR #32-2
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $src, #3
        AND     $wk6, $wk6, #&F
        ORR     $dst, $wk6, $dst, LSL #4
          LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk6, $wk6, #&F
          ORR     $dst, $wk6, $dst, LSL #4
        MEND

        MACRO
        SourceWord2_4_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk5, $src, #3
          MOV     $src, $src, ROR #32-2
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $src, #3
            MOV     $src, $src, ROR #32-2
        AND     $wk6, $wk6, #&F
        ORR     $dst, $wk6, $dst, LSL #4
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $src, #3
              MOV     $src, $src, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $dst, $wk6, $dst, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $src, #3
            AND     $wk6, $wk6, #&F
            ORR     $dst, $wk6, $dst, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk6, $wk6, #&F
              ORR     $dst, $wk6, $dst, LSL #4
        MEND

        MACRO
        SourceWord2_4_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk5, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
        AND     $wk1, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk1, $wk6, $wk1, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #3
                MOV     $wk0, $wk0, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk1, $wk6, $wk1, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk0, #3
                  MOV     $wk0, $wk0, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk1, $wk6, $wk1, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk0, #3
                    MOV     $wk0, $wk0, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk1, $wk6, $wk1, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk0, #3
                      MOV     $wk0, $wk0, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk1, $wk6, $wk1, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk0, #3
                    AND     $wk6, $wk6, #&F
                    ORR     $wk1, $wk6, $wk1, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk6, $wk6, #&F
                      ORR     $wk1, $wk6, $wk1, LSL #4
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord2_4_64bits $src, $fixed_skew
        Read1Word src, 2, carry, $fixed_skew, skew, $wk5
        MOV     $wk2, $wk2, ROR #32-2
        AND     $wk5, $wk2, #3
          MOV     $wk2, $wk2, ROR #32-2
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk2, #3
            MOV     $wk2, $wk2, ROR #32-2
        AND     $wk0, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk2, #3
              MOV     $wk2, $wk2, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk0, $wk6, $wk0, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk2, #3
                MOV     $wk2, $wk2, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk0, $wk6, $wk0, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk2, #3
                  MOV     $wk2, $wk2, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk0, $wk6, $wk0, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk2, #3
                    MOV     $wk2, $wk2, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk0, $wk6, $wk0, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk2, #3
                      MOV     $wk2, $wk2, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk0, $wk6, $wk0, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk2, #3
        MOV     $wk2, $wk2, ROR #32-2
                    AND     $wk6, $wk6, #&F
                    ORR     $wk0, $wk6, $wk0, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk2, #3
          MOV     $wk2, $wk2, ROR #32-2
                      AND     $wk6, $wk6, #&F
                      ORR     $wk0, $wk6, $wk0, LSL #4
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk2, #3
            MOV     $wk2, $wk2, ROR #32-2
        AND     $wk1, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk2, #3
              MOV     $wk2, $wk2, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk1, $wk6, $wk1, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk2, #3
                MOV     $wk2, $wk2, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk1, $wk6, $wk1, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk2, #3
                  MOV     $wk2, $wk2, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk1, $wk6, $wk1, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk2, #3
                    MOV     $wk2, $wk2, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk1, $wk6, $wk1, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk2, #3
                      MOV     $wk2, $wk2, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk1, $wk6, $wk1, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk2, #3
                    AND     $wk6, $wk6, #&F
                    ORR     $wk1, $wk6, $wk1, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk6, $wk6, #&F
                      ORR     $wk1, $wk6, $wk1, LSL #4
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord2_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 3, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord2_4_128bits_tail $src
        MOV     $wk3, $wk3, ROR #32-2
        AND     $wk5, $wk3, #3
          MOV     $wk3, $wk3, ROR #32-2
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk3, #3
            MOV     $wk3, $wk3, ROR #32-2
        AND     $wk0, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk3, #3
              MOV     $wk3, $wk3, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk0, $wk6, $wk0, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk3, #3
                MOV     $wk3, $wk3, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk0, $wk6, $wk0, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk3, #3
                  MOV     $wk3, $wk3, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk0, $wk6, $wk0, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk3, #3
                    MOV     $wk3, $wk3, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk0, $wk6, $wk0, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk3, #3
                      MOV     $wk3, $wk3, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk0, $wk6, $wk0, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk3, #3
        MOV     $wk3, $wk3, ROR #32-2
                    AND     $wk6, $wk6, #&F
                    ORR     $wk0, $wk6, $wk0, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk3, #3
          MOV     $wk3, $wk3, ROR #32-2
                      AND     $wk6, $wk6, #&F
                      ORR     $wk0, $wk6, $wk0, LSL #4
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk3, #3
            MOV     $wk3, $wk3, ROR #32-2
        AND     $wk1, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk3, #3
              MOV     $wk3, $wk3, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk1, $wk6, $wk1, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk3, #3
                MOV     $wk3, $wk3, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk1, $wk6, $wk1, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk3, #3
                  MOV     $wk3, $wk3, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk1, $wk6, $wk1, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk3, #3
                    MOV     $wk3, $wk3, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk1, $wk6, $wk1, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk3, #3
                      MOV     $wk3, $wk3, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk1, $wk6, $wk1, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk3, #3
        MOV     $wk4, $wk4, ROR #32-2
                    AND     $wk6, $wk6, #&F
                    ORR     $wk1, $wk6, $wk1, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk4, #3
          MOV     $wk4, $wk4, ROR #32-2
                      AND     $wk6, $wk6, #&F
                      ORR     $wk1, $wk6, $wk1, LSL #4
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk4, #3
            MOV     $wk4, $wk4, ROR #32-2
        AND     $wk2, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk4, #3
              MOV     $wk4, $wk4, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk2, $wk6, $wk2, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk4, #3
                MOV     $wk4, $wk4, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk2, $wk6, $wk2, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk4, #3
                  MOV     $wk4, $wk4, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk2, $wk6, $wk2, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk4, #3
                    MOV     $wk4, $wk4, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk2, $wk6, $wk2, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk4, #3
                      MOV     $wk4, $wk4, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk2, $wk6, $wk2, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk4, #3
        MOV     $wk4, $wk4, ROR #32-2
                    AND     $wk6, $wk6, #&F
                    ORR     $wk2, $wk6, $wk2, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
        AND     $wk5, $wk4, #3
          MOV     $wk4, $wk4, ROR #32-2
                      AND     $wk6, $wk6, #&F
                      ORR     $wk2, $wk6, $wk2, LSL #4
        LDR     $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $wk4, #3
            MOV     $wk4, $wk4, ROR #32-2
        AND     $wk3, $wk6, #&F
          LDR     $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk4, #3
              MOV     $wk4, $wk4, ROR #32-2
          AND     $wk6, $wk6, #&F
          ORR     $wk3, $wk6, $wk3, LSL #4
            LDR     $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk4, #3
                MOV     $wk4, $wk4, ROR #32-2
            AND     $wk6, $wk6, #&F
            ORR     $wk3, $wk6, $wk3, LSL #4
              LDR     $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk4, #3
                  MOV     $wk4, $wk4, ROR #32-2
              AND     $wk6, $wk6, #&F
              ORR     $wk3, $wk6, $wk3, LSL #4
                LDR     $wk6, [map, $wk5, LSL #2]
                  AND     $wk5, $wk4, #3
                    MOV     $wk4, $wk4, ROR #32-2
                AND     $wk6, $wk6, #&F
                ORR     $wk3, $wk6, $wk3, LSL #4
                  LDR     $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk4, #3
                      MOV     $wk4, $wk4, ROR #32-2
                  AND     $wk6, $wk6, #&F
                  ORR     $wk3, $wk6, $wk3, LSL #4
                    LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk4, #3
                    AND     $wk6, $wk6, #&F
                    ORR     $wk3, $wk6, $wk3, LSL #4
                      LDR     $wk6, [map, $wk5, LSL #2]
                      AND     $wk6, $wk6, #&F
                      ORR     $wk3, $wk6, $wk3, LSL #4
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 4,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", bitptrs ;wk4

; ********************************************************************

        MACRO
        SourceWord4_8_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk5, $src, #&F
        LDRB    $wk6, [map, $wk5, LSL #2]
        ORR     $dst, $wk6, $dst, LSL #8
        MEND

        MACRO
        SourceWord4_8_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk5, $src, #&F
          MOV     $src, $src, ROR #32-4
        LDRB    $wk6, [map, $wk5, LSL #2]
          AND     $wk5, $src, #&F
        ORR     $dst, $wk6, $dst, LSL #8
          LDRB    $wk6, [map, $wk5, LSL #2]
          ORR     $dst, $wk6, $dst, LSL #8
        MEND

        MACRO
        SourceWord4_8_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk5, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
        LDRB    $wk1, [map, $wk5, LSL #2]
          AND     $wk5, $wk0, #&F
            MOV     $wk0, $wk0, ROR #32-4
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk0, #&F
              MOV     $wk0, $wk0, ROR #32-4
          ORR     $wk1, $wk6, $wk1, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk0, #&F
            ORR     $wk1, $wk6, $wk1, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
              ORR     $wk1, $wk6, $wk1, LSL #8
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord4_8_64bits $src, $fixed_skew
        Read1Word src, 2, carry, $fixed_skew, skew, $wk5
        MOV     $wk2, $wk2, ROR #32-4
        AND     $wk5, $wk2, #&F
          MOV     $wk2, $wk2, ROR #32-4
        LDRB    $wk0, [map, $wk5, LSL #2]
          AND     $wk5, $wk2, #&F
            MOV     $wk2, $wk2, ROR #32-4
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk2, #&F
              MOV     $wk2, $wk2, ROR #32-4
          ORR     $wk0, $wk6, $wk0, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk2, #&F
                MOV     $wk2, $wk2, ROR #32-4
            ORR     $wk0, $wk6, $wk0, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk2, #&F
                  MOV     $wk2, $wk2, ROR #32-4
              ORR     $wk0, $wk6, $wk0, LSL #8
                LDRB    $wk1, [map, $wk5, LSL #2]
                  AND     $wk5, $wk2, #&F
                    MOV     $wk2, $wk2, ROR #32-4
                  LDRB    $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk2, #&F
                      MOV     $wk2, $wk2, ROR #32-4
                  ORR     $wk1, $wk6, $wk1, LSL #8
                    LDRB    $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk2, #&F
                    ORR     $wk1, $wk6, $wk1, LSL #8
                      LDRB    $wk6, [map, $wk5, LSL #2]
                      ORR     $wk1, $wk6, $wk1, LSL #8
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord4_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 3, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord4_8_128bits_tail $src
        MOV     $wk3, $wk3, ROR #32-4
        AND     $wk5, $wk3, #&F
          MOV     $wk3, $wk3, ROR #32-4
        LDRB    $wk0, [map, $wk5, LSL #2]
          AND     $wk5, $wk3, #&F
            MOV     $wk3, $wk3, ROR #32-4
          LDRB    $wk6, [map, $wk5, LSL #2]
            AND     $wk5, $wk3, #&F
              MOV     $wk3, $wk3, ROR #32-4
          ORR     $wk0, $wk6, $wk0, LSL #8
            LDRB    $wk6, [map, $wk5, LSL #2]
              AND     $wk5, $wk3, #&F
                MOV     $wk3, $wk3, ROR #32-4
            ORR     $wk0, $wk6, $wk0, LSL #8
              LDRB    $wk6, [map, $wk5, LSL #2]
                AND     $wk5, $wk3, #&F
                  MOV     $wk3, $wk3, ROR #32-4
              ORR     $wk0, $wk6, $wk0, LSL #8
                LDRB    $wk1, [map, $wk5, LSL #2]
                  AND     $wk5, $wk3, #&F
                    MOV     $wk3, $wk3, ROR #32-4
                  LDRB    $wk6, [map, $wk5, LSL #2]
                    AND     $wk5, $wk3, #&F
                      MOV     $wk3, $wk3, ROR #32-4
                  ORR     $wk1, $wk6, $wk1, LSL #8
                    LDRB    $wk6, [map, $wk5, LSL #2]
                      AND     $wk5, $wk3, #&F
                        MOV     $wk4, $wk4, ROR #32-4
                    ORR     $wk1, $wk6, $wk1, LSL #8
                      LDRB    $wk6, [map, $wk5, LSL #2]
                        AND     $wk5, $wk4, #&F
                          MOV     $wk4, $wk4, ROR #32-4
                      ORR     $wk1, $wk6, $wk1, LSL #8
                        LDRB    $wk2, [map, $wk5, LSL #2]
                          AND     $wk5, $wk4, #&F
                            MOV     $wk4, $wk4, ROR #32-4
                          LDRB    $wk6, [map, $wk5, LSL #2]
                            AND     $wk5, $wk4, #&F
                              MOV     $wk4, $wk4, ROR #32-4
                          ORR     $wk2, $wk6, $wk2, LSL #8
                            LDRB    $wk6, [map, $wk5, LSL #2]
                              AND     $wk5, $wk4, #&F
                                MOV     $wk4, $wk4, ROR #32-4
                            ORR     $wk2, $wk6, $wk2, LSL #8
                              LDRB    $wk6, [map, $wk5, LSL #2]
                                AND     $wk5, $wk4, #&F
                                  MOV     $wk4, $wk4, ROR #32-4
                              ORR     $wk2, $wk6, $wk2, LSL #8
                                LDRB    $wk3, [map, $wk5, LSL #2]
                                  AND     $wk5, $wk4, #&F
                                    MOV     $wk4, $wk4, ROR #32-4
                                  LDRB    $wk6, [map, $wk5, LSL #2]
                                    AND     $wk5, $wk4, #&F
                                      MOV     $wk4, $wk4, ROR #32-4
                                  ORR     $wk3, $wk6, $wk3, LSL #8
                                    LDRB    $wk6, [map, $wk5, LSL #2]
                                      AND     $wk5, $wk4, #&F
                                    ORR     $wk3, $wk6, $wk3, LSL #8
                                      LDRB    $wk6, [map, $wk5, LSL #2]
                                      ORR     $wk3, $wk6, $wk3, LSL #8
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", bitptrs ;wk4

; ********************************************************************

        MACRO
        SourceWord8_16_16bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8-2
        AND     $wk5, $src, #&3FC
          MOV     $src, $src, ROR #2
        LDRH    $wk6, [map, $wk5]
        ORR     $dst, $wk6, $dst, LSL #16
        MEND

        MACRO
        SourceWord8_16_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        MOV     $wk0, $wk0, ROR #32-8-2
        AND     $wk5, $wk0, #&3FC
          MOV     $wk0, $wk0, ROR #32-8
        LDRH    $wk1, [map, $wk5]
          AND     $wk5, $wk0, #&3FC
            MOV     $wk0, $wk0, ROR #2
          LDRH    $wk6, [map, $wk5]
          ORR     $wk1, $wk6, $wk1, LSL #16
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord8_16_64bits $src, $fixed_skew
        Read1Word src, 2, carry, $fixed_skew, skew, $wk5
        MOV     $wk2, $wk2, ROR #32-8-2
        AND     $wk5, $wk2, #&3FC
          MOV     $wk2, $wk2, ROR #32-8
        LDRH    $wk0, [map, $wk5]
          AND     $wk5, $wk2, #&3FC
            MOV     $wk2, $wk2, ROR #32-8
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk2, #&3FC
              MOV     $wk2, $wk2, ROR #32-8
          ORR     $wk0, $wk6, $wk0, LSL #16
            LDRH    $wk1, [map, $wk5]
              AND     $wk5, $wk2, #&3FC
              LDRH    $wk6, [map, $wk5]
              ORR     $wk1, $wk6, $wk1, LSL #16
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord8_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 3, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord8_16_128bits_tail $src
        MOV     $wk3, $wk3, ROR #32-8-2
        AND     $wk5, $wk3, #&3FC
          MOV     $wk3, $wk3, ROR #32-8
        LDRH    $wk0, [map, $wk5]
          AND     $wk5, $wk3, #&3FC
            MOV     $wk3, $wk3, ROR #32-8
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk3, #&3FC
              MOV     $wk3, $wk3, ROR #32-8
          ORR     $wk0, $wk6, $wk0, LSL #16
            LDRH    $wk1, [map, $wk5]
              AND     $wk5, $wk3, #&3FC
        MOV     $wk4, $wk4, ROR #32-8-2
              LDRH    $wk6, [map, $wk5]
        AND     $wk5, $wk4, #&3FC
          MOV     $wk4, $wk4, ROR #32-8
              ORR     $wk1, $wk6, $wk1, LSL #16
        LDRH    $wk2, [map, $wk5]
          AND     $wk5, $wk4, #&3FC
            MOV     $wk4, $wk4, ROR #32-8
          LDRH    $wk6, [map, $wk5]
            AND     $wk5, $wk4, #&3FC
              MOV     $wk4, $wk4, ROR #32-8
          ORR     $wk2, $wk6, $wk2, LSL #16
            LDRH    $wk3, [map, $wk5]
              AND     $wk5, $wk4, #&3FC
              LDRH    $wk6, [map, $wk5]
              ORR     $wk3, $wk6, $wk3, LSL #16
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 16,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,stride_s", bitptrs ;wk3

; ********************************************************************

        MACRO
        SourceWord16_32_init
        LDR     scratch, =&00800080
        LDR     ht, =&03E003E0
        ; Set GE[3:0] to 0101 so SEL instructions do what we want
        UADD8   scratch, scratch, scratch
      [ DebugData
        B       %FT00
        LTORG
00
      ]
        MEND

        MACRO
        SourceWord16_32_1pixel $src, $dst, $tmp
        BIC     $dst, $src, ht               ; XRRRRR00000BBBBBXXXXXX00000XXXXX
        AND     $tmp, $src, ht               ; 000000GGGGG00000000000XXXXX00000
        MOV     $dst, $dst, LSR #16          ; 0000000000000000XRRRRR00000BBBBB
        MOV     $tmp, $tmp, LSR #10          ; 0000000000000000GGGGG00000000000
        MOV     $dst, $dst, LSL #9           ; 0000000XRRRRR00000BBBBB000000000
        PKHTB   $dst, $dst, $dst, ASR #6     ; 0000000XRRRRR00000R00000BBBBB000
        SEL     $dst, $dst, $tmp             ; 00000000RRRRR000GGGGG000BBBBB000
        MOVS    $tmp, $src, LSR #16
        BEQ     %FT00
        TEQ     $dst, #0
        MOVEQ   $dst, #1
00
        MEND

        MACRO
        SourceWord16_32_2pixels $src, $dst0, $dst1, $tmp0, $tmp1
        BIC     $tmp0, $src, ht              ; XRRRRR00000BBBBBxrrrrr00000bbbbb
        AND     $tmp1, $src, ht              ; 000000GGGGG00000000000ggggg00000
        MOV     $dst0, $tmp0, LSR #16        ; 0000000000000000XRRRRR00000BBBBB
        MOV     $tmp1, $tmp1, LSL #6         ; GGGGG00000000000ggggg00000000000
        MOV     $dst0, $dst0, LSL #9         ; 0000000XRRRRR00000BBBBB000000000
        MOV     $tmp0, $tmp0, LSL #9         ; 00BBBBBxrrrrr00000bbbbb000000000
        PKHTB   $dst0, $dst0, $dst0, ASR #6  ; 0000000XRRRRR000RRR00000BBBBB000
        PKHTB   $tmp0, $tmp0, $tmp0, ASR #6  ; 00BBBBBxrrrrr000rrr00000bbbbb000
        MOV     $dst1, $tmp1, LSR #16        ; 0000000000000000GGGGG00000000000
        SEL     $dst0, $dst0, $dst1          ; 00000000RRRRR000GGGGG000BBBBB000
        BIC     $dst1, $tmp1, $dst1, LSL #16 ; 0000000000000000ggggg00000000000
        SEL     $dst1, $tmp0, $dst1          ; 00000000rrrrr000ggggg000bbbbb000
        MOVS    $tmp0, $src, LSR #16
        BEQ     %FT00
        TEQ     $dst0, #0
        MOVEQ   $dst0, #1
00      MOVS    $tmp0, $src, LSL #16
        BEQ     %FT00
        TEQ     $dst1, #0
        MOVEQ   $dst1, #1
00
        MEND

        MACRO
        SourceWord16_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        SourceWord16_32_1pixel $wk0, $wk1, $wk2
        Write1Word dst, 1
        MEND

        MACRO
        SourceWord16_32_64bits $src, $fixed_skew
        Read1Word src, 2, carry, $fixed_skew, skew, $wk5
        SourceWord16_32_2pixels  $wk2, $wk0, $wk1, $wk5, $wk6
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 3, carry, $fixed_skew, skew, $wk5
        MEND

        MACRO
        SourceWord16_32_128bits_tail $src
        SourceWord16_32_2pixels  $wk3, $wk0, $wk1, $wk5, $wk6
        SourceWord16_32_2pixels  $wk4, $wk2, $wk3, $wk5, $wk6
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 32,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_s,ht_info,map,bitptrs,skew,orig_w,scratch", \
  "x,stride_s,bitptrs", bitptrs,, init ;wk3

; ********************************************************************

        MACRO
        SourceWord1_1_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord1_1_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord1_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord1_1_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord1_1_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord1_1_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 1, 1,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 2, \
  "y,stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", ht

; ********************************************************************

        MACRO
        SourceWord2_2_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord2_2_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord2_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord2_2_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord2_2_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord2_2_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 2,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 2, \
  "y,stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", ht

; ********************************************************************

        MACRO
        SourceWord4_4_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord4_4_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord4_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord4_4_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord4_4_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord4_4_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 4,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 3, \
  "y,stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", ht

; ********************************************************************

        MACRO
        SourceWord8_8_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord8_8_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord8_8_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord8_8_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord8_8_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 8,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS_WIDE :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 4, \
  "ht,ht_info,map,bitptrs,y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", bitptrs, scratch

; ********************************************************************

        MACRO
        SourceWord16_16_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord16_16_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord16_16_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord16_16_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord16_16_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 16,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS_WIDE :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 4, \
  "ht,ht_info,map,bitptrs,y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", bitptrs, scratch

; ********************************************************************

        MACRO
        SourceWord32_32_32bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_32_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        SourceWord32_32_128bits_tail $src
        Write4Words dst, 0
        MEND

        MACRO
        SourceWord32_32_256bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk8
        Read4Words src, 4, carry, $fixed_skew, skew, $wk8
        MEND

        MACRO
        SourceWord32_32_256bits_tail $src
        Write4Words dst, 0
        Write4Words dst, 4
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 32,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS_WIDE :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_MAX_256BIT_MACRO, 2, \
  "ht,ht_info,map,bitptrs,y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", bitptrs, scratch

; ********************************************************************

        MACRO
        SourceWord2_1_1bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk6, $src, #3
        LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord2_1_2bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk6, $src, #3
          MOV     $src, $src, ROR #32-2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #3
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord2_1_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk6, $src, #3
          MOV     $src, $src, ROR #32-2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #3
            MOV     $src, $src, ROR #32-2
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src, #3
              MOV     $src, $src, ROR #32-2
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src, #3
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord2_1_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-2
        AND     $wk6, $src, #3
          MOV     $src, $src, ROR #32-2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #3
            MOV     $src, $src, ROR #32-2
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src, #3
              MOV     $src, $src, ROR #32-2
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src, #3
                MOV     $src, $src, ROR #32-2
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src, #3
                  MOV     $src, $src, ROR #32-2
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src, #3
                    MOV     $src, $src, ROR #32-2
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src, #3
                      MOV     $src, $src, ROR #32-2
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src, #3
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord2_1_16bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-2
        AND     $wk6, $wk0, #3
          MOV     $wk0, $wk0, ROR #32-2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $wk0, #3
            MOV     $wk0, $wk0, ROR #32-2
        AND     $wk7, $wk7, #1
        ORR     $wk1, $wk7, $wk1, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $wk0, #3
              MOV     $wk0, $wk0, ROR #32-2
          AND     $wk7, $wk7, #1
          ORR     $wk1, $wk7, $wk1, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $wk0, #3
                MOV     $wk0, $wk0, ROR #32-2
            AND     $wk7, $wk7, #1
            ORR     $wk1, $wk7, $wk1, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $wk0, #3
                  MOV     $wk0, $wk0, ROR #32-2
              AND     $wk7, $wk7, #1
              ORR     $wk1, $wk7, $wk1, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $wk0, #3
                    MOV     $wk0, $wk0, ROR #32-2
                AND     $wk7, $wk7, #1
                ORR     $wk1, $wk7, $wk1, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $wk0, #3
                      MOV     $wk0, $wk0, ROR #32-2
                  AND     $wk7, $wk7, #1
                  ORR     $wk1, $wk7, $wk1, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $wk0, #3
                        MOV     $wk0, $wk0, ROR #32-2
                    AND     $wk7, $wk7, #1
                    ORR     $wk1, $wk7, $wk1, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                        AND     $wk6, $wk0, #3
                          MOV     $wk0, $wk0, ROR #32-2
                      AND     $wk7, $wk7, #1
                      ORR     $wk1, $wk7, $wk1, LSL #1
                        LDR     $wk7, [map, $wk6, LSL #2]
                          AND     $wk6, $wk0, #3
                            MOV     $wk0, $wk0, ROR #32-2
                        AND     $wk7, $wk7, #1
                        ORR     $wk1, $wk7, $wk1, LSL #1
                          LDR     $wk7, [map, $wk6, LSL #2]
                            AND     $wk6, $wk0, #3
                              MOV     $wk0, $wk0, ROR #32-2
                          AND     $wk7, $wk7, #1
                          ORR     $wk1, $wk7, $wk1, LSL #1
                            LDR     $wk7, [map, $wk6, LSL #2]
                              AND     $wk6, $wk0, #3
                                MOV     $wk0, $wk0, ROR #32-2
                            AND     $wk7, $wk7, #1
                            ORR     $wk1, $wk7, $wk1, LSL #1
                              LDR     $wk7, [map, $wk6, LSL #2]
                                AND     $wk6, $wk0, #3
                                  MOV     $wk0, $wk0, ROR #32-2
                              AND     $wk7, $wk7, #1
                              ORR     $wk1, $wk7, $wk1, LSL #1
                                LDR     $wk7, [map, $wk6, LSL #2]
                                  AND     $wk6, $wk0, #3
                                    MOV     $wk0, $wk0, ROR #32-2
                                AND     $wk7, $wk7, #1
                                ORR     $wk1, $wk7, $wk1, LSL #1
                                  LDR     $wk7, [map, $wk6, LSL #2]
                                    AND     $wk6, $wk0, #3
                                      MOV     $wk0, $wk0, ROR #32-2
                                  AND     $wk7, $wk7, #1
                                  ORR     $wk1, $wk7, $wk1, LSL #1
                                    LDR     $wk7, [map, $wk6, LSL #2]
                                      AND     $wk6, $wk0, #3
                                    AND     $wk7, $wk7, #1
                                    ORR     $wk1, $wk7, $wk1, LSL #1
                                      LDR     $wk7, [map, $wk6, LSL #2]
                                      AND     $wk7, $wk7, #1
                                      ORR     $wk1, $wk7, $wk1, LSL #1
        MEND

        MACRO
        SourceWord2_1_32pixels $src0, $src1, $dst
        MOV     $src0, $src0, ROR #32-2
        AND     $wk6, $src0, #3
          MOV     $src0, $src0, ROR #32-2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #3
            MOV     $src0, $src0, ROR #32-2
        AND     $dst, $wk7, #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #3
              MOV     $src0, $src0, ROR #32-2
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #3
                MOV     $src0, $src0, ROR #32-2
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src0, #3
                  MOV     $src0, $src0, ROR #32-2
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src0, #3
                    MOV     $src0, $src0, ROR #32-2
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src0, #3
                      MOV     $src0, $src0, ROR #32-2
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src0, #3
                        MOV     $src0, $src0, ROR #32-2
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                        AND     $wk6, $src0, #3
                          MOV     $src0, $src0, ROR #32-2
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
                        LDR     $wk7, [map, $wk6, LSL #2]
                          AND     $wk6, $src0, #3
                            MOV     $src0, $src0, ROR #32-2
                        AND     $wk7, $wk7, #1
                        ORR     $dst, $wk7, $dst, LSL #1
                          LDR     $wk7, [map, $wk6, LSL #2]
                            AND     $wk6, $src0, #3
                              MOV     $src0, $src0, ROR #32-2
                          AND     $wk7, $wk7, #1
                          ORR     $dst, $wk7, $dst, LSL #1
                            LDR     $wk7, [map, $wk6, LSL #2]
                              AND     $wk6, $src0, #3
                                MOV     $src0, $src0, ROR #32-2
                            AND     $wk7, $wk7, #1
                            ORR     $dst, $wk7, $dst, LSL #1
                              LDR     $wk7, [map, $wk6, LSL #2]
                                AND     $wk6, $src0, #3
                                  MOV     $src0, $src0, ROR #32-2
                              AND     $wk7, $wk7, #1
                              ORR     $dst, $wk7, $dst, LSL #1
                                LDR     $wk7, [map, $wk6, LSL #2]
                                  AND     $wk6, $src0, #3
                                    MOV     $src0, $src0, ROR #32-2
                                AND     $wk7, $wk7, #1
                                ORR     $dst, $wk7, $dst, LSL #1
                                  LDR     $wk7, [map, $wk6, LSL #2]
                                    AND     $wk6, $src0, #3
                                      MOV     $src0, $src0, ROR #32-2
                                  AND     $wk7, $wk7, #1
                                  ORR     $dst, $wk7, $dst, LSL #1
                                    LDR     $wk7, [map, $wk6, LSL #2]
                                      AND     $wk6, $src0, #3
        MOV     $src1, $src1, ROR #32-2
                                    AND     $wk7, $wk7, #1
                                    ORR     $dst, $wk7, $dst, LSL #1
                                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #3
          MOV     $src1, $src1, ROR #32-2
                                      AND     $wk7, $wk7, #1
                                      ORR     $dst, $wk7, $dst, LSL #1
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #3
            MOV     $src1, $src1, ROR #32-2
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #3
              MOV     $src1, $src1, ROR #32-2
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #3
                MOV     $src1, $src1, ROR #32-2
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src1, #3
                  MOV     $src1, $src1, ROR #32-2
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src1, #3
                    MOV     $src1, $src1, ROR #32-2
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src1, #3
                      MOV     $src1, $src1, ROR #32-2
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src1, #3
                        MOV     $src1, $src1, ROR #32-2
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                        AND     $wk6, $src1, #3
                          MOV     $src1, $src1, ROR #32-2
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
                        LDR     $wk7, [map, $wk6, LSL #2]
                          AND     $wk6, $src1, #3
                            MOV     $src1, $src1, ROR #32-2
                        AND     $wk7, $wk7, #1
                        ORR     $dst, $wk7, $dst, LSL #1
                          LDR     $wk7, [map, $wk6, LSL #2]
                            AND     $wk6, $src1, #3
                              MOV     $src1, $src1, ROR #32-2
                          AND     $wk7, $wk7, #1
                          ORR     $dst, $wk7, $dst, LSL #1
                            LDR     $wk7, [map, $wk6, LSL #2]
                              AND     $wk6, $src1, #3
                                MOV     $src1, $src1, ROR #32-2
                            AND     $wk7, $wk7, #1
                            ORR     $dst, $wk7, $dst, LSL #1
                              LDR     $wk7, [map, $wk6, LSL #2]
                                AND     $wk6, $src1, #3
                                  MOV     $src1, $src1, ROR #32-2
                              AND     $wk7, $wk7, #1
                              ORR     $dst, $wk7, $dst, LSL #1
                                LDR     $wk7, [map, $wk6, LSL #2]
                                  AND     $wk6, $src1, #3
                                    MOV     $src1, $src1, ROR #32-2
                                AND     $wk7, $wk7, #1
                                ORR     $dst, $wk7, $dst, LSL #1
                                  LDR     $wk7, [map, $wk6, LSL #2]
                                    AND     $wk6, $src1, #3
                                      MOV     $src1, $src1, ROR #32-2
                                  AND     $wk7, $wk7, #1
                                  ORR     $dst, $wk7, $dst, LSL #1
                                    LDR     $wk7, [map, $wk6, LSL #2]
                                      AND     $wk6, $src1, #3
                                    AND     $wk7, $wk7, #1
                                    ORR     $dst, $wk7, $dst, LSL #1
                                      LDR     $wk7, [map, $wk6, LSL #2]
                                      AND     $wk7, $wk7, #1
                                      ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord2_1_32bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk2, $wk3, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord2_1_64bits $src, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk2, $wk3, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord2_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk4, $wk5, $wk0
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord2_1_32pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord2_1_128bits_tail $src
        SourceWord2_1_32pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 2, 1,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 3, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", bitptrs ;wk5

; ********************************************************************

        MACRO
        SourceWord4_2_2bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
        LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord4_2_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
          MOV     $src, $src, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&F
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord4_2_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
          MOV     $src, $src, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&F
            MOV     $src, $src, ROR #32-4
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src, #&F
              MOV     $src, $src, ROR #32-4
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src, #&F
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord4_2_16bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk6, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $wk0, #&F
            MOV     $wk0, $wk0, ROR #32-4
        AND     $wk7, $wk7, #3
        ORR     $wk1, $wk7, $wk1, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $wk0, #&F
              MOV     $wk0, $wk0, ROR #32-4
          AND     $wk7, $wk7, #3
          ORR     $wk1, $wk7, $wk1, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $wk0, #&F
                MOV     $wk0, $wk0, ROR #32-4
            AND     $wk7, $wk7, #3
            ORR     $wk1, $wk7, $wk1, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $wk0, #&F
                  MOV     $wk0, $wk0, ROR #32-4
              AND     $wk7, $wk7, #3
              ORR     $wk1, $wk7, $wk1, LSL #2
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $wk0, #&F
                    MOV     $wk0, $wk0, ROR #32-4
                AND     $wk7, $wk7, #3
                ORR     $wk1, $wk7, $wk1, LSL #2
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $wk0, #&F
                      MOV     $wk0, $wk0, ROR #32-4
                  AND     $wk7, $wk7, #3
                  ORR     $wk1, $wk7, $wk1, LSL #2
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $wk0, #&F
                    AND     $wk7, $wk7, #3
                    ORR     $wk1, $wk7, $wk1, LSL #2
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #3
                      ORR     $wk1, $wk7, $wk1, LSL #2
        MEND

        MACRO
        SourceWord4_2_16pixels $src0, $src1, $dst
        MOV     $src0, $src0, ROR #32-4
        AND     $wk6, $src0, #&F
          MOV     $src0, $src0, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&F
            MOV     $src0, $src0, ROR #32-4
        AND     $dst, $wk7, #3
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&F
              MOV     $src0, $src0, ROR #32-4
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&F
                MOV     $src0, $src0, ROR #32-4
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src0, #&F
                  MOV     $src0, $src0, ROR #32-4
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src0, #&F
                    MOV     $src0, $src0, ROR #32-4
                AND     $wk7, $wk7, #3
                ORR     $dst, $wk7, $dst, LSL #2
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src0, #&F
                      MOV     $src0, $src0, ROR #32-4
                  AND     $wk7, $wk7, #3
                  ORR     $dst, $wk7, $dst, LSL #2
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src0, #&F
        MOV     $src1, $src1, ROR #32-4
                    AND     $wk7, $wk7, #3
                    ORR     $dst, $wk7, $dst, LSL #2
                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&F
          MOV     $src1, $src1, ROR #32-4
                      AND     $wk7, $wk7, #3
                      ORR     $dst, $wk7, $dst, LSL #2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&F
            MOV     $src1, $src1, ROR #32-4
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&F
              MOV     $src1, $src1, ROR #32-4
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&F
                MOV     $src1, $src1, ROR #32-4
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src1, #&F
                  MOV     $src1, $src1, ROR #32-4
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src1, #&F
                    MOV     $src1, $src1, ROR #32-4
                AND     $wk7, $wk7, #3
                ORR     $dst, $wk7, $dst, LSL #2
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src1, #&F
                      MOV     $src1, $src1, ROR #32-4
                  AND     $wk7, $wk7, #3
                  ORR     $dst, $wk7, $dst, LSL #2
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src1, #&F
                    AND     $wk7, $wk7, #3
                    ORR     $dst, $wk7, $dst, LSL #2
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #3
                      ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord4_2_32bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk2, $wk3, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord4_2_64bits $src, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk2, $wk3, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord4_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk4, $wk5, $wk0
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_2_16pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord4_2_128bits_tail $src
        SourceWord4_2_16pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 2,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 3, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", bitptrs ;wk5

; ********************************************************************

        MACRO
        SourceWord8_4_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk6, $src, #&FF
        LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord8_4_8bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk6, $src, #&FF
          MOV     $src, $src, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&FF
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord8_4_16bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk6, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $wk0, #&FF
            MOV     $wk0, $wk0, ROR #32-8
        AND     $wk7, $wk7, #&F
        ORR     $wk1, $wk7, $wk1, LSL #4
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $wk0, #&FF
              MOV     $wk0, $wk0, ROR #32-8
          AND     $wk7, $wk7, #&F
          ORR     $wk1, $wk7, $wk1, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $wk0, #&FF
            AND     $wk7, $wk7, #&F
            ORR     $wk1, $wk7, $wk1, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #&F
              ORR     $wk1, $wk7, $wk1, LSL #4
        MEND

        MACRO
        SourceWord8_4_8pixels $src0, $src1, $dst
        MOV     $src0, $src0, ROR #32-8
        AND     $wk6, $src0, #&FF
          MOV     $src0, $src0, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&FF
            MOV     $src0, $src0, ROR #32-8
        AND     $dst, $wk7, #&F
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&FF
              MOV     $src0, $src0, ROR #32-8
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&FF
        MOV     $src1, $src1, ROR #32-8
            AND     $wk7, $wk7, #&F
            ORR     $dst, $wk7, $dst, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&FF
          MOV     $src1, $src1, ROR #32-8
              AND     $wk7, $wk7, #&F
              ORR     $dst, $wk7, $dst, LSL #4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&FF
            MOV     $src1, $src1, ROR #32-8
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&FF
              MOV     $src1, $src1, ROR #32-8
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&FF
            AND     $wk7, $wk7, #&F
            ORR     $dst, $wk7, $dst, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #&F
              ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord8_4_32bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk2, $wk3, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord8_4_64bits $src, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk2, $wk3, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord8_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk4, $wk5, $wk0
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_4_8pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord8_4_128bits_tail $src
        SourceWord8_4_8pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 4,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", skew ;wk5

; ********************************************************************

        MACRO
        SourceWord16_8_8bits $src, $dst, $fixed_skew
        MOV     $wk7, $src, LSR #16
        BIC     $wk6, $wk7, #&8000
        LDRB    $wk7, [map, $wk6, LSL #2]
        MOV     $src, $src, ROR #16 ; leave $src rotated to comply with tiny-case requirements
        ORR     $dst, $wk7, $dst, LSL #8
        MEND

        MACRO
        SourceWord16_8_16bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk7, $wk0, LSR #16
        BIC     $wk6, $wk7, #&8000
          BIC     $wk0, $wk0, $wk7, LSL #16
        LDRB    $wk7, [map, $wk6, LSL #2]
          BIC     $wk6, $wk0, #&8000
        ORR     $wk1, $wk7, $wk1, LSL #8
          LDRB    $wk7, [map, $wk6, LSL #2]
          ORR     $wk1, $wk7, $wk1, LSL #8
        MEND

        MACRO
        SourceWord16_8_4pixels $src0, $src1, $dst
        MOV     $wk7, $src0, LSR #16
        BIC     $wk6, $wk7, #&8000
          BIC     $src0, $src0, $wk7, LSL #16
        LDRB    $dst, [map, $wk6, LSL #2]
          BIC     $wk6, $src0, #&8000
            MOV     $src0, $src1, LSR #16
          LDRB    $wk7, [map, $wk6, LSL #2]
            BIC     $wk6, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          ORR     $dst, $wk7, $dst, LSL #8
            LDRB    $wk7, [map, $wk6, LSL #2]
              BIC     $wk6, $src1, #&8000
            ORR     $dst, $wk7, $dst, LSL #8
              LDRB    $wk7, [map, $wk6, LSL #2]
              ORR     $dst, $wk7, $dst, LSL #8
        MEND

        MACRO
        SourceWord16_8_32bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk2, $wk3, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord16_8_64bits $src, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk2, $wk3, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk4, $wk5, $wk0
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_8_4pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord16_8_128bits_tail $src
        SourceWord16_8_4pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", skew ;wk5

; ********************************************************************

; Convert 1 32-bit to 16-bit pixel, results in LS bits of 1 register
        MACRO
        Convert32_16_1pixel $src, $dst, $gbits, $tmp
        AND     $dst, $gbits, $src, LSR #3   ; 00000000000RRRRR00000000000BBBBB
        AND     $tmp, $src, #&F800           ; 0000000000000000GGGGG00000000000
        ORR     $dst, $dst, $dst, LSR #6     ; 00000000000RRRRR0RRRRR00000BBBBB
        ORR     $dst, $dst, $tmp, LSR #6     ; 00000000000RRRRR0RRRRRGGGGGBBBBB
        TEQ     $src, #0
        BEQ     %FT00
        MOVS    $tmp, $dst, LSL #16
        MOVEQ   $dst, #1
00
        MEND

; Convert 2 32-bit to 16-bit pixels, results in MS bits of 2 registers
        MACRO
        Convert32_16_2pixels $src0, $src1, $dst0, $dst1, $gbits, $tmp
        AND     $tmp, $gbits, $src1, LSR #3  ; 00000000000rrrrr00000000000bbbbb
        AND     $dst1, $src1, #&F800         ; 0000000000000000ggggg00000000000
        ORR     $tmp, $tmp, $tmp, LSR #6     ; 00000000000rrrrr0rrrrr00000bbbbb
        ORR     $dst1, $tmp, $dst1, LSR #6   ; 00000000000rrrrr0rrrrrgggggbbbbb
        AND     $tmp, $gbits, $src0, LSR #3  ; 00000000000RRRRR00000000000BBBBB
        AND     $dst0, $src0, #&F800         ; 0000000000000000GGGGG00000000000
        ORR     $tmp, $tmp, $tmp, LSR #6     ; 00000000000RRRRR0RRRRR00000BBBBB
        ORR     $dst0, $tmp, $dst0, LSR #6   ; 00000000000RRRRR0RRRRRGGGGGBBBBB
        MOVS    $dst1, $dst1, LSL #16        ; 0rrrrrgggggbbbbb0000000000000000
        BNE     %FT00
        TEQ     $src1, #0
        MOVNE   $dst1, #&10000
00      MOVS    $dst0, $dst0, LSL #16        ; 0RRRRRGGGGGBBBBB0000000000000000
        BNE     %FT00
        TEQ     $src0, #0
        MOVNE   $dst0, #&10000
00
        MEND

        MACRO
        SourceWord32_16_init
        LDR     ht, =&001F001F
      [ DebugData
        B       %FT00
        LTORG
00
      ]
        MEND

        MACRO
        SourceWord32_16_1pixel $src, $dst, $tmp
        Convert32_16_1pixel $src, $dst, ht, $tmp
        ; STRH will ignore the upper bits of $dst
        MEND

        MACRO
        SourceWord32_16_2pixels $src0, $src1, $dst, $tmp0, $tmp1
        Convert32_16_2pixels $src0, $src1, $tmp0, $tmp1, ht, $dst
        ORR     $dst, $tmp0, $tmp1, LSR #16  ; 0RRRRRGGGGGBBBBB0rrrrrgggggbbbbb
        MEND

        MACRO
        SourceWord32_16_16bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_16_1pixel $wk0, $wk1, $wk2
        MEND

        MACRO
        SourceWord32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk2, $wk3, $wk0, $wk6, $wk7
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_16_64bits $src, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk2, $wk3, $wk0, $wk6, $wk7
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk2, $wk3, $wk1, $wk6, $wk7
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk4, $wk5, $wk0, $wk6, $wk7
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk4, $wk5, $wk1, $wk6, $wk7
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_16_2pixels $wk4, $wk5, $wk2, $wk6, $wk7
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord32_16_128bits_tail $src
        SourceWord32_16_2pixels $wk4, $wk5, $wk3, $wk6, $wk7
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 16,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_d,stride_s,ht_info,map,bitptrs,skew,orig_w,scratch", \
  "x,stride_d,stride_s", skew,, init ;wk5

; ********************************************************************

        MACRO
        SourceWord4_1_1bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
        LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord4_1_2bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
          MOV     $src, $src, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&F
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord4_1_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-4
        AND     $wk6, $src, #&F
          MOV     $src, $src, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&F
            MOV     $src, $src, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src, #&F
              MOV     $src, $src, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src, #&F
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord4_1_8bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-4
        AND     $wk6, $wk0, #&F
          MOV     $wk0, $wk0, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $wk0, #&F
            MOV     $wk0, $wk0, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $wk1, $wk7, $wk1, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $wk0, #&F
              MOV     $wk0, $wk0, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $wk1, $wk7, $wk1, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $wk0, #&F
                MOV     $wk0, $wk0, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $wk1, $wk7, $wk1, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $wk0, #&F
                  MOV     $wk0, $wk0, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $wk1, $wk7, $wk1, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $wk0, #&F
                    MOV     $wk0, $wk0, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $wk1, $wk7, $wk1, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $wk0, #&F
                      MOV     $wk0, $wk0, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $wk1, $wk7, $wk1, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $wk0, #&F
                    AND     $wk7, $wk7, #1
                    ORR     $wk1, $wk7, $wk1, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #1
                      ORR     $wk1, $wk7, $wk1, LSL #1
        MEND

        MACRO
        SourceWord4_1_16pixels $src0, $src1, $dst, $first_pixel
        MOV     $src0, $src0, ROR #32-4
        AND     $wk6, $src0, #&F
          MOV     $src0, $src0, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&F
            MOV     $src0, $src0, ROR #32-4
      [ "$first_pixel" <> ""
        AND     $dst, $wk7, #1
      |
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
      ]
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&F
              MOV     $src0, $src0, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&F
                MOV     $src0, $src0, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src0, #&F
                  MOV     $src0, $src0, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src0, #&F
                    MOV     $src0, $src0, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src0, #&F
                      MOV     $src0, $src0, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src0, #&F
        MOV     $src1, $src1, ROR #32-4
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&F
          MOV     $src1, $src1, ROR #32-4
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&F
            MOV     $src1, $src1, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&F
              MOV     $src1, $src1, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&F
                MOV     $src1, $src1, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src1, #&F
                  MOV     $src1, $src1, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src1, #&F
                    MOV     $src1, $src1, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src1, #&F
                      MOV     $src1, $src1, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src1, #&F
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord4_1_32pixels $src0, $src1, $src2, $src3, $dst
        MOV     $src0, $src0, ROR #32-4
        AND     $wk6, $src0, #&F
          MOV     $src0, $src0, ROR #32-4
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&F
            MOV     $src0, $src0, ROR #32-4
        AND     $dst, $wk7, #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&F
              MOV     $src0, $src0, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&F
                MOV     $src0, $src0, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src0, #&F
                  MOV     $src0, $src0, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src0, #&F
                    MOV     $src0, $src0, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src0, #&F
                      MOV     $src0, $src0, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src0, #&F
        MOV     $src1, $src1, ROR #32-4
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&F
          MOV     $src1, $src1, ROR #32-4
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&F
            MOV     $src1, $src1, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&F
              MOV     $src1, $src1, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&F
                MOV     $src1, $src1, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src1, #&F
                  MOV     $src1, $src1, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src1, #&F
                    MOV     $src1, $src1, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src1, #&F
                      MOV     $src1, $src1, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src1, #&F
        MOV     $src2, $src2, ROR #32-4
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src2, #&F
          MOV     $src2, $src2, ROR #32-4
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src2, #&F
            MOV     $src2, $src2, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src2, #&F
              MOV     $src2, $src2, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src2, #&F
                MOV     $src2, $src2, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src2, #&F
                  MOV     $src2, $src2, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src2, #&F
                    MOV     $src2, $src2, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src2, #&F
                      MOV     $src2, $src2, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src2, #&F
        MOV     $src3, $src3, ROR #32-4
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src3, #&F
          MOV     $src3, $src3, ROR #32-4
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src3, #&F
            MOV     $src3, $src3, ROR #32-4
        AND     $wk7, $wk7, #1
        ORR     $dst, $wk7, $dst, LSL #1
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src3, #&F
              MOV     $src3, $src3, ROR #32-4
          AND     $wk7, $wk7, #1
          ORR     $dst, $wk7, $dst, LSL #1
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src3, #&F
                MOV     $src3, $src3, ROR #32-4
            AND     $wk7, $wk7, #1
            ORR     $dst, $wk7, $dst, LSL #1
              LDR     $wk7, [map, $wk6, LSL #2]
                AND     $wk6, $src3, #&F
                  MOV     $src3, $src3, ROR #32-4
              AND     $wk7, $wk7, #1
              ORR     $dst, $wk7, $dst, LSL #1
                LDR     $wk7, [map, $wk6, LSL #2]
                  AND     $wk6, $src3, #&F
                    MOV     $src3, $src3, ROR #32-4
                AND     $wk7, $wk7, #1
                ORR     $dst, $wk7, $dst, LSL #1
                  LDR     $wk7, [map, $wk6, LSL #2]
                    AND     $wk6, $src3, #&F
                      MOV     $src3, $src3, ROR #32-4
                  AND     $wk7, $wk7, #1
                  ORR     $dst, $wk7, $dst, LSL #1
                    LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk6, $src3, #&F
                    AND     $wk7, $wk7, #1
                    ORR     $dst, $wk7, $dst, LSL #1
                      LDR     $wk7, [map, $wk6, LSL #2]
                      AND     $wk7, $wk7, #1
                      ORR     $dst, $wk7, $dst, LSL #1
        MEND

        MACRO
        SourceWord4_1_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord4_1_16pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord4_1_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_32pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord4_1_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_32pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_16pixels $wk2, $wk3, $wk1, first_pixel
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_16pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord4_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_32pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord4_1_32pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_16pixels $wk4, $wk5, $wk2, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_16pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord4_1_16pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord4_1_128bits_tail $src
        SourceWord4_1_16pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 4, 1,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW, 2, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", bitptrs ;wk5

; ********************************************************************

        MACRO
        SourceWord8_2_2bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk6, $src, #&FF
        LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord8_2_4bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk6, $src, #&FF
          MOV     $src, $src, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src, #&FF
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord8_2_8bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk6, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $wk0, #&FF
            MOV     $wk0, $wk0, ROR #32-8
        AND     $wk7, $wk7, #3
        ORR     $wk1, $wk7, $wk1, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $wk0, #&FF
              MOV     $wk0, $wk0, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $wk1, $wk7, $wk1, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $wk0, #&FF
            AND     $wk7, $wk7, #3
            ORR     $wk1, $wk7, $wk1, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #3
              ORR     $wk1, $wk7, $wk1, LSL #2
        MEND

        MACRO
        SourceWord8_2_8pixels $src0, $src1, $dst, $first_pixel
        MOV     $src0, $src0, ROR #32-8
        AND     $wk6, $src0, #&FF
          MOV     $src0, $src0, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&FF
            MOV     $src0, $src0, ROR #32-8
      [ "$first_pixel" <> ""
        AND     $dst, $wk7, #3
      |
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
      ]
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&FF
              MOV     $src0, $src0, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&FF
        MOV     $src1, $src1, ROR #32-8
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&FF
          MOV     $src1, $src1, ROR #32-8
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&FF
            MOV     $src1, $src1, ROR #32-8
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&FF
              MOV     $src1, $src1, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&FF
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord8_2_16pixels $src0, $src1, $src2, $src3, $dst
        MOV     $src0, $src0, ROR #32-8
        AND     $wk6, $src0, #&FF
          MOV     $src0, $src0, ROR #32-8
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src0, #&FF
            MOV     $src0, $src0, ROR #32-8
        AND     $dst, $wk7, #3
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src0, #&FF
              MOV     $src0, $src0, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src0, #&FF
        MOV     $src1, $src1, ROR #32-8
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src1, #&FF
          MOV     $src1, $src1, ROR #32-8
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src1, #&FF
            MOV     $src1, $src1, ROR #32-8
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src1, #&FF
              MOV     $src1, $src1, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src1, #&FF
        MOV     $src2, $src2, ROR #32-8
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src2, #&FF
          MOV     $src2, $src2, ROR #32-8
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src2, #&FF
            MOV     $src2, $src2, ROR #32-8
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src2, #&FF
              MOV     $src2, $src2, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src2, #&FF
        MOV     $src3, $src3, ROR #32-8
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
        AND     $wk6, $src3, #&FF
          MOV     $src3, $src3, ROR #32-8
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk6, $src3, #&FF
            MOV     $src3, $src3, ROR #32-8
        AND     $wk7, $wk7, #3
        ORR     $dst, $wk7, $dst, LSL #2
          LDR     $wk7, [map, $wk6, LSL #2]
            AND     $wk6, $src3, #&FF
              MOV     $src3, $src3, ROR #32-8
          AND     $wk7, $wk7, #3
          ORR     $dst, $wk7, $dst, LSL #2
            LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk6, $src3, #&FF
            AND     $wk7, $wk7, #3
            ORR     $dst, $wk7, $dst, LSL #2
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #3
              ORR     $dst, $wk7, $dst, LSL #2
        MEND

        MACRO
        SourceWord8_2_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord8_2_8pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord8_2_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_16pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord8_2_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_16pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_8pixels $wk2, $wk3, $wk1, first_pixel
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_8pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord8_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_16pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord8_2_16pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_8pixels $wk4, $wk5, $wk2, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_8pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord8_2_8pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord8_2_128bits_tail $src
        SourceWord8_2_8pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 2,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", skew ;wk5

; ********************************************************************

        MACRO
        SourceWord16_4_4bits $src, $dst, $fixed_skew
        MOV     $wk7, $src, LSR #16
        BIC     $wk6, $wk7, #&8000
        LDR     $wk7, [map, $wk6, LSL #2]
        MOV     $src, $src, ROR #16 ; leave $src rotated to comply with tiny-case requirements
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord16_4_8bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        MOV     $wk7, $wk0, LSR #16
        BIC     $wk6, $wk7, #&8000
          BIC     $wk0, $wk0, $wk7, LSL #16
        LDR     $wk7, [map, $wk6, LSL #2]
          BIC     $wk6, $wk0, #&8000
        AND     $wk7, $wk7, #&F
        ORR     $wk1, $wk7, $wk1, LSL #4
          LDR     $wk7, [map, $wk6, LSL #2]
          AND     $wk7, $wk7, #&F
          ORR     $wk1, $wk7, $wk1, LSL #4
        MEND

        MACRO
        SourceWord16_4_4pixels $src0, $src1, $dst, $first_pixel
        MOV     $wk7, $src0, LSR #16
        BIC     $wk6, $wk7, #&8000
          BIC     $src0, $src0, $wk7, LSL #16
        LDR     $wk7, [map, $wk6, LSL #2]
          BIC     $wk6, $src0, #&8000
            MOV     $src0, $src1, LSR #16
      [ "$first_pixel" <> ""
        AND     $dst, $wk7, #&F
      |
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
      ]
          LDR     $wk7, [map, $wk6, LSL #2]
            BIC     $wk6, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              BIC     $wk6, $src1, #&8000
            AND     $wk7, $wk7, #&F
            ORR     $dst, $wk7, $dst, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #&F
              ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord16_4_8pixels $src0, $src1, $src2, $src3, $dst
        MOV     $wk7, $src0, LSR #16
        BIC     $wk6, $wk7, #&8000
          BIC     $src0, $src0, $wk7, LSL #16
        LDR     $wk7, [map, $wk6, LSL #2]
          BIC     $wk6, $src0, #&8000
            MOV     $src0, $src1, LSR #16
        AND     $dst, $wk7, #&F
          LDR     $wk7, [map, $wk6, LSL #2]
            BIC     $wk6, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              BIC     $wk6, $src1, #&8000
        MOV     $src0, $src2, LSR #16
            AND     $wk7, $wk7, #&F
            ORR     $dst, $wk7, $dst, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
        BIC     $wk6, $src0, #&8000
          BIC     $src2, $src2, $src0, LSL #16
              AND     $wk7, $wk7, #&F
              ORR     $dst, $wk7, $dst, LSL #4
        LDR     $wk7, [map, $wk6, LSL #2]
          BIC     $wk6, $src2, #&8000
            MOV     $src0, $src3, LSR #16
        AND     $wk7, $wk7, #&F
        ORR     $dst, $wk7, $dst, LSL #4
          LDR     $wk7, [map, $wk6, LSL #2]
            BIC     $wk6, $src0, #&8000
              BIC     $src3, $src3, $src0, LSL #16
          AND     $wk7, $wk7, #&F
          ORR     $dst, $wk7, $dst, LSL #4
            LDR     $wk7, [map, $wk6, LSL #2]
              BIC     $wk6, $src3, #&8000
            AND     $wk7, $wk7, #&F
            ORR     $dst, $wk7, $dst, LSL #4
              LDR     $wk7, [map, $wk6, LSL #2]
              AND     $wk7, $wk7, #&F
              ORR     $dst, $wk7, $dst, LSL #4
        MEND

        MACRO
        SourceWord16_4_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord16_4_4pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord16_4_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_8pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord16_4_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_8pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_4pixels $wk2, $wk3, $wk1, first_pixel
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_4pixels $wk2, $wk3, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_4_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_4pixels $wk4, $wk5, $wk2, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_4pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord16_4_4pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord16_4_128bits_tail $src
        SourceWord16_4_4pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 4,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", skew ;wk5

; ********************************************************************

        MACRO
        SourceWord32_8_init
        LDR     ht, =&001F001F
      [ DebugData
        B       %FT00
        LTORG
00
      ]
        MEND

        MACRO
        SourceWord32_8_8bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        Convert32_16_1pixel $wk0, $wk6, ht, $wk8
        UXTH    $wk6, $wk6
        LDRB    $wk6, [map, $wk6, LSL #2]
        ORR     $wk1, $wk6, $wk1, LSL #8
        MEND

        MACRO
        SourceWord32_8_2pixels $src0, $src1, $dst, $first_pixel
        Convert32_16_2pixels $src0, $src1, $wk6, $wk7, ht, $wk8
        LDRB    $wk6, [map, $wk6, LSR #16-2]
        LDRB    $wk7, [map, $wk7, LSR #16-2]
      [ "$first_pixel" <> ""
        ORR     $dst, $wk7, $wk6, LSL #8
      |
        ORR     $wk6, $wk7, $wk6, LSL #8
        ORR     $dst, $wk6, $dst, LSL #16
      ]
        MEND

        MACRO
        SourceWord32_8_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_8_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_8_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_8_2pixels $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_8_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_8_2pixels $wk3, $wk4, $wk0
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk3, $wk4, $wk1, first_pixel
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk3, $wk4, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk2, $wk3, $wk0, first_pixel
        SourceWord32_8_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_8_2pixels $wk2, $wk3, $wk1, first_pixel
        SourceWord32_8_2pixels $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk2, $wk3, $wk2, first_pixel
        SourceWord32_8_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_8_2pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord32_8_128bits_tail $src
        SourceWord32_8_2pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "y,stride_d,stride_s,ht_info,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", skew,, init ;leading_pixels_reg=wk5

; ********************************************************************

        MACRO
        SourceWord8_1_1bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk7, $src, #&FF
        LDR     $wk8, [map, $wk7, LSL #2]
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord8_1_2bits $src, $dst, $fixed_skew
        MOV     $src, $src, ROR #32-8
        AND     $wk7, $src, #&FF
          MOV     $src, $src, ROR #32-8
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src, #&FF
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord8_1_4bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        MOV     $wk0, $wk0, ROR #32-8
        AND     $wk7, $wk0, #&FF
          MOV     $wk0, $wk0, ROR #32-8
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $wk0, #&FF
            MOV     $wk0, $wk0, ROR #32-8
        AND     $wk8, $wk8, #1
        ORR     $wk1, $wk8, $wk1, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $wk0, #&FF
              MOV     $wk0, $wk0, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $wk1, $wk8, $wk1, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $wk0, #&FF
            AND     $wk8, $wk8, #1
            ORR     $wk1, $wk8, $wk1, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #1
              ORR     $wk1, $wk8, $wk1, LSL #1
        MEND

        MACRO
        SourceWord8_1_8pixels $src0, $src1, $dst, $first_pixel
        MOV     $src0, $src0, ROR #32-8
        AND     $wk7, $src0, #&FF
          MOV     $src0, $src0, ROR #32-8
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src0, #&FF
            MOV     $src0, $src0, ROR #32-8
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #1
      |
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src0, #&FF
              MOV     $src0, $src0, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src0, #&FF
        MOV     $src1, $src1, ROR #32-8
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
        AND     $wk7, $src1, #&FF
          MOV     $src1, $src1, ROR #32-8
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src1, #&FF
            MOV     $src1, $src1, ROR #32-8
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src1, #&FF
              MOV     $src1, $src1, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src1, #&FF
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord8_1_16pixels $src0, $src1, $src2, $src3, $dst, $first_pixel
        MOV     $src0, $src0, ROR #32-8
        AND     $wk7, $src0, #&FF
          MOV     $src0, $src0, ROR #32-8
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src0, #&FF
            MOV     $src0, $src0, ROR #32-8
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #1
      |
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src0, #&FF
              MOV     $src0, $src0, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src0, #&FF
        MOV     $src1, $src1, ROR #32-8
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
        AND     $wk7, $src1, #&FF
          MOV     $src1, $src1, ROR #32-8
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src1, #&FF
            MOV     $src1, $src1, ROR #32-8
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src1, #&FF
              MOV     $src1, $src1, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src1, #&FF
        MOV     $src2, $src2, ROR #32-8
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
        AND     $wk7, $src2, #&FF
          MOV     $src2, $src2, ROR #32-8
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src2, #&FF
            MOV     $src2, $src2, ROR #32-8
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src2, #&FF
              MOV     $src2, $src2, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src2, #&FF
        MOV     $src3, $src3, ROR #32-8
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
        AND     $wk7, $src3, #&FF
          MOV     $src3, $src3, ROR #32-8
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk7, $src3, #&FF
            MOV     $src3, $src3, ROR #32-8
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            AND     $wk7, $src3, #&FF
              MOV     $src3, $src3, ROR #32-8
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk7, $src3, #&FF
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord8_1_8bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord8_1_8pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord8_1_16bits $src, $dst, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord8_1_16pixels $wk2, $wk3, $wk4, $wk5, $wk1
        MEND

        MACRO
        SourceWord8_1_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk1, $wk2, $wk3, $wk4, $wk0, first_pixel
        Read4Words src, 1, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord8_1_64bits $src, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk2, $wk3, $wk4, $wk5, $wk0, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk2, $wk3, $wk4, $wk5, $wk1, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord8_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk0, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk0
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk1, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk2, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord8_1_16pixels $wk3, $wk4, $wk5, $wk6, $wk2
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_8pixels $wk5, $wk6, $wk3, first_pixel
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_8pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord8_1_8pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        MEND

        MACRO
        SourceWord8_1_128bits_tail $src
        SourceWord8_1_8pixels $wk5, $wk6, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 8, 1,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", skew ; leading_pixels_reg=wk6

; ********************************************************************

        MACRO
        SourceWord16_2_2bits $src, $dst, $fixed_skew
        MOV     $wk8, $src, LSR #16
        BIC     $wk7, $wk8, #&8000
        LDR     $wk8, [map, $wk7, LSL #2]
        MOV     $src, $src, ROR #16 ; leave $src rotated to comply with tiny-case requirements
        AND     $wk8, $wk8, #3
        ORR     $dst, $wk8, $dst, LSL #2
        MEND

        MACRO
        SourceWord16_2_4bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        MOV     $wk8, $wk0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $wk0, $wk0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $wk0, #&8000
        AND     $wk8, $wk8, #3
        ORR     $wk1, $wk8, $wk1, LSL #2
          LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk8, $wk8, #3
          ORR     $wk1, $wk8, $wk1, LSL #2
        MEND

        MACRO
        SourceWord16_2_4pixels $src0, $src1, $dst, $first_pixel
        MOV     $wk8, $src0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $src0, $src0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src0, #&8000
            MOV     $src0, $src1, LSR #16
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #3
      |
        AND     $wk8, $wk8, #3
        ORR     $dst, $wk8, $dst, LSL #2
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk8, $wk8, #3
          ORR     $dst, $wk8, $dst, LSL #2
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src1, #&8000
            AND     $wk8, $wk8, #3
            ORR     $dst, $wk8, $dst, LSL #2
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #3
              ORR     $dst, $wk8, $dst, LSL #2
        MEND

        MACRO
        SourceWord16_2_8pixels $src0, $src1, $src2, $src3, $dst, $first_pixel
        MOV     $wk8, $src0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $src0, $src0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src0, #&8000
            MOV     $src0, $src1, LSR #16
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #3
      |
        AND     $wk8, $wk8, #3
        ORR     $dst, $wk8, $dst, LSL #2
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk8, $wk8, #3
          ORR     $dst, $wk8, $dst, LSL #2
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src1, #&8000
        MOV     $src0, $src2, LSR #16
            AND     $wk8, $wk8, #3
            ORR     $dst, $wk8, $dst, LSL #2
              LDR     $wk8, [map, $wk7, LSL #2]
        BIC     $wk7, $src0, #&8000
          BIC     $src2, $src2, $src0, LSL #16
              AND     $wk8, $wk8, #3
              ORR     $dst, $wk8, $dst, LSL #2
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src2, #&8000
            MOV     $src0, $src3, LSR #16
        AND     $wk8, $wk8, #3
        ORR     $dst, $wk8, $dst, LSL #2
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src3, $src3, $src0, LSL #16
          AND     $wk8, $wk8, #3
          ORR     $dst, $wk8, $dst, LSL #2
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src3, #&8000
            AND     $wk8, $wk8, #3
            ORR     $dst, $wk8, $dst, LSL #2
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #3
              ORR     $dst, $wk8, $dst, LSL #2
        MEND

        MACRO
        SourceWord16_2_8bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord16_2_4pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord16_2_16bits $src, $dst, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord16_2_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        MEND

        MACRO
        SourceWord16_2_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk1, $wk2, $wk3, $wk4, $wk0, first_pixel
        Read4Words src, 1, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk1, $wk2, $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord16_2_64bits $src, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk2, $wk3, $wk4, $wk5, $wk0, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk2, $wk3, $wk4, $wk5, $wk1, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk0, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk0
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk1, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk2, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_2_8pixels $wk3, $wk4, $wk5, $wk6, $wk2
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_4pixels $wk5, $wk6, $wk3, first_pixel
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_2_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        MEND

        MACRO
        SourceWord16_2_128bits_tail $src
        SourceWord16_2_4pixels $wk5, $wk6, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 2,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", skew ; leading_pixels_reg=wk6

; ********************************************************************

        MACRO
        SourceWord32_4_init
        LDR     ht, =&001F001F
        B       %FT00
        LTORG
00
        MEND

        MACRO
        SourceWord32_4_4bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        Convert32_16_1pixel $wk0, $wk6, ht, $wk8
        UXTH    $wk6, $wk6
        LDR     $wk6, [map, $wk6, LSL #2]
        AND     $wk6, $wk6, #&F
        ORR     $wk1, $wk6, $wk1, LSL #4
        MEND

        MACRO
        SourceWord32_4_2pixels $src0, $src1, $dst, $first_pixel
        Convert32_16_2pixels $src0, $src1, $wk6, $wk7, ht, $wk8
        LDR     $wk6, [map, $wk6, LSR #16-2]
        LDR     $wk7, [map, $wk7, LSR #16-2]
        AND     $wk6, $wk6, #&F
        AND     $wk7, $wk7, #&F
      [ "$first_pixel" <> ""
        ORR     $dst, $wk7, $wk6, LSL #4
      |
        ORR     $wk6, $wk7, $wk6, LSL #4
        ORR     $dst, $wk6, $dst, LSL #8
      ]
        MEND

        MACRO
        SourceWord32_4_8bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_4_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_4_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_4_2pixels $wk2, $wk3, $wk1
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_4_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_4_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk1, $wk2, $wk0
        SourceWord32_4_2pixels $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_4_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_4_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk1, $wk2, $wk0
        SourceWord32_4_2pixels $wk3, $wk4, $wk0
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk3, $wk4, $wk1, first_pixel
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk3, $wk4, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk2, $wk3, $wk0, first_pixel
        SourceWord32_4_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_4_2pixels $wk2, $wk3, $wk0
        SourceWord32_4_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk2, $wk3, $wk1, first_pixel
        SourceWord32_4_2pixels $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_4_2pixels $wk2, $wk3, $wk1
        SourceWord32_4_2pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk2, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_4_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_4_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord32_4_128bits_tail $src
        SourceWord32_4_2pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 4,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "y,stride_d,stride_s,ht_info,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s,bitptrs", skew,, init ;leading_pixels_reg=wk5

; ********************************************************************

        MACRO
        SourceWord16_1_1bits $src, $dst, $fixed_skew
        MOV     $wk8, $src, LSR #16
        BIC     $wk7, $wk8, #&8000
        LDR     $wk8, [map, $wk7, LSL #2]
        MOV     $src, $src, ROR #16 ; leave $src rotated to comply with tiny-case requirements
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord16_1_2bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        MOV     $wk8, $wk0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $wk0, $wk0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $wk0, #&8000
        AND     $wk8, $wk8, #1
        ORR     $wk1, $wk8, $wk1, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
          AND     $wk8, $wk8, #1
          ORR     $wk1, $wk8, $wk1, LSL #1
        MEND

        MACRO
        SourceWord16_1_4pixels $src0, $src1, $dst, $first_pixel
        MOV     $wk8, $src0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $src0, $src0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src0, #&8000
            MOV     $src0, $src1, LSR #16
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #1
      |
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src1, #&8000
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord16_1_8pixels $src0, $src1, $src2, $src3, $dst, $first_pixel
        MOV     $wk8, $src0, LSR #16
        BIC     $wk7, $wk8, #&8000
          BIC     $src0, $src0, $wk8, LSL #16
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src0, #&8000
            MOV     $src0, $src1, LSR #16
      [ "$first_pixel" <> ""
        AND     $dst, $wk8, #1
      |
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
      ]
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src1, $src1, $src0, LSL #16
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src1, #&8000
        MOV     $src0, $src2, LSR #16
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
        BIC     $wk7, $src0, #&8000
          BIC     $src2, $src2, $src0, LSL #16
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        LDR     $wk8, [map, $wk7, LSL #2]
          BIC     $wk7, $src2, #&8000
            MOV     $src0, $src3, LSR #16
        AND     $wk8, $wk8, #1
        ORR     $dst, $wk8, $dst, LSL #1
          LDR     $wk8, [map, $wk7, LSL #2]
            BIC     $wk7, $src0, #&8000
              BIC     $src3, $src3, $src0, LSL #16
          AND     $wk8, $wk8, #1
          ORR     $dst, $wk8, $dst, LSL #1
            LDR     $wk8, [map, $wk7, LSL #2]
              BIC     $wk7, $src3, #&8000
            AND     $wk8, $wk8, #1
            ORR     $dst, $wk8, $dst, LSL #1
              LDR     $wk8, [map, $wk7, LSL #2]
              AND     $wk8, $wk8, #1
              ORR     $dst, $wk8, $dst, LSL #1
        MEND

        MACRO
        SourceWord16_1_4bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord16_1_4pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord16_1_8bits $src, $dst, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        MEND

        MACRO
        SourceWord16_1_16bits $src, $dst, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        ASSERT  $dst = $wk1
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        MEND

        MACRO
        SourceWord16_1_32bits $src, $dst, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord16_1_64bits $src, $fixed_skew
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1, first_pixel
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk2, $wk3, $wk4, $wk5, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord16_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk0, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk0
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk0
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk0
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk1, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk2, first_pixel
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk2
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk2
        Read4Words src, 3, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_8pixels $wk3, $wk4, $wk5, $wk6, $wk2
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3, first_pixel
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Read2Words src, 5, carry, $fixed_skew, skew, $wk7
        MEND

        MACRO
        SourceWord16_1_128bits_tail $src
        SourceWord16_1_4pixels $wk5, $wk6, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 16, 1,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,ht,ht_info,bitptrs,skew,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", skew ; leading_pixels_reg=wk6

; ********************************************************************

        MACRO
        SourceWord32_2_init
        LDR     ht, =&001F001F
        B       %FT00
        LTORG
00
        MEND

        MACRO
        SourceWord32_2_2bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        Convert32_16_1pixel $wk0, $wk6, ht, $wk8
        UXTH    $wk6, $wk6
        LDR     $wk6, [map, $wk6, LSL #2]
        AND     $wk6, $wk6, #3
        ORR     $wk1, $wk6, $wk1, LSL #2
        MEND

        MACRO
        SourceWord32_2_2pixels $src0, $src1, $dst, $first_pixel
        Convert32_16_2pixels $src0, $src1, $wk6, $wk7, ht, $wk8
        LDR     $wk6, [map, $wk6, LSR #16-2]
        LDR     $wk7, [map, $wk7, LSR #16-2]
        AND     $wk6, $wk6, #3
        AND     $wk7, $wk7, #3
      [ "$first_pixel" <> ""
        ORR     $dst, $wk7, $wk6, LSL #2
      |
        ORR     $wk6, $wk7, $wk6, LSL #2
        ORR     $dst, $wk6, $dst, LSL #4
      ]
        MEND

        MACRO
        SourceWord32_2_4bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_2_8bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_2_16bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_2_32bits $src, $dst, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_2_64bits $src, $fixed_skew
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk1, $wk2, $wk0
        SourceWord32_2_2pixels $wk3, $wk4, $wk0
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1, first_pixel
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk3, $wk4, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk0, first_pixel
        SourceWord32_2_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk2, $wk3, $wk0
        SourceWord32_2_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk0
        SourceWord32_2_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk2, $wk3, $wk0
        SourceWord32_2_2pixels $wk4, $wk5, $wk0
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1, first_pixel
        SourceWord32_2_2pixels $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        SourceWord32_2_2pixels $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        SourceWord32_2_2pixels $wk4, $wk5, $wk1
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk2, $wk3, $wk1
        SourceWord32_2_2pixels $wk4, $wk5, $wk1
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk4, $wk5, $wk2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3, first_pixel
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord32_2_128bits_tail $src
        SourceWord32_2_2pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 2,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,ht_info,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s,bitptrs", skew,, init ;leading_pixels_reg=wk5

; ********************************************************************

        MACRO
        SourceWord32_1_init
        LDR     ht, =&001F001F
        B       %FT00
        LTORG
00
        MEND

        MACRO
        SourceWord32_1_1bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        Convert32_16_1pixel $wk0, $wk6, ht, $wk8
        UXTH    $wk6, $wk6
        LDR     $wk6, [map, $wk6, LSL #2]
        AND     $wk6, $wk6, #1
        ORR     $wk1, $wk6, $wk1, LSL #1
        MEND

        MACRO
        SourceWord32_1_2pixels $src0, $src1, $dst, $first_pixel
        Convert32_16_2pixels $src0, $src1, $wk6, $wk7, ht, $wk8
        LDR     $wk6, [map, $wk6, LSR #16-2]
        LDR     $wk7, [map, $wk7, LSR #16-2]
        AND     $wk6, $wk6, #1
        AND     $wk7, $wk7, #1
      [ "$first_pixel" <> ""
        ORR     $dst, $wk7, $wk6, LSL #1
      |
        ORR     $wk6, $wk7, $wk6, LSL #1
        ORR     $dst, $wk6, $dst, LSL #2
      ]
        MEND

        MACRO
        SourceWord32_1_2bits $src, $dst, $fixed_skew
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        ASSERT  $dst = $wk1
        SourceWord32_1_2pixels $wk2, $wk3, $wk1
        MEND

        MACRO
        SourceWord32_1_4bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        LCLA    counter
counter SETA    0
        WHILE   counter < 4
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk2, $wk3, $wk1
counter SETA    counter + 2
        WEND
        MEND

        MACRO
        SourceWord32_1_8bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        LCLA    counter
counter SETA    0
        WHILE   counter < 8
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk2, $wk3, $wk1
counter SETA    counter + 2
        WEND
        MEND

        MACRO
        SourceWord32_1_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        LCLA    counter
counter SETA    0
        WHILE   counter < 16
        Read2Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk2, $wk3, $wk1
counter SETA    counter + 2
        WEND
        MEND

        MACRO
        SourceWord32_1_32bits $src, $dst, $fixed_skew
        LCLA    counter
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_1_2pixels $wk3, $wk4, $wk0
counter SETA    4
        WHILE   counter < 32
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk1, $wk2, $wk0
        SourceWord32_1_2pixels $wk3, $wk4, $wk0
counter SETA    counter + 4
        WEND
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord32_1_64bits $src, $fixed_skew
        LCLA    counter
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk1, $wk2, $wk0, first_pixel
        SourceWord32_1_2pixels $wk3, $wk4, $wk0
counter SETA    4
        WHILE   counter < 32
        Read4Words src, 1, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk1, $wk2, $wk0
        SourceWord32_1_2pixels $wk3, $wk4, $wk0
counter SETA    counter + 4
        WEND
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk3, $wk4, $wk1, first_pixel
counter SETA    2
        WHILE   counter < 32
        Read2Words src, 3, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk3, $wk4, $wk1
counter SETA    counter + 2
        WEND
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord32_1_128bits_head $src, $fixed_skew, $intra_preloads
        LCLA    counter
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk2, $wk3, $wk0, first_pixel
        SourceWord32_1_2pixels $wk4, $wk5, $wk0
counter SETA    4
        WHILE   counter < 32
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> "" :LAND: (counter + 4) :AND: 7 = 0
        PreloadMiddle
      ]
        SourceWord32_1_2pixels $wk2, $wk3, $wk0
        SourceWord32_1_2pixels $wk4, $wk5, $wk0
counter SETA    counter + 4
        WEND
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk2, $wk3, $wk1, first_pixel
        SourceWord32_1_2pixels $wk4, $wk5, $wk1
counter SETA    4
        WHILE   counter < 32
        Read4Words src, 2, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> "" :LAND: (counter + 4) :AND: 7 = 0
        PreloadMiddle
      ]
        SourceWord32_1_2pixels $wk2, $wk3, $wk1
        SourceWord32_1_2pixels $wk4, $wk5, $wk1
counter SETA    counter + 4
        WEND
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk4, $wk5, $wk2, first_pixel
counter SETA    2
        WHILE   counter < 32
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> "" :LAND: (counter + 4) :AND: 7 = 0
        PreloadMiddle
      ]
        SourceWord32_1_2pixels $wk4, $wk5, $wk2
counter SETA    counter + 2
        WEND
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        SourceWord32_1_2pixels $wk4, $wk5, $wk3, first_pixel
counter SETA    2
        WHILE   counter < 32 - 2
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
      [ "$intra_preloads" <> "" :LAND: (counter + 4) :AND: 7 = 0
        PreloadMiddle
      ]
        SourceWord32_1_2pixels $wk4, $wk5, $wk3
counter SETA    counter + 2
        WEND
        Read2Words src, 4, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        SourceWord32_1_128bits_tail $src
        SourceWord32_1_2pixels $wk4, $wk5, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 32, 1,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,ht_info,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s,bitptrs", skew,, init ;leading_pixels_reg=wk5

; ********************************************************************

        MACRO
        SourceWord0_1_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_1_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, #-1
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, #-1
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, #-1
      ]
        MEND

        MACRO
        SourceWord0_1_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_1_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_1_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_1_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 1,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_1_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_1_scalar_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, $wk3
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, $wk3
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, $wk3
      ]
        MEND

        MACRO
        SourceWord0_1_scalar_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_1_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_1_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_1_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 1, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_2_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_2_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, #-1
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, #-1
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, #-1
      ]
        MEND

        MACRO
        SourceWord0_2_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_2_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_2_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_2_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 2,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_2_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_2_scalar_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, $wk3
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, $wk3
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, $wk3
      ]
        MEND

        MACRO
        SourceWord0_2_scalar_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_2_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_2_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_2_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 2, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_4_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_4_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, #-1
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, #-1
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, #-1
      ]
        MEND

        MACRO
        SourceWord0_4_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_4_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_4_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_4_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 4,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_4_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_4_scalar_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, $wk3
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, $wk3
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, $wk3
      ]
        MEND

        MACRO
        SourceWord0_4_scalar_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_4_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_4_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_4_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 4, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_8_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_8_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, #-1
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, #-1
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, #-1
      ]
        MEND

        MACRO
        SourceWord0_8_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_8_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_8_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_8_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 8,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_8_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_8_scalar_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, $wk3
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, $wk3
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, $wk3
      ]
        MEND

        MACRO
        SourceWord0_8_scalar_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_8_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_8_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_8_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 8, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_16_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_16_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, #-1
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, #-1
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, #-1
      ]
        MEND

        MACRO
        SourceWord0_16_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_16_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_16_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_16_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 16,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_16_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_16_scalar_reinitwk $list
        LCLL    corrupted
corrupted RegIsInList $wk0, "$list"
      [ corrupted
        MOV     $wk0, $wk3
      ]
corrupted RegIsInList $wk1, "$list"
      [ corrupted
        MOV     $wk1, $wk3
      ]
corrupted RegIsInList $wk2, "$list"
      [ corrupted
        MOV     $wk2, $wk3
      ]
        MEND

        MACRO
        SourceWord0_16_scalar_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory" ; else requested a parallel sub-word, which is a no-op here
        Write1Word dst, 0
      ]
        MEND

        MACRO
        SourceWord0_16_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_16_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_16_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

SourceWord GenerateFunctions 0, 16, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init,, reinitwk \

; ********************************************************************

        MACRO
        SourceWord0_32_init
        MOV     $wk0, #-1
        MOV     $wk1, #-1
        MOV     $wk2, #-1
        MOV     $wk3, #-1
        MEND

        MACRO
        SourceWord0_32_32bits $src, $dst, $fixed_skew
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord0_32_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_32_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_32_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 0, 32,, \
  FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init \

; ********************************************************************

        MACRO
        SourceWord0_32_scalar_init
        ASSERT  ht = $wk2
        MOV     $wk0, ht
        MOV     $wk1, ht
        MOV     $wk3, ht
        MEND

        MACRO
        SourceWord0_32_scalar_32bits $src, $dst, $fixed_skew
        Write1Word dst, 0
        MEND

        MACRO
        SourceWord0_32_scalar_64bits $src, $fixed_skew
        Write2Words dst, 0
        MEND

        MACRO
        SourceWord0_32_scalar_128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        SourceWord0_32_scalar_128bits_tail $src
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

SourceWord GenerateFunctions 0, 32, _scalar, \
  FLAG_SCALAR_HALFTONE :OR: FLAG_DST_WRITEONLY :OR: FLAG_PROCESS_PARALLEL, 0, \
  "src,stride_s,ht,ht_info", "", map,, init \

; ********************************************************************

        END
