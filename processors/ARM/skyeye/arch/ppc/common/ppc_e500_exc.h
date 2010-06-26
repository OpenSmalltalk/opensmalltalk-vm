/*
        ppc_e500_exc.h - necessary definition for e500 exception
        Copyright (C) 2003-2007 Skyeye Develop Group
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
 * 07/04/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */
/*
IVOR0  Critical Input
IVOR1  Machine Check
IVOR2  Data Storage
IVOR3  Instruction Storage
IVOR4  External Input
IVOR5  Alignment
IVOR6  Program
IVOR7  Floating-Point Unavailable
IVOR8  System Call
IVOR9  Auxiliary Processor Unavailable
IVOR10 Decrementer
IVOR11 Fixed-Interval Timer Interrupt
IVOR12 Watchdog Timer Interrupt
IVOR13 Data TLB Error
IVOR14 Instruction TLB Error
IVOR15 Debug
*/
enum {
	CRI_INPUT = 0,
	MACH_CHECK,
	DATA_ST,
	INSN_ST,
	EXT_INT,
	ALIGN,
	PROG,
	FP_UN,
	SYSCALL,
	AP_UN,
	DEC,
	FIT,
	WD,
	DATA_TLB,
	INSN_TLB,
	DEBUG
};
