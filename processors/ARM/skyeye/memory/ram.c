/*
        ram.c - necessary ram module definition for skyeye
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.gro.clinux.org>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "skyeye_config.h"
#include "bank_defs.h"
#include "ram.h"

/* All the memory including rom and dram */
static mem_state_t global_memory;
extern generic_arch_t * arch_instance;
static uint32_t
mem_read_byte (uint32_t addr)
{
	uint32_t data, offset;
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();
	data = global_memory.rom[global_mbp -
			      memmap->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];
	//printf("In %s, banks=0x%x,offset=0x%x\n", __FUNCTION__, global_mbp - memmap->mem_banks, (addr - global_mbp-> addr) >> 2);
	offset = (((uint32_t) arch_instance->big_endian * 3) ^ (addr & 3)) << 3;	/* bit offset into the word */
	//printf("In %s,data=0x%x\n, offset=0x%x, addr=0x%x\n", __FUNCTION__, data, offset, addr);
	return (data >> offset & 0xffL);
}

static uint32_t
mem_read_halfword (uint32_t addr)
{
	uint32_t data, offset;
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();
	data = global_memory.rom[global_mbp -
			      memmap->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];

	offset = (((uint32_t) arch_instance->big_endian * 2) ^ (addr & 2)) << 3;	/* bit offset into the word */

	return (data >> offset) & 0xffff;
}

static uint32_t
mem_read_word (uint32_t addr)
{
	uint32_t data;
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();
	data = global_memory.rom[global_mbp -
			      memmap->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];
	return data;
}

static void
mem_write_byte (uint32_t addr, uint32_t data)
{
	uint32_t *temp, offset;
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();
#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		//teawater add for arm2x86 2005.03.18----------------------------------
		tb_setdirty (arch_instance, addr, global_mbp);
	}
#endif
	
	temp = &global_memory.rom[global_mbp -
			       memmap->mem_banks][(addr -
							    global_mbp->
							    addr) >> 2];
	offset = (((uint32_t) arch_instance->big_endian * 3) ^ (addr & 3)) << 3;	/* bit offset into the word */
	*temp = (*temp & ~(0xffL << offset)) | ((data & 0xffL) << offset);
	//printf("In %s, temp=0x%x,data=0x%x, temp=0x%x\n", __FUNCTION__, temp, *temp, global_memory.rom[4][0x2000]);
}

static void
mem_write_halfword (uint32_t addr, uint32_t data)
{
	unsigned long *temp, offset;
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();

#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		tb_setdirty (arch_instance, addr, global_mbp);
	}
#endif
	temp = &global_memory.rom[global_mbp -
			       memmap->mem_banks][(addr -
							    global_mbp->
							    addr) >> 2];
	offset = (((uint32_t) arch_instance->big_endian * 2) ^ (addr & 2)) << 3;	/* bit offset into the word */

	*temp = (*temp & ~(0xffffL << offset)) | ((data & 0xffffL) << offset);
}

static void
mem_write_word (uint32_t addr, uint32_t data)
{
	mem_bank_t * global_mbp = bank_ptr(addr);
	mem_config_t * memmap = get_global_memmap();

#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		//teawater add for arm2x86 2005.03.18----------------------------------
		tb_setdirty (arch_instance, addr, global_mbp);
	}
