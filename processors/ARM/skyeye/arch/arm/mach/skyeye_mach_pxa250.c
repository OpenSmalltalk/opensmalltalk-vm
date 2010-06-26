#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "pxa.h"

/*ywc 2005-03-30*/
#include "skyeye_flash.h"

#define F_CORE (100 * 1024 * 1024)	//core frequence
#define F_RTC 32768		//RTC
#define F_OS	3686400		//OS timer
#define RT_SCALE (F_CORE / F_RTC) / 50
#define OS_SCALE (F_CORE / F_OS / 10) / 50

#define FF_SCALE	200	//FF UART


/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

//ywc,2004-11-30,declare a external array which stores touchscreen event information
extern unsigned int Pen_buffer[8];	// defined in skyeye_lcd.c
//ywc,2004-11-30,declare a external array which stores touchscreen event information,end

//chy:  lubbock, cerf, idp are different board
// I can add a union to cover the difference in the future
//chy:  refer to linux/include/asm-arm/arch-pxa/pxa-regs.h
//chy 2005-09-19, the define of pxa27x_io_t is in pxa.h
static pxa250_io_t pxa250_io;


static void refresh_irq (ARMul_State *);
static void
pxa250_io_reset ()
{
	memset (&pxa250_io, 0, sizeof (pxa250_io));
	//chy 2003-08-25
	pxa250_io.cccr = 0x121;	// 1 0010 0001
	pxa250_io.cken = 0x17def;


	pxa250_io.ts_int = 1 << 15;
	pxa250_io.ts_addr_begin = 0x40000300;
	pxa250_io.ts_addr_end = 0x4000031f;
	//ywc,2004-11-30,evaluate io of LCD and Touchscreen,end

};
void
pxa250_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	return;
}

void
pxa250_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	return;
}

pxa_set_intr (u32 interrupt)
{
	pxa250_io.icpr |= (1 << interrupt);
}
static int
pxa_pending_intr (u32 interrupt)
{
	return ((pxa250_io.icpr & (1 << interrupt)));
}
static void
pxa_update_intr (void *mach)
{
	struct machine_config *mc = (struct machine_config *) mach;
	ARMul_State *state = (ARMul_State *) mc->state;

	pxa250_io.icip = (pxa250_io.icmr & pxa250_io.icpr) & ~pxa250_io.iclr;
	pxa250_io.icfp = (pxa250_io.icmr & pxa250_io.icpr) & pxa250_io.iclr;
	state->NirqSig = pxa250_io.icip ? LOW : HIGH;
	state->NfiqSig = pxa250_io.icfp ? LOW : HIGH;

}
static void
pxa250_update_int (ARMul_State * state)
{
	pxa250_io.icip = (pxa250_io.icmr & pxa250_io.icpr) & ~pxa250_io.iclr;
	pxa250_io.icfp = (pxa250_io.icmr & pxa250_io.icpr) & pxa250_io.iclr;
	state->NirqSig = pxa250_io.icip ? LOW : HIGH;
	state->NfiqSig = pxa250_io.icfp ? LOW : HIGH;
}

