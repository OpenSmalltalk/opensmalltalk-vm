/*
        bf537_io.c - implementation of bf537 simulation.
        Copyright (C) 2003-2007 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option.) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "bfin-sim.h"
#include "types.h"
#include "bf533_io.h"
#include "dma.h"
#include "bf533_irq.h"
#include "skyeye_config.h"
#include <stdio.h>
#include <fcntl.h>
#include <signal.h>

extern void dma_mem_cpy (unsigned int src, unsigned int dst, int size);

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

#define DEBUG 0
#if DEBUG
#define DBG_PRINT(a...) printf(##a)
#else
#define DBG_PRINT(a...)
#endif

#define IO_ERR {printf("\n%s bf537_io.error!!!addr=0x%x,pc=0x%x\n",__FUNCTION__,addr,PCREG);raise (SIGILL);}
#define MALLOC_ERR {printf("\n%s malloc error!\n",__FUNCTION__);skyeye_exit(-1);}

#define UART0_RX_IRQ 11
#define UART0_TX_IRQ 12

/*declare the device bf537_io.functbf537_io.s*/

declare_device (uart)
declare_device (wd)
declare_device (core_int)
declare_device (dma)
declare_device (dpmc)
declare_device (deu)
declare_device (ebiu)
declare_device (sic)
declare_device (l1mem)
declare_device (l1dmem)
declare_device (rtc)
declare_device (tbuf)
declare_device (core_timer)
declare_device (pf)
declare_device (port)
declare_device (eth)

static void handle_irq ();
static void bf537_disable_int ();
static void bf537_enable_int ();

     typedef struct uart
     {
	     bu16 rbr;
	     bu16 thr;
	     bu16 ier;
	     bu16 iir;
	     bu16 fcr;
	     bu16 lcr;
	     bu16 lsr;
	     bu16 msr;
	     bu16 scr;
	     bu16 dll;
	     bu16 dlh;
	     bu16 gctl;
     } bf537_uart_t;
     static int uart_outfd;


     typedef struct dma_channel
     {
	     bu32 next_desc_ptr;
	     bu32 start_addr;
	     bu32 x_count;
	     bu32 x_modify;
	     bu32 y_count;
	     bu32 y_modify;
	     bu32 curr_desc_ptr;
	     bu32 curr_addr;
	     bu32 irq_status;
	     bu32 peripheral_map;
	     bu32 curr_x_count;
	     bu32 curr_y_count;
     } bf537_dma_channel_t;

     typedef struct l1mem
     {
	     bu32 reg[L1MEM_IO_SIZE / 4];
     } bf537_l1mem_t;

     typedef struct l1dmem
     {
	     bu32 reg[L1DMEM_IO_SIZE / 4];
     } bf537_l1dmem_t;

     typedef struct dma
     {
	     bu16 tc_per;
	     bu16 tc_cnt;
	     bu32 bf537_dma_channel[16][14];

     } bf537_dma_t;

     typedef struct ebiu
     {
	     bu16 amgctl;
	     bu16 ambctl0;
	     bu16 ambctl1;
	     bu16 sdgctl;
	     bu16 sdbctl;
	     bu16 sdrrc;
	     bu16 sdstat;
     } bf537_ebiu_t;

     typedef struct core_int
     {
	     bu32 evt[16];
	     bu32 imask;
	     bu32 ipend;
	     bu32 iprio;
	     bu32 ilat;

     } bf537_core_int_t;

     typedef struct wd
     {
	     bu16 ctl;
	     bu32 cnt;
	     bu32 stat;
     } bf537_wd_t;

     typedef struct tbuf
     {
	     bu32 ctrl;
	     bu32 stat;
	     bu32 rix;
	     bu32 rsel;
	     bu32 wix;
	     bu32 wsel;
	     bu32 dbuf[16];
	     bu32 sbuf[16];

     } bf537_tbuf_t;

     typedef struct deu
     {
	     bu32 dspid;
     } bf537_deu_t;

     typedef struct dpmc
     {
	     bu16 pll_ctl;
	     bu16 pll_stat;
	     bu16 pll_lockcnt;
	     bu16 vr_ctl;
	     bu16 pll_div;
     } bf537_dpmc_t;

     typedef struct sic
     {
	     bu32 swrst;
	     bu32 syscr;
	     bu32 sic_imask;
	     bu32 sic_iar[4];
	     bu32 sic_isr;
	     bu32 sic_iwr;
     } bf537_sic_t;

     typedef struct rtc
     {
	     bu32 stat;
	     bu32 ictl;
	     bu32 istat;
	     bu32 swcnt;
	     bu32 alarm;
	     bu32 pren;
     } bf537_rtc_t;

     typedef struct core_timer
     {
	     bu32 tcntl;
	     bu32 tperio;
	     bu32 tscale;
	     bu32 tcount;
     } bf537_core_timer_t;

     typedef struct pf
     {
	     bu32 fio_flag_d;
	     bu32 fio_flag_c;
	     bu32 fio_flag_s;
	     bu32 fio_dir;
	     bu32 fio_polar;
	     bu32 fio_maska_c;
	     bu32 fio_maskb_c;
	     bu32 fio_inen;
     } bf537_pf_t;
typedef struct bf537_port_s{
	bu16 portf_fer;
	bu16 port_mux;
}bf537_port_t;
typedef struct bf537_eth_s{
	bu32 emac_systat;
}bf537_eth_t;

     typedef struct bf537_io
     {
	     bf537_uart_t uart;	/* Receive data register */
	     bf537_dma_t dma;
	     bf537_ebiu_t ebiu;
	     bf537_core_int_t core_int;
	     bf537_wd_t wd;
	     bf537_deu_t deu;
	     bf537_dpmc_t dpmc;
	     bf537_sic_t sic;
	     bf537_l1mem_t l1mem;
	     bf537_l1dmem_t l1dmem;
	     bf537_rtc_t rtc;
	     bf537_core_timer_t core_timer;
	     bf537_pf_t pf;
	     bf537_tbuf_t tbuf;
	bf537_port_t port;
	bf537_eth_t eth;
     } bf537_io_t;


