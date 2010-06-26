/*
	skyeye_mach_ps7500.c - define machine ps7500 for skyeye
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
 * 3/2005 	init this file.
 * 		add machine ps7500's function. Most taken from original armio.c. 
 * 		include: ps7500_mach_init, ps7500_io_do_cycle
 * 		ps7500_io_read_word, ps7500_io_write_word
 *		Most taken from skyeye_mach_ep7312.c		
 * */

#include "armdefs.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "ps7500.h"

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

extern int skyeye_net_maxfd;
extern int skyeye_net_on;

#define TC_DIVISOR	(32)	/* Set your BogoMips here :) */
#define FLYBACK_DIVISOR	(1000000)
#define SOMETIMES_DIVISOR (100)

#define NET_ADDR_START	0x03010C00
#define NET_ADDR_END	(NET_ADDR_START +  0x00000400)
#define IOMD_ADDR_START	0x03200000
#define IOMD_ADDR_END	(IOMD_ADDR_START + 0x00001000)
#define VIDEO_ADDR	0x03400000

//zzc:2005-1-1
#ifdef __CYGWIN__
#include <sys/time.h>
#endif

#define PC (state->Reg[15])

#define DEBUG 1

#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr,##a)
#else
#define DBG_PRINT(a...)
#endif

/*Internal IO Register*/
typedef struct ps7500_io {
	ARMword		flyback;
	ARMword		prescale;
	ARMword		sometimes;
	ARMbyte		irq[5], irqmask[5];
	ARMbyte		fiq[1], fiqmask[1];

	ARMbyte		iocr_write;
	ARMbyte		iocr_read;
	
	ARMword		tcd_reload[2];		/* Timer load register */
	ARMword		tcd[2];			/* Timer data */
	int		tc_prescale;		/* Timer prescale */

	ARMword		vidstart, vidend, vidinit;
	ARMbyte		vidcr;
	
	ARMword		lcd_is_enable;
	ARMword		lcd_addr_begin;
	ARMword		lcd_addr_end;
	ARMword		ts_int;
	ARMword		ts_is_enable;
	ARMword		ts_addr_begin;
	ARMbyte		net_int[5];
	ARMword		net_flag;
	
	ARMbyte		kb_stat;
	ARMbyte		kb_data;
	ARMbyte		kb_queued[4096];
	ARMword		kb_count;
	ARMbyte		kb_delay;
	
	ARMbyte		lcd_started;
	
	
} ps7500_io_t;

static ps7500_io_t ps7500_io;
#define io ps7500_io

// Macros for setting/clearing interrupt bits
// I used an array since there were more than 32 interrupt sources
//    and so it didn't fit in a ARMword.   Thus, the network interrupt
//    source must be less than 32.

#define SET_BIT(v, x)	(v)[(x) / 8] |= (1 << ((x) % 8))
#define CLR_BIT(v, x)	(v)[(x) / 8] &= ~(1 << ((x) % 8))

#define SET_IRQ(x)	SET_BIT(io.irq, x); ps7500_update_int(state)
#define CLR_IRQ(x)	CLR_BIT(io.irq, x); ps7500_update_int(state)
#define SET_IRQMASK(x)	SET_BIT(io.irqmask); ps7500_update_int(state)
#define CLR_IRQMASK(x)	CLR_BIT(io.irqmask); ps7500_update_int(state)

#define SET_FIQ(x)	SET_BIT(io.fiq, x); ps7500_update_int(state)
#define CLR_FIQ(x)	CLR_BIT(io.fiq, x); ps7500_update_int(state)
#define SET_FIQMASK(x)	SET_BIT(io.fiqmask, x); ps7500_update_int(state)
#define CLR_FIQMASK(x)	CLR_BIT(io.fiqmask, x); ps7500_update_int(state)

// Indexes into IRQ array.   This must match IRQ numbers in ps7500.h

#define IRQA		0	
#define IRQB		1
#define IRQDMA		2
#define IRQC		3
#define IRQD		4

#define FIQ		0

extern ARMul_State * state;

ARMbyte ps7500_getcode(ARMbyte);

