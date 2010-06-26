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

#include "armdefs.h"
#include "arm2x86_self.h"

uint8_t *
get_op_addq_T0_T1_eax_T2 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addq_T0_T1_eax_T2");
	__asm__ __volatile__ ("addl	%eax, %" AREG_T0);
	__asm__ __volatile__ ("adcl	%" AREG_T2 ", %" AREG_T1);
	OP_END ("get_op_addq_T0_T1_eax_T2");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_b_offset (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_b_offset");
	st->Reg[15] += INT32_MAX;
	OP_END ("get_op_b_offset");
	*len = end - begin;
	if (*len <= sizeof (INT32_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}

	return ((uint8_t *) begin);
}

uint8_t *
get_op_bl_offset (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_bl_offset");
	//st->Reg[14] = st->Reg[15] + 4;
	st->Reg[14] = st->Reg[15];
	wmb ();
	st->Reg[15] += INT32_MAX;
	OP_END ("get_op_bl_offset");
	*len = end - begin;
	if (*len <= sizeof (INT32_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}

	return ((uint8_t *) begin);
}

//teawater add check thumb 2005.07.21-------------------------------------------
uint8_t *
get_op_bx_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_bx_T1");
	if (T1 & 1) {
		//thumb XXX
		st->TFlag = 1;
		st->Reg[15] = (T1 & 0xfffffffe) + 2;
		st->trap = TRAP_UNPREDICTABLE;
	}
	else {
		//arm
		st->TFlag = 0;
		st->Reg[15] = (T1 & 0xfffffffc) + 4;
	}
	OP_END ("get_op_bx_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_blx_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_blx_T1");
	if (T1 & 1) {
		//thumb XXX
		st->TFlag = 1;
		st->Reg[14] = st->Reg[15];
		st->Reg[15] = (T1 & 0xfffffffe) + 2;
		st->trap = TRAP_UNPREDICTABLE;
	}
	else {
		//arm
		st->TFlag = 0;
		st->Reg[14] = st->Reg[15];
		st->Reg[15] = (T1 & 0xfffffffc) + 4;
	}
	OP_END ("get_op_blx_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
uint8_t *
get_op_hi_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_hi_T0");
	//T0 = (uint32_t)((int32_t)((int16_t)(T0 >> 16)));
	T0 = T0 >> 16;
	OP_END ("get_op_hi_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_hi_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_hi_T1");
	//T1 = (uint32_t)((int32_t)((int16_t)(T1 >> 16)));
	T1 = T1 >> 16;
	OP_END ("get_op_hi_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_lo_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lo_T0");
	//T0 = (uint32_t)((int32_t)((int16_t)(T0 & 0xffff)));
	T0 = T0 & 0xffff;
	OP_END ("get_op_lo_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_lo_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lo_T1");
	//T1 = (uint32_t)((int32_t)((int16_t)(T1 & 0xffff)));
	T1 = T1 & 0xffff;
	OP_END ("get_op_lo_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_smlalxy_T2_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_smlalxy_T2_T1_T0");
	arm2x86_tmp64 = (uint64_t) T1;
	arm2x86_tmp64 = ((uint64_t) T2) << 32;
	arm2x86_tmp64 += (uint64_t) T0;
	T1 = (uint32_t) (arm2x86_tmp64 & 0xffffffff);
	T2 = (uint32_t) (arm2x86_tmp64 >> 32);
	OP_END ("get_op_smlalxy_T2_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_smlawy_T2_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_smlawy_T2_T1_T0");
	arm2x86_tmp64 = (uint64_t) T0 *(uint64_t) T1;
	T0 = (uint32_t) ((arm2x86_tmp64 >> 16) & 0xffffffff);
	T1 = T0 + T2;
	QFLAG_reg = ~(T0 ^ T2);
	QFLAG_reg &= (T1 ^ T2);
	QFLAG_reg >>= 31;
	T0 = T1;
	OP_END ("get_op_smlawy_T2_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_smulwy_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_smulwy_T0_T1");
	arm2x86_tmp64 = (uint64_t) T0 *(uint64_t) T1;
	T0 = (uint32_t) ((arm2x86_tmp64 >> 16) & 0xffffffff);
	OP_END ("get_op_smulwy_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//AJ2D--------------------------------------------------------------------------

//teawater change for local tb branch directly jump 2005.10.17------------------
uint8_t *
get_op_local_b_offset(int *len)
{
	unsigned int	begin=0,end=0;

	OP_BEGIN("get_op_local_b_offset");
	__asm__ __volatile__ ("jmp	0xffffffff");
	OP_END("get_op_local_b_offset");
	*len = end - begin;
	if (*len <= sizeof(INT32_MAX)) {
		return(NULL);
	}

	return((uint8_t *)begin);
}

op_table_t	op_local_b_offset;
//AJ2D--------------------------------------------------------------------------

op_table_t op_addq_T0_T1_eax_T2;
op_table_t op_b_offset;
op_table_t op_bl_offset;
//teawater add check thumb 2005.07.21-------------------------------------------
op_table_t op_bx_T1;
op_table_t op_blx_T1;
//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
op_table_t op_hi_T0;
op_table_t op_hi_T1;
op_table_t op_lo_T0;
op_table_t op_lo_T1;
op_table_t op_smlalxy_T2_T1_T0;
op_table_t op_smlawy_T2_T1_T0;
op_table_t op_smulwy_T0_T1;
//AJ2D--------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
void
arm2x86_get_op_mul (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		    int *plen)
{
	ARMword rd, rn, rs, rm;

	rd = (insn >> 16) & 0xf;
	rn = (insn >> 12) & 0xf;
	rs = (insn >> 8) & 0xf;
	rm = (insn) & 0xf;
	if (!(insn & (1 << 23))) {
		//32 bit
		//mul
		gen_op_movl_Tx_reg (state, tbpp, plen, 0, rs);
		gen_op_movl_Tx_reg (state, tbpp, plen, 1, rm);
		GEN_OP (*tbpp, *plen, op_mul_T0_T1);
		if (insn & (1 << 21)) {
			//mla
			gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
			GEN_OP (*tbpp, *plen, op_addl_T0_T1);
		}
		if (insn & (1 << 20)) {
			//set cpsr nf
			GEN_OP (*tbpp, *plen, op_logic_T0_sn);
			GEN_OP (*tbpp, *plen, op_set_nf);
			//set cpsr zf
			GEN_OP (*tbpp, *plen, op_logic_T0_sz);
			GEN_OP (*tbpp, *plen, op_set_zf);
		}
		gen_op_movl_reg_Tx (state, tbpp, plen, rd, 0);
		if (rd == 15) {
			state->trap = 1;
		}
	}
	else {
		//64 bit
		gen_op_movl_Tx_reg (state, tbpp, plen, 0, rs);
		gen_op_movl_Tx_reg (state, tbpp, plen, 1, rm);
		if (insn & (1 << 22)) {
			//smull
			GEN_OP (*tbpp, *plen, op_smull_T0_T1);
		}
		else {
			//umull
			GEN_OP (*tbpp, *plen, op_umull_T0_T1);
		}
		if (insn & (1 << 21)) {
			//smlal if smull
			//umlal if umull
			gen_op_movl_Tx_reg (state, tbpp, plen, 2, rn);
			GEN_OP (*tbpp, *plen, op_movl_eax_T2);
			gen_op_movl_Tx_reg (state, tbpp, plen, 2, rd);
			GEN_OP (*tbpp, *plen, op_addq_T0_T1_eax_T2);
		}
		if (insn & (1 << 20)) {
			//set cpsr nf
			GEN_OP (*tbpp, *plen, op_logic_T0_sn);
			GEN_OP (*tbpp, *plen, op_set_nf);
			//set cpsr zf
			GEN_OP (*tbpp, *plen, op_logic_T0_sz);
			GEN_OP (*tbpp, *plen, op_set_zf);
		}
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 0);
		gen_op_movl_reg_Tx (state, tbpp, plen, rd, 1);
		if (rn == 15 || rd == 15) {
			state->trap = 1;
		}
	}
}

void
arm2x86_get_op_swp (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		    int *plen)
{
	ARMword rd, rn, rm;

	rn = (insn >> 16) & 0xf;
	rd = (insn >> 12) & 0xf;
	rm = (insn) & 0xf;
	gen_op_movl_Tx_reg (state, tbpp, plen, 0, rm);
	gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
	if (insn & (1 << 22)) {
		//swpb
		//ldrb T2 from T1
		GEN_OP (*tbpp, *plen, op_ldrb_T2_T1);
		//strb T0 to T1
		GEN_OP (*tbpp, *plen, op_strb_T0_T1);
	}
	else {
		//swp
		//ldr T2 from T1
		GEN_OP (*tbpp, *plen, op_ldr_T2_T1);
		//str T0 to T1
		GEN_OP (*tbpp, *plen, op_str_T0_T1);
	}
	gen_op_movl_reg_Tx (state, tbpp, plen, rd, 2);
}

void
arm2x86_get_op_insn_undef (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
			   int *plen)
{
	gen_op_movl_trap_im_use_T2 (state, tbpp, plen, TRAP_INSN_UNDEF);
	state->trap = 1;
}

void
arm2x86_get_op_ldrstr (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		       int *plen)
{
	ARMword rn = (insn >> 16) & 0xf;
	ARMword rd = (insn >> 12) & 0xf;

	gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
	if (insn & (1 << 24)) {	//P
		gen_op_add_data_offset (state, tbpp, plen, insn);
	}
	if (insn & (1 << 20)) {	//L
		if (insn & (1 << 22)) {	//B
			//ldrb
			GEN_OP (*tbpp, *plen, op_ldrb_T0_T1);
		}
		else {
			//ldr
			GEN_OP (*tbpp, *plen, op_ldr_T0_T1);
		}
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			gen_op_test_dataabort_im (state, tbpp, plen,
						  op_movl_reg_Tx[0][rd].len);
		}
		gen_op_movl_reg_Tx (state, tbpp, plen, rd, 0);
	}
	else {
		gen_op_movl_Tx_reg (state, tbpp, plen, 0, rd);
		if (insn & (1 << 22)) {	//B
			//strb
			GEN_OP (*tbpp, *plen, op_strb_T0_T1);
		}
		else {
			//str
			GEN_OP (*tbpp, *plen, op_str_T0_T1);
		}
	}
	if (!(insn & (1 << 24))) {	//!P
		gen_op_add_data_offset (state, tbpp, plen, insn);
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	else if (insn & (1 << 21)) {	//P & W
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	//if (!state->is_XScale) {
	if (state->abort_model > 1) {
		GEN_OP (*tbpp, *plen, op_test_dataabort_ret);
	}
}

void
arm2x86_get_op_ldmstm (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		       int *plen)
{
	int i, n;
	ARMword rn = (insn >> 16) & 0xf;

	if (rn == 15) {
		gen_op_movl_trap_im_use_T2 (state, tbpp, plen,
					    TRAP_UNPREDICTABLE);
		state->trap = 1;
		return;
	}
	if (insn & (1 << 22)) {	//S ("^")
		if (!(insn & (1 << 15)) && (insn & (1 << 21))) {
			gen_op_movl_trap_im_use_T2 (state, tbpp, plen,
						    TRAP_UNPREDICTABLE);
			state->trap = 1;
			return;
		}
		GEN_OP (*tbpp, *plen, op_test_cpsr_ret_UNP);
	}

	gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
	n = 0;
	for (i = 0; i < 16; i++) {
		if (insn & (1 << i)) {
			if (i == 15 && (insn & (1 << 20))) {
				//have pc & L
				state->trap = 1;
				if (insn & (1 << 22)) {
					//S
					gen_op_movl_trap_im_use_T2 (state,
								    tbpp,
								    plen,
								    TRAP_SETS_R15);
				}
			}
			n++;
		}
	}
	if (n == 0) {
		//compute total size ("If bits[15:0] are all zero, the result is UNPREDICTABLE" arm_arm)
		gen_op_movl_trap_im_use_T2 (state, tbpp, plen,
					    TRAP_UNPREDICTABLE);
		state->trap = 1;
		return;
	}

	if (insn & (1 << 23)) {	//U
		//i increment
		if (insn & (1 << 24)) {	//P
			//b before
			gen_op_addl_T1_im (state, tbpp, plen, 4);
		}
		else {
			//a after
		}
	}
	else {
		//d decrement
		if (insn & (1 << 24)) {	//P
			//b before
			gen_op_addl_T1_im (state, tbpp, plen, (-(n * 4)));
		}
		else {
			//a after
			if (n != 1) {
				gen_op_addl_T1_im (state, tbpp, plen,
						   (-((n - 1) * 4)));
			}
		}
	}

	gen_op_movl_Tx_im (state, tbpp, plen, 0, insn & 0xffff);
	if (insn & (1 << 20)) {	//L
		//ldm
		if (insn & (1 << 22) && !state->trap) {	//S ("^") & don't have pc
			GEN_OP (*tbpp, *plen, op_ldm_user_T1_T0);
		}
		else {
			GEN_OP (*tbpp, *plen, op_ldm_T1_T0);
		}
	}
	else {
		//stm
		if (insn & (1 << 22)) {	//S ("^")
			GEN_OP (*tbpp, *plen, op_stm_user_T1_T0);
		}
		else {
			GEN_OP (*tbpp, *plen, op_stm_T1_T0);
		}
	}


	if (insn & (1 << 21)) {	//W
		//write back
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			gen_op_test_dataabort_im (state, tbpp, plen,
						  op_addl_T1_im.len +
						  sizeof (ARMword) +
						  op_movl_reg_Tx[0][rn].len);
		}
		if (insn & (1 << 23)) {	//U
			//i increment
			if (insn & (1 << 24)) {	//P
				//b before
			}
			else {
				//a after
				gen_op_addl_T1_im (state, tbpp, plen, 4);
			}
		}
		else {
			//d decrement
			if (insn & (1 << 24)) {	//P
				//b before
				if (n != 1) {
					gen_op_addl_T1_im (state, tbpp, plen,
							   (-((n - 1) * 4)));
				}
			}
			else {
				//a after
				gen_op_addl_T1_im (state, tbpp, plen,
						   (-(n * 4)));
			}
		}
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	//if (!state->is_XScale) {
	if (state->abort_model > 1) {
		GEN_OP (*tbpp, *plen, op_test_dataabort_ret);
	}
}

void
arm2x86_get_op_bbl (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		    int *plen)
{
	int offset = ((((int) insn << 8) >> 8) << 2) + 4;

	if (insn & (1 << 24)) {
		//bl
		gen_op_bl_offset (state, tbpp, plen, (ARMword) offset);
	}
	else {
		//b
		gen_op_b_offset (state, tbpp, plen, (ARMword) offset);
	}
//teawater change for local tb branch directly jump 2005.10.18------------------
	if (now_tbt->addr == TB_ALIGN(now_tbt->tran_addr + offset + sizeof(ARMword))) {
		int	tmp_i = (now_tbt->tran_addr - now_tbt->addr) / sizeof(ARMword);

		GEN_OP(*tbpp, *plen, op_local_b_offset);
		tb_branch_save[tmp_i].dst_addr = now_tbt->tran_addr + offset + sizeof(ARMword);
		tb_branch_save[tmp_i].tbp = *tbpp;
		list_add_tail(&tb_branch_save[tmp_i].list, &tb_branch_save_list);
		if (now_tbt->ret_addr < tb_branch_save[tmp_i].dst_addr) {
			now_tbt->ret_addr = tb_branch_save[tmp_i].dst_addr;
		}
	}
//AJ2D--------------------------------------------------------------------------
}

void
arm2x86_get_op_ldcstc (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		       int *plen)
{
	ARMword rn = (insn >> 16) & 0xf;
	//ARMword       crd = (insn >> 12) & 0xf;
	//ARMword       cp = (insn >> 8) & 0xf;

//teawater add for xscale(arm v5) 2005.09.06------------------------------------
	if (state->is_XScale && ((insn >> 8) & 0xf) == 0) {
		uint32_t tmp_32 = (insn >> 20) & 0xff;

		if (tmp_32 == 0xc4) {
			//mar
			gen_op_movl_Tx_reg (state, tbpp, plen, 0, ((insn >> 12) & 0xf));	//rdlo
			gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 16) & 0xf));	//rdhi
			GEN_OP (*tbpp, *plen, op_mar_T0_T1);

			return;
		}
		else if (tmp_32 == 0xc5) {
			//mra
			GEN_OP (*tbpp, *plen, op_mra_T0_T1);
			gen_op_movl_reg_Tx (state, tbpp, plen, ((insn >> 12) & 0xf), 0);	//rdlo
			gen_op_movl_reg_Tx (state, tbpp, plen, ((insn >> 16) & 0xf), 1);	//rdhi

			return;
		}
	}
//AJ2D--------------------------------------------------------------------------

	//XXX teawater:howto deal with N
	gen_op_movl_Tx_reg (state, tbpp, plen, 1, rn);
	if (insn & (1 << 24))	//P
		gen_op_add_imm_offset (state, tbpp, plen, insn);
	gen_op_movl_Tx_im (state, tbpp, plen, 0, insn);
	if (insn & (1 << 20)) {	//L
		//ldc
		GEN_OP (*tbpp, *plen, op_ldc_T0_T1);
	}
	else {
		//stc
		GEN_OP (*tbpp, *plen, op_stc_T0_T1);
	}
	if (!(insn & (1 << 24))) {	//!P
		gen_op_add_imm_offset (state, tbpp, plen, insn);
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
	else if (insn & (1 << 21)) {	//P & W
		gen_op_movl_reg_Tx (state, tbpp, plen, rn, 1);
	}
}

void
arm2x86_get_op_cdp_mrcmcr (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
			   int *plen)
{
	gen_op_movl_Tx_im (state, tbpp, plen, 0, insn);
	//put cp_num to T1
	gen_op_movl_Tx_im (state, tbpp, plen, 1, (insn >> 8) & 0xf);
	if (insn & (1 << 4)) {
		if (insn & (1 << 20)) {	//L
			//mrc
			GEN_OP (*tbpp, *plen, op_mrc_T0_T1);
		}
		else {
//teawater add for xscale(arm v5) 2005.09.06------------------------------------
			if (state->is_XScale && ((insn >> 8) & 0xf) == 0) {
				switch ((insn >> 16) & 0xf) {
				case 0x0:	//mia
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_smull_T0_T1);
					GEN_OP (*tbpp, *plen, op_mia_T0_T1);
					return;
					break;
				case 0x8:	//miaph
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_miaph_T0_T1);
					return;
					break;
				case 0xc:	//miabb 1100
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_lo_T0);
					GEN_OP (*tbpp, *plen, op_lo_T1);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T0);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T1);
					GEN_OP (*tbpp, *plen, op_miaxy_T0_T1);
					return;
					break;
				case 0xd:	//miabt 1101
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_lo_T0);
					GEN_OP (*tbpp, *plen, op_hi_T1);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T0);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T1);
					GEN_OP (*tbpp, *plen, op_miaxy_T0_T1);
					return;
					break;
				case 0xe:	//miatb 1110
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_hi_T0);
					GEN_OP (*tbpp, *plen, op_lo_T1);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T0);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T1);
					GEN_OP (*tbpp, *plen, op_miaxy_T0_T1);
					return;
					break;
				case 0xf:	//miatt 1111
					gen_op_movl_Tx_reg (state, tbpp, plen, 0, (insn & 0xf));	//rm
					gen_op_movl_Tx_reg (state, tbpp, plen, 1, ((insn >> 12) & 0xf));	//rs
					GEN_OP (*tbpp, *plen, op_hi_T0);
					GEN_OP (*tbpp, *plen, op_hi_T1);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T0);
					GEN_OP (*tbpp, *plen,
						op_signextend_halfword_T1);
					GEN_OP (*tbpp, *plen, op_miaxy_T0_T1);
					return;
					break;
				}
			}
