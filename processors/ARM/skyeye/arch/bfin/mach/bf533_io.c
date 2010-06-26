/*
        bf533_io.c - implementation of bf533 machine simulation
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

#define IO_ERR {printf("\n%s io error!!!addr=0x%x,pc=0x%x\n",__FUNCTION__,addr,PCREG);raise (SIGILL);}
#define MALLOC_ERR {printf("\n%s malloc error!\n",__FUNCTION__);skyeye_exit(-1);}

/*declare the device io functions*/

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

static void handle_irq ();
static void bf533_disable_int ();
     static void bf533_enable_int ();

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
     } bf533_uart_t;
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
     } bf533_dma_channel_t;

     typedef struct l1mem
     {
	     bu32 reg[L1MEM_IO_SIZE / 4];
     } bf533_l1mem_t;

     typedef struct l1dmem
     {
	     bu32 reg[L1DMEM_IO_SIZE / 4];
     } bf533_l1dmem_t;

     typedef struct dma
     {
	     bu16 tc_per;
	     bu16 tc_cnt;
	     bu32 bf533_dma_channel[12][16];

     } bf533_dma_t;

     typedef struct ebiu
     {
	     bu16 amgctl;
	     bu16 ambctl0;
	     bu16 ambctl1;
	     bu16 sdgctl;
	     bu16 sdbctl;
	     bu16 sdrrc;
	     bu16 sdstat;
     } bf533_ebiu_t;

     typedef struct core_int
     {
	     bu32 evt[16];
	     bu32 imask;
	     bu32 ipend;
	     bu32 iprio;
	     bu32 ilat;

     } bf533_core_int_t;

     typedef struct wd
     {
	     bu16 ctl;
	     bu32 cnt;
	     bu32 stat;
     } bf533_wd_t;

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

     } bf533_tbuf_t;

     typedef struct deu
     {
	     bu32 dspid;
     } bf533_deu_t;

     typedef struct dpmc
     {
	     bu16 pll_ctl;
	     bu16 pll_stat;
	     bu16 pll_lockcnt;
	     bu16 vr_ctl;
	     bu16 pll_div;
     } bf533_dpmc_t;

     typedef struct sic
     {
	     bu32 swrst;
	     bu32 syscr;
	     bu32 sic_imask;
	     bu32 sic_iar[3];
	     bu32 sic_isr;
	     bu32 sic_iwr;
     } bf533_sic_t;

     typedef struct rtc
     {
	     bu32 stat;
	     bu32 ictl;
	     bu32 istat;
	     bu32 swcnt;
	     bu32 alarm;
	     bu32 pren;
     } bf533_rtc_t;

     typedef struct core_timer
     {
	     bu32 tcntl;
	     bu32 tperiod;
	     bu32 tscale;
	     bu32 tcount;
     } bf533_core_timer_t;

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
     } bf533_pf_t;

     typedef struct bf533_io
     {
	     bf533_uart_t uart;	/* Receive data register */
	     bf533_dma_t dma;
	     bf533_ebiu_t ebiu;
	     bf533_core_int_t core_int;
	     bf533_wd_t wd;
	     bf533_deu_t deu;
	     bf533_dpmc_t dpmc;
	     bf533_sic_t sic;
	     bf533_l1mem_t l1mem;
	     bf533_l1dmem_t l1dmem;
	     bf533_rtc_t rtc;
	     bf533_core_timer_t core_timer;
	     bf533_pf_t pf;
	     bf533_tbuf_t tbuf;

     } bf533_io_t;


static  bf533_io_t io;

