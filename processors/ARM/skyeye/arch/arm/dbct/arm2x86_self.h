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

#ifndef _ARM2X86_SELF_H_
#define _ARM2X86_SELF_H_

#define AREG_st		"ebp"
#define AREG_T0		"ebx"
#define AREG_T1		"esi"
#define AREG_T2		"edi"
register ARMul_State *st asm (AREG_st);
//register struct ARMul_State *st       asm(AREG_st);
register uint32_t T0 asm (AREG_T0);
register uint32_t T1 asm (AREG_T1);
register uint32_t T2 asm (AREG_T2);

#define NFLAG_reg	st->NFlag
#define ZFLAG_reg	st->ZFlag
#define CFLAG_reg	st->CFlag
#define VFLAG_reg	st->VFlag
//teawater change for debug function 2005.07.26---------------------------------
#define QFLAG_reg	st->SFlag
//AJ2D--------------------------------------------------------------------------

#define CP_ACCESS_ALLOWED(STATE, CP)			\
    (   ((CP) >= 14)					\
     || (! (STATE)->is_XScale)				\
     || (xscale_cp15_cp_access_allowed(STATE,15,CP)))

#endif //_ARM2X86_SELF_H_
