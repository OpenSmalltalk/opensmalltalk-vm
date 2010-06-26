/*
	dev_net_cs8900a.c - skyeye Cirrus Logic CS8900A ethernet controllor simulation
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
 * 03/19/2007	replaced the codes based on sigaction with portable function.
 * 			Anthony Lee <don.anthony.lee@gmail.com>
 * 06/04/2005   initial verion for cs8900a
 *                      walimis <wlm@student.dlut.edu.cn>
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_net_cs8900a.h"
#include "portable/gettimeofday.h"

static struct device_default_value cs8900a_net_def[] = {
	/* name         base        size   interrupt array */
	{"at91", 0xfffa0000, 0x20, {16, 0, 0, 0}},
	{"s3c2410x", 0x19000300, 0x20, {9, 0, 0, 0}},
	{NULL},
};

#define MAX_DEVICE_NUM 10
static struct device_desc *cs8900a_devs[MAX_DEVICE_NUM];
static struct timeval eth_timeout[MAX_DEVICE_NUM];
static int eth_timeout_flags[MAX_DEVICE_NUM] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
static void net_cs8900a_reset (struct device_desc *dev);

#define TIMEVAL_ADD_USEC(tv, usec)					\
	do {								\
		tv.tv_sec += ((tv.tv_usec + usec) / (1000000UL));	\
		tv.tv_usec = ((tv.tv_usec + usec) % (1000000UL));	\
	} while (0)

#define TIMEVAL_CMP(tv1, tv2)						\
	(memcmp(&tv1, &tv2, sizeof(struct timeval)) == 0 ?		\
	 0 : (								\
		tv1.tv_sec < tv2.tv_sec ? -1 : (			\
		(tv1.tv_sec == tv2.tv_sec && tv1.tv_usec < tv2.tv_usec) ? -1 : 1        \
	)))

static void set_time(int index, int packets)
{
	eth_timeout_flags[index] = 0;

	if (packets <= 0) return;
	if (gettimeofday(&eth_timeout[index], NULL) != 0) return;

#if 0
	TIMEVAL_ADD_USEC(eth_timeout[index], (unsigned int)packets * 100UL);
#else
	/* 
	 * NOTE by Stano:
	 * 	In 10 ms - no reason to wait 1 second for a big packet
	 *
	 * NOTE by Lee:
	 * 	Though the timeout just for generating interrupt,
	 *	but please increase the timeout microseconds to decrease
	 *	the loading of CPU when connecting to an external network.
	 */
	TIMEVAL_ADD_USEC(eth_timeout[index], 10000UL);
#endif

	eth_timeout_flags[index] = 1;
}

void
net_cs8900a_set_update_intr (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	mc->mach_set_intr (intr->interrupts[INT_CS8900A]);
	mc->mach_update_intr (mc);
}

static void send_interrupt(int index)
{
	struct device_desc *dev;

	if ((dev = cs8900a_devs[index]) != NULL) {
		struct net_device *net_dev = (struct net_device *) dev->dev;
		struct machine_config *mc = (struct machine_config *) dev->mach;
		struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
		if ((io->need_update)) {
			/* only update once. */
			net_cs8900a_set_update_intr (dev);
			io->need_update = 0;
			set_time (index, 0);
		}
	}
}

static void check_timeout(int index)
{
	struct timeval tv;

	if (!eth_timeout_flags[index]) return;
	if (gettimeofday(&tv, NULL) != 0) return;
	if (TIMEVAL_CMP(tv, eth_timeout[index]) < 1) return;

	send_interrupt(index);

	eth_timeout_flags[index] = 0;
}

/* ISQ read*/
static void
isq_read (struct device_desc *dev, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	io->ctrl_st[CtrlStNum (PP_ISQ)] = 0x0;
	if (io->ctrl_st[CtrlStNum (PP_RxEvent)] & 0xffc0) {
		io->ctrl_st[CtrlStNum (PP_ISQ)] =
			io->ctrl_st[CtrlStNum (PP_RxEvent)];
		//io->ctrl_st[CtrlStNum (PP_RxEvent)] &= 0x3f;
	}
	else if (io->ctrl_st[CtrlStNum (PP_TxEvent)] & 0xffc0) {
		io->ctrl_st[CtrlStNum (PP_ISQ)] =
			io->ctrl_st[CtrlStNum (PP_TxEvent)];
		io->ctrl_st[CtrlStNum (PP_TxEvent)] &= 0x3f;
	}

	*data = io->ctrl_st[CtrlStNum (PP_ISQ)];
}

