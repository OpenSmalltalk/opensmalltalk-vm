/*
	skyeye_mach_lpc.c - define machine lpc for skyeye
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
 * 3/24/2003 	init this file.
 * 		add machine lpc's function.Most taken from original armio.c 
 * 		include: lpc_mach_init, lpc_io_do_cycle
 * 		lpc_io_read_word, lpc_io_write_word
 *		walimis <walimi@peoplemail.com.cn> 
 *		
 *3/24/2003	chenyu <chenyu-tmlinux@hpclab.cs.tsinghua.edu.cn> has done the
 *		necessary work to armio.c
 * */

#include "armdefs.h"
#include "lpc.h"
//zzc:2005-1-1
#ifdef __CYGWIN__
//chy 2005-07-28
#include <time.h>
//teawater add DBCT_TEST_SPEED 2005.10.04---------------------------------------
/*struct timeval
{
  int tv_sec;
  int tv_usec;
};*/
//AJ2D--------------------------------------------------------------------------
#endif

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"


//teawater add for arm2x86 2005.03.18-------------------------------------------
//make gcc-3.4 can compile this file
ARMword lpc_io_read_word (ARMul_State * state, ARMword addr);
void lpc_io_write_word (ARMul_State * state, ARMword addr, ARMword data);
//AJ2D--------------------------------------------------------------------------


#define DEBUG 0
#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr, ##a)
#else
#define DBG_PRINT(a...)
#endif

typedef struct timer
{
	ARMword ir;
	ARMword tcr;
	ARMword tc;
	ARMword pr;
	ARMword pc;
	ARMword mcr;
	ARMword mr0;
	ARMword mr1;
	ARMword mr2;
	ARMword mr3;
	ARMword ccr;
	ARMword cr0;
	ARMword cr1;
	ARMword cr2;
	ARMword cr3;
	ARMword emr;
} lpc_timer_t;

typedef struct uart
{
	ARMword rbr;
	ARMword thr;
	ARMword ier;
	ARMword iir;
	ARMword fcr;
	ARMword lcr;
	ARMword lsr;
	ARMword msr;
	ARMword scr;
	ARMword dll;
	ARMword dlm;
	char t_fifo[16];
	char r_fifo[16];
} lpc_uart_t;

typedef struct pll
{
	ARMword con;
	ARMword cfg;
	ARMword stat;
	ARMword feed;
} lpc_pll_t;

typedef struct vic
{
	ARMword isr;
	ARMword fsr;
	ARMword risr;
	ARMword islr;
	ARMword ier;
	ARMword iecr;
	ARMword sir;
	ARMword sicr;
	ARMword per;
	ARMword var;
	ARMword dvar;
	ARMword va[15];
	ARMword vc[15];
} lpc_vic_t;

typedef struct lpc_io
{
	ARMword syscon;		/* System control */
	ARMword sysflg;		/* System status flags */
	lpc_pll_t pll;
	ARMword apbdiv;		/* APB divider register */
	lpc_timer_t timer[2];
	lpc_vic_t vic;
	ARMword pinsel0;
	lpc_uart_t uart[2];	/* Receive data register */
	ARMword memmap;		/*Memory mapping control register */


} lpc_io_t;

static lpc_io_t lpc_io;

#define io lpc_io

static void
lpc_update_int (ARMul_State * state)
{
	u32 irq = 0;
//        state->NfiqSig = (~(io.vic.risr&io.vic.ier& io.vic.)) ? LOW : HIGH;
	irq = io.vic.risr & io.vic.ier;
	io.vic.isr = irq & ~io.vic.islr;
	io.vic.fsr = irq & io.vic.islr;
	if (io.vic.isr & IRQ_UART0) {
		io.vic.var = io.vic.va[6];
	}
	if (io.vic.isr & IRQ_TC0) {
		io.vic.var = io.vic.va[4];
	}
	state->NirqSig = io.vic.isr ? LOW : HIGH;
	state->NfiqSig = io.vic.fsr ? LOW : HIGH;


}
static void
lpc_io_reset (ARMul_State * state)
{
	io.timer[0].pr = 500000;	/*prescale value */
	io.vic.isr = 0;
	io.vic.fsr = 0;
	io.vic.risr = 0;

	io.uart[0].lsr = 0x60;
	io.uart[0].iir = 0x01;
	io.pinsel0 = 0;

	io.apbdiv = 0;
	skyeye_config.mach->io_cycle_divisor = 4;
}


