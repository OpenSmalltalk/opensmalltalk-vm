/////////////////////////////////////////////////////////////////////////
// $Id: shift8.cc,v 1.38 2008/08/08 09:22:48 sshwarts Exp $
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

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROL_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned bit0, bit7;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  if ((count & 0x07) == 0) {
    if (count & 0x18) {
      bit0 = (op1_8 &  1);
      bit7 = (op1_8 >> 7);
      SET_FLAGS_OxxxxC(bit0 ^ bit7, bit0);
    }
    return;
  }

  count &= 0x7; // use only lowest 3 bits

  result_8 = (op1_8 << count) | (op1_8 >> (8 - count));

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  /* set eflags:
   * ROL count affects the following flags: C, O
   */

  bit0 = (result_8 &  1);
  bit7 = (result_8 >> 7);

  SET_FLAGS_OxxxxC(bit0 ^ bit7, bit0);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROR_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned bit6, bit7;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  if ((count & 0x07) == 0) {
    if (count & 0x18) {
      bit6 = (op1_8 >> 6) & 1;
      bit7 = (op1_8 >> 7) & 1;

      SET_FLAGS_OxxxxC(bit6 ^ bit7, bit7);
    }
    return;
  }

  count &= 0x7; /* use only bottom 3 bits */

  result_8 = (op1_8 >> count) | (op1_8 << (8 - count));

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  /* set eflags:
   * ROR count affects the following flags: C, O
   */

  bit6 = (result_8 >> 6) & 1;
  bit7 = (result_8 >> 7) & 1;

  SET_FLAGS_OxxxxC(bit6 ^ bit7, bit7);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCL_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned of, cf;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  count = (count & 0x1f) % 9;

  if (! count) return;

  if (count==1) {
    result_8 = (op1_8 << 1) | getB_CF();
  }
  else {
    result_8 = (op1_8 << count) | (getB_CF() << (count - 1)) |
               (op1_8 >> (9 - count));
  }

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  cf = (op1_8 >> (8 - count)) & 0x01;
  of = cf ^ (result_8 >> 7);  // of = cf ^ result7
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCR_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  count = (count & 0x1f) % 9;

  if (! count) return;

  result_8 = (op1_8 >> count) | (getB_CF() << (8 - count)) |
             (op1_8 << (9 - count));

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  cf = (op1_8 >> (count - 1)) & 0x1;
  of = ((result_8 << 1) ^ result_8) >> 7; // of = result6 ^ result7
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHL_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned of = 0, cf = 0;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  count &= 0x1f;

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  if (!count) return;

  if (count <= 8) {
    result_8 = (op1_8 << count);
    cf = (op1_8 >> (8 - count)) & 0x1;
    of = cf ^ (result_8 >> 7);
  }
  else {
    result_8 = 0;
  }

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  SET_FLAGS_OSZAPC_LOGIC_8(result_8); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHR_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  count &= 0x1f;

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  if (!count) return;

  result_8 = (op1_8 >> count);

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }

  cf = (op1_8 >> (count - 1)) & 0x1;
  // note, that of == result7 if count == 1 and
  //            of == 0       if count >= 2
  of = ((result_8 << 1) ^ result_8) >> 7;

  SET_FLAGS_OSZAPC_LOGIC_8(result_8); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SAR_Eb(bxInstruction_c *i)
{
  Bit8u op1_8, result_8;
  unsigned count, cf;

  if (i->b1() == 0xd2)
    count = CL;
  else // 0xc0 or 0xd0
    count = i->Ib();

  count &= 0x1f;

  /* op1 is a register or memory reference */
  if (i->modC0()) {
    op1_8 = BX_READ_8BIT_REGx(i->rm(), i->extend8bitL());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_8 = read_RMW_virtual_byte(i->seg(), eaddr);
  }

  if (!count) return;

  if (count < 8) {
    if (op1_8 & 0x80) {
      result_8 = (op1_8 >> count) | (0xff << (8 - count));
    }
    else {
      result_8 = (op1_8 >> count);
    }

    cf = (op1_8 >> (count - 1)) & 0x1;
  }
  else {
    if (op1_8 & 0x80) {
      result_8 = 0xff;
    }
    else {
      result_8 = 0;
    }

    cf = (result_8 & 0x1);
  }

  SET_FLAGS_OSZAPC_LOGIC_8(result_8); /* handle SF, ZF and AF flags */
  /* signed overflow cannot happen in SAR instruction */
  SET_FLAGS_OxxxxC(0, cf);

  /* now write result back to destination */
  if (i->modC0()) {
    BX_WRITE_8BIT_REGx(i->rm(), i->extend8bitL(), result_8);
  }
  else {
    write_RMW_virtual_byte(result_8);
  }
}
