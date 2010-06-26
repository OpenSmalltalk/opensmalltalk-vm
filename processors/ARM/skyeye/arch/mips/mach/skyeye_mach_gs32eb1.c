/*
        skyeye_mach_gs32eb1.c - gs32eb1 machine simulation 
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
#include "../common/types.h"
#include "../common/inttypes.h"
#include "../common/emul.h"
#include "../common/cpu.h"
#include <stdio.h>
#include <fcntl.h>
#include <signal.h>

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"
//#include "au1000.h"

extern MIPS_State* mstate;
typedef struct gpio_ctrl_s{
	uint32_t sys_trioutrd;
	uint32_t sys_outrd;
	uint32_t sys_pininputen;
	uint32_t sys_outputclr;
}gpio_ctrl_t;

typedef volatile struct
{
        /*00*/  u16 whoami;
                u16 reserved0;
        /*04*/  u16 status;
                u16 reserved1;
        /*08*/  u16 switches;
                u16 reserved2;
        /*0C*/  u16 resets;
                u16 reserved3;

        /*10*/  u16 pcmcia;
                u16 reserved4;
        /*14*/  u16 board;
                u16 reserved5;
        /*18*/  u16 disk_leds;
                u16 reserved6;
        /*1C*/  u16 system;
                u16 reserved7;

        /*20*/  u16 intclr;
                u16 reserved8;
        /*24*/  u16 intset;
                u16 reserved9;
        /*28*/  u16 intclr_mask;
                u16 reserved10;
        /*2C*/  u16 intset_mask;
                u16 reserved11;
	/*30*/  u16 sig_status;
                u16 reserved12;
        /*34*/  u16 int_status;
                u16 reserved13;
        /*38*/  u16 reserved14;
                u16 reserved15;
        /*3C*/  u16 reserved16;
                u16 reserved17;

} bcsr_t;


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
#if 0
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
}gs32eb1_uart_t;
#endif
typedef struct {
	unsigned int thr;
	unsigned int ier;
	unsigned int iir;
	unsigned int lcr;
	unsigned int mcr;
	unsigned int lsr;
	unsigned int msr;
	unsigned int scr;
} gs32eb1_uart_t;

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
typedef struct gs32eb1_io_s {
	gs32eb1_uart_t uart[3];
	int_ctrl_t int_ctrl[2];
	sys_clock_t clock;
	gpio_ctrl_t gpio_ctrl;
	pm_ctrl_t pm;
	sb_ctrl_t sb_ctrl;
	bcsr_t bcsr;
}gs32eb1_io_t;

static gs32eb1_io_t io;

static void update_int(){
	if(io.int_ctrl[0].req0int & 0x1){
		//printf("hardware int happened!\n");
		mstate->cp0[Cause] |= 1 << Cause_IP2;
		process_exception(mstate, EXC_Int, common_vector);
	}
}
static void
gs32eb1_io_do_cycle (void * state)
{
	MIPS_State * mstate = (MIPS_State *)state;
#if 1
	if(!(mstate->cp0[Cause] & (1 << Cause_IP4))){
		/* UART receive interrupt enable */
		int uart_int_enable = ((mstate->cp0[SR] & (1 << SR_IM4)) >> SR_IM4) & (mstate->cp0[SR] & (1 << SR_IEC));    // UART interrupt enable
		struct timeval tv;
		unsigned char c;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		if(skyeye_uart_read(-1, &c, 1, &tv, NULL) > 0)
		{
			io.uart[0].thr = (int) c;
			//printf("SKYEYE: io_do_cycle  set intcause = %x\n",io.uart[0].intcause);
			io.uart[0].lsr |= 0x01;	//Data ready
			//printf("In %s, uart receive int,uart_int_enable=0x%x, SR=0x%x\n", __FUNCTION__, uart_int_enable, mstate->cp0[SR]);
			io.uart[0].iir |= 0x4;	//Rx idle
		} /* if(skyeye_uart_read(-1, &c, 1, &tv, NULL) > 0) */
		// UART interrupt enable
	        if(uart_int_enable){
			if ((io.uart[0].ier & 0x1)
                            && (io.uart[0].iir & 0x4)) {
				io.uart[0].iir &= ~0x1;
			 	/* Set uart interrupt bit in IP section of Cause register */
                        	mstate->cp0[Cause] |= 1 << Cause_IP4;
                        	/* Set ExcCode to zero in Cause register */
                        	process_exception(mstate, EXC_Int, common_vector);
			}
			#if 1
			if (io.uart[0].ier & 0x2) {
				io.uart[0].iir |= 0x2;
				io.uart[0].iir &= ~0x1;
				io.uart[0].lsr |= 0x60;
				//printf("THR interrupt\n");
			 	/* Set uart interrupt bit in IP section of Cause register */
                        	mstate->cp0[Cause] |= 1 << Cause_IP4;
                        	/* Set ExcCode to zero in Cause register */
                        	process_exception(mstate, EXC_Int, common_vector);
			}
			#endif
		}
	}
#endif
}
static void gs32eb1_uart_write_word(int index, void * state, UInt32 offset, UInt32 data);
static UInt32 gs32eb1_uart_read_word(int index, void * state, UInt32 offset);

