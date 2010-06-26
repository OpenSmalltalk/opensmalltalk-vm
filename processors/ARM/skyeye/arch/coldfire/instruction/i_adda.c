/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Add instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 1 | 1 | 0 | 1 | Register  | 1 | 1 | 1 |  EA Mode  |EA Register|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int ADDATime[]={-1, 3, 3, 3, 3, 4, 3, -1 };


INSTRUCTION_5ARGS(ADDA,
	unsigned Code2,4,
	unsigned Register,3,
	unsigned Code1,3,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	ADDA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	if(!EA_GetFromPC(&Destination, 32, 1, Instr.Bits.Register)) return;

	EA_GetValue(&SValue, &Source);
	EA_GetValue(&DValue, &Destination);

	Result = SValue + DValue;


	/* Status register is not affected */

	EA_PutValue(&Destination, Result);

	cycle(ADDATime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	ADDA_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "ADDA.L");
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Addressing_Print(32, 1, Instr.Bits.Register, Arg2);
	return 0;
}

int adda_5206_register(void)
{
	instruction_register(0xD1C0, 0xF1C0, &execute, &disassemble);
	return 1;
}
