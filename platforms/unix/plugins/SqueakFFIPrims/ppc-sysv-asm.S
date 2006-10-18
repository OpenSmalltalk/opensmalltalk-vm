/* ppc-sysv-asm.S -- PowerPC FFI trampoline for SVr4-like ABIs		-*- asm -*-
 *
 * Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited:	2006-10-18 10:07:42 by piumarta on emilia.local
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

#define r0 0
#define sp 1
#define r2 2
#define r3 3
#define r4 4
#define r5 5
#define r6 6
#define r7 7
#define r8 8
#define r9 9
#define r10 10
#define r11 11
#define r12 12
#define f1 1
#define f2 2
#define f3 3
#define f4 4
#define f5 5
#define f6 6
#define f7 7
#define f8 8
#define f9 9
#define f10 10
#define f11 11
#define f12 12
#define f13 13

/* V.4 stack frames look like this (higher addresses first):

      old SP--> | back chain to caller's caller         |
                | Save area for FP registers (F)        | 8+P+A+V+L+X+C+G
                | Save area for GP registers (G)        | 8+P+A+V+L+X+C
                | saved CR (C)                          | 8+P+A+V+L+X
                | Float/int conversion temporary (X)    | 8+P+A+V+L
                | Local variable space (L)              | 8+P+A+V
                | Varargs save area (V)                 | 8+P+A
                | Alloca space (A)                      | 8+P
                | Parameter save area (P)               | 8
                | caller's saved LR                     | 4
          SP--> | back chain to caller                  | 0
*/
	
#define fn	r3
#define ngpr	r4
#define nfpr	r5
#define nparam	r6

	.text
	.globl	ffiCallAddressOf

ffiCallAddressOf:
	stwu	sp, -16(sp)			// push trampoline frame
	mflr	r0
	stw	r0, 20(sp)
        mfcr	r0
        stw	r0, 12(sp)			// saved ccr
	mtlr	fn				// destination fn address
	slwi	r10, nparam, 2			// param save area size
	addi	r10, r10, 16+15			// round to quad word
	rlwinm	r10, r10, 0,0,27
	neg	r10, r10
	stwux	sp, sp, r10			// push ffi caller frame
	cmpwi	nparam, 0			// have params?
	beq+	2f
	mtctr	nparam				// words to move
	lis	r10, (ffiStack-4)@ha
	la	r10, (ffiStack-4)@l(r10)	// ffi param stack - 4
	addi	r11, sp, 4			// param save area - 4
1:	lwzu	r0, 4(r10)			// copy param save area
	stwu	r0, 4(r11)
	bdnz	1b
2:	cmpwi	nfpr, 0
	beq+	4f				// no fp args
	lis	r11, ffiFPRs@ha
	la	r11, ffiFPRs@l(r11)
	cmpwi	nfpr, 4
	ble+	3f
	lfd	f5,  32(r11)
	lfd	f6,  40(r11)
	lfd	f7,  48(r11)
	lfd	f8,  56(r11)
3:	lfd	f1,   0(r11)
	lfd	f2,   8(r11)
	lfd	f3,  16(r11)
	lfd	f4,  24(r11)
4:	cmpwi	ngpr, 0
	beq-	6f				// no int args
	lis	r11, ffiGPRs@ha
	la	r11, ffiGPRs@l(r11)
	cmpwi	ngpr, 4
	ble+	5f
	lwz	r7,  16(r11)
	lwz	r8,  20(r11)
	lwz	r9,  24(r11)
	lwz	r10, 28(r11)
5:	lwz	r3,   0(r11)
	lwz	r4,   4(r11)
	lwz	r5,   8(r11)
	lwz	r6,  12(r11)
6:	blrl					// callout
	lwz	sp, 0(sp)			// pop ffi caller frame
	lis	r5, ffiLongReturnValue@ha
	la	r5, ffiLongReturnValue@l(r5)
	stw	r3, 0(r5)
	stw	r4, 4(r5)
	lis	r5, ffiFloatReturnValue@ha
	stfd	f1, ffiFloatReturnValue@l(r5)
	lwz	r0, 20(sp)
 	mtlr	r0
        lwz	r0, 12(sp)			// saved ccr
        mtcr	r0
	addi	sp, sp, 16			// pop trampoline frame
	blr
