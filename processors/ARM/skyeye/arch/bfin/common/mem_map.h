/*
        mem_map.h - memory map of bf533 
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
 * 01/12/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#ifndef __MEM_MAP_H__
#define __MEM_MAP_H__

#define IO_START 0xffc00000
#define IO_END 0xffffffff

#define ISRAM_SIZE 0x14000
#define ISRAM_START 0xFFA00000
#define ISRAM_END (ISRAM_START+ISRAM_SIZE)

#define DSRAM_SIZE 0x18000
#define DSRAM_START 0xFF800000
#define DSRAM_END (DSRAM_START+DSRAM_SIZE)

//psw 061606 scratchpad
#define SSRAM_SIZE 0x1000
#define SSRAM_START 0xFFB00000
#define SSRAM_END (SSRAM_START+SSRAM_SIZE)

#define BANK0_START 0x20000000
#define BANK3_END   0x20400000

#define SDRAM_START 0x0
#define SDRAM_END 0x08000000
#define SDRAM_SIZE (SDRAM_END-SDRAM_START)

#endif
