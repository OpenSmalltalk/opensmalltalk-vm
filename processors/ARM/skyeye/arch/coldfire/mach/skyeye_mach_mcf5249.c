/*
        skyeye_mach_mcf5249.c - implementation of Coldfire 5249 Processor 
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
#include "mcf5249.h"
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
	uint32_t uip;	
	uint32_t uivr;
	uint32_t uop1;
	uint32_t uop0;
}uart_t;

struct interrupt_ctl_s{
	uint32_t icr[3]; /* tweleve icr */
	uint32_t imr;
	uint32_t ipr;
}interrupt_ctl_t;

enum{
	UMR = 0,
	USR,
	UCSR = 1,
	UCR = 2,
	URB = 3,
	UTB = 3,
	UIPCR = 4,
	UACR = 4,
	UISR = 5,
	UIMR = 5,
	UBG1 = 6,
	UBG2 = 6,
	UIVR = 12,
	UIP = 13,
	UOP1 = 14,
	UOP0 = 15
};
uint32_t uart[2][0x3c];

typedef struct cs_module_s{
	uint16_t csar;
	uint32_t csmr;
	uint16_t cscr;
}cs_module_t;

typedef struct mcf5249_timer_s{
	uint32_t tmr;
	uint32_t trr;
	uint32_t tcr;
	uint32_t tcn;
	uint32_t ter;
}mcf5249_timer_t;

typedef struct mcf5249_dma_s{
	uint32_t ivr;
}mcf5249_dma_t;

typedef struct mcf5249_io_s{
	cs_module_t cs_module[4];
	unsigned int intbase;
	unsigned int pllcr;
	unsigned int ideconfig1;
	unsigned int ideconfig2;
	unsigned int dmaconfig;
	unsigned int dmaroute;

	unsigned int gpio_out;
	unsigned int gpio_en;
	unsigned int gpio_func;
	unsigned int gpio1_out;
	unsigned int gpio1_en;
	unsigned int gpio1_func;

	unsigned int iis2_config;

	unsigned int data_in_ctrl;
	
	unsigned char icr[12];
	unsigned int ipr;
	unsigned int imr;
	mcf5249_dma_t dma[4];
	mcf5249_timer_t timer[2];
	uart_t uart[2];
}mcf5249_io_t;

static mcf5249_io_t mcf5249_io;

static char cs_module_write(short size, int offset, unsigned int value);
static char cs_module_read(unsigned int *result, short size, int offset);
static char timer_write(short size, int offset, unsigned int value);
static char timer_read(unsigned int *result, short size, int offset);
static char uart_write(short size, int offset, unsigned int value);
static char uart_read(unsigned int *result, short size, int offset);

