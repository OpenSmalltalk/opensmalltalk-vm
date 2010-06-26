/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* EORI Immediate (EORI) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int EORITime=1;


INSTRUCTION_2ARGS(EORI,
	unsigned Code1,13,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	EORI_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, 7, 4)) return;
	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;

	EA_GetValue(&SValue, &Source);
	EA_GetValue(&DValue, &Destination);

	Result = SValue ^ DValue;


	EA_PutValue(&Destination, Result);

	/* Set the status register
	 *  X - not affected
	 *  N - set if MSB or result is 1
	 *  Z - set if result is zero
	 *  V,C always cleared
	 */
	memory_core.sr &= 0xFFF0;
	SRBits->N = ((int)Result < 0);
	SRBits->Z = (Result == 0);
				 
	cycle(EORITime);
					 
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	EORI_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "EORI.L");
	Addressing_Print(32, 7, 4, Arg1);
	Addressing_Print(32, 0, Instr.Bits.Register, Arg2);
	return 0;
}

int eori_5206_register(void)
{
	instruction_register(0x0A80, 0xFFF8, &execute, &disassemble);
	return 1;
}
