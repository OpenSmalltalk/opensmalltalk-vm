/////////////////////////////////////////////////////////////////////////
// $Id: exception.cc,v 1.121 2008/08/27 21:57:40 sshwarts Exp $
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
//
/////////////////////////////////////////////////////////////////////////

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

#include "iodev/iodev.h"

#if BX_SUPPORT_X86_64==0
// Make life easier merging cpu64 & cpu code.
#define RIP EIP
#define RSP ESP
#endif

/* Exception classes.  These are used as indexes into the 'is_exception_OK'
 * array below, and are stored in the 'exception' array also
 */
#define BX_ET_BENIGN       0
#define BX_ET_CONTRIBUTORY 1
#define BX_ET_PAGE_FAULT   2

#define BX_ET_DOUBLE_FAULT 10

static const bx_bool is_exception_OK[3][3] = {
    { 1, 1, 1 }, /* 1st exception is BENIGN */
    { 1, 0, 1 }, /* 1st exception is CONTRIBUTORY */
    { 1, 0, 0 }  /* 1st exception is PAGE_FAULT */
};

#define BX_EXCEPTION_CLASS_TRAP  0
#define BX_EXCEPTION_CLASS_FAULT 1
#define BX_EXCEPTION_CLASS_ABORT 2

#if BX_SUPPORT_X86_64
void BX_CPU_C::long_mode_int(Bit8u vector, bx_bool is_INT, bx_bool is_error_code, Bit16u error_code)
{
  // long mode interrupt
  Bit64u tmp1, tmp2;

  bx_descriptor_t gate_descriptor, cs_descriptor;
  bx_selector_t cs_selector;

  // interrupt vector must be within IDT table limits,
  // else #GP(vector number*16 + 2 + EXT)
  if ((vector*16 + 15) > BX_CPU_THIS_PTR idtr.limit) {
    BX_ERROR(("interrupt(long mode): vector must be within IDT table limits, IDT.limit = 0x%x", BX_CPU_THIS_PTR idtr.limit));
    exception(BX_GP_EXCEPTION, vector*16 + 2, 0);
  }

  access_read_linear(BX_CPU_THIS_PTR idtr.base + vector*16,     8, 0, BX_READ, &tmp1);
  access_read_linear(BX_CPU_THIS_PTR idtr.base + vector*16 + 8, 8, 0, BX_READ, &tmp2);

  if (tmp2 & BX_CONST64(0x00001F0000000000)) {
    BX_ERROR(("interrupt(long mode): IDT entry extended attributes DWORD4 TYPE != 0"));
    exception(BX_GP_EXCEPTION, vector*16 + 2, 0);
  }

  Bit32u dword1 = GET32L(tmp1);
  Bit32u dword2 = GET32H(tmp1);
  Bit32u dword3 = GET32L(tmp2);

  parse_descriptor(dword1, dword2, &gate_descriptor);

  if ((gate_descriptor.valid==0) || gate_descriptor.segment)
  {
    BX_ERROR(("interrupt(long mode): gate descriptor is not valid sys seg"));
    exception(BX_GP_EXCEPTION, vector*16 + 2, 0);
  }

  // descriptor AR byte must indicate interrupt gate, trap gate,
  // or task gate, else #GP(vector*16 + 2 + EXT)
  if (gate_descriptor.type != BX_386_INTERRUPT_GATE &&
      gate_descriptor.type != BX_386_TRAP_GATE)
  {
    BX_ERROR(("interrupt(long mode): unsupported gate type %u",
        (unsigned) gate_descriptor.type));
    exception(BX_GP_EXCEPTION, vector*16 + 2, 0);
  }

  // if software interrupt, then gate descripor DPL must be >= CPL,
  // else #GP(vector * 16 + 2 + EXT)
  if (is_INT && (gate_descriptor.dpl < CPL))
  {
    BX_ERROR(("interrupt(long mode): is_INT && (dpl < CPL)"));
    exception(BX_GP_EXCEPTION, vector*16 + 2, 0);
  }

  // Gate must be present, else #NP(vector * 16 + 2 + EXT)
  if (! IS_PRESENT(gate_descriptor)) {
    BX_ERROR(("interrupt(long mode): p == 0"));
    exception(BX_NP_EXCEPTION, vector*16 + 2, 0);
  }

  Bit16u gate_dest_selector = gate_descriptor.u.gate.dest_selector;
  Bit64u gate_dest_offset   = ((Bit64u)dword3 << 32) |
                       gate_descriptor.u.gate.dest_offset;

  unsigned ist = gate_descriptor.u.gate.param_count & 0x7;

  // examine CS selector and descriptor given in gate descriptor
  // selector must be non-null else #GP(EXT)
  if ((gate_dest_selector & 0xfffc) == 0) {
    BX_ERROR(("int_trap_gate(long mode): selector null"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  parse_selector(gate_dest_selector, &cs_selector);

  // selector must be within its descriptor table limits
  // else #GP(selector+EXT)
  fetch_raw_descriptor(&cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &cs_descriptor);

  // descriptor AR byte must indicate code seg
  // and code segment descriptor DPL<=CPL, else #GP(selector+EXT)
  if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
      IS_DATA_SEGMENT(cs_descriptor.type) ||
      cs_descriptor.dpl>CPL)
  {
    BX_ERROR(("interrupt(long mode): not accessable or not code segment"));
    exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
  }

  // check that it's a 64 bit segment
  if (! IS_LONG64_SEGMENT(cs_descriptor) || cs_descriptor.u.segment.d_b)
  {
    BX_ERROR(("interrupt(long mode): must be 64 bit segment"));
    exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
  }

  // segment must be present, else #NP(selector + EXT)
  if (! IS_PRESENT(cs_descriptor)) {
    BX_ERROR(("interrupt(long mode): segment not present"));
    exception(BX_NP_EXCEPTION, cs_selector.value & 0xfffc, 0);
  }

  // if code segment is non-conforming and DPL < CPL then
  // INTERRUPT TO INNER PRIVILEGE:
  if (IS_CODE_SEGMENT_NON_CONFORMING(cs_descriptor.type) && cs_descriptor.dpl<CPL)
  {
    Bit64u RSP_for_cpl_x;

    BX_DEBUG(("interrupt(long mode): INTERRUPT TO INNER PRIVILEGE"));

    // check selector and descriptor for new stack in current TSS
    if (ist != 0) {
      BX_DEBUG(("interrupt(long mode): trap to IST, vector = %d", ist));
      get_RSP_from_TSS(ist+3, &RSP_for_cpl_x);
    }
    else {
      get_RSP_from_TSS(cs_descriptor.dpl, &RSP_for_cpl_x);
    }

    RSP_for_cpl_x &= BX_CONST64(0xfffffffffffffff0);

    Bit64u old_CS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
    Bit64u old_RIP = RIP;
    Bit64u old_SS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
    Bit64u old_RSP = RSP;

    if (! IsCanonical(RSP_for_cpl_x)) {
      // #SS(selector) when changing priviledge level
      BX_ERROR(("interrupt(long mode): canonical address failure %08x%08x",
         GET32H(RSP_for_cpl_x), GET32L(RSP_for_cpl_x)));
      exception(BX_SS_EXCEPTION, old_SS & 0xfffc, 0);
    }

    // push old stack long pointer onto new stack
    write_new_stack_qword_64(RSP_for_cpl_x -  8, cs_descriptor.dpl, old_SS);
    write_new_stack_qword_64(RSP_for_cpl_x - 16, cs_descriptor.dpl, old_RSP);
    write_new_stack_qword_64(RSP_for_cpl_x - 24, cs_descriptor.dpl, read_eflags());
    // push long pointer to return address onto new stack
    write_new_stack_qword_64(RSP_for_cpl_x - 32, cs_descriptor.dpl, old_CS);
    write_new_stack_qword_64(RSP_for_cpl_x - 40, cs_descriptor.dpl, old_RIP);
    RSP_for_cpl_x -= 40;

    if (is_error_code) {
      RSP_for_cpl_x -= 8;
      write_new_stack_qword_64(RSP_for_cpl_x, cs_descriptor.dpl, error_code);
    }

    bx_selector_t ss_selector;
    bx_descriptor_t ss_descriptor;

    // set up a null descriptor
    parse_selector(0, &ss_selector);
    parse_descriptor(0, 0, &ss_descriptor);

    // load CS:RIP (guaranteed to be in 64 bit mode)
    branch_far64(&cs_selector, &cs_descriptor, gate_dest_offset, cs_descriptor.dpl);

    // set up null SS descriptor
    load_ss(&ss_selector, &ss_descriptor, cs_descriptor.dpl);
    RSP = RSP_for_cpl_x;

    // if INTERRUPT GATE set IF to 0
    if (!(gate_descriptor.type & 1)) // even is int-gate
      BX_CPU_THIS_PTR clear_IF();
    BX_CPU_THIS_PTR clear_TF();
    BX_CPU_THIS_PTR clear_VM();
    BX_CPU_THIS_PTR clear_RF();
    BX_CPU_THIS_PTR clear_NT();
    return;
  }

  // if code segment is conforming OR code segment DPL = CPL then
  // INTERRUPT TO SAME PRIVILEGE LEVEL:
  if (IS_CODE_SEGMENT_CONFORMING(cs_descriptor.type) || cs_descriptor.dpl==CPL)
  {
    BX_DEBUG(("interrupt(long mode): INTERRUPT TO SAME PRIVILEGE"));

    Bit64u old_RSP = RSP;

    // check selector and descriptor for new stack in current TSS
    if (ist > 0) {
      BX_DEBUG(("interrupt(long mode): trap to IST, vector = %d", ist));
      get_RSP_from_TSS(ist+3, &RSP);
    }

    // align stack
    RSP &= BX_CONST64(0xfffffffffffffff0);

    // push flags onto stack
    // push current CS selector onto stack
    // push return offset onto stack
    write_new_stack_qword_64(RSP - 8,  cs_descriptor.dpl,
         BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value);
    write_new_stack_qword_64(RSP - 16, cs_descriptor.dpl, old_RSP);
    write_new_stack_qword_64(RSP - 24, cs_descriptor.dpl, read_eflags());
    write_new_stack_qword_64(RSP - 32, cs_descriptor.dpl,
         BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
    write_new_stack_qword_64(RSP - 40, cs_descriptor.dpl, RIP);
    RSP -= 40;

    if (is_error_code) {
      RSP -= 8;
      write_new_stack_qword_64(RSP, cs_descriptor.dpl, error_code);
    }

    // set the RPL field of CS to CPL
    branch_far64(&cs_selector, &cs_descriptor, gate_dest_offset, CPL);

    // if interrupt gate then set IF to 0
    if (!(gate_descriptor.type & 1)) // even is int-gate
      BX_CPU_THIS_PTR clear_IF();
    BX_CPU_THIS_PTR clear_TF();
    BX_CPU_THIS_PTR clear_VM();
    BX_CPU_THIS_PTR clear_RF();
    BX_CPU_THIS_PTR clear_NT();
    return;
  }

  // else #GP(CS selector + ext)
  BX_ERROR(("interrupt(long mode): bad descriptor type=%u, descriptor.dpl=%u, CPL=%u",
    (unsigned) cs_descriptor.type, (unsigned) cs_descriptor.dpl, (unsigned) CPL));
  BX_ERROR(("cs.segment = %u", (unsigned) cs_descriptor.segment));
  exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
}
#endif

void BX_CPU_C::protected_mode_int(Bit8u vector, bx_bool is_INT, bx_bool is_error_code, Bit16u error_code)
{
  // protected mode interrupt
  Bit32u dword1, dword2;
  bx_descriptor_t gate_descriptor, cs_descriptor;
  bx_selector_t cs_selector;

  Bit16u raw_tss_selector;
  bx_selector_t   tss_selector;
  bx_descriptor_t tss_descriptor;

  Bit16u gate_dest_selector;
  Bit32u gate_dest_offset;

  // interrupt vector must be within IDT table limits,
  // else #GP(vector number*8 + 2 + EXT)
  if ((vector*8 + 7) > BX_CPU_THIS_PTR idtr.limit) {
    BX_DEBUG(("interrupt(): vector must be within IDT table limits, IDT.limit = 0x%x", BX_CPU_THIS_PTR idtr.limit));
    exception(BX_GP_EXCEPTION, vector*8 + 2, 0);
  }

  // descriptor AR byte must indicate interrupt gate, trap gate,
  // or task gate, else #GP(vector*8 + 2 + EXT)
  access_read_linear(BX_CPU_THIS_PTR idtr.base + vector*8,     4, 0,
      BX_READ, &dword1);
  access_read_linear(BX_CPU_THIS_PTR idtr.base + vector*8 + 4, 4, 0,
      BX_READ, &dword2);

  parse_descriptor(dword1, dword2, &gate_descriptor);

  if ((gate_descriptor.valid==0) || gate_descriptor.segment) {
    BX_DEBUG(("interrupt(): gate descriptor is not valid sys seg (vector=0x%02x)", vector));
    exception(BX_GP_EXCEPTION, vector*8 + 2, 0);
  }

  switch (gate_descriptor.type) {
  case BX_TASK_GATE:
  case BX_286_INTERRUPT_GATE:
  case BX_286_TRAP_GATE:
  case BX_386_INTERRUPT_GATE:
  case BX_386_TRAP_GATE:
    break;
  default:
    BX_ERROR(("interrupt(): gate.type(%u) != {5,6,7,14,15}",
      (unsigned) gate_descriptor.type));
    exception(BX_GP_EXCEPTION, vector*8 + 2, 0);
  }

  // if software interrupt, then gate descripor DPL must be >= CPL,
  // else #GP(vector * 8 + 2 + EXT)
  if (is_INT && (gate_descriptor.dpl < CPL)) {
    BX_DEBUG(("interrupt(): is_INT && (dpl < CPL)"));
    exception(BX_GP_EXCEPTION, vector*8 + 2, 0);
  }

  // Gate must be present, else #NP(vector * 8 + 2 + EXT)
  if (! IS_PRESENT(gate_descriptor)) {
    BX_ERROR(("interrupt(): gate not present"));
    exception(BX_NP_EXCEPTION, vector*8 + 2, 0);
  }

  switch (gate_descriptor.type) {
  case BX_TASK_GATE:
    // examine selector to TSS, given in task gate descriptor
    raw_tss_selector = gate_descriptor.u.taskgate.tss_selector;
    parse_selector(raw_tss_selector, &tss_selector);

    // must specify global in the local/global bit,
    //      else #GP(TSS selector)
    if (tss_selector.ti) {
      BX_ERROR(("interrupt: tss_selector.ti=1 from gate descriptor - #GP(tss_selector)"));
      exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
    }

    // index must be within GDT limits, else #TS(TSS selector)
    fetch_raw_descriptor(&tss_selector, &dword1, &dword2, BX_GP_EXCEPTION);

    parse_descriptor(dword1, dword2, &tss_descriptor);

    // AR byte must specify available TSS,
    //   else #GP(TSS selector)
    if (tss_descriptor.valid==0 || tss_descriptor.segment) {
      BX_ERROR(("exception: TSS selector points to invalid or bad TSS - #GP(tss_selector)"));
      exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
    }

    if (tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_286_TSS &&
        tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_386_TSS)
    {
      BX_ERROR(("exception: TSS selector points to bad TSS - #GP(tss_selector)"));
      exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
    }

    // TSS must be present, else #NP(TSS selector)
    if (! IS_PRESENT(tss_descriptor)) {
      BX_ERROR(("exception: TSS descriptor.p == 0"));
      exception(BX_NP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
    }

    // switch tasks with nesting to TSS
    task_switch(&tss_selector, &tss_descriptor,
                    BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

    // if interrupt was caused by fault with error code
    //   stack limits must allow push of 2 more bytes, else #SS(0)
    // push error code onto stack

    if (is_error_code) {
      if (tss_descriptor.type >= 9) // TSS386
        push_32(error_code);
      else
        push_16(error_code);
    }

    // instruction pointer must be in CS limit, else #GP(0)
    if (EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
      BX_ERROR(("exception(): EIP > CS.limit"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }

    return;

  case BX_286_INTERRUPT_GATE:
  case BX_286_TRAP_GATE:
  case BX_386_INTERRUPT_GATE:
  case BX_386_TRAP_GATE:
    gate_dest_selector = gate_descriptor.u.gate.dest_selector;
    gate_dest_offset   = gate_descriptor.u.gate.dest_offset;

    // examine CS selector and descriptor given in gate descriptor
    // selector must be non-null else #GP(EXT)
    if ((gate_dest_selector & 0xfffc) == 0) {
      BX_ERROR(("int_trap_gate(): selector null"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }

    parse_selector(gate_dest_selector, &cs_selector);

    // selector must be within its descriptor table limits
    // else #GP(selector+EXT)
    fetch_raw_descriptor(&cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
    parse_descriptor(dword1, dword2, &cs_descriptor);

    // descriptor AR byte must indicate code seg
    // and code segment descriptor DPL<=CPL, else #GP(selector+EXT)
    if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
        IS_DATA_SEGMENT(cs_descriptor.type) ||
        cs_descriptor.dpl>CPL)
    {
      BX_ERROR(("interrupt(): not accessable or not code segment cs=0x%04x", cs_selector.value));
      exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
    }

    // segment must be present, else #NP(selector + EXT)
    if (! IS_PRESENT(cs_descriptor)) {
      BX_ERROR(("interrupt(): segment not present"));
      exception(BX_NP_EXCEPTION, cs_selector.value & 0xfffc, 0);
    }

    // if code segment is non-conforming and DPL < CPL then
    // INTERRUPT TO INNER PRIVILEGE:
    if(IS_CODE_SEGMENT_NON_CONFORMING(cs_descriptor.type) && (cs_descriptor.dpl < CPL))
    {
      Bit16u old_SS, old_CS, SS_for_cpl_x;
      Bit32u ESP_for_cpl_x, old_EIP, old_ESP;
      bx_descriptor_t ss_descriptor;
      bx_selector_t   ss_selector;
      int is_v8086_mode = v8086_mode();

      BX_DEBUG(("interrupt(): INTERRUPT TO INNER PRIVILEGE"));

      if (is_v8086_mode && cs_descriptor.dpl != 0) {
        // if code segment DPL != 0 then #GP(new code segment selector)
        BX_ERROR(("interrupt(): code segment DPL != 0 in v8086 mode"));
        exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
      }

      // check selector and descriptor for new stack in current TSS
      get_SS_ESP_from_TSS(cs_descriptor.dpl,
                              &SS_for_cpl_x, &ESP_for_cpl_x);

      // Selector must be non-null else #TS(EXT)
      if ((SS_for_cpl_x & 0xfffc) == 0) {
        BX_ERROR(("interrupt(): SS selector null"));
        exception(BX_TS_EXCEPTION, 0, 0); /* TS(ext) */
      }

      // selector index must be within its descriptor table limits
      // else #TS(SS selector + EXT)
      parse_selector(SS_for_cpl_x, &ss_selector);
      // fetch 2 dwords of descriptor; call handles out of limits checks
      fetch_raw_descriptor(&ss_selector, &dword1, &dword2, BX_TS_EXCEPTION);
      parse_descriptor(dword1, dword2, &ss_descriptor);

      // selector rpl must = dpl of code segment,
      // else #TS(SS selector + ext)
      if (ss_selector.rpl != cs_descriptor.dpl) {
        BX_ERROR(("interrupt(): SS.rpl != CS.dpl"));
        exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
      }

      // stack seg DPL must = DPL of code segment,
      // else #TS(SS selector + ext)
      if (ss_descriptor.dpl != cs_descriptor.dpl) {
        BX_ERROR(("interrupt(): SS.dpl != CS.dpl"));
        exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
      }

      // descriptor must indicate writable data segment,
      // else #TS(SS selector + EXT)
      if (ss_descriptor.valid==0 || ss_descriptor.segment==0 ||
           IS_CODE_SEGMENT(ss_descriptor.type) ||
          !IS_DATA_SEGMENT_WRITEABLE(ss_descriptor.type))
      {
        BX_ERROR(("interrupt(): SS is not writable data segment"));
        exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
      }

      // seg must be present, else #SS(SS selector + ext)
      if (! IS_PRESENT(ss_descriptor)) {
        BX_ERROR(("interrupt(): SS not present"));
        exception(BX_SS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
      }

      // IP must be within CS segment boundaries, else #GP(0)
      if (gate_dest_offset > cs_descriptor.u.segment.limit_scaled) {
        BX_DEBUG(("interrupt(): gate EIP > CS.limit"));
        exception(BX_GP_EXCEPTION, 0, 0);
      }

      old_ESP = ESP;
      old_SS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
      old_EIP = EIP;
      old_CS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;

      // Prepare new stack segment
      bx_segment_reg_t new_stack;
      new_stack.selector = ss_selector;
      new_stack.cache = ss_descriptor;
      new_stack.selector.rpl = cs_descriptor.dpl;
      // add cpl to the selector value
      new_stack.selector.value = (0xfffc & new_stack.selector.value) |
        new_stack.selector.rpl;

      if (ss_descriptor.u.segment.d_b) {
        Bit32u temp_ESP = ESP_for_cpl_x;

        if (is_v8086_mode)
        {
          if (gate_descriptor.type>=14) { // 386 int/trap gate
            write_new_stack_dword_32(&new_stack, temp_ESP-4,  cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value);
            write_new_stack_dword_32(&new_stack, temp_ESP-8,  cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value);
            write_new_stack_dword_32(&new_stack, temp_ESP-12, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value);
            write_new_stack_dword_32(&new_stack, temp_ESP-16, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value);
            temp_ESP -= 16;
          }
          else {
            write_new_stack_word_32(&new_stack, temp_ESP-2, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value);
            write_new_stack_word_32(&new_stack, temp_ESP-4, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value);
            write_new_stack_word_32(&new_stack, temp_ESP-6, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value);
            write_new_stack_word_32(&new_stack, temp_ESP-8, cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value);
            temp_ESP -= 8;
          }
        }

        if (gate_descriptor.type>=14) { // 386 int/trap gate
          // push long pointer to old stack onto new stack
          write_new_stack_dword_32(&new_stack, temp_ESP-4,  cs_descriptor.dpl, old_SS);
          write_new_stack_dword_32(&new_stack, temp_ESP-8,  cs_descriptor.dpl, old_ESP);
          write_new_stack_dword_32(&new_stack, temp_ESP-12, cs_descriptor.dpl, read_eflags());
          write_new_stack_dword_32(&new_stack, temp_ESP-16, cs_descriptor.dpl, old_CS);
          write_new_stack_dword_32(&new_stack, temp_ESP-20, cs_descriptor.dpl, old_EIP);
          temp_ESP -= 20;

          if (is_error_code) {
            temp_ESP -= 4;
            write_new_stack_dword_32(&new_stack, temp_ESP, cs_descriptor.dpl, error_code);
          }
        }
        else {                          // 286 int/trap gate
          // push long pointer to old stack onto new stack
          write_new_stack_word_32(&new_stack, temp_ESP-2,  cs_descriptor.dpl, old_SS);
          write_new_stack_word_32(&new_stack, temp_ESP-4,  cs_descriptor.dpl, (Bit16u) old_ESP);
          write_new_stack_word_32(&new_stack, temp_ESP-6,  cs_descriptor.dpl, (Bit16u) read_eflags());
          write_new_stack_word_32(&new_stack, temp_ESP-8,  cs_descriptor.dpl, old_CS);
          write_new_stack_word_32(&new_stack, temp_ESP-10, cs_descriptor.dpl, (Bit16u) old_EIP);
          temp_ESP -= 10;

          if (is_error_code) {
            temp_ESP -= 2;
            write_new_stack_word_32(&new_stack, temp_ESP, cs_descriptor.dpl, error_code);
          }
        }

        ESP = temp_ESP;
      }
      else {
        Bit16u temp_SP = (Bit16u) ESP_for_cpl_x;

        if (is_v8086_mode)
        {
          if (gate_descriptor.type>=14) { // 386 int/trap gate
            write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-4),  cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value);
            write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-8),  cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value);
            write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-12), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value);
            write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-16), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value);
            temp_SP -= 16;
          }
          else {
            write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-2), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value);
            write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-4), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value);
            write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-6), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value);
            write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-8), cs_descriptor.dpl,
                BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value);
            temp_SP -= 8;
          }
        }

        if (gate_descriptor.type>=14) { // 386 int/trap gate
          // push long pointer to old stack onto new stack
          write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-4),  cs_descriptor.dpl, old_SS);
          write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-8),  cs_descriptor.dpl, old_ESP);
          write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-12), cs_descriptor.dpl, read_eflags());
          write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-16), cs_descriptor.dpl, old_CS);
          write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-20), cs_descriptor.dpl, old_EIP);
          temp_SP -= 20;

          if (is_error_code) {
            temp_SP -= 4;
            write_new_stack_dword_32(&new_stack, temp_SP, cs_descriptor.dpl, error_code);
          }
        }
        else {                          // 286 int/trap gate
          // push long pointer to old stack onto new stack
          write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-2),  cs_descriptor.dpl, old_SS);
          write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-4),  cs_descriptor.dpl, (Bit16u) old_ESP);
          write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-6),  cs_descriptor.dpl, (Bit16u) read_eflags());
          write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-8),  cs_descriptor.dpl, old_CS);
          write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-10), cs_descriptor.dpl, (Bit16u) old_EIP);
          temp_SP -= 10;

          if (is_error_code) {
            temp_SP -= 2;
            write_new_stack_word_32(&new_stack, temp_SP, cs_descriptor.dpl, error_code);
          }
        }

        SP = temp_SP;
      }

      // load new SS:eSP values from TSS
      load_ss(&ss_selector, &ss_descriptor, cs_descriptor.dpl);

      // load new CS:eIP values from gate
      // set CPL to new code segment DPL
      // set RPL of CS to CPL
      load_cs(&cs_selector, &cs_descriptor, cs_descriptor.dpl);
      EIP = gate_dest_offset;

      // if INTERRUPT GATE set IF to 0
      if (!(gate_descriptor.type & 1)) // even is int-gate
        BX_CPU_THIS_PTR clear_IF();
      BX_CPU_THIS_PTR clear_TF();
      BX_CPU_THIS_PTR clear_VM();
      BX_CPU_THIS_PTR clear_RF();
      BX_CPU_THIS_PTR clear_NT();

      if (is_v8086_mode)
      {
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].cache.valid = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].cache.valid = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].cache.valid = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].cache.valid = 0;
        BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value = 0;
      }

      return;
    }

    if (v8086_mode()) {
      // if code segment DPL != 0 then #GP(new code segment selector)
      BX_ERROR(("interrupt(): code seg DPL != 0 in v8086 mode"));
      exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
    }

    // if code segment is conforming OR code segment DPL = CPL then
    // INTERRUPT TO SAME PRIVILEGE LEVEL:
    if (IS_CODE_SEGMENT_CONFORMING(cs_descriptor.type) || cs_descriptor.dpl==CPL)
    {
      BX_DEBUG(("int_trap_gate286(): INTERRUPT TO SAME PRIVILEGE"));

      // EIP must be in CS limit else #GP(0)
      if (gate_dest_offset > cs_descriptor.u.segment.limit_scaled) {
        BX_ERROR(("interrupt(): IP > cs descriptor limit"));
        exception(BX_GP_EXCEPTION, 0, 0);
      }

      // push flags onto stack
      // push current CS selector onto stack
      // push return offset onto stack
      if (gate_descriptor.type >= 14) { // 386 gate
        push_32(read_eflags());
        push_32(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        push_32(EIP);
        if (is_error_code)
          push_32(error_code);
      }
      else { // 286 gate
        push_16((Bit16u) read_eflags());
        push_16(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        push_16(IP);
        if (is_error_code)
          push_16(error_code);
      }

      // load CS:IP from gate
      // load CS descriptor
      // set the RPL field of CS to CPL
      load_cs(&cs_selector, &cs_descriptor, CPL);
      EIP = gate_dest_offset;

      // if interrupt gate then set IF to 0
      if (!(gate_descriptor.type & 1)) // even is int-gate
        BX_CPU_THIS_PTR clear_IF();
      BX_CPU_THIS_PTR clear_TF();
      BX_CPU_THIS_PTR clear_NT();
      BX_CPU_THIS_PTR clear_VM();
      BX_CPU_THIS_PTR clear_RF();
      return;
    }

    // else #GP(CS selector + ext)
    BX_DEBUG(("interrupt: bad descriptor"));
    BX_DEBUG(("type=%u, descriptor.dpl=%u, CPL=%u",
          (unsigned) cs_descriptor.type, (unsigned) cs_descriptor.dpl,
          (unsigned) CPL));
    BX_DEBUG(("cs.segment = %u", (unsigned) cs_descriptor.segment));
    exception(BX_GP_EXCEPTION, cs_selector.value & 0xfffc, 0);
    break;

  default:
    BX_PANIC(("bad descriptor type in interrupt()!"));
    break;
  }
}

