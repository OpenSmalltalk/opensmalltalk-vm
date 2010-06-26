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
get_op_mul_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_mul_T0_T1");
	T0 = T0 * T1;
	OP_END ("get_op_mul_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_umull_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_umull_T0_T1");
	__asm__ __volatile__ ("movl	%" AREG_T0 ", %eax");
	__asm__ __volatile__ ("mull	%" AREG_T1);
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);
	__asm__ __volatile__ ("movl	%edx, %" AREG_T1);
	OP_END ("get_op_umull_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_smull_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_smull_T0_T1");
	__asm__ __volatile__ ("movl	%" AREG_T0 ", %eax");
	__asm__ __volatile__ ("imull	%" AREG_T1);
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);
	__asm__ __volatile__ ("movl	%edx, %" AREG_T1);
	OP_END ("get_op_smull_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_mul_T0_T1;
op_table_t op_umull_T0_T1;
op_table_t op_smull_T0_T1;
int
arm2x86_mul_init ()
{
	op_mul_T0_T1.op = get_op_mul_T0_T1 (&op_mul_T0_T1.len);
	if (op_mul_T0_T1.len <= 0)
		return (-1);

	op_umull_T0_T1.op = get_op_umull_T0_T1 (&op_umull_T0_T1.len);
	if (op_umull_T0_T1.len <= 0)
		return (-1);

	op_smull_T0_T1.op = get_op_smull_T0_T1 (&op_smull_T0_T1.len);
	if (op_smull_T0_T1.len <= 0)
		return (-1);

	return (0);
}
