/* one part from clps7110 and another from at91.
 * should modify it only for at91.
 * walimis. 2003/7/18
 * */
/*
 * linux/include/asm-arm/arch-lpc/hardware.h
 * for lpc
 * 2004-06-19 added by ksh,tsinghua
 */

#ifndef __ASM_ARCH_HARDWARE_H
#define __ASM_ARCH_HARDWARE_H

/* 0=TC0, 1=TC1*/
#define KERNEL_TIMER 0

#define LPC_TC_BASE 0xe0004000

/*
 *  added by ksh,2004-06-18,defined interrupt register
 */
#define VIC_BASE 	0xfffff000
#define VIC_ISR  		(VIC_BASE+0x000)
#define VIC_FSR  		(VIC_BASE+0x004)
#define VIC_RISR		(VIC_BASE+0x008)
#define VIC_ISLR		(VIC_BASE+0x00c)	//interrupt select register
#define VIC_IER		(VIC_BASE+0x010)
#define VIC_IECR		(VIC_BASE+0x014)
#define VIC_SIR		(VIC_BASE+0x018)
#define VIC_SICR		(VIC_BASE+0x01c)
#define VIC_PER		(VIC_BASE+0x020)
#define VIC_DVAR	(VIC_BASE+0x030)
#define VIC_VAR(i)	(VIC_BASE+0x100+i*4)
#define VIC_VCR(i)	(VIC_BASE+0x200+i*4)

/* EXTERNAL MEMORY CONTROLLER (EMC) */
/* 外部总线控制器 */
#define BCFG0           (*((volatile unsigned int *) 0xFFE00000))	/* lpc22xx only */
#define BCFG1           (*((volatile unsigned int *) 0xFFE00004))	/* lpc22xx only */
#define BCFG2           (*((volatile unsigned int *) 0xFFE00008))	/* lpc22xx only */
#define BCFG3           (*((volatile unsigned int *) 0xFFE0000C))	/* lpc22xx only */

/* External Interrupts */
/* 外部中断控制寄存器 */
#define EXTINT          (*((volatile unsigned char *) 0xE01FC140))
#define EXTWAKE         (*((volatile unsigned char *) 0xE01FC144))
#define EXTMODE         (*((volatile unsigned char *) 0xE01FC148))	/* no in lpc210x */
#define EXTPOLAR        (*((volatile unsigned char *) 0xE01FC14C))	/* no in lpc210x */

/* SMemory mapping control. */
/* 内存remap控制寄存器 */
#define MEMMAP          (*((volatile unsigned int *) 0xE01FC040))

/* Phase Locked Loop (PLL) */
/* PLL控制寄存器 */
#define PLLCON          (*((volatile unsigned char *) 0xE01FC080))
#define PLLCFG          (*((volatile unsigned char *) 0xE01FC084))
#define PLLSTAT         (*((volatile unsigned short*) 0xE01FC088))
#define PLLFEED         (*((volatile unsigned char *) 0xE01FC08C))

/* Power Control */
/* 功率控制寄存器 */
#define PCON            (*((volatile unsigned char *) 0xE01FC0C0))
#define PCONP           (*((volatile unsigned int *) 0xE01FC0C4))

/* VPB Divider */
/* VLSI外设总线（VPB）分频寄存器 */
#define VPBDIV          (*((volatile unsigned char *) 0xE01FC100))

/* Memory Accelerator Module (MAM) */
/* 存储器加速模块 */
#define MAMCR           (*((volatile unsigned char *) 0xE01FC000))
#define MAMTIM          (*((volatile unsigned char *) 0xE01FC004))

