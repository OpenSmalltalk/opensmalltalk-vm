/*
        skyeye_mach_imx.c - imx machine simulation 
        Copyright (C) 2003-2007 Skyeye Develop Group
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
 * 03/02/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "armdefs.h"
typedef struct imx_timer_s{
	uint32_t tctl;
	uint32_t tprer;
	uint32_t tcmp;
	uint32_t tcr;
	uint32_t tcn;
	uint32_t tstat;
}imx_timer_t;
typedef struct imx_uart_s{
	uint32_t urx;
	uint32_t utx;
	uint32_t ucr[4];
	uint32_t ufcr;
	uint32_t usr[2];
	uint32_t uesc;
	uint32_t utim;
	uint32_t ubir;
	uint32_t ubmr;
	uint32_t ubrc;
	uint32_t bipr[4];
	uint32_t bmpr[4];
	uint32_t uts;
}imx_uart_t;
typedef struct imx_aitc_s{
	uint32_t intcntl;
	uint32_t nimask;
	uint32_t intennum;
	uint32_t intdisnum;
	uint32_t intenableh;
	uint32_t intenablel;
	uint32_t inttypeh;
	uint32_t inttypel;
	uint32_t nipriority[8];
	uint32_t nivecsr;
	uint32_t fivecsr;
	uint32_t intsrch;
	uint32_t intsrcl;
	uint32_t intfrch;
	uint32_t intfrcl;
	uint32_t nipndh;
	uint32_t nipndl;
	uint32_t fipndh;
	uint32_t fipndl;
}imx_aitc_t;
typedef struct imx_io_s{
	imx_timer_t timer[2];
	imx_uart_t uart[3];
	imx_aitc_t aitc;
}imx_io_t;
void imx_io_do_cycle(){}

static ARMword aitc_read_word(void * state, ARMword addr){
	int offset = addr - 0x00223000;
	ARMword data;
	switch(offset){
		default:
			fprintf(stderr, "io error in %s, addr=0x%x\n", __FUNCTION__, addr);
			skyeye_exit(-1);
	}
	return data;
}
static void aitc_write_word(void * state, ARMword addr, ARMword data){
        int offset = addr - 0x00223000;
        switch(offset){
                default:
                        fprintf(stderr, "io error in %s, addr=0x%x\n", __FUNCTION__, addr);
                        skyeye_exit(-1);
        }
        return;
}
static ARMword 
imx_io_read_word (void * state, ARMword addr)
{
	ARMword data;
	switch(addr){
                default:
                        fprintf(stderr, "io error in %s, addr=0x%x\n", __FUNCTION__, addr);
                        skyeye_exit(-1);
        }
	return data;
}

static ARMword
imx_io_read_byte (void * state, ARMword addr)
{
	return imx_io_read_word (state, addr);

}

ARMword
imx_io_read_halfword (void * state, ARMword addr)
{
	return imx_io_read_word (state, addr);
}


void
imx_io_write_word (void * state, ARMword addr, ARMword data)
{
	/*
	 * The imx system registers
	 */
        if(addr >= 0x0022300 && addr <= 0x00223064)
                return aitc_write_word(state, addr, data);
        switch(addr){
                default:
                        fprintf(stderr, "io error in %s, addr=0x%x\n", __FUNCTION__, addr);
                        skyeye_exit(-1);
        }
        return ;

}

void
imx_io_write_byte (void * state, ARMword addr, ARMword data)
{

	imx_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);

}

void
imx_io_write_halfword (void * state, ARMword addr, ARMword data)
{
	imx_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}
static void
imx_io_reset (void * curr_state)
{
}


void
imx_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = HIGH;

	state->Reg[1] = 160; /* MACH_TYPE_MX1ADS 160 */

	this_mach->mach_io_do_cycle = imx_io_do_cycle;
	this_mach->mach_io_reset = imx_io_reset;
	this_mach->mach_io_read_byte = imx_io_read_byte;
	this_mach->mach_io_write_byte = imx_io_write_byte;
	this_mach->mach_io_read_halfword = imx_io_read_halfword;
	this_mach->mach_io_write_halfword = imx_io_write_halfword;
	this_mach->mach_io_read_word = imx_io_read_word;
	this_mach->mach_io_write_word = imx_io_write_word;

	//this_mach->mach_update_int = imx_update_int;

}
