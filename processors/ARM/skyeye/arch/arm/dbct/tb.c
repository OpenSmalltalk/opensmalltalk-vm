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
//teawater 2005-09-12  for gcc-3.3.x compiling, comment below line
//#include "arm2x86_self.h"

extern mem_bank_t *bank_ptr (ARMword addr);

/*ywc 2005-04-22, in armmem.c*/
extern mem_bank_t *insn_bank_ptr (ARMword addr);

extern ARMul_State *state;

//teawater add for new tb manage function 2005.07.10----------------------------
//static uint32_t       tb_tbt_size = 0;
//static uint32_t       tb_tbp_size = (1024 * 1024 * 32);
#define TB_TBT_SIZE	skyeye_config.tb_tbt_size
#define TB_TBP_SIZE	skyeye_config.tb_tbp_size

static tb_t *tbt_table = NULL;
static int tbt_table_size = 0;

static uint8_t *tbp_begin = NULL;
static uint8_t *tbp_now = NULL;
static uint32_t tbp_now_size = 0;
static int tbp_dynamic = 0;
static LIST_HEAD (tbp_dynamic_list);
//AJ2D--------------------------------------------------------------------------
#if defined(__FreeBSD__) || defined(__APPLE__)
#define MAP_ANONYMOUS MAP_ANON
#endif

static __inline__ int
translate_word (ARMul_State * state, ARMword insn, uint8_t * tbp)
{
	int toplen = 0, len = 0;
//teawater add for xscale(arm v5) 2005.09.26------------------------------------
	ARMword cond, val, op1, shift, rm, rs, rn, rd, sh, y, x;
//AJ2D--------------------------------------------------------------------------
	uint8_t *begin = tbp;

	//init
	begin = tbp;
	state->trap = 0;

//teawater change for debug function 2005.07.09---------------------------------
	//breakpoint
	if (insn == 0xe7ffdefe) {
		GEN_OP (tbp, len, op_begin);
		gen_op_movl_trap_im_use_T2 (state, &tbp, &len,
					    TRAP_BREAKPOINT);
		GEN_OP (tbp, len, op_return);
		goto out;
	}
//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.01------------------------------------
	if ((insn & 0xfff000f0) == 0xe1200070) {
		//BKPT
		//GEN_OP(tbp, len, op_begin);
		gen_op_movl_trap_im_use_T2 (state, &tbp, &len,
					    TRAP_INSN_ABORT);
		GEN_OP (tbp, len, op_return);
		goto out;
	}
//AJ2D--------------------------------------------------------------------------

	//return if debug || irq || fiq || condition
	cond = (insn >> 28) & 0xff;
	if (cond == AL || cond == NV) {
		GEN_OP (tbp, len, op_begin);
		//some insn need it
		//if (cond == NV)
		//      goto translate_word_out;
	}
	else {
		gen_op_movl_Tx_im (state, &tbp, &len, 0, cond);
		GEN_OP (tbp, len, op_begin_test_T0);
		toplen = len;
	}

	if (((insn & 0x0e000000) == 0 && (insn & 0x00000090) != 0x90)
	    || ((insn & 0x0e000000) == (1 << 25))) {
		ARMword set_cc, logic_cc, shiftop;

		if (cond == NV)
			goto translate_word_out;

		op1 = (insn >> 21) & 0xf;
		set_cc = (insn >> 20) & 1;

//teawater add for xscale(arm v5) 2005.09.01------------------------------------
		if (!set_cc & (op1 >= 0x8 && op1 <= 0xb)) {
			if (state->is_v5) {
				sh = ((insn >> 4) & 0xf);
				if (sh == 0x5) {
					rm = (insn >> 0) & 0xf;
					rd = (insn >> 12) & 0xf;
					rn = (insn >> 16) & 0xf;
					switch (op1) {
					case 0x8:
						//qadd
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 0,
								    rm);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rd);
						GEN_OP (tbp, len,
							op_qaddl_T0_T1_sq);
						break;
					case 0x9:
						//qsub
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 0,
								    rm);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rd);
						GEN_OP (tbp, len,
							op_qsubl_T0_T1_sq);
						break;
					case 0xa:
						//qdadd
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 0,
								    rn);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rn);
						GEN_OP (tbp, len,
							op_qaddl_T0_T1_sq);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rm);
						GEN_OP (tbp, len,
							op_qaddl_T0_T1_sq);
						break;
					case 0xb:
						//qdsub
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 0,
								    rn);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rn);
						GEN_OP (tbp, len,
							op_qaddl_T0_T1_sq);
						GEN_OP (tbp, len,
							op_movl_T1_T0);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 0,
								    rm);
						GEN_OP (tbp, len,
							op_qsubl_T0_T1_sq);
						break;
					}
					gen_op_movl_reg_Tx (state, &tbp, &len,
							    rd, 0);
					GEN_OP (tbp, len, op_set_q);
					goto translate_word_end;
				}
				else if ((sh & 0x9) == 0x8) {
					rm = (insn >> 0) & 0xf;
					rs = (insn >> 8) & 0xf;
					rn = (insn >> 12) & 0xf;	//rdlo
					rd = (insn >> 16) & 0xf;	//rdhi
					y = (insn >> 6) & 0x1;
					x = (insn >> 5) & 0x1;
					gen_op_movl_Tx_reg (state, &tbp, &len,
							    0, rm);
					gen_op_movl_Tx_reg (state, &tbp, &len,
							    1, rs);
					if (op1 != 0x9) {
						if (x) {
							//t
							GEN_OP (tbp, len,
								op_hi_T0);
						}
						else {
							//b
							GEN_OP (tbp, len,
								op_lo_T0);
						}
						GEN_OP (tbp, len,
							op_signextend_halfword_T0);
					}
					if (y) {
						//t
						GEN_OP (tbp, len, op_hi_T1);
					}
					else {
						//b
						GEN_OP (tbp, len, op_lo_T1);
					}
					GEN_OP (tbp, len,
						op_signextend_halfword_T1);
					switch (op1) {
					case 0x8:
						//smlaxy
						GEN_OP (tbp, len,
							op_mul_T0_T1);
						gen_op_movl_Tx_reg (state,
								    &tbp,
								    &len, 1,
								    rn);
						GEN_OP (tbp, len,
							op_addl_T0_T1_sq);
						gen_op_movl_reg_Tx (state,
								    &tbp,
								    &len, rd,
								    0);
						GEN_OP (tbp, len, op_set_q);
						break;
					case 0x9:
						if (x) {
							//smulwy
							GEN_OP (tbp, len,
								op_smulwy_T0_T1);
							gen_op_movl_reg_Tx
								(state, &tbp,
								 &len, rd, 0);
						}
						else {
							//smlawy
							//gen_op_movl_Tx_reg(state, &tbp, &len, 2, rn);
							//GEN_OP(tbp, len, op_smlawy_T2_T1_T0);
							GEN_OP (tbp, len,
								op_smulwy_T0_T1);
							gen_op_movl_Tx_reg
								(state, &tbp,
								 &len, 1, rn);
							GEN_OP (tbp, len,
								op_addl_T0_T1_sq);
							gen_op_movl_reg_Tx
								(state, &tbp,
								 &len, rd, 0);
							GEN_OP (tbp, len,
								op_set_q);
						}
						break;
					case 0xa:
						//smlalxy
						GEN_OP (tbp, len,
							op_mul_T0_T1);
						gen_op_movl_Tx_reg (state, &tbp, &len, 1, rn);	//rdlo
						gen_op_movl_Tx_reg (state, &tbp, &len, 2, rd);	//rdhi
						GEN_OP (tbp, len,
							op_smlalxy_T2_T1_T0);
						gen_op_movl_reg_Tx (state,
								    &tbp,
								    &len, 1,
								    rn);
						gen_op_movl_reg_Tx (state,
								    &tbp,
								    &len, 2,
								    rd);
						break;
					case 0xb:
						//smulxy
						GEN_OP (tbp, len,
							op_mul_T0_T1);
						gen_op_movl_reg_Tx (state,
								    &tbp,
								    &len, rd,
								    0);
						break;
					}
					goto translate_word_end;
				}
				else if (sh == 0x1 && op1 == 0xb) {
					//clz
					rm = insn & 0xf;
					gen_op_movl_Tx_reg (state, &tbp, &len,
							    1, rm);
					GEN_OP (tbp, len, op_clzl_T0_T1);
					rd = (insn >> 12) & 0xf;
					gen_op_movl_reg_Tx (state, &tbp, &len,
							    rd, 0);
					goto translate_word_end;
				}
			}

			if (op1 == 0x8 || op1 == 0xa) {
				//mrs
				gen_op_mrs (state, &tbp, &len, insn);
				goto translate_word_end;
			}
		}
