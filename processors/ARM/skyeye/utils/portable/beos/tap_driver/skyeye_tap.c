/*
	skyeye_tap.c - A kernel driver for SkyEye's net simulation on BeOS
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


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <bsd_mem.h>

#include <support/SupportDefs.h>
#include <kernel/OS.h>
#include <drivers/KernelExport.h>

#include "skyeye_tap.h"

#define SKYEYE_TAP_DEBUG		0

#if SKYEYE_TAP_DEBUG
#define DEBUG(x...)			dprintf("[SKYEYE_TAP]: " __FUNCTION__ " --- " x)
#else
#define DEBUG(x...)			(void)0
#endif

#define PACKET_QUEUE_LENGTH		256
#define SKYEYE_TAP_MAC_ADDRESS		"SkyEye"
#define MAX_MULTI			32

static char *skyeye_tap_devs[] = {SKYEYE_TAP_DEVICE_NAME, NULL};
static int32 skyeye_tap_status = 0;

typedef uint8 (mac_address)[6];

typedef struct skyeye_tap
{
	int nonblocking;		/* non-blocking mode */
	int promisc;			/* promisc mode */
	uint32 nmulti;			/* number of multicast addresses */
	mac_address multi[MAX_MULTI];	/* multicast addresses */

	sem_id ioLocker;		/* io locker */

	bool interrupted;		/* interrupted system call */
	int32 inrw;			/* in read or write function */

	port_id rxPort;			/* port for receiving data from user */
	port_id txPort;			/* port for sending data to user */
} skyeye_tap;


static status_t domulti(skyeye_tap *dev, uint8 *addr, bool add)
{
	uint32 i, nmulti;
	status_t retVal;

	if((retVal = acquire_sem(dev->ioLocker)) != B_NO_ERROR) return retVal;

	if((nmulti = dev->nmulti) < MAX_MULTI || !add)
	{
		for(i = 0; i < nmulti; i++)
		{
			if(memcmp(&(dev->multi[i]), addr, 6) == 0) break;
		}

		if(i == nmulti && add)
		{
			memcpy(&(dev->multi[i]), addr, 6);
			dev->nmulti++;
		}
		else if(i < nmulti && !add)
		{
			if(i != nmulti - 1) memcpy(&dev->multi[i], &dev->multi[i + 1], (nmulti - i - 1) * 6);
			dev->nmulti--;
		}
	}
	else
	{
		retVal = B_ERROR;
	}

	release_sem_etc(dev->ioLocker, 1, 0);

	return retVal;
}


static bool check_packet(skyeye_tap *dev, uint8 *addr)
{
	int i;

	if(addr == NULL) return false;
	if(dev->promisc) return true;
	if(memcmp(addr, SKYEYE_TAP_MAC_ADDRESS, 6) == 0) return true;
	if(memcmp(addr, "\xff\xff\xff\xff\xff\xff", 6) == 0) return true;
	for(i = 0; i < dev->nmulti; i++) if(memcmp(addr, &dev->multi[i], 6) == 0) return true;
	return false;
}


static int recv_packet(skyeye_tap *dev, void *buf, size_t buflen)
{
	ssize_t bufSize = 0;
	int32 code;

	if(buf == NULL || acquire_sem(dev->ioLocker) != B_NO_ERROR) return -1;

	if((bufSize = port_buffer_size_etc(dev->rxPort, B_TIMEOUT, 1000)) >= 0)
	{
		if(read_port_etc(dev->rxPort, &code, buf, buflen, B_TIMEOUT, 1000) != bufSize ||
		   code != SKYEYE_TAP_PORT_MSG_CODE || buflen < 6 || !check_packet(dev, (uint8*)buf))
		{
			DEBUG("Invalid packet, drop it.(code: 0x%x, buflen: %u, bufSize: %u)\n", code, buflen, bufSize);
			bufSize = 0;
		}
		else
		{
			DEBUG("Read %d bytes.\n", bufSize);
		}
	}
	else
	{
		DEBUG("port_buffer_size_etc() return B_GENERAL_ERROR_BASE+0x%x.\n", bufSize - B_GENERAL_ERROR_BASE);
	}

	release_sem_etc(dev->ioLocker, 1, 0);

	return(bufSize >= 0 && bufSize <= SKYEYE_TAP_FRAME_SIZE ? (int)bufSize : 0);
}


