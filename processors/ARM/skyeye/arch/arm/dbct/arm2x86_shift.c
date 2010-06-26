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
get_op_lsl_T1_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsl_T1_im");
	T1 = T1 << 31;
	OP_END ("get_op_lsl_T1_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_lsr_T1_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T1_im");
	T1 = T1 >> 31;
	OP_END ("get_op_lsr_T1_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_asr_T1_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T1_im");
	T1 = (int32_t) T1 >> 31;
	OP_END ("get_op_asr_T1_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_ror_T1_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ror_T1_im");
	__asm__ __volatile__ ("rorl	$31,%%" AREG_T1 "\n\t"::);
	OP_END ("get_op_ror_T1_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

int op_shift_T1_im_maxlen;
op_table_t op_shift_T1_im[4];
int
op_shift_T1_im_init ()
{
	int i;

	op_shift_T1_im[0].op = get_op_lsl_T1_im (&op_shift_T1_im[0].len);
	op_shift_T1_im[1].op = get_op_lsr_T1_im (&op_shift_T1_im[1].len);
	op_shift_T1_im[2].op = get_op_asr_T1_im (&op_shift_T1_im[2].len);
	op_shift_T1_im[3].op = get_op_ror_T1_im (&op_shift_T1_im[3].len);

	op_shift_T1_im_maxlen = 0;
	for (i = 0; i < 4; i++) {
		if (op_shift_T1_im[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T1_im[i].len > op_shift_T1_im_maxlen) {
			op_shift_T1_im_maxlen = op_shift_T1_im[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsl_T1_im_sc (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsl_T1_im_sc");
	st->CFlag = (T1 >> (32 - 2)) & 1;
	OP_END ("get_op_lsl_T1_im_sc");
	*len = end - begin;
	ret = (uint8_t *) begin;
	if (*len < 5)
		return (NULL);
	if (ret[4] != (32 - 2))
		return (NULL);

	return (ret);
}

uint8_t *
get_op_lsr_T1_im_sc (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

//teawater correct a little bug 2005.10.06--------------------------------------
	OP_BEGIN("get_op_lsr_T1_im_sc");
	st->CFlag = (T1 >> (31 - 1)) & 1;
	OP_END("get_op_lsr_T1_im_sc");
//AJ2D--------------------------------------------------------------------------
	*len = end - begin;
	ret = (uint8_t *) begin;
	if (*len < 5)
		return (NULL);
	if (ret[4] != 30)
		return (NULL);

	return (ret);
}

int op_shift_T1_im_sc_maxlen;
op_table_t op_shift_T1_im_sc[4];
int
op_shift_T1_im_sc_init ()
{
	op_shift_T1_im_sc[0].op =
		get_op_lsl_T1_im_sc (&op_shift_T1_im_sc[0].len);
	if (op_shift_T1_im_sc[0].op == NULL)
		return (-1);

	op_shift_T1_im_sc[1].op =
		get_op_lsr_T1_im_sc (&op_shift_T1_im_sc[1].len);
	if (op_shift_T1_im_sc[1].op == NULL)
		return (-1);

	op_shift_T1_im_sc[2].op = op_shift_T1_im_sc[1].op;
	op_shift_T1_im_sc[2].len = op_shift_T1_im_sc[1].len;

	op_shift_T1_im_sc[3].op = op_shift_T1_im_sc[1].op;
	op_shift_T1_im_sc[3].len = op_shift_T1_im_sc[1].len;

	if (op_shift_T1_im_sc[0].len > op_shift_T1_im_sc[1].len) {
		op_shift_T1_im_sc_maxlen = op_shift_T1_im_sc[0].len;
	}
	else {
		op_shift_T1_im_sc_maxlen = op_shift_T1_im_sc[1].len;
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsr_T1_0 (int *len)
{
	//arm_arm A 5.1.7
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T1_0");
	T1 = 0;
	OP_END ("get_op_lsr_T1_0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_asr_T1_0 (int *len)
{
	//arm_arm A 5.1.9
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T1_0");
	T1 = (int32_t) T1 >> 31;
	OP_END ("get_op_asr_T1_0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rrx_T1_0 (int *len)
{
	//arm_arm A 5.1.11
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rrx_T1_0");
	T1 = (T1 >> 1) | (st->CFlag << 31);
	OP_END ("get_op_rrx_T1_0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

int op_shift_T1_0_maxlen;
op_table_t op_shift_T1_0[4];
int
op_shift_T1_0_init ()
{
	int i;

	op_shift_T1_0[0].op = NULL;
	op_shift_T1_0[0].len = 0;

	op_shift_T1_0[1].op = get_op_lsr_T1_0 (&op_shift_T1_0[1].len);
	op_shift_T1_0[2].op = get_op_asr_T1_0 (&op_shift_T1_0[2].len);
	op_shift_T1_0[3].op = get_op_rrx_T1_0 (&op_shift_T1_0[3].len);

	op_shift_T1_0_maxlen = 0;
	for (i = 1; i < 4; i++) {
		if (op_shift_T1_0[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T1_0[i].len > op_shift_T1_0_maxlen) {
			op_shift_T1_0_maxlen = op_shift_T1_0[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsr_T2_0_sc (int *len)
{
	//arm_arm A 5.1.7
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T2_0_sc");
	st->CFlag = T2 >> 31;
	OP_END ("get_op_lsr_T2_0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_asr_T2_0_sc (int *len)
{
	//arm_arm A 5.1.9
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T2_0_sc");
	st->CFlag = T2 >> 31;
	OP_END ("get_op_asr_T2_0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_rrx_T2_0_sc (int *len)
{
	//arm_arm A 5.1.11
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_rrx_T2_0_sc");
	st->CFlag = T2 & 1;
	OP_END ("get_op_rrx_T2_0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

int op_shift_T2_0_sc_maxlen;
op_table_t op_shift_T2_0_sc[4];
int
op_shift_T2_0_sc_init ()
{
	int i;

	op_shift_T2_0_sc[0].op = NULL;
	op_shift_T2_0_sc[0].len = 0;

	op_shift_T2_0_sc[1].op =
		get_op_lsr_T2_0_sc (&op_shift_T2_0_sc[1].len);
	op_shift_T2_0_sc[2].op =
		get_op_asr_T2_0_sc (&op_shift_T2_0_sc[2].len);
	op_shift_T2_0_sc[3].op =
		get_op_rrx_T2_0_sc (&op_shift_T2_0_sc[3].len);

	op_shift_T2_0_sc_maxlen = 0;
	for (i = 1; i < 4; i++) {
		if (op_shift_T2_0_sc[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T2_0_sc[i].len > op_shift_T2_0_sc_maxlen) {
			op_shift_T2_0_sc_maxlen = op_shift_T2_0_sc[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsl_T1_T0 (int *len)
{
	//arm_arm A 5.1.6
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsl_T1_T0");
	T0 &= 0xff;
	if (T0)
		T1 = (T0 < 32) ? (T1 << T0) : 0;
	OP_END ("get_op_lsl_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_lsr_T1_T0 (int *len)
{
	//arm_arm A 5.1.8
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T1_T0");
	T0 &= 0xff;
	if (T0)
		T1 = (T0 < 32) ? (T1 >> T0) : 0;
	OP_END ("get_op_lsr_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_asr_T1_T0 (int *len)
{
	//arm_arm A 5.1.10
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T1_T0");
	T0 &= 0xff;
	if (T0 >= 32) {
		T0 = 31;
	}
	if (T0)
		T1 = (int32_t) T1 >> T0;
	OP_END ("get_op_asr_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ror_T1_T0 (int *len)
{
	//arm_arm A 5.1.12
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ror_T1_T0");
	T0 &= 0xff;
	if (T0) {
		T0 &= 0x1f;
		if (T0)
			T1 = (T1 >> T0) | (T1 << (32 - T0));
	}
	OP_END ("get_op_ror_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

int op_shift_T1_T0_maxlen;
op_table_t op_shift_T1_T0[4];
int
op_shift_T1_T0_init ()
{
	int i;

	op_shift_T1_T0[0].op = get_op_lsl_T1_T0 (&op_shift_T1_T0[0].len);
	op_shift_T1_T0[1].op = get_op_lsr_T1_T0 (&op_shift_T1_T0[1].len);
	op_shift_T1_T0[2].op = get_op_asr_T1_T0 (&op_shift_T1_T0[2].len);
	op_shift_T1_T0[3].op = get_op_ror_T1_T0 (&op_shift_T1_T0[3].len);

	op_shift_T1_T0_maxlen = 0;
	for (i = 0; i < 4; i++) {
		if (op_shift_T1_T0[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T1_T0[i].len > op_shift_T1_T0_maxlen) {
			op_shift_T1_T0_maxlen = op_shift_T1_T0[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsl_T1_T0_sc (int *len)
{
	//arm_arm A 5.1.6
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsl_T1_T0_sc");
	T0 &= 0xff;
	if (T0) {
		if (T0 < 32) {
			st->CFlag = (T1 >> (32 - T0)) & 1;
			T1 = T1 << T0;
		}
		else if (T0 == 32) {
			st->CFlag = T1 & 1;
			T1 = 0;
		}
		else {		//T0 > 32
			st->CFlag = 0;
			T1 = 0;
		}
	}
	OP_END ("get_op_lsl_T1_T0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_lsr_T1_T0_sc (int *len)
{
	//arm_arm A 5.1.8
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T1_T0_sc");
	T0 &= 0xff;
	if (T0) {
		if (T0 < 32) {
			st->CFlag = (T1 >> (T0 - 1)) & 1;
			T1 = T1 >> T0;
		}
		else if (T0 == 32) {
			st->CFlag = T1 >> 31;
			T1 = 0;
		}
		else {		//T0 > 32
			st->CFlag = 0;
			T1 = 0;
		}
	}
	OP_END ("get_op_lsr_T1_T0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_asr_T1_T0_sc (int *len)
{
	//arm_arm A 5.1.10
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T1_T0_sc");
	T0 &= 0xff;
	if (T0) {
		if (T0 < 32) {
			st->CFlag = (T1 >> (T0 - 1)) & 1;
		}
		if (T0 >= 32) {
			st->CFlag = T1 >> 31;
			T0 = 31;
		}
		T1 = (int32_t) T1 >> T0;
	}
	OP_END ("get_op_asr_T1_T0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ror_T1_T0_sc (int *len)
{
	//arm_arm A 5.1.12
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ror_T1_T0_sc");
	T0 &= 0xff;
	if (T0) {
		T0 &= 0x1f;
		if (T0 == 0) {
			st->CFlag = T1 >> 31;
		}
		if (T0) {
			st->CFlag = (T1 >> (T0 - 1)) & 1;
			T1 = (T1 >> T0) | (T1 << (32 - T0));
		}
	}
	OP_END ("get_op_ror_T1_T0_sc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

int op_shift_T1_T0_sc_maxlen;
op_table_t op_shift_T1_T0_sc[4];
int
op_shift_T1_T0_sc_init ()
{
	int i;

	op_shift_T1_T0_sc[0].op =
		get_op_lsl_T1_T0_sc (&op_shift_T1_T0_sc[0].len);
	op_shift_T1_T0_sc[1].op =
		get_op_lsr_T1_T0_sc (&op_shift_T1_T0_sc[1].len);
	op_shift_T1_T0_sc[2].op =
		get_op_asr_T1_T0_sc (&op_shift_T1_T0_sc[2].len);
	op_shift_T1_T0_sc[3].op =
		get_op_ror_T1_T0_sc (&op_shift_T1_T0_sc[3].len);

	op_shift_T1_T0_sc_maxlen = 0;
	for (i = 0; i < 4; i++) {
		if (op_shift_T1_T0[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T1_T0_sc[i].len > op_shift_T1_T0_sc_maxlen) {
			op_shift_T1_T0_sc_maxlen = op_shift_T1_T0_sc[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_lsl_T2_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsl_T2_im");
	T2 = T2 << 31;
	OP_END ("get_op_lsl_T2_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_lsr_T2_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_lsr_T2_im");
	T2 = T2 >> 31;
	OP_END ("get_op_lsr_T2_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_asr_T2_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_asr_T2_im");
	T2 = (int32_t) T2 >> 31;
	OP_END ("get_op_asr_T2_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

uint8_t *
get_op_ror_T2_im (int *len)
{
	uint8_t *ret;
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ror_T2_im");
	__asm__ __volatile__ ("rorl	$31,%%" AREG_T2 "\n\t"::);
	OP_END ("get_op_ror_T2_im");
	*len = end - begin;
	if (*len <= sizeof (uint8_t)) {
		return (NULL);
	}
	else {
		*len -= sizeof (uint8_t);
	}
	ret = (uint8_t *) begin;
	if (ret[*len] != 31)
		return (NULL);

	return (ret);
}

int op_shift_T2_im_maxlen;
op_table_t op_shift_T2_im[4];
int
op_shift_T2_im_init ()
{
	int i;

	op_shift_T2_im[0].op = get_op_lsl_T2_im (&op_shift_T2_im[0].len);
	op_shift_T2_im[1].op = get_op_lsr_T2_im (&op_shift_T2_im[1].len);
	op_shift_T2_im[2].op = get_op_asr_T2_im (&op_shift_T2_im[2].len);
	op_shift_T2_im[3].op = get_op_ror_T2_im (&op_shift_T2_im[3].len);

	op_shift_T2_im_maxlen = 0;
	for (i = 0; i < 4; i++) {
		if (op_shift_T2_im[i].op == NULL) {
			return (-1);
		}
		if (op_shift_T2_im[i].len > op_shift_T2_im_maxlen) {
			op_shift_T2_im_maxlen = op_shift_T2_im[i].len;
		}
	}

	return (0);
}

//--------------------------------------------------------------------------------------------------
int
arm2x86_shift_init ()
{
	if (op_shift_T1_im_init ()) {
		return (-1);
	}
	if (op_shift_T1_im_sc_init ()) {
		return (-1);
	}
	if (op_shift_T1_0_init ()) {
		return (-1);
	}
	if (op_shift_T2_0_sc_init ()) {
		return (-1);
	}
	if (op_shift_T1_T0_init ()) {
		return (-1);
	}
	if (op_shift_T1_T0_sc_init ()) {
		return (-1);
	}
	if (op_shift_T2_im_init ()) {
		return (-1);
	}

	return (0);
}
