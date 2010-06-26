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

uint32_t
tea_ldm (ARMul_State * state, ARMword address, ARMword reg_map)
{
	int i;
	ARMword data;

	for (i = 0; i < 16; i++) {
		arm2x86_tmp_reg[i] = state->Reg[i];
		if (reg_map & (1 << i)) {
			data = ARMul_ReadWord (state, address);
			if (state->abortSig != LOW) {
				state->trap = TRAP_DATA_ABORT;
				//if (state->is_XScale) {
				if (!state->abort_model) {
					return (0);
				}
				else {
					break;
				}
			}

			if (i == 15) {
				arm2x86_tmp_reg[i] = (data & (~3)) + 4;
			}
			else {
				arm2x86_tmp_reg[i] = data;
			}

			address += 4;
		}
	}
	if (state->trap != TRAP_DATA_ABORT) {
		for (i = 0; i < 16; i++) {
			state->Reg[i] = arm2x86_tmp_reg[i];
		}
		address -= 4;
	}

	return (address);
}

uint32_t
tea_ldm_user (ARMul_State * state, ARMword address, ARMword reg_map)
{
	int i;
	ARMword data;

	for (i = 0; i < 15; i++) {
		if (((state->Mode == FIQ26MODE || state->Mode == FIQ32MODE)
		     && (i >= 8)) || (i >= 13)) {
			arm2x86_tmp_reg[i] = state->RegBank[USERBANK][i];
		}
		else {
			arm2x86_tmp_reg[i] = state->Reg[i];
		}
		arm2x86_tmp_reg[i] = state->Reg[i];
		if (reg_map & (1 << i)) {
			data = ARMul_ReadWord (state, address);
			if (state->abortSig != LOW) {
				state->trap = TRAP_DATA_ABORT;
				//if (state->is_XScale) {
				if (!state->abort_model) {
					return (0);
				}
				else {
					break;
				}
			}

			/*if (((state->Mode == FIQ26MODE || state->Mode == FIQ32MODE) && (i >= 8)) || (i >= 13)) {
			   state->RegBank[USERBANK][i] = data;
			   }
			   else {
			   state->Reg[i] = data;
			   } */
			arm2x86_tmp_reg[i] = data;

			address += 4;
		}
	}
	if (state->trap != TRAP_DATA_ABORT) {
		for (i = 0; i < 15; i++) {
			if (((state->Mode == FIQ26MODE
			      || state->Mode == FIQ32MODE) && (i >= 8))
			    || (i >= 13)) {
				state->RegBank[USERBANK][i] =
					arm2x86_tmp_reg[i];
			}
			else {
				state->Reg[i] = arm2x86_tmp_reg[i];
			}
		}
		address -= 4;
	}

	return (address);
}

uint32_t
tea_stm (ARMul_State * state, ARMword address, ARMword reg_map)
{
	int i;

	for (i = 0; i < 16; i++) {
		if (reg_map & (1 << i)) {
			if (i == 15) {
				ARMul_WriteWord (state, address,
						 state->Reg[i] + 4);
			}
			else {
				ARMul_WriteWord (state, address,
						 state->Reg[i]);
			}
			if (state->abortSig != LOW) {
				state->trap = TRAP_DATA_ABORT;
				//if (state->is_XScale) {
				if (!state->abort_model) {
					return (0);
				}
				else {
					break;
				}
			}

			address += 4;
		}
	}
	if (state->trap != TRAP_DATA_ABORT) {
		address -= 4;
	}

	return (address);
}

