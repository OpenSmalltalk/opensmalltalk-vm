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

//--------------------------------------------------------------------------------------------------

void
tea_ldc (ARMul_State * state, uint32_t insn, uint32_t address)
{
	ARMword cp_num = (insn >> 8) & 0xf;
	unsigned cpab;
	ARMword data;

	if (!CP_ACCESS_ALLOWED (state, cp_num)) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	cpab = (state->LDC[cp_num]) (state, ARMul_FIRST, insn, 0);
	while (cpab == ARMul_BUSY) {
		//XXX teawater:howto deal with it ?
		//ARMul_Icycles(state, 1, 0);
		if (arm2x86_exception (state)) {
			cpab = (state->LDC[cp_num]) (state, ARMul_INTERRUPT,
						     insn, 0);
			return;
		}
		cpab = (state->LDC[cp_num]) (state, ARMul_BUSY, insn, 0);
	}
	if (cpab == ARMul_CANT) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	cpab = (state->LDC[cp_num]) (state, ARMul_TRANSFER, insn, 0);
	//XXX teawater:howto deal with BUSUSEDINCPCN ?
	do {
		data = ARMul_ReadWord (state, address);
		if (state->abortSig != LOW) {
			state->trap = TRAP_DATA_ABORT;
			return;
		}
		cpab = (state->LDC[cp_num]) (state, ARMul_DATA, insn, data);
		address += 4;
	} while (cpab == ARMul_INC);
}

void
tea_stc (ARMul_State * state, uint32_t insn, uint32_t address)
{
	ARMword cp_num = (insn >> 8) & 0xf;
	unsigned cpab;
	ARMword data;

	if (!CP_ACCESS_ALLOWED (state, cp_num)) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	cpab = (state->STC[cp_num]) (state, ARMul_FIRST, insn, &data);
	while (cpab == ARMul_BUSY) {
		//XXX teawater:howto deal with it ?
		//ARMul_Icycles(state, 1, 0);
		if (arm2x86_exception (state)) {
			cpab = (state->STC[cp_num]) (state, ARMul_INTERRUPT,
						     insn, 0);
			return;
		}
		cpab = (state->STC[cp_num]) (state, ARMul_BUSY, insn, &data);
	}
	if (cpab == ARMul_CANT) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	//XXX teawater:howto deal with BUSUSEDINCPCN ?
	do {
		cpab = (state->STC[cp_num]) (state, ARMul_DATA, insn, &data);
		ARMul_WriteWord (state, address, data);
		if (state->abortSig != LOW) {
			state->trap = TRAP_DATA_ABORT;
			return;
		}
		address += 4;
	} while (cpab == ARMul_INC);
}

void
tea_mrc (ARMul_State * state, uint32_t insn, uint32_t cp_num)
{
	unsigned cpab;
	ARMword result = 0;
	ARMword rd;

	if (!CP_ACCESS_ALLOWED (state, cp_num)) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	cpab = (state->MRC[cp_num]) (state, ARMul_FIRST, insn, &result);
	while (cpab == ARMul_BUSY) {
		//XXX teawater:howto deal with it ?
		//ARMul_Icycles(state, 1, 0);
		if (arm2x86_exception (state)) {
			cpab = (state->MRC[cp_num]) (state, ARMul_INTERRUPT,
						     insn, 0);
			return;
		}
		cpab = (state->MRC[cp_num]) (state, ARMul_BUSY, insn,
					     &result);
	}
	if (cpab == ARMul_CANT) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	//XXX teawater:howto deal with BUSUSEDINCPCN and so on ?
	rd = (insn >> 12) & 0xf;
	if (rd == 15) {
		st->Reg[15] = (result & (~3)) + 4;
		state->trap = TRAP_SET_R15;
	}
	else {
		state->Reg[rd] = result;
	}
}

void
tea_mcr (ARMul_State * state, uint32_t insn, uint32_t cp_num)
{
	unsigned cpab;
	ARMword source;

	if (!CP_ACCESS_ALLOWED (state, cp_num)) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	source = state->Reg[(insn >> 12) & 0xf];
	cpab = (state->MCR[cp_num]) (state, ARMul_FIRST, insn, source);
	while (cpab == ARMul_BUSY) {
		//XXX teawater:howto deal with it ?
		//ARMul_Icycles(state, 1, 0);
		if (arm2x86_exception (state)) {
			cpab = (state->MCR[cp_num]) (state, ARMul_INTERRUPT,
						     insn, 0);
			return;
		}
		cpab = (state->MCR[cp_num]) (state, ARMul_BUSY, insn, source);
	}
	if (cpab == ARMul_CANT) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	//XXX teawater:howto deal with BUSUSEDINCPCN and so on ?
}

