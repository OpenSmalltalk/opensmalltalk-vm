/*
	dev_net_s3c4510b.c - skyeye S3C4510B ethernet controllor simulation
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
 * 03/19/2007	cleanup the useless codes.
 * 			Anthony Lee <don.anthony.lee@gmail.com>
 * 06/17/2005   initial verion for s3c4510b
 *                      walimis <wlm@student.dlut.edu.cn>
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_net_s3c4510b.h"

static struct device_default_value s3c4510b_net_def[] = {
	/* name         base        size   interrupt array */
	{"s3c4510b", 0x3FF9000, 0x2000, {16, 17, 18, 19}},
	{NULL},
};

#define MAX_DEVICE_NUM 10
static struct device_desc *s3c4510b_devs[MAX_DEVICE_NUM];

static void
mac_write (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	fault_t fault;
	u32 ptr, status, len;
	int i;
	fault = mmu_read_word (state, io->bdmatxptr, &ptr);
	/*
	   if( fault ) {
	   *addr = io->bdmatxptr;
	   return fault;
	   }
	 */
	if (!(ptr & BDMA_owner))
		return;
	ptr &= ~BDMA_owner;
	fault = mmu_read_word (state, io->bdmatxptr + 8, &len);
	/*
	   if( fault ) {
	   *addr = io->bdmatxptr + 8;
	   return fault; 
	   }       
	 */
	len &= 0xffff;
	if (len > sizeof (io->mac_buf))
		return;
	for (i = 0; i < len; i++) {
		fault = mmu_read_byte (state, ptr + i, io->mac_buf + i);
		/*
		   if( fault ) {
		   *addr = ptr + i;
		   return fault;
		   }
		 */
	}
	//Update TXstatus 
	status = len | (Comp << 16);
	fault = mmu_write_word (state, io->bdmatxptr + 8, status);
	//print_packet(io->mac_buf, len);
	/*
	   if( fault ) {
	   *addr = io->bdmatxptr + 8;
	   return fault;
	   }
	 */
	//set owner bit of desc to CPU
	fault = mmu_write_word (state, io->bdmatxptr, ptr);
	/*
	   if( fault ) {
	   *addr = io->bdmatxptr;
	   return fault;
	   }
	 */
	//get next desc
	fault = mmu_read_word (state, io->bdmatxptr + 12, &io->bdmatxptr);
	/*
	   if( fault ) {
	   *addr = io->bdmatxptr + 12;
	 */
	net_dev->net_write (net_dev, io->mac_buf, len);
	//write( skyeye_config.net[0].fd, io->mac_buf, len  );
	//trigger interrupt
	if (io->mactxcon & EnComp) {
		mc->mach_set_intr (intr->interrupts[INT_S3C4510B_MACTX]);
		mc->mach_update_intr (mc);
		//s3c4510b_set_interrupt(INT_MACTX);
		//s3c4510b_update_int(state);
	}
}

static void
mac_read (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	int packet_len, s3c4510b_len;
	fault_t fault;
	u32 ptr, status_len;
	int n, i;

	//*addr = 0;
	packet_len =
		net_dev->net_read (net_dev, io->mac_buf,
				   sizeof (io->mac_buf));
	//n = read(skyeye_config.net[0].fd, mac_buf, sizeof(mac_buf));
	if (packet_len <= 0)
		return;
	fault = mmu_read_word (state, io->bdmarxptr, &ptr);
	//print_packet(io->mac_buf, packet_len);
	/*
	   if( fault ) {
	   *addr = io->bdmarxptr;
	   return fault;
	   }
	 */
	if (!(ptr & BDMA_owner))
		return;

	ptr &= ~BDMA_owner;
	//if( len + 2  > sizeof(mac_buf) ) return 0;
	/* FIXME:for s3c4510b frame, ptr offset is 2 */
	for (i = 0; i < packet_len; i++) {
		fault = mmu_write_byte (state, ptr + 2 + i,
					*(io->mac_buf + i));
		/*
		   if(fault) {
		   *addr = ptr + 2 + i;
		   return fault;
		   }
		 */
	}
	//in desc, set Good bit for RX status , and set len 
	status_len = (Good << 16) | (packet_len + 4);
	//printf("status_len:%x\n",status_len); 
	fault = mmu_write_word (state, io->bdmarxptr + 8, status_len);
	/*
	   if(fault) {
	   *addr = io->bdmarxptr+8;
	   return fault;
	   }
	 */

	//set owner bit of desc to CPU
	fault = mmu_write_word (state, io->bdmarxptr, ptr);
	/*
	   if(fault) {
	   *addr = io->bdmarxptr;
	   return fault;
	   }
	 */

	//get next desc
	fault = mmu_read_word (state, io->bdmarxptr + 12, &io->bdmarxptr);
	/*
	   if(fault) {
	   *addr = io->bdmarxptr + 12;
	   return fault;
	   }
	 */
	/* update bdmastat register */
	io->bdmastat |= S_BRxRDF;
	mc->mach_set_intr (intr->interrupts[INT_S3C4510B_BDMARX]);
	mc->mach_update_intr (mc);
}