static uint32_t uart_read_word(uint32_t offset, int uart_id){
	return uart[uart_id][offset];
}
static uint32_t uart_write_word(uint32_t offset, uint32_t value, int uart_id){
	uart[uart_id][offset] = value;
	return 0;
}
/*
static uint32_t timer_read_word(uint32_t offset, int timer_id){
	return timer[uart_id][offset];
}
static uint32_t timer_write_word(uint32_t offset, uint32_t value, int timer_id){
	timer[timer_id][offset] = value;
	return 0;
}*/
static char mcf5249_mbar_write(short size, int offset, unsigned int value){
	switch(offset){
		case 0x44:
			mcf5249_io.imr = value;
			return 1;
		case 0x84:
			mcf5249_io.cs_module[0].csmr = value;
			return 1;
		case 0x8c:
			mcf5249_io.cs_module[1].csmr = value;
			break;
		case 0x314:
			mcf5249_io.dma[0].ivr = value;
			break;
		
                default:
			if(offset >= 0x80 && offset <= 0xAE)
				return cs_module_write(size, offset, value);
			if(offset >= 0x4C && offset < 0x58){
				int index = offset - 0x4C;
				mcf5249_io.icr[index] = value;
				return 1;
			}
			if((offset >= 0x140 && offset < 0x154) || (offset >= 0x180 && offset < 0x194))
				return timer_write(size, offset, value);
			if((offset >= 0x1C0 && offset <= 0x1FC) || (offset >= 0x200 && offset <= 0x23C))
				return uart_write(size, offset, value);
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
                        return 0;
        }
}
static char mcf5249_mbar2_write(short size, int offset, unsigned int value){
	switch(offset){
		case 0x4:
			mcf5249_io.gpio_out = value;
			break;
		case 0x8:
			mcf5249_io.gpio_en = value;
			break;
		case 0xC:
			mcf5249_io.gpio_func = value;
			break;
		case 0x14:
			mcf5249_io.iis2_config = value;
			break;
		case 0x30:
			mcf5249_io.data_in_ctrl = value;
			break;
		case 0xB4:
                        mcf5249_io.gpio1_out = value;
                        break;
		case 0xB8:
			mcf5249_io.gpio1_en = value;
			break;
		case 0xBC:
			mcf5249_io.gpio1_func = value;
			break;
		case 0x16b:/* INT Base*/
			mcf5249_io.intbase = value;
			break;
		case 0x180:
			mcf5249_io.pllcr = value;
			break;
		case 0x18C:
			mcf5249_io.ideconfig1 = value;
			break;
		case 0x190:
			mcf5249_io.ideconfig2 = value;
			break;
		case 0x188:
			mcf5249_io.dmaroute = value;
			break;
		case 0x9F:
			mcf5249_io.dmaconfig = value;
			break;
		case 0x74:
			printf("Warning:register is not implemented\n");
			break;
		default:
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
			return 0;
	}
	return 1;
}
static char mcf5249_mbar_read(unsigned int *result, short size, int offset){
	switch(offset){
		case 0x40:
			*result = mcf5249_io.ipr;
			break;
		case 0x44:
			*result = mcf5249_io.imr;
			break;
		default:
			 if((offset >= 0x140 && offset < 0x154) || (offset >= 0x180 && offset < 0x194))

                                return timer_read(result, size, offset);

			if((offset >= 0x1C0 && offset <= 0x1FC) || (offset >= 0x200 && offset <= 0x23C))
                                return uart_read(result, size, offset);

                        fprintf(stderr,"Error adress in %s,offset=%x\n",__FUNCTION__,offset);
			skyeye_exit(-1);
			return 0;
	}
	return 1;
}