void BX_CPU_C::real_mode_int(Bit8u vector, bx_bool is_INT, bx_bool is_error_code, Bit16u error_code)
{
  // real mode interrupt
  Bit16u cs_selector, ip;

  if ((vector*4+3) > BX_CPU_THIS_PTR idtr.limit) {
    BX_ERROR(("interrupt(real mode) vector > idtr.limit"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  push_16((Bit16u) read_eflags());

  cs_selector = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
  push_16(cs_selector);
  ip = EIP;
  push_16(ip);

  access_read_linear(BX_CPU_THIS_PTR idtr.base + 4 * vector,     2, 0, BX_READ, &ip);
  EIP = (Bit32u) ip;
  access_read_linear(BX_CPU_THIS_PTR idtr.base + 4 * vector + 2, 2, 0, BX_READ, &cs_selector);
  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_selector);

  /* INT affects the following flags: I,T */
  BX_CPU_THIS_PTR clear_IF();
  BX_CPU_THIS_PTR clear_TF();
#if BX_CPU_LEVEL >= 4
  BX_CPU_THIS_PTR clear_AC();
#endif
  BX_CPU_THIS_PTR clear_RF();
}

void BX_CPU_C::interrupt(Bit8u vector, bx_bool is_INT, bx_bool is_error_code, Bit16u error_code)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_intsig;
#if BX_DEBUG_LINUX
  if (bx_dbg.linux_syscall) {
    if (vector == 0x80) bx_dbg_linux_syscall(BX_CPU_ID);
  }
#endif
  bx_dbg_interrupt(BX_CPU_ID, vector, error_code);
#endif

  BX_DEBUG(("interrupt(): vector = %u, INT = %u, EXT = %u",
      (unsigned) vector, (unsigned) is_INT, (unsigned) BX_CPU_THIS_PTR EXT));

  BX_INSTR_INTERRUPT(BX_CPU_ID, vector);
  invalidate_prefetch_q();

  // Discard any traps and inhibits for new context; traps will
  // resume upon return.
  BX_CPU_THIS_PTR debug_trap = 0;
  BX_CPU_THIS_PTR inhibit_mask = 0;

  BX_CPU_THIS_PTR save_cs = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS];
  BX_CPU_THIS_PTR save_ss = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS];
  BX_CPU_THIS_PTR save_eip = RIP;
  BX_CPU_THIS_PTR save_esp = RSP;

