/*
	dev_sound_s3c44b0x.c - SAMSUNG's S3C44B0X sound simulation for skyeye
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
 * 03/25/2007	Written by Anthony Lee
 */

#include "arch/arm/common/armdefs.h"
#include "arch/arm/mach/s3c44b0.h"
#include "skyeye_config.h"
#include "skyeye_sound.h"

extern ARMhword *s3c44b0x_iisfifo_tx; /* defined in "skyeye_mach_s3c44b0x.c" */

struct snd_s3c44b0x_io {
	int count;
};

static struct device_default_value skyeye_snd_def[] = {
	/* name		base			size	interrupt array */
	{"s3c44b0",	IISFIF_RX_CONTROL,	0x08,	{0, 0, 0, 0}},
	{"s3c44b0x",	IISFIF_RX_CONTROL,	0x08,	{0, 0, 0, 0}},
	{NULL},
};


static void snd_s3c44b0x_fini(struct device_desc *dev)
{
	struct sound_device *snd_dev = (struct sound_device*)dev->dev;
	struct snd_s3c44b0x_io *io = (struct snd_s3c44b0x_io*)dev->data;

	if (snd_dev->sound_close != NULL) (*(snd_dev->sound_close))(snd_dev);

	free(dev->dev);
	free(io);
}


static void snd_s3c44b0x_reset(struct device_desc *dev)
{
	struct sound_device *snd_dev = (struct sound_device*)dev->dev;
	struct snd_s3c44b0x_io *io = (struct snd_s3c44b0x_io*)dev->data;

	memset(io, 0, sizeof(struct snd_s3c44b0x_io));

	if (snd_dev->sound_close != NULL) (*(snd_dev->sound_close))(snd_dev);
	if (snd_dev->sound_open != NULL) (*(snd_dev->sound_open))(snd_dev);
}


static void snd_s3c44b0x_update(struct device_desc *dev)
{
	struct sound_device *snd_dev = (struct sound_device*)dev->dev;

	if (snd_dev->sound_update != NULL) (*(snd_dev->sound_update))(snd_dev);
}


static int snd_s3c44b0x_read_word(struct device_desc *dev, uint32_t addr, uint32_t *data)
{
	struct sound_device *snd_dev = (struct sound_device*)dev->dev;
	struct snd_s3c44b0x_io *io = (struct snd_s3c44b0x_io*)dev->data;
	uint32_t offset = addr - dev->base;
	uint16_t tmp;

	switch (offset) {
		case 0: /* IISFIF_RX_CONTROL */
			*data = 0x1400;
			if (snd_dev->sound_read == NULL) break;
			if ((*(snd_dev->sound_read))(snd_dev, &tmp, 2) <= 0) break;
			*data = (0x1500 | tmp);
			break;

		case 4: /* IISFIF_TX_CONTROL */
			*data = (0xa20 | io->count);
			break;

		default:
			break;
	}

	return ADDR_HIT;
}


static int snd_s3c44b0x_write_word(struct device_desc *dev, uint32_t addr, uint32_t data)
{
	struct sound_device *snd_dev = (struct sound_device*)dev->dev;
	struct snd_s3c44b0x_io *io = (struct snd_s3c44b0x_io*)dev->data;
	int count, ret = ADDR_HIT;
	uint32_t offset = addr - dev->base;

	switch (offset) {
		case 4: /* IISFIF_TX_CONTROL */
			io->count = 0;
			if (snd_dev->sound_write == NULL) break;
			if ((data & 0xa10) == 0xa10 && s3c44b0x_iisfifo_tx != NULL) {
				if ((count = (data & 0xf)) == 0) break;
				if (count > 8) count = 8;

				count = (*(snd_dev->sound_write))(snd_dev, (void*)s3c44b0x_iisfifo_tx, count * 2);
				if (count <= 0) break;
				count /= 2;

				io->count = count;
			}
			break;

		default:
			ret = ADDR_NOHIT;
			break;
	}

	return ret;
}


static int snd_s3c44b0x_setup(struct device_desc *dev)
{
	struct snd_s3c44b0x_io *io;

	dev->fini = snd_s3c44b0x_fini;
	dev->reset = snd_s3c44b0x_reset;
	dev->update = snd_s3c44b0x_update;
	dev->read_word = snd_s3c44b0x_read_word;
	dev->write_word = snd_s3c44b0x_write_word;

	io = (struct snd_s3c44b0x_io*)malloc(sizeof(struct snd_s3c44b0x_io));
	if (io == NULL) return -1;

	dev->data = (void*)io;

	snd_s3c44b0x_reset(dev);

	/* see if we need to set default values. */
	set_device_default(dev, skyeye_snd_def);

	return 0;
}


void sound_s3c44b0x_init(struct device_module_set *mod_set)
{
	register_device_module("s3c44b0x", mod_set, &snd_s3c44b0x_setup);
}

