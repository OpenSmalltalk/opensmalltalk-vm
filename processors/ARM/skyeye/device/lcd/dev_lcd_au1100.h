/*
	dev_lcd_au1100.h - skyeye Alchemy Au1100TM lcd controllor simulation
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

/*
 * 03/19/2007   written by Anthony Lee
 */

#ifndef __DEV_LCD_AU1100_H_
#define __DEV_LCD_AU1100_H_

#include <stdint.h>

#define AU1100_LCD_CONTROL		(0x0000)
#define AU1100_LCD_INT_STATUS		(0x0004)
#define AU1100_LCD_INT_ENABLE		(0x0008)
#define AU1100_LCD_HORZ_TIMING		(0x000c)
#define AU1100_LCD_VERT_TIMING		(0x0010)
#define AU1100_LCD_CLK_CONTROL		(0x0014)
#define AU1100_LCD_DMA_ADDR0		(0x0018)
#define AU1100_LCD_DMA_ADDR1		(0x001c)
#define AU1100_LCD_WORDS		(0x0020)
#define AU1100_LCD_PWM_DIV		(0x0024)
#define AU1100_LCD_PWM_HI		(0x0028)
#define AU1100_LCD_PALLETTE_BASE	(0x0400)

typedef struct lcd_au1100_io
{
	uint32_t	control;
	uint32_t	int_status;
	uint32_t	int_enable;
	uint32_t	horz_timing;
	uint32_t	vert_timing;
	uint32_t	clk_control;
	uint32_t	dma_addr0;
	uint32_t	dma_addr1;
	uint32_t	words;
	uint32_t	pwm_div;
	uint32_t	pwm_hi;
	uint8_t		pallette[256];
} lcd_au1100_io_t;


#define AU1100_LCD_6BITS_DATA_FORMAT(io)		((io->control >> 18) & 0x7)
#define AU1100_LCD_ROTATE_DEGREE(io)			((io->control >> 13) & 0x3)
#define AU1100_LCD_IS_BGR_ELSE_RGB(io)			((io->control >> 11) & 0x1)
#define AU1100_LCD_IS_DUAL_PANEL(io)			((io->control >> 10) & 0x1)
#define AU1100_LCD_PIXEL_ORDER(io)			((io->control >> 8) & 0x3)
#define AU1100_LCD_MONO_IS_8BITS_ELSE_4BITS(io)		((io->control >> 7) & 0x1)
#define AU1100_LCD_IS_COLOR_ELSE_MONO(io)		((io->control >> 5) & 0x1)
#define AU1100_LCD_BITS_PER_PIXEL(io)			((io->control >> 1) & 0x7)
#define AU1100_LCD_GO(io)				(io->control & 0x1)

#define AU1100_LCD_WIDTH(io)				((io->horz_timing & 0x3ff) + 1)
#define AU1100_LCD_HEIGHT(io)				((io->vert_timing & 0x3ff) + 1)
#define AU1100_LCD_FRAMEBUFFER_ADDR(io)			(io->dma_addr0 >> 5)

#endif /* __DEV_LCD_AU1100_H_ */

