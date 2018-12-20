/////////////////////////////////////////////////////////////////////////
// $Id: extdb.cc,v 1.30 2008/05/01 20:28:36 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////

#include "bochs.h"
#ifdef WIN32
// windows.h included in bochs.h
#else
#  error "extdb.cc only supported in win32 environment"
#endif

#include "cpu.h"
#include "iodev/iodev.h"
#include "extdb.h"

TRegs regs;

char debug_loaded = 0;

void (*call_debugger)(TRegs *,Bit8u *, Bit32u);

void bx_external_debugger(BX_CPU_C *cpu)
{
     switch (regs.debug_state) {
     case debug_run:
       return;
     case debug_count:
       if (--regs.debug_counter) return;
       regs.debug_state = debug_step;
       break;
     case debug_skip:
       if (cpu->get_instruction_pointer() != regs.debug_eip ||
           cpu->sregs[BX_SEG_REG_CS].selector.value != regs.debug_cs) return;
       regs.debug_state = debug_step;
       break;
     }

#if BX_SUPPORT_X86_64
     regs.rax = cpu->gen_reg[0].rrx;
     regs.rcx = cpu->gen_reg[1].rrx;
     regs.rdx = cpu->gen_reg[2].rrx;
     regs.rbx = cpu->gen_reg[3].rrx;
     regs.rsp = cpu->gen_reg[4].rrx;
     regs.rbp = cpu->gen_reg[5].rrx;
     regs.rsi = cpu->gen_reg[6].rrx;
     regs.rdi = cpu->gen_reg[7].rrx;
     regs.r8  = cpu->gen_reg[8].rrx;
     regs.r9  = cpu->gen_reg[9].rrx;
     regs.r10 = cpu->gen_reg[10].rrx;
     regs.r11 = cpu->gen_reg[11].rrx;
     regs.r12 = cpu->gen_reg[12].rrx;
     regs.r13 = cpu->gen_reg[13].rrx;
     regs.r14 = cpu->gen_reg[14].rrx;
     regs.r15 = cpu->gen_reg[15].rrx;
     regs.rip = cpu->get_instruction_pointer();
#else
     regs.rax = cpu->gen_reg[0].dword.erx;
     regs.rcx = cpu->gen_reg[1].dword.erx;
     regs.rdx = cpu->gen_reg[2].dword.erx;
     regs.rbx = cpu->gen_reg[3].dword.erx;
     regs.rsp = cpu->gen_reg[4].dword.erx;
     regs.rbp = cpu->gen_reg[5].dword.erx;
     regs.rsi = cpu->gen_reg[6].dword.erx;
     regs.rdi = cpu->gen_reg[7].dword.erx;
     regs.r8  = 0;
     regs.r9  = 0;
     regs.r10 = 0;
     regs.r11 = 0;
     regs.r12 = 0;
     regs.r13 = 0;
     regs.r14 = 0;
     regs.r15 = 0;
     regs.rip = cpu->get_instruction_pointer();
#endif
     regs.rflags = cpu->read_eflags();
     regs.es = cpu->sregs[BX_SEG_REG_ES].selector.value;
     regs.cs = cpu->sregs[BX_SEG_REG_CS].selector.value;
     regs.ss = cpu->sregs[BX_SEG_REG_SS].selector.value;
     regs.ds = cpu->sregs[BX_SEG_REG_DS].selector.value;
     regs.fs = cpu->sregs[BX_SEG_REG_FS].selector.value;
     regs.gs = cpu->sregs[BX_SEG_REG_GS].selector.value;
     regs.gdt.base = cpu->gdtr.base;
     regs.gdt.limit = cpu->gdtr.limit;
     regs.idt.base = cpu->idtr.base;
     regs.idt.limit = cpu->idtr.limit;
     regs.ldt = cpu->ldtr.selector.value;
     regs.cr0 = cpu->cr0.getRegister();
     regs.cr1 = cpu->cr1;
     regs.cr2 = cpu->cr2;
     regs.cr3 = cpu->cr3;
#if BX_CPU_LEVEL >= 4
     regs.cr4 = cpu->cr4.getRegister();
#endif
     regs.fsbase = cpu->sregs[BX_SEG_REG_FS].cache.u.segment.base;
     regs.gsbase = cpu->sregs[BX_SEG_REG_GS].cache.u.segment.base;
#if BX_SUPPORT_X86_64
     regs.efer = cpu->efer.getRegister();
#else
     regs.efer = 0;
#endif

     if (debug_loaded == 0) {
       HINSTANCE hdbg;
       debug_loaded = 1;
       hdbg = LoadLibrary("debug.dll");
       call_debugger = (void (*)(TRegs *,Bit8u *, Bit32u)) GetProcAddress(hdbg,"call_debugger");

       if (call_debugger != NULL) debug_loaded = 2;
     }
     if (debug_loaded == 2) {
       DEV_vga_refresh();
       call_debugger(&regs,BX_MEM(0)->get_vector(),BX_MEM(0)->get_memory_len());
     }
}

void trap_debugger(bx_bool callnow, BX_CPU_C *cpu)
{
  regs.debug_state = debug_step;
  if (callnow) {
    bx_external_debugger(cpu);
  }
}
