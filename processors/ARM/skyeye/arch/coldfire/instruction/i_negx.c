/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Negate with Excend (NEGX) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int NEGXTime=1;


INSTRUCTION_2ARGS(NEGX,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Destination;
	unsigned int Result, DValue;
	NEGX_Instr Instr;

	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;
	EA_GetValue(&DValue, &Destination);

	Result = 0 - DValue - (unsigned int)SRBits->X;


	SR_Set(I_NEGX, 0, DValue, Result);

	EA_PutValue(&Destination, Result);

	cycle(NEGXTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	NEGX_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "NEGX.L");
	Addressing_Print(32, 0, Instr.Bits.Register, Arg1);
	Arg2[0]=0;
	return 0;
}

int negx_5206_register(void)
{
	instruction_register(0x4080, 0xFFF8, &execute, &disassemble);
	return 1;
}
