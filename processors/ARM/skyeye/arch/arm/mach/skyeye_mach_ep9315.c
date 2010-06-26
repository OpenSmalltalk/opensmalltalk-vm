/*
	skyeye_mach_ep9315.c - define machine ep9315 for skyeye
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

#include "armdefs.h"
#include "clps9312.h"
#include "ep9315.h"
#include "serial_amba.h"
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


#define TC_DIVISOR	(50)	/* Set your BogoMips here :) */
void ep9315_io_write_word (ARMul_State * state, ARMword addr, ARMword data);
ARMword ep9315_io_read_word (ARMul_State * state, ARMword addr);



#define NR_UART			3

#define UART_FR_TXFE	(1<<7)
#define UART_FR_RXFE	(1<<4)

#define UART_IIR_RIS	(1<<1)
#define UART_IIR_TIS	(1<<2)


const int TCOI[2] = { 1 << 4, 1 << 5 };
const int UART_RXINTR[3] = { 1 << 23, 1 << 25, 1 << 27 };
const int UART_TXINTR[3] = { 1 << 24, 1 << 26, 1 << 28 };
const int INT_UART[3] = { 1 << (52 - 32), 1 << (54 - 32), 1 << (55 - 32) };
const int iConsole = 0;		//index of uart of serial console

/*Internal IO Register*/
typedef struct ep9315_io
{
	ARMword syscon_devcfg;	/* System control */

	ARMword intsr[2];	/* Interrupt status reg */
	ARMword intmr[2];	/* Interrupt mask reg */

	struct ep9315_tc_io tc[4];
	struct ep9315_uart_io uart[NR_UART];
	int tc_prescale;

} ep9315_io_t;

static ep9315_io_t ep9315_io;
#define io ep9315_io

static void
ep9315_update_int (ARMul_State * state)
{
	ARMword requests = io.intsr[0] & io.intmr[0];
	requests |= io.intsr[1] & io.intmr[1];

	state->NfiqSig = (requests & 0x0001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffe) ? LOW : HIGH;
}

static void
ep9315_io_reset (ARMul_State * state)
{
	int i;
	io.syscon_devcfg = 0;
	io.intmr[0] = 0;
	io.intmr[1] = 0;

	/* reset TC register */
	io.tc[0].value = 0;
	io.tc[1].value = 0;
	io.tc[2].value = 0;
	io.tc[0].mod_value = 0xffff;
	io.tc[1].mod_value = 0xffff;
	io.tc[2].mod_value = 0xffffffff;

	io.tc_prescale = TC_DIVISOR;

	for (i = 0; i < NR_UART; i++) {
		io.uart[i].dr = 0;
		io.uart[i].fr = UART_FR_TXFE;
	}
}


void
ep9315_io_do_cycle (ARMul_State * state)
{
	int i;


	io.tc_prescale--;
	if (io.tc_prescale < 0) {
		io.tc_prescale = TC_DIVISOR;

		/* We must implement TC1, TC2 and TC4 */
		for (i = 0; i < 2; i++) {
			if (io.tc[i].value == 0) {
				if (io.tc[i].ctl & TC_CTL_MODE)
					io.tc[i].value = io.tc[i].load;
				else
					io.tc[i].value = io.tc[i].mod_value;
				io.intsr[0] |= TCOI[i];
				ep9315_update_int (state);
			}
			else {
				io.tc[i].value--;
			}
		}
		io.tc[3].load++;

		if (!(io.intsr[0] & (UART_RXINTR[iConsole]))
		    && io.uart[iConsole].dr == 0) {
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char buf;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
			{
				io.uart[iConsole].dr = (int) buf;
				io.intsr[0] |= UART_RXINTR[iConsole];
				io.intmr[0] |= UART_RXINTR[iConsole];
				io.intsr[1] |= INT_UART[iConsole];
				io.intmr[1] |= INT_UART[iConsole];
				io.uart[iConsole].iir |= UART_IIR_RIS;
				io.uart[iConsole].fr &= ~UART_FR_RXFE;
				ep9315_update_int (state);
			}
		}		//if (!(io.intsr & URXINT))
	}
}


