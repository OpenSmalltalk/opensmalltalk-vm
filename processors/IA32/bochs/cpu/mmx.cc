/////////////////////////////////////////////////////////////////////////
// $Id: mmx.cc,v 1.81 2008/08/08 09:22:47 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2002 Stanislav Shwartsman
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

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

#if BX_SUPPORT_MMX || BX_SUPPORT_SSE

void BX_CPU_C::print_state_MMX(void)
{
  for(int i=0;i<8;i++) {
      BxPackedMmxRegister mm = BX_READ_MMX_REG(i);
      BX_DEBUG(("MM%d: %08x%08x\n", i, MMXUD1(mm), MMXUD0(mm)));
  }
}

void BX_CPU_C::prepareMMX(void)
{
  if(BX_CPU_THIS_PTR cr0.get_EM())
    exception(BX_UD_EXCEPTION, 0, 0);

  if(BX_CPU_THIS_PTR cr0.get_TS())
    exception(BX_NM_EXCEPTION, 0, 0);

  /* cause transition from FPU to MMX technology state */
  BX_CPU_THIS_PTR prepareFPU2MMX();
}

void BX_CPU_C::prepareFPU2MMX(void)
{
  /* check floating point status word for a pending FPU exceptions */
  FPU_check_pending_exceptions();

  FPU_TAG_WORD = 0;
  FPU_TOS = 0;        /* reset FPU Top-Of-Stack */
}

#endif

#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)

/* 0F 38 00 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSHUFB_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  for(unsigned j=0; j<8; j++)
  {
    unsigned mask = op2.mmxubyte(j);
    if (mask & 0x80)
      result.mmxubyte(j) = 0;
    else
      result.mmxubyte(j) = op1.mmxubyte(mask & 0x7);
  }

  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSHUFB_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 01 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHADDW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(result) = MMXUW0(op1) + MMXUW1(op1);
  MMXUW1(result) = MMXUW2(op1) + MMXUW3(op1);
  MMXUW2(result) = MMXUW0(op2) + MMXUW1(op2);
  MMXUW3(result) = MMXUW2(op2) + MMXUW3(op2);

  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHADDW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 02 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHADDD_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(result) = MMXUD0(op1) + MMXUD1(op1);
  MMXUD1(result) = MMXUD0(op2) + MMXUD1(op2);

  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHADDD_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 03 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHADDSW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSW0(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op1)) + Bit32s(MMXSW1(op1)));
  MMXSW1(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op1)) + Bit32s(MMXSW3(op1)));
  MMXSW2(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op2)) + Bit32s(MMXSW1(op2)));
  MMXSW3(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op2)) + Bit32s(MMXSW3(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHADDSW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 04 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMADDUBSW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  for(unsigned j=0; j<4; j++)
  {
    Bit32s temp = Bit32s(op1.mmxubyte(j*2+0))*Bit32s(op2.mmxsbyte(j*2+0)) +
                  Bit32s(op1.mmxubyte(j*2+1))*Bit32s(op2.mmxsbyte(j*2+1));

    result.mmx16s(j) = SaturateDwordSToWordS(temp);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMADDUBSW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 05 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHSUBSW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSW0(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op1)) - Bit32s(MMXSW1(op1)));
  MMXSW1(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op1)) - Bit32s(MMXSW3(op1)));
  MMXSW2(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op2)) - Bit32s(MMXSW1(op2)));
  MMXSW3(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op2)) - Bit32s(MMXSW3(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHSUBSW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 05 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHSUBW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(result) = MMXUW0(op1) - MMXUW1(op1);
  MMXUW1(result) = MMXUW2(op1) - MMXUW3(op1);
  MMXUW2(result) = MMXUW0(op2) - MMXUW1(op2);
  MMXUW3(result) = MMXUW2(op2) - MMXUW3(op2);

  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHSUBW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 06 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PHSUBD_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(result) = MMXUD0(op1) - MMXUD1(op1);
  MMXUD1(result) = MMXUD0(op2) - MMXUD1(op2);

  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PHSUBD_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 08 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSIGNB_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  for(unsigned j=0; j<8; j++) {
    int sign = (op2.mmxsbyte(j) > 0) - (op2.mmxsbyte(j) < 0);
    op1.mmxsbyte(j) *= sign;
  }

  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSIGNB_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 09 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSIGNW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  for(unsigned j=0; j<4; j++) {
    int sign = (op2.mmx16s(j) > 0) - (op2.mmx16s(j) < 0);
    op1.mmx16s(j) *= sign;
  }

  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSIGNW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 0A */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSIGND_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  int sign;

  sign = (MMXSD0(op2) > 0) - (MMXSD0(op2) < 0);
  MMXSD0(op1) *= sign;
  sign = (MMXSD1(op2) > 0) - (MMXSD1(op2) < 0);
  MMXSD1(op1) *= sign;

  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSIGND_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 0B */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMULHRSW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  for(unsigned j=0; j<4; j++) {
    Bit32s temp = Bit32s(op1.mmx16s(j)) * Bit32s(op2.mmx16s(j));
    result.mmx16u(j) = ((temp >> 14) + 1) >> 1;
  }

  MMXUW0(result) = (((MMXSW0(op1) * MMXSW0(op2)) >> 14) + 1) >> 1;
  MMXUW1(result) = (((MMXSW1(op1) * MMXSW1(op2)) >> 14) + 1) >> 1;
  MMXUW2(result) = (((MMXSW2(op1) * MMXSW2(op2)) >> 14) + 1) >> 1;
  MMXUW3(result) = (((MMXSW3(op1) * MMXSW3(op2)) >> 14) + 1) >> 1;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMULHRSW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 1C */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PABSB_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  if (i->modC0()) {
    op = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword(i->seg(), eaddr);
  }

  if (MMXSB0(op) < 0) MMXUB0(op) = -MMXSB0(op);
  if (MMXSB1(op) < 0) MMXUB1(op) = -MMXSB1(op);
  if (MMXSB2(op) < 0) MMXUB2(op) = -MMXSB2(op);
  if (MMXSB3(op) < 0) MMXUB3(op) = -MMXSB3(op);
  if (MMXSB4(op) < 0) MMXUB4(op) = -MMXSB4(op);
  if (MMXSB5(op) < 0) MMXUB5(op) = -MMXSB5(op);
  if (MMXSB6(op) < 0) MMXUB6(op) = -MMXSB6(op);
  if (MMXSB7(op) < 0) MMXUB7(op) = -MMXSB7(op);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
