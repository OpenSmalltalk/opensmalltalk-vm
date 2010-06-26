/*
	skyeye_mach_lpc2210.c - define machine lpc2210 for skyeye
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
 * 10/02/2007 	Add support for RTEMS/lpc2210 bsp. Be care that the clock in 
 *              skyeye lpc2210 support is 1000 times faster than the real hardware
 *              clock
 *		rayx <rayx.cn@gmail.com> 
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
//#include "skyeye-ne2k.h"

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

#define TC_DIVISOR	(50)	/* Set your BogoMips here :) may move elsewhere*/

#define DEBUG 0
#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr,##a)
#else
#define DBG_PRINT(a...)
#endif

typedef struct timer{
	ARMword	ir;
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
} lpc2210_timer_t;

typedef struct uart{
	ARMword	rbr;
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
} lpc2210_uart_t;

typedef struct pll{
	ARMword	con;
	ARMword cfg;
	ARMword stat;
	ARMword feed;
} lpc2210_pll_t;

typedef struct vic{
	ARMword IRQStatus;
	ARMword FIQStatus;
	ARMword RawIntr;
	ARMword IntSelect;
	ARMword IntEnable;
	ARMword IntEnClr;
	ARMword SoftInt;
	ARMword SoftIntClear;
	ARMword Protection;
	ARMword Vect_Addr;
	ARMword DefVectAddr;
	ARMword VectAddr[15];
	ARMword VectCntl[15];
} lpc2210_vic_t;

typedef struct lpc2210_io {
        ARMword         syscon;                 /* System control */
        ARMword         sysflg;                 /* System status flags */
	lpc2210_pll_t		pll;
	lpc2210_timer_t	timer[2];
	lpc2210_vic_t		vic;
	ARMword			pinsel0;	/*Pin Select Register*/
	ARMword			pinsel1;
	ARMword			pinsel2;		
	ARMword			bcfg[4];	/*BCFG Extend Mem control*/
	ARMword			vpbdiv;		/*VPB Divider control*/
        int             	tc_prescale;
	lpc2210_uart_t	uart[2];                 /* Receive data register */
	ARMword		mmcr;			/*Memory mapping control register*/
	ARMword		vibdiv;	

	/*real time regs*/
	ARMword		sec;
	ARMword		min;
	ARMword		hour;
	ARMword		dom;
	ARMword		dow;
	ARMword		doy;
	ARMword		month;
	ARMword		year;
	ARMword		preint;
	ARMword		prefrac;
	ARMword		ccr;
	
	/*mam accelerator module*/
	ARMword		mamcr;
	ARMword		mamtim;
	
} lpc2210_io_t;

static lpc2210_io_t lpc2210_io;

#define io lpc2210_io

void lpc2210_io_write_word(ARMul_State *state, ARMword addr, ARMword data);

static void lpc2210_update_int(ARMul_State *state)
{
	u32 irq = 0;
	int i;
	//state->NfiqSig = (~(io.vic.RawIntr&io.vic.IntEnable& io.vic.)) ? LOW : HIGH;
	irq = io.vic.RawIntr & io.vic.IntEnable ;
	//add by linxz
	//printf("SKYEYE:RawIntr:0x%x,IntEnable:0x%x\n", io.vic.RawIntr, io.vic.IntEnable);

	io.vic.IRQStatus = irq & ~io.vic.IntSelect;
	io.vic.FIQStatus = irq & io.vic.IntSelect;
	
	//here only deals some important int:
	//uart0 and timer0, other peripheral's int reqs are ignored.
	//added and rmked by linxz
	
	//UART0, Int src: 6
	if(io.vic.IRQStatus &IRQ_UART0){
		for ( i = 0; i<=15; i++ )
		{
			if ( ((io.vic.VectCntl[i] & 0xf) == 6 ) && (io.vic.VectCntl[i] & 0x20) )
				break;
		}
		if ( ((io.vic.VectCntl[i] & 0xf) == 6 ) && (io.vic.VectCntl[i] & 0x20) )
			io.vic.Vect_Addr = io.vic.VectAddr[i];				
	}
	
	//TIMER0, Int src: 4
	if(io.vic.IRQStatus &IRQ_TC0){
		for ( i = 0; i<=15; i++ )
		{
			if ( ((io.vic.VectCntl[i] & 0xf) == 4 ) && (io.vic.VectCntl[i] & 0x20) )
				break;
		}
		if ( ((io.vic.VectCntl[i] & 0xf) == 4 ) && (io.vic.VectCntl[i] & 0x20) )
		{
			io.vic.Vect_Addr = io.vic.VectAddr[i];				
			//printf("VicVect load vectaddr%d:%08x", i, io.vic.Vect_Addr);
		}
	}
	
	state->NirqSig = io.vic.IRQStatus ? LOW:HIGH; 
	state->NfiqSig = io.vic.FIQStatus ? LOW:HIGH;
}
static void lpc2210_io_reset(ARMul_State *state)
{
	//io.timer[0].pr = 500000;/*prescale value*/
	//rmked by linxz
	io.timer[0].pr = 0;
	io.pll.stat |= 1<<10;   /*PLL state register should be 1<<10 when hardware ready*/
	
	io.vic.IRQStatus = 0;
	io.vic.FIQStatus = 0;
	io.vic.RawIntr = 0;
	//added by linxz
	io.vic.IntSelect = 0;
	
	io.uart[0].lsr |= 0x60;
	io.uart[0].iir = 0x01;

	io.pinsel0 = 0;
	io.pinsel1 = 0x15400000;
	//io.pinsel2 = 		FIX ME
	
	io.bcfg[0] = 0x0000fbef;
	io.bcfg[1] = 0x2000fbef;
	io.bcfg[2] = 0x1000fbef;
	io.bcfg[3] = 0x0000fbef;
	
	io.vibdiv  = 0;
}


