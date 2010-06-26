/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/*
 * 12/06/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "ppc_cpu.h"
#include "ppc_mmu.h"
#include "ppc_exc.h"
#include "ppc_e500_exc.h"
#include "ppc_memory.h"
#include "ppc_io.h"
#include "types.h"
#include "tracers.h"

#include "skyeye_types.h"
#include "skyeye_config.h"
#include "sysendian.h"
#include "ppc_irq.h"

#include "skyeye_uart.h"

PPC_CPU_State gCPU;

/* For load OS image such as linux, we need to fill some entry in TLB to get 16M sdram mapped, then we can load linux to such memory */
static void bootloader(){
}
static void
ppc_reset_state ()
{
	struct device_desc *dev;
        int i;

        for (i = 0; i < skyeye_config.mach->dev_count; i++) {
                dev = skyeye_config.mach->devices[i];
                if (dev->reset)
                        dev->reset (dev);
        }

}

byte * init_ram; /* 16k init ram for 8560 */
byte * boot_rom; /* default 8M bootrom for 8560 */
byte * ddr_ram; /* 64M DDR SDRAM */

unsigned long init_ram_start_addr, init_ram_size;
uint32 boot_romSize;
uint32 boot_rom_start_addr;

FILE * prof_file;
static bool ppc_cpu_init()
{
	memset(&gCPU, 0, sizeof gCPU);
	//gCPU.pvr = gConfig->getConfigInt(CPU_KEY_PVR);

	gCPU.cpm_reg.dpram = (void *)malloc(MPC8650_DPRAM_SIZE);
	if(!gCPU.cpm_reg.dpram){
		printf("malloc failed for dpram\n");
		skyeye_exit(-1);
	}
	else
		printf("malloc succ for dpram, dpram=0x%x\n", gCPU.cpm_reg.dpram);
	/* initialize decoder */
	ppc_dec_init();
	// initialize srs (mostly for prom)
	int i;
	for (i=0; i<16; i++) {
		gCPU.sr[i] = 0x2aa*i;
	}
	
	return true;
}

static void
ppc_init_state ()
{
	ppc_cpu_init();
	/* initial phsical memory to DEFAULT_GMEMORY_SIZE */
	if(!(boot_rom = malloc(DEFAULT_BOOTROM_SIZE))){
		fprintf(stderr, "can not initialize physical memory...\n");
		skyeye_exit(-1);
	}
	/*we set start_addr */
	boot_rom_start_addr = 0xFFFFFFFF - DEFAULT_BOOTROM_SIZE + 1;
	boot_romSize = DEFAULT_BOOTROM_SIZE;

	/* initialize init_ram parameters */
	if(!(init_ram = malloc(INIT_RAM_SIZE))){
		fprintf(stderr, "malloc failed!\n");
		skyeye_exit(-1);
	}
	if(!(ddr_ram = malloc(DDR_RAM_SIZE))){
		fprintf(stderr, "malloc failed!\n");
                skyeye_exit(-1);

	}
	init_ram_size = INIT_RAM_SIZE;
	init_ram_start_addr = 0xe4010000;

	gCPU.por_conf.porpllsr = 0x40004;
	
	e500_mmu_init();
	
	/* write something to a file for debug or profiling */
	if (!prof_file) {
                prof_file = fopen ("./kernel_prof.txt", "w");
        }

	/* Before boot linux, we need to do some preparation */
	ppc_boot();
}

