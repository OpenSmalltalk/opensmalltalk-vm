/*
	skyeye_mach_at91rm92.c - define machine AT91RM9200 for skyeye
	Copyright (C) 2004 Skyeye Develop Group
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
#include "at91rm92.h"
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

#define UART_NUM 4

typedef struct at91rm92_io
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
	u32 pio_pdsr;

	struct at91rm92_st_io st;	/* system timer */
	struct at91rm92_uart_io uart[UART_NUM];	/* uart */
	struct at91rm92_dbgu_io dbgu; /* Debug unit */
	struct at91rm92_pmc_io pmc;

	int tc_prescale;


} at91rm92_io_t;
static at91rm92_io_t at91rm92_io;
#define io at91rm92_io

static void
at91rm92_update_int (ARMul_State * state)
{
	ARMword requests = io.ipr & io.imr;
	state->NfiqSig = (requests & 0x00001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffffffe) ? LOW : HIGH;
}

/* new added functions
 * */
static void
at91rm92_set_intr (u32 interrupt)
{
	io.ipr |= (1 << interrupt);
}
static int
at91rm92_pending_intr (u32 interrupt)
{
	return ((io.ipr & (1 << interrupt)));
}

#if 0
static void
at91rm92_update_intr (void *mach)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	ARMword requests = io.ipr & io.imr;
	state->NfiqSig = (requests & 0x00001) ? LOW : HIGH;
	state->NirqSig = (requests & 0x3fffe) ? LOW : HIGH;

}
static int
at91rm92_mem_read_byte (void *mach, u32 addr, u32 * data)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	*data = (u32) mem_read_char (state, addr);
}
static int
at91rm92_mem_write_byte (void *mach, u32 addr, u32 data)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	mem_write_char (state, addr, (char) data);
}
#endif

static void
at91rm92_io_reset (ARMul_State * state)
{
	int i = 0;
	for(;i < UART_NUM; i++){
		io.uart[i].csr = 0x00000202;
		io.uart[i].mr = 0x000000c0;
		io.uart[i].brgr = 0x000000c0;
	}

	io.dbgu.sr = 0x22;

	io.pmc.pmc_mckr=0x202;

	io.pmc.ckgr_pllbr = 0x3F00;
	io.pmc.ckgr_pllar = 0x3F00;
}


/*at91rm92 io_do_cycle*/
static void
at91rm92_io_do_cycle (ARMul_State * state)
{

	if (io.st.pimr != 0) {
		if (io.st.piv_dc == 0) {
			io.st.sr |= AT91RM92_ST_PITS;
			if (io.st.imr & AT91RM92_ST_PITS) {
				io.ipr |= AT91RM92_ID_SYS;
			}
			io.st.piv_dc = io.st.pimr;
		}
		else {
			io.st.crtr++;
			io.st.piv_dc--;
		}
	}


	if (1) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;
		unsigned char buf;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
		        int i = 0;
		        for(;i < UART_NUM; i++){
				if( (((io.uart[i].cr & 0x30) >> 4)) == 0x1 ) /* If RX is enabled */
				{
					if(io.uart[i].imr & AT91RM92_US_RXRDY)
					{
						io.uart[i].rhr = (int) buf;
						/* Receiver Ready
						 * */
						io.uart[i].csr |= AT91RM92_US_RXRDY;
						/* pending usart0 interrupt
						 * */
						io.ipr |= AT91RM92_ID_US(i);
					}
				}
			}
			if(io.dbgu.cr & 0x10) /* If RXEN is set */
			{
				/* at the same time we think DBGU is also waiting to receiving */
				io.dbgu.rhr = (int) buf;
				io.dbgu.sr |= 0x1; /* set TXRDY bit */ 
			}
		}
	}			/* if (rcr > 0 && ... */
	at91rm92_update_int (state);
}


