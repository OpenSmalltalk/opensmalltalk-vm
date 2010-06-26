/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Push Effective Address (pea) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 1 |  EAMode   | EARegister|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int PEATime[8]={-1, 2, -1, -1, 2, 3, 2, -1};


INSTRUCTION_3ARGS(PEA,
	unsigned Code1,10,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void)
{
	struct _Address Source;
	unsigned int SValue;
	PEA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	/* Retrive the effective address, not the value that the EA points to */
	if(!EA_GetFromPC(&Source, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_GetEA(&SValue, &Source);
	Stack_Push(32,SValue);


	cycle(PEATime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	PEA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "PEA");
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Arg2[0]=0;
	return 0;
}

int pea_5206_register(void)
{
	instruction_register(0x4840, 0xFFC0, &execute, &disassemble);
	return 1;
}
