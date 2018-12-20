/////////////////////////////////////////////////////////////////////////
//// $Id: plex86-interface.cc,v 1.13 2008/05/23 17:49:43 sshwarts Exp $
///////////////////////////////////////////////////////////////////////////
////
////  Copyright (C) 2002  Kevin P. Lawton
////
////  This library is free software; you can redistribute it and/or
////  modify it under the terms of the GNU Lesser General Public
////  License as published by the Free Software Foundation; either
////  version 2 of the License, or (at your option) any later version.
////
////  This library is distributed in the hope that it will be useful,
////  but WITHOUT ANY WARRANTY; without even the implied warranty of
////  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
////  Lesser General Public License for more details.
////
////  You should have received a copy of the GNU Lesser General Public
////  License along with this library; if not, write to the Free Software
////  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA


#include "bochs.h"
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/mman.h>
#include "plex86-interface.h"

#define LOG_THIS genlog->

unsigned      plex86State = 0;
int           plex86FD = -1;

asm (".comm   plex86PrintBufferPage,4096,4096");
asm (".comm   plex86GuestCPUPage,4096,4096");
extern Bit8u       plex86PrintBufferPage[];
extern Bit8u       plex86GuestCPUPage[];

static Bit8u       *plex86MemPtr = 0;
static size_t       plex86MemSize = 0;
static Bit8u       *plex86PrintBuffer = plex86PrintBufferPage;
static guest_cpu_t *plex86GuestCPU = (guest_cpu_t *) plex86GuestCPUPage;

static void copyPlex86StateToBochs(BX_CPU_C *cpu);
static void copyBochsDescriptorToPlex86(descriptor_t *, bx_descriptor_t *);
static void copyPlex86DescriptorToBochs(BX_CPU_C *,
                                        bx_descriptor_t *, descriptor_t *);
static int  openFD(void);

static unsigned faultCount[32];


int openFD(void)
{
  if (plex86State) {
    // This should be the first operation; no state should be set yet.
    fprintf(stderr, "plex86: openFD: plex86State = 0x%x\n", plex86State);
    return(0); // Error.
  }

  // Open a new VM.
  fprintf(stderr, "plex86: opening VM.\n");
  fprintf(stderr, "plex86: trying /dev/misc/plex86...");
  plex86FD = open("/dev/misc/plex86", O_RDWR);
  if (plex86FD < 0) {
    fprintf(stderr, "failed.\n");
    // Try the old name.
    fprintf(stderr, "plex86: trying /dev/plex86...");
    plex86FD = open("/dev/plex86", O_RDWR);
    if (plex86FD < 0) {
      fprintf(stderr, "failed.\n");
      fprintf(stderr, "plex86: did you load the kernel module?"
              "  Read the toplevel README file!\n");
      perror ("open");
      return(-1); // Error.
    }
  }
  fprintf(stderr, "OK.\n");
  return(1); // OK.
}

unsigned plex86CpuInfo(BX_CPU_C *cpu)
{
  cpuid_info_t bochsCPUID;

  if (plex86FD < 0) {
    // If the plex86 File Descriptor has not been opened yet.
    if (!openFD()) {
      return(0); // Error.
    }
  }

  bochsCPUID.vendorDWord0 = cpu->cpuidInfo.vendorDWord0;
  bochsCPUID.vendorDWord1 = cpu->cpuidInfo.vendorDWord1;
  bochsCPUID.vendorDWord2 = cpu->cpuidInfo.vendorDWord2;
  bochsCPUID.procSignature.raw = cpu->cpuidInfo.procSignature;
  bochsCPUID.featureFlags.raw  = cpu->cpuidInfo.featureFlags;

  fprintf(stderr, "plex86: passing guest CPUID to plex86.\n");
  if (ioctl(plex86FD, PLEX86_CPUID, &bochsCPUID)) {
    perror("ioctl CPUID: ");
    return(0); // Error.
  }

  return(1); // OK.
}