static void
at91rm92_uart_read (u32 offset, u32 * data)
{
	int i = (offset >> 14) & 0x3;
        offset = offset & 0xFFF;

	switch (offset) {
	case US_MR:
		*data = io.uart[i].mr;
		break;
	case US_IMR:
		*data = io.uart[i].imr;
		break;
	case US_CSR:
		*data = io.uart[i].csr;
		break;
	case US_RHR:
		/* receive char
		 * */
		*data = io.uart[i].rhr;
		io.uart[i].csr &= (~AT91RM92_US_RXRDY);
		break;
	case US_BRGR:
		*data = io.uart[i].brgr;
		break;
	case US_RTOR:
		*data = io.uart[i].rtor;
		break;
	case US_TTGR:
		*data = io.uart[i].ttgr;
		break;
	case US_FIDI:
		*data = io.uart[i].fidi;
		break;
	case US_NER:
		*data = io.uart[i].ner;
		break;
	case US_IF:
		*data = io.uart[i].us_if;
		break;
	default:
		fprintf(stderr,"in %s, io error, offset=0x%x\n", __FUNCTION__, offset);
		skyeye_exit(-1);
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}

static void
at91rm92_uart_write (ARMul_State * state, u32 offset, u32 data)
{

	SKYEYE_DBG ("at91rm92_uart_write(0x%x, 0x%x)\n", offset, data);

	int i = (offset >> 14) & 0x3;
	offset = offset & 0xFFF;

	switch (offset) {
	case US_CR:
		io.uart[i].cr = data;
		break;
	case US_MR:
		io.uart[i].mr = data;
		break;
	case US_IER:
		//io.uart0.ier = data;
		io.uart[i].imr |= (data & 0x000f3fff);
		if (io.uart[i].imr) {
			io.ipr |= AT91RM92_ID_US(i);
			extern ARMul_State * state;
			at91rm92_update_int (state);
		}
		break;
	case US_IDR:
		/* disable usart0 corresponding interrupt
		 * */
		io.uart[i].imr &= (~data) & 0x000f3fff;
		break;
	case US_THR:
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			io.uart[i].csr |= AT91RM92_US_TXRDY;
		}
		//io.uart0.thr = data;
		break;
	case US_BRGR:
		io.uart[i].brgr = data;
		break;
	case US_RTOR:
		io.uart[i].rtor = data;
		break;
	case US_TTGR:
		io.uart[i].ttgr = data;
		break;
	case US_FIDI:
		io.uart[i].fidi = data;
		break;
	case US_IF:
		io.uart[i].us_if = data;
		break;
	default:
		fprintf(stderr, "IO error in %s, offset=0x%x\n", __FUNCTION__, offset);
		skyeye_exit(-1);
	}
	SKYEYE_DBG ("%s(0x%x, 0x%x)\n", __func__, offset, data);
}



static void
at91rm92_st_read (u32 offset, u32 * data)
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
	default:
                fprintf(stderr, "IO error in %s, offset=0x%x\n", __FUNCTION__, offset);
                skyeye_exit(-1);

	}
}
static void
at91rm92_st_write (ARMul_State * state, u32 offset, u32 data)
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
			extern ARMul_State * state;
			at91rm92_update_int (state);
		}
		break;
	case ST_IDR:
		io.st.imr &= (~data) & 0xf;
		break;
	case ST_RTAR:
		io.st.rtar = data;
		break;
	default:
                fprintf(stderr, "IO error in %s, offset=0x%x\n", __FUNCTION__, offset);
                skyeye_exit(-1);
	}
}

static ARMword
at91rm92_io_read_word (ARMul_State * state, ARMword addr)
{

	ARMword data = -1;
	int i;
	/*uart0 */
	if ((addr >= AT91RM92_UART_BASE) &&
	    (addr < (AT91RM92_UART_BASE + UART_NUM * AT91RM92_UART_SIZE))) {
		at91rm92_uart_read ((u32) (addr - AT91RM92_UART_BASE),
				    (u32 *) & data);
		return data;
	}
	if ((addr >= AT91RM92_ST_BASE0) &&
	    (addr < (AT91RM92_ST_BASE0 + AT91RM92_ST_SIZE))) {
		at91rm92_st_read ((u32) (addr - AT91RM92_ST_BASE0),
				  (u32 *) & data);
		return data;
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
			extern ARMul_State * state;
			at91rm92_update_int (state);
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
	case DBGU_MR:
		data = io.dbgu.mr;
		break;
	case DBGU_IMR:
		data = io.dbgu.imr;
		break;
	case DBGU_RHR:
		data = io.dbgu.rhr;
		io.dbgu.sr &= ~(0x1); /*set RXRDY to zero */
		break;
	case DBGU_SR:
		//fprintf(stderr, "read DBGU_SR\n");
		data = io.dbgu.sr;
		break;
	case DBGU_CIDR:
		data = 0x4070080; /* RO register, see p331 of at914m9200 manual*/
		break;
	case CKGR_PLLBR:
		data = io.pmc.ckgr_pllbr;
		break;
	case CKGR_PLLAR:
		data = io.pmc.ckgr_pllar;
		break;
	case PMC_MCKR:
		data = io.pmc.pmc_mckr;
		break;
	case PMC_SR:
		data = io.pmc.pmc_sr;
		fprintf(stderr,"read sr=0x%x\n", data);
		break;
	case PIO_PDSR:
		data = io.pio_pdsr;
		break;
	default:
		fprintf(stderr,"In %s, io error, addr=0x%x\n", __FUNCTION__, addr);
		break;
	}
	return data;
}

