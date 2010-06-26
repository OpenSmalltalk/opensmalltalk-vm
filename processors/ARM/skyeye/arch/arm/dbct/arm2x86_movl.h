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

#ifndef _ARM2X86_MOVL_H_
#define _ARM2X86_MOVL_H_

extern op_table_t op_movl_Tx_im[Tx_MAX + 1];
extern op_table_t op_movl_tmpx_im[tmp_MAX + 1];
extern int op_movl_Tx_reg_maxlen;
extern int op_movl_Tx_reg_array_maxlen[Tx_MAX + 1];
extern op_table_t op_movl_Tx_reg[Tx_MAX + 1][16];
extern int op_movl_reg_Tx_maxlen;
extern int op_movl_reg_Tx_array_maxlen[Tx_MAX + 1];
extern op_table_t op_movl_reg_Tx[Tx_MAX + 1][16];
extern op_table_t op_movl_eax_T2;
extern op_table_t op_movl_trap_im;
extern op_table_t op_movl_trap_T2;
extern op_table_t op_movl_T0_T2;
extern op_table_t op_movl_T2_T1;
//teawater add for xscale(arm v5) 2005.09.22------------------------------------
extern op_table_t op_movl_T1_T0;
//AJ2D--------------------------------------------------------------------------

extern int arm2x86_movl_init ();

static __inline__ void
gen_op_movl_Tx_im (ARMul_State * state, uint8_t ** tbpp, int *plen, int Tx,
		   ARMword im)
{
	GEN_OP (*tbpp, *plen, op_movl_Tx_im[Tx]);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &im, sizeof(im));
		*tbpp += sizeof(im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}

static __inline__ void
gen_op_movl_tmpx_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
		     int tmpx, ARMword im)
{
	GEN_OP (*tbpp, *plen, op_movl_tmpx_im[tmpx]);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &im, sizeof(im));
		*tbpp += sizeof(im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}

static __inline__ void
gen_op_movl_Tx_reg (ARMul_State * state, uint8_t ** tbpp, int *plen, int Tx,
		    ARMword reg)
{
	GEN_OP (*tbpp, *plen, op_movl_Tx_reg[Tx][reg]);
}

static __inline__ void
gen_op_movl_reg_Tx (ARMul_State * state, uint8_t ** tbpp, int *plen,
		    ARMword reg, int Tx)
{
	GEN_OP (*tbpp, *plen, op_movl_reg_Tx[Tx][reg]);
	if (reg == 15) {
		//change pc
		state->trap = 1;
	}
}

static __inline__ void
gen_op_movl_trap_im_use_T2 (ARMul_State * state, uint8_t ** tbpp, int *plen,
			    ARMword im)
{
	gen_op_movl_Tx_im (state, tbpp, plen, 2, im);
	GEN_OP (*tbpp, *plen, op_movl_trap_T2);
}

static __inline__ void
gen_op_movl_trap_im (ARMul_State * state, uint8_t ** tbpp, int *plen,
		     ARMword im)
{
	GEN_OP (*tbpp, *plen, op_movl_trap_im);
//teawater remove tb_translate_find 2005.10.21----------------------------------
	//if (*tbpp) {
		memcpy(*tbpp, &im, sizeof(im));
		*tbpp += sizeof(im);
	//}
//AJ2D--------------------------------------------------------------------------
	*plen += sizeof (im);
}

#endif //_ARM2X86_MOVL_H_
