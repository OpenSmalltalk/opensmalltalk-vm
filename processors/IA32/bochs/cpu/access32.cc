/////////////////////////////////////////////////////////////////////////
// $Id: access32.cc,v 1.14 2008/08/31 06:04:14 sshwarts Exp $
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

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_byte_32(unsigned s, Bit32u offset, Bit8u data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
    Bit32u lpf = LPFOf(laddr);
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
    access_write_linear(laddr, 1, CPL, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 1))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_word_32(unsigned s, Bit32u offset, Bit16u data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 1) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset == 0xffffffff) {
      BX_ERROR(("write_virtual_word_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 1) {
        BX_ERROR(("write_virtual_word_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 2, CPL, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 2))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dword_32(unsigned s, Bit32u offset, Bit32u data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 3) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffffd) {
      BX_ERROR(("write_virtual_dword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 3) {
        BX_ERROR(("write_virtual_dword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 4, CPL, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < (seg->cache.u.segment.limit_scaled-2))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 4))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_qword_32(unsigned s, Bit32u offset, Bit64u data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 7) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffff8) {
      BX_ERROR(("write_virtual_qword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 7) {
        BX_ERROR(("write_virtual_qword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 8, CPL, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-7))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 8))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dqword_32(unsigned s, Bit32u offset, const BxPackedXmmRegister *data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 15) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xffffffea) {
      BX_ERROR(("write_virtual_dqword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 15) {
        BX_ERROR(("write_virtual_dqword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 16, CPL, (void *) data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-15))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 16))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::write_virtual_dqword_aligned_32(unsigned s, Bit32u offset, const BxPackedXmmRegister *data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_WRITE);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
    Bit32u lpf = AlignedAccessLPFOf(laddr, 15);
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
      BX_ERROR(("write_virtual_dqword_aligned_32(): #GP misaligned access"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }
    access_write_linear(laddr, 16, CPL, (void *) data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-15))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 16))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit8u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_byte_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit8u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
    Bit32u lpf = LPFOf(laddr);
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
    access_read_linear(laddr, 1, CPL, BX_READ, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset <= seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 1))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit16u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_word_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit16u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 1) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset == 0xffffffff) {
      BX_ERROR(("read_virtual_word_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 1) {
        BX_ERROR(("read_virtual_word_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 2, CPL, BX_READ, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset < seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 2))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit32u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_dword_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit32u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 3) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffffd) {
      BX_ERROR(("read_virtual_dword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 3) {
        BX_ERROR(("read_virtual_dword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 4, CPL, BX_READ, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset < (seg->cache.u.segment.limit_scaled-2))
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 4))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit64u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_virtual_qword_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit64u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 7) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffff8) {
      BX_ERROR(("read_virtual_qword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 7) {
        BX_ERROR(("read_virtual_qword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 8, CPL, BX_READ, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-7))
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 8))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::read_virtual_dqword_32(unsigned s, Bit32u offset, BxPackedXmmRegister *data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 15) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xffffffea) {
      BX_ERROR(("read_virtual_dqword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 15) {
        BX_ERROR(("read_virtual_dqword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 16, CPL, BX_READ, (void *) data);
    return;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-15))
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 16))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::read_virtual_dqword_aligned_32(unsigned s, Bit32u offset, BxPackedXmmRegister *data)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 16, BX_READ);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessROK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 15);
    Bit32u lpf = AlignedAccessLPFOf(laddr, 15);
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
      BX_ERROR(("read_virtual_dqword_aligned_32(): #GP misaligned access"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }
    access_read_linear(laddr, 16, CPL, BX_READ, (void *) data);
    return;
  }

  if (seg->cache.valid & SegAccessROK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-15))
      goto accessOK;
  }

  if (!read_virtual_checks(seg, offset, 16))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

//////////////////////////////////////////////////////////////
// special Read-Modify-Write operations                     //
// address translation info is kept across read/write calls //
//////////////////////////////////////////////////////////////

  Bit8u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_byte_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit8u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 1, BX_RW);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 0);
    Bit32u lpf = LPFOf(laddr);
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
    access_read_linear(laddr, 1, CPL, BX_RW, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 1))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit16u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_word_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit16u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 2, BX_RW);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 1) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset == 0xffffffff) {
      BX_ERROR(("read_RMW_virtual_word_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 1) {
        BX_ERROR(("read_RMW_virtual_word_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 2, CPL, BX_RW, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 2))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit32u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_dword_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit32u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 4, BX_RW);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 3) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffffd) {
      BX_ERROR(("read_RMW_virtual_dword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 3) {
        BX_ERROR(("read_RMW_virtual_dword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 4, CPL, BX_RW, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < (seg->cache.u.segment.limit_scaled-2))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 4))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

  Bit64u BX_CPP_AttrRegparmN(2)
BX_CPU_C::read_RMW_virtual_qword_32(unsigned s, Bit32u offset)
{
  Bit32u laddr;
  bx_segment_reg_t *seg = &BX_CPU_THIS_PTR sregs[s];
  Bit64u data;
  BX_INSTR_MEM_DATA_ACCESS(BX_CPU_ID, s, offset, 8, BX_RW);

  BX_ASSERT(BX_CPU_THIS_PTR cpu_mode != BX_MODE_LONG_64);

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = BX_CPU_THIS_PTR get_laddr32(s, offset);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 7) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffff8) {
      BX_ERROR(("read_RMW_virtual_qword_32(): 4G segment limit violation"));
      exception(int_number(s), 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check()) {
      if (laddr & 7) {
        BX_ERROR(("read_RMW_virtual_qword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_read_linear(laddr, 8, CPL, BX_RW, (void *) &data);
    return data;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-7))
      goto accessOK;
  }

  if (!write_virtual_checks(seg, offset, 8))
    exception(int_number(s), 0, 0);
  goto accessOK;
}

/*
 * With COG we implement the paging access_read/write_linear level in the
 * primitive plugin support code (sqBochsIA32Plugin.cpp) to access data
 * directly to/from from the current Bitmap memory object.
 */
#if !COG
  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_byte(Bit8u val8)
{
  BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
    BX_CPU_THIS_PTR address_xlation.paddress1, 2, BX_WRITE, (Bit8u*) &val8);

  if (BX_CPU_THIS_PTR address_xlation.pages > 2) {
    // Pages > 2 means it stores a host address for direct access.
    Bit8u *hostAddr = (Bit8u *) BX_CPU_THIS_PTR address_xlation.pages;
    *hostAddr = val8;
  }
  else {
    // address_xlation.pages must be 1
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 1, &val8);
  }
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_word(Bit16u val16)
{
  if (BX_CPU_THIS_PTR address_xlation.pages > 2) {
    // Pages > 2 means it stores a host address for direct access.
    Bit16u *hostAddr = (Bit16u *) BX_CPU_THIS_PTR address_xlation.pages;
    WriteHostWordToLittleEndian(hostAddr, val16);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 2, BX_WRITE, (Bit8u*) &val16);
  }
  else if (BX_CPU_THIS_PTR address_xlation.pages == 1) {
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 2, &val16);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 2, BX_WRITE, (Bit8u*) &val16);
  }
  else {
#ifdef BX_LITTLE_ENDIAN
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 1, &val16);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 1, BX_WRITE,  (Bit8u*) &val16);
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2, 1, ((Bit8u *) &val16) + 1);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2, 1, BX_WRITE, ((Bit8u*) &val16)+1);
#else
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 1, ((Bit8u *) &val16) + 1);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 1, BX_WRITE, ((Bit8u*) &val16)+1);
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2, 1, &val16);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2, 1, BX_WRITE,  (Bit8u*) &val16);
#endif
  }
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_dword(Bit32u val32)
{
  if (BX_CPU_THIS_PTR address_xlation.pages > 2) {
    // Pages > 2 means it stores a host address for direct access.
    Bit32u *hostAddr = (Bit32u *) BX_CPU_THIS_PTR address_xlation.pages;
    WriteHostDWordToLittleEndian(hostAddr, val32);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 4, BX_WRITE, (Bit8u*) &val32);
  }
  else if (BX_CPU_THIS_PTR address_xlation.pages == 1) {
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 4, &val32);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 4, BX_WRITE, (Bit8u*) &val32);
  }
  else {
#ifdef BX_LITTLE_ENDIAN
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1,
        &val32);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1, BX_WRITE, (Bit8u*) &val32);
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2,
        ((Bit8u *) &val32) + BX_CPU_THIS_PTR address_xlation.len1);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2, BX_WRITE,
        ((Bit8u *) &val32) + BX_CPU_THIS_PTR address_xlation.len1);
#else
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1,
        ((Bit8u *) &val32) + (4 - BX_CPU_THIS_PTR address_xlation.len1));
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1, BX_WRITE,
        ((Bit8u *) &val32) + (4 - BX_CPU_THIS_PTR address_xlation.len1));
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2,
        &val32);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2, BX_WRITE, (Bit8u*) &val32);