typedef struct bd_s{
	uint16 flag;
	uint16 len;
	uint32 buf_addr;
}bd_t;
static int scc1_io_do_cycle(){
	byte * ram = &gCPU.cpm_reg.dpram[0];
	/* Param is stored at 0x8000 for SCC1 */
	int rx_base = 0x8000; /* Receive buffer base address */
	int tx_base = 0x8002; /* Transmit buffer base address */

	/* If SCC0 Receive enalbed */
	if(gCPU.cpm_reg.scc[0].gsmrl & 0x00000020){
		/* If we already in recv interrupt, we go out */
		if(gCPU.cpm_reg.scc[0].scce & 0x1)
			goto out_of_recv;
		/* if interrupt is masked */
		if(!(gCPU.cpm_reg.scc[0].sccm & 0x1))
			goto out_of_recv;

		struct timeval tv;
                unsigned char buf;

                tv.tv_sec = 0;
                tv.tv_usec = 0;
		/* max idle cound ,when it become zero, rx bd will be closed */
		#define MAX_IDLE_COUNT 10
		static int max_idle_count = MAX_IDLE_COUNT;
		uint32 buf_addr;
		short datlen;
		static int curr_rx_bd = 0;
		/* if max idle count not expire , we can still receive data */

		/* get a char from current uart */
                if (skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0) {
			/* build a bd for rx */
			int recv_bd_base = ppc_half_from_BE(*(uint16 *)&ram[rx_base]);
			short bd_flag;

			gCPU.cpm_reg.scc[0].scce |= 0x1; /* set RX bit*/ 
			/*if int is masked and scc1 interrupt is masked */
			if(!(gCPU.int_ctrl.simr_l & 0x10)){
				gCPU.int_ctrl.sipnr_l &= 0x10; /* set pending bit in SIPNR_L */				
                		buf_addr = ppc_word_from_BE(*((uint32 *)&ram[recv_bd_base + curr_rx_bd + 4]));
				ddr_ram[buf_addr] = buf;
				/* Now we only implement that send a char once */
				*((sint16 *)&ram[recv_bd_base + curr_rx_bd + 2]) = ppc_half_to_BE(0x1);	

				bd_flag = ppc_half_from_BE(*(sint16 *)&ram[recv_bd_base + curr_rx_bd]);
				/* set empty bit to zero ,waiting core to read the date */
                		bd_flag &= ~0x8000;
				*((sint16 *)&ram[recv_bd_base + curr_rx_bd]) = ppc_half_to_BE(bd_flag);
				/* judge empty bit, if current bd not available, we use next bd */
				if(bd_flag & 0x2000) /* check wrap bit */
					curr_rx_bd = 0; /* Reset  pointer to the begin addr of the bd table */
				else	
					curr_rx_bd += 8; /* indicate to next BD */

				gCPU.pic_percpu.iack0 = SIU_INT_SCC1;

			 	/* trigger interrupt */
                         	ppc_exception(EXT_INT, 0, gCPU.pc);
			}
		}
	}
out_of_recv:
	/* If SCC0 transmit enabled */
	if(gCPU.cpm_reg.scc[0].gsmrl & 0x00000010){
		static int curr_tx_bd = 0;
		int trans_bd_base = ppc_half_from_BE(*(uint16 *)&ram[tx_base]); 
		short bd_flag = ppc_half_from_BE(*(sint16 *)&ram[trans_bd_base + curr_tx_bd]);	
		short bd_len = ppc_half_from_BE(*(sint16 *)&ram[trans_bd_base + curr_tx_bd + 2]);
		uint32 buf_addr = ppc_word_from_BE(*((uint32 *)&ram[trans_bd_base + curr_tx_bd + 4]));
		//fprintf(prof_file, "trans_bd_base=0x%x,curr_tx_bd=0x%x,bd_len=0x%x,buf_addr=0x%x\n",trans_bd_base, curr_tx_bd, bd_len, buf_addr);
		 /* If data ready */
		if(bd_flag & 0x8000){
			int i = 0;
			for (;i < bd_len; i++){
				char c = ddr_ram[buf_addr + i];
				skyeye_uart_write(-1, &c, 1, NULL);
			}

			/* set Empty bit */
			*((sint16 *)&ram[trans_bd_base + curr_tx_bd]) &= ppc_half_to_BE(~0x8000);
			if(bd_flag & 0x2000) /* check wrap bit */ 
				curr_tx_bd = 0; /* Reset  pointer to the begin addr of the bd table */
			else
				curr_tx_bd += 8; /* indicate to next BD */
		}
	}
}

#define TCR_DIE (1 << 26)
#define TSR_DIS (1 << 27)
static void dec_io_do_cycle(){
	gCPU.tbl++;
	/**
	 *  test DIE bit of TCR if timer is enabled
	 */
	if(!(gCPU.tsr & 0x8000000)){
		if((gCPU.tcr & 0x4000000) && (gCPU.msr & 0x8000)) {
		
			if(gCPU.dec > 0)
				gCPU.dec--;
			/* if decrementer eqauls zero */
			if(gCPU.dec == 0){

				/* if auto-load mode is set */
#if 0
				if (gCPU.tcr & 0x400000)
					gCPU.dec = gCPU.decar;
#endif
				/* trigger timer interrupt */
				ppc_exception(DEC, 0, gCPU.pc);
			}
		}
	}
}

/* io cycle */
static void ppc_io_do_cycle(){
	dec_io_do_cycle();
	scc1_io_do_cycle();

	struct device_desc *dev;
	int i;

	for (i = 0; i < skyeye_config.mach->dev_count; i++) {
			dev = skyeye_config.mach->devices[i];
			if (dev->update)
				dev->update (dev);
	}
}

