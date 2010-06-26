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
uint8_t *
get_op_set_nf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_nf");
	st->Cpsr &= ~((unsigned) 1L << NBIT_SHIFT);
	st->Cpsr ^= NFLAG_reg << NBIT_SHIFT;
	OP_END ("get_op_set_nf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_set_zf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_zf");
	st->Cpsr &= ~((unsigned) 1L << ZBIT_SHIFT);
	st->Cpsr ^= ZFLAG_reg << ZBIT_SHIFT;
	OP_END ("get_op_set_zf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_set_cf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_cf");
	st->Cpsr &= ~((unsigned) 1L << CBIT_SHIFT);
	st->Cpsr ^= CFLAG_reg << CBIT_SHIFT;
	OP_END ("get_op_set_cf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_set_vf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_vf");
	st->Cpsr &= ~((unsigned) 1L << VBIT_SHIFT);
	st->Cpsr ^= VFLAG_reg << VBIT_SHIFT;
	OP_END ("get_op_set_vf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_set_nzcf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_nzcf");
	st->Cpsr &= ((~FLAG_MASK) | ((unsigned) 1L << VBIT_SHIFT));
	st->Cpsr ^=
		((NFLAG_reg << NBIT_SHIFT) | (ZFLAG_reg << ZBIT_SHIFT) |
		 (CFLAG_reg << CBIT_SHIFT));
	OP_END ("get_op_set_nzcf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_set_nzcvf (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_nzcvf");
	st->Cpsr &= ~FLAG_MASK;
	st->Cpsr ^=
		((NFLAG_reg << NBIT_SHIFT) | (ZFLAG_reg << ZBIT_SHIFT) |
		 (CFLAG_reg << CBIT_SHIFT) | (VFLAG_reg << VBIT_SHIFT));
	OP_END ("get_op_set_nzcvf");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//teawater add for xscale(arm v5) 2005.09.21------------------------------------
