/////////////////////////////////////////////////////////////////////////
// $Id: access64.cc,v 1.17 2008/08/31 06:04:14 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2008 Stanislav Shwartsman
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

#if BX_SUPPORT_X86_64

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_byte_64(unsigned s, Bit64u offset, Bit8u data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
  Bit64u lpf = LPFOf(laddr);
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 1, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
            tlbEntry->ppf | pageOffset, 1, CPL, BX_WRITE, (Bit8u*) &data);
      Bit8u *hostAddr = (Bit8u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      *hostAddr = data;
      return;
    }
  }
#endif

  if (! IsCanonical(laddr)) {
    BX_ERROR(("write_virtual_byte_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

  access_write_linear(laddr, 1, CPL, (void *) &data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_word_64(unsigned s, Bit64u offset, Bit16u data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 1) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 2, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 2, CPL, BX_WRITE, (Bit8u*) &data);
      Bit16u *hostAddr = (Bit16u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+1)) {
    BX_ERROR(("write_virtual_word_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 1) {
      BX_ERROR(("write_virtual_word_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 2, CPL, (void *) &data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dword_64(unsigned s, Bit64u offset, Bit32u data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 3) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 4, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 4, CPL, BX_WRITE, (Bit8u*) &data);
      Bit32u *hostAddr = (Bit32u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostDWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+3)) {
    BX_ERROR(("write_virtual_dword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 3) {
      BX_ERROR(("write_virtual_dword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 4, CPL, (void *) &data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_qword_64(unsigned s, Bit64u offset, Bit64u data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 7) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 8, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 8, CPL, BX_WRITE, (Bit8u*) &data);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostQWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+7)) {
    BX_ERROR(("write_virtual_qword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 7) {
      BX_ERROR(("write_virtual_qword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 8, CPL, (void *) &data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dqword_64(unsigned s, Bit64u offset, const BxPackedXmmRegister *data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 15) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 16, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 16, CPL, BX_WRITE, (Bit8u*) data);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostQWordToLittleEndian(hostAddr,   data->xmm64u(0));
      WriteHostQWordToLittleEndian(hostAddr+1, data->xmm64u(1));
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+15)) {
    BX_ERROR(("write_virtual_dqword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 15) {
      BX_ERROR(("write_virtual_dqword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 16, CPL, (void *) data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dqword_aligned_64(unsigned s, Bit64u offset, const BxPackedXmmRegister *data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);

  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_WRITE);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
  Bit64u lpf = AlignedAccessLPFOf(laddr, 15);
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 16, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 16, CPL, BX_WRITE, (Bit8u*) data);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostQWordToLittleEndian(hostAddr,   data->xmm64u(0));
      WriteHostQWordToLittleEndian(hostAddr+1, data->xmm64u(1));
      return;
    }
  }
#endif

  if (laddr & 15) {
    BX_ERROR(("write_virtual_dqword_aligned_64(): #GP misaligned access"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+15)) {
    BX_ERROR(("write_virtual_dqword_aligned_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

  access_write_linear(laddr, 16, CPL, (void *) data);
}

  Bit8u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_byte_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit8u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
  Bit64u lpf = LPFOf(laddr);
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 1, BX_READ);
      Bit8u *hostAddr = (Bit8u*) (hostPageAddr | pageOffset);
      data = *hostAddr;
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 1, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr)) {
    BX_ERROR(("read_virtual_byte_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

  access_read_linear(laddr, 1, CPL, BX_READ, (void *) &data);
  return data;
}

  Bit16u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_word_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit16u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 1) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 2, BX_READ);
      Bit16u *hostAddr = (Bit16u*) (hostPageAddr | pageOffset);
      ReadHostWordFromLittleEndian(hostAddr, data);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 2, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+1)) {
    BX_ERROR(("read_virtual_word_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 1) {
      BX_ERROR(("read_virtual_word_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_read_linear(laddr, 2, CPL, BX_READ, (void *) &data);
  return data;
}

  Bit32u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_dword_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit32u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 3) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 4, BX_READ);
      Bit32u *hostAddr = (Bit32u*) (hostPageAddr | pageOffset);
      ReadHostDWordFromLittleEndian(hostAddr, data);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 4, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+3)) {
    BX_ERROR(("read_virtual_dword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 3) {
      BX_ERROR(("read_virtual_dword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_read_linear(laddr, 4, CPL, BX_READ, (void *) &data);
  return data;
}

  Bit64u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_qword_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit64u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 7) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 8, BX_READ);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
      ReadHostQWordFromLittleEndian(hostAddr, data);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 8, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+7)) {
    BX_ERROR(("read_virtual_qword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 7) {
      BX_ERROR(("read_virtual_qword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif
  access_read_linear(laddr, 8, CPL, BX_READ, (void *) &data);
  return data;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::read_virtual_dqword_64(unsigned s, Bit64u offset, BxPackedXmmRegister *data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 15) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 16, BX_READ);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
        ReadHostQWordFromLittleEndian(hostAddr,   data->xmm64u(0));
        ReadHostQWordFromLittleEndian(hostAddr+1, data->xmm64u(1));
        BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
            tlbEntry->ppf | pageOffset, 16, CPL, BX_READ, (Bit8u*) data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+15)) {
    BX_ERROR(("read_virtual_dqword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 15) {
      BX_ERROR(("read_virtual_dqword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif
  access_read_linear(laddr, 16, CPL, BX_READ, (void *) data);
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::read_virtual_dqword_aligned_64(unsigned s, Bit64u offset, BxPackedXmmRegister *data)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_READ);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
  Bit64u lpf = AlignedAccessLPFOf(laddr, 15);
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us read access
    // from this CPL.
    if (! (tlbEntry->accessBits & USER_PL)) { // Read this pl OK.
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 16, BX_READ);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
        ReadHostQWordFromLittleEndian(hostAddr,   data->xmm64u(0));
        ReadHostQWordFromLittleEndian(hostAddr+1, data->xmm64u(1));
        BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
            tlbEntry->ppf | pageOffset, 16, CPL, BX_READ, (Bit8u*) data);
      return;
    }
  }
#endif

  if (laddr & 15) {
    BX_ERROR(("read_virtual_dqword_aligned_64(): #GP misaligned access"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+15)) {
    BX_ERROR(("read_virtual_dqword_aligned_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

  access_read_linear(laddr, 16, CPL, BX_READ, (void *) data);
}

//////////////////////////////////////////////////////////////
// special Read-Modify-Write operations                     //
// address translation info is kept across read/write calls //
//////////////////////////////////////////////////////////////

  Bit8u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_byte_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit8u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_RW);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
  Bit64u lpf = LPFOf(laddr);
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 1, BX_RW);
      Bit8u *hostAddr = (Bit8u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      data = *hostAddr;
      BX_CPU_THIS_PTR address_xlation.pages = (bx_ptr_equiv_t) hostAddr;
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 1, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr)) {
    BX_ERROR(("read_RMW_virtual_byte_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

  access_read_linear(laddr, 1, CPL, BX_RW, (void *) &data);
  return data;
}

  Bit16u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_word_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit16u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_RW);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 1) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 2, BX_RW);
      Bit16u *hostAddr = (Bit16u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      ReadHostWordFromLittleEndian(hostAddr, data);
      BX_CPU_THIS_PTR address_xlation.pages = (bx_ptr_equiv_t) hostAddr;
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 2, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+1)) {
    BX_ERROR(("read_RMW_virtual_word_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 1) {
      BX_ERROR(("read_RMW_virtual_word_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_read_linear(laddr, 2, CPL, BX_RW, (void *) &data);
  return data;
}

  Bit32u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_dword_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit32u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_RW);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 3) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 4, BX_RW);
      Bit32u *hostAddr = (Bit32u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      ReadHostDWordFromLittleEndian(hostAddr, data);
      BX_CPU_THIS_PTR address_xlation.pages = (bx_ptr_equiv_t) hostAddr;
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 4, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+3)) {
    BX_ERROR(("read_RMW_virtual_dword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 3) {
      BX_ERROR(("read_RMW_virtual_dword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_read_linear(laddr, 4, CPL, BX_RW, (void *) &data);
  return data;
}

  Bit64u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_qword_64(unsigned s, Bit64u offset)
{
  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64);
  Bit64u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_RW);

  Bit64u laddr = BX_CPU_THIS_PTR get_laddr64(s, offset);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 7) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | USER_PL))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 8, BX_RW);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      ReadHostQWordFromLittleEndian(hostAddr, data);
      BX_CPU_THIS_PTR address_xlation.pages = (bx_ptr_equiv_t) hostAddr;
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 8, CPL, BX_READ, (Bit8u*) &data);
      return data;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+7)) {
    BX_ERROR(("read_RMW_virtual_qword_64(): canonical failure"));
    exception(int_number(s), 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check()) {
    if (laddr & 7) {
      BX_ERROR(("read_RMW_virtual_qword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_read_linear(laddr, 8, CPL, BX_RW, (void *) &data);
  return data;
}

void BX_CPU_C::write_new_stack_word_64(Bit64u laddr, unsigned curr_pl, Bit16u data)
{
  bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 1) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | user))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 2, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 2, curr_pl, BX_WRITE, (Bit8u*) &data);
      Bit16u *hostAddr = (Bit16u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+1)) {
    BX_ERROR(("write_new_stack_word_64(): canonical failure"));
    exception(BX_SS_EXCEPTION, 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check() && user) {
    if (laddr & 1) {
      BX_ERROR(("write_new_stack_word_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 2, curr_pl, (void *) &data);
}

void BX_CPU_C::write_new_stack_dword_64(Bit64u laddr, unsigned curr_pl, Bit32u data)
{
  bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 3) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | user))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 4, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 4, curr_pl, BX_WRITE, (Bit8u*) &data);
      Bit32u *hostAddr = (Bit32u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostDWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+3)) {
    BX_ERROR(("write_new_stack_dword_64(): canonical failure"));
    exception(BX_SS_EXCEPTION, 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check() && user) {
    if (laddr & 3) {
      BX_ERROR(("write_new_stack_dword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 4, curr_pl, (void *) &data);
}

void BX_CPU_C::write_new_stack_qword_64(Bit64u laddr, unsigned curr_pl, Bit64u data)
{
  bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
  unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
  Bit64u lpf = AlignedAccessLPFOf(laddr, 7) & BX_CPU_THIS_PTR alignment_check_mask;
#else
  Bit64u lpf = LPFOf(laddr);
#endif    
  bx_TLB_entry *tlbEntry = &BX_CPU_THIS_PTR TLB.entry[tlbIndex];
  if (tlbEntry->lpf == lpf) {
    // See if the TLB entry privilege level allows us write access
    // from this CPL.
    if (! (tlbEntry->accessBits & (0x2 | user))) {
      bx_hostpageaddr_t hostPageAddr = tlbEntry->hostPageAddr;
      Bit32u pageOffset = PAGE_OFFSET(laddr);
      BX_INSTR_LIN_ACCESS(BX_CPU_ID, laddr, tlbEntry->ppf | pageOffset, 8, BX_WRITE);
      BX_DBG_LIN_MEMORY_ACCESS(BX_CPU_ID, laddr,
          tlbEntry->ppf | pageOffset, 8, curr_pl, BX_WRITE, (Bit8u*) &data);
      Bit64u *hostAddr = (Bit64u*) (hostPageAddr | pageOffset);
#if BX_SUPPORT_ICACHE
      pageWriteStampTable.decWriteStamp(tlbEntry->ppf);
#endif
      WriteHostQWordToLittleEndian(hostAddr, data);
      return;
    }
  }
#endif

  if (! IsCanonical(laddr) || ! IsCanonical(laddr+7)) {
    BX_ERROR(("write_new_stack_qword_64(): canonical failure"));
    exception(BX_SS_EXCEPTION, 0, 0);
  }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  if (BX_CPU_THIS_PTR alignment_check() && user) {
    if (laddr & 7) {
      BX_ERROR(("write_new_stack_qword_64(): #AC misaligned access"));
      exception(BX_AC_EXCEPTION, 0, 0);
    }
  }
#endif

  access_write_linear(laddr, 8, curr_pl, (void *) &data);
}

#endif
