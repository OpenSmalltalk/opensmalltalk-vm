/*
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
#ifndef _ARM7100_MMU_H_
#define _ARM7100_MMU_H_

typedef struct arm7100_mmu_s
{
	cache_t cache_t;
	tlb_t tlb_t;
} arm7100_mmu_t;

extern mmu_ops_t arm7100_mmu_ops;
#endif	/*_ARM7100_MMU_H_*/