unsigned plex86TearDown(void)
{
  fprintf(stderr, "plex86: plex86TearDown called.\n");

  fprintf(stderr, "plex86: guest Fault Count (FYI):\n");
  for (unsigned f=0; f<32; f++) {
    if (faultCount[f])
      fprintf(stderr, "plex86:  FC[%u] = %u\n", f, faultCount[f]);
  }

  if (plex86FD < 0) {
    fprintf(stderr, "plex86: plex86TearDown: FD not open.\n");
    return(0);
  }

  if (plex86State & Plex86StateMMapPhyMem) {
    fprintf(stderr, "plex86: unmapping guest physical memory.\n");
  }
  plex86State &= ~Plex86StateMMapPhyMem;

  if (plex86State & Plex86StateMMapPrintBuffer) {
  }
  plex86State &= ~Plex86StateMMapPrintBuffer;

  if (plex86State & Plex86StateMMapGuestCPU) { }
  plex86State &= ~Plex86StateMMapGuestCPU;

  fprintf(stderr, "plex86: tearing down VM.\n");
  if (ioctl(plex86FD, PLEX86_TEARDOWN, 0) == -1) {
    perror("ioctl TEARDOWN: ");
    return(0); // Failed.
  }
  plex86State &= ~Plex86StateMemAllocated;

  // Close the connection to the kernel module.
  fprintf(stderr, "plex86: closing VM device.\n");
  if (close(plex86FD) == -1) {
    perror("close of VM device\n");
    return(0); // Failed.
  }

  plex86FD = -1; // File descriptor is now closed.

  plex86State = 0; // For good measure.

  return(1); // OK.
}