static void
frame_write (struct device_desc *dev, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	io->tx_frame[io->tx_tail] = data;
	io->tx_tail++;
	if ((io->tx_tail * 2) >= io->tx_length) {
		cs8900a_output (dev, (u8 *) io->tx_frame, (io->tx_tail * 2));
		io->tx_tail = 0;
	}
}

static void
frame_read (struct device_desc *dev, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	if (io->rx_tail > io->rx_head) {
		io->rx_head = io->rx_tail = 0;
		return;
	}
	*data = io->rx_frame[io->rx_tail];
	if (io->rx_tail==io->rx_head) {
		io->ctrl_st[CtrlStNum (PP_RxEvent)] &= ~0x100;
	}
	io->rx_tail++;
}


static void
eeprom_reset (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	u8 offset, checksum = 0, *buf;

	u16 eeprom_val[17] = { 0xa120,
		0x2020, 0x0300, 0x0003, 0x0001,
		0x502c, 0xe000, 0x000f, 0x0, 0xd, 0xc000, 0xf,
		0x2158, 0x0010, 0x0, 0x0,
		0x2800
	};

	/* set eeprom mac address */
	eeprom_val[13] = net_dev->macaddr[0] | (net_dev->macaddr[1] << 8);
	eeprom_val[14] = net_dev->macaddr[2] | (net_dev->macaddr[3] << 8);
	eeprom_val[15] = net_dev->macaddr[4] | (net_dev->macaddr[5] << 8);

	/* re-compute checksum. */
	buf = (u8 *) eeprom_val;
	for (offset = 0; offset < (sizeof (eeprom_val) - 2); offset++)
		checksum += buf[offset];
	eeprom_val[16] = ((u8) (0x100 - checksum)) << 8;

	/* fill eeprom. */
	memcpy (io->eeprom, eeprom_val, sizeof (eeprom_val));

	/* others */
	io->eeprom_writable = 0;

	io->ctrl_st[CtrlStNum (PP_SelfST)] |= EEPROMpresent | EEPROMOK;

	memcpy (io->ieee_addr, net_dev->macaddr, 6);

}

static void
ctrl_status_write (struct device_desc *dev, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	io->ctrl_st[CtrlStNum (io->pp_address)] = data;
	if (io->pp_address==PP_SelfCTL)
	{
		if (data&RESET)
			net_cs8900a_reset(dev);	
	}
	//printf("%s: addr %x, data %x\n", __FUNCTION__, io->pp_address, data);
}

static void
ctrl_status_read (struct device_desc *dev, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	*data = io->ctrl_st[CtrlStNum (io->pp_address)];
	//printf("%s: addr %x, data %x\n", __FUNCTION__, io->pp_address, *data);
}

/* FIXME: now it doesn't support erase-all/write-all commands
 */
static void
eeprom_write (struct device_desc *dev, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	if ((io->eeprom_cmd & EEWriteRegister) && io->eeprom_writable == 1) {
		io->eeprom[io->eeprom_cmd & 0xff] = io->eeprom_data;
	}
	else if ((io->eeprom_cmd & EEEraseRegister)
		 && io->eeprom_writable == 1) {
		io->eeprom[io->eeprom_cmd & 0xff] = 0xffff;
	}
	else {
		if (io->eeprom_cmd & EEWriteEnable) {
			io->eeprom_writable = 1;
		}
		else if (io->eeprom_cmd & EEWriteDis) {
			io->eeprom_writable = 0;
		}
	}

}
static void
eeprom_read (struct device_desc *dev, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	if (!(io->eeprom_cmd & EEReadRegister))
		return;

	*data = io->eeprom[io->eeprom_cmd & 0xff];

}

static void
net_cs8900a_fini (struct device_desc *dev)
{
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	free (dev->dev);
	free (io);
}

