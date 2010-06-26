/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Generate Illegal Instruction (ILLEGAL)  */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 0 | 1 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/


INSTRUCTION_1ARG(ILLEGAL,
	unsigned Code,16);

static void execute(void)
{
	unsigned int dummy;
	/* Read the instruction with out storing it.. we already know what it is */
	Memory_RetrWordFromPC(&dummy);
	exception_do_exception(4);

	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	unsigned int dummy;
	Memory_RetrWordFromPC(&dummy);
	sprintf(Instruction, "ILLEGAL");
	Arg1[0]=0;
	Arg2[0]=0;
	return 0;
}


int illegal_5206_register(void)
{
	instruction_register(0x4AFC, 0xFFFF, &execute, &disassemble);
	return 1;
}
