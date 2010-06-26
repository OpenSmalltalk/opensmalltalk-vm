/*
	skyeye_mach_ep7312.c - define machine ep7312 for skyeye
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
 * 3/24/2003 	init this file.
 * 		add machine ep7312's function. Most taken from original armio.c. 
 * 		include: ep7312_mach_init, ep7312_io_do_cycle
 * 		ep7312_io_read_word, ep7312_io_write_word
 *		walimis <walimi@peoplemail.com.cn> 		
 *
 * */

#include "armdefs.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "clps7110.h"
//zzc:
#ifdef __CYGWIN__
//chy 2005-07-28
#include <time.h>
//teawater add DBCT_TEST_SPEED 2005.10.04---------------------------------------
/*struct timeval
{
	int tv_sec;
	inttv_usec;
};*/
//AJ2D--------------------------------------------------------------------------
#endif


/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

//ywc 2004-04-01
extern unsigned int Pen_buffer[8];	// defined in skyeye_lcd.c

#define DEBUG 1

#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr,##a)
#else
#define DBG_PRINT(a...)
#endif


/*Internal IO Register*/
typedef struct ep7312_io
{
	ARMword syscon;		/* System control */
	ARMword sysflg;		/* System status flags */

	ARMword intsr;		/* Interrupt status reg */
	ARMword intmr;		/* Interrupt mask reg */
	ARMword intmr2;
	ARMword intmr3;

	ARMword tcd[2];		/* Timer/counter data */
	ARMword tcd_reload[2];	/* Last value written */

	ARMword uartdr;		/* Receive data register */

	//ywc,2004-04-01
	ARMword ts_int;		/* ywc 2004-04-02 */
	ARMword ts_buffer[8];
	//ARMword               tsaddr;                 /* ??? touch srceen data buffer start address*/
	ARMword ts_addr_begin;
	ARMword ts_addr_end;



	//2004-06-21
	ARMword padr;
	ARMword pbdr;
	ARMword pddr;
	ARMword paddr;
	ARMword pbddr;
	ARMword pdddr;
	ARMword pedr;
	ARMword peddr;
} ep7312_io_t;

static ep7312_io_t ep7312_io;
#define io ep7312_io


static void
ep7312_update_int (ARMul_State * state)
{
	ARMword requests = io.intsr & io.intmr;
	state->NfiqSig = (requests & 0x0001) ? LOW : HIGH;
	state->NirqSig = (requests & 0xfffe) ? LOW : HIGH;
}
static void
ep7312_io_reset (ARMul_State * state)
{
	memset(&io, 0, sizeof(io));

	io.syscon = LCDEN;
	io.sysflg = URXFE;
	io.intmr = 0;

	io.intsr = UTXINT;	/* always ready to transmit */

	io.tcd[0] = 0xffff;
	io.tcd[1] = 0xffff;
	io.tcd_reload[0] = 0xffff;
	io.tcd_reload[1] = 0xffff;
	io.uartdr = 0;

	//ywc 2004-04-01
	//io.tsaddr             =0x0;
	io.ts_int = EINT2;	/* ywc 2004-04-02 use EINT2 as touch screen interrupt */
	io.ts_addr_begin = 0x8000b000;
	io.ts_addr_end = 0x8000b01f;
}


void
ep7312_io_do_cycle (ARMul_State * state)
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
			ep7312_update_int (state);
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
			ep7312_update_int (state);
		}
	}			//if (!(io.intsr & URXINT))

	// ywc 2004-04-01 for touch screen interrupt
#ifndef NO_LCD
	{
		if (!(io.intsr & io.ts_int)) {	//if now has no ts interrupt,then query 
			if (Pen_buffer[6] == 1) {	//should trigger a interrupt
				*(io.ts_buffer + 0) = Pen_buffer[0];
				*(io.ts_buffer + 1) = Pen_buffer[1];
				*(io.ts_buffer + 4) = Pen_buffer[4];
				*(io.ts_buffer + 6) = Pen_buffer[6];
				//set EINT2 bit to trigger a interrupt,ts driver will clear it
				io.intsr |= io.ts_int;
				Pen_buffer[6] = 0;
			}
		}
	}
#endif
}