static ARMword
at91rm92_io_read_byte (ARMul_State * state, ARMword addr)
{
	SKYEYE_DBG ("SKYEYE: at91rm92_io_read_byte error\n");
	at91rm92_io_read_word (state, addr);
}

static ARMword
at91rm92_io_read_halfword (ARMul_State * state, ARMword addr)
{
	SKYEYE_DBG ("SKYEYE: at91rm92_io_read_halfword error\n");
	at91rm92_io_read_word (state, addr);
}

static void
at91rm92_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	if ((addr >= AT91RM92_UART_BASE) &&
	    (addr < AT91RM92_UART_BASE + UART_NUM * AT91RM92_UART_SIZE)) {
		at91rm92_uart_write (state, addr - AT91RM92_UART_BASE, data);
		return;
	}
	if ((addr >= AT91RM92_ST_BASE0) &&
	    (addr < (AT91RM92_ST_BASE0 + AT91RM92_ST_SIZE))) {
		at91rm92_st_write (state, addr - AT91RM92_ST_BASE0, data);
		return;
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
		extern ARMul_State * state;
		at91rm92_update_int (state);
		break;
	case DBGU_IER:
		io.dbgu.ier = data;
		break;
	case DBGU_THR:
		io.dbgu.thr = data;

		char c = data;
                skyeye_uart_write(-1, &c, 1, NULL);
		
		io.dbgu.sr |= 0x2; /* set TXRDY bit */
		io.dbgu.sr |= 0x20; /* set TXEMPTY bit */

		break;
	case DBGU_CR:
		io.dbgu.cr = data;
		break;
	case DBGU_IDR:
		io.dbgu.idr = data;
		if(io.dbgu.idr & AT91RM92_US_TXEMPTY)
			io.dbgu.sr |= AT91RM92_US_TXEMPTY;
		break;
	case DBGU_MR:
		io.dbgu.mr = data;
		break;
	case DBGU_BRGR:
		io.dbgu.brgr = data;
		break;
	case CKGR_PLLBR:
                io.pmc.ckgr_pllbr = data;
		if(io.pmc.ckgr_pllbr)
                	io.pmc.pmc_sr |=  AT91_PMC_LOCKB;
		else
			io.pmc.pmc_sr &= ~AT91_PMC_LOCKB;
                break;

	default:
		//fprintf(stderr,"in %s, io error, addr=0x%x, pc = 0x%x\n", __FUNCTION__, addr, state->pc);
		//SKYEYE_DBG ("io_write_word(0x%08x) = 0x%08x\n", addr, data);
		break;
	}
}

static void
at91rm92_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: at91rm92_io_write_byte error\n");
	at91rm92_io_write_word (state, addr, data);
}

static void
at91rm92_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	SKYEYE_DBG ("SKYEYE: at91rm92_io_write_halfword error\n");
	at91rm92_io_write_word (state, addr, data);
}


void
at91rm92_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	/* ARM920T uses LOW */
	state->lateabtSig = LOW;

	state->Reg[1] = 251;	//for AT91RM9200
	state->Reg[1] = 262;	//for AT91RM9200DK
	//state->Reg[1] = 705;    // AT91RM9200EK
	this_mach->mach_io_do_cycle = at91rm92_io_do_cycle;
	this_mach->mach_io_reset = at91rm92_io_reset;
	this_mach->mach_io_read_byte = at91rm92_io_read_byte;
	this_mach->mach_io_write_byte = at91rm92_io_write_byte;
	this_mach->mach_io_read_halfword = at91rm92_io_read_halfword;
	this_mach->mach_io_write_halfword = at91rm92_io_write_halfword;
	this_mach->mach_io_read_word = at91rm92_io_read_word;
	this_mach->mach_io_write_word = at91rm92_io_write_word;

	this_mach->mach_update_int = at91rm92_update_int;
	at91rm92_io_reset(state);

	this_mach->mach_set_intr =              at91rm92_set_intr;
	this_mach->mach_pending_intr =          at91rm92_pending_intr;
	//this_mach->mach_update_intr =           at91rm92_update_intr;

	//this_mach->mach_mem_read_byte =       at91rm92_mem_read_byte;
	//this_mach->mach_mem_write_byte =      at91rm92_mem_write_byte;

	this_mach->state = (void *)state;
}