static bf537_io_t bf537_io;

/*also be called by raise inst and except*/
static void bf537_set_int (int irq)
{
	if(irq != CORE_TIMER_IRQ & irq != 0)
	 //fprintf(PF,"####################irq=%d,in %s\n",irq,__FUNCTION__);
		;
	//if ((bf537_io.core_int.imask | 0x1f) & (1 << irq)) {
		//if(irq != CORE_TIMER_IRQ & irq != 0)
		//     fprintf(PF,"####################irq=%d,in %s\n",irq,__FUNCTION__);
		/*set the corresponding int bit to 1 in ilat */
		bf537_io.core_int.ilat |= (1 << irq);
	//}
}
static void
bf537_clear_int (int irq_no_use)
{
	int irq;
	//fprintf(PF,"KSDBG:begin in %s,ipend=0x%x,ilat=0x%x,SPREG=0x%x,irq=%d\n",__FUNCTION__, bf537_io.core_int.ipend,bf537_io.core_int.ilat, SPREG, irq);

	/*fix me, trigger the corresponding int according to some prio check, */
	for (irq = 0; irq < 16; irq++) {
		/* check there is a pending int for clear */
		if ((bf537_io.core_int.ipend >> irq) & 0x1) {
			/*clear the int bit */
			bf537_io.core_int.ipend &= ~(1 << irq);
			/*clear corresponding int in the device */
			if (irq == CORE_TIMER_IRQ) {
				bf537_io.core_timer.tcntl &= ~0x8;
			}
			if (bf537_io.core_int.ipend == 0x0) {
				/*There is no interrupt to handle, switch mode */
				//fprintf(PF,"KSDBG:mode switch,SPREG=0x%x,USPREG=0x%x\n",SPREG,USPREG);
				MODE = USR_MODE;
				OLDSPREG = SPREG;
				SPREG = USPREG;
			}
			else
				;
				//fprintf(PF,"KSDBG:in super mode,ipend=0x%x,SPREG=0x%x,irq=%d\n",bf537_io.core_int.ipend, SPREG, irq);
			return;
		}
	}
	//fprintf(PF,"KSDBG:end in %s,ipend=0x%x,SPREG=0x%x,irq=%d\n",__FUNCTION__, bf537_io.core_int.ipend, SPREG, irq);

}
static void
handle_irq ()
{

	int irq = 0;
	if (OLDPCREG < 0x1000) {
		printf ("in %s,pc=%x,jump to 0x%x,olderpc=0x%x\n",
			__FUNCTION__, PCREG, OLDPCREG, OLDERPCREG);
		raise (SIGINT);
	}

	/*if global int is disabled,just return */
	if (bf537_io.core_int.ipend & 0x10) {
		return;
	}
	/*fix me, trigger the corresponding int according to some prbf537_io.check, */
	for (irq = 0; irq < 16; irq++) {
		if (((bf537_io.core_int.ilat&(bf537_io.core_int.imask|0x1f)) >> irq) & 0x1) {
			if (irq != CORE_TIMER_IRQ)
				//fprintf (PF,
				//	 "# in %s begin,irq=%d,pc=0x%x,ipend=0x%x,RETI=0x%x\n",
				//	 __FUNCTION__, irq, PCREG, bf537_io.core_int.ipend, RETIREG);
			/*current there is a higher or equal prbf537_io.ity  pending int for handle,wait until it finish */
			if(bf537_io.core_int.ipend&(~((~0x0) << irq)))
				return;
			
			/* set ipend bit , and clear ilat */
			bf537_io.core_int.ilat &= ~(1 << irq);
			bf537_io.core_int.ipend |= (1 << irq);
			/*now if did_jump in interp.c is set, the following code is executed twice,maybe it not make something wrong */
			if (LC1REG && OLDPCREG == LB1REG && --LC1REG) {
				//printf("int in the end of loop,PC=%x\n",PCREG);
				PCREG = LT1REG;
			}
			else if (LC0REG && OLDPCREG == LB0REG && --LC0REG) {
				//printf("int in the end of loop,PC=%x\n",PCREG);
				PCREG = LT0REG;
			}
			/*clear corresponding int in the device */
			if (irq == CORE_TIMER_IRQ) {
				//return;
				bf537_io.core_timer.tcntl &= ~0x8;
//                              fprintf(PF,"##Timer IRQ:PC=0x%x,\n",PCREG);
			}
			else {
				//fprintf (PF, "## Other IRQ:irq=%d,\n", irq);

			}
			/* switch mode */
			if (MODE == USR_MODE) {
				MODE = SUPER_MODE;
				USPREG = SPREG;
				SPREG = OLDSPREG;
			}
			/*save pc to reti,jump to the corresponding vector */
			if (irq == EXCEPT_IRQ) {
				//fprintf (PF,
				//	 "##System Call:PC=0x%x, sys_number=%d,ipend=0x%x\n",
				//	 PCREG,  PREG (0),
				//	 bf537_io.core_int.ipend);
		
				saved_state.retx = PCREG;
			}
			else {
				saved_state.reti = PCREG;
			}
			PCREG = bf537_io.core_int.evt[irq];

			if (irq != CORE_TIMER_IRQ)
				;
                                //fprintf (PF,
                                  //       "## in %s end,irq=%d,pc=0x%x,ipend=0x%x\n",
                                    //     __FUNCTION__, irq, PCREG, bf537_io.core_int.ipend);

			/*at the same time , disable global int for protecting reti */
			bf537_disable_int ();
			return;
		}
	}
}
static void
bf537_disable_int ()
{
	//printf("in %s\n",__FUNCTION__);
	bf537_io.core_int.ipend |= 0x10;
}
static void
bf537_enable_int ()
{
	//printf("in %s\n",__FUNCTION__);
	bf537_io.core_int.ipend &= ~0x10;
}
static void
bf537_cli (bu32 * dreg)
{
	*dreg = bf537_io.core_int.imask;
	//printf("cli,%x\n",*dreg);
	bf537_io.core_int.imask = 0x1f;

}
static void
bf537_sti (bu32 * dreg)
{
	//printf("sti,%x\n",*dreg);
	bf537_io.core_int.imask = *dreg;
}


