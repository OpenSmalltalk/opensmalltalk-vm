/////////////////////////////////////////////////////////////////////////
// $Id: ctrl_xfer32.cc,v 1.78 2008/08/16 15:32:44 sshwarts Exp $
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

// Make code more tidy with a few macros.
#if BX_SUPPORT_X86_64==0
#define RSP ESP
#define RIP EIP
#endif

#if BX_CPU_LEVEL >= 3

BX_CPP_INLINE void BX_CPP_AttrRegparmN(1) BX_CPU_C::branch_near32(Bit32u new_EIP)
{
  // check always, not only in protected mode
  if (new_EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("branch_near32: offset outside of CS limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  RIP = new_EIP;

#if BX_SUPPORT_TRACE_CACHE && !defined(BX_TRACE_CACHE_NO_SPECULATIVE_TRACING)
  // assert magic async_event to stop trace execution
  BX_CPU_THIS_PTR async_event |= BX_ASYNC_EVENT_STOP_TRACE;
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETnear32_Iw(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  Bit16u imm16 = i->Iw();
  Bit32u return_EIP = pop_32();
  if (return_EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("RETnear32_Iw: offset outside of CS limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }
  RIP = return_EIP;

  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
    ESP += imm16;
  else
     SP += imm16;

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETnear32(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  Bit32u return_EIP = pop_32();
  if (return_EIP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("RETnear32: offset outside of CS limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }
  RIP = return_EIP;

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETfar32_Iw(bxInstruction_c *i)
{
  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  Bit16u imm16 = i->Iw();
  Bit16u cs_raw;
  Bit32u eip;

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR return_protected(i, imm16);
    goto done;
  }

  eip    =          pop_32();
  cs_raw = (Bit16u) pop_32(); /* 32bit pop, MSW discarded */

  // CS.LIMIT can't change when in real/v8086 mode
  if (eip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("RETfar32_Iw: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = eip;

  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
    ESP += imm16;
  else
     SP += imm16;

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETfar32(bxInstruction_c *i)
{
  Bit32u eip;
  Bit16u cs_raw;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR return_protected(i, 0);
    goto done;
  }

  eip = pop_32();

  // CS.LIMIT can't change when in real/v8086 mode
  if (eip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("RETfar32: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  cs_raw = (Bit16u) pop_32(); /* 32bit pop, MSW discarded */

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = eip;

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL_Jd(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  Bit32u new_EIP = EIP + i->Id();

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  /* push 32 bit EA of next instruction */
  push_32(EIP);

  branch_near32(new_EIP);

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL32_Ap(bxInstruction_c *i)
{
  Bit16u cs_raw;
  Bit32u disp32;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  disp32 = i->Id();
  cs_raw = i->Iw2();

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR call_protected(i, cs_raw, disp32);
    goto done;
  }

  // CS.LIMIT can't change when in real/v8086 mode
  if (disp32 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("CALL32_Ap: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  push_32(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
  push_32(EIP);

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = disp32;

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL_EdR(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  Bit32u new_EIP = BX_READ_32BIT_REG(i->rm());

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  /* push 32 bit EA of next instruction */
  push_32(EIP);

  branch_near32(new_EIP);

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL32_Ep(bxInstruction_c *i)
{
  Bit16u cs_raw;
  Bit32u op1_32;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_virtual_dword(i->seg(), eaddr);
  cs_raw = read_virtual_word (i->seg(), eaddr+4);

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR call_protected(i, cs_raw, op1_32);
    goto done;
  }

  // CS.LIMIT can't change when in real/v8086 mode
  if (op1_32 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("CALL32_Ep: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  push_32(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
  push_32(EIP);

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = op1_32;

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP_Jd(bxInstruction_c *i)
{
  Bit32u new_EIP = EIP + (Bit32s) i->Id();
  branch_near32(new_EIP);
  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP, new_EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JO_Jd(bxInstruction_c *i)
{
  if (get_OF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNO_Jd(bxInstruction_c *i)
{
  if (! get_OF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JB_Jd(bxInstruction_c *i)
{
  if (get_CF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNB_Jd(bxInstruction_c *i)
{
  if (! get_CF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JZ_Jd(bxInstruction_c *i)
{
  if (get_ZF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNZ_Jd(bxInstruction_c *i)
{
  if (! get_ZF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JBE_Jd(bxInstruction_c *i)
{
  if (get_CF() || get_ZF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNBE_Jd(bxInstruction_c *i)
{
  if (! (get_CF() || get_ZF())) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JS_Jd(bxInstruction_c *i)
{
  if (get_SF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNS_Jd(bxInstruction_c *i)
{
  if (! get_SF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JP_Jd(bxInstruction_c *i)
{
  if (get_PF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNP_Jd(bxInstruction_c *i)
{
  if (! get_PF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JL_Jd(bxInstruction_c *i)
{
  if (getB_SF() != getB_OF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNL_Jd(bxInstruction_c *i)
{
  if (getB_SF() == getB_OF()) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JLE_Jd(bxInstruction_c *i)
{
  if (get_ZF() || (getB_SF() != getB_OF())) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNLE_Jd(bxInstruction_c *i)
{
  if (! get_ZF() && (getB_SF() == getB_OF())) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP_Ap(bxInstruction_c *i)
{
  Bit32u disp32;
  Bit16u cs_raw;

  invalidate_prefetch_q();

  if (i->os32L()) {
    disp32 = i->Id();
  }
  else {
    disp32 = i->Iw();
  }
  cs_raw = i->Iw2();

  // jump_protected doesn't affect RSP so it is RSP safe
  if (protected_mode()) {
    BX_CPU_THIS_PTR jump_protected(i, cs_raw, disp32);
    goto done;
  }

  // CS.LIMIT can't change when in real/v8086 mode
  if (disp32 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("JMP_Ap: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = disp32;

done:
  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP_EdR(bxInstruction_c *i)
{
  Bit32u new_EIP = BX_READ_32BIT_REG(i->rm());
  branch_near32(new_EIP);
  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP, new_EIP);
}

/* Far indirect jump */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP32_Ep(bxInstruction_c *i)
{
  Bit16u cs_raw;
  Bit32u op1_32;

  invalidate_prefetch_q();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  /* pointer, segment address pair */
  op1_32 = read_virtual_dword(i->seg(), eaddr);
  cs_raw = read_virtual_word (i->seg(), eaddr+4);

  // jump_protected doesn't affect RSP so it is RSP safe
  if (protected_mode()) {
    BX_CPU_THIS_PTR jump_protected(i, cs_raw, op1_32);
    goto done;
  }

  // CS.LIMIT can't change when in real/v8086 mode
  if (op1_32 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("JMP32_Ep: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = op1_32;

done:
  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::IRET32(bxInstruction_c *i)
{
  Bit32u eip, eflags32;
  Bit16u cs_raw;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_iret;
#endif

  BX_CPU_THIS_PTR nmi_disable = 0;

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (v8086_mode()) {
    // IOPL check in stack_return_from_v86()
    iret32_stack_return_from_v86(i);
    goto done;
  }

  if (protected_mode()) {
    iret_protected(i);
    goto done;
  }

  eip      =          pop_32();
  cs_raw   = (Bit16u) pop_32(); // #SS has higher priority
  eflags32 =          pop_32();

  // CS.LIMIT can't change when in real/v8086 mode
  if (eip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("IRET32: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = eip;
  writeEFlags(eflags32, 0x00257fd5); // VIF, VIP, VM unchanged

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_IRET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JECXZ_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  Bit32u temp_ECX;

  if (i->as32L())
    temp_ECX = ECX;
  else
    temp_ECX = CX;

  if (temp_ECX == 0) {
    Bit32u new_EIP = EIP + (Bit32s) i->Id();
    branch_near32(new_EIP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

//
// There is some weirdness in LOOP instructions definition. If an exception
// was generated during the instruction execution (for example #GP fault
// because EIP was beyond CS segment limits) CPU state should restore the
// state prior to instruction execution.
//
// The final point that we are not allowed to decrement ECX register before
// it is known that no exceptions can happen.
//

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOPNE32_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0 && (get_ZF()==0)) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    ECX = count;
  }
  else {
    Bit16u count = CX;

    count--;
    if (count != 0 && (get_ZF()==0)) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOPE32_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0 && get_ZF()) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    ECX = count;
  }
  else {
    Bit16u count = CX;

    count--;
    if (count != 0 && get_ZF()) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOP32_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    ECX = count;
  }
  else {
    Bit16u count = CX;

    count--;
    if (count != 0) {
      Bit32u new_EIP = EIP + (Bit32s) i->Id();
      branch_near32(new_EIP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_EIP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}

#endif
