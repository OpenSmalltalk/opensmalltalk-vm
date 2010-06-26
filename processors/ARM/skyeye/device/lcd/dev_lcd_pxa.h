/*
	dev_lcd_pxa.h - skyeye PXA25x lcd controllor simulation
	Copyright (C) 2003 - 2005 Skyeye Develop Group
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
 * 06/23/2005   initial version
 *		walimis <wlm@student.dlut.edu.cn> 
 * */
#ifndef __DEV_LCD_PXA_H_
#define __DEV_LCD_PXA_H_

/* registers */
#define LCCR0  0x000000
#define LCCR1  0x000004
#define LCCR2  0x000008
#define LCCR3  0x00000C

#define FDADR0  0x000200
#define FSADR0  0x000204
#define FIDR0   0x000208
#define LDCMD0  0x00020C

#define FDADR1  0x000210
#define FSADR1  0x000214
#define FIDR1   0x000218
#define LDCMD1  0x00021C




#define LCCR0_ENB       0x00000001
#define LCCR1_PPL       0x000003FF
#define LCCR2_LPP       0x000003FF
#define LCCR3_BPP       0x07000000


typedef struct lcd_pxa_io
{
	u32 lccr0;
	u32 lccr1;
	u32 lccr2;
	u32 lccr3;

	u32 fdadr0;
	u32 fdadr1;

	u32 fsadr0;
	u32 fsadr1;

} lcd_pxa_io_t;


#endif //_DEV_LCD_PXA_H_
