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

#ifndef _ARM2X86_PSR_H_
#define _ARM2X86_PSR_H_

extern op_table_t op_set_nf;
extern op_table_t op_set_zf;
extern op_table_t op_set_cf;
extern op_table_t op_set_vf;
extern op_table_t op_set_nzcf;
extern op_table_t op_set_nzcvf;

extern op_table_t op_logic_T0_sn;
extern op_table_t op_logic_T0_sz;
extern op_table_t op_logic_T1_sn;
extern op_table_t op_logic_T1_sz;

extern op_table_t op_logic_0_sc;
extern op_table_t op_logic_1_sc;

extern op_table_t op_logicq_T0_T1_sz;

extern op_table_t op_mrs_T0_cpsr;
extern op_table_t op_mrs_T0_spsr;
extern op_table_t op_msr_spsr_T0_T1;
extern op_table_t op_msr_cpsr_T0_T1;

//teawater add for xscale(arm v5) 2005.09.21------------------------------------
extern op_table_t op_set_q;
//AJ2D--------------------------------------------------------------------------

//extern op_table_t     op_writesr15;

extern int arm2x86_psr_init ();

static __inline__ uint32_t
gen_op_condition (ARMul_State * state, uint32_t cond)
{
	uint32_t ret;

	switch (cond) {
	case EQ:
		ret = ZFLAG;
		break;
	case NE:
		ret = !ZFLAG;
		break;
	case VS:
		ret = VFLAG;
		break;
	case VC:
		ret = !VFLAG;
		break;
	case MI:
		ret = NFLAG;
		break;
	case PL:
		ret = !NFLAG;
		break;
	case CS:
		ret = CFLAG;
		break;
	case CC:
		ret = !CFLAG;
		break;
	case HI:
		ret = (CFLAG && !ZFLAG);
		break;
	case LS:
		ret = (!CFLAG || ZFLAG);
		break;
	case GE:
		ret = ((!NFLAG && !VFLAG) || (NFLAG && VFLAG));
		break;
	case LT:
		ret = ((NFLAG && !VFLAG) || (!NFLAG && VFLAG));
		break;
	case GT:
		ret = ((!NFLAG && !VFLAG && !ZFLAG)
		       || (NFLAG && VFLAG && !ZFLAG));
		break;
	case LE:
		ret = ((NFLAG && !VFLAG) || (!NFLAG && VFLAG)) || ZFLAG;
		break;
	default:
		ret = 0;
		break;
	}

	return (ret);
}

#endif //_ARM2X86_PSR_H_
