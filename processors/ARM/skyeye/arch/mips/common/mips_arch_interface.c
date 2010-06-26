/* Simulator for MIPS R3000 architecture.

		THIS SOFTWARE IS NOT COPYRIGHTED

   Cygnus offers the following for use in the public domain.  Cygnus
   makes no warranty with regard to the software or it's performance
   and the user accepts the software "AS IS" with all faults.

   CYGNUS DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD TO
   THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

*/

#include "skyeye_config.h"
#include "emul.h"
#include <stdlib.h>
#include "mipsdef.h"
#include <stdio.h>

MIPS_State* mstate;
static char *arch_name = "mips";
mips_mem_config_t mips_mem_config;
extern mips_mem_state_t mips_mem;
extern FILE *skyeye_logfd;
extern int trace_level;
extern UInt8* mem_bunks;
extern void mips_mem_reset ();
extern UInt32 mips_real_read_byte (UInt32 addr);
extern UInt32 mips_real_read_halfword (UInt32 addr);
extern UInt32 mips_real_read_word (UInt32 addr);
extern UInt64 mips_real_read_doubleword (UInt32 addr);
extern void mips_real_write_byte (UInt32 addr, UInt32 data);
extern void mips_real_write_halfword ( UInt32 addr, UInt32 data);
extern void mips_real_write_word ( UInt32 addr, UInt32 data);
extern void mips_real_write_doubleword ( UInt32 addr, UInt64 data);

//IO address space
extern UInt32 mips_io_read_byte (UInt32 addr);
extern UInt32 mips_io_read_halfword (UInt32 addr);
extern UInt32 mips_io_read_word (UInt32 addr);
extern UInt64 mips_io_read_doubleword (UInt32 addr);
extern void mips_io_write_byte (UInt32 addr, UInt32 data);
extern void mips_io_write_halfword (UInt32 addr, UInt32 data);
extern void mips_io_write_word (UInt32 addr, UInt32 data);
extern void mips_io_write_doubleword (UInt32 addr, UInt64 data);

//Flash address space
extern UInt32 mips_flash_read_byte (UInt32 addr);
extern UInt32 mips_flash_read_halfword (UInt32 addr);
extern UInt32 mips_flash_read_word (UInt32 addr);
extern UInt64 mips_flash_read_doubleword ( UInt32 addr);
extern void mips_flash_write_byte (UInt32 addr, UInt32 data);
extern void mips_flash_write_halfword (UInt32 addr, UInt32 data);
extern void mips_flash_write_word (UInt32 addr, UInt32 data);
extern void mips_flash_write_doubleword (UInt32 addr, UInt64 data);

extern void mips_warn_write_byte (UInt32 addr, UInt32 data);
extern void mips_warn_write_halfword (UInt32 addr, UInt32 data);
extern void mips_warn_write_word (UInt32 addr, UInt32 data);
extern mips_mem_bank_t* mips_bank_ptr (UInt32 addr);
extern void mips_mem_write_byte (UInt32 phys_addr, UInt32 v);
extern void mips_mem_write_halfword (UInt32 phys_addr, UInt32 v);
extern void mips_mem_write_word (UInt32 phys_addr, UInt32 v);
extern void mips_mem_write_doubleword (UInt64 phys_addr, UInt64 v);
extern UInt32 mips_mem_read_byte (UInt32 phys_addr);
extern UInt32 mips_mem_read_halfword (UInt32 phys_addr);
extern UInt32 mips_mem_read_word (UInt32 phys_addr);
extern UInt64 mips_mem_read_doubleword (UInt64 phys_addr);
extern void mipsMul_WriteByte (MIPS_State* mstate, UInt32 vir_addr, UInt32 v);
extern void mips_mmu_write_byte (MIPS_State* mstate, UInt32 vir_addr, UInt32 v);


//chy 20060717
int SKYPRINTF(char * fmt,...)
{ 
	return 0;
}

void 
mips_init_set(UInt32 addr, UInt8 value, int size)
{

}

void 
mips_mem_read(UInt32 pa, UInt32 *data, int len)
{
	/* if pa is located at kseg0 */
	if(pa >= 0x80000000 && pa < 0xA0000000)
		pa = pa & ~0x80000000;
	/* if pa is located at kseg1 */
	if(pa >= 0xA0000000 && pa < 0xC0000000)
		pa = pa & ~0xE0000000;
	//if(pa >= 0x14a1a0 && pa <= 0x14c000)
	//	printf("###############read addr pa=0x%x,pc=0x%x\n", pa, mstate->pc);
	bus_read(len * 8, pa, data);
#if 0
	switch(len) {
		
        	case 1: {
			*data = mips_mem_read_byte(pa);
			break;
		}
	 	case 2: {
	 		*data = mips_mem_read_halfword(pa);
			break;
	 	}
	 	case 4: {
			*data = mips_mem_read_word(pa);
			break;
	 	}
		default:
			break;
	}
#endif
}

