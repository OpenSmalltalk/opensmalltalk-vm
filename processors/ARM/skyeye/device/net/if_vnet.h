/*
 *  Universal Virtual Net Switch device driver.
 *  Copyright (C) 1999-2003  Chen Yu <chenyu@hpclab.cs.tsinghua.edu.cn>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  $Id: if_vnet.h,v 1.3 2006/08/04 16:40:41 chenyu Exp $
 */

#ifndef __IF_VNET_H
#define __IF_VNET_H

/* Uncomment to enable debugging */
/* #define VNET_DEBUG 1 */

#ifdef __KERNEL__

#define VNET_DEBUG
#ifdef VNET_DEBUG
#define DBG  if(1)printk
#define DBG1 if(1)printk
#else
#define DBG( a... )
#define DBG1( a... )
#endif

#define VNET_MAJOR 11
#define VNET_MINOR 201

struct vnet_struct
{
	char *name;
	unsigned int flags;
	int attached;
	uid_t owner;

	wait_queue_head_t read_wait;
	struct sk_buff_head readq;

	struct net_device dev;
	struct net_device_stats stats;

	struct fasync_struct *fasync;

#ifdef VNET_DEBUG
	int debug;
#endif
};

#ifndef MIN
#define MIN(a,b) ( (a)<(b) ? (a):(b) )
#endif

#endif /* __KERNEL__ */

/* Read queue size */
#define VNET_READQ_SIZE	10

/* VNET device flags */
#define VNET_VNET_DEV 	0x0001
#define VNET_TAP_DEV	0x0002
#define VNET_TYPE_MASK   0x000f

#define VNET_FASYNC	0x0010
#define VNET_NOCHECKSUM	0x0020
#define VNET_NO_PI	0x0040
#define VNET_ONE_QUEUE	0x0080
#define VNET_PERSIST 	0x0100

/* Ioctl defines */
#define VNETSETNOCSUM   _IOW('T', 200, int)
#define VNETSETDEBUG    _IOW('T', 201, int)
#define VNETSETIFF      _IOW('T', 202, int)
#define VNETSETPERSIST  _IOW('T', 203, int)
#define VNETSETOWNER    _IOW('T', 204, int)
#define VNETSHOWINFO    _IOW('T', 205, int)
#define VNETUNSETIFF    _IOW('T', 206, int)

/* VNETSETIFF ifr flags */
#define IFF_VNET		0x0001
#define IFF_TAP		0x0002
#define IFF_NO_PI	0x1000
#define IFF_ONE_QUEUE	0x2000


#define VNET_PKT_STRIP	0x0001
#define VNET_NUM_HUBS  		8
#define NUM_NUTS_PER_HUB 	32
#define VNET_MAX_NUT_NAME_LEN 	16
#define VNET_MAX_QLEN		128

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned  uint32;
typedef int  int32;
typedef char Bool;


#define VNET_MAC_EQ(_a, _b)         !memcmp((_a), (_b), ETH_ALEN)
#define VNET_SKB_2_DESTMAC(_skb)    (((struct ethhdr *)(_skb)->data)->h_dest)
#define VNET_SKB_2_SRCMAC(_skb)     (((struct ethhdr *)(_skb)->data)->h_source)
#define VNET_UP_AND_RUNNING(_flags) (((_flags) & (IFF_RUNNING|IFF_UP)) == (IFF_RUNNING|IFF_UP))

#define TRUE  1
#define FALSE 0

typedef enum
{
	VNET_GUESTIF_NUT,
	VNET_HOSTIF_NUT,
	VNET_HUB_NUT
} vnet_nuttype;

typedef enum
{
	VNET_HUB,
	VNET_SWITCH
} vnet_hubtype;

struct vnet_pi
{
	unsigned short flags;
	unsigned short proto;
};

#ifdef __KERNEL__

/*
 *  The net is the basic mechanism for connecting to objects
 *  that send packet between them.
 */

struct vnet_nut
{
	struct vnet_nut *peer;
	vnet_nuttype type;	//maybe guestif or hostif or hub
	int numbolts;
	char name[VNET_MAX_NUT_NAME_LEN];
	int refCount;
	Bool connected;		// could be a generic state variable if needed
	void *private;		// private field for containing object
	int index;		// private field for containing object
	struct proc_dir_entry *procEntry;	// private field for containing object
	wait_queue_head_t waitQueue;	// used to wait for other threads to release the jack

	void (*free) (struct vnet_nut * this);
	void (*rcv) (struct vnet_nut * this, struct sk_buff * skb);
	  Bool (*cycleDetect) (struct vnet_nut * this, int generation);
	void (*boltsChanged) (struct vnet_nut * this);
	int (*isBridged) (struct vnet_nut * this);
};

struct vnet_bolt
{
	struct vnet_nut nut;	// must be first
	unsigned id;
	uint32 flags;
	struct vnet_bolt *next;
	uint8 paddr[ETH_ALEN];
	uint8 ladrf[8];

	int (*fileOpRead) (struct vnet_bolt * this, struct file * filp,
			   char *buf, size_t count);
	int (*fileOpWrite) (struct vnet_bolt * this, struct file * filp,
			    const char *buf, size_t count);
	int (*fileOpIoctl) (struct vnet_bolt * this, struct file * filp,
			    unsigned int iocmd, unsigned int ioarg);
	int (*fileOpSelect) (struct vnet_bolt * this, struct file * filp,
			     poll_table * wait);

};


struct vnet_hub
{
	int num;
	vnet_hubtype type;	//hub or switch                   
	struct vnet_nut nut[NUM_NUTS_PER_HUB];
	int stats[NUM_NUTS_PER_HUB];
	int totalbolts;
	int mygeneration;
};

struct vnet_guestif_stats
{
	unsigned read;
	unsigned written;
	unsigned queued;
	unsigned droppedDown;
	unsigned droppedMismatch;
	unsigned droppedOverflow;
};

struct vnet_guestif
{
	struct vnet_bolt bolt;
	struct sk_buff_head packetQueue;
	uint32 *pollPtr;
	struct page *pollPage;
	uint32 pollMask;
	uint32 clusterCount;
	wait_queue_head_t waitQueue;
	struct vnet_guestif_stats stats;
};

struct vnet_hostif
{
	struct vnet_bolt bolt;
	unsigned int flags;
	int attached;
	uid_t owner;
	wait_queue_head_t read_wait;
	struct sk_buff_head readq;
	struct net_device dev;
	//char                    devName[8];
	struct net_device_stats stats;
	struct fasync_struct *fasync;
};
#endif /*__KERNEL__*/

#endif /* __IF_VNET_H */
