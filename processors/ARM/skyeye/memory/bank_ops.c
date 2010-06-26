#include "bank_defs.h"
#include "skyeye.h"
#include "skyeye_types.h"

extern generic_arch_t *arch_instance;
/* Here is the global memory map */
static mem_config_t global_memmap;

mem_bank_t *
bank_ptr (uint32_t addr)
{
	/* Try to reduce the time of find the right bank */
	static mem_bank_t *mbp = NULL;
	if (mbp) {
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	}
	for (mbp = global_memmap.mem_banks; mbp->len; mbp++)
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	return (NULL);
}

/* called by dbct/tb.c tb_find FUNCTION */
mem_bank_t *
insn_bank_ptr (uint32_t addr)
{
	static mem_bank_t *mbp = NULL;
	if (mbp) {
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	}
	for (mbp = global_memmap.mem_banks; mbp->len; mbp++)
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	return (NULL);
}

/**
 *  The interface of read data from bus
 */
int bus_read(short size, int addr, uint32_t * value){
	mem_bank_t * bank;
	if((bank = bank_ptr(addr)) && (bank->bank_read))
		bank->bank_read(size, addr, value);
	else{
		SKYEYE_ERR( "Bus read error, can not find corresponding bank for addr 0x%x,pc=0x%x\n", addr, arch_instance->get_pc());
		//skyeye_exit(-1);
	}
	return 0;	
}

/**
 * The interface of write data from bus
 */
int bus_write(short size, int addr, uint32_t value){
	mem_bank_t * bank;
        if(bank = bank_ptr(addr))
                bank->bank_write(size, addr, value);
        else{
		SKYEYE_ERR( "Bus write error, can not find corresponding bank for addr 0x%x,pc=0x%x\n", addr, arch_instance->get_pc());
		//skyeye_exit(-1);
	}
       return 0; 
}

mem_config_t * get_global_memmap(){
	return &global_memmap;
}
