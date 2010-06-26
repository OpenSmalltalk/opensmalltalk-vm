/*
	skyeye_net.c - skyeye general net device file support functions
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
 * 05/01/2005 	initial version
 *			walimis <wlm@student.dlut.edu.cn>
 */

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "skyeye_device.h"
#include "skyeye_options.h"
#include "skyeye.h"
#include "skyeye_net.h"

#define MAC_ADDR	"\0skyey"

static nic_num = 0;

/* initialize the net module set.
 * If you want to add a new ethernet nic simulation, just add a "net_*_init" function to it.
 * */
static void
net_init (struct device_module_set *mod_set)
{
	net_rtl8019_init (mod_set);
	net_cs8900a_init (mod_set);
	net_s3c4510b_init (mod_set);
}
static int
net_setup (struct device_desc *dev, void *option)
{
	struct net_device *net_dev;
	struct net_option *net_opt = (struct net_option *) option;
	int ret = 0;

	net_dev = (struct net_device *) malloc (sizeof (struct net_device));
	if (net_dev == NULL)
		return 1;

	memset (net_dev, 0, sizeof (struct net_device));

	/* if we don't config mac addr in config file, we set it here. */
	if (is_nulladdr (net_opt->macaddr)) {
		memcpy (net_dev->macaddr, MAC_ADDR, 6);
		net_dev->macaddr[5] += nic_num;
		nic_num++;
	}
	else {
		memcpy (net_dev->macaddr, net_opt->macaddr, 6);
	}

	memcpy (net_dev->hostip, net_opt->hostip, 4);
	net_dev->ethmod = net_opt->ethmod;
	switch (net_dev->ethmod) {
	case NET_MOD_TUNTAP:
		net_dev->net_open = tuntap_open;
		net_dev->net_close = tuntap_close;
		net_dev->net_read = tuntap_read;
		net_dev->net_write = tuntap_write;
		net_dev->net_wait_packet = tuntap_wait_packet;
		break;
	case NET_MOD_VNET:
		net_dev->net_open = vnet_open;
		net_dev->net_close = vnet_close;
		net_dev->net_read = vnet_read;
		net_dev->net_write = vnet_write;
		net_dev->net_wait_packet = vnet_wait_packet;
		break;
	}
	
	ret = net_dev->net_open (net_dev);

	dev->dev = (void *) net_dev;
	return ret;

}
static struct device_module_set net_mod_set = {
	.name = "net",
	.count = 0,
	.count_max = 0,
	.init = net_init,
	.initialized = 0,
	.setup_module = net_setup,
};

/* used by global device initialize function. 
 * */
void
net_register ()
{
	if (register_device_module_set (&net_mod_set))
		SKYEYE_ERR ("\"%s\" module set register error!\n",
			    net_mod_set.name);
}

/* help functions. */
inline int
is_broadcast (char *mac)
{
	static unsigned char bcast_addr[6] =
		{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
	return (!memcmp (mac, bcast_addr, 6));
}
inline int
is_nulladdr (char *mac)
{
	static unsigned char null_addr[6] = { 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 };
	return (!memcmp (mac, null_addr, 6));
}
inline int
is_multicast (char *mac)
{
	return (mac[0] & 0x01);
}

void
print_packet (u8 * buf, int len)
{
	int i = 0, j = 0, k = 0;
	fprintf (stderr, "\n");
	while (i < len) {
		if (buf[i] < 16)
			fprintf (stderr, "0%x", buf[i]);
		else
			fprintf (stderr, "%2x", buf[i]);
		k++;
		if (k >= 2) {
			fprintf (stderr, " ");
			k = 0;
		}
		i++;
		j++;
		if (j >= 16) {
			fprintf (stderr, "\n");
			j = 0;
		}
	}
	fprintf (stderr, "\n\n");
}