/*lpc io_do_cycle*/
void
lpc_io_do_cycle (ARMul_State * state)
{
	int t;

	io.timer[0].pc++;
	io.timer[1].pc++;
	if (!(io.vic.risr & IRQ_TC0)) {
		if (io.timer[0].pc >= io.timer[0].pr + 1) {
			io.timer[0].tc++;
			io.timer[0].pc = 0;
			if (io.timer[0].tc == io.timer[0].mr0 && io.timer[0].mcr & (1 << 0)) {
				io.vic.risr |= IRQ_TC0;
				if (io.timer[0].mcr & (1 << 1)) {
					io.timer[0].tc = 0;
				}
			}
			lpc_update_int (state);
		}
	}
	if (io.timer[0].pc == 0) {
		if (!(io.vic.risr & IRQ_UART0)) {
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char buf;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
			{
				//printf("SKYEYE:get input is %c\n",buf);
				io.uart[0].rbr = buf;
				io.uart[0].lsr |= 0x1;
				io.vic.risr |= IRQ_UART0;
				lpc_update_int (state);
			}
		}		/* if (rcr > 0 && ... */
	}
}


ARMword
lpc_fix_int (ARMword val)
{
/*	ARMword ret = 0;
	if (val & (1 << 2))
		ret |= URXINT;
	if (val & (1 << 5))
		ret |= TC1OI;
	if (val & (1 << 6))
		ret |= TC2OI;
	if (val & (1 << 16))
		ret |= AT91_EXT0;*/
	return (val);
}

ARMword
lpc_unfix_int (ARMword val)
{
/*	ARMword ret = 0;
	if (val & URXINT)
		ret |= (1 << 2);
	if (val & TC1OI)
		ret |= (1 << 5);
	if (val & TC2OI)
		ret |= (1 << 6);
	if (val & AT91_EXT0)
		ret |= (1 << 16);
		*/
	return (val);
}

ARMword
lpc_uart_read (ARMul_State * state, ARMword addr, int i)
{
	ARMword data;
	//printf("lpc_uart_read,addr=%x\n",addr);
	switch ((addr & 0xfff) >> 2) {
	case 0x0:		// RbR
		io.uart[i].lsr &= ~0x1;
		if (i == 0)
			io.vic.risr &= ~IRQ_UART0;
		else
			io.vic.risr &= ~IRQ_UART1;
		lpc_update_int (state);
		data = io.uart[i].rbr;
		break;

	case 0x1:		// ier
		data = io.uart[i].ier;
		break;
	case 0x2:		// iir
		data = io.uart[i].iir;
		break;
	case 0x3:		// IDR
	case 0x4:		// IMR
	case 0x5:		// LSR
		data = io.uart[i].lsr;
		break;
	case 0x6:		// MSR
		data = io.uart[i].msr;
		break;
	case 0x7:		// SCR
		data = io.uart[i].scr;
		break;

	default:
		DBG_PRINT ("uart_read(%s=0x%08x)\n", "uart_reg", addr);

		break;
	}

	return (data);
}


void
lpc_uart_write (ARMul_State * state, ARMword addr, ARMword data, int i)
{
	static ARMword tx_buf = 0;

	//DBG_PRINT("uart_write(0x%x, 0x%x)\n", (addr & 0xfff) >> 2, data);
	switch ((addr & 0xfff) >> 2) {
	case 0x0:		// THR
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			//io.uart[0].lsr |= 0x40;
			io.uart[0].lsr |= 0x20;
		}
	case 0x2:		//FCR
		{
			io.uart[i].fcr = data;
			break;
		}
	case 0x7:		// SCR
		io.uart[i].scr = data;
		break;
	default:
		//printf("%c", data); fflush(stdout);
		DBG_PRINT ("uart_write(%s=0x%08x)\n", "uart_reg", addr);
		break;
	}
}

