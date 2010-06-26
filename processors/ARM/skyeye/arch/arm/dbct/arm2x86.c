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

const uint8_t table_logic_cc[16] = {
	1,			/* and */
	1,			/* eor */
	0,			/* sub */
	0,			/* rsb */
	0,			/* add */
	0,			/* adc */
	0,			/* sbc */
	0,			/* rsc */
	1,			/* tst */
	1,			/* teq */
	0,			/* cmp */
	0,			/* cmn */
	1,			/* orr */
	1,			/* mov */
	1,			/* bic */
	1,			/* mvn */
};

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
volatile uint32_t arm2x86_pfun;
#else
volatile void (*arm2x86_pfun) (void);
#endif

uint32_t arm2x86_tmp_reg[16];
volatile uint32_t arm2x86_tmp0;

//teawater add for xscale(arm v5) 2005.09.23------------------------------------
volatile uint64_t arm2x86_tmp64;
//AJ2D--------------------------------------------------------------------------

//teawater change for local tb branch directly jump 2005.10.10------------------
struct list_head	tb_branch_save_list;
tb_branch_save_t	tb_branch_save[TB_LEN / sizeof(ARMword)];
tb_t			*now_tbt;
//AJ2D--------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------

//teawater change for debug function 2005.07.09---------------------------------
static int step_out = 0;

/* Values for Emulate.  */
#define STOP            0	/* stop */
#define CHANGEMODE      1	/* change mode */
#define ONCE            2	/* execute just one interation */
#define RUN             3	/* continuous execution */

#define INSN_SIZE	(state->TFlag ? 2 : 4)

static inline int
tea_check_out (ARMul_State * state)
{
//teawater add compile switch for DBCT GDB RSP function 2005.10.21--------------
#ifdef DBCT_GDBRSP
	if (state->tea_break_ok
	    && state->Reg[15] == state->tea_break_addr + 4) {
		ARMul_Debug (state, 0, 0);
		state->tea_break_ok = 0;
	}
	else {
		state->tea_break_ok = 1;
	}

	//step
	if (state->Emulate == ONCE) {
		if (step_out) {
			step_out = 0;
			//state->trap = TRAP_OUT;
			//state->Emulate = STOP;
			return (1);
		}
		else {
			step_out = 1;
		}
	}
	else if (state->Emulate != RUN) {
		//state->trap = TRAP_OUT;
		return (1);
	}

	if (state->tea_pc) {
		int i;
		if (state->tea_reg_fd) {
			fprintf (state->tea_reg_fd, "\n");
			for (i = 0; i < 15; i++) {
				fprintf (state->tea_reg_fd, "%x,",
					 state->Reg[i]);
			}
			fprintf (state->tea_reg_fd, "%x,",
				 state->Reg[15] - INSN_SIZE);
			fprintf (state->tea_reg_fd, "%x\n", state->Cpsr);
		}
		else {
			printf ("\n");
			for (i = 0; i < 15; i++) {
				printf ("%x,", state->Reg[i]);
			}
			printf ("%x,", state->Reg[15] - INSN_SIZE);
			printf ("%x\n", state->Cpsr);
		}
	}
	//fprintf(fd, "------------\npc:%x\n", state->Reg[15] - INSN_SIZE);
#endif	//DBCT_GDBRSP
//AJ2D--------------------------------------------------------------------------

	//exception
	if (arm2x86_exception (state)) {
		return (1);
	}

//teawater change for return if running tb dirty 2005.07.09---------------------
	if (((tb_t *) (state->tb_now))->ted == 0) {
		return (1);
	}
//AJ2D--------------------------------------------------------------------------

	//do io
	io_do_cycle (state);

	return (0);
}

uint32_t
tea_begin (ARMul_State * state)
{
	if (tea_check_out (state)) {
		return (ULONG_MAX);
	}

	return (0);
}

extern int stop_simulator;
uint32_t
tea_begin_test (ARMul_State * state, uint32_t cond)
{
	if (tea_check_out (state)) {
		return (ULONG_MAX);
	}

	//test_op
	return (gen_op_condition (state, cond));
}

