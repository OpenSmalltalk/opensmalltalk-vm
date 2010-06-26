#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"

static uint32_t
flash_read_byte (uint32_t addr)
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
	printf("In %s,Can not find address 0x%x\n", __FUNCTION__, addr);
	return data;
}

static uint32_t
flash_read_halfword (uint32_t addr)
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
	printf("In %s,Can not find address 0x%x\n", __FUNCTION__, addr);
	return data;
}

uint32_t
flash_read_word (uint32_t addr)
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
	printf("In %s,Can not find address 0x%x\n", __FUNCTION__, addr);
	return data;
}

void
flash_write_byte (uint32_t addr, uint32_t data)
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
	fprintf(stderr, "In %s, addr 0x%x is invalid.\n", __FUNCTION__, addr);
}

void
flash_write_halfword (uint32_t addr, uint32_t data)
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
	fprintf(stderr, "In %s, addr 0x%x is invalid.\n", __FUNCTION__, addr);
}

static void
flash_write_word (uint32_t addr, uint32_t data)
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
	fprintf(stderr, "In %s, addr 0x%x is invalid.\n", __FUNCTION__, addr);
}
char flash_read(short size, int offset, uint32_t * value){
	switch(size){
		case 8:
			*(uint8_t *)value = (uint8_t)flash_read_byte (offset);
			break;
		case 16:
			*(uint16_t *)value = (uint16_t)flash_read_halfword(offset);
			break;
		case 32:
			*value = flash_read_word(offset);
			break;
		default:
			return -1;
	}
	return 0;

}
char flash_write(short size, int offset, uint32_t value){
	switch(size){
		case 8:
                        flash_write_byte (offset, value);
                        break;
                case 16:
                        flash_write_halfword(offset, value);
                        break;
                case 32:
                        flash_write_word(offset, value);
                        break;
                default:
                        return -1;

	}
	return 0;

}
