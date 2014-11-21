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
        pixelMatchTally32_32_1pixel $wk0, $wk4
        pixelMatchTally32_32_1pixel $wk1, $wk5
        pixelMatchTally32_32_1pixel $wk2, $wk6
        pixelMatchTally32_32_1pixel $wk3, $wk7
        MEND

;$op     GenerateFunctions $src_bpp, $dst_w_bpp, $qualifier, $flags, $prefetch_distance,
;        $work_regs, $line_saved_regs, $leading_pixels_reg, $preload_offset_reg, $init, $newline, $reinitwk, $cleanup

pixelMatchTally GenerateFunctions 32, 32,, \
  FLAG_VECTOR_HALFTONE :OR: FLAG_DST_READONLY :OR: FLAG_SPILL_LINE_VARS, 2, \
  "y,stride_d,stride_s,bitptrs,skew,orig_w,scratch,carry", \
  "x,y,stride_d,stride_s", orig_w,, init,,, cleanup ; leading_pixels_reg = wk5

; ********************************************************************

        END
