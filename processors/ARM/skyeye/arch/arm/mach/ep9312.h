/*
	ep9312.h - definitions of "ep9312" machine  for skyeye
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
 * 11/04/2004  	initial version
 *		define TC struct
 *		walimis <wlm@student.dlut.edu.cn> 
 * */

#ifndef __EP931200_H_
#define __EP931200_H_

/********************************************
* Timer Count definition
********************************************/
#define EP9312_TC_BASE1       (0x80810000)
#define EP9312_TC_BASE2       (0x80810020)
#define EP9312_TC_BASE3       (0x80810080)
#define EP9312_TC_BASE4       (0x80810060)
#define EP9312_TC_SIZE       	0x10

/* Timer Count I/O register
 * */
#define TC_LOAD          	0x0
#define TC_VALUE       		0x4
#define TC_CTL         		0x8
#define TC_CLEAR       		0xC

#define TC_VALUELOW          	0x0
#define TC_VALUEHIGH  		0x4

/* TC interrupt use "sys" interrupt
 * */
#define EP9312_ID_SYS    (0x1 << 1)	// System Peripheral


#define TC_CTL_CLKSEL          (0x1 <<  3)	// (TC) Control: CLKSEL bit
#define TC_CTL_MODE            (0x1 <<  6)	// (TC) Control: Mode bit
#define TC_CTL_ENABLE          (0x1 <<  7)	// (TC) Control: Enable bit

struct ep9312_tc_io
{
	/* I/O register
	 * */
	u32 load;		/* Load Register */
	u32 value;		/* Value Register */
	u32 ctl;		/* Control Register */
	u32 clear;		/* Clear Register */

	u32 mod_value;		/* TC1 and TC2: 0xffff; TC3: 0xffffffff */

};



/********************************************
* UART definition
********************************************/
/* I/O register Offset
 * */
#define UART_DR                  0x00
#define UART_RSR                 0x04	/* Read */
#define UART_ECR                 0x04	/* Write */
#define UART_CR_H                0x08
#define UART_CR_M                0x0C
#define UART_CR_L                0x10
#define UART_CR                  0x14
#define UART_FR                  0x18
#define UART_IIR                 0x1C	/* Read */
#define UART_ICR                 0x1C	/* Write */
#define UART_ILPR                0x20
#define UART_DMACR               0x28
#define UART_TCR                 0x80
#define UART_TISR                0x88
#define UART_TOCR                0x8C
#define UART_TMR                 0x84
#define UART_MCR                 0x100	/* Modem Control Reg */
#define UART_MSR                 0x104	/* Modem Status Reg */

#define UART_HDLCCR              0x20C	/* HDLC Registers */
#define UART_HDLCAMV             0x210	/* HDLC Registers */
#define UART_HDLCAMSK            0x214	/* HDLC Registers */
#define UART_HDLCCRIB            0x218	/* HDLC Registers */
#define UART_HDLCSR              0x21C	/* HDLC Registers */

/* default base address 
 * */

#define EP9312_UART_BASE1       (0x808C0000)
#define EP9312_UART_BASE2       (0x808D0000)
#define EP9312_UART_BASE3       (0x808E0000)

#define EP9312_UART_SIZE	  0x10000

struct ep9312_uart_io
{
	/* I/O register
	 * */
	u32 dr;
	u32 rsr;
	u32 ecr;
	u32 cr_h;
	u32 cr_m;
	u32 cr_l;
	u32 cr;
	u32 fr;
	u32 iir;
	u32 icr;
	u32 ilpr;
	u32 dmacr;
	u32 tcr;
	u32 tisr;
	u32 tocr;
	u32 tmr;
	u32 mcr;
	u32 msr;

	u32 sysflg;
};


#endif /*__EP931200_H_ */