static void
ppc_step_once ()
{
	uint ops=0;
	uint32 real_addr;
	if (true) {
		static uint32_t dbg_start = 0x1000010c;
		static uint32_t dbg_end = 0xfff83254;
		static int flag = 0;
		gCPU.npc = gCPU.pc + 4;
		switch(	ppc_effective_to_physical(gCPU.pc, 0, &real_addr))
		{
			case PPC_MMU_OK:
				break;
			/* we had TLB miss and need to jump to its handler */
			case PPC_MMU_EXC:
				goto exec_npc;
			case PPC_MMU_FATAL:
				/* TLB miss */
	        	        fprintf(stderr, "TLB missed at 0x%x\n", gCPU.pc);
        	        	skyeye_exit(-1);
			default:
				 /* TLB miss */
       			         fprintf(stderr, "Somethingwrong during address translation at 0x%x\n", gCPU.pc);
             			 skyeye_exit(-1);
	
		};

		if(real_addr > boot_rom_start_addr)
			gCPU.current_opc = ppc_word_from_BE(*((int *)&boot_rom[real_addr - boot_rom_start_addr]));
		else if(real_addr >=0 && real_addr < DDR_RAM_SIZE)
			gCPU.current_opc = ppc_word_from_BE(*((int *)&ddr_ram[real_addr]));  	
		else{
			fprintf(stderr,"Can not get instruction from addr 0x%x\n",real_addr);
			skyeye_exit(-1);
		}
		if(gCPU.pc == dbg_start)
			flag = 0;
		if(flag){
			//fprintf(prof_file,"DBG:before pc=0x%x,r0=0x%x,r3=0x%x,r31=0x%x,ddr_ram[0xc21701e4 + 48]=0x%x\n", gCPU.pc, gCPU.gpr[0], gCPU.gpr[3], gCPU.gpr[31], *(int *)&ddr_ram[0x21701e4 + 48]);
			//fprintf(prof_file,"DBG:before pc=0x%x,r0=0x%x,r1=0x%x,r3=0x%x,r4=0x%x,r5=0x%x,r8=0x%x,r30=0x%x, r31=0x%x, lr=0x%x\n", gCPU.pc, gCPU.gpr[0], gCPU.gpr[1], gCPU.gpr[3], gCPU.gpr[4], gCPU.gpr[5], gCPU.gpr[8], gCPU.gpr[30], gCPU.gpr[31], gCPU.lr);
			if(gCPU.pc <= 0xC0000000)
				fprintf(prof_file,"DBG:before pc=0x%x,r0=0x%x,r6=0x%x,r21=0x%x\n", gCPU.pc,gCPU.gpr[0],gCPU.gpr[6],gCPU.gpr[21]);

		}

		ppc_exec_opc();
		
		ppc_io_do_cycle();
exec_npc:
		gCPU.pc = gCPU.npc;
	}		
}

static void
ppc_set_pc (WORD pc)
{
	gCPU.pc = pc;
	/* Fixme, for e500 core, the first instruction should be executed at 0xFFFFFFFC */
	//gCPU.pc = 0xFFFFFFFC;
}
static WORD
ppc_get_pc(){
	return gCPU.pc;
}
/*
 * Since mmu of ppc always enabled, so we can write virtual address here
 */
static int
ppc_ICE_write_byte (WORD addr, uint8_t v)
{
	ppc_write_effective_byte(addr, v);

	/* if failed, return -1*/
	return 0;
}

/*
 * Since mmu of ppc always enabled, so we can read virtual address here
 */
static int ppc_ICE_read_byte (WORD addr, uint8_t *pv){
//	fprintf(stderr, "KSDBG:in %s, addr=0x%x\n", __FUNCTION__, addr);
	/**
	 *  work around for ppc debugger
	 */
	if ((addr & 0xFFFFF000) == 0xBFFFF000)
		return 0;

	ppc_read_effective_byte(addr, pv);
	return 0;
}

static int
ppc_parse_cpu (const char *params[])
{
	return 0;
}

