/*
	skyeye_mach_lh79520.c - define machine lh79520 for skyeye
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
 * 11/17/2004 	init this file.
 * 		add machine lh79520's function. 
 * 		include: lh79520_mach_init, lh79520_io_do_cycle
 * 		lh79520_io_read_word, lh79520_io_write_word
 *		Cai Qiang <caiqiang@ustc.edu> 		
 *
 * */

#include "armdefs.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "lh79520-hardware.h"
#include "lh79520_irq.h"
#include "serial_amba_pl011.h"
#include "lh79520.h"
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

#define REVISION "$Revision: 1.10 $"

#define TC_DIVISOR	(50)	/* Set your BogoMips here :) */

#define DEBUG 1

#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr,##a)
#else
#define DBG_PRINT(a...)
#endif

/*Internal IO Register*/
typedef struct lh79520_io
{
	ARMword intsr;		/* Interrupt status reg */
	ARMword intmr;		/* Interrupt mask reg */

	ARMword tcd[2];		/* Timer/counter data */
	ARMword tcd_reload[2];	/* Last value written */
	ARMword tcd_ctrl[2];	/* Timer Control Register */
	int tc_prescale;

	ARMword uartdr;		/* Receive Data Register */
	ARMword uartfr;		/* Flag Register */
	ARMword uartcr;		/* Control Register */
	ARMword uartimsc;	/* Interrupt Mask Set/Clear register */
	ARMword uartmis;	/* Masked Interrupt Status Register */
} lh79520_io_t;

static lh79520_io_t lh79520_io;
#define io lh79520_io

static void
lh79520_update_int (ARMul_State * state)
{
	ARMword requests = io.intsr & io.intmr;
	state->NfiqSig = (requests & 0x0001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffffffe) ? LOW : HIGH;
}

static void
lh79520_io_reset (ARMul_State * state)
{
	int i;

	io.intmr = 0;
	io.intsr = 0;
	for (i = 0; i < 2; i++) {
		io.tcd[i] = 0xffff;
		io.tcd_reload[i] = 0xffff;
		io.tcd_ctrl[i] = 0;
	}
	io.tc_prescale = TC_DIVISOR;
	io.uartdr = 0;
	io.uartfr = AMBA_UARTFR_TXFE;
}

static void
UART2VIC (ARMul_State * state)
{
	if (io.uartmis)
		io.intsr |= UART1INT;
	else
		io.intsr &= ~UART1INT;
	lh79520_update_int (state);
}


void
lh79520_io_do_cycle (ARMul_State * state)
{
	int t;

	io.tc_prescale--;
	if (io.tc_prescale < 0) {
		io.tc_prescale = TC_DIVISOR;

		for (t = 0; t < 2 - 1; t++) {	//only timer0 be supported now
			if (io.tcd[t] == 0) {
				if (io.tcd_ctrl[t] & TIMER_CONTROL_MODE) {	//Periodic mode
					io.tcd[t] = io.tcd_reload[t];
				}
				else {	//Free-Running mode
					io.tcd[t] = 0xffff;
				}
				io.intsr |= (t ? TC2OI : TC1OI);
				lh79520_update_int (state);
			}
			else {
				io.tcd[t]--;
			}
		}

		if (!(io.intsr & UART1INT)) {
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char buf;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
			{
				io.uartdr = (int) buf;
				io.uartfr &= ~AMBA_UARTFR_RXFE;
				io.uartmis |= AMBA_UART_IS_RX;
				UART2VIC (state);
			}
		}		//if (!(io.intsr & UART1INT))
	}
}


ARMword
lh79520_io_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data = 0;

	switch (addr) {
	case RCPC_PHYS:
	case RCPC_HCLKPrescale:
	case RCPC_periphClkCtrl:
	case IOCON_UARTMux:
	case UART1_PHYS + UARTLCR_H:
//                      printf("%s(%x)\n", __func__, addr);
		break;
	case UART1_PHYS + UARTCR:
		data = io.uartcr;
		break;
	case UART0_PHYS + UARTFR:
	case UART1_PHYS + UARTFR:
		data = io.uartfr;
		break;
	case UART1_PHYS + UARTRSR:
		data = 0;
		break;
	case UART1_PHYS + UARTIMSC:	//5: TXIM       4: RXIM
		data = io.uartimsc;
		break;
	case UART1_PHYS + UARTMIS:	//5: TXIM       4: RXIM 
		data = io.uartmis;
		break;
	case UART1_PHYS + UARTDR:
		data = io.uartdr;
		io.uartfr |= AMBA_UARTFR_RXFE;
		io.uartmis &= ~AMBA_UART_IS_RX;
		UART2VIC (state);
		break;
	case VIC_IRQStatus:
		data = io.intsr;
		break;
	case VIC_IntEnable:
		data = io.intmr;
		break;
        case RCPC_idString:
                data = 0x5200;  // Chip ID
                break;

	default:
//chy 2003-07-11: sometime has fault, but linux can continue running  !!!!????
		printf ("SKYEYE:unknown io addr, %s(0x%08x), pc %x \n",
			__func__, addr, state->Reg[15]);
		//SKYEYE_DBG("io_read_word(0x%08x) = 0x%08x\n", addr, data);
		break;
	}
	return data;
}

