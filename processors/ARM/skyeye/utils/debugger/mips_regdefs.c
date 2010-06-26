/*
        mips_regdefs.c - necessary mips definition for skyeye debugger
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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
 * 12/21/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

/*
 * according to GDB_SOURCE/gdb/regformats/mips-reg.dat
 *
	32:zero 32:at 32:v0  32:v1
	32:a0   32:a1 32:a2  32:a3
	32:t0   32:t1 32:t2  32:t3
	32:t4   32:t5 32:t6  32:t7
	32:s0   32:s1 32:s2 32:s3
	32:s4   32:s5 32:s6 32:s7
	32:t8   32:t9 32:k0 32:k1
	32:gp   32:sp 32:s8 32:ra

	32:sr   32:lo 32:hi 32:bad
	32:cause 32:pc

	32:f0   32:f1 32:f2 32:f3
	32:f4   32:f5 32:f6 32:f7
	32:f8   32:f9  32:f10  32:f11
	32:f12  32:f13 32:f14 32:f15
	32:f16  32:f17 32:f18 32:f19
	32:f20  32:f21 32:f22 32:f23
	32:f24  32:f25 32:f26 32:f27
	32:f28  32:f29 32:f30 32:f31

	32:fsr  32:fir 32:fp
*/

#include <skyeye_defs.h>
#include "skyeye2gdb.h"
#include <emul.h>

static int mips_register_raw_size(int x){
	return 32;
}
static int mips_register_byte(int x){
	return 4 * x;
}

extern int bigendSig;

extern MIPS_State* mstate;

static int mips_store_register(int rn, unsigned char * memory){
	uint32_t v = frommem(memory);
	if(rn >= 0 && rn < 32)
		mstate->gpr[rn] = v;
	else if(rn == 32)/* SR register of CP0 */
		mstate->cp0[12] = v;
	else if(rn == 33)
		mstate->lo = v;
	else if(rn == 34)
		mstate->hi = v;
	else if(rn == 35) /* Bad Vaddr */
		mstate->cp0[8] = v;
	else if(rn == 36) /* Cause */
		mstate->cp0[13] = v;
	else if(rn == 37)
		mstate->pc = v;
	else if(rn >= 38 && rn < 70)
		mstate->fpr[rn] = v;			
	else if(rn == 70 || rn == 71 || rn == 72) /* fsr, fir, fp */
		; /* do nothing */
	return 0;
}
static int mips_fetch_register(int rn, unsigned char * memory){
	uint32_t v;
	if(rn >= 0 && rn < 32)
		v = mstate->gpr[rn];
	else if(rn == 32)/* SR register of CP0 */
		v = mstate->cp0[12];
	else if(rn == 33)
		v = mstate->lo;
	else if(rn == 34)
		v = mstate->hi;
	else if(rn == 35) /* Bad Vaddr */
		v = mstate->cp0[8];
	else if(rn == 36) /* Cause */
		v = mstate->cp0[13];
	else if(rn == 37)
		v = mstate->pc;
	else if(rn >= 38 && rn < 70)
		v = mstate->fpr[rn];			
	else if(rn == 70 || rn == 71 || rn == 72) /* fsr, fir, fp */
		; /* do nothing */

	tomem (memory, v);
	return 0;
}


/*
 * register mips register type to the array
 */
void init_mips_register_defs(void){
	/* initialize the struct of mips register defination */
	static register_defs_t mips_reg_defs;
	extern int big_endian;
	mips_reg_defs.name = "mips";
	mips_reg_defs.register_raw_size = mips_register_raw_size;
	mips_reg_defs.register_bytes = (32 + 6 + 32 + 3)*4; 	
	mips_reg_defs.register_byte = mips_register_byte;
	mips_reg_defs.num_regs = 73; /* the total number of mips register is 73 */
	mips_reg_defs.max_register_raw_size = 4;
	mips_reg_defs.store_register = mips_store_register;
	mips_reg_defs.fetch_register = mips_fetch_register;
	mips_reg_defs.endian_flag = big_endian;
	
	register_reg_type(&mips_reg_defs);
}
