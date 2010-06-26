/*  armengr.h -- ARMulator emulation macros:  SA11x Instruction Emulator.
    Copyright (C) 1994 Advanced RISC Machines Ltd.
 
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
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */
#ifndef _ARMENGR_H_
#define _ARMENGR_H_

extern void ARMul_EnergyInit (ARMul_State * state);
extern void ARMul_do_energy (ARMul_State * state, ARMword instr, ARMword pc);
extern void ARMul_do_cycle (ARMul_State * state);
#endif
