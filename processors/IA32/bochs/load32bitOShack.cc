/////////////////////////////////////////////////////////////////////////
// $Id: load32bitOShack.cc,v 1.30 2008/05/01 20:08:36 sshwarts Exp $
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


#include "bochs.h"
#include "cpu/cpu.h"
#include "iodev/iodev.h"
#define LOG_THIS genlog->


static void bx_load_linux_hack(void);
static void bx_load_null_kernel_hack(void);
static Bit32u bx_load_kernel_image(char *path, Bit32u paddr);

void bx_load32bitOSimagehack(void)
{
  if (SIM->get_param_string(BXPN_LOAD32BITOS_IOLOG) &&
     (SIM->get_param_string(BXPN_LOAD32BITOS_IOLOG)->getptr()[0] != '\0'))
  {

    // Replay IO from log to initialize IO devices to
    // a reasonable state needed for the OS.  This is done
    // in lieu of running the 16-bit BIOS to init things,
    // since we want to test straight 32bit stuff for
    // freemware.

    FILE *fp = fopen(SIM->get_param_string(BXPN_LOAD32BITOS_IOLOG)->getptr(), "r");
    if (fp == NULL) {
      BX_PANIC(("could not open IO init file."));
    }

    while (1) {
      unsigned len, op, port, val;
      int ret;
      ret = fscanf(fp, "%u %u %x %x\n", &len, &op, &port, &val);
      if (ret != 4) {
        BX_PANIC(("could not open IO init file."));
      }
      if (op == 0) {
        // read
        bx_devices.inp(port, len);
      }
      else if (op == 1) {
        // write
        bx_devices.outp(port, val, len);
      }
      else {
        BX_PANIC(("bad IO op in init filen"));
      }
      if (feof(fp)) break;
    }
  } //if iolog file to load

  // Invoke proper hack depending on which OS image we're loading
  switch (SIM->get_param_enum(BXPN_LOAD32BITOS_WHICH)->get()) {
    case Load32bitOSLinux:
      bx_load_linux_hack();
      break;
    case Load32bitOSNullKernel:
      bx_load_null_kernel_hack();
      break;
    default:
      BX_PANIC(("load32bitOSImage: OS not recognized"));
    }
}

struct gdt_entry
{
  Bit32u low;
  Bit32u high;
};

struct linux_setup_params
{
   /* 0x000 */ Bit8u   orig_x;
   /* 0x001 */ Bit8u   orig_y;
   /* 0x002 */ Bit16u  memory_size_std;
   /* 0x004 */ Bit16u  orig_video_page;
   /* 0x006 */ Bit8u   orig_video_mode;
   /* 0x007 */ Bit8u   orig_video_cols;
   /* 0x008 */ Bit16u  unused1;
   /* 0x00a */ Bit16u  orig_video_ega_bx;
   /* 0x00c */ Bit16u  unused2;
   /* 0x00e */ Bit8u   orig_video_lines;
   /* 0x00f */ Bit8u   orig_video_isVGA;
   /* 0x010 */ Bit16u  orig_video_points;
   /* 0x012 */ Bit8u   pad1[0x40 - 0x12];
   /* 0x040 */ Bit8u   apm_info[0x80 - 0x40];
   /* 0x080 */ Bit8u   hd0_info[16];
   /* 0x090 */ Bit8u   hd1_info[16];
   /* 0x0a0 */ Bit8u   pad2[0x1e0 - 0xa0];
   /* 0x1e0 */ Bit32u  memory_size_ext;
   /* 0x1e4 */ Bit8u   pad3[0x1f1 - 0x1e4];
   /* 0x1f1 */ Bit8u   setup_sects;
   /* 0x1f2 */ Bit16u  mount_root_rdonly;
   /* 0x1f4 */ Bit16u  sys_size;
   /* 0x1f6 */ Bit16u  swap_dev;
   /* 0x1f8 */ Bit16u  ramdisk_flags;
   /* 0x1fa */ Bit16u  vga_mode;
   /* 0x1fc */ Bit16u  orig_root_dev;
   /* 0x1fe */ Bit16u  bootsect_magic;
   /* 0x200 */ Bit8u   pad4[0x210 - 0x200];
   /* 0x210 */ Bit32u  loader_type;
   /* 0x214 */ Bit32u  kernel_start;
   /* 0x218 */ Bit32u  initrd_start;
   /* 0x21c */ Bit32u  initrd_size;
   /* 0x220 */ Bit8u   pad5[0x400 - 0x220];
   /* 0x400 */ struct  gdt_entry gdt[128];
   /* 0x800 */ Bit8u   commandline[2048];
};