/*lpc2210 io_do_cycle*/
void lpc2210_io_do_cycle(ARMul_State *state)
{
	int t;
	io.timer[0].pc++;
	io.timer[1].pc++;
	//add by linxz
	//printf("SKYEYE:Timer0 PC:%d, TC:%d\n", io.timer[0].pc, io.timer[0].tc);
	//printf(",MR0:%d,PR:%d,RISR:%d,IER:%d,ISLR:%d,ISR:%d\n", io.timer[0].mr0, io.timer[0].pr, io.vic.RawIntr, io.vic.IntEnable, io.vic.IntSelect, io.vic.IRQStatus);
	if (!(io.vic.RawIntr & IRQ_TC0)) {	//no timer0 int yet
		if (io.timer[0].pc >= io.timer[0].pr+1) {		
			io.timer[0].tc++;
			io.timer[0].pc = 0;
		       	if(io.timer[0].tc >= io.timer[0].mr0/1000) /*Skyeye's clock is far more slow than the real Ocs. I have to make the clock interrupt come quicker*/{
	//		if(io.timer[0].tc == 20){
		       		io.vic.RawIntr |= IRQ_TC0;	
				io.timer[0].tc = 0;
				//add by linxz
				//printf("\r\nI\r\n");	
			}
			lpc2210_update_int(state);
		}
	}
	if(io.timer[0].pc == 0){
		if (!(io.vic.RawIntr & IRQ_UART0)) {
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
			io.vic.RawIntr |= IRQ_UART0;
			lpc2210_update_int(state);
		}
        }/* if (rcr > 0 && ...*/
	}
}


ARMword	lpc2210_fix_int(ARMword val)
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
	return(val);
}

ARMword	lpc2210_unfix_int(ARMword val)
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
	return(val);
}

ARMword
lpc2210_uart_read(ARMul_State *state, ARMword addr,int i)
{
	ARMword data;
	//printf("lpc2210_uart_read,addr=%x\n",addr);
	switch ((addr & 0xfff) >> 2) {
	case 0x0: // RbR
		io.uart[i].lsr &= ~0x1;
		if(i==0)
			io.vic.RawIntr &= ~IRQ_UART0;
		else
			io.vic.RawIntr &= ~IRQ_UART1;
		lpc2210_update_int(state);
		data = io.uart[i].rbr;
		break;
	
	case 0x1: // ier
		data = io.uart[i].ier;
		break;
	case 0x2: // iir
		data = io.uart[i].iir;
		break;
	case 0x3: // IDR
	case 0x4: // IMR
	case 0x5: // LSR
		data = io.uart[i].lsr;
		break;
	case 0x6: // MSR
		    data = io.uart[i].msr;
				    break;						
	case 0x7: // SCR
				data = io.uart[i].scr;
						break;
																
	default:
		DBG_PRINT("uart_read(%s=0x%08x)\n", "uart_reg", addr);
		
		break;
	}

	return(data);
}


