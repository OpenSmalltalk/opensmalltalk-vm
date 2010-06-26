/*
        ppc_io.c - necessary arm definition for skyeye debugger
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
 * 04/26/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include <stdint.h>
#include <skyeye_device.h>
#include <skyeye_config.h>

extern skyeye_config_t skyeye_config;

uint32_t ppc_read_byte(void * state, uint32_t addr){
	return 0;
}
uint32_t ppc_read_halfword(void * state,uint32_t addr){
	return 0;
}
uint32_t ppc_read_word(void * state, uint32_t addr){
	return 0;
}
void ppc_write_byte(void * state, uint32_t addr, uint32_t data){}
void ppc_write_halfword(void * state, uint32_t addr,uint32_t data){}
void ppc_write_word(void * state,uint32_t addr,uint32_t data){}

uint32_t
ppc_io_read_byte (void * state, uint32_t addr)
{
	struct device_desc *dev;
	uint32_t data;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->read_byte)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {

			if (dev->read_byte (dev, addr, (u8 *) & data) !=
			    ADDR_NOHIT)
				return data & 0xff;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {

			if (dev->read_byte (dev, addr, (u8 *) & data) !=
			    ADDR_NOHIT)
				return data & 0xff;
		}
	}
}

uint32_t
ppc_io_read_halfword (void * state, uint32_t addr)
{
	struct device_desc *dev;
	uint32_t data;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->read_halfword)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {
			if (dev->read_halfword (dev, addr, (u16 *) & data) !=
			    ADDR_NOHIT)
				return data & 0xffff;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {
			if (dev->read_halfword (dev, addr, (u16 *) & data) !=
			    ADDR_NOHIT)
				return data & 0xffff;
		}
	}
}

uint32_t
ppc_io_read_word (void * state, uint32_t addr)
{
	struct device_desc *dev;
	uint32_t data;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->read_word)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {
			if (dev->read_word (dev, addr, (u32 *) & data) !=
			    ADDR_NOHIT)
				return data;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {
			if (dev->read_word (dev, addr, (u32 *) & data) !=
			    ADDR_NOHIT)
				return data;
		}
	}
}

void
ppc_io_write_byte (void * state, uint32_t addr, uint32_t data)
{
	struct device_desc *dev;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->write_byte)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {
			if (dev->write_byte (dev, addr, (u8) data) !=
			    ADDR_NOHIT)
				return;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {
			if (dev->write_byte (dev, addr, (u8) data) !=
			    ADDR_NOHIT)
				return;
		}
	}
}

void
ppc_io_write_halfword (void * state, uint32_t addr, uint32_t data)
{
	struct device_desc *dev;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->write_halfword)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {
			if (dev->write_halfword (dev, addr, (u16) data) !=
			    ADDR_NOHIT)
				return;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {
			if (dev->write_halfword (dev, addr, (u16) data) !=
			    ADDR_NOHIT)
				return;
		}
	}
}

void
ppc_io_write_word (void * state, uint32_t addr, uint32_t data)
{
	struct device_desc *dev;
	int i;
	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (!dev->write_word)
			continue;
		/* if we specify size=0, we don't check 
		 * whether "addr" is in the range of address space of device.
		 * */
		if (dev->size == 0) {
			if (dev->write_word (dev, addr, data) != ADDR_NOHIT)
				return;
		}
		else if ((addr >= dev->base)
			 && (addr < (dev->base + dev->size))) {
			if (dev->write_word (dev, addr, data) != ADDR_NOHIT)
				return;
		}
	}
}