/*also be called by raise inst and except*/
static void bf533_set_int (int irq)
{
	//if(irq != CORE_TIMER_IRQ & irq != 0)
	 //fprintf(PF,"####################irq=%d,in %s\n",irq,__FUNCTION__);
	//if ((io.core_int.imask | 0x1f) & (1 << irq)) {
		//if(irq != CORE_TIMER_IRQ & irq != 0)
		//     fprintf(PF,"####################irq=%d,in %s\n",irq,__FUNCTION__);
		/*set the corresponding int bit to 1 in ilat */
		io.core_int.ilat |= (1 << irq);
	//}
}
static void
bf533_clear_int (int irq_no_use)
{
	int irq;
	//fprintf(PF,"KSDBG:begin in %s,ipend=0x%x,ilat=0x%x,SPREG=0x%x,irq=%d\n",__FUNCTION__, io.core_int.ipend,io.core_int.ilat, SPREG, irq);

	/*fix me, trigger the corresponding int according to some prio check, */
	for (irq = 0; irq < 16; irq++) {
		/* check there is a pending int for clear */
		if ((io.core_int.ipend >> irq) & 0x1) {
			/*clear the int bit */
			io.core_int.ipend &= ~(1 << irq);
			/*clear corresponding int in the device */
			if (irq == CORE_TIMER_IRQ) {
				io.core_timer.tcntl &= ~0x8;
			}
			if (io.core_int.ipend == 0x0) {
				/*There is no interrupt to handle, switch mode */
				//fprintf(PF,"KSDBG:mode switch,SPREG=0x%x,USPREG=0x%x\n",SPREG,USPREG);
				MODE = USR_MODE;
				OLDSPREG = SPREG;
				SPREG = USPREG;
			}
			else
				;
				//fprintf(PF,"KSDBG:in super mode,ipend=0x%x,SPREG=0x%x,irq=%d\n",io.core_int.ipend, SPREG, irq);
			return;
		}
	}
	//fprintf(PF,"KSDBG:end in %s,ipend=0x%x,SPREG=0x%x,irq=%d\n",__FUNCTION__, io.core_int.ipend, SPREG, irq);

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
	if (io.core_int.ipend & 0x10) {
		return;
	}
	/*fix me, trigger the corresponding int according to some prio check, */
	for (irq = 0; irq < 16; irq++) {
		if (((io.core_int.ilat&(io.core_int.imask|0x1f)) >> irq) & 0x1) {
			if (irq != CORE_TIMER_IRQ)
				;
				//fprintf (PF,
				//	 "# in %s begin,irq=%d,pc=0x%x,ipend=0x%x,RETI=0x%x\n",
				//	 __FUNCTION__, irq, PCREG, io.core_int.ipend, RETIREG);
			/*current there is a higher or equal priority  pending int for handle,wait until it finish */
			if(io.core_int.ipend&(~((~0x0) << irq)))
				return;
			
			/* set ipend bit , and clear ilat */
			io.core_int.ilat &= ~(1 << irq);
			io.core_int.ipend |= (1 << irq);
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
				io.core_timer.tcntl &= ~0x8;
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
				//	 io.core_int.ipend);
		
				saved_state.retx = PCREG;
			}
			else {
				saved_state.reti = PCREG;
			}
			PCREG = io.core_int.evt[irq];

			if (irq != CORE_TIMER_IRQ)
                                //fprintf (PF,
                                  //       "## in %s end,irq=%d,pc=0x%x,ipend=0x%x\n",
                                    //     __FUNCTION__, irq, PCREG, io.core_int.ipend);

			/*at the same time , disable global int for protecting reti */
			bf533_disable_int ();
			return;
		}
	}
}
static void
bf533_disable_int ()
{
	//printf("in %s\n",__FUNCTION__);
	io.core_int.ipend |= 0x10;
}
static void
bf533_enable_int ()
{
	//printf("in %s\n",__FUNCTION__);
	io.core_int.ipend &= ~0x10;
}
static void
bf533_cli (bu32 * dreg)
{
	*dreg = io.core_int.imask;
	//printf("cli,%x\n",*dreg);
	io.core_int.imask = 0x1f;

}
static void
bf533_sti (bu32 * dreg)
{
	//printf("sti,%x\n",*dreg);
	io.core_int.imask = *dreg;
}


#define BF533_HZ 50
static UART_OPEN = 0;