//AJ2D--------------------------------------------------------------------------
			//mcr
			GEN_OP (*tbpp, *plen, op_mcr_T0_T1);
		}
	}
	else {
		//cdp
		GEN_OP (*tbpp, *plen, op_cdp_T0_T1);
	}
}

void
arm2x86_get_op_swi (ARMul_State * state, ARMword insn, uint8_t ** tbpp,
		    int *plen)
{
	gen_op_movl_trap_im_use_T2 (state, tbpp, plen, TRAP_SWI);
	state->trap = 1;
}

arm2x86_get_other_op_t *arm2x86_get_other_op[16] = {
	arm2x86_get_op_mul,
	arm2x86_get_op_swp,
	arm2x86_get_op_insn_undef,
	arm2x86_get_op_insn_undef,
	arm2x86_get_op_ldrstr,
	arm2x86_get_op_ldrstr,
	arm2x86_get_op_ldrstr,
	arm2x86_get_op_ldrstr,
	arm2x86_get_op_ldmstm,
	arm2x86_get_op_ldmstm,
	arm2x86_get_op_bbl,
	arm2x86_get_op_bbl,
	arm2x86_get_op_ldcstc,
	arm2x86_get_op_ldcstc,
	arm2x86_get_op_cdp_mrcmcr,
	arm2x86_get_op_swi,
};

