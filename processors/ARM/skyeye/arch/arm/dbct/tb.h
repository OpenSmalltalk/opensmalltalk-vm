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

#ifndef _TB_H_
#define _TB_H_

#define ALIGN(val,align)	(val - val % align)

#define TB_INSN_LEN_MAX		tb_insn_len_max
//teawater change align to make speed up 2005.07.22-----------------------------
//teawater change TB_LEN to 512 2005.10.10--------------------------------------
//#define TB_LEN			(1 << 8)		//256
#define TB_LEN			(1 << 10)		//1024
//AJ2D--------------------------------------------------------------------------
#define TB_ALIGN(a)		(a & (~(TB_LEN - 1)))
//AJ2D--------------------------------------------------------------------------

#define TB_TBP_MAX		(TB_LEN / sizeof(ARMword) * TB_INSN_LEN_MAX + op_return.len)
//teawater add tb_insn_addr 2005.10.06------------------------------------------
//#define TB_TBT_CACHE_MAX	8
//AJ2D--------------------------------------------------------------------------
#define TB_TBP_DEFAULT		(1024 * 1024 * 64)

typedef struct tb_cache_s
{
	struct list_head list;
	ARMword addr;
	uint8_t *tp;
} tb_cache_t;

typedef struct tb_s
{
//teawater add for new tb manage function 2005.07.10----------------------------
	struct list_head list;
//AJ2D--------------------------------------------------------------------------
	int ted;		//0 not translated      1 already translated
//teawater add tb_insn_addr 2005.10.06------------------------------------------
	//struct list_head	cache[TB_TBT_CACHE_MAX];	//if set ted = 0 must clear it
	uint8_t			*insn_addr[TB_LEN / sizeof(uint8_t *)];
//AJ2D--------------------------------------------------------------------------
//teawater add for new tb manage function 2005.07.10----------------------------
	uint8_t *tbp;
	ARMword addr;
//AJ2D--------------------------------------------------------------------------
//teawater change for if trap translate stop 2005.07.23-------------------------
	ARMword tran_addr;
	uint8_t *tbp_now;
//AJ2D--------------------------------------------------------------------------
//teawater add last use addr 2005.10.10-----------------------------------------
	ARMword			last_addr;
	uint8_t			*last_tbp;
//AJ2D--------------------------------------------------------------------------
//teawater change for local tb branch directly jump 2005.10.17------------------
	ARMword			ret_addr;
//AJ2D--------------------------------------------------------------------------
} tb_t;

extern int tb_insn_len_max;

extern uint8_t *tb_find (ARMul_State * state, ARMword addr);
extern int tb_insn_len_max_init (ARMul_State * state);

#ifndef TEA_OUT
//#define TEA_DEBUG
#ifdef TEA_DEBUG
#define TEA_OUT(a)	a
#else
#define TEA_OUT(a)
#endif
#endif

#endif //_TB_H_
