/*
	skyeye_mach_s3c2440.c - define machine S3C2440 for skyeye
	Copyright (C) 2005 Skyeye Develop Group
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

#include "armdefs.h"
#include "s3c2440.h"
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

#define TC_DIVISOR	(1)	/* Set your BogoMips here :) may move elsewhere */

typedef struct s3c2440_io
{
	u32 srcpnd;		/* Indicate the interrupt request status */
	u32 intmod;		/* Interrupt mode register */
	u32 intmsk;		/* Determine which interrupt source is masked */
	u32 priority;		/* IRQ priority control register */
	u32 intpnd;		/* Indicate the interrupt request status */
	u32 intoffset;		/* Indicate the IRQ interrupt request source */
	u32 subsrcpnd;		/* Indicate the interrupt request status */
	u32 intsubmsk;		/* Determin which interrupt source is masked */
	struct s3c2440_timer_io timer;	/* Timer */
	struct s3c2440_uart_io uart0;	/* uart0 */
	struct s3c2440_clkpower clkpower;	/* clock and power management */

	int tc_prescale;


} s3c2440_io_t;
static s3c2440_io_t s3c2440_io;
#define io s3c2440_io


static inline void
s3c2440_set_subsrcint (unsigned int irq)
{
	io.subsrcpnd |= irq;
}
static inline void
s3c2440_update_subsrcint ()
{
	u32 requests;
	s3c2440_set_subsrcint (UART_INT_TXD << (0 * 3));
	s3c2440_set_subsrcint (UART_INT_TXD << (1 * 3));
	s3c2440_set_subsrcint (UART_INT_TXD << (2 * 3));
	requests = ((io.subsrcpnd & (~io.intsubmsk)) & 0x7fff);
	if (requests & 0x7)
		io.srcpnd |= INT_UART0;
	if (requests & 0x38)
		io.srcpnd |= INT_UART1;
	if (requests & 0x1c0)
		io.srcpnd |= INT_UART2;
	if (requests & 0x600)
		io.srcpnd |= INT_ADC;
}
static void
s3c2440_update_int (ARMul_State * state)
{
	ARMword requests;
	s3c2440_update_subsrcint ();
	requests = io.srcpnd & (~io.intmsk & INT_MASK_INIT);
	state->NfiqSig = (requests & io.intmod) ? LOW : HIGH;
	state->NirqSig = (requests & ~io.intmod) ? LOW : HIGH;
}

static void
s3c2440_io_reset (ARMul_State * state)
{
	memset (&s3c2440_io, 0, sizeof (s3c2440_io));
	io.tc_prescale = TC_DIVISOR;
	io.uart0.ulcon = UART_ULCON_INIT;
	io.uart0.utrstat = UART_UTRSTAT_INIT;
	//io.timer.tcnt[4] = 25350;

	io.clkpower.locktime = 0x00FFFFFF;
	io.clkpower.mpllcon = 0x0005C080;
	io.clkpower.upllcon = 0x00028080;
	io.clkpower.clkcon = 0x7FFF0;
	io.clkpower.clkslow = 0x4;

	io.intmsk = INT_MASK_INIT;
	io.intpnd = 0x0;
}


/* s3c2440 io_do_cycle */
static void
s3c2440_io_do_cycle (ARMul_State * state)
{
	
	io.tc_prescale--;
	if (io.tc_prescale < 0) {
		io.tc_prescale = TC_DIVISOR;
		if ((io.timer.tcon & 0x100000) != 0) {
			io.timer.tcnt[4]--;
			if (io.timer.tcnt[4] < 0) {
				io.timer.tcnt[4] = io.timer.tcntb[4];
				/*timer 4 hasn't tcmp */
				//io.timer.tcmp[4] = io.timer.tcmpb[4];
				io.timer.tcnto[4] = io.timer.tcntb[4];
				io.srcpnd |= INT_TIMER4;
				s3c2440_update_int (state);
				return;
			}
		}
		if (((io.uart0.utrstat & 0x1) == 0x0)
		    && ((io.uart0.ucon & 0x3) == 0x1)) {
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char buf;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
			{
				io.uart0.urxh = (int) buf;
				/* Receiver Ready
				 * */
				io.uart0.utrstat |= (0x1);
				/* pending usart0 interrupt
				 * */
				s3c2440_set_subsrcint (UART_INT_RXD <<
						       (0 * 3));
				//io.srcpnd |= INT_UART0;
				s3c2440_update_int (state);
				return;
			}
		}
		//s3c2440_update_int (state);
	}			/* if (io.tc_prescale < 0) */
}


