/*
	skyeye_touchscreen.c - skyeye general touchscreen device support functions
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
 * 03/19/2007	initial version by Anthony Lee
 */

#include "skyeye_device.h"
#include "skyeye_options.h"
#include "skyeye.h"
#include "skyeye_touchscreen.h"

unsigned int Pen_buffer[8];

/*
 * touchscreen_init() : Initialize the touchscreen module set.
 *	If you want to add a new touchscreen simulation,
 *	just add a "touchscreen_*_init" function to it.
 */
static void touchscreen_init (struct device_module_set *mod_set)
{
	memset(&Pen_buffer[0], 0, sizeof(Pen_buffer));
	touchscreen_skyeye_init (mod_set);
}


static int touchscreen_setup(struct device_desc *dev, void *option)
{
	struct touchscreen_device *ts_dev;
	struct touchscreen_option *ts_opt = (struct touchscreen_option*)option;
	int ret = 0;

	ts_dev = (struct touchscreen_device*)malloc(sizeof(struct touchscreen_device));
	if (ts_dev == NULL) return 1;

	memset(ts_dev, 0, sizeof(struct touchscreen_device));

	/* TODO */

	dev->dev = (void*)ts_dev;
	return ret;
}

static struct device_module_set ts_mod_set = {
	.name = "touchscreen",
	.count = 0,
	.count_max = 0,
	.init = touchscreen_init,
	.initialized = 0,
	.setup_module = touchscreen_setup,
};

/*
 * touchscreen_register() : Used by global device initialize function.
 */
void touchscreen_register(void)
{
	if (register_device_module_set(&ts_mod_set)) {
		SKYEYE_ERR("\"%s\" module set register error!\n", ts_mod_set.name);
	}
}

/* help functions. */