uint8_t *
get_op_set_q (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_set_q");
	st->Cpsr &= ~0x08000000;
	st->Cpsr ^= ((QFLAG_reg << 27));
	OP_END ("get_op_set_q");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//AJ2D--------------------------------------------------------------------------

op_table_t op_set_nf;
op_table_t op_set_zf;
op_table_t op_set_cf;
op_table_t op_set_vf;
op_table_t op_set_nzcf;
op_table_t op_set_nzcvf;
//teawater add for xscale(arm v5) 2005.09.21------------------------------------
op_table_t op_set_q;
//AJ2D--------------------------------------------------------------------------
int
op_set_init ()
{
	op_set_nf.op = get_op_set_nf (&op_set_nf.len);
	if (op_set_nf.len <= 0)
		return (-1);

	op_set_zf.op = get_op_set_zf (&op_set_zf.len);
	if (op_set_zf.len <= 0)
		return (-1);

	op_set_cf.op = get_op_set_cf (&op_set_cf.len);
	if (op_set_cf.len <= 0)
		return (-1);

	op_set_vf.op = get_op_set_vf (&op_set_vf.len);
	if (op_set_vf.len <= 0)
		return (-1);

	op_set_nzcf.op = get_op_set_nzcf (&op_set_nzcf.len);
	if (op_set_nzcf.len <= 0)
		return (-1);

	op_set_nzcvf.op = get_op_set_nzcvf (&op_set_nzcvf.len);
	if (op_set_nzcvf.len <= 0)
		return (-1);

//teawater add for xscale(arm v5) 2005.09.21------------------------------------
	op_set_q.op = get_op_set_q (&op_set_q.len);
	if (op_set_q.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_logic_T0_sn (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_T0_sn");
	NFLAG_reg = T0 >> 31;
	OP_END ("get_op_logic_T0_sn");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_logic_T0_sz (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_T0_sz");
	ZFLAG_reg = T0 ? 0 : 1;
	OP_END ("get_op_logic_T0_sz");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_logic_T1_sn (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_T1_sn");
	NFLAG_reg = T1 >> 31;
	OP_END ("get_op_logic_T1_sn");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_logic_T1_sz (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_T1_sz");
	ZFLAG_reg = T1 ? 0 : 1;
	OP_END ("get_op_logic_T1_sz");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_logic_0_sc (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_0_sc");
	CFLAG_reg = 0;
	OP_END ("get_op_logic_0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_logic_1_sc (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logic_1_sc");
	CFLAG_reg = 1;
	OP_END ("get_op_logic_1_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_logic_T0_sn;
op_table_t op_logic_T0_sz;
op_table_t op_logic_T1_sn;
op_table_t op_logic_T1_sz;
op_table_t op_logic_0_sc;
op_table_t op_logic_1_sc;
int
op_logic_init ()
{
	op_logic_T0_sn.op = get_op_logic_T0_sn (&op_logic_T0_sn.len);
	if (op_logic_T0_sn.len <= 0)
		return (-1);
	op_logic_T0_sz.op = get_op_logic_T0_sz (&op_logic_T0_sz.len);
	if (op_logic_T0_sz.len <= 0)
		return (-1);
	op_logic_T1_sn.op = get_op_logic_T1_sn (&op_logic_T1_sn.len);
	if (op_logic_T1_sn.len <= 0)
		return (-1);
	op_logic_T1_sz.op = get_op_logic_T1_sz (&op_logic_T1_sz.len);
	if (op_logic_T1_sz.len <= 0)
		return (-1);

	op_logic_0_sc.op = get_op_logic_0_sc (&op_logic_0_sc.len);
	if (op_logic_0_sc.len <= 0)
		return (-1);
	op_logic_1_sc.op = get_op_logic_1_sc (&op_logic_1_sc.len);
	if (op_logic_1_sc.len <= 0)
		return (-1);

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_logicq_T0_T1_sz (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_logicq_T0_T1_sz");
	ZFLAG_reg = (T0 | T1) ? 0 : 1;
	OP_END ("get_op_logicq_T0_T1_sz");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_logicq_T0_T1_sz;
int
op_logicq_init ()
{
	op_logicq_T0_T1_sz.op =
		get_op_logicq_T0_T1_sz (&op_logicq_T0_T1_sz.len);
	if (op_logicq_T0_T1_sz.len <= 0)
		return (-1);

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_mrs_T0_cpsr (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mrs_T0_cpsr");
	T0 = st->Cpsr;
	OP_END ("get_op_mrs_T0_cpsr");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_mrs_T0_spsr (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mrs_T0_spsr");
	T0 = st->Cpsr & 0x1f;
	if (T0 == 0x10 && T0 == 0x1f) {
		//user mode | System mode ("Accessing the SPSR when in User mode is UNPREDICTABLE. Accessing the SPSR when in System mode is UNPREDICTABLE." arm_arm)
		st->trap = TRAP_UNPREDICTABLE;
		__asm__ __volatile__ ("ret");
	}
	T0 = st->Spsr[st->Bank];
	OP_END ("get_op_mrs_T0_spsr");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_msr_cpsr_T0_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_msr_cpsr_T0_T1");
	//chy 2006-02-16 also should not consider SYSTEM32MODE=1f
	if ((st->Cpsr & 0x1f) == 0x10 ) {
		//user mode 
		T0 &= 0xff000000;
	}
	st->Cpsr &= ~T0;
	T1 &= T0;
	st->Cpsr |= T1;
	if ((T0 | 0xff000000) != 0) {
		//set the flag field
		T2 = st->Cpsr;
		NFLAG_reg = (T2 >> 28) & 1;
		ZFLAG_reg = (T2 >> 29) & 1;
		CFLAG_reg = (T2 >> 30) & 1;
		VFLAG_reg = T2 >> 31;
	}
	if ((T0 | 0x00ffffff) != 0) {
		//set the control field
		st->trap = TRAP_SET_CPSR;
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_msr_cpsr_T0_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_msr_spsr_T0_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_msr_spsr_T0_T1");
	st->Spsr[st->Bank] &= ~T0;
	T1 &= T0;
	st->Spsr[st->Bank] |= T1;
	OP_END ("get_op_msr_spsr_T0_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

op_table_t op_mrs_T0_cpsr;
op_table_t op_mrs_T0_spsr;
op_table_t op_msr_cpsr_T0_T1;
op_table_t op_msr_spsr_T0_T1;

int
op_mrsmsr_init ()
{
	op_mrs_T0_cpsr.op = get_op_mrs_T0_cpsr (&op_mrs_T0_cpsr.len);
	if (op_mrs_T0_cpsr.len <= 0)
		return (-1);
	op_mrs_T0_spsr.op = get_op_mrs_T0_spsr (&op_mrs_T0_spsr.len);
	if (op_mrs_T0_spsr.len <= 0)
		return (-1);

	op_msr_cpsr_T0_T1.op = get_op_msr_cpsr_T0_T1 (&op_msr_cpsr_T0_T1.len);
	if (op_msr_cpsr_T0_T1.len <= 0)
		return (-1);
	op_msr_spsr_T0_T1.op = get_op_msr_spsr_T0_T1 (&op_msr_spsr_T0_T1.len);
	if (op_msr_spsr_T0_T1.len <= 0)
		return (-1);

	return (0);
}

//--------------------------------------------------------------------------------------------------
/*uint8_t *
get_op_writesr15(int *len)
{
	unsigned int	begin=0, end=0;

	OP_BEGIN("get_op_writesr15");
	if (st->Bank > 0) {
		st->Cpsr = st->Spsr[st->Bank];
		__asm__ __volatile__ ("push	%"AREG_st);
		T0 = (uint32_t)ARMul_CPSRAltered;
		__asm__ __volatile__ ("call	*%"AREG1_T0);
		__asm__ __volatile__ ("addl	$0x4, %esp");
		st->trapflags |= 
		__asm__ __volatile__ ("ret");
	}
	OP_END("get_op_writesr15");
	*len = end - begin;

	return((uint8_t *)begin);
}

op_table_t	op_writesr15;
int
op_writesr15_init()
{
	op_writesr15.op = get_op_writesr15(&op_writesr15.len);

	return(0);
}*/
//--------------------------------------------------------------------------------------------------
int
arm2x86_psr_init ()
{
	op_set_init ();
	op_logic_init ();
	op_logicq_init ();
	op_mrsmsr_init ();
	//op_writesr15_init();

	return (0);
}
