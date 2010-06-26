/*
        skyeye_mach_fulong.c - fulong machine simulation 
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

typedef struct gpio_ctrl_s{
	uint32_t sys_trioutrd;
	uint32_t sys_outrd;
	uint32_t sys_pininputen;
	uint32_t sys_outputclr;
}gpio_ctrl_t;

/* Clock Register Descriptions */
typedef struct sys_clock_s{
	uint32_t sys_freqctrl0;
	uint32_t sys_freqctrl1;
	uint32_t sys_clksrc;
	uint32_t sys_cpupll;
	uint32_t sys_auxpll;
	uint32_t sys_toytrim;
	uint32_t sys_toywrite;
	uint32_t sys_toymatch0;
	uint32_t sys_toymatch1;
	uint32_t sys_toymatch2;
	uint32_t sys_cntrctrl;
	uint32_t sys_toyread;
	uint32_t sys_rtctrim;
	uint32_t sys_rtcwrite;
	uint32_t sys_rtmatch0;
	uint32_t sys_rtcmatch1;
	uint32_t sys_rtcmatch2;
	uint32_t sys_rtcread;
}sys_clock_t;


/* UART Controller */
typedef struct uart_s {
	uint32_t rxdata;
	uint32_t txdata;
	uint32_t inten;
	uint32_t intcause;
	uint32_t fifoctrl;
	uint32_t linectrl;
	uint32_t mdmctrl;
	uint32_t linestat;
	uint32_t mdmstat;
	uint32_t autoflow;
	uint32_t clkdiv;
	uint32_t enable;
}fulong_uart_t;

/* Interrupt Controller */
typedef struct int_ctrl_s {
	uint32_t cfg0rd;
	uint32_t cfg0set;
	uint32_t cfg0clr;
	uint32_t cfg1rd;
	uint32_t cfg1set;
	uint32_t cfg1clr;
	uint32_t cfg2rd;
	uint32_t cfg2set;
	uint32_t cfg2clr;
	uint32_t req0int;
	uint32_t srcrd;
	uint32_t srcset;
	uint32_t srcclr;
	uint32_t req1int;
	uint32_t assignrd;
	uint32_t assignset;
	uint32_t assignclr;
	uint32_t wakerd;
	uint32_t wakeset;
	uint32_t wakeclr;
	uint32_t maskrd;
	uint32_t maskset;
	uint32_t maskclr;
	uint32_t risingrd;
	uint32_t risingclr;
	uint32_t fallingrd;
	uint32_t fallingclr;
	uint32_t testbit;
}int_ctrl_t;

/* static bus controller */
typedef struct sb_ctrl_s{
	uint32_t mem_stcfg[4];
	uint32_t mem_sttime[4];
	uint32_t mem_staddr[4];
	
}sb_ctrl_t ;

typedef struct pm_ctrl_s{
	uint32_t sys_powerctrl;
}pm_ctrl_t;
typedef struct fulong_io_s {
	fulong_uart_t uart[3];
	int_ctrl_t int_ctrl[2];
	sys_clock_t clock;
	gpio_ctrl_t gpio_ctrl;
	pm_ctrl_t pm;
	sb_ctrl_t sb_ctrl;
}fulong_io_t;

static fulong_io_t io;