#endif
	global_memory.rom[global_mbp -
		       memmap->mem_banks][(addr -
						    global_mbp->addr) >> 2] =
	data;
}
void
mem_reset (void * state)
{
	int i, num, bank;
	FILE *f;
	unsigned char *p;
	int s;
	uint32_t swap;
	mem_config_t *mc = get_global_memmap();
	mem_bank_t *mb = mc->mem_banks;
	mem_state_t * mem = &global_memory;
	num = mc->current_num;
	for (i = 0; i < num; i++) {
		bank = i;
		if (global_memory.rom[bank])
			free (global_memory.rom[bank]);
		//chy 2003-09-21: if mem type =MEMTYPE_IO, we need not malloc space for it.
		global_memory.rom_size[bank] = mb[bank].len;
		if (mb[bank].type != MEMTYPE_IO) {
			global_memory.rom[bank] = malloc (mb[bank].len);
			if (!global_memory.rom[bank]) {
				fprintf (stderr,
					 "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n",
					 bank);
				skyeye_exit (-1);
			}
			/*ywc 2005-04-01 */
#ifdef DBCT
			if (!skyeye_config.no_dbct) {
				//teawater add for arm2x86 2004.12.04-------------------------------------------
				if (mb[bank].len % TB_LEN) {
					fprintf (stderr,
						 "SKYEYE: mem_reset: Bank number %d length error.\n",
						 bank);
					skyeye_exit (-1);
				}

				global_memory.tbp[bank] = MAP_FAILED;
				global_memory.tbt[bank] = NULL;

				/*
				   global_memory.tbp[bank] = mmap(NULL, mb[bank].len / sizeof(ARMword) * TB_INSN_LEN_MAX + mb[bank].len / TB_LEN * op_return.len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
				   if (global_memory.tbp[bank] == MAP_FAILED) {
				   fprintf(stderr, "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n", bank);
				   exit(-1);
				   }
				   global_memory.tbt[bank] = malloc(mb[bank].len/TB_LEN*sizeof(tb_t));
				   if (!global_memory.tbt[bank]) {
				   fprintf(stderr, "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n", bank);
				   exit(-1);
				   }
				   memset(global_memory.tbt[bank], 0, mb[bank].len/TB_LEN*sizeof(tb_t));
				 */
				//AJ2D--------------------------------------------------------------------------
			}
#endif

#if 1 
			if (mb[bank].filename
			    && (f = fopen (mb[bank].filename, "rb"))) {
				if (fread
				    (global_memory.rom[bank], 1, mb[bank].len,
				     f) <= 0) {
					perror ("fread");
					fprintf (stderr,
						 "Failed to load '%s'\n",
						 mb[bank].filename);
					skyeye_exit (-1);
				}
				fclose (f);

				p = (char *) global_memory.rom[bank];
				s = 0;
				while (s < global_memory.rom_size[bank]) {
					if (arch_instance->big_endian == HIGH)	/*big enddian? */
						swap = ((uint32_t) p[3]) |
							(((uint32_t) p[2]) <<
							 8) | (((uint32_t)
								p[1]) << 16) |
							(((uint32_t) p[0]) <<
							 24);
					else
						swap = ((uint32_t) p[0]) |
							(((uint32_t) p[1]) <<
							 8) | (((uint32_t)
								p[2]) << 16) |
							(((uint32_t) p[3]) <<
							 24);
					*(uint32_t *) p = swap;
					p += 4;
					s += 4;
				}

				/*ywc 2004-03-30 */
				//printf("Loaded ROM %s\n", mb[bank].filename);
				if (mb[bank].type == MEMTYPE_FLASH) {
					printf ("Loaded FLASH %s\n",
						mb[bank].filename);
				}
				else if (mb[bank].type == MEMTYPE_RAM) {
					printf ("Loaded RAM   %s\n",
						mb[bank].filename);
				}
				else if (mb[bank].type == MEMTYPE_ROM) {
					printf ("Loaded ROM   %s\n",
						mb[bank].filename);
				}

			}
			else if (mb[bank].filename[0] != '\0') {
				perror (mb[bank].filename);
				fprintf (stderr,
					 "bank %d, Couldn't open boot ROM %s - execution will "
					 "commence with the debuger.\n", bank,
					 mb[bank].filename);
				skyeye_exit (-1);
			}
#endif
		}
	}			/*end  for(i = 0;i < num; i++) */

}

char mem_read(short size, int offset, uint32_t * value){
	void * state;
	switch(size){
		case 8:
			*(uint8_t *)value = (uint8_t)mem_read_byte (offset);
			break;
		case 16:
			*(uint16_t *)value = (uint16_t)mem_read_halfword(offset);
			break;
		case 32:
			*value = mem_read_word(offset);
			break;
		default:
			fprintf(stderr, "In %s, invalid data length %d\n", __FUNCTION__, size);
			return -1;
	}
	return 0;

}

char mem_write(short size, int offset, uint32_t value){
	switch(size){
		case 8:
                        mem_write_byte (offset, value);
                        break;
                case 16:
                        mem_write_halfword(offset, value);
                        break;
                case 32:
                        mem_write_word(offset, value);
                        break;
                default:
			fprintf(stderr, "In %s, invalid data length %d\n", __FUNCTION__, size);
                        return -1;
	}
	return 0;
}

/* 
 * Here, we translate an address from guest machine 
 * to the address of host machine, you can use it as dma transfer. 
 */
unsigned char * get_dma_addr(unsigned long guest_addr){
        unsigned char * host_addr;
        mem_bank_t * global_mbp = bank_ptr(guest_addr);
        mem_config_t * memmap = get_global_memmap();
        host_addr = &global_memory.rom[global_mbp -
                              memmap->mem_banks][(guest_addr -
                                                           global_mbp->
                                                           addr) >> 2];
        return host_addr;
}

char warn_write(short size, int offset, uint32_t value){
	SKYEYE_ERR("Read-only ram\n");
}
mem_state_t * get_global_memory(){
	return &global_memory;
}
