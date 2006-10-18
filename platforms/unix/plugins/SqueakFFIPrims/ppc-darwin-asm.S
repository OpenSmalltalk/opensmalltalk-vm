/* ppc-sysv-asm.S -- PowerPC FFI trampoline for Mach-O			-*- asm -*-
 *
 * Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited:	2006-10-18 10:08:10 by piumarta on emilia.local
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

/* Mach-O PPC stack frames look like this (higher addresses first):
 *
 * 		| caller's lr		|
 * 		| caller's cr		|
 * caller's sp->| caller's caller's sp	|
 *		| fpr save area		|
 *		| gpr save area		|
 *		|     [alignment pad]	|
 *		| local variables	|
 * sp + 24  ->	| param save area	|
 * sp + 20  ->	| caller's toc		|
 * sp + 16  ->	| reserved		|
 * sp + 12  ->	| reserved		|
 * sp +  8  ->	| (callee-save) lr	|
 * sp +  4  ->	| (callee-save) cr	|
 * sp +  0  ->	| caller's sp		|
 */

#define GPR_MAX   8
#define FPR_MAX  13
#define ARG_MAX 512
#define FRAMESZ	 32

#include "ppc-global.h"

#define sp r1

	.text
	.globl	_ffiCallAddressOf

_ffiCallAddressOf:
	stwu	sp, -FRAMESZ(sp)		// push trampoline frame
	mflr	r0
	stw	r0, (FRAMESZ+8)(sp)
        mfcr	r0
        stw	r0, (FRAMESZ+4)(sp)		// saved ccr
	mtlr	r3				// destination fn address
	stw	r4, (FRAMESZ-4)(sp)		// globals
	lwz	r5, stackIndex(r4)
	slwi	r10, r5, 2			// param save area size
	addi	r10, r10, 32+15			// round to quad word
	rlwinm	r10, r10, 0,0,27
	neg	r10, r10
	stwux	sp, sp, r10			// push ffi caller frame
	cmpwi	r5, 0				// have params?
	beq+	2f
	mtctr	r5				// words to move
	la	r10, (stack-4)(r4)		// ffi param stack - 4
	addi	r11, sp, 24-4			// param save area - 4
1:	lwzu	r0, 4(r10)			// copy param save area
	stwu	r0, 4(r11)
	bdnz	1b
2:	lwz	r5, fprCount(r4)
	cmpwi	r5, 0
	beq+	4f				// no fp args
	la	r11, fprs(r4)
	cmpwi	r5, 4
	ble+	3f
	lfd	f5,  32(r11)
	lfd	f6,  40(r11)
	lfd	f7,  48(r11)
	lfd	f8,  56(r11)
#	if (FPR_MAX > 8)
	lfd	f9,  64(r11)
	lfd	f10, 72(r11)
	lfd	f11, 80(r11)
	lfd	f12, 88(r11)
	lfd	f13, 96(r11)
#	endif
3:	lfd	f1,   0(r11)
	lfd	f2,   8(r11)
	lfd	f3,  16(r11)
	lfd	f4,  24(r11)
4:	lwz	r5, gprCount(r4)
	cmpwi	r5, 0
	beq-	6f				// no int args
	la	r11, gprs(r4)
	cmpwi	r5, 4
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
	lwz	r5, (FRAMESZ-4)(sp)		// globals
	stw	r3, longReturnValue+0(r5)
	stw	r4, longReturnValue+4(r5)
	stfd	f1, floatReturnValue(r5)
	lwz	r0, (FRAMESZ+8)(sp)
 	mtlr	r0
        lwz	r0, (FRAMESZ+4)(sp)		// saved ccr
        mtcr	r0
	addi	sp, sp, FRAMESZ			// pop trampoline frame
	blr