static void
net_cs8900a_reset (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	int i;

	/* set ProductID: rev_d */
	io->product_id[0] = EISA_REG_CODE;
	io->product_id[1] = CS8900A | (REV_D << 8);

	/* see section 4.10.5 */
	io->pp_address |= 0x3000;


	/* set control and status registers low 6 bits. see P49. */
	for (i = 0; i < 16; i++) {
		io->ctrl_st[i] |= i * 2 + 1;
		io->ctrl_st[i + 16] |= i * 2;

	}
	io->ctrl_st[CtrlStNum (PP_BusST)] |= Rdy4TxNOW;

	eeprom_reset (dev);

	/* init tx/rx buffer */
	if (!io->rx_frame)
		io->rx_frame = (u16 *) malloc (Rx_Frame_Count);
	memset (io->rx_frame, 0, Rx_Frame_Count);
	io->rx_status_p = &(io->rx_frame[0]);
	io->rx_length_p = &(io->rx_frame[1]);
	io->rx_head = io->rx_tail = 0;

	if (!io->tx_frame)
		io->tx_frame = (u16 *) malloc (Tx_Frame_Count);
	memset (io->tx_frame, 0, Tx_Frame_Count);
	io->tx_head = io->tx_tail = 0;
	io->ctrl_st[CtrlStNum (PP_SelfST)] |= INITD;
	io->ctrl_st[CtrlStNum (PP_LineST)] |= LINK_OK;
	io->ctrl_st[CtrlStNum (PP_TxEvent)] &= 0x3f;
}

static void
net_cs8900a_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	if ((!mc->mach_pending_intr (intr->interrupts[INT_CS8900A]))) {
		struct timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 0;
		if(net_dev->net_wait_packet (net_dev, &tv) == 0) cs8900a_input (dev);
	}

}


int
net_cs8900a_read_halfword (struct device_desc *dev, u32 addr, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	int offset = (u16) (addr - dev->base);
	int ret = ADDR_HIT;

	*data = 0;
	switch (offset) {
	case Rx_Frame_Port:
		frame_read (dev, data);
		break;
	case IO_ISQ:
		isq_read (dev, data);
		break;
	case PP_Address:
		*data = io->pp_address | 0x3000;
		break;
	case PP_Data:
		if (io->pp_address >= 0x100 && io->pp_address < 0x140) {

			ctrl_status_read (dev, data);
		}
		switch (io->pp_address) {
		case PP_ProductID:
			*data = io->product_id[0];
			break;
		case PP_ProductID + 2:
			*data = io->product_id[1];
			break;
		case PP_IntNum:
			*data = io->int_num;
			break;
		case PP_EEPROMCommand:
			*data = io->eeprom_cmd;
			break;
		case PP_EEPROMData:
			eeprom_read (dev, data);
			break;

		case PP_IA:
		case PP_IA + 2:
		case PP_IA + 4:
			*data = io->ieee_addr[io->pp_address - PP_IA] |
				(io->
				 ieee_addr[io->pp_address - PP_IA + 1] << 8);
			break;
		case PP_ISQ:
			isq_read (dev, data);
			break;

		case PP_RxStatus:
			*data = *(io->rx_status_p);
			*(io->rx_status_p) = 0;
			io->rx_tail++;
			break;
		case PP_RxLength:
			*data = *(io->rx_length_p);
			*(io->rx_length_p) = 0;
			io->rx_tail++;
			break;
		}
		//printf("addr:%x, data:%x\n", io->pp_address, *data);
		break;
	default:
		break;
	}
	return ret;

}

int
net_cs8900a_write_halfword (struct device_desc *dev, u32 addr, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;

	int offset = (u16) (addr - dev->base);
	int ret = ADDR_HIT;

	switch (offset) {
	case Tx_Frame_Port:
		frame_write (dev, data);
		break;
	case IO_TxCMD:
		io->tx_cmd = data;
		break;
	case IO_TxLength:
		io->tx_length = data;
		break;
	case PP_Address:
		io->pp_address = data;
		break;
	case PP_Data:
		if (io->pp_address >= 0x100 && io->pp_address < 0x140) {

			ctrl_status_write (dev, data);
		}
		switch (io->pp_address) {
		case PP_IntNum:
			io->int_num = data;
			break;
		case PP_EEPROMCommand:
			io->eeprom_cmd = data;
			eeprom_write (dev, data);
			break;
		case PP_EEPROMData:
			if (io->eeprom_writable == 1)
				io->eeprom_data = data;
			break;
		case PP_IA:
		case PP_IA + 2:
		case PP_IA + 4:
			io->ieee_addr[io->pp_address - PP_IA] = data & 0xff;
			io->ieee_addr[io->pp_address - PP_IA + 1] =
				(data >> 8) & 0xff;
			break;
		case PP_TxCMD:
			io->tx_cmd = data;
			break;
		case PP_TxLength:
			io->tx_length = data;
			break;
		}
		break;
	default:
		break;
	}

	return ret;
}

