////////////////////////////////////////////////////////////////////////
// $Id: jmp_far.cc,v 1.16 2008/05/25 15:53:29 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2005 Stanislav Shwartsman
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
////////////////////////////////////////////////////////////////////////

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

#if BX_SUPPORT_X86_64==0
// Make life easier merging cpu64 & cpu code.
#define RIP EIP
#endif

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::jump_protected(bxInstruction_c *i, Bit16u cs_raw, bx_address disp)
{
  bx_descriptor_t  descriptor;
  bx_selector_t    selector;
  Bit32u dword1, dword2;

  /* destination selector is not null else #GP(0) */
  if ((cs_raw & 0xfffc) == 0) {
    BX_ERROR(("jump_protected: cs == 0"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  parse_selector(cs_raw, &selector);

  /* destination selector index is within its descriptor table
     limits else #GP(selector) */
  fetch_raw_descriptor(&selector, &dword1, &dword2, BX_GP_EXCEPTION);

  /* examine AR byte of destination selector for legal values: */
  parse_descriptor(dword1, dword2, &descriptor);

  if (descriptor.segment) {
    check_cs(&descriptor, cs_raw, BX_SELECTOR_RPL(cs_raw), CPL);
    branch_far64(&selector, &descriptor, disp, CPL);
    return;
  }
  else {
    // call gate DPL must be >= CPL else #GP(gate selector)
    if (descriptor.dpl < CPL) {
      BX_ERROR(("jump_protected: call gate.dpl < CPL"));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

    // call gate DPL must be >= gate selector RPL else #GP(gate selector)
    if (descriptor.dpl < selector.rpl) {
      BX_ERROR(("jump_protected: call gate.dpl < selector.rpl"));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

#if BX_SUPPORT_X86_64
    if (long_mode()) {
      if (descriptor.type != BX_386_CALL_GATE) {
        BX_ERROR(("jump_protected: gate type %u unsupported in long mode", (unsigned) descriptor.type));
        exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
      }
    }
    else
#endif
    {
      switch (descriptor.type) {
        case BX_SYS_SEGMENT_AVAIL_286_TSS:
        case BX_SYS_SEGMENT_AVAIL_386_TSS:
        case BX_286_CALL_GATE:
        case BX_386_CALL_GATE:
        case BX_TASK_GATE:
          break;
        default:
          BX_ERROR(("jump_protected: gate type %u unsupported", (unsigned) descriptor.type));
         exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
      }
    }

    // task gate must be present else #NP(gate selector)
    if (! IS_PRESENT(descriptor)) {
      BX_ERROR(("jump_protected: call gate.p == 0"));
      exception(BX_NP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

#if BX_SUPPORT_X86_64
    if (long_mode()) {
      jmp_call_gate64(&selector);
      return;
    }
#endif

    switch (descriptor.type) {
      case BX_SYS_SEGMENT_AVAIL_286_TSS:
      case BX_SYS_SEGMENT_AVAIL_386_TSS:

        if (descriptor.type==BX_SYS_SEGMENT_AVAIL_286_TSS)
          BX_DEBUG(("jump_protected: jump to 286 TSS"));
        else
          BX_DEBUG(("jump_protected: jump to 386 TSS"));

        // SWITCH_TASKS _without_ nesting to TSS
        task_switch(&selector, &descriptor, BX_TASK_FROM_JUMP, dword1, dword2);

        // EIP must be in code seg limit, else #GP(0)
        if (EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
          BX_ERROR(("jump_protected: EIP not within CS limits"));
          exception(BX_GP_EXCEPTION, 0, 0);
        }
        return;

      case BX_TASK_GATE:
        jmp_task_gate(&descriptor);
        return;

      case BX_286_CALL_GATE:
      case BX_386_CALL_GATE:
        jmp_call_gate(&descriptor);
        return;

      default: // can't get here
        BX_PANIC(("jump_protected: gate type %u unsupported", (unsigned) descriptor.type));
        exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }
  }
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::jmp_task_gate(bx_descriptor_t *gate_descriptor)
{
  Bit16u          raw_tss_selector;
  bx_selector_t   tss_selector;
  bx_descriptor_t tss_descriptor;
  Bit32u dword1, dword2;
  Bit32u temp_eIP;

  // examine selector to TSS, given in Task Gate descriptor
  // must specify global in the local/global bit else #GP(TSS selector)
  raw_tss_selector = gate_descriptor->u.taskgate.tss_selector;
  parse_selector(raw_tss_selector, &tss_selector);

  if (tss_selector.ti) {
    BX_ERROR(("jmp_task_gate: tss_selector.ti=1"));
    exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
  }

  // index must be within GDT limits else #GP(TSS selector)
  fetch_raw_descriptor(&tss_selector, &dword1, &dword2, BX_GP_EXCEPTION);

  // descriptor AR byte must specify available TSS
  //   else #GP(TSS selector)
  parse_descriptor(dword1, dword2, &tss_descriptor);

  if (tss_descriptor.valid==0 || tss_descriptor.segment) {
    BX_ERROR(("jmp_task_gate: TSS selector points to bad TSS"));
    exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
  }
  if (tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_286_TSS &&
      tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_386_TSS)
  {
    BX_ERROR(("jmp_task_gate: TSS selector points to bad TSS"));
    exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
  }

  // task state segment must be present, else #NP(tss selector)
  if (! IS_PRESENT(tss_descriptor)) {
    BX_ERROR(("jmp_task_gate: TSS descriptor.p == 0"));
    exception(BX_NP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
  }

  // SWITCH_TASKS _without_ nesting to TSS
  task_switch(&tss_selector, &tss_descriptor, BX_TASK_FROM_JUMP, dword1, dword2);

  // EIP must be within code segment limit, else #GP(0)
  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.d_b)
    temp_eIP = EIP;
  else
    temp_eIP =  IP;

  if (temp_eIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("jmp_task_gate: EIP > CS.limit"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::jmp_call_gate(bx_descriptor_t *gate_descriptor)
{
  bx_selector_t gate_cs_selector;
  bx_descriptor_t gate_cs_descriptor;
  Bit32u dword1, dword2;

  if (gate_descriptor->type==BX_286_CALL_GATE)
    BX_DEBUG(("jmp_call_gate: jump to 286 CALL GATE"));
  else
    BX_DEBUG(("jmp_call_gate: jump to 386 CALL GATE"));

  // examine selector to code segment given in call gate descriptor
  // selector must not be null, else #GP(0)
  Bit16u gate_cs_raw = gate_descriptor->u.gate.dest_selector;

  if ((gate_cs_raw & 0xfffc) == 0) {
    BX_ERROR(("jmp_call_gate: CS selector null"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  parse_selector(gate_cs_raw, &gate_cs_selector);
  // selector must be within its descriptor table limits else #GP(CS selector)
  fetch_raw_descriptor(&gate_cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &gate_cs_descriptor);

  // check code-segment descriptor
  check_cs(&gate_cs_descriptor, gate_cs_raw, 0, CPL);

  Bit32u temp_EIP = gate_descriptor->u.gate.dest_offset;
  branch_far32(&gate_cs_selector, &gate_cs_descriptor, temp_EIP, CPL);
}

#if BX_SUPPORT_X86_64
  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::jmp_call_gate64(bx_selector_t *gate_selector)
{
  bx_selector_t cs_selector;
  Bit32u dword1, dword2, dword3;
  bx_descriptor_t cs_descriptor;
  bx_descriptor_t gate_descriptor;

  BX_DEBUG(("jmp_call_gate64: jump to CALL GATE 64"));

  fetch_raw_descriptor_64(gate_selector, &dword1, &dword2, &dword3, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &gate_descriptor);

  Bit16u dest_selector = gate_descriptor.u.gate.dest_selector;
  // selector must not be null else #GP(0)
  if ((dest_selector & 0xfffc) == 0) {
    BX_ERROR(("jmp_call_gate64: selector in gate null"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  parse_selector(dest_selector, &cs_selector);
  // selector must be within its descriptor table limits,
  //   else #GP(code segment selector)
  fetch_raw_descriptor(&cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &cs_descriptor);

  // find the RIP in the gate_descriptor
  Bit64u new_RIP = gate_descriptor.u.gate.dest_offset;
  new_RIP |= ((Bit64u)dword3 << 32);

  // AR byte of selected descriptor must indicate code segment,
  //   else #GP(code segment selector)
  if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
      IS_DATA_SEGMENT(cs_descriptor.type))
  {
    BX_ERROR(("jmp_call_gate64: not code segment in 64-bit call gate"));
    exception(BX_GP_EXCEPTION, dest_selector & 0xfffc, 0);
  }

  // In long mode, only 64-bit call gates are allowed, and they must point
  // to 64-bit code segments, else #GP(selector)
  if (! IS_LONG64_SEGMENT(cs_descriptor) || cs_descriptor.u.segment.d_b)
  {
    BX_ERROR(("jmp_call_gate64: not 64-bit code segment in 64-bit call gate"));
    exception(BX_GP_EXCEPTION, dest_selector & 0xfffc, 0);
  }

  // check code-segment descriptor
  check_cs(&cs_descriptor, dest_selector, 0, CPL);
  // and transfer the control
  branch_far64(&cs_selector, &cs_descriptor, new_RIP, CPL);
}
#endif