#define BF537_HZ 50


static void
bf537_io_do_cycle (void * state)
{
	static int sclk_count = 0;
	static int timer_count = BF537_HZ;
	
	//if (PCREG >= 0x7480048){
      //          fprintf(PF,"KSDBG:begin,pc=0x%x,insn@pc=0x%x,sp=0x%x,usp=0x%x,ipend=0x%x\n",(PCREG), get_long(saved_state.memory, PCREG), SPREG,USPREG,bf537_io.core_int.ipend);
        //}

	sclk_count++;
	/*if global int is disabled */
	/*
	   if(sclk_count == bf537_io.core_timer.tscale+1){
	   sclk_count = 0;
	   bf537_io.core_timer.tcount--;
	   if(bf537_io.core_timer.tcount == 0){
	   bf537_set_int(CORE_TIMER_IRQ);
	   bf537_io.core_timer.tcount = bf537_io.core_timer.tperbf537_io.;
	   }
	   } */
	if (sclk_count == bf537_io.core_timer.tscale + 1) {
		sclk_count = 0;
		timer_count--;
		if (timer_count == 0) {
			timer_count = BF537_HZ;
			/*if previs timer int handle is not finished , this int is lost */
			/*If core_timer enabled? */

			if ((bf537_io.core_timer.tcntl & 0x2)) {
				bf537_io.core_timer.tcntl |= 0x8;
				bf537_set_int (CORE_TIMER_IRQ);
			}
		}
	}

	if ((bf537_io.sic.sic_imask & 0x1000) && (bf537_io.uart.ier & 0x2)) {
		//printf("\nUART TX IRQ\n");
		bf537_set_int (((bf537_io.sic.sic_iar[1] & 0xf0000) >> 16) + 7);
		bf537_io.uart.iir = 0x2;
		bf537_io.sic.sic_isr |= 0x1000;
	}

	if (!(bf537_io.uart.lsr & 0x1)) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;
		unsigned char buf;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		//printf("\nUART RX IRQ before skyeye_uart_read\n");
		if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
			//printf ("\nUART RX IRQ,getchar=%c\n",buf);
			//printf("%c",buf);
			//putchar(buf);
			bf537_io.uart.rbr = buf;
			/*set DR bit in LSR */
			bf537_io.uart.lsr |= 0x1;
			//printf("\nUART RX IRQ getchar\n");
		}
	}
	if ((bf537_io.sic.sic_imask & 0x800) && (bf537_io.uart.ier & 0x1)
	    && (bf537_io.uart.lsr & 0x1)) {
		bf537_io.uart.iir = 0x4;
		bf537_io.sic.sic_isr |= 0x800;
		bf537_set_int (((bf537_io.sic.sic_iar[1] & 0xf000) >> 12) + 7);

	}
	handle_irq ();
}

static bu8
bf537_io_read_byte (void * p_state, bu32 addr)
{
	switch (addr) {
	default:
		if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
			return dma_read_byte (addr);
		}
		else if (addr >= UART_IO_START_ADDR
			 && addr < UART_IO_END_ADDR) {
			return uart_read_byte (addr);
		}
		else {
			IO_ERR;
		}
	}
}


static bu16
bf537_io_read_word (void * state, bu32 addr)
{
	switch (addr) {
	default:
		if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
			return dma_read_word (addr);
		}
		else if (addr >= UART_IO_START_ADDR
			 && addr < UART_IO_END_ADDR) {
			return uart_read_word (addr);
		}
		else if (addr >= DPMC_IO_START_ADDR
			 && addr < DPMC_IO_END_ADDR) {
			return dpmc_read_word (addr);
		}
		else if (addr >= EBIU_IO_START_ADDR
			 && addr < EBIU_IO_END_ADDR) {
			return ebiu_read_word (addr);
		}
		else if (addr >= RTC_IO_START_ADDR && addr < RTC_IO_END_ADDR) {
			return rtc_read_word (addr);
		}
		else if (addr >= PF_IO_START_ADDR && addr < PF_IO_END_ADDR) {
			return pf_read_word (addr);
		}
		else if (addr >= PORT_IO_START_ADDR && addr <= PORT_IO_END_ADDR){
			return port_read_word (addr);
		}
		else {
			IO_ERR;
		}
	}
}
static bu32
bf537_io_read_long (void * state, bu32 addr)
{
	switch (addr) {
	default:
		if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
			return dma_read_long (addr);
		}
		else if (addr >= UART_IO_START_ADDR
			 && addr < UART_IO_END_ADDR) {
			return uart_read_long (addr);
		}
		else if (addr >= DEU_IO_START_ADDR && addr < DEU_IO_END_ADDR) {
			return deu_read_long (addr);
		}
		else if (addr >= EBIU_IO_START_ADDR
			 && addr < EBIU_IO_END_ADDR) {
			return ebiu_read_long (addr);
		}
		else if (addr >= SIC_IO_START_ADDR && addr < SIC_IO_END_ADDR) {
			return sic_read_long (addr);
		}
		else if (addr >= L1MEM_IO_START_ADDR
			 && addr < L1MEM_IO_END_ADDR) {
			return l1mem_read_long (addr);
		}
		else if (addr >= L1DMEM_IO_START_ADDR
			 && addr < L1DMEM_IO_END_ADDR) {
			return l1dmem_read_long (addr);
		}
		else if (addr >= CORE_INT_IO_START_ADDR
			 && addr < CORE_INT_IO_END_ADDR) {
			return core_int_read_long (addr);
		}
		else if (addr >= RTC_IO_START_ADDR && addr < RTC_IO_END_ADDR) {
			return rtc_read_long (addr);
		}
		else if (addr >= CORE_TIMER_IO_START_ADDR
			 && addr < CORE_TIMER_IO_END_ADDR) {
			return core_timer_read_long (addr);
		}
		else if (addr >= TBUF_IO_START_ADDR
			 && addr < TBUF_IO_END_ADDR) {
			return tbuf_read_long (addr);
		}
		else if (addr >= PORT_IO_START_ADDR && addr <= PORT_IO_END_ADDR){
			return port_read_long (addr);
		}
		else if(addr >= ETH_IO_START_ADDR && addr <= ETH_IO_END_ADDR){
			return eth_read_long (addr);
		}
		else {
			IO_ERR;
		}
	}

}
static void
bf537_io_write_byte (void * state, bu32 addr, bu8 v)
{
	switch (addr) {
	default:
		if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
			dma_write_byte (addr, v);

		}
		else if (addr >= UART_IO_START_ADDR
			 && addr < UART_IO_END_ADDR) {
			uart_write_byte (addr, v);
		}
		else {
			IO_ERR;
		}

	}
	return;
}

