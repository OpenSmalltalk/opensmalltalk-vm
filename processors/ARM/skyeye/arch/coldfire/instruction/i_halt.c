/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* HALT instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 0 | 1 | 0 | 1 | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int HALTTime=7;  /* minimum time to halt per Sue Cozart */


INSTRUCTION_1ARG(HALT,
	unsigned Code,16);

static void execute(void)
{
	HALT_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(SRBits->S) {
		/* Supervisor State */
		SKYEYE_ERR("Halting the processor:\n");
		return;
	} else {
		/* User state */
		/* FIXME: Generate an exception violation here */
	}

	cycle(HALTTime);
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	HALT_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "HALT");

	Arg1[0]=0;
	Arg2[0]=0;

	return 0;
}

int halt_5206_register(void)
{
	instruction_register(0x4AC8, 0xFFFF, &execute, &disassemble);
	return 1;
}
