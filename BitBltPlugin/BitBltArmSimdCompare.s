;
; Copyright © 2014 Raspberry Pi Foundation
; Copyright © 2014 RISC OS Open Ltd
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

        AREA    |BitBltArmSimdCompare$$Code|, CODE, READONLY
        ARM

; We use the two halftone arguments/registers to hold the two comparison colours
; and the map register to hold the hit count.
; Source A is referenced by dst/stride_d.
; Source B is referenced by src/stride_s.

; ********************************************************************

        MACRO
        pixelMatchTally32_32_init
        MOV     map, #0
        MEND

        MACRO
        pixelMatchTally32_32_cleanup
        MOV     a1, map
        MEND

        MACRO
        pixelMatchTally32_32_1pixel $srcA, $srcB
        EOR     $srcA, $srcA, ht
        CLZ     $srcA, $srcA ; bit 5 set => all bits were 0
        TEQ     $srcB, ht_info
        ADDEQ   map, map, $srcA, LSR #5
        MEND

        MACRO
        pixelMatchTally32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        pixelMatchTally32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        pixelMatchTally32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTally32_32_1pixel $wk0, $wk2
        pixelMatchTally32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        pixelMatchTally32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTally32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        pixelMatchTally32_32_1pixel $wk0, $wk4
        pixelMatchTally32_32_1pixel $wk1, $wk5
        pixelMatchTally32_32_1pixel $wk2, $wk6
        pixelMatchTally32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTally GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        notAnotBTally32_32_init
        MOV     map, #0
        MEND

        MACRO
        notAnotBTally32_32_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAnotBTally32_32_1pixel $srcA, $srcB
        EORS    $srcA, $srcA, ht
        MOVNE   $srcA, #1
        TEQ     $srcB, ht_info
        ADDNE   map, map, $srcA
        MEND

        MACRO
        notAnotBTally32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAnotBTally32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        notAnotBTally32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTally32_32_1pixel $wk0, $wk2
        notAnotBTally32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        notAnotBTally32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTally32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        notAnotBTally32_32_1pixel $wk0, $wk4
        notAnotBTally32_32_1pixel $wk1, $wk5
        notAnotBTally32_32_1pixel $wk2, $wk6
        notAnotBTally32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTally GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        notAmatchBTally32_32_init
        MOV     map, #0
        MEND

        MACRO
        notAmatchBTally32_32_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAmatchBTally32_32_1pixel $srcA, $srcB
        EORS    $srcA, $srcA, ht
        MOVNE   $srcA, #1
        TEQ     $srcB, ht_info
        ADDEQ   map, map, $srcA
        MEND

        MACRO
        notAmatchBTally32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAmatchBTally32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        notAmatchBTally32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTally32_32_1pixel $wk0, $wk2
        notAmatchBTally32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        notAmatchBTally32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTally32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        notAmatchBTally32_32_1pixel $wk0, $wk4
        notAmatchBTally32_32_1pixel $wk1, $wk5
        notAmatchBTally32_32_1pixel $wk2, $wk6
        notAmatchBTally32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTally GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        pixelMatchTest32_32_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        pixelMatchTest32_32_1pixel $srcA, $srcB
        TEQ     $srcA, ht
        TEQEQ   $srcB, ht_info
        BEQ     %FA90
        MEND

        MACRO
        pixelMatchTest32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        pixelMatchTest32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        pixelMatchTest32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTest32_32_1pixel $wk0, $wk2
        pixelMatchTest32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        pixelMatchTest32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTest32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        pixelMatchTest32_32_1pixel $wk0, $wk4
        pixelMatchTest32_32_1pixel $wk1, $wk5
        pixelMatchTest32_32_1pixel $wk2, $wk6
        pixelMatchTest32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTest GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,,,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        notAnotBTest32_32_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAnotBTest32_32_1pixel $srcA, $srcB
        TEQ     $srcA, ht
        TEQNE   $srcB, ht_info
        BNE     %FA90
        MEND

        MACRO
        notAnotBTest32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAnotBTest32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        notAnotBTest32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTest32_32_1pixel $wk0, $wk2
        notAnotBTest32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        notAnotBTest32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTest32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        notAnotBTest32_32_1pixel $wk0, $wk4
        notAnotBTest32_32_1pixel $wk1, $wk5
        notAnotBTest32_32_1pixel $wk2, $wk6
        notAnotBTest32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTest GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,,,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        notAmatchBTest32_32_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAmatchBTest32_32_1pixel $srcA, $srcB
        TEQ     $srcB, ht_info
        MOVNE   $srcA, ht
        TEQ     $srcA, ht
        BNE     %FA90
        MEND

        MACRO
        notAmatchBTest32_32_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAmatchBTest32_32_1pixel $wk0, $wk1
        MEND

        MACRO
        notAmatchBTest32_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest32_32_1pixel $wk0, $wk2
        notAmatchBTest32_32_1pixel $wk1, $wk3
        MEND

        MACRO
        notAmatchBTest32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words dst, 0,, 0
        Read4Words src, 4, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTest32_32_128bits_tail $src
        LDR     scratch, [src, #-8] ; reload after it was (in many cases) corrupted by preload calculations
        notAmatchBTest32_32_1pixel $wk0, $wk4
        notAmatchBTest32_32_1pixel $wk1, $wk5
        notAmatchBTest32_32_1pixel $wk2, $wk6
        notAmatchBTest32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTest GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,,,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        MACRO
        pixelMatchTally16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        pixelMatchTally16_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        pixelMatchTally16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        pixelMatchTally16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        pixelMatchTally16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        pixelMatchTally16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        pixelMatchTally16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        pixelMatchTally16_16_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        pixelMatchTally16_16_1pixel $dst, $src, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        pixelMatchTally16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTally16_16_128bits_tail $src
        MOV     scratch, #0
        pixelMatchTally16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTally GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTally16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAnotBTally16_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAnotBTally16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        notAnotBTally16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAnotBTally16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAnotBTally16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAnotBTally16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAnotBTally16_16_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        notAnotBTally16_16_1pixel $dst, $src, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        notAnotBTally16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTally16_16_128bits_tail $src
        MOV     scratch, #0
        notAnotBTally16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTally GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTally16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAmatchBTally16_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAmatchBTally16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        notAmatchBTally16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAmatchBTally16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAmatchBTally16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAmatchBTally16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAmatchBTally16_16_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        notAmatchBTally16_16_1pixel $dst, $src, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        notAmatchBTally16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTally16_16_128bits_tail $src
        MOV     scratch, #0
        notAmatchBTally16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTally GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        pixelMatchTest16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        pixelMatchTest16_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        pixelMatchTest16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcA, $srcB
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        pixelMatchTest16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        pixelMatchTest16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        pixelMatchTest16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        pixelMatchTest16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        pixelMatchTest16_16_16bits $src, $dst, $fixed_skew
        pixelMatchTest16_16_1pixel $dst, $src, map, bitptrs
        MEND

        MACRO
        pixelMatchTest16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        pixelMatchTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        pixelMatchTest16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        pixelMatchTest16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        pixelMatchTest16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTest16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTest16_16_128bits_tail $src
        pixelMatchTest16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTest GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTest16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAnotBTest16_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAnotBTest16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
        AND     $srcA, $srcA, $srcB
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        notAnotBTest16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAnotBTest16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAnotBTest16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAnotBTest16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAnotBTest16_16_16bits $src, $dst, $fixed_skew
        notAnotBTest16_16_1pixel $dst, $src, map, bitptrs
        MEND

        MACRO
        notAnotBTest16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAnotBTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        notAnotBTest16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        notAnotBTest16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        notAnotBTest16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTest16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTest16_16_128bits_tail $src
        notAnotBTest16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTest GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTest16_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16     ; replicate the constant colours across words
        PKHBT   ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAmatchBTest16_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAmatchBTest16_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcA, $srcB
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        notAmatchBTest16_16_2pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAmatchBTest16_16_4pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAmatchBTest16_16_2pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAmatchBTest16_16_2pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAmatchBTest16_16_16bits $src, $dst, $fixed_skew
        notAmatchBTest16_16_1pixel $dst, $src, map, bitptrs
        MEND

        MACRO
        notAmatchBTest16_16_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAmatchBTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        notAmatchBTest16_16_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest16_16_2pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        notAmatchBTest16_16_2pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        notAmatchBTest16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest16_16_4pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTest16_16_128bits_tail $src
        notAmatchBTest16_16_4pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTest GenerateFunctions 16, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        pixelMatchTally32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        pixelMatchTally32_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        pixelMatchTally32_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcB, $srcB, ht_info
        CLZ     $srcB, $srcB
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        AND     $srcA, $srcA, $srcB, LSL #16-5
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        pixelMatchTally32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EOR     $srcB0, $srcB0, ht_info
        CLZ     $srcB0, $srcB0
        EOR     $srcB1, $srcB1, ht_info
        CLZ     $srcB1, $srcB1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB0, LSR #5
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB0, LSR #5
      |
        AND     $srcA, $srcA, $srcB0, LSR #5
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        pixelMatchTally32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally32_16_1pixel $wk1, $wk0, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        pixelMatchTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        pixelMatchTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        pixelMatchTally32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        pixelMatchTally32_16_128bits_tail $src
        MOV     scratch, #0
        pixelMatchTally32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTally GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTally32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAnotBTally32_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAnotBTally32_16_1pixel $srcA, $srcB, $zeros, $ones
        EORS    $srcB, $srcB, ht_info
        MOVNE   $srcB, #1
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        AND     $srcA, $srcA, $srcB, LSL #16
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        notAnotBTally32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EORS    $srcB0, $srcB0, ht_info
        MOVNE   $srcB0, #1
        EORS    $srcB1, $srcB1, ht_info
        MOVNE   $srcB1, #1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB0
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB0
      |
        AND     $srcA, $srcA, $srcB0
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAnotBTally32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally32_16_1pixel $wk1, $wk0, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAnotBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAnotBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAnotBTally32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        notAnotBTally32_16_128bits_tail $src
        MOV     scratch, #0
        notAnotBTally32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTally GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTally32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAmatchBTally32_16_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAmatchBTally32_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcB, $srcB, ht_info
        CLZ     $srcB, $srcB
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        AND     $srcA, $srcA, $srcB, LSL #16-5
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        notAmatchBTally32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EOR     $srcB0, $srcB0, ht_info
        CLZ     $srcB0, $srcB0
        EOR     $srcB1, $srcB1, ht_info
        CLZ     $srcB1, $srcB1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB0, LSR #5
        UXTAH   map, map, $srcA
        UXTAH   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB0, LSR #5
      |
        AND     $srcA, $srcA, $srcB0, LSR #5
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAmatchBTally32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally32_16_1pixel $wk1, $wk0, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAmatchBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAmatchBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTally32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MOV     scratch, #0
        notAmatchBTally32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTally32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        notAmatchBTally32_16_128bits_tail $src
        MOV     scratch, #0
        notAmatchBTally32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTally GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        pixelMatchTest32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        pixelMatchTest32_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        pixelMatchTest32_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcB, $srcB, ht_info
        CLZ     $srcB, $srcB
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        AND     $srcA, $srcA, $srcB, LSL #16-5
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        pixelMatchTest32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EOR     $srcB0, $srcB0, ht_info
        CLZ     $srcB0, $srcB0
        EOR     $srcB1, $srcB1, ht_info
        CLZ     $srcB1, $srcB1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB0, LSR #5
    |
      [ $first
        AND     $wk4, $srcA, $srcB0, LSR #5
      |
        AND     $srcA, $srcA, $srcB0, LSR #5
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        pixelMatchTest32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        pixelMatchTest32_16_1pixel $wk1, $wk0, map, bitptrs
        MEND

        MACRO
        pixelMatchTest32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        pixelMatchTest32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        pixelMatchTest32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        pixelMatchTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        pixelMatchTest32_16_128bits_tail $src
        pixelMatchTest32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTest GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTest32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAnotBTest32_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAnotBTest32_16_1pixel $srcA, $srcB, $zeros, $ones
        EORS    $srcB, $srcB, ht_info
        MOVNE   $srcB, #1
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        AND     $srcA, $srcA, $srcB, LSL #16
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        notAnotBTest32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EORS    $srcB0, $srcB0, ht_info
        MOVNE   $srcB0, #1
        EORS    $srcB1, $srcB1, ht_info
        MOVNE   $srcB1, #1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB0
    |
      [ $first
        AND     $wk4, $srcA, $srcB0
      |
        AND     $srcA, $srcA, $srcB0
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAnotBTest32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        notAnotBTest32_16_1pixel $wk1, $wk0, map, bitptrs
        MEND

        MACRO
        notAnotBTest32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        notAnotBTest32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        notAnotBTest32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAnotBTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        notAnotBTest32_16_128bits_tail $src
        notAnotBTest32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTest GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTest32_16_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht, ht, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAmatchBTest32_16_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAmatchBTest32_16_1pixel $srcA, $srcB, $zeros, $ones
        EOR     $srcB, $srcB, ht_info
        CLZ     $srcB, $srcB
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        AND     $srcA, $srcA, $srcB, LSL #16-5
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        notAmatchBTest32_16_2pixels $first, $last, $srcA, $srcB0, $srcB1, $zeros, $ones
        EOR     $srcB0, $srcB0, ht_info
        CLZ     $srcB0, $srcB0
        EOR     $srcB1, $srcB1, ht_info
        CLZ     $srcB1, $srcB1
        ORR     $srcB0, $srcB1, $srcB0, LSL #16
        EOR     $srcA, $srcA, ht
        USUB16  $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB0, LSR #5
    |
      [ $first
        AND     $wk4, $srcA, $srcB0, LSR #5
      |
        AND     $srcA, $srcA, $srcB0, LSR #5
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAmatchBTest32_16_16bits $src, $dst, $fixed_skew
        ASSERT  $dst = $wk1
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        notAmatchBTest32_16_1pixel $wk1, $wk0, map, bitptrs
        MEND

        MACRO
        notAmatchBTest32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        notAmatchBTest32_16_64bits $src, $fixed_skew
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        notAmatchBTest32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        notAmatchBTest32_16_2pixels {FALSE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words src, 1, carry, $fixed_skew, skew, scratch
        Read1Word dst, 0,, 0
        MEND

        MACRO
        notAmatchBTest32_16_128bits_tail $src
        notAmatchBTest32_16_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTest GenerateFunctions 32, 16,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTally16_32_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht_info, ht_info, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAmatchBTally16_32_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAmatchBTally16_32_1pixel $srcA, $srcB, $zeros, $ones
        EORS    $srcA, $srcA, ht
        MOVNE   $srcA, #1
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcB, $srcA, LSL #16
        UXTAH   map, map, $srcA, ROR #16
        MEND

        MACRO
        notAmatchBTally16_32_2pixels $first, $last, $srcA0, $srcA1, $srcB, $zeros, $ones
        EORS    $srcA0, $srcA0, ht
        MOVNE   $srcA0, #1
        EORS    $srcA1, $srcA1, ht
        MOVNE   $srcA1, #1
        ORR     $srcA0, $srcA1, $srcA0, LSL #16
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA0, $srcB, $srcA0
        UXTAH   map, map, $srcA0
        UXTAH   map, map, $srcA0, ROR #16
    |
      [ $first
        AND     $wk4, $srcB, $srcA0
      |
        AND     $srcA0, $srcB, $srcA0
        ADD     $wk4, $wk4, $srcA0
      ]
      [ $last
        UXTAH   map, map, $wk4
        UXTAH   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAmatchBTally16_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        Read1Word dst, 1,, 0
        MOV     scratch, #0
        notAmatchBTally16_32_1pixel $wk1, $wk0, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally16_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read1Word src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally16_32_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally16_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally16_32_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, scratch, bitptrs
        Read2Words dst, 0,, 0
        MEND

        MACRO
        notAmatchBTally16_32_128bits_tail $src
        MOV     scratch, #0
        notAmatchBTally16_32_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTally GenerateFunctions 16, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTest16_32_init
        LDR     bitptrs, =0x00010001
        MOV     map, #0
        PKHBT   ht_info, ht_info, LSL #16 ; replicate the constant 16bpp colour across word
        MEND

        MACRO
        notAmatchBTest16_32_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAmatchBTest16_32_1pixel $srcA, $srcB, $zeros, $ones
        EORS    $srcA, $srcA, ht
        MOVNE   $srcA, #1
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
        AND     $srcA, $srcB, $srcA, LSL #16
        TST     $srcA, #0x10000
        BNE     %FA90
        MEND

        MACRO
        notAmatchBTest16_32_2pixels $first, $last, $srcA0, $srcA1, $srcB, $zeros, $ones
        EORS    $srcA0, $srcA0, ht
        MOVNE   $srcA0, #1
        EORS    $srcA1, $srcA1, ht
        MOVNE   $srcA1, #1
        ORR     $srcA0, $srcA1, $srcA0, LSL #16
        EOR     $srcB, $srcB, ht_info
        USUB16  $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcB, $srcA0
    |
      [ $first
        AND     $wk4, $srcB, $srcA0
      |
        AND     $srcA0, $srcB, $srcA0
        ORRS    $wk4, $wk4, $srcA0
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAmatchBTest16_32_32bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        Read1Word dst, 1,, 0
        notAmatchBTest16_32_1pixel $wk1, $wk0, map, bitptrs
        MEND

        MACRO
        notAmatchBTest16_32_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read1Word src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest16_32_2pixels {TRUE}, {TRUE}, $wk0, $wk1, $wk2, map, bitptrs
        MEND

        MACRO
        notAmatchBTest16_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest16_32_2pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, map, bitptrs
        Read2Words dst, 0,, 0
        MEND

        MACRO
        notAmatchBTest16_32_128bits_tail $src
        notAmatchBTest16_32_2pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTest GenerateFunctions 16, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        pixelMatchTally8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        pixelMatchTally8_8_cleanup
        MOV     a1, map
        MEND

        MACRO
        pixelMatchTally8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $ones, $zeros
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        pixelMatchTally8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $ones, $zeros
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        UXTAB   map, map, $tmpA, ROR #16
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        pixelMatchTally8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        ADD     $srcA, $srcA, $srcA, ROR #8
        UXTAB   map, map, $srcA
        UXTAB   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        ADD     $wk4, $wk4, $wk4, ROR #8
        UXTAB   map, map, $wk4
        UXTAB   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        pixelMatchTally8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        pixelMatchTally8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        pixelMatchTally8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        pixelMatchTally8_8_8bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        pixelMatchTally8_8_1pixel $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        pixelMatchTally8_8_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        pixelMatchTally8_8_2pixels $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        pixelMatchTally8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        pixelMatchTally8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        pixelMatchTally8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        pixelMatchTally8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTally8_8_128bits_tail $src
        MOV     scratch, #0
        pixelMatchTally8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTally GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTally8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAnotBTally8_8_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAnotBTally8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $zeros, $ones
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        notAnotBTally8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $zeros, $ones
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        UXTAB   map, map, $tmpA, ROR #16
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        notAnotBTally8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        ADD     $srcA, $srcA, $srcA, ROR #8
        UXTAB   map, map, $srcA
        UXTAB   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        ADD     $wk4, $wk4, $wk4, ROR #8
        UXTAB   map, map, $wk4
        UXTAB   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAnotBTally8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAnotBTally8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAnotBTally8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAnotBTally8_8_8bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAnotBTally8_8_1pixel $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAnotBTally8_8_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAnotBTally8_8_2pixels $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAnotBTally8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        notAnotBTally8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        notAnotBTally8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAnotBTally8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTally8_8_128bits_tail $src
        MOV     scratch, #0
        notAnotBTally8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTally GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTally8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAmatchBTally8_8_cleanup
        MOV     a1, map
        MEND

        MACRO
        notAmatchBTally8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        notAmatchBTally8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        UXTAB   map, map, $tmpA, ROR #16
        UXTAB   map, map, $tmpA, ROR #24
        MEND

        MACRO
        notAmatchBTally8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        AND     $srcA, $srcA, $srcB
        ADD     $srcA, $srcA, $srcA, ROR #8
        UXTAB   map, map, $srcA
        UXTAB   map, map, $srcA, ROR #16
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ADD     $wk4, $wk4, $srcA
      ]
      [ $last
        ADD     $wk4, $wk4, $wk4, ROR #8
        UXTAB   map, map, $wk4
        UXTAB   map, map, $wk4, ROR #16
      ]
    ]
        MEND

        MACRO
        notAmatchBTally8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAmatchBTally8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAmatchBTally8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAmatchBTally8_8_8bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAmatchBTally8_8_1pixel $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAmatchBTally8_8_16bits $src, $dst, $fixed_skew
        MOV     scratch, #0
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAmatchBTally8_8_2pixels $dst, $src, scratch, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAmatchBTally8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, scratch, bitptrs
        notAmatchBTally8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, scratch, bitptrs
        MEND

        MACRO
        notAmatchBTally8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MOV     scratch, #0
        notAmatchBTally8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTally8_8_128bits_tail $src
        MOV     scratch, #0
        notAmatchBTally8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, scratch, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTally GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        pixelMatchTest8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        pixelMatchTest8_8_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        pixelMatchTest8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $ones, $zeros
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        MEND

        MACRO
        pixelMatchTest8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $ones, $zeros
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x10000
        TSTEQ   $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        MEND

        MACRO
        pixelMatchTest8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $ones, $zeros
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        pixelMatchTest8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        pixelMatchTest8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        pixelMatchTest8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        pixelMatchTest8_8_8bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        pixelMatchTest8_8_1pixel $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        pixelMatchTest8_8_16bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        pixelMatchTest8_8_2pixels $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        pixelMatchTest8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        pixelMatchTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        pixelMatchTest8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        pixelMatchTest8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        pixelMatchTest8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        pixelMatchTest8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        pixelMatchTest8_8_128bits_tail $src
        pixelMatchTest8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTest GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAnotBTest8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAnotBTest8_8_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAnotBTest8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $zeros, $ones
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        MEND

        MACRO
        notAnotBTest8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $zeros, $ones
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x10000
        TSTEQ   $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        MEND

        MACRO
        notAnotBTest8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $zeros, $ones
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAnotBTest8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAnotBTest8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAnotBTest8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAnotBTest8_8_8bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAnotBTest8_8_1pixel $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAnotBTest8_8_16bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAnotBTest8_8_2pixels $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAnotBTest8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAnotBTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        notAnotBTest8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        notAnotBTest8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        notAnotBTest8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAnotBTest8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAnotBTest8_8_128bits_tail $src
        notAnotBTest8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAnotBTest GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        notAmatchBTest8_8_init
        MOV     bitptrs, #0x0001
        ORR     bitptrs, bitptrs, #0x0100
        MOV     map, #0
        ORR     bitptrs, bitptrs, bitptrs, ROR #16 ; bitptrs = 0x01010101
        ORR     ht, ht, ht, LSL #8  ; replicate the constant colours across words
        ORR     ht_info, ht_info, ht_info, LSL #8
        ORR     ht, ht, ht, LSL #16
        ORR     ht_info, ht_info, ht_info, LSL #16
        MEND

        MACRO
        notAmatchBTest8_8_cleanup
        MOV     a1, #0
        B       %FT95
90      ADD     sp, sp, #num_line_saved_regs * 4
        MOV     a1, #1
95
        MEND

        MACRO
        notAmatchBTest8_8_1pixel $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #8
        MOV     $srcB, $srcB, LSL #8
        MEND

        MACRO
        notAmatchBTest8_8_2pixels $srcA, $srcB, $zeros, $ones, $tmpA, $tmpB
        EOR     $tmpA, $srcA, ht
        EOR     $tmpB, $srcB, ht_info
        USUB8   $tmpA, $zeros, $tmpA
        SEL     $tmpA, $zeros, $ones
        USUB8   $tmpB, $zeros, $tmpB
        SEL     $tmpB, $ones, $zeros
        AND     $tmpA, $tmpA, $tmpB
        TST     $tmpA, #0x10000
        TSTEQ   $tmpA, #0x1000000
        BNE     %FA90
        MOV     $srcA, $srcA, LSL #16
        MOV     $srcB, $srcB, LSL #16
        MEND

        MACRO
        notAmatchBTest8_8_4pixels $first, $last, $srcA, $srcB, $zeros, $ones
        EOR     $srcA, $srcA, ht
        EOR     $srcB, $srcB, ht_info
        USUB8   $srcA, $zeros, $srcA
        SEL     $srcA, $zeros, $ones
        USUB8   $srcB, $zeros, $srcB
        SEL     $srcB, $ones, $zeros
    [ $first :LAND: $last  ; avoid touching wk4
        TST     $srcA, $srcB
    |
      [ $first
        AND     $wk4, $srcA, $srcB
      |
        AND     $srcA, $srcA, $srcB
        ORRS    $wk4, $wk4, $srcA
      ]
    ]
      [ $last
        BNE     %FA90
      ]
        MEND

        MACRO
        notAmatchBTest8_8_8pixels $first, $last, $srcA0, $srcA1, $srcB0, $srcB1, $zeros, $ones
        notAmatchBTest8_8_4pixels $first,  {FALSE}, $srcA0, $srcB0, $zeros, $ones
        notAmatchBTest8_8_4pixels {FALSE}, $last,   $srcA1, $srcB1, $zeros, $ones
        MEND

        MACRO
        notAmatchBTest8_8_8bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAmatchBTest8_8_1pixel $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAmatchBTest8_8_16bits $src, $dst, $fixed_skew
        ASSERT  $src = $wk0
        ASSERT  $dst = $wk1
        notAmatchBTest8_8_2pixels $dst, $src, map, bitptrs, $wk2, $wk3
        MEND

        MACRO
        notAmatchBTest8_8_32bits $src, $dst, $fixed_skew
        Read1Word dst, 0,, 0
        Read1Word src, 1, carry, $fixed_skew, skew, scratch
        notAmatchBTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk1, map, bitptrs
        MEND

        MACRO
        notAmatchBTest8_8_64bits $src, $fixed_skew
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest8_8_4pixels {TRUE}, {TRUE}, $wk0, $wk2, map, bitptrs
        notAmatchBTest8_8_4pixels {TRUE}, {TRUE}, $wk1, $wk3, map, bitptrs
        MEND

        MACRO
        notAmatchBTest8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        notAmatchBTest8_8_8pixels {TRUE}, {FALSE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        Read2Words dst, 0,, 0
        Read2Words src, 2, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        notAmatchBTest8_8_128bits_tail $src
        notAmatchBTest8_8_8pixels {FALSE}, {TRUE}, $wk0, $wk1, $wk2, $wk3, map, bitptrs
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

notAmatchBTest GenerateFunctions 8, 8,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 4, \
  "y,stride_d,stride_s,skew,orig_w", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk4

; ********************************************************************

        END