static void ps7500_update_int(ARMul_State *state)
{
	int i;
	
	//if (io.irq[IRQB] & io.net_int[IRQB]) {
	//	printf("Network interrupt set\n");
	//	for (i=0; i < 5; i++) {
	//		printf("IRQ[%d] %02x IRQMASK[%d] %02x\n", 
	//			i, io.irq[i], i, io.irqmask[i]);
	//	}
	//}
		
	
	state->NfiqSig = (io.fiq[FIQ] & io.fiqmask[FIQ]) ? LOW : HIGH;   

	state->NirqSig = 
		((io.irq[IRQA] & io.irqmask[IRQA]) ||
		 (io.irq[IRQB] & io.irqmask[IRQB]) ||
		 (io.irq[IRQC] & io.irqmask[IRQC]) ||
		 (io.irq[IRQD] & io.irqmask[IRQD]) ||
		 (io.irq[IRQDMA] & io.irqmask[IRQDMA])) ? LOW : HIGH;		 
}

/* 
 *  added some functions for device simulation by ksh
 * 
 */
static void
ps7500_set_intr (u32 interrupt)
{
	//io.irq |= (1 << interrupt);
	SET_IRQ(interrupt);
}
static int
ps7500_pending_intr (u32 interrupt)
{
	return io.irq[interrupt];
}
static void
ps7500_update_intr (void *mach)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;

	
        state->NfiqSig = (io.fiq[FIQ] & io.fiqmask[FIQ]) ? LOW : HIGH;

        state->NirqSig =
                ((io.irq[IRQA] & io.irqmask[IRQA]) ||
                 (io.irq[IRQB] & io.irqmask[IRQB]) ||
                 (io.irq[IRQC] & io.irqmask[IRQC]) ||
                 (io.irq[IRQD] & io.irqmask[IRQD]) ||
                 (io.irq[IRQDMA] & io.irqmask[IRQDMA])) ? LOW : HIGH;

}
static void ps7500_io_reset(ARMul_State *state)
{
	int i;
	
	for (i=0; i < 4; i++)
		io.irqmask[i] = io.irq[i] = 0;
	io.fiqmask[FIQ] = io.fiq[FIQ] = 0;
	io.irq[IRQA] = 0x80;			// SWI bit always true

	io.tcd[0] = io.tcd[1] = 0xffff;
	io.tcd_reload[0] = io.tcd_reload[1] = 0xffff;
	io.tc_prescale = TC_DIVISOR;
	
	io.lcd_addr_begin  	=0x10000000;
	io.lcd_addr_end   	=0x10004000;
	
	SET_BIT(io.net_int, IRQ_INT5);		// Network interrupt bit
	
	printf("netint %02x\n", io.net_int[IRQB]);
	
	io.sometimes = SOMETIMES_DIVISOR;
	
	io.lcd_started = 0;
		

	//state->Exception = TRUE;
}

ps7500_kb_queue(ARMul_State *state, ARMbyte c)
{
	io.kb_queued[io.kb_count++] = c;
	
	if ((io.kb_stat & (KB_TXB | KB_RXF)) == 0)
		ps7500_kb_next(state);
}

ps7500_kb_next(ARMul_State *state)
{
	int i;
	int p;
	
	if (io.kb_count) {
		io.kb_data = io.kb_queued[0];
		p = 0;
		for (i=0; i < 8; i++) 
			if (io.kb_data & (1 << i))
				p++;
		if (p % 2) 
			io.kb_stat &= ~KB_RXP;
		else
			io.kb_stat |= KB_RXP;
		io.kb_stat |= KB_RXF;
		SET_IRQ(IRQ_KEYBOARDRX); 
		io.kb_count--;
		if (io.kb_count)
			for (i=0; i < io.kb_count; i++) 
				io.kb_queued[i] = io.kb_queued[i+1];
	}
}

void ps7500_uart_cycle(ARMul_State *state)
{
	/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
	struct timeval tv;
	unsigned char buf, c;

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
	{
	    printf("read something %02x\n", buf);
	    c = ps7500_getcode(buf);
	    ps7500_kb_queue(state, c);
	    ps7500_kb_queue(state, 0xf0);
	    ps7500_kb_queue(state, c);
	}
}

