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
get_op_movl_T0_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_im");
	T0 = ULONG_MAX;
	OP_END ("get_op_movl_T0_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_im");
	T1 = ULONG_MAX;
	OP_END ("get_op_movl_T1_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_im");
	T2 = ULONG_MAX;
	OP_END ("get_op_movl_T2_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}
	ret = (uint8_t *) begin;

	return (ret);
}

op_table_t op_movl_Tx_im[Tx_MAX + 1];
int
op_movl_Tx_im_init ()
{
	int i;

	op_movl_Tx_im[0].op = get_op_movl_T0_im (&op_movl_Tx_im[0].len);
	op_movl_Tx_im[1].op = get_op_movl_T1_im (&op_movl_Tx_im[1].len);
	op_movl_Tx_im[2].op = get_op_movl_T2_im (&op_movl_Tx_im[2].len);

	for (i = 0; i <= Tx_MAX; i++) {
		if (op_movl_Tx_im[i].op == NULL) {
			return (-1);
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_tmp0_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_tmp0_im");
	arm2x86_tmp0 = ULONG_MAX;
	OP_END ("get_op_movl_tmp0_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}
	ret = (uint8_t *) begin;

	return (ret);
}

op_table_t op_movl_tmpx_im[tmp_MAX + 1];
int
op_movl_tmpx_im_init ()
{
	op_movl_tmpx_im[0].op = get_op_movl_tmp0_im (&op_movl_tmpx_im[0].len);
	if (op_movl_tmpx_im[0].op == NULL)
		return (-1);

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_T0_r0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r0");
	T0 = st->Reg[0];
	OP_END ("get_op_movl_T0_r0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r1");
	T0 = st->Reg[1];
	OP_END ("get_op_movl_T0_r1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r2");
	T0 = st->Reg[2];
	OP_END ("get_op_movl_T0_r2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r3 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r3");
	T0 = st->Reg[3];
	OP_END ("get_op_movl_T0_r3");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r4 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r4");
	T0 = st->Reg[4];
	OP_END ("get_op_movl_T0_r4");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r5 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r5");
	T0 = st->Reg[5];
	OP_END ("get_op_movl_T0_r5");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r6 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r6");
	T0 = st->Reg[6];
	OP_END ("get_op_movl_T0_r6");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r7 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r7");
	T0 = st->Reg[7];
	OP_END ("get_op_movl_T0_r7");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r8 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r8");
	T0 = st->Reg[8];
	OP_END ("get_op_movl_T0_r8");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r9 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r9");
	T0 = st->Reg[9];
	OP_END ("get_op_movl_T0_r9");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r10 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r10");
	T0 = st->Reg[10];
	OP_END ("get_op_movl_T0_r10");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r11 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r11");
	T0 = st->Reg[11];
	OP_END ("get_op_movl_T0_r11");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r12 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r12");
	T0 = st->Reg[12];
	OP_END ("get_op_movl_T0_r12");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r13 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r13");
	T0 = st->Reg[13];
	OP_END ("get_op_movl_T0_r13");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r14 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r14");
	T0 = st->Reg[14];
	OP_END ("get_op_movl_T0_r14");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T0_r15 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_r15");
	T0 = st->Reg[15] + 4;
	OP_END ("get_op_movl_T0_r15");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r0");
	T1 = st->Reg[0];
	OP_END ("get_op_movl_T1_r0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r1");
	T1 = st->Reg[1];
	OP_END ("get_op_movl_T1_r1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r2");
	T1 = st->Reg[2];
	OP_END ("get_op_movl_T1_r2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r3 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r3");
	T1 = st->Reg[3];
	OP_END ("get_op_movl_T1_r3");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r4 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r4");
	T1 = st->Reg[4];
	OP_END ("get_op_movl_T1_r4");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r5 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r5");
	T1 = st->Reg[5];
	OP_END ("get_op_movl_T1_r5");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r6 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r6");
	T1 = st->Reg[6];
	OP_END ("get_op_movl_T1_r6");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r7 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r7");
	T1 = st->Reg[7];
	OP_END ("get_op_movl_T1_r7");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r8 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r8");
	T1 = st->Reg[8];
	OP_END ("get_op_movl_T1_r8");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r9 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r9");
	T1 = st->Reg[9];
	OP_END ("get_op_movl_T1_r9");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r10 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r10");
	T1 = st->Reg[10];
	OP_END ("get_op_movl_T1_r10");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r11 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r11");
	T1 = st->Reg[11];
	OP_END ("get_op_movl_T1_r11");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r12 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r12");
	T1 = st->Reg[12];
	OP_END ("get_op_movl_T1_r12");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r13 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r13");
	T1 = st->Reg[13];
	OP_END ("get_op_movl_T1_r13");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r14 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r14");
	T1 = st->Reg[14];
	OP_END ("get_op_movl_T1_r14");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T1_r15 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_r15");
	T1 = st->Reg[15] + 4;
	OP_END ("get_op_movl_T1_r15");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r0");
	T2 = st->Reg[0];
	OP_END ("get_op_movl_T2_r0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r1");
	T2 = st->Reg[1];
	OP_END ("get_op_movl_T2_r1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r2");
	T2 = st->Reg[2];
	OP_END ("get_op_movl_T2_r2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r3 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r3");
	T2 = st->Reg[3];
	OP_END ("get_op_movl_T2_r3");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r4 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r4");
	T2 = st->Reg[4];
	OP_END ("get_op_movl_T2_r4");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r5 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r5");
	T2 = st->Reg[5];
	OP_END ("get_op_movl_T2_r5");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r6 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r6");
	T2 = st->Reg[6];
	OP_END ("get_op_movl_T2_r6");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r7 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r7");
	T2 = st->Reg[7];
	OP_END ("get_op_movl_T2_r7");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r8 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r8");
	T2 = st->Reg[8];
	OP_END ("get_op_movl_T2_r8");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r9 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r9");
	T2 = st->Reg[9];
	OP_END ("get_op_movl_T2_r9");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r10 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r10");
	T2 = st->Reg[10];
	OP_END ("get_op_movl_T2_r10");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r11 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r11");
	T2 = st->Reg[11];
	OP_END ("get_op_movl_T2_r11");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r12 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r12");
	T2 = st->Reg[12];
	OP_END ("get_op_movl_T2_r12");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r13 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r13");
	T2 = st->Reg[13];
	OP_END ("get_op_movl_T2_r13");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r14 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r14");
	T2 = st->Reg[14];
	OP_END ("get_op_movl_T2_r14");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_r15 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_r15");
	T2 = st->Reg[15] + 4;
	OP_END ("get_op_movl_T2_r15");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

int op_movl_Tx_reg_maxlen;
int op_movl_Tx_reg_array_maxlen[Tx_MAX + 1];
op_table_t op_movl_Tx_reg[Tx_MAX + 1][16];
int
op_movl_Tx_reg_init ()
{
	int i, j;

	op_movl_Tx_reg[0][0].op =
		get_op_movl_T0_r0 (&op_movl_Tx_reg[0][0].len);
	op_movl_Tx_reg[0][1].op =
		get_op_movl_T0_r1 (&op_movl_Tx_reg[0][1].len);
	op_movl_Tx_reg[0][2].op =
		get_op_movl_T0_r2 (&op_movl_Tx_reg[0][2].len);
	op_movl_Tx_reg[0][3].op =
		get_op_movl_T0_r3 (&op_movl_Tx_reg[0][3].len);
	op_movl_Tx_reg[0][4].op =
		get_op_movl_T0_r4 (&op_movl_Tx_reg[0][4].len);
	op_movl_Tx_reg[0][5].op =
		get_op_movl_T0_r5 (&op_movl_Tx_reg[0][5].len);
	op_movl_Tx_reg[0][6].op =
		get_op_movl_T0_r6 (&op_movl_Tx_reg[0][6].len);
	op_movl_Tx_reg[0][7].op =
		get_op_movl_T0_r7 (&op_movl_Tx_reg[0][7].len);
	op_movl_Tx_reg[0][8].op =
		get_op_movl_T0_r8 (&op_movl_Tx_reg[0][8].len);
	op_movl_Tx_reg[0][9].op =
		get_op_movl_T0_r9 (&op_movl_Tx_reg[0][9].len);
	op_movl_Tx_reg[0][10].op =
		get_op_movl_T0_r10 (&op_movl_Tx_reg[0][10].len);
	op_movl_Tx_reg[0][11].op =
		get_op_movl_T0_r11 (&op_movl_Tx_reg[0][11].len);
	op_movl_Tx_reg[0][12].op =
		get_op_movl_T0_r12 (&op_movl_Tx_reg[0][12].len);
	op_movl_Tx_reg[0][13].op =
		get_op_movl_T0_r13 (&op_movl_Tx_reg[0][13].len);
	op_movl_Tx_reg[0][14].op =
		get_op_movl_T0_r14 (&op_movl_Tx_reg[0][14].len);
	op_movl_Tx_reg[0][15].op =
		get_op_movl_T0_r15 (&op_movl_Tx_reg[0][15].len);

	op_movl_Tx_reg[1][0].op =
		get_op_movl_T1_r0 (&op_movl_Tx_reg[1][0].len);
	op_movl_Tx_reg[1][1].op =
		get_op_movl_T1_r1 (&op_movl_Tx_reg[1][1].len);
	op_movl_Tx_reg[1][2].op =
		get_op_movl_T1_r2 (&op_movl_Tx_reg[1][2].len);
	op_movl_Tx_reg[1][3].op =
		get_op_movl_T1_r3 (&op_movl_Tx_reg[1][3].len);
	op_movl_Tx_reg[1][4].op =
		get_op_movl_T1_r4 (&op_movl_Tx_reg[1][4].len);
	op_movl_Tx_reg[1][5].op =
		get_op_movl_T1_r5 (&op_movl_Tx_reg[1][5].len);
	op_movl_Tx_reg[1][6].op =
		get_op_movl_T1_r6 (&op_movl_Tx_reg[1][6].len);
	op_movl_Tx_reg[1][7].op =
		get_op_movl_T1_r7 (&op_movl_Tx_reg[1][7].len);
	op_movl_Tx_reg[1][8].op =
		get_op_movl_T1_r8 (&op_movl_Tx_reg[1][8].len);
	op_movl_Tx_reg[1][9].op =
		get_op_movl_T1_r9 (&op_movl_Tx_reg[1][9].len);
	op_movl_Tx_reg[1][10].op =
		get_op_movl_T1_r10 (&op_movl_Tx_reg[1][10].len);
	op_movl_Tx_reg[1][11].op =
		get_op_movl_T1_r11 (&op_movl_Tx_reg[1][11].len);
	op_movl_Tx_reg[1][12].op =
		get_op_movl_T1_r12 (&op_movl_Tx_reg[1][12].len);
	op_movl_Tx_reg[1][13].op =
		get_op_movl_T1_r13 (&op_movl_Tx_reg[1][13].len);
	op_movl_Tx_reg[1][14].op =
		get_op_movl_T1_r14 (&op_movl_Tx_reg[1][14].len);
	op_movl_Tx_reg[1][15].op =
		get_op_movl_T1_r15 (&op_movl_Tx_reg[1][15].len);

	op_movl_Tx_reg[2][0].op =
		get_op_movl_T2_r0 (&op_movl_Tx_reg[2][0].len);
	op_movl_Tx_reg[2][1].op =
		get_op_movl_T2_r1 (&op_movl_Tx_reg[2][1].len);
	op_movl_Tx_reg[2][2].op =
		get_op_movl_T2_r2 (&op_movl_Tx_reg[2][2].len);
	op_movl_Tx_reg[2][3].op =
		get_op_movl_T2_r3 (&op_movl_Tx_reg[2][3].len);
	op_movl_Tx_reg[2][4].op =
		get_op_movl_T2_r4 (&op_movl_Tx_reg[2][4].len);
	op_movl_Tx_reg[2][5].op =
		get_op_movl_T2_r5 (&op_movl_Tx_reg[2][5].len);
	op_movl_Tx_reg[2][6].op =
		get_op_movl_T2_r6 (&op_movl_Tx_reg[2][6].len);
	op_movl_Tx_reg[2][7].op =
		get_op_movl_T2_r7 (&op_movl_Tx_reg[2][7].len);
	op_movl_Tx_reg[2][8].op =
		get_op_movl_T2_r8 (&op_movl_Tx_reg[2][8].len);
	op_movl_Tx_reg[2][9].op =
		get_op_movl_T2_r9 (&op_movl_Tx_reg[2][9].len);
	op_movl_Tx_reg[2][10].op =
		get_op_movl_T2_r10 (&op_movl_Tx_reg[2][10].len);
	op_movl_Tx_reg[2][11].op =
		get_op_movl_T2_r11 (&op_movl_Tx_reg[2][11].len);
	op_movl_Tx_reg[2][12].op =
		get_op_movl_T2_r12 (&op_movl_Tx_reg[2][12].len);
	op_movl_Tx_reg[2][13].op =
		get_op_movl_T2_r13 (&op_movl_Tx_reg[2][13].len);
	op_movl_Tx_reg[2][14].op =
		get_op_movl_T2_r14 (&op_movl_Tx_reg[2][14].len);
	op_movl_Tx_reg[2][15].op =
		get_op_movl_T2_r15 (&op_movl_Tx_reg[2][15].len);

	op_movl_Tx_reg_maxlen = 0;
	for (i = 0; i <= Tx_MAX; i++) {
		op_movl_Tx_reg_array_maxlen[i] = 0;
		for (j = 0; j <= 15; j++) {
			if (op_movl_Tx_reg[i][j].len <= 0) {
				return (-1);
			}
			if (op_movl_Tx_reg[i][j].len >
			    op_movl_Tx_reg_array_maxlen[i]) {
				op_movl_Tx_reg_array_maxlen[i] =
					op_movl_Tx_reg[i][j].len;
			}
		}
		if (op_movl_Tx_reg_array_maxlen[i] > op_movl_Tx_reg_maxlen) {
			op_movl_Tx_reg_maxlen =
				op_movl_Tx_reg_array_maxlen[i];
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_r0_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r0_T0");
	st->Reg[0] = T0;
	OP_END ("get_op_movl_r0_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r1_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r1_T0");
	st->Reg[1] = T0;
	OP_END ("get_op_movl_r1_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r2_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r2_T0");
	st->Reg[2] = T0;
	OP_END ("get_op_movl_r2_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r3_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r3_T0");
	st->Reg[3] = T0;
	OP_END ("get_op_movl_r3_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r4_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r4_T0");
	st->Reg[4] = T0;
	OP_END ("get_op_movl_r4_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r5_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r5_T0");
	st->Reg[5] = T0;
	OP_END ("get_op_movl_r5_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r6_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r6_T0");
	st->Reg[6] = T0;
	OP_END ("get_op_movl_r6_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r7_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r7_T0");
	st->Reg[7] = T0;
	OP_END ("get_op_movl_r7_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r8_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r8_T0");
	st->Reg[8] = T0;
	OP_END ("get_op_movl_r8_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r9_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r9_T0");
	st->Reg[9] = T0;
	OP_END ("get_op_movl_r9_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r10_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r10_T0");
	st->Reg[10] = T0;
	OP_END ("get_op_movl_r10_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r11_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r11_T0");
	st->Reg[11] = T0;
	OP_END ("get_op_movl_r11_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r12_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r12_T0");
	st->Reg[12] = T0;
	OP_END ("get_op_movl_r12_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r13_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r13_T0");
	st->Reg[13] = T0;
	OP_END ("get_op_movl_r13_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r14_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r14_T0");
	st->Reg[14] = T0;
	OP_END ("get_op_movl_r14_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r15_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r15_T0");
	st->Reg[15] = (T0 & (~3)) + 4;
	OP_END ("get_op_movl_r15_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r0_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r0_T1");
	st->Reg[0] = T1;
	OP_END ("get_op_movl_r0_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r1_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r1_T1");
	st->Reg[1] = T1;
	OP_END ("get_op_movl_r1_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r2_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r2_T1");
	st->Reg[2] = T1;
	OP_END ("get_op_movl_r2_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r3_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r3_T1");
	st->Reg[3] = T1;
	OP_END ("get_op_movl_r3_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r4_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r4_T1");
	st->Reg[4] = T1;
	OP_END ("get_op_movl_r4_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r5_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r5_T1");
	st->Reg[5] = T1;
	OP_END ("get_op_movl_r5_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r6_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r6_T1");
	st->Reg[6] = T1;
	OP_END ("get_op_movl_r6_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r7_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r7_T1");
	st->Reg[7] = T1;
	OP_END ("get_op_movl_r7_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r8_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r8_T1");
	st->Reg[8] = T1;
	OP_END ("get_op_movl_r8_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r9_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r9_T1");
	st->Reg[9] = T1;
	OP_END ("get_op_movl_r9_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r10_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r10_T1");
	st->Reg[10] = T1;
	OP_END ("get_op_movl_r10_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r11_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r11_T1");
	st->Reg[11] = T1;
	OP_END ("get_op_movl_r11_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r12_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r12_T1");
	st->Reg[12] = T1;
	OP_END ("get_op_movl_r12_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r13_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r13_T1");
	st->Reg[13] = T1;
	OP_END ("get_op_movl_r13_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r14_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r14_T1");
	st->Reg[14] = T1;
	OP_END ("get_op_movl_r14_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r15_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r15_T1");
	st->Reg[15] = (T1 & (~3)) + 4;
	OP_END ("get_op_movl_r15_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r0_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r0_T2");
	st->Reg[0] = T2;
	OP_END ("get_op_movl_r0_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r1_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r1_T2");
	st->Reg[1] = T2;
	OP_END ("get_op_movl_r1_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r2_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r2_T2");
	st->Reg[2] = T2;
	OP_END ("get_op_movl_r2_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r3_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r3_T2");
	st->Reg[3] = T2;
	OP_END ("get_op_movl_r3_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r4_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r4_T2");
	st->Reg[4] = T2;
	OP_END ("get_op_movl_r4_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r5_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r5_T2");
	st->Reg[5] = T2;
	OP_END ("get_op_movl_r5_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r6_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r6_T2");
	st->Reg[6] = T2;
	OP_END ("get_op_movl_r6_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r7_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r7_T2");
	st->Reg[7] = T2;
	OP_END ("get_op_movl_r7_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r8_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r8_T2");
	st->Reg[8] = T2;
	OP_END ("get_op_movl_r8_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r9_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r9_T2");
	st->Reg[9] = T2;
	OP_END ("get_op_movl_r9_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r10_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r10_T2");
	st->Reg[10] = T2;
	OP_END ("get_op_movl_r10_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r11_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r11_T2");
	st->Reg[11] = T2;
	OP_END ("get_op_movl_r11_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r12_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r12_T2");
	st->Reg[12] = T2;
	OP_END ("get_op_movl_r12_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r13_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r13_T2");
	st->Reg[13] = T2;
	OP_END ("get_op_movl_r13_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r14_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r14_T2");
	st->Reg[14] = T2;
	OP_END ("get_op_movl_r14_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_r15_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_r15_T2");
	st->Reg[15] = (T2 & (~3)) + 4;
	OP_END ("get_op_movl_r15_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

int op_movl_reg_Tx_maxlen;
int op_movl_reg_Tx_array_maxlen[Tx_MAX + 1];
op_table_t op_movl_reg_Tx[Tx_MAX + 1][16];
int
op_movl_reg_Tx_init ()
{
	int i, j;

	op_movl_reg_Tx[0][0].op =
		get_op_movl_r0_T0 (&op_movl_reg_Tx[0][0].len);
	op_movl_reg_Tx[0][1].op =
		get_op_movl_r1_T0 (&op_movl_reg_Tx[0][1].len);
	op_movl_reg_Tx[0][2].op =
		get_op_movl_r2_T0 (&op_movl_reg_Tx[0][2].len);
	op_movl_reg_Tx[0][3].op =
		get_op_movl_r3_T0 (&op_movl_reg_Tx[0][3].len);
	op_movl_reg_Tx[0][4].op =
		get_op_movl_r4_T0 (&op_movl_reg_Tx[0][4].len);
	op_movl_reg_Tx[0][5].op =
		get_op_movl_r5_T0 (&op_movl_reg_Tx[0][5].len);
	op_movl_reg_Tx[0][6].op =
		get_op_movl_r6_T0 (&op_movl_reg_Tx[0][6].len);
	op_movl_reg_Tx[0][7].op =
		get_op_movl_r7_T0 (&op_movl_reg_Tx[0][7].len);
	op_movl_reg_Tx[0][8].op =
		get_op_movl_r8_T0 (&op_movl_reg_Tx[0][8].len);
	op_movl_reg_Tx[0][9].op =
		get_op_movl_r9_T0 (&op_movl_reg_Tx[0][9].len);
	op_movl_reg_Tx[0][10].op =
		get_op_movl_r10_T0 (&op_movl_reg_Tx[0][10].len);
	op_movl_reg_Tx[0][11].op =
		get_op_movl_r11_T0 (&op_movl_reg_Tx[0][11].len);
	op_movl_reg_Tx[0][12].op =
		get_op_movl_r12_T0 (&op_movl_reg_Tx[0][12].len);
	op_movl_reg_Tx[0][13].op =
		get_op_movl_r13_T0 (&op_movl_reg_Tx[0][13].len);
	op_movl_reg_Tx[0][14].op =
		get_op_movl_r14_T0 (&op_movl_reg_Tx[0][14].len);
	op_movl_reg_Tx[0][15].op =
		get_op_movl_r15_T0 (&op_movl_reg_Tx[0][15].len);

	op_movl_reg_Tx[1][0].op =
		get_op_movl_r0_T1 (&op_movl_reg_Tx[1][0].len);
	op_movl_reg_Tx[1][1].op =
		get_op_movl_r1_T1 (&op_movl_reg_Tx[1][1].len);
	op_movl_reg_Tx[1][2].op =
		get_op_movl_r2_T1 (&op_movl_reg_Tx[1][2].len);
	op_movl_reg_Tx[1][3].op =
		get_op_movl_r3_T1 (&op_movl_reg_Tx[1][3].len);
	op_movl_reg_Tx[1][4].op =
		get_op_movl_r4_T1 (&op_movl_reg_Tx[1][4].len);
	op_movl_reg_Tx[1][5].op =
		get_op_movl_r5_T1 (&op_movl_reg_Tx[1][5].len);
	op_movl_reg_Tx[1][6].op =
		get_op_movl_r6_T1 (&op_movl_reg_Tx[1][6].len);
	op_movl_reg_Tx[1][7].op =
		get_op_movl_r7_T1 (&op_movl_reg_Tx[1][7].len);
	op_movl_reg_Tx[1][8].op =
		get_op_movl_r8_T1 (&op_movl_reg_Tx[1][8].len);
	op_movl_reg_Tx[1][9].op =
		get_op_movl_r9_T1 (&op_movl_reg_Tx[1][9].len);
	op_movl_reg_Tx[1][10].op =
		get_op_movl_r10_T1 (&op_movl_reg_Tx[1][10].len);
	op_movl_reg_Tx[1][11].op =
		get_op_movl_r11_T1 (&op_movl_reg_Tx[1][11].len);
	op_movl_reg_Tx[1][12].op =
		get_op_movl_r12_T1 (&op_movl_reg_Tx[1][12].len);
	op_movl_reg_Tx[1][13].op =
		get_op_movl_r13_T1 (&op_movl_reg_Tx[1][13].len);
	op_movl_reg_Tx[1][14].op =
		get_op_movl_r14_T1 (&op_movl_reg_Tx[1][14].len);
	op_movl_reg_Tx[1][15].op =
		get_op_movl_r15_T1 (&op_movl_reg_Tx[1][15].len);

	op_movl_reg_Tx[2][0].op =
		get_op_movl_r0_T2 (&op_movl_reg_Tx[2][0].len);
	op_movl_reg_Tx[2][1].op =
		get_op_movl_r1_T2 (&op_movl_reg_Tx[2][1].len);
	op_movl_reg_Tx[2][2].op =
		get_op_movl_r2_T2 (&op_movl_reg_Tx[2][2].len);
	op_movl_reg_Tx[2][3].op =
		get_op_movl_r3_T2 (&op_movl_reg_Tx[2][3].len);
	op_movl_reg_Tx[2][4].op =
		get_op_movl_r4_T2 (&op_movl_reg_Tx[2][4].len);
	op_movl_reg_Tx[2][5].op =
		get_op_movl_r5_T2 (&op_movl_reg_Tx[2][5].len);
	op_movl_reg_Tx[2][6].op =
		get_op_movl_r6_T2 (&op_movl_reg_Tx[2][6].len);
	op_movl_reg_Tx[2][7].op =
		get_op_movl_r7_T2 (&op_movl_reg_Tx[2][7].len);
	op_movl_reg_Tx[2][8].op =
		get_op_movl_r8_T2 (&op_movl_reg_Tx[2][8].len);
	op_movl_reg_Tx[2][9].op =
		get_op_movl_r9_T2 (&op_movl_reg_Tx[2][9].len);
	op_movl_reg_Tx[2][10].op =
		get_op_movl_r10_T2 (&op_movl_reg_Tx[2][10].len);
	op_movl_reg_Tx[2][11].op =
		get_op_movl_r11_T2 (&op_movl_reg_Tx[2][11].len);
	op_movl_reg_Tx[2][12].op =
		get_op_movl_r12_T2 (&op_movl_reg_Tx[2][12].len);
	op_movl_reg_Tx[2][13].op =
		get_op_movl_r13_T2 (&op_movl_reg_Tx[2][13].len);
	op_movl_reg_Tx[2][14].op =
		get_op_movl_r14_T2 (&op_movl_reg_Tx[2][14].len);
	op_movl_reg_Tx[2][15].op =
		get_op_movl_r15_T2 (&op_movl_reg_Tx[2][15].len);

	op_movl_reg_Tx_maxlen = 0;
	for (i = 0; i <= Tx_MAX; i++) {
		op_movl_reg_Tx_array_maxlen[i] = 0;
		for (j = 0; j <= 15; j++) {
			if (op_movl_reg_Tx[i][j].len <= 0) {
				return (-1);
			}
			if (op_movl_reg_Tx[i][j].len >
			    op_movl_reg_Tx_array_maxlen[i]) {
				op_movl_reg_Tx_array_maxlen[i] =
					op_movl_reg_Tx[i][j].len;
			}
		}
		if (op_movl_reg_Tx_array_maxlen[i] > op_movl_reg_Tx_maxlen) {
			op_movl_reg_Tx_maxlen =
				op_movl_reg_Tx_array_maxlen[i];
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_eax_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_eax_T2");
	__asm__ __volatile__ ("movl	%" AREG_T2 ", %eax");
	OP_END ("get_op_movl_eax_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

op_table_t op_movl_eax_T2;
//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_trap_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_trap_im");
	st->trap = ULONG_MAX;
	OP_END ("get_op_movl_trap_im");
	*len = end - begin;
	if (*len <= sizeof (ULONG_MAX)) {
		return (NULL);
	}
	else {
		*len -= sizeof (ULONG_MAX);
	}
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_trap_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_trap_T2");
	st->trap = T2;
	OP_END ("get_op_movl_trap_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

op_table_t op_movl_trap_im;
op_table_t op_movl_trap_T2;
//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_movl_T0_T2 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T0_T2");
	T0 = T2;
	OP_END ("get_op_movl_T0_T2");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

uint8_t *
get_op_movl_T2_T1 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T2_T1");
	T2 = T1;
	OP_END ("get_op_movl_T2_T1");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

//teawater add for xscale(arm v5) 2005.09.22------------------------------------
uint8_t *
get_op_movl_T1_T0 (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_movl_T1_T0");
	T1 = T0;
	OP_END ("get_op_movl_T1_T0");
	*len = end - begin;
	ret = (uint8_t *) begin;

	return (ret);
}

//AJ2D--------------------------------------------------------------------------

op_table_t op_movl_T0_T2;
op_table_t op_movl_T2_T1;
//teawater add for xscale(arm v5) 2005.09.22------------------------------------
op_table_t op_movl_T1_T0;
//AJ2D--------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
int
arm2x86_movl_init ()
{
	if (op_movl_Tx_im_init ()) {
		return (-1);
	}
	if (op_movl_tmpx_im_init ()) {
		return (-1);
	}
	if (op_movl_Tx_reg_init ()) {
		return (-1);
	}
	if (op_movl_reg_Tx_init ()) {
		return (-1);
	}

	op_movl_eax_T2.op = get_op_movl_eax_T2 (&op_movl_eax_T2.len);
	if (op_movl_eax_T2.len <= 0)
		return (-1);

	op_movl_trap_im.op = get_op_movl_trap_im (&op_movl_trap_im.len);
	if (op_movl_trap_im.len <= 0)
		return (-1);

	op_movl_trap_T2.op = get_op_movl_trap_T2 (&op_movl_trap_T2.len);
	if (op_movl_trap_T2.len <= 0)
		return (-1);

	op_movl_T0_T2.op = get_op_movl_T0_T2 (&op_movl_T0_T2.len);
	if (op_movl_T0_T2.len <= 0)
		return (-1);

	op_movl_T2_T1.op = get_op_movl_T2_T1 (&op_movl_T2_T1.len);
	if (op_movl_T2_T1.len <= 0)
		return (-1);

//teawater add for xscale(arm v5) 2005.09.22------------------------------------
	op_movl_T1_T0.op = get_op_movl_T1_T0 (&op_movl_T1_T0.len);
	if (op_movl_T1_T0.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}
