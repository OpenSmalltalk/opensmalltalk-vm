/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

/* FIXME: Unverified correct operation */
#include "coldfire.h"

/* Stop (STOP) instruction */
/* MHM July 13, 2000 */
/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int STOPTime=3;


INSTRUCTION_1ARG(STOP,
	unsigned Code1,16);

static void execute(void)
{
	struct _Address Source;
	unsigned int Result, SValue;
	STOP_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 16, 7, 4)) return;
	EA_GetValue(&SValue, &Source);

	Result = SValue;



	/* Set the status register */
	memory_core.sr=Result;  /* Not quite finished yet */

	
	cycle(STOPTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	STOP_Instr Instr;
	unsigned int SValue;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "STOP");
	Memory_RetrWordFromPC(&SValue);
	sprintf(Arg1, "#$%08lx", SValue);
	Arg2[0]=0;
	/* Addressing_Print(32, 0, Instr.Bits.Register, Arg2); */
	return 0;
}

int stop_5206_register(void)
{
	instruction_register(0x4E72, 0xFFFF, &execute, &disassemble);
	return 1;
}
