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

#ifndef _ARM2X86_OTHER_H_
#define _ARM2X86_OTHER_H_

extern op_table_t op_addq_T0_T1_eax_T2;
extern op_table_t op_b_offset;
extern op_table_t op_bl_offset;
//teawater add check thumb 2005.07.21-------------------------------------------
extern op_table_t op_bx_T1;
extern op_table_t op_blx_T1;
//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
extern op_table_t op_hi_T0;
extern op_table_t op_hi_T1;
extern op_table_t op_lo_T0;
extern op_table_t op_lo_T1;
extern op_table_t op_smlalxy_T2_T1_T0;
extern op_table_t op_smlawy_T2_T1_T0;
extern op_table_t op_smulwy_T0_T1;
//AJ2D--------------------------------------------------------------------------

//teawater change for local tb branch directly jump 2005.10.17------------------
extern op_table_t	op_local_b_offset;
//AJ2D--------------------------------------------------------------------------

typedef void (arm2x86_get_other_op_t) (ARMul_State * state, ARMword insn,
				       uint8_t ** tbpp, int *plen);
extern arm2x86_get_other_op_t *arm2x86_get_other_op[16];

extern int arm2x86_other_init ();

static __inline__ void
gen_op_mrs (ARMul_State * state, uint8_t ** tbpp, int *plen, ARMword insn)
{
	if ((insn >> 22) & 1) {
		//spsr
		GEN_OP (*tbpp, *plen, op_mrs_T0_spsr);
	}
	else {
		//cpsr
		GEN_OP (*tbpp, *plen, op_mrs_T0_cpsr);
	}
	gen_op_movl_reg_Tx (state, tbpp, plen, ((insn >> 12) & 0xf), 0);
}

static __inline__ void
gen_op_msr (ARMul_State * state, uint8_t ** tbpp, int *plen, ARMword insn)
{
	uint32_t mask = 0;

	//get mask & set it to T0
	if ((insn >> 16) & 1) {
		//control field mask
		mask |= 0xff;
	}
	if ((insn >> 17) & 1) {
		//extension field mask
		mask |= 0xff00;
	}
	if ((insn >> 18) & 1) {
		//status field mask
		mask |= 0xff0000;
	}
	if ((insn >> 19) & 1) {
		//flags field mask
		mask |= 0xff000000;
	}
	if (mask == 0) {
		return;
	}
	gen_op_movl_Tx_im (state, tbpp, plen, 0, mask);

	if ((insn >> 22) & 1) {
		//spsr
		GEN_OP (*tbpp, *plen, op_msr_spsr_T0_T1);
	}
	else {
		//cpsr
		GEN_OP (*tbpp, *plen, op_msr_cpsr_T0_T1);
	}
}

static __inline__ void
gen_op_ldrhstrh (ARMul_State * state, uint8_t ** tbpp, int *plen,
		 ARMword insn, ARMword sh)
{
	ARMword rn, rd;

	rn = (insn >> 16) & 0xf;
	rd = (insn >> 12) & 0xf;
	gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
	if (insn & (1 << 24)) {
		gen_op_add_datah_offset (state, tbpp, plen, insn);
	}
	if (insn & (1 << 20)) {
		if (sh == 1) {
			//ldrh
			GEN_OP (*tbpp, *plen, op_ldrh_T0_T1);
		}
		else if (sh == 2) {
			//ldrsb
			GEN_OP (*tbpp, *plen, op_ldrb_T0_T1);
			GEN_OP (*tbpp, *plen, op_signextend_byte_T0);
		}
		else {
			//ldrsh
			GEN_OP (*tbpp, *plen, op_ldrh_T0_T1);
			GEN_OP (*tbpp, *plen, op_signextend_halfword_T0);
		}
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			gen_op_test_dataabort_im (state, tbpp, plen,
						  op_movl_reg_Tx[0][rd].len);
		}
		gen_op_movl_reg_Tx (state, tbpp, plen, rd, 0);
	}
	else {
//teawater add for xscale(arm v5) 2005.09.15------------------------------------
		if (sh == 1) {
			//strh
			gen_op_movl_Tx_reg (state, tbpp, plen, 0, rd);
			GEN_OP (*tbpp, *plen, op_strh_T0_T1);
		}
		else if (state->is_v5) {
			if (sh == 2 || sh == 3) {
				if (rd >= 14) {
					gen_op_movl_trap_im_use_T2 (state,
								    tbpp,
								    plen,
								    TRAP_UNPREDICTABLE);
					state->trap = 1;
					return;
				}
				if (sh == 2) {
					//ldrd
					GEN_OP (*tbpp, *plen,
						op_ldrd_T0_T2_T1);
					if (state->abort_model > 1) {
						gen_op_test_dataabort_im
							(state, tbpp, plen,
							 op_movl_reg_Tx[0]
							 [rd].len +
							 op_movl_reg_Tx[2][rd
									   +
									   1].
							 len);
					}
					gen_op_movl_reg_Tx (state, tbpp, plen,
							    rd, 0);
					gen_op_movl_reg_Tx (state, tbpp, plen,
							    rd + 1, 2);
				}
				else {
					//strd
					gen_op_movl_Tx_reg (state, tbpp, plen,
							    0, rd);
					gen_op_movl_Tx_reg (state, tbpp, plen,
							    2, rd + 1);
					GEN_OP (*tbpp, *plen,
						op_strd_T0_T2_T1);
				}
			}
			else {
				//undef
				gen_op_movl_trap_im_use_T2 (state, tbpp, plen,
							    TRAP_INSN_UNDEF);
				state->trap = 1;
				return;
			}
		}
		else {
			//undef
			gen_op_movl_trap_im_use_T2 (state, tbpp, plen,
						    TRAP_INSN_UNDEF);
			state->trap = 1;
			return;
		}
//AJ2D--------------------------------------------------------------------------
	}
	if (!(insn & (1 << 24))) {
		gen_op_add_datah_offset (state, tbpp, plen, insn);
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	else if (insn & (1 << 21)) {
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	//if (!state->is_XScale) {
	if (state->abort_model > 1) {
		GEN_OP (*tbpp, *plen, op_test_dataabort_ret);
	}
}

static __inline__ void
gen_op_b_offset (ARMul_State * state, uint8_t ** tbpp, int *plen,
		 ARMword offset)
{
	GEN_OP (*tbpp, *plen, op_b_offset);
	offset += 4;
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &offset, sizeof(offset));
		*tbpp += sizeof(offset);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (offset);
	state->trap = 1;
}

static __inline__ void
gen_op_bl_offset (ARMul_State * state, uint8_t ** tbpp, int *plen,
		  ARMword offset)
{
	GEN_OP (*tbpp, *plen, op_bl_offset);
	offset += 4;
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &offset, sizeof(offset));
		*tbpp += sizeof(offset);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (offset);
	state->trap = 1;
}

#endif //_ARM2X86_OTHER_H_