static void
pxa250_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	pxa_ioregnum_t ioregaddr = addr;

	//printf("SKYEYE:pxa250_io_write_word: io addr 0x%x, RCNR 0x%x\n",ioregaddr,RCNR);

	switch (ioregaddr) {
	 /*RTC*/ case RCNR:
		pxa250_io.rcnr = data;
		break;
	case RTAR:
		pxa250_io.rtar = data;
		break;
	case RTSR:
		pxa250_io.rtsr |= (data & 0xc);
		pxa250_io.rtsr &= ~(data & 0x3);
		break;
	case RTTR:
		pxa250_io.rttr = data & 0x3ffffff;
		break;
		/*OS timer */
	case OSCR:
		pxa250_io.oscr = data;
		break;
	case OSMR0:
		pxa250_io.osmr0 = data;
		break;
	case OSMR1:
		pxa250_io.osmr1 = data;
		break;
	case OSMR2:
		pxa250_io.osmr2 = data;
		break;
	case OSMR3:
		pxa250_io.osmr3 = data;
		break;
	case OWER:
		pxa250_io.ower |= data & 0x1;
		break;
	case OSSR:
		/* When the status register is updated, the
		   results are seen immediately in the icpr */
		pxa250_io.ossr &= ~(data & 0xf);
		pxa250_io.icpr &= ~(0xf << OS_IRQ_SHF);
		pxa250_io.icpr |= (pxa250_io.ossr << OS_IRQ_SHF);
		break;
	case OIER:
		pxa250_io.oier = data & 0xf;
		break;

		/*interrupt control */
		//ywc,2004-11-30,for touchscreen use ICPR
	case ICPR:
		/*read only - see 4.2.2.5 Intel PXA255 Processor Developer's Manual */
		break;
	case ICMR:
		pxa250_io.icmr = data;
		break;
	case ICLR:
		pxa250_io.iclr = data;
		break;

		//ffuart contril
	case FFTHR:
		{		/*static tx_cnt=0; */
			unsigned char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			/*chy 2004-07-21 from luzhetao: after write char, should set some value */
			pxa250_io.ffiir &= ~0x2;
			pxa250_io.ffiir |= 0x1;
			pxa250_io.fflsr &= ~0x60;
			//tx_cnt++;
			//pxa250_io.ffier|=0x2;
			/*
			   if(tx_cnt>63){
			   tx_cnt=0;
			   pxa250_io.ffiir|=0x2;
			   pxa250_io.fflsr|=0x60;
			   refresh_irq(state);
			   }
			 */
			//printf("SKYEYE: write FFTHR %x, iir %x,lsr %x, ier %x\n",data, pxa250_io.ffiir,pxa250_io.fflsr,pxa250_io.ffier);
		}
		break;
	case FFIER:
		pxa250_io.ffier = data & 0xff;
		break;
	case FFFCR:		//write only
		pxa250_io.fffcr = data & 0xc7;
		//pxa250_io.ffiir = data & 0xc7 ;
		//if(pxa250_io.fffcr & 2
		//printf("SKYEYE: write FFFCR %x, but is ffiir %x\n",pxa250_io.fffcr,pxa250_io.ffiir);
		break;
	case FFLCR:
		pxa250_io.fflcr = data & 0xff;
		break;
		//core clock 
	case FFMCR:
		pxa250_io.ffmcr = data & 0x1f;
		break;
		//core clock 
	case CCCR:
		pxa250_io.cccr = data & 0x3ff;
		break;
	case CKEN:
		pxa250_io.cken = data & 0x17def;
		break;
	case OSCC:
		pxa250_io.oscc = data & 0x3;
		break;

		//ywc,2004-11-30,add for pxa's LCD simulation
#if 0
	case LCCR0:
		tmp = pxa250_io.lccr0;
		pxa250_io.lccr0 = data;
		if ((!(tmp & LCCR0_ENB)) && (pxa250_io.lccr0 & LCCR0_ENB)) {
			if (once)
				break;
			once++;
			/*
			   printf("\nFDADR0=%x,FDADR1=%x",pxa250_io.fdadr0,pxa250_io.fdadr1);
			   printf("\n");
			   pxa250_io.lcd_addr_begin = pxa250_io.fdadr0 + 16*(2+2);
			   printf("\nlcd_addr_begin=%x",pxa250_io.lcd_addr_begin);
			   printf("\n");
			 */
			pxa250_update_lcd (state);
		}
		break;
	case LCCR1:
		pxa250_io.lccr1 = data;
		break;
	case LCCR2:
		pxa250_io.lccr2 = data;
		break;
	case LCCR3:
		pxa250_io.lccr3 = data;
		break;
	case FDADR0:
		pxa250_io.fdadr0 = data;

		//printf("\nFDADR0=%x",pxa250_io.fdadr0);
		//printf("\n");
		/*      
		   mbp = bank_ptr(pxa250_io.fdadr0); 
		   if(!mbp){
		   fprintf(stderr, "No bank at address 0x%x", pxa250_io.fdadr0);
		   return;
		   }   
		   fdadr0ADDRESS=(u32 *) &state->mem.rom[mbp - skyeye_config.mem.mem_banks][(pxa250_io.fdadr0 - mbp->addr)];
		   printf("\n %p",fdadr0ADDRESS);
		 */
		//       printf("\n 0: %x",*((u32 *)fdadr0ADDRESS));
		//       printf("\n 1: %x",*((u32 *)fdadr0ADDRESS+1));
		//       printf("\n 2: %x",*((u32 *)fdadr0ADDRESS+2));
		//       printf("\n 3: %x",*((u32 *)fdadr0ADDRESS+3));
		//printf("\n");

		break;
	case FDADR1:
		pxa250_io.fdadr1 = data;
		//printf("\nFDADR1=%x",pxa250_io.fdadr1);
		//printf("\n");
		break;
	case FSADR0:
		pxa250_io.fsadr0 = data;
		//printf("\nFSADR0=%x",pxa250_io.fsadr0);
		//printf("\n");
		break;
	case FSADR1:
		pxa250_io.fsadr1 = data;
		//printf("\nFSADR1=%x",pxa250_io.fsadr1);
		//printf("\n");
		break;
#endif
		//ywc,2004-11-30,add for pxa's LCD simulation,end
#if 0
	case FFIIR:		//read only
	case FFMSR:		//read only no use
	case FFSPR:		// no use
	case FFISR:		// no use
#endif

	default:
		//chy 2003-09-03 if debug, uncommit it
		//log_msg("SKYEYE: pxa250_io_write_word: unknown addr 0x%x, reg15 0x%x \n", addr,state->Reg[15]);
		;
	};

};

