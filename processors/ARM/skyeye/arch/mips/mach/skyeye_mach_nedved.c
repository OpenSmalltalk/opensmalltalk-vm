#include "skyeye_config.h"
#include "../common/types.h"
#include "../common/inttypes.h"
#include "../common/emul.h"
#include "../common/cpu.h"
#include <stdio.h>
#include <fcntl.h>
#include <signal.h>

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

/* Timer Controller */
#define RTC_INIT_REG1			0xb8300000	/* Initial value */
#define RTC_COMPARE1			0xb8300004	/* 0 forever */
#define RTC_INIT_REG2			0xb8300008
#define RTC_COMPARE2			0xb830000c
#define RTC_COUNTER1			0xb8300010	/* Initial value sub 1 per ms */
#define RTC_COUNTER2			0xb8300014
#define RTC_CONTROL1			0xb8300018	/* Ack timer interrupt */
#define RTC_CONTROL2			0xb830001c

/* Interrupt Controller */
#define INC_ISR				0xb8200000
#define INC_IMR				0xb8200004

/* UART Controller */
#define UART_BAUDRATE			0xb8500000	/* 1byte */
#define UART_CHAR			0xb8500004	/* 1byte */

#define INC_PCI_A			(1<<0)
#define INC_PCI_B			(1<<1)
#define INC_PCI_C			(1<<2)
#define INC_PCI_D			(1<<3)
#define INC_PCITBD1			(1<<4)
#define INC_PCITBD2			(1<<5)
#define INC_PCITBD3			(1<<6)
#define INC_PCITBD4			(1<<7)
#define INC_DMA1			(1<<8)
#define INC_DMA2			(1<<9)
#define INC_UART_RX			(1<<10)
#define INC_UART_TX			(1<<11)
#define INC_USB				(1<<12)
#define INC_USBTBD			(1<<13)
#define INC_TIMER1			(1<<14)
#define INC_TIMER2			(1<<15)
#define INC_PM1				(1<<16)
#define INC_PM2				(1<<17)

#define MIPS_CP0_STATUS_IMASK      0x0000FF00
#define  ImpRev 		 0x2070

extern MIPS_State *mstate;

typedef struct uart_s {
	UInt32 uart_baudrate; 
	UInt32 uart_char;
}uart_t;

typedef struct rtc_s {
	UInt32 timer_initreg1;
	UInt32 timer_compare1;
	UInt32 timer_initreg2;
	UInt32 timer_compare2;
	UInt32 timer_counter1;
	UInt32 timer_counter2;
	UInt32 timer_controlreg1;
	UInt32 timer_controlreg2;
	UInt32 timer_refreshreg;
}rtc_t;

typedef struct intc_s {
	UInt32 isr;
	UInt32 imr;
}intc_t;

typedef struct nedved_io_s {
	uart_t uart;
	rtc_t timer;
	intc_t intc;
}nedved_io_t;

static  nedved_io_t io;

void
mips_update_irq_flag_fast(MIPS_State* mstate)
{
	mstate->irq_pending = 0;
	UInt32 sreg_mask, imask;

   	sreg_mask = (1 << SR_IEC); //Shi yang 2006-08-18

  	if((mstate->cp0[SR] & sreg_mask) == (1 << SR_IEC)) {
  		imask = mstate->cp0[SR] & MIPS_CP0_STATUS_IMASK;
			if(((mstate->cp0[Cause]) & imask) && (io.intc.imr & io.intc.isr))
				mstate->irq_pending = 1;	
  	
  	}
}

static void
nedved_io_do_cycle ()
{
	io.timer.timer_counter1--;
	
	if (io.timer.timer_counter1 == io.timer.timer_compare1) {
		io.timer.timer_counter1 = io.timer.timer_initreg1;
		io.intc.isr |= INC_TIMER1;
	}

	if (io.uart.uart_char == 0)
		io.intc.isr |= INC_UART_RX;//UART TX IRQ

	if (io.uart.uart_char != 0) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;
		unsigned char buf;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		//printf("\nUART RX IRQ before skyeye_uart_read\n");
		if(skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
			//printf ("\nUART RX IRQ\n");
			io.uart.uart_char = buf;
			io.intc.isr |= INC_UART_TX; //UART RX IRQ
		}
	}

	mips_update_irq_flag_fast(mstate);
}