unsigned plex86ExecuteInVM(BX_CPU_C *cpu)
{
  plex86IoctlExecute_t executeMsg;
  int ret;

  if (plex86State != Plex86StateReady) {
    fprintf(stderr, "plex86: plex86ExecuteInVM: not in ready state (0x%x)\n",
            plex86State);
    BX_PANIC(("plex86ExecuteInVM: bailing"));
    return(0);
  }

  executeMsg.executeMethod = Plex86ExecuteMethodNative;
  plex86GuestCPU->edi = cpu->gen_reg[BX_32BIT_REG_EDI].dword.erx;
  plex86GuestCPU->esi = cpu->gen_reg[BX_32BIT_REG_ESI].dword.erx;
  plex86GuestCPU->ebp = cpu->gen_reg[BX_32BIT_REG_EBP].dword.erx;
  plex86GuestCPU->esp = cpu->gen_reg[BX_32BIT_REG_ESP].dword.erx;
  plex86GuestCPU->ebx = cpu->gen_reg[BX_32BIT_REG_EBX].dword.erx;
  plex86GuestCPU->edx = cpu->gen_reg[BX_32BIT_REG_EDX].dword.erx;
  plex86GuestCPU->ecx = cpu->gen_reg[BX_32BIT_REG_ECX].dword.erx;
  plex86GuestCPU->eax = cpu->gen_reg[BX_32BIT_REG_EAX].dword.erx;

  plex86GuestCPU->eflags = cpu->eflags.val32;
  plex86GuestCPU->eip = cpu->get_eip();

  // ES/CS/SS/DS/FS/GS
  for (unsigned s=0; s<6; s++) {
    plex86GuestCPU->sreg[s].sel.raw = cpu->sregs[s].selector.value;
    copyBochsDescriptorToPlex86(&plex86GuestCPU->sreg[s].des,
                                &cpu->sregs[s].cache);
    plex86GuestCPU->sreg[s].valid = cpu->sregs[s].cache.valid;
  }

  // LDTR
  plex86GuestCPU->ldtr.sel.raw = cpu->ldtr.selector.value;
  copyBochsDescriptorToPlex86(&plex86GuestCPU->ldtr.des, &cpu->ldtr.cache);
  plex86GuestCPU->ldtr.valid = cpu->ldtr.cache.valid;

  // TR
  plex86GuestCPU->tr.sel.raw = cpu->tr.selector.value;
  copyBochsDescriptorToPlex86(&plex86GuestCPU->tr.des, &cpu->tr.cache);
  plex86GuestCPU->tr.valid = cpu->tr.cache.valid;

  // GDTR/IDTR
  plex86GuestCPU->gdtr.base  = cpu->gdtr.base;
  plex86GuestCPU->gdtr.limit = cpu->gdtr.limit;
  plex86GuestCPU->idtr.base  = cpu->idtr.base;
  plex86GuestCPU->idtr.limit = cpu->idtr.limit;

  plex86GuestCPU->dr[0] = cpu->dr[0];
  plex86GuestCPU->dr[1] = cpu->dr[1];
  plex86GuestCPU->dr[2] = cpu->dr[2];
  plex86GuestCPU->dr[3] = cpu->dr[3];
  plex86GuestCPU->dr6 = cpu->dr6;
  plex86GuestCPU->dr7 = cpu->dr7;

  plex86GuestCPU->tr3 = 0; // Unimplemented in bochs.
  plex86GuestCPU->tr4 = 0; // Unimplemented in bochs.
  plex86GuestCPU->tr5 = 0; // Unimplemented in bochs.
  plex86GuestCPU->tr6 = 0; // Unimplemented in bochs.
  plex86GuestCPU->tr7 = 0; // Unimplemented in bochs.

  plex86GuestCPU->cr0.raw = cpu->cr0.val32;
  plex86GuestCPU->cr1     = cpu->cr1;
  plex86GuestCPU->cr2     = cpu->cr2;
  plex86GuestCPU->cr3     = cpu->cr3;
  plex86GuestCPU->cr4.raw = cpu->cr4.registerValue;

  plex86GuestCPU->a20Enable = BX_GET_ENABLE_A20();

  ret = ioctl(plex86FD, PLEX86_EXECUTE, &executeMsg);
  if (ret != 0) {
    fprintf(stderr, "plex86: ioctl(PLEX86_EXECUTE): ");
    switch (ret) {
      case Plex86NoExecute_Method:
        fprintf(stderr, "bad execute method.\n");
        break;
      case Plex86NoExecute_CR0:
        fprintf(stderr, "bad CR0 value.\n");
        break;
      case Plex86NoExecute_CR4:
        fprintf(stderr, "bad CR4 value.\n");
        break;
      case Plex86NoExecute_CS:
        fprintf(stderr, "bad CS value.\n");
        break;
      case Plex86NoExecute_A20:
        fprintf(stderr, "bad A20 enable value.\n");
        break;
      case Plex86NoExecute_Selector:
        fprintf(stderr, "bad selector value.\n");
        break;
      case Plex86NoExecute_DPL:
        fprintf(stderr, "bad descriptor DPL.\n");
        break;
      case Plex86NoExecute_EFlags:
        fprintf(stderr, "bad EFlags.\n");
        break;
      case Plex86NoExecute_Panic:
        fprintf(stderr, "panic.\n");
        break;
      case Plex86NoExecute_VMState:
        fprintf(stderr, "bad VM state.\n");
        break;
      default:
        fprintf(stderr, "ret = %d\n", ret);
    }
  }
  else {
    switch (executeMsg.monitorState.request) {
      case MonReqFlushPrintBuf:
        fprintf(stderr, "plex86: MonReqFlushPrintBuf:\n");
        fprintf(stderr, "::%s\n", plex86PrintBuffer);
        break;
      case MonReqPanic:
        fprintf(stderr, "plex86: MonReqPanic:\n");
        fprintf(stderr, "::%s\n", plex86PrintBuffer);
        break;
      //case MonReqNone:
      //  copyPlex86StateToBochs(cpu);
      //  return(0); /* All OK. */
      case MonReqGuestFault:
        faultCount[ executeMsg.monitorState.guestFaultNo ]++;
        copyPlex86StateToBochs(cpu);
        return(0); /* All OK. */
      default:
        fprintf(stderr, "plex86: executeMsg.request = %u\n",
                executeMsg.monitorState.request);
        break;
    }
  }

  plex86TearDown();
  BX_PANIC(("plex86ExecuteInVM: bailing"));

  return(0);
}

