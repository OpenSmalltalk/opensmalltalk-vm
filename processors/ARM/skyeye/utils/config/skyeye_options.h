/*
	skyeye_option.h - definitions of the device options structures.
	Copyright (C) 2004 Skyeye Develop Group
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
 * 05/16/2004  	initial version
 *
 *		walimis <wlm@student.dlut.edu.cn> 
 * */

#ifndef __SKYEYE_OPTION_H_
#define __SKYEYE_OPTION_H_

#include "skyeye.h"
#include "skyeye_device.h"

struct uart_option
{
	/* 2007-01-18 by Anthony Lee: for new uart device frame */
	char desc_in[MAX_STR_NAME];	/* description of device, such as path etc. */
	char desc_out[MAX_STR_NAME];	/* description of device, such as path etc. */
	int mod;

	char converter[MAX_STR_NAME];
};


struct timer_option
{
};


struct net_option
{
	unsigned char macaddr[6];
	unsigned char hostip[4];
	int ethmod;
};


struct lcd_option
{
	/* display mode. e.g. gtk, qt, X, sdl */
	int mod;

	int width;
	int height;

	int depth;
};


struct flash_option
{
	char dump[MAX_STR_NAME];
};


struct touchscreen_option
{
};


struct sound_option
{
	int mod;

	int channels;
	int bits_per_sample;
	int samples_per_sec;
};
struct code_cov_option
{
	int prof_on;
	char prof_filename[MAX_STR_NAME];
	int start;
	int end;
};

#endif /*__SKYEYE_OPTION_H_ */

