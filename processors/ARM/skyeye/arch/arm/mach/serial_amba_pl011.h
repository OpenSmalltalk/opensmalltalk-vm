/*
 *  linux/include/asm-arm/hardware/serial_amba_pl011.h
 *
 *  Internal header file for AMBA PrimeCell PL011 serial ports
 *
 *  Copyright (C) 2002 Lineo, Inc.
 *
 *  Based on serial_amba.h, which is:
 *    Copyright (C) ARM Limited
 *    Copyright (C) 2000 Deep Blue Solutions Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#ifndef ASM_ARM_HARDWARE_SERIAL_AMBA_PL011_H
#define ASM_ARM_HARDWARE_SERIAL_AMBA_PL011_H

/* -------------------------------------------------------------------------------
 *  From AMBA UART (PL011) TRM
 * -------------------------------------------------------------------------------
 *  UART Register Offsets.
 */
#define AMBA_UARTDR                     0x00	/*  Data read or written from the interface. */
#define AMBA_UARTRSR                    0x04	/*  Receive status register (Read). */
#define AMBA_UARTECR                    0x04	/*  Error clear register (Write). */


#define AMBA_UARTFR                     0x18	/*  Flag register (Read only). */
#define AMBA_UARTILPR                   0x20	/*  IrDA low power counter register. */
#define AMBA_UARTIBRD                   0x24	/*  Integer baud rate divisor. */
#define AMBA_UARTFBRD                   0x28	/*  Fractional baud rate divisor. */
#define AMBA_UARTLCR_H                  0x2C	/*  Line control register, high byte. */
#define AMBA_UARTCR                     0x30	/*  Control register. */
#define AMBA_UARTIFLS                   0x34	/*  Interrupt FIFO level select. */
#define AMBA_UARTIMSC                   0x38	/*  Interrupt Mask Set/Clear. */
#define AMBA_UARTRIS                    0x3C	/*  Raw Interrupt status register (Read). */
#define AMBA_UARTMIS                    0x40	/*  Masked Interrupt status register (Read). */
#define AMBA_UARTICR                    0x44	/*  Interrupt clear register (Write). */

#define AMBA_UARTRSR_OE                 0x0800	/*  Overrun error */
#define AMBA_UARTRSR_BE                 0x0400	/*  Break error   */
#define AMBA_UARTRSR_PE                 0x0200	/*  Parity error  */
#define AMBA_UARTRSR_FE                 0x0100	/*  framing error */

#define AMBA_UARTFR_TXFF                0x20	/* Tx FIFO full   */
#define AMBA_UARTFR_RXFE                0x10	/* Rx FIFO empty  */
#define AMBA_UARTFR_BUSY                0x08	/* busy xmitting  */
#define AMBA_UARTFR_DCD                 0x04
#define AMBA_UARTFR_DSR                 0x02
#define AMBA_UARTFR_CTS                 0x01
#define AMBA_UARTFR_TMSK                (AMBA_UARTFR_TXFF + AMBA_UARTFR_BUSY)

/* Interrupt Mask Set/Clear register bits */
#define AMBA_UARTIMSC_RTIM              0x40	/* Rx timeout interrupt mask */
#define AMBA_UARTIMSC_TXIM              0x20	/* Tx interrupt mask */
#define AMBA_UARTIMSC_RXIM              0x10	/* Rx interrupt mask */
#define AMBA_UARTIMSC_DSRMIM            0x08	/* DSR Modem Interrupt mask */
#define AMBA_UARTIMSC_DCDMIM            0x04	/* DCD Modem Interrupt mask */
#define AMBA_UARTIMSC_CTSMIM            0x02	/* CTS Modem Interrupt mask */
#define AMBA_UARTIMSC_RIMIM             0x01	/* RI  Modem Interrupt mask */
/* all modem mask bits */
#define AMBA_UARTIMSC_Modem             (AMBA_UARTIMSC_DSRMIM |AMBA_UARTIMSC_DCDMIM | \
	                                 AMBA_UARTIMSC_CTSMIM |AMBA_UARTIMSC_RIMIM)



/* Control Register bits */

#define AMBA_UARTCR_RTS                 0x800	/* nRTS */
#define AMBA_UARTCR_DTR                 0x400	/* nDTR */
#define AMBA_UARTCR_RXE                 0x200	/* Rx enable */
#define AMBA_UARTCR_TXE                 0x100	/* Tx enable */
#define AMBA_UARTCR_LBE                 0x080	/* Loopback enable */
#define AMBA_UARTCR_SIRLP               0x004	/* IR SIR Low Power Mode */
#define AMBA_UARTCR_SIREN               0x002	/* IR SIR enable */
#define AMBA_UARTCR_UARTEN              0x001	/* UART enable */

#define AMBA_UARTLCR_H_WLEN_8           0x60
#define AMBA_UARTLCR_H_WLEN_7           0x40
#define AMBA_UARTLCR_H_WLEN_6           0x20
#define AMBA_UARTLCR_H_WLEN_5           0x00
#define AMBA_UARTLCR_H_FEN              0x10
#define AMBA_UARTLCR_H_STP2             0x08
#define AMBA_UARTLCR_H_EPS              0x04
#define AMBA_UARTLCR_H_PEN              0x02
#define AMBA_UARTLCR_H_BRK              0x01

/* Raw/Masked Interrupt Status Register bits*/
#define AMBA_UART_IS_RT                 0x40
#define AMBA_UART_IS_TX                 0x20
#define AMBA_UART_IS_RX                 0x10
#define AMBA_UART_IS_DSR                0x08
#define AMBA_UART_IS_DCD                0x04
#define AMBA_UART_IS_CTS                0x02
#define AMBA_UART_IS_RI                 0x01
#define AMBA_UART_IS_MI                 (AMBA_UART_IS_DSR | AMBA_UART_IS_DCD | \
	                                 AMBA_UART_IS_CTS | AMBA_UART_IS_RI )

#define AMBA_UARTRSR_ANY	(AMBA_UARTRSR_OE|AMBA_UARTRSR_BE|AMBA_UARTRSR_PE|AMBA_UARTRSR_FE)
#define AMBA_UARTFR_MODEM_ANY	(AMBA_UARTFR_DCD|AMBA_UARTFR_DSR|AMBA_UARTFR_CTS)

#endif /*  ASM_ARM_HARDWARE_SERIAL_AMBA_PL011_H */
