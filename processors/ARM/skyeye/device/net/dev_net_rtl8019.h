/*
	dev_net_rtl8019.h - skyeye realtek 8019 ethernet controllor simulation
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
 * 05/25/2005 	modified for rtl8019
 *			walimis <wlm@student.dlut.edu.cn>
 *
 * 02/25/2003 	initial version
 *			yangye <yangye@163.net> 		
 *			chenyu <chenyu@hpclab.cs.tsinghua.edu.cn>
 */

#ifndef _DEV_NET_RTL8019_H_
#define _DEV_NET_RTL8019_H_


#define NE_CR              0x0	//R/W，对不同的页，CR都是同一个
//page0 registers  
#define NE_PSTART          0x01	//W，接收缓冲环起始页
#define NE_PSTOP           0x02	//W，接收缓冲环终止页（不包括此页）
#define NE_BNRY            0x03	//R/W，接收缓冲环读指针，指向下一个包到来时的起始页,应初始化成＝CURR＝PSTART
#define NE_TPSR            0x04	//W，Local DMA发送缓冲起始页寄存器
#define NE_TBCR0           0x05	//W，Local DMA发送长度低位
#define NE_TBCR1           0x06	//W，Local DMA发送长度高位
#define NE_ISR             0x07	//R/W，中断状态寄存器
#define NE_RSAR0           0x08	//W，Remote DMA目的起始地址低位
#define NE_RSAR1           0x09	//W，Remote DMA目的起始地址高位
//这两个是CPU向网卡写入或读出数据包的实际长度，执行Remote DMA命令前设置
#define NE_RBCR0           0x0a	//W，Remote DMA数据长度低位
#define NE_RBCR1           0x0b	//W，Remote DMA数据长度高位
#define NE_RCR             0x0c	//W，接收配置寄存器,初始化时写入0x04,表示只接收发给本网卡MAC地址的,大于64字节的以太网包或广播包
#define NE_TCR             0x0d	//发送配置寄存器,初始化开始时写入0x02，置网卡为Loop Back模式，停止发送数据包,初始化结束写入0x00。正常发送数据包并加上CRC
#define NE_DCR             0x0e	//W，数据配置寄存器,初始化时写入0x48，8位模式，FIFO深度8字节，DMA方式
#define NE_IMR             0x0f	//W，中断屏蔽寄存器它的各位和ISR中的各位相对应，向IMR写入值即为打开相应中断

//page1 registers
#define NE_PAR0            0x01	//R/W，网卡MAC地址最高位
#define NE_PAR1            0x02	//R/W，网卡MAC地址
#define NE_PAR2            0x03	//R/W，网卡MAC地址
#define NE_PAR3            0x04	//R/W，网卡MAC地址
#define NE_PAR4            0x05	//R/W，网卡MAC地址
#define NE_PAR5            0x06	//R/W，网卡MAC地址最低位
#define NE_CURR            0x07	//R/W，接收缓冲环写指针
#define NE_MAR0            0x08	//R/W，组播寄存器
#define NE_MAR1            0x09	//R/W，组播寄存器
#define NE_MAR2            0x0a	//R/W，组播寄存器
#define NE_MAR3            0x0b	//R/W，组播寄存器
#define NE_MAR4            0x0c	//R/W，组播寄存器
#define NE_MAR5            0x0d	//R/W，组播寄存器
#define NE_MAR6            0x0e	//R/W，组播寄存器
#define NE_MAR7            0x0f	//R/W，组播寄存器

//page2 registers
//#define NE_PSTART          0x01            //R，接收缓冲环起始页
//#define NE_PSTOP           0x02            //R，接收缓冲环终止页（不包括此页）
//#define NE_TPSR            0x04            //R，Local DMA发送缓冲起始页寄存器
//#define NE_RCR             0x0c            //R，接收配置寄存器
//#define NE_TCR             0x0d            //R,发送配置寄存器
//#define NE_DCR             0x0e            //R，数据配置寄存器
//#define NE_IMR             0x0f            //R，用来读中断屏蔽寄存器IMR状态