static void
bf533_io_do_cycle ()
{
	static int sclk_count = 0;
	static int uart_tx_count = 0;
	
	//if (PCREG >= 0x7480048){
	//                fprintf(PF,"KSDBG:pc=0x%x,insn@pc=0x%x,sp=0x%x,usp=0x%x,ipend=0x%x\n",(PCREG-0x7480044), get_long(saved_state.memory, PCREG), SPREG,USPREG,io.core_int.ipend);
        //}*/

	sclk_count++;
	/*if global int is disabled */
	/*
	   if(sclk_count == io.core_timer.tscale+1){
	   sclk_count = 0;
	   io.core_timer.tcount--;
	   if(io.core_timer.tcount == 0){
	   bf533_set_int(CORE_TIMER_IRQ);
	   io.core_timer.tcount = io.core_timer.tperiod;
	   }
	   } */
	if (sclk_count == io.core_timer.tscale + 1) {
		sclk_count = 0;
               if ( io.core_timer.tcntl & 0x2 ) {
                       io.core_timer.tcount--;
                       if (io.core_timer.tcount == 0) {
                               io.core_timer.tcount = io.core_timer.tperiod / 10;
                               /*if previous timer int handle is not finished , this int is lost */
                               /*If core_timer enabled? */

                               if ((io.core_timer.tcntl & 0x2) && ! (io.core_timer.tcntl & 0x8) ) {
                                       io.core_timer.tcntl |= 0x8;
                                       bf533_set_int (CORE_TIMER_IRQ);
                                       uart_tx_count++;
                               }
			}
		}
	}

	if ((io.sic.sic_imask & 0x8000) && (io.uart.ier & 0x2)) {
		//       printf("\nUART TX IRQ\n");

		bf533_set_int (((io.sic.sic_iar[1] & 0xf0000000) >> 28) + 7);
		io.uart.iir = 0x2;
		io.sic.sic_isr |= 0x8000;
		uart_tx_count = 0;

	}

	if (!(io.uart.lsr & 0x1)) {
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
			io.uart.rbr = buf;
			/*set DR bit in LSR */
			io.uart.lsr |= 0x1;
			//printf("\nUART RX IRQ getchar\n");
		}
	}
	if ((io.sic.sic_imask & 0x4000) && (io.uart.ier & 0x1)
	    && (io.uart.lsr & 0x1)) {
		io.uart.iir = 0x4;
		io.sic.sic_isr |= 0x4000;
		bf533_set_int (((io.sic.sic_iar[1] & 0xf000000) >> 24) + 7);

	}
	/*
	fprintf(PF,"KSDBG:in super mode,ipend=0x%x,SPREG=0x%x,irq=%d\n",io.core_int.ipend, SPREG, irq);
	*/
	handle_irq ();
}

static bu8
bf533_io_read_byte (void * state, bu32 addr)
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
bf533_io_read_word (void * state, bu32 addr)
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
		else {
			IO_ERR;
		}
	}
}
static bu32
bf533_io_read_long (void * state, bu32 addr)
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

		else {
			IO_ERR;
		}
	}

}
static void
bf533_io_write_byte (void * state, bu32 addr, bu8 v)
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
bf533_io_write_word (void * state, bu32 addr, bu16 v)
{
	switch (addr) {
	default:
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
		else {
			IO_ERR;
		}

	}
	return;
}
static void
bf533_io_write_long (void * state, bu32 addr, bu32 v)
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
		  return tbuf_write_long (addr, v);
		}
		else {
			IO_ERR;
		}

	}
	return;
}

bu16
uart_read_word (bu32 addr)
{
	bu16 data;
	//printf("bf533_uart_read,addr=%x\n",addr);
	bu32 offset = addr - UART_IO_START_ADDR;
	/*
	   if(offset != 0 && offset != 0x14 && offset != 0xc && offset!=0x4)
	   printf("###############offset=0x%x\n",offset);
	 */
	static int read_num = 0;
	switch (offset) {
	case 0x0:		// RbR
		if (io.uart.lcr & 0x80) {
			data = io.uart.dlh;
		}

		if (read_num == 0) {
			read_num = 1;
			return 'k';
		}
		if (read_num == 1) {
			io.uart.lsr &= ~0x1;
			io.sic.sic_isr &= ~0x4000;
			data = io.uart.rbr & 0xff;
			//io.uart.iir = 0x1;
			read_num = 0;
			//fprintf (PF, "*****read rbr=%x,pc=%x,isr=%x\n", data,
			//	 PCREG, io.sic.sic_isr);
		}
		break;

	case 0x4:		// ier
		if (io.uart.lcr & 0x80)
			data = io.uart.dlh;
		else
			data = io.uart.ier;
		break;
	case 0x8:		// iir

		data = io.uart.iir;
		//printf("read iir=%x,pc=%x\n",data,PCREG);
		io.uart.iir = 0x1;
		break;
	case 0xc:		// lcr
		data = io.uart.lcr;
		break;
	case 0x10:		// MCR
		data = 0x0;
		break;
	case 0x14:		// LSR
		data = io.uart.lsr;
		//printf("read lsr=%x,pc=%x\n",data,PCREG);
		break;
	case 0x1c:		// SCR
		data = io.uart.lcr;
		break;
	case 0x24:		// SCR
		data = io.uart.gctl;
		break;

	default:
		IO_ERR;
		DBG_PRINT ("uart_read(%s=0x%08x)\n", "uart_reg", addr);

		break;
	}

	return (data);
}


