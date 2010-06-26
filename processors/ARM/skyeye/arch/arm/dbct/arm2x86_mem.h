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

#ifndef _ARM2X86_MEM_H_
#define _ARM2X86_MEM_H_

#define LOADWORD_ALIGN(addr, data)	((data >> ((addr & 3) << 3)) | (data << (32 - ((addr & 3) << 3))))

extern op_table_t op_ldr_T0_T1;
extern op_table_t op_ldr_T2_T1;
extern op_table_t op_ldrh_T0_T1;
extern op_table_t op_ldrb_T0_T1;
extern op_table_t op_ldrb_T2_T1;

extern op_table_t op_str_T0_T1;
extern op_table_t op_strh_T0_T1;
extern op_table_t op_strb_T0_T1;

extern op_table_t op_ldm_T1_T0;
extern op_table_t op_stm_T1_T0;

extern op_table_t op_ldm_user_T1_T0;
extern op_table_t op_stm_user_T1_T0;

extern op_table_t op_signextend_halfword_T0;
extern op_table_t op_signextend_byte_T0;

//teawater add for xscale(arm v5) 2005.09.19------------------------------------
extern op_table_t op_signextend_halfword_T1;
extern op_table_t op_signextend_byte_T1;

extern op_table_t op_ldrd_T0_T2_T1;
extern op_table_t op_strd_T0_T2_T1;
//AJ2D--------------------------------------------------------------------------

extern int arm2x86_mem_init ();

static __inline__ void
gen_op_add_datah_offset (ARMul_State * state, uint8_t ** tbpp, int *plen,
			 ARMword insn)
{
	if (insn & (1 << 22)) {
		//immediate
		int val = (insn & 0xf) | ((insn >> 4) & 0xf0);

		if (!(insn & (1 << 23)))
			val = -val;
		if (val != 0)
			gen_op_addl_T1_im (state, tbpp, plen, (ARMword) val);
	}
	else {
		//register
		ARMword rm = (insn) & 0xf;

		gen_op_movl_Tx_reg (state, tbpp, plen, 2, rm);
		if (!(insn & (1 << 23)))
			GEN_OP (*tbpp, *plen, op_subl_T1_T2);
		else
			GEN_OP (*tbpp, *plen, op_addl_T1_T2);
	}
}

static __inline__ void
gen_op_add_data_offset (ARMul_State * state, uint8_t ** tbpp, int *plen,
			ARMword insn)
{
	if (!(insn & (1 << 25))) {
		//immediate
		int val = insn & 0xfff;

		if (!(insn & (1 << 23)))	//U
			val = -val;
		if (val != 0)
			gen_op_addl_T1_im (state, tbpp, plen, (ARMword) val);
	}
	else {
		//register
		ARMword rm = (insn) & 0xf;
		ARMword shift = (insn >> 7) & 0x1f;

		gen_op_movl_Tx_reg (state, tbpp, plen, 2, rm);
		if (shift != 0)
			gen_op_shift_T2_im (state, tbpp, plen,
					    ((insn >> 5) & 3), shift);
		if (!(insn & (1 << 23)))	//U
			GEN_OP (*tbpp, *plen, op_subl_T1_T2);
		else
			GEN_OP (*tbpp, *plen, op_addl_T1_T2);
	}
}

#endif //_ARM2X86_MEM_H_
