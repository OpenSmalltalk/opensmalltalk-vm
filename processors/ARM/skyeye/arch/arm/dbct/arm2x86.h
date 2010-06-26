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

#ifndef _ARM2X86_H_
#define _ARM2X86_H_

#include <limits.h>

/*
typedef unsigned char		uint8_t;
typedef unsigned short		uint16_t;
typedef unsigned int		uint32_t;
#if defined (__x86_64__)
typedef unsigned long		uint64_t;
#else
typedef unsigned long long	uint64_t;
#endif
*/

/*
typedef signed char		int8_t;
typedef signed short		int16_t;
typedef signed int		int32_t;
#if defined (__x86_64__)
typedef signed long		int64_t;
#else
typedef signed long long	int64_t;
#endif
*/
//chy 2005-05-11
/*#ifndef __CYGWIN__
#define INT8_MIN		(-128)
#define INT16_MIN		(-32767-1)
#define INT32_MIN		(-2147483647-1)
#define INT64_MIN		(-(int64_t)(9223372036854775807)-1)
#define INT8_MAX		(127)
#define INT16_MAX		(32767)
#define INT32_MAX		(2147483647)
#define INT64_MAX		((int64_t)(9223372036854775807))
#define UINT8_MAX		(255)
#define UINT16_MAX		(65535)
#define UINT32_MAX		(4294967295U)
#define UINT64_MAX		((uint64_t)(18446744073709551615))
#endif*/

#define TRAP_SET_R15		0x01

#define TRAP_RESET		0x10
#define TRAP_INSN_UNDEF		0x11
#define TRAP_SWI		0x12
#define TRAP_INSN_ABORT		0x13
#define TRAP_DATA_ABORT		0x14
#define TRAP_IRQ		0x15
#define TRAP_FIQ		0x16

#define TRAP_SETS_R15		0x20
#define TRAP_SET_CPSR		0x21
#define TRAP_UNPREDICTABLE	0x22

//teawater change for debug function 2005.07.09---------------------------------
#define TRAP_OUT		0x30
#define TRAP_BREAKPOINT		0x40
//AJ2D--------------------------------------------------------------------------

#define wmb()			__asm__ __volatile__ ("": : :"memory")
#define OP_BEGIN(f)		__asm__ __volatile__ ("jmp ."f"_teawater_op_end\n\t""."f"_teawater_op_begin:\n\t")
#define OP_END(f)		__asm__ __volatile__ ("."f"_teawater_op_end:\n\t""movl $."f"_teawater_op_begin,%0\n\t""movl $."f"_teawater_op_end,%1\n\t":"=g"(begin), "=g"(end));
//teawater remove tb_translate_find 2005.10.21----------------------------------
//#define GEN_OP(a, l, o)		do { if(a) { memcpy(a, o.op, o.len);a += o.len; } l += o.len; } while(0)
#define GEN_OP(a, l, o)		do { memcpy(a, o.op, o.len);a += o.len; l += o.len; } while(0)
//AJ2D--------------------------------------------------------------------------

#define Tx_MAX		2
#define tmp_MAX		0

typedef struct op_table_s
{
	uint8_t *op;
	int len;
} op_table_t;

extern const uint8_t table_logic_cc[16];

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
extern volatile uint32_t arm2x86_pfun;
#else
extern volatile void (*arm2x86_pfun) (void);
#endif

extern uint32_t arm2x86_tmp_reg[16];
extern volatile uint32_t arm2x86_tmp0;

//teawater add for xscale(arm v5) 2005.09.23------------------------------------
extern volatile uint64_t arm2x86_tmp64;
//AJ2D--------------------------------------------------------------------------

extern op_table_t op_writesr15;
extern op_table_t op_return;
extern op_table_t op_addpc;
//extern op_table_t             op_fiqirq;
extern op_table_t op_begin;
extern op_table_t op_begin_test_T0;

//teawater change for local tb branch directly jump 2005.10.10------------------
#include "tb.h"
typedef struct	tb_branch_save_s {
	struct list_head	list;
//	ARMword			addr;
	ARMword			dst_addr;
	uint8_t			*tbp;
}tb_branch_save_t;
extern struct list_head		tb_branch_save_list;
extern tb_branch_save_t		tb_branch_save[TB_LEN / sizeof(ARMword)];
extern tb_t			*now_tbt;
//AJ2D--------------------------------------------------------------------------

extern int arm2x86_init ();

#ifndef IFLAG
#define IFLAG	(state->IFFlags >> 1)
#endif //IFLAG

#ifndef FFLAG
#define FFLAG	(state->IFFlags & 1)
#endif //FFLAG

static __inline__ int
arm2x86_exception (ARMul_State * state)
{
	//reset
	if (state->NresetSig == LOW) {
		state->trap = TRAP_RESET;
		return (1);
	}
	//fiq
	if (!state->NfiqSig && !FFLAG) {
		state->trap = TRAP_FIQ;
		return (1);
	}
	//irq
	if (!state->NirqSig && !IFLAG) {
		state->trap = TRAP_IRQ;
		return (1);
	}

	return (0);
}

#endif //_ARM2X86_H_