void ps7500_io_do_cycle(ARMul_State *state)
{
	int t;
	
	// Timers
	
	io.tc_prescale--;
	if (io.tc_prescale < 0) {
		io.tc_prescale = TC_DIVISOR;		// 64 Mhz -> 2 Mhz 
		for (t=0; t < 2; t++) {
			if (io.tcd[t] == 0) {
				io.tcd[t] = io.tcd_reload[t];
				//DBG_PRINT("Timer %d interrupt\n", t);
				SET_IRQ(t ? IRQ_TIMER1 : IRQ_TIMER0);
			} else {
				io.tcd[t]--;
			}
		}
	}
	
	io.iocr_write |= 0x80;		// Flyback bit always true
	
	// VSYNC pulse interrupt 
	
	if (io.flyback == 0) {
		io.flyback = FLYBACK_DIVISOR;
		//DBG_PRINT("Flyback interrupt\n");
		SET_IRQ(IRQ_VSYNCPULSE);
	} else {
		io.flyback--;
	}
	
	// Make sure SWI interrupt bit stays set
	if ((io.irq[IRQA] & 0x80) == 0) {	
		io.irq[IRQA] |= 0x80;
		ps7500_update_int(state);
	}
	
	// Keyboard
	if (io.kb_delay != 0) {
		io.kb_delay--;
		if (io.kb_delay == 0) {
			io.kb_stat &= ~KB_TXB;
			io.kb_stat |= KB_TXE;
			SET_IRQ(IRQ_KEYBOARDTX);
			ps7500_kb_next(state);
		}
	}
	
	if (io.sometimes == 0) {
		ps7500_uart_cycle(state);
		io.sometimes = SOMETIMES_DIVISOR;
	} else {
		io.sometimes--;
	}		
}

ARMword ps7500_io_read_byte(ARMul_State *state, ARMword addr)
{
	ARMword data = 0;
	ARMword offset;

	if ((addr >= IOMD_ADDR_START) && (addr < IOMD_ADDR_END)) {
		offset = addr - IOMD_ADDR_START;
		switch (offset) {
		
		case IOMD_CONTROL:
			data = io.iocr_write | io.iocr_read;
			//DBG_PRINT("@0x%08x: IOCR(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
			
		case IOMD_IRQMASKA:
			data = io.irqmask[IRQA];
			//DBG_PRINT("@0x%08x: IRQMASKA(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQSTATA:
			data = io.irq[IRQA];
			//DBG_PRINT("@0x%08x: IRQSTATA(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQREQA:
			data = io.irq[IRQA] & io.irqmask[IRQA];
			//DBG_PRINT("@0x%08x: IRQREQA(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		
		case IOMD_IRQMASKB:
			data = io.irqmask[IRQB];
			//DBG_PRINT("@0x%08x: IRQMASKB(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQSTATB:
			data = io.irq[IRQB];
			//DBG_PRINT("@0x%08x: IRQSTATB(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQREQB:
			data = io.irq[IRQB] & io.irqmask[IRQB];
			//DBG_PRINT("@0x%08x: IRQREQB(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		
		case IOMD_IRQMASKC:
			data = io.irqmask[IRQC];
			//DBG_PRINT("@0x%08x: IRQMASKC(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQSTATC:
			data = io.irq[IRQC];
			//DBG_PRINT("@0x%08x: IRQSTATC(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQREQC:
			data = io.irq[IRQC] & io.irqmask[IRQC];
			//DBG_PRINT("@0x%08x: IRQREQC(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
				
		case IOMD_IRQMASKD:
			data = io.irqmask[IRQD];
			//DBG_PRINT("@0x%08x: IRQMASKD(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQSTATD:
			data = io.irq[IRQD];
			//DBG_PRINT("@0x%08x: IRQSTATD(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQREQD:
			data = io.irq[IRQD] & io.irqmask[IRQD];
			//DBG_PRINT("@0x%08x: IRQREQD(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		
		case IOMD_DMAMASK:
			data = io.irqmask[IRQDMA];
			//DBG_PRINT("@0x%08x: DMAMASK(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_DMASTAT:
			data = io.irq[IRQDMA];
			//DBG_PRINT("@0x%08x: DMASTAT(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_DMAREQ:
			data = io.irq[IRQDMA] & io.irqmask[IRQDMA];
			//DBG_PRINT("@0x%08x: DMAREQ(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		
		case IOMD_FIQSTAT:
			data = io.fiq[FIQ];
			//DBG_PRINT("@0x%08x: FIQSTAT(0x%08x) -> %02x\n",
			//	PC - 8, addr, data );
			break;
		case IOMD_FIQREQ:
			data = io.fiqmask[FIQ] & io.fiqmask[FIQ];
			//DBG_PRINT("@0x%08x: FIQREQ(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_KCTRL:
			data = io.kb_stat;
			//DBG_PRINT("@0x%08x: KCTRL(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		
		case IOMD_KARTRX:
			io.kb_stat &= ~KB_RXF;
			CLR_IRQ(IRQ_KEYBOARDRX);
			data = io.kb_data;
			ps7500_kb_next(state);
			//DBG_PRINT("@0x%08x: KARTRX(0x%08x) -> %02x\n",
			//	PC - 8, addr, data);
			break;
		}
		return data;
						
	}	
	
	if ((addr >= NET_ADDR_START) && (addr < NET_ADDR_END)) {
		offset = (addr - NET_ADDR_START) >> 2;
		DBG_PRINT("@0x%08x: Ethernet reg %03x read byte start\n",
			PC - 8, offset);
		//data = nic_read(0, state, offset);
		DBG_PRINT("@0x%08x: Ethernet reg %03x read byte 0x%02x\n",
			PC - 8, offset, data);
		return data;
	}
	
	DBG_PRINT("@0x%08x: io_read_byte(0x%08x) -> 0x%02x\n", PC - 8,
			 addr, data);
	return data;
}
ARMword ps7500_io_read_halfword(ARMul_State *state, ARMword addr)
{
	DBG_PRINT("SKYEYE: ps7500_io_read_halfword error\n");
}