static void
bf537_io_write_word (void * state, bu32 addr, bu16 v)
{
	if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
		dma_write_word (addr, v);
	}
	else if (addr >= UART_IO_START_ADDR
		 && addr < UART_IO_END_ADDR) {
		uart_write_word (addr, v);
	}
	else if (addr >= EBIU_IO_START_ADDR
		 && addr < EBIU_IO_END_ADDR) {
		ebiu_write_word (addr, v);
	}
	else if (addr >= WD_IO_START_ADDR && addr < WD_IO_END_ADDR) {
		wd_write_word (addr, v);
	}
	else if (addr >= DPMC_IO_START_ADDR
		 && addr < DPMC_IO_END_ADDR) {
		dpmc_write_word (addr, v);
	}
	else if (addr >= RTC_IO_START_ADDR && addr < RTC_IO_END_ADDR) {
		rtc_write_word (addr, v);
	}
	else if (addr >= PF_IO_START_ADDR && addr < PF_IO_END_ADDR) {
		pf_write_word (addr, v);
	}
	else if (addr >= PORT_IO_START_ADDR && addr <= PORT_IO_END_ADDR){
                port_write_word (addr, v);
	}
	else {
		IO_ERR;
	}
	return;
}
static void
bf537_io_write_long (void * state, bu32 addr, bu32 v)
{
	switch (addr) {
	default:
		if (addr >= DMA_IO_START_ADDR && addr < DMA_IO_END_ADDR) {
			dma_write_long (addr, v);

		}
		else if (addr >= UART_IO_START_ADDR
			 && addr < UART_IO_END_ADDR) {
			uart_write_long (addr, v);
		}
		else if (addr >= EBIU_IO_START_ADDR
			 && addr < EBIU_IO_END_ADDR) {
			ebiu_write_long (addr, v);
		}
		else if (addr >= CORE_INT_IO_START_ADDR
			 && addr < CORE_INT_IO_END_ADDR) {
			core_int_write_long (addr, v);
		}
		else if (addr >= SIC_IO_START_ADDR && addr < SIC_IO_END_ADDR) {
			sic_write_long (addr, v);
		}
		else if (addr >= L1MEM_IO_START_ADDR
			 && addr < L1MEM_IO_END_ADDR) {
			l1mem_write_long (addr, v);
		}
		else if (addr >= L1DMEM_IO_START_ADDR
			 && addr < L1DMEM_IO_END_ADDR) {
			l1dmem_write_long (addr, v);
		}
		else if (addr >= RTC_IO_START_ADDR && addr < RTC_IO_END_ADDR) {
			rtc_write_long (addr, v);
		}
		else if (addr >= CORE_TIMER_IO_START_ADDR
			 && addr < CORE_TIMER_IO_END_ADDR) {
			core_timer_write_long (addr, v);
		}
		else if (addr >= TBUF_IO_START_ADDR
			 && addr < TBUF_IO_END_ADDR) {
		  	tbuf_write_long (addr, v);
		}
		else if(addr >= ETH_IO_START_ADDR && addr <= ETH_IO_END_ADDR){
                        eth_write_long (addr, v);
                }
		else {
			IO_ERR;
		}

	}
	return;
}

static bu16
uart_read_word (bu32 addr)
{
	bu16 data;
	//printf("bf537_uart_read,addr=%x\n",addr);
	bu32 offset = addr - UART_IO_START_ADDR;
	
	/*
	if(offset != 0 && offset != 0x14 && offset != 0xc && offset!=0x4)
		printf("###############offset=0x%x\n",offset);
	*/
	static int read_num = 0;
	switch (offset) {
	case 0x0:		// RbR
		if (bf537_io.uart.lcr & 0x80) {
			data = bf537_io.uart.dlh;
		}

		if (read_num == 0) {
			read_num = 1;
			return 'k';
		}
		if (read_num == 1) {
			bf537_io.uart.lsr &= ~0x1;
			bf537_io.sic.sic_isr &= ~0x800;
			data = bf537_io.uart.rbr & 0xff;
			//bf537_io.uart.iir = 0x1;
			read_num = 0;
			//fprintf (PF, "*****read rbr=%x,pc=%x,isr=%x\n", data,
			//	 PCREG, bf537_io.sic.sic_isr);
		}
		break;

	case 0x4:		// ier
		if (bf537_io.uart.lcr & 0x80)
			data = bf537_io.uart.dlh;
		else
			data = bf537_io.uart.ier;
		break;
	case 0x8:		// iir

		data = bf537_io.uart.iir;
		//printf("read iir=%x,pc=%x\n",data,PCREG);
		bf537_io.uart.iir = 0x1;
		break;
	case 0xc:		// lcr
		data = bf537_io.uart.lcr;
		break;
	case 0x10:		// MCR
		data = 0x0;
		break;
	case 0x14:		// LSR
		data = bf537_io.uart.lsr;
		//printf("read lsr=%x,pc=%x\n",data,PCREG);
		break;
	case 0x1c:		// SCR
		data = bf537_io.uart.lcr;
		break;
	case 0x24:		// SCR
		data = bf537_io.uart.gctl;
		break;

	default:
		IO_ERR;
		DBG_PRINT ("uart_read(%s=0x%08x)\n", "uart_reg", addr);

		break;
	}

	return (data);
}


