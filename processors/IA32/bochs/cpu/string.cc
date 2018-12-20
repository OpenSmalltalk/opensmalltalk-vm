/////////////////////////////////////////////////////////////////////////
// $Id: string.cc,v 1.63 2008/08/03 19:53:09 sshwarts Exp $
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

#if BX_SUPPORT_X86_64==0
#define RSI ESI
#define RDI EDI
#define RAX EAX
#define RCX ECX
#endif

//
// Repeat Speedups methods
//

#if BX_SupportRepeatSpeedups
Bit32u BX_CPU_C::FastRepMOVSB(bxInstruction_c *i, unsigned srcSeg, bx_address srcOff, unsigned dstSeg, bx_address dstOff, Bit32u count)
{
  Bit32u bytesFitSrc, bytesFitDst;
  signed int pointerDelta;
  bx_address laddrDst, laddrSrc;
  Bit8u *hostAddrSrc, *hostAddrDst;

  bx_segment_reg_t *srcSegPtr = &BX_CPU_THIS_PTR sregs[srcSeg];
  if (!(srcSegPtr->cache.valid & SegAccessROK4G))
    return 0;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if (!(dstSegPtr->cache.valid & SegAccessWOK4G))
    return 0;

  laddrSrc = BX_CPU_THIS_PTR get_laddr(srcSeg, srcOff);

#if BX_SupportGuest2HostTLB
  hostAddrSrc = v2h_read_byte(laddrSrc, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrSrc;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrSrc = dtranslate_linear(laddrSrc, CPL, BX_READ);
  }
  else {
    paddrSrc = laddrSrc;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrSrc = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrSrc), BX_READ, DATA_ACCESS);
#endif
  if (! hostAddrSrc) return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many bytes can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    bytesFitSrc = 1 + PAGE_OFFSET(laddrSrc);
    bytesFitDst = 1 + PAGE_OFFSET(laddrDst);
    pointerDelta = (signed int) -1;
  }
  else {
    // Counting upward.
    bytesFitSrc = 0x1000 - PAGE_OFFSET(laddrSrc);
    bytesFitDst = 0x1000 - PAGE_OFFSET(laddrDst);
    pointerDelta = (signed int)  1;
  }

  // Restrict word count to the number that will fit in either
  // source or dest pages.
  if (count > bytesFitSrc)
    count = bytesFitSrc;
  if (count > bytesFitDst)
    count = bytesFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      * (Bit8u *) hostAddrDst = * (Bit8u *) hostAddrSrc;
      hostAddrDst += pointerDelta;
      hostAddrSrc += pointerDelta;
    }

    return count;
  }

  return 0;
}

Bit32u BX_CPU_C::FastRepMOVSW(bxInstruction_c *i, unsigned srcSeg, bx_address srcOff, unsigned dstSeg, bx_address dstOff, Bit32u count)
{
  Bit32u wordsFitSrc, wordsFitDst;
  signed int pointerDelta;
  bx_address laddrDst, laddrSrc;
  Bit8u *hostAddrSrc, *hostAddrDst;

  bx_segment_reg_t *srcSegPtr = &BX_CPU_THIS_PTR sregs[srcSeg];
  if (!(srcSegPtr->cache.valid & SegAccessROK4G))
    return 0;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if (!(dstSegPtr->cache.valid & SegAccessWOK4G))
    return 0;

  laddrSrc = BX_CPU_THIS_PTR get_laddr(srcSeg, srcOff);

#if BX_SupportGuest2HostTLB
  hostAddrSrc = v2h_read_byte(laddrSrc, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrSrc;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrSrc = dtranslate_linear(laddrSrc, CPL, BX_READ);
  }
  else {
    paddrSrc = laddrSrc;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrSrc = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrSrc), BX_READ, DATA_ACCESS);
#endif
  if (! hostAddrSrc) return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many words can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    // Note: 1st word must not cross page boundary.
    if (((laddrSrc & 0xfff) > 0xffe) || ((laddrDst & 0xfff) > 0xffe))
       return 0;
    wordsFitSrc = (2 + PAGE_OFFSET(laddrSrc)) >> 1;
    wordsFitDst = (2 + PAGE_OFFSET(laddrDst)) >> 1;
    pointerDelta = (signed int) -2;
  }
  else {
    // Counting upward.
    wordsFitSrc = (0x1000 - PAGE_OFFSET(laddrSrc)) >> 1;
    wordsFitDst = (0x1000 - PAGE_OFFSET(laddrDst)) >> 1;
    pointerDelta = (signed int)  2;
  }

  // Restrict word count to the number that will fit in either
  // source or dest pages.
  if (count > wordsFitSrc)
    count = wordsFitSrc;
  if (count > wordsFitDst)
    count = wordsFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      CopyHostWordLittleEndian(hostAddrDst, hostAddrSrc);
      hostAddrDst += pointerDelta;
      hostAddrSrc += pointerDelta;
    }

    return count;
  }

  return 0;
}

