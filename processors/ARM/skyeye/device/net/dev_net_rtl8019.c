/*
	dev_net_rtl8019.c - skyeye realtek 8019 ethernet controllor simulation
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
 * 04/01/2007	added 16-bits mode.
 * 			Anthony Lee <don.anthony.lee@gmail.com>
 * 03/19/2007	fixed writing CR directly when page over 2,
 * 		fixed for running on Windows,
 * 		replaced the codes based on sigaction with portable function.
 * 			Anthony Lee <don.anthony.lee@gmail.com>
 * 05/25/2005   modified for rtl8019
 *                      walimis <wlm@student.dlut.edu.cn>
 * 04/27/2003	add net option support
 * 			chenyu <chenyu@hpclab.cs.tsinghua.edu.cn>
 * 02/25/2003 	initial version
 *			yangye <yangye@163.net> 		
 */

#include "armdefs.h"
#include "skyeye_device.h"
#include "dev_net_rtl8019.h"
#include "portable/gettimeofday.h"

//if you don't want to the debug info,just commit below two line
//#define DEBUG 1
#undef DEBUG
#if DEBUG
#define DBG_PRINT(a...) fprintf(stderr, ##a)
#else
#define DBG_PRINT(a...)
#endif

static struct device_default_value rtl8019_net_def[] = {
	/* name		base		size	interrupt array */
	{"at91",	0xfffa0000,	0xff,	{16, 0, 0, 0}},
	{"s3c44b0x",	0x06000000,	0xff,	{22, 0, 0, 0}},
	{NULL},
};

#define MAX_DEVICE_NUM 10
static struct device_desc *rtl8019_devs[MAX_DEVICE_NUM];
static struct timeval eth_timeout[MAX_DEVICE_NUM];
static int eth_timeout_flags[MAX_DEVICE_NUM] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

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

static inline void
net_rtl8019_set_update_intr (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	mc->mach_set_intr (intr->interrupts[INT_RTL8019]);
	mc->mach_update_intr (mc);
}

