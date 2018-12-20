/////////////////////////////////////////////////////////////////////////
// $Id: stack.h,v 1.3 2008/06/12 19:14:39 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2007 Stanislav Shwartsman
//          Written by Stanislav Shwartsman [sshwarts at sourceforge net]
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
//
/////////////////////////////////////////////////////////////////////////

#ifndef BX_PUSHPOP_H
#define BX_PUSHPOP_H

  BX_CPP_INLINE void BX_CPP_AttrRegparmN(1)
BX_CPU_C::push_16(Bit16u value16)
{
  /* must use StackAddrSize, and either RSP, ESP or SP accordingly */
#if BX_SUPPORT_X86_64
  if (StackAddrSize64()) {
    write_virtual_word_64(BX_SEG_REG_SS, RSP-2, value16);
    RSP -= 2;
  }
  else
#endif
  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b) { /* StackAddrSize = 32 */
    write_virtual_word_32(BX_SEG_REG_SS, (Bit32u) (ESP-2), value16);
    ESP -= 2;
  }
  else
  {
    write_virtual_word_32(BX_SEG_REG_SS, (Bit16u) (SP-2), value16);
    SP -= 2;
  }
}

  BX_CPP_INLINE void BX_CPP_AttrRegparmN(1)
BX_CPU_C::push_32(Bit32u value32)
{
  /* must use StackAddrSize, and either RSP, ESP or SP accordingly */
#if BX_SUPPORT_X86_64
  if (StackAddrSize64()) {
    write_virtual_dword_64(BX_SEG_REG_SS, RSP-4, value32);
    RSP -= 4;
  }
  else
#endif
  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b) { /* StackAddrSize = 32 */
    write_virtual_dword_32(BX_SEG_REG_SS, (Bit32u) (ESP-4), value32);
    ESP -= 4;
  }
  else
  {
    write_virtual_dword_32(BX_SEG_REG_SS, (Bit16u) (SP-4), value32);
    SP -= 4;
  }
}

/* push 64 bit operand */
#if BX_SUPPORT_X86_64
  BX_CPP_INLINE void BX_CPP_AttrRegparmN(1)
BX_CPU_C::push_64(Bit64u value64)
{
  write_virtual_qword_64(BX_SEG_REG_SS, RSP-8, value64);
  RSP -= 8;
}
#endif

/* pop 16 bit operand from the stack */
BX_CPP_INLINE Bit16u BX_CPU_C::pop_16(void)
{
  Bit16u value16;

#if BX_SUPPORT_X86_64
  if (StackAddrSize64()) {
    value16 = read_virtual_word_64(BX_SEG_REG_SS, RSP);
    RSP += 2;
  }
  else
#endif
  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b) {
    value16 = read_virtual_word_32(BX_SEG_REG_SS, ESP);
    ESP += 2;
  }
  else {
    value16 = read_virtual_word_32(BX_SEG_REG_SS, SP);
    SP += 2;
  }

  return value16;
}

/* pop 32 bit operand from the stack */
BX_CPP_INLINE Bit32u BX_CPU_C::pop_32(void)
{
  Bit32u value32;

#if BX_SUPPORT_X86_64
  if (StackAddrSize64()) {
    value32 = read_virtual_dword_64(BX_SEG_REG_SS, RSP);
    RSP += 4;
  }
  else
#endif
  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b) {
    value32 = read_virtual_dword_32(BX_SEG_REG_SS, ESP);
    ESP += 4;
  }
  else {
    value32 = read_virtual_dword_32(BX_SEG_REG_SS, SP);
    SP += 4;
  }

  return value32;
}

/* pop 64 bit operand from the stack */
#if BX_SUPPORT_X86_64
BX_CPP_INLINE Bit64u BX_CPU_C::pop_64(void)
{
  Bit64u value64 = read_virtual_qword_64(BX_SEG_REG_SS, RSP);
  RSP += 8;

  return value64;
}
#endif // BX_SUPPORT_X86_64

#endif
