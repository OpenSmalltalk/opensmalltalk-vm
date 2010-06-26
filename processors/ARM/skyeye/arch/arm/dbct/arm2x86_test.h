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

#ifndef _ARM2X86_TEST_H_
#define _ARM2X86_TEST_H_

extern op_table_t op_test_dataabort;
extern op_table_t op_test_dataabort_ret;
extern op_table_t op_test_cpsr_ret_UNP;
//extern op_table_t     op_test_debug;
extern int arm2x86_test_init ();

static __inline__ void
gen_op_test_dataabort_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
			  uint32_t im)
{
	GEN_OP (*tbpp, *plen, op_test_dataabort);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp - sizeof(im), &im, sizeof(im));
	//}
//AJ2D--------------------------------------------------------------------------
}

#endif //_ARM2X86_TEST_H_
