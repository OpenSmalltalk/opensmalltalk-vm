/*
	skyeye_tap.h - A kernel driver for SkyEye's net simulation on BeOS
	Copyright (C) 2007 Anthony Lee <don.anthony.lee+program@gmail.com>

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
 * 02/01/2007   written by Anthony Lee
 */

#ifndef __SKYEYE_TAP_BEOS_DRIVER_H__
#define __SKYEYE_TAP_BEOS_DRIVER_H__

#include <drivers/Drivers.h>

#define SKYEYE_TAP_RX_PORT_NAME			"SkyEye_Tap_RX"
#define SKYEYE_TAP_TX_PORT_NAME			"SkyEye_Tap_TX"

#define SKYEYE_TAP_RX_PORT_FOR_USER		SKYEYE_TAP_TX_PORT_NAME
#define SKYEYE_TAP_TX_PORT_FOR_USER		SKYEYE_TAP_RX_PORT_NAME
#define SKYEYE_TAP_PORT_MSG_CODE		'snet'

#define SKYEYE_TAP_DEVICE_NAME			"net/skyeye_tap/0"
#define SKYEYE_TAP_DEVICE			"/dev/" SKYEYE_TAP_DEVICE_NAME
#define SKYEYE_TAP_FRAME_SIZE			1560

enum
{
	ETHER_GETADDR = B_DEVICE_OP_CODES_END,	/* get ethernet address */
	ETHER_INIT,				/* set irq and port */
	ETHER_NONBLOCK,				/* set/unset nonblocking mode */
	ETHER_ADDMULTI,				/* add multicast addr */
	ETHER_REMMULTI,				/* rem multicast addr */
	ETHER_SETPROMISC,			/* set promiscuous */
	ETHER_GETFRAMESIZE,			/* get frame size */
};

#endif /* __SKYEYE_TAP_BEOS_DRIVER_H__ */