static void
uart_write_word (bu32 addr, bu16 data)
{
	bu32 offset = addr - UART_IO_START_ADDR;
	
	/*
	if(offset != 0 && offset != 0xc)
		printf("in %s,offset=%x,value = %x\n", __FUNCTION__, offset,data);
	*/
	switch (offset) {
	case 0x0:		// THR
		{
			unsigned char c = data & 0xff;
			/*There is no TSR ,so we set TEMT and THRE together */
			bf537_io.uart.lsr |= 0x60;
			bf537_io.sic.sic_isr &= ~0x1000;
			bf537_io.uart.iir = 0x1;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);
		}
		break;
	case 0x4:		//FCR
		/*just walkaround code to open uart */
		if (bf537_io.uart.lcr & 0x80) {
			bf537_io.uart.dlh = data;
		}
		else {
			bf537_io.uart.ier = data;
			/*generate RX interrupt */
			if (data & 0x1) {
			}
			/*generate TX interrupt */
			if (data & 0x2) {
			}
		}

		break;
	case 0xc:		// SCR
		bf537_io.uart.lcr = data;
		break;
	case 0x24:
		bf537_io.uart.gctl = data;
		break;
	default:
		IO_ERR;
		//printf("%c", data); fflush(stdout);
		DBG_PRINT ("uart_write(%s=0x%08x)\n", "uart_reg", addr);
		break;
	}
}
static bu32
uart_read_long (bu32 addr)
{
	bu16 ret;
	IO_ERR;
	return ret;
}

static void
uart_write_long (bu32 addr, bu32 value)
{
	uart_write_word(addr, (value & 0xffff));
	//IO_ERR;
	return;
}

static bu8
uart_read_byte (bu32 addr)
{
	bu8 ret;
	IO_ERR;
	return ret;
}
static void
uart_write_byte (bu32 addr, bu8 value)
{
	IO_ERR;
	return;
}
static bu16
ebiu_read_word (bu32 addr)
{
	int offset = addr - EBIU_IO_START_ADDR;
	switch (offset) {
	case 0:
		return bf537_io.ebiu.amgctl;
	case 4:
		return bf537_io.ebiu.ambctl0;
	case 8:
		return bf537_io.ebiu.ambctl1;
	case 0x10:
		return bf537_io.ebiu.sdgctl;
	case 0x1c:
		return bf537_io.ebiu.sdstat;
	default:
		IO_ERR;
	}
	return;

}
static bu32
ebiu_read_long (bu32 addr)
{
	int offset = addr - EBIU_IO_START_ADDR;
	switch (offset) {
	case 0:
		return bf537_io.ebiu.amgctl;
	case 4:
		return bf537_io.ebiu.ambctl0;
	case 8:
		return bf537_io.ebiu.ambctl1;
	case 0x10:
		return bf537_io.ebiu.sdgctl;
	default:
		IO_ERR;
	}
	return;

}
static void
ebiu_write_long (bu32 addr, bu32 v)
{
	int offset = addr - EBIU_IO_START_ADDR;
	switch (offset) {
	case 0:
		bf537_io.ebiu.amgctl = v;
		break;
	case 4:
		bf537_io.ebiu.ambctl0 = v;
		break;
	case 8:
		bf537_io.ebiu.ambctl1 = v;
		break;
	case 0x10:
		bf537_io.ebiu.sdgctl = v;
		break;
	default:
		IO_ERR;
	}
	return;
}
static void
ebiu_write_word (bu32 addr, bu16 v)
{
	int offset = addr - EBIU_IO_START_ADDR;
	switch (offset) {
	case 0:
		bf537_io.ebiu.amgctl = v;
		break;
	case 4:
		bf537_io.ebiu.ambctl0 = v;
		break;
	case 8:
		bf537_io.ebiu.ambctl1 = v;
		break;
	case 0x18:
		bf537_io.ebiu.sdrrc = v;
		break;
	default:
		IO_ERR;
	}
	return;
}



static bu8
dma_read_byte (bu32 addr)
{
	bu8 ret = 0;
	IO_ERR;
	return ret;
}
static void
dma_write_byte (bu32 addr, bu8 value)
{
	IO_ERR;
	/*
	   int channel = addr&0x3c0;
	   int offset = (addr&0x3f)>>2;
	   bf537_io.dma.bf537_dma_channel[channel][offset] = value;
	 */
	return;
}


