/*
	skyeye_lcd_beos.c - LCD display emulation on BeOS' BWindow.
	Copyright (C) 2003 - 2007 Skyeye Develop Group
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
 * 01/31/2007   written by Anthony Lee
 */

#include "skyeye_lcd.h"
#include "skyeye_lcd_beos.h"

extern unsigned int Pen_buffer[8];


static u32 colors4b[16] =
{
	0x000000,0x000080,0x008000,0x008080,0x800000,0x800080,0x808000,0x808080,
	0xc0c0c0,0x0000ff,0x00ff00,0x00ffff,0xff0000,0xff00ff,0xffff00,0xffffff
};


void beos_lcd_skPenEvent(unsigned int *buffer, int eventType, int stateType, int x, int y)
{
	buffer[0] = x;
	buffer[1] = y;
	buffer[2] = 0;		// dx
	buffer[3] = 0;		// dy
	buffer[4] = eventType;	// event from pen (DOWN,UP,CLICK,MOVE)
	buffer[5] = stateType;	// state of pen (DOWN,UP,ERROR)
	buffer[6] = 1;		// no of the event
	buffer[7] = 0;		// time of the event (ms) since ts_open
}


static int beos_lcd_update(struct lcd_device *lcd_dev)
{
	if(lcd_dev == NULL || lcd_dev->priv == NULL) return -1;

	SkyEyeLCD_Be_Update(lcd_dev->priv);

	return 0;
}


static int beos_lcd_open(struct lcd_device *lcd_dev)
{
	unsigned char *fbSkyeyeADDR;

	if(lcd_dev == NULL || lcd_dev->priv != NULL) return -1;

	if((fbSkyeyeADDR = skyeye_find_lcd_dma(lcd_dev)) == NULL)
	{
		fprintf(stderr, "[BEOS_LCD]: Can't find LCD DMA from address 0x%x\n", lcd_dev->lcd_addr_begin);
		return -1;
	}

	lcd_dev->priv = SkyEyeLCD_Be_new(lcd_dev->width, lcd_dev->width + (int)lcd_dev->lcd_line_offset,
					 lcd_dev->height,
					 lcd_dev->depth,
					 lcd_dev->depth == 4 ? &colors4b[0] : NULL,
					 fbSkyeyeADDR,
					 &Pen_buffer[0],
					 (lcd_lookup_color_func)lcd_dev->lcd_lookup_color,
					 (void*)lcd_dev);

	return(lcd_dev->priv == NULL ? -1 : 0);
}


static int beos_lcd_close(struct lcd_device *lcd_dev)
{
	if(lcd_dev == NULL || lcd_dev->priv == NULL) return -1;

	SkyEyeLCD_Be_delete(lcd_dev->priv);

	lcd_dev->priv = NULL;
	lcd_dev->lcd_addr_end = lcd_dev->lcd_addr_begin = 0;

	return 0;
}


static int beos_lcd_filter_write(struct lcd_device *lcd_dev, u32 addr, u32 data, size_t count)
{
	int offsetADDR1, offsetADDR2;
	int w, x1, y1, x2, y2;

	if(lcd_dev == NULL || lcd_dev->priv == NULL ||
	   addr < lcd_dev->lcd_addr_begin || addr > lcd_dev->lcd_addr_end) return 0;

	offsetADDR1 = (int)(addr - lcd_dev->lcd_addr_begin) * 8 / lcd_dev->depth;
	offsetADDR2 = offsetADDR1 + (int)count * 8 / lcd_dev->depth;
	w = lcd_dev->width + (int)lcd_dev->lcd_line_offset;
	x1 = min(offsetADDR1 % w, w - 1);
	y1 = min(offsetADDR1 / w, lcd_dev->height - 1);
	x2 = min(offsetADDR2 % w, w - 1);
	y2 = min(offsetADDR2 / w, lcd_dev->height - 1);

	SkyEyeLCD_Be_DMAChanged(lcd_dev->priv,
				min(x1, x2), min(y1, y2),
				max(x1, x2), max(y1, y2));

	return 0;
}


int beos_lcd_init(struct lcd_device *lcd_dev)
{
	if (lcd_dev == NULL) return -1;

	lcd_dev->lcd_open = beos_lcd_open;
	lcd_dev->lcd_close = beos_lcd_close;
	lcd_dev->lcd_update = beos_lcd_update;
	lcd_dev->lcd_filter_read = NULL;
	lcd_dev->lcd_filter_write = beos_lcd_filter_write;

	return 0;
}