//AJ2D--------------------------------------------------------------------------

		logic_cc = table_logic_cc[op1] & set_cc;
		//in arm_arm A 5.1
		if (insn & (1 << 25)) {
			//immediate operand arm_arm A 5.1.3
			val = insn & 0xff;
			shift = (uint8_t) ((insn >> 8) & 0xf) * 2;
			//ror
			if (shift)
				val = (val >> shift) | (val << (32 - shift));
			//op=set val to t1
			gen_op_movl_Tx_im (state, &tbp, &len, 1, val);

			if (logic_cc && shift) {
				//val = ((insn & 0xff) >> (shift - 1)) & 1;
				//op=set val[31] to C
				if (val >> 31) {
					GEN_OP (tbp, len, op_logic_1_sc);
				}
				else {
					GEN_OP (tbp, len, op_logic_0_sc);
				}
			}
		}
		else {
			//register
			rm = (insn) & 0xf;
			//op=set rm(0-15) to t1
			gen_op_movl_Tx_reg (state, &tbp, &len, 1, rm);

//teawater add check thumb 2005.07.21-------------------------------------------
			if (op1 == 0x9 && !set_cc
			    && ((insn >> 8) & 0xf) == 0xf) {
				//bx or blx(2)
				uint32_t tmp = (insn >> 4) & 0xf;

				if (tmp == 0x1) {
					//bx
					GEN_OP (tbp, len, op_bx_T1);
				}
				else if (tmp == 0x2) {
					//blx(2)
					GEN_OP (tbp, len, op_blx_T1);
				}
				if (tmp == 0x1 || tmp == 0x2) {
					state->trap = 1;
					goto translate_word_end;
				}
			}
//AJ2D--------------------------------------------------------------------------

			shiftop = (insn >> 5) & 3;
			if (!(insn & (1 << 4))) {
				//imm
				shift = (uint8_t) (insn >> 7) & 0x1f;
				if (shift != 0) {
					//op=shift, & set CF if logic_cc
					if (logic_cc) {
						gen_op_shift_T1_im_sc (state,
								       &tbp,
								       &len,
								       shiftop,
								       shift);
					}
					gen_op_shift_T1_im (state, &tbp, &len,
							    shiftop, shift);
				}
				else {
					GEN_OP (tbp, len, op_movl_T2_T1);
					GEN_OP (tbp, len,
						op_shift_T1_0[shiftop]);
					if (logic_cc) {
						GEN_OP (tbp, len,
							op_shift_T2_0_sc
							[shiftop]);
						GEN_OP (tbp, len, op_set_cf);
					}
				}
			}
			else {
				//reg
				rs = (insn >> 8) & 0xf;
				//op=set rs(0-15) to t0
				gen_op_movl_Tx_reg (state, &tbp, &len, 0, rs);
				//op=shift, & set CF if logic_cc
				if (logic_cc) {
					//op=shift & set CF
					gen_op_shift_T1_T0_sc (state, &tbp,
							       &len, shiftop);
				}
				else {
					//op=shift
					gen_op_shift_T1_T0 (state, &tbp, &len,
							    shiftop);
				}
			}
		}

		if ((op1 == 0x9 || op1 == 0xb) && !set_cc) {
			//msr   T1, psr
			gen_op_msr (state, &tbp, &len, insn);
			goto translate_word_end;
		}

		//data processing instruction
		if (op1 != 0x0f && op1 != 0x0d) {	//!mov && !mvn
			rn = (insn >> 16) & 0xf;
			//op=set rn(0-15) to t0
			gen_op_movl_Tx_reg (state, &tbp, &len, 0, rn);
		}
		rd = (insn >> 12) & 0xf;
		arm2x86_get_dp_op[op1] (state, &tbp, &len, set_cc, rd);
		arm2x86_get_dp_op_setcpsr[op1] (state, &tbp, &len, set_cc,
						rd);
	}
	else {
		//other instructions
		op1 = (insn >> 24) & 0xf;
		sh = (insn >> 5) & 3;

		if (cond == NV) {
//teawater add for xscale(arm v5) 2005.09.15------------------------------------
			if (state->is_v5) {
				switch (op1) {
				case 0x5:
				case 0x7:
					if (((insn >> 12) & 0xf) == 0xf) {
						//pld Ignored

					}
					goto translate_word_out;
					break;
//teawater add check thumb 2005.07.21-------------------------------------------
				case 0xa:
				case 0xb:
					//blx(1)
					gen_op_movl_trap_im_use_T2 (state,
								    &tbp,
								    &len,
								    TRAP_UNPREDICTABLE);
					GEN_OP (tbp, len, op_return);
					goto out;
					break;
//AJ2D--------------------------------------------------------------------------
				case 0xc:
				case 0xd:
					//ldc2 stc2
					if (state->is_XScale
					    && ((insn >> 8) & 0xf) == 0) {
						//mar mra
						goto translate_word_out;
					}
					break;
				case 0xe:
					//cdp2 mrc2 mcr2
					if (state->is_XScale
					    && (insn & (1 << 4))
					    && (!(insn & (1 << 20)))
					    && ((insn >> 8) & 0xf) == 0) {
						//mia miaph miabb miabt miatb miatt
						goto translate_word_out;
					}
					break;
				default:
					goto translate_word_out;
					break;
				}
			}
//AJ2D--------------------------------------------------------------------------
			else {
				goto translate_word_out;
			}
		}

		if (sh != 0 && (op1 == 0 || op1 == 1)) {
			//ldrh strh ldrsh ldrsb
			gen_op_ldrhstrh (state, &tbp, &len, insn, sh);
		}
		else {
			arm2x86_get_other_op[op1] (state, insn, &tbp, &len);
		}
	}

      translate_word_end:
	if (state->trap) {
		GEN_OP (tbp, len, op_return);
	}
	if (toplen && begin) {
		//set jmp length of condition code
		//begin[toplen-1] = (uint8_t)(len - toplen);
		int *p_tmp = (int *) (begin + (toplen - sizeof (int)));
		*p_tmp = len - toplen;
	}

      translate_word_out:
	//r15 += 4
	if (!state->trap || toplen) {
		GEN_OP (tbp, len, op_addpc);
		state->trap = 0;
	}
	//TEA_OUT(GEN_OP(tbp, len, op_return));

      out:
	if (len > TB_INSN_LEN_MAX) {
		fprintf (stderr,
			 "SKYEYE: TB_INSN_LEN_MAX: insn %x len %d > TB_INSN_LEN_MAX %d.\n",
			 insn, len, TB_INSN_LEN_MAX);
		skyeye_exit (-1);
	}