static char mcf5249_mbar2_read(unsigned int *result, short size, int offset){
	 switch(offset){
		case 0x4:
			*result = mcf5249_io.gpio_out;
			break;
		case 0x8:
			*result = mcf5249_io.gpio_en;
			break;
		case 0xc:
			*result = mcf5249_io.gpio_func;
			break;
		/* GPIO1 read */
		case 0xB4:
                        *result = mcf5249_io.gpio1_out;
                        break;
		case 0xB8:
                        *result = mcf5249_io.gpio1_en;
                        break;
		case 0xBC:
			*result = mcf5249_io.gpio1_func;
			break;
		case 0x180:
			*result = mcf5249_io.pllcr;
			return 1;
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
#define ICR_LEVEL(icr) 	(((icr) & 0x1c) >> 2)
#define ICR_PRI(icr) 	((icr) & 0x02)
#define ICR_AVEC(icr)	((icr) & 0x80)

static unsigned int mcf5249_iack_func(unsigned int interrupt_level){

	unsigned long vector=0;
        int x;
	mcf5249_io_t * io = &mcf5249_io;
        //TRACE("called for interrupt_level=%d\n", interrupt_level);
        /* Find the _pending_ interrupt with level == interrupt_level */
        for(x = 1; x < 18; x++) {
                int icr_avec, icr_level, icr_pri;
		if(!((io->ipr >> x) & 0x1)){
			//TRACE("sim input number %d is not pending.\n", x);
                        continue;
                }
		/* icr_avec will be non-zero if it's autovectored, but
		 *  it will be different for each interrupt level */
		if(x >= 8) {
			icr_avec = ICR_AVEC(io->icr[x-8]);
			icr_level = ICR_LEVEL(io->icr[x-8]);
			icr_pri = ICR_PRI(io->icr[x-8]);
			/* TRACE(" %d: ICR = 0x%02x (IL=%d,pri=%d,avec=%d)\n", x, 
				io->icr[x-8], icr_level, icr_pri, icr_avec?1:0);
			*/
			/*
			printf("DBG:%d: ICR = 0x%02x (IL=%d,pri=%d,avec=%d)\n", x,
                                io->icr[x-8], icr_level, icr_pri, icr_avec?1:0);
			*/
		} else {
			/* 0 - interrupt source returns vector 
			 * 1 - autovector */
			//icr_avec = (io->avr & (0x1<<x) );
			icr_level=x;
			icr_pri=0;
			
			/* TRACE(" %d: external int (lev=%d,pri=%d,avec=%d)\n", x, 
				icr_level, icr_pri, icr_avec?1:0);
			*/
			/* FIXME: how the heck do we use the IRQPAR? */
		}
		
                if(icr_level != interrupt_level) continue;

                if(icr_avec) {
                        //TRACE("   This interrupt is autovectored, using autovector.\n");
                        //TRACE("   vector = 24 + interrupt level(%d) = %d\n",
                                //        icr_level, 24 + icr_level);
                        vector = 24 + icr_level;
                } else {
			/* check if uart0 interrupt */
			if(icr_level == ICR_LEVEL(io->icr[4]))
				vector = mcf5249_io.uart[0].uivr;
			else
				fprintf(stderr, "Not implement for non autovector in %s\n", __FUNCTION__);
                        //TRACE("   Polling the device to get the vector number...\n");
                        //vector = interrupt_acknowledge[x];
                        //TRACE("   vector = %d\n", vector);
			//ERR("Not implement for non autovector");
                }
		 return vector;
        }

	//ERR("Inside iack_func, but no interrupt is waiting with level %d\n", interrupt_level);
	fprintf(stderr, "Inside iack_func, but no interrupt is waiting with level %d\n", interrupt_level);
	return 0;
}

static void interrupt_assert(short number){
	mcf5249_io_t * io = &mcf5249_io;
	int level = ICR_LEVEL(io->icr[number - 8]);
	int mask = 0x1 << number;

        //TRACE("Posting interrupt Number=%d, Vector=%d\n", number, vector);
        /* Post an interrupt */
        if(!(io->imr & mask )) {
		/* check if exist pending interrupt */
                if(io->ipr & mask) {
                        //TRACE("Already pending, not playing with registers further.\n");
                        return;
                }
		exception_post(level, &mcf5249_iack_func);
		io->ipr |= mask;
		return;
	}
}

static void interrupt_withdraw(short number){
	short mask = (0x1 << number);
	mcf5249_io_t * io = &mcf5249_io;
	int icr_level = ICR_LEVEL(io->icr[number - 8]);
	if(!(io->imr & mask )) {
                //TRACE("Withdrawing interrupt Number=%d\n", number);

                if(! (io->ipr & mask) ) {
                        /* This interrupt isn't pending, there's no
                         * need to withdraw it further */
                        //TRACE("Interrupt wasn't pending, no need to withdraw.\n");
                        return;
                }
                /* Set us not pending */
                io->ipr &= ~mask;
		exception_withdraw(icr_level);
		//TRACE("Done.\n");
                return;
        }
//      TRACE("NOT Withdrawn, the interrupt is unmasked in the IMR\n");
        return;
}

void mcf5249_io_do_cycle(){
	int i;
	for(i = 0; i < 2; i++){
		//mcf5249_timer_t * timer = &mcf5249_io.timer[i];
		/* check if timer is enbaled */
		if(mcf5249_io.timer[i].tmr & 0x1){
			mcf5249_io.timer[i].tcn++;
			/* check if reference interrupt is enabled */
			if((mcf5249_io.timer[i].tcn == mcf5249_io.timer[i].trr) && (mcf5249_io.timer[i].tmr & 0x10))
			{
			
				//printf("KSDBG:tcn=0x%x,trr=0x%x\n", mcf5249_io.timer[i].tcn, mcf5249_io.timer[i].trr);
				/* set REF bit in TER */
				mcf5249_io.timer[i].ter |= 0x2;
				interrupt_assert(9 + i);
	
				/* check if in restart mode */
				if(mcf5249_io.timer[i].tmr & 0x8)
					mcf5249_io.timer[i].tcn = 0x0;
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
                        mcf5249_io.uart[0].urb = buf;
                        /* set RXRDY bit in UISR */
                        mcf5249_io.uart[0].uisr |= 0x2;
                }
		/* set TXRDY bit in UISR */
                mcf5249_io.uart[0].uisr |= 0x1;

	}
	
	/* check if UART Transmitter ready interrupt enabled */
	if(!(mcf5249_io.ipr & 0xc)){
		if((mcf5249_io.uart[0].uimr & mcf5249_io.uart[0].uisr))
			interrupt_assert(0xc);
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
		case CSAR:
			*result = mcf5249_io.cs_module[index].csar;
			return 1;
		case CSMR:
			*result = mcf5249_io.cs_module[index].csmr;
			return 1;
		case CSCR:
			*result = mcf5249_io.cs_module[index].cscr;
			return 1;
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
		case CSAR:
			mcf5249_io.cs_module[index].csar = value;
			return 1;
		case CSMR:
			mcf5249_io.cs_module[index].csmr = value;
			return 1;
		case CSCR:
			mcf5249_io.cs_module[index].cscr = value;
			return 1;
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
}
static char timer_read(unsigned int *result, short size, int offset){
	int index = (offset - 0x140) / 0x40;
	offset = offset - 0x140 - (index * 0x40);
	//printf("DBG: in %s, offset = 0x%x, value=0x%x\n", __FUNCTION__, offset, value);
	switch(offset){
		case 0x0:
			*result = mcf5249_io.timer[index].tmr;
			return 1;
		case 0x4:
			*result = mcf5249_io.timer[index].trr;
			return 1;
		case 0x8:
			*result = mcf5249_io.timer[index].tcr;
			return 1;
		case 0xc:
			*result = mcf5249_io.timer[index].tcn;
			return 1;
		case 0x11:
			/* write one to clear the corresponding bit */
			*result = mcf5249_io.timer[index].ter;
			/* clear the corresponding bit in ipr */
			//mcf5249_io.ipr &=  ~(0x1 << 9);
			interrupt_withdraw(index + 9);
			return 1;
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}

}
static char timer_write(short size, int offset, unsigned int value){
	int index = (offset - 0x140) / 0x40;
	offset = offset - 0x140 - (index * 0x40);
	//printf("DBG: in %s, offset = 0x%x, value=0x%x\n", __FUNCTION__, offset, value);
	switch(offset){
		case 0x0:
			mcf5249_io.timer[index].tmr = value;
			return 1;
		case 0x4:
			mcf5249_io.timer[index].trr = value;
			return 1;
		case 0x8:
			mcf5249_io.timer[index].tcr = value;
			return 1;
		case 0xc:
			mcf5249_io.timer[index].tcn = value;
			return 1;
		case 0x11:
			/* write one to clear the corresponding bit */
			mcf5249_io.timer[index].ter &= ~(value & 0x3);
			/* clear the corresponding bit in ipr */
			//mcf5249_io.ipr &=  ~(0x1 << 9);
			interrupt_withdraw(index + 9);
			return 1;
		default:
			fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}

}
static char uart_read(unsigned int *result, short size, int offset){
	int index;
        if(offset >= 0x1C0 && offset <= 0x1FC){
                index = 0;
                offset = offset - 0x1C0;
        }
        if(offset >= 0x200 && offset <= 0x23C){
                index = 1;
                offset = offset - 0x200;
        }
	/*
	extern struct _memory_core memory_core;
	if(offset != 0x4)
                printf("DBG: in %s, offset = 0x%x,PC=0x%x\n", __FUNCTION__, offset, memory_core.pc);
	*/
        switch(offset){
		case 0x0:
			*result = mcf5249_io.uart[index].umr1;
			break;
		case 0x4:
			*result = mcf5249_io.uart[index].usr;
			break;
		case 0xC:
			*result = mcf5249_io.uart[index].urb;
			/* set FFULL bit in USR is zero */
			mcf5249_io.uart[index].usr &= ~0x2;
			/* set RxRDY bit in USR is zero */
			mcf5249_io.uart[index].usr &= ~0x1;
			/* check RXIRQ bit in UMR1 */
			//if(mcf5249_io.uart[index].umr1 & 0x40)
			mcf5249_io.uart[index].uisr &= ~0x2;
			break;	
		case 0x10:
			*result = mcf5249_io.uart[index].uipcr;
			break;
		case 0x14:
			*result = mcf5249_io.uart[index].uisr;	
			mcf5249_io.uart[index].uisr = 0x0;
			interrupt_withdraw(12);
			break;
		case 0x18:
			*result = mcf5249_io.uart[index].ubg1;
			break;
		case 0x1C:
			*result = mcf5249_io.uart[index].ubg2;
			break;
		case 0x30:
			*result = mcf5249_io.uart[index].uivr;
			break;
		case 0x34:
			*result = mcf5249_io.uart[index].uip;
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
	if(offset >= 0x1C0 && offset <= 0x1FC){
		index = 0;
		offset = offset - 0x1C0;
	}
	if(offset >= 0x200 && offset <= 0x23C){
		index = 1;
		offset = offset - 0x200;
	}
	/*
	if(offset != 0xc)
		printf("DBG: in %s, offset = 0x%x, value=0x%x\n", __FUNCTION__, offset, value);
	*/
	switch(offset){
		case 0x0:
			mcf5249_io.uart[index].umr1 = value;
			break;
		case 0x4:
			mcf5249_io.uart[index].ucsr = value;
			break;
		case 0x8:
			mcf5249_io.uart[index].ucr = value;
			if((value & 0x3) == 0x1) /* Receiver enable */
				;

			if(((value >> 2) & 0x3) == 0x1) /* Transmitter enable */
				/* set TXRDY bit and TXEMP bit in usr */
	                        mcf5249_io.uart[index].usr |= 0xc;

			cmd = (value >> 4) & 0x7;
			if (cmd == 0x4) /* Reset error status */
				mcf5249_io.uart[index].usr &= 0xf;
			break;
		case 0xc:
			mcf5249_io.uart[index].utb = value;
			tmp = value & 0xff;
			skyeye_uart_write(-1, &tmp, 1, NULL);
			/* set TXRDY bit and TXEMP bit in usr */
			mcf5249_io.uart[index].usr |= 0xc;
			/* set TXRDY bit in usr */
			mcf5249_io.uart[index].uisr |= 0x1;
			break;
		case 0x10:
			mcf5249_io.uart[index].uacr = value;
			break;
		case 0x14:
			mcf5249_io.uart[index].uimr = value;
			break;
		case 0x18:
			mcf5249_io.uart[index].ubg1 = value;
			break;
		case 0x1C:
			mcf5249_io.uart[index].ubg2 = value;
			break;
		case 0x30:
			mcf5249_io.uart[index].uivr = value;
			break;
		case 0x38:
			mcf5249_io.uart[index].uop1 = value;
			break;
		case 0x3C:
			mcf5249_io.uart[index].uop0 = value;
			break;
		default:
                        fprintf(stderr,"Error adress in %s,offset=0x%x\n",__FUNCTION__,offset);
                        skyeye_exit(-1);
                        return 0;
	}
	return 1;
}
void mcf5249_mach_init(void * state, machine_config_t * mach){
	struct _memory_core * core = (struct _memory_core *)state;
	machine_config_t * this_mach = mach;
	core->mbar_read = mcf5249_mbar_read;
	core->mbar_write = mcf5249_mbar_write;
	core->mbar2_read = mcf5249_mbar2_read;
	core->mbar2_write = mcf5249_mbar2_write;
	/* init io  value */

	/* init mach */
	if (!this_mach) {
		exit (-1);
	}
        this_mach->mach_io_do_cycle = mcf5249_io_do_cycle;
/*
	this_mach->mach_io_read_byte = mcf5249_io_read_byte;
        this_mach->mach_io_read_halfword = mcf5249_io_read_halfword;
        this_mach->mach_io_read_word = mcf5249_io_read_word;
        this_mach->mach_io_write_byte = mcf5249_io_write_byte;
        this_mach->mach_io_write_halfword = mcf5249_io_write_halfword;
        this_mach->mach_io_write_word = mcf5249_io_write_word;
        this_mach->mach_io_do_cycle = mcf5249_io_do_cycle;
        this_mach->mach_set_intr = mcf5249_set_int;
*/

}
