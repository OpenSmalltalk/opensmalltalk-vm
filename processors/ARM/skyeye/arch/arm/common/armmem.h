/*
    armmem.c - Memory map decoding, ROM and RAM emulation.
    ARMulator extensions for the ARM7100 family.
    Copyright (C) 1999  Ben Williamson

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

#ifndef _ARMMEM_H_
#define _ARMMEM_H_


#define DRAM_BITS       (23)	/* 8MB of DRAM */
#define ROM_BANKS	16
#define ROM_BITS	(28)	/* 0x10000000 each bank */
#if 0
typedef struct mem_state_t
{
	ARMword *dram;
	ARMword *rom[ROM_BANKS];
	unsigned int rom_size[ROM_BANKS];
//teawater add for arm2x86 2004.12.04-------------------------------------------
	uint8_t *tbp[ROM_BANKS];	//translate block pointer
	struct tb_s *tbt[ROM_BANKS];	//translate block structure pointer
//AJ2D--------------------------------------------------------------------------

} mem_state_t;

void mem_reset (ARMul_State * state);
ARMword mem_read_word (ARMul_State * state, ARMword addr);
void mem_write_word (ARMul_State * state, ARMword addr, ARMword data);


ARMword fail_read_word (ARMul_State * state, ARMword addr);
void fail_write_word (ARMul_State * state, ARMword addr, ARMword data);
ARMword warn_read_word (ARMul_State * state, ARMword addr);
void warn_write_byte (ARMul_State * state, ARMword addr, ARMword data);
void warn_write_halfword (ARMul_State * state, ARMword addr, ARMword data);
void warn_write_word (ARMul_State * state, ARMword addr, ARMword data);
ARMword _read_word (ARMul_State * state, ARMword addr);
void _write_word (ARMul_State * state, ARMword addr, ARMword data);
ARMword real_read_byte (ARMul_State * state, ARMword addr);
void real_write_byte (ARMul_State * state, ARMword addr, ARMword data);
ARMword real_read_halfword (ARMul_State * state, ARMword addr);
void real_write_halfword (ARMul_State * state, ARMword addr, ARMword data);
ARMword real_read_word (ARMul_State * state, ARMword addr);
void real_write_word (ARMul_State * state, ARMword addr, ARMword data);
ARMword io_read_byte (ARMul_State * state, ARMword addr);
void io_write_byte (ARMul_State * state, ARMword addr, ARMword data);
ARMword io_read_halfword (ARMul_State * state, ARMword addr);
void io_write_halfword (ARMul_State * state, ARMword addr, ARMword data);
ARMword io_read_word (ARMul_State * state, ARMword addr);
void io_write_word (ARMul_State * state, ARMword addr, ARMword data);
#endif

#endif /* _ARMMEM_H_ */
