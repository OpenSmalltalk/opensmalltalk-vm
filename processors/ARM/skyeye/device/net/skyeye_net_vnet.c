/*
	skyeye_net_vnet.c - vnet net device file support functions
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
 * 06/15/2005 	modified for new net simulation framework
 *			walimis <wlm@student.dlut.edu.cn>
 *
 * 04/27/2003 	initial version
 *			chenyu <chenyu@hpclab.cs.tsinghua.edu.cn>
 */

#include "armdefs.h"

#if !(defined(__MINGW32__) || defined(__CYGWIN__) || defined(__BEOS__) || defined(__svr4__))

#if defined( __FreeBSD__) || defined(__APPLE__)
#include <sys/socket.h>
#endif

#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/types.h>

//chy: make sure that if_vnet.h is as same as vnet/if_vnet.h
#include "if_vnet.h"

#define DEBUG 1
#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr, ##a)
#else
#define DBG_PRINT(a...)
#endif

#define DEFAULT_VNET_IF_NAME "tap"
static name_index = 0;

//chy:2003-04-26 open&ioctl net dev file, and return file handler 
// set ne2k mac addr is in nic_reset function
// no use hostip
int
vnet_open (struct net_device *net_dev)
{
	int vnetif_fd, vnet_fd;
	static int firsttime = 0;
	struct ifreq ifr;
	int flag;
	unsigned char maddr[6];
	char buf[128];
	char if_name[10];

	firsttime++;
	//chy: should change !!! will support more virtual hubs in the future
	if (firsttime == 1) {
		if (net_dev->hostip[0] == 0)	//means don't do hostif ......
			goto vnet_done;
/*
  if(vnet_fd=open("/var/vnet_lock",O_CREAT|O_EXCL|O_RDONLY)<0)
	goto vnet_done;
  if(unlink("/var/vnet_lock")<0){
	perror("vnet_open: unlink error");
	exit(-1);
  }
*/

		vnetif_fd = open ("/dev/net/vnet", O_RDWR);
		DBG_PRINT ("vnet_open:for hostif fd %d\n", vnetif_fd);
		if (vnetif_fd == -1) {
			perror ("vnet_open:for hostif open");
			printf ("-----------------------------------------------------------\n");
			printf ("NOTICE: Now the net simulation function is disable!!!\n");
			printf ("NOTICE: 1. you should be root at first !!!\n");
			printf ("NOTICE: 2. if you don't make device node, you should do commands:\n");
			printf ("NOTICE:      mkdir /dev/net; mknod /dev/net/vnet c 10 201\n");
			printf ("NOTICE: 3. you should inmod linux kernel net driver vnet.o!!!\n");
			printf ("NOTICE: Please read README in SkyEye package and try again!!!\n");
			printf ("-----------------------------------------------------------\n");
			skyeye_exit (-1);
		}

		snprintf (if_name, sizeof (if_name), "%s%d",
			  DEFAULT_VNET_IF_NAME, name_index);

		memset (&ifr, 0, sizeof (ifr));
		//If you don't  set name, then it will be set in vnet_hostif_create
		//If you want more vnet, then you should set in here
		//maybe should be defineed in skyeye.conf 
		//now, I only use vnet0.   chy
		//IFNAMSIZ=16
		strncpy (ifr.ifr_name, if_name, IFNAMSIZ);
		ifr.ifr_flags = IFF_VNET;
		if (ioctl (vnetif_fd, VNETSETIFF, (void *) &ifr) < 0) {
			perror ("ioctl VNETSETIFF error");
			skyeye_exit (-1);
		}
		DBG_PRINT ("ioctl VNETSETIFF ok\n");
		snprintf (buf, sizeof (buf), "ifconfig %s inet %d.%d.%d.%d",
			  if_name, net_dev->hostip[0], net_dev->hostip[1],
			  net_dev->hostip[2], net_dev->hostip[3]);

		DBG_PRINT ("tapif_init: system(\"%s\");\n", buf);
		system (buf);
	}

      vnet_done:
	//the scond time, open dev file for guestif
	vnetif_fd = open ("/dev/net/vnet", 2);
	DBG_PRINT ("vnet_open:for guestif fd %d\n", vnetif_fd);
	if (vnetif_fd == -1) {
		perror ("vnet_open:for guestif open");
		skyeye_exit (-1);
	}

	//set mac addr for vnet
	memcpy (maddr, net_dev->macaddr, 6);
	if (ioctl (vnetif_fd, SIOCSIFADDR, (void *) maddr) < 0) {
		printf ("vnet_open: set mac addr error\n");
		skyeye_exit (-1);
	}
	DBG_PRINT ("vnet_open: vnet_open: set mac addr ok\n");
	//set ifflag for vnet
	flag = IFF_UP | IFF_RUNNING | IFF_BROADCAST;
	if (ioctl (vnetif_fd, SIOCSIFFLAGS, (void *) &flag) < 0) {
		printf ("vnet_open: ioctl vnet set ifflag error\n");
		skyeye_exit (-1);
	}
	DBG_PRINT ("vnet_open: ioctl vnet set ifflag ok.\n");

	DBG_PRINT ("vnet_open end\n");
	return vnetif_fd;
}

int
vnet_close (struct net_device *net_dev)
{
	close (net_dev->net_fd);
	return 0;
}

int
vnet_read (struct net_device *net_dev, void *buf, size_t count)
{
	return read (net_dev->net_fd, buf, count);
}

int
vnet_write (struct net_device *net_dev, void *buf, size_t count)
{
	return write (net_dev->net_fd, buf, count);
}

int
vnet_wait_packet (struct net_device *net_dev, struct timeval *tv)
{
	fd_set frds;
	int ret;

	FD_ZERO(&frds);
	FD_SET(net_dev->net_fd, &frds);
	if((ret = select(net_dev->net_fd + 1, &frds, NULL, NULL, tv)) <= 0) return -1;
	if(!FD_ISSET(net_dev->net_fd, &frds)) return -1;

	return 0;
}

#else /* unsupported */

int
vnet_open (struct net_device *net_dev)
{
	return -1;
}

int
vnet_close (struct net_device *net_dev)
{
	return 0;
}

int
vnet_read (struct net_device *net_dev, void *buf, size_t count)
{
	return 0;
}

int
vnet_write (struct net_device *net_dev, void *buf, size_t count)
{
	return 0;
}

int
vnet_wait_packet (struct net_device *net_dev, struct timeval *tv)
{
	return -1;
}

#endif
