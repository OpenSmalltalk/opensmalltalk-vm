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
get_op_andl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_andl_T0_T1");
	T0 &= T1;
	OP_END ("get_op_andl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_eorl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_eorl_T0_T1");
	T0 ^= T1;
	OP_END ("get_op_eorl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_subl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_subl_T0_T1");
	T0 -= T1;
	OP_END ("get_op_subl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_subl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_subl_T0_T1_scv");
	T2 = T0 - T1;
	//CFLAG_reg = (T0<T1)?1:0;
	CFLAG_reg = (T0 >= T1) ? 1 : 0;
	//chy 2006-02-12 chage ! to ~
	//VFLAG_reg = !(T2 ^ T1);
	VFLAG_reg = ~(T2 ^ T1);
	VFLAG_reg &= (T0 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_subl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rsbl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rsbl_T0_T1");
	T0 = T1 - T0;
	OP_END ("get_op_rsbl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rsbl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rsbl_T0_T1_scv");
	T2 = T1 - T0;
	//CFLAG_reg = (T1<T0)?1:0;
	CFLAG_reg = (T1 >= T0) ? 1 : 0;
	//chy 2006-02-12 chage ! to ~
	//VFLAG_reg = !(T2 ^ T0);
	VFLAG_reg = ~(T2 ^ T0);
	VFLAG_reg &= (T0 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_rsbl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addl_T0_T1");
	T0 += T1;
	OP_END ("get_op_addl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addl_T0_T1_scv");
	T2 = T0 + T1;
	CFLAG_reg = (T2 < T0);
	VFLAG_reg = ~(T0 ^ T1);
	VFLAG_reg &= (T2 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_addl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_adcl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_adcl_T0_T1");
	T0 += T1 + CFLAG_reg;
	OP_END ("get_op_adcl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_adcl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_adcl_T0_T1_scv");
	T2 = T0 + T1 + CFLAG_reg;
	if (!CFLAG_reg) {
		CFLAG_reg = (T2 < T0);
	}
	else {
		CFLAG_reg = (T2 <= T0);
	}
	VFLAG_reg = ~(T0 ^ T1);
	VFLAG_reg &= (T2 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_adcl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_sbcl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_sbcl_T0_T1");
	//T0 -= (T1 + !CFLAG_reg);
	T0 = T0 - T1 + CFLAG_reg - 1;
	OP_END ("get_op_sbcl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_sbcl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_sbcl_T0_T1_scv");
	T2 = T0 - T1 + CFLAG_reg - 1;
	if (!CFLAG_reg) {
		CFLAG_reg = (T0 > T1);
	}
	else {
		CFLAG_reg = (T0 >= T1);
	}
	//chy 2006-02-12 chage ! to ~
	//VFLAG_reg = !(T2 ^ T1);
	VFLAG_reg = ~(T2 ^ T1);
	VFLAG_reg &= (T0 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_sbcl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rscl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rscl_T0_T1");
	//T0 = T1 - T0 - !CFLAG_reg;
	T0 = T1 - T0 + CFLAG_reg - 1;
	OP_END ("get_op_rscl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rscl_T0_T1_scv (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rscl_T0_T1_scv");
	T0 += !CFLAG_reg;
	T2 = T1 - T0;
	//CFLAG_reg = (T1<T0)?1:0;
	//CFLAG_reg = (T1 >= T0)?1:0;
	if (!CFLAG_reg) {
		CFLAG_reg = (T1 > T0);
	}
	else {
		CFLAG_reg = (T1 >= T0);
	}
	//chy 2006-02-12 chage ! to ~
	//VFLAG_reg = !(T2 ^ T0);
	VFLAG_reg = ~(T2 ^ T0);
	VFLAG_reg &= (T0 ^ T1);
	VFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_rscl_T0_T1_scv");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_orrl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_orrl_T0_T1");
	T0 |= T1;
	OP_END ("get_op_orrl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_movl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_T1");
	T0 = T1;
	OP_END ("get_op_movl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_bicl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_bicl_T0_T1");
	T0 &= ~T1;
	OP_END ("get_op_bicl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_notl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_notl_T0_T1");
	T0 = ~T1;
	OP_END ("get_op_notl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addl_T1_im (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addl_T1_im");
	T1 += INT32_MAX;
	OP_END ("get_op_addl_T1_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}

	return ((uint8_t *) begin);
}

uint8_t *
get_op_subl_T1_T2 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_subl_T1_T2");
	T1 -= T2;
	OP_END ("get_op_subl_T1_T2");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addl_T1_T2 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addl_T1_T2");
	T1 += T2;
	OP_END ("get_op_addl_T1_T2");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//teawater add for xscale(arm v5) 2005.09.01------------------------------------
uint8_t *
get_op_clzl_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_clzl_T0_T1");
	//chy 2006-02-12 fix a bug
	if(T1){
		for (T0 = 0; (T1 & 0x80000000) == 0; T1 <<= 1) {
			T0++;
		}
	}
	OP_END ("get_op_clzl_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_qaddl_T0_T1_sq (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_qaddl_T0_T1_sq");
	T2 = T0 + T1;
	QFLAG_reg = ~(T0 ^ T1);
	QFLAG_reg &= (T2 ^ T1);
	QFLAG_reg >>= 31;
	T0 = T2;
	if (QFLAG_reg) {
		T0 = (T0 >> 31) ? 0x7fffffff : 0x80000000;
	}
	OP_END ("get_op_qaddl_T0_T1_sq");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_qsubl_T0_T1_sq (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_qsubl_T0_T1_sq");
	T2 = T0 - T1;
	//chy 2006-02-12 chage ! to ~
	//QFLAG_reg = !(T2 ^ T1);
	QFLAG_reg = ~(T2 ^ T1);
	QFLAG_reg &= (T0 ^ T1);
	QFLAG_reg >>= 31;
	T0 = T2;
	if (QFLAG_reg) {
		T0 = (T0 >> 31) ? 0x7fffffff : 0x80000000;
	}
	OP_END ("get_op_qsubl_T0_T1_sq");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addl_T0_T1_sq (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addl_T0_T1_sq");
	T2 = T0 + T1;
	QFLAG_reg = ~(T0 ^ T1);
	QFLAG_reg &= (T2 ^ T1);
	QFLAG_reg >>= 31;
	T0 = T2;
	OP_END ("get_op_addl_T0_T1_sq");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//AJ2D--------------------------------------------------------------------------

op_table_t op_andl_T0_T1;
op_table_t op_eorl_T0_T1;
op_table_t op_subl_T0_T1;
op_table_t op_subl_T0_T1_scv;
op_table_t op_rsbl_T0_T1;
op_table_t op_rsbl_T0_T1_scv;
op_table_t op_addl_T0_T1;
op_table_t op_addl_T0_T1_scv;
op_table_t op_adcl_T0_T1;
op_table_t op_adcl_T0_T1_scv;
op_table_t op_sbcl_T0_T1;
op_table_t op_sbcl_T0_T1_scv;
op_table_t op_rscl_T0_T1;
op_table_t op_rscl_T0_T1_scv;
op_table_t op_orrl_T0_T1;
op_table_t op_movl_T0_T1;
op_table_t op_bicl_T0_T1;
op_table_t op_notl_T0_T1;
op_table_t op_addl_T1_im;
op_table_t op_subl_T1_T2;
op_table_t op_addl_T1_T2;
//teawater add for xscale(arm v5) 2005.09.01------------------------------------
op_table_t op_clzl_T0_T1;
op_table_t op_qaddl_T0_T1_sq;
op_table_t op_qsubl_T0_T1_sq;
op_table_t op_addl_T0_T1_sq;
//AJ2D--------------------------------------------------------------------------

int
op_dp_T0_T1 ()
{
	op_andl_T0_T1.op = get_op_andl_T0_T1 (&op_andl_T0_T1.len);
	if (op_andl_T0_T1.len <= 0)
		return (-1);

	op_eorl_T0_T1.op = get_op_eorl_T0_T1 (&op_eorl_T0_T1.len);
	if (op_eorl_T0_T1.len <= 0)
		return (-1);

	op_subl_T0_T1.op = get_op_subl_T0_T1 (&op_subl_T0_T1.len);
	if (op_subl_T0_T1.len <= 0)
		return (-1);

	op_subl_T0_T1_scv.op = get_op_subl_T0_T1_scv (&op_subl_T0_T1_scv.len);
	if (op_subl_T0_T1_scv.len <= 0)
		return (-1);

	op_rsbl_T0_T1.op = get_op_rsbl_T0_T1 (&op_rsbl_T0_T1.len);
	if (op_rsbl_T0_T1.len <= 0)
		return (-1);

	op_rsbl_T0_T1_scv.op = get_op_rsbl_T0_T1_scv (&op_rsbl_T0_T1_scv.len);
	if (op_rsbl_T0_T1_scv.len <= 0)
		return (-1);

	op_addl_T0_T1.op = get_op_addl_T0_T1 (&op_addl_T0_T1.len);
	if (op_addl_T0_T1.len <= 0)
		return (-1);

	op_addl_T0_T1_scv.op = get_op_addl_T0_T1_scv (&op_addl_T0_T1_scv.len);
	if (op_addl_T0_T1_scv.len <= 0)
		return (-1);

	op_adcl_T0_T1.op = get_op_adcl_T0_T1 (&op_adcl_T0_T1.len);
	if (op_adcl_T0_T1.len <= 0)
		return (-1);

	op_adcl_T0_T1_scv.op = get_op_adcl_T0_T1_scv (&op_adcl_T0_T1_scv.len);
	if (op_adcl_T0_T1_scv.len <= 0)
		return (-1);

	op_sbcl_T0_T1.op = get_op_sbcl_T0_T1 (&op_sbcl_T0_T1.len);
	if (op_sbcl_T0_T1.len <= 0)
		return (-1);

	op_sbcl_T0_T1_scv.op = get_op_sbcl_T0_T1_scv (&op_sbcl_T0_T1_scv.len);
	if (op_sbcl_T0_T1_scv.len <= 0)
		return (-1);

	op_rscl_T0_T1.op = get_op_rscl_T0_T1 (&op_rscl_T0_T1.len);
	if (op_rscl_T0_T1.len <= 0)
		return (-1);

	op_rscl_T0_T1_scv.op = get_op_rscl_T0_T1_scv (&op_rscl_T0_T1_scv.len);
	if (op_rscl_T0_T1_scv.len <= 0)
		return (-1);

	op_orrl_T0_T1.op = get_op_orrl_T0_T1 (&op_orrl_T0_T1.len);
	if (op_orrl_T0_T1.len <= 0)
		return (-1);

	op_movl_T0_T1.op = get_op_movl_T0_T1 (&op_movl_T0_T1.len);
	if (op_movl_T0_T1.len <= 0)
		return (-1);

	op_bicl_T0_T1.op = get_op_bicl_T0_T1 (&op_bicl_T0_T1.len);
	if (op_bicl_T0_T1.len <= 0)
		return (-1);

	op_notl_T0_T1.op = get_op_notl_T0_T1 (&op_notl_T0_T1.len);
	if (op_notl_T0_T1.len <= 0)
		return (-1);

	op_addl_T1_im.op = get_op_addl_T1_im (&op_addl_T1_im.len);
	if (op_addl_T1_im.len <= 0)
		return (-1);

	op_subl_T1_T2.op = get_op_subl_T1_T2 (&op_subl_T1_T2.len);
	if (op_subl_T1_T2.len <= 0)
		return (-1);

	op_addl_T1_T2.op = get_op_addl_T1_T2 (&op_addl_T1_T2.len);
	if (op_addl_T1_T2.len <= 0)
		return (-1);

//teawater add for xscale(arm v5) 2005.09.01------------------------------------
	op_clzl_T0_T1.op = get_op_clzl_T0_T1 (&op_clzl_T0_T1.len);
	if (op_clzl_T0_T1.len <= 0)
		return (-1);

	op_qaddl_T0_T1_sq.op = get_op_qaddl_T0_T1_sq (&op_qaddl_T0_T1_sq.len);
	if (op_qaddl_T0_T1_sq.len <= 0)
		return (-1);

	op_qsubl_T0_T1_sq.op = get_op_qsubl_T0_T1_sq (&op_qsubl_T0_T1_sq.len);
	if (op_qsubl_T0_T1_sq.len <= 0)
		return (-1);

	op_addl_T0_T1_sq.op = get_op_addl_T0_T1_sq (&op_addl_T0_T1_sq.len);
	if (op_addl_T0_T1_sq.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}

//--------------------------------------------------------------------------------------------------
void
arm2x86_get_op_and (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_andl_T0_T1);
}

void
arm2x86_get_op_eor (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_eorl_T0_T1);
}

void
arm2x86_get_op_sub (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_subl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_subl_T0_T1);
	}
}

void
arm2x86_get_op_rsb (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_rsbl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_rsbl_T0_T1);
	}
}

void
arm2x86_get_op_add (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_addl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_addl_T0_T1);
	}
}