/* Vectored Interrupt Controller (VIC) */
/* 向量中断控制器(VIC)的特殊寄存器 */
#define VICIRQStatus    (*((volatile unsigned int *) 0xFFFFF000))
#define VICFIQStatus    (*((volatile unsigned int *) 0xFFFFF004))
#define VICRawIntr      (*((volatile unsigned int *) 0xFFFFF008))
#define VICIntSelect    (*((volatile unsigned int *) 0xFFFFF00C))
#define VICIntEnable    (*((volatile unsigned int *) 0xFFFFF010))
#define VICIntEnClr     (*((volatile unsigned int *) 0xFFFFF014))
#define VICSoftInt      (*((volatile unsigned int *) 0xFFFFF018))
#define VICSoftIntClear (*((volatile unsigned int *) 0xFFFFF01C))
#define VICProtection   (*((volatile unsigned int *) 0xFFFFF020))
#define VICVectAddr     (*((volatile unsigned int *) 0xFFFFF030))
#define VICDefVectAddr  (*((volatile unsigned int *) 0xFFFFF034))
#define VICVectAddr0    (*((volatile unsigned int *) 0xFFFFF100))
#define VICVectAddr1    (*((volatile unsigned int *) 0xFFFFF104))
#define VICVectAddr2    (*((volatile unsigned int *) 0xFFFFF108))
#define VICVectAddr3    (*((volatile unsigned int *) 0xFFFFF10C))
#define VICVectAddr4    (*((volatile unsigned int *) 0xFFFFF110))
#define VICVectAddr5    (*((volatile unsigned int *) 0xFFFFF114))
#define VICVectAddr6    (*((volatile unsigned int *) 0xFFFFF118))
#define VICVectAddr7    (*((volatile unsigned int *) 0xFFFFF11C))
#define VICVectAddr8    (*((volatile unsigned int *) 0xFFFFF120))
#define VICVectAddr9    (*((volatile unsigned int *) 0xFFFFF124))
#define VICVectAddr10   (*((volatile unsigned int *) 0xFFFFF128))
#define VICVectAddr11   (*((volatile unsigned int *) 0xFFFFF12C))
#define VICVectAddr12   (*((volatile unsigned int *) 0xFFFFF130))
#define VICVectAddr13   (*((volatile unsigned int *) 0xFFFFF134))
#define VICVectAddr14   (*((volatile unsigned int *) 0xFFFFF138))
#define VICVectAddr15   (*((volatile unsigned int *) 0xFFFFF13C))
#define VICVectCntl0    (*((volatile unsigned int *) 0xFFFFF200))
#define VICVectCntl1    (*((volatile unsigned int *) 0xFFFFF204))
#define VICVectCntl2    (*((volatile unsigned int *) 0xFFFFF208))
#define VICVectCntl3    (*((volatile unsigned int *) 0xFFFFF20C))
#define VICVectCntl4    (*((volatile unsigned int *) 0xFFFFF210))
#define VICVectCntl5    (*((volatile unsigned int *) 0xFFFFF214))
#define VICVectCntl6    (*((volatile unsigned int *) 0xFFFFF218))
#define VICVectCntl7    (*((volatile unsigned int *) 0xFFFFF21C))
#define VICVectCntl8    (*((volatile unsigned int *) 0xFFFFF220))
#define VICVectCntl9    (*((volatile unsigned int *) 0xFFFFF224))
#define VICVectCntl10   (*((volatile unsigned int *) 0xFFFFF228))
#define VICVectCntl11   (*((volatile unsigned int *) 0xFFFFF22C))
#define VICVectCntl12   (*((volatile unsigned int *) 0xFFFFF230))
#define VICVectCntl13   (*((volatile unsigned int *) 0xFFFFF234))
#define VICVectCntl14   (*((volatile unsigned int *) 0xFFFFF238))
#define VICVectCntl15   (*((volatile unsigned int *) 0xFFFFF23C))

/* Pin Connect Block */
/* 管脚连接模块控制寄存器 */
#define PINSEL0         (*((volatile unsigned int *) 0xE002C000))
#define PINSEL1         (*((volatile unsigned int *) 0xE002C004))
#define PINSEL2         (*((volatile unsigned int *) 0xE002C014))	/* no in lpc210x */

/* General Purpose Input/Output (GPIO) */
/* 通用并行IO口的特殊寄存器 */
#define IOPIN           (*((volatile unsigned int *) 0xE0028000))	/* lpc210x only */
#define IOSET           (*((volatile unsigned int *) 0xE0028004))	/* lpc210x only */
#define IODIR           (*((volatile unsigned int *) 0xE0028008))	/* lpc210x only */
#define IOCLR           (*((volatile unsigned int *) 0xE002800C))	/* lpc210x only */