//--------------------------------------------------------------------------------------------------
uint8_t *
get_op_writesr15 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_writesr15");
	st->trap = TRAP_SETS_R15;
	OP_END ("get_op_writesr15");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_return (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_return");
	__asm__ __volatile__ ("ret");
	OP_END ("get_op_return");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_addpc (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_addpc");
	st->Reg[15] += 4;
	OP_END ("get_op_addpc");
	*len = end - begin;

	return ((uint8_t *) begin);
}

/*
uint8_t *
get_op_fiqirq(int *len)
{
	unsigned int	begin=0,end=0;

	OP_BEGIN("get_op_fiqirq");
	if (!FFLAG && !st->NfiqSig) {
		st->trap = TRAP_FIQ;
		__asm__ __volatile__ ("ret");
	}
	if (!IFLAG && !st->NirqSig) {
		st->trap = TRAP_IRQ;
		__asm__ __volatile__ ("ret");
	}
	//io_do_cycle(st);
	__asm__ __volatile__ ("subl	$0xc, %esp");
	__asm__ __volatile__ ("push	%"AREG_st);
	arm2x86_pfun = (uint32_t)io_do_cycle;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
	__asm__ __volatile__ ("addl	$0x10, %esp");
	OP_END("get_op_fiqirq");
	*len = end - begin;

	return((uint8_t *)begin);
}
*/

uint8_t *
get_op_begin (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_begin");
	//T0 = tea_begin(st);
	__asm__ __volatile__ ("subl	$0xc, %esp");
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_begin;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);
	if (T0) {
		__asm__ __volatile__ ("ret");
	}
	OP_END ("get_op_begin");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_begin_test_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_begin_test_T0");
	//T0 = tea_begin_test(st, T0);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_st);
	T2 = (uint32_t) tea_begin_test;
	__asm__ __volatile__ ("call	*%" AREG_T2);
	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);

	if (T0 == ULONG_MAX) {
		__asm__ __volatile__ ("ret");
	}
	if (!T0) {
		__asm__ __volatile__ ("jmp	0xffffffff");
	}
	OP_END ("get_op_begin_test_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

op_table_t op_writesr15;
op_table_t op_return;
op_table_t op_addpc;
//op_table_t    op_fiqirq;
op_table_t op_begin;
op_table_t op_begin_test_T0;
int
op_init ()
{
	op_writesr15.op = get_op_writesr15 (&op_writesr15.len);
	if (op_writesr15.len <= 0)
		return (-1);
	op_return.op = get_op_return (&op_return.len);
	if (op_return.len <= 0)
		return (-1);
	op_addpc.op = get_op_addpc (&op_addpc.len);
	if (op_addpc.len <= 0)
		return (-1);
	op_begin.op = get_op_begin (&op_begin.len);
	if (op_begin.len <= 0)
		return (-1);
	op_begin_test_T0.op = get_op_begin_test_T0 (&op_begin_test_T0.len);
	if (op_begin_test_T0.len <= 0)
		return (-1);

	return (0);
}

//--------------------------------------------------------------------------------------------------
int
arm2x86_init (ARMul_State * state)
{
	if (op_init ()) {
		return (-1);
	}
	if (arm2x86_test_init ()) {
		return (-1);
	}
	if (arm2x86_shift_init ()) {
		return (-1);
	}
	if (arm2x86_psr_init ()) {
		return (-1);
	}
	if (arm2x86_movl_init ()) {
		return (-1);
	}
	if (arm2x86_mul_init ()) {
		return (-1);
	}
	if (arm2x86_mem_init ()) {
		return (-1);
	}
	if (arm2x86_other_init ()) {
		return (-1);
	}
	if (arm2x86_dp_init ()) {
		return (-1);
	}
	if (arm2x86_coproc_init ()) {
		return (-1);
	}

	if (tb_insn_len_max_init (state)) {
		return (-1);
	}

//teawater add for new tb manage function 2005.07.10----------------------------
	if (tb_memory_init (state)) {
		return (-1);
	}
//AJ2D--------------------------------------------------------------------------

	return (0);
}