static void send_interrupt(int index)
{
	struct device_desc *dev;

	if ((dev = rtl8019_devs[index]) != NULL) {
		struct net_device *net_dev = (struct net_device *) dev->dev;
		struct machine_config *mc = (struct machine_config *) dev->mach;
		struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
		if ((io->need_update) && (io->IMR & io->ISR)) {
			net_rtl8019_set_update_intr(dev);
			io->need_update = 0;
			set_time(index, 0);
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

static void
write_cr (struct device_desc *dev, u8 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	u8 startpage;
	u16 packet_len;
	u16 rtl8019_len;

	DBG_PRINT ("write_cr begin: data 0x%x\n", data);

	// Validate remote-DMA (RD2,RD1,RD0 not allowed to be 000) 
	if (((data & 0x38) == 0x00)) {	//wrong command
		DBG_PRINT ("write_cr: wrong command\n");
		return;
	}

	// XMIT command
	if (data & CMD_XMIT) {
		DBG_PRINT ("write_cr: xmit command\n");
		startpage = (io->TPSR - START_PAGE);	//tpsr - 0x40
		packet_len = (((u16) io->TBCR1 << 8) | (io->TBCR0));
		packet_len &= 0xffff;


		io->TSR = 0;
		if (!rtl8019_output
		    (dev, (io->sram + startpage * PAGE_SIZE), packet_len)) {
			io->TSR |= TSR_PTX;
		}
		else {
			io->TSR |= TSR_COL;
		}

		/**** send a interrupt to CPU here! ****/
		io->ISR |= ISR_PTX;
		set_time (io->index, packet_len);
		io->need_update = 1;
		//net_rtl8019_set_update_intr(dev);

	}

	//remote dma write 
	if ((data & CMD_READ) && (data & CMD_RUN)) {
		rtl8019_len = (((u16) io->RBCR1 << 8) | io->RBCR0);
		io->remote_read_offset =
			(u16) (io->RSAR1 << 8 | io->RSAR0) -
			(u16) (START_PAGE * PAGE_SIZE);
		io->remote_read_offset &= 0xffff;
		io->remote_read_count = rtl8019_len;
		//printf("io->remote_read_count:%d,io->remote_read_offset:%x\n", io->remote_read_count, io->remote_read_offset);
	}

	//remote dma write 
	if ((data & CMD_WRITE) && (data & CMD_RUN)
	    && ((data & CMD_NODMA) == 0)) {

		io->remote_write_offset =
			(io->RSAR1 << 8 | io->RSAR0) - START_PAGE * PAGE_SIZE;
		io->remote_write_count = (((u16) io->RBCR1 << 8) | io->RBCR0);
		io->remote_write_count &= 0xffff;
		//printf("rtl8019 rw:count:%d,offset:%x\n", io->remote_write_count, io->remote_write_offset);

	}

	io->CR = data;

	DBG_PRINT ("write_cr: end\n");
}

static void
remote_write_word (struct device_desc *dev, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	DBG_PRINT ("remote_write begin: data 0x%x\n", data);
	if (io->CR & CMD_WRITE) {	//in remote write mode

		if (io->remote_write_offset + 1 >= PAGE_NUM * PAGE_SIZE) {
			io->ISR |= ISR_OVW;
			if ((ISR_OVW & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
			DBG_PRINT ("%s: write data overflow!\n", __FUNCTION__);
			return;
		}

		io->sram[io->remote_write_offset] = data & 0xff;
		io->sram[io->remote_write_offset + 1] = data >> 8;
		io->remote_write_offset += 2;
		io->remote_write_count -= 2;


		if (io->remote_write_count <= 0) {
			io->CR &= (~CMD_WRITE);	//clear dma command in CR
			io->CR |= CMD_NODMA;

			io->ISR |= ISR_RDC;	// remote write finished int
			if ((ISR_RDC & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
		}
		DBG_PRINT ("remote write end\n");
		return;
	}

}

static void
remote_write_byte (struct device_desc *dev, u8 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	DBG_PRINT ("remote_write begin: data 0x%x\n", data);
	if (io->CR & CMD_WRITE) {	//in remote write mode

		if (io->remote_write_offset >= PAGE_NUM * PAGE_SIZE) {
			io->ISR |= ISR_OVW;
			if ((ISR_OVW & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
			DBG_PRINT ("%s: write data overflow!\n", __FUNCTION__);
			return;
		}

		io->sram[io->remote_write_offset] = data;
		io->remote_write_offset++;
		io->remote_write_count--;


		if (io->remote_write_count == 0) {
			io->CR &= (~CMD_WRITE);	//clear dma command in CR
			io->CR |= CMD_NODMA;

			io->ISR |= ISR_RDC;	// remote write finished int
			if ((ISR_RDC & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
		}
		DBG_PRINT ("remote write end\n");
		return;
	}

}

static u16
remote_read_halfword (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	u16 data;

	DBG_PRINT ("remote read begin\n");

	if (io->CR & CMD_READ) {

		data = io->sram[io->remote_read_offset];
		data |= io->sram[io->remote_read_offset + 1] << 8;
		io->remote_read_offset += 2;

		io->remote_read_count -= 2;

		if (io->remote_read_count <= 0) {
			io->CR &= (~CMD_READ);
			io->CR |= CMD_NODMA;
			io->ISR |= ISR_RDC;
			if ((ISR_RDC & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
		}

		DBG_PRINT ("remote read end:data %d\n", data);
		return data;
	}

	return 0;
}

static u8
remote_read_byte (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	u8 data;

	DBG_PRINT ("remote read begin\n");

	if (io->CR & CMD_READ) {

		data = io->sram[io->remote_read_offset];
		io->remote_read_offset++;

		if (--io->remote_read_count == 0) {
			io->CR &= (~CMD_READ);
			io->CR |= CMD_NODMA;
			io->ISR |= ISR_RDC;
			if ((ISR_RDC & io->IMR)) {
				net_rtl8019_set_update_intr (dev);
			}
		}

		DBG_PRINT ("remote read end:data %d\n", data);
		return data;
	}

	return 0;
}

static void
net_rtl8019_fini (struct device_desc *dev)
{
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	free (dev->dev);
	free (io);
}

static void
net_rtl8019_reset (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	/*init PROM */
	io->PROM[0] = (u8) net_dev->macaddr[0];	//MACADDR0;
	io->PROM[1] = (u8) net_dev->macaddr[0];	//MACADDR0;
	io->PROM[2] = (u8) net_dev->macaddr[1];	//MACADDR1;
	io->PROM[3] = (u8) net_dev->macaddr[1];	//MACADDR1;
	io->PROM[4] = (u8) net_dev->macaddr[2];	//MACADDR2;
	io->PROM[5] = (u8) net_dev->macaddr[2];	//MACADDR2;
	io->PROM[6] = (u8) net_dev->macaddr[3];	//MACADDR3;
	io->PROM[7] = (u8) net_dev->macaddr[3];	//MACADDR3;
	io->PROM[8] = (u8) net_dev->macaddr[4];	//MACADDR4;
	io->PROM[9] = (u8) net_dev->macaddr[4];	//MACADDR4;
	io->PROM[10] = (u8) net_dev->macaddr[5];	//MACADDR5;
	io->PROM[11] = (u8) net_dev->macaddr[5];	//MACADDR5;

	io->PAR0 = io->PROM[0];
	io->PAR1 = io->PROM[2];
	io->PAR2 = io->PROM[4];
	io->PAR3 = io->PROM[6];
	io->PAR4 = io->PROM[8];
	io->PAR5 = io->PROM[10];

	//init Registers
	io->CR = 0x21;		//nic Stopped
	io->PSTART = 0;
	io->PSTOP = 0;
	io->BNRY = 0;
	io->TPSR = 0;
	io->TBCR0 = 0;
	io->TBCR1 = 0;
	io->ISR = 0;
	io->RSAR0 = 0;
	io->RSAR1 = 0;
	io->RBCR0 = 0;
	io->RBCR1 = 0;
	io->RCR = 0;
	io->TCR = 0;
	io->DCR = 0x84;		//set long addr bit
	io->IMR = 0;
	io->CURR = 0;

	/* raise reset interrupt */
	io->ISR = io->ISR | ISR_RST;

	/* init nic RAM */
	if (io->sram != NULL) {
		memset (io->sram, 0, PAGE_NUM * PAGE_SIZE);
	}
	else {
		io->sram = (u8 *) malloc (PAGE_NUM * PAGE_SIZE);
	}
	io->remote_read_offset = 0;
	io->remote_write_offset = 0;
	io->remote_read_count = 0;
	io->remote_write_count = 0;
	io->need_update = 0;
}

static void
net_rtl8019_update (struct device_desc *dev)
{
	struct device_interrupt *intr = &dev->intr;
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 0;

#if 0
	/* disabled: ISR_OVW instead of this */
	if ((!mc->mach_pending_intr (intr->interrupts[INT_RTL8019])))
#else
	if (!(io->ISR & ISR_OVW))
#endif
		if(net_dev->net_wait_packet (net_dev, &tv) == 0) rtl8019_input (dev);

	check_timeout(io->index);
}


static int
net_rtl8019_read_halfword (struct device_desc *dev, u32 addr, u16 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	int offset = (u8) (addr - dev->base);
	int ret = ADDR_HIT;

	offset >>= io->op_16;

	//DBG_PRINT("nic read begin: offset %x, io->ISR %x\n",offset,io->ISR);

	if (offset == 0x10) {	//remote read
		if (io->DCR & 0x1) {
			*data = remote_read_halfword (dev);
		}
	}

	return ret;
}

static int
net_rtl8019_read_byte (struct device_desc *dev, u32 addr, u8 * data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	int offset = (u8) (addr - dev->base);
	int ret = ADDR_HIT;

	offset >>= io->op_16;

	DBG_PRINT ("nic read begin: offset %x, io->ISR %x\n", offset,
		   io->ISR);

	*data = 0;
	if (offset == 0x10) {	//remote read
		/* FIXME: don't use DCR here. */
		*data = remote_read_byte (dev);
		return ret;
	}
	if (offset == 0x1f) {	//reset
		net_rtl8019_reset (dev);
		return ret;
	}
	if ((io->CR >> 6) == 0) {	//read page0
		switch (offset) {
		case 0x00:	//CR
			*data = io->CR;
			break;

		case 0x03:	//BNRY
			*data = io->BNRY;
			break;
		case 0x04:	// ISR
			*data = io->TSR;
			break;
		case 0x07:	// ISR
			*data = io->ISR;
			break;
		case 0x0c:	// ISR
			*data = io->RSR;
			break;
		case 0x0d:	// ISR
			io->CNTR0 = 0;
			*data = io->CNTR0;
			break;
		}
	}			//end  if page0

	if ((io->CR >> 6) == 1) {	//read page1
		switch (offset) {
		case 0x00:	//CR
			*data = io->CR;;
			break;

		case 0x01:	//PAR0 - PAR5 ,MAC addr
			*data = io->PAR0;
			break;

		case 0x02:
			*data = io->PAR1;
			break;

		case 0x03:
			*data = io->PAR2;
			break;

		case 0x04:
			*data = io->PAR3;
			break;

		case 0x05:
			*data = io->PAR4;
			break;
		case 0x06:
			*data = io->PAR5;
			break;
		case 0x07:	//CURR
			*data = io->CURR;
			break;
		}
	}			//end if PAGE1

	if ((io->CR >> 6) == 2) {	//read page2
		switch (offset) {
		case 0x00:	//CR
			*data = io->CR;
			break;

		case 0x01:	//PSTART
			*data = io->PSTART;
			break;

		case 0x02:	//PSTOP
			*data = io->PSTOP;
			break;

		case 0x04:	//TPSR
			*data = io->TPSR;
			break;

		case 0x0C:	//RCR
			*data = io->RCR;
			break;

		case 0x0D:	//TCR
			*data = io->TCR;
			break;

		case 0x0E:	//DCR
			*data = io->DCR;
			break;

		case 0x0F:	//IMR
			*data = io->IMR;
			break;
		}
	}			//end if page2

	return ret;

}

static int
net_rtl8019_write_halfword (struct device_desc *dev, u32 addr, u16 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	int offset = (u8) (addr - dev->base);
	int ret = ADDR_HIT;

	offset >>= io->op_16;

	if (offset == 0x10) {	//remote write
		if (io->DCR & 0x1) {
			remote_write_word (dev, (u16) data);
		}
	}
	return ret;
	//DBG_PRINT("nic write begin: offset %x, data %x\n",offset,data);
}

//offset should be 00-0f, 10 or 1f
static int
net_rtl8019_write_byte (struct device_desc *dev, u32 addr, u8 data)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;

	int offset = (u8) (addr - dev->base);
	int ret = ADDR_HIT;

	offset >>= io->op_16;

	if (offset == 0x10) {	//remote write
		/* FIXME: don't use DCR here. */
		//if (io->DCR & 0x2) {
		remote_write_byte (dev, (u8) data);
		//}
		return ret;
	}
	if (offset == 0x1f) {	//reset
		net_rtl8019_reset (dev);
		return ret;
	}
	if (offset == 0x00) { // 2007-03-14 by Anthony Lee : here we should set the CR directly.
		write_cr (dev, data);
		return ret;
	}
	if ((io->CR >> 6) == 0) {	//write page0
		switch (offset) {
#if 0
		case 0x00:	//CR
			write_cr (dev, data);
			break;
#endif

		case 0x01:	//PSTART
			io->PSTART = data;
			break;

		case 0x02:	//PSTOP
			io->PSTOP = data;
			break;

		case 0x03:	//BNRY
			io->BNRY = data;
			break;

		case 0x04:	//TPSR
			io->TPSR = data;
			break;

		case 0x05:	//TBCR0
			io->TBCR0 = data;
			break;

		case 0x06:	//TBCR1
			io->TBCR1 = data;
			break;

		case 0x07:	//ISR  (write means clear)
			io->ISR = (io->ISR & (~data));
			/*
			   if (io->IMR & io->ISR) {
			   }
			 */
			//UNSET_NET_INT ();
			break;

		case 0x08:	//RSAR0
			io->RSAR0 = data;
			break;

		case 0x09:	//RSAR1
			io->RSAR1 = data;
			break;

		case 0x0a:	//RBCR0
			io->RBCR0 = data;
			break;

		case 0x0b:	//RBCR1
			io->RBCR1 = data;
			break;

		case 0x0c:	//RCR
			io->RCR = data;
			break;

		case 0x0d:	//TCR
			io->TCR = data;
			break;

		case 0x0e:	//DCR
			io->DCR = data;
			break;

		case 0x0f:	//IMR
			//printf("IMR:%x -> %x. ISR:%x\n", io->IMR, data, io->ISR);
			io->IMR = data;
			/*
			   if (io->IMR & io->ISR) {
			   net_rtl8019_set_update_intr(dev);
			   }
			 */
			break;
		}
		return ret;
	}			//end if page0


	if ((io->CR >> 6) == 1) {	//write page1
		switch (offset) {
#if 0
		case 0x00:	//CR
			write_cr (dev, data);
			break;
#endif

		case 0x01:	//PAR0 - PAR5 ,MAC addr
			io->PAR0 = data;
			break;

		case 0x02:
			io->PAR1 = data;
			break;

		case 0x03:
			io->PAR2 = data;
			break;

		case 0x04:
			io->PAR3 = data;
			break;

		case 0x05:
			io->PAR4 = data;
			break;

		case 0x06:
			io->PAR5 = data;
			break;

		case 0x07:	//CURR
			io->CURR = data;
			break;
		}
		return ret;
	}			//end if page1

#if 0
	//yangye 2003-1-21
	//add write page2 ,only CR
	if ((io->CR >> 6) == 2) {	//write page2
		if (offset == 0x00) {
			write_cr (dev, data);
			return ret;
		}
	}			//end if page2
#endif

	DBG_PRINT ("error write page or error write register\n");
	return ret;
}

static void
rtl8019_input (struct device_desc *dev)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	int packet_len, rtl8019_len;
	u8 buf[1600];
	u8 frame_header[4];
	u8 *bufptr;
	u8 *sramptr;
	u16 i, j, len;
	u32 free_pages, occupy_pages, next_page;

	if ((io->CR & CMD_STOP) || (io->TCR & TCR_LOOP_EXT)) {
		return;
	}

	if (io->CURR < io->BNRY) {
		free_pages = io->BNRY - io->CURR;
	}
	else {
		free_pages = (io->PSTOP - io->PSTART) - (io->CURR - io->BNRY);
	}


	packet_len = net_dev->net_read (net_dev, buf, sizeof (buf));
	if (packet_len < 0)
		return;
	/* if packet_len < 60, pad zero to 60 bytes length. */
	if (packet_len < 60) {
		memset (buf + packet_len, 0, 60 - packet_len);
		packet_len = 60;
	}

	rtl8019_len = packet_len + 4;

	occupy_pages = (rtl8019_len + 255) / PAGE_SIZE;

	/* check if we have available space to receive packet */
	if (occupy_pages > free_pages) {
		io->ISR |= ISR_OVW;
		if ((ISR_OVW & io->IMR)) {
			net_rtl8019_set_update_intr (dev);
		}
		DBG_PRINT ("%s: read data overflow!\n", __FUNCTION__);
		return;
	}

	next_page = io->CURR + occupy_pages;
	if (next_page >= io->PSTOP) {
		next_page -= io->PSTOP - io->PSTART;
	}

	//add 8019 frame header
	frame_header[0] = RSR_RXOK;
	frame_header[1] = next_page;
	frame_header[2] = (rtl8019_len & 0xFF);	//low 8 bit
	frame_header[3] = (rtl8019_len >> 8);	//high 8 bit

	/* check if we are in in promiscuous mode */

       /**
       * The tuntap does sometimes match the multicast address and
        * we _want_ to get broadcasts. Ignore this all and play
        * promisc.
        */
#if 0


	if (!(io->RCR & RCR_PRO)) {
		/* not in promiscuous mode */
		if (!is_broadcast (buf)) {
			DBG_PRINT
				(" destination address is a broadcast address!!!\n");
			if (!(io->RCR & RCR_AB)) {
				/* reject broadcast destination address */
				return;
			}
		}
		else if (is_multicast (buf)) {
			DBG_PRINT
				("destination address is a multicast address!!!\n");
			if (!(io->RCR & RCR_AM)) {
				/* reject multicast destination address */
				return;
			}
		}
		else if ((io->PAR0 != buf[0]) || (io->PAR1 != buf[1])
			 || (io->PAR2 != buf[2]) || (io->PAR3 != buf[3])
			 || (io->PAR4 != buf[4]) || (io->PAR5 != buf[5])) {
			return;
		}
	}
#endif

	sramptr = &io->sram[(io->CURR - START_PAGE) * PAGE_SIZE];

	if (next_page > io->CURR || ((io->CURR + occupy_pages) == io->PSTOP)) {
		memcpy (sramptr, frame_header, 4);
		memcpy (sramptr + 4, buf, packet_len);
	}
	else {
		int copy_bytes = (io->PSTOP - io->CURR) * PAGE_SIZE;
		memcpy (sramptr, frame_header, 4);
		memcpy (sramptr + 4, buf, copy_bytes - 4);

		sramptr = &io->sram[(io->PSTART - START_PAGE) * PAGE_SIZE];
		memcpy (sramptr, (void *) (buf + copy_bytes - 4),
			(packet_len - copy_bytes + 4));
	}

	io->CURR = next_page;

	io->RSR |= RSR_RXOK;
#if 0
	fprintf(stderr, "\n----(%s)(packet_len:%d)----", __FUNCTION__, packet_len);
	print_packet (sramptr + 4, packet_len);
#endif

	/*** send CPU a rx interrupt here! *****/
	io->ISR |= ISR_PRX;	//got packet int
	if ((ISR_PRX & io->IMR)) {
		//printf ("+++%s: raise RX interrupt, ISR:%x, IMR:%x\n", __FUNCTION__, io->ISR, io->IMR);
		set_time (io->index, rtl8019_len);
		io->need_update = 1;
		net_rtl8019_set_update_intr (dev);
	}
}

static u8
rtl8019_output (struct device_desc *dev, u8 * buf, u16 packet_len)
{
	struct net_device *net_dev = (struct net_device *) dev->dev;
	struct net_rtl8019_io *io = (struct net_rtl8019_io *) dev->data;
	int len;

	if (io->CR & CMD_STOP) {	//nic in stop mode 
		return 0;
	}

#if 0
	fprintf(stderr, "\n----(%s)(packet_len:%d)----", __FUNCTION__, packet_len);
	print_packet (buf, packet_len);
#endif
	if ((len = net_dev->net_write (net_dev, buf, packet_len)) == -1) {
		fprintf (stderr, "write to tapif error in skyeye-ne2k.c\n");
		return -1;
	}
	//printf ("+++%s: trans\n", __FUNCTION__);
	return 0;
}

static int
net_rtl8019_setup(struct device_desc *dev)
{
	int i;
	int enough = 0;
	struct net_rtl8019_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = net_rtl8019_fini;
	dev->reset = net_rtl8019_reset;
	dev->update = net_rtl8019_update;
	dev->read_byte = net_rtl8019_read_byte;
	dev->write_byte = net_rtl8019_write_byte;
	dev->read_halfword = net_rtl8019_read_halfword;
	dev->write_halfword = net_rtl8019_write_halfword;

	io = (struct net_rtl8019_io*)malloc(sizeof(struct net_rtl8019_io));
	if (io == NULL) return 1;

	memset(io, 0, sizeof (struct net_rtl8019_io));
	dev->data = (void*)io;

	net_rtl8019_reset(dev);

	/* see if we need to set default values. */
	set_device_default(dev, rtl8019_net_def);

	for (i = 0; i < MAX_DEVICE_NUM; i++) {
		if (rtl8019_devs[i] == NULL) {
			rtl8019_devs[i] = dev;
			io->index = i;
			enough = 1;
			break;
		}
	}

	if (enough == 0) return 1;

	return 0;
}

static int
net_rtl8019_8bits_setup(struct device_desc *dev)
{
	int ret = net_rtl8019_setup(dev);

	if (ret != 0) return ret;

	((struct net_rtl8019_io*)dev->data)->op_16 = 8;

	return 0;
}

static int
net_rtl8019_16bits_setup(struct device_desc *dev)
{
	int ret = net_rtl8019_setup(dev);

	if (ret != 0) return ret;

	((struct net_rtl8019_io*)dev->data)->op_16 = 1;

	return 0;
}

void
net_rtl8019_init (struct device_module_set *mod_set)
{
	int i;

	register_device_module("rtl8019", mod_set, &net_rtl8019_setup);
	register_device_module("rtl8019_8", mod_set, &net_rtl8019_8bits_setup);
	register_device_module("rtl8019_16", mod_set, &net_rtl8019_16bits_setup);

	for (i = 0; i < MAX_DEVICE_NUM; i++) rtl8019_devs[i] = NULL;
}