static bu16
dma_read_word (bu32 addr)
{
	bu16 ret;
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	ret = bf537_io.dma.bf537_dma_channel[channel][offset];
	return ret;
}
static void
dma_write_word (bu32 addr, bu16 value)
{
	int i;
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	DBG_PRINT("\nIn %s,channel=0x%x,offset = %x,value=%x\n",__FUNCTION__, channel,offset,value);
	switch (offset) {
	case 0x2:
		/* CONFIG */ 
		bf537_io.dma.bf537_dma_channel[channel][offset] = value;
		if (!(value & 0x1))
                        break;
		if (channel == BF537_MDMA_D0) {

			unsigned int src =
				bf537_io.dma.bf537_dma_channel[BF537_MDMA_S0][START_ADDR];
			unsigned int dst =
				bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][START_ADDR];
			short x_modify =
                                (short)bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][X_MODIFY];
			unsigned int size =
				bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][X_COUNT] * \
				abs(x_modify);

			/* if two-demisbf537_io. is used */
			if(bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][DMA_CONFIG] & 0x10){
				size = size * bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][Y_COUNT] * \
					bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][Y_MODIFY];
			}
			/* if 16 width is used */
			if((((bf537_io.dma.bf537_dma_channel[BF537_MDMA_D0][DMA_CONFIG] & 0xc) >> 2)) == 0x1){
				size = size / 2;
			}
			i = size;
			//mem_cpy(start_addr,end_addr,size);

			/*work around code for dma copy to isram */
			/*
 			if (dst >= 0xffa00000) {
				return;
			}*/
				/***************************************/
			DBG_PRINT (
				 "DMA copy begin from 0x%x to 0x%x,size=0x%x\n",
				 src, dst, size);
			for (; i >= 0; i--) {	
				if(x_modify > 0)
					put_byte (saved_state.memory, dst++,
					  get_byte (saved_state.memory,
						    src++));
				else
					 put_byte (saved_state.memory, dst--,
                                          get_byte (saved_state.memory,
                                                    src--));
			}

		}
		break;

	default:
		bf537_io.dma.bf537_dma_channel[channel][offset] = value;
		break;
	}
	return;
}
static bu32
dma_read_long (bu32 addr)
{
	bu32 ret;
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	ret = bf537_io.dma.bf537_dma_channel[channel][offset];
	return ret;
}
static void
dma_write_long (bu32 addr, bu32 value)
{
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	DBG_PRINT("\nIn %s channel=0x%x,offset = %x,value=%x\n",__FUNCTION__,channel,offset,value); 
	bf537_io.dma.bf537_dma_channel[channel][offset] = value;
	return;
}
static void
core_int_write_long (bu32 addr, bu32 v)
{
	int offset = addr - CORE_INT_IO_START_ADDR;
	//printf("%x,%x\n",addr,v);
	switch (offset) {
	case 0x104:
		bf537_io.core_int.imask = (v | 0x1f) & 0xffff;
		break;
	case 0x108:
		bf537_io.core_int.ipend = v;
		break;
	case 0x10c:
		bf537_io.core_int.ilat = v;
		//printf("write ilat %x\n",v);
		break;
	case 0x110:
		bf537_io.core_int.iprio= v;
		break;
	default:
		if (offset >= 0 && offset < 0x100) {
			bf537_io.core_int.evt[offset >> 2] = v;
			return;
		}
		IO_ERR;
	}
}
static bu32
core_int_read_long (bu32 addr)
{
	int offset = addr - CORE_INT_IO_START_ADDR;
	bu32 ret;
	//printf("read %x\n",offset);
	switch (offset) {
	case 0x104:
		ret = (bf537_io.core_int.imask | 0x1f) & 0xffff;
		break;
	case 0x108:
		ret = bf537_io.core_int.ipend;
		break;
	case 0x10c:
		ret = bf537_io.core_int.ilat;
		//printf("read ilat %x",ret);
		break;
	case 0x110:
		ret = bf537_io.core_int.iprio;
		break;
	default:
		if (offset >= 0 && offset < 0x100) {
			ret = bf537_io.core_int.evt[offset >> 2];
			return ret;
		}
		IO_ERR;

	}
	return ret;

}
static void
wd_write_word (bu32 addr, bu16 v)
{
	int offset = addr - WD_IO_START_ADDR;
	switch (offset) {
	case 0x0:
		bf537_io.wd.ctl = v;
		break;
	case 0x4:
		bf537_io.wd.cnt = v;
		break;
	case 0x8:
		bf537_io.wd.stat = v;
		break;
	default:
		IO_ERR;
	}
}



static bu32
deu_read_long (bu32 addr)
{
	int offset = addr - DEU_IO_START_ADDR;
	switch (offset) {
	case 0x0:
		return bf537_io.deu.dspid;
	default:
		IO_ERR;

	}
}

static bu16
dpmc_read_word (bu32 addr)
{
	int offset = addr - DPMC_IO_START_ADDR;
	bu16 ret;
	switch (offset) {
	case 0x0:
		ret = bf537_io.dpmc.pll_ctl;
		break;
	case 0x4:
		ret = bf537_io.dpmc.pll_div;
		break;
	case 0x8:
		ret = bf537_io.dpmc.vr_ctl;
		break;
	case 0xc:
		ret = bf537_io.dpmc.pll_stat;	/*PLL_LOCKED is set */
		break;
	case 0x10:
		ret = bf537_io.dpmc.pll_lockcnt;
		break;
	default:
		IO_ERR;
	}
	return ret;
}
static void
dpmc_write_word (bu32 addr, bu16 v)
{
	int offset = addr - DPMC_IO_START_ADDR;
	switch (offset) {
	case 0x0:
		bf537_io.dpmc.pll_ctl = v;
		break;
	case 0x4:
		bf537_io.dpmc.pll_div = v;
		break;
	case 0x8:
		bf537_io.dpmc.vr_ctl = v;
		break;
	case 0xc:
		bf537_io.dpmc.pll_stat = v;
		break;
	case 0x10:
		bf537_io.dpmc.pll_lockcnt = v;
		break;
	default:
		IO_ERR;
	}
	return;
}
static bu32
tbuf_read_long (bu32 addr)
{
	int offset = addr - TBUF_IO_START_ADDR;
	switch (offset) {
	case 0:
		return bf537_io.tbuf.ctrl;
	case 4:
		return bf537_io.tbuf.stat;

	case 0x100:
	  if (bf537_io.tbuf.rsel == 1) {
	        bf537_io.tbuf.rsel = 0;
	        if (bf537_io.tbuf.rix >= 16) bf537_io.tbuf.rix = 0;
		return bf537_io.tbuf.sbuf[bf537_io.tbuf.rix];
	  } else {
	        bf537_io.tbuf.rsel = 1;
		return bf537_io.tbuf.dbuf[bf537_io.tbuf.rix++];
	  }
	  break;

	default:
		IO_ERR;
 	        break;

	}
	return 0;

}
static void
tbuf_write_long (bu32 addr, bu32 v)
{
	int offset = addr - TBUF_IO_START_ADDR;
	switch (offset) {
	case 0:
		bf537_io.tbuf.ctrl = v;
		break;
	case 4:
		bf537_io.tbuf.stat = v;
		break;

	case 0x100:
	  if (bf537_io.tbuf.wsel == 1) {
	        bf537_io.tbuf.wsel = 0;
	        if (bf537_io.tbuf.wix >= 16) bf537_io.tbuf.wix = 0;
		bf537_io.tbuf.sbuf[bf537_io.tbuf.wix] = v;
	  } else {
	        bf537_io.tbuf.wsel = 1;
		bf537_io.tbuf.dbuf[bf537_io.tbuf.wix++] = v;
	  }
	  break;

	default:
		IO_ERR;
 	        break;

	}
	return ;
}

