/*
        iomem.c - implementation of read/write function for blackfin simulation 
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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

#include "bfin-sim.h"
#include "types.h"
#include "mem_map.h"
#include <signal.h>
#include <skyeye_config.h>
bu32
get_long (unsigned char *memory, bu32 addr);
//#define IO_ERR {printf("\n%s io error!addr=0x%x\n",__FUNCTION__,addr);exit(-1);}

#define IO_ERR {printf("\n%s io error!addr=0x%x,pc=0x%x,oldpc=0x%x,sp=0x%x,insn@pc=0x%x\n",__FUNCTION__,addr,PCREG,OLDPCREG,SPREG,get_long(saved_state.memory,PCREG));exit(-1);}


static void
isram_write_word (bu32 addr, bu16 v)
{
	int offset = addr - ISRAM_START;
	//saved_state.isram[offset] = (bu16)v;
	saved_state.isram[offset] = v;
        saved_state.isram[offset + 1] = v >> 8;

}

static bu16
isram_read_word (bu32 addr)
{
	int offset = addr - ISRAM_START;
	//return (bu16)(saved_state.isram[offset]);
	     return saved_state.isram[offset] | (saved_state.
                                            isram[offset + 1] << 8);
}

static void
isram_write_byte (bu32 addr, bu8 v)
{
	int offset = addr - ISRAM_START;
	saved_state.isram[offset] = v;
}

static bu8
isram_read_byte (bu32 addr)
{
	int offset = addr - ISRAM_START;
	return saved_state.isram[offset];
}
static bu32
isram_read_long (bu32 addr)
{
        int offset = addr - ISRAM_START;
        //printf("ssram_read_long addr %p\n",addr);
        //return (bu16)(saved_state.ssram[offset]);
        return (saved_state.isram[offset] |
               (saved_state.isram[offset + 1] << 8) |
               (saved_state.isram[offset + 2] << 16) |
               (saved_state.isram[offset + 3] << 24) );
}


//PSW scratch pad ram 061606
static void
ssram_write_long (bu32 addr, bu32 v)
{

        int offset = addr - SSRAM_START;
	//printf("ssram_write_long addr %p\n",addr);
	//saved_state.ssram[offset] = (bu16)v;
	saved_state.ssram[offset] = v;
        saved_state.ssram[offset + 1] = v >> 8;
        saved_state.ssram[offset + 2] = v >> 16;
        saved_state.ssram[offset + 3] = v >> 24;

}

static bu32
ssram_read_long (bu32 addr)
{
	int offset = addr - SSRAM_START;
	//printf("ssram_read_long addr %p\n",addr);
	//return (bu16)(saved_state.ssram[offset]);
	return (saved_state.ssram[offset] | 
	       (saved_state.ssram[offset + 1] << 8) |
	       (saved_state.ssram[offset + 2] << 16) |
	       (saved_state.ssram[offset + 3] << 24) );
}

static void
ssram_write_word (bu32 addr, bu16 v)
{
	int offset = addr - SSRAM_START;
	//printf("ssram_write_word addr %p\n",addr);
	//saved_state.ssram[offset] = (bu16)v;
	saved_state.ssram[offset] = v;
        saved_state.ssram[offset + 1] = v >> 8;

}

static bu16
ssram_read_word (bu32 addr)
{
	int offset = addr - SSRAM_START;
	//printf("ssram_read_word addr %p\n",addr);
	//return (bu16)(saved_state.ssram[offset]);
	return saved_state.ssram[offset] | (saved_state.
                                            ssram[offset + 1] << 8);
}

static void
ssram_write_byte (bu32 addr, bu8 v)
{
	int offset = addr - SSRAM_START;
	//printf("ssram_read_byte addr %p\n",addr);
	saved_state.ssram[offset] = v;
}

static bu8
ssram_read_byte (bu32 addr)
{
	int offset = addr - SSRAM_START;
	//printf("ssram_read_byte addr %p\n",addr);
	return saved_state.ssram[offset];
}

static void
dsram_write_byte (bu32 addr, bu8 v)
{
	int offset = addr - DSRAM_START;
	saved_state.dsram[offset] = v;
}

static bu8
dsram_read_byte (bu32 addr)
{
	int offset = addr - DSRAM_START;
	return saved_state.dsram[offset];
}


void
put_byte (unsigned char *memory, bu32 addr, bu8 v)
{
	if ((addr >= IO_START) && (addr < IO_END)) {
		skyeye_config.mach->mach_io_write_byte (&saved_state, addr, v);

	}
	else if (addr >= ISRAM_START && addr < ISRAM_END) {
		isram_write_byte (addr, v);
	}
	else if (addr >= DSRAM_START && addr < DSRAM_END) {
		dsram_write_byte (addr, v);
	} // PSW 061606
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		ssram_write_byte (addr, v);
	}
	else if (addr >= SDRAM_START && addr < SDRAM_END) {
		memory[addr] = v;
	}
        else if (addr >= BANK0_START && addr < BANK3_END) {
        }
	else {
		IO_ERR;
		exit(-1);
	}

}

void
put_word (unsigned char *memory, bu32 addr, bu16 v)
{
	if ((addr >= IO_START) && (addr < IO_END)) {
		skyeye_config.mach->mach_io_write_halfword (&saved_state, addr, v);
	}
	else if (addr >= ISRAM_START && addr < ISRAM_END) {
		IO_ERR;
	} // PSW 061606
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		ssram_write_word (addr, v);
	}

	else if (addr >= SDRAM_START && addr < SDRAM_END) {
		//memory[addr] = (bu16)v;
		    memory[addr] = v;
	                memory[addr + 1] = v >> 8;
	}
	else {
		IO_ERR;
	}

}

void
put_long (unsigned char *memory, bu32 addr, bu32 v)
{
	if ((addr > IO_START) && (addr < IO_END)) {
		skyeye_config.mach->mach_io_write_word (&saved_state, addr, v);
	} // PSW 061606
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		ssram_write_long (addr, v);
	}
	else if (addr >= SDRAM_START && addr < SDRAM_END) {
		//memory[addr] = (bu32)v;
		memory[addr] = v;
                memory[addr + 1] = v >> 8;
                memory[addr + 2] = v >> 16;
                memory[addr + 3] = v >> 24;

	}
	else {
		IO_ERR;
	}
}

bu8
get_byte (unsigned char *memory, bu32 addr)
{
	if ((addr >= IO_START) && (addr < IO_END)) {
		return skyeye_config.mach->mach_io_read_byte (&saved_state, addr);
	}
	else if (addr >= ISRAM_START && addr < ISRAM_END) {
		return isram_read_byte (addr);
	}
	else if (addr >= DSRAM_START && addr < DSRAM_END) {
		return dsram_read_byte (addr);
	} // PSW 061606
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		return ssram_read_byte (addr);
	}
	else if (addr >= SDRAM_START && addr < SDRAM_END)
		return memory[addr];
	else {
		IO_ERR;
	}
}

bu16
get_word (unsigned char *memory, bu32 addr)
{
	if ((addr >= IO_START) && (addr < IO_END)) {
		return skyeye_config.mach->mach_io_read_halfword (&saved_state, addr);
	}
	else if (addr >= ISRAM_START && addr < ISRAM_END) {
		return isram_read_word (addr);
	} //PSW 061606 
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		return ssram_read_word (addr);
	}
	else if (addr >= SDRAM_START && addr < SDRAM_END) {
		//return (bu16)(memory[addr]);
		 return memory[addr] | (memory[addr + 1] << 8);
	}
	else {
		IO_ERR;
	}
}

bu32
get_long (unsigned char *memory, bu32 addr)
{
	if ((addr >= IO_START) && (addr < IO_END)) {
		return skyeye_config.mach->mach_io_read_word (&saved_state, addr);
	}
	else if (addr >= ISRAM_START && addr < ISRAM_END) {
		return isram_read_long (addr);
	} //PSW 061606 
	else if (addr >= SSRAM_START && addr < SSRAM_END) {
		return ssram_read_long (addr);
	}
	else if (addr >= SDRAM_START && addr < SDRAM_END) {
		//return (bu32)(memory[addr]);
		 return (memory[addr] | (memory[addr + 1] << 8)
                        | (memory[addr + 2] << 16) | (memory[addr + 3] <<
                                                      24));
	}
	else {
		IO_ERR;
	}
}
