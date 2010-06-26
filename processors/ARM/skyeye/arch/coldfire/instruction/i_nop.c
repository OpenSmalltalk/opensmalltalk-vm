/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* No Operation (NOP)  */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int NOPTime=3;


INSTRUCTION_1ARG(NOP,
	unsigned Code1,16);

static void execute(void)
{
	unsigned int dummy;
	/* Read the instruction with out storing it.. we already know what it is */
	Memory_RetrWordFromPC(&dummy);


	cycle(NOPTime);  /* Everything takes some time...*/
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	unsigned int dummy;
	Memory_RetrWordFromPC(&dummy);
	sprintf(Instruction, "NOP");
	Arg1[0]=0;
	Arg2[0]=0;
	return 0;
}


int nop_5206_register(void)
{
	instruction_register(0x4E71, 0xFFFF, &execute, &disassemble);
	return 1;
}
