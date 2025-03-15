// A setlmp/longjmp pair that does not check the stack on unwind, hence avoiding
// issues caused by the JIT executing on the Smalltalk stack which is
// discontiguous with the C stack.
	.text
	.globl _setjmp
	.p2align	4, 0x90
_setjmp:
	stp   x19, x20, [x0, #0<<3]
	stp   x21, x22, [x0, #2<<3]
	stp   x23, x24, [x0, #4<<3]
	stp   x25, x26, [x0, #6<<3]
	stp   x27, x28, [x0, #8<<3]
	stp   x29, x30, [x0, #10<<3] // x29=fp x30=lr
	stp    d8,  d9, [x0, #14<<3]
	stp   d10, d11, [x0, #16<<3]
	stp   d12, d13, [x0, #18<<3]
	stp   d14, d15, [x0, #20<<3]
	mrs    x2, FPCR
	str    w2, [x0, #13<<3]
	mrs    x2, FPSR
	str    w2, [x0, #(13<<3) + 4]
	mov    x2,  sp
	str    x2,  [x0, #12<<3]
	mov    x0, x31
	ret

	.globl _longjmp
	.p2align	4, 0x90
_longjmp:
	ldp   x19, x20, [x0, #0<<3]
	ldp   x21, x22, [x0, #2<<3]
	ldp   x23, x24, [x0, #4<<3]
	ldp   x25, x26, [x0, #6<<3]
	ldp   x27, x28, [x0, #8<<3]
	ldp   x29, x30, [x0, #10<<3]
	ldp    d8,  d9, [x0, #14<<3]
	ldp   d10, d11, [x0, #16<<3]
	ldp   d12, d13, [x0, #18<<3]
	ldp   d14, d15, [x0, #20<<3]
	ldr    w2,      [x0, #13<<3]
    msr    FPCR, x2
    ldr    w2,      [x0, #(13<<3) + 4]
    msr    FPSR, x2
	ldr    x2,      [x0, #13<<3]
	mov    sp, x2
	mov    x0, x1
	ret