//CR命令寄存器的命令 
#define	CMD_STOP	0x01	//网卡停止收发数据
#define	CMD_RUN	    0x02	//网卡执行命令并开始收发数据包（命令为下面四种）
#define	CMD_XMIT	0x04	//Local DMA SEND（网卡――>以太网 ）
#define	CMD_READ	0x08	//Remote DMA READ，用于手动接收数据（网卡――>CPU）
#define	CMD_WRITE	0x10	//Remote DMA WRITE （网卡<――CPU）
#define	CMD_SEND	0x18	//SEND COMMAND命令，用于自动接收数据包                                      （网卡――>CPU）
#define	CMD_NODMA	0x20	//停止DMA操作
#define	CMD_PAGE0	0x00	//   选择第0页（要先选页，再读写该页寄存器）
#define	CMD_PAGE1	0x40	//   选择第1页
#define	CMD_PAGE2	0x80	//   选择第2页

//写入TPSR的值 
#define	XMIT_START	 0x4000	//发送缓冲起始地址（写入时要右移8位得到页号）
//写入PSTART的值 
#define	RECV_START	 0x4600	//接收缓冲起始地址（写入时要右移8位得到页号）
//写入PSTOP的值 
#define	RECV_STOP	 0x6000	//接收缓冲结束地址（写入时要右移8位得到页号）

//中断状态寄存器的值 
#define	ISR_PRX	    0x01	//正确接收数据包中断。做接收处理
#define	ISR_PTX		0x02	//正确发送数据包中断。做不做处理要看上层软件了。
#define	ISR_RXE	    0x04	//接收数据包出错。做重新设置BNRY＝CURR处理。
#define	ISR_TXE	    0x08	//由于冲突次数过多，发送出错。做重发处理
#define	ISR_OVW	    0x10	//网卡内存溢出。做软件重启网卡处理。见手册。
#define	ISR_CNT	    0x20	//出错计数器中断，屏蔽掉（屏蔽用IMR寄存器）。
#define	ISR_RDC	    0x40	//Remote DMA结束 。屏蔽掉。轮询等待DMA结束。
#define	ISR_RST		0x80	//网卡Reset，屏蔽掉。
//中断屏蔽寄存器的值 
#define	ISR_PRX	    0x01
#define	ISR_PTX		0x02
#define	ISR_RXE	    0x04
#define	ISR_TXE	    0x08
#define	ISR_OVW	    0x10
#define	ISR_CNT 	0x20
#define	ISR_RDC	    0x40
#define	ISR_RST		0x80


//数据控制寄存器
//初始化时写入0x48，8位模式，FIFO深度8字节，DMA方式。
#define DCR_WTS 	0x01
#define DCR_BOS 	0x02
#define DCR_LAS 	0x04
#define DCR_LS		0x08
#define DCR_ARM 	0x10
#define DCR_FIFO2	0x00
#define DCR_FIFO4	0x20
#define DCR_FIFO8	0x40
#define DCR_FIFO12	0x60

//TCR发送配置寄存器
//初始化开始时写入0x02，置网卡为Loop Back模式，停止发送数据包，
//初始化结束写入0x00。正常发送数据包并加上CRC。
#define TCR_CRC 	0x01
#define TCR_LOOP_NONE	0x00
#define TCR_LOOP_INT	0x02
#define TCR_LOOP_EXT	0x06
#define TCR_ATD 	0x08
#define TCR_OFST	0x10

//RCR接收配置寄存器
//初始化时写入0x04。只接收发给本网卡MAC地址大于64字节的以太网包或广播包
#define RCR_SEP 	0x01
#define RCR_AR		0x02
#define RCR_AB		0x04
#define RCR_AM		0x08
#define RCR_PRO 	0x10
#define RCR_MON 	0x20

