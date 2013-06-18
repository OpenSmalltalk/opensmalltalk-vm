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

        AREA    |BitBltArmSimdBitLogical$$Code|, CODE, READONLY
        ARM

; ********************************************************************

        MACRO
        BitAnd32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        ; src = 0  => don't read dest; write 0 to dest
        ; src = -1 => don't read or write dest
        TEQ     $wk0, $wk0, ASR #32
        LDRNE   $wk1, [dst, #-1*4]
        CMP     $wk0, #-1
        BEQ     %FT01
        AND     $wk0, $wk0, $wk1
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        AND     $src, $src, $dst
      ]
        MEND

        MACRO
        BitAnd64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, $wk0, ASR #32
        TEQEQ   $wk0, $wk1
        LDMNEDB dst, {$wk2, $wk3}
        CMP     $wk0, #-1
        CMPEQ   $wk1, #-1
        BEQ     %FT01
        AND     $wk0, $wk0, $wk2
        AND     $wk1, $wk1, $wk3
        Write2Words dst, 0
01
        MEND

        MACRO
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        BitAnd128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, $wk0, ASR #32
        TEQEQ   $wk0, $wk1
        TEQEQ   $wk0, $wk2
        TEQEQ   $wk0, $wk3
        LDMNEDB dst, {$wk4, $wk5, $wk6, $wk7}
        CMP     $wk0, #-1
        CMPEQ   $wk1, #-1
        CMPEQ   $wk2, #-1
        CMPEQ   $wk3, #-1
        BEQ     %FT01
        AND     $wk0, $wk0, $wk4
        AND     $wk1, $wk1, $wk5
        AND     $wk2, $wk2, $wk6
        AND     $wk3, $wk3, $wk7
        Write4Words dst, 0
01
        MEND

; ********************************************************************

        MACRO
        BitAnd1_1_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd1_1_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd1_1_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd1_1_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 1, 1,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 3, \
  "stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", map ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        BitAnd2_2_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd2_2_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd2_2_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd2_2_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 2, 2,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 1, \
  "stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", map ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        BitAnd4_4_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd4_4_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd4_4_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd4_4_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 4, 4,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "stride_d,stride_s,ht,ht_info,map,bitptrs,orig_w,scratch", \
  "x,stride_d,stride_s,bitptrs", map ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        BitAnd8_8_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd8_8_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd8_8_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd8_8_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 8, 8,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "stride_d,ht,ht_info,map,bitptrs,skew,orig_w,scratch", \
  "x,stride_d", bitptrs ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        BitAnd16_16_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd16_16_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd16_16_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd16_16_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 16, 16,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "stride_s,ht,ht_info,map,bitptrs,skew,orig_w,scratch", \
  "x,stride_s", bitptrs ; leading_pixels_reg = wk4

; ********************************************************************

        MACRO
        BitAnd32_32_32bits $src, $dst, $fixed_skew
        BitAnd32bits $src, $dst, $fixed_skew
        MEND

        MACRO
        BitAnd32_32_64bits $src, $fixed_skew
        BitAnd64bits $src, $fixed_skew
        MEND

        MACRO
        BitAnd32_32_128bits_head $src, $fixed_skew, $intra_preloads
        BitAnd128bits_head $src, $fixed_skew, $intra_preloads
        MEND

        MACRO
        BitAnd32_32_128bits_tail $src
        BitAnd128bits_tail $src
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

BitAnd GenerateFunctions 32, 32,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 1, \
  "ht,ht_info,map,bitptrs,skew,orig_w,scratch,carry", \
  "x", skew ; leading_pixels_reg = wk4

; ********************************************************************

        END