ARMword
lh79520_io_read_byte (ARMul_State * state, ARMword addr)
{
	//some parts of kernel such as printascii use byte operation
	if (addr >= UART1_PHYS + UARTDR && addr <= UART1_PHYS + UARTICR)
		return lh79520_io_read_word (state, addr);
	else {
		printf ("SKYEYE: %s error\n", __func__);
		printf ("SKYEYE: state->pc=%x,state->instr=%x,addr=%x\n",
			state->pc, state->instr, addr);
		system ("stty sane");
		skyeye_exit (-1);
	}
}

ARMword
lh79520_io_read_halfword (ARMul_State * state, ARMword addr)
{
	//some parts of kernel use it
	if (addr >= UART1_PHYS + UARTDR && addr <= UART1_PHYS + UARTICR)
		return lh79520_io_read_word (state, addr);
	else {
		printf ("SKYEYE: %s error %x\n", __func__, addr);
		system ("stty sane");
		skyeye_exit (-1);
	}
}

void
lh79520_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword tmp;

	if (addr >= VIC_VectAddr && addr <= VIC_VectAddr + 0x3c) {
//              printf("%s VectAddr(%x %x)\n", __func__, addr, data);
		return;
	}
	if (addr >= VIC_VectCntl && addr <= VIC_VectCntl + 0x3c) {
//              printf("%s VectCntl(%x %x)\n", __func__, addr, data);
		return;
	}
	if (addr >= DMAC_PHYS && addr < RCPC_PHYS) {
//              printf("%s DMAC(%x %x)\n", __func__, addr, data);
		return;
	}

	switch (addr) {
	case VIC_IntSelect:
	case IOCON_MiscMux:
	case IOCON_UARTMux:
	case RCPC_PHYS:
	case RCPC_idString:
	case RCPC_intClear:
	case RCPC_intConfig:
	case RCPC_HCLKPrescale:
	case RCPC_periphClkCtrl:
	case TIMER0_LOAD:
	case TIMER0_VALUE:
	case TIMER1_LOAD:
	case TIMER1_VALUE:
	case TIMER1_CONTROL:
	case TIMER1_CLEAR:
	case TIMER2_CONTROL:
	case TIMER3_CONTROL:
	case UART1_PHYS + UARTIBRD:
	case UART1_PHYS + UARTLCR_H:
//                      printf("%s(%x %x)\n", __func__, addr, data);
		break;
	case TIMER0_CONTROL:
		io.tcd_ctrl[0] = data;
		break;
	case TIMER0_CLEAR:
		io.intsr &= ~TC1OI;
		lh79520_update_int (state);
		break;
	case VIC_IntEnable:
		io.intmr = data;
		lh79520_update_int (state);
		break;
	case VIC_IntEnClear:
		io.intmr &= ~data;
		lh79520_update_int (state);
		break;

	case UART0_PHYS:
	case UART1_PHYS:
		/* The UART writes chars to console */
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);
		}
		break;
	case UART1_PHYS + UARTCR:
		io.uartcr = data;
		break;
	case UART1_PHYS + UARTIMSC:	//5: TXIM       4: RXIM
		io.uartimsc = data;
		if (data & AMBA_UART_IS_TX)
			io.uartmis |= AMBA_UART_IS_TX;
		else
			io.uartmis &= ~AMBA_UART_IS_TX;
		UART2VIC (state);
		break;

	default:
//chy 2003-07-11: sometime has fault, but linux can continue running  !!!!????
		printf ("SKYEYE:unknown io addr, %s(0x%08x, 0x%08x), pc %x \n", __func__, addr, data, state->Reg[15]);
		break;
	}
}
void
lh79520_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	//some parts of kernel such as printascii use byte operation
	if (addr >= UART1_PHYS + UARTDR && addr <= UART1_PHYS + UARTICR)
		return lh79520_io_write_word (state, addr, data);
	else {
		printf ("SKYEYE: %s(%x %x) error\n", __func__, addr, data);
		SKYEYE_OUTREGS (stderr);
		system ("stty sane");
		skyeye_exit (-1);
	}
}

void
lh79520_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: %s error %x %x\n", __func__, addr, data);
	skyeye_exit (-1);
}


void
lh79520_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	state->lateabtSig = HIGH;

//      state->Reg[1] = 999; //MACH_TYPE_LH79520EVB
	state->Reg[1] = 997;	//MACH_TYPE_LH79520LPD
	this_mach->mach_io_do_cycle = lh79520_io_do_cycle;
	this_mach->mach_io_reset = lh79520_io_reset;
	this_mach->mach_io_read_byte = lh79520_io_read_byte;
	this_mach->mach_io_write_byte = lh79520_io_write_byte;
	this_mach->mach_io_read_halfword = lh79520_io_read_halfword;
	this_mach->mach_io_write_halfword = lh79520_io_write_halfword;
	this_mach->mach_io_read_word = lh79520_io_read_word;
	this_mach->mach_io_write_word = lh79520_io_write_word;

	this_mach->mach_update_int = lh79520_update_int;

	state->mach_io.instr = (ARMword *) & io.intsr;
}
