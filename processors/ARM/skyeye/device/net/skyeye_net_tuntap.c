/*
	skyeye_net_tuntap.c - tuntap net device file support functions
	Copyright (C) 2003 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.sf.linuxforum.net> 
	
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
 *			chenyu <chenyu@hpclab.cs.tsinghua.edu.cn>
 */

#include "armdefs.h"

#if !(defined(__MINGW32__) || defined(__CYGWIN__) || defined(__BEOS__))

#ifdef __linux__
#include <net/if.h>
#include <linux/if_tun.h>
#include <sys/ioctl.h>
#endif

#ifdef __svr4__
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
//#include <net/if_tun.h>
#include <fcntl.h>
#endif

#ifdef __FreeBSD__
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_tun.h>
#include <fcntl.h>
#endif

#ifdef __APPLE__
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#endif

#define DEBUG 0
#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr, ##a)
#else
#define DBG_PRINT(a...)
#endif

#define DEFAULT_TUNTAP_IF_NAME "tap"
static name_index = 0;

int
tuntap_open (struct net_device *net_dev)
{
	int tapif_fd;
	struct ifreq ifr;
	char buf[128];
	char if_name[10];


	DBG_PRINT ("tapif_init begin\n");

#ifdef __linux__
	tapif_fd = open ("/dev/net/tun", O_RDWR);
	DBG_PRINT ("tapif_init: fd %d\n", tapif_fd);
	if (tapif_fd < 0) {
		perror ("tapif_init:open");
		printf ("-----------------------------------------------------------\n");
		printf ("NOTICE: you should be root at first !!!\n");
		printf ("NOTICE: you should inmod linux kernel net driver tun.o!!!\n");
		printf ("NOTICE: if you don't make device node, you should do commands:\n");
		printf ("NOTICE:    mkdir /dev/net; mknod /dev/net/tun c 10 200\n");
		printf ("NOTICE: now the net simulation function can not support!!!\n");
		printf ("NOTICE: Please read SkyEye.README and try again!!!\n");
		printf ("-----------------------------------------------------------\n");
		return 1;
	}
#endif
#ifdef __FreeBSD__
	tapif_fd = open ("/dev/tap", O_RDWR);
	DBG_PRINT ("tapif_init: fd %d\n", tapif_fd);
	if (tapif_fd == -1) {
		perror ("tapif_init:open");
		printf ("-----------------------------------------------------------\n");
		printf ("NOTICE: You should run as root if you require network\n");
		printf ("NOTICE: load the kernel tap module with 'kldload if_tap'\n");
		printf ("NOTICE: and execute 'cat /dev/tap'. there should be a \n");
		printf ("NOTICE: device node under /dev/ (e.g. /dev/tap0).\n");
		printf ("-----------------------------------------------------------\n");
		return 1;
	}
#endif
#if !defined(__FreeBSD__)&&!defined(__linux__)
	printf ("NOTICE: No network support for your OS(yet). Bugging out!\n");
	return 1;
#endif

	snprintf (if_name, sizeof (if_name), "%s%d", DEFAULT_TUNTAP_IF_NAME,
		  name_index);

#ifdef __linux__
	memset (&ifr, 0, sizeof (ifr));
	ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
	strncpy (ifr.ifr_name, if_name, IFNAMSIZ);

	if (ioctl (tapif_fd, TUNSETIFF, (void *) &ifr) < 0) {
		printf ("tapif_init: icotl TUNSETIFF error");
		return 1;
	}
#endif

	snprintf (buf, sizeof (buf), "ifconfig %s inet %d.%d.%d.%d",
		  if_name, net_dev->hostip[0], net_dev->hostip[1],
		  net_dev->hostip[2], net_dev->hostip[3]);

	DBG_PRINT ("tapif_init: system(\"%s\");\n", buf);

	system (buf);
	net_dev->net_fd = tapif_fd;

	name_index++;

	DBG_PRINT ("tapif_init end\n");

	return 0;
}


int
tuntap_close (struct net_device *net_dev)
{
	close (net_dev->net_fd);
	return 0;
}

int
tuntap_read (struct net_device *net_dev, void *buf, size_t count)
{
	return read (net_dev->net_fd, buf, count);
}

int
tuntap_write (struct net_device *net_dev, void *buf, size_t count)
{
	return write (net_dev->net_fd, buf, count);
}

int
tuntap_wait_packet (struct net_device *net_dev, struct timeval *tv)
{
	fd_set frds;
	int ret;

	FD_ZERO(&frds);
	FD_SET(net_dev->net_fd, &frds);
	if((ret = select(net_dev->net_fd + 1, &frds, NULL, NULL, tv)) <= 0) return -1;
	if(!FD_ISSET(net_dev->net_fd, &frds)) return -1;

	return 0;
}

#else /* other systems */

#if (defined(__MINGW32__) || defined(__CYGWIN__))
#define SKYEYE_NET_TUNTAP_SUPPORT
#include "./skyeye_net_tap_win32.c"
#endif /* defined(__MINGW32__) || defined(__CYGWIN__) */

#ifdef __BEOS__
#define SKYEYE_NET_TUNTAP_SUPPORT
#include "./skyeye_net_tap_beos.c"
#endif /* __BEOS__ */

#ifndef SKYEYE_NET_TUNTAP_SUPPORT

int
tuntap_open (struct net_device *net_dev)s
{
	return -1;
}

int
tuntap_close (struct net_device *net_dev)
{
	return 0;
}

int
tuntap_read (struct net_device *net_dev, void *buf, size_t count)
{
	return 0;
}

int
tuntap_write (struct net_device *net_dev, void *buf, size_t count)
{
	return 0;
}

int
tuntap_wait_packet (struct net_device *net_dev, struct timeval *tv)
{
	return -1;
}

#endif /* SKYEYE_NET_TUNTAP_SUPPORT */

#endif