/* Bits in received packet status byte and EN0_RSR*/
#define RSR_RXOK      0x01	/* Received a good packet */
#define RSR_CRC       0x02	/* CRC error */
#define RSR_FAE       0x04	/* frame alignment error */
#define RSR_FO        0x08	/* FIFO overrun */
#define RSR_MPA       0x10	/* missed pkt */
#define RSR_PHY       0x20	/* physical/multicast address */
#define RSR_DIS       0x40	/* receiver disable. set in monitor mode */
#define RSR_DEF       0x80	/* deferring */

/* Transmitted packet status, EN0_TSR. */
#define TSR_PTX 0x01		/* Packet transmitted without error */
#define TSR_ND  0x02		/* The transmit wasn't deferred. */
#define TSR_COL 0x04		/* The transmit collided at least once. */
#define TSR_ABT 0x08		/* The transmit collided 16 times, and was deferred. */
#define TSR_CRS 0x10		/* The carrier sense was lost. */
#define TSR_FU  0x20		/* A "FIFO underrun" occurred during transmit. */
#define TSR_CDH 0x40		/* The collision detect "heartbeat" signal was lost. */
#define TSR_OWC 0x80		/* There was an out-of-window collision. */



/* walimis */
#define START_PAGE	0x40
#define END_PAGE	0x80
#define PAGE_SIZE	0x100
#define PAGE_NUM	(END_PAGE - START_PAGE)	/* 16Kbytes */

#define INT_RTL8019 0



//the structure 

typedef struct net_rtl8019_io
{
	// Page 0
	//  Command Register - 00h read/write

	u8 CR;
	//01h write ; page start register
	u8 PSTART;
	//02h write ; page stop register
	u8 PSTOP;
	//03h read/write ; boundary pointer
	u8 BNRY;
	//04h write ; transmit page start register
	u8 TSR;
	u8 TPSR;
	//05,06h write ; transmit byte-count register
	u8 TBCR0;
	u8 TBCR1;
	// Interrupt Status Register - 07h read/write
	u8 ISR;
	//08,09h write ; remote start address register
	u8 RSAR0;
	u8 RSAR1;
	//0a,0bh write ; remote byte-count register
	u8 RBCR0;
	u8 RBCR1;
	// Receive Configuration Register - 0ch write
	u8 RSR;
	u8 RCR;
	// Transmit Configuration Register - 0dh write
	u8 CNTR0;
	u8 TCR;
	// Data Configuration Register - 0eh write
	u8 CNTR1;
	u8 DCR;
	// Interrupt Mask Register - 0fh write
	u8 CNTR2;
	u8 IMR;

	// Page 1
	//
	// Command Register 00h (repeated)
	//01-06h read/write ; MAC address
	u8 PAR0;
	u8 PAR1;
	u8 PAR2;
	u8 PAR3;
	u8 PAR4;
	u8 PAR5;
	// 07h read/write ; current page register
	u8 CURR;
	// 08-0fh read/write ; multicast hash array
	//Bit8u  MAR[8];    


	//
	// Page 2  - diagnostic use only
	// 
	//   Command Register 00h (repeated)
	//
	//   Page Start Register 01h read  (repeated)   PSTART
	//   Page Stop Register  02h read  (repeated)   PSTOP
	//   Transmit Page start address 04h read (repeated)  TPSR
	//   Receive Configuration Register 0ch read (repeated) RCR
	//   Transmit Configuration Register 0dh read (repeated)TCR
	//   Data Configuration Register 0eh read (repeated) DCR
	//   Interrupt Mask Register 0fh read (repeated) IMR
	//

	u8 PROM[12];		// 12 bytes in Prom for MAC addr.

	u8 *sram;
	u32 remote_read_offset;
	u32 remote_write_offset;

	u32 remote_read_count;
	u32 remote_write_count;

	int need_update;
	int index;
	int op_16;
} net_rtl8019_io_t;

static u8 rtl8019_output (struct device_desc *dev, u8 * buf, u16 packet_len);
static void rtl8019_input (struct device_desc *dev);
#endif //_DEV_NET_RTL8019_H_