static bu32
sic_read_long (bu32 addr)
{
	int offset = addr - SIC_IO_START_ADDR;
	bu32 ret;
	switch (offset) {
	case 0x0:
		ret = bf537_io.sic.swrst;
		break;
	case 0x4:
		ret = bf537_io.sic.syscr;
		break;
	case 0xc:
		ret = bf537_io.sic.sic_imask;
		//printf("KSDBG:read imask ret= %x\n",ret);
		break;
	case 0x20:
		ret = bf537_io.sic.sic_isr;
		//printf("read sic_isr 0x%x\n",ret);
		break;
	case 0x24:
		ret = bf537_io.sic.sic_iwr;
		break;
	default:
		if (offset >= 0x10 && offset <= 0x1c) {
			ret = bf537_io.sic.sic_iar[(offset - 0x10) >> 2];
			return ret;
		}

		IO_ERR;
	}
	return ret;
}
static void
sic_write_long (bu32 addr, bu32 v)
{
	int offset = addr - SIC_IO_START_ADDR;
	switch (offset) {
	case 0x24:
		bf537_io.sic.sic_iwr = v;
		break;
	case 0xc:
		//printf("KSDBG:write sic_imask v=%x\n",v);
		bf537_io.sic.sic_imask = v;
		break;
	default:
		if (offset >= 0x10 && offset <= 0x1c) {
			bf537_io.sic.sic_iar[(offset - 0x10) >> 2] = v;
			return;
		}
		IO_ERR;
	}
}
static void
l1mem_write_long (bu32 addr, bu32 v)
{
	int offset = addr - L1MEM_IO_START_ADDR;
	int pos = offset >> 2;
	switch (pos) {
		default:
			bf537_io.l1mem.reg[pos] = v;
			break;
	}
}
static bu32
l1mem_read_long (bu32 addr)
{
	int offset = addr - L1MEM_IO_START_ADDR;
	int pos = offset >> 2;
	bu32 ret;
	switch (pos) {
	default:
		ret = bf537_io.l1mem.reg[pos];
	}
	return ret;
}
static void
l1dmem_write_long (bu32 addr, bu32 v)
{
	int offset = addr - L1DMEM_IO_START_ADDR;
	int pos = offset >> 2;
	switch (pos) {
	default:
		bf537_io.l1dmem.reg[pos];
		break;
	}
}
static void
rtc_write_word (bu32 addr, bu16 v)
{
	int offset = addr - RTC_IO_START_ADDR;
	switch (offset) {
	case 0x4:
		bf537_io.rtc.ictl = v;
		return;
	case 0x14:
		bf537_io.rtc.pren = v;
		/*set write complete bit to one */
		bf537_io.rtc.istat |= 0x8000;
		return;
	case 0x8:
		bf537_io.rtc.istat = v;
		return;

	default:
		IO_ERR;
	}
}
static bu16
rtc_read_word (bu32 addr)
{
	int offset = addr - RTC_IO_START_ADDR;
	bu16 ret;
	switch (offset) {

	case 0x14:
		ret = bf537_io.rtc.pren;
		break;
	case 0x8:
		ret = bf537_io.rtc.istat;
		/*clear write complete bit */
		bf537_io.rtc.istat &= ~0x8000;
		break;
	default:
		IO_ERR;
	}
	return ret;

}
static void
rtc_write_long (bu32 addr, bu32 v)
{
	int offset = addr - RTC_IO_START_ADDR;
	switch (offset) {
	case 0x0:
		bf537_io.rtc.stat = v;
		return;
	case 0x10:
		bf537_io.rtc.alarm = v;
		return;
	default:
		IO_ERR;
	}
}
static bu32
rtc_read_long (bu32 addr)
{
	int offset = addr - RTC_IO_START_ADDR;
	bu32 ret;
	switch (offset) {
	case 0x0:
		ret = bf537_io.rtc.stat;
		break;
	default:
		IO_ERR;
	}
	return ret;
}
static bu32
l1dmem_read_long (bu32 addr)
{
	int offset = addr - L1DMEM_IO_START_ADDR;
	int pos = offset >> 2;
	bu32 ret;
	switch (pos) {
	default:
		ret = bf537_io.l1dmem.reg[pos];
		break;
	}
	return ret;
}
static void
core_timer_write_long (bu32 addr, bu32 v)
{
	int offset = addr - CORE_TIMER_IO_START_ADDR;
	//printf("offset=%x",offset);
	switch (offset) {
	case 0x0:
		bf537_io.core_timer.tcntl = v;
		/*not sure core_int is open at this time */
		if (bf537_io.core_timer.tcntl & 0x2) {
			bf537_io.core_int.imask |= 1 << CORE_TIMER_IRQ;
		}
		break;
	case 0x4:
		bf537_io.core_timer.tperio = v;
		break;
	case 0x8:
		bf537_io.core_timer.tscale = v;
		break;
	case 0xc:
		bf537_io.core_timer.tcount = v;
		break;
	default:
		IO_ERR;
	}
	return;
}
static bu32
core_timer_read_long (bu32 addr)
{
	int offset = addr - CORE_TIMER_IO_START_ADDR;
	bu32 ret;
	switch (offset) {
	case 0x0:
		ret = bf537_io.core_timer.tcntl;
		break;
	case 0x4:
		ret = bf537_io.core_timer.tperio;
		break;
	case 0x8:
		ret = bf537_io.core_timer.tscale;
		break;
	case 0xc:
		ret = bf537_io.core_timer.tcount;
		break;
	default:
		IO_ERR;
	}
	return ret;

}

