#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"

ARMword
flash_read_byte (ARMul_State * state, ARMword addr)
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
}

ARMword
flash_read_halfword (ARMul_State * state, ARMword addr)
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
}

ARMword
flash_read_word (ARMul_State * state, ARMword addr)
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
}

void
flash_write_byte (ARMul_State * state, ARMword addr, ARMword data)
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
flash_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
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
flash_write_word (ARMul_State * state, ARMword addr, ARMword data)
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