static void
s3c2440_uart_read (u32 offset, u32 * data)
{
	switch (offset) {
	case ULCON:
		*data = io.uart0.ulcon;
		break;
	case UCON:
		*data = io.uart0.ucon;
		break;
	case UFCON:
		*data = io.uart0.ufcon;
		break;
	case UMCON:
		*data = io.uart0.umcon;
		break;
	case UTRSTAT:
		*data = io.uart0.utrstat;
		break;
	case UERSTAT:
		*data = io.uart0.uerstat;
		break;
	case UFSTAT:
		*data = io.uart0.ufstat;
		break;
	case UMSTAT:
		*data = io.uart0.umstat;
		break;
	case URXH:
		/* receive char
		 * */
		*data = io.uart0.urxh;
		io.uart0.utrstat &= (~0x1);	/* clear strstat register bit[0] */
		break;
	case UBRDIV:
		*data = io.uart0.ubrdiv;
		break;
	default:
		break;
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}

static void
s3c2440_uart_write (ARMul_State * state, u32 offset, u32 data)
{

	SKYEYE_DBG ("s3c2440_uart_write(0x%x, 0x%x)\n", offset, data);
	switch (offset) {
	case ULCON:
		io.uart0.ulcon = data;
		break;
	case UCON:
		io.uart0.ucon = data;
		break;
	case UFCON:
		io.uart0.ufcon = data;
		break;
	case UMCON:
		io.uart0.umcon = data;
		break;
	case UTRSTAT:
		io.uart0.utrstat = data;
		break;
	case UERSTAT:
		io.uart0.uerstat = data;
		break;
	case UFSTAT:
		io.uart0.ufstat = data;
		break;
	case UMSTAT:
		io.uart0.umstat = data;
		break;
	case UTXH:
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			io.uart0.utrstat |= 0x6;	//set strstat register bit[0]
			if ((io.uart0.ucon & 0xc) == 0x4) {
				s3c2440_set_subsrcint (UART_INT_TXD <<
						       (0 * 3));
				s3c2440_update_int (state);
			}
		}
		break;
	case UBRDIV:
		io.uart0.ubrdiv = data;
		break;
	default:
		break;
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}

static void
s3c2440_timer_read (u32 offset, u32 * data)
{
	switch (offset) {
	case TCFG0:
		*data = io.timer.tcfg0;
		break;
	case TCFG1:
		*data = io.timer.tcfg1;
		break;
	case TCON:
		*data = io.timer.tcon;
		break;
	case TCNTB0:
	case TCNTB1:
	case TCNTB2:
	case TCNTB3:
	case TCNTB4:
		{
			int n = (offset - 0xC) / 0xC;
			*data = io.timer.tcntb[n];
		}
		break;
	case TCMPB0:
	case TCMPB1:
	case TCMPB2:
	case TCMPB3:
		{
			int n = (offset - 0x10) / 0xC;
			*data = io.timer.tcmpb[n];
		}
		break;
	case TCNTO0:
	case TCNTO1:
	case TCNTO2:
	case TCNTO3:
		{
			int n = (offset - 0x10) / 0xC;
			*data = io.timer.tcnto[n];
		}
		break;
	case TCNTO4:
		*data = io.timer.tcnto[4];
		break;
	default:
		break;
	}
}

static void
s3c2440_timer_write (ARMul_State * state, u32 offset, u32 data)
{
	switch (offset) {
	case TCFG0:
		io.timer.tcfg0 = data;
		break;
	case TCFG1:
		io.timer.tcfg1 = data;
		break;
	case TCON:
		{
			io.timer.tcon = data;
			if (io.timer.tcon) {
			}
		}
		break;
	case TCNTB0:
	case TCNTB1:
	case TCNTB2:
	case TCNTB3:
	case TCNTB4:
		{
			int n = (offset - 0xC) / 0xC;
			//io.timer.tcntb[n] = data;
			io.timer.tcntb[n] = 25350;
		}
		break;
	case TCMPB0:
	case TCMPB1:
	case TCMPB2:
	case TCMPB3:
		{
			int n = (offset - 0x10) / 0xC;
			io.timer.tcmpb[n] = data;
		}
		break;
	default:
		break;
	}
}

static ARMword
s3c2440_io_read_word (ARMul_State * state, ARMword addr)
{

	ARMword data = -1;
	int i;
	/*uart0 */
	if ((addr >= UART_CTL_BASE0)
	    && (addr < (UART_CTL_BASE0 + UART_CTL_SIZE))) {
		s3c2440_uart_read ((u32) (addr - UART_CTL_BASE0),
				   (u32 *) & data);
	}
	if ((addr >= PWM_CTL_BASE) && (addr < (PWM_CTL_BASE + PWM_CTL_SIZE))) {
		s3c2440_timer_read ((u32) (addr - PWM_CTL_BASE),
				    (u32 *) & data);
	}
	switch (addr) {
	case SRCPND:
		data = io.srcpnd;
		break;
	case INTMOD:
		data = io.intmod;
		break;
	case INTMSK:
		data = io.intmsk;
		break;
	case PRIORITY:
		data = io.priority;
		break;
	case INTPND:
	case INTOFFSET:
		{
			/*find which interrupt is pending */
			int i;
			for (i = 0; i < 32; i++) {
				if (io.srcpnd & (1 << i))
					break;
			}
			if (i < 32) {
				io.intoffset = i;
				io.intpnd = (1 << i);
				if (addr == INTPND)
					data = (1 << i);
				else
					data = i;
			}
			else
				data = 0;

		}
		io.intpnd = (1 << io.intoffset);
		//printf ("io.intoffset:%x, io.intpnd:%x (0x%08x) = 0x%08x\n", io.intoffset, io.intpnd, addr, data);
		break;
	case SUBSRCPND:
		data = io.subsrcpnd;
		break;
	case INTSUBMSK:
		data = io.intsubmsk;
		break;
		/* GPIO Register */
	case GSTATUS1:
		data = 0x32410000;
		break;
		/* Clock and Power Management Registers */
	case LOCKTIME:
		data = io.clkpower.locktime;
		break;
	case MPLLCON:
		data = io.clkpower.mpllcon;
		break;
	case UPLLCON:
		data = io.clkpower.upllcon;
		break;
	case CLKCON:
		data = io.clkpower.clkcon;
		break;
	case CLKSLOW:
		data = io.clkpower.clkslow;
		break;
	case CLKDIVN:
		data = io.clkpower.clkdivn;
		break;
	default:
		break;
	}
	return data;
}

static ARMword
s3c2440_io_read_byte (ARMul_State * state, ARMword addr)
{
	s3c2440_io_read_word (state, addr);
}

static ARMword
s3c2440_io_read_halfword (ARMul_State * state, ARMword addr)
{
	s3c2440_io_read_word (state, addr);
}

static void
s3c2440_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	if ((addr >= UART_CTL_BASE0)
	    && (addr < UART_CTL_BASE0 + UART_CTL_SIZE)) {
		s3c2440_uart_write (state, addr - UART_CTL_BASE0, data);
	}
	if ((addr >= PWM_CTL_BASE) && (addr < (PWM_CTL_BASE + PWM_CTL_SIZE))) {
		s3c2440_timer_write (state, addr - PWM_CTL_BASE, data);
	}
	switch (addr) {
	case SRCPND:
		io.srcpnd &= (~data & INT_MASK_INIT);
		break;
	case INTMOD:
		io.intmod = data;
		break;
	case INTMSK:
		io.intmsk = data;
		s3c2440_update_int (state);
		break;
	case PRIORITY:
		io.priority = data;
		break;
	case INTPND:
		io.intpnd &= (~data & INT_MASK_INIT);
		io.intoffset = 0;
		//printf ("io.intoffset:%x, io.intpnd:%x (0x%08x) = 0x%08x, pc:%x\n", io.intoffset, io.intpnd, addr, data, state->pc);
		break;
		/*read only */
		//case INTOFFSET:
		//      break;
	case SUBSRCPND:
		io.subsrcpnd &= (~data & INT_SUBMSK_INIT);
		break;
	case INTSUBMSK:
		io.intsubmsk = data;
		break;
	default:
		SKYEYE_DBG ("io_write_word(0x%08x) = 0x%08x\n", addr, data);
		break;
	}
}

static void
s3c2440_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: s3c2440_io_write_byte error\n");
	s3c2440_io_write_word (state, addr, data);
}

static void
s3c2440_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: s3c2440_io_write_halfword error\n");
	s3c2440_io_write_word (state, addr, data);
}


void
s3c2440_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	/* ARM920T uses LOW */
	state->lateabtSig = LOW;

	state->Reg[1] = 241;	//ARCH_S3C2440
	this_mach->mach_io_do_cycle = s3c2440_io_do_cycle;
	this_mach->mach_io_reset = s3c2440_io_reset;
	this_mach->mach_io_read_byte = s3c2440_io_read_byte;
	this_mach->mach_io_write_byte = s3c2440_io_write_byte;
	this_mach->mach_io_read_halfword = s3c2440_io_read_halfword;
	this_mach->mach_io_write_halfword = s3c2440_io_write_halfword;
	this_mach->mach_io_read_word = s3c2440_io_read_word;
	this_mach->mach_io_write_word = s3c2440_io_write_word;

	this_mach->mach_update_int = s3c2440_update_int;

}