static void
fulong_io_do_cycle (void * state)
{

}
/* fulong uart read function */
static UInt32 fulong_uart_read_word(int index, void * state, UInt32 offset){
	fulong_uart_t * uart_p = &io.uart[index];
	//printf("KSDBG:in %s, offset=0x%x\n", __FUNCTION__, offset);
	UInt32 data;
	switch (offset) {
		case 0x0:
			data = uart_p->rxdata;
			break;
		case 0x4:
			data = uart_p->txdata;
			break;
		case 0x8:
			data = uart_p->inten;
			break;
		case 0xC:
			data = uart_p->intcause;
			break;
		case 0x10:
			data = uart_p->fifoctrl;
			break;
		case 0x14:
			data = uart_p->linectrl;
			break;
		case 0x18:
			data = uart_p->mdmctrl;
			break;
		case 0x1C:
			data = uart_p->linestat;
			break;
		case 0x20:
			data = uart_p->mdmstat;
			break;
		case 0x24:
			data = uart_p->autoflow;
			break;
		case 0x28:
			data = uart_p->clkdiv;
			break;
		case 0x100:
			data = uart_p->enable;
			break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x\n", __FUNCTION__, offset);
                        skyeye_exit(-1);
        }
	return data;

}
static UInt32
fulong_io_read_byte(void * state, UInt32 addr)
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
fulong_io_read_halfword(void * state, UInt32 addr)
{
	UInt32 ret;

	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x\n", __FUNCTION__, addr);
		        skyeye_exit(-1);

	}
	return ret;
}

static UInt32
fulong_io_read_word(void * state, UInt32 addr)
{
	
	UInt32 ret;
	MIPS_State * mstate = (MIPS_State *)state;
	 /* uart write word */
        if(addr >= 0x11100000 && addr <= (0x11400000 + 0x10)){
                return fulong_uart_read_word(addr & 0x600000, state, addr & 0xfff);
        }

	switch (addr) {
		case 0x11900014:
                        ret = io.clock.sys_cntrctrl;
                        break;
		case 0x1190003c:
                        ret = io.pm.sys_powerctrl;
                        break;
		case 0x11900060:
			ret = io.clock.sys_cpupll;
                        break;
		case 0x14001000:
			ret = io.sb_ctrl.mem_stcfg[0];
			break;
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        skyeye_exit(-1);

	}
	return ret;
}

static void
fulong_io_write_byte(void * state, UInt32 addr, UInt32 data)
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
fulong_io_write_halfword(void * state, UInt32 addr, UInt32 data)
{
	
	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x\n", __FUNCTION__, addr);
                        skyeye_exit(-1);
	}
}


/* fulong uart write function */
static void fulong_uart_write_word(int index, void * state, UInt32 offset, UInt32 data){
	fulong_uart_t * uart_p = &io.uart[index];
	//printf("KSDBG:in %s, offset=0x%x\n", __FUNCTION__, offset);
	MIPS_State * curr_state = (MIPS_State*)state;
	 switch (offset) {
		case 0x0:
			uart_p->rxdata = data;
			break;
		case 0x4:
		{
			char c = data & 0xff;
			uart_p->txdata = data;
			skyeye_uart_write(index, &c, 1, NULL);
			uart_p->linestat |= 0x60;

			break;
		}
		case 0x8:
			uart_p->inten = data;
			break;
		case 0xC:
			uart_p->intcause = data;
			break;
		case 0x10:
			uart_p->fifoctrl = data;
			break;
		case 0x14:
			uart_p->linectrl = data;
			break;
		case 0x18:
			uart_p->mdmctrl = data;
			break;
		case 0x1C:
			uart_p->linestat = data;
			break;
		case 0x20:
			uart_p->mdmstat = data;
			break;
		case 0x24:
			uart_p->autoflow = data;
			break;
		case 0x28:
			uart_p->clkdiv = data;
			break;
		case 0x100:
			uart_p->enable = data;
			break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x, pc=0x%x\n", __FUNCTION__, offset, curr_state->pc);
                        skyeye_exit(-1);
        }


}
static void fulong_ic_write_word(int index, void * state, UInt32 offset, UInt32 data){
	int_ctrl_t * int_ctrl_p = &io.int_ctrl[index];
	 switch (offset) {
		case 0x40:
			int_ctrl_p->cfg0set = data;
			break;
		case 0x44:
			int_ctrl_p->cfg0clr = data;
			break;
		case 0x48:
			int_ctrl_p->cfg1set = data;
			break;
		case 0x4C:
			int_ctrl_p->cfg1clr = data;
			break;
		case 0x50:
			int_ctrl_p->cfg2set = data;
			break;
		case 0x54:
			int_ctrl_p->cfg2clr = data;
			break;
		case 0x58:
			int_ctrl_p->srcset = data;
			break;
		case 0x5C:
			int_ctrl_p->srcclr = data;
			break;
		case 0x60:
			int_ctrl_p->assignset = data;
			break;
		case 0x64:
			int_ctrl_p->assignclr = data;
			break;
		case 0x68:
			int_ctrl_p->wakeset = data;
			break;
		case 0x6C:
			int_ctrl_p->wakeclr = data;
			break;
		case 0x70:
			int_ctrl_p->maskset = data;
			break;
		case 0x74:
			int_ctrl_p->maskclr = data;
			break;
		case 0x78:
			int_ctrl_p->risingclr = data;
			break;
		case 0x7C:
			int_ctrl_p->fallingclr = data;
			break;
		case 0x80:
			int_ctrl_p->testbit = data;
			break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x\n", __FUNCTION__, offset);
                        skyeye_exit(-1);
        }


}