Bit32u BX_CPU_C::FastRepMOVSD(bxInstruction_c *i, unsigned srcSeg, bx_address srcOff, unsigned dstSeg, bx_address dstOff, Bit32u count)
{
  Bit32u dwordsFitSrc, dwordsFitDst;
  signed int pointerDelta;
  bx_address laddrDst, laddrSrc;
  Bit8u *hostAddrSrc, *hostAddrDst;

  bx_segment_reg_t *srcSegPtr = &BX_CPU_THIS_PTR sregs[srcSeg];
  if (!(srcSegPtr->cache.valid & SegAccessROK4G))
    return 0;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if (!(dstSegPtr->cache.valid & SegAccessWOK4G))
    return 0;

  laddrSrc = BX_CPU_THIS_PTR get_laddr(srcSeg, srcOff);

#if BX_SupportGuest2HostTLB
  hostAddrSrc = v2h_read_byte(laddrSrc, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrSrc;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrSrc = dtranslate_linear(laddrSrc, CPL, BX_READ);
  }
  else {
    paddrSrc = laddrSrc;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrSrc = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrSrc), BX_READ, DATA_ACCESS);
#endif
  if (! hostAddrSrc) return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many dwords can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    // Note: 1st dword must not cross page boundary.
    if (((laddrSrc & 0xfff) > 0xffc) || ((laddrDst & 0xfff) > 0xffc))
      return 0;
    dwordsFitSrc = (4 + PAGE_OFFSET(laddrSrc)) >> 2;
    dwordsFitDst = (4 + PAGE_OFFSET(laddrDst)) >> 2;
    pointerDelta = (signed int) -4;
  }
  else {
    // Counting upward.
    dwordsFitSrc = (0x1000 - PAGE_OFFSET(laddrSrc)) >> 2;
    dwordsFitDst = (0x1000 - PAGE_OFFSET(laddrDst)) >> 2;
    pointerDelta = (signed int)  4;
  }

  // Restrict dword count to the number that will fit in either
  // source or dest pages.
  if (count > dwordsFitSrc)
    count = dwordsFitSrc;
  if (count > dwordsFitDst)
    count = dwordsFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      CopyHostDWordLittleEndian(hostAddrDst, hostAddrSrc);
      hostAddrDst += pointerDelta;
      hostAddrSrc += pointerDelta;
    }

    return count;
  }

  return 0;
}

Bit32u BX_CPU_C::FastRepSTOSB(bxInstruction_c *i, unsigned dstSeg, bx_address dstOff, Bit8u val, Bit32u count)
{
  Bit32u bytesFitDst;
  signed int pointerDelta;
  bx_address laddrDst;
  Bit8u *hostAddrDst;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if ((dstSegPtr->cache.valid & SegAccessWOK4G) != SegAccessWOK4G)
    return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many bytes can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    bytesFitDst = 1 + PAGE_OFFSET(laddrDst);
    pointerDelta = (signed int) -1;
  }
  else {
    // Counting upward.
    bytesFitDst = 0x1000 - PAGE_OFFSET(laddrDst);
    pointerDelta = (signed int)  1;
  }

  // Restrict word count to the number that will fit in either
  // source or dest pages.
  if (count > bytesFitDst)
    count = bytesFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      * (Bit8u *) hostAddrDst = val;
      hostAddrDst += pointerDelta;
    }

    return count;
  }

  return 0;
}

Bit32u BX_CPU_C::FastRepSTOSW(bxInstruction_c *i, unsigned dstSeg, bx_address dstOff, Bit16u val, Bit32u count)
{
  Bit32u wordsFitDst;
  signed int pointerDelta;
  bx_address laddrDst;
  Bit8u *hostAddrDst;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if ((dstSegPtr->cache.valid & SegAccessWOK4G) != SegAccessWOK4G)
    return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many words can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    // Note: 1st word must not cross page boundary.
    if ((laddrDst & 0xfff) > 0xffe) return 0;
    wordsFitDst = (2 + PAGE_OFFSET(laddrDst)) >> 1;
    pointerDelta = (signed int) -2;
  }
  else {
    // Counting upward.
    wordsFitDst = (0x1000 - PAGE_OFFSET(laddrDst)) >> 1;
    pointerDelta = (signed int)  2;
  }

  // Restrict word count to the number that will fit in either
  // source or dest pages.
  if (count > wordsFitDst)
    count = wordsFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      WriteHostWordToLittleEndian(hostAddrDst, val);
      hostAddrDst += pointerDelta;
    }

    return count;
  }

  return 0;
}

