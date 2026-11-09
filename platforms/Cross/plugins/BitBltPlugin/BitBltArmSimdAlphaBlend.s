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

        AREA    |BitBltArmSimdAlphaBlend$$Code|, CODE, READONLY
        ARM

; ********************************************************************

        MACRO
        AlphaBlend32_32_init
        MOV     round_const, #&80
        ORR     round_const, round_const, round_const, LSL #16 ; 0x00800080
        MEND

        MACRO
        AlphaBlend32_32_1pixel $src, $dst, $tmp0, $tmp1, $tmp2, $known_not_transp
      [ "$known_not_transp" = ""
        MOVS    $tmp2, $src, LSR #24      ; s_a
        BEQ     %FT09 ; fully transparent - use dst
      ]
        TEQ     $tmp2, #&FF
        BEQ     %FT10 ; fully opaque - use src
        ; Set src alpha byte to 0xFF so alpha blends with the exact same formula
        ORR     $src, $src, #&FF000000    ; src = 0xFF R_s G_s B_s
        ; Byte-wise unsigned |src - dst| and sign masks via GE flags!
        USUB8   $tmp0, $src, $dst         ; sets GE[3:0] = 1 where src_byte >= dst_byte
        USUB8   $tmp1, $dst, $src         ; dst - src for lanes where src < dst
        SEL     $tmp0, $tmp0, $tmp1       ; $tmp0 = |src - dst| per byte (all >= 0!)
        ; Unpack |diff| into 16-bit lanes and multiply by s_a (ONLY 2 MULs!)
        UXTB16  $tmp1, $tmp0, ROR #8      ; |diff_ag| = 0x00|dA|00|dG|
        UXTB16  $tmp0, $tmp0              ; |diff_rb| = 0x00|dR|00|dB|
        MUL     $tmp1, $tmp1, $tmp2       ; |diff_ag| * s_a (max 65025, unsigned!)
        MUL     $tmp0, $tmp0, $tmp2       ; |diff_rb| * s_a (max 65025, unsigned!)
        ; Exact round-to-nearest: floor((|diff| * s_a + 128) / 255)
        ADD     $tmp1, $tmp1, round_const
        UXTAB16 $tmp1, $tmp1, $tmp1, ROR #8
        UXTB16  $tmp1, $tmp1, ROR #8      ; delta_ag = 0x00 dA 00 dG
        ADD     $tmp0, $tmp0, round_const
        UXTAB16 $tmp0, $tmp0, $tmp0, ROR #8
        UXTB16  $tmp0, $tmp0, ROR #8      ; delta_rb = 0x00 dR 00 dB
        ; Recombine |delta| into 0xAARRGGBB and add or subtract using preserved GE flags!
        ORR     $tmp0, $tmp0, $tmp1, LSL #8 ; $tmp0 = packed |delta| (0xAARRGGBB)
        UADD8   $tmp1, $dst, $tmp0        ; dst + |delta| (used where src >= dst)
        USUB8   $tmp2, $dst, $tmp0        ; dst - |delta| (used where src < dst)
        SEL     $src, $tmp1, $tmp2        ; select per-byte based on GE flags from first USUB8!
        B       %FT10
09      MOV     $src, $dst
10
        MEND

        MACRO
        AlphaBlend32_32_32bits $src, $dst, $fixed_skew
        Read1Word src, 0, carry, $fixed_skew, skew, scratch
        ADD     dst, dst, #1*4
        MOVS    $wk7, $wk0, LSR #24
        BEQ     %FT01 ; all pixels fully transparent - don't touch destination
        LDR     $wk4, [dst, #-1*4]
        AlphaBlend32_32_1pixel $wk0, $wk4, $wk5, $wk6, $wk7, known_not_transp
        Write1Word dst, 0
01
        MEND

        MACRO
        AlphaBlend32_32_64bits $src, $fixed_skew
        Read2Words src, 0, carry, $fixed_skew, skew, scratch
        ADD     dst, dst, #2*4
        MOVS    $wk7, $wk0, LSR #24
        MOVEQS  $wk7, $wk1, LSR #24
        BEQ     %FT01 ; all pixels fully transparent - don't touch destination
        LDR     $wk4, [dst, #-2*4]
        AlphaBlend32_32_1pixel $wk0, $wk4, $wk5, $wk6, $wk7
        LDR     $wk4, [dst, #-1*4]
        AlphaBlend32_32_1pixel $wk1, $wk4, $wk5, $wk6, $wk7
        Write2Words dst, 0
01
        MEND

        MACRO
        AlphaBlend32_32_128bits_head $src, $fixed_skew, $intra_preloads
        Read4Words src, 0, carry, $fixed_skew, skew, scratch
        MEND

        MACRO
        AlphaBlend32_32_128bits_tail $src
        ADD     dst, dst, #4*4
        MOVS    $wk7, $wk0, LSR #24
        MOVEQS  $wk7, $wk1, LSR #24
        MOVEQS  $wk7, $wk2, LSR #24
        MOVEQS  $wk7, $wk3, LSR #24
        BEQ     %FT01 ; all pixels fully transparent - don't touch destination
        LDR     $wk4, [dst, #-4*4]
        AlphaBlend32_32_1pixel $wk0, $wk4, $wk5, $wk6, $wk7
        LDR     $wk4, [dst, #-3*4]
        AlphaBlend32_32_1pixel $wk1, $wk4, $wk5, $wk6, $wk7
        LDR     $wk4, [dst, #-2*4]
        AlphaBlend32_32_1pixel $wk2, $wk4, $wk5, $wk6, $wk7
        LDR     $wk4, [dst, #-1*4]
        AlphaBlend32_32_1pixel $wk3, $wk4, $wk5, $wk6, $wk7
        Write4Words dst, 0
01
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $cleanup

AlphaBlend GenerateFunctions 32, 32,, \
  FLAG_DST_READWRITE :OR: FLAG_SPILL_LINE_VARS :OR: FLAG_PROCESS_PARALLEL :OR: FLAG_NO_PRELOAD_DST, 1, \
  "stride_d,stride_s,map,bitptrs,skew,orig_w,scratch,carry", \
  "x,stride_d,stride_s", bitptrs,, init ; leading_pixels_reg = wk3

; ********************************************************************

        END
