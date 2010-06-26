/*
    armio.c - I/O registers and interrupt controller.
    ARMulator extensions for the ARM7100 family.
    Copyright (C) 1999  Ben Williamson

	Changes to support running uClinux/Atmel AT91 targets
    Copyright (C) 2002  David McCullough <davidm@snapgear.com>

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

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"

/*
 *  7/17/2003     clean some routine.
 *                clean io_reset only to do special mach_io_reset function.
 *                wlm <wlm@student.dlut.edu.cn>
 */


/* Reset IO. 
 * Now only reset some Internal IO Register.
 * Every machine has a reset routine to init it's special registers.
 * wlm 2003/7/17
 * */

#if 0
static int prescale;

void
io_reset (ARMul_State * state)
{
	struct device_desc *dev;
	int i;

	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
		dev = skyeye_config.mach->devices[i];
		if (dev->reset)
			dev->reset (dev);
	}
	if(skyeye_config.mach->mach_io_reset)
		skyeye_config.mach->mach_io_reset (state);
	else
		fprintf(stderr,"SKYEYE_ERR:mach_io_reset is NULL\n");
}

void
io_do_cycle (ARMul_State * state)
{
	struct device_desc *dev;
	int i;

//teawater add DBCT_TEST_SPEED 2005.10.04---------------------------------------
#ifdef DBCT_TEST_SPEED
	state->instr_count++;
#endif	//DBCT_TEST_SPEED
//AJ2D--------------------------------------------------------------------------
	prescale--;
	if (prescale <= 0) {
		prescale = skyeye_config.mach->io_cycle_divisor;
		for (i = 0; i < skyeye_config.mach->dev_count; i++) {
			dev = skyeye_config.mach->devices[i];
			if (dev->update)
				dev->update (dev);
		}
		skyeye_config.mach->mach_io_do_cycle (state);
	}
}
#endif
unsigned char
mem_read_char (ARMul_State * state, ARMword addr)
{
	union
	{
		unsigned char buf[4];
		ARMword w;
	} tmp;

	//tmp.w = mem_read_word (state, addr & ~0x3);
	bus_read(32, addr & ~0x3, &tmp.w);
	if (state->bigendSig == HIGH)
		//if (big_endian)
		return (tmp.buf[3 - (addr & 0x3)]);
	return (tmp.buf[addr & 0x3]);
}

void
mem_write_char (ARMul_State * state, ARMword addr, unsigned char c)
{
	union
	{
		unsigned char buf[4];
		ARMword w;
	} tmp;

	//tmp.w = mem_read_word (state, addr & ~0x3);
	bus_read(32, addr & ~0x3, &tmp.w);
	if (state->bigendSig == HIGH)	/*big enddian? */
		//if (big_endian)
		tmp.buf[3 - (addr & 0x3)] = c;
	else
		tmp.buf[addr & 0x3] = c;
	//mem_write_word (state, addr & ~0x3, tmp.w);
	bus_write(32, addr & ~0x3, tmp.w);
}
#if 0
/* Internal registers from 0x80000000 to 0x80002000.
   We also define a "debug I/O" register thereafter. */

ARMword
io_read_byte (ARMul_State * state, ARMword addr)
{
	struct device_desc *dev;
	ARMword data;
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
	return skyeye_config.mach->mach_io_read_byte (state, addr);
}

ARMword
io_read_halfword (ARMul_State * state, ARMword addr)
{
	struct device_desc *dev;
	ARMword data;
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
	return skyeye_config.mach->mach_io_read_halfword (state, addr);
}

ARMword
io_read_word (ARMul_State * state, ARMword addr)
{
	struct device_desc *dev;
	ARMword data;
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
	return skyeye_config.mach->mach_io_read_word (state, addr);
}

void
io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
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
	skyeye_config.mach->mach_io_write_byte (state, addr, data);
}

void
io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
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
	skyeye_config.mach->mach_io_write_halfword (state, addr, data);
}

void
io_write_word (ARMul_State * state, ARMword addr, ARMword data)
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
	skyeye_config.mach->mach_io_write_word (state, addr, data);
}
#endif
