/*
	skyeye_mach_cs89712.c - define machine cs89712 for skyeye
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
 * 		add machine cs89712's function. Most taken from original armio.c. 
 * 		include: cs89712_mach_init, cs89712_io_do_cycle
 * 		cs89712_io_read_word, cs89712_io_write_word
 *		Most taken from skyeye_mach_ep7312.c		
 *		<trilok_soni@yahoo.co.in>
 * */

#include "armdefs.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "clps7110.h"
#include "ep7212.h"
#include "cs89712.h"
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

/*Internal IO Register*/
typedef struct cs89712_io
{
	ARMword syscon;		/* System control */
	ARMword sysflg;		/* System status flags */

	ARMword intsr;		/* Interrupt status reg */
	ARMword intmr;		/* Interrupt mask reg */

	ARMword tcd[2];		/* Timer/counter data */
	ARMword tcd_reload[2];	/* Last value written */
	int tc_prescale;

	ARMword uartdr;		/* Receive data register */

	ARMword lcdcon;		/* LCD control */
	ARMword lcd_limit;	/* 0xc0000000 <= LCD buffer < lcd_limit */
} cs89712_io_t;

static cs89712_io_t cs89712_io;
#define io cs89712_io

static void
cs89712_update_int (ARMul_State * state)
{
	ARMword requests = io.intsr & io.intmr;
	state->NfiqSig = (requests & 0x0001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffe) ? LOW : HIGH;
}
static void
cs89712_io_reset (ARMul_State * state)
{
	io.syscon = 0;
	io.sysflg = URXFE;
	io.intmr = 0;
	io.intsr = UTXINT;	/* always ready to transmit */
	io.tcd[0] = 0xffff;
	io.tcd[1] = 0xffff;
	io.tcd_reload[0] = 0xffff;
	io.tcd_reload[1] = 0xffff;
	io.uartdr = 0;
	io.lcdcon = 0;
	io.lcd_limit = 0;
}


void
cs89712_io_do_cycle (ARMul_State * state)
{
	int t;


	for (t = 0; t < 2; t++) {
		if (io.tcd[t] == 0) {

			if (io.syscon & (t ? TC2M : TC1M)) {

				io.tcd[t] = io.tcd_reload[t];
			}
			else {
				io.tcd[t] = 0xffff;
			}
			io.intsr |= (t ? TC2OI : TC1OI);
			cs89712_update_int (state);
		}
		else {
			io.tcd[t]--;
		}
	}
	if (!(io.intsr & URXINT)) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;
		unsigned char buf;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
			io.uartdr = (int) buf;

			io.sysflg &= ~URXFE;
			io.intsr |= URXINT;
			cs89712_update_int (state);
		}
	}
}


ARMword
cs89712_io_read_byte (ARMul_State * state, ARMword addr)
{
	/*printf("SKYEYE: cs89712_io_read_byte error\n"); */
	skyeye_exit (-1);
}

ARMword
cs89712_io_read_halfword (ARMul_State * state, ARMword addr)
{
	/*printf("SKYEYE: cs89712_io_read_halfword error\n"); */
	skyeye_exit (-1);
}

ARMword
cs89712_io_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data = 0;

	switch (addr - 0x80000000) {
	case SYSCON:
		data = io.syscon;
		break;
	case SYSFLG:
		data = io.sysflg;
		break;
/*	case MEMCFG1:
 *	case MEMCFG2:
 *	case DRFPR */
	case INTSR:
		data = io.intsr;
		break;
	case INTMR:
		data = io.intmr;
		break;
	case LCDCON:
		data = io.lcdcon;
		break;
	case TC1D:
		data = io.tcd[0];
		break;
	case TC2D:
		data = io.tcd[1];
		break;
/*	case RTCDR:
 *	case RTCMR:
 *	case PMPCON :
 *	case CODR:*/
	case UARTDR:
		data = io.uartdr;
		io.sysflg |= URXFE;
		io.intsr &= ~URXINT;
		extern ARMul_State * state;
		cs89712_update_int (state);
		break;
/*	case UBRLCR:		*/
	case SYNCIO:
		/* if we return zero here, the battery voltage calculation
		 *         results in a divide-by-zero that messes up the kernel */
		data = 1;
		break;
/*	case PALLSW:
 *	case PALMSW:*/

		/* write-only: */
	case STFCLR:
	case BLEOI:
	case MCEOI:
	case TEOI:
	case TC1EOI:
	case TC2EOI:
	case RTCEOI:
	case UMSEOI:
	case COEOI:
	case HALT:
	case STDBY:
		break;
	default:
//chy 2003-07-11: sometime has fault, but linux can continue running  !!!!????
		//SKYEYE_DBG("io_read_word(0x%08x) = 0x%08x\n", addr, data);
		break;
	}
	return data;
}



