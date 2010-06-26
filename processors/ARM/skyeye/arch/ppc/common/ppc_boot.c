/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/*
 * 30/10/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */


/*
 * A simple boot function for linux happy
 */

#include <stdio.h>

#include "ppc_cpu.h"
#include "ppc_boot.h"
#include "ppc_mmu.h"
#include "sysendian.h"

extern byte * ddr_ram; /* 64M DDR SDRAM */

static void load_initrd(){

	FILE *f;
	const int initrd_start  = 32 * 1024 * 1024, initrd_size = 1 * 1024 * 1024;
	const char * filename = "initrd.img";

/*
 *   r4 - Starting address of the init RAM disk
 *   r5 - Ending address of the init RAM disk
 */
	gCPU.gpr[4] = initrd_start;
	gCPU.gpr[5] = initrd_start + initrd_size;

	if(f = fopen(filename, "rb")){
		void * t = &ddr_ram[initrd_start];
		if (fread(&ddr_ram[initrd_start], 1, initrd_size, f))
			printf("Load %s to 0x%x...\n", filename, initrd_start);
		else
			printf("Can not load %s to 0x%x\n", filename, initrd_start);
		fclose(f);
	}
	else{
		fprintf(stderr, "Can not open initrd file %s.\n", filename);
		skyeye_exit(-1);
	}
        
}

static void set_bootcmd(){
	const int bd_start = 8 * 1024 * 1024;
	bd_t * t = &ddr_ram[bd_start];
        t->bi_immr_base = ppc_word_to_BE(0xe0000000);
        t->bi_busfreq = ppc_word_to_BE(100 * 1024 * 1024);
        t->bi_intfreq = ppc_word_to_BE(500 * 1024 * 1024);
        t->bi_baudrate = ppc_word_to_BE(9600);
        t->bi_memsize = ppc_word_to_BE(64 * 1024 * 1024);
	gCPU.gpr[3] = bd_start;

	char * bootcmd = "root=/dev/ram0 console=ttyCPM0 mem=64M";
	const int bootcmd_start= 9 * 1024 * 1024;
	memcpy(&ddr_ram[bootcmd_start], bootcmd, (strlen(bootcmd) + 1));

	gCPU.gpr[6] = bootcmd_start;
	gCPU.gpr[7] = bootcmd_start + strlen(bootcmd) + 1;

}

static void setup_boot_map(){
	/* setup initial tlb map for linux, that should be done by bootloader */
        ppc_tlb_entry_t * entry = &l2_tlb1_vsp[0];
        entry->v = 1; /* entry is valid */
        entry->ts = 0; /* address space 0 */
        entry->tid = 0; /* TID value for shared(global) page */
        entry->epn = 0xC0000; /* Virtual address of DDR ram in address space*/
        entry->rpn = 0x0; /* Physical address of DDR ram in address space*/
        entry->size = 0x7; /* 16M byte page size */
        /* usxrw should be initialized to 010101 */
        entry->usxrw |= 0x15; /* Full supervisor mode access allowed */
        entry->usxrw &= 0x15; /* No user mode access allowed */
        entry->wimge = 0x8; /* Caching-inhibited, non-coherent,big-endian*/
        entry->x = 0; /* Reserved system attributes */
        entry->u = 0; /* User attribute bits */
        entry->iprot = 1; /* Page is protected from invalidation */
	gCPU.ccsr.ccsr = 0xE0000; /* Just for boot linux */

}
void ppc_boot(){
	/* Fixme, will move it to skyeye.conf */
	load_initrd();
	set_bootcmd();

	/* just for linux boot, so we need to do some map */
	setup_boot_map();
}