/*#ifdef TEA_DEBUG
	{
		static int	insn_max = 0;
		if (len > insn_max) {
			insn_max = len;
			fprintf(stderr, "\nSKYEYE: insn_max = %d.\n", insn_max);
		}
	}
#endif	//TEA_DEBUG*/

	return (len);
}

//teawater add tb_insn_addr 2005.10.08------------------------------------------
/*
static uint8_t *
tb_translate(ARMul_State * state, ARMword *addr, ARMword *tb_begin_addr, uint8_t *tbp, ARMword *tran_addr, uint8_t **tbp_now)
*/
static uint8_t *
tb_translate(ARMul_State * state, ARMword *addr, ARMword *tb_begin_addr, tb_t *tbt)
{
	int		len;
	uint8_t		*ret = NULL;
//	ARMword		*tb_end_addr = tb_begin_addr + (TB_LEN - (*tran_addr - TB_ALIGN(*tran_addr)))  / sizeof(ARMword);
	ARMword		*tb_end_addr = tb_begin_addr + (TB_LEN - (tbt->tran_addr - TB_ALIGN(tbt->tran_addr)))  / sizeof(ARMword);
//teawater change for local tb branch directly jump 2005.10.10------------------
	tb_branch_save_t	*e;
	struct list_head	*list,*n;
//AJ2D--------------------------------------------------------------------------

//teawater change for local tb branch directly jump 2005.10.10------------------
	INIT_LIST_HEAD(&tb_branch_save_list);
	now_tbt = tbt;
	tbt->ret_addr = 0;
//AJ2D--------------------------------------------------------------------------
	for( ; tb_begin_addr < tb_end_addr; tb_begin_addr++) {
		//set ret
		if (addr == tb_begin_addr) {
			ret = tbt->tbp_now;
		}
		//set insn_addr
		tbt->insn_addr[(tbt->tran_addr - tbt->addr) / sizeof(uint8_t *)] = tbt->tbp_now;

		//translate
		len = translate_word(state, *tb_begin_addr, tbt->tbp_now);
		tbt->tbp_now += len;
//teawater change for if trap translate stop 2005.07.23-------------------------
		//*tran_addr += 4;
		tbt->tran_addr += 4;
		if (state->trap && ret && (tbt->tran_addr > tbt->ret_addr)) {
			break;
		}
//AJ2D--------------------------------------------------------------------------
	}
//teawater change for if trap translate stop 2005.07.23-------------------------
	//*tbp_now = tbp;
	if (!state->trap) {
		GEN_OP(tbt->tbp_now, len, op_return);
	}
//AJ2D--------------------------------------------------------------------------
//teawater change for local tb branch directly jump 2005.10.10------------------
	list_for_each_safe(list, n, &tb_branch_save_list) {
		e = list_entry(list, tb_branch_save_t, list);
		//memcpy((e->tbp - sizeof(ARMword)), &((uint32_t)tbt->insn_addr[(e->dst_addr - tbt->addr) / sizeof(uint8_t *)] - (uint32_t)e->tbp), sizeof(ARMword));
		*((uint32_t *)(e->tbp - sizeof(ARMword))) = (uint32_t)tbt->insn_addr[(e->dst_addr - tbt->addr) / sizeof(uint8_t *)] - (uint32_t)e->tbp;
	}
//AJ2D--------------------------------------------------------------------------

	return(ret);
}
//AJ2D--------------------------------------------------------------------------

//teawater remove tb_translate_find 2005.10.21----------------------------------
/*static uint8_t *
tb_translate_find (ARMul_State * state, ARMword * addr,
		   ARMword * tb_begin_addr, uint8_t * tbp)
{
	int len;
	uint8_t *ret = NULL;
	ARMword *tb_end_addr = tb_begin_addr + TB_LEN / sizeof (ARMword);

	for (; tb_begin_addr < tb_end_addr; tb_begin_addr++) {
		if (addr == tb_begin_addr) {
			ret = tbp;
			break;
		}
		len = translate_word (state, *tb_begin_addr, NULL);
		tbp += len;
	}

	return (ret);
}*/
//AJ2D--------------------------------------------------------------------------

//teawater add tb_insn_addr 2005.10.06------------------------------------------
/*
static inline void
tb_insert_cache (tb_t * tbt, ARMword addr, uint8_t * ret)
{
	tb_cache_t *e = malloc (sizeof (tb_cache_t));

	if (e) {
		uint32_t cache_num = addr & (TB_TBT_CACHE_MAX - 1);

		if (!tbt->cache[cache_num].next)
			INIT_LIST_HEAD (&tbt->cache[cache_num]);
		e->addr = addr;
		e->tp = ret;
		list_add_tail (&e->list, &tbt->cache[cache_num]);
	}
	else {
		TEA_OUT (fprintf
			 (stderr,
			  "SKYEYE: tb_find: Error allocating mem for cache.\n"));
	}
}

static inline uint8_t *
tb_find_cache (tb_t * tbt, ARMword addr)
{
	tb_cache_t *e;
	struct list_head *list, *n;
	uint32_t cache_num = addr & (TB_TBT_CACHE_MAX - 1);

	if (tbt->cache[cache_num].next) {
		list_for_each_safe (list, n, &tbt->cache[cache_num]) {
			e = list_entry (list, tb_cache_t, list);
			if (e->addr == addr) {
				return (e->tp);
			}
		}
	}

	return (NULL);
}

static inline void
tb_clear_cache (tb_t * tbt)
{
	tb_cache_t *e;
	struct list_head *list, *n;
	uint32_t cache_num;

	for (cache_num = 0; cache_num < TB_TBT_CACHE_MAX; cache_num++) {
		if (tbt->cache[cache_num].next) {
			list_for_each_safe (list, n, &tbt->cache[cache_num]) {
				e = list_entry (list, tb_cache_t, list);
				list_del_init (&e->list);
				free (e);
			}
		}
	}
}
*/
//AJ2D--------------------------------------------------------------------------

