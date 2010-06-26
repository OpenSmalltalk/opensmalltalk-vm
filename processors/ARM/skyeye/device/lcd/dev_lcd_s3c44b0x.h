/*
	dev_lcd_s3c44b0x.h - skyeye S3C44B0X lcd controllor simulation
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
 * 01/27/2007   initial version by Anthony Lee
 */

#ifndef __DEV_LCD_S3C44B0X_H_
#define __DEV_LCD_S3C44B0X_H_

#define LCDCON1		(0x0)
#define LCDCON2		(0x4)
#define LCDCON3		(0x40)
#define LCDSADDR1	(0x8)
#define LCDSADDR2	(0xc)
#define LCDSADDR3	(0x10)

#define REDLUT		(0x14)
#define GREENLUT	(0x18)
#define BLUELUT		(0x1c)

#define DP1_2		(0x20)
#define DP4_7		(0x24)
#define DP3_5		(0x28)
#define DP2_3		(0x2c)
#define DP5_7		(0x30)
#define DP3_4		(0x34)
#define DP4_5		(0x38)
#define DP6_7		(0x3c)
#define DITHMODE	(0x44)


typedef struct lcd_s3c44b0x_io
{
	u32 lcdcon1;
	u32 lcdcon2;
	u32 lcdcon3;
	u32 lcdsaddr1;
	u32 lcdsaddr2;
	u32 lcdsaddr3;

	u32 lcdredlut;
	u32 lcdgreenlut;
	u32 lcdbluelut;

	u32 lcddp12;
	u32 lcddp47;
	u32 lcddp35;
	u32 lcddp23;
	u32 lcddp57;
	u32 lcddp34;
	u32 lcddp45;
	u32 lcddp67;

	u32 lcddithmode;
} lcd_s3c44b0x_io_t;

#endif /* _DEV_LCD_S3C44B0X_H_ */