void
lpc2210_uart_write(ARMul_State *state, ARMword addr, ARMword data,int i)
{
	static ARMword tx_buf = 0;

	//DBG_PRINT("uart_write(0x%x, 0x%x)\n", (addr & 0xfff) >> 2, data);
	switch ((addr & 0xfff) >> 2) {
		case 0x0: // THR
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			//io.uart[0].lsr |= 0x40;
			io.uart[0].lsr |= 0x20;			
		}
		case 0x2: //FCR
		{
			io.uart[i].fcr = data;
			break;
		}
		case 0x7: // SCR
		        io.uart[i].scr = data;
						break;
		default:										
			//printf("%c", data); fflush(stdout);
			DBG_PRINT("uart_write(%s=0x%08x)\n", "uart_reg", addr);						
			break;
	}
}

ARMword lpc2210_io_read_word(ARMul_State *state, ARMword addr)
{
	/*
 * 	 * The lpc2210 system registers
 * 	 	 */

	ARMword data = -1;
	static ARMword current_ivr = 0; /* mega hack,  2.0 needs this */
	int i;
	ARMword dataimr = 0;


	switch (addr) {
	case 0xfffff000: /* ISR */
//		data = unfix_int(io.intsr);
//		dataimr = unfix_int(io.intmr);
		data = io.vic.IRQStatus;
		DBG_PRINT("read ISR=%d\n", data);
		break;
	case 0xfffff004: /* interrupt status register */
		data = io.vic.FIQStatus;
		DBG_PRINT("SKYEYE:read ISR=%x,%x\n", data, io.vic.FIQStatus);
		break;
	case 0xfffff008: /* IMR */
		data = io.vic.RawIntr;
		break;
	case 0xfffff00c: /* CORE interrupt status register */
		data = io.vic.IntSelect;
		break;
	case 0xfffff010: /* IER */
		data = io.vic.IntEnable;
		DBG_PRINT("read IER=%x,after update IntEnable=%x\n", data,io.vic.IntEnable);
		break;

	case 0xfffff014: /* Int Enable Clr Reg */
		data = io.vic.IntEnClr;		
		lpc2210_update_int(state);
		break;	
	case 0xfffff034: /* Default Vector Addr Reg */
		data = io.vic.DefVectAddr ;
		break;
	case 0xfffff030: /* VAR */
		data = io.vic.Vect_Addr ;
		break;

	case 0xfffff100: /* VicVectAddr0*/
		data = io.vic.VectAddr[0] ;
		break;
	case 0xfffff200: /*VicVectCntl0*/
		data = io.vic.VectCntl[0];
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
		//io.vic.RawIntr &= ~IRQ_TC0;
		//printf("SKYEYE:Clear TC Interrupt,tc=%x,RawIntr=%x,\n",data,io.vic.RawIntr);
		//lpc2210_update_int(state);
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
		data = io.pll.stat|1<<10; /*skyeye should aways return a pll ready*/
		break;
	case 0xe01fc08c:
		data = io.pll.feed;
		
	/*Pin Select Control*/
	case 0xe002c000:
		data = io.pinsel0;
		break;
	case 0xE002C004:
		data = io.pinsel1;
		break;
	case 0xE002C014:
		data = io.pinsel2;
		break;
	
	/*Extend Mem control*/
	case 0xFFE00000:
		data = io.bcfg[0];
		break;
	case 0xFFE00004:
		data = io.bcfg[1];
		break;
	case 0xFFE00008:
		data = io.bcfg[2];
		break;
	case 0xFFE0000c:
		data = io.bcfg[3];
		break;
	
	/*VIBDIV*/
	case 0xe01fc100:
		data = io.vibdiv;
		break;
	
	/*Real timer*/
	case 0xe0024080:
		data = io.preint;
		break;
	case 0xe0024084:
		data = io.prefrac;
		break;
	case 0xe0024008:
		data = io.ccr;
		break;
	case 0xe0024020:
		data = io.sec;
		break;
	case 0xe0024024:
		data = io.min;
		break;
	case 0xe0024028:
		data = io.hour;
		break;
	case 0xe002402c:
		data = io.dom;
		break;
	case 0xe0024030:
		data = io.dow;
		break;
	case 0xe0024034:
		data = io.doy;
		break;
	case 0xe0024038:
		data = io.month;
		break;
	case 0xe002403c:
		data = io.year;
		break;
	
	/*Mem accelerator regs*/
	case 0xe01fc000:
		data = io.mamcr;
		break;
	case 0xe01fc004:
		data = io.mamtim;
		break;
	
		
	default:
		if (addr >=0xe000c000 && addr <= 0xe000c01c) {
			data = lpc2210_uart_read(state, addr,0);
			break;
		}
		if (addr >=0xe0001000 && addr <= 0xe000101c) {
			data = lpc2210_uart_read(state, addr,1);
			break;
		}
		if(addr-0xfffff100 <=0x3c && addr-0xfffff100 >=0){
			data = io.vic.VectAddr[(addr-0xfffff100)/4] ;
			break;
		}
		if(addr-0xfffff200 <=0x3c && addr-0xfffff200>=0){
			data = io.vic.VectCntl[(addr-0xfffff200)/4] ;
			break;
		}
		
		printf("ERROR:io_read: addr = %x\n", addr);
		
		/*fprintf(stderr,"NumInstr %llu, io_read_word unknown addr(0x%08x) = 0x%08x\n", state->NumInstrs, addr, data);*/
		SKYEYE_OUTREGS(stderr);
		//ARMul_Debug(state, 0, 0);
		break;
	}
	return data; 													
}