#define IO0PIN          (*((volatile unsigned int *) 0xE0028000))	/* no in lpc210x */
#define IO0SET          (*((volatile unsigned int *) 0xE0028004))	/* no in lpc210x */
#define IO0DIR          (*((volatile unsigned int *) 0xE0028008))	/* no in lpc210x */
#define IO0CLR          (*((volatile unsigned int *) 0xE002800C))	/* no in lpc210x */

#define IO1PIN          (*((volatile unsigned int *) 0xE0028010))	/* no in lpc210x */
#define IO1SET          (*((volatile unsigned int *) 0xE0028014))	/* no in lpc210x */
#define IO1DIR          (*((volatile unsigned int *) 0xE0028018))	/* no in lpc210x */
#define IO1CLR          (*((volatile unsigned int *) 0xE002801C))	/* no in lpc210x */

#define IO2PIN          (*((volatile unsigned int *) 0xE0028020))	/* lpc22xx only */
#define IO2SET          (*((volatile unsigned int *) 0xE0028024))	/* lpc22xx only */
#define IO2DIR          (*((volatile unsigned int *) 0xE0028028))	/* lpc22xx only */
#define IO2CLR          (*((volatile unsigned int *) 0xE002802C))	/* lpc22xx only */

#define IO3PIN          (*((volatile unsigned int *) 0xE0028030))	/* lpc22xx only */
#define IO3SET          (*((volatile unsigned int *) 0xE0028034))	/* lpc22xx only */
#define IO3DIR          (*((volatile unsigned int *) 0xE0028038))	/* lpc22xx only */
#define IO3CLR          (*((volatile unsigned int *) 0xE002803C))	/* lpc22xx only */

/* Universal Asynchronous Receiver Transmitter 0 (UART0) */
/* 通用异步串行口0(UART0)的特殊寄存器 */
#define U0RBR           (*((volatile unsigned char *) 0xE000C000))
#define U0THR           (*((volatile unsigned char *) 0xE000C000))
#define U0IER           (*((volatile unsigned char *) 0xE000C004))
#define U0IIR           (*((volatile unsigned char *) 0xE000C008))
#define U0FCR           (*((volatile unsigned char *) 0xE000C008))
#define U0LCR           (*((volatile unsigned char *) 0xE000C00C))
#define U0LSR           (*((volatile unsigned char *) 0xE000C014))
#define U0SCR           (*((volatile unsigned char *) 0xE000C01C))
#define U0DLL           (*((volatile unsigned char *) 0xE000C000))
#define U0DLM           (*((volatile unsigned char *) 0xE000C004))

/* Universal Asynchronous Receiver Transmitter 1 (UART1) */
/* 通用异步串行口1(UART1)的特殊寄存器 */
#define U1RBR           (*((volatile unsigned char *) 0xE0010000))
#define U1THR           (*((volatile unsigned char *) 0xE0010000))
#define U1IER           (*((volatile unsigned char *) 0xE0010004))
#define U1IIR           (*((volatile unsigned char *) 0xE0010008))
#define U1FCR           (*((volatile unsigned char *) 0xE0010008))
#define U1LCR           (*((volatile unsigned char *) 0xE001000C))
#define U1MCR           (*((volatile unsigned char *) 0xE0010010))
#define U1LSR           (*((volatile unsigned char *) 0xE0010014))
#define U1MSR           (*((volatile unsigned char *) 0xE0010018))
#define U1SCR           (*((volatile unsigned char *) 0xE001001C))
#define U1DLL           (*((volatile unsigned char *) 0xE0010000))
#define U1DLM           (*((volatile unsigned char *) 0xE0010004))

/* I2C (8/16 bit data bus) */
/* 芯片间总线（I2C）的特殊寄存器 */
#define I2CONSET        (*((volatile unsigned int *) 0xE001C000))
#define I2STAT          (*((volatile unsigned int *) 0xE001C004))
#define I2DAT           (*((volatile unsigned int *) 0xE001C008))
#define I2ADR           (*((volatile unsigned int *) 0xE001C00C))
#define I2SCLH          (*((volatile unsigned int *) 0xE001C010))
#define I2SCLL          (*((volatile unsigned int *) 0xE001C014))
#define I2CONCLR        (*((volatile unsigned int *) 0xE001C018))

/* SPI (Serial Peripheral Interface) */
/* SPI总线接口的特殊寄存器 */
	/* only for lpc210x */