static inline void
tb_get_tbp (tb_t * tbt)
{
	tb_t *e;
	struct list_head *list;

	if (tbp_now_size) {
		tbt->tbp = tbp_now;
		tbp_now += TB_TBP_MAX;
		tbp_now_size -= TB_TBP_MAX;
	}
	else {
		//get the oldest tbt from tbp_dynamic_list's head
		if (list_empty (&tbp_dynamic_list)) {
			fprintf (stderr, "SKYEYE: mem_reset: some bug.\n");
			skyeye_exit (-1);
		}
		e = list_entry (tbp_dynamic_list.next, tb_t, list);
		tbt->tbp = e->tbp;
		e->tbp = NULL;
//teawater add tb_insn_addr 2005.10.06------------------------------------------
		/*if (e->ted) {
			tb_clear_cache(e);
			e->ted = 0;
		}*/
		e->ted = 0;
//AJ2D--------------------------------------------------------------------------
		list_del_init (&e->list);
	}
}

static inline mem_bank_t *
tb_get_mbp (ARMword addr, int *bank_num)
{
	mem_bank_t *ret;

	ret = insn_bank_ptr (addr);
	if (ret) {
		*bank_num = ret - state->mem_bank->mem_banks;
	}

	return (ret);
}

uint8_t *
tb_find (ARMul_State * state, ARMword ADDR)
{
	uint8_t *ret = NULL;
	ARMword addr, align_addr;
	ARMword *real_begin_addr, *real_addr;
	static ARMword save_align_addr = 0x1;
	static tb_t *tbt;
	static uint8_t *tbp;
	static mem_bank_t *mbp;
	static int bank_num = -1;

	//get addr & align_addr
	if (mmu_v2p_dbct (state, ADDR, &addr)) {
		goto out;
	}
	align_addr = TB_ALIGN (addr);
	if (align_addr == save_align_addr) {
		goto get_ret;
	}

	//init
	bank_num = -1;
	save_align_addr = 0x1;

	//get tbt
	if (tbt_table_size) {
		//dynamic tbt
		tbt = &(tbt_table
			[align_addr & (uint32_t) (tbt_table_size - 1)]);
		if (tbt->addr != align_addr) {
			if (tbt->ted) {
//teawater add tb_insn_addr 2005.10.06------------------------------------------
				//tb_clear_cache(tbt);
//AJ2D--------------------------------------------------------------------------
				tbt->ted = 0;
			}
			tbt->addr = align_addr;
		}

		//get tbt->tbp
		if (!tbt->tbp) {
			tb_get_tbp (tbt);
		}
		else {
			if (tbp_dynamic) {
				list_del_init (&tbt->list);
			}
		}
	}
	else {
		//static tbt
		mbp = tb_get_mbp (align_addr, &bank_num);
		if (!mbp) {
			goto out;
		}
		if (!state->mem.tbt[bank_num]) {
			if (!tbp_dynamic) {
				state->mem.tbp[bank_num] =
					mmap (NULL,
					      state->mem.rom_size[bank_num] /
					      sizeof (ARMword) *
					      TB_INSN_LEN_MAX +
					      state->mem.rom_size[bank_num] /
					      TB_LEN * op_return.len,
					      PROT_READ | PROT_WRITE |
					      PROT_EXEC,
					      MAP_PRIVATE | MAP_ANONYMOUS, -1,
					      0);
				if (state->mem.tbp[bank_num] == MAP_FAILED) {
					fprintf (stderr,
						 "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n",
						 bank_num);
					skyeye_exit (-1);
				}
			}
			state->mem.tbt[bank_num] =
				malloc (state->mem.rom_size[bank_num] /
					TB_LEN * sizeof (tb_t));
			if (!state->mem.tbt[bank_num]) {
				fprintf (stderr,
					 "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n",
					 bank_num);
				skyeye_exit (-1);
			}
			memset (state->mem.tbt[bank_num], 0,
				state->mem.rom_size[bank_num] / TB_LEN *
				sizeof (tb_t));
		}
		tbt = &(state->mem.
			tbt[bank_num][(align_addr - mbp->addr) / TB_LEN]);
//teawater add tb_insn_addr 2005.10.08------------------------------------------
		tbt->addr = align_addr;
//AJ2D--------------------------------------------------------------------------

		//get tbt->tbp
		if (!tbt->tbp) {
			if (tbp_dynamic) {
				//dynamic tbp
				tb_get_tbp (tbt);
			}
			else {
				tbt->tbp =
					&(state->mem.
					  tbp[bank_num][(align_addr -
							 mbp->addr) /
							sizeof (ARMword) *
							TB_INSN_LEN_MAX +
							(align_addr -
							 mbp->addr) / TB_LEN *
							op_return.len]);
			}
		}
		else {
			if (tbp_dynamic) {
				list_del_init (&tbt->list);
			}
		}
	}

	//get tbp
	tbp = tbt->tbp;

	//set tb_now to check the current running block is written.
	state->tb_now = (void *) tbt;

	//set save_align_addr
	save_align_addr = align_addr;

	//add tbt to tbp_dynamic_list's tail to be the newest one
	if (tbp_dynamic) {
		list_add_tail (&tbt->list, &tbp_dynamic_list);
	}

	//find ret from tb
      get_ret:
	if (tbt->ted) {
		//tbt has been translated
//teawater add last use addr 2005.10.10-----------------------------------------
		if (tbt->last_addr == addr) {
			return(tbt->last_tbp);
		}

		//addr is align
		/*if (addr == align_addr) {
			ret = tbp;
			goto out;
		}*/
//AJ2D--------------------------------------------------------------------------

		if (addr >= tbt->tran_addr) {
			//block need continue translate
			if (bank_num == -1) {
				mbp = tb_get_mbp (align_addr, &bank_num);
				if (!mbp) {
					goto out;
				}
			}
			real_begin_addr =
				&(state->mem.
				  rom[bank_num][(align_addr -
						 mbp->addr) /
						sizeof (ARMword)]) +
				(tbt->tran_addr -
				 align_addr) / sizeof (ARMword);
			real_addr =
				real_begin_addr + (addr -
						   tbt->tran_addr) /
				sizeof (ARMword);
//teawater add tb_insn_addr 2005.10.08------------------------------------------
			//ret = tb_translate(state, real_addr, real_begin_addr, tbt->tbp_now, &tbt->tran_addr, &tbt->tbp_now);
			ret = tb_translate(state, real_addr, real_begin_addr, tbt);
//AJ2D--------------------------------------------------------------------------
		}
		else {
//teawater add tb_insn_addr 2005.10.08------------------------------------------
			/*//find in cache
			ret = tb_find_cache(tbt, addr);
			if (ret) {
				goto out;
			}

			if (bank_num == -1) {
				mbp = tb_get_mbp(align_addr, &bank_num);
				if(!mbp) {
					goto out;
				}
			}
			real_begin_addr = &(state->mem.rom[bank_num][(align_addr - mbp->addr) / sizeof(ARMword)]);
			real_addr = real_begin_addr + (addr - align_addr) / sizeof(ARMword);
			ret = tb_translate_find(state, real_addr, real_begin_addr, tbp);*/

			//find in insn_addr
			ret = tbt->insn_addr[(addr - align_addr) / sizeof(uint8_t *)];
//AJ2D--------------------------------------------------------------------------
		}
	}
	else {
		//tbt has not been translated
		if (bank_num == -1) {
			mbp = tb_get_mbp (align_addr, &bank_num);
			if (!mbp) {
				goto out;
			}
		}
		real_begin_addr =
			&(state->mem.
			  rom[bank_num][(align_addr -
					 mbp->addr) / sizeof (ARMword)]);
		real_addr =
			real_begin_addr + (addr -
					   align_addr) / sizeof (ARMword);
		tbt->tran_addr = align_addr;
//teawater add tb_insn_addr 2005.10.08------------------------------------------
		//ret = tb_translate(state, real_addr, real_begin_addr, tbp, &tbt->tran_addr, &tbt->tbp_now);
		tbt->tbp_now = tbp;
		ret = tb_translate(state, real_addr, real_begin_addr, tbt);
		/*if (ret) {
			tbt->ted = 1;
		}*/
		tbt->ted = 1;
//AJ2D--------------------------------------------------------------------------
	}

//teawater add tb_insn_addr 2005.10.08------------------------------------------
	/*if (ret) {
		tb_insert_cache(tbt, addr, ret);
	}*/
//AJ2D--------------------------------------------------------------------------
      out:
//teawater add last use addr 2005.10.10-----------------------------------------
	if (ret) {
		tbt->last_addr = addr;
		tbt->last_tbp = ret;
	}
//AJ2D--------------------------------------------------------------------------
	return (ret);
}

