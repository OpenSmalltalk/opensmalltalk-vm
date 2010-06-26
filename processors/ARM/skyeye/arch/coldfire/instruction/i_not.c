/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* NOT instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0   1   1   0   1   0   0   0   0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int NOTTime=1;


INSTRUCTION_2ARGS(NOT,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Destination;
	unsigned int Result, DValue;
	NOT_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;
	EA_GetValue(&DValue, &Destination);

	Result = ~DValue;

	/* Set the status register */
	memory_core.sr &= 0xFFF0;
	SRBits->N = ((int)Result < 0);
	SRBits->Z = (Result == 0);

	EA_PutValue(&Destination, Result);

	
	cycle(NOTTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	NOT_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "NOT.L");
	Addressing_Print(32, 0, Instr.Bits.Register, Arg1);
	Arg2[0]=0;
 	return 0;

}

int not_5206_register(void)
{
	instruction_register(0x4680, 0xFFF8, &execute, &disassemble);
	return 1;
}
