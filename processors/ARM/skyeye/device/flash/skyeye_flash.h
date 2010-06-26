/*
	skyeye_flash.h - skyeye general flash device file support functions
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

#ifndef __SKYEYE_FLASH_H_
#define __SKYEYE_FLASH_H_

#include "skyeye_device.h"


struct flash_device
{
	int mod;
	char dump[MAX_STR_NAME];

	void *state;

	void *priv;

	int (*flash_open) (struct flash_device * flash_dev);
	int (*flash_close) (struct flash_device * flash_dev);
	int (*flash_update) (struct flash_device * flash_dev);
	int (*flash_read) (struct flash_device * flash_dev, void *buf,
			   size_t count);
	int (*flash_write) (struct flash_device * flash_dev, void *buf,
			    size_t count);
};

/* helper functions */
int skyeye_flash_dump (const char *filename, uint32_t base, uint32_t size);


#endif	/*__SKYEYE_FLASH_H_*/