ARMword
lpc_io_read_word (ARMul_State * state, ARMword addr)
{
	/*
	 *       * The LPC system registers
	 *               */

	ARMword data = -1;
	static ARMword current_ivr = 0;	/* mega hack,  2.0 needs this */
	int i;
	ARMword dataimr = 0;


	switch (addr) {
	case 0xfffff000:	/* ISR */
//              data = unfix_int(io.intsr);
//              dataimr = unfix_int(io.intmr);
		data = io.vic.isr;
		DBG_PRINT ("read ISR=%d\n", data);
		break;
	case 0xfffff004:	/* interrupt status register */
		data = io.vic.fsr;
		DBG_PRINT ("SKYEYE:read ISR=%x,%x\n", data, io.vic.fsr);
		break;
	case 0xfffff008:	/* IMR */
		data = io.vic.risr;
		break;
	case 0xfffff00c:	/* CORE interrupt status register */
		data = io.vic.islr;
		break;
	case 0xfffff010:	/* IER */
		data = io.vic.ier;
		DBG_PRINT ("read IER=%x,after update ier=%x\n", data,
			   io.vic.ier);
		break;

	case 0xfffff014:	/* IECR */
		data = io.vic.iecr;
		lpc_update_int (state);
		break;
	case 0xfffff034:	/* DVAR */
		data = io.vic.dvar;
		break;
	case 0xfffff030:	/* VAR */
		data = io.vic.var;
		break;

		/*Timer0 */
	case 0xe0004000:
		data = io.timer[0].ir;
		break;
	case 0xe0004004:
		data = io.timer[0].tcr;
		break;
	case 0xe0004008:
		data = io.timer[0].tc;
		//io.vic.risr &= ~IRQ_TC0;
		//printf("SKYEYE:Clear TC Interrupt,tc=%x,risr=%x,\n",data,io.vic.risr);
		//lpc_update_int(state);
		break;
	case 0xe000400c:
		data = io.timer[0].pr;
		break;
	case 0xe0004010:
		data = io.timer[0].pc;
		break;
	case 0xe0004014:
		data = io.timer[0].mcr;
		break;
	case 0xe0004018:
		data = io.timer[0].mr0;
		break;

/*pll*/
	case 0xe01fc080:
		data = io.pll.con;
		break;
	case 0xe01fc084:
		data = io.pll.cfg;
		break;
	case 0xe01fc088:
		data = io.pll.stat;
		break;
	case 0xe01fc08c:
		data = io.pll.feed;
		break;
	case 0xe002c000:
		data = io.pinsel0;
		break;
	case 0xe01fc100:
		data = io.apbdiv;
		break;
	default:
		if (addr >= 0xe000c000 && addr <= 0xe000c01c) {
			data = lpc_uart_read (state, addr, 0);
			break;
		}
		if (addr >= 0xe0001000 && addr <= 0xe000101c) {
			data = lpc_uart_read (state, addr, 1);
			break;
		}
		if (addr - 0xfffff100 <= 0x3c && addr - 0xfffff100 >= 0) {
			data = io.vic.va[(addr - 0xfffff100) / 4];
			break;
		}
		if (addr - 0xfffff200 <= 0x3c && addr - 0xfffff200 >= 0) {
			data = io.vic.vc[(addr - 0xfffff200) / 4];
			break;
		}

		printf ("ERROR:io_read: addr = %x\n", addr);

		/*fprintf(stderr,"NumInstr %llu, io_read_word unknown addr(0x%08x) = 0x%08x\n", state->NumInstrs, addr, data); */
		SKYEYE_OUTREGS (stderr);
		//ARMul_Debug(state, 0, 0);
		break;
	}
	return data;
}

ARMword
lpc_io_read_byte (ARMul_State * state, ARMword addr)
{
	return lpc_io_read_word (state, addr);
//                      SKYEYE_OUTREGS(stderr);
	//exit(-1);

}

ARMword
lpc_io_read_halfword (ARMul_State * state, ARMword addr)
{
	return lpc_io_read_word (state, addr);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}