void
arm2x86_get_op_adc (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_adcl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_adcl_T0_T1);
	}
}

void
arm2x86_get_op_sbc (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_sbcl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_sbcl_T0_T1);
	}
}

void
arm2x86_get_op_rsc (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		GEN_OP (*tbpp, *plen, op_rscl_T0_T1_scv);
	}
	else {
		GEN_OP (*tbpp, *plen, op_rscl_T0_T1);
	}
}

void
arm2x86_get_op_tst (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		GEN_OP (*tbpp, *plen, op_andl_T0_T1);
	}
}

void
arm2x86_get_op_teq (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		GEN_OP (*tbpp, *plen, op_eorl_T0_T1);
	}
}

void
arm2x86_get_op_cmp (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		GEN_OP (*tbpp, *plen, op_subl_T0_T1_scv);
	}
}

void
arm2x86_get_op_cmn (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		GEN_OP (*tbpp, *plen, op_addl_T0_T1_scv);
	}
}

void
arm2x86_get_op_orr (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_orrl_T0_T1);
}

void
arm2x86_get_op_mov (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_movl_T0_T1);
}

void
arm2x86_get_op_bic (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_bicl_T0_T1);
}

void
arm2x86_get_op_mvn (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword set_cc, ARMword rd)
{
	GEN_OP (*tbpp, *plen, op_notl_T0_T1);
}