static void
ep9315_uart_read (ARMul_State * state, u32 offset, u32 * data, int index)
{
	switch (offset) {
	case UART_DR:
		*data = io.uart[index].dr;
		io.uart[index].dr = 0;
		io.intsr[0] &= ~(UART_RXINTR[index]);
		io.intsr[1] &= ~(INT_UART[index]);
		io.uart[index].iir &= ~UART_IIR_RIS;
		io.uart[index].fr |= UART_FR_RXFE;
		ep9315_update_int (state);
		break;
	case UART_RSR:
		*data = io.uart[index].rsr;
		break;
		//case UART_ECR:
	case UART_CR_H:
	case UART_CR_M:
	case UART_CR_L:
		break;
	case UART_CR:
		*data = io.uart[index].cr;
		break;
	case UART_FR:
		*data = io.uart[index].fr;
		break;
	case UART_IIR:
		*data = io.uart[index].iir;
		break;
		//case UART_ICR:
	case UART_ILPR:
	case UART_DMACR:
	case UART_TCR:
	case UART_TISR:
	case UART_TOCR:
	case UART_TMR:
	case UART_MCR:
	case UART_MSR:
		break;
	default:
		SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
		break;
	}
}
static void
ep9315_uart_write (ARMul_State * state, u32 offset, u32 data, int index)
{
	switch (offset) {
	case UART_DR:
		{
			char c = data;
#if 0
			write (skyeye_config.uart.fd_out, &c, 1);
#else
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);
#endif
		}
	case UART_RSR:
		//case UART_ECR:
	case UART_CR_H:
	case UART_CR_M:
	case UART_CR_L:
		break;
	case UART_CR:
		{
			io.uart[index].cr = data;
			if ((data & AMBA_UARTCR_TIE) == 0) {
				io.intmr[0] &= ~(UART_TXINTR[index]);
				io.intsr[0] &= ~(UART_TXINTR[index]);
				io.intsr[1] &= ~(INT_UART[index]);
				io.intmr[1] &= ~(INT_UART[index]);

				io.uart[index].iir &= ~(UART_IIR_TIS);	//Interrupt Identification and Clear
			}
			else {

				io.intmr[0] |= (UART_TXINTR[index]);
				io.intsr[0] |= (UART_TXINTR[index]);
				io.intsr[1] = (INT_UART[index]);
				io.intmr[1] = (INT_UART[index]);
				io.uart[index].iir |= (UART_IIR_TIS);
			}
			ep9315_update_int (state);
		}
		break;
	case UART_FR:
	case UART_IIR:
		io.uart[index].iir = data;
		break;
		//case UART_ICR:
	case UART_ILPR:
	case UART_DMACR:
	case UART_TCR:
	case UART_TISR:
	case UART_TOCR:
	case UART_TMR:
	case UART_MCR:
	case UART_MSR:
		break;
	default:
		SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
	}
}

/* Timer read/write register 
 */
static void
ep9315_tc_read (u32 offset, u32 * data, int index)
{
	if (index == 4) {
		if (offset == TC_VALUELOW)
			*data = io.tc[index].load;
		else if (offset == TC_VALUEHIGH)
			*data = io.tc[index].value;
	}
	switch (offset) {
	case TC_LOAD:
		*data = io.tc[index].load;
		break;
	case TC_VALUE:
		*data = io.tc[index].value;
		break;
	case TC_CTL:
		*data = io.tc[index].ctl;
		break;
	case TC_CLEAR:
		SKYEYE_DBG ("%s(0x%x, 0x%x): read WO register\n", __func__,
			    offset, data);
		break;
	default:
		SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
		break;
	}
}
static void
ep9315_tc_write (ARMul_State * state, u32 offset, u32 data, int index)
{
	switch (offset) {
	case TC_LOAD:
		io.tc[index].load = data;
		break;
	case TC_VALUE:
		SKYEYE_DBG ("%s(0x%x, 0x%x): write RO register\n", __func__,
			    offset, data);
		break;
	case TC_CTL:
		io.tc[index].ctl = data;
		break;
	case TC_CLEAR:
		io.intsr[0] &= ~TCOI[index];
		ep9315_update_int (state);
		break;
	default:
		SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
		break;
	}
}

ARMword
ep9315_io_read_byte (ARMul_State * state, ARMword addr)
{
	return ep9315_io_read_word (state, addr);
}

ARMword
ep9315_io_read_halfword (ARMul_State * state, ARMword addr)
{

	SKYEYE_DBG ("SKYEYE: %s error\n", __func__);
}