Bit32u BX_CPU_C::FastRepSTOSD(bxInstruction_c *i, unsigned dstSeg, bx_address dstOff, Bit32u val, Bit32u count)
{
  Bit32u dwordsFitDst;
  signed int pointerDelta;
  bx_address laddrDst;
  Bit8u *hostAddrDst;

  bx_segment_reg_t *dstSegPtr = &BX_CPU_THIS_PTR sregs[dstSeg];
  if (!(dstSegPtr->cache.valid & SegAccessWOK4G))
    return 0;

  laddrDst = BX_CPU_THIS_PTR get_laddr(dstSeg, dstOff);

#if BX_SupportGuest2HostTLB
  hostAddrDst = v2h_write_byte(laddrDst, BX_CPU_THIS_PTR user_pl);
#else
  bx_phy_address paddrDst;

  if (BX_CPU_THIS_PTR cr0.get_PG()) {
    paddrDst = dtranslate_linear(laddrDst, CPL, BX_WRITE);
  }
  else {
    paddrDst = laddrDst;
  }

  // If we want to write directly into the physical memory array,
  // we need the A20 address.
  hostAddrDst = BX_MEM(0)->getHostMemAddr(BX_CPU_THIS,
            A20ADDR(paddrDst), BX_WRITE, DATA_ACCESS);
#endif
  if (! hostAddrDst) return 0;

  // See how many dwords can fit in the rest of this page.
  if (BX_CPU_THIS_PTR get_DF()) {
    // Counting downward.
    // Note: 1st dword must not cross page boundary.
    if ((laddrDst & 0xfff) > 0xffc) return 0;
    dwordsFitDst = (4 + PAGE_OFFSET(laddrDst)) >> 2;
    pointerDelta = (signed int) -4;
  }
  else {
    // Counting upward.
    dwordsFitDst = (0x1000 - PAGE_OFFSET(laddrDst)) >> 2;
    pointerDelta = (signed int)  4;
  }

  // Restrict dword count to the number that will fit in either
  // source or dest pages.
  if (count > dwordsFitDst)
    count = dwordsFitDst;
  if (count > bx_pc_system.getNumCpuTicksLeftNextEvent())
    count = bx_pc_system.getNumCpuTicksLeftNextEvent();

  // If after all the restrictions, there is anything left to do...
  if (count) {
    // Transfer data directly using host addresses
    for (unsigned j=0; j<count; j++) {
      WriteHostDWordToLittleEndian(hostAddrDst, val);
      hostAddrDst += pointerDelta;
    }

    return count;
  }

  return 0;
}
#endif

//
// REP MOVS methods
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_MOVSB_XbYb(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSB64_XbYb);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSB32_XbYb);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSB16_XbYb);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_MOVSW_XwYw(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSW64_XwYw);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSW32_XwYw);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSW16_XwYw);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_MOVSD_XdYd(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSD64_XdYd);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSD32_XdYd);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSD16_XdYd);
  }
}

#if BX_SUPPORT_X86_64
void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_MOVSQ_XqYq(bxInstruction_c *i)
{
  if (i->as64L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSQ64_XqYq);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::MOVSQ32_XqYq);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
}
#endif

//
// MOVSB/MOVSW/MOVSD/MOVSQ methods
//

// 16 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSB16_XbYb(bxInstruction_c *i)
{
  Bit8u temp8 = read_virtual_byte_32(i->seg(), SI);
  write_virtual_byte_32(BX_SEG_REG_ES, DI, temp8);

  if (BX_CPU_THIS_PTR get_DF()) {
    /* decrement SI, DI */
    SI--;
    DI--;
  }
  else {
    /* increment SI, DI */
    SI++;
    DI++;
  }
}

// 32 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSB32_XbYb(bxInstruction_c *i)
{
  Bit8u temp8;

  Bit32u incr = 1;

#if (BX_SupportRepeatSpeedups) && (BX_DEBUGGER == 0)
  /* If conditions are right, we can transfer IO to physical memory
   * in a batch, rather than one instruction at a time */
  if (i->repUsedL() && !BX_CPU_THIS_PTR async_event)
  {
    Bit32u byteCount = FastRepMOVSB(i, i->seg(), ESI, BX_SEG_REG_ES, EDI, ECX);
    if (byteCount) {
      // Decrement the ticks count by the number of iterations, minus
      // one, since the main cpu loop will decrement one.  Also,
      // the count is predecremented before examined, so defintely
      // don't roll it under zero.
      BX_TICKN(byteCount-1);

      // Decrement eCX. Note, the main loop will decrement 1 also, so
      // decrement by one less than expected, like the case above.
      RCX = ECX - (byteCount-1);

      incr = byteCount;
    }
    else {
      temp8 = read_virtual_byte(i->seg(), ESI);
      write_virtual_byte(BX_SEG_REG_ES, EDI, temp8);
    }
  }
  else
#endif
  {
    temp8 = read_virtual_byte(i->seg(), ESI);
    write_virtual_byte(BX_SEG_REG_ES, EDI, temp8);
  }

  if (BX_CPU_THIS_PTR get_DF()) {
    RSI = ESI - incr;
    RDI = EDI - incr;
  }
  else {
    RSI = ESI + incr;
    RDI = EDI + incr;
  }
}

#if BX_SUPPORT_X86_64
// 64 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSB64_XbYb(bxInstruction_c *i)
{
  Bit8u temp8;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  temp8 = read_virtual_byte_64(i->seg(), rsi);
  write_virtual_byte_64(BX_SEG_REG_ES, rdi, temp8);

  if (BX_CPU_THIS_PTR get_DF()) {
    /* decrement RSI, RDI */
    rsi--;
    rdi--;
  }
  else {
    /* increment RSI, RDI */
    rsi++;
    rdi++;
  }

  RSI = rsi;
  RDI = rdi;
}
#endif

