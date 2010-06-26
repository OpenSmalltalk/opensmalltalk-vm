/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Unlink (UNLK) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 0 | 1 | 1 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int UNLKTime=2;


INSTRUCTION_2ARGS(UNLK,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	struct _Address ARegister,Stack;
	unsigned int Result;
	
	UNLK_Instr Instr;

	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&ARegister, 32, 1, Instr.Bits.Register)) return;
	if(!EA_GetFromPC(&Stack, 32, 1, 7)) return;
	
	/* Load the stack pointer from the A register */
	EA_GetValue(&Result, &ARegister);
	EA_PutValue(&Stack, Result);

	/* Now pop a longword from the stack and set that to be the 
            A register */
	Result = Stack_Pop(32);
	EA_PutValue(&ARegister, Result);

	
	cycle(UNLKTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	UNLK_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "UNLK");
	Addressing_Print(32, 1, Instr.Bits.Register, Arg1);
	Arg2[0]=0;

	return 0;
}

int unlk_5206_register(void)
{
	instruction_register(0x4E58, 0xFFF8, &execute, &disassemble);
	return 1;
}