ARMword
ep7312_io_read_byte (ARMul_State * state, ARMword addr)
{
	ARMword data = -1;
	unsigned char offset = 0;
	unsigned char ret;
	switch (addr - 0x80000000) {
	case PADR:
		data = io.padr;
		break;
	case PBDR:
		data = io.pbdr;
		break;
	case PDDR:
		data = io.pddr;
		break;
	case PADDR:
		data = io.paddr;
		break;
	case PBDDR:
		data = io.pbddr;
		break;
	case PDDDR:
		data = io.pdddr;
		break;
	case PEDR:
		data = io.pedr;
		break;
	case PEDDR:
		data = io.peddr;
		break;
	default:
		printf ("SKYEYE: ep7312_io_read_byte error\n");
		printf ("SKYEYE: state->pc=%x,state->instr=%x,addr=%x\n",
			state->pc, state->instr, addr);
		skyeye_exit (-1);
		break;
	}
	return data;
}

ARMword
ep7312_io_read_halfword (ARMul_State * state, ARMword addr)
{
	printf ("SKYEYE: ep7312_io_read_halfword error\n");
	skyeye_exit (-1);
}

ARMword
ep7312_io_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data = 0;
	ARMword ts_addr;

	//ywc 2004-04-01 read the touch srceen data buffer,return to the ts device driver
	ts_addr = addr & ~3;	// 1 word==4 byte
	if (ts_addr >= io.ts_addr_begin && ts_addr <= io.ts_addr_end) {
		data = io.ts_buffer[(ts_addr - io.ts_addr_begin) / 4];
		return data;
	}
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
		ep7312_update_int (state);
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
ep7312_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	//fprintf(stderr,"skyeye:ep7312_io_write_byte,@addr is  %x",addr);
	unsigned char offset = 0;
	unsigned char ret;
	switch (addr - 0x80000000) {
	case PADR:
		io.padr = data;
		break;
	case PBDR:
		io.pbdr = data;
		break;
	case PDDR:
		io.pddr = data;
		break;
	case PADDR:
		io.paddr = data;
		break;
	case PBDDR:
		io.pbddr = data;
		break;
	case PDDDR:
		io.pdddr = data;
		break;
	case PEDR:
		data = io.pedr;
		break;
	case PEDDR:
		io.peddr = data;
		break;
	case INTMR3:
		io.intmr3 = data;	
		break;
	case INTMR2:
		io.intmr2 = data;
		break;
	default:
		printf ("SKYEYE: ep7312_io_write_byte error@@@@@@@\n");
		SKYEYE_OUTREGS (stderr);
		skyeye_exit (-1);
		break;
	}
}

void
ep7312_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: ep7312_io_write_halfword error\n");
	skyeye_exit (-1);
}

void
ep7312_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword tmp;

	switch (addr - 0x80000000) {
	case SYSCON:
		tmp = io.syscon;
		io.syscon = data;
		//chy 2004-03-11
		if ((tmp & LCDEN) != (data & LCDEN)) {
			// by ywc 2004-07-07
			printf ("\n\n SYSCON:will call ep7312_update_lcd()");
			//ep7312_update_lcd (state);
		}
		break;
	case SYSFLG:
		break;
	case INTSR:
		//DBG_PRINT("write INTSR=0x%x\n", data);
		io.intsr = data;
		//      printf("SKYEYE: write INTSR=0x%x\n", io.intsr);
		break;
	case INTMR:
		//DBG_PRINT("write INTMR=0x%x\n", data);
		//if(data != 0x2000 && data != 0x2200)
		//printf("SKYEYE: write INTMR=0x%x\n", data);
		io.intmr = data;
		extern ARMul_State * state;
		ep7312_update_int (state);
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
		ep7312_update_int (state);
		SKYEYE_DBG ("TC1EOI\n");
		break;
	case TC2EOI:
		io.intsr &= ~TC2OI;
		extern ARMul_State * state;
		ep7312_update_int (state);
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
		//printf("SKYEYE:unknown io addr, io_write_word(0x%08x, 0x%08x), pc %x \n", addr, data,state->Reg[15]);
		break;
	}
}

void
ep7312_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	state->abort_model = 2;
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = HIGH;

	state->Reg[1] = 91;	//for EP7212/EP7312 arch id
	this_mach->mach_io_do_cycle = ep7312_io_do_cycle;
	this_mach->mach_io_reset = ep7312_io_reset;
	this_mach->mach_io_read_byte = ep7312_io_read_byte;
	this_mach->mach_io_write_byte = ep7312_io_write_byte;
	this_mach->mach_io_read_halfword = ep7312_io_read_halfword;
	this_mach->mach_io_write_halfword = ep7312_io_write_halfword;
	this_mach->mach_io_read_word = ep7312_io_read_word;
	this_mach->mach_io_write_word = ep7312_io_write_word;

	this_mach->mach_update_int = ep7312_update_int;

	this_mach->state = (void *) state;
}
