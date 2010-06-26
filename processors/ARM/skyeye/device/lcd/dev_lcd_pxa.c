/*
	dev_lcd_pxa.c - skyeye PXA25x serial lcd controllor simulation
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
 * 06/17/2005   initial verion for pxa
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_lcd_pxa.h"

static struct device_default_value pxa_lcd_def[] = {
	/* name         base        size   interrupt array */
	{"pxa_lubbock", 0x44000000, 0x220, {0, 0, 0, 0}},
	{"pxa_mainstone", 0x44000000, 0x220, {0, 0, 0, 0}},
	{NULL},
};



static void
pxa_changed (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;

	lcd_dev->state = mc->state;


	//width  = (pxa_io.lccr1 & LCCR1_PPL) + 1;
	//height = ((pxa_io.lccr2 & LCCR2_LPP) + 1)*2;
	//depth  = 1 << ((pxa_io.lccr3 & LCCR3_BPP)>>24);
	//printf("io->fdadr0:%x, io->fdadr1:%x\n", io->fdadr0, io->fdadr1);
	lcd_dev->lcd_addr_begin = ((io->fdadr0 + 0x1000) & 0xffff1000);
	lcd_dev->depth = 1 << ((io->lccr3 & LCCR3_BPP) >> 24);
	lcd_dev->width = (io->lccr1 & LCCR1_PPL) + 1;
	lcd_dev->height = ((io->lccr2 & LCCR2_LPP) + 1) * 2;
	lcd_dev->lcd_open (lcd_dev);
}

static void
lcd_pxa_fini (struct device_desc *dev)
{
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;
	if (!dev->dev)
		free (dev->dev);
	if (!io)
		free (io);
}

static void
lcd_pxa_reset (struct device_desc *dev)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;

//      lcd_dev->lcd_addr_begin = 0xc0e01000;
	//       lcd_dev->lcd_addr_end = 0xc0e01000;
}

static void
lcd_pxa_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;

	lcd_dev->lcd_update (lcd_dev);
}


int
lcd_pxa_read_word (struct device_desc *dev, u32 addr, u32 * data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	//printf("%s:addr %x, %x\n", __FUNCTION__, addr, MACON);
	*data = 0;
	switch (offset) {
	case LCCR0:
		*data = io->lccr0;
		break;
	case LCCR1:
		*data = io->lccr1;
		break;
	case LCCR2:
		*data = io->lccr2;
		break;
	case LCCR3:
		*data = io->lccr3;
		break;
	case FDADR0:
		*data = io->fdadr0;
		break;
	case FDADR1:
		*data = io->fdadr1;
		break;
	case FSADR0:
		*data = io->fsadr0;
		break;
	case FSADR1:
		*data = io->fsadr1;
		break;
	default:
		break;
	}
	return ret;

}

int
lcd_pxa_write_word (struct device_desc *dev, u32 addr, u32 data)
{
	struct lcd_device *lcd_dev = (struct lcd_device *) dev->dev;
	struct lcd_pxa_io *io = (struct lcd_pxa_io *) dev->data;

	int offset = (addr - dev->base);
	int ret = ADDR_HIT;

	static int once = 0;

	//printf("%s:mach:%x\n", __FUNCTION__, dev->mach);
	switch (offset) {
	case LCCR0:
		if ((!(io->lccr0 & LCCR0_ENB)) && (data & LCCR0_ENB)) {
			if (!once) {
				once++;
				pxa_changed (dev);
			}
		}
		io->lccr0 = data;
		break;
	case LCCR1:
		io->lccr1 = data;
		break;
	case LCCR2:
		io->lccr2 = data;
		break;
	case LCCR3:
		io->lccr3 = data;
		break;
	case FDADR0:
		io->fdadr0 = data;
		break;
	case FDADR1:
		io->fdadr1 = data;
		break;
	case FSADR0:
		io->fsadr0 = data;
		break;
	case FSADR1:
		io->fsadr1 = data;
		break;
	default:
		ret = ADDR_NOHIT;
		break;
	}

	return ret;
}

static int
lcd_pxa_setup (struct device_desc *dev)
{
	int i;
	struct lcd_pxa_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = lcd_pxa_fini;
	dev->reset = lcd_pxa_reset;
	dev->update = lcd_pxa_update;
	dev->read_word = lcd_pxa_read_word;
	dev->write_word = lcd_pxa_write_word;

	io = (struct lcd_pxa_io *) malloc (sizeof (struct lcd_pxa_io));
	memset (io, 0, sizeof (struct lcd_pxa_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	lcd_pxa_reset (dev);


	/* see if we need to set default values.
	 * */
	set_device_default (dev, pxa_lcd_def);


	return 0;
}

void
lcd_pxa_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("pxa", mod_set, &lcd_pxa_setup);

}
