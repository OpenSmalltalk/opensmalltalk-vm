/*
	skyeye_net_tap_beos.c - tuntap net device file support functions on BeOS
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
 * 01/31/2007   written by Anthony Lee
 */

/*
 * TODO: To be sure that just one process read/write the tap.
 */

#include <sys/ioctl.h>
#include <stdlib.h>
#include <BeBuild.h>
#include <kernel/OS.h>

#include "skyeye_net.h"
#include "portable/beos/tap_driver/skyeye_tap.h"

#define TAP_BEOS_DEBUG	0

#define PRINT(x...)	printf("[TAP_BEOS]: " x)

#if TAP_BEOS_DEBUG
#define DEBUG(x...)	printf("[TAP_BEOS]: " x)
#else
#define DEBUG(x...)	(void)0
#endif

typedef struct tap_beos {
	port_id rxPort;
	port_id txPort;
} tap_beos;


int tuntap_open(struct net_device *net_dev)
{
	char buf[1024];
	tap_beos *dev = (tap_beos*)malloc(sizeof(tap_beos));

	net_dev->priv = NULL;
	if(dev == NULL) return -1;

#if (B_BEOS_VERSION >= 0x510)
	/* on BONE, the if_name is same as device. */
	snprintf(buf, sizeof(buf), "ifconfig %s %d.%d.%d.%d 255.255.255.0 up > /dev/null 2>&1",
		 SKYEYE_TAP_DEVICE, net_dev->hostip[0], net_dev->hostip[1],
		 net_dev->hostip[2], net_dev->hostip[3]);

	DEBUG("system(\"%s\")\n", buf);
	system(buf);
	snooze(1000000);
#endif

	if((dev->rxPort = find_port(SKYEYE_TAP_RX_PORT_FOR_USER)) < 0 ||
	   (dev->txPort = find_port(SKYEYE_TAP_TX_PORT_FOR_USER)) < 0)
	{
		PRINT("\x1b[31m******************************************************************\x1b[0m\n");
		PRINT("\x1b[31m*** You should install the skyeye_tap driver,\x1b[0m\n");
		PRINT("\x1b[31m*** see \"utils/portable/beos/tap_driver/README\" for more detail.\x1b[0m\n");
		PRINT("\x1b[31m******************************************************************\x1b[0m\n");

		free(dev);
		return -1;
	}

	net_dev->priv = (void*)dev;

	return 0;
}


int tuntap_close(struct net_device *net_dev)
{
	if(net_dev->priv != NULL)
	{
		free(net_dev->priv);
		net_dev->priv = NULL;
	}

	return 0;
}


int tuntap_read(struct net_device *net_dev, void *buf, size_t count)
{
	tap_beos *dev = (tap_beos*)net_dev->priv;
	ssize_t nBytes = 0;
	int32 code;

	if(dev == NULL) return -1;

	nBytes = read_port_etc(dev->rxPort, &code, buf, count, B_TIMEOUT, 1000);
	if(nBytes < 0 || code != SKYEYE_TAP_PORT_MSG_CODE) nBytes = -1;

#if TAP_BEOS_DEBUG
	if(nBytes > 0)
	{
		DEBUG("*********** READ ***********\n");
		print_packet(buf, nBytes);
		DEBUG("*****************************\n");
	}
	else
	{
		DEBUG("read failed(%d).\n", nBytes);
	}
#endif

	return (int)nBytes;
}


int tuntap_write(struct net_device *net_dev, void *buf, size_t count)
{
	tap_beos *dev = (tap_beos*)net_dev->priv;
	ssize_t nBytes = 0;

	if(dev == NULL) return -1;

	if(write_port_etc(dev->txPort, SKYEYE_TAP_PORT_MSG_CODE, buf, count, B_TIMEOUT, 1000) == B_OK) nBytes = (ssize_t)count;

#if TAP_BEOS_DEBUG
	if(nBytes > 0)
	{
		DEBUG("*********** WRITE ***********\n");
		print_packet(buf, nBytes);
		DEBUG("*****************************\n");
	}
	else
	{
		DEBUG("write failed(%d).\n", nBytes);
	}
#endif

	return (int)nBytes;
}


int tuntap_wait_packet(struct net_device *net_dev, struct timeval *tv)
{
	tap_beos *dev = (tap_beos*)net_dev->priv;
	bigtime_t timeout = (tv == NULL ? B_INFINITE_TIMEOUT : (bigtime_t)tv->tv_sec * (bigtime_t)1000000UL + (bigtime_t)tv->tv_usec);

	if(dev == NULL) return -1;

	if(port_buffer_size_etc(dev->rxPort, B_TIMEOUT, timeout) >= 0) return 0;

	return -1;
}