#if BX_SUPPORT_X86_64
  if (long_mode()) {
    long_mode_int(vector, is_INT, is_error_code, error_code);
    return;
  }
#endif

  if(real_mode()) {
    real_mode_int(vector, is_INT, is_error_code, error_code);
  }
  else {
    protected_mode_int(vector, is_INT, is_error_code, error_code);
  }
}

// vector:     0..255: vector in IDT
// error_code: if exception generates and error, push this error code
// trap:       override exception class to TRAP
void BX_CPU_C::exception(unsigned vector, Bit16u error_code, bx_bool trap)
{
  unsigned exception_type = 0, exception_class = BX_EXCEPTION_CLASS_FAULT;
  bx_bool push_error = 0;

  BX_INSTR_EXCEPTION(BX_CPU_ID, vector);

#if BX_DEBUGGER
  bx_dbg_exception(BX_CPU_ID, vector, error_code);
#endif

  BX_DEBUG(("exception(0x%02x): error_code=%04x", vector, error_code));

  // if not initial error, restore previous register values from
  // previous attempt to handle exception
  if (BX_CPU_THIS_PTR errorno) {
    BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS] = BX_CPU_THIS_PTR save_cs;
    BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS] = BX_CPU_THIS_PTR save_ss;
    RIP = BX_CPU_THIS_PTR save_eip;
    RSP = BX_CPU_THIS_PTR save_esp;
  }

  if (BX_CPU_THIS_PTR errorno > 0) {
    if (BX_CPU_THIS_PTR errorno > 2 || BX_CPU_THIS_PTR curr_exception == BX_ET_DOUBLE_FAULT) {
      debug(BX_CPU_THIS_PTR prev_rip); // print debug information to the log
#if BX_DEBUGGER
      // trap into debugger (similar as done when PANIC occured)
      bx_debug_break();
#endif
#if !COG // No SIM in COG
      if (SIM->get_param_bool(BXPN_RESET_ON_TRIPLE_FAULT)->get()) {
        BX_ERROR(("exception(): 3rd (%d) exception with no resolution, shutdown status is %02xh, resetting", vector, DEV_cmos_get_reg(0x0f)));
        bx_pc_system.Reset(BX_RESET_SOFTWARE);
      }
      else {
#endif
        BX_PANIC(("exception(): 3rd (%d) exception with no resolution", vector));
        BX_ERROR(("WARNING: Any simulation after this point is completely bogus !"));
        shutdown();
#if !COG // No SIM in COG
      }
#endif
      longjmp(BX_CPU_THIS_PTR jmp_buf_env, 1); // go back to main decode loop
    }
  }

  // note: fault-class exceptions _except_ #DB set RF in
  //       eflags image.

  switch (vector) {
    case BX_DE_EXCEPTION: // DIV by 0
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_CONTRIBUTORY;
      break;
    case BX_DB_EXCEPTION: // debug exceptions
      push_error = 0;
      // Instruction fetch breakpoint  - FAULT
      // Data read or write breakpoint - TRAP
      // I/O read or write breakpoint  - TRAP
      // General detect condition      - FAULT
      // Single-step                   - TRAP
      // Task-switch                   - TRAP
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
    case 2:               // NMI
      push_error = 0;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_BP_EXCEPTION: // breakpoint
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_TRAP;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_OF_EXCEPTION: // overflow
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_TRAP;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_BR_EXCEPTION: // bounds check
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_UD_EXCEPTION: // invalid opcode
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_NM_EXCEPTION: // device not available
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
    case BX_DF_EXCEPTION: // double fault
      push_error = 1;
      error_code = 0;
      exception_class = BX_EXCEPTION_CLASS_ABORT;
      exception_type  = BX_ET_DOUBLE_FAULT;
      break;
    case 9:               // coprocessor segment overrun (286,386 only)
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_ABORT;
      exception_type  = BX_ET_BENIGN;
      BX_PANIC(("exception(9): unfinished"));
      break;
    case BX_TS_EXCEPTION: // invalid TSS
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_CONTRIBUTORY;
      break;
    case BX_NP_EXCEPTION: // segment not present
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_CONTRIBUTORY;
      break;
    case BX_SS_EXCEPTION: // stack fault
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_CONTRIBUTORY;
      break;
    case BX_GP_EXCEPTION: // general protection
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_CONTRIBUTORY;
      break;
    case BX_PF_EXCEPTION: // page fault
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_PAGE_FAULT;
      break;
    case 15:              // reserved
      BX_PANIC(("exception(15): reserved"));
      push_error = 0;
      exception_type = 0;
      break;
    case BX_MF_EXCEPTION: // floating-point error
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
#if BX_CPU_LEVEL >= 4
    case BX_AC_EXCEPTION: // alignment check
      push_error = 1;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
#endif
#if BX_CPU_LEVEL >= 5
    case BX_MC_EXCEPTION: // machine check
      BX_PANIC(("exception(): machine-check, vector 18 not implemented"));
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_ABORT;
      exception_type  = BX_ET_BENIGN;
      break;
#if BX_SUPPORT_SSE
    case BX_XM_EXCEPTION: // SIMD Floating-Point exception
      push_error = 0;
      exception_class = BX_EXCEPTION_CLASS_FAULT;
      exception_type  = BX_ET_BENIGN;
      break;
#endif
#endif
    default:
      BX_PANIC(("exception(%u): bad vector", (unsigned) vector));
      exception_type = BX_ET_BENIGN;
      push_error = 0;    // keep compiler happy for now
      break;
  }

  if (trap) {
    exception_class = BX_EXCEPTION_CLASS_TRAP;
  }
  else {
    if (exception_class == BX_EXCEPTION_CLASS_FAULT)
    {
      // restore RIP/RSP to value before error occurred
      RIP = BX_CPU_THIS_PTR prev_rip;
      if (BX_CPU_THIS_PTR speculative_rsp)
        RSP = BX_CPU_THIS_PTR prev_rsp;

      if (vector != BX_DB_EXCEPTION) BX_CPU_THIS_PTR assert_RF();
    }
  }

  // clear GD flag in the DR7 prior entering debug exception handler
  if (vector == BX_DB_EXCEPTION)
    BX_CPU_THIS_PTR dr7 &= ~0x00002000;

  if (exception_type != BX_ET_PAGE_FAULT) {
    // Page faults have different format
    error_code = (error_code & 0xfffe) | BX_CPU_THIS_PTR EXT;
  }
  else {
    // FIXME: special format error returned for page faults ?
  }
  BX_CPU_THIS_PTR EXT = 1;

  /* if we've already had 1st exception, see if 2nd causes a
   * Double Fault instead.  Otherwise, just record 1st exception
   */
  if (BX_CPU_THIS_PTR errorno > 0 && exception_type != BX_ET_DOUBLE_FAULT) {
    if (! is_exception_OK[BX_CPU_THIS_PTR curr_exception][exception_type]) {
      exception(BX_DF_EXCEPTION, 0, 0);
    }
  }

  BX_CPU_THIS_PTR curr_exception = exception_type;
  BX_CPU_THIS_PTR errorno++;

  if (real_mode()) {
    // not INT, no error code pushed
    BX_CPU_THIS_PTR interrupt(vector, 0, 0, 0);
    BX_CPU_THIS_PTR errorno = 0; // error resolved
    longjmp(BX_CPU_THIS_PTR jmp_buf_env, 1); // go back to main decode loop
  }
  else {
    BX_CPU_THIS_PTR interrupt(vector, 0, push_error, error_code);
    BX_CPU_THIS_PTR errorno = 0; // error resolved
    longjmp(BX_CPU_THIS_PTR jmp_buf_env, 1); // go back to main decode loop
  }
}