void 
mips_mem_write(UInt32 pa, const UInt32* data, int len)
{
	/* if pa is located at kseg0 */
        if(pa >= 0x80000000 && pa < 0xA0000000)
                pa = pa & ~0x80000000;
        /* if pa is located at kseg1 */
        if(pa >= 0xA0000000 && pa < 0xC0000000)
                pa = pa & ~0xE0000000;

	UInt32 addr = bits(pa, 31, 0);
	bus_write(len * 8, pa, *data);
#if 0
	if(pa >= 0x14a1a0 && pa <= 0x14c000)
		printf("###############write addr pa=0x%x,pc=0x%x\n", addr, mstate->pc);
	switch(len) {
		
        	case 1: {
			mips_mem_write_byte(pa, *data);
			break;
		}
	 	case 2: {
	 		mips_mem_write_halfword(pa, *data);
			break;
	 	}
	 	case 4: {
			mips_mem_write_word(pa, *data);
			break;
	 	}
		default:
			fprintf(stderr, "unimplemented write for size %d in %s\n", len, __FUNCTION__);
			break;
	}
#endif
	return;
	
}

static void 
init_icache()
{
	int i;
	for(i = 0; i < Icache_log2_sets; i++)
	{  
		Icache_lru_init(mstate->icache.set[i].Icache_lru);
	}

}

static void 
init_dcache()
{
	int i;
	for(i = 0; i < Dcache_log2_sets; i++)
	{  
	      Dcache_lru_init(mstate->dcache.set[i].Dcache_lru);
	}
}

static void 
init_tlb()
{
	int i; 
	for(i = 0;i < tlb_map_size + 1; i++)
	{
		mstate->tlb_map[i] = NULL;
	}
}


static void 
mips_init_state()
{
	set_bit(mstate->mode, 2);
	mstate = (MIPS_State* )malloc(sizeof(MIPS_State));
	if (!mstate) {
		fprintf (stderr, "malloc error!\n");
		skyeye_exit (-1);
	}

	mstate->warm = 0;
	mstate->conf.ec = 4; //I don't know what should it be.

	// set the little endian as the default
	mstate->bigendSig = 0; //Shi yang 2006-08-18
	
	//No interrupt
	mstate->irq_pending = 0;

	mstate->cp0[SR] = 0x40004;
	
	init_icache();
	init_dcache();
	init_tlb();

	 /* mach init */
	if(skyeye_config.mach->mach_init)
        	skyeye_config.mach->mach_init (mstate, skyeye_config.mach);
	else{
		fprintf(stderr, "skyeye arch is not initializd correctly.\n");
		skyeye_exit(-1);
	}
		
}

static void 
mips_reset_state()
{
	mips_mem_reset();

    	if (!mstate->warm) {
		memset(mstate->cp1, 0, sizeof(mstate->cp1[32]));
		memset(mstate->fpr, 0, sizeof(mstate->fpr[32]));
		mstate->count_seed = mstate->now;
		mstate->nop_count = 0;
    	}
    	mstate->ll_bit = 0;
    	mstate->sync_bit = 0;

    	// Deliver the reset exception.
    	if (mstate->warm)
		deliver_soft_reset(mstate);
    	else
		deliver_cold_reset(mstate);

    	process_reset(mstate);
}

void 
mips_trigger_irq(MIPS_State* mstate)
{
	VA epc;

	//Get the content of the cause register
	UInt32 cause = mstate->cp0[Cause];

	//When the instruction is in the delay slot, we have to delay an instruction 
    	if (!branch_delay_slot(mstate))
		epc = mstate->pc;
    	else {
		epc = mstate->pc - 4;
		cause = set_bit(cause, Cause_BD);
    	}
    	mstate->cp0[Cause] = cause;
	mstate->cp0[EPC] = epc;

	//Change the pointer pc to deal with the interrupt handler
	if(bit(mstate->cp0[SR], SR_BEV) )
	{
		mstate->pc = 0xbfc00380;
	} else {
		mstate->pc = 0x80000180;
	}

	mstate->pipeline = nothing_special;
	
}

