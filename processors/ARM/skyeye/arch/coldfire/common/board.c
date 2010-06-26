#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "coldfire.h"

/* Arnewsh memory map */
/* $00000000 - $01FFFFFF DRAM
 * $10000000 - $100003FF Internal module registers
 * $20000000 - $200001FF Internal SRAM
 * $30000000 - $300FFFFF 1Meg space for MC68HC901
 * $40000000 - $400FFFFF 1Meg ISA bus area
 * $FFE00000 - $FFE3FFFF 256K flash rom */

static const char *arnewsh_config_data = 
"board		\"Arnewsh\"\n"
"cpu		\"5206\"\n"
"\n"
"; DRAM is most likely to be accessed\n"
"ram		name=\"dram\", base=0x0, len=0x00400000\n"
"\n"
"; Default core register values\n"
"reg		VBR=0x0\n"
"reg		MBAR=0x10000000\n"
"reg		RAMBAR=0x20000000\n"
"reg		ROMBAR=0xFFE00000\n"
"reg		PC=0xFFE00000\n"
"reg		SP=0x00400000\n"
"reg		SR=0x2000\n"
"\n"
"; Then the SIM, the sim_init initializes the entire sim region, \n"
";  so the timer and uart need to go first else we'll never send \n"
";  read/writes into them \n"
"; We also don't need the lengths, the modules know how long they are\n"
"timer_5206	name=\"timer1\", base=MBAR+0x100, int=9\n"
"timer_5206	name=\"timer2\", base=MBAR+0x120, int=10\n"
"uart_5206	name=\"uart1\", base=MBAR+0x140, int=12\n"
"uart_5206	name=\"uart2\", base=MBAR+0x180, int=13, code=00\n"
"sim_5206	name=\"sim\", base=MBAR+0x0\n"
"\n"
"; Least likely to be accessed\n"
"dummy		name=ne2000, base=0x40000300, len=0x0100\n"
"dummy		name=isa, base=0x40000000, len=0x00100000\n"
"rom		name=rom, base=ROMBAR+0x0, len=0x00040000, \\\n"
"			code=70004e4f\n"
"ram 		name=sram, base=RAMBAR+0x0, len=0x00000100\n";

struct _board_data board_data;

struct _board_data *board_get_data(void) 
{
	return &board_data;
}

void board_init(void)
{
	/* Setup global board data */
	memset(&board_data, 0, sizeof(struct _board_data));
	/* Set some defaults */
	board_data.clock_speed = 25000000;
	board_data.cycle_count = 0;
	board_data.use_timer_hack = 0;
	board_data.trace_run = 0;
	board_data.cpu = CF_NULL;
}

void board_reset(void)
{
	board_data.cycle_count = 0;
	memory_reset();
}

void board_fini(void)
{
}
	

void board_do_config(char *config_data)
{
	char *ptr = config_data;
	char *next_ptr, *tmp_ptr;
	int argc;
	char *argv[3];
	int num_memory_segments=0;
/*	printf("[%s]\n", config_data);*/
	printf("\n");
		
}

void board_setup(char *file) 
{
}
