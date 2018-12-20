/////////////////////////////////////////////////////////////////////////
// $Id: ctrl_xfer16.cc,v 1.62 2008/08/23 22:27:58 sshwarts Exp $
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

BX_CPP_INLINE void BX_CPP_AttrRegparmN(1) BX_CPU_C::branch_near16(Bit16u new_IP)
{
  // check always, not only in protected mode
  if (new_IP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("branch_near16: offset outside of CS limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  RIP = new_IP;

#if BX_SUPPORT_TRACE_CACHE && !defined(BX_TRACE_CACHE_NO_SPECULATIVE_TRACING)
  // assert magic async_event to stop trace execution
  BX_CPU_THIS_PTR async_event |= BX_ASYNC_EVENT_STOP_TRACE;
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETnear16_Iw(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  Bit16u return_IP = pop_16();

  if (return_IP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("RETnear16_Iw: IP > limit"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  RIP = return_IP;

  Bit16u imm16 = i->Iw();

  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b) /* 32bit stack */
    ESP += imm16;
  else
     SP += imm16;

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETnear16(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  Bit16u return_IP = pop_16();

  if (return_IP > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled)
  {
    BX_ERROR(("RETnear16: IP > limit"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  RIP = return_IP;

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETfar16_Iw(bxInstruction_c *i)
{
  Bit16u ip, cs_raw;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_ret;
#endif

  Bit16s imm16 = (Bit16s) i->Iw();

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR return_protected(i, imm16);
    goto done;
  }

  ip     = pop_16();
  cs_raw = pop_16();

  // CS.LIMIT can't change when in real/v8086 mode
  if (ip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("RETfar16_Iw: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = (Bit32u) ip;

  if (BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.u.segment.d_b)
    ESP += imm16;
  else
     SP += imm16;

done:

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::RETfar16(bxInstruction_c *i)
{
  Bit16u ip, cs_raw;

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

  ip     = pop_16();
  cs_raw = pop_16();

  // CS.LIMIT can't change when in real/v8086 mode
  if (ip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("RETfar16: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = (Bit32u) ip;

done:

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_RET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL_Jw(bxInstruction_c *i)
{
#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  /* push 16 bit EA of next instruction */
  push_16(IP);

  Bit16u new_IP = IP + i->Iw();
  branch_near16(new_IP);

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL16_Ap(bxInstruction_c *i)
{
  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  Bit16u disp16 = i->Iw();
  Bit16u cs_raw = i->Iw2();

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR call_protected(i, cs_raw, disp16);
    goto done;
  }

  push_16(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
  push_16(IP);

  // CS.LIMIT can't change when in real/v8086 mode
  if (disp16 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("CALL16_Ap: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = (Bit32u) disp16;

done:

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL_EwR(bxInstruction_c *i)
{
  Bit16u new_IP = BX_READ_16BIT_REG(i->rm());

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  /* push 16 bit EA of next instruction */
  push_16(IP);

  branch_near16(new_IP);

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::CALL16_Ep(bxInstruction_c *i)
{
  Bit16u cs_raw;
  Bit16u op1_16;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_call;
#endif

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_virtual_word(i->seg(), eaddr);
  cs_raw = read_virtual_word(i->seg(), eaddr+2);

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (protected_mode()) {
    BX_CPU_THIS_PTR call_protected(i, cs_raw, op1_16);
    goto done;
  }

  push_16(BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value);
  push_16(IP);

  // CS.LIMIT can't change when in real/v8086 mode
  if (op1_16 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("CALL16_Ep: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = op1_16;

done:

  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_CALL,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP_Jw(bxInstruction_c *i)
{
  Bit16u new_IP = IP + i->Iw();
  branch_near16(new_IP);
  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP, new_IP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JO_Jw(bxInstruction_c *i)
{
  if (get_OF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNO_Jw(bxInstruction_c *i)
{
  if (! get_OF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JB_Jw(bxInstruction_c *i)
{
  if (get_CF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNB_Jw(bxInstruction_c *i)
{
  if (! get_CF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JZ_Jw(bxInstruction_c *i)
{
  if (get_ZF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNZ_Jw(bxInstruction_c *i)
{
  if (! get_ZF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JBE_Jw(bxInstruction_c *i)
{
  if (get_CF() || get_ZF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNBE_Jw(bxInstruction_c *i)
{
  if (! (get_CF() || get_ZF())) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JS_Jw(bxInstruction_c *i)
{
  if (get_SF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNS_Jw(bxInstruction_c *i)
{
  if (! get_SF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JP_Jw(bxInstruction_c *i)
{
  if (get_PF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNP_Jw(bxInstruction_c *i)
{
  if (! get_PF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JL_Jw(bxInstruction_c *i)
{
  if (getB_SF() != getB_OF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNL_Jw(bxInstruction_c *i)
{
  if (getB_SF() == getB_OF()) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JLE_Jw(bxInstruction_c *i)
{
  if (get_ZF() || (getB_SF() != getB_OF())) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JNLE_Jw(bxInstruction_c *i)
{
  if (! get_ZF() && (getB_SF() == getB_OF())) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
  }
#if BX_INSTRUMENTATION
  else {
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
  }
#endif
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP_EwR(bxInstruction_c *i)
{
  Bit16u new_IP = BX_READ_16BIT_REG(i->rm());
  branch_near16(new_IP);
  BX_INSTR_UCNEAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP, new_IP);
}

/* Far indirect jump */
void BX_CPP_AttrRegparmN(1) BX_CPU_C::JMP16_Ep(bxInstruction_c *i)
{
  Bit16u cs_raw;
  Bit16u op1_16;

  invalidate_prefetch_q();

  bx_address eaddr = BX_CPU_CALL_METHODR(i->ResolveModrm, (i));

  op1_16 = read_virtual_word(i->seg(), eaddr);
  cs_raw = read_virtual_word(i->seg(), eaddr+2);

  // jump_protected doesn't affect RSP so it is RSP safe
  if (protected_mode()) {
    BX_CPU_THIS_PTR jump_protected(i, cs_raw, op1_16);
    goto done;
  }

  // CS.LIMIT can't change when in real/v8086 mode
  if (op1_16 > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("JMP16_Ep: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = op1_16;

done:

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_JMP,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::IRET16(bxInstruction_c *i)
{
  Bit16u ip, cs_raw, flags;

  invalidate_prefetch_q();

#if BX_DEBUGGER
  BX_CPU_THIS_PTR show_flag |= Flag_iret;
#endif

  BX_CPU_THIS_PTR nmi_disable = 0;

  BX_CPU_THIS_PTR speculative_rsp = 1;
  BX_CPU_THIS_PTR prev_rsp = RSP;

  if (v8086_mode()) {
    // IOPL check in stack_return_from_v86()
    iret16_stack_return_from_v86(i);
    goto done;
  }

  if (protected_mode()) {
    iret_protected(i);
    goto done;
  }

  ip     = pop_16();
  cs_raw = pop_16(); // #SS has higher priority
  flags  = pop_16();

  // CS.LIMIT can't change when in real/v8086 mode
  if(ip > BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled) {
    BX_ERROR(("IRET16: instruction pointer not within code segment limits"));
    exception(BX_GP_EXCEPTION, 0, 0);
  }

  load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], cs_raw);
  RIP = (Bit32u) ip;
  write_flags(flags, /* change IOPL? */ 1, /* change IF? */ 1);

done:
  BX_CPU_THIS_PTR speculative_rsp = 0;

  BX_INSTR_FAR_BRANCH(BX_CPU_ID, BX_INSTR_IS_IRET,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value, EIP);
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::JCXZ_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  Bit32u temp_ECX;

  if (i->as32L())
    temp_ECX = ECX;
  else
    temp_ECX = CX;

  if (temp_ECX == 0) {
    Bit16u new_IP = IP + i->Iw();
    branch_near16(new_IP);
    BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
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

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOPNE16_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0 && (get_ZF()==0)) {
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
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
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOPE16_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0 && get_ZF()) {
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
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
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::LOOP16_Jb(bxInstruction_c *i)
{
  // it is impossible to get this instruction in long mode
  BX_ASSERT(i->as64L() == 0);

  if (i->as32L()) {
    Bit32u count = ECX;

    count--;
    if (count != 0) {
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
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
      Bit16u new_IP = IP + i->Iw();
      branch_near16(new_IP);
      BX_INSTR_CNEAR_BRANCH_TAKEN(BX_CPU_ID, new_IP);
    }
#if BX_INSTRUMENTATION
    else {
      BX_INSTR_CNEAR_BRANCH_NOT_TAKEN(BX_CPU_ID);
    }
#endif

    CX = count;
  }
}
