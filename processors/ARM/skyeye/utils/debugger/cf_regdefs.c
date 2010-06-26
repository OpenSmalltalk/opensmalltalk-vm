/*
        cf_regdefs.c - necessary coldfire definition for skyeye debugger
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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */
/*
 * refer to GDB_SOURCE/gdb/regformats/reg-m68k.dat 

32:d0 32:d1 32:d2 32:d3 32:d4 32:d5 32:d6 32:d7
32:a0 32:a1 32:a2 32:a3 32:a4 32:a5 32:fp 32:sp
32:ps 32:pc

96:fp0 96:fp1 96:fp2 96:fp3 96:fp4 96:fp5 96:fp6 96:fp7
32:fpcontrol 32:fpstatus 32:fpiaddr

*/

#include "skyeye.h"
#include "skyeye_defs.h"
#include "skyeye2gdb.h"
#include "skyeye_types.h"
#include "arch/coldfire/common/memory.h"

#define CF_NUM_REGS 29
extern struct _memory_core memory_core;
static int cf_register_raw_size(int x){
	if(x >= 0 && x < 18)
		return 4;
	if(x >= 18 && x < 26)
		return 12;
	if(x >=26 && x < 29)
		return 4;
}
static int cf_register_byte(int x){
	if(x >= 0 && x < 18)
		return (4 * x);
	if(x >= 18 && x < 26)
		return (4*18 + (x-18)*12);
	if(x >= 26 && x < 29)
		return (4 * 18 + 8 * 12 + (x - 26) * 4);
}

static int cf_store_register(int rn, unsigned char * memory){
	//SKYEYE_DBG("in %s\n",__FUNCTION__);
	WORD val = frommem(memory);
	if(0 <= rn && rn < 8)
        	memory_core.d[rn] = val ;
        else if(8 <= rn && rn < 16 )
        	memory_core.a[rn-8] = val ;
        else if(16 == rn)
                        memory_core.sr = val;
        else if(17 == rn)
                        memory_core.pc = val;
	else if(rn >= 18 && rn < 29)
			; /* Do nothing */
	else
		return -1;
	return 0;
}

static int cf_fetch_register(int rn, unsigned char * memory){
	WORD regval;
	if(0 <= rn && rn < 8)
		regval =  memory_core.d[rn];
	else if(8 <= rn && rn < 16 )
		regval =  memory_core.a[rn-8];
	else if(16 == rn)
		regval =  memory_core.sr;
	else if(17 == rn)
		regval =  memory_core.pc;
	else if(rn >= 18 && rn < 29)
		regval = 0;
	else	
		return -1;	
	
	//SKYEYE_DBG("in %s, regval=%d,rn=%d\n",__FUNCTION__,regval,rn);
	tomem (memory, regval);
	return 0;
}

static register_defs_t cf_reg_defs;

/*
 * register coldfire register type to the array
 */
void init_cf_register_defs(void){
	cf_reg_defs.name = "coldfire";
	cf_reg_defs.register_raw_size = cf_register_raw_size;
	cf_reg_defs.register_bytes = 4 * 18 + 12 * 8 + 4 * 3; 	
	cf_reg_defs.register_byte = cf_register_byte;
	cf_reg_defs.num_regs = CF_NUM_REGS;
	cf_reg_defs.max_register_raw_size = 12;
	cf_reg_defs.store_register = cf_store_register;
	cf_reg_defs.fetch_register = cf_fetch_register;
	cf_reg_defs.endian_flag = HIGH;
	register_reg_type(&cf_reg_defs);
}
