/*
    armio.c - I/O registers and interrupt controller.
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

#ifndef _ARMIO_H_
#define _ARMIO_H_

void io_reset (ARMul_State * state);
void io_do_cycle (ARMul_State * state);
ARMword io_read_word (ARMul_State * state, ARMword addr);
void io_write_word (ARMul_State * state, ARMword addr, ARMword data);
unsigned char mem_read_char (ARMul_State * state, ARMword addr);
void mem_write_char (ARMul_State * state, ARMword addr, unsigned char c);


#endif /* _ARMIO_H_ */
