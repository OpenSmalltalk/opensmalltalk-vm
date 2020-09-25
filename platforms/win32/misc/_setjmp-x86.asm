/*-
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * William Jolitz.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *  from: @(#)_setjmp.s 5.1 (Berkeley) 4/23/90
 */

/* TODO: save/restore floating point control state and reset avx state
 */

	.text
#	.globl _setjmp
#	.globl _setjmp0
	.globl __setjmp
	.globl __setjmp0
	.p2align	4, 0x90
#_setjmp:
#_setjmp0:
__setjmp:
__setjmp0:
    movl   0(%esp), %edx	# rta
    movl   4(%esp), %eax	# arg
    movl   %ebp,  0(%eax)
    movl   %ebx,  4(%eax)
    movl   %edi,  8(%eax)
    movl   %esi, 12(%eax)
    movl   %esp, 16(%eax)
    movl   %edx, 20(%eax)	# eip/rta
    movl   %fs:0, %edx		# seh registration
    movl   %edx, 24(%eax)
    xorl    %eax, %eax		# return 0
    ret

#	.globl _longjmp
	.globl __longjmp
	.p2align	4, 0x90
#_longjmp:
__longjmp:
    movl    4(%esp), %edx	# arg 1
    movl    8(%esp), %eax	# arg 2
    movl   24(%edx), %ebp	# seh registration
    movl   20(%edx), %ecx	# eip
    movl   16(%edx), %esp
    movl   12(%edx), %esi
    movl    8(%edx), %edi
    movl    4(%edx), %ebx
    movl   %ebp, %fs:0
    movl    0(%edx), %ebp
    movl   %ecx, 0(%esp)
    testl  %eax, %eax
    jne    a
    inc    %eax
a:  ret    # jmp ecx
