/*
	skyeye_net.h - skyeye general net device file support functions
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

/*
 * 04/27/2003 	initial version
 *				chenyu <chenyu@hpclab.cs.tsinghua.edu.cn>
 */

#ifndef __SKYEYE_NET_H_
#define __SKYEYE_NET_H_

#include <sys/time.h>

#include "skyeye_device.h"

#define NET_MOD_LINUX   0
#define NET_MOD_TUNTAP  1
#define NET_MOD_VNET    2

struct net_device
{
	int net_fd;
	unsigned char macaddr[6];
	unsigned char hostip[4];
	int ethmod;

	/* private data */
	void *priv;

	int (*net_open) (struct net_device * net_dev);
	int (*net_close) (struct net_device * net_dev);
	int (*net_read) (struct net_device * net_dev, void *buf, size_t count);
	int (*net_write) (struct net_device * net_dev, void *buf, size_t count);
	int (*net_wait_packet) (struct net_device * net_dev, struct timeval *tv);
};

/* TUNTAP */
extern int tuntap_open (struct net_device *net_dev);
extern int tuntap_close (struct net_device *net_dev);
extern int tuntap_read (struct net_device *net_dev, void *buf, size_t count);
extern int tuntap_write (struct net_device *net_dev, void *buf, size_t count);
extern int tuntap_wait_packet (struct net_device *net_dev, struct timeval *tv);

/* VNEt */
extern int vnet_open (struct net_device *net_dev);
extern int vnet_close (struct net_device *net_dev);
extern int vnet_read (struct net_device *net_dev, void *buf, size_t count);
extern int vnet_write (struct net_device *net_dev, void *buf, size_t count);
extern int vnet_wait_packet (struct net_device *net_dev, struct timeval *tv);

/* ethernet controller initialize functions*/
extern void net_rtl8019_init (struct device_module_set *mod_set);
extern void net_cs8900a_init (struct device_module_set *mod_set);
extern void net_s3c4510b_init (struct device_module_set *mod_set);

/* help function*/
extern inline int is_broadcast (char *mac);
extern inline int is_nulladdr (char *mac);
extern inline int is_multicast (char *mac);
extern void print_packet (u8 * buf, int len);
#endif	/*__SKYEYE_NET_H_*/