ARMword
pxa250_io_read_byte (ARMul_State * state, ARMword addr)
{
	return 0;
}

ARMword
pxa250_io_read_halfword (ARMul_State * state, ARMword addr)
{
	return 0;
}

ARMword
pxa250_io_read_word (ARMul_State * state, ARMword addr)
{
	u32 data;
	pxa_ioregnum_t ioregaddr = addr;

	//ywc,2004-11-30,add for pxa's Touchscreen simulation
	u32 ts_addr;
	//ywc,2004-11-30,add for pxa's Touchscreen simulation,end

	//ywc 2004-11-30 read the touch srceen data buffer,return to the ts device driver
	ts_addr = addr & ~3;	// 1 word==4 byte
	if (ts_addr >= pxa250_io.ts_addr_begin
	    && ts_addr <= pxa250_io.ts_addr_end) {
		data = pxa250_io.
			ts_buffer[(ts_addr - pxa250_io.ts_addr_begin) / 4];
		return data;
	}
	//ywc 2004-11-30 read the touch srceen data buffer,return to the ts device driver,end

	switch (addr) {
	 /*RTC*/ case RCNR:
		data = pxa250_io.rcnr;
		break;
	case RTAR:
		data = pxa250_io.rtar;
		break;
	case RTSR:
		data = pxa250_io.rtsr;
		break;
	case RTTR:
		data = pxa250_io.rttr;
		break;

		/*OS timer */
	case OSCR:
		data = pxa250_io.oscr;
		break;
	case OSMR0:
		data = pxa250_io.osmr0;
		break;
	case OSMR1:
		data = pxa250_io.osmr1;
		break;
	case OSMR2:
		data = pxa250_io.osmr2;
		break;
	case OSMR3:
		data = pxa250_io.osmr3;
		break;
	case OWER:
		data = pxa250_io.ower;
		break;
	case OSSR:
		data = pxa250_io.ossr;
		break;
	case OIER:
		data = pxa250_io.oier;
		break;

		/*interrupt controler */
	case ICPR:
		data = pxa250_io.icpr;
		break;
	case ICIP:
		data = (pxa250_io.icmr & pxa250_io.icpr) & ~pxa250_io.iclr;
		break;
	case ICFP:
		data = (pxa250_io.icmr & pxa250_io.icpr) & pxa250_io.iclr;
		break;
	case ICMR:
		data = pxa250_io.icmr;
		break;
	case ICLR:
		data = pxa250_io.iclr;
		break;

		/* ffuart control */
	case FFRBR:		//chy: 2003-08-24 have some question, maybe skyeye will be locked here ????
		{
			//unsigned char c;
			//read(skyeye_config.uart.fd_in, &c, 1);
			//data = c;
			data = pxa250_io.ffrbr & 0xff;
			pxa250_io.icpr &= ~FFUART_IRQ;
			pxa250_io.icip &= ~FFUART_IRQ;
			pxa250_io.ffiir &= ~0x4;
			/*chy 2004-07-21 from lzt, afte read char, should set this bit */
			pxa250_io.ffiir |= 0x1;

			//printf("SKYEYE: read FFRBR, but set ffiir  and ~04, now %x\n",pxa250_io.ffiir);
			pxa250_io.fflsr &= ~0x1;

		};
		break;
	case FFIER:
		data = pxa250_io.ffier;
		break;
	case FFIIR:		//read only
		data = pxa250_io.ffiir & 0xcf;
		pxa250_io.icpr &= ~FFUART_IRQ;
		pxa250_io.icip &= ~FFUART_IRQ;
		//printf("SKYEYE: read FFIIR  %x\n",data);
		break;
	case FFLCR:
		data = pxa250_io.fflcr;
		break;
	case FFMCR:
		data = pxa250_io.ffmcr;
		break;
	case FFLSR:		//read only 
		//chy 2003-08-24  NOTICE!
		//fixed by ksh 2004-05-09,for FFUART can input char,I am not sure?
		//pxa250_io.fflsr=1<<5; // LSR's TDRQ =1 , then the cpu can write char again
		pxa250_io.fflsr |= 0x60;	// chy 2003-09-02 for LSR_TEMT|LSR_THRE 0x40|0x20
		data = pxa250_io.fflsr & 0xff;
		break;

		// core clock 
	case CCCR:
		data = pxa250_io.cccr;
		break;
	case CKEN:
		data = pxa250_io.cken;
		break;
	case OSCC:
		data = pxa250_io.oscc;
		break;
		//ywc,2004-11-30,add for pxa's LCD simulation
#if 0
	case LCCR0:
		data = pxa250_io.lccr0;
		break;
	case LCCR1:
		data = pxa250_io.lccr1;
		break;
	case LCCR2:
		data = pxa250_io.lccr2;
		break;
	case LCCR3:
		data = pxa250_io.lccr3;
		break;
	case FDADR0:
		data = pxa250_io.fdadr0;
		break;
	case FDADR1:
		data = pxa250_io.fdadr1;
		break;
	case FSADR0:
		data = pxa250_io.fsadr0;
		break;
	case FSADR1:
		data = pxa250_io.fsadr1;
		break;
#endif
		//ywc,2004-11-30,add for pxa's LCD simulation,end
#if 0
	case FFFCR:		//write only
	case FFMSR:		//read only no use
	case FFSPR:		// no use
	case FFISR:		// no use
#endif

	default:
		data = 0;
		//chy 2003-09-03 if debug, uncommit it
		//log_msg("SKYEYE: pxa250_io_read_word: unknown addr 0x%x, reg15 0x%x \n", addr,state->Reg[15]);
	};

	return data;
};