void
uart_write_word (bu32 addr, bu16 data)
{
	bu32 offset = addr - UART_IO_START_ADDR;
	
	   //if(offset != 0 && offset != 0xc)
	   //printf("************offset=%x,value = %x\n",offset,data);
	
	switch (offset) {
	case 0x0:		// THR
		{
			unsigned char c = data & 0xff;
			/*There is no TSR ,so we set TEMT and THRE together */
			io.uart.lsr |= 0x60;
			io.sic.sic_isr &= ~0x8000;
			io.uart.iir = 0x1;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);
		}
		break;
	case 0x4:		//FCR
		/*just walkaround code to open uart */
		if (io.uart.lcr & 0x80) {
			io.uart.dlh = data;
			/*
			   if(data&0x8){
			   printf("KSDBG:UART OPEN\n");
			   UART_OPEN = 1;
			   } */
		}
		else {
			io.uart.ier = data;
			/*generate RX interrupt */
			if (data & 0x1) {
			}
			/*generate TX interrupt */
			if (data & 0x2) {
			}
			if (data & 0x8) {
				UART_OPEN = 1;
			}
		}

		break;
	case 0xc:		// SCR
		io.uart.lcr = data;
		break;
	case 0x24:
		io.uart.gctl = data;
		break;
	default:
		IO_ERR;
		//printf("%c", data); fflush(stdout);
		DBG_PRINT ("uart_write(%s=0x%08x)\n", "uart_reg", addr);
		break;
	}
}
bu32
uart_read_long (bu32 addr)
{
	bu16 ret;
	IO_ERR;
	return ret;
}

void
uart_write_long (bu32 addr, bu32 value)
{
	uart_write_word(addr, (value & 0xffff));
	//IO_ERR;
	return;
}

bu8
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
		return io.ebiu.amgctl;
	case 4:
		return io.ebiu.ambctl0;
	case 8:
		return io.ebiu.ambctl1;
	case 0x10:
		return io.ebiu.sdgctl;
	case 0x1c:
		return io.ebiu.sdstat;
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
		return io.ebiu.amgctl;
	case 4:
		return io.ebiu.ambctl0;
	case 8:
		return io.ebiu.ambctl1;
	case 0x10:
		return io.ebiu.sdgctl;
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
		io.ebiu.amgctl = v;
		break;
	case 4:
		io.ebiu.ambctl0 = v;
		break;
	case 8:
		io.ebiu.ambctl1 = v;
		break;
	case 0x10:
		io.ebiu.sdgctl = v;
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
		io.ebiu.amgctl = v;
		break;
	case 4:
		io.ebiu.ambctl0 = v;
		break;
	case 8:
		io.ebiu.ambctl1 = v;
		break;
	case 0x18:
		io.ebiu.sdrrc = v;
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
	   io.dma.bf533_dma_channel[channel][offset] = value;
	 */
	return;
}