void copyPlex86StateToBochs(BX_CPU_C *cpu)
{
  cpu->gen_reg[BX_32BIT_REG_EDI].dword.erx = plex86GuestCPU->edi;
  cpu->gen_reg[BX_32BIT_REG_ESI].dword.erx = plex86GuestCPU->esi;
  cpu->gen_reg[BX_32BIT_REG_EBP].dword.erx = plex86GuestCPU->ebp;
  cpu->gen_reg[BX_32BIT_REG_ESP].dword.erx = plex86GuestCPU->esp;
  cpu->gen_reg[BX_32BIT_REG_EBX].dword.erx = plex86GuestCPU->ebx;
  cpu->gen_reg[BX_32BIT_REG_EDX].dword.erx = plex86GuestCPU->edx;
  cpu->gen_reg[BX_32BIT_REG_ECX].dword.erx = plex86GuestCPU->ecx;
  cpu->gen_reg[BX_32BIT_REG_EAX].dword.erx = plex86GuestCPU->eax;

  cpu->eflags.val32 = plex86GuestCPU->eflags;
  cpu->gen_reg[BX_32BIT_REG_EIP].dword.erx = plex86GuestCPU->eip;

  // Set fields used for exception processing.
  cpu->prev_rip = plex86GuestCPU->eip;

  // ES/CS/SS/DS/FS/GS
  for (unsigned s=0; s<6; s++) {
    cpu->sregs[s].selector.value = plex86GuestCPU->sreg[s].sel.raw;
    cpu->sregs[s].cache.valid    = plex86GuestCPU->sreg[s].valid;
    if ((cpu->sregs[s].selector.value & 0xfffc) == 0) {
      /* Null selector. */
      if (cpu->sregs[s].cache.valid) {
        plex86TearDown();
        BX_PANIC(("copyPlex86StateToBochs: null descriptor [%u] "
                  "with descriptor cache valid bit set.", s));
      }
      /* valid bit == 0, invalidates a bochs descriptor cache. */
    }
    else {
      /* Non-null selector. */
      if (cpu->sregs[s].cache.valid==0) {
        plex86TearDown();
        BX_PANIC(("copyPlex86StateToBochs: non-null descriptor [%u] "
                  "with descriptor cache valid bit clear.", s));
      }
      copyPlex86DescriptorToBochs(cpu, &cpu->sregs[s].cache,
          &plex86GuestCPU->sreg[s].des);
    }
  }
}

