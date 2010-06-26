/*
	skyeye_touchscreen.h - skyeye general touchscreen device support functions
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

#ifndef __SKYEYE_TOUCHSCREEN_H_
#define __SKYEYE_TOUCHSCREEN_H_

#include "skyeye_device.h"

struct touchscreen_device
{
};

/* touchscreen controller initialize functions*/
extern void touchscreen_skyeye_init(struct device_module_set *mod_set);

/* help function*/

#endif	/* __SKYEYE_TOUCHSCREEN_H_ */

