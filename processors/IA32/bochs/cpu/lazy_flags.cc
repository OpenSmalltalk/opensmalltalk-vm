/////////////////////////////////////////////////////////////////////////
// $Id: lazy_flags.cc,v 1.48 2008/05/06 20:29:26 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2001  MandrakeSoft S.A.
//
//    MandrakeSoft S.A.
//    43, rue d'Aboukir
//    75002 Paris - France
//    http://www.linux-mandrake.com/
//    http://www.mandrakesoft.com/
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
/////////////////////////////////////////////////////////////////////////

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

// This array defines a look-up table for the even parity-ness
// of an 8bit quantity, for optimal assignment of the parity bit
// in the EFLAGS register
const bx_bool bx_parity_lookup[256] = {
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1
};

#define op1_8     ((Bit8u)(BX_CPU_THIS_PTR oszapc.op1))
#define op2_8     ((Bit8u)(BX_CPU_THIS_PTR oszapc.op2))
#define result_8  ((Bit8u)(BX_CPU_THIS_PTR oszapc.result))

#define op1_16    ((Bit16u)(BX_CPU_THIS_PTR oszapc.op1))
#define op2_16    ((Bit16u)(BX_CPU_THIS_PTR oszapc.op2))
#define result_16 ((Bit16u)(BX_CPU_THIS_PTR oszapc.result))

#define op1_32    ((Bit32u)(BX_CPU_THIS_PTR oszapc.op1))
#define op2_32    ((Bit32u)(BX_CPU_THIS_PTR oszapc.op2))
#define result_32 ((Bit32u)(BX_CPU_THIS_PTR oszapc.result))

#if BX_SUPPORT_X86_64
#define op1_64    ((Bit64u)(BX_CPU_THIS_PTR oszapc.op1))
#define op2_64    ((Bit64u)(BX_CPU_THIS_PTR oszapc.op2))
#define result_64 ((Bit64u)(BX_CPU_THIS_PTR oszapc.result))
#endif

bx_bool BX_CPU_C::get_CFLazy(void)
{
  unsigned cf;

  switch (BX_CPU_THIS_PTR oszapc.instr) {
    case BX_LF_INSTR_ADD8:
    case BX_LF_INSTR_ADD16:
    case BX_LF_INSTR_ADD32:
      cf = (result_32 < op1_32);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_ADD64:
      cf = (result_64 < op1_64);
      break;
#endif
    // used only if CF = 1 when executing ADC instruction
    case BX_LF_INSTR_ADC8:
    case BX_LF_INSTR_ADC16:
    case BX_LF_INSTR_ADC32:
      cf = (result_32 <= op1_32);
      break;
#if BX_SUPPORT_X86_64
    // used only if CF = 1 when executing ADC instruction
    case BX_LF_INSTR_ADC64:
      cf = (result_64 <= op1_64);
      break;
#endif
    case BX_LF_INSTR_SUB8:
    case BX_LF_INSTR_SUB16:
    case BX_LF_INSTR_SUB32:
      cf = (op1_32 < op2_32);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_SUB64:
      cf = (op1_64 < op2_64);
      break;
#endif
    // used only if CF = 1 when executing SBB instruction
    case BX_LF_INSTR_SBB8:
      cf = (op1_8 < result_8) || (op2_8==0xff);
      break;
    // used only if CF = 1 when executing SBB instruction
    case BX_LF_INSTR_SBB16:
      cf = (op1_16 < result_16) || (op2_16==0xffff);
      break;
    // used only if CF = 1 when executing SBB instruction
    case BX_LF_INSTR_SBB32:
      cf = (op1_32 < result_32) || (op2_32==0xffffffff);
      break;
#if BX_SUPPORT_X86_64
    // used only if CF = 1 when executing SBB instruction
    case BX_LF_INSTR_SBB64:
      cf = (op1_64 < result_64) || (op2_64==BX_CONST64(0xffffffffffffffff));
      break;
#endif
    case BX_LF_INSTR_NEG8:
    case BX_LF_INSTR_NEG16:
    case BX_LF_INSTR_NEG32:
      cf = (result_32 != 0);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_NEG64:
      cf = (result_64 != 0);
      break;
#endif
    case BX_LF_INSTR_LOGIC8:
    case BX_LF_INSTR_LOGIC16:
    case BX_LF_INSTR_LOGIC32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_LOGIC64:
#endif
      cf = 0;
      break;
    default:
      cf = 0; // Keep compiler quiet.
      BX_PANIC(("get_CF: OSZAPC: unknown instr %u",
            (unsigned) BX_CPU_THIS_PTR oszapc.instr));
  }

  return(cf);
}

