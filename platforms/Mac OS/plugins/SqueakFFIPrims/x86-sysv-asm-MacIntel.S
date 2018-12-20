#if __LITTLE_ENDIAN__ 
/* x86-sysv-asm.S -- 386 FFI trampoline for SVr4-like ABIs	-*- asm -*-
 *
 * Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: Tue Jan 28 16:53:52 2003 by piumarta (Ian Piumarta) on xombul
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

#import <architecture/i386/asm_help.h>
	.text
	.globl	_ffiCallAddressOf

_ffiCallAddressOf:	/* 8=addr, 12=stack, 16=stackSize */
	pushl	%ebp
	movl	%esp, %ebp
	movl	16(%ebp), %ecx
	testl	%ecx, %ecx
	je	2f
	subl	%ecx, %esp
	and     $0xFFFFFFF0,%esp /*align to 128-bits*/
	subl	$4, %ecx
	movl	12(%ebp), %edx
1:	movl	(%edx,%ecx,1), %eax
	movl	%eax, (%esp,%ecx,1)
	subl	$4, %ecx
	jnc	1b
	jmp 3f
2:	and     $0xFFFFFFF0,%esp /*align to 128-bits*/

3:
	cld
	call	*8(%ebp)
	REG_TO_EXTERN (%eax, _intReturnValue) 
	REG_TO_EXTERN (%edx, _intReturnValue2) 
	PICIFY(_floatReturnValue)
	fstpl	(%edx)
	NON_LAZY_STUB(_floatReturnValue)
	movl	%ebp, %esp
	popl	%ebp
	ret
#endif