static void 
mips_step_once()
{
	mstate->gpr[0] = 0;
	
	/* Check for interrupts. In real hardware, these have a priority lower
	 * than all exceptions, but simulating this effect is too hard to be
	 * worth the effort (interrupts and resets are not meant to be
	 * delivered accurately anyway.)
         */
	if(mstate->irq_pending)
	{
		mips_trigger_irq(mstate);
	}
	
	/* Look up the ITLB. It's not clear from the manuals whether the ITLB
	 * stores the ASIDs or not. I assume it does. ITLB has the same size
	 * as in the real hardware, mapping two 4KB pages.  Because decoding a
	 * MIPS64 virtual address is far from trivial, ITLB and DTLB actually
	 * improve the simulator's performance: something I cannot say about
	 * caches and JTLB.
   	 */

	PA pa; //Shi yang 2006-08-18
	VA va;
	Instr instr;
	int next_state;
	va = mstate->pc;
	if(translate_vaddr(mstate, va, instr_fetch, &pa) == TLB_SUCC){
		mips_mem_read(pa, &instr, 4);
		next_state = decode(mstate, instr);	
		//skyeye_exit(-1);
	}
	else{
		//fprintf(stderr, "Exception when get instruction!\n");
	}

	/* NOTE: mstate->pipeline is also possibely set in decode function */

	static int flag = 0;
	if(va == 0x40acb8)
		flag = 0;
	if(flag && skyeye_logfd)
		//fprintf(skyeye_logfd, "KSDBG:instr=0x%x,pa=0x%x, va=0x%x, sp=0x%x, ra=0x%x,s1=0x%x, v0=0x%x\n", instr, pa, va, mstate->gpr[29], mstate->gpr[31],mstate->gpr[17], mstate->gpr[2]);
		fprintf(skyeye_logfd, "KSDBG:instr=0x%x,pa=0x%x, va=0x%x, a0=0x%x, k1=0x%x, t0=0x%x, ra=0x%x, s4=0x%x, gp=0x%x\n", instr, pa, va, mstate->gpr[4], mstate->gpr[27], mstate->gpr[8], mstate->gpr[31], mstate->gpr[20], mstate->gpr[28]);
		//fprintf(skyeye_logfd, "KSDBG:instr=0x%x,pa=0x%x, va=0x%x,v0=0x%x,t0=0x%x\n", instr, pa, va, mstate->gpr[2], mstate->gpr[8]);
	/*if(mips_mem.rom[0][(0x1179a00 >> 2)] != 0){
		if(mips_mem.rom[0][(0x1179a00 >> 2)] != 0x81179b28)
			fprintf(stderr, "Value changed:0x81179a00 = 0x%x,pc=0x%x\n", mips_mem.rom[0][(0x1179a00 >> 2)],mstate->pc);
	}*/

	switch (mstate->pipeline) {
		case nothing_special:
	    		mstate->pc += 4;
	    		break;
		case branch_delay:
		    	mstate->pc = mstate->branch_target;
		    	break;
		case instr_addr_error:
		    	process_address_error(mstate, instr_fetch, mstate->branch_target);
		case branch_nodelay: /* For syscall and TLB exp, we donot like to add pc */
			mstate->pipeline = nothing_special;
			return; /* do nothing */
	}
	mstate->pipeline = next_state;
	/* if timer int is not mask and counter value is equal to compare value */
	if(mstate->cp0[Count]++ >= mstate->cp0[Compare]){
			/* update counter value in cp0 */
			mstate->cp0[Count] = 0;
	
		/* if interrupt is enabled? */
		if((mstate->cp0[SR] & (1 << SR_IEC)) && (mstate-> cp0[SR] & 1 << SR_IM7)){
			if(!(mstate->cp0[Cause] & 1 << Cause_IP7) && (!(mstate->cp0[SR] & 0x2)))
			{
				//fprintf(stderr, "counter=0x%x,pc=0x%x\n", mstate->cp0[Count], mstate->pc);
				/* Set counter interrupt bit in IP section of Cause register */
				mstate->cp0[Cause] |= 1 << Cause_IP7;
			/* Set ExcCode to zero in Cause register */
				process_exception(mstate, EXC_Int, common_vector);
			}
		}
	}
	skyeye_config.mach->mach_io_do_cycle (mstate);	
}

static void 
mips_set_pc(UInt32 addr)
{
	mstate->pc = addr;
}

static UInt32 
mips_get_pc()
{
	return  mstate->pc;
}

static void
mips_write_byte (WORD addr, uint8_t v)
{
	mips_mem_write_byte (addr, v);
}

static void 
mips_write_byte64(UInt64 addr, UInt8 data)
{

}

static unsigned char 
mips_read_byte64(UInt64 addr)
{

}


extern void nedved_mach_init(void * state, machine_config_t * mach);
extern void au1100_mach_init(void * state, machine_config_t * mach);
extern void fulong_mach_init(void * state, machine_config_t * mach);
extern void gs32eb1_mach_init(void * state, machine_config_t * mach);


machine_config_t mips_machines[] = {
	{"nedved", nedved_mach_init, NULL, NULL, NULL},
	{"au1100", au1100_mach_init, NULL, NULL, NULL},
	{"fulong", fulong_mach_init, NULL, NULL, NULL},
	{"gs32eb1", gs32eb1_mach_init, NULL, NULL, NULL},
	{NULL, NULL, NULL, NULL, NULL},
};