/* 16 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSW16_XwYw(bxInstruction_c *i)
{
  Bit16u si = SI;
  Bit16u di = DI;

  Bit16u temp16 = read_virtual_word_32(i->seg(), si);
  write_virtual_word_32(BX_SEG_REG_ES, di, temp16);

  if (BX_CPU_THIS_PTR get_DF()) {
    /* decrement SI, DI */
    si -= 2;
    di -= 2;
  }
  else {
    /* increment SI, DI */
    si += 2;
    di += 2;
  }

  SI = si;
  DI = di;
}

/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSW32_XwYw(bxInstruction_c *i)
{
  Bit16u temp16;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  temp16 = read_virtual_word(i->seg(), esi);
  write_virtual_word(BX_SEG_REG_ES, edi, temp16);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 2;
    edi -= 2;
  }
  else {
    esi += 2;
    edi += 2;
  }

  // zero extension of RSI/RDI
  RSI = esi;
  RDI = edi;
}

#if BX_SUPPORT_X86_64
/* 16 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSW64_XwYw(bxInstruction_c *i)
{
  Bit16u temp16;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  temp16 = read_virtual_word_64(i->seg(), rsi);
  write_virtual_word_64(BX_SEG_REG_ES, rdi, temp16);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 2;
    rdi -= 2;
  }
  else {
    rsi += 2;
    rdi += 2;
  }

  RSI = rsi;
  RDI = rdi;
}
#endif

/* 32 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSD16_XdYd(bxInstruction_c *i)
{
  Bit32u temp32;

  Bit16u si = SI;
  Bit16u di = DI;

  temp32 = read_virtual_dword_32(i->seg(), si);
  write_virtual_dword_32(BX_SEG_REG_ES, di, temp32);

  if (BX_CPU_THIS_PTR get_DF()) {
    si -= 4;
    di -= 4;
  }
  else {
    si += 4;
    di += 4;
  }

  SI = si;
  DI = di;
}

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSD32_XdYd(bxInstruction_c *i)
{
  Bit32u temp32;

  Bit32u incr = 4;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

#if (BX_SupportRepeatSpeedups) && (BX_DEBUGGER == 0)
  /* If conditions are right, we can transfer IO to physical memory
   * in a batch, rather than one instruction at a time.
   */
  if (i->repUsedL() && !BX_CPU_THIS_PTR async_event)
  {
    Bit32u dwordCount = FastRepMOVSD(i, i->seg(), esi, BX_SEG_REG_ES, edi, ECX);
    if (dwordCount) {
      // Decrement the ticks count by the number of iterations, minus
      // one, since the main cpu loop will decrement one.  Also,
      // the count is predecremented before examined, so defintely
      // don't roll it under zero.
      BX_TICKN(dwordCount-1);

      // Decrement eCX. Note, the main loop will decrement 1 also, so
      // decrement by one less than expected, like the case above.
      RCX = ECX - (dwordCount-1);

      incr = dwordCount << 2; // count * 4
    }
    else {
      temp32 = read_virtual_dword(i->seg(), esi);
      write_virtual_dword(BX_SEG_REG_ES, edi, temp32);
    }
  }
  else
#endif
  {
    temp32 = read_virtual_dword(i->seg(), esi);
    write_virtual_dword(BX_SEG_REG_ES, edi, temp32);
  }

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= incr;
    edi -= incr;
  }
  else {
    esi += incr;
    edi += incr;
  }

  // zero extension of RSI/RDI
  RSI = esi;
  RDI = edi;
}

#if BX_SUPPORT_X86_64

