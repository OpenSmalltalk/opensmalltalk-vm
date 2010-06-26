/*
	skyeye_mach_ns9750.c - define machine NS9750 for skyeye
	Copyright (C) 2003 - 2005 Skyeye Develop Group
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
 * 10/31/2004 	complete UART, Timer, Interrupt, now it can boot ARMLinux successfully.
 *		walimis <wlm@student.dlut.edu.cn> 
 * 5/23/2004 	init this file.
 *		walimis <wlm@student.dlut.edu.cn> 
 *		
 * */

#include "armdefs.h"
#include "ns9750.h"
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

typedef struct ns9750_io
{
	u32 ivr;		/*AIC Interrupt Vector Register */
	u32 fvr;		/*AIC FIQ Vector Register */
	u32 isr;		/*AIC Interrupt Status Register */
	u32 ipr;		/*AIC Interrupt Pending Register */
	u32 imr;		/*AIC Interrupt Mask Register */
	u32 cisr;
	u32 iecr;
	u32 idcr;
	u32 iccr;
	u32 iscr;
	u32 eoicr;
	u32 spu;

	struct ns9750_st_io st;	/*system timer */
	struct ns9750_uart_io uart0;	/*uart0 */

	int tc_prescale;


} ns9750_io_t;
static ns9750_io_t ns9750_io;
#define io ns9750_io

static void
ns9750_update_int (ARMul_State * state)
{
	ARMword requests = io.ipr & io.imr;
	state->NfiqSig = (requests & 0x00001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffffffe) ? LOW : HIGH;
}

/* new added functions
 * */
static void
ns9750_set_intr (u32 interrupt)
{
	io.ipr |= (1 << interrupt);
}
static int
ns9750_pending_intr (u32 interrupt)
{
	return ((io.ipr & (1 << interrupt)));
}

#if 0
static void
ns9750_update_intr (void *mach)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	ARMword requests = io.ipr & io.imr;
	state->NfiqSig = (requests & 0x00001) ? LOW : HIGH;
	state->NirqSig = (requests & 0x3fffe) ? LOW : HIGH;

}
static int
ns9750_mem_read_byte (void *mach, u32 addr, u32 * data)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	*data = (u32) mem_read_char (state, addr);
}
static int
ns9750_mem_write_byte (void *mach, u32 addr, u32 data)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	mem_write_char (state, addr, (char) data);
}
#endif

static void
ns9750_io_reset (ARMul_State * state)
{

	io.uart0.csr = 0x00000202;
	/* CHRL : 11 8bit
	 * */
	io.uart0.mr = 0x000000c0;
	io.uart0.brgr = 0x000000c0;

}


/*ns9750 io_do_cycle*/
static void
ns9750_io_do_cycle (ARMul_State * state)
{
#if 1


	if (io.st.pimr != 0) {
		if (io.st.piv_dc == 0) {
			io.st.sr |= AT91RM92_ST_PITS;
			if (io.st.imr & AT91RM92_ST_PITS) {
				io.ipr |= AT91RM92_ID_SYS;
			}
			io.st.piv_dc = io.st.pimr;
		}
		else {
			io.st.piv_dc--;
		}
	}
	if ((io.uart0.imr & AT91RM92_US_RXRDY)) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;
		unsigned char buf;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
			io.uart0.rhr = (int) buf;
			/* Receiver Ready
			 * */
			io.uart0.csr |= AT91RM92_US_RXRDY;
			/* pending usart0 interrupt
			 * */
			io.ipr |= AT91RM92_ID_US0;
		}
	}			/* if (rcr > 0 && ... */
	ns9750_update_int (state);
#endif
}


