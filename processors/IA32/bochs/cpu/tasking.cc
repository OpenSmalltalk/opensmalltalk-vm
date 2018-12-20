/////////////////////////////////////////////////////////////////////////
// $Id: tasking.cc,v 1.61 2008/08/03 19:53:09 sshwarts Exp $
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

// Notes:
// ======

  // ======================
  // 286 Task State Segment
  // ======================
  // dynamic item                      | hex  dec  offset
  // 0       task LDT selector         | 2a   42
  // 1       DS selector               | 28   40
  // 1       SS selector               | 26   38
  // 1       CS selector               | 24   36
  // 1       ES selector               | 22   34
  // 1       DI                        | 20   32
  // 1       SI                        | 1e   30
  // 1       BP                        | 1c   28
  // 1       SP                        | 1a   26
  // 1       BX                        | 18   24
  // 1       DX                        | 16   22
  // 1       CX                        | 14   20
  // 1       AX                        | 12   18
  // 1       flag word                 | 10   16
  // 1       IP (entry point)          | 0e   14
  // 0       SS for CPL 2              | 0c   12
  // 0       SP for CPL 2              | 0a   10
  // 0       SS for CPL 1              | 08   08
  // 0       SP for CPL 1              | 06   06
  // 0       SS for CPL 0              | 04   04
  // 0       SP for CPL 0              | 02   02
  //         back link selector to TSS | 00   00


  // ======================
  // 386 Task State Segment
  // ======================
  // |31            16|15                    0| hex dec
  // |I/O Map Base    |000000000000000000000|T| 64  100 static
  // |0000000000000000| LDT                   | 60  96  static
  // |0000000000000000| GS selector           | 5c  92  dynamic
  // |0000000000000000| FS selector           | 58  88  dynamic
  // |0000000000000000| DS selector           | 54  84  dynamic
  // |0000000000000000| SS selector           | 50  80  dynamic
  // |0000000000000000| CS selector           | 4c  76  dynamic
  // |0000000000000000| ES selector           | 48  72  dynamic
  // |                EDI                     | 44  68  dynamic
  // |                ESI                     | 40  64  dynamic
  // |                EBP                     | 3c  60  dynamic
  // |                ESP                     | 38  56  dynamic
  // |                EBX                     | 34  52  dynamic
  // |                EDX                     | 30  48  dynamic
  // |                ECX                     | 2c  44  dynamic
  // |                EAX                     | 28  40  dynamic
  // |                EFLAGS                  | 24  36  dynamic
  // |                EIP (entry point)       | 20  32  dynamic
  // |           CR3 (PDPR)                   | 1c  28  static
  // |000000000000000 | SS for CPL 2          | 18  24  static
  // |           ESP for CPL 2                | 14  20  static
  // |000000000000000 | SS for CPL 1          | 10  16  static
  // |           ESP for CPL 1                | 0c  12  static
  // |000000000000000 | SS for CPL 0          | 08  08  static
  // |           ESP for CPL 0                | 04  04  static
  // |000000000000000 | back link to prev TSS | 00  00  dynamic (updated only when return expected)


  // ==================================================
  // Effect of task switch on Busy, NT, and Link Fields
  // ==================================================

  // Field         jump        call/interrupt     iret
  // ------------------------------------------------------
  // new busy bit  Set         Set                No change
  // old busy bit  Cleared     No change          Cleared
  // new NT flag   No change   Set                No change
  // old NT flag   No change   No change          Cleared
  // new link      No change   old TSS selector   No change
  // old link      No change   No change          No change
  // CR0.TS        Set         Set                Set

  // Note: I checked 386, 486, and Pentium, and they all exhibited
  //       exactly the same behaviour as above.  There seems to
  //       be some misprints in the Intel docs.