arm2x86_get_dp_op_t *arm2x86_get_dp_op[16] = {
	arm2x86_get_op_and,
	arm2x86_get_op_eor,
	arm2x86_get_op_sub,
	arm2x86_get_op_rsb,
	arm2x86_get_op_add,
	arm2x86_get_op_adc,
	arm2x86_get_op_sbc,
	arm2x86_get_op_rsc,
	arm2x86_get_op_tst,
	arm2x86_get_op_teq,
	arm2x86_get_op_cmp,
	arm2x86_get_op_cmn,
	arm2x86_get_op_orr,
	arm2x86_get_op_mov,
	arm2x86_get_op_bic,
	arm2x86_get_op_mvn,
};

void
arm2x86_get_op_setcpsr_nzc (ARMul_State * state, uint8_t ** tbpp, int *plen,
			    ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		//set cpsr nf
		GEN_OP (*tbpp, *plen, op_logic_T0_sn);
		//GEN_OP(*tbpp, *plen, op_set_nf);
		//set cpsr zf
		GEN_OP (*tbpp, *plen, op_logic_T0_sz);
		//GEN_OP(*tbpp, *plen, op_set_zf);
		//set cpsr cf
		//GEN_OP(*tbpp, *plen, op_set_cf);
		GEN_OP (*tbpp, *plen, op_set_nzcf);
	}
}

