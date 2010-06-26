/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Link and Allocate (LINK) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 0 | 1 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                          Displacement                         |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int LINKTime=2;


INSTRUCTION_2ARGS(LINK,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	unsigned int Displacement;
	struct _Address ARegister,Stack;
	unsigned int StackValue;
	LINK_Instr Instr;

	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&Displacement);
	Displacement = (short)Displacement;

	/* Get the A register, and push it to the stack */
	if(!EA_GetFromPC(&ARegister, 32, 1, Instr.Bits.Register)) return;
	EA_GetValue(&StackValue, &ARegister);
	Stack_Push(32,StackValue);

	/* Now store the stack pointer in the register before modifying it */
	if(!EA_GetFromPC(&Stack, 32, 1, 7)) return;
	EA_GetValue(&StackValue, &Stack);
	EA_PutValue(&ARegister, StackValue);

	/* Move the stack pointer Displacement bytes */
	/* The displacement will be -ve, causes the SP to move
            down */
	EA_PutValue(&Stack, StackValue + Displacement);

	
	cycle(LINKTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	LINK_Instr Instr;
	unsigned int Displacement;
	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&Displacement);

	sprintf(Instruction, "LINK");
	Addressing_Print(32, 1, Instr.Bits.Register, Arg1);
	/* Print manually because it uses negative numbers */
	sprintf(Arg2, "#%hd", (short)Displacement);

	return 0;
}

int link_5206_register(void)
{
	instruction_register(0x4E50, 0xFFF8, &execute, &disassemble);
	return 1;
}