uint32_t
tea_stm_user (ARMul_State * state, ARMword address, ARMword reg_map)
{
	int i;

	for (i = 0; i < 16; i++) {
		if (reg_map & (1 << i)) {
			if (i == 15) {
				ARMul_WriteWord (state, address,
						 state->Reg[i] + 4);
			}
			else {
				if (((state->Mode == FIQ26MODE
				      || state->Mode == FIQ32MODE)
				     && (i >= 8)) || (i >= 13)) {
					ARMul_WriteWord (state, address,
							 state->
							 RegBank[USERBANK]
							 [i]);
				}
				else {
					ARMul_WriteWord (state, address,
							 state->Reg[i]);
				}
			}
			if (state->abortSig != LOW) {
				state->trap = TRAP_DATA_ABORT;
				//if (state->is_XScale) {
				if (!state->abort_model) {
					return (0);
				}
				else {
					break;
				}
			}

			address += 4;
		}
	}
	if (state->trap != TRAP_DATA_ABORT) {
		address -= 4;
	}

	return (address);
}

//--------------------------------------------------------------------------------------------------

uint8_t *
get_op_ldr_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldr_T0_T1");
	//T0 = ARMul_ReadWord(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);

	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	if (T1 & 3) {
		T0 = LOADWORD_ALIGN (T1, T0);
	}
	OP_END ("get_op_ldr_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldr_T2_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldr_T2_T1");
	//T2 = ARMul_ReadWord(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T2);

	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}

	if (T1 & 3) {
		T2 = LOADWORD_ALIGN (T1, T2);
	}
	OP_END ("get_op_ldr_T2_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldrh_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldrh_T0_T1");
	//T0 = ARMul_LoadHalfWord(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_LoadHalfWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_LoadHalfWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);

	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_ldrh_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldrb_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldrb_T0_T1");
	//T0 = ARMul_ReadByte(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadByte;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadByte;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);

	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_ldrb_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldrb_T2_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldrb_T2_T1");
	//T2 = ARMul_ReadByte(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadByte;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadByte;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T2);

	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_ldrb_T2_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_str_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_str_T0_T1");
	//ARMul_WriteWord(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_WriteWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_WriteWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_str_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_strh_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_strh_T0_T1");
	//ARMul_StoreHalfWord(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_StoreHalfWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_StoreHalfWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		if (st->abort_model < 2) {
			//if (st->is_XScale) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_strh_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_strb_T0_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_strb_T0_T1");
	//ARMul_WriteByte(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_WriteByte;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_WriteByte;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_strb_T0_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldm_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldm_T1_T0");
	//T1 = tea_ldm(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) tea_ldm;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))tea_ldm;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T1);
	/*if (st->abortSig != LOW) {
	   st->trap = TRAP_DATA_ABORT;
	   __asm__ __volatile__ ("ret");
	   } */
	if (st->abortSig != LOW) {
		//if (st->is_XScale) {
		if (!st->abort_model) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_ldm_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_stm_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_stm_T1_T0");
	//T1 = tea_stm(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) tea_stm;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))tea_stm;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T1);
	/*if (st->abortSig != LOW) {
	   st->trap = TRAP_DATA_ABORT;
	   __asm__ __volatile__ ("ret");
	   } */
	if (st->abortSig != LOW) {
		//if (st->is_XScale) {
		if (!st->abort_model) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_stm_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldm_user_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldm_user_T1_T0");
	//T1 = tea_ldm_user(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) tea_ldm_user;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))tea_ldm_user;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T1);
	/*if (st->abortSig != LOW) {
	   st->trap = TRAP_DATA_ABORT;
	   __asm__ __volatile__ ("ret");
	   } */
	if (st->abortSig != LOW) {
		//if (st->is_XScale) {
		if (!st->abort_model) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_ldm_user_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_stm_user_T1_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_stm_user_T1_T0");
	//T1 = tea_stm_user(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) tea_stm_user;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))tea_stm_user;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T1);
	/*if (st->abortSig != LOW) {
	   st->trap = TRAP_DATA_ABORT;
	   __asm__ __volatile__ ("ret");
	   } */
	if (st->abortSig != LOW) {
		//if (st->is_XScale) {
		if (!st->abort_model) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_stm_user_T1_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//teawater add for xscale(arm v5) 2005.09.19------------------------------------

uint8_t *
get_op_signextend_halfword_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_signextend_halfword_T0");
	//if (T0 & 1 << (16 - 1))
	//T0 |= 0xffff0000;
	T0 = (uint32_t) ((int32_t) ((int16_t) T0));
	OP_END ("get_op_signextend_halfword_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_signextend_byte_T0 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_signextend_byte_T0");
	//if (T0 & 1 << (8 - 1))
	//T0 |= 0xffffff00;
	T0 = (uint32_t) ((int32_t) ((int8_t) T0));
	OP_END ("get_op_signextend_byte_T0");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_signextend_halfword_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_signextend_halfword_T1");
	//if (T1 & 1 << (16 - 1))
	//T1 |= 0xffff0000;
	T1 = (uint32_t) ((int32_t) ((int16_t) T1));
	OP_END ("get_op_signextend_halfword_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_signextend_byte_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_signextend_byte_T1");
	//if (T1 & 1 << (8 - 1))
	//T1 |= 0xffffff00;
	T1 = (uint32_t) ((int32_t) ((int8_t) T1));
	OP_END ("get_op_signextend_byte_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_ldrd_T0_T2_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_ldrd_T0_T2_T1");
	//T0 = ARMul_ReadWord(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T0);
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	if (T1 & 3) {
		T0 = LOADWORD_ALIGN (T1, T0);
	}

	T1 += 4;
	//T2 = ARMul_ReadWord(st, T1);
	__asm__ __volatile__ ("subl	$0x8, %esp");
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_ReadWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_ReadWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	__asm__ __volatile__ ("movl	%eax, %" AREG_T2);
	T1 -= 4;
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	if (T1 & 3) {
		T0 = LOADWORD_ALIGN (T1, T2);
	}

	OP_END ("get_op_ldrd_T0_T2_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

uint8_t *
get_op_strd_T0_T2_T1 (int *len)
{
	unsigned int begin = 0, end = 0;

	OP_BEGIN ("get_op_strd_T0_T2_T1");
	//ARMul_WriteWord(st, T1, T0);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T0);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_WriteWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_WriteWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}

	T1 += 4;
	//ARMul_WriteWord(st, T1, T2);
	__asm__ __volatile__ ("subl	$0x4, %esp");
	__asm__ __volatile__ ("push	%" AREG_T2);
	__asm__ __volatile__ ("push	%" AREG_T1);
	__asm__ __volatile__ ("push	%" AREG_st);

//chy 2005-05-11
#if !(defined(__CYGWIN__) || defined(__MINGW32__) || defined(__APPLE__))
	arm2x86_pfun = (uint32_t) ARMul_WriteWord;
	__asm__ __volatile__ ("call	*arm2x86_pfun");
#else
	arm2x86_pfun = (volatile void(*))ARMul_WriteWord;
	wmb ();
	(*arm2x86_pfun) ();
#endif

	__asm__ __volatile__ ("addl	$0x10, %esp");
	T1 -= 4;
	if (st->abortSig != LOW) {
		st->trap = TRAP_DATA_ABORT;
		//if (st->is_XScale) {
		if (st->abort_model < 2) {
			__asm__ __volatile__ ("ret");
		}
	}
	OP_END ("get_op_strd_T0_T2_T1");
	*len = end - begin;

	return ((uint8_t *) begin);
}

//AJ2D--------------------------------------------------------------------------

op_table_t op_ldr_T0_T1;
op_table_t op_ldr_T2_T1;
op_table_t op_ldrh_T0_T1;
op_table_t op_ldrb_T0_T1;
op_table_t op_ldrb_T2_T1;

op_table_t op_str_T0_T1;
op_table_t op_strh_T0_T1;
op_table_t op_strb_T0_T1;

op_table_t op_ldm_T1_T0;
op_table_t op_stm_T1_T0;

op_table_t op_ldm_user_T1_T0;
op_table_t op_stm_user_T1_T0;

op_table_t op_signextend_halfword_T0;
op_table_t op_signextend_byte_T0;

//teawater add for xscale(arm v5) 2005.09.19------------------------------------
op_table_t op_signextend_halfword_T1;
op_table_t op_signextend_byte_T1;

op_table_t op_ldrd_T0_T2_T1;
op_table_t op_strd_T0_T2_T1;
//AJ2D--------------------------------------------------------------------------

int
arm2x86_mem_init ()
{
	op_ldr_T0_T1.op = get_op_ldr_T0_T1 (&op_ldr_T0_T1.len);
	if (op_ldr_T0_T1.len <= 0)
		return (-1);
	op_ldr_T2_T1.op = get_op_ldr_T2_T1 (&op_ldr_T2_T1.len);
	if (op_ldr_T2_T1.len <= 0)
		return (-1);
	op_ldrh_T0_T1.op = get_op_ldrh_T0_T1 (&op_ldrh_T0_T1.len);
	if (op_ldrh_T0_T1.len <= 0)
		return (-1);
	op_ldrb_T0_T1.op = get_op_ldrb_T0_T1 (&op_ldrb_T0_T1.len);
	if (op_ldrb_T0_T1.len <= 0)
		return (-1);
	op_ldrb_T2_T1.op = get_op_ldrb_T2_T1 (&op_ldrb_T2_T1.len);
	if (op_ldrb_T2_T1.len <= 0)
		return (-1);

	op_str_T0_T1.op = get_op_str_T0_T1 (&op_str_T0_T1.len);
	if (op_str_T0_T1.len <= 0)
		return (-1);
	op_strh_T0_T1.op = get_op_strh_T0_T1 (&op_strh_T0_T1.len);
	if (op_strh_T0_T1.len <= 0)
		return (-1);
	op_strb_T0_T1.op = get_op_strb_T0_T1 (&op_strb_T0_T1.len);
	if (op_strb_T0_T1.len <= 0)
		return (-1);

	op_ldm_T1_T0.op = get_op_ldm_T1_T0 (&op_ldm_T1_T0.len);
	if (op_ldm_T1_T0.len <= 0)
		return (-1);
	op_stm_T1_T0.op = get_op_stm_T1_T0 (&op_stm_T1_T0.len);
	if (op_stm_T1_T0.len <= 0)
		return (-1);

	op_ldm_user_T1_T0.op = get_op_ldm_user_T1_T0 (&op_ldm_user_T1_T0.len);
	if (op_ldm_user_T1_T0.len <= 0)
		return (-1);
	op_stm_user_T1_T0.op = get_op_stm_user_T1_T0 (&op_stm_user_T1_T0.len);
	if (op_stm_user_T1_T0.len <= 0)
		return (-1);

	op_signextend_halfword_T0.op =
		get_op_signextend_halfword_T0 (&op_signextend_halfword_T0.
					       len);
	if (op_signextend_halfword_T0.len <= 0)
		return (-1);
	op_signextend_byte_T0.op =
		get_op_signextend_byte_T0 (&op_signextend_byte_T0.len);
	if (op_signextend_byte_T0.len <= 0)
		return (-1);

//teawater add for xscale(arm v5) 2005.09.20------------------------------------
	op_signextend_halfword_T1.op =
		get_op_signextend_halfword_T1 (&op_signextend_halfword_T1.
					       len);
	if (op_signextend_halfword_T1.len <= 0)
		return (-1);
	op_signextend_byte_T1.op =
		get_op_signextend_byte_T1 (&op_signextend_byte_T1.len);
	if (op_signextend_byte_T1.len <= 0)
		return (-1);

	op_ldrd_T0_T2_T1.op = get_op_ldrd_T0_T2_T1 (&op_ldrd_T0_T2_T1.len);
	if (op_ldrd_T0_T2_T1.len <= 0)
		return (-1);

	op_strd_T0_T2_T1.op = get_op_strd_T0_T2_T1 (&op_strd_T0_T2_T1.len);
	if (op_strd_T0_T2_T1.len <= 0)
		return (-1);
//AJ2D--------------------------------------------------------------------------

	return (0);
}