void
arm2x86_get_op_setcpsr_nzc_setreg (ARMul_State * state, uint8_t ** tbpp,
				   int *plen, ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		//set cpsr nf
		GEN_OP (*tbpp, *plen, op_logic_T0_sn);
		//GEN_OP(*tbpp, *plen, op_set_nf);
		//set cpsr zf
		GEN_OP (*tbpp, *plen, op_logic_T0_sz);
		//GEN_OP(*tbpp, *plen, op_set_zf);
		//set cpsr cf
		//GEN_OP(*tbpp, *plen, op_set_cf);
		GEN_OP (*tbpp, *plen, op_set_nzcf);
	}
	gen_op_movl_reg_Tx (state, tbpp, plen, rd, 0);
	if (rd == 15 && set_cc) {
		//change pc & set spsr to cpsr
		gen_op_movl_trap_im_use_T2 (state, tbpp, plen, TRAP_SETS_R15);
	}
}

void
arm2x86_get_op_setcpsr_nzcv (ARMul_State * state, uint8_t ** tbpp, int *plen,
			     ARMword set_cc, ARMword rd)
{
	if (set_cc) {
		//set cpsr nf
		GEN_OP (*tbpp, *plen, op_logic_T0_sn);
		//GEN_OP(*tbpp, *plen, op_set_nf);
		//set cpsr zf
		GEN_OP (*tbpp, *plen, op_logic_T0_sz);
		//GEN_OP(*tbpp, *plen, op_set_zf);
		//set cpsr cf
		//GEN_OP(*tbpp, *plen, op_set_cf);
		//set cpsr vf
		//GEN_OP(*tbpp, *plen, op_set_vf);
		GEN_OP (*tbpp, *plen, op_set_nzcvf);
	}
}

