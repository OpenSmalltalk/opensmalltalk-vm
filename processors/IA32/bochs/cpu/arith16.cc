/////////////////////////////////////////////////////////////////////////
// $Id: arith16.cc,v 1.71 2008/08/09 21:05:05 sshwarts Exp $
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

void BX_CPP_AttrRegparmN(1) BX_CPU_C::INC_RX(bxInstruction_c *i)
{
  Bit16u rx = ++BX_READ_16BIT_REG(i->opcodeReg());
  SET_FLAGS_OSZAPC_INC_16(rx);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::DEC_RX(bxInstruction_c *i)
{
  Bit16u rx = --BX_READ_16BIT_REG(i->opcodeReg());
  SET_FLAGS_OSZAPC_DEC_16(rx);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADD_EwGwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  sum_16 = op1_16 + op2_16;
  write_RMW_virtual_word(sum_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADD_GwEwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;

  op1_16 = BX_READ_16BIT_REG(i->nnn());
  op2_16 = BX_READ_16BIT_REG(i->rm());
  sum_16 = op1_16 + op2_16;

  BX_WRITE_16BIT_REG(i->nnn(), sum_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADD_AXIw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;

  op1_16 = AX;
  op2_16 = i->Iw();
  sum_16 = op1_16 + op2_16;
  AX = sum_16;

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADC_EwGwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;
  bx_bool temp_CF = getB_CF();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  sum_16 = op1_16 + op2_16 + temp_CF;
  write_RMW_virtual_word(sum_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_LF_INSTR_ADD_ADC16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADC_GwEwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;
  bx_bool temp_CF = getB_CF();

  op1_16 = BX_READ_16BIT_REG(i->nnn());
  op2_16 = BX_READ_16BIT_REG(i->rm());
  sum_16 = op1_16 + op2_16 + temp_CF;
  BX_WRITE_16BIT_REG(i->nnn(), sum_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_LF_INSTR_ADD_ADC16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADC_AXIw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, sum_16;
  bx_bool temp_CF = getB_CF();

  op1_16 = AX;
  op2_16 = i->Iw();
  sum_16 = op1_16 + op2_16 + temp_CF;
  AX = sum_16;

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_LF_INSTR_ADD_ADC16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SBB_EwGwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;
  bx_bool temp_CF = getB_CF();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  diff_16 = op1_16 - (op2_16 + temp_CF);
  write_RMW_virtual_word(diff_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_LF_INSTR_SUB_SBB16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SBB_GwEwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;
  bx_bool temp_CF = getB_CF();

  op1_16 = BX_READ_16BIT_REG(i->nnn());
  op2_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - (op2_16 + temp_CF);
  BX_WRITE_16BIT_REG(i->nnn(), diff_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_LF_INSTR_SUB_SBB16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SBB_AXIw(bxInstruction_c *i)
{
  bx_bool temp_CF = getB_CF();
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = AX;
  op2_16 = i->Iw();
  diff_16 = op1_16 - (op2_16 + temp_CF);
  AX = diff_16;

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_LF_INSTR_SUB_SBB16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SBB_EwIwM(bxInstruction_c *i)
{
  bx_bool temp_CF = getB_CF();
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  diff_16 = op1_16 - (op2_16 + temp_CF);
  write_RMW_virtual_word(diff_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_LF_INSTR_SUB_SBB16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SBB_EwIwR(bxInstruction_c *i)
{
  bx_bool temp_CF = getB_CF();
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - (op2_16 + temp_CF);
  BX_WRITE_16BIT_REG(i->rm(), diff_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_LF_INSTR_SUB_SBB16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SUB_EwGwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  diff_16 = op1_16 - op2_16;
  write_RMW_virtual_word(diff_16);

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SUB_GwEwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = BX_READ_16BIT_REG(i->nnn());
  op2_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - op2_16;
  BX_WRITE_16BIT_REG(i->nnn(), diff_16);

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SUB_AXIw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = AX;
  op2_16 = i->Iw();
  diff_16 = op1_16 - op2_16;
  AX = diff_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMP_EwGwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMP_GwEwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = BX_READ_16BIT_REG(i->nnn());
  op2_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMP_AXIw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = AX;
  op2_16 = i->Iw();
  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CBW(bxInstruction_c *i)
{
  /* CBW: no flags are effected */
  AX = (Bit8s) AL;
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CWD(bxInstruction_c *i)
{
  /* CWD: no flags are affected */
  if (AX & 0x8000) {
    DX = 0xFFFF;
  }
  else {
    DX = 0x0000;
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::XADD_EwGwM(bxInstruction_c *i)
{
#if BX_CPU_LEVEL >= 4
  Bit16u op1_16, op2_16, sum_16;

  /* XADD dst(r/m), src(r)
   * temp <-- src + dst         | sum = op2 + op1
   * src  <-- dst               | op2 = op1
   * dst  <-- tmp               | op1 = sum
   */

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  sum_16 = op1_16 + op2_16;
  write_RMW_virtual_word(sum_16);

  /* and write destination into source */
  BX_WRITE_16BIT_REG(i->nnn(), op1_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
#else
  BX_INFO(("XADD_EwGw: not supported on < 80486"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::XADD_EwGwR(bxInstruction_c *i)
{
#if BX_CPU_LEVEL >= 4
  Bit16u op1_16, op2_16, sum_16;

  /* XADD dst(r/m), src(r)
   * temp <-- src + dst         | sum = op2 + op1
   * src  <-- dst               | op2 = op1
   * dst  <-- tmp               | op1 = sum
   */

  op1_16 = BX_READ_16BIT_REG(i->rm());
  op2_16 = BX_READ_16BIT_REG(i->nnn());
  sum_16 = op1_16 + op2_16;

  // and write destination into source
  // Note: if both op1 & op2 are registers, the last one written
  //       should be the sum, as op1 & op2 may be the same register.
  //       For example:  XADD AL, AL
  BX_WRITE_16BIT_REG(i->nnn(), op1_16);
  BX_WRITE_16BIT_REG(i->rm(), sum_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
#else
  BX_INFO(("XADD_EwGw: not supported on < 80486"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADD_EwIwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), sum_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  sum_16 = op1_16 + op2_16;
  write_RMW_virtual_word(sum_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADD_EwIwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), sum_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  sum_16 = op1_16 + op2_16;
  BX_WRITE_16BIT_REG(i->rm(), sum_16);

  SET_FLAGS_OSZAPC_ADD_16(op1_16, op2_16, sum_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADC_EwIwM(bxInstruction_c *i)
{
  bx_bool temp_CF = getB_CF();
  Bit16u op1_16, op2_16 = i->Iw(), sum_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  sum_16 = op1_16 + op2_16 + temp_CF;
  write_RMW_virtual_word(sum_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_LF_INSTR_ADD_ADC16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ADC_EwIwR(bxInstruction_c *i)
{
  bx_bool temp_CF = getB_CF();
  Bit16u op1_16, op2_16 = i->Iw(), sum_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  sum_16 = op1_16 + op2_16 + temp_CF;
  BX_WRITE_16BIT_REG(i->rm(), sum_16);

  SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_LF_INSTR_ADD_ADC16(temp_CF));
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SUB_EwIwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  diff_16 = op1_16 - op2_16;
  write_RMW_virtual_word(diff_16);

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SUB_EwIwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - op2_16;
  BX_WRITE_16BIT_REG(i->rm(), diff_16);

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMP_EwIwM(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_virtual_word(i->seg(), eaddr);
  diff_16 = op1_16 - op2_16;
  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMP_EwIwR(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16 = i->Iw(), diff_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = op1_16 - op2_16;
  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::NEG_EwM(bxInstruction_c *i)
{
  Bit16u op1_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op1_16 = - (Bit16s)(op1_16);
  write_RMW_virtual_word(op1_16);

  SET_FLAGS_OSZAPC_RESULT_16(op1_16, BX_LF_INSTR_NEG16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::NEG_EwR(bxInstruction_c *i)
{
  Bit16u op1_16 = BX_READ_16BIT_REG(i->rm());
  op1_16 = - (Bit16s)(op1_16);
  BX_WRITE_16BIT_REG(i->rm(), op1_16);

  SET_FLAGS_OSZAPC_RESULT_16(op1_16, BX_LF_INSTR_NEG16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::INC_EwM(bxInstruction_c *i)
{
  Bit16u op1_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op1_16++;
  write_RMW_virtual_word(op1_16);

  SET_FLAGS_OSZAPC_INC_16(op1_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::DEC_EwM(bxInstruction_c *i)
{
  Bit16u op1_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  op1_16--;
  write_RMW_virtual_word(op1_16);

  SET_FLAGS_OSZAPC_DEC_16(op1_16);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPXCHG_EwGwM(bxInstruction_c *i)
{
#if BX_CPU_LEVEL >= 4
  Bit16u op1_16, op2_16, diff_16;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  diff_16 = AX - op1_16;
  SET_FLAGS_OSZAPC_SUB_16(AX, op1_16, diff_16);

  if (diff_16 == 0) {  // if accumulator == dest
    // dest <-- src
    op2_16 = BX_READ_16BIT_REG(i->nnn());
    write_RMW_virtual_word(op2_16);
  }
  else {
    // accumulator <-- dest
    AX = op1_16;
  }
#else
  BX_INFO(("CMPXCHG_EwGw: not supported for cpu-level <= 3"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPXCHG_EwGwR(bxInstruction_c *i)
{
#if BX_CPU_LEVEL >= 4
  Bit16u op1_16, op2_16, diff_16;

  op1_16 = BX_READ_16BIT_REG(i->rm());
  diff_16 = AX - op1_16;
  SET_FLAGS_OSZAPC_SUB_16(AX, op1_16, diff_16);

  if (diff_16 == 0) {  // if accumulator == dest
    // dest <-- src
    op2_16 = BX_READ_16BIT_REG(i->nnn());
    BX_WRITE_16BIT_REG(i->rm(), op2_16);
  }
  else {
    // accumulator <-- dest
    AX = op1_16;
  }
#else
  BX_INFO(("CMPXCHG_EwGw: not supported for cpu-level <= 3"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}
