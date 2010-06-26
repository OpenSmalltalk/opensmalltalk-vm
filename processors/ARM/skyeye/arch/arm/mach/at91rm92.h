/*
	at91rm92.h - definitions of "at91rm9200" machine  for skyeye
	Copyright (C) 2004 Skyeye Develop Group
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
 * 05/29/2004  	initial version
 *
 *		walimis <wlm@student.dlut.edu.cn> 
 * */

#ifndef __AT91RM9200_H_
#define __AT91RM9200_H_

/********************************************
* Advanced Interrupt Controller(AIC)
********************************************/

#define AT91RM92_AIC_BASE0       (0xfffff000)
#define AT91RM92_AIC_SIZE        0x1000

#define AIC_SMR         AT91RM92_AIC_BASE0+(0)	// Source Mode Register
#define AIC_SVR         AT91RM92_AIC_BASE0+(128)	// Source Vector Register
#define AIC_IVR         AT91RM92_AIC_BASE0+(256)	// IRQ Vector Register
#define AIC_FVR         AT91RM92_AIC_BASE0+(260)	// FIQ Vector Register
#define AIC_ISR         AT91RM92_AIC_BASE0+(264)	// Interrupt Status Register
#define AIC_IPR         AT91RM92_AIC_BASE0+(268)	// Interrupt Pending Register
#define AIC_IMR         AT91RM92_AIC_BASE0+(272)	// Interrupt Mask Register
#define AIC_CISR        AT91RM92_AIC_BASE0+(276)	// Core Interrupt Status Register
#define AIC_IECR        AT91RM92_AIC_BASE0+(288)	// Interrupt Enable Command Register
#define AIC_IDCR        AT91RM92_AIC_BASE0+(292)	// Interrupt Disable Command Register
#define AIC_ICCR        AT91RM92_AIC_BASE0+(296)	// Interrupt Clear Command Register
#define AIC_ISCR        AT91RM92_AIC_BASE0+(300)	// Interrupt Set Command Register
#define AIC_EOICR       AT91RM92_AIC_BASE0+(304)	// End of Interrupt Command Register
#define AIC_SPU         AT91RM92_AIC_BASE0+(308)	// Spurious Vector Register
#define AIC_DCR         AT91RM92_AIC_BASE0+(312)	// Debug Control Register (Protect)
#define AIC_FFER        AT91RM92_AIC_BASE0+(320)	// Fast Forcing Enable Register
#define AIC_FFDR        AT91RM92_AIC_BASE0+(324)	// Fast Forcing Disable Register
#define AIC_FFSR        AT91RM92_AIC_BASE0+(328)	// Fast Forcing Status Register

#define PIO_PDSR	0xFFFFF63c

/********************************************
* System Timer definition
********************************************/
#define AT91RM92_ST_BASE0       (0xfffffd00)
#define AT91RM92_ST_SIZE       	0x100

/* System I/O register
 * */
#define ST_CR          	0x0
#define ST_PIMR         0x4
#define ST_WDMR         0x8
#define ST_RTMR         0xC
#define ST_SR           0x10
#define ST_IER          0x14
#define ST_IDR          0x18
#define ST_IMR          0x1C
#define ST_RTAR         0x20
#define ST_CRTR         0x24

/* ST interrupt use "sys" interrupt
 * */
#define AT91RM92_ID_SYS    (0x1 << 1)	// System Peripheral


#define AT91RM92_ST_PITS         (0x1 <<  0)	// (ST) Period Interval Timer Interrupt
#define AT91RM92_ST_WDOVF        (0x1 <<  1)	// (ST) Watchdog Overflow
#define AT91RM92_ST_RTTINC       (0x1 <<  2)	// (ST) Real-time Timer Increment
#define AT91RM92_ST_ALMS         (0x1 <<  3)	// (ST) Alarm Status

struct at91rm92_st_io
{
	/* I/O register
	 * */
	u32 cr;			/* control */
	u32 pimr;		/* Period Interval Mode */
	u32 wdmr;		/* Watchdog Mode Register */
	u32 rtmr;		/* Real-time Mode Register */
	u32 sr;			/* Status Register */
	u32 ier;		/* Interrupt Enable Register */
	u32 idr;		/* Interrupt Disable Register */
	u32 imr;		/* Interrupt Mask Register */
	u32 rtar;		/* Real-time Alarm Register */
	u32 crtr;		/* Current Real-time Register */

	u16 piv_dc;		/*Period Interval Value down count */
	u16 wdv_dc;		/*Watchdog Counter Value down count */
	u16 rtpres_dc;		/*Real-time Timer Prescaler Value down count */
};



/********************************************
* USART definition
********************************************/
/* I/O register Offset
 * */
#define US_CR           0x0
#define US_MR           0x4
#define US_IER          0x8
#define US_IDR         	0xC
#define US_IMR         	0x10
#define US_CSR         	0x14
#define US_RHR         	0x18
#define US_THR         	0x1C
#define US_BRGR         0x20
#define US_RTOR         0x24
#define US_TTGR         0x28
#define US_FIDI         0x40
#define US_NER         	0x44
#define US_IF         	0x4C

