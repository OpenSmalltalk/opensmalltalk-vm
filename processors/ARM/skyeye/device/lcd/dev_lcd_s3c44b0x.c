/*
	dev_lcd_s3c44b0x.c - skyeye S3C44B0X lcd controllor simulation
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
 * 01/27/2007   written by Anthony Lee
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_lcd_s3c44b0x.h"

#define LCD_S3C44B0X_DEBUG	0

#define PRINT(x...)	printf("[LCD_S3C44B0X]: " x)

#if LCD_S3C44B0X_DEBUG
#define DEBUG(x...)	printf("[LCD_S3C44B0X]: " x)
#else
#define DEBUG(x...)	(void)0
#endif

static struct device_default_value s3c44b0x_lcd_def[] = {
	/* name		base		size	interrupt array */
	{"s3c44b0",	0x1f00000,	0x48,	{0, 0, 0, 0}},
	{"s3c44b0x",	0x1f00000,	0x48,	{0, 0, 0, 0}},
	{NULL},
};


static u32 s3c44b0x_lookup_color_MONO(struct lcd_device *lcd_dev, u32 color)
{
	return (color ? 0xffffff : 0x000000);
}


static u32 s3c44b0x_lookup_color_G4(struct lcd_device *lcd_dev, u32 color)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)lcd_dev->device_priv;

	u8 gray = (io->lcdbluelut >> ((color & 0x3) << 2)) & 0xf;

	return (((u32)((gray << 4) | 0xf) << 16) | ((u32)((gray << 4) | 0xf) << 8) | (u32)((gray << 4) | 0xf));
}


static u32 s3c44b0x_lookup_color_G16(struct lcd_device *lcd_dev, u32 color)
{
	u8 gray = color & 0xf;

	return (((u32)((gray << 4) | 0xf) << 16) | ((u32)((gray << 4) | 0xf) << 8) | (u32)((gray << 4) | 0xf));
}


static u32 s3c44b0x_lookup_color_C256(struct lcd_device *lcd_dev, u32 color)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)lcd_dev->device_priv;
	u8 c = color & 0xff;

	u8 r = (io->lcdredlut >> ((c >> 5) << 2)) & 0xf;
	u8 g = (io->lcdgreenlut >> (((c >> 2) & 0x7) << 2)) & 0xf;
	u8 b = (io->lcdbluelut >> ((c & 0x3) << 2)) & 0xf;

	return (((u32)((r << 4) | 0xf) << 16) | ((u32)((g << 4) | 0xf) << 8) | (u32)((b << 4) | 0xf));
}


