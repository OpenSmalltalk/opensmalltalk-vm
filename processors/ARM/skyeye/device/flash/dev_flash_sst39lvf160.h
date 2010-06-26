/*
	dev_flash_sst39lvf160.h - skyeye SST39LF/VF160 flash simulation
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

#ifndef __DEV_FLASH_SST39LVF160_H_
#define __DEV_FLASH_SST39LVF160_H_

#include <stdint.h>

struct flash_sst39lvf160_bus {
	uint32_t addr;
	uint32_t data;
};

struct flash_sst39lvf160_io {
	int cnt;
	int n_bus;
	struct flash_sst39lvf160_bus bus[6];

	int dump_cnt;
	int dump_flags;
};

#define CMD_CHECK(io, n, o, v)				\
	(io->bus[n].addr == o && io->bus[n].data == v)

#define CMD_WORD_PROGRAM(io)				\
	(io->cnt == 3 &&				\
	 CMD_CHECK(io, 0, 0x5555, 0xaa) &&		\
	 CMD_CHECK(io, 1, 0x2aaa, 0x55) &&		\
	 CMD_CHECK(io, 2, 0x5555, 0xa0))

#define CMD_ERASE(io)					\
	(io->cnt == 5 &&				\
	 CMD_CHECK(io, 0, 0x5555, 0xaa) &&		\
	 CMD_CHECK(io, 1, 0x2aaa, 0x55) &&		\
	 CMD_CHECK(io, 2, 0x5555, 0x80) &&		\
	 CMD_CHECK(io, 3, 0x5555, 0xaa) &&		\
	 CMD_CHECK(io, 4, 0x2aaa, 0x55))

#define CMD_SOFTWARE_ID_ENTRY(io)			\
	(io->cnt == 3 &&				\
	 CMD_CHECK(io, 0, 0x5555, 0xaa) &&		\
	 CMD_CHECK(io, 1, 0x2aaa, 0x55) &&		\
	 CMD_CHECK(io, 2, 0x5555, 0x90))

#define CMD_CFI_QUERY_ENTRY(io)				\
	(io->cnt == 3 &&				\
	 CMD_CHECK(io, 0, 0x5555, 0xaa) &&		\
	 CMD_CHECK(io, 1, 0x2aaa, 0x55) &&		\
	 CMD_CHECK(io, 2, 0x5555, 0x98))

#define CMD_QUERY_EXIT(io)				\
	((io->cnt == 1 && io->bus[0].data == 0xf0) ||	\
	 (io->cnt == 3 &&				\
	  CMD_CHECK(io, 0, 0x5555, 0xaa) &&		\
	  CMD_CHECK(io, 1, 0x2aaa, 0x55) &&		\
	  CMD_CHECK(io, 2, 0x5555, 0xf0)))

#endif /* __DEV_FLASH_SST39LVF160_H_ */

