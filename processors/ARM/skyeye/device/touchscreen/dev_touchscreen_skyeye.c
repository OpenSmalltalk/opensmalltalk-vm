/*
	dev_touchscreen_skyeye.c - skyeye custom touchscreen simulation
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
 * 03/19/2007	initial version, most from skyeye_mach_ep7312.c by ywc.
 * 			Anthony Lee <don.anthony.lee@gmail.com>
 */

#include <stdint.h>
#include "skyeye_config.h"
#include "skyeye_device.h"

/* Pen_buffer: defined in skyeye_touchscreen.c */
extern unsigned int Pen_buffer[8];

struct ts_skyeye_io {
	uint32_t ts_buffer[8];
};

static struct device_default_value skyeye_ts_def[] = {
	/* name			base		size	interrupt array */
#if 0
	{"at91",		0xff00b000,	0x20,	{17, 0, 0, 0}},
	{"ep7312",		0x8000b000,	0x20,	{6, 0, 0, 0}},
	{"pxa_lubbock",		0x40000300,	0x20,	{15, 0, 0, 0}},
	{"pxa_mainstone",	0x40000300,	0x20,	{15, 0, 0, 0}},
#endif
	{NULL},
};

static void ts_skyeye_set_update_intr(struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct machine_config *mc = (struct machine_config*)dev->mach;
	struct ts_skyeye_io *io = (struct ts_skyeye_io*)dev->data;

	if (mc->mach_set_intr == NULL) return;
	mc->mach_set_intr(intr->interrupts[0]);

	if (mc->mach_update_intr != NULL) mc->mach_update_intr(mc);
}

static void ts_skyeye_fini(struct device_desc *dev)
{
	struct ts_skyeye_io *io = (struct ts_skyeye_io*)dev->data;
	free(dev->dev);
	free(io);
}

static void ts_skyeye_reset(struct device_desc *dev)
{
	struct touchscreen_device *ts_dev = (struct touchscreen_device*)dev->dev;
	struct ts_skyeye_io *io = (struct ts_skyeye_io*) dev->data;

	memset(io, 0, sizeof(struct ts_skyeye_io));
}

static void ts_skyeye_update(struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct touchscreen_device *ts_dev = (struct touchscreen_device*)dev->dev;
	struct ts_skyeye_io *io = (struct ts_skyeye_io*)dev->data;
	struct machine_config *mc = (struct machine_config*)dev->mach;

	if (mc->mach_pending_intr == NULL) return;

	if ((!mc->mach_pending_intr(intr->interrupts[0]))) { /* if now has no ts interrupt, then query */
		if (Pen_buffer[6] == 1) { /* interrupt */
			*(io->ts_buffer + 0) = Pen_buffer[0];
			*(io->ts_buffer + 1) = Pen_buffer[1];
			*(io->ts_buffer + 4) = Pen_buffer[4];
			*(io->ts_buffer + 6) = Pen_buffer[6];

			ts_skyeye_set_update_intr(dev); /* update interrupt, ts driver will clear it */
			Pen_buffer[6] = 0;
		}
	}
}

static int ts_skyeye_read_word(struct device_desc *dev, uint32_t addr, uint32_t *data)
{
	struct touchscreen_device *ts_dev = (struct touchscreen_device*) dev->dev;
	struct ts_skyeye_io *io = (struct ts_skyeye_io*)dev->data;
	int offset = (addr & ~3) - dev->base;

	*data = io->ts_buffer[offset / 4];

	return ADDR_HIT;
}

static int ts_skyeye_write_word(struct device_desc *dev, uint32_t addr, uint32_t data)
{
	return ADDR_NOHIT;
}

static int ts_skyeye_setup(struct device_desc *dev)
{
	struct ts_skyeye_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = ts_skyeye_fini;
	dev->reset = ts_skyeye_reset;
	dev->update = ts_skyeye_update;
	dev->read_word = ts_skyeye_read_word;
	dev->write_word = ts_skyeye_write_word;

	io = (struct ts_skyeye_io*)malloc(sizeof(struct ts_skyeye_io));
	if (io == NULL) return 1;

	dev->data = (void*)io;

	ts_skyeye_reset(dev);

	/* see if we need to set default values. */
	set_device_default(dev, skyeye_ts_def);

	return 0;
}

void touchscreen_skyeye_init(struct device_module_set *mod_set)
{
	register_device_module("skyeye", mod_set, &ts_skyeye_setup);
}