void copyBochsDescriptorToPlex86(descriptor_t *plex86Desc, bx_descriptor_t *bochsDesc)
{
  // For now this function is a hack to convert from bochs descriptor
  // cache fields which are parsed out into separate fields, to
  // a packed descriptor format as stored in a real segment descriptor.
  // This is user only for code/data segments and the LDTR/TR.
  // Ideally, bochs would store the 64-bit segment descriptor when
  // it loads segment registers.

  if (bochsDesc->valid == 0) {
    memset(plex86Desc, 0, sizeof(*plex86Desc));
    return;
  }
  plex86Desc->p = bochsDesc->p;
  plex86Desc->dpl = bochsDesc->dpl;
  plex86Desc->type = (bochsDesc->segment<<4) | bochsDesc->type;
  if (bochsDesc->segment) {
    // Code/Data segment type.
    Bit32u limit = bochsDesc->u.segment.limit;
    plex86Desc->limit_low  = limit; // Only lower 16-bits.
    plex86Desc->limit_high = limit >> 16;
    Bit32u base = bochsDesc->u.segment.base;
    plex86Desc->base_low  = base;
    plex86Desc->base_med  = base >> 16;
    plex86Desc->base_high = base >> 24;
    plex86Desc->avl = bochsDesc->u.segment.avl;
    plex86Desc->reserved = 0;
    plex86Desc->d_b = bochsDesc->u.segment.d_b;
    plex86Desc->g   = bochsDesc->u.segment.g;
    }
  else if (bochsDesc->type == BX_SYS_SEGMENT_AVAIL_286_TSS ||
           bochsDesc->type == BX_SYS_SEGMENT_AVAIL_386_TSS ||
           bochsDesc->type == BX_SYS_SEGMENT_LDT)
  {
    // LDT or TSS
    Bit32u limit = bochsDesc->u.system.limit;
    plex86Desc->limit_low  = limit; // Only lower 16-bits.
    plex86Desc->limit_high = limit >> 16;
    Bit32u base = bochsDesc->u.system.base;
    plex86Desc->base_low  = base;
    plex86Desc->base_med  = base >> 16;
    plex86Desc->base_high = base >> 24;
    plex86Desc->avl = bochsDesc->u.system.avl;
    plex86Desc->reserved = 0;
    plex86Desc->d_b = 0;
    plex86Desc->g   = bochsDesc->u.system.g;
  }
  else {
    BX_PANIC(("copyBochsDescriptorToPlex86: desc type = %u.",
              bochsDesc->type));
  }
}

void copyPlex86DescriptorToBochs(BX_CPU_C *cpu,
                            bx_descriptor_t *bochsDesc, descriptor_t *plex86Desc)
{
  Bit32u dword1, dword2, *dwordPtr;
  dwordPtr = (Bit32u *) plex86Desc;

  /* We can assume little endian, since we're running an x86 VM. */
  dword1 = dwordPtr[0];
  dword2 = dwordPtr[1];
  cpu->parse_descriptor(dword1, dword2, bochsDesc);
}

unsigned plex86RegisterGuestMemory(Bit8u *vector, unsigned bytes)
{
  plex86IoctlRegisterMem_t ioctlMsg;

  if (plex86FD < 0) {
    // If the plex86 File Descriptor has not been opened yet.
    if (!openFD()) {
      return(0); // Error.
    }
  }

  if (bytes & 0x3fffff) {
    // Memory size must be multiple of 4Meg.
    fprintf(stderr, "plex86: RegisterGuestMemory: memory size of %u bytes"
                    "is not a 4Meg increment.\n", bytes);
    return(0); // Error.
  }
  if (((unsigned)vector) & 0xfff) {
    // Memory vector must be page aligned.
    fprintf(stderr, "plex86: RegisterGuestMemory: vector not page aligned.");
    return(0); // Error.
  }
  ioctlMsg.nMegs = bytes >> 20;
  ioctlMsg.guestPhyMemVector = (Bit32u) vector;
  ioctlMsg.logBufferWindow   = (Bit32u) plex86PrintBuffer;
  ioctlMsg.guestCPUWindow    = (Bit32u) plex86GuestCPU;
  if (ioctl(plex86FD, PLEX86_REGISTER_MEMORY, &ioctlMsg) == -1) {
    return(0); // Error.
  }
  plex86MemSize = bytes;

  /* For now... */
plex86State |= Plex86StateMemAllocated;
plex86State |= Plex86StateMMapPhyMem;
plex86State |= Plex86StateMMapPrintBuffer;
plex86State |= Plex86StateMMapGuestCPU;
// Zero out printbuffer and guestcpu here?

  fprintf(stderr, "plex86: RegisterGuestMemory: %uMB succeeded.\n",
          ioctlMsg.nMegs);
  return(1); // OK.
}

unsigned plex86UnregisterGuestMemory(Bit8u *vector, unsigned bytes)
{
  return(1); // OK.
}
