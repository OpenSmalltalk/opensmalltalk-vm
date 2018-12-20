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

        AREA    |sqUnixX11Arm$$Code|, CODE, READONLY
        ARM

; ********************************************************************

        MACRO
        Convert_x888_8_LEPacking_1pixel $src, $dst
        AND     $dst, ht, $src, LSR #6     ; 00000000000000rrr0000000000000bb
        AND     $src, $src, #&E000         ; 0000000000000000ggg0000000000000
        ORR     $dst, $dst, $dst, LSR #10  ; 00000000000000rrr0000000rrr000bb
        ORR     $dst, $dst, $src, LSR #11  ; 00000000000000rrr0000000rrrgggbb
        AND     $dst, $dst, #&FF           ; 000000000000000000000000rrrgggbb
        LDR     $dst, [map, $dst, LSL #2]
        MEND

        MACRO
        Convert_x888_8_LEPacking_4pixels $src0, $src1, $src2, $src3, $dst
        Convert_x888_8_LEPacking_1pixel $src0, $dst
        Convert_x888_8_LEPacking_1pixel $src1, $src0
        Convert_x888_8_LEPacking_1pixel $src2, $src1
        Convert_x888_8_LEPacking_1pixel $src3, $src2
        ORR     $dst, $dst, $src0, LSL #8
        ORR     $dst, $dst, $src1, LSL #16
        ORR     $dst, $dst, $src2, LSL #24
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_init
        LDR     ht, =&38003
        B       %FT00
        LTORG
00
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_8bits $src, $dst, $fixed_skew
        ; This code should never be executed. It's for handling stray
        ; pixels at the start or end of the row, but for now the
        ; assembler framework only supports packing these big-endian
        ; into words, which isn't what we want.
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_16bits $src, $dst, $fixed_skew
        ; This code should never be executed. It's for handling stray
        ; pixels at the start or end of the row, but for now the
        ; assembler framework only supports packing these big-endian
        ; into words, which isn't what we want.
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_32bits $src, $dst, $fixed_skew
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_64bits $src, $fixed_skew
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk0
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk0
        Read4Words src, 4, carry, $fixed_skew, skew, unused
      [ "$intra_preloads" <> ""
        PreloadMiddle
      ]
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk1
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk2
        Read4Words src, 4, carry, $fixed_skew, skew, unused
        MEND

        MACRO
        Convert_x888_8_LEPacking32_8_128bits_tail $src
        Convert_x888_8_LEPacking_4pixels $wk4, $wk5, $wk6, $wk7, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

Convert_x888_8_LEPacking GenerateFunctions 32, 8,, \
  FLAG_COLOUR_MAP :OR: FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "y,stride_d,stride_s,ht_info,bitptrs,skew,orig_w,carry", \
  "x,y,stride_d,stride_s", ht_info,, init ; leading_pixels_reg = wk3

; ********************************************************************

        MACRO
        Convert_x888_0565_LEPacking_2pixels $src0, $src1, $dst
        AND     $dst, ht, $src1, LSR #3     ; 00000000000rrrrr00000000000bbbbb
        AND     $src1, $src1, #&FC00        ; 0000000000000000gggggg0000000000
        ORR     $dst, $dst, $dst, LSR #5    ; 00000000000rrrrrrrrrr000000bbbbb
        ORR     $src1, $dst, $src1, LSR #5  ; 00000000000rrrrrrrrrrggggggbbbbb
        AND     $dst, ht, $src0, LSR #3     ; 00000000000RRRRR00000000000BBBBB
        AND     $src0, $src0, #&FC00        ; 0000000000000000GGGGGG0000000000
        ORR     $dst, $dst, $dst, LSR #5    ; 00000000000RRRRRRRRRR000000BBBBB
        ORR     $src0, $dst, $src0, LSR #5  ; 00000000000RRRRRRRRRRGGGGGGBBBBB
        BIC     $src0, $src0, #&1F0000      ; 0000000000000000RRRRRGGGGGGBBBBB
        ORR     $dst, $src0, $src1, LSL #16 ; rrrrrggggggbbbbbRRRRRGGGGGGBBBBB
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_init
        LDR     ht, =&001F001F
        B       %FT00
        LTORG
00
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_16bits $src, $dst, $fixed_skew
        ; This code should never be executed. It's for handling stray
        ; pixels at the start or end of the row, but for now the
        ; assembler framework only supports packing these big-endian
        ; into words, which isn't what we want.
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_32bits $src, $dst, $fixed_skew
        Read2Words src, 3, carry, $fixed_skew, skew, unused
        Convert_x888_0565_LEPacking_2pixels $wk3, $wk4, $wk0
        Write1Word dst, 0
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_64bits $src, $fixed_skew
        Read4Words src, 3, carry, $fixed_skew, skew, unused
        Convert_x888_0565_LEPacking_2pixels $wk3, $wk4, $wk0
        Convert_x888_0565_LEPacking_2pixels $wk5, $wk6, $wk1
        Write2Words dst, 0
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 3, carry, $fixed_skew, skew, unused
        Convert_x888_0565_LEPacking_2pixels $wk3, $wk4, $wk0
        Convert_x888_0565_LEPacking_2pixels $wk5, $wk6, $wk1
        Read4Words src, 3, carry, $fixed_skew, skew, unused
        MEND

        MACRO
        Convert_x888_0565_LEPacking32_16_128bits_tail $src
        Convert_x888_0565_LEPacking_2pixels $wk3, $wk4, $wk2
        Convert_x888_0565_LEPacking_2pixels $wk5, $wk6, $wk3
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

Convert_x888_0565_LEPacking GenerateFunctions 32, 16,, \
  FLAG_DST_WRITEONLY :OR: FLAG_SPILL_LINE_VARS, 3, \
  "stride_s,ht_info,map,bitptrs,skew,orig_w,carry", \
  "x,stride_s", map, scratch, init ; leading_pixels_reg = wk2

; ********************************************************************

        MACRO
        Convert_x888_x888BGR_LEPacking32_32_32bits $src, $dst, $fixed_skew
        SETEND  BE
        Read1Word src, 0, carry, $fixed_skew, skew, unused
        SETEND  LE
        MOV     $wk0, $wk0, LSR #8
        Write1Word dst, 0
        MEND

        MACRO
        Convert_x888_x888BGR_LEPacking32_32_64bits $src, $fixed_skew
        SETEND  BE
        Read2Words src, 0, carry, $fixed_skew, skew, unused
        SETEND  LE
        MOV     $wk0, $wk0, LSR #8
        MOV     $wk1, $wk1, LSR #8
        Write2Words dst, 0
        MEND

        MACRO
        Convert_x888_x888BGR_LEPacking32_32_128bits_head $src, $fixed_skew, $intra_preloads
        SETEND  BE
        Read4Words src, 0, carry, $fixed_skew, skew, unused
        MEND

        MACRO
        Convert_x888_x888BGR_LEPacking32_32_128bits_tail $src
        SETEND  LE
        MOV     $wk0, $wk0, LSR #8
        MOV     $wk1, $wk1, LSR #8
        MOV     $wk2, $wk2, LSR #8
        MOV     $wk3, $wk3, LSR #8
        Write4Words dst, 0
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

Convert_x888_x888BGR_LEPacking GenerateFunctions 32, 32,, \
  FLAG_DST_WRITEONLY, 2, \
  "ht,ht_info,map,bitptrs", \
  "", skew, scratch

; ********************************************************************

        END
