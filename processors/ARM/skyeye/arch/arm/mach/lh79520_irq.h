/*
 * lh79520_vic.h - LH79520 Virtual Interrupt Controller channel definitions
 * Copyright (C) 2006 Dwayne C. Litzenberger <dlitz@dlitz.net>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 * 
 */

#ifndef ARCH_ARM_MACH_LH79520_IRQ_H
#define ARCH_ARM_MACH_LH79520_IRQ_H

// Virtual Interrupt Controller (VIC) Channels
// Note that these aren't really IRQs (ARM only has a single IRQ line), but
// it's easier for people to understand if we call them IRQs.
#define IRQ_EXTINT0         0   // External Interrupt 0
#define IRQ_EXTINT1         1   // External Interrupt 1
#define IRQ_EXTINT2         2   // External Interrupt 2
#define IRQ_EXTINT3         3   // External Interrupt 3
#define IRQ_EXTINT4         4   // External Interrupt 4
#define IRQ_EXTINT5         5   // External Interrupt 5
#define IRQ_EXTINT6         6   // External Interrupt 6
#define IRQ_EXTINT7         7   // External Interrupt 7
#define IRQ_SPARE0          8   // Spare Internal Interrupt 0
#define IRQ_COMRX           9   // COMRx Interrupt (intended for debugger)
#define IRQ_COMTX           10  // COMTx Interrupt (intended for debugger)
#define IRQ_SSPRXTO         11  // Sync. Serial Port Rx Timeout for DMA xfer
#define IRQ_CLCD            12  // Color LCD Combined Interrupt
#define IRQ_SSPTXINTR       13  // Sync. Serial Port Tx Interrupt
#define IRQ_SSPRXINTR       14  // Sync. Serial Port Rx Interrupt
#define IRQ_SSPRORINTR      15  // Sync. Serial Port Rx Overrun Interrupt
#define IRQ_SSPINTR         16  // Sync. Serial Port Combined Interrupt
#define IRQ_TIMER0          17  // Timer 0 Interrupt
#define IRQ_TIMER1          18  // Timer 1 Interrupt
#define IRQ_TIMER2          19  // Timer 2 Interrupt
#define IRQ_TIMER3          20  // Timer 3 Interrupt
#define IRQ_UART0RX         21  // UART0 Rx Combined Interrupt
#define IRQ_UART0TX         22  // UART0 Tx Combined Interrupt
#define IRQ_UART0           23  // UART0 Combined Interrupt
#define IRQ_UART1           24  // UART1 Combined Interrupt
#define IRQ_UART2           25  // UART2 Combined Interrupt
#define IRQ_DMA             26  // DMA Combined Interrupt
#define IRQ_SPARE4          27  // Space Internal Interrupt 4
#define IRQ_SPARE5          28  // Space Internal Interrupt 5
#define IRQ_SPARE6          29  // Space Internal Interrupt 6
#define IRQ_RTC             30  // Real Time Clock Interrupt
#define IRQ_WDT             31  // Watchdog Timer Interrupt


#endif /* ARCH_ARM_MACH_LH79520_IRQS_H */
/* vim:set tabstop=8 shiftwidth=4 softtabstop=4 expandtab: */