static void lcd_s3c44b0x_changed(struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	ARMul_State *state = (ARMul_State*)mc->state;

	int DISMOD = (io->lcdcon1 >> 5) & 0x3;
	int HOZVAL = (io->lcdcon2 >> 10) & 0x7ff;
	int LINEVAL = io->lcdcon2 & 0x3ff;
	int MODESEL = (io->lcdsaddr1 >> 27) & 0x3;
	int OFFSIZE = (io->lcdsaddr3 >> 9) & 0x7ff;
	int PAGEWIDTH = io->lcdsaddr3 & 0x1ff;
	int BSWP = (io->lcdsaddr2 >> 29) & 0x1;

	int depth, width, height;

	if (state == NULL) return;
	lcd_dev->state = (void*)state;

	lcd_dev->lcd_color_right_to_left = 0;
	lcd_dev->lcd_lookup_color = NULL;
	lcd_dev->lcd_color_right_to_left = 0;

	/* In big endian mode, the dma also be big endian per 4 bytes. */
	lcd_dev->lcd_dma_swap_word = (BSWP ? (!state->bigendSig) : state->bigendSig);

	if (MODESEL == 0) { /* monochrome mode */
		depth = 1;
		lcd_dev->lcd_lookup_color = s3c44b0x_lookup_color_MONO;
	} else if (MODESEL == 1) { /* 4-level gray mode */
		depth = 2;
		lcd_dev->lcd_lookup_color = s3c44b0x_lookup_color_G4;
	} else if (MODESEL == 2) { /* 16-level gray mode */
		depth = 4;
		lcd_dev->lcd_lookup_color = s3c44b0x_lookup_color_G16;
	} else if (MODESEL == 3) { /* 8 bits color mode */
		depth = 8;
		lcd_dev->lcd_lookup_color = s3c44b0x_lookup_color_C256;
	}

	width = (HOZVAL + 1) * (DISMOD == 1 ? 4 : 8);
	if (depth == 8) width /= 3;

	if (DISMOD == 0) height = (LINEVAL + 1) >> 1; /* dual scan */
	else height = LINEVAL + 1; /* single scan */

	lcd_dev->lcd_close(lcd_dev);

	if (io->lcdcon1 & 0x1) { /* ENVID = 1 */
		lcd_dev->lcd_line_offset = OFFSIZE << (4 - MODESEL);
		lcd_dev->lcd_addr_end = lcd_dev->lcd_addr_begin = (io->lcdsaddr1 & 0x7ffffff) << 1;
		lcd_dev->lcd_addr_end += (width + PAGEWIDTH << (4 - MODESEL)) * height * depth / 8 - 1;

		DEBUG("DISMOD: 0x%x, HOZVAL: 0x%x, LINEVAL: 0x%x, MODESEL: 0x%x, BSWP: %d\n",
		      DISMOD, HOZVAL, LINEVAL, MODESEL, BSWP);
		DEBUG("OFFSIZE: 0x%x, PAGEWIDTH: 0x%x\n", OFFSIZE, PAGEWIDTH);
		DEBUG("depth: %d, width: %d, height: %d\n", depth, width, height);
		DEBUG("lcdsaddr1: 0x%x\n", io->lcdsaddr1);
		DEBUG("lcd_addr_begin: 0x%x\n", lcd_dev->lcd_addr_begin);

		if (DISMOD == 0) PRINT(" *** WARNING: Dual scan mode unsupported !!!\n");

		lcd_dev->depth = depth;
		lcd_dev->width = width;
		lcd_dev->height = height;

		lcd_dev->device_priv = (void*)io;
		lcd_dev->lcd_open(lcd_dev);
	}
}


static void lcd_s3c44b0x_fini(struct device_desc *dev)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;
	if (dev->dev != NULL) free(dev->dev); /* lcd_device from "lcd_setup()", so we free it. */
	if (io != NULL) free(io);
}


static void lcd_s3c44b0x_reset(struct device_desc *dev)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;

	io->lcddp12 = 0xa5a5;
	io->lcddp47 = 0xba5da65;
	io->lcddp35 = 0xa5a5f;
	io->lcddp23 = 0xd6b;
	io->lcddp57 = 0xeb7b5ed;
	io->lcddp34 = 0x7dbe;
	io->lcddp45 = 0x7ebdf;
	io->lcddp67 = 0x7fdfbfe;

	io->lcddithmode = 0x0;
}


static void lcd_s3c44b0x_update(struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;

	lcd_dev->lcd_update(lcd_dev);
}


int lcd_s3c44b0x_read_word(struct device_desc *dev, u32 addr, u32 *data)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;

	int offset = addr - dev->base;
	int ret = ADDR_HIT;

	*data = 0;

	switch (offset) {
		case LCDCON1:
			*data = io->lcdcon1;
			break;

		case LCDCON2:
			*data = io->lcdcon2;
			break;

		case LCDCON3:
			*data = io->lcdcon3;
			break;

		case LCDSADDR1:
			*data = io->lcdsaddr1;
			break;

		case LCDSADDR2:
			*data = io->lcdsaddr2;
			break;

		case LCDSADDR3:
			*data = io->lcdsaddr3;
			break;

		case REDLUT:
			*data = io->lcdredlut;
			break;

		case GREENLUT:
			*data = io->lcdgreenlut;
			break;

		case BLUELUT:
			*data = io->lcdbluelut;
			break;

		case DP1_2:
			*data = io->lcddp12;
			break;

		case DP4_7:
			*data = io->lcddp47;
			break;

		case DP3_5:
			*data = io->lcddp35;
			break;

		case DP2_3:
			*data = io->lcddp23;
			break;

		case DP5_7:
			*data = io->lcddp57;
			break;

		case DP3_4:
			*data = io->lcddp34;
			break;

		case DP4_5:
			*data = io->lcddp45;
			break;

		case DP6_7:
			*data = io->lcddp67;
			break;

		case DITHMODE:
			*data = io->lcddithmode;
			break;
	}

	return ret;
}


