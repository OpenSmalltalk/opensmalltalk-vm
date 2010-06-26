/*
        skyeye_mach_vr41xx.c - vr41xx machine simulation 
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
 * 11/14/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "skyeye_config.h"
#include "types.h"
#include "inttypes.h"
#include "../common/emul.h"
#include "../common/cpu.h"
#include <stdio.h>
#include <fcntl.h>
#include <signal.h>

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"


/* UART Controller */
typedef struct uart_s {
	uint32_t rbr;
	uint32_t thr;
	uint32_t dll;
	uint32_t ier;
	uint32_t dlm;
	uint32_t iir;
	uint32_t fcr;
	uint32_t lcr;
	uint32_t mcr;
	uint32_t lsr;
	uint32_t msr;
	uint32_t scr;
	uint32_t usr;
}vr41xx_uart_t;

typedef struct vr41xx_bhif_s{
	uint32_t alternate0;
	uint32_t alternate1;
}vr41xx_bhif_t;

typedef struct vr41xx_broi_s{
	uint32_t rom_mode;
	uint32_t access_mode;
	uint32_t romif_mode;
	uint32_t nand_cnt;
	uint32_t nand_adr0;
	uint32_t nand_adr1;
	uint32_t rom_status;
} vr41xx_broi_t;

typedef struct vr41xx_io_s {
	vr41xx_uart_t uart[3];
	vr41xx_bhif_t bhif;
	vr41xx_broi_t broi;
}vr41xx_io_t;

static vr41xx_io_t io;

static void
vr41xx_io_do_cycle (void * state)
{

}
/* vr41xx uart read function */
static UInt32 vr41xx_uart_read_word(int index, void * state, UInt32 offset){
	vr41xx_uart_t * uart_p = &io.uart[index];
	//printf("KSDBG:in %s, offset=0x%x\n", __FUNCTION__, offset);
	UInt32 data;
	switch (offset) {
		case 0x0:
			data = uart_p->rbr;
			break;
		case 0x10:
			data = uart_p->ier;
			break;
		case 0x20:
			data = uart_p->iir;
			break;
		case 0x30:
			data = uart_p->lcr;
			break;
		case 0x40:
			data = uart_p->mcr;
			break;
		case 0x50:
			data = uart_p->lsr;
			//printf("read lsr=0x%x\n",data);
			break;
		case 0x60:
			data = uart_p->msr;
			break;
		case 0x70:
			data = uart_p->scr;
			break;
		case 0xD0:
			data = uart_p->usr;
			break;

                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x\n", __FUNCTION__, offset);
                        skyeye_exit(-1);
        }
	return data;

}
static UInt32
vr41xx_io_read_byte(void * state, UInt32 addr)
{
	UInt32 ret;

	MIPS_State * mstate = (MIPS_State *)state;
	switch (addr) {
		default:
			fprintf(stderr,"I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        skyeye_exit(-1);

	}
	return ret;
}

static UInt32
vr41xx_io_read_halfword(void * state, UInt32 addr)
{
	UInt32 ret;

	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x\n", __FUNCTION__, addr);
		        //skyeye_exit(-1);

	}
	return ret;
}

static UInt32
vr41xx_io_read_word(void * state, UInt32 addr)
{
	
	UInt32 ret;
	MIPS_State * mstate = (MIPS_State *)state;
	 /* uart write word */
        if(addr >= 0x10101000 && addr < 0x10103000){
                return vr41xx_uart_read_word((addr & 0x2000) >> 13, state, addr & 0xfff);
        }
	/*
	if(addr >= 0x12001000 && addr < 0x12002000){
                return vr41xx_uart_read_word(addr & 0x2000, state, addr & 0xfff);
	}
	*/
	switch (addr) {
		case 0x10000028:
                        ret = io.bhif.alternate0;
                        break;

		default:
			//fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        //skyeye_exit(-1);
			break;

	}
	return ret;
}

static void
vr41xx_io_write_byte(void * state, UInt32 addr, UInt32 data)
{
	unsigned char c = data & 0xff;

	MIPS_State * mstate = (MIPS_State *)state;
	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        skyeye_exit(-1);
	}
}