static UInt32
nedved_io_read_byte(UInt32 addr)
{
	UInt32 ret;

	switch (addr) {
		case RTC_INIT_REG1:
			ret = io.timer.timer_initreg1 & 0xff;
			break;
		case RTC_COMPARE1:
			ret = io.timer.timer_compare1 & 0xff;
			break;
		case RTC_INIT_REG2:
			ret = io.timer.timer_initreg2 & 0xff;
			break;
		case RTC_COMPARE2:
			ret = io.timer.timer_compare2 & 0xff;
			break;
		case RTC_COUNTER1:
			ret = io.timer.timer_counter1 & 0xff;
			break;
		case RTC_COUNTER2:
			ret = io.timer.timer_counter2 & 0xff;
			break;
		case RTC_CONTROL1:
			ret = io.timer.timer_controlreg1 & 0xff;
			break;
		case RTC_CONTROL2:
			ret = io.timer.timer_controlreg2 & 0xff;
			break;
		case INC_IMR:
			ret = io.intc.imr & 0xff;
			break;
		case INC_ISR:
			ret = io.intc.isr & 0xff;
			break;
		case UART_BAUDRATE:
			ret = io.uart.uart_baudrate & 0xff;
			break;
		case UART_CHAR:
			ret = io.uart.uart_char & 0xff;
			if (ret != 0) {
				io.intc.isr &= ~INC_UART_TX;		
			}
			break;
		default:
			break;
	}
	return ret;
}

static UInt32
nedved_io_read_halfword(UInt32 addr)
{
	UInt32 ret;

	switch (addr) {
		case RTC_INIT_REG1:
			ret = io.timer.timer_initreg1 & 0xffff;
			break;
		case RTC_COMPARE1:
			ret = io.timer.timer_compare1 & 0xffff;
			break;
		case RTC_INIT_REG2:
			ret = io.timer.timer_initreg2 & 0xffff;
			break;
		case RTC_COMPARE2:
			ret = io.timer.timer_compare2 & 0xffff;
			break;
		case RTC_COUNTER1:
			ret = io.timer.timer_counter1 & 0xffff;
			break;
		case RTC_COUNTER2:
			ret = io.timer.timer_counter2 & 0xffff;
			break;
		case RTC_CONTROL1:
			ret = io.timer.timer_controlreg1 & 0xffff;
			break;
		case RTC_CONTROL2:
			ret = io.timer.timer_controlreg2 & 0xffff;
			break;
		case INC_IMR:
			ret = io.intc.imr & 0xffff;
			break;
		case INC_ISR:
			ret = io.intc.isr & 0xffff;
			break;
		case UART_BAUDRATE:
			ret = io.uart.uart_baudrate & 0xffff;
			break;
		case UART_CHAR:
			ret = io.uart.uart_char & 0xffff;
			break;
		default:
			break;
	}
	return ret;
}

static UInt32
nedved_io_read_word(UInt32 addr)
{
	UInt32 ret;

	switch (addr) {
		case RTC_INIT_REG1:
			ret = io.timer.timer_initreg1;
			break;
		case RTC_COMPARE1:
			ret = io.timer.timer_compare1;
			break;
		case RTC_INIT_REG2:
			ret = io.timer.timer_initreg2;
			break;
		case RTC_COMPARE2:
			ret = io.timer.timer_compare2;
			break;
		case RTC_COUNTER1:
			ret = io.timer.timer_counter1;
			break;
		case RTC_COUNTER2:
			ret = io.timer.timer_counter2;
			break;
		case RTC_CONTROL1:
			ret = io.timer.timer_controlreg1;
			break;
		case RTC_CONTROL2:
			ret = io.timer.timer_controlreg2;
			break;
		case INC_IMR:
			ret = io.intc.imr;
			break;
		case INC_ISR:
			ret = io.intc.isr;
			break;
		case UART_BAUDRATE:
			ret = io.uart.uart_baudrate;
			break;
		case UART_CHAR:
			ret = io.uart.uart_char;
			if (ret != 0) {
				io.intc.isr &= ~INC_UART_TX;		
			}
			break;
		default:
			break;
	}
	return ret;
}

static void
nedved_io_write_byte(UInt32 addr, UInt32 data)
{
	unsigned char c = data & 0xff;

	switch (addr) {
		case RTC_INIT_REG1:
			io.timer.timer_initreg1 = copy_bits(io.timer.timer_initreg1, data, 7, 0);
			break;
		case RTC_COMPARE1:
			io.timer.timer_compare1 = copy_bits(io.timer.timer_compare1, data, 7, 0);
			break;
		case RTC_INIT_REG2:
			io.timer.timer_initreg2 = copy_bits(io.timer.timer_initreg2, data, 7, 0);
			break;
		case RTC_COMPARE2:
			io.timer.timer_compare2 = copy_bits(io.timer.timer_compare2, data, 7, 0);
			break;
		case RTC_COUNTER1:
			io.timer.timer_counter1 = copy_bits(io.timer.timer_counter1, data, 7, 0);
			break;
		case RTC_COUNTER2:
			io.timer.timer_counter2 = copy_bits(io.timer.timer_counter2, data, 7, 0);
			break;
		case RTC_CONTROL1:
			io.timer.timer_controlreg1 = copy_bits(io.timer.timer_controlreg1, data, 7, 0);
			break;
		case RTC_CONTROL2:
			io.timer.timer_controlreg2 = copy_bits(io.timer.timer_controlreg2, data, 7, 0);
			break;
		case INC_IMR:
			io.intc.imr = copy_bits(io.intc.imr, data, 7, 0);
			break;
		case INC_ISR:	
			io.intc.isr = copy_bits(io.intc.isr, data, 7, 0);
			break;
		case UART_BAUDRATE:
			io.uart.uart_baudrate = copy_bits(io.uart.uart_baudrate, data, 7, 0);
			break;
		case UART_CHAR:
			io.intc.isr &= ~INC_UART_RX; //Buffer is full
			io.uart.uart_char = copy_bits(io.uart.uart_char, data, 7, 0);

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			io.intc.isr |= INC_UART_RX; //Buffer is empty
			
			break;
		defalut:
			break;
	}
}

