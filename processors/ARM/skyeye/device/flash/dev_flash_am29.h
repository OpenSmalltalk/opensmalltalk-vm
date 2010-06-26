/*
	dev_flash_am29.h - skyeye AMD Am29LV160B flash simulation
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

#ifndef __DEV_FLASH_AM29_H_
#define __DEV_FLASH_AM29_H_

#include <stdint.h>

struct flash_am29_bus {
	uint32_t addr;
	uint32_t data;
};

struct flash_am29_io;
typedef void (*flash_am29_bautoselect_func)(struct flash_am29_io*, uint32_t, uint8_t*);
typedef void (*flash_am29_wautoselect_func)(struct flash_am29_io*, uint32_t, uint16_t*);

struct flash_am29_io {
	char type[MAX_STR_NAME];

	int bcnt;
	int n_bbus;
	struct flash_am29_bus bbus[6];

	int wcnt;
	int n_wbus;
	struct flash_am29_bus wbus[6];

	uint16_t *query;
	int max_query;

	flash_am29_bautoselect_func bautoselect;
	flash_am29_wautoselect_func wautoselect;

	uint32_t chip_size;
	uint32_t sector_size;

	int dump_cnt;
	int dump_flags;
};

#define CMD_BCHECK(io, n, o, v)				\
	(io->bbus[n].addr == o && io->bbus[n].data == v)

#define CMD_WCHECK(io, n, o, v)				\
	(io->wbus[n].addr == o && io->wbus[n].data == v)

#define CMD_BYTE_PROGRAM(io)				\
	(io->bcnt == 3 &&				\
	 CMD_BCHECK(io, 0, 0xaaa, 0xaa) &&		\
	 CMD_BCHECK(io, 1, 0x555, 0x55) &&		\
	 CMD_BCHECK(io, 2, 0xaaa, 0xa0))

#define CMD_WORD_PROGRAM(io)				\
	(io->wcnt == 3 &&				\
	 CMD_WCHECK(io, 0, 0x555, 0xaa) &&		\
	 CMD_WCHECK(io, 1, 0x2aa, 0x55) &&		\
	 CMD_WCHECK(io, 2, 0x555, 0xa0))

#define CMD_BYTE_ERASE(io)				\
	(io->bcnt == 5 &&				\
	 CMD_BCHECK(io, 0, 0xaaa, 0xaa) &&		\
	 CMD_BCHECK(io, 1, 0x555, 0x55) &&		\
	 CMD_BCHECK(io, 2, 0xaaa, 0x80) &&		\
	 CMD_BCHECK(io, 3, 0xaaa, 0xaa) &&		\
	 CMD_BCHECK(io, 4, 0x555, 0x55))

#define CMD_WORD_ERASE(io)				\
	(io->wcnt == 5 &&				\
	 CMD_WCHECK(io, 0, 0x555, 0xaa) &&		\
	 CMD_WCHECK(io, 1, 0x2aa, 0x55) &&		\
	 CMD_WCHECK(io, 2, 0x555, 0x80) &&		\
	 CMD_WCHECK(io, 3, 0x555, 0xaa) &&		\
	 CMD_WCHECK(io, 4, 0x2aa, 0x55))

#define CMD_BYTE_AUTOSELCT(io)				\
	(io->bcnt == 3 &&				\
	 CMD_BCHECK(io, 0, 0xaaa, 0xaa) &&		\
	 CMD_BCHECK(io, 1, 0x555, 0x55) &&		\
	 CMD_BCHECK(io, 2, 0xaaa, 0x90))

#define CMD_WORD_AUTOSELCT(io)				\
	(io->wcnt == 3 &&				\
	 CMD_WCHECK(io, 0, 0x555, 0xaa) &&		\
	 CMD_WCHECK(io, 1, 0x2aa, 0x55) &&		\
	 CMD_WCHECK(io, 2, 0x555, 0x90))

#define CMD_BYTE_QUERY(io)				\
	(io->bcnt == 1 &&				\
	 CMD_BCHECK(io, 0, 0xaa, 0x98))

#define CMD_WORD_QUERY(io)				\
	(io->wcnt == 1 &&				\
	 CMD_WCHECK(io, 0, 0x55, 0x98))

#define CMD_BYTE_UNLOCK_BYPASS(io)			\
	(io->bcnt == 3 &&				\
	 CMD_BCHECK(io, 0, 0xaaa, 0xaa) &&		\
	 CMD_BCHECK(io, 1, 0x555, 0x55) &&		\
	 CMD_BCHECK(io, 2, 0xaaa, 0x20))

#define CMD_WORD_UNLOCK_BYPASS(io)			\
	(io->wcnt == 3 &&				\
	 CMD_WCHECK(io, 0, 0x555, 0xaa) &&		\
	 CMD_WCHECK(io, 1, 0x2aa, 0x55) &&		\
	 CMD_WCHECK(io, 2, 0x555, 0x20))

#define CMD_BYTE_UNLOCK_BYPASS_PROGRAM_RESET(io)	\
	(io->bcnt == 2 &&				\
	 io->bbus[0].data == 0xa0 ||			\
	 io->bbus[0].data == 0x90)

#define CMD_WORD_UNLOCK_BYPASS_PROGRAM_RESET(io)	\
	(io->wcnt == 2 &&				\
	 io->wbus[0].data == 0xa0 ||			\
	 io->wbus[0].data == 0x90)

#endif /* __DEV_FLASH_AM29_H_ */