void
lpc_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	/*
	 * The lpc system registers
	 */


	switch (addr) {
	case 0xfffff000:	/* ISR */
		DBG_PRINT ("SKYEYE:can not write  ISR,it is RO,=%d\n", data);
		break;
	case 0xfffff004:	/* interrupt status register */
		//io.vic.fsr = data ;
//              DBG_PRINT("read ISR=%x,%x\n", data, io.intsr);
		DBG_PRINT ("can not write  fsr,it is RO,=%d\n", data);
		break;
	case 0xfffff008:	/* IMR */
		//io.vic.risr = data;
		DBG_PRINT ("can not write  risr,it is RO,=%d\n", data);
		break;
	case 0xfffff00c:	/* CORE interrupt status register */
		io.vic.islr = data;
		break;
	case 0xfffff010:	/* IER */
		io.vic.ier = data;
		io.vic.iecr = ~data;
		lpc_update_int (state);
//              data = unfix_int(io.intmr);
		DBG_PRINT ("write IER=%x,after update ier=%x\n", data,
			   io.vic.ier);
		break;
	case 0xfffff014:	/* IECR */
		io.vic.iecr = data;
		io.vic.ier = ~data;
		lpc_update_int (state);
		break;

	case 0xfffff018:	/* SIR */
		io.vic.sir = data;
		break;
	case 0xfffff01c:	/* SICR */
		io.vic.sicr = data;
		break;
	case 0xfffff020:	/* PER */
		io.vic.per = data;
		break;
	case 0xfffff030:	/* VAR */
		io.vic.var = data;
		break;
	case 0xfffff034:	/* DVAR */
		io.vic.dvar = data;
		break;


		/*Timer0 */
	case 0xe0004000:
		io.timer[0].ir = data;
		if (io.timer[0].ir & 0x1) {
			io.timer[0].ir &= 0x0;
			io.vic.risr &= ~IRQ_TC0;
		}
		lpc_update_int (state);
		break;
	case 0xe0004004:
		io.timer[0].tcr = data;
		break;
	case 0xe0004008:
		io.timer[0].tc = data;
		break;
	case 0xe000400c:
		io.timer[0].pr = data;
		break;
	case 0xe0004010:
		io.timer[0].pc = data;
		break;
	case 0xe0004014:
		io.timer[0].mcr = data;
		break;
	case 0xe0004018:
		io.timer[0].mr0 = data;
		break;

		/*pll */
	case 0xe01fc080:
		io.pll.con = data;
		break;
	case 0xe01fc084:
		io.pll.cfg = data;
		break;
	case 0xe01fc088:
		io.pll.stat = data;
		break;
	case 0xe01fc08c:
		io.pll.feed = data;
		break;

		/*memory map control */
	case 0xe01fc040:
		io.memmap = data;
		switch(io.memmap & 0x3){
#if 0
			case 0: /* Bootloader mode, vector is remaped to Boot Block */
			case 1: /* User Flash mode, vector is not remapped */
			case 3: /* User external memory module, vector is remapped to external memory */
#endif
			case 2: /* User ram mode, vector is remapped to static ram */
				state->vector_remap_flag = 1;
				state->vector_remap_addr = 0x40000000;
				break;
			default:
				printf ("ERROR:io_write memmap register to invalid value: data = %x\n", data);
		}
		break;
	case 0xe002c000:
		io.pinsel0 = data;
		break;
	case 0xe01fc100:
		io.apbdiv = data;
		switch (io.apbdiv & 3) {
			case 0:	skyeye_config.mach->io_cycle_divisor = 4; break;
			case 1:	skyeye_config.mach->io_cycle_divisor = 1; break;
			case 2:	skyeye_config.mach->io_cycle_divisor = 2; break;
			default: break; /* no effect */
		}
		break;
	default:
		if (addr >= 0xe000c000 && addr <= 0xe000c01c) {
			lpc_uart_write (state, addr, data, 0);
			break;
		}
		if (addr >= 0xe0001000 && addr <= 0xe000101c) {
			lpc_uart_write (state, addr, data, 1);
			break;
		}

		if (addr - 0xfffff100 <= 0x3c && addr - 0xfffff100 >= 0) {
			io.vic.va[(addr - 0xfffff100) / 4] = data;
			break;
		}
		if (addr - 0xfffff200 <= 0x3c && addr - 0xfffff200 >= 0) {
			io.vic.vc[(addr - 0xfffff200) / 4] = data;
			break;
		}
		printf ("ERROR:io_write a non-exsiting addr:addr = %x, data = %x\n", addr, data);
		/*
		   fprintf(stderr,"NumInstr %llu,io_write_word unknown addr(1x%08x) = 0x%08x\n", state->NumInstrs, addr, data); */
		//SKYEYE_OUTREGS(stderr);
		//ARMul_Debug(state, 0, 0);
		break;
	}
}

void
lpc_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{

	lpc_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);

}

void
lpc_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	lpc_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}


void
lpc_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = HIGH;

	this_mach->io_cycle_divisor = 4;
	this_mach->mach_io_do_cycle = lpc_io_do_cycle;
	this_mach->mach_io_reset = lpc_io_reset;
	this_mach->mach_io_read_byte = lpc_io_read_byte;
	this_mach->mach_io_write_byte = lpc_io_write_byte;
	this_mach->mach_io_read_halfword = lpc_io_read_halfword;
	this_mach->mach_io_write_halfword = lpc_io_write_halfword;
	this_mach->mach_io_read_word = lpc_io_read_word;
	this_mach->mach_io_write_word = lpc_io_write_word;

	this_mach->mach_update_int = lpc_update_int;

	//ksh 2004-2-7


	state->mach_io.instr = (ARMword *) & io.vic.isr;
	//*state->io.instr = (ARMword *)&io.intsr;
	//state->io->net_flags = (ARMword *)&io.net_flags;
	//state->mach_io.net_int = (ARMword *)&io.net_int;


}