static int send_packet(skyeye_tap *dev, const void *buf, size_t buflen)
{
	if(buf == NULL || buflen < 0 || buflen > SKYEYE_TAP_FRAME_SIZE) return -1;
	if(write_port_etc(dev->txPort, SKYEYE_TAP_PORT_MSG_CODE, buf, buflen, B_TIMEOUT, 1000) == B_OK) return (int)buflen;
	return 0;
}


static status_t open_hook(const char *name, uint32 flags, void **cookie)
{
	skyeye_tap *dev;

	*cookie = NULL;

	/* device is not SkyEye Tap */
	if(strcmp(skyeye_tap_devs[0], name) != 0) return EINVAL;

	/* open once */
	if(atomic_or(&skyeye_tap_status, 1) & 1) return B_BUSY;

	/* allocate storage for the cookie */
	if((*cookie = (dev = (skyeye_tap*)malloc(sizeof(skyeye_tap)))) == NULL)
	{
		atomic_and(&skyeye_tap_status, ~1);
		DEBUG("Failed to allocate memory for device!\n");
		return B_NO_MEMORY;
	}
	bzero(dev, sizeof(skyeye_tap));

	/* setup the cookie */
	dev->rxPort = dev->txPort = -1;
	dev->ioLocker = -1;
	dev->interrupted = false;
	dev->inrw = 0;
	dev->promisc = 1;

	if((dev->rxPort = create_port(PACKET_QUEUE_LENGTH, SKYEYE_TAP_RX_PORT_NAME)) < 0 ||
	   (dev->txPort = create_port(PACKET_QUEUE_LENGTH, SKYEYE_TAP_TX_PORT_NAME)) < 0 ||
	   (dev->ioLocker = create_sem(1, "skyeye_tap_io")) < 0 ||
	   set_port_owner(dev->rxPort, B_SYSTEM_TEAM) != B_OK ||
	   set_port_owner(dev->txPort, B_SYSTEM_TEAM) != B_OK ||
	   set_sem_owner(dev->ioLocker, B_SYSTEM_TEAM) != B_OK)
	{
		if(dev->rxPort >= 0) delete_port(dev->rxPort);
		if(dev->txPort >= 0) delete_port(dev->txPort);
		if(dev->ioLocker >= 0) delete_sem(dev->ioLocker);

		free(dev);
		atomic_and(&skyeye_tap_status, ~1);
		DEBUG("Failed to create port/sem for RX/TX!\n");

		*cookie = NULL;
		return B_ERROR;
	}

	DEBUG("dev = %x\n", dev);

	return B_NO_ERROR;
}


static status_t close_hook(void *data)
{
	skyeye_tap *dev = (skyeye_tap*)data;

	DEBUG("dev = %x\n", dev);

	/* force pending reads and writes to terminate */
	while(true) {if(acquire_sem(dev->ioLocker) == B_NO_ERROR) break;}
	dev->interrupted = true;
	close_port(dev->rxPort);
	close_port(dev->txPort);
	release_sem_etc(dev->ioLocker, 1, 0);

	while(dev->inrw != 0)
	{
		snooze(1000000);
		DEBUG("waiting for read/write to finish\n");
	}

	atomic_and(&skyeye_tap_status, ~1);

	delete_sem(dev->ioLocker);

	return B_NO_ERROR;
}


static status_t free_hook(void *data)
{
	DEBUG("dev = %x\n", data);
	free(data);
	return B_ERROR;
}


static status_t control_hook(void *data, uint32 msg, void *buf, size_t len)
{
	skyeye_tap *dev = (skyeye_tap*)data;
	unsigned int sz;

	if(data == NULL) return B_ERROR;

	switch(msg)
	{
		case ETHER_INIT:
			DEBUG("ETHER_INIT\n");
			return B_NO_ERROR;

		case ETHER_GETADDR:
			if(buf == NULL) return B_ERROR;
			DEBUG("GET_ADDR\n");
			memcpy(buf, SKYEYE_TAP_MAC_ADDRESS, 6);
			return B_NO_ERROR;

		case ETHER_NONBLOCK:
			if(buf == NULL || acquire_sem(dev->ioLocker) != B_NO_ERROR) return B_ERROR;
			dev->nonblocking = *((int*)buf);
			DEBUG("NON_BLOCK %d\n", dev->nonblocking);
			release_sem_etc(dev->ioLocker, 1, 0);
			return B_NO_ERROR;

		case ETHER_ADDMULTI:
		case ETHER_REMMULTI:
			if(buf == NULL) return B_ERROR;
			DEBUG("DO_MULTI(%s) - %2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x\n",
			      msg == ETHER_ADDMULTI ? "add" : "remove",
			      *((uint8*)buf), *((uint8*)buf + 1), *((uint8*)buf + 2),
			      *((uint8*)buf + 3), *((uint8*)buf + 4), *((uint8*)buf + 5));
			return(domulti(data, (uint8*)buf, msg == ETHER_ADDMULTI));

		case ETHER_SETPROMISC:
			if(buf == NULL || acquire_sem(dev->ioLocker) != B_NO_ERROR) return B_ERROR;
			dev->promisc = *((int*)buf);
			DEBUG("PROMISC %x\n", dev->promisc);
			release_sem_etc(dev->ioLocker, 1, 0);
			return B_NO_ERROR;

		case ETHER_GETFRAMESIZE:
			if(buf == NULL) return B_ERROR;
			sz = SKYEYE_TAP_FRAME_SIZE;
			DEBUG("GET_FRAMESIZE %u\n", sz);
			memcpy(buf, &sz, sizeof(sz));
			return B_NO_ERROR;

		default:
			break;
	}

	return B_ERROR;
}