/* 32 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSD64_XdYd(bxInstruction_c *i)
{
  Bit32u temp32;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  temp32 = read_virtual_dword_64(i->seg(), rsi);
  write_virtual_dword_64(BX_SEG_REG_ES, rdi, temp32);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 4;
    rdi -= 4;
  }
  else {
    rsi += 4;
    rdi += 4;
  }

  RSI = rsi;
  RDI = rdi;
}

/* 64 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSQ32_XqYq(bxInstruction_c *i)
{
  Bit64u temp64;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  temp64 = read_virtual_qword_64(i->seg(), esi);
  write_virtual_qword_64(BX_SEG_REG_ES, edi, temp64);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 8;
    edi -= 8;
  }
  else {
    esi += 8;
    edi += 8;
  }

  // zero extension of RSI/RDI
  RSI = esi;
  RDI = edi;
}

/* 64 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::MOVSQ64_XqYq(bxInstruction_c *i)
{
  Bit64u temp64;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  temp64 = read_virtual_qword_64(i->seg(), rsi);
  write_virtual_qword_64(BX_SEG_REG_ES, rdi, temp64);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 8;
    rdi -= 8;
  }
  else {
    rsi += 8;
    rdi += 8;
  }

  RSI = rsi;
  RDI = rdi;
}

#endif

//
// REP CMPS methods
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_CMPSB_XbYb(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSB64_XbYb);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSB32_XbYb);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSB16_XbYb);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_CMPSW_XwYw(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSW64_XwYw);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSW32_XwYw);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSW16_XwYw);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_CMPSD_XdYd(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSD64_XdYd);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSD32_XdYd);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSD16_XdYd);
  }
}

#if BX_SUPPORT_X86_64
void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_CMPSQ_XqYq(bxInstruction_c *i)
{
  if (i->as64L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSQ64_XqYq);
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::CMPSQ32_XqYq);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI/RDI
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI);
  }
}
#endif

//
// CMPSB/CMPSW/CMPSD/CMPSQ methods
//

/* 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSB16_XbYb(bxInstruction_c *i)
{
  Bit8u op1_8, op2_8, diff_8;

  Bit16u si = SI;
  Bit16u di = DI;

  op1_8 = read_virtual_byte_32(i->seg(), si);
  op2_8 = read_virtual_byte_32(BX_SEG_REG_ES, di);

  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    si--;
    di--;
  }
  else {
    si++;
    di++;
  }

  DI = di;
  SI = si;
}

/* 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSB32_XbYb(bxInstruction_c *i)
{
  Bit8u op1_8, op2_8, diff_8;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  op1_8 = read_virtual_byte(i->seg(), esi);
  op2_8 = read_virtual_byte(BX_SEG_REG_ES, edi);

  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi--;
    edi--;
  }
  else {
    esi++;
    edi++;
  }

  // zero extension of RSI/RDI
  RDI = edi;
  RSI = esi;
}

#if BX_SUPPORT_X86_64
/* 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSB64_XbYb(bxInstruction_c *i)
{
  Bit8u op1_8, op2_8, diff_8;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  op1_8 = read_virtual_byte_64(i->seg(), rsi);
  op2_8 = read_virtual_byte_64(BX_SEG_REG_ES, rdi);

  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi--;
    rdi--;
  }
  else {
    rsi++;
    rdi++;
  }

  RDI = rdi;
  RSI = rsi;
}
#endif

/* 16 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSW16_XwYw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  Bit16u si = SI;
  Bit16u di = DI;

  op1_16 = read_virtual_word_32(i->seg(), si);
  op2_16 = read_virtual_word_32(BX_SEG_REG_ES, di);

  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    si -= 2;
    di -= 2;
  }
  else {
    si += 2;
    di += 2;
  }

  DI = di;
  SI = si;
}

/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSW32_XwYw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  op1_16 = read_virtual_word(i->seg(), esi);
  op2_16 = read_virtual_word(BX_SEG_REG_ES, edi);

  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 2;
    edi -= 2;
  }
  else {
    esi += 2;
    edi += 2;
  }

  // zero extension of RSI/RDI
  RDI = edi;
  RSI = esi;
}

#if BX_SUPPORT_X86_64
/* 16 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSW64_XwYw(bxInstruction_c *i)
{
  Bit16u op1_16, op2_16, diff_16;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  op1_16 = read_virtual_word_64(i->seg(), rsi);
  op2_16 = read_virtual_word_64(BX_SEG_REG_ES, rdi);

  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 2;
    rdi -= 2;
  }
  else {
    rsi += 2;
    rdi += 2;
  }

  RDI = rdi;
  RSI = rsi;
}
#endif

/* 32 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSD16_XdYd(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, diff_32;

  Bit16u si = SI;
  Bit16u di = DI;

  op1_32 = read_virtual_dword_32(i->seg(), si);
  op2_32 = read_virtual_dword_32(BX_SEG_REG_ES, di);

  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    si -= 4;
    di -= 4;
  }
  else {
    si += 4;
    di += 4;
  }

  DI = di;
  SI = si;
}

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSD32_XdYd(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, diff_32;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  op1_32 = read_virtual_dword(i->seg(), esi);
  op2_32 = read_virtual_dword(BX_SEG_REG_ES, edi);

  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 4;
    edi -= 4;
  }
  else {
    esi += 4;
    edi += 4;
  }

  // zero extension of RSI/RDI
  RDI = edi;
  RSI = esi;
}

#if BX_SUPPORT_X86_64

/* 32 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSD64_XdYd(bxInstruction_c *i)
{
  Bit32u op1_32, op2_32, diff_32;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  op1_32 = read_virtual_dword_64(i->seg(), rsi);
  op2_32 = read_virtual_dword_64(BX_SEG_REG_ES, rdi);

  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 4;
    rdi -= 4;
  }
  else {
    rsi += 4;
    rdi += 4;
  }

  RDI = rdi;
  RSI = rsi;
}

/* 64 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSQ32_XqYq(bxInstruction_c *i)
{
  Bit64u op1_64, op2_64, diff_64;

  Bit32u esi = ESI;
  Bit32u edi = EDI;

  op1_64 = read_virtual_qword_64(i->seg(), esi);
  op2_64 = read_virtual_qword_64(BX_SEG_REG_ES, edi);

  diff_64 = op1_64 - op2_64;

  SET_FLAGS_OSZAPC_SUB_64(op1_64, op2_64, diff_64);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 8;
    edi -= 8;
  }
  else {
    esi += 8;
    edi += 8;
  }

  // zero extension of RSI/RDI
  RDI = edi;
  RSI = esi;
}

/* 64 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::CMPSQ64_XqYq(bxInstruction_c *i)
{
  Bit64u op1_64, op2_64, diff_64;

  Bit64u rsi = RSI;
  Bit64u rdi = RDI;

  op1_64 = read_virtual_qword_64(i->seg(), rsi);
  op2_64 = read_virtual_qword_64(BX_SEG_REG_ES, rdi);

  diff_64 = op1_64 - op2_64;

  SET_FLAGS_OSZAPC_SUB_64(op1_64, op2_64, diff_64);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 8;
    rdi -= 8;
  }
  else {
    rsi += 8;
    rdi += 8;
  }

  RDI = rdi;
  RSI = rsi;
}

#endif

//
// REP SCAS methods
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_SCASB_ALXb(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASB64_ALXb);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASB32_ALXb);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASB16_ALXb);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_SCASW_AXXw(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASW64_AXXw);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASW32_AXXw);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASW16_AXXw);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_SCASD_EAXXd(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASD64_EAXXd);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASD32_EAXXd);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASD16_EAXXd);
  }
}

#if BX_SUPPORT_X86_64
void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_SCASQ_RAXXq(bxInstruction_c *i)
{
  if (i->as64L()) {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASQ64_RAXXq);
  }
  else {
    BX_CPU_THIS_PTR repeat_ZFL(i, &BX_CPU_C::SCASQ32_RAXXq);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
}
#endif

//
// SCASB/SCASW/SCASD/SCASQ methods
//

/* 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASB16_ALXb(bxInstruction_c *i)
{
  Bit8u op1_8 = AL, op2_8, diff_8;

  Bit16u di = DI;

  op2_8 = read_virtual_byte_32(BX_SEG_REG_ES, di);

  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    di--;
  }
  else {
    di++;
  }

  DI = di;
}

/* 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASB32_ALXb(bxInstruction_c *i)
{
  Bit8u op1_8 = AL, op2_8, diff_8;

  Bit32u edi = EDI;

  op2_8 = read_virtual_byte(BX_SEG_REG_ES, edi);
  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi--;
  }
  else {
    edi++;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64
/* 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASB64_ALXb(bxInstruction_c *i)
{
  Bit8u op1_8 = AL, op2_8, diff_8;

  Bit64u rdi = RDI;

  op2_8 = read_virtual_byte_64(BX_SEG_REG_ES, rdi);

  diff_8 = op1_8 - op2_8;

  SET_FLAGS_OSZAPC_SUB_8(op1_8, op2_8, diff_8);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi--;
  }
  else {
    rdi++;
  }

  RDI = rdi;
}
#endif

/* 16 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASW16_AXXw(bxInstruction_c *i)
{
  Bit16u op1_16 = AX, op2_16, diff_16;

  Bit16u di = DI;

  op2_16 = read_virtual_word_32(BX_SEG_REG_ES, di);
  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    di -= 2;
  }
  else {
    di += 2;
  }

  DI = di;
}

/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASW32_AXXw(bxInstruction_c *i)
{
  Bit16u op1_16 = AX, op2_16, diff_16;

  Bit32u edi = EDI;

  op2_16 = read_virtual_word(BX_SEG_REG_ES, edi);
  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 2;
  }
  else {
    edi += 2;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64
/* 16 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASW64_AXXw(bxInstruction_c *i)
{
  Bit16u op1_16 = AX, op2_16, diff_16;

  Bit64u rdi = RDI;

  op2_16 = read_virtual_word_64(BX_SEG_REG_ES, rdi);

  diff_16 = op1_16 - op2_16;

  SET_FLAGS_OSZAPC_SUB_16(op1_16, op2_16, diff_16);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 2;
  }
  else {
    rdi += 2;
  }

  RDI = rdi;
}
#endif

/* 32 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASD16_EAXXd(bxInstruction_c *i)
{
  Bit32u op1_32 = EAX, op2_32, diff_32;

  Bit16u di = DI;

  op2_32 = read_virtual_dword_32(BX_SEG_REG_ES, di);
  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    di -= 4;
  }
  else {
    di += 4;
  }

  DI = di;
}

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASD32_EAXXd(bxInstruction_c *i)
{
  Bit32u op1_32 = EAX, op2_32, diff_32;

  Bit32u edi = EDI;

  op2_32 = read_virtual_dword(BX_SEG_REG_ES, edi);
  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 4;
  }
  else {
    edi += 4;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64

/* 32 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASD64_EAXXd(bxInstruction_c *i)
{
  Bit32u op1_32 = EAX, op2_32, diff_32;

  Bit64u rdi = RDI;

  op2_32 = read_virtual_dword_64(BX_SEG_REG_ES, rdi);

  diff_32 = op1_32 - op2_32;

  SET_FLAGS_OSZAPC_SUB_32(op1_32, op2_32, diff_32);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 4;
  }
  else {
    rdi += 4;
  }

  RDI = rdi;
}

/* 64 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASQ32_RAXXq(bxInstruction_c *i)
{
  Bit64u op1_64 = RAX, op2_64, diff_64;

  Bit32u edi = EDI;

  op2_64 = read_virtual_qword_64(BX_SEG_REG_ES, edi);

  diff_64 = op1_64 - op2_64;

  SET_FLAGS_OSZAPC_SUB_64(op1_64, op2_64, diff_64);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 8;
  }
  else {
    edi += 8;
  }

  // zero extension of RDI
  RDI = edi;
}

/* 64 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::SCASQ64_RAXXq(bxInstruction_c *i)
{
  Bit64u op1_64 = RAX, op2_64, diff_64;

  Bit64u rdi = RDI;

  op2_64 = read_virtual_qword_64(BX_SEG_REG_ES, rdi);

  diff_64 = op1_64 - op2_64;

  SET_FLAGS_OSZAPC_SUB_64(op1_64, op2_64, diff_64);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 8;
  }
  else {
    rdi += 8;
  }

  RDI = rdi;
}

#endif

//
// REP STOS methods
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_STOSB_YbAL(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSB64_YbAL);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSB32_YbAL);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSB16_YbAL);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_STOSW_YwAX(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
  BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSW64_YwAX);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSW32_YwAX);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSW16_YwAX);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_STOSD_YdEAX(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSD64_YdEAX);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSD32_YdEAX);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSD16_YdEAX);
  }
}

#if BX_SUPPORT_X86_64
void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_STOSQ_YqRAX(bxInstruction_c *i)
{
  if (i->as64L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSQ64_YqRAX);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::STOSQ32_YqRAX);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RDI); // always clear upper part of RDI
  }
}
#endif

//
// STOSB/STOSW/STOSD/STOSQ methods
//

// 16 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSB16_YbAL(bxInstruction_c *i)
{
  Bit16u di = DI;

  write_virtual_byte_32(BX_SEG_REG_ES, di, AL);

  if (BX_CPU_THIS_PTR get_DF()) {
    di--;
  }
  else {
    di++;
  }

  DI = di;
}

// 32 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSB32_YbAL(bxInstruction_c *i)
{
  Bit32u incr = 1;
  Bit32u edi = EDI;

#if (BX_SupportRepeatSpeedups) && (BX_DEBUGGER == 0)
  /* If conditions are right, we can transfer IO to physical memory
   * in a batch, rather than one instruction at a time.
   */
  if (i->repUsedL() && !BX_CPU_THIS_PTR async_event)
  {
    Bit32u byteCount = FastRepSTOSB(i, BX_SEG_REG_ES, edi, AL, ECX);
    if (byteCount) {
      // Decrement the ticks count by the number of iterations, minus
      // one, since the main cpu loop will decrement one.  Also,
      // the count is predecremented before examined, so defintely
      // don't roll it under zero.
      BX_TICKN(byteCount-1);

      // Decrement eCX.  Note, the main loop will decrement 1 also, so
      // decrement by one less than expected, like the case above.
      RCX = ECX - (byteCount-1);

      incr = byteCount;
    }
    else {
      write_virtual_byte(BX_SEG_REG_ES, edi, AL);
    }
  }
  else
