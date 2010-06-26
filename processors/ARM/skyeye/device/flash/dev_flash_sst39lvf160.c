/*
	dev_flash_sst39lvf160.c - skyeye SST39LF/VF160 flash simulation
	Copyright (C) 2007 Skyeye Develop Group
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
 * 2007.04.03	Written by Anthony Lee
 */

#include <stdio.h>
#include <stdlib.h>

#include "armdefs.h"
#include "skyeye_device.h"
#include "skyeye_flash.h"
#include "dev_flash_sst39lvf160.h"

#define FLASH_SST39LVF160_DEBUG		0

#define PRINT(x...)			printf("[FLASH_SST39LVF160]: " x)

#if FLASH_SST39LVF160_DEBUG
#define DEBUG(x...)			printf("[FLASH_SST39LVF160]: " x)
#else
#define DEBUG(x...)			(void)0
#endif
/*
extern mem_bank_t *global_mbp;
extern mem_bank_t *bank_ptr(ARMword addr);

extern ARMword real_read_byte(ARMul_State*, ARMword);
extern ARMword real_read_halfword(ARMul_State*, ARMword);
extern ARMword real_read_word(ARMul_State*, ARMword);
extern void real_write_byte(ARMul_State*, ARMword, ARMword);
extern void real_write_halfword(ARMul_State*, ARMword, ARMword);
extern void real_write_word(ARMul_State*, ARMword, ARMword);
*/

static void flash_sst39lvf160_fini(struct device_desc *dev)
{
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;

	free(dev->dev);
	free(io);
}


static void flash_sst39lvf160_reset(struct device_desc *dev)
{
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;

	memset(io, 0, sizeof(struct flash_sst39lvf160_io));
	io->dump_cnt = 0xffff;
}


static void flash_sst39lvf160_update(struct device_desc *dev)
{
	struct flash_device *flash_dev = (struct flash_device*)dev->dev;
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;
	uint32_t addr, data;
	int fd;

	if (flash_dev->dump[0] == 0) return;
	if (io->dump_flags == 0 || (io->dump_flags & 0x2) != 0) return;

	io->dump_cnt -= 1;

	if (io->dump_cnt == 0) {
		if (skyeye_flash_dump(flash_dev->dump, dev->base, 0x200000) != 0) {
			io->dump_flags |= 0x2;
			printf("\n");
			PRINT("*** FAILED: Can't dump to %s\n", flash_dev->dump);
			return;
		}

		io->dump_cnt = 0xffff;
		io->dump_flags = 0;

		printf("\n");
		PRINT("Dumped to %s\n", flash_dev->dump);
	}
}


static int flash_sst39lvf160_read_byte(struct device_desc *dev, uint32_t addr, uint8_t *data)
{
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;

	/*global_mbp = bank_ptr(addr);
	*data = real_read_byte(state, addr);
	*/
	bus_read(8, addr, data);
	DEBUG("read_byte(addr:0x%08x, data:0x%x)\n", addr, *data);

	return ADDR_HIT;
}


static int flash_sst39lvf160_write_byte(struct device_desc *dev, uint32_t addr, uint8_t data)
{
#if 0
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;

	global_mbp = bank_ptr(addr);
	real_write_byte(state, addr, data);

	io->dump_flags |= 0x1;

	DEBUG("write_byte(addr:0x%08x, data:0x%x)\n", addr, data);

	return ADDR_HIT;
#else
	PRINT("write_byte: Unsupported !!!\n");
	return ADDR_NOHIT;
#endif
}


static int flash_sst39lvf160_read_halfword(struct device_desc *dev, uint32_t addr, uint16_t *data)
{
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;
	uint32_t offset = (addr - dev->base) >> 1;

	if (CMD_SOFTWARE_ID_ENTRY(io)) {
		switch (offset) {
			case 0: *data = 0xbf; break;
			case 1: *data = 0x2782; break;

			default: *data = 0x0; break;
		}
	}

	if (CMD_CFI_QUERY_ENTRY(io)) {
		switch (offset) {
			/* CFI QUERY IDENTIFICATION STRING */
			case 0x10: *data= 0x51; break;
			case 0x11: *data= 0x52; break;
			case 0x12: *data= 0x59; break;
			case 0x13: *data= 0x1; break;
			case 0x14: *data= 0x7; break;
			case 0x15: *data= 0x0; break;
			case 0x16: *data= 0x0; break;
			case 0x17: *data= 0x0; break;
			case 0x18: *data= 0x0; break;
			case 0x19: *data= 0x0; break;
			case 0x1a: *data= 0x0; break;

			/* SYSTEM INTERFACE INFORMATION */
			case 0x1b: *data= strcmp(dev->type, "SST39LF160") == 0 ? 0x30 : 0x27; break;
			case 0x1c: *data= 0x36; break;
			case 0x1d: *data= 0x0; break;
			case 0x1e: *data= 0x0; break;
			case 0x1f: *data= 0x4; break;
			case 0x20: *data= 0x0; break;
			case 0x21: *data= 0x4; break;
			case 0x22: *data= 0x6; break;
			case 0x23: *data= 0x1; break;
			case 0x24: *data= 0x0; break;
			case 0x25: *data= 0x1; break;
			case 0x26: *data= 0x1; break;

			/* DEVICE GEOMETRY INFORMATION */
			case 0x27: *data= 0x15; break;
			case 0x28: *data= 0x1; break;
			case 0x29: *data= 0x0; break;
			case 0x2a: *data= 0x0; break;
			case 0x2b: *data= 0x0; break;
			case 0x2c: *data= 0x2; break;
			case 0x2d: *data= 0xff; break;
			case 0x2e: *data= 0x1; break;
			case 0x2f: *data= 0x10; break;
			case 0x30: *data= 0x0; break;
			case 0x31: *data= 0x1f; break;
			case 0x32: *data= 0x0; break;
			case 0x33: *data= 0x0; break;
			case 0x34: *data= 0x1; break;

			default: *data = 0x0; break;
		}
	}

	if (io->cnt == 0) {
		/* read data from addr */
		/*
		global_mbp = bank_ptr(addr);
		*data = real_read_halfword(state, addr);
		*/
		bus_read(16, addr, data);
	}

	io->n_bus = 0;

	DEBUG("read_halfword(offset:0x%08x, data:0x%x)\n", offset, *data);

	return ADDR_HIT;
}


