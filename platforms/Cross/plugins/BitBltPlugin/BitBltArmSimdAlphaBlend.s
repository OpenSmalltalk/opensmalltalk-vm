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
        MOV     ht_info, #1
        MOV     ht, #0
        ORR     ht_info, ht_info, ht_info, LSL #16 ; &10001
        MEND

        MACRO
        AlphaBlend32_32_1pixel $src, $dst, $tmp0, $tmp1, $tmp2, $known_not_transp
      [ "$known_not_transp" = ""
        MOVS    $tmp2, $src, LSR #24      ; s_a
        BEQ     %FT09 ; fully transparent - use dst
      ]
        TEQ     $tmp2, #&FF
        BEQ     %FT10 ; fully opaque - use src
        UXTB    $tmp0, $src, ROR #8       ; s_ag
        ORR     $tmp0, $tmp0, #&FF0000
        UXTB16  $tmp1, $src               ; s_rb
        MUL     $tmp0, $tmp0, $tmp2
        MUL     $tmp1, $tmp1, $tmp2
        RSB     $tmp2, $tmp2, #&FF
        UXTB16  $src, $dst, ROR #8        ; d_ag
        UXTB16  $dst, $dst                ; d_rb
        MLA     $src, $src, $tmp2, $tmp0  ; ag
        MLA     $dst, $dst, $tmp2, $tmp1  ; rb
        USUB16  $tmp0, $src, ht_info
        UXTAB16 $src, $src, $src, ROR #8
        SEL     $tmp1, ht_info, ht
        UXTAB16 $src, $tmp1, $src, ROR #8
        USUB16  $tmp0, $dst, ht_info
        UXTAB16 $dst, $dst, $dst, ROR #8
        SEL     $tmp1, ht_info, ht
        UXTAB16 $dst, $tmp1, $dst, ROR #8
        ORR     $src, $dst, $src, LSL #8  ; recombine
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
