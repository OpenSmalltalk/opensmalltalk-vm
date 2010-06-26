/*
	dev_lcd_s3c2410.h - skyeye S3C2410 lcd controllor simulation
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
 * 07/25/2005   initial version
 *		walimis <wlm@student.dlut.edu.cn> 
 * */
#ifndef __DEV_LCD_S3C2410_H_
#define __DEV_LCD_S3C2410_H_


#define VBUFSIZ 0x00001fff	/* Video buffer size (bits/128-1) */
#define LINELEN 0x0007e000	/* Line length (pix/16-1) */
#define LINELEN_SHIFT   13
#define PIXPSC  0x01f80000	/* Pixel prescale (526628/pixels-1) */
#define PIXPSC_SHIFT    19
#define ACPSC   0x3e000000	/* AC prescale */
#define ACPSC_SHIFT     25
#define GSEN    0x40000000	/* Grayscale enable (0: monochrome) */
#define GSMD    0x80000000	/* Grayscale mode (0: 2 bit, 1: 4 bit) */


#define LCDCON1		(0x0)
#define LCDCON2		(0x4 * 1)
#define LCDCON3		(0x4 * 2)
#define LCDCON4		(0x4 * 3)
#define LCDCON5		(0x4 * 4)
#define LCDSADDR1	(0x4 * 5)
#define LCDSADDR2	(0x4 * 6)
#define LCDSADDR3	(0x4 * 7)

typedef struct lcd_s3c2410_io
{
	u32 lcdcon1;
	u32 lcdcon2;
	u32 lcdcon3;
	u32 lcdcon4;
	u32 lcdcon5;
	u32 lcdsaddr1;
	u32 lcdsaddr2;
	u32 lcdsaddr3;
	u32 lcdintpnd;
	u32 lcdsrcpnd;
	u32 lcdintmsk;
} lcd_s3c2410_io_t;


#endif //_DEV_LCD_S3C2410_H_
