/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Load Effective Address (lea) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | ARegister | 1 | 1 | 1 |  EAMode   | EARegister|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int LEATime[8]={-1, 1, -1, -1, 1, 2, 1, -1};


INSTRUCTION_5ARGS(LEA,
	unsigned Code2,4,
	unsigned Register,3,
	unsigned Code1,3,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int SValue;
	LEA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	if(!EA_GetFromPC(&Destination, 32, 1, Instr.Bits.Register)) return;

	EA_GetEA(&SValue, &Source);


	/* Condition codes are not affected */

	EA_PutValue(&Destination, SValue);

	
	cycle(LEATime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	LEA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "LEA");
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Addressing_Print(32, 1, Instr.Bits.Register, Arg2);
	return 0;
}

int lea_5206_register(void)
{
	instruction_register(0x41C0, 0xF1C0, &execute, &disassemble);
	return 1;
}