int
tb_setdirty (ARMul_State * state, ARMword addr, mem_bank_t * mbp)
{
	ARMword align_addr = TB_ALIGN (addr);
	static ARMword save_align_addr = 0x1;
	static tb_t *tbt = NULL;

	if (save_align_addr == align_addr) {
		goto setdirty;
	}

	save_align_addr = 0x1;
	//get tbt
	if (tbt_table_size) {
		tbt = &(tbt_table
			[align_addr & (uint32_t) (tbt_table_size - 1)]);
		if (tbt->addr != align_addr) {
			return (0);
		}
	}
	else {
		int bank_num;

		if (!mbp) {
			mbp = tb_get_mbp (align_addr, &bank_num);
			if (!mbp) {
				return (0);
			}
		}
		else {
			bank_num = mbp - state->mem_bank->mem_banks;
		}
		if (!state->mem.tbt[bank_num]) {
			return (0);
		}
		tbt = &(state->mem.
			tbt[bank_num][(align_addr - mbp->addr) / TB_LEN]);
	}
	save_align_addr = align_addr;

      setdirty:
	if (tbt->ted) {
//teawater add tb_insn_addr 2005.10.09------------------------------------------
		//tb_clear_cache(tbt);
//AJ2D--------------------------------------------------------------------------
		tbt->ted = 0;
		switch (state->cpu->cpu_val & state->cpu->cpu_mask) {
		case SA1100:
		case SA1110:
			mmu_wb_drain_all (state, (&state->mmu.u.sa_mmu.wb_t));
			break;
		case 0x41009200:
			mmu_wb_drain_all (state,
					  (&state->mmu.u.arm920t_mmu.wb_t));
			break;
		};
	}

	return (0);
}

int tb_insn_len_max = 0;