static void bx_load_linux_setup_params(Bit32u initrd_start, Bit32u initrd_size)
{
  struct linux_setup_params *params =
         (struct linux_setup_params *) BX_MEM(0)->get_vector(0x00090000);

  memset(params, '\0', sizeof(*params));

  /* Video settings (standard VGA) */
  params->orig_x = 0;
  params->orig_y = 0;
  params->orig_video_page = 0;
  params->orig_video_mode = 3;
  params->orig_video_cols = 80;
  params->orig_video_lines = 25;
  params->orig_video_points = 16;
  params->orig_video_isVGA = 1;
  params->orig_video_ega_bx = 3;

  /* Memory size (total mem - 1MB, in KB) */
  params->memory_size_ext = (BX_MEM(0)->get_memory_len()/(1024*1024) - 1) * 1024;

  /* Boot parameters */
  params->loader_type = 1;
  params->bootsect_magic = 0xaa55;
  params->mount_root_rdonly = 0;
  params->orig_root_dev = 0x0100;
  params->initrd_start = initrd_start;
  params->initrd_size  = initrd_size;

  /* Initial GDT */
  params->gdt[2].high = 0x00cf9a00;
  params->gdt[2].low  = 0x0000ffff;
  params->gdt[3].high = 0x00cf9200;
  params->gdt[3].low  = 0x0000ffff;
}

void bx_load_linux_hack(void)
{
  Bit32u initrd_start = 0, initrd_size = 0;

  // The RESET function will have been called first.
  // Set CPU and memory features which are assumed at this point.

  // Load Linux kernel image
  bx_load_kernel_image(SIM->get_param_string(BXPN_LOAD32BITOS_PATH)->getptr(), 0x100000);

  // Load initial ramdisk image if requested
  char *tmpPtr = SIM->get_param_string(BXPN_LOAD32BITOS_INITRD)->getptr();
  if (tmpPtr && tmpPtr[0]) /* The initial value is "" and not NULL */
  {
    initrd_start = 0x00800000;  /* FIXME: load at top of memory */
    initrd_size  = bx_load_kernel_image(tmpPtr, initrd_start);
  }

  // Setup Linux startup parameters buffer
  bx_load_linux_setup_params(initrd_start, initrd_size);

  // Enable A20 line
  BX_SET_ENABLE_A20(1);

  // Setup PICs the way Linux likes it
  BX_OUTP(0x20, 0x11, 1);
  BX_OUTP(0xA0, 0x11, 1);
  BX_OUTP(0x21, 0x20, 1);
  BX_OUTP(0xA1, 0x28, 1);
  BX_OUTP(0x21, 0x04, 1);
  BX_OUTP(0xA1, 0x02, 1);
  BX_OUTP(0x21, 0x01, 1);
  BX_OUTP(0xA1, 0x01, 1);
  BX_OUTP(0x21, 0xFF, 1);
  BX_OUTP(0xA1, 0xFB, 1);

  // Disable interrupts and NMIs
  BX_CPU(0)->clear_IF();
  BX_OUTP(0x70, 0x80, 1);

  // Enter protected mode
  // Fixed by george (kyriazis at nvidia.com)
  // BX_CPU(0)->cr0.pe = 1;
  // BX_CPU(0)->cr0.val32 |= 0x01;

  BX_CPU(0)->SetCR0(BX_CPU(0)->cr0.val32 | 0x01);

  // load esi with real_mode
  BX_CPU(0)->gen_reg[BX_32BIT_REG_ESI].dword.erx = 0x90000;

  // Set up initial GDT
  BX_CPU(0)->gdtr.limit = 0x400;
  BX_CPU(0)->gdtr.base  = 0x00090400;

  // Jump to protected mode entry point
  BX_CPU(0)->jump_protected(NULL, 0x10, 0x100000);
}

