/*
 *  linux/include/asm-arm/arch-lh79520/hardware.h
 *
 *	Copyright (C) 2001 Sharp Microelectronics of the Americas, Inc.
 *		CAMAS, WA
 *  Portions Copyright (C) 2002 Lineo, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 *	References:
 *		(1) Sharp LH79520 Universal Microcontroller User's Guide,
 *		Version 1.x, Sharp Microelectronics of the Americas, Inc.
 *
 */

#ifndef _BIT
#define _BIT(n)	(1 << (n))
#endif

#ifndef _SBF
#define _SBF(f,v) ((v) << (f))
#endif

#ifndef _BITMASK
#define _BITMASK(field_width) ( _BIT(field_width) - 1)
#endif

/* Hardware addresses of major areas.
 *  *_START is the physical address
 *  *_SIZE  is the size of the region
 *  *_BASE  is the virtual address
 */

/*
 * we can do an identity mapping (V=P) of all of I/O
 * space, except for the VIC.
 *
 * One of the places you can find the VIC is at 0xffff0000,
 * which is the same place the interrupt vectors want to live,
 * so we'll leave a hole there, and use the VIC at it's other
 * address: 0xfffff000.
 */

#define APB_START	0xfffc0000	/* Physical address of APB I/O space */
#define APB_BASE	0xfffc0000	/* Virtual address of APB I/O space  */
#define APB_SIZE	0x00026000	/* its size (up to 0xfffe6000)   */

#define AHB_START	0xffff1000	/* Physical address of AHB I/O space */
#define AHB_BASE	0xffff1000	/* Virtual address of AHB I/O space  */
#define AHB_SIZE	0x00004000	/* its size (up to 0xffff5000)  */

#define VIC_START	VIC_PHYS	/* Physical address of VIC      */
#define VIC_BASE	0xfffff000	/* Virtual address of VIC       */
#define VIC_SIZE	0x1000	/* its size                     */



#define	FLASH_START	0x40000000	/* Flash on SMC bank 0          */
#define	FLASH_BASE	0xf4000000
#define	FLASH_SIZE	(4 * 1024 * 1024)

#if defined(CONFIG_LPD_79520_10)
#define LPD_CPLD_START	0x54200000	/* CPLD on SMC bank 5           */
#define LPD_CPLD_BASE	0xf5000000
#define LPD_CPLD_SIZE	0x01400000

#define SMC91c111_START	0x54000000	/* Ethernet on SMC bank 3       */
#define SMC91c111_BASE	0xf4800000
#define SMC91c111_SIZE	4096

#define IDE_START	0x50200000	/* CF/IDE on SMC bank 4 + lpd_cpld offset */
#define IDE_BASE	0xf6400000
#define IDE_SIZE	0x00002000
#endif

#define UNUSED_START	0x58000000	/* unused   on SMC bank 6       */
#define RESERVED_START	0x5C000000	/* reserved on SMC bank 7       */

#define	INT_SRAM_START	0x60000000	/* on-chip SRAM                 */
#define	INT_SRAM_BASE	0xf6800000
#define	INT_SRAM_SIZE	(32 * 1024)


#define IO_START	APB_START
#define IO_BASE		APB_BASE

/* macro to get at IO space when running virtually */
#define IO_ADDRESS(phys)	(phys)

#define PCIO_BASE	IO_BASE


/**********************************************************************
 * AHB BASES
 *********************************************************************/
#define AHB_PHYS		(0xFFFF0000)
#define VIC_PHYS_MIRROR		(AHB_PHYS + 0x0000)
#define SMC_REGS_PHYS		(AHB_PHYS + 0x1000)
#define SDRAM_REGS_PHYS		(AHB_PHYS + 0x2000)
#define LCD_PHYS		(AHB_PHYS + 0x4000)
#define VIC_PHYS		(AHB_PHYS + 0xF000)

/**********************************************************************
 * APB PHYSS
 *********************************************************************/
#define APB_PHYS		(0xFFFC0000)
#define UART0_PHYS		(APB_PHYS + 0x00000)
#define UART1_PHYS		(APB_PHYS + 0x01000)
#define UART2_PHYS		(APB_PHYS + 0x02000)
#define PWM_PHYS		(APB_PHYS + 0x03000)
#define TIMER0_PHYS		(APB_PHYS + 0x04000)
#define TIMER1_PHYS		(APB_PHYS + 0x05000)
#define SSP_PHYS		(APB_PHYS + 0x06000)
#define GPIO3_PHYS		(APB_PHYS + 0x1C000)
#define GPIO2_PHYS		(APB_PHYS + 0x1D000)
#define GPIO1_PHYS		(APB_PHYS + 0x1E000)
#define GPIO0_PHYS		(APB_PHYS + 0x1F000)
#define RTC_PHYS		(APB_PHYS + 0x20000)
#define DMAC_PHYS		(APB_PHYS + 0x21000)
#define RCPC_PHYS		(APB_PHYS + 0x22000)
#define WDTIMER_PHYS		(APB_PHYS + 0x23000)
#define LCDICP_PHYS		(APB_PHYS + 0x24000)
#define IOCON_PHYS		(APB_PHYS + 0x25000)