#else
  BX_INFO(("PABSB_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 1D */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PABSW_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  if (i->modC0()) {
    op = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword(i->seg(), eaddr);
  }

  if (MMXSW0(op) < 0) MMXUW0(op) = -MMXSW0(op);
  if (MMXSW1(op) < 0) MMXUW1(op) = -MMXSW1(op);
  if (MMXSW2(op) < 0) MMXUW2(op) = -MMXSW2(op);
  if (MMXSW3(op) < 0) MMXUW3(op) = -MMXSW3(op);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
#else
  BX_INFO(("PABSW_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 38 1E */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PABSD_PqQq(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  if (i->modC0()) {
    op = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword(i->seg(), eaddr);
  }

  if (MMXSD0(op) < 0) MMXUD0(op) = -MMXSD0(op);
  if (MMXSD1(op) < 0) MMXUD1(op) = -MMXSD1(op);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
#else
  BX_INFO(("PABSD_PqQq: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 3A 0F */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PALIGNR_PqQqIb(bxInstruction_c *i)
{
#if (BX_SUPPORT_SSE >= 4) || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  unsigned shift = i->Ib() * 8;

  if(shift == 0)
    MMXUQ(result) = MMXUQ(op2);
  else if(shift < 64)
    MMXUQ(result) = (MMXUQ(op2) >> shift) | (MMXUQ(op1) << (64-shift));
  else if(shift < 128)
    MMXUQ(result) = MMXUQ(op1) >> (shift-64);
  else
    MMXUQ(result) = 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PALIGNR_PqQqIb: required SSE3E, use --enable-sse and --enable-sse-extension options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

#endif // BX_SUPPORT_SSE >= 4 || (BX_SUPPORT_SSE >= 3 && BX_SUPPORT_SSE_EXTENSION > 0)

/* 0F 60 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKLBW_PqQd(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB7(result) = MMXUB3(op2);
  MMXUB6(result) = MMXUB3(op1);
  MMXUB5(result) = MMXUB2(op2);
  MMXUB4(result) = MMXUB2(op1);
  MMXUB3(result) = MMXUB1(op2);
  MMXUB2(result) = MMXUB1(op1);
  MMXUB1(result) = MMXUB0(op2);
  MMXUB0(result) = MMXUB0(op1);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PUNPCKLBW_PqQd: required MMX, configure --enable-mmx"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 61 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKLWD_PqQd(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW3(result) = MMXUW1(op2);
  MMXUW2(result) = MMXUW1(op1);
  MMXUW1(result) = MMXUW0(op2);
  MMXUW0(result) = MMXUW0(op1);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PUNPCKLWD_PqQd: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 62 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKLDQ_PqQd(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD1(op1) = MMXUD0(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PUNPCKLDQ_PqQd: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 63 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PACKSSWB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSB0(result) = SaturateWordSToByteS(MMXSW0(op1));
  MMXSB1(result) = SaturateWordSToByteS(MMXSW1(op1));
  MMXSB2(result) = SaturateWordSToByteS(MMXSW2(op1));
  MMXSB3(result) = SaturateWordSToByteS(MMXSW3(op1));
  MMXSB4(result) = SaturateWordSToByteS(MMXSW0(op2));
  MMXSB5(result) = SaturateWordSToByteS(MMXSW1(op2));
  MMXSB6(result) = SaturateWordSToByteS(MMXSW2(op2));
  MMXSB7(result) = SaturateWordSToByteS(MMXSW3(op2));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PACKSSWB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 64 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPGTB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(op1) = (MMXSB0(op1) > MMXSB0(op2)) ? 0xff : 0;
  MMXUB1(op1) = (MMXSB1(op1) > MMXSB1(op2)) ? 0xff : 0;
  MMXUB2(op1) = (MMXSB2(op1) > MMXSB2(op2)) ? 0xff : 0;
  MMXUB3(op1) = (MMXSB3(op1) > MMXSB3(op2)) ? 0xff : 0;
  MMXUB4(op1) = (MMXSB4(op1) > MMXSB4(op2)) ? 0xff : 0;
  MMXUB5(op1) = (MMXSB5(op1) > MMXSB5(op2)) ? 0xff : 0;
  MMXUB6(op1) = (MMXSB6(op1) > MMXSB6(op2)) ? 0xff : 0;
  MMXUB7(op1) = (MMXSB7(op1) > MMXSB7(op2)) ? 0xff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPGTB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 65 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPGTW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(op1) = (MMXSW0(op1) > MMXSW0(op2)) ? 0xffff : 0;
  MMXUW1(op1) = (MMXSW1(op1) > MMXSW1(op2)) ? 0xffff : 0;
  MMXUW2(op1) = (MMXSW2(op1) > MMXSW2(op2)) ? 0xffff : 0;
  MMXUW3(op1) = (MMXSW3(op1) > MMXSW3(op2)) ? 0xffff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPGTW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 66 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPGTD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(op1) = (MMXSD0(op1) > MMXSD0(op2)) ? 0xffffffff : 0;
  MMXUD1(op1) = (MMXSD1(op1) > MMXSD1(op2)) ? 0xffffffff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPGTD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 67 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PACKUSWB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(result) = SaturateWordSToByteU(MMXSW0(op1));
  MMXUB1(result) = SaturateWordSToByteU(MMXSW1(op1));
  MMXUB2(result) = SaturateWordSToByteU(MMXSW2(op1));
  MMXUB3(result) = SaturateWordSToByteU(MMXSW3(op1));
  MMXUB4(result) = SaturateWordSToByteU(MMXSW0(op2));
  MMXUB5(result) = SaturateWordSToByteU(MMXSW1(op2));
  MMXUB6(result) = SaturateWordSToByteU(MMXSW2(op2));
  MMXUB7(result) = SaturateWordSToByteU(MMXSW3(op2));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PACKUSWB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 68 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKHBW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB7(result) = MMXUB7(op2);
  MMXUB6(result) = MMXUB7(op1);
  MMXUB5(result) = MMXUB6(op2);
  MMXUB4(result) = MMXUB6(op1);
  MMXUB3(result) = MMXUB5(op2);
  MMXUB2(result) = MMXUB5(op1);
  MMXUB1(result) = MMXUB4(op2);
  MMXUB0(result) = MMXUB4(op1);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PUNPCKHBW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 69 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKHWD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW3(result) = MMXUW3(op2);
  MMXUW2(result) = MMXUW3(op1);
  MMXUW1(result) = MMXUW2(op2);
  MMXUW0(result) = MMXUW2(op1);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PUNPCKHWD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 6A */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PUNPCKHDQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD1(result) = MMXUD1(op2);
  MMXUD0(result) = MMXUD1(op1);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PUNPCKHDQ_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 6B */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PACKSSDW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSW0(result) = SaturateDwordSToWordS(MMXSD0(op1));
  MMXSW1(result) = SaturateDwordSToWordS(MMXSD1(op1));
  MMXSW2(result) = SaturateDwordSToWordS(MMXSD0(op2));
  MMXSW3(result) = SaturateDwordSToWordS(MMXSD1(op2));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PACKSSDW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 6E */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVD_PqEd(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  MMXUD1(op) = 0;

  /* op is a register or memory reference */
  if (i->modC0()) {
    MMXUD0(op) = BX_READ_32BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUD0(op) = read_virtual_dword(i->seg(), eaddr);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
#else
  BX_INFO(("MOVD_PqEd: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 6E */
#if BX_SUPPORT_X86_64

void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVQ_PqEq(bxInstruction_c *i)
{
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  /* op is a register or memory reference */
  if (i->modC0()) {
    MMXUQ(op) = BX_READ_64BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword_64(i->seg(), eaddr);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
}

#endif

/* 0F 6F */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op;

  /* op is a register or memory reference */
  if (i->modC0()) {
    op = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword(i->seg(), eaddr);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op);
#else
  BX_INFO(("MOVQ_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 70 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSHUFW_PqQqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op, result;
  Bit8u order = i->Ib();

  /* op is a register or memory reference */
  if (i->modC0()) {
    op = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(result) = op.mmx16u((order)    & 0x3);
  MMXUW1(result) = op.mmx16u((order>>2) & 0x3);
  MMXUW2(result) = op.mmx16u((order>>4) & 0x3);
  MMXUW3(result) = op.mmx16u((order>>6) & 0x3);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSHUFW_PqQqIb: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 74 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPEQB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(op1) = (MMXUB0(op1) == MMXUB0(op2)) ? 0xff : 0;
  MMXUB1(op1) = (MMXUB1(op1) == MMXUB1(op2)) ? 0xff : 0;
  MMXUB2(op1) = (MMXUB2(op1) == MMXUB2(op2)) ? 0xff : 0;
  MMXUB3(op1) = (MMXUB3(op1) == MMXUB3(op2)) ? 0xff : 0;
  MMXUB4(op1) = (MMXUB4(op1) == MMXUB4(op2)) ? 0xff : 0;
  MMXUB5(op1) = (MMXUB5(op1) == MMXUB5(op2)) ? 0xff : 0;
  MMXUB6(op1) = (MMXUB6(op1) == MMXUB6(op2)) ? 0xff : 0;
  MMXUB7(op1) = (MMXUB7(op1) == MMXUB7(op2)) ? 0xff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPEQB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 75 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPEQW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(op1) = (MMXUW0(op1) == MMXUW0(op2)) ? 0xffff : 0;
  MMXUW1(op1) = (MMXUW1(op1) == MMXUW1(op2)) ? 0xffff : 0;
  MMXUW2(op1) = (MMXUW2(op1) == MMXUW2(op2)) ? 0xffff : 0;
  MMXUW3(op1) = (MMXUW3(op1) == MMXUW3(op2)) ? 0xffff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPEQW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 76 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PCMPEQD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(op1) = (MMXUD0(op1) == MMXUD0(op2)) ? 0xffffffff : 0;
  MMXUD1(op1) = (MMXUD1(op1) == MMXUD1(op2)) ? 0xffffffff : 0;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PCMPEQD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 77 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::EMMS(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX || BX_SUPPORT_3DNOW
  BX_CPU_THIS_PTR prepareMMX();
  FPU_TAG_WORD  = 0xffff;
#else
  BX_INFO(("EMMS: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 7E */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVD_EdPd(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->nnn());

  /* destination is a register or memory reference */
  if (i->modC0()) {
    BX_WRITE_32BIT_REGZ(i->rm(), MMXUD0(op));
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    write_virtual_dword(i->seg(), eaddr, MMXUD0(op));
  }

#else
  BX_INFO(("MOVD_EdPd: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

#if BX_SUPPORT_X86_64

/* 0F 7E */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVQ_EqPq(bxInstruction_c *i)
{
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->nnn());

  /* destination is a register or memory reference */
  if (i->modC0()) {
    BX_WRITE_64BIT_REG(i->rm(), MMXUQ(op));
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    write_virtual_qword_64(i->seg(), eaddr, MMXUQ(op));
  }
}

#endif

/* 0F 7F */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVQ_QqPq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->nnn());

  /* op is a register or memory reference */
  if (i->modC0()) {
    BX_WRITE_MMX_REG(i->rm(), op);
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    write_virtual_qword(i->seg(), eaddr, MMXUQ(op));
  }
#else
  BX_INFO(("MOVQ_QqPq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F C4 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PINSRW_PqEwIb(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn());
  Bit16u op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op2 = read_virtual_word(i->seg(), eaddr);
  }

  op1.xmm16u(i->Ib() & 0x3) = op2;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PINSRW_PqEdIb: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F C5 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PEXTRW_GdPqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit32u result = (Bit32u) op.mmx16u(i->Ib() & 0x3);

  BX_WRITE_32BIT_REGZ(i->nnn(), result);
#else
  BX_INFO(("PEXTRW_GdPqIb: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D1 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 15) MMXUQ(op1) = 0;
  else
  {
    Bit8u shift = MMXUB0(op2);

    MMXUW0(op1) >>= shift;
    MMXUW1(op1) >>= shift;
    MMXUW2(op1) >>= shift;
    MMXUW3(op1) >>= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSRLW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D2 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 31) MMXUQ(op1) = 0;
  else
  {
    Bit8u shift = MMXUB0(op2);

    MMXUD0(op1) >>= shift;
    MMXUD1(op1) >>= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSRLD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D3 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 63) {
    MMXUQ(op1) = 0;
  }
  else {
    MMXUQ(op1) >>= MMXUB0(op2);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSRLQ_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D4 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_SSE >= 2
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) += MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PADDQ_PqQq: required SSE2, use --enable-sse option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D5 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMULLW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  Bit32u product1 = Bit32u(MMXUW0(op1)) * Bit32u(MMXUW0(op2));
  Bit32u product2 = Bit32u(MMXUW1(op1)) * Bit32u(MMXUW1(op2));
  Bit32u product3 = Bit32u(MMXUW2(op1)) * Bit32u(MMXUW2(op2));
  Bit32u product4 = Bit32u(MMXUW3(op1)) * Bit32u(MMXUW3(op2));

  MMXUW0(result) = product1 & 0xffff;
  MMXUW1(result) = product2 & 0xffff;
  MMXUW2(result) = product3 & 0xffff;
  MMXUW3(result) = product4 & 0xffff;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMULLW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D7 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMOVMSKB_GdPRq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit32u result = 0;

  if(MMXUB0(op) & 0x80) result |= 0x01;
  if(MMXUB1(op) & 0x80) result |= 0x02;
  if(MMXUB2(op) & 0x80) result |= 0x04;
  if(MMXUB3(op) & 0x80) result |= 0x08;
  if(MMXUB4(op) & 0x80) result |= 0x10;
  if(MMXUB5(op) & 0x80) result |= 0x20;
  if(MMXUB6(op) & 0x80) result |= 0x40;
  if(MMXUB7(op) & 0x80) result |= 0x80;

  /* now write result back to destination */
  BX_WRITE_32BIT_REGZ(i->nnn(), result);

#else
  BX_INFO(("PMOVMSKB_GdPRq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D8 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBUSB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(result) = 0;

  if(MMXUB0(op1) > MMXUB0(op2)) MMXUB0(result) = MMXUB0(op1) - MMXUB0(op2);
  if(MMXUB1(op1) > MMXUB1(op2)) MMXUB1(result) = MMXUB1(op1) - MMXUB1(op2);
  if(MMXUB2(op1) > MMXUB2(op2)) MMXUB2(result) = MMXUB2(op1) - MMXUB2(op2);
  if(MMXUB3(op1) > MMXUB3(op2)) MMXUB3(result) = MMXUB3(op1) - MMXUB3(op2);
  if(MMXUB4(op1) > MMXUB4(op2)) MMXUB4(result) = MMXUB4(op1) - MMXUB4(op2);
  if(MMXUB5(op1) > MMXUB5(op2)) MMXUB5(result) = MMXUB5(op1) - MMXUB5(op2);
  if(MMXUB6(op1) > MMXUB6(op2)) MMXUB6(result) = MMXUB6(op1) - MMXUB6(op2);
  if(MMXUB7(op1) > MMXUB7(op2)) MMXUB7(result) = MMXUB7(op1) - MMXUB7(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSUBUSB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F D9 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBUSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(result) = 0;

  if(MMXUW0(op1) > MMXUW0(op2)) MMXUW0(result) = MMXUW0(op1) - MMXUW0(op2);
  if(MMXUW1(op1) > MMXUW1(op2)) MMXUW1(result) = MMXUW1(op1) - MMXUW1(op2);
  if(MMXUW2(op1) > MMXUW2(op2)) MMXUW2(result) = MMXUW2(op1) - MMXUW2(op2);
  if(MMXUW3(op1) > MMXUW3(op2)) MMXUW3(result) = MMXUW3(op1) - MMXUW3(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSUBUSW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DA */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMINUB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUB0(op2) < MMXUB0(op1)) MMXUB0(op1) = MMXUB0(op2);
  if(MMXUB1(op2) < MMXUB1(op1)) MMXUB1(op1) = MMXUB1(op2);
  if(MMXUB2(op2) < MMXUB2(op1)) MMXUB2(op1) = MMXUB2(op2);
  if(MMXUB3(op2) < MMXUB3(op1)) MMXUB3(op1) = MMXUB3(op2);
  if(MMXUB4(op2) < MMXUB4(op1)) MMXUB4(op1) = MMXUB4(op2);
  if(MMXUB5(op2) < MMXUB5(op1)) MMXUB5(op1) = MMXUB5(op2);
  if(MMXUB6(op2) < MMXUB6(op1)) MMXUB6(op1) = MMXUB6(op2);
  if(MMXUB7(op2) < MMXUB7(op1)) MMXUB7(op1) = MMXUB7(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PMINUB_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DB */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PAND_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) &= MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PAND_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DC */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDUSB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(result) = SaturateWordSToByteU(Bit16s(MMXUB0(op1)) + Bit16s(MMXUB0(op2)));
  MMXUB1(result) = SaturateWordSToByteU(Bit16s(MMXUB1(op1)) + Bit16s(MMXUB1(op2)));
  MMXUB2(result) = SaturateWordSToByteU(Bit16s(MMXUB2(op1)) + Bit16s(MMXUB2(op2)));
  MMXUB3(result) = SaturateWordSToByteU(Bit16s(MMXUB3(op1)) + Bit16s(MMXUB3(op2)));
  MMXUB4(result) = SaturateWordSToByteU(Bit16s(MMXUB4(op1)) + Bit16s(MMXUB4(op2)));
  MMXUB5(result) = SaturateWordSToByteU(Bit16s(MMXUB5(op1)) + Bit16s(MMXUB5(op2)));
  MMXUB6(result) = SaturateWordSToByteU(Bit16s(MMXUB6(op1)) + Bit16s(MMXUB6(op2)));
  MMXUB7(result) = SaturateWordSToByteU(Bit16s(MMXUB7(op1)) + Bit16s(MMXUB7(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PADDUSB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DD */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDUSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(result) = SaturateDwordSToWordU(Bit32s(MMXUW0(op1)) + Bit32s(MMXUW0(op2)));
  MMXUW1(result) = SaturateDwordSToWordU(Bit32s(MMXUW1(op1)) + Bit32s(MMXUW1(op2)));
  MMXUW2(result) = SaturateDwordSToWordU(Bit32s(MMXUW2(op1)) + Bit32s(MMXUW2(op2)));
  MMXUW3(result) = SaturateDwordSToWordU(Bit32s(MMXUW3(op1)) + Bit32s(MMXUW3(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PADDUSW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DE */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMAXUB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUB0(op2) > MMXUB0(op1)) MMXUB0(op1) = MMXUB0(op2);
  if(MMXUB1(op2) > MMXUB1(op1)) MMXUB1(op1) = MMXUB1(op2);
  if(MMXUB2(op2) > MMXUB2(op1)) MMXUB2(op1) = MMXUB2(op2);
  if(MMXUB3(op2) > MMXUB3(op1)) MMXUB3(op1) = MMXUB3(op2);
  if(MMXUB4(op2) > MMXUB4(op1)) MMXUB4(op1) = MMXUB4(op2);
  if(MMXUB5(op2) > MMXUB5(op1)) MMXUB5(op1) = MMXUB5(op2);
  if(MMXUB6(op2) > MMXUB6(op1)) MMXUB6(op1) = MMXUB6(op2);
  if(MMXUB7(op2) > MMXUB7(op1)) MMXUB7(op1) = MMXUB7(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PMAXUB_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F DF */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PANDN_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) = ~(MMXUQ(op1)) & MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PANDN_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E0 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PAVGB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(op1) = (MMXUB0(op1) + MMXUB0(op2) + 1) >> 1;
  MMXUB1(op1) = (MMXUB1(op1) + MMXUB1(op2) + 1) >> 1;
  MMXUB2(op1) = (MMXUB2(op1) + MMXUB2(op2) + 1) >> 1;
  MMXUB3(op1) = (MMXUB3(op1) + MMXUB3(op2) + 1) >> 1;
  MMXUB4(op1) = (MMXUB4(op1) + MMXUB4(op2) + 1) >> 1;
  MMXUB5(op1) = (MMXUB5(op1) + MMXUB5(op2) + 1) >> 1;
  MMXUB6(op1) = (MMXUB6(op1) + MMXUB6(op2) + 1) >> 1;
  MMXUB7(op1) = (MMXUB7(op1) + MMXUB7(op2) + 1) >> 1;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PAVGB_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E1 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRAW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(!MMXUQ(op2)) return;

  if(MMXUQ(op2) > 15) {
    MMXUW0(result) = (MMXUW0(op1) & 0x8000) ? 0xffff : 0;
    MMXUW1(result) = (MMXUW1(op1) & 0x8000) ? 0xffff : 0;
    MMXUW2(result) = (MMXUW2(op1) & 0x8000) ? 0xffff : 0;
    MMXUW3(result) = (MMXUW3(op1) & 0x8000) ? 0xffff : 0;
  }
  else {
    Bit8u shift = MMXUB0(op2);

    MMXUW0(result) = MMXUW0(op1) >> shift;
    MMXUW1(result) = MMXUW1(op1) >> shift;
    MMXUW2(result) = MMXUW2(op1) >> shift;
    MMXUW3(result) = MMXUW3(op1) >> shift;

    if(MMXUW0(op1) & 0x8000) MMXUW0(result) |= (0xffff << (16 - shift));
    if(MMXUW1(op1) & 0x8000) MMXUW1(result) |= (0xffff << (16 - shift));
    if(MMXUW2(op1) & 0x8000) MMXUW2(result) |= (0xffff << (16 - shift));
    if(MMXUW3(op1) & 0x8000) MMXUW3(result) |= (0xffff << (16 - shift));
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSRAW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E2 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRAD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(!MMXUQ(op2)) return;

  if(MMXUQ(op2) > 31) {
    MMXUD0(result) = (MMXUD0(op1) & 0x80000000) ? 0xffffffff : 0;
    MMXUD1(result) = (MMXUD1(op1) & 0x80000000) ? 0xffffffff : 0;
  }
  else {
    Bit8u shift = MMXUB0(op2);

    MMXUD0(result) = MMXUD0(op1) >> shift;
    MMXUD1(result) = MMXUD1(op1) >> shift;

    if(MMXUD0(op1) & 0x80000000)
       MMXUD0(result) |= (0xffffffff << (32 - shift));

    if(MMXUD1(op1) & 0x80000000)
       MMXUD1(result) |= (0xffffffff << (32 - shift));
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSRAD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E3 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PAVGW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(op1) = (MMXUW0(op1) + MMXUW0(op2) + 1) >> 1;
  MMXUW1(op1) = (MMXUW1(op1) + MMXUW1(op2) + 1) >> 1;
  MMXUW2(op1) = (MMXUW2(op1) + MMXUW2(op2) + 1) >> 1;
  MMXUW3(op1) = (MMXUW3(op1) + MMXUW3(op2) + 1) >> 1;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PAVGW_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E4 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMULHUW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  Bit32u product1 = Bit32u(MMXUW0(op1)) * Bit32u(MMXUW0(op2));
  Bit32u product2 = Bit32u(MMXUW1(op1)) * Bit32u(MMXUW1(op2));
  Bit32u product3 = Bit32u(MMXUW2(op1)) * Bit32u(MMXUW2(op2));
  Bit32u product4 = Bit32u(MMXUW3(op1)) * Bit32u(MMXUW3(op2));

  MMXUW0(result) = (Bit16u)(product1 >> 16);
  MMXUW1(result) = (Bit16u)(product2 >> 16);
  MMXUW2(result) = (Bit16u)(product3 >> 16);
  MMXUW3(result) = (Bit16u)(product4 >> 16);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMULHUW_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E5 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMULHW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  Bit32s product1 = Bit32s(MMXSW0(op1)) * Bit32s(MMXSW0(op2));
  Bit32s product2 = Bit32s(MMXSW1(op1)) * Bit32s(MMXSW1(op2));
  Bit32s product3 = Bit32s(MMXSW2(op1)) * Bit32s(MMXSW2(op2));
  Bit32s product4 = Bit32s(MMXSW3(op1)) * Bit32s(MMXSW3(op2));

  MMXUW0(result) = Bit16u(product1 >> 16);
  MMXUW1(result) = Bit16u(product2 >> 16);
  MMXUW2(result) = Bit16u(product3 >> 16);
  MMXUW3(result) = Bit16u(product4 >> 16);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMULHW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E7 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVNTQ_MqPq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();
  BxPackedMmxRegister reg = BX_READ_MMX_REG(i->nnn());
  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
  write_virtual_qword(i->seg(), eaddr, MMXUQ(reg));
#else
  BX_INFO(("MOVNTQ_MqPq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E8 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBSB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSB0(result) = SaturateWordSToByteS(Bit16s(MMXSB0(op1)) - Bit16s(MMXSB0(op2)));
  MMXSB1(result) = SaturateWordSToByteS(Bit16s(MMXSB1(op1)) - Bit16s(MMXSB1(op2)));
  MMXSB2(result) = SaturateWordSToByteS(Bit16s(MMXSB2(op1)) - Bit16s(MMXSB2(op2)));
  MMXSB3(result) = SaturateWordSToByteS(Bit16s(MMXSB3(op1)) - Bit16s(MMXSB3(op2)));
  MMXSB4(result) = SaturateWordSToByteS(Bit16s(MMXSB4(op1)) - Bit16s(MMXSB4(op2)));
  MMXSB5(result) = SaturateWordSToByteS(Bit16s(MMXSB5(op1)) - Bit16s(MMXSB5(op2)));
  MMXSB6(result) = SaturateWordSToByteS(Bit16s(MMXSB6(op1)) - Bit16s(MMXSB6(op2)));
  MMXSB7(result) = SaturateWordSToByteS(Bit16s(MMXSB7(op1)) - Bit16s(MMXSB7(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSUBSB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F E9 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSW0(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op1)) - Bit32s(MMXSW0(op2)));
  MMXSW1(result) = SaturateDwordSToWordS(Bit32s(MMXSW1(op1)) - Bit32s(MMXSW1(op2)));
  MMXSW2(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op1)) - Bit32s(MMXSW2(op2)));
  MMXSW3(result) = SaturateDwordSToWordS(Bit32s(MMXSW3(op1)) - Bit32s(MMXSW3(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PSUBSW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F EA */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMINSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXSW0(op2) < MMXSW0(op1)) MMXSW0(op1) = MMXSW0(op2);
  if(MMXSW1(op2) < MMXSW1(op1)) MMXSW1(op1) = MMXSW1(op2);
  if(MMXSW2(op2) < MMXSW2(op1)) MMXSW2(op1) = MMXSW2(op2);
  if(MMXSW3(op2) < MMXSW3(op1)) MMXSW3(op1) = MMXSW3(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PMINSW_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F EB */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::POR_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) |= MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("POR_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F EC */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDSB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSB0(result) = SaturateWordSToByteS(Bit16s(MMXSB0(op1)) + Bit16s(MMXSB0(op2)));
  MMXSB1(result) = SaturateWordSToByteS(Bit16s(MMXSB1(op1)) + Bit16s(MMXSB1(op2)));
  MMXSB2(result) = SaturateWordSToByteS(Bit16s(MMXSB2(op1)) + Bit16s(MMXSB2(op2)));
  MMXSB3(result) = SaturateWordSToByteS(Bit16s(MMXSB3(op1)) + Bit16s(MMXSB3(op2)));
  MMXSB4(result) = SaturateWordSToByteS(Bit16s(MMXSB4(op1)) + Bit16s(MMXSB4(op2)));
  MMXSB5(result) = SaturateWordSToByteS(Bit16s(MMXSB5(op1)) + Bit16s(MMXSB5(op2)));
  MMXSB6(result) = SaturateWordSToByteS(Bit16s(MMXSB6(op1)) + Bit16s(MMXSB6(op2)));
  MMXSB7(result) = SaturateWordSToByteS(Bit16s(MMXSB7(op1)) + Bit16s(MMXSB7(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PADDSB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F ED */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXSW0(result) = SaturateDwordSToWordS(Bit32s(MMXSW0(op1)) + Bit32s(MMXSW0(op2)));
  MMXSW1(result) = SaturateDwordSToWordS(Bit32s(MMXSW1(op1)) + Bit32s(MMXSW1(op2)));
  MMXSW2(result) = SaturateDwordSToWordS(Bit32s(MMXSW2(op1)) + Bit32s(MMXSW2(op2)));
  MMXSW3(result) = SaturateDwordSToWordS(Bit32s(MMXSW3(op1)) + Bit32s(MMXSW3(op2)));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PADDSW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F EE */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMAXSW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXSW0(op2) > MMXSW0(op1)) MMXSW0(op1) = MMXSW0(op2);
  if(MMXSW1(op2) > MMXSW1(op1)) MMXSW1(op1) = MMXSW1(op2);
  if(MMXSW2(op2) > MMXSW2(op1)) MMXSW2(op1) = MMXSW2(op2);
  if(MMXSW3(op2) > MMXSW3(op1)) MMXSW3(op1) = MMXSW3(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PMAXSW_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F EF */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PXOR_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) ^= MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PXOR_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F1 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 15) MMXUQ(op1) = 0;
  else
  {
    Bit8u shift = MMXUB0(op2);

    MMXUW0(op1) <<= shift;
    MMXUW1(op1) <<= shift;
    MMXUW2(op1) <<= shift;
    MMXUW3(op1) <<= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSLLW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F2 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 31) MMXUQ(op1) = 0;
  else
  {
    Bit8u shift = MMXUB0(op2);

    MMXUD0(op1) <<= shift;
    MMXUD1(op1) <<= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSLLD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F3 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUQ(op2) > 63) {
    MMXUQ(op1) = 0;
  }
  else {
    MMXUQ(op1) <<= MMXUB0(op2);
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSLLQ_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F4 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMULUDQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_SSE >= 2
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(result) = Bit64u(MMXUD0(op1)) * Bit64u(MMXUD0(op2));

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMULUDQ_PqQq: required SSE2, use --enable-sse option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F5 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PMADDWD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2, result;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  if(MMXUD0(op1) == 0x80008000 && MMXUD0(op2) == 0x80008000) {
    MMXUD0(result) = 0x80000000;
  }
  else {
    MMXUD0(result) = Bit32s(MMXSW0(op1))*Bit32s(MMXSW0(op2)) + Bit32s(MMXSW1(op1))*Bit32s(MMXSW1(op2));
  }

  if(MMXUD1(op1) == 0x80008000 && MMXUD1(op2) == 0x80008000) {
    MMXUD1(result) = 0x80000000;
  }
  else {
    MMXUD1(result) = Bit32s(MMXSW2(op1))*Bit32s(MMXSW2(op2)) + Bit32s(MMXSW3(op1))*Bit32s(MMXSW3(op2));
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), result);
#else
  BX_INFO(("PMADDWD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F6 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSADBW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;
  Bit16u temp = 0;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  temp += abs(MMXUB0(op1) - MMXUB0(op2));
  temp += abs(MMXUB1(op1) - MMXUB1(op2));
  temp += abs(MMXUB2(op1) - MMXUB2(op2));
  temp += abs(MMXUB3(op1) - MMXUB3(op2));
  temp += abs(MMXUB4(op1) - MMXUB4(op2));
  temp += abs(MMXUB5(op1) - MMXUB5(op2));
  temp += abs(MMXUB6(op1) - MMXUB6(op2));
  temp += abs(MMXUB7(op1) - MMXUB7(op2));

  MMXUQ(op1) = (Bit64u) temp;

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSADBW_PqQq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F7 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MASKMOVQ_PqPRq(bxInstruction_c *i)
{
#if BX_SUPPORT_3DNOW || BX_SUPPORT_SSE >= 1
  BX_CPU_THIS_PTR prepareMMX();

  bx_address rdi;
  BxPackedMmxRegister op = BX_READ_MMX_REG(i->nnn()), tmp,
    mask = BX_READ_MMX_REG(i->rm());

#if BX_SUPPORT_X86_64
  if (i->as64L()) { 	/* 64 bit address mode */
      rdi = RDI;
  }
  else
#endif
  if (i->as32L()) {
      rdi = EDI;
  }
  else {   		/* 16 bit address mode */
      rdi = DI;
  }

  if (MMXUQ(mask) == 0) return;

  /* do read-modify-write for efficiency */
  MMXUQ(tmp) = read_RMW_virtual_qword(i->seg(), rdi);

  if(MMXUB0(mask) & 0x80) MMXUB0(tmp) = MMXUB0(op);
  if(MMXUB1(mask) & 0x80) MMXUB1(tmp) = MMXUB1(op);
  if(MMXUB2(mask) & 0x80) MMXUB2(tmp) = MMXUB2(op);
  if(MMXUB3(mask) & 0x80) MMXUB3(tmp) = MMXUB3(op);
  if(MMXUB4(mask) & 0x80) MMXUB4(tmp) = MMXUB4(op);
  if(MMXUB5(mask) & 0x80) MMXUB5(tmp) = MMXUB5(op);
  if(MMXUB6(mask) & 0x80) MMXUB6(tmp) = MMXUB6(op);
  if(MMXUB7(mask) & 0x80) MMXUB7(tmp) = MMXUB7(op);

  write_RMW_virtual_qword(MMXUQ(tmp));
#else
  BX_INFO(("MASKMOVQ_PqPRq: required SSE or 3DNOW, use --enable-sse or --enable-3dnow options"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F8 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(op1) -= MMXUB0(op2);
  MMXUB1(op1) -= MMXUB1(op2);
  MMXUB2(op1) -= MMXUB2(op2);
  MMXUB3(op1) -= MMXUB3(op2);
  MMXUB4(op1) -= MMXUB4(op2);
  MMXUB5(op1) -= MMXUB5(op2);
  MMXUB6(op1) -= MMXUB6(op2);
  MMXUB7(op1) -= MMXUB7(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSUBB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F F9 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(op1) -= MMXUW0(op2);
  MMXUW1(op1) -= MMXUW1(op2);
  MMXUW2(op1) -= MMXUW2(op2);
  MMXUW3(op1) -= MMXUW3(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSUBW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F FA */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(op1) -= MMXUD0(op2);
  MMXUD1(op1) -= MMXUD1(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSUBD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F FB */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSUBQ_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_SSE >= 2
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUQ(op1) -= MMXUQ(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PSUBQ_PqQq: required SSE2, use --enable-sse option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F FC */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDB_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUB0(op1) += MMXUB0(op2);
  MMXUB1(op1) += MMXUB1(op2);
  MMXUB2(op1) += MMXUB2(op2);
  MMXUB3(op1) += MMXUB3(op2);
  MMXUB4(op1) += MMXUB4(op2);
  MMXUB5(op1) += MMXUB5(op2);
  MMXUB6(op1) += MMXUB6(op2);
  MMXUB7(op1) += MMXUB7(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PADDB_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F FD */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDW_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUW0(op1) += MMXUW0(op2);
  MMXUW1(op1) += MMXUW1(op2);
  MMXUW2(op1) += MMXUW2(op2);
  MMXUW3(op1) += MMXUW3(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PADDW_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F FE */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PADDD_PqQq(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op1 = BX_READ_MMX_REG(i->nnn()), op2;

  /* op2 is a register or memory reference */
  if (i->modC0()) {
    op2 = BX_READ_MMX_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    MMXUQ(op2) = read_virtual_qword(i->seg(), eaddr);
  }

  MMXUD0(op1) += MMXUD0(op2);
  MMXUD1(op1) += MMXUD1(op2);

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->nnn(), op1);
#else
  BX_INFO(("PADDD_PqQq: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 71 GrpA 010 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLW_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 15) MMXUQ(op) = 0;
  else
  {
    MMXUW0(op) >>= shift;
    MMXUW1(op) >>= shift;
    MMXUW2(op) >>= shift;
    MMXUW3(op) >>= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSRLW_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 71 GrpA 100 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRAW_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm()), result;
  Bit8u shift = i->Ib();

  if(shift == 0) return;

  if(shift > 15) {
    MMXUW0(result) = (MMXUW0(op) & 0x8000) ? 0xffff : 0;
    MMXUW1(result) = (MMXUW1(op) & 0x8000) ? 0xffff : 0;
    MMXUW2(result) = (MMXUW2(op) & 0x8000) ? 0xffff : 0;
    MMXUW3(result) = (MMXUW3(op) & 0x8000) ? 0xffff : 0;
  }
  else {
    MMXUW0(result) = MMXUW0(op) >> shift;
    MMXUW1(result) = MMXUW1(op) >> shift;
    MMXUW2(result) = MMXUW2(op) >> shift;
    MMXUW3(result) = MMXUW3(op) >> shift;

    if(MMXUW0(op) & 0x8000) MMXUW0(result) |= (0xffff << (16 - shift));
    if(MMXUW1(op) & 0x8000) MMXUW1(result) |= (0xffff << (16 - shift));
    if(MMXUW2(op) & 0x8000) MMXUW2(result) |= (0xffff << (16 - shift));
    if(MMXUW3(op) & 0x8000) MMXUW3(result) |= (0xffff << (16 - shift));
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), result);
#else
  BX_INFO(("PSRAW_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 71 GrpA 110 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLW_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 15) MMXUQ(op) = 0;
  else
  {
    MMXUW0(op) <<= shift;
    MMXUW1(op) <<= shift;
    MMXUW2(op) <<= shift;
    MMXUW3(op) <<= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSLLW_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 72 GrpA 010 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLD_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 31) MMXUQ(op) = 0;
  else
  {
    MMXUD0(op) >>= shift;
    MMXUD1(op) >>= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSRLD_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 72 GrpA 100 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRAD_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm()), result;
  Bit8u shift = i->Ib();

  if(shift == 0) return;

  if(shift > 31) {
    MMXUD0(result) = (MMXUD0(op) & 0x80000000) ? 0xffffffff : 0;
    MMXUD1(result) = (MMXUD1(op) & 0x80000000) ? 0xffffffff : 0;
  }
  else {
    MMXUD0(result) = MMXUD0(op) >> shift;
    MMXUD1(result) = MMXUD1(op) >> shift;

    if(MMXUD0(op) & 0x80000000)
       MMXUD0(result) |= (0xffffffff << (32 - shift));

    if(MMXUD1(op) & 0x80000000)
       MMXUD1(result) |= (0xffffffff << (32 - shift));
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), result);
#else
  BX_INFO(("PSRAD_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 72 GrpA 110 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLD_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 31) MMXUQ(op) = 0;
  else
  {
    MMXUD0(op) <<= shift;
    MMXUD1(op) <<= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSLLD_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 73 GrpA 010 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSRLQ_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 63) {
    MMXUQ(op) = 0;
  }
  else {
    MMXUQ(op) >>= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSRLQ_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

/* 0F 73 GrpA 110 */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::PSLLQ_PqIb(bxInstruction_c *i)
{
#if BX_SUPPORT_MMX
  BX_CPU_THIS_PTR prepareMMX();

  BxPackedMmxRegister op = BX_READ_MMX_REG(i->rm());
  Bit8u shift = i->Ib();

  if(shift > 63) {
    MMXUQ(op) = 0;
  }
  else {
    MMXUQ(op) <<= shift;
  }

  /* now write result back to destination */
  BX_WRITE_MMX_REG(i->rm(), op);
#else
  BX_INFO(("PSLLQ_PqIb: required MMX, use --enable-mmx option"));
  exception(BX_UD_EXCEPTION, 0, 0);
#endif
}
