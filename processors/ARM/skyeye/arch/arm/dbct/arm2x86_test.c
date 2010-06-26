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
get_op_test_dataabort (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_test_dataabort");
	if (st->abortSig != LOW) {
		__asm__ __volatile__ ("jmp	0xffffffff");
	}
	OP_END ("get_op_test_dataabort");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_test_dataabort_ret (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_test_dataabort_ret");
	if (st->abortSig != LOW) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_test_dataabort_ret");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_test_cpsr_ret_UNP (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_test_cpsr_ret_UNP");
	T2 = st->Cpsr & 0x1f;
	if (T2 == 0x10 || T2 == 0x1f) {
		st->trap = TRAP_UNPREDICTABLE;
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_test_cpsr_ret_UNP");
	*len = end - begin;

	return ((uint8_t *) begin);
}

/*uint8_t *
get_op_test_debug(int *len)
{
	unsigned int	begin=0,end=0;

	OP_BEGIN("get_op_test_debug");
	T0 = st->Emulate;
	if (T0 == 0) {
		st->trap = TRAP_DEBUG;
		__asm__ __volatile__ ("ret");
	}
	OP_END("get_op_test_debug");
	*len = end - begin;

	return((uint8_t *)begin);
}*/

op_table_t op_test_dataabort;
op_table_t op_test_dataabort_ret;
op_table_t op_test_cpsr_ret_UNP;
//op_table_t    op_test_debug;
int
arm2x86_test_init ()
{
	op_test_dataabort.op = get_op_test_dataabort (&op_test_dataabort.len);
	if (op_test_dataabort.len <= 0)
		return (-1);

	op_test_dataabort_ret.op =
		get_op_test_dataabort_ret (&op_test_dataabort_ret.len);
	if (op_test_dataabort_ret.len <= 0)
		return (-1);

	op_test_cpsr_ret_UNP.op =
		get_op_test_cpsr_ret_UNP (&op_test_cpsr_ret_UNP.len);
	if (op_test_cpsr_ret_UNP.len <= 0)
		return (-1);

	/*op_test_debug.op = get_op_test_debug(&op_test_debug.len);
	   if (op_test_debug.len <= 0)
	   return(-1); */

	return (0);
}
