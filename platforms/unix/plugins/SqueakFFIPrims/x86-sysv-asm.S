/* x86-sysv-asm.S -- 386 FFI trampoline for SVr4-like ABIs	-*- asm -*-
 *
 * Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: Tue Jan 28 16:53:52 2003 by piumarta (Ian Piumarta) on xombul
 *
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 *   You are not allowed to distribute a modified version of this file
 *   under its original name without explicit permission to do so.  If
 *   you change it, rename it.
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
	fstl	ffiFloatReturnValue
	movl	%ebp, %esp
	popl	%ebp
	ret
