/////////////////////////////////////////////////////////////////////////
// $Id: shift32.cc,v 1.46 2008/08/08 09:22:48 sshwarts Exp $
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

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHLD_EdGdM(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, result_32;
  unsigned count;
  unsigned of, cf;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xa4) // 0x1a4
    count = i->Ib();
  else // 0x1a5
    count = CL;

  count &= 0x1f; // use only 5 LSB's
  if (!count) return;

  op2_32 = BX_READ_32BIT_REG(i->nnn());

  result_32 = (op1_32 << count) | (op2_32 >> (32 - count));

  write_RMW_virtual_dword(result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */

  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31); // of = cf ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHLD_EdGdR(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, result_32;
  unsigned count;
  unsigned of, cf;

  if (i->b1() == 0xa4) // 0x1a4
    count = i->Ib();
  else // 0x1a5
    count = CL;

  count &= 0x1f; // use only 5 LSB's
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());
  op2_32 = BX_READ_32BIT_REG(i->nnn());

  result_32 = (op1_32 << count) | (op2_32 >> (32 - count));

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */

  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31); // of = cf ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHRD_EdGdM(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, result_32;
  unsigned count;
  unsigned cf, of;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xac) // 0x1ac
    count = i->Ib();
  else // 0x1ad
    count = CL;

  count &= 0x1f; // use only 5 LSB's
  if (!count) return;

  op2_32 = BX_READ_32BIT_REG(i->nnn());

  result_32 = (op2_32 << (32 - count)) | (op1_32 >> count);

  write_RMW_virtual_dword(result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */

  cf = (op1_32 >> (count - 1)) & 0x1;
  of = ((result_32 << 1) ^ result_32) >> 31; // of = result30 ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHRD_EdGdR(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, result_32;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xac) // 0x1ac
    count = i->Ib();
  else // 0x1ad
    count = CL;

  count &= 0x1f; // use only 5 LSB's
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());
  op2_32 = BX_READ_32BIT_REG(i->nnn());

  result_32 = (op2_32 << (32 - count)) | (op1_32 >> count);

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */

  cf = (op1_32 >> (count - 1)) & 0x1;
  of = ((result_32 << 1) ^ result_32) >> 31; // of = result30 ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROL_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (! count) return;

  result_32 = (op1_32 << count) | (op1_32 >> (32 - count));

  write_RMW_virtual_dword(result_32);

  unsigned bit0  = (result_32 & 0x1);
  unsigned bit31 = (result_32 >> 31);
  // of = cf ^ result31
  SET_FLAGS_OxxxxC(bit0 ^ bit31, bit0);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROL_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned bit0, bit31;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (! count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());
  result_32 = (op1_32 << count) | (op1_32 >> (32 - count));
  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  bit0  = (result_32 & 0x1);
  bit31 = (result_32 >> 31);
  // of = cf ^ result31
  SET_FLAGS_OxxxxC(bit0 ^ bit31, bit0);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROR_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned bit31, bit30;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (! count) return;

  result_32 = (op1_32 >> count) | (op1_32 << (32 - count));

  write_RMW_virtual_dword(result_32);

  bit31 = (result_32 >> 31) & 1;
  bit30 = (result_32 >> 30) & 1;
  // of = result30 ^ result31
  SET_FLAGS_OxxxxC(bit30 ^ bit31, bit31);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ROR_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned bit31, bit30;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (! count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());
  result_32 = (op1_32 >> count) | (op1_32 << (32 - count));
  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  bit31 = (result_32 >> 31) & 1;
  bit30 = (result_32 >> 30) & 1;
  // of = result30 ^ result31
  SET_FLAGS_OxxxxC(bit30 ^ bit31, bit31);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCL_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  if (count==1) {
    result_32 = (op1_32 << 1) | getB_CF();
  }
  else {
    result_32 = (op1_32 << count) | (getB_CF() << (count - 1)) |
                (op1_32 >> (33 - count));
  }

  write_RMW_virtual_dword(result_32);

  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31); // of = cf ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCL_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());

  if (count==1) {
    result_32 = (op1_32 << 1) | getB_CF();
  }
  else {
    result_32 = (op1_32 << count) | (getB_CF() << (count - 1)) |
                (op1_32 >> (33 - count));
  }

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31); // of = cf ^ result31
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCR_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  if (count==1) {
    result_32 = (op1_32 >> 1) | (getB_CF() << 31);
  }
  else {
    result_32 = (op1_32 >> count) | (getB_CF() << (32 - count)) |
                (op1_32 << (33 - count));
  }

  write_RMW_virtual_dword(result_32);

  cf = (op1_32 >> (count - 1)) & 0x1;
  of = ((result_32 << 1) ^ result_32) >> 31; // of = result30 ^ result31
  SET_FLAGS_OxxxxC(of, cf);

}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RCR_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());

  if (count==1) {
    result_32 = (op1_32 >> 1) | (getB_CF() << 31);
  }
  else {
    result_32 = (op1_32 >> count) | (getB_CF() << (32 - count)) |
                (op1_32 << (33 - count));
  }

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  cf = (op1_32 >> (count - 1)) & 0x1;
  of = ((result_32 << 1) ^ result_32) >> 31; // of = result30 ^ result31
  SET_FLAGS_OxxxxC(of, cf);

}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHL_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  /* count < 32, since only lower 5 bits used */
  result_32 = (op1_32 << count);

  write_RMW_virtual_dword(result_32);

  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31);
  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHL_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned cf, of;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());

  /* count < 32, since only lower 5 bits used */
  result_32 = (op1_32 << count);
  cf = (op1_32 >> (32 - count)) & 0x1;
  of = cf ^ (result_32 >> 31);

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHR_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned of, cf;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  result_32 = (op1_32 >> count);

  write_RMW_virtual_dword(result_32);

  cf = (op1_32 >> (count - 1)) & 0x1;
  // note, that of == result31 if count == 1 and
  //            of == 0        if count >= 2
  of = ((result_32 << 1) ^ result_32) >> 31;

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SHR_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;
  unsigned of, cf;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());
  result_32 = (op1_32 >> count);
  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  cf = (op1_32 >> (count - 1)) & 0x1;
  // note, that of == result31 if count == 1 and
  //            of == 0        if count >= 2
  of = ((result_32 << 1) ^ result_32) >> 31;

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  SET_FLAGS_OxxxxC(of, cf);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SAR_EdM(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_RMW_virtual_dword(i->seg(), eaddr);

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  /* count < 32, since only lower 5 bits used */
  if (op1_32 & 0x80000000) {
    result_32 = (op1_32 >> count) | (0xffffffff << (32 - count));
  }
  else {
    result_32 = (op1_32 >> count);
  }

  write_RMW_virtual_dword(result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  set_CF((op1_32 >> (count - 1)) & 1);
  clear_OF();  /* signed overflow cannot happen in SAR instruction */
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SAR_EdR(bxInstruction_c *i)
{
  Bit32u op1_32, result_32;
  unsigned count;

  if (i->b1() == 0xd3)
    count = CL;
  else // 0xc1 or 0xd1
    count = i->Ib();

  count &= 0x1f;
  if (!count) return;

  op1_32 = BX_READ_32BIT_REG(i->rm());

  /* count < 32, since only lower 5 bits used */
  if (op1_32 & 0x80000000) {
    result_32 = (op1_32 >> count) | (0xffffffff << (32 - count));
  }
  else {
    result_32 = (op1_32 >> count);
  }

  BX_WRITE_32BIT_REGZ(i->rm(), result_32);

  SET_FLAGS_OSZAPC_LOGIC_32(result_32); /* handle SF, ZF and AF flags */
  set_CF((op1_32 >> (count - 1)) & 1);
  clear_OF();  /* signed overflow cannot happen in SAR instruction */
}