static void
pxa250_io_do_cycle (ARMul_State * state)
{
	
	 /*RTC*/ if (++pxa250_io.rt_scale >= RT_SCALE) {
		pxa250_io.rt_scale = 0;
		if (pxa250_io.rt_count++ == (pxa250_io.rttr & 0xffff)) {
			pxa250_io.rt_count = 0;

			if (pxa250_io.rcnr++ == pxa250_io.rtar) {
				if (pxa250_io.rtsr & 0x4) {
					pxa250_io.rtsr |= 0x1;
				};
			}
			if (pxa250_io.rtsr & 0x8) {
				pxa250_io.rtsr |= 0x2;
			}
		}
		if ((pxa250_io.rtsr & 0x1) && (pxa250_io.rtsr & 0x4))
			pxa250_io.icpr |= RTC_ALARM_IRQ;
		if ((pxa250_io.rtsr & 0x2) && (pxa250_io.rtsr & 0x8))
			pxa250_io.icpr |= RTC_HZ_IRQ;
	}

	/*OS timer */
	if (++pxa250_io.os_scale >= OS_SCALE) {
		u32 mask = 0;
		u32 count;

		pxa250_io.os_scale = 0;
		count = pxa250_io.oscr++;

		if (count == pxa250_io.osmr0)
			mask = 1;
		if (count == pxa250_io.osmr1)
			mask |= 0x2;
		if (count == pxa250_io.osmr2)
			mask |= 0x4;
		if (count == pxa250_io.osmr3) {
			mask |= 0x8;
			if (pxa250_io.ower & 1) {
				state->NresetSig = LOW;
				printf ("************SKYEYE: WatchDog reset!!!!!!!**************\n");
			}
		}
		pxa250_io.ossr |= mask;
		mask = pxa250_io.oier & pxa250_io.ossr;
		pxa250_io.icpr |= (mask << OS_IRQ_SHF);
	}

	/*FF UART */
	//pxa250_io.utsr0 = 1; /*always TFS, no others*/
	//pxa250_io.utsr1 = 0x4; /*TNF*/
	if (++pxa250_io.ff_scale >= FF_SCALE) {
		pxa250_io.ff_scale = 0;
		if (!(FFUART_IRQ & pxa250_io.icpr)) {
			int int_enable = pxa250_io.ffmcr & 0x18;    // UART interrupt enable

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char c;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			//pxa250_io.utsr1 |= 0x2;  //RNE
			//pxa250_io.utsr0 |= 0x4; //Rx idle
			//added by ksh,2004-4-25,get uart data and  set the interrupt
			if(skyeye_uart_read(-1, &c, 1, &tv, NULL) > 0)
			{
				pxa250_io.ffrbr = (int) c;
				pxa250_io.ffiir |= 0x4;	//Rx idle
				//printf("SKYEYE: io_do_cycle  set ffiir  or 04, now %x\n",pxa250_io.ffiir);
				pxa250_io.fflsr |= 0x01;	//Data ready
			}

			if ((pxa250_io.ffier & 0x1)
			    && (pxa250_io.ffiir & 0x4)) {
				if (int_enable)
					pxa250_io.icpr |= FFUART_IRQ;
				pxa250_io.ffiir &= ~0x1;
			}
			/*chy 2004-07-21 from luzhetao: produce a IRQ and ox2 should clean by OS driver */
			if (pxa250_io.ffier & 0x2) {
				if (int_enable)
					pxa250_io.icpr |= FFUART_IRQ;
				pxa250_io.ffiir |= 0x2;
				pxa250_io.ffiir &= ~0x1;
				pxa250_io.fflsr |= 0x60;
			}
		}
		//ywc,2004-11-30,check and get the mouse event
#ifndef NO_LCD
		if (!(pxa250_io.icpr & pxa250_io.ts_int)) {	//if now has no ts interrupt,then query 
			if (Pen_buffer[6] == 1) {	//should trigger a interrupt
				*(pxa250_io.ts_buffer + 0) = Pen_buffer[0];
				*(pxa250_io.ts_buffer + 1) = Pen_buffer[1];
				*(pxa250_io.ts_buffer + 4) = Pen_buffer[4];
				*(pxa250_io.ts_buffer + 6) = Pen_buffer[6];
				//set EINT2 bit to trigger a interrupt,ts driver will clear it
				pxa250_io.icpr |= pxa250_io.ts_int;
				Pen_buffer[6] = 0;
			}
		}
#endif
		//ywc,2004-11-30,check and get the mouse event,end
	}

	pxa250_update_int (state);
	/*reset interrupt pin status */
	//refresh_irq (state);
};


void
pxa250_mach_init (ARMul_State * state, machine_config_t * mc)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state,
			       ARM_XScale_Prop | ARM_v5_Prop | ARM_v5e_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = LOW;

	state->Reg[1] = 89;	/*lubbock machine id. */
	pxa250_io_reset ();
	/*added by ksh for energy estimation in 2004-11-26 */
	state->energy.cccr = pxa250_io.cccr;

	mc->mach_io_do_cycle = pxa250_io_do_cycle;
	mc->mach_io_reset = pxa250_io_reset;
	mc->mach_io_read_byte = pxa250_io_read_byte;
	mc->mach_io_write_byte = pxa250_io_write_byte;
	mc->mach_io_read_halfword = pxa250_io_read_halfword;
	mc->mach_io_write_halfword = pxa250_io_write_halfword;
	mc->mach_io_read_word = pxa250_io_read_word;
	mc->mach_io_write_word = pxa250_io_write_word;

	mc->mach_set_intr = pxa_set_intr;
	mc->mach_pending_intr = pxa_pending_intr;
	mc->mach_update_intr = pxa_update_intr;

	mc->state = (void *) state;
}