/**********************************************************************
 * REMAPping
 *********************************************************************/
#define SDRAM_MEM_PHYS		(0x20000000)
#define SMC_MEM_PHYS		(0x40000000)
#define INTERNAL_MEM_PHYS	(0x60000000)

// DDD #if REMAP == 0 
#define SMC_MIRROR_MEM_PHYS	(0x00000000)
// DDD #elif REMAP == 1 
// DDD #define SDRAM_MIRROR_MEM_PHYS            (0x00000000)
// DDD #elif REMAP == 2 
// DDD #define INTERNAL_MIRROR_MEM_PHYS (0x00000000)
// DDD #else
// DDD #error REMAP must be defined as 0, 1, or 2
// DDD #endif

/**********************************************************************
 * xSPR bits
 *********************************************************************/
#define CORE_IRQ	_BIT(7)
#define CORE_FIQ	_BIT(6)

/**********************************************************************
 * SMC Memory Bank Address Space Bases
 *********************************************************************/

#define SMC_BANK0_PHYS		(SMC_MEM_PHYS + 0x00000000)
#define SMC_BANK1_PHYS		(SMC_MEM_PHYS + 0x04000000)
#define SMC_BANK2_PHYS		(SMC_MEM_PHYS + 0x08000000)
#define SMC_BANK3_PHYS		(SMC_MEM_PHYS + 0x0C000000)
#define SMC_BANK4_PHYS		(SMC_MEM_PHYS + 0x10000000)
#define SMC_BANK5_PHYS		(SMC_MEM_PHYS + 0x14000000)
#define SMC_BANK6_PHYS		(SMC_MEM_PHYS + 0x18000000)
#define SMC_BANK7_PHYS		(SMC_MEM_PHYS + 0x1C000000)

/**********************************************************************
 * SDRAMC Memory Bank Address Space Bases
 *********************************************************************/

#define SDRAM_BANK0_PHYS	(SDRAM_MEM_PHYS + 0x00000000)
#define SDRAM_BANK1_PHYS	(SDRAM_MEM_PHYS + 0x08000000)

/**********************************************************************
 * Vectored Interrupt Controller (VIC)
 *********************************************************************/
#define VICID_OFFSET		(0xFE0)
// DDD #define VIC                      ((VICREGS *)(VIC_PHYS))
// DDD #define VICID                    ((VICIDREGS *)(VIC_PHYS + VICID_OFFSET))
#define VIC_INT_TYPE_IRQ	0
#define VIC_INT_TYPE_FIQ	1

/* VIC Interrupt Sources */
#define	VIC_EXTINT0		0
#define	VIC_EXTINT1		1
#define	VIC_EXTINT2		2
#define	VIC_EXTINT3		3
#define	VIC_EXTINT4		4
#define	VIC_EXTINT5		5
#define	VIC_EXTINT6		6
#define	VIC_EXTINT7		7
#define	VIC_SPEXTINT0		8
#define	VIC_SPEXTINT1		9
#define	VIC_SPEXTINT2		10
#define	VIC_SPEXTINT3		11
#define	VIC_CLCDC		12
#define	VIC_SSPTXINTR		13
#define	VIC_SSPRXINTR		14
#define	VIC_SSPRORINTR		15
#define	VIC_SSPINTR		16
#define	VIC_TIMER0		17
#define	VIC_TIMER1		18
#define	VIC_TIMER2		19
#define	VIC_TIMER3		20
#define	VIC_UART0_RX		21
#define	VIC_UART0_TX		22
#define	VIC_UART0		23
#define	VIC_UART1		24
#define	VIC_UART2		25
#define	VIC_DMA0		26
#define	VIC_DMA1		27
#define	VIC_DMA2		28
#define	VIC_DMA3		29
#define	VIC_RTC			30
#define	VIC_WDT			31