static int 
mips_parse_cpu(const char* param[])
{
	return 1;
}

static int 
mips_parse_mach(machine_config_t * mach, const char* params[])
{
	int i;
	for (i = 0; i < (sizeof (mips_machines) / sizeof (machine_config_t));
	     i++) {
		if (!strncmp
		    (params[0], mips_machines[i].machine_name,
		     MAX_PARAM_NAME)) {
			skyeye_config.mach = &mips_machines[i];
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

static int 
mips_parse_mem(int num_params, const char* params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, num;
	mips_mem_config_t *mc = &mips_mem_config;
	mips_mem_bank_t *mb = mc->mem_banks;

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
				mb[num].read_byte = mips_real_read_byte;
				mb[num].write_byte = mips_real_write_byte;
				mb[num].read_halfword = mips_real_read_halfword;
				mb[num].write_halfword = mips_real_write_halfword;
				mb[num].read_word = mips_real_read_word;
				mb[num].write_word = mips_real_write_word;
				mb[num].read_doubleword = mips_real_read_doubleword;
				mb[num].write_doubleword = mips_real_write_doubleword;
				mb[num].type = MEMTYPE_RAM;
			}
			else if (!strncmp ("I", value, strlen (value))) {
				mb[num].read_byte = mips_io_read_byte;
				mb[num].write_byte = mips_io_write_byte;
				mb[num].read_halfword = mips_io_read_halfword;
				mb[num].write_halfword = mips_io_write_halfword;
				mb[num].read_word = mips_io_read_word;
				mb[num].write_word = mips_io_write_word;
				mb[num].read_doubleword = mips_io_read_doubleword;
				mb[num].write_doubleword = mips_io_write_doubleword;

				mb[num].type = MEMTYPE_IO;

				/*ywc 2005-03-30 */
			}
			else if (!strncmp ("F", value, strlen (value))) {
				mb[num].read_byte = mips_flash_read_byte;
				mb[num].write_byte = mips_flash_write_byte;
				mb[num].read_halfword = mips_flash_read_halfword;
				mb[num].write_halfword = mips_flash_write_halfword;
				mb[num].read_word = mips_flash_read_word;
				mb[num].write_word = mips_flash_write_word;
				mb[num].read_doubleword = mips_flash_read_doubleword;
				mb[num].write_doubleword = mips_flash_write_doubleword;
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
				mb[num].write_byte = mips_warn_write_byte;
				mb[num].write_halfword = mips_warn_write_halfword;
				mb[num].write_word = mips_warn_write_word;
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
			/*this must be the last parameter. */
			if (!strncmp ("yes", value, strlen (value)))
				skyeye_config.start_address = mb[num].addr;
		}
		else {
			SKYEYE_ERR
				("Error: mem_bank %d has unknow parameter \"%s\".\n",
				 num, name);
		}
	}

	return 0;
}

static int mips_ICE_read_byte(WORD addr, uint8_t *data){
	mips_mem_read(addr, (UInt32 *)data, 1);
	return 0;
}
static int mips_ICE_write_byte(WORD addr, uint8_t data){
#if 0
	extern mips_mem_bank_t *mips_global_mbp;
        /* if pa is located at kseg0 */
        if(addr >= 0x80000000 && addr < 0xA0000000)
                addr = addr & ~0x80000000;
        /* if pa is located at kseg1 */
        if(addr >= 0xA0000000 && addr < 0xC0000000)
                addr = addr & ~0xE0000000;


	uint8_t  *temp;
	 //get the memory bank of the address
        mips_global_mbp = mips_bank_ptr (addr);

        if (mips_global_mbp ) {
		temp = &(mips_mem.rom[mips_global_mbp -
                               mips_mem_config.mem_banks][(addr -
                            mips_global_mbp->addr) >> 2]);
		temp += addr & 0x3;
        	*temp = data ;
        } else {
                fprintf(stderr,"mips memory write error in %s, addr=0x%x,pc=0x%x..\n",__FUNCTION__,addr, mstate->pc);
                skyeye_exit(-1);
        }
#endif
      	mips_mem_write(addr, &data, 1);  
	return 0;
}

void 
init_mips_arch ()
{
	static arch_config_t mips_arch;
	mips_arch.arch_name = arch_name;
	mips_arch.init = mips_init_state;
	mips_arch.reset = mips_reset_state;
	mips_arch.step_once = mips_step_once;
	mips_arch.set_pc = mips_set_pc;
	mips_arch.get_pc = mips_get_pc;
	mips_arch.ICE_read_byte = mips_ICE_read_byte;
	mips_arch.ICE_write_byte = mips_ICE_write_byte;
	mips_arch.parse_cpu = mips_parse_cpu;
	mips_arch.parse_mach = mips_parse_mach;
	//mips_arch.parse_mem = mips_parse_mem;
	register_arch (&mips_arch);
}
