// A setlmp/longjmp pair that does not check the stack on unwind, hence avoiding
// issues caused by the JIT executing on the Smalltalk stack which is
// discontiguous with the C stack.
// Code adapted from Julia, whose license is MIT: https://julialang.org/license
	.text
	.globl _setjmp
	.globl _setjmp0
	.p2align	4, 0x90
_setjmp:
_setjmp0:
    movq   (%rsp), %rdx		# rta
    movq   %gs:0,  %rax		# SEH registration
    movq   %rax,    0(%rcx)
    movq   %rbx,    8(%rcx)
    movq   %rsp,   16(%rcx)
    movq   %rbp,   24(%rcx)
    movq   %rsi,   32(%rcx)
    movq   %rdi,   40(%rcx)
    movq   %r12,   48(%rcx)
    movq   %r13,   56(%rcx)
    movq   %r14,   64(%rcx)
    movq   %r15,   72(%rcx)
    movq   %rdx,   80(%rcx) # %rip
    movq   %rax,   88(%rcx)
    movaps %xmm6,  96(%rcx)
    movaps %xmm7, 112(%rcx)
    movaps %xmm8, 128(%rcx)
    movaps %xmm9, 144(%rcx)
    movaps %xmm10,160(%rcx)
    movaps %xmm11,176(%rcx)
    movaps %xmm12,192(%rcx)
    movaps %xmm13,208(%rcx)
    movaps %xmm14,224(%rcx)
    movaps %xmm15,240(%rcx)
    xor    %rax, %rax		# return 0
    ret

	.globl _longjmp
	.p2align	4, 0x90
_longjmp:
    movq     0(%rcx), %rax
    movq     8(%rcx), %rbx
    movq    16(%rcx), %rsp
    movq    24(%rcx), %rbp
    movq    32(%rcx), %rsi
    movq    40(%rcx), %rdi
    movq    48(%rcx), %r12
    movq    56(%rcx), %r13
    movq    64(%rcx), %r14
    movq    72(%rcx), %r15
    movq    80(%rcx), %r8
    movaps  96(%rcx), %xmm6
    movaps 112(%rcx), %xmm7
    movaps 128(%rcx), %xmm8
    movaps 144(%rcx), %xmm9
    movaps 160(%rcx), %xmm10
    movaps 176(%rcx), %xmm11
    movaps 192(%rcx), %xmm12
    movaps 208(%rcx), %xmm13
    movaps 224(%rcx), %xmm14
    movaps 240(%rcx), %xmm15
    movq   %rax, %gs:0		# SEH registration
    movl   %edx, %eax
    test   %eax, %eax
    jne    a
    inc    %eax
a:  movq   %r8, (%rsp)
    ret