#define AT91RM92_US_RXRDY        ( 0x1 <<  0)	// (USART) RXRDY Interrupt
#define AT91RM92_US_TXRDY        ( 0x1 <<  1)	// (USART) TXRDY Interrupt
#define AT91RM92_US_RXBRK        ( 0x1 <<  2)	// (USART) Break Received/End of Break
#define AT91RM92_US_ENDRX        ( 0x1 <<  3)	// (USART) End of Receive Transfer Interrupt
#define AT91RM92_US_ENDTX        ( 0x1 <<  4)	// (USART) End of Transmit Interrupt
#define AT91RM92_US_OVRE         ( 0x1 <<  5)	// (USART) Overrun Interrupt
#define AT91RM92_US_FRAME        ( 0x1 <<  6)	// (USART) Framing Error Interrupt
#define AT91RM92_US_PARE         ( 0x1 <<  7)	// (USART) Parity Error Interrupt
#define AT91RM92_US_TIMEOUT      ( 0x1 <<  8)	// (USART) Receiver Time-out
#define AT91RM92_US_TXEMPTY      ( 0x1 <<  9)	// (USART) TXEMPTY Interrupt
#define AT91RM92_US_ITERATION    ( 0x1 << 10)	// (USART) Max number of Repetitions Reached
#define AT91RM92_US_TXBUFE       ( 0x1 << 11)	// (USART) TXBUFE Interrupt
#define AT91RM92_US_RXBUFF       ( 0x1 << 12)	// (USART) RXBUFF Interrupt
#define AT91RM92_US_NACK         ( 0x1 << 13)	// (USART) Non Acknowledge
#define AT91RM92_US_RIIC         ( 0x1 << 16)	// (USART) Ring INdicator Input Change Flag
#define AT91RM92_US_DSRIC        ( 0x1 << 17)	// (USART) Data Set Ready Input Change Flag
#define AT91RM92_US_DCDIC        ( 0x1 << 18)	// (USART) Data Carrier Flag
#define AT91RM92_US_CTSIC        ( 0x1 << 19)	// (USART) Clear To Send Input Change Flag

/* default base address for uart0 and uart1
 * at91rm9200 use "USART" instead of "UART". we here use name "UART".
 * */

#define AT91RM92_UART_BASE       (0xfffc0000)

#define AT91RM92_UART_SIZE	  0x4000


#define AT91RM92_ID_US0    ( 0x1 << 6)	// USART 0
#define AT91RM92_ID_US1    ( 0x1 << 7)	// USART 1
#define AT91RM92_ID_US2    ( 0x1 << 8)	// USART 2
#define AT91RM92_ID_US3    ( 0x1 << 9)	// USART 3

#define AT91RM92_ID_US(i) (0x1 << (6 + i))

/* DBGU Register Defination */
#define DBGU_BASE 0xFFFFF200
#define DBGU_CR (DBGU_BASE + 0x0)
#define DBGU_MR (DBGU_BASE + 0x4)
#define DBGU_IER (DBGU_BASE + 0x8)
#define DBGU_IDR (DBGU_BASE + 0xC)
#define DBGU_IMR (DBGU_BASE + 0x10)
#define DBGU_SR (DBGU_BASE + 0x14)
#define DBGU_RHR (DBGU_BASE + 0x18)
#define DBGU_THR (DBGU_BASE + 0x1C)
#define DBGU_BRGR (DBGU_BASE + 0x20)
#define DBGU_CIDR (DBGU_BASE + 0x40)

/* Power Management Controller */
#define PMC_BASE 0xFFFFFC00
#define CKGR_PLLAR (PMC_BASE + 0x28)
#define CKGR_PLLBR (PMC_BASE + 0x2C)
#define PMC_MCKR (PMC_BASE + 0x30)
#define PMC_SR (PMC_BASE + 0x68)

#define AT91_PMC_LOCKB (1 << 2)

struct at91rm92_uart_io
{
	/* I/O register
	 * */
	u32 cr;			/* control */
	u32 mr;			/* mode */
	u32 ier;		/* interrupt enable */
	u32 idr;		/* interrupt disable */
	u32 imr;		/* interrupt mask */
	u32 csr;		/* channel status */
	u32 rhr;		/* receive holding */
	u32 thr;		/* tramsmit holding  */
	u32 brgr;		/* baud rate generator */
	u32 rtor;		/* rx time-out */
	u32 ttgr;		/* tx time-guard */
	u32 fidi;
	u32 ner;
	u32 us_if;

	u32 sysflg;

};

struct at91rm92_dbgu_io
{
	/* I/O register
         * */
	u32 cr; /* Control register */
	u32 mr; /* Mode register */
	u32 ier; /* Interrupt enable register */
	u32 idr; /* Interrupt disable register*/
	u32 imr; /* Interrupt mask register */
	u32 sr;
	u32 rhr;
	u32 thr;
	u32 brgr;
	u32 cidr;
	u32 exid;

};
struct at91rm92_pmc_io{
	u32 ckgr_pllar;
	u32 ckgr_pllbr;
	u32 pmc_mckr;
	u32 pmc_sr;
};
#endif /*__AT91RM9200_H_ */
