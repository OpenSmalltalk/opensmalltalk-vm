/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* DC.W  */
/* Format ... well.. anything that any of the other instructions
   don't handle
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/


INSTRUCTION_1ARG(DC,
	unsigned Code1,16);

static void execute(void)
{
	unsigned int dummy;
	/* Read the instruction, we already know what it is */
	Memory_RetrWordFromPC(&dummy);
	/* Do an exception */
	//exception_do_exception(4);
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	unsigned int dummy;
	Memory_RetrWordFromPC(&dummy);
	sprintf(Instruction, "DC.W");
	sprintf(Arg1, "0x%04lx", dummy);
	Arg2[0]=0;
	return 0;
}


int dc_5206_register(void)
{
	instruction_register(0x0000, 0x0000, &execute, &disassemble);
	return 0;
}