#endif
  }
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_qword(Bit64u val64)
{
  if (BX_CPU_THIS_PTR address_xlation.pages > 2) {
    // Pages > 2 means it stores a host address for direct access.
    Bit64u *hostAddr = (Bit64u *) BX_CPU_THIS_PTR address_xlation.pages;
    WriteHostQWordToLittleEndian(hostAddr, val64);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 8, BX_WRITE, (Bit8u*) &val64);
  }
  else if (BX_CPU_THIS_PTR address_xlation.pages == 1) {
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1, 8, &val64);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1, 8, BX_WRITE, (Bit8u*) &val64);
  }
  else {
#ifdef BX_LITTLE_ENDIAN
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1,
        &val64);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1, BX_WRITE, (Bit8u*) &val64);
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2,
        ((Bit8u *) &val64) + BX_CPU_THIS_PTR address_xlation.len1);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2, BX_WRITE,
        ((Bit8u *) &val64) + BX_CPU_THIS_PTR address_xlation.len1);
#else
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1,
        ((Bit8u *) &val64) + (8 - BX_CPU_THIS_PTR address_xlation.len1));
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress1,
        BX_CPU_THIS_PTR address_xlation.len1, BX_WRITE,
        ((Bit8u *) &val64) + (8 - BX_CPU_THIS_PTR address_xlation.len1));
    BX_MEM(0)->writePhysicalPage(BX_CPU_THIS,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2,
        &val64);
    BX_DBG_PHY_MEMORY_ACCESS(BX_CPU_ID,
        BX_CPU_THIS_PTR address_xlation.paddress2,
        BX_CPU_THIS_PTR address_xlation.len2, BX_WRITE, (Bit8u*) &val64);
