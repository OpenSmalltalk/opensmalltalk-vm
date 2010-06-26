/*
        bfin_regdefs.c - necessary blackfin definition for skyeye debugger
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

#include "skyeye2gdb.h"
#include "skyeye_defs.h"
#include "bfin-sim.h"


/*
 *
32:r0             32:r1        32:r2         32:r3   32:r4     32:r5      32:r6  32:r7
32:p0             32:p1        32:p2         32:p3   32:p4     32:p5      32:sp  32:fp
32:i0             32:i1        32:i2         32:i3   32:m0     32:m1      32:m2  32:m3
32:b0             32:b1        32:b2         32:b3   32:l0     32:l1      32:l2  32:l3
32:a0x            32:a0w       32:a1x        32:a1w  32:astat  32:rets    32:lc0 32:lt0
32:lb0            32:lc1       32:lt1        32:lb1  32:cycles 32:cycles2 32:usp 32:seqstat
32:syscfg         32:reti      32:retx       32:retn 32:rete   32:pc      32:cc  32:text_addr
32:text_end_addr  32:data_addr 32:fpdic_exec 32:fpdic_interp 32:ipend
*/

#define BFIN_NUM_REGS 61

static int bfin_register_raw_size(int x){
	return 4;
}
static int bfin_register_byte(int x){
	return (4 * x);
}
static int bfin_store_register(int x, unsigned char * memory){
	uint32_t val = frommem(memory);
	if(x >= 0 && x < 16)
		DPREG(x) = val;
	else if(x == 45)
		RETSREG = val;
	else if(x == 49)
		RETIREG = val;	
	else if(x == 50)
		RETXREG = val;
	else if(x == 51)
		RETNREG = val;
	else if(x == 52)
		RETEREG = val;
	else if(x == 53)
		PCREG = val;
	else if(x == 54)
		CCREG = val;
	else if(x >= 0 && x < BFIN_NUM_REGS)
		return 0;
	else	
		return -1;
}
static int bfin_fetch_register(int x,unsigned char * memory){
	uint32_t val;	
	if(x >= 0 && x < 16)
		val = DPREG(x);
	else if(x == 45)
		val = RETSREG;
	else if(x == 49)
		val = RETIREG;	
	else if(x == 50)
		val = RETXREG;
	else if(x == 51)
		val = RETNREG;
	else if(x == 52)
		val = RETEREG;
	else if(x == 53)
		val = PCREG; 
	else if(x == 54)
		val = CCREG;
	else if(x >= 0 && x < BFIN_NUM_REGS)
		val = 0;
	else 
		return -1; /* wrong register number */
	tomem(memory, val);
	return 0;
}

static register_defs_t bfin_reg_defs;
/*
 * register blackfin register type to the array
 */
void init_bfin_register_defs(void){
	/* initialize the struct of blackfin register defination */
	bfin_reg_defs.name = "blackfin";
	bfin_reg_defs.register_raw_size = bfin_register_raw_size;
	bfin_reg_defs.register_bytes = BFIN_NUM_REGS * 4; 	
	bfin_reg_defs.register_byte = bfin_register_byte;
	bfin_reg_defs.num_regs = BFIN_NUM_REGS;
	bfin_reg_defs.max_register_raw_size = 4;
	bfin_reg_defs.store_register = bfin_store_register;
	bfin_reg_defs.fetch_register = bfin_fetch_register;
	
	register_reg_type(&bfin_reg_defs);
}