#define SPI_SPCR        (*((volatile unsigned char *) 0xE0020000))
#define SPI_SPSR        (*((volatile unsigned char *) 0xE0020004))
#define SPI_SPDR        (*((volatile unsigned char *) 0xE0020008))
#define SPI_SPCCR       (*((volatile unsigned char *) 0xE002000C))
#define SPI_SPINT       (*((volatile unsigned char *) 0xE002001C))

#define S0PCR           (*((volatile unsigned char *) 0xE0020000))	/* no in lpc210x */
#define S0PSR           (*((volatile unsigned char *) 0xE0020004))	/* no in lpc210x */
#define S0PDR           (*((volatile unsigned char *) 0xE0020008))	/* no in lpc210x */
#define S0PCCR          (*((volatile unsigned char *) 0xE002000C))	/* no in lpc210x */
#define S0PINT          (*((volatile unsigned char *) 0xE002001C))	/* no in lpc210x */

#define S1PCR           (*((volatile unsigned char *) 0xE0030000))	/* no in lpc210x */
#define S1PSR           (*((volatile unsigned char *) 0xE0030004))	/* no in lpc210x */
#define S1PDR           (*((volatile unsigned char *) 0xE0030008))	/* no in lpc210x */
#define S1PCCR          (*((volatile unsigned char *) 0xE003000C))	/* no in lpc210x */
#define S1PINT          (*((volatile unsigned char *) 0xE003001C))	/* no in lpc210x */

