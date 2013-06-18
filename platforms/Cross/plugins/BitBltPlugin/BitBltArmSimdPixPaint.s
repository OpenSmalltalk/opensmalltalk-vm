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

        AREA    |BitBltArmSimdPixPaint$$Code|, CODE, READONLY
        ARM

; ********************************************************************

        MACRO
        PixPaint1_1_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDR     $wk1, [dst, #-4]
        ORR     $wk0, $wk0, $wk1
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        ORR     $src, $src, $dst
      ]
        MEND

        MACRO
        PixPaint1_1_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk2, $wk3}
        ORR     $wk0, $wk0, $wk2
        ORR     $wk1, $wk1, $wk3
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint1_1_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        PixPaint1_1_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk4, $wk5, $wk6, $wk7}
        ORR     $wk0, $wk0, $wk4
        ORR     $wk1, $wk1, $wk5
        ORR     $wk2, $wk2, $wk6
        ORR     $wk3, $wk3, $wk7
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 1, 1,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "y,stride_d,stride_s,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", map

; ********************************************************************

        MACRO
        PixPaint2_2_init
        LDR     ht, =&55555555
        B       %FT00
        LTORG
00
        MEND

        MACRO
        PixPaint2_2_16pixels $src, $dst, $pattern, $tmp, $src_known_nonzero
        ORRS    $tmp, $src, $src, LSR #1
      [ "$src_known_nonzero" = ""
        BEQ     %FT03
      ]
        AND     $tmp, $tmp, $pattern
        ORR     $tmp, $tmp, $tmp, LSL #1
        BIC     $tmp, $dst, $tmp
        ORR     $src, $src, $tmp
      [ "$src_known_nonzero" = ""
        B       %FT04
03      MOV     $src, $dst
04
      ]
        MEND

        MACRO
        PixPaint2_2_32pixels $src0, $src1, $dst0, $dst1, $pattern, $tmp0, $tmp1
        ORR     $tmp0, $src0, $src0, LSR #1
        ORR     $tmp1, $src1, $src1, LSR #1
        AND     $tmp0, $tmp0, $pattern
        AND     $tmp1, $tmp1, $pattern
        ORR     $tmp0, $tmp0, $tmp0, LSL #1
        ORR     $tmp1, $tmp1, $tmp1, LSL #1
        BIC     $tmp0, $dst0, $tmp0
        BIC     $tmp1, $dst1, $tmp1
        ORR     $src0, $src0, $tmp0
        ORR     $src1, $src1, $tmp1
        MEND

        MACRO
        PixPaint2_2_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDR     $wk1, [dst, #-4]
        PixPaint2_2_16pixels $wk0, $wk1, ht, $wk6, src_known_nonzero
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        PixPaint2_2_16pixels $src, $dst, ht, $wk6
      ]
        MEND

        MACRO
        PixPaint2_2_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk2, $wk3}
        PixPaint2_2_32pixels $wk0, $wk1, $wk2, $wk3, ht, $wk6, $wk7
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint2_2_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        PixPaint2_2_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDRD    $wk4, $wk5, [dst, #-4*4]
        PixPaint2_2_32pixels $wk0, $wk1, $wk4, $wk5, ht, $wk6, $wk7
        LDRD    $wk4, $wk5, [dst, #-2*4]
        PixPaint2_2_32pixels $wk2, $wk3, $wk4, $wk5, ht, $wk6, $wk7
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 2, 2,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "y,stride_d,stride_s,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", map,, init

; ********************************************************************

        MACRO
        PixPaint4_4_init
        LDR     ht, =&11111111
        B       %FT00
        LTORG
00
        MEND

        MACRO
        PixPaint4_4_8pixels $src, $dst, $pattern, $tmp, $src_known_nonzero
        ORRS    $tmp, $src, $src, LSR #1
      [ "$src_known_nonzero" = ""
        BEQ     %FT03
      ]
        ORR     $tmp, $tmp, $tmp, LSR #2
        AND     $tmp, $tmp, $pattern
        ORR     $tmp, $tmp, $tmp, LSL #2
        ORR     $tmp, $tmp, $tmp, LSL #1
        BIC     $tmp, $dst, $tmp
        ORR     $src, $src, $tmp
      [ "$src_known_nonzero" = ""
        B       %FT04
03      MOV     $src, $dst
04
      ]
        MEND

        MACRO
        PixPaint4_4_16pixels $src0, $src1, $dst0, $dst1, $pattern, $tmp0, $tmp1
        ORR     $tmp0, $src0, $src0, LSR #1
        ORR     $tmp1, $src1, $src1, LSR #1
        ORR     $tmp0, $tmp0, $tmp0, LSR #2
        ORR     $tmp1, $tmp1, $tmp1, LSR #2
        AND     $tmp0, $tmp0, $pattern
        AND     $tmp1, $tmp1, $pattern
        ORR     $tmp0, $tmp0, $tmp0, LSL #2
        ORR     $tmp1, $tmp1, $tmp1, LSL #2
        ORR     $tmp0, $tmp0, $tmp0, LSL #1
        ORR     $tmp1, $tmp1, $tmp1, LSL #1
        BIC     $tmp0, $dst0, $tmp0
        BIC     $tmp1, $dst1, $tmp1
        ORR     $src0, $src0, $tmp0
        ORR     $src1, $src1, $tmp1
        MEND

        MACRO
        PixPaint4_4_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDR     $wk1, [dst, #-4]
        PixPaint4_4_8pixels $wk0, $wk1, ht, $wk6, src_known_nonzero
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        PixPaint4_4_8pixels $src, $dst, ht, $wk6
      ]
        MEND

        MACRO
        PixPaint4_4_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk2, $wk3}
        PixPaint4_4_16pixels $wk0, $wk1, $wk2, $wk3, ht, $wk6, $wk7
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint4_4_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        PixPaint4_4_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDRD    $wk4, $wk5, [dst, #-4*4]
        PixPaint4_4_16pixels $wk0, $wk1, $wk4, $wk5, ht, $wk6, $wk7
        LDRD    $wk4, $wk5, [dst, #-2*4]
        PixPaint4_4_16pixels $wk2, $wk3, $wk4, $wk5, ht, $wk6, $wk7
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 4, 4,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_NO_EXPAND_SKEW :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 3, \
  "y,stride_d,stride_s,ht_info,map,bitptrs,orig_w,scratch", \
  "x,y,stride_d,stride_s,bitptrs", map,, init

; ********************************************************************

        MACRO
        PixPaint8_8_init
        MOV     ht, #0
        MEND

        MACRO
        PixPaint8_8_4pixels $src, $dst, $zero, $tmp
        USUB8   $tmp, $zero, $src ; set GE bit for each zero byte
        SEL     $src, $dst, $src
        MEND

        MACRO
        PixPaint8_8_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDR     $wk1, [dst, #-4]
        PixPaint8_8_4pixels $wk0, $wk1, ht, $wk6
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        PixPaint8_8_4pixels $src, $dst, ht, $wk6
      ]
        MEND

        MACRO
        PixPaint8_8_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk2, $wk3}
        PixPaint8_8_4pixels $wk0, $wk2, ht, $wk6
        PixPaint8_8_4pixels $wk1, $wk3, ht, $wk6
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint8_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        PixPaint8_8_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDRD    $wk5, $wk6, [dst, #-4*4]
        PixPaint8_8_4pixels $wk0, $wk5, ht, $wk4
        PixPaint8_8_4pixels $wk1, $wk6, ht, $wk4
        LDRD    $wk5, $wk6, [dst, #-2*4]
        PixPaint8_8_4pixels $wk2, $wk5, ht, $wk4
        PixPaint8_8_4pixels $wk3, $wk6, ht, $wk4
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 8, 8,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "stride_d,stride_s,ht_info,map,bitptrs,skew,orig_w", \
  "x,stride_d,stride_s", bitptrs, scratch, init

; ********************************************************************

        MACRO
        PixPaint16_16_init
        MOV     ht, #0
        MEND

        MACRO
        PixPaint16_16_2pixels $src, $dst, $zero, $tmp
        USUB16  $tmp, $zero, $src ; set GE bit pair for each zero halfword
        SEL     $src, $dst, $src
        MEND

        MACRO
        PixPaint16_16_32bits $src, $dst, $fixed_skew
      [ "$dst" = "memory"
        ; Operate on memory, referenced by src/dst registers
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDR     $wk1, [dst, #-4]
        PixPaint16_16_2pixels $wk0, $wk1, ht, $wk6
        Write1Word dst, 0
01
      |
        ; Operate in registers, input from $src/$dst, return in $src
        PixPaint16_16_2pixels $src, $dst, ht, $wk6
      ]
        MEND

        MACRO
        PixPaint16_16_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDMDB   dst, {$wk2, $wk3}
        PixPaint16_16_2pixels $wk0, $wk2, ht, $wk6
        PixPaint16_16_2pixels $wk1, $wk3, ht, $wk6
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint16_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, $wk6
        MEND

        MACRO
        PixPaint16_16_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        LDRD    $wk5, $wk6, [dst, #-4*4]
        PixPaint16_16_2pixels $wk0, $wk5, ht, $wk4
        PixPaint16_16_2pixels $wk1, $wk6, ht, $wk4
        LDRD    $wk5, $wk6, [dst, #-2*4]
        PixPaint16_16_2pixels $wk2, $wk5, ht, $wk4
        PixPaint16_16_2pixels $wk3, $wk6, ht, $wk4
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 16, 16,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "stride_d,stride_s,ht_info,map,bitptrs,skew,orig_w", \
  "x,stride_d,stride_s", bitptrs, scratch, init

; ********************************************************************

        MACRO
        PixPaint32_32_32bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, $wk1
        ADD     dst, dst, #1*4
        TEQ     $wk0, #0
        STRNE   $wk0, [dst, #-4]
        MEND

        MACRO
        PixPaint32_32_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, $wk2
        ADD     dst, dst, #2*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        TEQ     $wk0, #0
        LDREQ   $wk0, [dst, #-2*4]
        TEQ     $wk1, #0
        LDREQ   $wk1, [dst, #-1*4]
        Write2Words dst, 0
01
        MEND

        MACRO
        PixPaint32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        PixPaint32_32_128bits_tail $src
        ADD     dst, dst, #4*4
        TEQ     $wk0, #0
        TEQEQ   $wk1, #0
        TEQEQ   $wk2, #0
        TEQEQ   $wk3, #0
        BEQ     %FT01 ; don't read or write dest unless we really have to
        TEQ     $wk0, #0
        LDREQ   $wk0, [dst, #-4*4]
        TEQ     $wk1, #0
        LDREQ   $wk1, [dst, #-3*4]
        TEQ     $wk2, #0
        LDREQ   $wk2, [dst, #-2*4]
        TEQ     $wk3, #0
        LDREQ   $wk3, [dst, #-1*4]
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

PixPaint GenerateFunctions 32, 32,, \
  FLAG_DST_READWRITE :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 2, \
  "ht,ht_info,map,bitptrs", \
  "", bitptrs, scratch

; ********************************************************************

        END