static status_t read_hook(void *data, off_t pos, void *buf, size_t *len)
{
	skyeye_tap *dev = (skyeye_tap*)data;

	size_t buflen = *len;
	int packet_len = 0;
	status_t retVal = B_NO_ERROR;

	atomic_add(&dev->inrw, 1);

	while(true)
	{
		packet_len = recv_packet(dev, buf, buflen);

		if(acquire_sem(dev->ioLocker) != B_NO_ERROR)
		{
			atomic_add(&dev->inrw, -1);
			return B_INTERRUPTED;
		}

		if(dev->interrupted)
		{
			retVal = B_INTERRUPTED;
			break;
		}

		if(packet_len == 0 && dev->nonblocking == 0)
		{
			release_sem_etc(dev->ioLocker, 1, 0);
			snooze(100000);
			continue;
		}

		if(packet_len < 0) retVal = B_ERROR;

		break;
	}

	release_sem_etc(dev->ioLocker, 1, 0);

	atomic_add(&dev->inrw, -1);
	*len = (int)packet_len;

	return retVal;
}


static status_t write_hook(void *data, off_t pos, const void *buf, size_t *len)
{
	skyeye_tap *dev = (skyeye_tap*)data;

	size_t buflen = *len;
	int packet_len = 0;
	status_t retVal = B_NO_ERROR;

	atomic_add(&dev->inrw, 1);

	while(true)
	{
		packet_len = send_packet(dev, buf, buflen);

		if(acquire_sem(dev->ioLocker) != B_NO_ERROR)
		{
			atomic_add(&dev->inrw, -1);
			return B_INTERRUPTED;
		}

		if(dev->interrupted)
		{
			retVal = B_INTERRUPTED;
			break;
		}

		if(packet_len == 0 && dev->nonblocking == 0)
		{
			release_sem_etc(dev->ioLocker, 1, 0);
			snooze(100000);
			continue;
		}

		if(packet_len < 0) retVal = B_ERROR;

		break;
	}

	release_sem_etc(dev->ioLocker, 1, 0);

	atomic_add(&dev->inrw, -1);
	*len = (size_t)packet_len;

	return retVal;
}


/* prototypes */
static device_hooks hooks = {
	open_hook,		/* -> open entry point */
	close_hook,		/* -> close entry point */
	free_hook,		/* -> free entry point */
	control_hook,		/* -> control entry point */
	read_hook,		/* -> read entry point */
	write_hook,		/* -> write entry point */
	NULL,			/* -> select entry point */
	NULL,			/* -> deselect entry point */
	NULL,			/* -> readv */
	NULL			/* -> writev */
};


/* Initalize hardware */
_EXPORT status_t init_hardware(void)
{
	return B_NO_ERROR;
}


/* Initalize driver */
_EXPORT status_t init_driver()
{
	return B_NO_ERROR;
}


/* Uninitalize driver */
_EXPORT void uninit_driver(void)
{
}


/* Publish devices */
_EXPORT const char** publish_devices(void)
{
	return((const char **)skyeye_tap_devs);
}


/* Device hooks */
_EXPORT device_hooks *find_device(const char *name)
{
	if(strcmp(skyeye_tap_devs[0], name) == 0) return(&hooks);
	return NULL;
}


_EXPORT int32 api_version = B_CUR_DRIVER_API_VERSION;


_EXPORT void suspend_driver(void)
{
}


_EXPORT void wake_driver(void)
{
}
