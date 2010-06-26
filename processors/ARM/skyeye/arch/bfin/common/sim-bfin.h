/* Common target dependent code for GDB on BFIN systems.
   Copyright 2002, 2003 Free Software Foundation, Inc.

   This file is part of GDB.

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
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* Register numbers of various important registers.  Note that some of
   these values are "real" register numbers, and correspond to the
   general registers of the machine, and some are "phony" register
   numbers which are too large to be actual register numbers as far as
   the user is concerned but do serve to get the desired values when
   passed to read_register.  */

enum gdb_regnum
{
	BFIN_SYSCFG_REGNUM = 0,
	//BFIN_ORIGR0_REGNUM, 
	BFIN_R0_REGNUM,
	BFIN_R1_REGNUM,
	BFIN_R2_REGNUM,
	BFIN_R3_REGNUM,
	BFIN_R4_REGNUM,
	BFIN_R5_REGNUM,
	BFIN_R6_REGNUM,
	BFIN_R7_REGNUM,
	BFIN_P0_REGNUM,
	BFIN_P1_REGNUM,
	BFIN_P2_REGNUM,
	BFIN_P3_REGNUM,
	BFIN_P4_REGNUM,
	BFIN_P5_REGNUM,
	BFIN_FP_REGNUM,
	BFIN_SP_REGNUM,
	BFIN_I0_REGNUM,
	BFIN_I1_REGNUM,
	BFIN_I2_REGNUM,
	BFIN_I3_REGNUM,
	BFIN_M0_REGNUM,
	BFIN_M1_REGNUM,
	BFIN_M2_REGNUM,
	BFIN_M3_REGNUM,
	BFIN_L0_REGNUM,
	BFIN_L1_REGNUM,
	BFIN_L2_REGNUM,
	BFIN_L3_REGNUM,
	BFIN_B0_REGNUM,
	BFIN_B1_REGNUM,		/* START MODIFIER REGISTER */
	BFIN_B2_REGNUM,		/* END MODIFIER REGISTER */
	BFIN_B3_REGNUM,
	BFIN_A0_DOT_X_REGNUM,
	BFIN_AO_DOT_W_REGNUM,
	BFIN_A1_DOT_X_REGNUM,
	BFIN_A1_DOT_W_REGNUM,
	BFIN_LC0_REGNUM,
	BFIN_LC1_REGNUM,
	BFIN_LT0_REGNUM,
	BFIN_LT1_REGNUM,
	BFIN_LB0_REGNUM,
	BFIN_LB1_REGNUM,
	BFIN_ASTAT_REGNUM,
	BFIN_RESERVED_REGNUM,
	BFIN_RETS_REGNUM,	/* Subroutine address register */
	BFIN_PC_REGNUM,		/*actually RETI pc will be in ORIG_PC */
	BFIN_RETX_REGNUM,
	BFIN_RETN_REGNUM,
	BFIN_RETE_REGNUM,
	BFIN_SEQSTAT_REGNUM,
	BFIN_IPEND_REGNUM,	/* Subroutine address register */
	BFIN_ORIGPC_REGNUM,	/* Subroutine address register */
	BFIN_EXTRA1,		/* Extra "registers" for hacks 1. address of .text */
	BFIN_EXTRA2,
	BFIN_EXTRA3,

	// LAST ENTRY SHOULD NOT BE CHANGED
	BFIN_NUM_REGS		/* 0 index, so this entry is size */
};
