#include "instr.h"
#include "emul.h"

int 
decode_cache(MIPS_State* mstate, Instr instr) //Use in Cache Instruction, it's unuseable in R3000
{
    	// CP0 is usable in kernel mode or when the CU bit in SR is set.
    	if (!(mstate->mode & kmode) && !bit(mstate->cp0[SR], SR_CU0))
		process_coprocessor_unusable(mstate, 0);
	
    	VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
    	PA pa;
	if(translate_vaddr(mstate, va, cache_op, &pa) != 0){
		return nothing_special;
	}
    	if (pa != bad_pa) {
		if (bit(instr, 16)) {
	    		// Control data cache.
	    		control_dcache(mstate, va, pa, bits(instr, 20, 18), bit(instr, 17));
		} else {
	    		// Control instruction cache.
	    		control_icache(mstate, va, pa, bits(instr, 20, 18), bit(instr, 17));
		}
    	}
    	return nothing_special;
}
