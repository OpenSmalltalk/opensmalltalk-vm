/*
        bf533_io.h - necessary bf533 io address range definition for bf533 simulation
        Copyright (C) 2003-2007 Skyeye Develop Group
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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#ifndef __BF533_IO_H__
#define __BF533_IO_H__

#define IO_START_ADDR 0xFFC00000
#define IO_END_ADDR 0xFFFFFFFF

#define DMA_IO_START_ADDR 0xFFC00B00
#define DMA_IO_END_ADDR 0xFFC00FFF

#define UART_IO_START_ADDR 0xFFC00400
#define UART_IO_END_ADDR 0xFFC004FF

#define CORETIMER_IO_START_ADDR 0xFFE03000
#define CORETIMER_IO_END_ADDR 0xFFE0300C

#define EBIU_IO_START_ADDR 0xFFC00A00
#define EBIU_IO_END_ADDR 0xFFC00AFF

#define TCNTL 0x0
#define TPERIOD 0x4
#define TSCALE 0x8
#define TCOUNT 0xc

#define CORE_INT_IO_START_ADDR 0xFFE02000
#define CORE_INT_IO_END_ADDR 0xFFE02110

#define WD_IO_START_ADDR 0xFFC00200
#define WD_IO_END_ADDR 0xFFC002FF

#define DEU_IO_START_ADDR 0xFFE05000
#define DEU_IO_END_ADDR 0xFFE05008

#define DPMC_IO_START_ADDR 0xFFC00000
#define DPMC_IO_END_ADDR 0xFFC000FF

#define SIC_IO_START_ADDR 0xFFC00100
#define SIC_IO_END_ADDR 0xFFC001FF

#define L1MEM_IO_START_ADDR 0xFFE01004
#define L1MEM_IO_END_ADDR 0xFFE01404
#define L1MEM_IO_SIZE (L1MEM_IO_END_ADDR - L1MEM_IO_START_ADDR)

#define L1DMEM_IO_START_ADDR 0xFFE00000
#define L1DMEM_IO_END_ADDR 0xFFE00404
#define L1DMEM_IO_SIZE (L1DMEM_IO_END_ADDR - L1DMEM_IO_START_ADDR)

#define RTC_IO_START_ADDR 0xFFC00300
#define RTC_IO_END_ADDR 0xFFC003FF
#define RTC_IO_SIZE (RTC_IO_END_ADDR - RTC_IO_START_ADDR)

#define CORE_TIMER_IO_START_ADDR 0xFFE03000
#define CORE_TIMER_IO_END_ADDR 0xFFE03010
#define CORE_TIMER_IO_SIZE (CORE_TIMER_IO_END_ADDR-CORE_TIMER_IO_START_ADDR)

#define PF_IO_START_ADDR 0xFFC00700
#define PF_IO_END_ADDR 0xFFC007FF
#define PF_IO_SIZE (PF_IO_END_ADDR - PF_IO_START_ADDR)

#define TBUF_IO_START_ADDR 0xFFE06000
#define TBUF_IO_END_ADDR 0xFFE06103
#define TBUF_IO_SIZE (TBUF_IO_END_ADDR - TBUF_IO_START_ADDR)

#define PORT_IO_START_ADDR 0xFFC03200
#define PORT_IO_END_ADDR 0xFFC0320C
#define PORT_IO_SIZE (PORT_IO_END_ADDR - PORT_IO_START_ADDR)

#define ETH_IO_START_ADDR 0xFFC03000
#define ETH_IO_END_ADDR   0xFFC031D8
#define ETH_IO_SIZE (ETH_IO_END_ADDR - ETH_IO_START_ADDR)

#define declare_device(name) \
static void name##_write_byte(bu32 addr, bu8 v); \
static void name##_write_word(bu32 addr, bu16 v); \
static void name##_write_long(bu32 addr, bu32 v); \
static bu8 name##_read_byte(bu32 addr); \
static bu16 name##_read_word(bu32 addr); \
static bu32 name##_read_long(bu32 addr);

#endif