#endif
  {
    write_virtual_byte(BX_SEG_REG_ES, edi, AL);
  }

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= incr;
  }
  else {
    edi += incr;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64
// 64 bit address size
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSB64_YbAL(bxInstruction_c *i)
{
  Bit64u rdi = RDI;

  write_virtual_byte_64(BX_SEG_REG_ES, rdi, AL);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi--;
  }
  else {
    rdi++;
  }

  RDI = rdi;
}
#endif

/* 16 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSW16_YwAX(bxInstruction_c *i)
{
  Bit16u di = DI;

  write_virtual_word_32(BX_SEG_REG_ES, di, AX);

  if (BX_CPU_THIS_PTR get_DF()) {
    di -= 2;
  }
  else {
    di += 2;
  }

  DI = di;
}

/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSW32_YwAX(bxInstruction_c *i)
{
  Bit32u edi = EDI;

  write_virtual_word(BX_SEG_REG_ES, edi, AX);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 2;
  }
  else {
    edi += 2;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64
/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSW64_YwAX(bxInstruction_c *i)
{
  Bit64u rdi = RDI;

  write_virtual_word_64(BX_SEG_REG_ES, rdi, AX);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 2;
  }
  else {
    rdi += 2;
  }

  RDI = rdi;
}
#endif

/* 32 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSD16_YdEAX(bxInstruction_c *i)
{
  Bit16u di = DI;

  write_virtual_dword_32(BX_SEG_REG_ES, di, EAX);

  if (BX_CPU_THIS_PTR get_DF()) {
    di -= 4;
  }
  else {
    di += 4;
  }

  DI = di;
}

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSD32_YdEAX(bxInstruction_c *i)
{
  Bit32u edi = EDI;

  write_virtual_dword(BX_SEG_REG_ES, edi, EAX);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 4;
  }
  else {
    edi += 4;
  }

  // zero extension of RDI
  RDI = edi;
}

#if BX_SUPPORT_X86_64

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSD64_YdEAX(bxInstruction_c *i)
{
  Bit64u rdi = RDI;

  write_virtual_dword_64(BX_SEG_REG_ES, rdi, EAX);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 4;
  }
  else {
    rdi += 4;
  }

  RDI = rdi;
}

/* 64 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSQ32_YqRAX(bxInstruction_c *i)
{
  Bit32u edi = EDI;

  write_virtual_qword_64(BX_SEG_REG_ES, edi, RAX);

  if (BX_CPU_THIS_PTR get_DF()) {
    edi -= 8;
  }
  else {
    edi += 8;
  }

  // zero extension of RDI
  RDI = edi;
}

/* 64 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::STOSQ64_YqRAX(bxInstruction_c *i)
{
  Bit64u rdi = RDI;

  write_virtual_qword_64(BX_SEG_REG_ES, rdi, RAX);

  if (BX_CPU_THIS_PTR get_DF()) {
    rdi -= 8;
  }
  else {
    rdi += 8;
  }

  RDI = rdi;
}

#endif

//
// REP LODS methods
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_LODSB_ALXb(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSB64_ALXb);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSB32_ALXb);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSB16_ALXb);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_LODSW_AXXw(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSW64_AXXw);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSW32_AXXw);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSW16_AXXw);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_LODSD_EAXXd(bxInstruction_c *i)
{
#if BX_SUPPORT_X86_64
  if (i->as64L())
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSD64_EAXXd);
  else
#endif
  if (i->as32L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSD32_EAXXd);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSD16_EAXXd);
  }
}

#if BX_SUPPORT_X86_64
void BX_CPP_AttrRegparmN(1) BX_CPU_C::REP_LODSQ_RAXXq(bxInstruction_c *i)
{
  if (i->as64L()) {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSQ64_RAXXq);
  }
  else {
    BX_CPU_THIS_PTR repeat(i, &BX_CPU_C::LODSQ32_RAXXq);
    BX_CLEAR_64BIT_HIGH(BX_64BIT_REG_RSI); // always clear upper part of RSI
  }
}
#endif

//
// LODSB/LODSW/LODSD/LODSQ methods
//

/* 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSB16_ALXb(bxInstruction_c *i)
{
  Bit16u si = SI;

  AL = read_virtual_byte_32(i->seg(), si);

  if (BX_CPU_THIS_PTR get_DF()) {
    si--;
  }
  else {
    si++;
  }

  SI = si;
}

/* 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSB32_ALXb(bxInstruction_c *i)
{
  Bit32u esi = ESI;

  AL = read_virtual_byte(i->seg(), esi);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi--;
  }
  else {
    esi++;
  }

  // zero extension of RSI
  RSI = esi;
}

#if BX_SUPPORT_X86_64
/* 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSB64_ALXb(bxInstruction_c *i)
{
  Bit64u rsi = RSI;

  AL = read_virtual_byte_64(i->seg(), rsi);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi--;
  }
  else {
    rsi++;
  }

  RSI = rsi;
}
#endif

/* 16 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSW16_AXXw(bxInstruction_c *i)
{
  Bit16u si = SI;

  AX = read_virtual_word_32(i->seg(), si);

  if (BX_CPU_THIS_PTR get_DF()) {
    si -= 2;
  }
  else {
    si += 2;
  }

  SI = si;
}

/* 16 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSW32_AXXw(bxInstruction_c *i)
{
  Bit32u esi = ESI;

  AX = read_virtual_word(i->seg(), esi);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 2;
  }
  else {
    esi += 2;
  }

  // zero extension of RSI
  RSI = esi;
}

#if BX_SUPPORT_X86_64
/* 16 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSW64_AXXw(bxInstruction_c *i)
{
  Bit64u rsi = RSI;

  AX = read_virtual_word_64(i->seg(), rsi);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 2;
  }
  else {
    rsi += 2;
  }

  RSI = rsi;
}
#endif

/* 32 bit opsize mode, 16 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSD16_EAXXd(bxInstruction_c *i)
{
  Bit16u si = SI;

  RAX = read_virtual_dword_32(i->seg(), si);

  if (BX_CPU_THIS_PTR get_DF()) {
    si -= 4;
  }
  else {
    si += 4;
  }

  SI = si;
}

/* 32 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSD32_EAXXd(bxInstruction_c *i)
{
  Bit32u esi = ESI;

  RAX = read_virtual_dword(i->seg(), esi);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 4;
  }
  else {
    esi += 4;
  }

  // zero extension of RSI
  RSI = esi;
}

#if BX_SUPPORT_X86_64

/* 32 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSD64_EAXXd(bxInstruction_c *i)
{
  Bit64u rsi = RSI;

  RAX = read_virtual_dword_64(i->seg(), rsi);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 4;
  }
  else {
    rsi += 4;
  }

  RSI = rsi;
}

/* 64 bit opsize mode, 32 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSQ32_RAXXq(bxInstruction_c *i)
{
  Bit32u esi = ESI;

  RAX = read_virtual_qword_64(i->seg(), esi);

  if (BX_CPU_THIS_PTR get_DF()) {
    esi -= 8;
  }
  else {
    esi += 8;
  }

  // zero extension of RSI
  RSI = esi;
}

/* 64 bit opsize mode, 64 bit address size */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::LODSQ64_RAXXq(bxInstruction_c *i)
{
  Bit64u rsi = RSI;

  RAX = read_virtual_qword_64(i->seg(), rsi);

  if (BX_CPU_THIS_PTR get_DF()) {
    rsi -= 8;
  }
  else {
    rsi += 8;
  }

  RSI = rsi;
}

#endif
