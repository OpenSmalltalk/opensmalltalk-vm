/*
	skyeye_sound.h - skyeye sound device support functions
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
 * 03/25/2007	initial version by Anthony Lee
 */

#ifndef __SKYEYE_SOUND_H_
#define __SKYEYE_SOUND_H_

#include "skyeye_device.h"

/* sound simulation type */
#define SOUND_SIM_PCM		1	/* pcm data write to device directly */

struct sound_device
{
	int mod;

	int channels;
	int bits_per_sample;
	int samples_per_sec;

	/* private data. */
	void *priv;

	int (*sound_open)(struct sound_device *snd_dev);
	int (*sound_close)(struct sound_device *snd_dev);
	int (*sound_update)(struct sound_device *snd_dev);
	int (*sound_read)(struct sound_device *snd_dev, void *buf, size_t count);
	int (*sound_write)(struct sound_device *snd_dev, void *buf, size_t count);
};


/* sound controller initialize functions */
extern void sound_s3c44b0x_init(struct device_module_set *mod_set);


/* modules */
int pcm_sound_open(struct sound_device *snd_dev);
int pcm_sound_close(struct sound_device *snd_dev);
int pcm_sound_update(struct sound_device *snd_dev);
int pcm_sound_read(struct sound_device *snd_dev, void *buf, size_t count);
int pcm_sound_write(struct sound_device *snd_dev, void *buf, size_t count);


/* help function*/

#endif	/* __SKYEYE_SOUND_H_ */