/* CAN CONTROLLERS AND ACCEPTANCE FILTER */
/* CAN控制器和接收路波器 */
#define CAN1MOD         (*((volatile unsigned char *) 0xE0044000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1CMR         (*((volatile unsigned char *) 0xE0044004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1GSR         (*((volatile unsigned char *) 0xE0044008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1ICR         (*((volatile unsigned char *) 0xE004400C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1IER         (*((volatile unsigned char *) 0xE0044010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1BTR         (*((volatile unsigned char *) 0xE0044014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1EWL         (*((volatile unsigned char *) 0xE004401C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1SR          (*((volatile unsigned char *) 0xE0044020))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1RFS         (*((volatile unsigned char *) 0xE0044024))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1RDA         (*((volatile unsigned char *) 0xE0044028))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1RDB         (*((volatile unsigned char *) 0xE004402C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TFI1        (*((volatile unsigned char *) 0xE0044030))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TID1        (*((volatile unsigned char *) 0xE0044034))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDA1        (*((volatile unsigned char *) 0xE0044038))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDB1        (*((volatile unsigned char *) 0xE004403C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TFI2        (*((volatile unsigned char *) 0xE0044040))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TID2        (*((volatile unsigned char *) 0xE0044044))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDA2        (*((volatile unsigned char *) 0xE0044048))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDB2        (*((volatile unsigned char *) 0xE004404C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TFI3        (*((volatile unsigned char *) 0xE0044050))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TID3        (*((volatile unsigned char *) 0xE0044054))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDA3        (*((volatile unsigned char *) 0xE0044058))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN1TDB3        (*((volatile unsigned char *) 0xE004405C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CAN2MOD         (*((volatile unsigned char *) 0xE0048000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2CMR         (*((volatile unsigned char *) 0xE0048004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2GSR         (*((volatile unsigned char *) 0xE0048008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2ICR         (*((volatile unsigned char *) 0xE004800C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2IER         (*((volatile unsigned char *) 0xE0048010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2BTR         (*((volatile unsigned char *) 0xE0048014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2EWL         (*((volatile unsigned char *) 0xE004801C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2SR          (*((volatile unsigned char *) 0xE0048020))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2RFS         (*((volatile unsigned char *) 0xE0048024))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2RDA         (*((volatile unsigned char *) 0xE0048028))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2RDB         (*((volatile unsigned char *) 0xE004802C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TFI1        (*((volatile unsigned char *) 0xE0048030))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TID1        (*((volatile unsigned char *) 0xE0048034))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDA1        (*((volatile unsigned char *) 0xE0048038))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDB1        (*((volatile unsigned char *) 0xE004803C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TFI2        (*((volatile unsigned char *) 0xE0048040))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TID2        (*((volatile unsigned char *) 0xE0048044))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDA2        (*((volatile unsigned char *) 0xE0048048))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDB2        (*((volatile unsigned char *) 0xE004804C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TFI3        (*((volatile unsigned char *) 0xE0048050))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TID3        (*((volatile unsigned char *) 0xE0048054))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDA3        (*((volatile unsigned char *) 0xE0048058))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN2TDB3        (*((volatile unsigned char *) 0xE004805C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CAN3MOD         (*((volatile unsigned char *) 0xE004C000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3CMR         (*((volatile unsigned char *) 0xE004C004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3GSR         (*((volatile unsigned char *) 0xE004C008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3ICR         (*((volatile unsigned char *) 0xE004C00C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3IER         (*((volatile unsigned char *) 0xE004C010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3BTR         (*((volatile unsigned char *) 0xE004C014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3EWL         (*((volatile unsigned char *) 0xE004C01C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3SR          (*((volatile unsigned char *) 0xE004C020))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3RFS         (*((volatile unsigned char *) 0xE004C024))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3RDA         (*((volatile unsigned char *) 0xE004C028))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3RDB         (*((volatile unsigned char *) 0xE004C02C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TFI1        (*((volatile unsigned char *) 0xE004C030))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TID1        (*((volatile unsigned char *) 0xE004C034))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDA1        (*((volatile unsigned char *) 0xE004C038))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDB1        (*((volatile unsigned char *) 0xE004C03C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TFI2        (*((volatile unsigned char *) 0xE004C040))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TID2        (*((volatile unsigned char *) 0xE004C044))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDA2        (*((volatile unsigned char *) 0xE004C048))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDB2        (*((volatile unsigned char *) 0xE004C04C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TFI3        (*((volatile unsigned char *) 0xE004C050))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TID3        (*((volatile unsigned char *) 0xE004C054))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDA3        (*((volatile unsigned char *) 0xE004C058))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN3TDB3        (*((volatile unsigned char *) 0xE004C05C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CAN4MOD         (*((volatile unsigned char *) 0xE0050000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4CMR         (*((volatile unsigned char *) 0xE0050004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4GSR         (*((volatile unsigned char *) 0xE0050008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4ICR         (*((volatile unsigned char *) 0xE005000C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4IER         (*((volatile unsigned char *) 0xE0050010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4BTR         (*((volatile unsigned char *) 0xE0050014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4EWL         (*((volatile unsigned char *) 0xE005001C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4SR          (*((volatile unsigned char *) 0xE0050020))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4RFS         (*((volatile unsigned char *) 0xE0050024))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4RDA         (*((volatile unsigned char *) 0xE0050028))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4RDB         (*((volatile unsigned char *) 0xE005002C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TFI1        (*((volatile unsigned char *) 0xE0050030))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TID1        (*((volatile unsigned char *) 0xE0050034))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDA1        (*((volatile unsigned char *) 0xE0050038))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDB1        (*((volatile unsigned char *) 0xE005003C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TFI2        (*((volatile unsigned char *) 0xE0050040))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TID2        (*((volatile unsigned char *) 0xE0050044))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDA2        (*((volatile unsigned char *) 0xE0050048))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDB2        (*((volatile unsigned char *) 0xE005004C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TFI3        (*((volatile unsigned char *) 0xE0050050))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TID3        (*((volatile unsigned char *) 0xE0050054))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDA3        (*((volatile unsigned char *) 0xE0050058))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN4TDB3        (*((volatile unsigned char *) 0xE005005C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CAN5MOD         (*((volatile unsigned char *) 0xE0054000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5CMR         (*((volatile unsigned char *) 0xE0054004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5GSR         (*((volatile unsigned char *) 0xE0054008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5ICR         (*((volatile unsigned char *) 0xE005400C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5IER         (*((volatile unsigned char *) 0xE0054010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5BTR         (*((volatile unsigned char *) 0xE0054014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5EWL         (*((volatile unsigned char *) 0xE005401C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5SR          (*((volatile unsigned char *) 0xE0054020))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5RFS         (*((volatile unsigned char *) 0xE0054024))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5RDA         (*((volatile unsigned char *) 0xE0054028))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5RDB         (*((volatile unsigned char *) 0xE005402C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TFI1        (*((volatile unsigned char *) 0xE0054030))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TID1        (*((volatile unsigned char *) 0xE0054034))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDA1        (*((volatile unsigned char *) 0xE0054038))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDB1        (*((volatile unsigned char *) 0xE005403C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TFI2        (*((volatile unsigned char *) 0xE0054040))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TID2        (*((volatile unsigned char *) 0xE0054044))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDA2        (*((volatile unsigned char *) 0xE0054048))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDB2        (*((volatile unsigned char *) 0xE005404C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TFI3        (*((volatile unsigned char *) 0xE0054050))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TID3        (*((volatile unsigned char *) 0xE0054054))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDA3        (*((volatile unsigned char *) 0xE0054058))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CAN5TDB3        (*((volatile unsigned char *) 0xE005405C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CAN6MOD         (*((volatile unsigned char *) 0xE0058000))	/* lpc2292\lpc2294 only */
#define CAN6CMR         (*((volatile unsigned char *) 0xE0058004))	/* lpc2292\lpc2294 only */
#define CAN6GSR         (*((volatile unsigned char *) 0xE0058008))	/* lpc2292\lpc2294 only */
#define CAN6ICR         (*((volatile unsigned char *) 0xE005800C))	/* lpc2292\lpc2294 only */
#define CAN6IER         (*((volatile unsigned char *) 0xE0058010))	/* lpc2292\lpc2294 only */
#define CAN6BTR         (*((volatile unsigned char *) 0xE0058014))	/* lpc2292\lpc2294 only */
#define CAN6EWL         (*((volatile unsigned char *) 0xE005801C))	/* lpc2292\lpc2294 only */
#define CAN6SR          (*((volatile unsigned char *) 0xE0058020))	/* lpc2292\lpc2294 only */
#define CAN6RFS         (*((volatile unsigned char *) 0xE0058024))	/* lpc2292\lpc2294 only */
#define CAN6RDA         (*((volatile unsigned char *) 0xE0058028))	/* lpc2292\lpc2294 only */
#define CAN6RDB         (*((volatile unsigned char *) 0xE005802C))	/* lpc2292\lpc2294 only */
#define CAN6TFI1        (*((volatile unsigned char *) 0xE0058030))	/* lpc2292\lpc2294 only */
#define CAN6TID1        (*((volatile unsigned char *) 0xE0058034))	/* lpc2292\lpc2294 only */
#define CAN6TDA1        (*((volatile unsigned char *) 0xE0058038))	/* lpc2292\lpc2294 only */
#define CAN6TDB1        (*((volatile unsigned char *) 0xE005803C))	/* lpc2292\lpc2294 only */
#define CAN6TFI2        (*((volatile unsigned char *) 0xE0058040))	/* lpc2292\lpc2294 only */
#define CAN6TID2        (*((volatile unsigned char *) 0xE0058044))	/* lpc2292\lpc2294 only */
#define CAN6TDA2        (*((volatile unsigned char *) 0xE0058048))	/* lpc2292\lpc2294 only */
#define CAN6TDB2        (*((volatile unsigned char *) 0xE005804C))	/* lpc2292\lpc2294 only */
#define CAN6TFI3        (*((volatile unsigned char *) 0xE0058050))	/* lpc2292\lpc2294 only */
#define CAN6TID3        (*((volatile unsigned char *) 0xE0058054))	/* lpc2292\lpc2294 only */
#define CAN6TDA3        (*((volatile unsigned char *) 0xE0058058))	/* lpc2292\lpc2294 only */
#define CAN6TDB3        (*((volatile unsigned char *) 0xE005805C))	/* lpc2292\lpc2294 only */

