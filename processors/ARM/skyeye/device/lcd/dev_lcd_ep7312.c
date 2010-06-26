/*
	dev_lcd_ep7312.c - skyeye EP7312 serial lcd controllor simulation
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
 * 06/17/2005   initial verion for ep7312
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_lcd_ep7312.h"

static struct device_default_value ep7312_lcd_def[] = {
	/* name         base        size   interrupt array */
	{"ep7312", 0x800002c0, 0x4, {0, 0, 0, 0}},
	{"at91", 0xffc002c0, 0x4, {0, 0, 0, 0}},
	{NULL},
};



static void
ep7312_changed (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	u32 lcdcon = io->lcdcon;
	u32 vbufsiz = lcdcon & VBUFSIZ;
	u32 linelen = (lcdcon & LINELEN) >> LINELEN_SHIFT;

	lcd_dev->state = mc->state;

	lcd_dev->lcd_close (lcd_dev);


	lcd_dev->depth = 8;	//test by ywc 2004-07-24
	lcd_dev->width = (linelen + 1) * 16;
	if (linelen == 0x3b) {
		lcd_dev->depth = 12;	//test by ywc 2004-10-14
		lcd_dev->width = (linelen + 1) * 16 / 3;
	}
	lcd_dev->height =
		(vbufsiz + 1) * 128 / (lcd_dev->depth) / (lcd_dev->width);

	/* 2007-01-29 added by anthonylee */
	lcd_dev->lcd_addr_begin = 0xc0000000;

	lcd_dev->lcd_open (lcd_dev);
}

static void
lcd_ep7312_fini (struct device_desc *dev)
{
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;
	if (!dev->dev)
		free (dev->dev);
	if (!io)
		free (io);
}

static void
lcd_ep7312_reset (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;

	//io->lcdcon = GSEN|GSMD | 0x12bf | (0x27<<13);
	io->lcdcon = GSEN | GSMD | 0x95f | (0x13 << 13);

	/* 2007-01-29 removed by anthonylee */
#if 0
	lcd_dev->lcd_addr_begin = 0xc0000000;
	lcd_dev->lcd_addr_end = 0xc0000000;
#endif
}

static void
lcd_ep7312_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;

	if(lcd_dev->lcd_update)
		lcd_dev->lcd_update (lcd_dev);

}


int
lcd_ep7312_read_word (struct device_desc *dev, u32 addr, u32 * data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	//printf("%s:addr %x, %x\n", __FUNCTION__, addr, MACON);
	*data = 0;
	switch (offset) {
	case 0:
		*data = io->lcdcon;
		break;
	default:
		break;
	}
	return ret;

}

int
lcd_ep7312_write_word (struct device_desc *dev, u32 addr, u32 data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_ep7312_io *io = (struct lcd_ep7312_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	//printf("%s:mach:%x\n", __FUNCTION__, dev->mach);
	switch (offset) {
	case 0:
		if (io->lcdcon != data) {
			io->lcdcon = data;
			ep7312_changed (dev);
		}
		break;
	default:
		ret = ADDR_NOHIT;
		break;
	}

	return ret;
}

static int
lcd_ep7312_setup (struct device_desc *dev)
{
	int i;
	struct lcd_ep7312_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = lcd_ep7312_fini;
	dev->reset = lcd_ep7312_reset;
	dev->update = lcd_ep7312_update;
	dev->read_word = lcd_ep7312_read_word;
	dev->write_word = lcd_ep7312_write_word;

	io = (struct lcd_ep7312_io *) malloc (sizeof (struct lcd_ep7312_io));
	memset (io, 0, sizeof (struct lcd_ep7312_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	lcd_ep7312_reset (dev);


	/* see if we need to set default values.
	 * */
	set_device_default (dev, ep7312_lcd_def);


	return 0;
}

void
lcd_ep7312_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("ep7312", mod_set, &lcd_ep7312_setup);

}
