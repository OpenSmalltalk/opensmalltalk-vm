/*
        arm_regdefs.c - necessary arm definition for skyeye debugger
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.gro.clinux.org>

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
/*
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */


#include "skyeye2gdb.h"
#include "armdefs.h"

#define ARM_NUM_REGS 26
#define CPSR_REGNUM 25
extern int bigendSig;
extern ARMul_State * state;
static int arm_register_raw_size(int x){
	if(x > 15 && x < 24)
		return 12;
	else
		return 4;
}
static int arm_register_byte(int x){
	if(x < 16)
		return (x*4);
	if(x > 15 && x < 24)
		return (16 * 4 + (x - 16)*12);
	if(x == 24)
		return (16 * 4 + 8 * 12);
	if(x == CPSR_REGNUM)
		return (16 * 4 + 8 * 12 + 4);
}
static int arm_store_register(int rn, unsigned long * memory){
	bigendSig = state->bigendSig;
	if(rn == CPSR_REGNUM){
		ARMul_SetCPSR(state, frommem(memory));
		return 0;
	}
	if(rn < 16)
		ARMul_SetReg (state, state->Mode, rn, frommem (memory));
	return 0;
}
static int arm_fetch_register(int rn, unsigned char * memory){
	WORD regval;
	bigendSig = state->bigendSig;
	if (rn < 16)
		regval = ARMul_GetReg (state, state->Mode, rn);
	else if (rn == CPSR_REGNUM)	/* FIXME: use PS_REGNUM from gdb/config/arm/tm-arm.h */
		regval = ARMul_GetCPSR (state);
	else
		regval = 0x0;	/* FIXME: should report an error */
	
	tomem (memory, regval);
	return 0;
}

/*
 * register arm register type to the array
 */
void init_arm_register_defs(void){
	static register_defs_t arm_reg_defs;
	arm_reg_defs.name = "arm";
	arm_reg_defs.register_raw_size = arm_register_raw_size;
	arm_reg_defs.register_bytes = (16 * 4 + 12 * 8 + 4 + 4); 	
	arm_reg_defs.register_byte = arm_register_byte;
	arm_reg_defs.num_regs = ARM_NUM_REGS;
	arm_reg_defs.max_register_raw_size = 12;
	arm_reg_defs.store_register = arm_store_register;
	arm_reg_defs.fetch_register = arm_fetch_register;
	register_reg_type(&arm_reg_defs);
}