int lcd_s3c44b0x_write_word(struct device_desc *dev, u32 addr, u32 data)
{
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;

	int offset = addr - dev->base;
	int ret = ADDR_HIT;

	switch(offset) {
		case LCDCON1:
			if (io->lcdcon1 != data) {
				io->lcdcon1 = data;
				lcd_s3c44b0x_changed(dev);
			}
			break;

		case LCDCON2:
			io->lcdcon2 = data;
			break;

		case LCDCON3:
			io->lcdcon3 = data;
			break;

		case LCDSADDR1:
			io->lcdsaddr1 = data;
			break;

		case LCDSADDR2:
			io->lcdsaddr2 = data;
			break;

		case LCDSADDR3:
			io->lcdsaddr3 = data;
			break;

		case REDLUT:
			io->lcdredlut = data;
			break;

		case GREENLUT:
			io->lcdgreenlut = data;
			break;

		case BLUELUT:
			io->lcdbluelut = data;
			break;

		case DP1_2:
			io->lcddp12 = data;
			break;

		case DP4_7:
			io->lcddp47 = data;
			break;

		case DP3_5:
			io->lcddp35 = data;
			break;

		case DP2_3:
			io->lcddp23 = data;
			break;

		case DP5_7:
			io->lcddp57 = data;
			break;

		case DP3_4:
			io->lcddp34 = data;
			break;

		case DP4_5:
			io->lcddp45 = data;
			break;

		case DP6_7:
			io->lcddp67 = data;
			break;

		case DITHMODE:
			io->lcddithmode = data;
			break;

		default:
			ret = ADDR_NOHIT;
			break;
	}

	return ret;
}


static int lcd_s3c44b0x_filter_read(struct device_desc *dev, u32 addr, u32 *data, size_t count)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;

	if (lcd_dev->lcd_filter_read == NULL) return 0;
	if ((io->lcdcon1 & 0x1) == 0) return 0;

	return lcd_dev->lcd_filter_read(lcd_dev, addr, data, count);
}


static int lcd_s3c44b0x_filter_write(struct device_desc *dev, u32 addr, u32 data, size_t count)
{
	struct lcd_device *lcd_dev = (struct lcd_device*)dev->dev;
	struct lcd_s3c44b0x_io *io = (struct lcd_s3c44b0x_io*)dev->data;

	if (lcd_dev->lcd_filter_write == NULL) return 0;
	if ((io->lcdcon1 & 0x1) == 0) return 0;

	return lcd_dev->lcd_filter_write(lcd_dev, addr, data, count);
}


static int lcd_s3c44b0x_setup(struct device_desc *dev)
{
	struct lcd_s3c44b0x_io *io;

	dev->fini = lcd_s3c44b0x_fini;
	dev->reset = lcd_s3c44b0x_reset;
	dev->update = lcd_s3c44b0x_update;

	dev->filter_read = lcd_s3c44b0x_filter_read;
	dev->filter_write = lcd_s3c44b0x_filter_write;

	dev->read_word = lcd_s3c44b0x_read_word;
	dev->write_word = lcd_s3c44b0x_write_word;

	if ((io = (struct lcd_s3c44b0x_io*)malloc(sizeof(struct lcd_s3c44b0x_io))) == NULL) return -1;

	memset(io, 0, sizeof(struct lcd_s3c44b0x_io));
	dev->data = (void*)io;

	lcd_s3c44b0x_reset(dev);

	/* see if we need to set default values. */
	set_device_default(dev, s3c44b0x_lcd_def);

	return 0;
}


void lcd_s3c44b0x_init(struct device_module_set *mod_set)
{
	register_device_module("s3c44b0x", mod_set, &lcd_s3c44b0x_setup);
}

