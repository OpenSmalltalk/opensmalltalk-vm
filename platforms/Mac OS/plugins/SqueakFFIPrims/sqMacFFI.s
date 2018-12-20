#if __BIG_ENDIAN__
/****************************************************************************
*   PROJECT: mac os-x FFI assembler, from the os-9 version
*   FILE:    sqMacFFI.s
*   CONTENT: 
*
*   AUTHOR:  Andreas Raab (ar), John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacFFI.s 1369 2006-03-22 04:48:20Z johnmci $
*
*   NOTES: See change log below.
*	1/24/2002  JMM hacked from the original code for os-x, added save for CCR and 
*			tweaked _4_gpregs compare
*	
*	11/14/2002 JMM clean & fix quad word alignment issue
*   2/24/2006 JMM unable to compile and work on GCC 3.3, perhaps linkage area is 32, not 24? 
*****************************************************************************/
#import <architecture/ppc/asm_help.h>
#import	<architecture/ppc/pseudo_inst.h>
.text
.globl _ffiCallAddressOf
_ffiCallAddressOf:	
	mflr r0		/* Save link register */
	stw r0, 8(sp)
	mfcr r0		/* save CCR  */
	stw r0, 4(sp)

	/* get stack index and preserve it for copying stuff later */
	EXTERN_TO_REG(r4, _ffiStackIndex) // lwz r4, ffiStackIndex(r2)

	/* compute frame size */
	rlwinm r5, r4, 2, 0, 29  /* ffiStackIndex words to bytes (e.g., "slwi r5, r4, 2") */
	addi r5, r5, 32+15 	/* linkage area */ //* JMM 02/25/06 was 24, Ian has 32 */
	rlwinm r5,r5,0,0,27 	/* JMM round up to quad word*/
	neg  r5, r5    		/* stack goes down */
	stwux sp, sp, r5 	/* adjust stack frame */

	/* load the stack frame area */
	/* note: r4 == ffiStackIndex */
	addi r5, sp, 24         /* dst = r1 + linkage area, was 24 */
	EXTERN_TO_REG(r6, _ffiStackLocation) //lwz r6, ffiStack(r2)  /* src = ffiStack */
	li r7, 0                /* i = 0 */
	b nextItem
copyItem:
	rlwinm r8, r7, 2, 0, 29 /* r8 = i << 2 (e.g., "slwi r8, r7, 2") */
	lwzx r0, r6, r8         /* r0 = ffiStack[r8] */
	addi r7, r7, 1          /* i = i + 1 */
	stwx r0, r5, r8         /* dst[r8] = r0 */
nextItem:
	cmpw r7, r4             /* i < ffiStackIndex ? */
	blt copyItem

	/* Keep addr somewhere so we can load all regs beforehand */
	stw r3, 20(sp)

	/* load all the floating point registers */
	EXTERN_TO_REG(r3, _fpRegCount) //lwz r3, fpRegCount
	EXTERN_TO_REG(r12, _FPRegsLocation) // lwz r12, FPRegs(r2)
	cmpwi r3, 0     /* skip all fpregs if no FP values used */
	beq _0_fpregs   /* was lt should be eq */ 
	cmpwi r3, 8
	blt _7_fpregs   /* skip last N fpregs if unused */
_all_fpregs:
	lfd  f8, 56(r12)
	lfd  f9, 64(r12)
	lfd f10, 72(r12)
	lfd f11, 80(r12)
	lfd f12, 88(r12)
	lfd f13, 96(r12)
_7_fpregs:
	lfd  f1,  0(r12)
	lfd  f2,  8(r12)
	lfd  f3, 16(r12)
	lfd  f4, 24(r12)
	lfd  f5, 32(r12)
	lfd  f6, 40(r12)
	lfd  f7, 48(r12)
_0_fpregs:

	/* load all the general purpose registers */
	EXTERN_TO_REG(r3, _gpRegCount) //lwz  r3, gpRegCount
	EXTERN_TO_REG(r12, _GPRegsLocation) // lwz  r12, GPRegs(r2)
	cmpwi r3, 5     /* 5 was 4 in original code but that seems to be a bug? */
	blt _4_gpregs    /* skip last four gpregs if unused */
_all_gpregs:
	lwz  r7, 16(r12)
	lwz  r8, 20(r12)
	lwz  r9, 24(r12)
	lwz r10, 28(r12)
_4_gpregs:
	lwz  r3,  0(r12)
	lwz  r4,  4(r12)
	lwz  r5,  8(r12)
	lwz  r6, 12(r12)
_0_gpregs:

	/* go calling out */
	//Note: OS-X mach-o does not use TVectors rather the addr is the entry point
	lwz r12, 20(sp) /* fetch addr */
	mtctr r12       /* move entry point into count register */
	bctrl           /* jump through count register and link */

	lwz sp, 0(sp)   /* restore frame */

	/* store the result of the call */
        /* more intelligent logic would have a check for type versus assuming all */
        
	REG_TO_EXTERN(r3,_intReturnValue) // stw r3, intReturnValue(r2)
	EXTERN_TO_REG(r12, _longReturnValueLocation) //lwz r12, longReturnValue(r2)
	stw r3, 0(r12)
	stw r4, 4(r12)
 	EXTERN_TO_REG(r12, _floatReturnValueLocation) //lwz r12, longReturnValue(r2)
        stfd f1, 0(r12) //stfd f1, floatReturnValue(r2)

	/* and get out of here */
        lwz r0, 4(sp) 	/*restore CCR */
        mtcrf 0xff,r0                               
	lwz r0, 8(sp)	/* restore ltr */
 	mtlr r0
	blr
#endif