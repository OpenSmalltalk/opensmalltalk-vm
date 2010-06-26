/*
	dev_lcd_s3c2410.c - skyeye SAMSUNG s3c2410 lcd controllor simulation
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
 * 06/17/2005   initial verion for s3c2410
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_lcd_s3c2410.h"

static struct device_default_value s3c2410_lcd_def[] = {
	/* name         base        size   interrupt array */
	{"s3c2410x", 0x4d000000, 0x60, {0, 0, 0, 0}},
	{"s3c2440", 0x4d000000, 0x60, {0, 0, 0, 0}},
	{NULL},
};



static void
s3c2410_changed (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	int bppmode = ((io->lcdcon1 >> 1) & 0xF);
	int depth = 16;

	lcd_dev->state = mc->state;

	lcd_dev->lcd_close (lcd_dev);

	/*
	   if ((bppmode <= 4)) {
	   if (bppmode == 4)
	   depth = 12;
	   else
	   depth = 2^bppmode;
	   } else {
	   if (bppmode == 0xd)
	   depth = 24;
	   else
	   depth = 2^(bppmode - 8);
	   }
	 */

	//printf("lcdsaddr1:%x\n", io->lcdsaddr1<<1);

	/* we here use lcdsaddr1 as lcd_addr_begin */
	lcd_dev->lcd_addr_begin = io->lcdsaddr1 << 1;
	lcd_dev->depth = depth;
	lcd_dev->height = ((io->lcdcon2 >> 14) & 0x3ff) + 1;
	lcd_dev->width = ((io->lcdcon3 >> 8) & 0x7ff) + 1;
	lcd_dev->lcd_open (lcd_dev);
}

static void
lcd_s3c2410_fini (struct device_desc *dev)
{
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;
	if (!dev->dev)
		free (dev->dev);
	if (!io)
		free (io);
}

static void
lcd_s3c2410_reset (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;

	//lcd_dev->lcd_addr_begin = 0xc0141000;
	//lcd_dev->lcd_addr_end = 0xc0141000;
}

static void
lcd_s3c2410_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;

	lcd_dev->lcd_update (lcd_dev);

}


int
lcd_s3c2410_read_word (struct device_desc *dev, u32 addr, u32 * data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	//printf("%s:addr %x, %x\n", __FUNCTION__, addr, MACON);
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
	case LCDCON4:
		*data = io->lcdcon4;
		break;
	case LCDCON5:
		*data = io->lcdcon5;
		break;
	default:
		break;
	}
	return ret;

}

int
lcd_s3c2410_write_word (struct device_desc *dev, u32 addr, u32 data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_s3c2410_io *io = (struct lcd_s3c2410_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	//printf("%s:mach:%x\n", __FUNCTION__, dev->mach);
	switch (offset) {
	case LCDCON1:
		if ((io->lcdcon1 != data) && (data & 0x1)) {
			io->lcdcon1 = data;
			s3c2410_changed (dev);
		}
		break;
	case LCDCON2:
		io->lcdcon2 = data;
		break;
	case LCDCON3:
		io->lcdcon3 = data;
		break;
	case LCDCON4:
		io->lcdcon4 = data;
		break;
	case LCDCON5:
		io->lcdcon5 = data;
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
	default:
		ret = ADDR_NOHIT;
		break;
	}

	return ret;
}

static int
lcd_s3c2410_setup (struct device_desc *dev)
{
	int i;
	struct lcd_s3c2410_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = lcd_s3c2410_fini;
	dev->reset = lcd_s3c2410_reset;
	dev->update = lcd_s3c2410_update;
	dev->read_word = lcd_s3c2410_read_word;
	dev->write_word = lcd_s3c2410_write_word;

	io = (struct lcd_s3c2410_io *)
		malloc (sizeof (struct lcd_s3c2410_io));
	memset (io, 0, sizeof (struct lcd_s3c2410_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	lcd_s3c2410_reset (dev);


	/* see if we need to set default values.
	 * */
	set_device_default (dev, s3c2410_lcd_def);


	return 0;
}

void
lcd_s3c2410_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("s3c2410x", mod_set, &lcd_s3c2410_setup);

}
