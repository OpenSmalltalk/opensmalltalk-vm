/*
	s3c2440.h - definitions of "s3c2440" machine  for skyeye
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

#ifndef __S3C2440_H_
#define __S3C2440_H_

#define REGW(addr)	(*(volatile unsigned int *)(addr))
/********************************************
* Memory Controller Registers
********************************************/
#define MEM_CTL_BASE		(0x48000000)

#define BWSCON		MEM_CTL_BASE+(0x0)
#define BANKCON0	MEM_CTL_BASE+(0x4)
#define BANKCON1	MEM_CTL_BASE+(0x8)
#define BANKCON2	MEM_CTL_BASE+(0xc)
#define BANKCON3	MEM_CTL_BASE+(0x10)
#define BANKCON4	MEM_CTL_BASE+(0x14)
#define BANKCON5	MEM_CTL_BASE+(0x18)
#define BANKCON6	MEM_CTL_BASE+(0x1c)
#define BANKCON7	MEM_CTL_BASE+(0x20)
#define REFRESH		MEM_CTL_BASE+(0x24)
#define BANKSIZE	MEM_CTL_BASE+(0x28)
#define MRSRB6		MEM_CTL_BASE+(0x2c)
#define MRSRB7		MEM_CTL_BASE+(0x30)

/********************************************
* GPIO Controller Registers
********************************************/
#define GPIO_CTL_BASE		(0x56000000)
#define GPIO_CTL_SIZE		(0xC0)

#define GPACON		GPIO_CTL_BASE+(0x0)
#define GPADAT		GPIO_CTL_BASE+(0x4)
#define GPBCON		GPIO_CTL_BASE+(0x10)
#define GPBDAT		GPIO_CTL_BASE+(0x14)
#define GPBUP		GPIO_CTL_BASE+(0x18)
#define GPCCON		GPIO_CTL_BASE+(0x20)
#define GPCDAT		GPIO_CTL_BASE+(0x24)
#define GPCUP		GPIO_CTL_BASE+(0x28)
#define GPDCON		GPIO_CTL_BASE+(0x30)
#define GPDDAT		GPIO_CTL_BASE+(0x34)
#define GPDUP		GPIO_CTL_BASE+(0x38)
#define GPECON		GPIO_CTL_BASE+(0x40)
#define GPEDAT		GPIO_CTL_BASE+(0x44)
#define GPEUP		GPIO_CTL_BASE+(0x48)
#define GPFCON		GPIO_CTL_BASE+(0x50)
#define GPFDAT		GPIO_CTL_BASE+(0x54)
#define GPFUP		GPIO_CTL_BASE+(0x58)
#define GPGCON		GPIO_CTL_BASE+(0x60)
#define GPGDAT		GPIO_CTL_BASE+(0x64)
#define GPGUP		GPIO_CTL_BASE+(0x68)
#define GPHCON		GPIO_CTL_BASE+(0x70)
#define GPHDAT		GPIO_CTL_BASE+(0x74)
#define GPHUP		GPIO_CTL_BASE+(0x78)
#define MISCCR		GPIO_CTL_BASE+(0x80)
#define DCLKCON		GPIO_CTL_BASE+(0x84)
#define EXTINT0		GPIO_CTL_BASE+(0x88)
#define EXTINT1		GPIO_CTL_BASE+(0x8c)
#define EXTINT2		GPIO_CTL_BASE+(0x90)
#define EINTFLT0	GPIO_CTL_BASE+(0x94)
#define EINTFLT1	GPIO_CTL_BASE+(0x98)
#define EINTFLT2	GPIO_CTL_BASE+(0x9c)
#define EINTFLT3	GPIO_CTL_BASE+(0xa0)
#define EINTMASK	GPIO_CTL_BASE+(0xa4)
#define EINTPEND	GPIO_CTL_BASE+(0xa8)
#define GSTATUS0	GPIO_CTL_BASE+(0xac)
#define GSTATUS1	GPIO_CTL_BASE+(0xb0)
#define GSTATUS2	GPIO_CTL_BASE+(0xb4)
#define GSTATUS3	GPIO_CTL_BASE+(0xb8)
#define GSTATUS4	GPIO_CTL_BASE+(0xbc)

