/*
        skyeye_types.h - some data types definition for skyeye debugger
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

#ifndef __SKYEYE_TYPES_H
#define __SKYEYE_TYPES_H

#include <stdint.h>

/*default machine word length */

#define WORD uint32_t
typedef struct _arch_s
{
	void (*init) ();
	void (*reset) ();
	void (*step_once) ();
	void (*set_pc)(WORD addr);
	WORD (*get_pc)();
	//chy 2004-04-15 
	int (*ICE_write_byte) (WORD addr, uint8_t v);
	int (*ICE_read_byte)(WORD addr, uint8_t *pv);
	int big_endian;
} generic_arch_t;
#endif