void
arm2x86_get_op_setcpsr_nzcv_setreg (ARMul_State * state, uint8_t ** tbpp,
				    int *plen, ARMword set_cc, ARMword rd)
{
	if (set_cc && rd != 15) {
		//set cpsr cf
		//GEN_OP(*tbpp, *plen, op_set_cf);
		//set cpsr vf
		//GEN_OP(*tbpp, *plen, op_set_vf);
		//set cpsr nf
		GEN_OP (*tbpp, *plen, op_logic_T0_sn);
		//GEN_OP(*tbpp, *plen, op_set_nf);
		//set cpsr zf
		GEN_OP (*tbpp, *plen, op_logic_T0_sz);
		//GEN_OP(*tbpp, *plen, op_set_zf);
		GEN_OP (*tbpp, *plen, op_set_nzcvf);
	}
	gen_op_movl_reg_Tx (state, tbpp, plen, rd, 0);
	if (rd == 15 && set_cc) {
		//change pc & set spsr to cpsr
		gen_op_movl_trap_im_use_T2 (state, tbpp, plen, TRAP_SETS_R15);
	}
}

arm2x86_get_dp_op_t *arm2x86_get_dp_op_setcpsr[16] = {
	arm2x86_get_op_setcpsr_nzc_setreg,	//and
	arm2x86_get_op_setcpsr_nzc_setreg,	//eor
	arm2x86_get_op_setcpsr_nzcv_setreg,	//sub
	arm2x86_get_op_setcpsr_nzcv_setreg,	//rsb
	arm2x86_get_op_setcpsr_nzcv_setreg,	//add
	arm2x86_get_op_setcpsr_nzcv_setreg,	//adc
	arm2x86_get_op_setcpsr_nzcv_setreg,	//sbc
	arm2x86_get_op_setcpsr_nzcv_setreg,	//rsc
	arm2x86_get_op_setcpsr_nzc,	//tst
	arm2x86_get_op_setcpsr_nzc,	//teq
	arm2x86_get_op_setcpsr_nzcv,	//cmp
	arm2x86_get_op_setcpsr_nzcv,	//cmn
	arm2x86_get_op_setcpsr_nzc_setreg,	//orr
	arm2x86_get_op_setcpsr_nzc_setreg,	//mov
	arm2x86_get_op_setcpsr_nzc_setreg,	//bic
	arm2x86_get_op_setcpsr_nzc_setreg,	//mvn
};

//--------------------------------------------------------------------------------------------------
int
arm2x86_dp_init ()
{
	if (op_dp_T0_T1 ()) {
		return (-1);
	}

	return (0);
}
