/*
        ppc_regdefs.c - necessary ppc definition for skyeye debugger
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
 * according to GDB_SOURCE/gdb/regformats/ppc-reg.dat
32:r0  32:r1  32:r2  32:r3  32:r4  32:r5  32:r6  32:r7
32:r8  32:r9  32:r10 32:r11 32:r12 32:r13 32:r14 32:r15
32:r16 32:r17 32:r18 32:r19 32:r20 32:r21 32:r22 32:r23
32:r24 32:r25 32:r26 32:r27 32:r28 32:r29 32:r30 32:r31

64:f0  64:f1  64:f2  64:f3  64:f4  64:f5  64:f6  64:f7
64:f8  64:f9  64:f10 64:f11 64:f12 64:f13 64:f14 64:f15
64:f16 64:f17 64:f18 64:f19 64:f20 64:f21 64:f22 64:f23
64:f24 64:f25 64:f26 64:f27 64:f28 64:f29 64:f30 64:f31

32:pc  32:ps  32:cr  32:lr  32:ctr 32:xer 32:fpscr

 * in gdb internal, it seem that there is 72 register, need to dig more. 
 */

#include <skyeye_defs.h>
#include "skyeye2gdb.h"
#include "ppc_cpu.h"

extern PPC_CPU_State gCPU;

static int ppc_register_raw_size(int x){
#if 0
	if(x > 31 && x < 64)
		return 8;
	else
#endif
		return 4;
}
static int ppc_register_byte(int x){
#if 0
	if(x < 32)
		return (4 * x);
	else if(31 < x && x < 64)
		return (32 * 4 + (x - 32) * 8);
	else
		return (32 * 4 + 32 * 8 + (x - 64) * 4);
#endif
	return 4 * x;
}

static int ppc_store_register(int rn, unsigned char * memory){
	int v = frommem(memory);
	if(rn < 32)
		gCPU.gpr[rn] = v ;
	else if(rn > 31 && rn < 64)
		return 0;
	else{
		switch(rn){
			case 64:
				//NIA = v;
				gCPU.pc = v;
				break;
			case 65:
				gCPU.msr = v;
				//MSR = v;
				break;
			case 66:
				//CR = v;	
				gCPU.cr = v;
				break;
			case 67:
				//LR = v;
				gCPU.lr = v;
				break;
			case 68:
				//CTR = v;
				gCPU.ctr = v;
				break;
			case 69:
				//XER = v;
				gCPU.xer = v;
				return;
			case 70:
				//FPSCR = v;
				gCPU.fpscr = v;
				break;
			case 71:
				break;
			default:
				fprintf(stderr,"Wrong reg number 0x%d in %s\n", rn, __FUNCTION__);
				return -1;
		}
	}		
	return 0;
}
static int ppc_fetch_register(int rn, unsigned char * memory){
	uint32_t v;
	if(rn < 32)
		v = gCPU.gpr[rn];
	else if(rn > 31 && rn < 64)
		return 0;
	else{
		switch(rn){
			case 64:
				v = gCPU.pc;
				break;
			case 65:
				v = gCPU.msr;
				break;
			case 66:
				v = gCPU.cr;
				break;
			case 67:
				v = gCPU.lr;
				break;
			case 68:
				v = gCPU.ctr;
				break;
			case 69:
				v = gCPU.xer;
				break;
			case 70:
				v = gCPU.fpscr;
				break;
			default:
				v = 0;
				//fprintf(stderr,"Wrong reg number 0x%d in %s\n", rn, __FUNCTION__);
				//return -1;
		}
	}

	tomem (memory, v);
	return 0;
}


/*
 * register powerpc register type to the array
 */
void init_ppc_register_defs(void){
	/* initialize the struct of powerpc register defination */
	static register_defs_t ppc_reg_defs;
	ppc_reg_defs.name = "ppc";
	ppc_reg_defs.register_raw_size = ppc_register_raw_size;
	ppc_reg_defs.register_bytes = 32 * 4 + 32 * 4 + 7 * 4; 	
	ppc_reg_defs.register_byte = ppc_register_byte;
	ppc_reg_defs.num_regs = 71; /* the total number of ppc register is 71 */
	ppc_reg_defs.max_register_raw_size = 4;
	ppc_reg_defs.store_register = ppc_store_register;
	ppc_reg_defs.fetch_register = ppc_fetch_register;
	ppc_reg_defs.endian_flag = HIGH;
	
	register_reg_type(&ppc_reg_defs);
}