void
cs89712_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: cs89712_io_write_byte error\n");
	skyeye_exit (-1);
}

void
cs89712_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: cs89712_io_write_halfword error\n");
	skyeye_exit (-1);
}

void
cs89712_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword tmp;

	switch (addr - 0x80000000) {
	case SYSCON:
		tmp = io.syscon;
		io.syscon = data;
		/*if ((tmp & LCDEN) != (data & LCDEN)) {
		   update_lcd(state);
		   } */
		break;
	case SYSFLG:
		break;
	case INTSR:
		break;
	case INTMR:
		io.intmr = data;
		extern ARMul_State * state;
		cs89712_update_int (state);
		break;
	case LCDCON:
		tmp = io.lcdcon;
		io.lcdcon = data;
		if ((tmp & (VBUFSIZ | LINELEN | GSEN | GSMD)) !=
		    (tmp & (VBUFSIZ | LINELEN | GSEN | GSMD))) {
			//chy 2005-01-07 no use now
			/* update_lcd(state); */
		}
		break;
	case TC1D:
		io.tcd[0] = io.tcd_reload[0] = data & 0xffff;
		SKYEYE_DBG ("TC1D 0x%x\n", data & 0xffff);
		break;
	case TC2D:
		io.tcd[1] = io.tcd_reload[1] = data & 0xffff;
		SKYEYE_DBG ("TC2D 0x%x\n", data & 0xffff);
		break;
	case UARTDR:
		/* The UART writes chars to console */
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);
		}
		break;
/*	case BLEOI: printf("BLEOI\n"); break;
	case MCEOI: printf("MCEOI\n"); break;
	case TEOI: printf("TEOI\n"); break;*/
	case TC1EOI:
		io.intsr &= ~TC1OI;
		extern ARMul_State * state;
		cs89712_update_int (state);
		SKYEYE_DBG ("TC1EOI\n");
		break;
	case TC2EOI:
		io.intsr &= ~TC2OI;
		extern ARMul_State * state;
		cs89712_update_int (state);
		SKYEYE_DBG ("TC2EOI\n");
		break;
		//case RTCEOI: printf("RTCEOI\n"); break;
		//case UMSEOI: printf("UMSEOI\n"); break;
		//case COEOI: printf("COEOI\n"); break;
	case 0x2000:
		/* Not a real register, for debugging only: */
		SKYEYE_DBG ("io_write_word debug: 0x%08lx\n", data);
		break;
	default:
		//chy 2003-07-11: sometime has fault, but linux can continue running  !!!!????
		//printf("unknown io addr, io_write_word(0x%08x, 0x%08x), pc %x \n", addr, data,state->Reg[15]);
		break;
	}
}

void
cs89712_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	state->abort_model = 2;
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = HIGH;

	state->Reg[1] = 107;	//for cdb89712 arch id
	this_mach->mach_io_do_cycle = cs89712_io_do_cycle;
	this_mach->mach_io_reset = cs89712_io_reset;
	this_mach->mach_io_read_byte = cs89712_io_read_byte;
	this_mach->mach_io_write_byte = cs89712_io_write_byte;
	this_mach->mach_io_read_halfword = cs89712_io_read_halfword;
	this_mach->mach_io_write_halfword = cs89712_io_write_halfword;
	this_mach->mach_io_read_word = cs89712_io_read_word;
	this_mach->mach_io_write_word = cs89712_io_write_word;

	this_mach->mach_update_int = cs89712_update_int;
}