static void
vr41xx_io_write_halfword(void * state, UInt32 addr, UInt32 data)
{
	MIPS_State * mstate = (MIPS_State *)state;
	
	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        //skyeye_exit(-1);
	}
}


/* vr41xx uart write function */
static void vr41xx_uart_write_word(int index, void * state, UInt32 offset, UInt32 data){
	vr41xx_uart_t * uart_p = &io.uart[index];
	//printf("KSDBG:in %s, offset=0x%x\n", __FUNCTION__, offset);
	MIPS_State * curr_state = (MIPS_State*)state;
	 switch (offset) {
		case 0x0: /* THR or DLL */
		{
			char c = data & 0xff;
			uart_p->thr = data;
			skyeye_uart_write(index, &c, 1, NULL);
			uart_p->lsr |= 0x60;

			break;
		}
		case 0x10:
			uart_p->ier = data;
			break;
		case 0x20:
			uart_p->iir = data;
			break;
		case 0x30:
			uart_p->lcr = data;
			break;
		case 0x40:
			uart_p->mcr = data;
			break;
		case 0x50:
			uart_p->lsr = data;
			break;
		case 0x60:
			uart_p->msr = data;
			break;
		case 0x70:
			uart_p->scr = data;
			break;
		case 0xD0:
			uart_p->usr = data;
			break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x, pc=0x%x\n", __FUNCTION__, offset, curr_state->pc);
                        skyeye_exit(-1);
        }


}

static void
vr41xx_io_write_word(void * state, UInt32 addr, UInt32 data)
{
	MIPS_State * curr_state = (MIPS_State*)state;
	/* uart write word */
	if(addr >= 0x10101000 && addr < 0x10103000){
		vr41xx_uart_write_word((addr & 0x2000) >> 13, state, addr & 0xfff, data);
		return;
	}
	/*
	if(addr >= 0x12001000 && addr < 0x12002000){
                return vr41xx_uart_write_word(addr & 0x2000, state, addr & 0xfff, data);
	}
	*/
	switch (addr) {
		case 0x10000028:
			io.bhif.alternate0 = data;
			break;			
		case 0x10000800:
			io.broi.rom_mode = data;
			break;
		case 0x10000804:
			io.broi.access_mode = data;
			break;
		case 0x10000808:
			io.broi.romif_mode = data;
			break;
		default:
			//fprintf(stderr, "I/O err in %s, addr=0x%x,pc=0x%x\n", __FUNCTION__, addr, curr_state->pc);
			//skyeye_exit(-1);
			break;
	}
}


static void
vr41xx_disable_int()
{

}

static void
vr41xx_enable_int()
{

}

static void
vr41xx_clear_int(UInt32 irq)
{

}

static void
vr41xx_set_int(UInt32 irq)
{

}

static void
vr41xx_sti(UInt32 dreg)
{

}

static void
vr41xx_cli(UInt32 dreg)
{

}

void
vr41xx_mach_init (void * state, machine_config_t * this_mach)
{
	io.uart[0].lsr = 0x60; /* according to 8250 uart spec, this bit should be THRE */
	/*init mach */
	if (!this_mach) {
		exit (-1);
	}
	MIPS_State * mstate = (MIPS_State *)state;
	//mstate->cp0[Config0] = 0x80818483;	
	mstate->cp0[Config] = 0x80818483;	
	//mstate->cp0[PRId] = 0x1846c;
	mstate->cp0[PRId] = 0xc50;
	
	this_mach->mach_io_read_byte = vr41xx_io_read_byte;
        this_mach->mach_io_read_halfword = vr41xx_io_read_halfword;
        this_mach->mach_io_read_word = vr41xx_io_read_word;
        this_mach->mach_io_write_byte = vr41xx_io_write_byte;
        this_mach->mach_io_write_halfword = vr41xx_io_write_halfword;
        this_mach->mach_io_write_word = vr41xx_io_write_word;
        this_mach->mach_io_do_cycle = vr41xx_io_do_cycle;
        this_mach->mach_set_intr = vr41xx_set_int;

}