void bx_load_null_kernel_hack(void)
{
  // The RESET function will have been called first.
  // Set CPU and memory features which are assumed at this point.

  bx_load_kernel_image(SIM->get_param_string(BXPN_LOAD32BITOS_PATH)->getptr(), 0x100000);

  // EIP deltas
  BX_CPU(0)->prev_rip = BX_CPU(0)->gen_reg[BX_32BIT_REG_EIP].dword.erx = 0x100000;

  // CS deltas
  BX_CPU(0)->sregs[BX_SEG_REG_CS].cache.u.segment.base = 0x00000000;
  BX_CPU(0)->sregs[BX_SEG_REG_CS].cache.u.segment.limit = 0xFFFFF;
  BX_CPU(0)->sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled = 0xFFFFFFFF;
  BX_CPU(0)->sregs[BX_SEG_REG_CS].cache.u.segment.g   = 1; // page gran
  BX_CPU(0)->sregs[BX_SEG_REG_CS].cache.u.segment.d_b = 1; // 32bit

#if BX_SUPPORT_ICACHE
  BX_CPU(0)->updateFetchModeMask();
#endif

  // DS deltas
  BX_CPU(0)->sregs[BX_SEG_REG_DS].cache.u.segment.base = 0x00000000;
  BX_CPU(0)->sregs[BX_SEG_REG_DS].cache.u.segment.limit = 0xFFFFF;
  BX_CPU(0)->sregs[BX_SEG_REG_DS].cache.u.segment.limit_scaled = 0xFFFFFFFF;
  BX_CPU(0)->sregs[BX_SEG_REG_DS].cache.u.segment.g   = 1; // page gran
  BX_CPU(0)->sregs[BX_SEG_REG_DS].cache.u.segment.d_b = 1; // 32bit

  // CR0 deltas
  BX_CPU(0)->cr0.set_PE(1); // protected mode
}

  Bit32u
bx_load_kernel_image(char *path, Bit32u paddr)
{
  struct stat stat_buf;
  int fd, ret;
  unsigned long size, offset;
  Bit32u page_size;

  // read in ROM BIOS image file
  fd = open(path, O_RDONLY
#ifdef O_BINARY
            | O_BINARY
#endif
           );
  if (fd < 0) {
    BX_INFO(("load_kernel_image: couldn't open image file '%s'.", path));
    BX_EXIT(1);
  }
  ret = fstat(fd, &stat_buf);
  if (ret) {
    BX_INFO(("load_kernel_image: couldn't stat image file '%s'.", path));
    BX_EXIT(1);
  }

  size = (unsigned long) stat_buf.st_size;
  page_size = ((Bit32u)size + 0xfff) & ~0xfff;

  if ((paddr + size) > BX_MEM(0)->get_memory_len()) {
    BX_INFO(("load_kernel_image: address range > physical memsize!"));
    BX_EXIT(1);
  }

  offset = 0;
  while (size > 0) {
    ret = read(fd, (bx_ptr_t) BX_MEM(0)->get_vector(paddr + offset), size);
    if (ret <= 0) {
      BX_INFO(("load_kernel_image: read failed on image"));
      BX_EXIT(1);
    }
    size -= ret;
    offset += ret;
  }
  close(fd);
  BX_INFO(("load_kernel_image: '%s', size=%u read into memory at %08x",
       path, (unsigned) stat_buf.st_size, (unsigned) paddr));

  return page_size;
}
