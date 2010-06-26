/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/*
 * author teawater <c7code-uc@yahoo.com.cn> <teawater@gmail.com>
 */

#ifndef _ARM2X86_COPROC_H_
#define _ARM2X86_COPROC_H_

extern op_table_t op_ldc_T0_T1;
extern op_table_t op_stc_T0_T1;
extern op_table_t op_mrc_T0_T1;
extern op_table_t op_mcr_T0_T1;
extern op_table_t op_cdp_T0_T1;

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
extern op_table_t op_mar_T0_T1;
extern op_table_t op_mra_T0_T1;
extern op_table_t op_mia_T0_T1;
extern op_table_t op_miaph_T0_T1;
extern op_table_t op_miaxy_T0_T1;
//AJ2D--------------------------------------------------------------------------

extern int arm2x86_coproc_init ();

static __inline__ void
gen_op_add_imm_offset (ARMul_State * state, uint8_t ** tbpp, int *plen,
		       ARMword insn)
{
	int offset = (insn & 0xff) * 4;

	if (!(insn & (1 << 23)))	//U
		offset = -offset;
	if (offset != 0)
		gen_op_addl_T1_im (state, tbpp, plen, (ARMword) offset);
}

#endif //_ARM2X86_COPROC_H_
