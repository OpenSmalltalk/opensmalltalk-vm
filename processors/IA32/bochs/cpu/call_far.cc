////////////////////////////////////////////////////////////////////////
// $Id: call_far.cc,v 1.40 2008/08/31 06:04:14 sshwarts Exp $
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
/////////////////////////////////////////////////////////////////////////

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

#if BX_SUPPORT_X86_64==0
// Make life easier merging cpu64 & cpu code.
#define RIP EIP
#endif

  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::call_protected(bxInstruction_c *i, Bit16u cs_raw, bx_address disp)
{
  bx_selector_t cs_selector;
  Bit32u dword1, dword2;
  bx_descriptor_t cs_descriptor;
  Bit32u temp_RSP;

  /* new cs selector must not be null, else #GP(0) */
  if ((cs_raw & 0xfffc) == 0) {
    BX_ERROR(("call_protected: CS selector null"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  parse_selector(cs_raw, &cs_selector);
  // check new CS selector index within its descriptor limits,
  // else #GP(new CS selector)
  fetch_raw_descriptor(&cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &cs_descriptor);

  // examine AR byte of selected descriptor for various legal values
  if (cs_descriptor.valid==0) {
    BX_ERROR(("call_protected: invalid CS descriptor"));
    exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
  }

  if (cs_descriptor.segment)   // normal segment
  {
    check_cs(&cs_descriptor, cs_raw, BX_SELECTOR_RPL(cs_raw), CPL);

#if BX_SUPPORT_X86_64
    if (cs_descriptor.u.segment.l) {
      // moving to long mode, push return address onto 64-bit stack
      if (i->os64L()) {
        write_new_stack_qword_64(RSP -  8, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_qword_64(RSP - 16, cs_descriptor.dpl, RIP);
        RSP -= 16;
      }
      else if (i->os32L()) {
        write_new_stack_dword_64(RSP - 4, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_dword_64(RSP - 8, cs_descriptor.dpl, EIP);
        RSP -= 8;
      }
      else {
        write_new_stack_word_64(RSP - 2, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_word_64(RSP - 4, cs_descriptor.dpl, IP);
        RSP -= 4;
      }
    }
    else
#endif
    {
      // moving to legacy mode, push return address onto 32-bit stack
      if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
        temp_RSP = ESP;
      else
        temp_RSP = SP;

#if BX_SUPPORT_X86_64
      if (i->os64L()) {
        write_new_stack_qword_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP -  8, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_qword_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP - 16, cs_descriptor.dpl, RIP);
        temp_RSP -= 16;
      }
      else
#endif
      if (i->os32L()) {
        write_new_stack_dword_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP - 4, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_dword_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP - 8, cs_descriptor.dpl, EIP);
        temp_RSP -= 8;
      }
      else {
        write_new_stack_word_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP - 2, cs_descriptor.dpl,
             BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
        write_new_stack_word_32(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS],
             temp_RSP - 4, cs_descriptor.dpl, IP);
        temp_RSP -= 4;
      }

      if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
        ESP = (Bit32u) temp_RSP;
      else
         SP = (Bit16u) temp_RSP;
    }

    // load code segment descriptor into CS cache
    // load CS with new code segment selector
    // set RPL of CS to CPL
    branch_far64(&cs_selector, &cs_descriptor, disp, CPL);

    return;
  }
  else { // gate & special segment
    bx_descriptor_t  gate_descriptor = cs_descriptor;
    bx_selector_t    gate_selector = cs_selector;
    Bit32u new_EIP;
    Bit16u dest_selector;
    Bit16u          raw_tss_selector;
    bx_selector_t   tss_selector;
    bx_descriptor_t tss_descriptor;
    Bit32u temp_eIP;

    // descriptor DPL must be >= CPL else #GP(gate selector)
    if (gate_descriptor.dpl < CPL) {
      BX_ERROR(("call_protected: descriptor.dpl < CPL"));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

    // descriptor DPL must be >= gate selector RPL else #GP(gate selector)
    if (gate_descriptor.dpl < gate_selector.rpl) {
      BX_ERROR(("call_protected: descriptor.dpl < selector.rpl"));
      exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

#if BX_SUPPORT_X86_64
    if (long_mode()) {
      // call gate type is higher priority than non-present bit check
      if (gate_descriptor.type != BX_386_CALL_GATE) {
        BX_ERROR(("call_protected: gate type %u unsupported in long mode", (unsigned) gate_descriptor.type));
        exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
      }
    }
    else
#endif
    {
      switch (gate_descriptor.type) {
        case BX_SYS_SEGMENT_AVAIL_286_TSS:
        case BX_SYS_SEGMENT_AVAIL_386_TSS:
        case BX_TASK_GATE:
        case BX_286_CALL_GATE:
        case BX_386_CALL_GATE:
          break;
        default:
          BX_ERROR(("call_protected(): gate.type(%u) unsupported", (unsigned) gate_descriptor.type));
          exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
      }
    }

    // gate descriptor must be present else #NP(gate selector)
    if (! IS_PRESENT(gate_descriptor)) {
      BX_ERROR(("call_protected: gate not present"));
      exception(BX_NP_EXCEPTION, cs_raw & 0xfffc, 0);
    }

#if BX_SUPPORT_X86_64
    if (long_mode()) {
      call_gate64(&gate_selector);
      return;
    }
#endif

    switch (gate_descriptor.type) {
      case BX_SYS_SEGMENT_AVAIL_286_TSS:
      case BX_SYS_SEGMENT_AVAIL_386_TSS:

        if (gate_descriptor.type==BX_SYS_SEGMENT_AVAIL_286_TSS)
          BX_DEBUG(("call_protected: 16bit available TSS"));
        else
          BX_DEBUG(("call_protected: 32bit available TSS"));

        // SWITCH_TASKS _without_ nesting to TSS
        task_switch(&gate_selector, &gate_descriptor,
          BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

        // EIP must be in code seg limit, else #GP(0)
        if (EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
          BX_ERROR(("call_protected: EIP not within CS limits"));
          exception(BX_GP_EXCEPTION, 0, 0);
        }
        return;

      case BX_TASK_GATE:
        // examine selector to TSS, given in Task Gate descriptor
        // must specify global in the local/global bit else #TS(TSS selector)
        raw_tss_selector = gate_descriptor.u.taskgate.tss_selector;
        parse_selector(raw_tss_selector, &tss_selector);

        if (tss_selector.ti) {
          BX_ERROR(("call_protected: tss_selector.ti=1"));
          exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
        }

        // index must be within GDT limits else #TS(TSS selector)
        fetch_raw_descriptor(&tss_selector, &dword1, &dword2, BX_GP_EXCEPTION);

        parse_descriptor(dword1, dword2, &tss_descriptor);

        // descriptor AR byte must specify available TSS
        //   else #GP(TSS selector)
        if (tss_descriptor.valid==0 || tss_descriptor.segment) {
          BX_ERROR(("call_protected: TSS selector points to bad TSS"));
          exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
        }
        if (tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_286_TSS &&
            tss_descriptor.type!=BX_SYS_SEGMENT_AVAIL_386_TSS)
        {
          BX_ERROR(("call_protected: TSS selector points to bad TSS"));
          exception(BX_GP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
        }

        // task state segment must be present, else #NP(tss selector)
        if (! IS_PRESENT(tss_descriptor)) {
          BX_ERROR(("call_protected: task descriptor.p == 0"));
          exception(BX_NP_EXCEPTION, raw_tss_selector & 0xfffc, 0);
        }

        // SWITCH_TASKS without nesting to TSS
        task_switch(&tss_selector, &tss_descriptor,
                    BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

        // EIP must be within code segment limit, else #TS(0)
        if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.d_b)
          temp_eIP = EIP;
        else
          temp_eIP =  IP;

        if (temp_eIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
        {
          BX_ERROR(("call_protected: EIP > CS.limit"));
          exception(BX_GP_EXCEPTION, 0, 0);
        }
        return;

      case BX_286_CALL_GATE:
      case BX_386_CALL_GATE:
        // examine code segment selector in call gate descriptor
        BX_DEBUG(("call_protected: call gate"));
        dest_selector = gate_descriptor.u.gate.dest_selector;
        new_EIP       = gate_descriptor.u.gate.dest_offset;

        // selector must not be null else #GP(0)
        if ((dest_selector & 0xfffc) == 0) {
          BX_ERROR(("call_protected: selector in gate null"));
          exception(BX_GP_EXCEPTION, 0, 0);
        }

        parse_selector(dest_selector, &cs_selector);
        // selector must be within its descriptor table limits,
        //   else #GP(code segment selector)
        fetch_raw_descriptor(&cs_selector, &dword1, &dword2, BX_GP_EXCEPTION);
        parse_descriptor(dword1, dword2, &cs_descriptor);

        // AR byte of selected descriptor must indicate code segment,
        //   else #GP(code segment selector)
        // DPL of selected descriptor must be <= CPL,
        // else #GP(code segment selector)
        if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
            IS_DATA_SEGMENT(cs_descriptor.type) ||
            cs_descriptor.dpl > CPL)
        {
          BX_ERROR(("call_protected: selected descriptor is not code"));
          exception(BX_GP_EXCEPTION, dest_selector & 0xfffc, 0);
        }

        // code segment must be present else #NP(selector)
        if (! IS_PRESENT(cs_descriptor)) {
          BX_ERROR(("call_protected: code segment not present !"));
          exception(BX_NP_EXCEPTION, dest_selector & 0xfffc, 0);
        }

        // CALL GATE TO MORE PRIVILEGE
        // if non-conforming code segment and DPL < CPL then
        if (IS_CODE_SEGMENT_NON_CONFORMING(cs_descriptor.type) && (cs_descriptor.dpl < CPL))
        {
          Bit16u SS_for_cpl_x;
          Bit32u ESP_for_cpl_x;
          bx_selector_t   ss_selector;
          bx_descriptor_t ss_descriptor;
          Bit16u   return_SS, return_CS;
          Bit32u   return_ESP, return_EIP;
          Bit16u   parameter_word[32];
          Bit32u   parameter_dword[32];

          BX_DEBUG(("CALL GATE TO MORE PRIVILEGE LEVEL"));

          // get new SS selector for new privilege level from TSS
          get_SS_ESP_from_TSS(cs_descriptor.dpl, &SS_for_cpl_x, &ESP_for_cpl_x);

          // check selector & descriptor for new SS:
          // selector must not be null, else #TS(0)
          if ((SS_for_cpl_x & 0xfffc) == 0) {
            BX_ERROR(("call_protected: new SS null"));
            exception(BX_TS_EXCEPTION, 0, 0);
          }

          // selector index must be within its descriptor table limits,
          //   else #TS(SS selector)
          parse_selector(SS_for_cpl_x, &ss_selector);
          fetch_raw_descriptor(&ss_selector, &dword1, &dword2, BX_TS_EXCEPTION);
          parse_descriptor(dword1, dword2, &ss_descriptor);

          // selector's RPL must equal DPL of code segment,
          //   else #TS(SS selector)
          if (ss_selector.rpl != cs_descriptor.dpl) {
            BX_ERROR(("call_protected: SS selector.rpl != CS descr.dpl"));
            exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
          }

          // stack segment DPL must equal DPL of code segment,
          //   else #TS(SS selector)
          if (ss_descriptor.dpl != cs_descriptor.dpl) {
            BX_ERROR(("call_protected: SS descr.rpl != CS descr.dpl"));
            exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
          }

          // descriptor must indicate writable data segment,
          //   else #TS(SS selector)
          if (ss_descriptor.valid==0 || ss_descriptor.segment==0 ||
               IS_CODE_SEGMENT(ss_descriptor.type) ||
              !IS_DATA_SEGMENT_WRITEABLE(ss_descriptor.type))
          {
            BX_ERROR(("call_protected: ss descriptor is not writable data seg"));
            exception(BX_TS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
          }

          // segment must be present, else #SS(SS selector)
          if (! IS_PRESENT(ss_descriptor)) {
            BX_ERROR(("call_protected: ss descriptor not present"));
            exception(BX_SS_EXCEPTION, SS_for_cpl_x & 0xfffc, 0);
          }

          // get word count from call gate, mask to 5 bits
          unsigned param_count = gate_descriptor.u.gate.param_count & 0x1f;

          // save return SS:eSP to be pushed on new stack
          return_SS = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
          if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
            return_ESP = ESP;
          else
            return_ESP =  SP;

          // save return CS:eIP to be pushed on new stack
          return_CS = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
          if (cs_descriptor.u.segment.d_b)
            return_EIP = EIP;
          else
            return_EIP = IP;

          if (gate_descriptor.type==BX_286_CALL_GATE) {
            for (unsigned n=0; n<param_count; n++) {
              parameter_word[n] = read_virtual_word_32(BX_SEG_REG_SS, return_ESP + n*2);
            }
          }
          else {
            for (unsigned n=0; n<param_count; n++) {
              parameter_dword[n] = read_virtual_dword_32(BX_SEG_REG_SS, return_ESP + n*4);
            }
          }

          // Prepare new stack segment
          bx_segment_reg_t new_stack;
          new_stack.selector = ss_selector;
          new_stack.cache = ss_descriptor;
          new_stack.selector.rpl = cs_descriptor.dpl;
          // add cpl to the selector value
          new_stack.selector.value = (0xfffc & new_stack.selector.value) |
            new_stack.selector.rpl;

          /* load new SS:SP value from TSS */
          if (ss_descriptor.u.segment.d_b) {
            Bit32u temp_ESP = ESP_for_cpl_x;

            // push pointer of old stack onto new stack
            if (gate_descriptor.type==BX_386_CALL_GATE) {
              write_new_stack_dword_32(&new_stack, temp_ESP-4, cs_descriptor.dpl, return_SS);
              write_new_stack_dword_32(&new_stack, temp_ESP-8, cs_descriptor.dpl, return_ESP);
              temp_ESP -= 8;

              for (unsigned n=param_count; n>0; n--) {
                temp_ESP -= 4;
                write_new_stack_dword_32(&new_stack, temp_ESP, cs_descriptor.dpl, parameter_dword[n-1]);
              }
              // push return address onto new stack
              write_new_stack_dword_32(&new_stack, temp_ESP-4, cs_descriptor.dpl, return_CS);
              write_new_stack_dword_32(&new_stack, temp_ESP-8, cs_descriptor.dpl, return_EIP);
              temp_ESP -= 8;
            }
            else {
              write_new_stack_word_32(&new_stack, temp_ESP-2, cs_descriptor.dpl, return_SS);
              write_new_stack_word_32(&new_stack, temp_ESP-4, cs_descriptor.dpl, (Bit16u) return_ESP);
              temp_ESP -= 4;

              for (unsigned n=param_count; n>0; n--) {
                temp_ESP -= 2;
                write_new_stack_word_32(&new_stack, temp_ESP, cs_descriptor.dpl, parameter_word[n-1]);
              }
              // push return address onto new stack
              write_new_stack_word_32(&new_stack, temp_ESP-2, cs_descriptor.dpl, return_CS);
              write_new_stack_word_32(&new_stack, temp_ESP-4, cs_descriptor.dpl, (Bit16u) return_EIP);
              temp_ESP -= 4;
            }

            ESP = temp_ESP;
          }
          else {
            Bit16u temp_SP = (Bit16u) ESP_for_cpl_x;

            // push pointer of old stack onto new stack
            if (gate_descriptor.type==BX_386_CALL_GATE) {
              write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-4), cs_descriptor.dpl, return_SS);
              write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-8), cs_descriptor.dpl, return_ESP);
              temp_SP -= 8;

              for (unsigned n=param_count; n>0; n--) {
                temp_SP -= 4;
                write_new_stack_dword_32(&new_stack, temp_SP, cs_descriptor.dpl, parameter_dword[n-1]);
              }
              // push return address onto new stack
              write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-4), cs_descriptor.dpl, return_CS);
              write_new_stack_dword_32(&new_stack, (Bit16u)(temp_SP-8), cs_descriptor.dpl, return_EIP);
              temp_SP -= 8;
            }
            else {
              write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-2), cs_descriptor.dpl, return_SS);
              write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-4), cs_descriptor.dpl, (Bit16u) return_ESP);
              temp_SP -= 4;

              for (unsigned n=param_count; n>0; n--) {
                temp_SP -= 2;
                write_new_stack_word_32(&new_stack, temp_SP, cs_descriptor.dpl, parameter_word[n-1]);
              }
              // push return address onto new stack
              write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-2), cs_descriptor.dpl, return_CS);
              write_new_stack_word_32(&new_stack, (Bit16u)(temp_SP-4), cs_descriptor.dpl, (Bit16u) return_EIP);
              temp_SP -= 4;
            }

            SP = temp_SP;
          }

          // new eIP must be in code segment limit else #GP(0)
          if (new_EIP > cs_descriptor.u.segment.limit_scaled) {
            BX_ERROR(("call_protected: EIP not within CS limits"));
            exception(BX_GP_EXCEPTION, 0, 0);
          }

          /* load SS descriptor */
          load_ss(&ss_selector, &ss_descriptor, cs_descriptor.dpl);

          /* load new CS:IP value from gate */
          /* load CS descriptor */
          /* set CPL to stack segment DPL */
          /* set RPL of CS to CPL */
          load_cs(&cs_selector, &cs_descriptor, cs_descriptor.dpl);
          EIP = new_EIP;
        }
        else   // CALL GATE TO SAME PRIVILEGE
        {
          BX_DEBUG(("CALL GATE TO SAME PRIVILEGE"));

          if (gate_descriptor.type == BX_386_CALL_GATE) {
            // call gate 32bit, push return address onto stack
            push_32(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
            push_32(EIP);
          }
          else {
            // call gate 16bit, push return address onto stack
            push_16(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
            push_16(IP);
          }

          // load CS:EIP from gate
          // load code segment descriptor into CS register
          // set RPL of CS to CPL
          branch_far32(&cs_selector, &cs_descriptor, new_EIP, CPL);
        }
        return;

      default: // can't get here
        BX_PANIC(("call_protected: gate type %u unsupported", (unsigned) cs_descriptor.type));
        exception(BX_GP_EXCEPTION, cs_raw & 0xfffc, 0);
    }
  }
}

