/*

		THIS SOFTWARE IS NOT COPYRIGHTED

   Cygnus offers the following for use in the public domain.  Cygnus
   makes no warranty with regard to the software or it's performance
   and the user accepts the software "AS IS" with all faults.

   CYGNUS DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD TO
   THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

*/
/*
 *  written by Michael.Kang
 */

#ifdef __MINGW32__
#include <windows.h>
#endif

#include <signal.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "bfin-sim.h"
#include "mem_map.h"
#include "skyeye_types.h"
#include "skyeye_config.h"
//#include "bfin_defs.h"

#define NONCACHE  0

saved_state_type saved_state;
static char * arch_name = "blackfin";
static void
sim_size ()
{
	if (!saved_state.memory)
		saved_state.memory = (unsigned char *) malloc (SDRAM_SIZE);
	if (!saved_state.dsram)
		saved_state.dsram = (unsigned char *) malloc (DSRAM_SIZE);
	if (!saved_state.isram)
		saved_state.isram = (unsigned char *) malloc (ISRAM_SIZE);
	// PSW 061606
	if (!saved_state.ssram)
		saved_state.ssram = (unsigned char *) malloc (SSRAM_SIZE);
	if (!saved_state.memory) {
		fprintf (stderr, "Not enough VM for simulation of RAM\n");
	}
}


void
bfin_init_state ()
{
	/*
	mach_t *p_mach;
	printf ("begin init emulator()\n");
	p_mach = malloc (sizeof (mach_t));
	init_bf533_mach (p_mach);*/
	/*malloc memory */
	sim_size ();

	/*mach init */
        skyeye_config.mach->mach_init (&saved_state, skyeye_config.mach);

	//saved_state.p_mach = p_mach;
}
void
bfin_reset_state ()
{
	/*fixme */
	saved_state.usp = 0x1000000;
	SPREG = saved_state.usp;
	saved_state.pc = 0x0;
}

/* Set by an instruction emulation function if we performed a jump.  */
int did_jump;

int raise_flag ;
static tmp_flag = 0;
/* Execute a single instruction.  */
static void
bfin_step_once ()
{
	OLDERPCREG = OLDPCREG;
	OLDPCREG = PCREG;


	did_jump = 0;
	
	interp_insn_bfin (PCREG);
	/* @@@ Not sure how the hardware really behaves when the last insn
	   of a loop is a jump.  */
	if (!did_jump) {
		if (LC1REG && OLDPCREG == LB1REG && --LC1REG)
			PCREG = LT1REG;
		else if (LC0REG && OLDPCREG == LB0REG && --LC0REG)
			PCREG = LT0REG;
	}

	if(raise_flag > 0)	
		raise_flag = 0;
	else
		skyeye_config.mach->mach_io_do_cycle (&saved_state);
}
static void
bfin_set_pc (WORD addr)
{
	PCREG = (bu32) addr;
}
static WORD bfin_get_pc(){
	return PCREG;
}
cpu_config_t bfin_cpu[] = {
	{"bf533", "bf533", 0xffffffff, 0xfffffff0, NONCACHE}
	,
	{NULL,NULL,0,0,0}
};
//chy 2006-04-15
static int 
bfin_ICE_write_byte (WORD addr, uint8_t v)
{
	put_byte (saved_state.memory, addr, (bu8) v);
	return 0;
}
static int
bfin_ICE_read_byte(WORD addr, uint8_t * pv){
	*pv = (unsigned char)get_byte(saved_state.memory, addr);
	return 0;
}
static int
bfin_parse_cpu (cpu_config_t * cpu, const char *param[])
{
}

extern void bf533_mach_init(void * state, machine_config_t * mach);
extern void bf537_mach_init(void * state, machine_config_t * mach);

machine_config_t bfin_machines[] = {
	{"bf533", bf533_mach_init, NULL, NULL, NULL},
	{"bf537", bf537_mach_init, NULL, NULL, NULL},
	{NULL, NULL, NULL, NULL, NULL},
};


static int
bfin_parse_mach (machine_config_t * cpu, const char *params[])
{
	int i;
	for (i = 0; i < (sizeof (bfin_machines) / sizeof (machine_config_t));
	     i++) {
		if (!strncmp
		    (params[0], bfin_machines[i].machine_name,
		     MAX_PARAM_NAME)) {
			skyeye_config.mach = &bfin_machines[i];
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
bfin_parse_mem(int num_params, const char* params[])
{
#if 0
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, num;
	bfin_mem_config_t *mc = &bfin_mem_config;
	bfin_mem_bank_t *mb = mc->mem_banks;

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
				mb[num].read_byte = bfin_real_read_byte;
				mb[num].write_byte = bfin_real_write_byte;
				mb[num].read_halfword = bfin_real_read_halfword;
				mb[num].write_halfword = bfin_real_write_halfword;
				mb[num].read_word = bfin_real_read_word;
				mb[num].write_word = bfin_real_write_word;
				mb[num].read_doubleword = bfin_real_read_doubleword;
				mb[num].write_doubleword = bfin_real_write_doubleword;
				mb[num].type = MEMTYPE_RAM;
			}
			else if (!strncmp ("I", value, strlen (value))) {
				mb[num].read_byte = bfin_io_read_byte;
				mb[num].write_byte = bfin_io_write_byte;
				mb[num].read_halfword = bfin_io_read_halfword;
				mb[num].write_halfword = bfin_io_write_halfword;
				mb[num].read_word = bfin_io_read_word;
				mb[num].write_word = bfin_io_write_word;
				mb[num].read_doubleword = bfin_io_read_doubleword;
				mb[num].write_doubleword = bfin_io_write_doubleword;

				mb[num].type = MEMTYPE_IO;

				/*ywc 2005-03-30 */
			}
			else if (!strncmp ("F", value, strlen (value))) {
				mb[num].read_byte = bfin_flash_read_byte;
				mb[num].write_byte = bfin_flash_write_byte;
				mb[num].read_halfword = bfin_flash_read_halfword;
				mb[num].write_halfword = bfin_flash_write_halfword;
				mb[num].read_word = bfin_flash_read_word;
				mb[num].write_word = bfin_flash_write_word;
				mb[num].read_doubleword = bfin_flash_read_doubleword;
				mb[num].write_doubleword = bfin_flash_write_doubleword;
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
				mb[num].write_byte = bfin_warn_write_byte;
				mb[num].write_halfword = bfin_warn_write_halfword;
				mb[num].write_word = bfin_warn_write_word;
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
#endif
	return 0;
}


void
init_bfin_arch ()
{
	static arch_config_t bfin_arch;

	bfin_arch.arch_name = arch_name;
	bfin_arch.init = bfin_init_state;
	bfin_arch.reset = bfin_reset_state;
	bfin_arch.step_once = bfin_step_once;
	bfin_arch.set_pc = bfin_set_pc;
	bfin_arch.get_pc = bfin_get_pc;
	bfin_arch.ICE_write_byte = bfin_ICE_write_byte;
	bfin_arch.ICE_read_byte = bfin_ICE_read_byte;
	bfin_arch.parse_cpu = bfin_parse_cpu;
	bfin_arch.parse_mach = bfin_parse_mach;
	bfin_arch.parse_mem = bfin_parse_mem;

	register_arch (&bfin_arch);
}