#define CANTxSR         (*((volatile unsigned char *) 0xE0040000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANRxSR         (*((volatile unsigned char *) 0xE0040004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANMSR          (*((volatile unsigned char *) 0xE0040008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */

#define CANAFMR         (*((volatile unsigned char *) 0xE003C000))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANSFF_sa       (*((volatile unsigned char *) 0xE003C004))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANSFF_GRP_sa   (*((volatile unsigned char *) 0xE003C008))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANEFF_sa       (*((volatile unsigned char *) 0xE003C00C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANEFF_GRP_sa   (*((volatile unsigned char *) 0xE003C010))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANENDofTable   (*((volatile unsigned char *) 0xE003C014))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANLUTerrAd     (*((volatile unsigned char *) 0xE003C018))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */
#define CANLUTerr       (*((volatile unsigned char *) 0xE003C01C))	/* lpc2119\lpc2129\lpc2292\lpc2294 only */


/* Timer 0 */
/* 定时器0的特殊寄存器 */
#define T0IR            (*((volatile unsigned int *) 0xE0004000))
#define T0TCR           (*((volatile unsigned int *) 0xE0004004))
#define T0TC            (*((volatile unsigned int *) 0xE0004008))
#define T0PR            (*((volatile unsigned int *) 0xE000400C))
#define T0PC            (*((volatile unsigned int *) 0xE0004010))
#define T0MCR           (*((volatile unsigned int *) 0xE0004014))
#define T0MR0           (*((volatile unsigned int *) 0xE0004018))
#define T0MR1           (*((volatile unsigned int *) 0xE000401C))
#define T0MR2           (*((volatile unsigned int *) 0xE0004020))
#define T0MR3           (*((volatile unsigned int *) 0xE0004024))
#define T0CCR           (*((volatile unsigned int *) 0xE0004028))
#define T0CR0           (*((volatile unsigned int *) 0xE000402C))
#define T0CR1           (*((volatile unsigned int *) 0xE0004030))
#define T0CR2           (*((volatile unsigned int *) 0xE0004034))
#define T0CR3           (*((volatile unsigned int *) 0xE0004038))
#define T0EMR           (*((volatile unsigned int *) 0xE000403C))