//--------------------------------------------------------------------------------------------------
int
arm2x86_other_init ()
{
	op_addq_T0_T1_eax_T2.op =
		get_op_addq_T0_T1_eax_T2 (&op_addq_T0_T1_eax_T2.len);
	if (op_addq_T0_T1_eax_T2.len <= 0)
		return (-1);

	op_b_offset.op = get_op_b_offset (&op_b_offset.len);
	if (op_b_offset.len <= 0)
		return (-1);

	op_bl_offset.op = get_op_bl_offset (&op_bl_offset.len);
	if (op_bl_offset.len <= 0)
		return (-1);

//teawater add check thumb 2005.07.21-------------------------------------------
	op_bx_T1.op = get_op_bx_T1 (&op_bx_T1.len);
	if (op_bx_T1.len <= 0)
		return (-1);

	op_blx_T1.op = get_op_blx_T1 (&op_blx_T1.len);
	if (op_blx_T1.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
	op_hi_T0.op = get_op_hi_T0 (&op_hi_T0.len);
	if (op_hi_T0.len <= 0)
		return (-1);

	op_hi_T1.op = get_op_hi_T1 (&op_hi_T1.len);
	if (op_hi_T1.len <= 0)
		return (-1);

	op_lo_T0.op = get_op_lo_T0 (&op_lo_T0.len);
	if (op_lo_T0.len <= 0)
		return (-1);

	op_smlalxy_T2_T1_T0.op =
		get_op_smlalxy_T2_T1_T0 (&op_smlalxy_T2_T1_T0.len);
	if (op_smlalxy_T2_T1_T0.len <= 0)
		return (-1);

	op_smlawy_T2_T1_T0.op =
		get_op_smlawy_T2_T1_T0 (&op_smlawy_T2_T1_T0.len);
	if (op_smlawy_T2_T1_T0.len <= 0)
		return (-1);

	op_smulwy_T0_T1.op = get_op_smulwy_T0_T1 (&op_smulwy_T0_T1.len);
	if (op_smulwy_T0_T1.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

//teawater change for local tb branch directly jump 2005.10.17------------------
	op_local_b_offset.op = get_op_local_b_offset(&op_local_b_offset.len);
	if (op_local_b_offset.len <= 0)
		return(-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}