/* VIC Vectors */
#define VIC_VECT_0		0
#define VIC_VECT_1		1
#define VIC_VECT_2		2
#define VIC_VECT_3		3
#define VIC_VECT_4		4
#define VIC_VECT_5		5
#define VIC_VECT_6		6
#define VIC_VECT_7		7
#define VIC_VECT_8		8
#define VIC_VECT_9		9
#define VIC_VECT_10		10
#define VIC_VECT_11		11
#define VIC_VECT_12		12
#define VIC_VECT_13		13
#define VIC_VECT_14		14
#define VIC_VECT_15		15
#define VIC_VECT_MAX		VIC_VECT_15
#define VIC_VECT_DEFAULT	~(0)


#define	XTAL_IN			14745600	/* 14.7456 MHz crystal  */
#define PLL_CLOCK		(XTAL_IN * 21)	/* 309 MHz PLL clock    */



/**********************************************************************
 * UART'S
 *********************************************************************/
#define UARTID_OFFSET	(0xFE0)
// DDD #define UART0            ((UARTREGS *)(UART0_PHYS))
// DDD #define UART1            ((UARTREGS *)(UART1_PHYS))
// DDD #define UART2            ((UARTREGS *)(UART2_PHYS))
// DDD #define UART0ID          ((UARTIDREGS *)(UART0_PHYS + UARTID_OFFSET))
// DDD #define UART1ID          ((UARTIDREGS *)(UART1_PHYS + UARTID_OFFSET))
// DDD #define UART2ID          ((UARTIDREGS *)(UART2_PHYS + UARTID_OFFSET))

/**********************************************************************
 * IRDA
 *********************************************************************/
// DDD #define IRDA0    ((UARTREGS *)(UART0_PHYS))
// DDD #define IRDA1    ((UARTREGS *)(UART1_PHYS))
// DDD #define IRDA2    ((UARTREGS *)(UART2_PHYS))

/**********************************************************************
 * Pulse Width Modulator (PWM)
 *********************************************************************/
// DDD #define PWMX_OFFSET      (0x20)
// DDD #define PWM              ((PWMREGS *)(PWM_PHYS))
// DDD #define PWM0             ((PWMXREGS *)(PWM_PHYS))
// DDD #define PWM1             ((PWMXREGS *)(PWM_PHYS + PWMX_OFFSET))

/**********************************************************************
 * TIMER
 *********************************************************************/
// DDD #define TIMER2_OFFSET    (0x20)
// DDD #define TIMER0           ((TIMERREG *)(TIMER0_PHYS))
// DDD #define TIMER1           ((volatile TIMERREG *)(TIMER0_PHYS + TIMER2_OFFSET))
// DDD #define TIMER2           ((TIMERREG *)(TIMER1_PHYS))
// DDD #define TIMER3           ((TIMERREG *)(TIMER1_PHYS + TIMER2_OFFSET))

/**********************************************************************
 * Synchronous Serial Port (SSP)
 *********************************************************************/
// DDD #define SSP              ((SSPREGS *)(SSP_PHYS))

/**********************************************************************
 * General Purpose Input/Output (GPIO)
 *********************************************************************/
// DDD #define GPIOA    ((GPIOPAREGS *)(GPIO0_PHYS))
// DDD #define GPIOB    ((GPIOPBREGS *)(GPIO0_PHYS))
// DDD #define GPIOC    ((GPIOPAREGS *)(GPIO1_PHYS))
// DDD #define GPIOD    ((GPIOPBREGS *)(GPIO1_PHYS))
// DDD #define GPIOE    ((GPIOPAREGS *)(GPIO2_PHYS))
// DDD #define GPIOF    ((GPIOPBREGS *)(GPIO2_PHYS))
// DDD #define GPIOG    ((GPIOPAREGS *)(GPIO3_PHYS))
// DDD #define GPIOH    ((GPIOPBREGS *)(GPIO3_PHYS))

/**********************************************************************
 * Real Time Clock (RTC)
 *********************************************************************/
// DDD #define RTC      ((RTCREGS *)(RTC_PHYS))

/**********************************************************************
 * DMA Controller (DMAC)
 *********************************************************************/
// DDD #define DMAC     ((DMACREGS *)(DMAC_PHYS))

/**********************************************************************
 * Reset, Clock, and Power Controller (RCPC)
 *********************************************************************/
// DDD #define RCPC     ((RCPCREGS *)(RCPC_PHYS))       

/**********************************************************************
 * Watchdog Timer (WDTIMER)
 *********************************************************************/
// DDD #define WDTIMER          ((WDTIMERREGS *)(WDTIMER_PHYS))

/**********************************************************************
 * LCD Interface Control Processor (LCDICP)
 *********************************************************************/
// DDD #define LCDICP           ((LCDICPREGS *)(LCDICP_PHYS))

/**********************************************************************
 * IOCON
 *********************************************************************/
// DDD #define IOCON    ((IOCONREGS *)(IOCON_PHYS))
