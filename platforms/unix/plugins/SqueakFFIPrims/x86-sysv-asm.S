/* x86-sysv-asm.S -- 386 FFI trampoline for SVr4-like ABIs	-*- asm -*-
 *
 * Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2009-09-10 12:55:54 by piumarta on emilia-2.local
 *
 *   Copyright (C) 1996-2009 by Ian Piumarta and other authors/contributors
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

	.text
	.globl	ffiCallAddressOf

ffiCallAddressOf:	/* 8=addr, 12=stack, 16=stackSize */
	pushl	%ebp
	movl	%esp, %ebp
	movl	16(%ebp), %ecx
	testl	%ecx, %ecx
	je	2f
	subl	%ecx, %esp
	subl	$4, %ecx
	movl	12(%ebp), %edx
1:	movl	(%edx,%ecx,1), %eax
	movl	%eax, (%esp,%ecx,1)
	subl	$4, %ecx
	jnc	1b
2:	call	*8(%ebp)
	movl	%eax, ffiIntReturnValue
	movl	%edx, ffiLongReturnValue
	fstpl	ffiFloatReturnValue
	movl	%ebp, %esp
	popl	%ebp
	ret
