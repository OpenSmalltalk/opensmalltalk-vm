/////////////////////////////////////////////////////////////////////////
// $Id: protect_ctrl.cc,v 1.91 2008/08/08 09:22:48 sshwarts Exp $
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

void BX_CPP_AttrRegparmN(1) BX_CPU_C::ARPL_EwGw(bxInstruction_c *i)
{
  Bit16u op2_16, op1_16;

  if (real_mode() || v8086_mode()) {
    BX_DEBUG(("ARPL: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  /* op1_16 is a register or memory reference */
  if (i->modC0()) {
    op1_16 = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    op1_16 = read_RMW_virtual_word(i->seg(), eaddr);
  }

  op2_16 = BX_READ_16BIT_REG(i->nnn());

  if ((op1_16 & 0x03) < (op2_16 & 0x03)) {
    op1_16 = (op1_16 & 0xfffc) | (op2_16 & 0x03);
    /* now write back to destination */
    if (i->modC0()) {
      BX_WRITE_16BIT_REG(i->rm(), op1_16);
    }
    else {
      write_RMW_virtual_word(op1_16);
    }
    assert_ZF();
  }
  else {
    clear_ZF();
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LAR_GvEw(bxInstruction_c *i)
{
  /* for 16 bit operand size mode */
  Bit16u raw_selector;
  bx_descriptor_t descriptor;
  bx_selector_t selector;
  Bit32u dword1, dword2;

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("LAR: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  /* if selector null, clear ZF and done */
  if ((raw_selector & 0xfffc) == 0) {
    clear_ZF();
    return;
  }

  parse_selector(raw_selector, &selector);

  if (!fetch_raw_descriptor2(&selector, &dword1, &dword2)) {
    BX_DEBUG(("LAR: failed to fetch descriptor"));
    clear_ZF();
    return;
  }

  parse_descriptor(dword1, dword2, &descriptor);

  if (descriptor.valid==0) {
    BX_DEBUG(("LAR: descriptor not valid"));
    clear_ZF();
    return;
  }

  /* if source selector is visible at CPL & RPL,
   * within the descriptor table, and of type accepted by LAR instruction,
   * then load register with segment limit and set ZF
   */

  if (descriptor.segment) { /* normal segment */
    if (IS_CODE_SEGMENT(descriptor.type) && IS_CODE_SEGMENT_CONFORMING(descriptor.type)) {
      /* ignore DPL for conforming segments */
    }
    else {
      if ((descriptor.dpl<CPL) || (descriptor.dpl<selector.rpl)) {
        clear_ZF();
        return;
      }
    }
    assert_ZF();
    if (i->os32L()) {
      /* masked by 00FxFF00, where x is undefined */
      BX_WRITE_32BIT_REGZ(i->nnn(), dword2 & 0x00ffff00);
    }
    else {
      BX_WRITE_16BIT_REG(i->nnn(), dword2 & 0xff00);
    }
  }
  else { /* system or gate segment */
    switch (descriptor.type) {
      case BX_SYS_SEGMENT_AVAIL_286_TSS:
      case BX_SYS_SEGMENT_BUSY_286_TSS:
      case BX_286_CALL_GATE:
      case BX_TASK_GATE:
        if (long_mode()) {
          BX_DEBUG(("LAR: descriptor type in not accepted in long mode"));
          clear_ZF();
          return;
        }
        /* fall through */
      case BX_SYS_SEGMENT_LDT:
#if BX_CPU_LEVEL >= 3
      case BX_SYS_SEGMENT_AVAIL_386_TSS:
      case BX_SYS_SEGMENT_BUSY_386_TSS:
      case BX_386_CALL_GATE:
#endif
        break;
      default: /* rest not accepted types to LAR */
        BX_DEBUG(("LAR: not accepted descriptor type"));
        clear_ZF();
        return;
    }

    if ((descriptor.dpl<CPL) || (descriptor.dpl<selector.rpl)) {
      clear_ZF();
      return;
    }
    assert_ZF();
    if (i->os32L()) {
      /* masked by 00FxFF00, where x is undefined ? */
      BX_WRITE_32BIT_REGZ(i->nnn(), dword2 & 0x00ffff00);
    }
    else {
      BX_WRITE_16BIT_REG(i->nnn(), dword2 & 0xff00);
    }
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LSL_GvEw(bxInstruction_c *i)
{
  /* for 16 bit operand size mode */
  Bit16u raw_selector;
  Bit32u limit32;
  bx_selector_t selector;
  Bit32u dword1, dword2;

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("LSL: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  /* if selector null, clear ZF and done */
  if ((raw_selector & 0xfffc) == 0) {
    clear_ZF();
    return;
  }

  parse_selector(raw_selector, &selector);

  if (!fetch_raw_descriptor2(&selector, &dword1, &dword2)) {
    clear_ZF();
    return;
  }

  Bit32u descriptor_dpl = (dword2 >> 13) & 0x03;

  if ((dword2 & 0x00001000) == 0) { // system segment
    Bit32u type = (dword2 >> 8) & 0x0000000f;
    switch (type) {
      case BX_SYS_SEGMENT_AVAIL_286_TSS:
      case BX_SYS_SEGMENT_BUSY_286_TSS:
        if (long_mode()) {
          clear_ZF();
          return;
        }
        /* fall through */
      case BX_SYS_SEGMENT_LDT:
      case BX_SYS_SEGMENT_AVAIL_386_TSS:
      case BX_SYS_SEGMENT_BUSY_386_TSS:
        if ((descriptor_dpl<CPL) || (descriptor_dpl<selector.rpl)) {
          clear_ZF();
          return;
        }
        limit32 = (dword1 & 0x0000ffff) | (dword2 & 0x000f0000);
        if (dword2 & 0x00800000)
          limit32 = (limit32 << 12) | 0x00000fff;
        break;
      default:
        clear_ZF();
        return;
    }
  }
  else { // data & code segment
    limit32 = (dword1 & 0x0000ffff) | (dword2 & 0x000f0000);
    if (dword2 & 0x00800000)
      limit32 = (limit32 << 12) | 0x00000fff;
    if ((dword2 & 0x00000c00) != 0x00000c00) {
      // non-conforming code segment
      if ((descriptor_dpl<CPL) || (descriptor_dpl<selector.rpl)) {
        clear_ZF();
        return;
      }
    }
  }

  /* all checks pass, limit32 is now byte granular, write to op1 */
  assert_ZF();

  if (i->os32L()) {
    BX_WRITE_32BIT_REGZ(i->nnn(), limit32);
  }
  else {
    // chop off upper 16 bits
    BX_WRITE_16BIT_REG(i->nnn(), (Bit16u) limit32);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SLDT_Ew(bxInstruction_c *i)
{
  if (real_mode() || v8086_mode()) {
    BX_ERROR(("SLDT: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  Bit16u val16 = BX_CPU_THIS_PTR ldtr.selector.value;
  if (i->modC0()) {
    if (i->os32L()) {
      BX_WRITE_32BIT_REGZ(i->rm(), val16);
    }
    else {
      BX_WRITE_16BIT_REG(i->rm(), val16);
    }
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    write_virtual_word(i->seg(), eaddr, val16);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::STR_Ew(bxInstruction_c *i)
{
  if (real_mode() || v8086_mode()) {
    BX_ERROR(("STR: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  Bit16u val16 = BX_CPU_THIS_PTR tr.selector.value;
  if (i->modC0()) {
    if (i->os32L()) {
      BX_WRITE_32BIT_REGZ(i->rm(), val16);
    }
    else {
      BX_WRITE_16BIT_REG(i->rm(), val16);
    }
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    write_virtual_word(i->seg(), eaddr, val16);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LLDT_Ew(bxInstruction_c *i)
{
  /* protected mode */
  bx_descriptor_t  descriptor;
  bx_selector_t    selector;
  Bit16u raw_selector;
  Bit32u dword1, dword2;
#if BX_SUPPORT_X86_64
  Bit32u dword3 = 0;
#endif

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("LLDT: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (CPL != 0) {
    BX_ERROR(("LLDT: The current privilege level is not 0"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  invalidate_prefetch_q();

  /* if selector is NULL, invalidate and done */
  if ((raw_selector & 0xfffc) == 0) {
    BX_CPU_THIS_PTR ldtr.selector.value = raw_selector;
    BX_CPU_THIS_PTR ldtr.cache.valid = 0;
    return;
  }

  /* parse fields in selector */
  parse_selector(raw_selector, &selector);

  // #GP(selector) if the selector operand does not point into GDT
  if (selector.ti != 0) {
    BX_ERROR(("LLDT: selector.ti != 0"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

  /* fetch descriptor; call handles out of limits checks */
#if BX_SUPPORT_X86_64
  if (BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64) {
    fetch_raw_descriptor_64(&selector, &dword1, &dword2, &dword3, BX_GP_EXCEPTION);
  }
  else
#endif
  {
    fetch_raw_descriptor(&selector, &dword1, &dword2, BX_GP_EXCEPTION);
  }

  parse_descriptor(dword1, dword2, &descriptor);

  /* if selector doesn't point to an LDT descriptor #GP(selector) */
  if (descriptor.valid == 0 || descriptor.segment ||
         descriptor.type != BX_SYS_SEGMENT_LDT)
  {
    BX_ERROR(("LLDT: doesn't point to an LDT descriptor!"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

  /* #NP(selector) if LDT descriptor is not present */
  if (! IS_PRESENT(descriptor)) {
    BX_ERROR(("LLDT: LDT descriptor not present!"));
    exception(BX_NP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

#if BX_SUPPORT_X86_64
  descriptor.u.system.base |= ((Bit64u)(dword3) << 32);
  BX_DEBUG(("64 bit LDT base = 0x%08x%08x",
     GET32H(descriptor.u.system.base), GET32L(descriptor.u.system.base)));
  if (!IsCanonical(descriptor.u.system.base)) {
    BX_ERROR(("LLDT: non-canonical LDT descriptor base!"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }
#endif

  BX_CPU_THIS_PTR ldtr.selector = selector;
  BX_CPU_THIS_PTR ldtr.cache = descriptor;
  BX_CPU_THIS_PTR ldtr.cache.valid = 1;
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LTR_Ew(bxInstruction_c *i)
{
  bx_descriptor_t descriptor;
  bx_selector_t selector;
  Bit16u raw_selector;
  Bit32u dword1, dword2;
#if BX_SUPPORT_X86_64
  Bit32u dword3 = 0;
#endif

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("LTR: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (CPL != 0) {
    BX_ERROR(("LTR: The current privilege level is not 0"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  invalidate_prefetch_q();

  /* if selector is NULL, invalidate and done */
  if ((raw_selector & BX_SELECTOR_RPL_MASK) == 0) {
    BX_ERROR(("LTR: loading with NULL selector!"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  /* parse fields in selector, then check for null selector */
  parse_selector(raw_selector, &selector);

  if (selector.ti) {
    BX_ERROR(("LTR: selector.ti != 0"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

  /* fetch descriptor; call handles out of limits checks */
#if BX_SUPPORT_X86_64
  if (BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64) {
    fetch_raw_descriptor_64(&selector, &dword1, &dword2, &dword3, BX_GP_EXCEPTION);
  }
  else
#endif
  {
    fetch_raw_descriptor(&selector, &dword1, &dword2, BX_GP_EXCEPTION);
  }

  parse_descriptor(dword1, dword2, &descriptor);

  /* #GP(selector) if object is not a TSS or is already busy */
  if (descriptor.valid==0 || descriptor.segment ||
         (descriptor.type!=BX_SYS_SEGMENT_AVAIL_286_TSS &&
          descriptor.type!=BX_SYS_SEGMENT_AVAIL_386_TSS))
  {
    BX_ERROR(("LTR: doesn't point to an available TSS descriptor!"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

#if BX_SUPPORT_X86_64
  if (long_mode() && descriptor.type!=BX_SYS_SEGMENT_AVAIL_386_TSS) {
    BX_ERROR(("LTR: doesn't point to an available TSS386 descriptor in long mode!"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }
#endif

  /* #NP(selector) if TSS descriptor is not present */
  if (! IS_PRESENT(descriptor)) {
    BX_ERROR(("LTR: TSS descriptor not present!"));
    exception(BX_NP_EXCEPTION, raw_selector & 0xfffc, 0);
  }

#if BX_SUPPORT_X86_64
  descriptor.u.system.base |= ((Bit64u)(dword3) << 32);
  BX_DEBUG(("64 bit TSS base = 0x%08x%08x",
     GET32H(descriptor.u.system.base), GET32L(descriptor.u.system.base)));
  if (!IsCanonical(descriptor.u.system.base)) {
    BX_ERROR(("LTR: non-canonical TSS descriptor base!"));
    exception(BX_GP_EXCEPTION, raw_selector & 0xfffc, 0);
  }
#endif

  BX_CPU_THIS_PTR tr.selector = selector;
  BX_CPU_THIS_PTR tr.cache    = descriptor;
  BX_CPU_THIS_PTR tr.cache.valid = 1;
  // tr.cache.type should not have busy bit, or it would not get
  // through the conditions above.
  BX_ASSERT((BX_CPU_THIS_PTR tr.cache.type & 2) == 0);
  BX_CPU_THIS_PTR tr.cache.type |= 2; // mark as busy

  /* mark as busy */
  if (!(dword2 & 0x0200)) {
    dword2 |= 0x0200; /* set busy bit */
    access_write_linear(BX_CPU_THIS_PTR gdtr.base + selector.index*8 + 4, 4, 0, &dword2);
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::VERR_Ew(bxInstruction_c *i)
{
  /* for 16 bit operand size mode */
  Bit16u raw_selector;
  bx_descriptor_t descriptor;
  bx_selector_t selector;
  Bit32u dword1, dword2;

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("VERR: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  /* if selector null, clear ZF and done */
  if ((raw_selector & 0xfffc) == 0) {
    BX_DEBUG(("VERR: null selector"));
    clear_ZF();
    return;
  }

  /* if source selector is visible at CPL & RPL,
   * within the descriptor table, and of type accepted by VERR instruction,
   * then load register with segment limit and set ZF */
  parse_selector(raw_selector, &selector);

  if (!fetch_raw_descriptor2(&selector, &dword1, &dword2)) {
    /* not within descriptor table */
    BX_DEBUG(("VERR: not within descriptor table"));
    clear_ZF();
    return;
  }

  parse_descriptor(dword1, dword2, &descriptor);

  if (descriptor.segment==0) { /* system or gate descriptor */
    BX_DEBUG(("VERR: system descriptor"));
    clear_ZF();  /* inaccessible */
    return;
  }

  if (descriptor.valid==0) {
    BX_DEBUG(("VERR: valid bit cleared"));
    clear_ZF();  /* inaccessible */
    return;
  }

  /* normal data/code segment */
  if (IS_CODE_SEGMENT(descriptor.type)) { /* code segment */
    /* ignore DPL for readable conforming segments */
    if (IS_CODE_SEGMENT_CONFORMING(descriptor.type) &&
        IS_CODE_SEGMENT_READABLE(descriptor.type))
    {
      BX_DEBUG(("VERR: conforming code, OK"));
      assert_ZF(); /* accessible */
      return;
    }
    if (!IS_CODE_SEGMENT_READABLE(descriptor.type)) {
      BX_DEBUG(("VERR: code not readable"));
      clear_ZF();  /* inaccessible */
      return;
    }
    /* readable, non-conforming code segment */
    if ((descriptor.dpl<CPL) || (descriptor.dpl<selector.rpl)) {
      BX_DEBUG(("VERR: non-conforming code not withing priv level"));
      clear_ZF();  /* inaccessible */
    }
    else {
      assert_ZF(); /* accessible */
    }
  }
  else { /* data segment */
    if ((descriptor.dpl<CPL) || (descriptor.dpl<selector.rpl)) {
      BX_DEBUG(("VERR: data seg not withing priv level"));
      clear_ZF(); /* not accessible */
    }
    else {
      assert_ZF(); /* accessible */
    }
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::VERW_Ew(bxInstruction_c *i)
{
  /* for 16 bit operand size mode */
  Bit16u raw_selector;
  bx_descriptor_t descriptor;
  bx_selector_t selector;
  Bit32u dword1, dword2;

  if (real_mode() || v8086_mode()) {
    BX_ERROR(("VERW: not recognized in real or virtual-8086 mode"));
    exception(BX_UD_EXCEPTION, 0, 0);
  }

  if (i->modC0()) {
    raw_selector = BX_READ_16BIT_REG(i->rm());
  }
  else {
    bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));
    /* pointer, segment address pair */
    raw_selector = read_virtual_word(i->seg(), eaddr);
  }

  /* if selector null, clear ZF and done */
  if ((raw_selector & 0xfffc) == 0) {
    BX_DEBUG(("VERW: null selector"));
    clear_ZF();
    return;
  }

  /* if source selector is visible at CPL & RPL,
   * within the descriptor table, and of type accepted by VERW instruction,
   * then load register with segment limit and set ZF */
  parse_selector(raw_selector, &selector);

  if (!fetch_raw_descriptor2(&selector, &dword1, &dword2)) {
    /* not within descriptor table */
    BX_DEBUG(("VERW: not within descriptor table"));
    clear_ZF();
    return;
  }

  parse_descriptor(dword1, dword2, &descriptor);

  /* rule out system segments & code segments */
  if (descriptor.segment==0 || IS_CODE_SEGMENT(descriptor.type)) {
    BX_DEBUG(("VERW: system seg or code"));
    clear_ZF();
    return;
  }

  if (descriptor.valid==0) {
    BX_DEBUG(("VERW: valid bit cleared"));
    clear_ZF();
    return;
  }

  /* data segment */
  if (IS_DATA_SEGMENT_WRITEABLE(descriptor.type)) { /* writable */
    if ((descriptor.dpl<CPL) || (descriptor.dpl<selector.rpl)) {
      BX_DEBUG(("VERW: writable data seg not within priv level"));
      clear_ZF(); /* not accessible */
    }
    else {
      assert_ZF();  /* accessible */
    }
  }
  else {
    BX_DEBUG(("VERW: data seg not writable"));
    clear_ZF(); /* not accessible */
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SGDT_Ms(bxInstruction_c *i)
{
  Bit16u limit_16 = BX_CPU_THIS_PTR gdtr.limit;
  Bit32u base_32  = (Bit32u) BX_CPU_THIS_PTR gdtr.base;

  Bit32u eaddr = (Bit32u) BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  write_virtual_word_32(i->seg(), eaddr, limit_16);
  write_virtual_dword_32(i->seg(), eaddr+2, base_32);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SIDT_Ms(bxInstruction_c *i)
{
  Bit16u limit_16 = BX_CPU_THIS_PTR idtr.limit;
  Bit32u base_32  = (Bit32u) BX_CPU_THIS_PTR idtr.base;

  Bit32u eaddr = (Bit32u) BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  write_virtual_word_32(i->seg(), eaddr, limit_16);
  write_virtual_dword_32(i->seg(), eaddr+2, base_32);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LGDT_Ms(bxInstruction_c *i)
{
  if (v8086_mode()) {
    BX_ERROR(("LGDT: not recognized in virtual-8086 mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (!real_mode() && CPL!=0) {
    BX_ERROR(("LGDT: CPL!=0 in protected mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  invalidate_prefetch_q();

  Bit32u eaddr = (Bit32u) BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  Bit16u limit_16 = read_virtual_word_32(i->seg(), eaddr);
  Bit32u base_32 = read_virtual_dword_32(i->seg(), eaddr + 2);

  if (i->os32L() == 0) base_32 &= 0x00ffffff; /* ignore upper 8 bits */

  BX_CPU_THIS_PTR gdtr.limit = limit_16;
  BX_CPU_THIS_PTR gdtr.base = base_32;
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LIDT_Ms(bxInstruction_c *i)
{
  if (v8086_mode()) {
    BX_ERROR(("LIDT: not recognized in virtual-8086 mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  if (!real_mode() && CPL!=0) {
    BX_ERROR(("LIDT: CPL!=0 in protected mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  invalidate_prefetch_q();

  Bit32u eaddr = (Bit32u) BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  Bit32u base_32 = read_virtual_dword_32(i->seg(), eaddr + 2);
  Bit16u limit_16 = read_virtual_word_32(i->seg(), eaddr);

  if (i->os32L() == 0) base_32 &= 0x00ffffff; /* ignore upper 8 bits */

  BX_CPU_THIS_PTR idtr.limit = limit_16;
  BX_CPU_THIS_PTR idtr.base = base_32;
}

#if BX_SUPPORT_X86_64

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SGDT64_Ms(bxInstruction_c *i)
{
  Bit16u limit_16 = BX_CPU_THIS_PTR gdtr.limit;
  Bit64u base_64  = BX_CPU_THIS_PTR gdtr.base;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  write_virtual_word_64(i->seg(), eaddr, limit_16);
  write_virtual_qword_64(i->seg(), eaddr+2, base_64);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::SIDT64_Ms(bxInstruction_c *i)
{
  Bit16u limit_16 = BX_CPU_THIS_PTR idtr.limit;
  Bit64u base_64  = BX_CPU_THIS_PTR idtr.base;

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  write_virtual_word_64(i->seg(), eaddr, limit_16);
  write_virtual_qword_64(i->seg(), eaddr+2, base_64);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LGDT64_Ms(bxInstruction_c *i)
{
  if (CPL!=0) {
    BX_ERROR(("LGDT64_Ms: CPL != 0 in long mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  invalidate_prefetch_q();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  Bit64u base_64 = read_virtual_qword_64(i->seg(), eaddr + 2);
  if (! IsCanonical(base_64)) {
    BX_ERROR(("LGDT64_Ms: loaded base64 address is not in canonical form!"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }
  Bit16u limit_16 = read_virtual_word_64(i->seg(), eaddr);

  BX_CPU_THIS_PTR gdtr.limit = limit_16;
  BX_CPU_THIS_PTR gdtr.base = base_64;
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LIDT64_Ms(bxInstruction_c *i)
{
  if (CPL != 0) {
    BX_ERROR(("LIDT64_Ms: CPL != 0 in long mode"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  invalidate_prefetch_q();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  Bit64u base_64 = read_virtual_qword_64(i->seg(), eaddr + 2);
  if (! IsCanonical(base_64)) {
    BX_ERROR(("LIDT64_Ms: loaded base64 address is not in canonical form!"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }
  Bit16u limit_16 = read_virtual_word_64(i->seg(), eaddr);

  BX_CPU_THIS_PTR idtr.limit = limit_16;
  BX_CPU_THIS_PTR idtr.base = base_64;
}

#endif
