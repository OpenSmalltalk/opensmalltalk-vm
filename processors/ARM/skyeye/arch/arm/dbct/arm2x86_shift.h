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

#ifndef _ARM2X86_SHIFT_H_
#define _ARM2X86_SHIFT_H_

extern int op_shift_T1_im_maxlen;
extern op_table_t op_shift_T1_im[4];	//only shift
extern int op_shift_T1_im_sc_maxlen;
extern op_table_t op_shift_T1_im_sc[4];	//only set CFlag

extern int op_shift_T1_0_maxlen;
extern op_table_t op_shift_T1_0[4];	//only shift

extern int op_shift_T2_0_sc_maxlen;
extern op_table_t op_shift_T2_0_sc[4];	//only set CFlag

extern int op_shift_T1_T0_maxlen;
extern op_table_t op_shift_T1_T0[4];	//only shift
extern int op_shift_T1_T0_sc_maxlen;
extern op_table_t op_shift_T1_T0_sc[4];	//shift & set CFlag

extern int op_shift_T2_im_maxlen;
extern op_table_t op_shift_T2_im[4];	//only shift

extern int arm2x86_shift_init ();

static __inline__ void
gen_op_shift_T1_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword op, uint8_t im)
{
	if (im == 0)
		return;
	GEN_OP (*tbpp, *plen, op_shift_T1_im[op]);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy (*tbpp, &im, sizeof (im));
		*tbpp += sizeof (im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}

static __inline__ void
gen_op_shift_T1_im_sc (ARMul_State * state, uint8_t ** tbpp, int *plen,
		       ARMword op, uint8_t im)
{
	if (im == 0)
		return;
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, op_shift_T1_im_sc[op].op, op_shift_T1_im_sc[op].len);
		if (!op) {
			(*tbpp)[4] = 32 - im;
		}
		else {
			(*tbpp)[4] = im - 1;
		}
		*tbpp += op_shift_T1_im_sc[op].len;
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += op_shift_T1_im_sc[op].len;

	//set cpsr cf
	GEN_OP (*tbpp, *plen, op_set_cf);
}

static __inline__ void
gen_op_shift_T1_T0 (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword op)
{
	GEN_OP (*tbpp, *plen, op_shift_T1_T0[op]);
}

static __inline__ void
gen_op_shift_T1_T0_sc (ARMul_State * state, uint8_t ** tbpp, int *plen,
		       ARMword op)
{
	GEN_OP (*tbpp, *plen, op_shift_T1_T0_sc[op]);

	//set cpsr cf
	GEN_OP (*tbpp, *plen, op_set_cf);
}

static __inline__ void
gen_op_shift_T2_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword op, uint8_t im)
{
	if (im == 0)
		return;
	GEN_OP (*tbpp, *plen, op_shift_T2_im[op]);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &im, sizeof(im));
		*tbpp += sizeof(im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}
#endif //_ARM2X86_SHIFT_H_