static void
cs8900a_input (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	int packet_len, cs8900a_len;
	u8 *bufptr;
     /*When the CS8900A commits buffer space to a par-
       ticular held receive frame ,data from subsequent frames can be written P85*/
	if (io->ctrl_st[CtrlStNum (PP_RxEvent)] & 0x100)
		return;
	bufptr = (u8 *) & (io->rx_frame[2]);
	packet_len = net_dev->net_read (net_dev, bufptr, Rx_Max_Count);
	if (packet_len < 0)
		return;

	*(io->rx_status_p) |= RxOK;
	*(io->rx_length_p) = packet_len;

	io->rx_head = 2;

	io->rx_head = io->rx_head + ((packet_len + 1) / 2) - 1;

	io->rx_tail = 0;

	//printf("io->rx_head:%d, io->rx_tail:%d, packet_len:%d\n", io->rx_head, io->rx_tail, packet_len);

#if 0
	print_packet (bufptr, packet_len);
#endif

	io->ctrl_st[CtrlStNum (PP_RxEvent)] |= 0x100;	//TxOK
	if (io->ctrl_st[CtrlStNum (PP_BusCTL)] & EnableRQ) {
		//printf("%s:%x, packet_len:%d\n", __FUNCTION__, io->ctrl_st[CtrlStNum(PP_RxEvent)], packet_len);
		set_time (io->index, packet_len);
		io->need_update = 1;
		net_cs8900a_set_update_intr (dev);
	}
}

static u8
cs8900a_output (struct device_desc *dev, u8 * buf, u16 packet_len)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_cs8900a_io *io = (struct net_cs8900a_io *) dev->data;
	int len;

	//printf("%s: packet_len:%d\n", __FUNCTION__, packet_len);
#if 0
	print_packet (buf, packet_len);
#endif
	if ((len = net_dev->net_write (net_dev, buf, packet_len)) == -1) {
		fprintf (stderr, "write to tapif error in skyeye-ne2k.c\n");
		return -1;
	}
	io->ctrl_st[CtrlStNum (PP_TxEvent)] |= 0x100;
	io->ctrl_st[CtrlStNum (PP_BusST)] |= Rdy4TxNOW;

	if (io->ctrl_st[CtrlStNum (PP_BusCTL)] & EnableRQ) {
		set_time (io->index, packet_len);
		io->need_update = 1;
		net_cs8900a_set_update_intr (dev);
	}
	return 0;
}
static int
net_cs8900a_setup (struct device_desc *dev)
{
	int i;
	int enough = 0;
	struct net_cs8900a_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = net_cs8900a_fini;
	dev->reset = net_cs8900a_reset;
	dev->update = net_cs8900a_update;
	dev->read_halfword = net_cs8900a_read_halfword;
	dev->write_halfword = net_cs8900a_write_halfword;

	io = (struct net_cs8900a_io *)
		malloc (sizeof (struct net_cs8900a_io));
	memset (io, 0, sizeof (struct net_cs8900a_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	net_cs8900a_reset (dev);

	/* see if we need to set default values.
	 * */
	set_device_default (dev, cs8900a_net_def);

	for (i = 0; i < MAX_DEVICE_NUM; i++) {
		if (cs8900a_devs[i] == NULL) {
			cs8900a_devs[i] = dev;
			io->index = i;
			enough = 1;
			break;
		}
	}
	if (enough == 0)
		return 1;

	return 0;
}

void
net_cs8900a_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("cs8900a", mod_set, &net_cs8900a_setup);

	for (i = 0; i < MAX_DEVICE_NUM; i++)
		cs8900a_devs[i] = NULL;

}