static void
net_s3c4510b_fini (struct device_desc *dev)
{
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;
	free (dev->dev);
	free (io);
}

static void
net_s3c4510b_reset (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;
	int i;

	io->bdmatxptr = 0xFFFFFFFF;
	io->bdmarxptr = 0xFFFFFFFF;
}

static void
net_s3c4510b_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;

	if ((io->bdmarxcon & RxEn)) {
		struct timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 0;
		if(net_dev->net_wait_packet (net_dev, &tv) == 0) mac_read (dev);
	}
}


int
net_s3c4510b_read_word (struct device_desc *dev, u32 addr, u32 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;

	int offset = (u16) (addr - dev->base + 0x9000);
	int ret = ADDR_HIT;

	//printf("%s:addr %x, %x\n", __FUNCTION__, addr, MACON);
	*data = 0;
	switch (offset) {
	case MACON:
		*data = io->macon;
		break;
	case CAMCON:
		*data = io->camcon;
		break;
	case MACTXCON:
		*data = io->mactxcon;
		break;
	case MACTXSTAT:
		*data = io->mactxstat;
		break;
	case MACRXCON:
		*data = io->macrxcon;
		break;
	case MACRXSTAT:
		*data = io->macrxstat;
		break;
	case STADATA:
		*data = io->stadata;
		break;
	case STACON:
		*data = io->stacon;
		break;
	case CAMEN:
		*data = io->camen;
		break;
	case BDMATXPTR:
		*data = io->bdmatxptr;
		break;
	case BDMARXPTR:
		*data = io->bdmarxptr;
		break;
	case BDMASTAT:
		*data = io->bdmastat;
		break;
	case BDMARXCON:
		*data = io->bdmarxcon;
		break;
	case BDMATXCON:
		*data = io->bdmatxcon;
		break;
	case BDMARXLSZ:
		*data = io->bdmarxlsz;
		break;
	default:
		break;
	}
	return ret;

}

int
net_s3c4510b_write_word (struct device_desc *dev, u32 addr, u32 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_s3c4510b_io *io = (struct net_s3c4510b_io *) dev->data;

	int offset = (u16) (addr - dev->base + 0x9000);
	int ret = ADDR_HIT;

	//printf("%s\n", __FUNCTION__);
	switch (offset) {
	case MACTXCON:
		if (data & TxEn == TxEn) {
			/*
			   u32 addr;
			   fault_t fault;
			   fault = mac_write(dev);
			   if( fault ) {
			   mmu_data_abort(state, fault, addr);
			   return;
			   }
			 */
			mac_write (dev);
		}
		io->mactxcon = data;
		break;
	case BDMATXPTR:
		io->bdmatxptr = data;
		break;
	case BDMARXPTR:
		io->bdmarxptr = data;
		break;
	case BDMASTAT:
		io->bdmastat &= (~data);
		break;
	case MACON:
		io->macon = data;
		break;
	case MACRXCON:
		io->macrxcon = data;
		break;
	case BDMARXCON:
		io->bdmarxcon = data;
		break;
	case BDMATXCON:
		io->bdmatxcon = data;
		break;
	case BDMARXLSZ:
		io->bdmarxlsz = data;
		break;
	case CAMEN:
		io->camen = data;
		break;
	default:
		break;
	}

	return ret;
}

static int
net_s3c4510b_setup (struct device_desc *dev)
{
	int i;
	int enough = 0;
	struct net_s3c4510b_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = net_s3c4510b_fini;
	dev->reset = net_s3c4510b_reset;
	dev->update = net_s3c4510b_update;
	dev->read_word = net_s3c4510b_read_word;
	dev->write_word = net_s3c4510b_write_word;

	io = (struct net_s3c4510b_io *)
		malloc (sizeof (struct net_s3c4510b_io));
	memset (io, 0, sizeof (struct net_s3c4510b_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	net_s3c4510b_reset (dev);

	/* see if we need to set default values.
	 * */
	set_device_default (dev, s3c4510b_net_def);

	for (i = 0; i < MAX_DEVICE_NUM; i++) {
		if (s3c4510b_devs[i] == NULL) {
			s3c4510b_devs[i] = dev;
			enough = 1;
			break;
		}
	}
	if (enough == 0)
		return 1;

	return 0;
}

void
net_s3c4510b_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("s3c4510b", mod_set, &net_s3c4510b_setup);

	for (i = 0; i < MAX_DEVICE_NUM; i++)
		s3c4510b_devs[i] = NULL;

}