bx_bool BX_CPU_C::get_AFLazy(void)
{
  unsigned af;

  switch (BX_CPU_THIS_PTR oszapc.instr) {
    case BX_LF_INSTR_ADD8:
    case BX_LF_INSTR_ADC8:
    case BX_LF_INSTR_SUB8:
    case BX_LF_INSTR_SBB8:
    case BX_LF_INSTR_ADD16:
    case BX_LF_INSTR_ADC16:
    case BX_LF_INSTR_SUB16:
    case BX_LF_INSTR_SBB16:
    case BX_LF_INSTR_ADD32:
    case BX_LF_INSTR_ADC32:
    case BX_LF_INSTR_SUB32:
    case BX_LF_INSTR_SBB32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_ADD64:
    case BX_LF_INSTR_ADC64:
    case BX_LF_INSTR_SUB64:
    case BX_LF_INSTR_SBB64:
#endif
      af = ((op1_8 ^ op2_8) ^ result_8) & 0x10;
      break;
    case BX_LF_INSTR_NEG8:
    case BX_LF_INSTR_NEG16:
    case BX_LF_INSTR_NEG32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_NEG64:
#endif
      af = (result_8 & 0xf) != 0;
      break;
    case BX_LF_INSTR_INC8:
    case BX_LF_INSTR_INC16:
    case BX_LF_INSTR_INC32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_INC64:
#endif
      af = (result_8 & 0xf) == 0;
      break;
    case BX_LF_INSTR_DEC8:
    case BX_LF_INSTR_DEC16:
    case BX_LF_INSTR_DEC32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_DEC64:
#endif
      af = (result_8 & 0xf) == 0xf;
      break;
    case BX_LF_INSTR_LOGIC8:
    case BX_LF_INSTR_LOGIC16:
    case BX_LF_INSTR_LOGIC32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_LOGIC64:
#endif
      af = 0;
      break;
    default:
      af = 0; // Keep compiler quiet.
      BX_PANIC(("get_AF: OSZAPC: unknown instr %u", (unsigned) BX_CPU_THIS_PTR oszapc.instr));
    }

    return(af);
}

#define GET_ADD_OVERFLOW(op1, op2, result, mask) \
  (((~((op1) ^ (op2)) & ((op2) ^ (result))) & (mask)) != 0)

#define GET_SUB_OVERFLOW(op1, op2, result, mask) \
   (((((op1) ^ (op2)) & ((op1) ^ (result))) & (mask)) != 0)

bx_bool BX_CPU_C::get_OFLazy(void)
{
  unsigned of;

  switch (BX_CPU_THIS_PTR oszapc.instr) {
    case BX_LF_INSTR_ADD8:
    case BX_LF_INSTR_ADC8:
    case BX_LF_INSTR_ADD16:
    case BX_LF_INSTR_ADC16:
    case BX_LF_INSTR_ADD32:
    case BX_LF_INSTR_ADC32:
      of = GET_ADD_OVERFLOW(op1_32, op2_32, result_32, 0x80000000);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_ADD64:
    case BX_LF_INSTR_ADC64:
      of = GET_ADD_OVERFLOW(op1_64, op2_64, result_64, BX_CONST64(0x8000000000000000));
      break;
#endif
    case BX_LF_INSTR_SUB8:
    case BX_LF_INSTR_SBB8:
    case BX_LF_INSTR_SUB16:
    case BX_LF_INSTR_SBB16:
    case BX_LF_INSTR_SUB32:
    case BX_LF_INSTR_SBB32:
      of = GET_SUB_OVERFLOW(op1_32, op2_32, result_32, 0x80000000);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_SUB64:
    case BX_LF_INSTR_SBB64:
      of = GET_SUB_OVERFLOW(op1_64, op2_64, result_64, BX_CONST64(0x8000000000000000));
      break;
#endif
    case BX_LF_INSTR_LOGIC8:
    case BX_LF_INSTR_LOGIC16:
    case BX_LF_INSTR_LOGIC32:
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_LOGIC64:
#endif
      of = 0;
      break;
    case BX_LF_INSTR_NEG8:
    case BX_LF_INSTR_INC8:
      of = (result_8 == 0x80);
      break;
    case BX_LF_INSTR_NEG16:
    case BX_LF_INSTR_INC16:
      of = (result_16 == 0x8000);
      break;
    case BX_LF_INSTR_NEG32:
    case BX_LF_INSTR_INC32:
      of = (result_32 == 0x80000000);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_NEG64:
    case BX_LF_INSTR_INC64:
      of = (result_64 == BX_CONST64(0x8000000000000000));
      break;
#endif
    case BX_LF_INSTR_DEC8:
      of = (result_8 == 0x7F);
      break;
    case BX_LF_INSTR_DEC16:
      of = (result_16 == 0x7FFF);
      break;
    case BX_LF_INSTR_DEC32:
      of = (result_32 == 0x7FFFFFFF);
      break;
#if BX_SUPPORT_X86_64
    case BX_LF_INSTR_DEC64:
      of = (result_64 == BX_CONST64(0x7FFFFFFFFFFFFFFF));
      break;
#endif
    default:
      of = 0; // Keep compiler happy.
      BX_PANIC(("get_OF: OSZAPC: unknown instr"));
    }

    return(of);
}
