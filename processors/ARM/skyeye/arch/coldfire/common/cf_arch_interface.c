/*
        cf_arch_interface.c - interface between simulation of coldfire to common utility

        Copyright (C) 2007 Skyeye Develop Group
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



#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif


#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#ifdef HAVE_LIBREADLINE
#include <readline/readline.h>
#endif

#include "coldfire.h"
#include "skyeye_config.h"
char Run_Exit = 0;

SKYEYE_DBGR_DEFAULT_CHANNEL(run);

static int stop_now = 0;


void coldfire_init_state(){
	static int done = 0;
	if(!done){
		done = 1;
		Memory_Init();	
		Instruction_Init();
		instruction_register_instructions();
		memory_module_setup_segment("ram",0,0x0,32*1024*1024);
		/* SRAM for 5272 */
		memory_module_setup_segment("ram",0, 0x20000000, 4096);
		/* set supervisor mode */
		SRBits->S = 1;
		memory_core.mbar = 0x10000000;
		memory_core.mbar2 = 0x80000000;
		memory_core.mbar_size = 0x1024;
		memory_core.mbar2_size = 0x1024;

		 /*mach init */
	        skyeye_config.mach->mach_init (&memory_core, skyeye_config.mach);
	
	}
	
}
void coldfire_reset_state(){
}

extern void mcf5249_io_do_cycle();
/* Execute a single instruction.  */

void
coldfire_step_once ()
{
	unsigned int Instr;
	struct _Instruction *InstructionPtr;
#ifdef INSTRUCTION_PROFILE        
	unsigned long long LowTime=0, HighTime=0;
	char Buffer[16];
#endif        

	//while(!Run_Exit) {
	if(1){

		SKYEYE_DBG("New cycle, PC=0x%08lx, SP=0x%08lx\n",
                                memory_core.pc, memory_core.a[7]);
		/* printf("New cycle, PC=0x%08lx, SP=0x%08lx\n",
                                memory_core.pc, memory_core.a[7]);	
		*/
		/* Check for any pending exceptions */
		exception_check_and_handle();
		/* As we're coming back from an interrupt, check for exit */
		//if(Run_Exit) break;

		/* Save the PC for the beginning of this instruction
		 *  This is useful for exceptions that reset the PC */
		memory_core.pc_instruction_begin = memory_core.pc;

		/* Before we execute this instruction, catch a bad PC counter */

		/* Get the instruction from memory */
		if(!Memory_RetrWord(&Instr, memory_core.pc)) 
			//continue;
			;

		/* Look it up */
		InstructionPtr = Instruction_FindInstruction(Instr);

                if(InstructionPtr==NULL) {
                        //exception_do_exception(4);
			//continue;
                } else {
                        /* Run the instruction */


			(*InstructionPtr->FunctionPtr)();

		}
		/* Now update anything that could cause an interrupt, so we
		 * can catch it in the next cycle */

		/* Call this, which will call an update
		 * for things like the UARTs and Timers */
		skyeye_config.mach->mach_io_do_cycle (&memory_core);
	}
}
static void coldfire_set_pc(WORD addr){
	memory_core.pc = addr; 
}
static WORD coldfire_get_pc(){
	return (WORD)memory_core.pc;
}
//chy 2006-04-14 maybe changed in the future !!!???
static int
coldfire_ICE_write_byte (WORD addr, uint8_t v)
{
	Memory_StorByte(addr,v);
	return 0;
}
static int 
coldfire_ICE_read_byte(WORD addr, uint8_t *pv){
	unsigned int v;
	int res;
	res = Memory_RetrByte(&v, addr);
	if (res == 1){ //success
		*pv=(unsigned char)v;
		return 0; //fault=0
	}else{
		return 1;//fault=1
	}
}
static int
coldfire_parse_cpu (cpu_config_t * cpu, const char *param[])
{
}

extern void mcf5249_mach_init(void * state, machine_config_t * mach);
extern void mcf5272_mach_init(void * state, machine_config_t * mach);

machine_config_t coldfire_machines[] = {
	{"mcf5249", mcf5249_mach_init, NULL, NULL, NULL},
	{"mcf5272", mcf5272_mach_init, NULL, NULL, NULL},
	{NULL, NULL, NULL, NULL, NULL},
};


static int
coldfire_parse_mach (machine_config_t * cpu, const char *params[])
{
	int i;
	for (i = 0; i < (sizeof (coldfire_machines) / sizeof (machine_config_t));
	     i++) {
		if (!strncmp
		    (params[0], coldfire_machines[i].machine_name,
		     MAX_PARAM_NAME)) {
			skyeye_config.mach = &coldfire_machines[i];
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

static int coldfire_parse_mem(int num_params, const char *params[]){
	//memory_module_setup_segment("ram",0,0x0,0x400000);	
}

void init_coldfire_arch(){
	static arch_config_t coldfire_arch;

	coldfire_arch.arch_name = "coldfire";
        //coldfire_arch.pc = 0;
        coldfire_arch.init = coldfire_init_state;
        coldfire_arch.reset = coldfire_reset_state;
        coldfire_arch.set_pc = coldfire_set_pc;
	coldfire_arch.get_pc = coldfire_get_pc;
        coldfire_arch.step_once = coldfire_step_once;
        coldfire_arch.ICE_write_byte = coldfire_ICE_write_byte;
	coldfire_arch.ICE_read_byte = coldfire_ICE_read_byte;
        coldfire_arch.parse_cpu = coldfire_parse_cpu;
        coldfire_arch.parse_mach = coldfire_parse_mach;
        coldfire_arch.parse_mem = NULL;

        register_arch (&coldfire_arch);
}
