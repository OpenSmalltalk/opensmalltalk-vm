
#ifndef __LH79520_H__
#define __LH79520_H__

#define TC1OI		(1<<IRQ_TIMER0)
#define TC2OI		(1<<IRQ_TIMER1)
#define UART1INT	(1<<IRQ_UART1)

#define VIC_IRQStatus	(VIC_BASE+0x000)
#define VIC_IntSelect  	(VIC_BASE+0x00c)
#define VIC_IntEnable	(VIC_BASE+0x010)
#define VIC_IntEnClear	(VIC_BASE+0x014)
#define VIC_VectAddr	(VIC_BASE+0x100)
#define VIC_VectCntl	(VIC_BASE+0x200)

#define RCPC_control		(RCPC_PHYS+0x00)
#define RCPC_idString   	(RCPC_PHYS+0x04)    //Chip ID
#define RCPC_HCLKPrescale	(RCPC_PHYS+0x18)
#define RCPC_periphClkCtrl	(RCPC_PHYS+0x24)
#define RCPC_intClear		(RCPC_PHYS+0x84)
#define RCPC_intConfig		(RCPC_PHYS+0x80)

#define IOCON_MiscMux		(IOCON_PHYS+0x08)
#define IOCON_UARTMux		(IOCON_PHYS+0x10)

#define UARTDR		0x000	//Data read from or written to the UART
#define UARTRSR		0x004	//Receive Status Register (when Read).
#define UARTECR		0x004	//Error Clear Register (when Written).

#define UARTFR		0x018	//Flag Register
#define UARTIBRD 	0x024	//Integer Baud Rate Divisor Register
#define UARTFBRD	0x028	//Fractional Baud Rate Divisor Register
#define UARTLCR_H	0x02C	//Line Control Register, HIGH byte
#define UARTCR		0x030	//Control Register
#define UARTIMSC	0x038	//Interrupt Mask Set/Clear
#define UARTMIS		0x040	//Masked Interrupt Status Register
#define UARTICR		0x044	//Interrupt Clear Register

#define AMBA_UARTFR_TXFE    (1<<7)	/* Tx FIFO Empty */

#define TIMER0_LOAD		(TIMER0_PHYS+0x00)
#define TIMER0_VALUE	(TIMER0_PHYS+0x04)
#define TIMER0_CONTROL	(TIMER0_PHYS+0x08)
#define TIMER0_CLEAR	(TIMER0_PHYS+0x0C)

#define TIMER1_LOAD		(TIMER0_PHYS+0x20)
#define TIMER1_VALUE	(TIMER0_PHYS+0x24)
#define TIMER1_CONTROL	(TIMER0_PHYS+0x28)
#define TIMER1_CLEAR	(TIMER0_PHYS+0x2C)

#define TIMER2_CONTROL	(TIMER1_PHYS+0x08)
#define TIMER3_CONTROL	(TIMER1_PHYS+0x28)



#define TIMER_CONTROL_MODE	(1<<6)

#endif //