void BX_CPU_C::task_switch(bx_selector_t *tss_selector,
                 bx_descriptor_t *tss_descriptor, unsigned source,
                 Bit32u dword1, Bit32u dword2)
{
  Bit32u obase32; // base address of old TSS
  Bit32u nbase32; // base address of new TSS
  Bit32u temp32, newCR3;
  Bit16u raw_cs_selector, raw_ss_selector, raw_ds_selector, raw_es_selector,
         raw_fs_selector, raw_gs_selector, raw_ldt_selector;
  Bit16u temp16, trap_word;
  bx_selector_t cs_selector, ss_selector, ds_selector, es_selector,
                fs_selector, gs_selector, ldt_selector;
  bx_descriptor_t cs_descriptor, ss_descriptor, ldt_descriptor;
  Bit32u old_TSS_max, new_TSS_max, old_TSS_limit, new_TSS_limit;
  Bit32u newEAX, newECX, newEDX, newEBX;
  Bit32u newESP, newEBP, newESI, newEDI;
  Bit32u newEFLAGS, newEIP;

  BX_DEBUG(("TASKING: ENTER"));

  invalidate_prefetch_q();

  // Discard any traps and inhibits for new context; traps will
  // resume upon return.
  BX_CPU_THIS_PTR debug_trap = 0;
  BX_CPU_THIS_PTR inhibit_mask = 0;

  // STEP 1: The following checks are made before calling task_switch(),
  //         for JMP & CALL only. These checks are NOT made for exceptions,
  //         interrupts & IRET.
  //
  //   1) TSS DPL must be >= CPL
  //   2) TSS DPL must be >= TSS selector RPL
  //   3) TSS descriptor is not busy.

  // TSS must be present, else #NP(TSS selector)
  if (tss_descriptor->p==0) {
    BX_ERROR(("task_switch: TSS descriptor is not present !"));
    exception(BX_NP_EXCEPTION, tss_selector->value & 0xfffc, 0);
  }

  // STEP 2: The processor performs limit-checking on the target TSS
  //         to verify that the TSS limit is greater than or equal
  //         to 67h (2Bh for 16-bit TSS).

  // Gather info about old TSS
  if (BX_CPU_THIS_PTR tr.cache.type <= 3) {
    old_TSS_max = 0x29;
  }
  else {
    old_TSS_max = 0x5F;
  }
  // Gather info about new TSS
  if (tss_descriptor->type <= 3) { // {1,3}
    new_TSS_max = 0x2B;
  }
  else { // tss_descriptor->type = {9,11}
    new_TSS_max = 0x67;
  }

  obase32 = (Bit32u) BX_CPU_THIS_PTR tr.cache.u.system.base;        // old TSS.base
  old_TSS_limit = BX_CPU_THIS_PTR tr.cache.u.system.limit_scaled;
  nbase32 = (Bit32u) tss_descriptor->u.system.base;                 // new TSS.base
  new_TSS_limit = tss_descriptor->u.system.limit_scaled;

  // TSS must have valid limit, else #TS(TSS selector)
  if (tss_selector->ti || tss_descriptor->valid==0 ||
      new_TSS_limit < new_TSS_max)
  {
    BX_ERROR(("task_switch(): new TSS limit < %d", new_TSS_max));
    exception(BX_TS_EXCEPTION, tss_selector->value & 0xfffc, 0);
  }

  if (old_TSS_limit < old_TSS_max) {
    BX_ERROR(("task_switch(): old TSS limit < %d", old_TSS_max));
    exception(BX_TS_EXCEPTION, BX_CPU_THIS_PTR tr.selector.value & 0xfffc, 0);
  }

  if (obase32 == nbase32) {
    BX_INFO(("TASK SWITCH: switching to the same TSS !"));
  }

  // Check that old TSS, new TSS, and all segment descriptors
  // used in the task switch are paged in.
  if (BX_CPU_THIS_PTR cr0.get_PG())
  {
    dtranslate_linear(obase32, 0, BX_WRITE); // new TSS
    dtranslate_linear(obase32 + old_TSS_max, 0, BX_WRITE);
    dtranslate_linear(nbase32, 0, BX_READ);  // old TSS
    dtranslate_linear(nbase32 + new_TSS_max, 0, BX_READ);

    // ??? Humm, we check the new TSS region with READ above,
    // but sometimes we need to write the link field in that
    // region.  We also sometimes update other fields, perhaps
    // we need to WRITE check them here also, so that we keep
    // the written state consistent (ie, we don't encounter a
    // page fault in the middle).

    if (source == BX_TASK_FROM_CALL_OR_INT)
    {
      dtranslate_linear(nbase32,     0, BX_WRITE);
      dtranslate_linear(nbase32 + 2, 0, BX_WRITE);
    }
  }

  // Privilege and busy checks done in CALL, JUMP, INT, IRET

  // STEP 3: Save the current task state in the TSS. Up to this point,
  //         any exception that occurs aborts the task switch without
  //         changing the processor state.

  /* save current machine state in old task's TSS */

  Bit32u oldEFLAGS = read_eflags();

  /* if moving to busy task, clear NT bit */
  if (tss_descriptor->type == BX_SYS_SEGMENT_BUSY_286_TSS ||
      tss_descriptor->type == BX_SYS_SEGMENT_BUSY_386_TSS)
  {
    oldEFLAGS &= ~EFlagsNTMask;
  }

  if (BX_CPU_THIS_PTR tr.cache.type <= 3) {
    temp16 = IP; access_write_linear(Bit32u(obase32 + 14), 2, 0, &temp16);
    temp16 = oldEFLAGS; access_write_linear(Bit32u(obase32 + 16), 2, 0, &temp16);
    temp16 = AX; access_write_linear(Bit32u(obase32 + 18), 2, 0, &temp16);
    temp16 = CX; access_write_linear(Bit32u(obase32 + 20), 2, 0, &temp16);
    temp16 = DX; access_write_linear(Bit32u(obase32 + 22), 2, 0, &temp16);
    temp16 = BX; access_write_linear(Bit32u(obase32 + 24), 2, 0, &temp16);
    temp16 = SP; access_write_linear(Bit32u(obase32 + 26), 2, 0, &temp16);
    temp16 = BP; access_write_linear(Bit32u(obase32 + 28), 2, 0, &temp16);
    temp16 = SI; access_write_linear(Bit32u(obase32 + 30), 2, 0, &temp16);
    temp16 = DI; access_write_linear(Bit32u(obase32 + 32), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value;
                 access_write_linear(Bit32u(obase32 + 34), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
                 access_write_linear(Bit32u(obase32 + 36), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
                 access_write_linear(Bit32u(obase32 + 38), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value;
                 access_write_linear(Bit32u(obase32 + 40), 2, 0, &temp16);
  }
  else {
    temp32 = EIP; access_write_linear(Bit32u(obase32 + 0x20), 4, 0, &temp32);
    temp32 = oldEFLAGS; access_write_linear(Bit32u(obase32 + 0x24), 4, 0, &temp32);
    temp32 = EAX; access_write_linear(Bit32u(obase32 + 0x28), 4, 0, &temp32);
    temp32 = ECX; access_write_linear(Bit32u(obase32 + 0x2c), 4, 0, &temp32);
    temp32 = EDX; access_write_linear(Bit32u(obase32 + 0x30), 4, 0, &temp32);
    temp32 = EBX; access_write_linear(Bit32u(obase32 + 0x34), 4, 0, &temp32);
    temp32 = ESP; access_write_linear(Bit32u(obase32 + 0x38), 4, 0, &temp32);
    temp32 = EBP; access_write_linear(Bit32u(obase32 + 0x3c), 4, 0, &temp32);
    temp32 = ESI; access_write_linear(Bit32u(obase32 + 0x40), 4, 0, &temp32);
    temp32 = EDI; access_write_linear(Bit32u(obase32 + 0x44), 4, 0, &temp32);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x48), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x4c), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x50), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x54), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x58), 2, 0, &temp16);
    temp16 = BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector.value;
                  access_write_linear(Bit32u(obase32 + 0x5c), 2, 0, &temp16);
  }

  // effect on link field of new task
  if (source == BX_TASK_FROM_CALL_OR_INT)
  {
    // set to selector of old task's TSS
    temp16 = BX_CPU_THIS_PTR tr.selector.value;
    access_write_linear(nbase32, 2, 0, &temp16);
  }

  // STEP 4: The new-task state is loaded from the TSS

  if (tss_descriptor->type <= 3) {
    access_read_linear(Bit32u(nbase32 + 14), 2, 0, BX_READ, &temp16);
      newEIP = temp16; // zero out upper word
    access_read_linear(Bit32u(nbase32 + 16), 2, 0, BX_READ, &temp16);
      newEFLAGS = temp16;

    // incoming TSS is 16bit:
    //   - upper word of general registers is set to 0xFFFF
    //   - upper word of eflags is zero'd
    //   - FS, GS are zero'd
    //   - upper word of eIP is zero'd
    access_read_linear(Bit32u(nbase32 + 18), 2, 0, BX_READ, &temp16);
      newEAX = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 20), 2, 0, BX_READ, &temp16);
      newECX = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 22), 2, 0, BX_READ, &temp16);
      newEDX = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 24), 2, 0, BX_READ, &temp16);
      newEBX = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 26), 2, 0, BX_READ, &temp16);
      newESP = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 28), 2, 0, BX_READ, &temp16);
      newEBP = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 30), 2, 0, BX_READ, &temp16);
      newESI = 0xffff0000 | temp16;
    access_read_linear(Bit32u(nbase32 + 32), 2, 0, BX_READ, &temp16);
      newEDI = 0xffff0000 | temp16;

    access_read_linear(Bit32u(nbase32 + 34), 2, 0, BX_READ, &raw_es_selector);
    access_read_linear(Bit32u(nbase32 + 36), 2, 0, BX_READ, &raw_cs_selector);
    access_read_linear(Bit32u(nbase32 + 38), 2, 0, BX_READ, &raw_ss_selector);
    access_read_linear(Bit32u(nbase32 + 40), 2, 0, BX_READ, &raw_ds_selector);
    access_read_linear(Bit32u(nbase32 + 42), 2, 0, BX_READ, &raw_ldt_selector);

    raw_fs_selector = 0; // use a NULL selector
    raw_gs_selector = 0; // use a NULL selector
    // No CR3 change for 286 task switch
    newCR3 = 0;   // keep compiler happy (not used)
    trap_word = 0; // keep compiler happy (not used)
  }
  else {
    if (BX_CPU_THIS_PTR cr0.get_PG())
      access_read_linear(Bit32u(nbase32 + 0x1c), 4, 0, BX_READ, &newCR3);
    else
      newCR3 = 0;   // keep compiler happy (not used)
    access_read_linear(Bit32u(nbase32 + 0x20), 4, 0, BX_READ, &newEIP);
    access_read_linear(Bit32u(nbase32 + 0x24), 4, 0, BX_READ, &newEFLAGS);
    access_read_linear(Bit32u(nbase32 + 0x28), 4, 0, BX_READ, &newEAX);
    access_read_linear(Bit32u(nbase32 + 0x2c), 4, 0, BX_READ, &newECX);
    access_read_linear(Bit32u(nbase32 + 0x30), 4, 0, BX_READ, &newEDX);
    access_read_linear(Bit32u(nbase32 + 0x34), 4, 0, BX_READ, &newEBX);
    access_read_linear(Bit32u(nbase32 + 0x38), 4, 0, BX_READ, &newESP);
    access_read_linear(Bit32u(nbase32 + 0x3c), 4, 0, BX_READ, &newEBP);
    access_read_linear(Bit32u(nbase32 + 0x40), 4, 0, BX_READ, &newESI);
    access_read_linear(Bit32u(nbase32 + 0x44), 4, 0, BX_READ, &newEDI);
    access_read_linear(Bit32u(nbase32 + 0x48), 2, 0, BX_READ, &raw_es_selector);
    access_read_linear(Bit32u(nbase32 + 0x4c), 2, 0, BX_READ, &raw_cs_selector);
    access_read_linear(Bit32u(nbase32 + 0x50), 2, 0, BX_READ, &raw_ss_selector);
    access_read_linear(Bit32u(nbase32 + 0x54), 2, 0, BX_READ, &raw_ds_selector);
    access_read_linear(Bit32u(nbase32 + 0x58), 2, 0, BX_READ, &raw_fs_selector);
    access_read_linear(Bit32u(nbase32 + 0x5c), 2, 0, BX_READ, &raw_gs_selector);
    access_read_linear(Bit32u(nbase32 + 0x60), 2, 0, BX_READ, &raw_ldt_selector);
    access_read_linear(Bit32u(nbase32 + 0x64), 2, 0, BX_READ, &trap_word);
  }

  // Step 5: If CALL, interrupt, or JMP, set busy flag in new task's
  //         TSS descriptor.  If IRET, leave set.

  if (source == BX_TASK_FROM_JUMP || source == BX_TASK_FROM_CALL_OR_INT)
  {
    // set the new task's busy bit
    Bit32u laddr = (Bit32u)(BX_CPU_THIS_PTR gdtr.base) + (tss_selector->index<<3) + 4;
    access_read_linear(laddr, 4, 0, BX_READ, &dword2);
    dword2 |= 0x200;
    access_write_linear(laddr, 4, 0, &dword2);
  }

  // Step 6: If JMP or IRET, clear busy bit in old task TSS descriptor,
  //         otherwise leave set.

  // effect on Busy bit of old task
  if (source == BX_TASK_FROM_JUMP || source == BX_TASK_FROM_IRET) {
    // Bit is cleared
    Bit32u laddr = (Bit32u) BX_CPU_THIS_PTR gdtr.base + (BX_CPU_THIS_PTR tr.selector.index<<3) + 4;
    access_read_linear(laddr, 4, 0, BX_READ, &temp32);
    temp32 &= ~0x200;
    access_write_linear(laddr, 4, 0, &temp32);
  }

  //
  // Commit point.  At this point, we commit to the new
  // context.  If an unrecoverable error occurs in further
  // processing, we complete the task switch without performing
  // additional access and segment availablility checks and
  // generate the appropriate exception prior to beginning
  // execution of the new task.
  //

  // Step 7: Load the task register with the segment selector and
  //        descriptor for the new task TSS.

  BX_CPU_THIS_PTR tr.selector = *tss_selector;
  BX_CPU_THIS_PTR tr.cache    = *tss_descriptor;
  BX_CPU_THIS_PTR tr.cache.type |= 2; // mark TSS in TR as busy

  // Step 8: Set TS flag in the CR0 image stored in the new task TSS.
  BX_CPU_THIS_PTR cr0.set_TS(1);

  // Task switch clears LE/L3/L2/L1/L0 in DR7
  BX_CPU_THIS_PTR dr7 &= ~0x00000155;

  // Step 9: If call or interrupt, set the NT flag in the eflags
  //         image stored in new task's TSS.  If IRET or JMP,
  //         NT is restored from new TSS eflags image. (no change)

  // effect on NT flag of new task
  if (source == BX_TASK_FROM_CALL_OR_INT) {
    newEFLAGS |= EFlagsNTMask; // NT flag is set
  }

  // Step 10: Load the new task (dynamic) state from new TSS.
  //          Any errors associated with loading and qualification of
  //          segment descriptors in this step occur in the new task's
  //          context.  State loaded here includes LDTR, CR3,
  //          EFLAGS, EIP, general purpose registers, and segment
  //          descriptor parts of the segment registers.

  if ((tss_descriptor->type >= 9) && BX_CPU_THIS_PTR cr0.get_PG()) {
    // change CR3 only if it actually modified
    if (newCR3 != BX_CPU_THIS_PTR cr3) {
      SetCR3(newCR3); // Tell paging unit about new cr3 value
      BX_DEBUG (("task_switch changing CR3 to 0x" FMT_PHY_ADDRX, newCR3));
      BX_INSTR_TLB_CNTRL(BX_CPU_ID, BX_INSTR_TASKSWITCH, newCR3);
    }
  }

  BX_CPU_THIS_PTR prev_rip = EIP = newEIP;

  EAX = newEAX;
  ECX = newECX;
  EDX = newEDX;
  EBX = newEBX;
  ESP = newESP;
  EBP = newEBP;
  ESI = newESI;
  EDI = newEDI;

  writeEFlags(newEFLAGS, EFlagsValidMask);

  // Fill in selectors for all segment registers.  If errors
  // occur later, the selectors will at least be loaded.
  parse_selector(raw_cs_selector, &cs_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector = cs_selector;
  parse_selector(raw_ds_selector, &ds_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].selector = ds_selector;
  parse_selector(raw_es_selector, &es_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].selector = es_selector;
  parse_selector(raw_ss_selector, &ss_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].selector = ss_selector;
  parse_selector(raw_fs_selector, &fs_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].selector = fs_selector;
  parse_selector(raw_gs_selector, &gs_selector);
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].selector = gs_selector;

  parse_selector(raw_ldt_selector, &ldt_selector);
  BX_CPU_THIS_PTR ldtr.selector = ldt_selector;

  // Start out with invalid descriptor caches, fill in
  // with values only as they are validated.
  BX_CPU_THIS_PTR ldtr.cache.valid = 0;
  BX_CPU_THIS_PTR ldtr.cache.u.system.limit = 0;
  BX_CPU_THIS_PTR ldtr.cache.u.system.limit_scaled = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES].cache.valid = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.valid = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache.valid = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS].cache.valid = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS].cache.valid = 0;
  BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS].cache.valid = 0;

  // LDTR
  if (ldt_selector.ti) {
    // LDT selector must be in GDT
    BX_INFO(("task_switch(exception after commit point): bad LDT selector TI=1"));
    exception(BX_TS_EXCEPTION, raw_ldt_selector & 0xfffc, 0);
  }

  if ((raw_ldt_selector & 0xfffc) != 0) {
    bx_bool good = fetch_raw_descriptor2(&ldt_selector, &dword1, &dword2);
    if (!good) {
      BX_ERROR(("task_switch(exception after commit point): bad LDT fetch"));
      exception(BX_TS_EXCEPTION, raw_ldt_selector & 0xfffc, 0);
    }

    parse_descriptor(dword1, dword2, &ldt_descriptor);

    // LDT selector of new task is valid, else #TS(new task's LDT)
    if (ldt_descriptor.valid==0 ||
        ldt_descriptor.type!=BX_SYS_SEGMENT_LDT ||
        ldt_descriptor.segment)
    {
      BX_ERROR(("task_switch(exception after commit point): bad LDT segment"));
      exception(BX_TS_EXCEPTION, raw_ldt_selector & 0xfffc, 0);
    }

    // LDT of new task is present in memory, else #TS(new tasks's LDT)
    if (! IS_PRESENT(ldt_descriptor)) {
      BX_ERROR(("task_switch(exception after commit point): LDT not present"));
      exception(BX_TS_EXCEPTION, raw_ldt_selector & 0xfffc, 0);
    }

    // All checks pass, fill in LDTR shadow cache
    BX_CPU_THIS_PTR ldtr.cache = ldt_descriptor;
  }
  else {
    // NULL LDT selector is OK, leave cache invalid
  }

  if (v8086_mode()) {
    // load seg regs as 8086 registers
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS], raw_cs_selector);
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS], raw_ss_selector);
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS], raw_ds_selector);
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES], raw_es_selector);
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS], raw_fs_selector);
    load_seg_reg(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS], raw_gs_selector);
  }
  else {

    // SS
    if ((raw_ss_selector & 0xfffc) != 0)
    {
      bx_bool good = fetch_raw_descriptor2(&ss_selector, &dword1, &dword2);
      if (!good) {
        BX_ERROR(("task_switch(exception after commit point): bad SS fetch"));
        exception(BX_TS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
      }

      parse_descriptor(dword1, dword2, &ss_descriptor);
      // SS selector must be within its descriptor table limits else #TS(SS)
      // SS descriptor AR byte must must indicate writable data segment,
      // else #TS(SS)
      if (ss_descriptor.valid==0 || ss_descriptor.segment==0 ||
           IS_CODE_SEGMENT(ss_descriptor.type) ||
          !IS_DATA_SEGMENT_WRITEABLE(ss_descriptor.type))
      {
        BX_ERROR(("task_switch(exception after commit point): SS not valid or writeable segment"));
        exception(BX_TS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
      }

      //
      // Stack segment is present in memory, else #SS(new stack segment)
      //
      if (! IS_PRESENT(ss_descriptor)) {
        BX_ERROR(("task_switch(exception after commit point): SS not present"));
        exception(BX_SS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
      }

      // Stack segment DPL matches CS.RPL, else #TS(new stack segment)
      if (ss_descriptor.dpl != cs_selector.rpl) {
        BX_ERROR(("task_switch(exception after commit point): SS.rpl != CS.RPL"));
        exception(BX_TS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
      }

      // Stack segment DPL matches selector RPL, else #TS(new stack segment)
      if (ss_descriptor.dpl != ss_selector.rpl) {
        BX_ERROR(("task_switch(exception after commit point): SS.dpl != SS.rpl"));
        exception(BX_TS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
      }

      // All checks pass, fill in shadow cache
      BX_CPU_THIS_PTR sregs[BX_SEG_REG_SS].cache = ss_descriptor;
    }
    else {
      // SS selector is valid, else #TS(new stack segment)
      BX_ERROR(("task_switch(exception after commit point): SS NULL"));
      exception(BX_TS_EXCEPTION, raw_ss_selector & 0xfffc, 0);
    }

    // if new selector is not null then perform following checks:
    //    index must be within its descriptor table limits else #TS(selector)
    //    AR byte must indicate data or readable code else #TS(selector)
    //    if data or non-conforming code then:
    //      DPL must be >= CPL else #TS(selector)
    //      DPL must be >= RPL else #TS(selector)
    //    AR byte must indicate PRESENT else #NP(selector)
    //    load cache with new segment descriptor and set valid bit

    // CS
    if ((raw_cs_selector & 0xfffc) != 0) {
      bx_bool good = fetch_raw_descriptor2(&cs_selector, &dword1, &dword2);
      if (!good) {
        BX_ERROR(("task_switch(exception after commit point): bad CS fetch"));
        exception(BX_TS_EXCEPTION, raw_cs_selector & 0xfffc, 0);
      }

      parse_descriptor(dword1, dword2, &cs_descriptor);

      // CS descriptor AR byte must indicate code segment else #TS(CS)
      if (cs_descriptor.valid==0 || cs_descriptor.segment==0 ||
          IS_DATA_SEGMENT(cs_descriptor.type))
      {
        BX_ERROR(("task_switch(exception after commit point): CS not valid executable seg"));
        exception(BX_TS_EXCEPTION, raw_cs_selector & 0xfffc, 0);
      }

      // if non-conforming then DPL must equal selector RPL else #TS(CS)
      if (IS_CODE_SEGMENT_NON_CONFORMING(cs_descriptor.type) &&
          cs_descriptor.dpl != cs_selector.rpl)
      {
        BX_ERROR(("task_switch(exception after commit point): non-conforming: CS.dpl!=CS.RPL"));
        exception(BX_TS_EXCEPTION, raw_cs_selector & 0xfffc, 0);
      }

      // if conforming then DPL must be <= selector RPL else #TS(CS)
      if (IS_CODE_SEGMENT_CONFORMING(cs_descriptor.type) &&
          cs_descriptor.dpl > cs_selector.rpl)
      {
        BX_ERROR(("task_switch(exception after commit point): conforming: CS.dpl>RPL"));
        exception(BX_TS_EXCEPTION, raw_cs_selector & 0xfffc, 0);
      }

      // Code segment is present in memory, else #NP(new code segment)
      if (! IS_PRESENT(cs_descriptor)) {
        BX_ERROR(("task_switch(exception after commit point): CS.p==0"));
        exception(BX_NP_EXCEPTION, raw_cs_selector & 0xfffc, 0);
      }

      // All checks pass, fill in shadow cache
      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache = cs_descriptor;
    }
    else {
      // If new cs selector is null #TS(CS)
      BX_ERROR(("task_switch(exception after commit point): CS NULL"));
      exception(BX_TS_EXCEPTION, raw_cs_selector & 0xfffc, 0);
    }

    updateFetchModeMask();

#if BX_CPU_LEVEL >= 4 && BX_SUPPORT_ALIGNMENT_CHECK
    handleAlignmentCheck(); // task switch, CPL was modified
#endif

    task_switch_load_selector(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_DS],
        &ds_selector, raw_ds_selector, cs_selector.rpl);
    task_switch_load_selector(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_ES],
        &es_selector, raw_es_selector, cs_selector.rpl);
    task_switch_load_selector(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_FS],
        &fs_selector, raw_fs_selector, cs_selector.rpl);
    task_switch_load_selector(&BX_CPU_THIS_PTR sregs[BX_SEG_REG_GS],
        &gs_selector, raw_gs_selector, cs_selector.rpl);
  }

  if ((tss_descriptor->type>=9) && (trap_word & 0x1)) {
    BX_CPU_THIS_PTR debug_trap |= 0x00008000; // BT flag in DR6
    BX_CPU_THIS_PTR async_event = 1; // so processor knows to check
    BX_INFO(("task_switch: T bit set in new TSS"));
  }

  //
  // Step 14: Begin execution of new task.
  //
  BX_DEBUG(("TASKING: LEAVE"));
}

void BX_CPU_C::task_switch_load_selector(bx_segment_reg_t *seg,
                 bx_selector_t *selector, Bit16u raw_selector, Bit8u cs_rpl)
{
  bx_descriptor_t descriptor;
  Bit32u dword1, dword2;

  // NULL selector is OK, will leave cache invalid
  if ((raw_selector & 0xfffc) != 0)
  {
    bx_bool good = fetch_raw_descriptor2(selector, &dword1, &dword2);
    if (!good) {
      BX_ERROR(("task_switch(%s): bad selector fetch !", strseg(seg)));
      exception(BX_TS_EXCEPTION, raw_selector & 0xfffc, 0);
    }

    parse_descriptor(dword1, dword2, &descriptor);

    /* AR byte must indicate data or readable code segment else #TS(selector) */
    if (descriptor.segment==0 || (IS_CODE_SEGMENT(descriptor.type) &&
        IS_CODE_SEGMENT_READABLE(descriptor.type) == 0))
    {
      BX_ERROR(("task_switch(%s): not data or readable code !", strseg(seg)));
      exception(BX_TS_EXCEPTION, raw_selector & 0xfffc, 0);
    }

    /* If data or non-conforming code, then both the RPL and the CPL
     * must be less than or equal to DPL in AR byte else #GP(selector) */
    if (IS_DATA_SEGMENT(descriptor.type) ||
        IS_CODE_SEGMENT_NON_CONFORMING(descriptor.type))
    {
      if ((selector->rpl > descriptor.dpl) || (cs_rpl > descriptor.dpl)) {
        BX_ERROR(("load_seg_reg(%s): RPL & CPL must be <= DPL", strseg(seg)));
        exception(BX_TS_EXCEPTION, raw_selector & 0xfffc, 0);
      }
    }

    if (! IS_PRESENT(descriptor)) {
      BX_ERROR(("task_switch(%s): descriptor not present !", strseg(seg)));
      exception(BX_NP_EXCEPTION, raw_selector & 0xfffc, 0);
    }

    // All checks pass, fill in shadow cache
    seg->cache = descriptor;
  }
}

void BX_CPU_C::get_SS_ESP_from_TSS(unsigned pl, Bit16u *ss, Bit32u *esp)
{
  if (BX_CPU_THIS_PTR tr.cache.valid==0)
    BX_PANIC(("get_SS_ESP_from_TSS: TR.cache invalid"));

  if (BX_CPU_THIS_PTR tr.cache.type==BX_SYS_SEGMENT_AVAIL_386_TSS ||
      BX_CPU_THIS_PTR tr.cache.type==BX_SYS_SEGMENT_BUSY_386_TSS)
  {
    // 32-bit TSS
    Bit32u TSSstackaddr = 8*pl + 4;
    if ((TSSstackaddr+7) > BX_CPU_THIS_PTR tr.cache.u.system.limit_scaled) {
      BX_DEBUG(("get_SS_ESP_from_TSS(386): TSSstackaddr > TSS.LIMIT"));
      exception(BX_TS_EXCEPTION, BX_CPU_THIS_PTR tr.selector.value & 0xfffc, 0);
    }
    access_read_linear(BX_CPU_THIS_PTR tr.cache.u.system.base +
      TSSstackaddr+4, 2, 0, BX_READ, ss);
    access_read_linear(BX_CPU_THIS_PTR tr.cache.u.system.base +
      TSSstackaddr,   4, 0, BX_READ, esp);
  }
  else if (BX_CPU_THIS_PTR tr.cache.type==BX_SYS_SEGMENT_AVAIL_286_TSS ||
           BX_CPU_THIS_PTR tr.cache.type==BX_SYS_SEGMENT_BUSY_286_TSS)
  {
    // 16-bit TSS
    Bit16u temp16;
    Bit32u TSSstackaddr = 4*pl + 2;
    if ((TSSstackaddr+4) > BX_CPU_THIS_PTR tr.cache.u.system.limit_scaled) {
      BX_DEBUG(("get_SS_ESP_from_TSS(286): TSSstackaddr > TSS.LIMIT"));
      exception(BX_TS_EXCEPTION, BX_CPU_THIS_PTR tr.selector.value & 0xfffc, 0);
    }
    access_read_linear(BX_CPU_THIS_PTR tr.cache.u.system.base +
      TSSstackaddr+2, 2, 0, BX_READ, ss);
    access_read_linear(BX_CPU_THIS_PTR tr.cache.u.system.base +
      TSSstackaddr,   2, 0, BX_READ, &temp16);
    *esp = temp16; // truncate
  }
  else {
    BX_PANIC(("get_SS_ESP_from_TSS: TR is bogus type (%u)",
             (unsigned) BX_CPU_THIS_PTR tr.cache.type));
  }
}

#if BX_SUPPORT_X86_64
void BX_CPU_C::get_RSP_from_TSS(unsigned pl, Bit64u *rsp)
{
  if (BX_CPU_THIS_PTR tr.cache.valid==0)
    BX_PANIC(("get_RSP_from_TSS: TR.cache invalid"));

  // 32-bit TSS
  Bit32u TSSstackaddr = 8*pl + 4;
  if ((TSSstackaddr+7) > BX_CPU_THIS_PTR tr.cache.u.system.limit_scaled) {
    BX_DEBUG(("get_RSP_from_TSS(): TSSstackaddr > TSS.LIMIT"));
    exception(BX_TS_EXCEPTION, BX_CPU_THIS_PTR tr.selector.value & 0xfffc, 0);
  }

  access_read_linear(BX_CPU_THIS_PTR tr.cache.u.system.base +
    TSSstackaddr, 8, 0, BX_READ, rsp);
}
#endif  // #if BX_SUPPORT_X86_64
