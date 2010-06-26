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

#ifndef _ARM2X86_DP_H_
#define _ARM2X86_DP_H_

extern op_table_t op_andl_T0_T1;
extern op_table_t op_eorl_T0_T1;
extern op_table_t op_subl_T0_T1;
extern op_table_t op_subl_T0_T1_scv;
extern op_table_t op_rsbl_T0_T1;
extern op_table_t op_rsbl_T0_T1_scv;
extern op_table_t op_addl_T0_T1;
extern op_table_t op_addl_T0_T1_scv;
extern op_table_t op_adcl_T0_T1;
extern op_table_t op_adcl_T0_T1_scv;
extern op_table_t op_sbcl_T0_T1;
extern op_table_t op_sbcl_T0_T1_scv;
extern op_table_t op_rscl_T0_T1;
extern op_table_t op_rscl_T0_T1_scv;
extern op_table_t op_orrl_T0_T1;
extern op_table_t op_movl_T0_T1;
extern op_table_t op_bicl_T0_T1;
extern op_table_t op_notl_T0_T1;
extern op_table_t op_addl_T1_im;
extern op_table_t op_subl_T1_T2;
extern op_table_t op_addl_T1_T2;
//teawater add for xscale(arm v5) 2005.09.01------------------------------------
extern op_table_t op_clzl_T0_T1;
extern op_table_t op_qaddl_T0_T1_sq;
extern op_table_t op_qsubl_T0_T1_sq;
extern op_table_t op_addl_T0_T1_sq;
//AJ2D--------------------------------------------------------------------------

typedef void (arm2x86_get_dp_op_t) (ARMul_State * state, uint8_t ** tbpp,
				    int *plen, ARMword set_cc, ARMword rd);
extern arm2x86_get_dp_op_t *arm2x86_get_dp_op[16];
extern arm2x86_get_dp_op_t *arm2x86_get_dp_op_setcpsr[16];

extern int arm2x86_dp_init ();

static __inline__ void
gen_op_addl_T1_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
		   ARMword im)
{
	GEN_OP (*tbpp, *plen, op_addl_T1_im);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &im, sizeof(im));
		*tbpp += sizeof(im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}

#endif //_ARM2X86_DP_H_
