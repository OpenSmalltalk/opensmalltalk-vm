/*
	dev_lcd_au1100.c - skyeye Alchemy Au1100TM lcd controllor simulation
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

/*
 * WARNING: uncompleted yet !!!
 */

#include "skyeye_config.h"
#include "skyeye_lcd.h"
#include "dev_lcd_au1100.h"

#define LCD_AU1100_DEBUG	1

#define PRINT(x...)		printf("[LCD_AU1100]: " x)

#if LCD_AU1100_DEBUG
#define DEBUG(x...)		printf("[LCD_AU1100]: " x)
#else
#define DEBUG(x...)		(void)0
#endif


static struct device_default_value au1100_lcd_def[] = {
	/* name		base		size	interrupt array */
	{"au1100",	0x15000000,	0x500,	{0, 0, 0, 0}},
	{NULL},
};


static void lcd_au1100_changed(struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;
	struct lcd_au1100_io *io = (struct lcd_au1100_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	int depth = 1, width, height;

	/* TODO: not test yet!!! */
	if (AU1100_LCD_IS_COLOR_ELSE_MONO(io)) {
		depth = AU1100_LCD_BITS_PER_PIXEL(io);
		if (depth < 4) {
			depth = (1 << depth);
		} else if (depth < 6) {
			depth = (12 + (depth - 4) << 2);
		} else {
			PRINT(" *** WARNING: unsupported depth !!!\n");
			return;
		}
	}

	width = AU1100_LCD_WIDTH(io);
	height = AU1100_LCD_HEIGHT(io);

	lcd_dev->state = mc->state;

	lcd_dev->lcd_close(lcd_dev);

	if (AU1100_LCD_GO(io)) { /* start sending framebuffer to LCD */
		lcd_dev->lcd_line_offset = 0;
		lcd_dev->lcd_addr_begin = AU1100_LCD_FRAMEBUFFER_ADDR(io);
		lcd_dev->lcd_addr_end = lcd_dev->lcd_addr_begin + width * height * depth / 8 - 1;

		DEBUG("depth: %d, width: %d, height: %d\n", depth, width, height);
		DEBUG("control: 0x%x\n", io->control);
		DEBUG("horz_timing: 0x%x\n", io->horz_timing);
		DEBUG("vert_timing: 0x%x\n", io->vert_timing);
		DEBUG("dma_addr0: 0x%x\n", io->dma_addr0);
		DEBUG("dma_addr1: 0x%x\n", io->dma_addr1);
		DEBUG("words: 0x%x\n", io->words);
		DEBUG("lcd_addr_begin: 0x%x\n", lcd_dev->lcd_addr_begin);

		if (AU1100_LCD_IS_DUAL_PANEL(io)) PRINT(" *** WARNING: Dual scan mode unsupported !!!\n");

		lcd_dev->depth = depth;
		lcd_dev->width = width;
		lcd_dev->height = height;

		lcd_dev->device_priv = (void*)io;
		lcd_dev->lcd_open(lcd_dev);
	}
}


static void lcd_au1100_fini(struct device_desc *dev)
{
	struct lcd_au1100_io *io = (struct lcd_au1100_io*)dev->data;
	if(dev->dev != NULL) free(dev->dev); /* lcd_device from "lcd_setup()", so we free it. */
	if(io != NULL) free(io);
}


static void lcd_au1100_reset(struct device_desc *dev)
{
	struct lcd_au1100_io *io = (struct lcd_au1100_io*)dev->data;
	memset(io, 0, sizeof(struct lcd_au1100_io));
}


static void lcd_au1100_update(struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;

	lcd_dev->lcd_update(lcd_dev);
}


int lcd_au1100_read_word(struct device_desc *dev, uint32_t addr, uint32_t *data)
{
	struct lcd_au1100_io *io = (struct lcd_au1100_io*)dev->data;

	int offset = addr - dev->base;
	int ret = ADDR_HIT;

	*data = 0;

	if (offset >= AU1100_LCD_PALLETTE_BASE && offset < AU1100_LCD_PALLETTE_BASE + 0xff) {
		offset -= AU1100_LCD_PALLETTE_BASE;
		memcpy(data, &io->pallette[offset], (offset < 0xfb ? 4 : (0xff - offset)));
		return ret;
	}

	switch(offset) {
		case AU1100_LCD_CONTROL:
			*data = io->control;
			break;

		case AU1100_LCD_INT_STATUS:
			*data = io->int_status;
			break;

		case AU1100_LCD_INT_ENABLE:
			*data = io->int_enable;
			break;

		case AU1100_LCD_HORZ_TIMING:
			*data = io->horz_timing;
			break;

		case AU1100_LCD_VERT_TIMING:
			*data = io->vert_timing;
			break;

		case AU1100_LCD_CLK_CONTROL:
			*data = io->clk_control;
			break;

		case AU1100_LCD_DMA_ADDR0:
			*data = io->dma_addr0;
			break;

		case AU1100_LCD_DMA_ADDR1:
			*data = io->dma_addr1;
			break;

		case AU1100_LCD_WORDS:
			*data = io->words;
			break;

		case AU1100_LCD_PWM_DIV:
			*data = io->pwm_div;
			break;

		case AU1100_LCD_PWM_HI:
			*data = io->pwm_hi;
			break;

		default:
			break;
	}

	return ret;
}


int lcd_au1100_write_word(struct device_desc *dev, uint32_t addr, uint32_t data)
{
	struct lcd_au1100_io *io = (struct lcd_au1100_io*)dev->data;

	int offset = addr - dev->base;
	int ret = ADDR_HIT;

	if (offset >= AU1100_LCD_PALLETTE_BASE && offset < AU1100_LCD_PALLETTE_BASE + 0xff) {
		offset -= AU1100_LCD_PALLETTE_BASE;
		memcpy(&io->pallette[offset], &data, (offset < 0xfb ? 4 : (0xff - offset)));
		return ret;
	}

	switch (offset) {
		case AU1100_LCD_CONTROL:
			if (io->control != data) {
				io->control = data;
				lcd_au1100_changed(dev);
			}
			break;

		case AU1100_LCD_INT_STATUS:
			io->int_status = data;
			break;

		case AU1100_LCD_INT_ENABLE:
			io->int_enable = data;
			break;

		case AU1100_LCD_HORZ_TIMING:
			io->horz_timing = data;
			break;

		case AU1100_LCD_VERT_TIMING:
			io->vert_timing = data;
			break;

		case AU1100_LCD_CLK_CONTROL:
			io->clk_control = data;
			break;

		case AU1100_LCD_DMA_ADDR0:
			io->dma_addr0 = data;
			break;

		case AU1100_LCD_DMA_ADDR1:
			io->dma_addr1 = data;
			break;

		case AU1100_LCD_WORDS:
			io->words = data;
			break;

		case AU1100_LCD_PWM_DIV:
			io->pwm_div = data;
			break;

		case AU1100_LCD_PWM_HI:
			io->pwm_hi = data;
			break;

		default:
			ret = ADDR_NOHIT;
			break;
	}

	return ret;
}


static int lcd_au1100_setup(struct device_desc *dev)
{
	struct lcd_au1100_io *io;

	dev->fini = lcd_au1100_fini;
	dev->reset = lcd_au1100_reset;
	dev->update = lcd_au1100_update;
	dev->read_word = lcd_au1100_read_word;
	dev->write_word = lcd_au1100_write_word;

	if((io = (struct lcd_au1100_io*)malloc(sizeof(struct lcd_au1100_io))) == NULL) return -1;

	dev->data = (void*)io;

	lcd_au1100_reset(dev);

	/* see if we need to set default values. */
	set_device_default(dev, au1100_lcd_def);

	return 0;
}


void lcd_au1100_init(struct device_module_set *mod_set)
{
	register_device_module("au1100", mod_set, &lcd_au1100_setup);
}