ARMword
ep9315_io_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data = 0;

	/* TC1 */
	if ((addr >= EP9315_TC_BASE1) &&
	    (addr < (EP9315_TC_BASE1 + EP9315_TC_SIZE))) {
		ep9315_tc_read ((u32) (addr - EP9315_TC_BASE1),
				(u32 *) & data, 0);
	}
	/* TC2 */
	if ((addr >= EP9315_TC_BASE4) &&
	    (addr < (EP9315_TC_BASE4 + EP9315_TC_SIZE))) {
		ep9315_tc_read ((u32) (addr - EP9315_TC_BASE4),
				(u32 *) & data, 3);
	}
	/* UART1 */
	if ((addr >= EP9315_UART_BASE1) &&
	    (addr < (EP9315_UART_BASE1 + EP9315_UART_SIZE))) {
		ep9315_uart_read (state, (u32) (addr - EP9315_UART_BASE1),
				  (u32 *) & data, 0);
		return data;
	}
	/* UART3 */
	if ((addr >= EP9315_UART_BASE3) &&
	    (addr < (EP9315_UART_BASE3 + EP9315_UART_SIZE))) {
		ep9315_uart_read (state, (u32) (addr - EP9315_UART_BASE3),
				  (u32 *) & data, 2);
		return data;
	}
	switch (addr) {
	case SYSCON_PWRCNT:
		break;
	case VIC0INTENABLE:
		data = io.intmr[0];
//              printf("%s(0x%08x) = 0x%08x\n", __func__, addr, data);
		break;
	case VIC0IRQSTATUS:
		data = io.intsr[0];
		io.intsr[0] = 0;	//!!!
		break;
	case VIC1IRQSTATUS:
		data = io.intsr[1];
		io.intsr[1] = 0;
		break;
	case RTCDR:
	case AACGCR:
	case AACRGIS:
//              printf("%s(0x%08x) = 0x%08x\n", __func__, addr, data);
		break;
	case SYSCON_DEVCFG:
		data = io.syscon_devcfg;
		break;
	default:
		SKYEYE_DBG ("SKYEYE:unknown io addr, %s(0x%08x) = 0x%08x\n",
			    __func__, addr, data);
		break;
	}
	return data;
}

void
ep9315_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	ep9315_io_write_word (state, addr, data);
}

void
ep9315_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: %s error\n", __func__);
}

void
ep9315_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword tmp;
	if ((addr >= EP9315_TC_BASE1) &&
	    (addr < (EP9315_TC_BASE1 + EP9315_TC_SIZE))) {
		ep9315_tc_write (state, (u32) (addr - EP9315_TC_BASE1), data,
				 0);
	}
	if ((addr >= EP9315_UART_BASE1) &&
	    (addr < (EP9315_UART_BASE1 + EP9315_UART_SIZE))) {
		ep9315_uart_write (state, (u32) (addr - EP9315_UART_BASE1),
				   data, 0);
	}
	if ((addr >= EP9315_UART_BASE3) &&
	    (addr < (EP9315_UART_BASE3 + EP9315_UART_SIZE))) {
		ep9315_uart_write (state, (u32) (addr - EP9315_UART_BASE3),
				   data, 2);
	}

	switch (addr) {
	case SYSCON_CLKSET1:
		break;
	case SYSCON_CLKSET2:
	case SYSCON_PWRCNT:
		break;
	case VIC0INTENABLE:
		io.intmr[0] = data;
		if (data != 0x10 && data != 0x20)
			printf ("SKYEYE: write VIC0INTENABLE=0x%x\n", data);
		ep9315_update_int (state);
		break;
	case VIC1INTENABLE:
		io.intmr[1] = data;
//              printf("SKYEYE: write VIC1INTENABLE=0x%x\n", data);

		ep9315_update_int (state);
		break;
	case VIC0INTENCLEAR:
		io.intmr[0] ^= data;
		ep9315_update_int (state);
		break;
	case VIC1INTENCLEAR:
		io.intmr[1] ^= data;
		ep9315_update_int (state);
		break;
	case SYSCON_DEVCFG:
		io.syscon_devcfg = data;
		break;
	default:
		SKYEYE_DBG
			("SKYEYE:unknown io addr, %s(0x%08x, 0x%08x), pc %x \n",
			 __func__, addr, data, state->Reg[15]);
		break;
	}
}

void
ep9315_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	/* ARM920T uses LOW */
	state->lateabtSig = LOW;

//      state->Reg[1] = 282;    //for EP9315 2.4.x arch id
	state->Reg[1] = 451;	//for EP9315 2.6.x arch id
	this_mach->mach_io_do_cycle = ep9315_io_do_cycle;
	this_mach->mach_io_reset = ep9315_io_reset;
	this_mach->mach_io_read_byte = ep9315_io_read_byte;
	this_mach->mach_io_write_byte = ep9315_io_write_byte;
	this_mach->mach_io_read_halfword = ep9315_io_read_halfword;
	this_mach->mach_io_write_halfword = ep9315_io_write_halfword;
	this_mach->mach_io_read_word = ep9315_io_read_word;
	this_mach->mach_io_write_word = ep9315_io_write_word;

	this_mach->mach_update_int = ep9315_update_int;

}