#if BX_SUPPORT_X86_64
  void BX_CPP_AttrRegparmN(3)
BX_CPU_C::call_gate64(bx_selector_t *gate_selector)
{
  bx_selector_t cs_selector;
  Bit32u dword1, dword2, dword3;
  bx_descriptor_t cs_descriptor;
  bx_descriptor_t gate_descriptor;

  // examine code segment selector in call gate descriptor
  BX_DEBUG(("call_gate64: CALL 64bit call gate"));

  fetch_raw_descriptor_64(gate_selector, &dword1, &dword2, &dword3, BX_GP_EXCEPTION);
  parse_descriptor(dword1, dword2, &gate_descriptor);

  Bit16u dest_selector = gate_descriptor.u.gate.dest_selector;
  // selector must not be null else #GP(0)
  if ((dest_selector & 0xfffc) == 0) {
    BX_ERROR(("call_gate64: selector in gate null"));
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
  // DPL of selected descriptor must be <= CPL,
  // else #GP(code segment selector)
  if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
      IS_DATA_SEGMENT(cs_descriptor.type) ||
      cs_descriptor.dpl > CPL)
  {
    BX_ERROR(("call_gate64: selected descriptor is not code"));
    exception(BX_GP_EXCEPTION, dest_selector & 0xfffc, 0);
  }

  // In long mode, only 64-bit call gates are allowed, and they must point
  // to 64-bit code segments, else #GP(selector)
  if (! IS_LONG64_SEGMENT(cs_descriptor) || cs_descriptor.u.segment.d_b)
  {
    BX_ERROR(("call_gate64: not 64-bit code segment in call gate 64"));
    exception(BX_GP_EXCEPTION, dest_selector & 0xfffc, 0);
  }

  // code segment must be present else #NP(selector)
  if (! IS_PRESENT(cs_descriptor)) {
    BX_ERROR(("call_gate64: code segment not present !"));
    exception(BX_NP_EXCEPTION, dest_selector & 0xfffc, 0);
  }

  Bit64u old_CS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
  Bit64u old_RIP = RIP;

  // CALL GATE TO MORE PRIVILEGE
  // if non-conforming code segment and DPL < CPL then
  if (IS_CODE_SEGMENT_NON_CONFORMING(cs_descriptor.type) && (cs_descriptor.dpl < CPL))
  {
    Bit64u RSP_for_cpl_x;

    BX_DEBUG(("CALL GATE TO MORE PRIVILEGE LEVEL"));

    // get new RSP for new privilege level from TSS
    get_RSP_from_TSS(cs_descriptor.dpl, &RSP_for_cpl_x);

    Bit64u old_SS  = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
    Bit64u old_RSP = RSP;

    if (! IsCanonical(RSP_for_cpl_x)) {
      // #SS(selector) when changing priviledge level
      BX_ERROR(("call_gate64: canonical address failure %08x%08x",
         GET32H(RSP_for_cpl_x), GET32L(RSP_for_cpl_x)));
      exception(BX_SS_EXCEPTION, old_SS & 0xfffc, 0);
    }

    // push old stack long pointer onto new stack
    write_new_stack_qword_64(RSP_for_cpl_x -  8, cs_descriptor.dpl, old_SS);
    write_new_stack_qword_64(RSP_for_cpl_x - 16, cs_descriptor.dpl, old_RSP);
    // push long pointer to return address onto new stack
    write_new_stack_qword_64(RSP_for_cpl_x - 24, cs_descriptor.dpl, old_CS);
    write_new_stack_qword_64(RSP_for_cpl_x - 32, cs_descriptor.dpl, old_RIP);
    RSP_for_cpl_x -= 32;

    // prepare new stack null SS selector
    bx_selector_t ss_selector;
    bx_descriptor_t ss_descriptor;

    // set up a null descriptor
    parse_selector(0, &ss_selector);
    parse_descriptor(0, 0, &ss_descriptor);

    // load CS:RIP (guaranteed to be in 64 bit mode)
    branch_far64(&cs_selector, &cs_descriptor, new_RIP, cs_descriptor.dpl);

    // set up null SS descriptor
    load_ss(&ss_selector, &ss_descriptor, cs_descriptor.dpl);
    RSP = RSP_for_cpl_x;
  }
  else
  {
    BX_DEBUG(("CALL GATE TO SAME PRIVILEGE"));

    // push to 64-bit stack, switch to long64 guaranteed
    write_new_stack_qword_64(RSP -  8, CPL, old_CS);
    write_new_stack_qword_64(RSP - 16, CPL, old_RIP);
    RSP -= 16;

    // load CS:RIP (guaranteed to be in 64 bit mode)
    branch_far64(&cs_selector, &cs_descriptor, new_RIP, CPL);
  }
}
#endif