static void
ns9750_uart_read (u32 offset, u32 * data)
{
	switch (offset) {
	case US_MR:
		*data = io.uart0.mr;
		break;
	case US_IMR:
		*data = io.uart0.imr;
		break;
	case US_CSR:
		*data = io.uart0.csr;
		break;
	case US_RHR:
		/* receive char
		 * */
		*data = io.uart0.rhr;
		io.uart0.csr &= (~AT91RM92_US_RXRDY);
		break;
	case US_BRGR:
		*data = io.uart0.brgr;
		break;
	case US_RTOR:
		*data = io.uart0.rtor;
		break;
	case US_TTGR:
		*data = io.uart0.ttgr;
		break;
	case US_FIDI:
		*data = io.uart0.fidi;
		break;
	case US_NER:
		*data = io.uart0.ner;
		break;
	case US_IF:
		*data = io.uart0.us_if;
		break;
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}

static void
ns9750_uart_write (ARMul_State * state, u32 offset, u32 data)
{

	SKYEYE_DBG ("ns9750_uart_write(0x%x, 0x%x)\n", offset, data);
	switch (offset) {
	case US_CR:
		io.uart0.cr = data;
		break;
	case US_MR:
		io.uart0.mr = data;
		break;
	case US_IER:
		//io.uart0.ier = data;
		io.uart0.imr |= (data & 0x000f3fff);
		if (io.uart0.imr) {
			io.ipr |= AT91RM92_ID_US0;
			ns9750_update_int (state);
		}
		break;
	case US_IDR:
		/* disable usart0 corresponding interrupt
		 * */
		io.uart0.imr &= (~data) & 0x000f3fff;
		break;
	case US_THR:
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			io.uart0.csr |= AT91RM92_US_TXRDY;
		}
		//io.uart0.thr = data;
		break;
	case US_BRGR:
		io.uart0.brgr = data;
		break;
	case US_RTOR:
		io.uart0.rtor = data;
		break;
	case US_TTGR:
		io.uart0.ttgr = data;
		break;
	case US_FIDI:
		io.uart0.fidi = data;
		break;
	case US_IF:
		io.uart0.us_if = data;
		break;
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}



static void
ns9750_st_read (u32 offset, u32 * data)
{
	switch (offset) {
	case ST_PIMR:
		*data = io.st.pimr;
		break;
	case ST_WDMR:
		*data = io.st.wdmr;
		break;
	case ST_RTMR:
		*data = io.st.rtmr;
		break;
	case ST_SR:
		*data = io.st.sr;
		/* reinitialize it to zero */
		io.st.sr = 0x0;
		break;
	case ST_IMR:
		*data = io.st.imr;
		break;
	case ST_RTAR:
		*data = io.st.rtar;
		break;
	case ST_CRTR:
		*data = io.st.crtr;
		break;
	}
}
static void
ns9750_st_write (ARMul_State * state, u32 offset, u32 data)
{
	switch (offset) {
	case ST_CR:
		io.st.cr = data;
		io.st.wdv_dc = io.st.wdmr;
		break;
	case ST_PIMR:
		io.st.pimr = data;
		io.st.piv_dc = data;
		break;
	case ST_WDMR:
		io.st.wdmr = data;
		io.st.wdv_dc = data;
		break;
	case ST_RTMR:
		io.st.rtmr = data;
		io.st.rtpres_dc = data;
		break;
	case ST_IER:
		io.st.imr |= (data & 0x0000000f);
		if (io.st.imr) {
			io.ipr |= AT91RM92_ID_SYS;
			ns9750_update_int (state);
		}
		break;
	case ST_IDR:
		io.st.imr &= (~data) & 0xf;
		break;
	case ST_RTAR:
		io.st.rtar = data;
		break;
	}
}

static ARMword
ns9750_io_read_word (ARMul_State * state, ARMword addr)
{

	ARMword data = -1;
	int i;
	/*uart0 */
	if ((addr >= AT91RM92_UART_BASE0) &&
	    (addr < (AT91RM92_UART_BASE0 + AT91RM92_UART_SIZE))) {
		ns9750_uart_read ((u32) (addr - AT91RM92_UART_BASE0),
				  (u32 *) & data);
	}
	if ((addr >= AT91RM92_ST_BASE0) &&
	    (addr < (AT91RM92_ST_BASE0 + AT91RM92_ST_SIZE))) {
		ns9750_st_read ((u32) (addr - AT91RM92_ST_BASE0),
				(u32 *) & data);
	}
	switch (addr) {
	case AIC_IVR:		/* IVR */
		data = io.ipr;
		SKYEYE_DBG ("IVR irqs=%x ", data);
		for (i = 0; i < 32; i++)
			if (data & (1 << i))
				break;
		if (i < 32) {
			data = i;
			io.ipr &= ~(1 << data);
			ns9750_update_int (state);
		}
		else
			data = 0;
		io.ivr = data;
		SKYEYE_DBG ("read IVR=%d\n", data);
		break;
	case AIC_ISR:		/* ISR: interrupt status register */
		data = io.ivr;
		break;
	case AIC_IMR:		/* IMR */
		data = io.imr;
		break;
	case AIC_CISR:		/* CISR: Core interrupt status register */
		data = io.cisr;
		data = io.imr;
		SKYEYE_DBG ("read CISR=%x,%x\n", data, io.cisr);
		break;
	default:
		break;
	}
	return data;
}

static ARMword
ns9750_io_read_byte (ARMul_State * state, ARMword addr)
{
	SKYEYE_DBG ("SKYEYE: ns9750_io_read_byte error\n");
	ns9750_io_read_word (state, addr);
}

static ARMword
ns9750_io_read_halfword (ARMul_State * state, ARMword addr)
{
	SKYEYE_DBG ("SKYEYE: ns9750_io_read_halfword error\n");
	ns9750_io_read_word (state, addr);
}

static void
ns9750_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	if ((addr >= AT91RM92_UART_BASE0) &&
	    (addr < AT91RM92_UART_BASE0 + AT91RM92_UART_SIZE)) {
		ns9750_uart_write (state, addr - AT91RM92_UART_BASE0, data);
	}
	if ((addr >= AT91RM92_ST_BASE0) &&
	    (addr < (AT91RM92_ST_BASE0 + AT91RM92_ST_SIZE))) {
		ns9750_st_write (state, addr - AT91RM92_ST_BASE0, data);
	}
	switch (addr) {
	case AIC_IECR:		/* IECR */
		io.iecr = data;
		io.imr |= data;
		break;
	case AIC_IDCR:		/* IDCR */
		io.idcr = data;
		io.imr &= ~data;
		break;
	case AIC_ICCR:		/* CLEAR interrupts */
		io.iccr = data;
		io.ipr &= ~data;
		break;
	case AIC_EOICR:	/* EOI */
		io.eoicr = data;
		io.ipr &= ~data;
		ns9750_update_int (state);
		break;
	default:
		SKYEYE_DBG ("io_write_word(0x%08x) = 0x%08x\n", addr, data);
		break;
	}
}