/* Timer 1 */
/* 定时器1的特殊寄存器 */
#define T1IR            (*((volatile unsigned int *) 0xE0008000))
#define T1TCR           (*((volatile unsigned int *) 0xE0008004))
#define T1TC            (*((volatile unsigned int *) 0xE0008008))
#define T1PR            (*((volatile unsigned int *) 0xE000800C))
#define T1PC            (*((volatile unsigned int *) 0xE0008010))
#define T1MCR           (*((volatile unsigned int *) 0xE0008014))
#define T1MR0           (*((volatile unsigned int *) 0xE0008018))
#define T1MR1           (*((volatile unsigned int *) 0xE000801C))
#define T1MR2           (*((volatile unsigned int *) 0xE0008020))
#define T1MR3           (*((volatile unsigned int *) 0xE0008024))
#define T1CCR           (*((volatile unsigned int *) 0xE0008028))
#define T1CR0           (*((volatile unsigned int *) 0xE000802C))
#define T1CR1           (*((volatile unsigned int *) 0xE0008030))
#define T1CR2           (*((volatile unsigned int *) 0xE0008034))
#define T1CR3           (*((volatile unsigned int *) 0xE0008038))
#define T1EMR           (*((volatile unsigned int *) 0xE000803C))

/* Pulse Width Modulator (PWM) */
/* 脉宽调制器的特殊寄存器 */
#define PWMIR           (*((volatile unsigned int *) 0xE0014000))
#define PWMTCR          (*((volatile unsigned int *) 0xE0014004))
#define PWMTC           (*((volatile unsigned int *) 0xE0014008))
#define PWMPR           (*((volatile unsigned int *) 0xE001400C))
#define PWMPC           (*((volatile unsigned int *) 0xE0014010))
#define PWMMCR          (*((volatile unsigned int *) 0xE0014014))
#define PWMMR0          (*((volatile unsigned int *) 0xE0014018))
#define PWMMR1          (*((volatile unsigned int *) 0xE001401C))
#define PWMMR2          (*((volatile unsigned int *) 0xE0014020))
#define PWMMR3          (*((volatile unsigned int *) 0xE0014024))
#define PWMMR4          (*((volatile unsigned int *) 0xE0014040))
#define PWMMR5          (*((volatile unsigned int *) 0xE0014044))
#define PWMMR6          (*((volatile unsigned int *) 0xE0014048))
#define PWMPCR          (*((volatile unsigned int *) 0xE001404C))
#define PWMLER          (*((volatile unsigned int *) 0xE0014050))

/* A/D CONVERTER */
/* A/D转换器 */
#define ADCR            (*((volatile unsigned int *) 0xE0034000))	/* no in lpc210x */
#define ADDR            (*((volatile unsigned int *) 0xE0034004))	/* no in lpc210x */