static bu16
pf_read_word (bu32 addr)
{
	int offset = addr - PF_IO_START_ADDR;
	bu32 ret;
	switch (offset) {
		case 0x30:
			ret = bf537_io.pf.fio_dir;
			break;
		case 0x40:
			ret = bf537_io.pf.fio_inen;
			break;
		default:
			IO_ERR;
	}
	return ret;
}
static void
pf_write_word (bu32 addr, bu16 v)
{
	int offset = addr - PF_IO_START_ADDR;
	switch (offset) {
	case 0x4:
		bf537_io.pf.fio_flag_c = v;
		return;
	case 0x8:
		bf537_io.pf.fio_flag_s = v;
		return;
	case 0x14:
		bf537_io.pf.fio_maska_c = v;
		return;
	case 0x24:
		bf537_io.pf.fio_maskb_c = v;
		return;
	case 0x30:
		bf537_io.pf.fio_dir = v;
		return;
        case 0x10:  // Flag Mask Interrupt A Register (set directly)
        case 0x38:  // Flag Source Sensitivity Register
        case 0x40:  // Flag Input Enable Register
               return;

	default:
		IO_ERR;
	}
}

static bu16 port_read_word(bu32 addr){
	uint32_t offset = addr - PORT_IO_START_ADDR;
	switch(offset){
		case 0x0:
			return bf537_io.port.portf_fer;
		case 0xc:
			return bf537_io.port.port_mux;
		default:
			IO_ERR;
	}
}
static void port_write_word(bu32 addr, bu16 v){
	uint32_t offset = addr - PORT_IO_START_ADDR;
	switch(offset){
		case 0x0:
			bf537_io.port.portf_fer = v;
			return;
		case 0xc:
			bf537_io.port.port_mux = v;
			return;
		default:
			IO_ERR;
	}
}
static bu32 port_read_long(bu32 addr){
	IO_ERR;
	return -1;
}
static bu32 eth_read_long(bu32 addr){
	uint32_t offset = addr - ETH_IO_START_ADDR;
	switch(offset){
		case 0x64:
			return bf537_io.eth.emac_systat;
		default:
			IO_ERR;
	}
}
static void eth_write_long(bu32 addr, bu32 v){
	uint32_t offset = addr - ETH_IO_START_ADDR;
	switch(offset){
		case 0x64:
			bf537_io.eth.emac_systat = v;
			return;
		default:
			IO_ERR;
	}
}
void
bf537_mach_init (void * curr_state, machine_config_t * this_mach)
{
	saved_state_type *p_state;

	/*init bf537_io. value */
	bf537_io.dpmc.pll_div = 0x0005;
	bf537_io.dpmc.pll_ctl = 0x1400;
	bf537_io.dpmc.pll_lockcnt = 0x0200;
	bf537_io.dpmc.pll_stat = 0x00a2;
	bf537_io.core_int.ipend = 0x11; /*at the beginning,global int is disabled and we are in Reset exception */
	bf537_io.core_int.imask = 0x1f;
	bf537_io.core_int.ilat = 0x0;
	/**/ 
	bf537_io.sic.sic_isr = 0x0;
	bf537_io.uart.lcr = 0x0;
	bf537_io.uart.dll = 0x0001;
	bf537_io.uart.ier = 0x0;
	bf537_io.uart.iir = 0x1;
	bf537_io.uart.lsr = 0x60;
        bf537_io.tbuf.ctrl = 0;
        bf537_io.tbuf.stat = 0;
        bf537_io.tbuf.rix = 0;
        bf537_io.tbuf.rsel = 0;
        bf537_io.tbuf.wix = 0;
        bf537_io.tbuf.wsel = 0;

	/*init mach */
	if (!this_mach) {
		skyeye_exit (-1);
	}
	this_mach->mach_io_read_byte = bf537_io_read_byte;
	this_mach->mach_io_read_halfword = bf537_io_read_word;
	this_mach->mach_io_read_word = bf537_io_read_long;
	this_mach->mach_io_write_byte = bf537_io_write_byte;
	this_mach->mach_io_write_halfword = bf537_io_write_word;
	this_mach->mach_io_write_word = bf537_io_write_long;
	this_mach->mach_io_do_cycle = bf537_io_do_cycle;
	this_mach->mach_set_intr = bf537_set_int;

	p_state = (saved_state_type *)curr_state;
	p_state->disable_int = bf537_disable_int;
	p_state->enable_int = bf537_enable_int;
	p_state->clear_int = bf537_clear_int;
	p_state->sti = bf537_sti;
	p_state->cli = bf537_cli;
	p_state->set_int = bf537_set_int;
}