static void
nedved_io_write_halfword(UInt32 addr, UInt32 data)
{
	
	switch (addr) {
		case RTC_INIT_REG1:
			io.timer.timer_initreg1 = copy_bits(io.timer.timer_initreg1, data, 15, 0);
			break;
		case RTC_COMPARE1:
			io.timer.timer_compare1 = copy_bits(io.timer.timer_compare1, data, 15, 0);
			break;
		case RTC_INIT_REG2:
			io.timer.timer_initreg2 = copy_bits(io.timer.timer_initreg2, data, 15, 0);
			break;
		case RTC_COMPARE2:
			io.timer.timer_compare2 = copy_bits(io.timer.timer_compare2, data, 15, 0);
			break;
		case RTC_COUNTER1:
			io.timer.timer_counter1 = copy_bits(io.timer.timer_counter1, data, 15, 0);
			break;
		case RTC_COUNTER2:
			io.timer.timer_counter2 = copy_bits(io.timer.timer_counter2, data, 15, 0);
			break;
		case RTC_CONTROL1:
			io.timer.timer_controlreg1 = copy_bits(io.timer.timer_controlreg1, data, 15, 0);
			break;
		case RTC_CONTROL2:
			io.timer.timer_controlreg2 = copy_bits(io.timer.timer_controlreg2, data, 15, 0);
			break;
		case INC_IMR:
			io.intc.imr = copy_bits(io.intc.imr, data, 15, 0);
			break;
		case INC_ISR:	
			io.intc.isr = copy_bits(io.intc.isr, data, 15, 0);
			break;
		case UART_BAUDRATE:
			io.uart.uart_baudrate = copy_bits(io.uart.uart_baudrate, data, 15, 0);
			break;
		case UART_CHAR:
			io.uart.uart_char = copy_bits(io.uart.uart_char, data, 15, 0);
			break;
		defalut:
			break;
	}
}

static void
nedved_io_write_word(UInt32 addr, UInt32 data)
{
	
	switch (addr) {
		case RTC_INIT_REG1:
			io.timer.timer_initreg1 = data;
			io.timer.timer_counter1 = data;
			break;
		case RTC_COMPARE1:
			io.timer.timer_compare1 = data;
			break;
		case RTC_INIT_REG2:
			io.timer.timer_initreg2 = data;
			break;
		case RTC_COMPARE2:
			io.timer.timer_compare2 = data;
			break;
		case RTC_COUNTER1:
			io.timer.timer_counter1 = data;
			break;
		case RTC_COUNTER2:
			io.timer.timer_counter2 = data;
			break;
		case RTC_CONTROL1:
			io.timer.timer_controlreg1 = data;
			break;
		case RTC_CONTROL2:
			io.timer.timer_controlreg2 = data;
			break;
		case INC_IMR:
			io.intc.imr = data;
			break;
		case INC_ISR:	
			io.intc.isr = data;
			break;
		case UART_BAUDRATE:
			io.uart.uart_baudrate = data;
			break;
		case UART_CHAR:
			io.uart.uart_char = data;
			break;
		defalut:
			break;
	}
}

static void
nedved_set_int(UInt32 irq)
{

}

void
nedved_mach_init (void * state, machine_config_t * this_mach)
{		
	mstate->cp0[PRId] = ImpRev; 
	mstate->cp1[FCR0] = ImpRev;

	/*init io  value */
	io.intc.isr = 0x0 | INC_UART_RX;
	io.intc.imr = 0x0;
	io.uart.uart_char = 0x0;

	/*init mach */
	if (!this_mach) {

		exit (-1);
	}

	this_mach->mach_io_read_byte = nedved_io_read_byte;
	this_mach->mach_io_read_halfword = nedved_io_read_halfword;
	this_mach->mach_io_read_word = nedved_io_read_word;
	this_mach->mach_io_write_byte = nedved_io_write_byte;
	this_mach->mach_io_write_halfword = nedved_io_write_halfword;
	this_mach->mach_io_write_word = nedved_io_write_word;
	this_mach->mach_io_do_cycle = nedved_io_do_cycle;
	this_mach->mach_set_intr = nedved_set_int;
}