ARMword lpc2210_io_read_byte(ARMul_State *state, ARMword addr)
{
			return lpc2210_io_read_word(state,addr);		
//			SKYEYE_OUTREGS(stderr);
			//exit(-1);
		
}

ARMword lpc2210_io_read_halfword(ARMul_State *state, ARMword addr)
{
		return lpc2210_io_read_word(state,addr);
		//SKYEYE_OUTREGS(stderr);
		//exit(-1);
}




void lpc2210_io_write_byte(ARMul_State *state, ARMword addr, ARMword data)
{

     lpc2210_io_write_word(state,addr,data);
	   //SKYEYE_OUTREGS(stderr);
	   //exit(-1);
         
}

void lpc2210_io_write_halfword(ARMul_State *state, ARMword addr, ARMword data)
{
	lpc2210_io_write_word(state,addr,data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}

void lpc2210_io_write_word(ARMul_State *state, ARMword addr, ARMword data)
{
  	int i, mask, nIRQNum, nHighestIRQ;
	
	/*
  	 * The lpc2210 system registers
  	 */
	

	switch (addr) {
	case 0xfffff000: /* ISR */
		DBG_PRINT("SKYEYE:can not write  ISR,it is RO,=%d\n", data);
		break;
	case 0xfffff004: /* interrupt status register */
		//io.vic.FIQStatus = data ;
//		DBG_PRINT("read ISR=%x,%x\n", data, io.intsr);
		DBG_PRINT("can not write  FIQStatus,it is RO,=%d\n", data);
		break;
	case 0xfffff008: /* IMR */
		 //io.vic.RawIntr = data;
		 DBG_PRINT("can not write  RawIntr,it is RO,=%d\n", data);
		break;
	case 0xfffff00c: /* CORE interrupt status register */
		io.vic.IntSelect = data;
		break;
	case 0xfffff010: /* IER */
		io.vic.IntEnable = data;
		io.vic.IntEnClr = ~data;
		lpc2210_update_int(state);
//		data = unfix_int(io.intmr);
		DBG_PRINT("write IER=%x,after update IntEnable=%x\n", data,io.vic.IntEnable);
		break;
	case 0xfffff014: /* IECR */
		io.vic.IntEnClr = data;		
		io.vic.IntEnable = ~data;
		lpc2210_update_int(state);
		break;		

	case 0xfffff018: /* SIR */
		io.vic.SoftInt = data;
		break;	
	case 0xfffff01c: /* SICR */
		io.vic.SoftIntClear = data;
		break;	
	case 0xfffff020: /* PER */
		io.vic.Protection = data;
		break;	
	case 0xfffff030: /* VAR */
		//io.vic.Vect_Addr = data;
		//rmk by linxz, write VAR with any data will clear current int states
		//FIQ interrupt
		//FIXME:clear all bits of FIQStatus?
		if ( io.vic.FIQStatus )
		{
			io.vic.FIQStatus = 0;
			break;
		}
		//find the current IRQ number: which has the highest priority.
		mask = 1;
		nHighestIRQ = 0xffff;
		for ( i = 0; i<=15; i++ )
		{
			nIRQNum = io.vic.VectCntl[i] & 0xf;
			if ( (nIRQNum<<mask) & io.vic.IRQStatus )
			{
				if ( nIRQNum < nHighestIRQ )
					nHighestIRQ = nIRQNum;
			}	
		}
		//If there's at least one IRQ now, clean status and raw
		//status register.
		if ( nHighestIRQ != 0xffff )		
		{
			io.vic.IRQStatus &= ~( nHighestIRQ << mask );
			io.vic.RawIntr &= ~( nHighestIRQ << mask);
		}
		break;
	case 0xfffff034: /* DVAR */
		io.vic.DefVectAddr = data;
		break;
		
	/*Timer0 */
	case 0xe0004000:
		io.timer[0].ir = data;
		if(io.timer[0].ir&0x1){
			io.vic.RawIntr &= ~IRQ_TC0;
		}
		lpc2210_update_int(state);
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

	/*pll*/
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
		
	/*memory map control*/
	case 0xe01fc040:
		io.mmcr = data;
		break;
		
	/*Pin select control*/
 	case 0xe002c000:
		io.pinsel0 = data;
		break;
	case 0xE002C004:
		io.pinsel1 = data;
		break;
	case 0xE002C014:
		io.pinsel2 = data;
		break;
		
	/*Extend Mem control*/
	case 0xFFE00000:
		io.bcfg[0] = data;
		break;
	case 0xFFE00004:
		io.bcfg[1] = data;
		break;
	case 0xFFE00008:
		io.bcfg[2] = data;
		break;
	case 0xFFE0000c:
		io.bcfg[3] = data;
		break;
	
	/*VIBDIV*/
	case 0xe01fc100:
		io.vibdiv = data;
		break;
		
	/*Real timer*/
	case 0xe0024008:
		io.ccr = data;
		break;
	case 0xe0024080:
                io.preint = data;
                break;
        case 0xe0024084:
                io.prefrac = data;
                break;
	case 0xe0024020:
		io.sec = data;
		break;
	case 0xe0024024:
		io.min = data;
		break;
	case 0xe0024028:
		io.hour = data;
		break;
	case 0xe002402c:
		io.dom = data;
		break;
	case 0xe0024030:
		io.dow = data;
		break;
	case 0xe0024034:
		io.doy = data;
		break;
	case 0xe0024038:
		io.month = data;
		break;
	case 0xe002403c:
		io.year = data;
		break;
			
	/*Mem accelerator regs*/
	case 0xe01fc000:
		io.mamcr = data;
		break;
	case 0xe01fc004:
		io.mamtim = data;
		break;	
		
	default:
		if (addr >=0xe000c000 && addr <= 0xe000c01c) {
			lpc2210_uart_write(state, addr, data,0);
			break;
		}
		if (addr >=0xe0001000 && addr <= 0xe000101c) {
			lpc2210_uart_write(state, addr, data,1);
			break;
		}

		if(addr-0xfffff100 <=0x3c && addr-0xfffff100 >=0){
			io.vic.VectAddr[(addr-0xfffff100)/4] = data;
			break;
		}
		if(addr-0xfffff200 <=0x3c && addr-0xfffff200>=0){
			io.vic.VectCntl[(addr-0xfffff200)/4] = data;
			break;
		}
		printf("ERROR:io_write a non-exsiting addr:addr = %x, data = %x\n", addr, data);
		/*
		fprintf(stderr,"NumInstr %llu,io_write_word unknown addr(1x%08x) = 0x%08x\n", state->NumInstrs, addr, data);*/
		//SKYEYE_OUTREGS(stderr);
		//ARMul_Debug(state, 0, 0);
		break;
	}
}

void lpc2210_mach_init(ARMul_State *state, machine_config_t *this_mach)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor(state, ARM_v4_Prop);
        //chy 2004-05-09, set lateabtSig
        state->lateabtSig = HIGH;

	this_mach->mach_io_do_cycle = 		lpc2210_io_do_cycle;
	this_mach->mach_io_reset = 		lpc2210_io_reset;
	this_mach->mach_io_read_byte = 		lpc2210_io_read_byte;
	this_mach->mach_io_write_byte = 	lpc2210_io_write_byte;
	this_mach->mach_io_read_halfword = 	lpc2210_io_read_halfword;
	this_mach->mach_io_write_halfword = 	lpc2210_io_write_halfword;
	this_mach->mach_io_read_word = 		lpc2210_io_read_word;
	this_mach->mach_io_write_word = 	lpc2210_io_write_word;

	this_mach->mach_update_int = 		lpc2210_update_int;

	//ksh 2004-2-7


	state->mach_io.instr = (ARMword *)&io.vic.IRQStatus;
	//*state->io.instr = (ARMword *)&io.intsr;
	//state->io->net_flags = (ARMword *)&io.net_flags;
	//state->mach_io.net_int = (ARMword *)&io.net_int;
}