extern void mpc8560_mach_init();
machine_config_t ppc_machines[] = {
        /* machine define for MPC8560 */
        {"mpc8560", mpc8560_mach_init, NULL, NULL, NULL},
	{NULL, NULL, NULL, NULL, NULL},
};
static int
ppc_parse_mach (machine_config_t * mach, const char *params[])
{	
	int i;
	for (i = 0; i < (sizeof (ppc_machines) / sizeof (machine_config_t));
	     i++) {
		if (!strncmp
		    (params[0], ppc_machines[i].machine_name,
		     MAX_PARAM_NAME)) {
			skyeye_config.mach = &ppc_machines[i];
			SKYEYE_INFO
				("mach info: name %s, mach_init addr %p\n",
				 skyeye_config.mach->machine_name,
				 skyeye_config.mach->mach_init);
			return 0;
		}
	}
	SKYEYE_ERR ("Error: Unkonw mach name \"%s\"\n", params[0]);

	return -1;
}
//static mem_config_t ppc_mem;
static int
ppc_parse_mem (int num_params, const char *params[])
{
#if 0
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, num;
	mem_config_t *mc = &ppc_mem;
	mem_bank_t *mb = mc->mem_banks;

	mc->bank_num = mc->current_num++;
	num = mc->current_num - 1;	/*mem_banks should begin from 0. */
	mb[num].filename[0] = '\0';
	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: mem_bank %d has wrong parameter \"%s\".\n",
				 num, name);

		if (!strncmp ("map", name, strlen (name))) {
			if (!strncmp ("M", value, strlen (value))) {
				mb[num].read_byte = ppc_read_byte;
				mb[num].write_byte = ppc_write_byte;
				mb[num].read_halfword = ppc_read_halfword;
				mb[num].write_halfword = ppc_write_halfword;
				mb[num].read_word = ppc_read_word;
				mb[num].write_word = ppc_write_word;
				mb[num].type = MEMTYPE_RAM;
			}
			else if (!strncmp ("I", value, strlen (value))) {
				mb[num].read_byte = ppc_read_byte;
				mb[num].write_byte = ppc_write_byte;
				mb[num].read_halfword = ppc_read_halfword;
				mb[num].write_halfword = ppc_write_halfword;
				mb[num].read_word = ppc_read_word;
				mb[num].write_word = ppc_write_word;
				mb[num].type = MEMTYPE_IO;

				/*ywc 2005-03-30 */
			}
			else if (!strncmp ("F", value, strlen (value))) {
				mb[num].read_byte = ppc_read_byte;
				mb[num].write_byte = ppc_write_byte;
				mb[num].read_halfword = ppc_read_halfword;
				mb[num].write_halfword = ppc_write_halfword;
				mb[num].read_word = ppc_read_word;
				mb[num].write_word = ppc_write_word;
				mb[num].type = MEMTYPE_FLASH;
			}
			else {
				SKYEYE_ERR
					("Error: mem_bank %d \"%s\" parameter has wrong value \"%s\"\n",
					 num, name, value);
			}
		}
		else if (!strncmp ("type", name, strlen (name))) {
			//chy 2003-09-21: process type
			if (!strncmp ("R", value, strlen (value))) {
				if (mb[num].type == MEMTYPE_RAM)
					mb[num].type = MEMTYPE_ROM;
				mb[num].write_byte = warn_write_byte;
				mb[num].write_halfword = warn_write_halfword;
				mb[num].write_word = warn_write_word;
			}
		}
		else if (!strncmp ("addr", name, strlen (name))) {

			if (value[0] == '0' && value[1] == 'x')
				mb[num].addr = strtoul (value, NULL, 16);
			else
				mb[num].addr = strtoul (value, NULL, 10);

		}
		else if (!strncmp ("size", name, strlen (name))) {

			if (value[0] == '0' && value[1] == 'x')
				mb[num].len = strtoul (value, NULL, 16);
			else
				mb[num].len = strtoul (value, NULL, 10);

		}
		else if (!strncmp ("file", name, strlen (name))) {
			strncpy (mb[num].filename, value, strlen (value) + 1);
		}
		else if (!strncmp ("boot", name, strlen (name))) {
			/* this must be the last parameter. */
			if (!strncmp ("yes", value, strlen (value)))
				skyeye_config.start_address = mb[num].addr;
		}
		else {
			SKYEYE_ERR
				("Error: mem_bank %d has unknow parameter \"%s\".\n",
				 num, name);
		}
	}
#endif
	return 0;
}

void
init_ppc_arch ()
{

	static arch_config_t ppc_arch;

	ppc_arch.arch_name = "ppc";
	ppc_arch.init = ppc_init_state;
	ppc_arch.reset = ppc_reset_state;
	ppc_arch.set_pc = ppc_set_pc;
	ppc_arch.get_pc = ppc_get_pc;
	ppc_arch.step_once = ppc_step_once;
	ppc_arch.ICE_write_byte = ppc_ICE_write_byte;
	ppc_arch.ICE_read_byte = ppc_ICE_read_byte;
	ppc_arch.parse_cpu = ppc_parse_cpu;
	ppc_arch.parse_mach = ppc_parse_mach;
	ppc_arch.parse_mem = ppc_parse_mem;

	register_arch (&ppc_arch);
}

void print_ppc_arg(FILE * log){
	if(log)
		fprintf(log, "r3=0x%x", gCPU.gpr[3]);
}
