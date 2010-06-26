/*
        skyeye_mach_mcf5272.c - implementation of Coldfire 5272 Processor 
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
 * 12/27/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */


#include <stdint.h>
#include <stdio.h>

#include "../common/memory.h"
#include "mcf5272.h"
//#include "tracer.h"
#include "skyeye_uart.h"

typedef struct uart_s{
	uint8_t * umr;
	uint8_t umr1;
	uint8_t umr2;
	uint32_t usr;
	uint32_t ucsr;
	uint8_t ucr;
	uint32_t urb;
	uint32_t utb;
	uint32_t uipcr;
	uint32_t uacr;
	uint32_t uisr;
	uint32_t uimr;
	uint32_t ubg1;
	uint32_t ubg2;
	uint32_t ufpd;
	uint32_t uip;	
	uint32_t uop1;
	uint32_t uop0;
}uart_t;

typedef struct cs_module_s{
	uint16_t csar;
	uint32_t csmr;
	uint16_t cscr;
}cs_module_t;

typedef struct mcf5272_timer_s{
	uint32_t tmr;
	uint32_t trr;
	uint32_t tcap;
	uint32_t tcn;
	uint32_t ter;
}mcf5272_timer_t;

typedef struct mcf5272_dma_s{
	uint32_t ivr;
}mcf5272_dma_t;

typedef struct mcf5272_ethernet_s{
	uint32_t ecr;
	uint32_t eir;
	uint32_t eimr;
	uint32_t rdar;
	uint32_t mscr;
	uint32_t mmfr;
	uint32_t rcr;
	uint32_t tcr;
	uint32_t htur;
	uint32_t htlr;
	uint32_t malr;
	uint32_t maur;
	uint32_t erdsr;
	uint32_t etdst;
	uint32_t emrbr;
}mcf5272_ethernet_t;

typedef struct mcf5272_io_s{
	unsigned int scr;
	cs_module_t cs_module[4];
	unsigned int intbase;
	unsigned int pllcr;
	unsigned int ideconfig1;
	unsigned int ideconfig2;
	unsigned int dmaconfig;
	unsigned int dmaroute;

	unsigned int pacnt; /* Port A Control (r/w) */
	unsigned int paddr; /* Port A Direction (r/w) */
	unsigned int padat; /* Port A Data (r/w) */
	unsigned int pbcnt; /* Port B Control (r/w) */
	unsigned int pbddr; /* Port B Direction (r/w) */
	unsigned int pbdat; /* Port B Data (r/w) */
	unsigned int pcddr; /* Port C Direction (r/w) */
	unsigned int pcdat; /* Port C Data (r/w) */
	unsigned int pdcnt; /* Port D Control (r/w) */

	unsigned int iis2_config;

	unsigned int data_in_ctrl;
	
	unsigned int icr[4];
	unsigned int isr;
	unsigned char pivr;
	unsigned int pmr;

	mcf5272_dma_t dma[4];
	mcf5272_timer_t timer[4];
	uart_t uart[2];

	mcf5272_ethernet_t ether;
}mcf5272_io_t;

static mcf5272_io_t mcf5272_io;

static char cs_module_write(short size, int offset, unsigned int value);
static char cs_module_read(unsigned int *result, short size, int offset);
static char timer_write(short size, int offset, unsigned int value);
static char timer_read(unsigned int *result, short size, int offset);
static char uart_write(short size, int offset, unsigned int value);
static char uart_read(unsigned int *result, short size, int offset);