/* Real Time Clock */
/* 实时时钟的特殊寄存器 */
#define ILR             (*((volatile unsigned char *) 0xE0024000))
#define CTC             (*((volatile unsigned short*) 0xE0024004))
#define CCR             (*((volatile unsigned char *) 0xE0024008))
#define CIIR            (*((volatile unsigned char *) 0xE002400C))
#define AMR             (*((volatile unsigned char *) 0xE0024010))
#define CTIME0          (*((volatile unsigned int *) 0xE0024014))
#define CTIME1          (*((volatile unsigned int *) 0xE0024018))
#define CTIME2          (*((volatile unsigned int *) 0xE002401C))
#define SEC             (*((volatile unsigned char *) 0xE0024020))
#define MIN             (*((volatile unsigned char *) 0xE0024024))
#define HOUR            (*((volatile unsigned char *) 0xE0024028))
#define DOM             (*((volatile unsigned char *) 0xE002402C))
#define DOW             (*((volatile unsigned char *) 0xE0024030))
#define DOY             (*((volatile unsigned short*) 0xE0024034))
#define MONTH           (*((volatile unsigned char *) 0xE0024038))
#define YEAR            (*((volatile unsigned short*) 0xE002403C))
#define ALSEC           (*((volatile unsigned char *) 0xE0024060))
#define ALMIN           (*((volatile unsigned char *) 0xE0024064))
#define ALHOUR          (*((volatile unsigned char *) 0xE0024068))
#define ALDOM           (*((volatile unsigned char *) 0xE002406C))
#define ALDOW           (*((volatile unsigned char *) 0xE0024070))
#define ALDOY           (*((volatile unsigned short*) 0xE0024074))
#define ALMON           (*((volatile unsigned char *) 0xE0024078))
#define ALYEAR          (*((volatile unsigned short*) 0xE002407C))
#define PREINT          (*((volatile unsigned short*) 0xE0024080))
#define PREFRAC         (*((volatile unsigned short*) 0xE0024084))

/* Watchdog */
/* 看门狗的特殊寄存器 */
#define WDMOD           (*((volatile unsigned char *) 0xE0000000))
#define WDTC            (*((volatile unsigned int *) 0xE0000004))
#define WDFEED          (*((volatile unsigned char *) 0xE0000008))
#define WDTV            (*((volatile unsigned int *) 0xE000000C))

/* Define firmware Functions */
/* 定义固件函数 */
#define rm_init_entry()             ((void (*)())(0x7fffff91))()
#define rm_undef_handler()          ((void (*)())(0x7fffffa0))()
#define rm_prefetchabort_handler()  ((void (*)())(0x7fffffb0))()
#define rm_dataabort_handler()      ((void (*)())(0x7fffffc0))()
#define rm_irqhandler()             ((void (*)())(0x7fffffd0))()
#define rm_irqhandler2()            ((void (*)())(0x7fffffe0))()
#define iap_entry(a, b)             ((void (*)())(0x7ffffff1))(a, b)


struct lpc_timers
{

	unsigned int ir;	// 
	unsigned int tcr;	// 
	unsigned int tc;	// 
	unsigned int pr;	// 
	unsigned int pc;	// 
	unsigned int mcr;	// 
	unsigned int mr0;	// 
	unsigned int mr1;	// 
	unsigned int mr2;	// 
	unsigned int mr3;	// 
	unsigned int ccr;	// 
	unsigned int cr0;	// 
	unsigned int cr1;	// 
	unsigned int cr2;	// 
	unsigned int cr3;	// 
	unsigned int emr;	// 
};

#define IRQ_WD		0
//#define IRQ_SWI               1
//#define IRQ_USART0    2
//#define IRQ_USART1    3
//#define IRQ_TC0               (1<<4)
#define IRQ_TC0		0x10
#define IRQ_TC1		5
#define IRQ_UART0	(1 << 6)
#define IRQ_UART1	7
#define IRQ_PWM		8
#define IRQ_I2C		9
#define IRQ_SPI0		10
#define IRQ_SPI1		11
#define IRQ_PLL		12
#define IRQ_RTC		13
#define IRQ_EXT0		14
#define IRQ_EXT1		15
#define IRQ_EXT2		16
#define IRQ_EXT3		17
#define IRQ_AD		18

#endif