static int flash_sst39lvf160_write_halfword(struct device_desc *dev, uint32_t addr, uint16_t data)
{
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;
	uint32_t offset = (addr - dev->base) >> 1;
	uint32_t start, end;

	DEBUG("write_halfword(%dst Bus, offset:0x%08x, data:0x%x)\n", io->n_bus + 1, offset, data);

	if (CMD_WORD_PROGRAM(io)) {
		/* write data to addr */
		/*
		global_mbp = bank_ptr(addr);
		real_write_halfword(state, addr, data);
		*/
		bus_write(16, addr, data);
		io->dump_flags |= 0x1;
		goto reset;
	}

	if (CMD_ERASE(io)) {
		switch (data) {
			case 0x10: /* Chip-Erase */
				start = dev->base;
				end = start + 0x200000;
				break;

			case 0x30: /* Sector-Erase: 4KBytes/sector */
				start = addr;
				end = start + 0x1000;
				break;

			case 0x50: /* Block-Erase: 64KBytes/block */
				start = addr;
				end = start + 0x10000;
				break;

			default:
				start = end = 0x0;
				break;
		}

		if (end > start && end <= dev->base + 0x200000) {
			for (addr = start; addr < end; addr += 4) {
				/*
				global_mbp = bank_ptr(addr);
				real_write_word(state, addr, 0xffffffff);
				*/
				bus_write(32, addr, 0xffffffff);
			}
			DEBUG("*** Erase(start:0x%08x, end:0x%08x)\n", start, end);
		} else {
			PRINT("*** ERROR: Erase(start:0x%08x, end:0x%08x)\n", start, end);
		}

		goto reset;
	}

	if (io->n_bus < 6) {
		io->bus[io->n_bus].addr = offset;
		io->bus[io->n_bus].data = data;
		io->n_bus += 1;

		io->cnt = io->n_bus;

		if (CMD_QUERY_EXIT(io)) goto reset;
	}

	goto exit;

reset:
	io->cnt = io->n_bus = 0;
	memset(&io->bus[0], 0, sizeof(io->bus[0]) * 6);

exit:
	return ADDR_HIT;
}


static int flash_sst39lvf160_read_word(struct device_desc *dev, uint32_t addr, uint32_t *data)
{
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;

	/*
	global_mbp = bank_ptr(addr);
	*data = real_read_word(state, addr);
	*/
	bus_read(32, addr, data);
	DEBUG("read_word(addr:0x%08x, data:0x%x)\n", addr, *data);

	return ADDR_HIT;
}


static int flash_sst39lvf160_write_word(struct device_desc *dev, uint32_t addr, uint32_t data)
{
#if 0
	struct flash_sst39lvf160_io *io = (struct flash_sst39lvf160_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;

	global_mbp = bank_ptr(addr);
	real_write_word(state, addr, data);

	io->dump_flags |= 0x1;

	DEBUG("write_word(addr:0x%08x, data:0x%x)\n", addr, data);

	return ADDR_HIT;
#else
	PRINT("write_word: Unsupported !!!\n");
	return ADDR_NOHIT;
#endif
}


static int flash_sst39lvf160_setup(struct device_desc *dev)
{
	struct flash_sst39lvf160_io *io;

	if (skyeye_config.arch == NULL ||
	    skyeye_config.arch->arch_name == NULL ||
	    strcmp(skyeye_config.arch->arch_name, "arm") != 0) {
		PRINT("*** ERROR: Unsupported architecture !!!\n");
		return -1;
	}

	if (dev->size != 0x200000) {
		PRINT("*** ERROR: Only support 2M flash !!!\n");
		return -1;
	}

	io = (struct flash_sst39lvf160_io*)malloc(sizeof(struct flash_sst39lvf160_io));
	if (io == NULL) return -1;

	dev->fini = flash_sst39lvf160_fini;
	dev->reset = flash_sst39lvf160_reset;
	dev->update = flash_sst39lvf160_update;
	dev->read_byte = flash_sst39lvf160_read_byte;
	dev->write_byte = flash_sst39lvf160_write_byte;
	dev->read_halfword = flash_sst39lvf160_read_halfword;
	dev->write_halfword = flash_sst39lvf160_write_halfword;
	dev->read_word = flash_sst39lvf160_read_word;
	dev->write_word = flash_sst39lvf160_write_word;
	dev->data = (void*)io;

	flash_sst39lvf160_reset(dev);

	return 0;
}


void flash_sst39lvf160_init(struct device_module_set *mod_set)
{
	register_device_module("SST39LF160", mod_set, &flash_sst39lvf160_setup);
	register_device_module("SST39VF160", mod_set, &flash_sst39lvf160_setup);
}