/********************************************
* Clock and Power Management Registers
********************************************/
#define CLK_CTL_BASE		(0x4c000000)

#define LOCKTIME	CLK_CTL_BASE+(0x0)
#define MPLLCON		CLK_CTL_BASE+(0x4)
#define UPLLCON		CLK_CTL_BASE+(0x8)
#define CLKCON		CLK_CTL_BASE+(0xc)
#define CLKSLOW		CLK_CTL_BASE+(0x10)
#define CLKDIVN		CLK_CTL_BASE+(0x14)

/********************************************
* UART Control Registers
********************************************/
#define UART_CTL_BASE0		(0x50000000)
#define UART_CTL_SIZE		(0x802c)

#define ULCON		(0x0)
#define UCON		(0x4)
#define UFCON		(0x8)
#define UMCON		(0xc)
#define UTRSTAT		(0x10)
#define UERSTAT		(0x14)
#define UFSTAT		(0x18)
#define UMSTAT		(0x1c)
#define UTXH		(0x20)
#define URXH		(0x24)
#define UBRDIV		(0x28)


/**************************************/
/* Interrupt Controller Registers     */
/**************************************/
#define INT_CTL_BASE		(0x4a000000)

#define SRCPND		INT_CTL_BASE+(0x0)
#define INTMOD		INT_CTL_BASE+(0x4)
#define INTMSK		INT_CTL_BASE+(0x8)
#define PRIORITY	INT_CTL_BASE+(0xc)
#define	INTPND		INT_CTL_BASE+(0x10)
#define INTOFFSET	INT_CTL_BASE+(0x14)
#define SUBSRCPND	INT_CTL_BASE+(0x18)
#define INTSUBMSK	INT_CTL_BASE+(0x1c)

#define INT_ADCTC		(1 << 31)	/* ADC EOC interrupt */
#define INT_RTC			(1 << 30)	/* RTC alarm interrupt */
#define INT_SPI1		(1 << 29)	/* UART1 transmit interrupt */
#define INT_UART0		(1 << 28)	/* UART0 transmit interrupt */
#define INT_IIC			(1 << 27)	/* IIC interrupt */
#define INT_USBH		(1 << 26)	/* USB host interrupt */
#define INT_USBD		(1 << 25)	/* USB device interrupt */
#define INT_RESERVED24		(1 << 24)
#define INT_UART1		(1 << 23)	/* UART1 receive interrupt */
#define INT_SPI0		(1 << 22)	/* SPI interrupt */
#define INT_MMC			(1 << 21)	/* MMC interrupt */
#define INT_DMA3		(1 << 20)	/* DMA channel 3 interrupt */
#define INT_DMA2		(1 << 19)	/* DMA channel 2 interrupt */
#define INT_DMA1		(1 << 18)	/* DMA channel 1 interrupt */
#define INT_DMA0		(1 << 17)	/* DMA channel 0 interrupt */
#define INT_LCD			(1 << 16)	/* reserved for future use */
#define INT_UART2		(1 << 15)	/* UART 2 interrupt  */
#define INT_TIMER4		(1 << 14)	/* Timer 4 interrupt */
#define INT_TIMER3		(1 << 13)	/* Timer 3 interrupt */
#define INT_TIMER2		(1 << 12)	/* Timer 2 interrupt */
#define INT_TIMER1		(1 << 11)	/* Timer 1 interrupt */
#define INT_TIMER0		(1 << 10)	/* Timer 0 interrupt */
#define INT_WDT			(1 << 9)	/* Watch-Dog timer interrupt */
#define INT_TICK		(1 << 8)	/* RTC time tick interrupt  */
#define INT_BAT_FLT		(1 << 7)
#define INT_RESERVED6		(1 << 6)	/* Reserved for future use */
#define INT_EINT8_23		(1 << 5)	/* External interrupt 8 ~ 23 */
#define INT_EINT4_7		(1 << 4)	/* External interrupt 4 ~ 7 */
#define INT_EINT3		(1 << 3)	/* External interrupt 3 */
#define INT_EINT2		(1 << 2)	/* External interrupt 2 */
#define INT_EINT1		(1 << 1)	/* External interrupt 1 */
#define INT_EINT0		(1 << 0)	/* External interrupt 0 */