static char mcf5272_mbar_write(short size, int offset, unsigned int value){
	mcf5272_io_t * io = &mcf5272_io;
	switch(offset){
		case MCFSIM_SCR:
			io->scr = value;
			break;
		case MCFSIM_PIVR:
			io->pivr = value;
			break;
		case 0xa:
			io->pmr = value;
			break;
		case MCFSIM_PBDDR:
                        io->pbddr = value;
                        break;
		case MCFSIM_PBCNT:
                        io->pbcnt = value;
                        break;
		case MCFSIM_PDCNT:
			io->pdcnt = value;
			break;

		case MCF_ECR:
			io->ether.ecr = value;
			break;
		case MCF_EIR:
			io->ether.eir = value;
			break;
		case MCF_EIMR:
			io->ether.eimr = value;
			break;
		case MCF_RDAR:
			io->ether.rdar = value;
			break;
		case MCF_MMFR:
			io->ether.mmfr = value;
			break;
		case MCF_MSCR:
			io->ether.mscr = value;
			break;
		case MCF_RCR:
			io->ether.rcr = value;
			break;
		case MCF_TCR:
			io->ether.tcr = value;
			break;
		case MCF_MALR:
                        io->ether.malr = value;
                        break;
                case MCF_MAUR:
                        io->ether.maur = value;
                        break;
		case MCF_HTUR:
			io->ether.htur = value;
			break;
		case MCF_HTLR:
			io->ether.htlr = value;
			break;
		case MCF_ERDSR:
			io->ether.erdsr = value;
			break;
		case MCF_ETDSR:
			io->ether.etdst = value;
			break;
		case MCF_EMRBR:
			io->ether.emrbr = value;
			break;
                default:
			 if(offset >= 0x20 && offset <= 0x2C){
                                int index = (offset - 0x20) / 4;
				unsigned int old_value = mcf5272_io.icr[index];
				int i;
				/* IPL is changed only when a 1 is written simultaneously to the corresponding PI bit */
				for(i = 31; i > 0; i = i - 4)
					if((value >> i) & 0x1)
                                		old_value = (value & (0xf << (i - 3))) | (old_value & (~(0xf << (i - 3))));
				mcf5272_io.icr[index] = old_value;

                                return 1;
                        }
			if((offset >= 0x200 && offset <= 0x272))
                                return timer_write(size, offset, value);
			if((offset >= 0x100 && offset <= 0x13C) || (offset >= 0x140 && offset <= 0x17C))
                                return uart_write(size, offset, value);


#if 0
			if(offset >= 0x80 && offset <= 0xAE)
				return cs_module_write(size, offset, value);
			if((offset >= 0x140 && offset < 0x154) || (offset >= 0x180 && offset < 0x194))
				return timer_write(size, offset, value);
			if((offset >= 0x1C0 && offset <= 0x1FC) || (offset >= 0x200 && offset <= 0x23C))
				return uart_write(size, offset, value);
#endif
                        fprintf(stderr,"Error adress in %s,offset=0x%x,pc=0x%x\n",__FUNCTION__,offset, memory_core.pc);
			skyeye_exit(-1);
                        return 0;
        }
}
static char mcf5272_mbar2_write(short size, int offset, unsigned int value){
	switch(offset){
#if 0
		case 0x4:
			mcf5272_io.gpio_out = value;
			break;
		case 0x8:
			mcf5272_io.gpio_en = value;
			break;
		case 0xC:
			mcf5272_io.gpio_func = value;
			break;
		case 0x14:
			mcf5272_io.iis2_config = value;
			break;
		case 0x30:
			mcf5272_io.data_in_ctrl = value;
			break;
		case 0xB4:
                        mcf5272_io.gpio1_out = value;
                        break;
		case 0xB8:
			mcf5272_io.gpio1_en = value;
			break;
		case 0xBC:
			mcf5272_io.gpio1_func = value;
			break;
		case 0x16b:/* INT Base*/
			mcf5272_io.intbase = value;
			break;
		case 0x180:
			mcf5272_io.pllcr = value;
			break;
		case 0x18C:
			mcf5272_io.ideconfig1 = value;
			break;
		case 0x190:
			mcf5272_io.ideconfig2 = value;
			break;
		case 0x188:
			mcf5272_io.dmaroute = value;
			break;
		case 0x9F:
			mcf5272_io.dmaconfig = value;
			break;
		case 0x74:
			printf("Warning:register is not implemented\n");
			break;
#endif
		default:
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
			return 0;
	}
	return 1;
}
static char mcf5272_mbar_read(unsigned int *result, short size, int offset){
	mcf5272_io_t * io = &mcf5272_io;
	switch(offset){
		case MCFSIM_ISR:
			*result = io->isr;
			break;
		case MCFSIM_PBDDR:
			*result = io->pbddr;
			break;
		case MCFSIM_PBCNT:
			*result = io->pbcnt;
			break;
		 case MCFSIM_PDCNT:
                        *result = io->pdcnt;
                        break;

		case MCF_MALR:
			*result = io->ether.malr;
			break;
		case MCF_MAUR:
			*result = io->ether.maur;
			break;
		default:
			if((offset >= 0x100 && offset <= 0x13C) || (offset >= 0x140 && offset <= 0x17C))
                                return uart_read(result, size, offset);
			if((offset >= 0x200 && offset < 0x270))
				return timer_read(result, size, offset);
			if(offset >= 0x20 && offset <= 0x2C){
                                int index = offset - 0x20;
                                return mcf5272_io.icr[index/4];
                        }

                        fprintf(stderr,"Error adress in %s,offset=%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
			return 0;
	}
	return 1;
}

static char mcf5272_mbar2_read(unsigned int *result, short size, int offset){
	 switch(offset){
/*
		case 0x4:
			*result = mcf5272_io.gpio_out;
			break;
		case 0x8:
			*result = mcf5272_io.gpio_en;
			break;
		case 0xc:
			*result = mcf5272_io.gpio_func;
			break;
*/
		/* GPIO1 read */
#if 0
		case 0xB4:
                        *result = mcf5272_io.gpio1_out;
                        break;
		case 0xB8:
                        *result = mcf5272_io.gpio1_en;
                        break;
		case 0xBC:
			*result = mcf5272_io.gpio1_func;
			break;
		case 0x180:
			*result = mcf5272_io.pllcr;
			return 1;
#endif
                default:
                        fprintf(stderr,"Error adress in %s,offset=%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
                        return 0;
        }
	return 1;
}

/* Interrupts go from 0 -> 9 on the 5307, with the 7 external
 *  autovector only interrupts defined in the autovector interrupt */

/* ICR:
 *	+----+----+----+----+----+----+----+----+
 * 	| av | xx | xx |  int level   | int pri |
 *	+----+----+----+----+----+----+----+----+ 
 * av -- autovectored, 1=yes 
 * int level -- interrupt level, 0 -> 7
 * int pri -- interrupt priority 11(high) -> 00 (low) */
#define ICR_LEVEL(x) 	((mcf5272_io.icr[(31 - x) / 8] >> (4 * (x % 8))) & 0x7) 
//#define ICR_PRI(icr) 	((icr) & 0x02)
//#define ICR_AVEC(icr)	((icr) & 0x80)

static unsigned int mcf5272_iack_func(unsigned int interrupt_level){

	unsigned long vector=0;
        int x;
	mcf5272_io_t * io = &mcf5272_io;
        //TRACE("called for interrupt_level=%d\n", interrupt_level);
        /* Find the _pending_ interrupt with level == interrupt_level */
	/* INT1_IRQ has highest priority and SWTO_IRQ is lowest priority */
        for(x = INT1_IRQ; x > SWTO_IRQ; x--) {
                int icr_avec, icr_level, icr_pri;
		if(!((io->isr >> x) & 0x1)){
                        continue;
                }
		icr_level = ICR_LEVEL(x);
		
                if(icr_level != interrupt_level) continue;
		/* see p163 of user manual of 5272 */
		vector = (32 - x) | (io->pivr & 0xe0);	
		/*
		if(x != 24)
			printf("DBG: in %s, vector=%d\n", __FUNCTION__, vector);
		*/
		return vector;
        }

	//ERR("Inside iack_func, but no interrupt is waiting with level %d\n", interrupt_level);
	fprintf(stderr, "Inside iack_func, but no interrupt is waiting with level %d\n", interrupt_level);
	return 0;
}

static void interrupt_assert(short number){
	mcf5272_io_t * io = &mcf5272_io;
	int level = ICR_LEVEL(number);;
	/*
	if(number != 24)
		printf("DBG:Posting interrupt Number=%d, Level=%d\n", number, level);
	*/
        //TRACE("Posting interrupt Number=%d, Vector=%d\n", number, vector);
        /* Post an interrupt */
	exception_post(level, &mcf5272_iack_func);
	io->isr |= 0x1 << number;
	return;
}

static void interrupt_withdraw(short number){
	mcf5272_io_t * io = &mcf5272_io;
	int icr_level = ICR_LEVEL(number);

        io->isr &= ~(0x1 << number);
	/*
	if(number != 24)
		printf("DBG:in %s Number=%d, Level=%d\n", __FUNCTION__, number, icr_level);
	*/
	exception_withdraw(icr_level);
		//TRACE("Done.\n");
	return;
}

void mcf5272_io_do_cycle(){
	int i;
	for(i = 0; i < TIMER_NUM; i++){
		//mcf5272_timer_t * timer = &mcf5272_io.timer[i];
		/* check if timer is enbaled */
		if(mcf5272_io.timer[i].tmr & 0x1){
			mcf5272_io.timer[i].tcn++;
			/* check if reference interrupt is enabled */
			if((mcf5272_io.timer[i].tcn == mcf5272_io.timer[i].trr) && (mcf5272_io.timer[i].tmr & 0x10))
			{
			
				//printf("DBG:tcn=0x%x,trr=0x%x,i=%d\n", mcf5272_io.timer[i].tcn, mcf5272_io.timer[i].trr, i);
				/* set REF bit in TER */
				mcf5272_io.timer[i].ter |= 0x2;
				interrupt_assert(TIMER0_IRQ - i);
	
				/* check if in restart mode */
				if(mcf5272_io.timer[i].tmr & 0x8)
					mcf5272_io.timer[i].tcn = 0x0;
			}
		}
	}

	if(1){
                /* UART FIFO full interrupt enabled */
                struct timeval tv;
                unsigned char buf;
                tv.tv_sec = 0;
                tv.tv_usec = 0;

                if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0){
                        mcf5272_io.uart[0].urb = buf;
                        /* set RXRDY bit in UISR */
                        mcf5272_io.uart[0].uisr |= 0x2;
                }
		/* set TXRDY bit in UISR */
                mcf5272_io.uart[0].uisr |= 0x1;

	}
	
	/* check if UART Transmitter ready interrupt enabled */
	if(!(mcf5272_io.isr & UART1_IRQ)){
		if((mcf5272_io.uart[0].uimr & mcf5272_io.uart[0].uisr))
			interrupt_assert(UART1_IRQ);
	}
}

static char cs_module_read(unsigned int *result, short size, int offset){
	int index = offset - 0x80;
	int reg_no;
	if(index >= 0 && index <=8){
		reg_no = index / 4;
		index = 0;
	}
	if(index >= 0xc && index <= 0x16){
                reg_no = (index - 0xc)/ 4;
                index = 1;
        }
	if(index >= 0x18 && index <= 0x22){
		reg_no = (index - 0x18)/4;
		index = 2;
	}
	if(index >= 0x24 && index <= 0x2e){
		reg_no = (index - 0x24);
		index = 3;
	}
	switch(reg_no){
/*
		case CSAR:
			*result = mcf5272_io.cs_module[index].csar;
			return 1;
		case CSMR:
			*result = mcf5272_io.cs_module[index].csmr;
			return 1;
		case CSCR:
			*result = mcf5272_io.cs_module[index].cscr;
			return 1;
*/
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
}
static char cs_module_write(short size, int offset, unsigned int value){
	int index = offset - 0x80;
	int reg_no;
	if(index >= 0 && index <=8){
		reg_no = index / 4;
		index = 0;
	}
	if(index >= 0xc && index <= 0x16){
                reg_no = (index - 0xc)/ 4;
                index = 1;
        }
	if(index >= 0x18 && index <= 0x22){
		reg_no = (index - 0x18)/4;
		index = 2;
	}
	if(index >= 0x24 && index <= 0x2e){
		reg_no = (index - 0x24);
		index = 3;
	}
	switch(reg_no){
/*
		case CSAR:
			mcf5272_io.cs_module[index].csar = value;
			return 1;
		case CSMR:
			mcf5272_io.cs_module[index].csmr = value;
			return 1;
		case CSCR:
			mcf5272_io.cs_module[index].cscr = value;
			return 1;
*/
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
}
static char timer_read(unsigned int *result, short size, int offset){
	int index = (offset - 0x200) / 0x20;
        offset = offset % 0x20;

	//printf("DBG: in %s, offset = 0x%x", __FUNCTION__, offset);
	switch(offset){
		case 0x0:
			*result = mcf5272_io.timer[index].tmr;
			return 1;
		case 0x4:
			*result = mcf5272_io.timer[index].trr;
			return 1;
		case 0x8:
			*result = mcf5272_io.timer[index].tcap;
			return 1;
		case 0xc:
			*result = mcf5272_io.timer[index].tcn;
			return 1;
		case 0x11:
			/* write one to clear the corresponding bit */
			*result = mcf5272_io.timer[index].ter;
			/* clear the corresponding bit in ipr */
			//mcf5272_io.ipr &=  ~(0x1 << 9);
			interrupt_withdraw(TIMER0_IRQ - index);
			return 1;
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}

}
static char timer_write(short size, int offset, unsigned int value){
	int index = (offset - 0x200) / 0x20;
        offset = offset % 0x20;

	switch(offset){
		case 0x0:
			mcf5272_io.timer[index].tmr = value;
			return 1;
		case 0x4:
			mcf5272_io.timer[index].trr = value;
			return 1;
		case 0x8:
			mcf5272_io.timer[index].tcap = value;
			return 1;
		case MCFTIMER_TCN:
			mcf5272_io.timer[index].tcn = value;
			return 1;
		case MCFTIMER_TER:
			/* write one to clear the corresponding bit */
			mcf5272_io.timer[index].ter &= ~(value & 0x3);
			/* clear the corresponding bit in ipr */
			//mcf5272_io.ipr &=  ~(0x1 << 9);
			interrupt_withdraw(TIMER0_IRQ - index);
			return 1;
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        //skyeye_exit(-1);
                        return 0;
	}

}
static char uart_read(unsigned int *result, short size, int offset){
	int index;
        if(offset >= 0x100 && offset <= 0x13C){
                index = 0;
                offset = offset - 0x100;
        }
        if(offset >= 0x140 && offset <= 0x17C){
                index = 1;
                offset = offset - 0x140;
        }
	extern struct _memory_core memory_core;
	/*
	if(offset != 0x4)
                printf("DBG: in %s, offset = 0x%x,PC=0x%x\n", __FUNCTION__, offset, memory_core.pc);
	*/
        switch(offset){
		case 0x0:
			*result = mcf5272_io.uart[index].umr1;
			break;
		case 0x4:
			*result = mcf5272_io.uart[index].usr;
			break;
		case 0xC:
			*result = mcf5272_io.uart[index].urb;
			/* set FFULL bit in USR is zero */
			mcf5272_io.uart[index].usr &= ~0x2;
			/* set RxRDY bit in USR is zero */
			mcf5272_io.uart[index].usr &= ~0x1;
			/* check RXIRQ bit in UMR1 */
			//if(mcf5272_io.uart[index].umr1 & 0x40)
			mcf5272_io.uart[index].uisr &= ~0x2;
			break;	
		case 0x10:
			*result = mcf5272_io.uart[index].uipcr;
			break;
		case 0x14:
			*result = mcf5272_io.uart[index].uisr;	
			mcf5272_io.uart[index].uisr = 0x0;
			interrupt_withdraw(UART1_IRQ - index);
			break;
		case 0x18:
			*result = mcf5272_io.uart[index].ubg1;
			break;
		case 0x1C:
			*result = mcf5272_io.uart[index].ubg2;
			break;
		case 0x34:
			*result = mcf5272_io.uart[index].uip;
			break;
		default:
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
	return 1;
}
static char uart_write(short size, int offset, unsigned int value){
	int index, cmd;
	char tmp;
	if(offset >= 0x100 && offset <= 0x13C){
		index = 0;
		offset = offset - 0x100;
	}
	if(offset >= 0x140 && offset <= 0x17C){
		index = 1;
		offset = offset - 0x140;
	}
	/*
	if(offset != 0xc)
		printf("DBG: in %s, offset = 0x%x, value=0x%x\n", __FUNCTION__, offset, value);
	*/
	switch(offset){
		case 0x0:
			mcf5272_io.uart[index].umr1 = value;
			break;
		case 0x4:
			mcf5272_io.uart[index].ucsr = value;
			break;
		case 0x8:
			mcf5272_io.uart[index].ucr = value;
			if((value & 0x3) == 0x1) /* Receiver enable */
				;

			if(((value >> 2) & 0x3) == 0x1) /* Transmitter enable */
				/* set TXRDY bit and TXEMP bit in usr */
	                        mcf5272_io.uart[index].usr |= 0xc;

			cmd = (value >> 4) & 0x7;
			if (cmd == 0x4) /* Reset error status */
				mcf5272_io.uart[index].usr &= 0xf;
			break;
		case 0xc:
			mcf5272_io.uart[index].utb = value;
			tmp = value & 0xff;
			skyeye_uart_write(-1, &tmp, 1, NULL);
			/* set TXRDY bit and TXEMP bit in usr */
			mcf5272_io.uart[index].usr |= 0xc;
			/* set TXRDY bit in usr */
			mcf5272_io.uart[index].uisr |= 0x1;
			break;
		case 0x10:
			mcf5272_io.uart[index].uacr = value;
			break;
		case 0x14:
			mcf5272_io.uart[index].uimr = value;
			break;
		case 0x18:
			mcf5272_io.uart[index].ubg1 = value;
			break;
		case 0x1C:
			mcf5272_io.uart[index].ubg2 = value;
			break;
		case 0x30:
			mcf5272_io.uart[index].ufpd = value;
			break;
		case 0x38:
			mcf5272_io.uart[index].uop1 = value;
			break;
		case 0x3C:
			mcf5272_io.uart[index].uop0 = value;
			break;
		default:
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
	return 1;
}
void mcf5272_mach_init(void * state, machine_config_t * mach){
	struct _memory_core * core = (struct _memory_core *)state;
	machine_config_t * this_mach = mach;
	core->mbar_read = mcf5272_mbar_read;
	core->mbar_write = mcf5272_mbar_write;
	core->mbar2_read = mcf5272_mbar2_read;
	core->mbar2_write = mcf5272_mbar2_write;

	mcf5272_io.uart[0].usr |= 0xc;

	/* init io  value */
	/* fixme, workaround for uClinux */
	mcf5272_io.pivr = 0x40;
	/* init mach */
	if (!this_mach) {
		exit (-1);
	}
        this_mach->mach_io_do_cycle = mcf5272_io_do_cycle;
#if 0
	this_mach->mach_io_read_byte = mcf5272_io_read_byte;
        this_mach->mach_io_read_halfword = mcf5272_io_read_halfword;
        this_mach->mach_io_read_word = mcf5272_io_read_word;
        this_mach->mach_io_write_byte = mcf5272_io_write_byte;
        this_mach->mach_io_write_halfword = mcf5272_io_write_halfword;
        this_mach->mach_io_write_word = mcf5272_io_write_word;
        this_mach->mach_io_do_cycle = mcf5272_io_do_cycle;
        this_mach->mach_set_intr = mcf5272_set_int;
#endif
}
