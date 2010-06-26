/*
    armmmu.c - Memory Management Unit emulation.
    ARMulator extensions for the ARM7100 family.
    Copyright (C) 1999  Ben Williamson

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <assert.h>
#include <string.h>
#include "armdefs.h"

extern mmu_ops_t xscale_mmu_ops;
#define MMU_OPS (state->mmu.ops)
static mmu_inited = 0;
ARMword skyeye_cachetype = -1;

int
mmu_init (ARMul_State * state)
{
	int ret;

	state->mmu.control = 0x70;
	state->mmu.translation_table_base = 0xDEADC0DE;
	state->mmu.domain_access_control = 0xDEADC0DE;
	state->mmu.fault_status = 0;
	state->mmu.fault_address = 0;
	state->mmu.process_id = 0;

	switch (state->cpu->cpu_val & state->cpu->cpu_mask) {
	case SA1100:
	case SA1110:
		fprintf (stderr, "SKYEYE: use sa11xx mmu ops\n");
		state->mmu.ops = sa_mmu_ops;
		break;
	case PXA250:
	case PXA270:		//xscale
		fprintf (stderr, "SKYEYE: use xscale mmu ops\n");
		state->mmu.ops = xscale_mmu_ops;
		break;
	case 0x41807200:	//arm720t
	case 0x41007700:	//arm7tdmi
	case 0x41007100:	//arm7100
		fprintf (stderr, "SKYEYE: use arm7100 mmu ops\n");
		state->mmu.ops = arm7100_mmu_ops;
		break;
	case 0x41009200:
		fprintf (stderr, "SKYEYE: use arm920t mmu ops\n");
		state->mmu.ops = arm920t_mmu_ops;
		break;
	case 0x41069260:
		fprintf (stderr, "SKYEYE: use arm926ejs mmu ops\n");
		state->mmu.ops = arm926ejs_mmu_ops;
		break;

	default:
		fprintf (stderr,
			 "SKYEYE: armmmu.c : mmu_init: unknown cpu_val&cpu_mask 0x%x\n",
			 state->cpu->cpu_val & state->cpu->cpu_mask);
		skyeye_exit (-1);
		break;

	};
	ret = state->mmu.ops.init (state);
	mmu_inited = (ret == 0);
	return ret;
}

int
mmu_reset (ARMul_State * state)
{
	if (mmu_inited)
		mmu_exit (state);
	return mmu_init (state);
}

void
mmu_exit (ARMul_State * state)
{
	MMU_OPS.exit (state);
	mmu_inited = 0;
}

fault_t
mmu_read_byte (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	return MMU_OPS.read_byte (state, virt_addr, data);
};

fault_t
mmu_read_halfword (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	return MMU_OPS.read_halfword (state, virt_addr, data);
};

fault_t
mmu_read_word (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	return MMU_OPS.read_word (state, virt_addr, data);
};

fault_t
mmu_write_byte (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	fault_t fault;
	//static int count = 0;
	//count ++;
	fault = MMU_OPS.write_byte (state, virt_addr, data);
	return fault;
}

fault_t
mmu_write_halfword (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	fault_t fault;
	//static int count = 0;
	//count ++;
	fault = MMU_OPS.write_halfword (state, virt_addr, data);
	return fault;
}

fault_t
mmu_write_word (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	fault_t fault;
	static int count = 0;

	count++;
	fault = MMU_OPS.write_word (state, virt_addr, data);

	/*used for debug for MMU*

	   if (!fault){
	   ARMword tmp;

	   if (mmu_read_word(state, virt_addr, &tmp)){
	   err_msg("load back\n");
	   exit(-1);
	   }else{
	   if (tmp != data){
	   err_msg("load back not equal %d %x\n", count, virt_addr);
	   }
	   }
	   }
	 */

	return fault;
};

fault_t
mmu_load_instr (ARMul_State * state, ARMword virt_addr, ARMword * instr)
{
	return MMU_OPS.load_instr (state, virt_addr, instr);
}

ARMword
mmu_mrc (ARMul_State * state, ARMword instr, ARMword * value)
{
	return MMU_OPS.mrc (state, instr, value);
}

void
mmu_mcr (ARMul_State * state, ARMword instr, ARMword value)
{
	MMU_OPS.mcr (state, instr, value);
}

/*ywc 20050416*/
int
mmu_v2p_dbct (ARMul_State * state, ARMword virt_addr, ARMword * phys_addr)
{
	return (MMU_OPS.v2p_dbct (state, virt_addr, phys_addr));
}