static void
fulong_io_write_word(void * state, UInt32 addr, UInt32 data)
{
	MIPS_State * curr_state = (MIPS_State*)state;
	/* Interrupt controller 0 write word */
	if(addr >= 0x10400000 && addr <= (0x10400000 + 0x80))	{
		fulong_ic_write_word(0,state, addr - 0x10400000, data);
		return;
	}
	/* Interrupt controller 1 write word */
	if(addr >= 0x11800000 && addr <= (0x11800000 + 0x80)){
		fulong_ic_write_word(1, state, addr - 0x11800000, data);
		return;
	}
	/* uart write word */
	if(addr >= 0x11100000 && addr <= (0x11400000 + 0x10)){
		fulong_uart_write_word(addr & 0x600000, state, addr & 0xfff, data);
		return;
	}
	switch (addr) {
		case 0x11900004:
			io.clock.sys_toywrite = data;
			break;
		case 0x11900000:
			io.clock.sys_toytrim = data;
			break;
		case 0x11900014:
                        io.clock.sys_cntrctrl = data;
                        break;
		case 0x11900020:
			io.clock.sys_freqctrl0 = data;
			break;
		case 0x11900024:
			io.clock.sys_freqctrl1 = data;
			break;
		case 0x11900028:
			io.clock.sys_clksrc = data;
			break;
		case 0x1190003c:
			io.pm.sys_powerctrl = data;
			break;
		case 0x11900044:
			io.clock.sys_rtctrim = data;
			break;
		case 0x11900060:
			io.clock.sys_cpupll = data;
			break;
		case 0x11900064:
			io.clock.sys_auxpll = data;
			break;		
		case 0x11900110:
			io.gpio_ctrl.sys_pininputen = data;
			break;
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x,pc=0x%x\n", __FUNCTION__, addr, curr_state->pc);
			skyeye_exit(-1);
	}
}


static void
fulong_disable_int()
{

}

static void
fulong_enable_int()
{

}

static void
fulong_clear_int(UInt32 irq)
{

}

static void
fulong_set_int(UInt32 irq)
{

}

static void
fulong_sti(UInt32 dreg)
{

}

static void
fulong_cli(UInt32 dreg)
{

}

void
fulong_mach_init (void * state, machine_config_t * this_mach)
{
	io.uart[0].linestat = 0x20; /* according to 8250 uart spec, this bit should be THRE */
	/*init io  value */
	io.clock.sys_cpupll = 0x10;
	/*init mach */
	if (!this_mach) {
		exit (-1);
	}

	this_mach->mach_io_read_byte = fulong_io_read_byte;
        this_mach->mach_io_read_halfword = fulong_io_read_halfword;
        this_mach->mach_io_read_word = fulong_io_read_word;
        this_mach->mach_io_write_byte = fulong_io_write_byte;
        this_mach->mach_io_write_halfword = fulong_io_write_halfword;
        this_mach->mach_io_write_word = fulong_io_write_word;
        this_mach->mach_io_do_cycle = fulong_io_do_cycle;
        this_mach->mach_set_intr = fulong_set_int;

}