/* gs32eb1 uart read function */
static UInt32 gs32eb1_uart_read_word(int index, void * state, UInt32 offset){
	gs32eb1_uart_t * uart_p = &io.uart[index];
	UInt32 data;
	//printf("read offset=0x%x\n", offset);
	switch (offset) {
		case 0x0:
			data = uart_p->thr;
			/* clear the corresponding interrupt */
			mstate->cp0[Cause] &= ~(1 << Cause_IP4);
			uart_p->iir &= ~0x4;
			uart_p->iir |= 0x1;
			uart_p->lsr &= ~0x1;
			break;
		case 0x1:
			data = uart_p->ier;
			break;
		case 0x2:
			data = uart_p->iir;
			/* clear the corresponding interrupt */
			//mstate->cp0[Cause] &= ~(1 << Cause_IP4);
			break;
		case 0x3:
			data = uart_p->lcr;
			break;
		case 0x4:
			data = uart_p->mcr;
			break;
		case 0x5:
                        data = uart_p->lsr;
                        break;
		case 0x6:
                        data = uart_p->msr;
                        break;
		case 0x7:
                        data = uart_p->lcr;
                        break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x,pc=0x%x\n", __FUNCTION__, offset, mstate->pc);
                        //skyeye_exit(-1);
        }
	return data;

}
static UInt32
gs32eb1_io_read_byte(void * state, UInt32 addr)
{
	UInt32 ret;

	MIPS_State * mstate = (MIPS_State *)state;
	if(addr >= 0x14000100 && addr <= (0x14000100 + 0xff)){
                return (0xff & gs32eb1_uart_read_word(0, state, addr & 0xff));
        }

	switch (addr) {
		
		default:
			fprintf(stderr,"I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        //skyeye_exit(-1);

	}
	return ret;
}

static UInt32
gs32eb1_io_read_halfword(void * state, UInt32 addr)
{
	UInt32 ret;
	MIPS_State * mstate = (MIPS_State *)state;
	switch (addr) {
		
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%xi, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
		        skyeye_exit(-1);

	}
	return ret;
}

static UInt32
gs32eb1_io_read_word(void * state, UInt32 addr)
{
	
	UInt32 ret;
	MIPS_State * mstate = (MIPS_State *)state;
	 /* uart write word */
	/*
        if(addr >= 0x11100000 && addr <= (0x11400000 + 0x100)){
                return gs32eb1_uart_read_word((addr & 0x600000) >> 20, state, addr & 0xfff);
        }
	*/
         if(addr >= 0x14000100 && addr <= (0x14000100 + 0xff)){
                return gs32eb1_uart_read_word(0 , state, addr & 0xff);
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
		case 0x10400054:
			ret = io.int_ctrl[0].req0int;
			break;
		case 0x11900110:
			printf("read gpio\n");
			break;
		case 0x1190002c:
			printf("read gpio\n");
			break;
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        //skyeye_exit(-1);

	}
	return ret;
}

static void
gs32eb1_io_write_byte(void * state, UInt32 addr, UInt32 data)
{
	unsigned char c = data & 0xff;

	MIPS_State * mstate = (MIPS_State *)state;
	if(addr >= 0x14000100 && addr <= (0x14000100 + 0xff)){
                gs32eb1_uart_write_word(0, state, addr & 0xff, data&0xff);
                return;
        }

	switch (addr) {
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x, pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        //skyeye_exit(-1);
	}
}

static void
gs32eb1_io_write_halfword(void * state, UInt32 addr, UInt32 data)
{
	MIPS_State * mstate = (MIPS_State *)state;	
	switch (addr) {
		case 0x19800028:
			io.bcsr.intclr_mask = data;
			break;
		case 0x19800020:
			io.bcsr.intclr = data;
			break;
		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x,pc=0x%x\n", __FUNCTION__, addr, mstate->pc);
                        skyeye_exit(-1);
	}
}


/* gs32eb1 uart write function */
static void gs32eb1_uart_write_word(int index, void * state, UInt32 offset, UInt32 data){
	gs32eb1_uart_t * uart_p = &io.uart[index];
	//printf("KSDBG:in %s, offset=0x%x\n", __FUNCTION__, offset);
	 switch (offset) {
		case 0x0:
		{
			char c = data & 0xff;
                        uart_p->thr = data;
                        skyeye_uart_write(index, &c, 1, NULL);
			uart_p->iir &= ~0x2;
                        uart_p->iir |= 0x1;
                        uart_p->lsr &= ~0x60;

			/* clear the corresponding interrupt */
			mstate->cp0[Cause] &= ~(1 << Cause_IP4);
			break;
		}	
		case 0x1:
		{
			//printf("KSDBG:IER in %s, offset=0x%x\n", __FUNCTION__, offset);
			uart_p->ier = data;
			break;
		}
		case 0x2:
		{
			uart_p->iir = data;
			break;
		}
		case 0x3:
                {
                        uart_p->lcr = data;
                        break;
                }
		case 0x4:
                {
                        uart_p->mcr = data;
                        break;
                }
		case 0x5:
                {
                        uart_p->lsr = data;
                        break;
                }
		case 0x6:
			uart_p->msr = data;
			break;
		case 0x7:
			uart_p->scr = data;
			break;
                default:
                        fprintf(stderr, "I/O err in %s, offset=0x%x,pc=0x%x\n", __FUNCTION__, offset, mstate->pc);
                        //skyeye_exit(-1);
        }


}
static void gs32eb1_ic_write_word(int index, void * state, UInt32 offset, UInt32 data){
	int_ctrl_t * int_ctrl_p = &io.int_ctrl[index];
	MIPS_State * curr_state = (MIPS_State*)state;
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
		case 0x70: /* Maskset */
			int_ctrl_p->maskrd |= data;
			//printf("maskset=0x%x\n",data);
			break;
		case 0x74: /* Maskclr */
			/* W1C, write 1 to clear */
			int_ctrl_p->maskrd &= ~data;
			//printf("maskclr=0x%x\n", data);
			break;
		case 0x78:
			/* W1C */
			int_ctrl_p->risingclr = data;
			 printf("risingclr=0x%x\n", data);
			break;
		case 0x7C:
			int_ctrl_p->fallingclr = data;
			printf("fallingclr=0x%x\n", data);
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
gs32eb1_io_write_word(void * state, UInt32 addr, UInt32 data)
{
	MIPS_State * curr_state = (MIPS_State*)state;
	/* Interrupt controller 0 write word */
	if(addr >= 0x10400000 && addr <= (0x10400000 + 0x80))	{
		gs32eb1_ic_write_word(0,state, addr - 0x10400000, data);
		return;
	}
	/* Interrupt controller 1 write word */
	if(addr >= 0x11800000 && addr <= (0x11800000 + 0x80)){
		gs32eb1_ic_write_word(1, state, addr - 0x11800000, data);
		return;
	}
	/* uart write word */
	/*
	if(addr >= 0x11100000 && addr <= (0x11400000 + 0x100)){
		gs32eb1_uart_write_word((addr & 0x600000) > 20, state, addr & 0x1ff, data);
		return;
	}*/
	if(addr >= 0x14000100 && addr <= (0x14000100 + 0xff)){
		gs32eb1_uart_write_word(0, state, addr & 0xff, data);
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
		case 0x11700008:
			printf("gpio write\n");
			break;
		case 0x11900100:
			printf("gpio write\n");
			break;
		 case 0x1190002c:
                        printf("gpio write\n");
                        break;

		default:
			fprintf(stderr, "I/O err in %s, addr=0x%x,pc=0x%x\n", __FUNCTION__, addr, curr_state->pc);
			//skyeye_exit(-1);
	}
}

static void
gs32eb1_update_intr(machine_config_t *mach)
{
}

static void
gs32eb1_set_intr(UInt32 irq)
{
	io.int_ctrl[0].req0int = irq;
}

void
gs32eb1_mach_init (void * state, machine_config_t * this_mach)
{
	MIPS_State * mstate = (MIPS_State*)state;
	io.uart[0].lsr = 0x60; /* according to 8250 uart spec, this bit should be THRE */
	/*init io  value */
	io.clock.sys_cpupll = 0x10;
	/*init mach */
	if (!this_mach) {
		fprintf(stderr, "Memory have not been allocated for mach.\n");
		skyeye_exit (-1);
	}
	
	/*clfei: add the initialization of PRId and Config*/
	mstate->cp0[PRId] = 0x00004200;
	mstate->cp0[Config] = 0x00030270;
	set_bit(mstate->cp0[SR],SR_CU0); 

	this_mach->mach_io_read_byte = gs32eb1_io_read_byte;
        this_mach->mach_io_read_halfword = gs32eb1_io_read_halfword;
        this_mach->mach_io_read_word = gs32eb1_io_read_word;
        this_mach->mach_io_write_byte = gs32eb1_io_write_byte;
        this_mach->mach_io_write_halfword = gs32eb1_io_write_halfword;
        this_mach->mach_io_write_word = gs32eb1_io_write_word;
        this_mach->mach_io_do_cycle = gs32eb1_io_do_cycle;
        //this_mach->mach_set_intr = gs32eb1_set_intr;
	//this_mach->mach_update_intr = gs32eb1_update_intr;
}