int
tb_insn_len_max_init (ARMul_State * state)
{
	int dp_len = 0, other_len = 0;

	//return if debug || irq || fiq || condition
	if (op_begin.len >
	    op_movl_Tx_im[0].len + sizeof (ARMword) + op_begin_test_T0.len) {
		tb_insn_len_max += op_begin.len;
	}
	else {
		tb_insn_len_max +=
			op_movl_Tx_im[0].len + sizeof (ARMword) +
			op_begin_test_T0.len;
	}

	//end
	tb_insn_len_max += op_return.len;
	tb_insn_len_max += op_addpc.len;
	//TEA_OUT(tb_insn_len_max += op_return.len);

	//dp_len
	{
		int dp_head_len = 0;
		int sm_head;
		int op_setcpsr_nzc_len = 0, op_setcpsr_nzc_setr15_len =
			0, op_setcpsr_nzc_notsetr15_len =
			0, op_setcpsr_nzc_setreg_len = 0;
		int op_setcpsr_nzcv_len = 0, op_setcpsr_nzcv_setr15_len =
			0, op_setcpsr_nzcv_notsetr15_len =
			0, op_setcpsr_nzcv_setreg_len = 0;
		int dp_tmp1;

		//dp_head_len
		{
			int dp_head_imm_len = 0, dp_head_reg_len = 0;

			//dp_head_imm_len
			dp_head_imm_len += op_movl_Tx_im[1].len;
			dp_head_imm_len += sizeof (ARMword);
			if (op_logic_1_sc.len > op_logic_0_sc.len) {
				dp_head_imm_len += op_logic_1_sc.len;
			}
			else {
				dp_head_imm_len += op_logic_0_sc.len;
			}

			//dp_head_reg_len
			{
				int dp_head_reg_imm_len =
					0, dp_head_reg_reg_len = 0;

				dp_head_reg_len +=
					op_movl_Tx_reg_array_maxlen[1];

				//dp_head_reg_imm_len
				//shift != 0
				dp_head_reg_imm_len +=
					op_shift_T1_im_sc_maxlen;
				dp_head_reg_imm_len += op_set_cf.len;
				dp_head_reg_imm_len += op_shift_T1_im_maxlen;
				dp_head_reg_imm_len += sizeof (uint8_t);
				//shift == 0
				dp_tmp1 = op_movl_T2_T1.len;
				dp_tmp1 += op_shift_T1_0_maxlen;
				dp_tmp1 += op_shift_T2_0_sc_maxlen;
				dp_tmp1 += op_set_cf.len;
				//compare
				if (dp_tmp1 > dp_head_reg_imm_len)
					dp_head_reg_imm_len = dp_tmp1;

				//dp_head_reg_reg_len
				if (op_shift_T1_T0_sc_maxlen + op_set_cf.len >
				    op_shift_T1_T0_maxlen) {
					dp_head_reg_reg_len +=
						op_shift_T1_T0_sc_maxlen +
						op_set_cf.len;
				}
				else {
					dp_head_reg_reg_len +=
						op_shift_T1_T0_maxlen;
				}
				dp_head_reg_reg_len +=
					op_movl_Tx_reg_array_maxlen[0];

				if (dp_head_reg_imm_len > dp_head_reg_reg_len) {
					dp_head_reg_len +=
						dp_head_reg_imm_len;
				}
				else {
					dp_head_reg_len +=
						dp_head_reg_reg_len;
				}
			}

			if (dp_head_imm_len > dp_head_reg_len) {
				dp_head_len = dp_head_imm_len;
			}
			else {
				dp_head_len = dp_head_reg_len;
			}
		}

		//op_setcpsr_nzc_len
		op_setcpsr_nzc_len += op_logic_T0_sn.len;
		//op_setcpsr_nzc_len += op_set_nf.len;
		op_setcpsr_nzc_len += op_logic_T0_sz.len;
		//op_setcpsr_nzc_len += op_set_zf.len;
		//op_setcpsr_nzc_len += op_set_cf.len;
		op_setcpsr_nzc_len += op_set_nzcf.len;

		//op_setcpsr_nzcv_len
		op_setcpsr_nzcv_len += op_logic_T0_sn.len;
		//op_setcpsr_nzcv_len += op_set_nf.len;
		op_setcpsr_nzcv_len += op_logic_T0_sz.len;
		//op_setcpsr_nzcv_len += op_set_zf.len;
		//op_setcpsr_nzcv_len += op_set_cf.len;
		//op_setcpsr_nzcv_len += op_set_vf.len;
		op_setcpsr_nzcv_len += op_set_nzcvf.len;

		//op_setcpsr_nzc_setreg
		op_setcpsr_nzc_notsetr15_len += op_setcpsr_nzc_len;
		op_setcpsr_nzc_notsetr15_len +=
			op_movl_reg_Tx_array_maxlen[0];
		op_setcpsr_nzc_setr15_len += op_movl_reg_Tx_array_maxlen[0];
		op_setcpsr_nzc_setr15_len +=
			op_movl_Tx_im[2].len + sizeof (ARMword) +
			op_movl_trap_T2.len;
		if (op_setcpsr_nzc_notsetr15_len > op_setcpsr_nzc_setr15_len) {
			op_setcpsr_nzc_setreg_len +=
				op_setcpsr_nzc_notsetr15_len;
		}
		else {
			op_setcpsr_nzc_setreg_len +=
				op_setcpsr_nzc_setr15_len;
		}

		//op_setcpsr_nzcv_setreg
		op_setcpsr_nzcv_notsetr15_len += op_setcpsr_nzcv_len;
		op_setcpsr_nzcv_notsetr15_len +=
			op_movl_reg_Tx_array_maxlen[0];
		op_setcpsr_nzcv_setr15_len += op_movl_reg_Tx_array_maxlen[0];
		op_setcpsr_nzcv_setr15_len +=
			op_movl_Tx_im[2].len + sizeof (ARMword) +
			op_movl_trap_T2.len;
		if (op_setcpsr_nzcv_notsetr15_len >
		    op_setcpsr_nzcv_setr15_len) {
			op_setcpsr_nzcv_setreg_len +=
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			op_setcpsr_nzcv_setreg_len +=
				op_setcpsr_nzcv_setr15_len;
		}

		//mrs
		if (op_mrs_T0_spsr.len > op_mrs_T0_cpsr.len) {
			dp_len += op_mrs_T0_spsr.len;
		}
		else {
			dp_len += op_mrs_T0_cpsr.len;
		}
		dp_len += op_movl_reg_Tx_array_maxlen[0];
		TEA_OUT (printf
			 ("mrs insn's max len is %d\n",
			  dp_len + tb_insn_len_max));

//teawater add for xscale(arm v5) 2005.09.14------------------------------------]
		//clz
		dp_tmp1 = 0;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_clzl_T0_T1.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("clz insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

//teawater add for xscale(arm v5) 2005.09.26------------------------------------
		//qadd
		dp_tmp1 = 0;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_qaddl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("qadd insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//qsub
		dp_tmp1 = 0;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_qsubl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("qsub insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//qdadd
		dp_tmp1 = 0;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_qaddl_T0_T1_sq.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_qaddl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("qdadd insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//qdsub
		dp_tmp1 = 0;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_qaddl_T0_T1_sq.len;
		dp_tmp1 += op_movl_T1_T0.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_qsubl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("qdsub insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//sm_head
		sm_head = 0;
		sm_head += op_movl_Tx_reg_array_maxlen[0];
		sm_head += op_movl_Tx_reg_array_maxlen[1];
		if (op_hi_T0.len > op_lo_T0.len) {
			sm_head += op_hi_T0.len;
		}
		else {
			sm_head += op_lo_T0.len;
		}
		sm_head += op_signextend_halfword_T0.len;
		if (op_hi_T1.len > op_lo_T1.len) {
			sm_head += op_hi_T1.len;
		}
		else {
			sm_head += op_lo_T1.len;
		}
		sm_head += op_signextend_halfword_T1.len;

		//smlaxy
		dp_tmp1 = sm_head;
		dp_tmp1 += op_mul_T0_T1.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_addl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("smlaxy insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//smulwy
		dp_tmp1 = sm_head;
		dp_tmp1 += op_smulwy_T0_T1.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("smulwy insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//smlawy
		dp_tmp1 = sm_head;
		dp_tmp1 += op_smulwy_T0_T1.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_addl_T0_T1_sq.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		dp_tmp1 += op_set_q.len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("smlawy insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//smlalxy
		dp_tmp1 = sm_head;
		dp_tmp1 += op_mul_T0_T1.len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[2];
		dp_tmp1 += op_smlalxy_T2_T1_T0.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[1];
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[2];
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("smlalxy insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//smulxy
		dp_tmp1 = sm_head;
		dp_tmp1 += op_mul_T0_T1.len;
		dp_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("smulxy insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

//teawater add check thumb 2005.07.21-------------------------------------------
		//bx or blx(2)
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		if (op_bx_T1.len > op_blx_T1.len) {
			dp_tmp1 += op_bx_T1.len;
		}
		else {
			dp_tmp1 += op_blx_T1.len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("bx or blx(2) insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

		//msr
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		if (op_msr_spsr_T0_T1.len > op_msr_cpsr_T0_T1.len) {
			dp_tmp1 += op_msr_spsr_T0_T1.len;
		}
		else {
			dp_tmp1 += op_msr_spsr_T0_T1.len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("msr insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//and
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_andl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("and insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//eor
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_eorl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("eor insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//sub
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_subl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_subl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_subl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_subl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("sub insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//rsb
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_rsbl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_rsbl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_rsbl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_rsbl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("rsb insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//add
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_addl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_addl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_addl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_addl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("add insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//adc
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_adcl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_adcl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_adcl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_adcl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("adc insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//sbc
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_sbcl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_sbcl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_sbcl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_sbcl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("sbc insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//rsc
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		if (op_rscl_T0_T1_scv.len + op_setcpsr_nzcv_notsetr15_len >
		    op_rscl_T0_T1.len + op_setcpsr_nzcv_setr15_len) {
			dp_tmp1 +=
				op_rscl_T0_T1_scv.len +
				op_setcpsr_nzcv_notsetr15_len;
		}
		else {
			dp_tmp1 +=
				op_rscl_T0_T1.len +
				op_setcpsr_nzcv_setr15_len;
		}
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("rsc insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//tst
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_andl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("tst insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//teq
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_eorl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("teq insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//cmp
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_subl_T0_T1_scv.len;
		dp_tmp1 += op_setcpsr_nzcv_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("cmp insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//cmn
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_addl_T0_T1_scv.len;
		dp_tmp1 += op_setcpsr_nzcv_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("cmn insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//orr
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_orrl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("orr insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//mov
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("mov insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//bic
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		dp_tmp1 += op_bicl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("bic insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));

		//mvn
		dp_tmp1 = 0;
		dp_tmp1 += dp_head_len;
		dp_tmp1 += op_notl_T0_T1.len;
		dp_tmp1 += op_setcpsr_nzc_setreg_len;
		if (dp_tmp1 > dp_len) {
			dp_len = dp_tmp1;
		}
		TEA_OUT (printf
			 ("mvn insn's max len is %d\n",
			  dp_tmp1 + tb_insn_len_max));
	}

	//other_len
	{
		int op_add_data_offset_len = 0, ldr_head_len =
			0, str_head_len = 0;
		int other_tmp1, other_tmp2;

		//op_add_data_offset_len
		op_add_data_offset_len += op_movl_Tx_reg_array_maxlen[2];
		op_add_data_offset_len += op_shift_T2_im_maxlen;
		op_add_data_offset_len += sizeof (uint8_t);
		if (op_subl_T1_T2.len > op_addl_T1_T2.len) {
			op_add_data_offset_len += op_subl_T1_T2.len;
		}
		else {
			op_add_data_offset_len += op_addl_T1_T2.len;
		}
		if (op_addl_T1_im.len + sizeof (ARMword) >
		    op_add_data_offset_len) {
			op_add_data_offset_len =
				op_addl_T1_im.len + sizeof (ARMword);
		}

		//ldr_head_len str_head_len
		ldr_head_len += op_movl_Tx_reg_array_maxlen[1];
		ldr_head_len += op_add_data_offset_len;
		ldr_head_len += op_movl_reg_Tx_array_maxlen[1];
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			ldr_head_len += op_test_dataabort_ret.len;
		}
		str_head_len = ldr_head_len;
		ldr_head_len += op_movl_reg_Tx_array_maxlen[0];
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			ldr_head_len += op_test_dataabort.len;
		}
		str_head_len += op_movl_Tx_reg_array_maxlen[0];

		//ldrh
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldrh_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldrh insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//ldrsb
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldrb_T0_T1.len;
		other_tmp1 += op_signextend_byte_T0.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldrsb insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//ldrsh
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldrh_T0_T1.len;
		other_tmp1 += op_signextend_halfword_T0.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldrsh insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//ldrb
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldrb_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldrb insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//ldr
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldr_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldr insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//strh
		other_tmp1 = str_head_len;
		other_tmp1 += op_strh_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("strh insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

//teawater add for xscale(arm v5) 2005.09.26------------------------------------
		//ldrd
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_ldrd_T0_T2_T1.len;
		if (state->abort_model > 1) {
			other_tmp1 += op_test_dataabort_ret.len;
		}
		other_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		other_tmp1 += op_movl_reg_Tx_array_maxlen[2];
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldrd insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//strd
		other_tmp1 = ldr_head_len;
		other_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		other_tmp1 += op_movl_reg_Tx_array_maxlen[2];
		other_tmp1 += op_strd_T0_T2_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("strd insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

		//strb
		other_tmp1 = str_head_len;
		other_tmp1 += op_strb_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("strb insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//str
		other_tmp1 = str_head_len;
		other_tmp1 += op_str_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("str insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//mul
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_mul_T0_T1.len;
		other_tmp1 += op_logic_T0_sn.len;
		other_tmp1 += op_set_nf.len;
		other_tmp1 += op_logic_T0_sz.len;
		other_tmp1 += op_set_zf.len;
		other_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		TEA_OUT (printf
			 ("mul insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//mla
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_addl_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mla insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//mull
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		if (op_smull_T0_T1.len > op_umull_T0_T1.len) {
			other_tmp1 += op_smull_T0_T1.len;
		}
		else {
			other_tmp1 += op_umull_T0_T1.len;
		}
		other_tmp1 += op_movl_Tx_reg_array_maxlen[2];
		other_tmp1 += op_movl_eax_T2.len;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[2];
		other_tmp1 += op_addq_T0_T1_eax_T2.len;
		other_tmp1 += op_logic_T0_sn.len;
		other_tmp1 += op_set_nf.len;
		other_tmp1 += op_logic_T0_sz.len;
		other_tmp1 += op_set_zf.len;
		other_tmp1 += op_movl_reg_Tx_array_maxlen[0];
		other_tmp1 += op_movl_reg_Tx_array_maxlen[1];
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mull insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//swp
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		if (op_ldrb_T2_T1.len + op_strb_T0_T1.len >
		    op_ldr_T2_T1.len + op_str_T0_T1.len) {
			other_tmp1 += op_ldrb_T2_T1.len + op_strb_T0_T1.len;
		}
		else {
			other_tmp1 += op_ldr_T2_T1.len + op_str_T0_T1.len;
		}
		other_tmp1 += op_movl_reg_Tx_array_maxlen[2];
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("swp insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//insn_undef
		other_tmp1 = 0;
		other_tmp1 +=
			op_movl_Tx_im[2].len + sizeof (ARMword) +
			op_movl_trap_T2.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("insn_undef insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//ldm stm
		other_tmp1 = 0;
		other_tmp1 += op_test_cpsr_ret_UNP.len;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 +=
			op_movl_Tx_im[2].len + sizeof (ARMword) +
			op_movl_trap_T2.len;
		other_tmp1 += op_addl_T1_im.len + sizeof (ARMword);
		other_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		other_tmp2 = op_ldm_user_T1_T0.len;
		if (op_ldm_T1_T0.len > other_tmp2) {
			other_tmp2 = op_ldm_T1_T0.len;
		}
		if (op_stm_user_T1_T0.len > other_tmp2) {
			other_tmp2 = op_stm_user_T1_T0.len;
		}
		if (op_stm_T1_T0.len > other_tmp2) {
			other_tmp2 = op_stm_T1_T0.len;
		}
		other_tmp1 += other_tmp2;
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			ldr_head_len += op_test_dataabort.len;
		}
		other_tmp1 += op_addl_T1_im.len + sizeof (ARMword);
		other_tmp1 += op_movl_reg_Tx_array_maxlen[1];
		//if (!state->is_XScale) {
		if (state->abort_model > 1) {
			ldr_head_len += op_test_dataabort_ret.len;
		}
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldm stm insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//b
		other_tmp1 = 0;
		other_tmp1 += op_b_offset.len + sizeof (ARMword);
//teawater change for local tb branch directly jump 2005.10.21------------------
		other_tmp1 += op_local_b_offset.len;
//AJ2D--------------------------------------------------------------------------
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("b insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//bl
		other_tmp1 = 0;
		other_tmp1 += op_bl_offset.len + sizeof (ARMword);
//teawater change for local tb branch directly jump 2005.10.21------------------
		other_tmp1 += op_local_b_offset.len;
//AJ2D--------------------------------------------------------------------------
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("bl insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

//teawater add for xscale(arm v5) 2005.09.14------------------------------------
		//mar
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_mar_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mar insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//mra
		other_tmp1 += op_mra_T0_T1.len;
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mra insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

		//ldc stc
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_addl_T1_im.len + sizeof (ARMword);
		other_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		if (op_ldc_T0_T1.len > op_stc_T0_T1.len) {
			other_tmp1 += op_ldc_T0_T1.len;
		}
		else {
			other_tmp1 += op_stc_T0_T1.len;
		}
		other_tmp1 += op_movl_reg_Tx_array_maxlen[1];
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("ldc stc insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

//teawater add for xscale(arm v5) 2005.09.14------------------------------------
		//mia
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_smull_T0_T1.len;
		other_tmp1 += op_mia_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mia insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//miaph
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_miaph_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("miaph insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//miabb
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_lo_T0.len;
		other_tmp1 += op_lo_T1.len;
		other_tmp1 += op_miaxy_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("miabb insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//miabt
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_lo_T0.len;
		other_tmp1 += op_hi_T1.len;
		other_tmp1 += op_miaxy_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("miabt insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//miatb
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_hi_T0.len;
		other_tmp1 += op_lo_T1.len;
		other_tmp1 += op_miaxy_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("miatb insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//miatt
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_reg_array_maxlen[0];
		other_tmp1 += op_movl_Tx_reg_array_maxlen[1];
		other_tmp1 += op_hi_T0.len;
		other_tmp1 += op_hi_T1.len;
		other_tmp1 += op_miaxy_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("miatt insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));
//AJ2D--------------------------------------------------------------------------

		//mrc
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		other_tmp1 += op_movl_Tx_im[1].len + sizeof (ARMword);
		other_tmp1 += op_mrc_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mrc insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//mcr
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		other_tmp1 += op_movl_Tx_im[1].len + sizeof (ARMword);
		other_tmp1 += op_mcr_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("mcr insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//cdp
		other_tmp1 = 0;
		other_tmp1 += op_movl_Tx_im[0].len + sizeof (ARMword);
		other_tmp1 += op_movl_Tx_im[1].len + sizeof (ARMword);
		other_tmp1 += op_cdp_T0_T1.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("cdp insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));

		//swi
		other_tmp1 = 0;
		other_tmp1 +=
			op_movl_Tx_im[2].len + sizeof (ARMword) +
			op_movl_trap_T2.len;
		if (other_tmp1 > other_len) {
			other_len = other_tmp1;
		}
		TEA_OUT (printf
			 ("swi insn's max len is %d\n",
			  other_tmp1 + tb_insn_len_max));
	}

	if (dp_len > other_len) {
		tb_insn_len_max += dp_len;
	}
	else {
		tb_insn_len_max += other_len;
	}

	TEA_OUT (printf ("tb_insn_len_max is %d\n", tb_insn_len_max));
	return (0);
}

//teawater add for new tb manage function 2005.07.10----------------------------
int
tb_memory_init (ARMul_State * state)
{
	int i;
	uint64_t tmp_u64;
	mem_bank_t *mbp;

	//tbt
	if (TB_TBT_SIZE) {
		//get align tbt size
		TB_TBT_SIZE = ALIGN (TB_TBT_SIZE, sizeof (tb_cache_t));
		if (TB_TBT_SIZE < sizeof (tb_cache_t)) {
			fprintf (stderr,
				 "SKYEYE: tb_memory_init: TB_TBT_SIZE %u is too little.\n",
				 (unsigned int) TB_TBT_SIZE);
			return (-1);
		}

		//get tbt max size
		tmp_u64 = 0;
		for (i = 0; i < state->mem_bank->current_num; i++) {
			tmp_u64 += state->mem_bank->mem_banks[i].len;
		}
		tmp_u64 = tmp_u64 / TB_LEN * sizeof (tb_cache_t);

		if (TB_TBT_SIZE >= tmp_u64) {
			//if set size >= max size, use the simple function
			TB_TBT_SIZE = 0;
		}
		else {
			//get mem by TB_TBT_SIZE
			tbt_table = (tb_t *) malloc (TB_TBT_SIZE);
			if (!tbt_table) {
				fprintf (stderr,
					 "SKYEYE: tb_memory_init: Error allocating mem.\n");
				return (-1);
			}
			memset (tbt_table, 0, TB_TBT_SIZE);
			tbt_table_size = TB_TBT_SIZE / sizeof (tb_cache_t);
		}
	}

	//tbp
	if (TB_TBP_SIZE) {
		//get align tbp size
		TB_TBP_SIZE = ALIGN (TB_TBP_SIZE, TB_TBP_MAX);
		if (TB_TBP_SIZE < TB_TBP_MAX) {
			fprintf (stderr,
				 "SKYEYE: tb_memory_init: TB_TBP_SIZE %u is too little.\n",
				 (unsigned int) TB_TBP_SIZE);
			return (-1);
		}
	}
	if (TB_TBT_SIZE) {
		//get tbp max size
		tmp_u64 =
			tbt_table_size * TB_LEN / sizeof (ARMword) *
			TB_INSN_LEN_MAX + tbt_table_size * op_return.len;

		if (TB_TBP_SIZE == 0 || TB_TBP_SIZE > tmp_u64) {
			TB_TBP_SIZE = tmp_u64;
		}
		else {
			tbp_dynamic = 1;
		}
	}
	else {
		if (TB_TBP_SIZE) {
			//get tbp max size
			tmp_u64 = 0;
			for (i = 0; i < state->mem_bank->current_num; i++) {
				tmp_u64 += state->mem_bank->mem_banks[i].len;
			}
			tmp_u64 =
				tmp_u64 / sizeof (ARMword) * TB_INSN_LEN_MAX +
				tmp_u64 / TB_LEN * op_return.len;

			if (TB_TBP_SIZE >= tmp_u64) {
				//if set size >= max size, use the simple function
				TB_TBP_SIZE = 0;
			}
			else {
				tbp_dynamic = 1;
			}
		}
	}
	if (TB_TBP_SIZE) {
		//get mem by TB_TBP_SIZE
		tbp_begin =
			mmap (NULL, TB_TBP_SIZE,
			      PROT_READ | PROT_WRITE | PROT_EXEC,
			      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		if (tbp_begin == MAP_FAILED) {
			fprintf (stderr,
				 "SKYEYE: tb_memory_init: Error allocating mem.\n");
			return (-1);
		}
		tbp_now_size = TB_TBP_SIZE;
		tbp_now = tbp_begin;
	}

	if (TB_TBT_SIZE) {
		printf ("dbct translate block entry use memory 0x%08x bytes.\n", TB_TBT_SIZE);
	}
	if (TB_TBP_SIZE) {
		printf ("dbct translate block use memory 0x%08x bytes.\n",
			TB_TBP_SIZE);
	}

	return (0);
}

//AJ2D--------------------------------------------------------------------------