static void
ns9750_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: ns9750_io_write_byte error\n");
	ns9750_io_write_word (state, addr, data);
}

static void
ns9750_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: ns9750_io_write_halfword error\n");
	ns9750_io_write_word (state, addr, data);
}


void
ns9750_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	ARMul_SelectProcessor (state, ARM_v5_Prop | ARM_v5e_Prop);
	/* FIXME:ARM926EJS uses LOW? */
	state->lateabtSig = LOW;

	state->Reg[1] = 552;	//for NS9750
	//state->Reg[1] = 627;  //for NS9750
	//state->Reg[1] = 196;  //for NS9750
	this_mach->mach_io_do_cycle = ns9750_io_do_cycle;
	this_mach->mach_io_reset = ns9750_io_reset;
	this_mach->mach_io_read_byte = ns9750_io_read_byte;
	this_mach->mach_io_write_byte = ns9750_io_write_byte;
	this_mach->mach_io_read_halfword = ns9750_io_read_halfword;
	this_mach->mach_io_write_halfword = ns9750_io_write_halfword;
	this_mach->mach_io_read_word = ns9750_io_read_word;
	this_mach->mach_io_write_word = ns9750_io_write_word;

	this_mach->mach_update_int = ns9750_update_int;

	//this_mach->mach_set_intr =              ns9750_set_intr;
	//this_mach->mach_pending_intr =          ns9750_pending_intr;
	//this_mach->mach_update_intr =           ns9750_update_intr;

	//this_mach->mach_mem_read_byte =       ns9750_mem_read_byte;
	//this_mach->mach_mem_write_byte =      ns9750_mem_write_byte;

	//this_mach->state = (void *)state;


}
