/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Compare (CMP) instruction */

/* Format 

CMP   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 1 | 0 | 1 | 1 | Register  | 0 | 1 | 0 |  EAMode   |EARegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+


*/

int CMPTime[8]={ 1, 3, 3, 3, 3, 4, 3, 1};


INSTRUCTION_5ARGS(CMP,
	unsigned Code2,4,
	unsigned Register,3,
	unsigned Code1,3,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	CMP_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	
	if(!EA_GetFromPC(&Source, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;

	EA_GetValue(&SValue, &Source);
	EA_GetValue(&DValue, &Destination);


	Result = DValue - SValue;

	SR_Set(I_CMP, SValue, DValue, Result);

	cycle(CMPTime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	CMP_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "CMP.L");
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Addressing_Print(32, 0, Instr.Bits.Register, Arg2);
	return 0;
}

int cmp_5206_register(void)
{
	instruction_register(0xB080, 0xF1C0, &execute, &disassemble);
	return 1;
}