#define INT_ADC			(1 << 10)
#define INT_TC			(1 << 9)
#define INT_ERR2		(1 << 8)
#define INT_TXD2		(1 << 7)
#define INT_RXD2		(1 << 6)
#define INT_ERR1		(1 << 5)
#define INT_TXD1		(1 << 4)
#define INT_RXD1		(1 << 3)
#define INT_ERR0		(1 << 2)
#define INT_TXD0		(1 << 1)
#define INT_RXD0		(1 << 0)

#define INT_MASK_INIT		0xffffffff
#define INT_SUBMSK_INIT		0x7ff

/*********************/
/* RTC Registers     */
/*********************/
#define RTC_CTL_BASE		(0x57000000)

#define RTCCON		RTC_CTL_BASE+(0x40)
#define TICNT		RTC_CTL_BASE+(0x44)
#define RTCALM		RTC_CTL_BASE+(0x50)
#define ALMSEC		RTC_CTL_BASE+(0x54)
#define ALMMIN		RTC_CTL_BASE+(0x58)
#define ALMHOUR		RTC_CTL_BASE+(0x5c)
#define ALMDATE		RTC_CTL_BASE+(0x60)
#define ALMMON		RTC_CTL_BASE+(0x64)
#define ALMYEAR		RTC_CTL_BASE+(0x68)
#define RTCRST		RTC_CTL_BASE+(0x6c)
#define BCDSEC		RTC_CTL_BASE+(0x70)
#define BCDMIN		RTC_CTL_BASE+(0x74)
#define BCDHOUR		RTC_CtL_BASE+(0x78)
#define BCDDATE		RTC_CTL_BASE+(0x7c)
#define BCDDAY		RTC_CTL_BASE+(0x80)
#define BCDMON		RTC_CTL_BASE+(0x84)
#define BCDYEAR		RTC_CTL_BASE+(0x88)

/***************************/
/* PWM Timer Registers     */
/***************************/
#define PWM_CTL_BASE		(0x51000000)
#define PWM_CTL_SIZE		(0x44)

#define TCFG0		(0x0)
#define TCFG1		(0x4)
#define TCON		(0x8)
#define TCNTB0		(0xc)
#define TCMPB0		(0x10)
#define TCNTO0		(0x14)
#define TCNTB1		(0x18)
#define TCMPB1		(0x1c)
#define TCNTO1		(0x20)
#define TCNTB2		(0x24)
#define TCMPB2		(0x28)
#define TCNTO2		(0x2c)
#define TCNTB3		(0x30)
#define TCMPB3		(0x34)
#define TCNTO3		(0x38)
#define TCNTB4		(0x3c)
#define TCNTO4		(0x40)

#define S3C2410_TIMER_NUM 5

struct s3c2440_clkpower
{
	u32 locktime;
	u32 mpllcon;
	u32 upllcon;
	u32 clkcon;
	u32 clkslow;
	u32 clkdivn;
};

struct s3c2440_timer_io
{
	u32 tcfg0;
	u32 tcfg1;
	u32 tcon;
	int tcnt[S3C2410_TIMER_NUM];
	int tcmp[S3C2410_TIMER_NUM];
	int tcntb[S3C2410_TIMER_NUM];
	int tcmpb[S3C2410_TIMER_NUM];
	int tcnto[S3C2410_TIMER_NUM];
};

struct s3c2440_uart_io
{
	u32 ulcon;		/* UART line control register */
	u32 ucon;		/* UART control register */
	u32 ufcon;		/* UART FIFO control register */
	u32 umcon;		/* UART Modem control register */
	u32 utrstat;		/* UART Tx/Rx status register */
	u32 uerstat;		/* UART Rx error status register */
	u32 ufstat;		/* UART FIFO status register */
	u32 umstat;		/* UART Modem status register */
	u32 utxh;		/* UART transmit buffer register */
	u32 urxh;		/* UART receive buffer register */
	u32 ubrdiv;		/* Baud rate divisor register 0 */
};

#define UART_INT_RXD		0x1
#define UART_INT_TXD		0x2
#define UART_INT_EXD		0x4


#define UART_UCON_INIT		0x5
#define UART_ULCON_INIT		0x3	//8N1
#define UART_UTRSTAT_INIT	0x6

#endif /* __S3C2440_H_ */