void
tea_cdp (ARMul_State * state, uint32_t insn, uint32_t cp_num)
{
	unsigned cpab;

	if (!CP_ACCESS_ALLOWED (state, cp_num)) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	cpab = (state->CDP[cp_num]) (state, ARMul_FIRST, insn);
	while (cpab == ARMul_BUSY) {
		//XXX teawater:howto deal with it ?
		//ARMul_Icycles(state, 1, 0);
		if (arm2x86_exception (state)) {
			cpab = (state->CDP[cp_num]) (state, ARMul_INTERRUPT,
						     insn);
			return;
		}
		cpab = (state->CDP[cp_num]) (state, ARMul_BUSY, insn);
	}
	if (cpab == ARMul_CANT) {
		state->trap = TRAP_INSN_UNDEF;
		return;
	}
	//XXX teawater:howto deal with BUSUSEDINCPCN and so on ?
}

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
uint8_t *
get_op_mar_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mar_T0_T1");
	if (T1 & 0x80) {
		T1 |= 0xffffff00;
	}
	else {
		T1 &= 0xff;
	}
	st->Accumulator = (ARMdword) T0 + (((ARMdword) T1) << 32);
	OP_END ("get_op_mar_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_mra_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mra_T0_T1");
	T0 = (uint32_t) (st->Accumulator & 0xffffffff);
	T1 = ((uint32_t) (st->Accumulator >> 32)) & 0xff;
	if (T1 & 0x80) {
		T1 |= 0xffffff00;
	}
	OP_END ("get_op_mra_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_mia_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mia_T0_T1");
	if (T1 & 0x80) {
		T1 |= 0xffffff00;
	}
	else {
		T1 &= 0xff;
	}
	st->Accumulator += (ARMdword) T0 + (((ARMdword) T1) << 32);
	OP_END ("get_op_mia_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_miaph_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_miaph_T0_T1");
	T2 = (uint32_t) ((int32_t) ((int16_t) (T0 >> 16)) *
			 (int32_t) ((int16_t) (T1 >> 16)));
	if (T2 & 0x80000000) {
		st->Accumulator += 0xffffffff00000000;
	}
	st->Accumulator += (ARMdword) T2;
	T2 = (uint32_t) ((int32_t) ((int16_t) (T0 & 0xffff)) *
			 (int32_t) ((int16_t) (T1 & 0xffff)));
	if (T2 & 0x80000000) {
		st->Accumulator += 0xffffffff00000000;
	}
	st->Accumulator += (ARMdword) T2;
	OP_END ("get_op_miaph_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_miaxy_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_miaxy_T0_T1");
	T2 = (uint32_t) ((int32_t) T0 * (int32_t) T1);
	if (T2 & 0x80000000) {
		st->Accumulator += 0xffffffff00000000;
	}
	st->Accumulator += (ARMdword) T2;
	OP_END ("get_op_miaxy_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_mar_T0_T1;
op_table_t op_mra_T0_T1;
op_table_t op_mia_T0_T1;
op_table_t op_miaph_T0_T1;
op_table_t op_miaxy_T0_T1;
//AJ2D--------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------

uint8_t *
get_op_ldc_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldc_T0_T1");
	//tea_ldc(st, T0, T1);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_ldc;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->trap) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_ldc_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_stc_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_stc_T0_T1");
	//tea_stc(st, T0, T1);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_stc;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->trap) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_stc_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_mrc_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mrc_T0_T1");
	//tea_mrc(st, T0, T1);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_mrc;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->trap) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_mrc_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_mcr_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mcr_T0_T1");
	//tea_mcr(st, T0, T1);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_mcr;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->trap) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_mcr_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_cdp_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_cdp_T0_T1");
	//tea_cdp(st, T0, T1);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_cdp;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->trap) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_cdp_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_ldc_T0_T1;
op_table_t op_stc_T0_T1;
op_table_t op_mrc_T0_T1;
op_table_t op_mcr_T0_T1;
op_table_t op_cdp_T0_T1;

//--------------------------------------------------------------------------------------------------
int
arm2x86_coproc_init ()
{
	op_ldc_T0_T1.op = get_op_ldc_T0_T1 (&op_ldc_T0_T1.len);
	if (op_ldc_T0_T1.len <= 0)
		return (-1);

	op_stc_T0_T1.op = get_op_stc_T0_T1 (&op_stc_T0_T1.len);
	if (op_stc_T0_T1.len <= 0)
		return (-1);

	op_mrc_T0_T1.op = get_op_mrc_T0_T1 (&op_mrc_T0_T1.len);
	if (op_mrc_T0_T1.len <= 0)
		return (-1);

	op_mcr_T0_T1.op = get_op_mcr_T0_T1 (&op_mcr_T0_T1.len);
	if (op_mcr_T0_T1.len <= 0)
		return (-1);

	op_cdp_T0_T1.op = get_op_cdp_T0_T1 (&op_cdp_T0_T1.len);
	if (op_cdp_T0_T1.len <= 0)
		return (-1);

//teawater add for xscale(arm v5) 2005.09.12------------------------------------
	op_mar_T0_T1.op = get_op_mar_T0_T1 (&op_mar_T0_T1.len);
	if (op_mar_T0_T1.len <= 0)
		return (-1);

	op_mra_T0_T1.op = get_op_mra_T0_T1 (&op_mra_T0_T1.len);
	if (op_mra_T0_T1.len <= 0)
		return (-1);

	op_mia_T0_T1.op = get_op_mia_T0_T1 (&op_mia_T0_T1.len);
	if (op_mia_T0_T1.len <= 0)
		return (-1);

	op_miaph_T0_T1.op = get_op_miaph_T0_T1 (&op_miaph_T0_T1.len);
	if (op_miaph_T0_T1.len <= 0)
		return (-1);

	op_miaxy_T0_T1.op = get_op_miaxy_T0_T1 (&op_miaxy_T0_T1.len);
	if (op_miaxy_T0_T1.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}