FILE *fo = NULL;

#define RAMSTART	0x10000000
#define BANKOFFSET	0x04000000
#define BANKSIZE	0x00400000

ARMword ps7500_io_read_word(ARMul_State *state, ARMword addr)
{
	ARMword data = 0;
	ARMword data2;
	ARMword b;
	ARMword i;
	
	if (fo == NULL) {
		DBG_PRINT("Dumping memory\n");
		fo = fopen("mem.dump", "w");
		for (b=0; b < 4; b++) {
			for (i=0; i < BANKSIZE; i = i + 4) {
				/*
				data2 = real_read_word(state,
					 RAMSTART + (b * BANKOFFSET) + i); 	
				*/
				bus_read(32, RAMSTART + (b * BANKOFFSET) + i, &data2);
				fwrite(&data2, 4, 1, fo);
				
			
			}
		}
		fclose(fo);
		DBG_PRINT("Done\n");
	}			
	
	DBG_PRINT("io_read_word(0x%08x) = 0x%08x\n", addr, data);

	return data;
}

void ps7500_io_write_byte(ARMul_State *state, ARMword addr, ARMword data)
{
	ARMword offset;
	
	if ((addr >= IOMD_ADDR_START) && (addr < IOMD_ADDR_END)) {
		offset = addr - IOMD_ADDR_START;
		switch (offset) {
		
		case IOMD_CONTROL:
			io.iocr_write = data & 0x03;
			DBG_PRINT("@0x%08x: IOCR(0x%08x) <- 0x%02x\n",
				PC - 8, addr, data);
			break;
			
		case IOMD_IRQMASKA:
			io.irqmask[IRQA] = data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: IRQMASKA(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQCLRA:
			io.irq[IRQA] &= ~data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: IRQCLRA(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQMASKB:
			io.irqmask[IRQB]= data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: IRQMSKB(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQMASKC:
			io.irqmask[IRQC] = data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: IRQMASKC(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_IRQMASKD:
			io.irqmask[IRQD] = data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: IRQMASKD(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;		
		case IOMD_DMAMASK:
			io.irqmask[IRQDMA] = data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: DMAMSK(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;		
		case IOMD_FIQMASK:
			io.fiqmask[FIQ] = data;
			ps7500_update_int(state);
			//DBG_PRINT("@0x%08x: FIQMSK(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
			
		case IOMD_CLKCTL:
			//DBG_PRINT("@0x%08x: CLKCTL(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
			
		case IOMD_T0CNTL:
			io.tcd_reload[0] = (io.tcd_reload[0] & 0xff00) | data;
			//DBG_PRINT("@0x%08x: T0CNTL(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_T0CNTH:
			io.tcd_reload[0] = (io.tcd_reload[0] & 0x00ff) | data;
			//DBG_PRINT("T0CNTH(0x%08x) <- 0x%02x\n", PC - 8, addr, data);
			break;			
		case IOMD_T0GO:
			io.tcd[0] = io.tcd_reload[0];
			//DBG_PRINT("@0x%08x: T0GO(0x%08x) <- 0x%02x\n",	
			//	PC - 8, addr, data);
			break;			
		case IOMD_T1CNTL:
			io.tcd_reload[1] = (io.tcd_reload[1] & 0xff00) | data;
			DBG_PRINT("@0x%08x: T1CNTL(0x%08x) <- 0x%02x\n",
				PC - 8, addr, data);
			break;
		case IOMD_T1CNTH:
			io.tcd_reload[1] = (io.tcd_reload[1] & 0x00ff) | data;
			//DBG_PRINT("T1CNTH(0x%08x) <- 0x%02x\n", PC - 8, addr, data);
			break;			
		case IOMD_T1GO:
			io.tcd[1] = io.tcd_reload[1];
			//DBG_PRINT("@0x%08x: T1GO(0x%08x) <- 0x%02x\n",	
			//	PC - 8, addr, data);
			break;
			
		case IOMD_ROMCR0:
			//DBG_PRINT("@0x%08x: ROMCR0(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
		case IOMD_ROMCR1:
			//DBG_PRINT("@0x%08x: ROMCR1(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;

		case IOMD_DRAMCR:
			//DBG_PRINT("@0x%08x: DRAMCR(0x%08x) <- 0x%02x\n",
			//	PC - 8, addr, data);
			break;
			
		case IOMD_VIDCR:
			DBG_PRINT("@0x%08x: VIDCR(0x%08x) <- 0x%02x\n",
				PC - 8, addr, data);
			if ((data & 0x20) && (io.lcd_started == 0)) {
				DBG_PRINT("Start LCD\n");
				//lcd_enable(state, 640, 480, 8);
				io.lcd_started = 1;
			}
			io.vidcr = data;
			break;
			
		case IOMD_KCTRL:
			if (data & 0x08) 		// Enable
				io.kb_stat = KB_SKC | KB_SKD | KB_ENA | KB_TXE;
			else				// Disable
				io.kb_stat = 0;
			//DBG_PRINT("@0x%08x: KCTRL(0x%08x) <- 0x%02x\n", 
			//	PC - 8, addr, data);
			break;
			
		case IOMD_KARTTX:
			//DBG_PRINT("@0x%08x: KARTTX(0x%08x) <- 0x%02x\n", 
			//	PC - 8, addr, data);
			// Send a character to PS2 keyboard.
			// This is a keyboard command.
			// Clear TXEmpty, clear TX interrupt, set TXBusy
			// Queue an ACK (0xfa) response
			// If command is RESET (0xff), then
			// also queue a reset done (0xaa) response
			io.kb_stat &= ~ KB_TXE;
			CLR_IRQ(IRQ_KEYBOARDTX);
			io.kb_stat |= KB_TXB ;
			io.kb_delay = 10;
			ps7500_kb_queue(state, 0xfa);
			if (data == 0xff)  
				ps7500_kb_queue(state, 0xaa);
			break;

		
		default:
			DBG_PRINT("@0x%08x: io_write_byte(0x%08x) <- 0x%02x\n", 
				PC - 8, addr, data);
			break;
		}
		return;
	} 
	
	if (addr == VIDEO_ADDR) {
		DBG_PRINT("@0x%08x: Video register write 0x%08x\n", PC - 8, data);
		return;
	}
	
	if ((addr >= NET_ADDR_START) && (addr <= NET_ADDR_END)) {
		offset = (addr - NET_ADDR_START) >> 2;
		DBG_PRINT("@0x%08x: Ethernet reg %03x write byte 0x%02x\n",
			PC - 8, offset, data);
		//nic_write(0, state, offset, data);
		return;
	}
	
	DBG_PRINT("@0x%08x: io_write_byte(0x%08x) <- 0x%08x\n",
		PC - 8, addr, data);
}

void ps7500_io_write_halfword(ARMul_State *state, ARMword addr, ARMword data)
{
	DBG_PRINT("io_write_halfword(0x%08x) <- 0x%08x\n", addr, data);
}

void ps7500_io_write_word(ARMul_State *state, ARMword addr, ARMword data)
{       
	ARMword offset;
	
	if ((addr >= IOMD_ADDR_START) && ( addr < IOMD_ADDR_END)) {
		offset = addr - IOMD_ADDR_START;
		switch (offset) {

		case IOMD_CURSINIT:
			DBG_PRINT("CURSINIT <- 0x%08x\n", data);
			break;
		case IOMD_VIDEND:
			io.vidend = data;
			DBG_PRINT("VIDEND <- 0x%08x\n", data);
			break;
		case IOMD_VIDSTART:
			io.vidstart = data;
			io.lcd_addr_begin = data;
			DBG_PRINT("VIDSTART <- 0x%08x\n", data);
			break;
		case IOMD_VIDINIT:
			io.vidinit = data;
			DBG_PRINT("VIDINIT <- 0x%08x\n", data);
			break;
			
		default:
			DBG_PRINT("io_write_word(0x%08x) <- 0x%08x\n", 
				addr - 0x03200000, data);
			break;
		}
		return;
	} 
	
	if (addr == VIDEO_ADDR) {
		DBG_PRINT("Video register write <- 0x%08x\n", data);
		return;
	}
	
	// Network data sometimes written in 16 bit pieces
	if ((addr >= NET_ADDR_START) && (addr < NET_ADDR_END)) {
		offset = (addr - NET_ADDR_START) >> 2;
		if (offset != 0x10) {
			printf("Net word write at bad address\n");
			exit(1);
		}
		DBG_PRINT("Net data write <- 0x%04x\n", data & 0xffff);
		//nic_write(0, state, offset, data & 0xff);
		//nic_write(0, state, offset, (data >> 8) & 0xff);
		return;
	}
		
	DBG_PRINT("io_write_word(0x%08x) <- 0x%08x\n", addr, data);
}

void ps7500_mach_init(ARMul_State *state, machine_config_t *this_mach)
{
	ARMul_SelectProcessor(state, ARM_v4_Prop);
        //chy 2004-05-09, set lateabtSig
        state->lateabtSig = HIGH;

	this_mach->mach_io_do_cycle = 		ps7500_io_do_cycle;
	this_mach->mach_io_reset = 		ps7500_io_reset;
        this_mach->mach_io_read_byte = 		ps7500_io_read_byte;
        this_mach->mach_io_write_byte = 	ps7500_io_write_byte;
        this_mach->mach_io_read_halfword = 	ps7500_io_read_halfword;
        this_mach->mach_io_write_halfword = 	ps7500_io_write_halfword;
	this_mach->mach_io_read_word = 		ps7500_io_read_word;
	this_mach->mach_io_write_word = 	ps7500_io_write_word;
	
	this_mach->mach_update_int =            ps7500_update_int;

	this_mach->mach_set_intr = ps7500_set_intr;
	this_mach->mach_pending_intr = ps7500_pending_intr;
	this_mach->mach_update_intr = ps7500_update_intr;
	
	/*
	state->mach_io.lcd_is_enable = (ARMword *)&io.lcd_is_enable;
	state->mach_io.lcd_addr_begin = (ARMword *)&io.lcd_addr_begin;
	state->mach_io.lcd_addr_end = (ARMword *)&io.lcd_addr_end;
	*/
	state->mach_io.ts_int		=(ARMword *)&io.ts_int;
	state->mach_io.ts_is_enable	=(ARMword *)&io.ts_is_enable;	
	state->mach_io.ts_addr_begin	=(ARMword *)&io.ts_addr_begin;
	
	state->mach_io.instr		=(ARMword *)io.irq;
	state->mach_io.net_int		=(ARMword *)io.net_int;	
	state->mach_io.net_flag		=(ARMword *)&io.net_flag;

	state->Reg[1] = 14;
	
	printf("%02x %02x\n", state->mach_io.instr, state->mach_io.net_int);
}

ARMbyte scancode_alpha[] = {
	0x1c, 0x32, 0x21, 0x23, 0x24, 0x2b, 0x34, 0x33,
	0x43, 0x3b, 0x42, 0x4b, 0x3a, 0x31, 0x44, 0x4d,
	0x15, 0x2d, 0x1b, 0x2c, 0x3c, 0x2a, 0x1d, 0x22,
	0x35, 0x1a};
	
ARMbyte scancode_number[] = {
	0x45, 0x16, 0x1e, 0x26, 0x25, 0x2e, 0x36, 0x3d,
	0x3e, 0x46}; 


ARMbyte ps7500_getcode(ARMbyte c)
{
	if ((c >= 'a') && (c <= 'z')) 
		return scancode_alpha[c - 'a'];
	if ((c >= '0') && (c <= '9'))
		return scancode_number[c - '0'];
	if (c == '\n')
		return 0x5a;
	if (c == '.')
		return 0x49;
	if (c == '/')
		return 0x4a;
	return 0x49;
}
	
