/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Subtract Immediate (SUBI) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|               Upper Word of Immediate Data                    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|               Lower Word of Immediate Data                    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int SUBITime=1;


INSTRUCTION_2ARGS(SUBI,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	SUBI_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, 7, 4)) return;
	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;

	EA_GetValue(&SValue, &Source);
	EA_GetValue(&DValue, &Destination);

	Result = DValue - SValue;


	/* Set the status register */
	SR_Set(I_SUBI, SValue, DValue, Result);

	EA_PutValue(&Destination, Result);


	cycle(SUBITime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	SUBI_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "SUBI.L");
	Addressing_Print(32, 7, 4, Arg1);
	Addressing_Print(32, 0, Instr.Bits.Register, Arg2);
	return 0;
}

int subi_5206_register(void)
{
	instruction_register(0x0480, 0xFFF8, &execute, &disassemble);
	return 1;
}
