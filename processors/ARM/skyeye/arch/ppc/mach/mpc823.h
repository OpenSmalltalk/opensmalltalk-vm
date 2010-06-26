/*
        mpc823.h - register definition for MPC823
        Copyright (C) 2006 Skyeye Develop Group
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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

uint32_t mpc823_mem_map[64 * 1024];
enum{	
/* System Interface Unit */
	SIUMCR = 0,
	SYPCR,
	SWSR = 0xe,
	SIPED = 0x10,
	SIMASK,
	SIEL,
	SIVEC,
	TESR,
	SDCR = 0x30,
/* PCMICA */
/* Memory Controller */
/* System Integration Timers */
/* CLOCKS AND RESET */
/* System Integration Timer Keys */
/* Clocks and Reset Keys */
/* Video Controller */
/* LCD Controller */
/* I2C Controller */
/* DMA Controller */
/* Communications Processor Module Interrupt Controller */
/* Parallel Ports */
/* CPM Timers */
/* Communication Processor Module */
/* Baud Rate Generators */
/* Universal Serial Bus */
/* Serial Communication Controller 2 */
/* Serial Communication Controller 3 */
/* Serial Management Controller 1 */
/* Serial Management Controller 2 */
/* Serial Peripheral Interface */
/* Port B */
/* Serial Interface */
/* Specialized RAM */
/* Dual-port RAM */

}
enum{
	PSMR = 0xa28,
	SCCE = 0xa30,
	SCCM = 0xa24, /* SCCX UART mask register */
	SCCS = 0xa37, /* SCCX status register */
	
}
enum{
	RBASE = 0x00;
	TBASE = 0x02;
	RFCR  = 0x04;
	TFCR  = 0x05;
	MRBLR = 0x06;
	RSTATE= 0x08;
	RPTR  = 0x0c;
	RBPTR = 0x10;
	RCNT  = 0x12;
	RTMP  = 0x14;
	TSTATE= 0x18;
	TPTR  = 0x1C;
	TBPTR = 0x20;
	TCNT  = 0x22;
	TTMP  = 0x24;
	RCRC  = 0x28;
	TCRC  = 0x2c;
}
