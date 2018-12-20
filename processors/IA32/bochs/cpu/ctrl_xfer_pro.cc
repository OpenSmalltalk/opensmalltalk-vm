////////////////////////////////////////////////////////////////////////
// $Id: ctrl_xfer_pro.cc,v 1.76 2008/08/03 19:53:08 sshwarts Exp $
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
// Make life easier merging cpu64 & cpu code.
#define RIP EIP
#endif

/* pass zero in check_rpl if no needed selector RPL checking for
   non-conforming segments */
void BX_CPU_C::check_cs(bx_descriptor_t *descriptor, Bit16u cs_raw, Bit8u check_rpl, Bit8u check_cpl)
{
  // descriptor AR byte must indicate code segment else #GP(selector)
  if (descriptor->valid==0 || descriptor->segment==0 ||
          IS_DATA_SEGMENT(descriptor->type))
  {
    BX_ERROR(("check_cs(0x%04x): not a valid code segment !", cs_raw));
    exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
  }

#if BX_SUPPORT_X86_64
  if (descriptor->u.segment.l) {
    if (! BX_CPU_THIS_PTR efer.get_LMA()) {
      BX_ERROR(("check_cs(0x%04x): attempt to jump to long mode without enabling EFER.LMA !", cs_raw));
    }
    else if (descriptor->u.segment.d_b) {
      BX_ERROR(("check_cs(0x%04x): Both L and D bits enabled for segment descriptor !", cs_raw));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }
  }
#endif

  // if non-conforming, code segment descriptor DPL must = CPL else #GP(selector)
  if (IS_CODE_SEGMENT_NON_CONFORMING(descriptor->type)) {
    if (descriptor->dpl != check_cpl) {
      BX_ERROR(("check_cs(0x%04x): non-conforming code seg descriptor dpl != cpl, dpl=%d, cpl=%d",
         cs_raw, descriptor->dpl, check_cpl));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

    /* RPL of destination selector must be <= CPL else #GP(selector) */
    if (check_rpl > check_cpl) {
      BX_ERROR(("check_cs(0x%04x): non-conforming code seg selector rpl > cpl, rpl=%d, cpl=%d",
         cs_raw, check_rpl, check_cpl));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }
  }
  // if conforming, then code segment descriptor DPL must <= CPL else #GP(selector)
  else {
    if (descriptor->dpl > check_cpl) {
      BX_ERROR(("check_cs(0x%04x): conforming code seg descriptor dpl > cpl, dpl=%d, cpl=%d",
         cs_raw, descriptor->dpl, check_cpl));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }
  }

  // code segment must be present else #NP(selector)
  if (! descriptor->p) {
    BX_ERROR(("check_cs(0x%04x): code segment not present !", cs_raw));
    exception(BX_NP_EXCEPTION, cs_raw & 0xfffc, 0);
  }
}

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::load_cs(bx_selector_t *selector, bx_descriptor_t *descriptor, Bit8u cpl)
{
  // Add cpl to the selector value.
  selector->value = (0xfffc & selector->value) | cpl;

  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector = *selector;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache = *descriptor;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.rpl = cpl;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.valid  = 1;

#if BX_SUPPORT_X86_64
  if (long_mode()) {
    if (descriptor->u.segment.l) {
      loadSRegLMNominal(BX_SEG_REG_CS, selector->value, cpl);
    }
    handleCpuModeChange();
  }
#endif

  updateFetchModeMask();

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
  handleAlignmentCheck(); // CPL was modified
#endif

  // Loading CS will invalidate the EIP fetch window.
  invalidate_prefetch_q();
}

void BX_CPU_C::branch_far32(bx_selector_t *selector,
           bx_descriptor_t *descriptor, Bit32u eip, Bit8u cpl)
{
  /* instruction pointer must be in code segment limit else #GP(0) */
  if (eip > descriptor->u.segment.limit_scaled) {
    BX_ERROR(("branch_far32: EIP > limit"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  /* Load CS:IP from destination pointer */
  /* Load CS-cache with new segment descriptor */
  load_cs(selector, descriptor, cpl);

  /* Change the EIP value */
  EIP = eip;
}

void BX_CPU_C::branch_far64(bx_selector_t *selector,
           bx_descriptor_t *descriptor, bx_address rip, Bit8u cpl)
{
#if BX_SUPPORT_X86_64
  if (long_mode() && descriptor->u.segment.l) {
    if (! IsCanonical(rip)) {
      BX_ERROR(("branch_far64: canonical RIP violation"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }
  }
  else
#endif
  {
    /* instruction pointer must be in code segment limit else #GP(0) */
    if (rip > descriptor->u.segment.limit_scaled) {
      BX_ERROR(("branch_far64: RIP > limit"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }
  }

  /* Load CS:IP from destination pointer */
  /* Load CS-cache with new segment descriptor */
  load_cs(selector, descriptor, cpl);

  /* Change the RIP value */
  RIP = rip;
}