#endif
  }
}
#endif /* !COG */


//
// Write data to new stack, these methods are required for emulation
// correctness but not performance critical.
//

// assuming the write happens in legacy mode
void BX_CPU_C::write_new_stack_word_32(bx_segment_reg_t *seg, Bit32u offset, unsigned curr_pl, Bit16u data)
{
  Bit32u laddr;

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = (Bit32u)(seg->cache.u.segment.base) + offset;
    bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 1);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 1) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset == 0xffffffff) {
      BX_ERROR(("write_new_stack_word_32(): 4G segment limit violation"));
      exception(BX_SS_EXCEPTION, seg->selector.value & 0xfffc, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check() && user) {
      if (laddr & 1) {
        BX_ERROR(("write_new_stack_word_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 2, curr_pl, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < seg->cache.u.segment.limit_scaled)
      goto accessOK;
  }

  // add error code when segment violation occurs when pushing into new stack
  if (!write_virtual_checks(seg, offset, 2))
    exception(BX_SS_EXCEPTION, 
         seg->selector.rpl != CPL ? (seg->selector.value & 0xfffc) : 0, 0);
  goto accessOK;
}

// assuming the write happens in legacy mode
void BX_CPU_C::write_new_stack_dword_32(bx_segment_reg_t *seg, Bit32u offset, unsigned curr_pl, Bit32u data)
{
  Bit32u laddr;

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = (Bit32u)(seg->cache.u.segment.base) + offset;
    bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 3);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 3) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffffd) {
      BX_ERROR(("write_new_stack_dword_32(): 4G segment limit violation"));
      exception(BX_SS_EXCEPTION, seg->selector.value & 0xfffc, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check() && user) {
      if (laddr & 3) {
        BX_ERROR(("write_new_stack_dword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 4, curr_pl, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset < (seg->cache.u.segment.limit_scaled-2))
      goto accessOK;
  }

  // add error code when segment violation occurs when pushing into new stack
  if (!write_virtual_checks(seg, offset, 4))
    exception(BX_SS_EXCEPTION, 
         seg->selector.rpl != CPL ? (seg->selector.value & 0xfffc) : 0, 0);
  goto accessOK;
}

// assuming the write happens in legacy mode
void BX_CPU_C::write_new_stack_qword_32(bx_segment_reg_t *seg, Bit32u offset, unsigned curr_pl, Bit64u data)
{
  Bit32u laddr;

  if (seg->cache.valid & SegAccessWOK4G) {
accessOK:
    laddr = (Bit32u)(seg->cache.u.segment.base) + offset;
    bx_bool user = (curr_pl == 3);
#if BX_SupportGuest2HostTLB
    unsigned tlbIndex = BX_TLB_INDEX_OF(laddr, 7);
#if BX_SUPPORT_ALIGNMENT_CHECK && BX_CPU_LEVEL >= 4
    Bit32u lpf = AlignedAccessLPFOf(laddr, 7) & (Bit32u) BX_CPU_THIS_PTR alignment_check_mask;
#else
    Bit32u lpf = LPFOf(laddr);
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

    // missed 4G limit check
    if (offset >= 0xfffffff8) {
      BX_ERROR(("write_new_stack_qword_32(): 4G segment limit violation"));
      exception(BX_SS_EXCEPTION, 
         seg->selector.rpl != CPL ? (seg->selector.value & 0xfffc) : 0, 0);
    }

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    if (BX_CPU_THIS_PTR alignment_check() && user) {
      if (laddr & 7) {
        BX_ERROR(("write_new_stack_qword_32(): #AC misaligned access"));
        exception(BX_AC_EXCEPTION, 0, 0);
      }
    }
#endif

    access_write_linear(laddr, 8, curr_pl, (void *) &data);
    return;
  }

  if (seg->cache.valid & SegAccessWOK) {
    if (offset <= (seg->cache.u.segment.limit_scaled-7))
      goto accessOK;
  }

  // add error code when segment violation occurs when pushing into new stack
  if (!write_virtual_checks(seg, offset, 8))
    exception(BX_SS_EXCEPTION, 
        seg->selector.rpl != CPL ? (seg->selector.value & 0xfffc) : 0, 0);
  goto accessOK;
}