static bu16
dma_read_word (bu32 addr)
{
	bu16 ret;
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	ret = io.dma.bf533_dma_channel[channel][offset];
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
		/*CONFIG*/ 
		io.dma.bf533_dma_channel[channel][offset] = value;
		if (!(value & 0x1))
                        break;
		if (channel == BF533_MDMA_D0) {

			unsigned int src =
				io.dma.bf533_dma_channel[BF533_MDMA_S0][START_ADDR];
			unsigned int dst =
				io.dma.bf533_dma_channel[BF533_MDMA_D0][START_ADDR];
			short x_modify =
                                (short)io.dma.bf533_dma_channel[BF533_MDMA_D0][X_MODIFY];
			unsigned int size =
				io.dma.bf533_dma_channel[BF533_MDMA_D0][X_COUNT] * \
				abs(x_modify);

			/* if two-demision is used */
			if(io.dma.bf533_dma_channel[BF533_MDMA_D0][DMA_CONFIG] & 0x10){
				size = size * io.dma.bf533_dma_channel[BF533_MDMA_D0][Y_COUNT] * \
					io.dma.bf533_dma_channel[BF533_MDMA_D0][Y_MODIFY];
			}
			/* if 16 width is used */
			if((((io.dma.bf533_dma_channel[BF533_MDMA_D0][DMA_CONFIG] & 0xc) >> 2)) == 0x1){
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
		io.dma.bf533_dma_channel[channel][offset] = value;
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
	ret = io.dma.bf533_dma_channel[channel][offset];
	return ret;
}
static void
dma_write_long (bu32 addr, bu32 value)
{
	int channel = (addr & 0x3c0) >> 6;
	int offset = (addr & 0x3f) >> 2;
	DBG_PRINT("\nIn %s channel=0x%x,offset = %x,value=%x\n",__FUNCTION__,channel,offset,value); 
	io.dma.bf533_dma_channel[channel][offset] = value;
	return;
}
static void
core_int_write_long (bu32 addr, bu32 v)
{
	int offset = addr - CORE_INT_IO_START_ADDR;
	//printf("%x,%x\n",addr,v);
	switch (offset) {
	case 0x104:
		io.core_int.imask = (v | 0x1f) & 0xffff;
		break;
	case 0x108:
		io.core_int.ipend = v;
		break;
	case 0x10c:
		io.core_int.ilat = v;
		//printf("write ilat %x\n",v);
		break;
	case 0x110:
		io.core_int.iprio = v;
		break;
	default:
		if (offset >= 0 && offset < 0x100) {
			io.core_int.evt[offset >> 2] = v;
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
		ret = (io.core_int.imask | 0x1f) & 0xffff;
		break;
	case 0x108:
		ret = io.core_int.ipend;
		break;
	case 0x10c:
		ret = io.core_int.ilat;
		//printf("read ilat %x",ret);
		break;
	case 0x110:
		ret = io.core_int.iprio;
		break;
	default:
		if (offset >= 0 && offset < 0x100) {
			ret = io.core_int.evt[offset >> 2];
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
		io.wd.ctl = v;
		break;
	case 0x4:
		io.wd.cnt = v;
		break;
	case 0x8:
		io.wd.stat = v;
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
		return io.deu.dspid;
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
		ret = io.dpmc.pll_ctl;
		break;
	case 0x4:
		ret = io.dpmc.pll_div;
		break;
	case 0x8:
		ret = io.dpmc.vr_ctl;
		break;
	case 0xc:
		ret = io.dpmc.pll_stat;	/*PLL_LOCKED is set */
		break;
	case 0x10:
		ret = io.dpmc.pll_lockcnt;
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
		io.dpmc.pll_ctl = v;
		break;
	case 0x4:
		io.dpmc.pll_div = v;
		break;
	case 0x8:
		io.dpmc.vr_ctl = v;
		break;
	case 0xc:
		io.dpmc.pll_stat = v;
		break;
	case 0x10:
		io.dpmc.pll_lockcnt = v;
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
		return io.tbuf.ctrl;
	case 4:
		return io.tbuf.stat;

	case 0x100:
	  if (io.tbuf.rsel == 1) {
	        io.tbuf.rsel = 0;
	        if (io.tbuf.rix >= 16) io.tbuf.rix = 0;
		return io.tbuf.sbuf[io.tbuf.rix];
	  } else {
	        io.tbuf.rsel = 1;
		return io.tbuf.dbuf[io.tbuf.rix++];
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
		io.tbuf.ctrl = v;
		break;
	case 4:
		io.tbuf.stat = v;
		break;

	case 0x100:
	  if (io.tbuf.wsel == 1) {
	        io.tbuf.wsel = 0;
	        if (io.tbuf.wix >= 16) io.tbuf.wix = 0;
		io.tbuf.sbuf[io.tbuf.wix] = v;
	  } else {
	        io.tbuf.wsel = 1;
		io.tbuf.dbuf[io.tbuf.wix++] = v;
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
		ret = io.sic.swrst;
		break;
	case 0x4:
		ret = io.sic.syscr;
		break;
	case 0xc:
		ret = io.sic.sic_imask;
		//printf("read ret= %x\n",ret);
		break;
	case 0x20:
		ret = io.sic.sic_isr;
		//printf("read sic_isr 0x%x\n",ret);
		break;
	case 0x24:
		ret = io.sic.sic_iwr;
		break;
	default:
		if (offset >= 0x10 && offset <= 0x18) {
			ret = io.sic.sic_iar[(offset - 0x10) >> 2];
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
		io.sic.sic_iwr = v;
		break;
	case 0xc:
		//printf("write v=%x\n",v);
		io.sic.sic_imask = v;
		break;

	default:
		if (offset >= 0x10 && offset <= 0x18) {
			io.sic.sic_iar[(offset - 0x10) >> 2] = v;
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
		io.l1mem.reg[pos] = v;
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
		ret = io.l1mem.reg[pos];
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
		io.l1dmem.reg[pos];
		break;
	}
}
static void
rtc_write_word (bu32 addr, bu16 v)
{
	int offset = addr - RTC_IO_START_ADDR;
	switch (offset) {
	case 0x4:
		io.rtc.ictl = v;
		return;
	case 0x14:
		io.rtc.pren = v;
		/*set write complete bit to one */
		io.rtc.istat |= 0x8000;
		return;
	case 0x8:
		io.rtc.istat = v;
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
		ret = io.rtc.pren;
		break;
	case 0x8:
		ret = io.rtc.istat;
		/*clear write complete bit */
		io.rtc.istat &= ~0x8000;
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
		io.rtc.stat = v;
		return;
	case 0x10:
		io.rtc.alarm = v;
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
		ret = io.rtc.stat;
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
		ret = io.l1dmem.reg[pos];
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
		io.core_timer.tcntl = v;
		/*not sure core_int is open at this time */
		if (io.core_timer.tcntl & 0x2) {
			io.core_int.imask |= 1 << CORE_TIMER_IRQ;
		}
                /* if autorld is enabled reload tcount */
                if (io.core_timer.tcntl & 0x4) {
                     io.core_timer.tcount = io.core_timer.tperiod / 10;
                }
		break;
	case 0x4:
		io.core_timer.tperiod = v;
		break;
	case 0x8:
		io.core_timer.tscale = v;
		break;
	case 0xc:
		io.core_timer.tcount = v;
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
		ret = io.core_timer.tcntl;
		break;
	case 0x4:
		ret = io.core_timer.tperiod;
		break;
	case 0x8:
		ret = io.core_timer.tscale;
		break;
	case 0xc:
		ret = io.core_timer.tcount;
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
		ret = io.pf.fio_dir;
		break;
	case 0x40:
		ret = io.pf.fio_inen;
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
		io.pf.fio_flag_c = v;
		return;
	case 0x8:
		io.pf.fio_flag_s = v;
		return;
	case 0x14:
		io.pf.fio_maska_c = v;
		return;
	case 0x24:
		io.pf.fio_maskb_c = v;
		return;
	case 0x30:
		io.pf.fio_dir = v;
		return;
        case 0x10:  // Flag Mask Interrupt A Register (set directly)
        case 0x38:  // Flag Source Sensitivity Register
        case 0x40:  // Flag Input Enable Register
               return;

	default:
		IO_ERR;
	}
}

static void bf533_io_reset(){}

void
bf533_mach_init (void * curr_state, machine_config_t * this_mach)
{
	saved_state_type *p_state;

	/*init io  value */
	io.dpmc.pll_div = 0x0005;
	io.dpmc.pll_ctl = 0x1400;
	io.dpmc.pll_lockcnt = 0x0200;
	io.dpmc.pll_stat = 0x00a2;
	io.core_int.ipend = 0x10; /*at the beginning,global int is disabled*/
	io.core_int.imask = 0x1f;
	io.core_int.ilat = 0x0;
	/**/ 
        io.core_timer.tcntl   =  0;
        io.core_timer.tcount  =  BF533_HZ;
        io.core_timer.tperiod =  BF533_HZ;

	io.sic.sic_isr = 0x0;
	io.uart.lcr = 0x0;
	io.uart.dll = 0x0001;
	io.uart.ier = 0x0;
	io.uart.iir = 0x1;
	io.uart.lsr = 0x60;
        io.tbuf.ctrl = 0;
        io.tbuf.stat = 0;
        io.tbuf.rix = 0;
        io.tbuf.rsel = 0;
        io.tbuf.wix = 0;
        io.tbuf.wsel = 0;

	/*init mach */
	if (!this_mach) {
		skyeye_exit (-1);
	}
	this_mach->mach_io_read_byte = bf533_io_read_byte;
	this_mach->mach_io_read_halfword = bf533_io_read_word;
	this_mach->mach_io_read_word = bf533_io_read_long;
	this_mach->mach_io_write_byte = bf533_io_write_byte;
	this_mach->mach_io_write_halfword = bf533_io_write_word;
	this_mach->mach_io_write_word = bf533_io_write_long;
	this_mach->mach_io_do_cycle = bf533_io_do_cycle;
	this_mach->mach_io_reset = bf533_io_reset;
	this_mach->mach_set_intr = bf533_set_int;
	//this_mach->mach_update_intr = bf533_update_int;
	//this_mach->mach_pending_intr = bf533_pending_int;

	p_state = (saved_state_type *)curr_state;
	p_state->disable_int = bf533_disable_int;
	p_state->enable_int = bf533_enable_int;
	p_state->clear_int = bf533_clear_int;
	p_state->sti = bf533_sti;
	p_state->cli = bf533_cli;
	p_state->set_int = bf533_set_int;
}
