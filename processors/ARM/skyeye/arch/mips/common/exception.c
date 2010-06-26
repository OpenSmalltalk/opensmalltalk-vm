#include "emul.h"
#include <stdio.h>

/* Exception processing functions.  Before handling the exception, these
 * functions check for a higher- priority exception occuring elsewhere in the
 * pipeline, and handle those instead if necessary.


 * Process a reset, soft reset and nmi exceptions as specified by the (events)
 * field. These are the highest-priority exceptions handled in the D pipeline
 * stage, so handling them is fairly easy.
 *
 * Where (sr) is cleared for a cold reset and set otherwise.
 * For both cold and soft reset, the caches and the TLB are also reset.

 * WARNING: Because resets and interrupts are detected in the D pipeline
 * stage, one instruction should complete before they are detected and the
 * interrupt is taken. This effect is currently NOT simulated: it is unlikely
 * that the detail will cause any problems as interrupts are typically driven
 * by a clock many times slower than the pipeline anyway. The same effect can
 * also be achieved by scheduling the interrupts one cycle after the actual
 * event time (for example, by ignoring the fact that the events are guranteed
 * to be invoked *after* the scheduled time.)
 */

void 
process_reset(MIPS_State* mstate)
{
    	mstate->now += 5;
    	if (mstate->events & cold_reset_event) {
		mstate->cp0[Random] = tlb_size - 1;
		mstate->random_seed  = mstate->now;
		reset_icache(mstate);
		reset_dcache(mstate);
		reset_tlb(mstate);
    	}
	mstate->cp0[SR] = set_bit(mstate->cp0[SR], SR_BEV);
    	mstate->pc = reset_vector_base + reset_vector;
    	mstate->pipeline = nothing_special;
    	enter_kernel_mode(mstate);
    	mstate->events = 0;
}


/* Process a general exception.
 *
 * Because the IP field in the Cause register is actually stored in the
 * (events) word, Cause may be set directly to the exception code, adjusted
 * for exceptions in a branch-delay slot. Any additional changes to the
 * machine state are handled in inline wrappers on process_exception() (see
 * "koala.hh".) Exceptions are serviced when the corresponding instruction
 * enters the W pipeline stage: at this stage. Hence, there are always
 * exactly five dead clock cycles after an exception: these are simulated
 * simply by incrementing the clock by five.
 */

void 
process_exception(MIPS_State* mstate, UInt32 cause, int vec)
{
	//fprintf(stderr, "KSDBG:in %s, vec=0x%x, cause=0x%x, ,v0=0x%x, pc=0x%x\n", __FUNCTION__, vec, cause, mstate->gpr[2], mstate->pc);
	UInt32 exc_code = cause & 0x7f;
    	mstate->now += 5;
	/* we need to modify pipeline according to different exception */
	
    	VA epc;
    	if (!branch_delay_slot(mstate))
		epc = mstate->pc;
    	else {
		epc = mstate->pc - 4;
		cause = set_bit(cause, Cause_BD);
    	}

	if((exc_code == EXC_Sys) || (exc_code == EXC_TLBL)
		||(exc_code) ==	EXC_CpU	|| (exc_code == EXC_TLBS) || (exc_code == EXC_Mod)){
		mstate->pipeline = branch_nodelay;
		//fprintf(stderr, "KSDBG:1 in %s, vec=0x%x, cause=0x%x, ,v0=0x%x, pc=0x%x\n", __FUNCTION__, vec, exc_code, mstate->gpr[2], mstate->pc);
	}
	else{
    		mstate->pipeline = nothing_special;
	}

	/* Set ExcCode to zero in Cause register */
	mstate->cp0[Cause] &= 0xFFFFFF83;
    	mstate->cp0[Cause] |= cause;
		mstate->cp0[EPC] = epc;
    	mstate->pc = vec + (bit(mstate->cp0[SR], SR_BEV) ? general_vector_base : boot_vector_base);
	/* set EXL to one */
	mstate->cp0[SR] |= 0x2;	
	/* Set Exl bit to zero, disable interrupt */
	mstate->cp0[SR] &= 0xFFFFFFFD; 	
    	enter_kernel_mode(mstate);
	//fprintf(stderr, "End of %s,sr=0x%x,cause=0x%x\n", __FUNCTION__, mstate->cp0[SR], mstate->cp0[Cause]);
	//skyeye_exit(-1);
}

