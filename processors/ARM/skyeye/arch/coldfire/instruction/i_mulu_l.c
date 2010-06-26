/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Long Unsigned multiply (MULU.L) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |  EA Mode  |EA Register|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | Register  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int MULLTime[8]={18, 20, 20, 20, 20, -1, -1, -1};


INSTRUCTION_3ARGS(MULU_L,
	unsigned Code1,10,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void) 
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	char Register;
	unsigned int Instr2;
	MULU_L_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&Instr2);
	Register=(Instr2 & 0x7000) >> 12;


	if(Instr.Bits.EAMode==1) {
		SKYEYE_ERR("May Not specify Address Register (Ay) for MULU.L");
		return;
	} else if(Instr.Bits.EAMode==7) {
		SKYEYE_ERR("May Not specify Direct Addressing for MULU.L");
		return;
	}
	if(!EA_GetFromPC(&Source, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	if(!EA_GetFromPC(&Destination, 32, 0, Register)) return;

	EA_GetValue(&SValue, &Source);
	EA_GetValue(&DValue, &Destination);

	/* FIXME: I'm not sure if this discards the upper 32 bits (as 
		required in the spec) or if it does something FuNkY */
	
	if(Instr2 & 0x0800) {
		/* Signed multiply */
		Result = (int)(SValue) * (int)(DValue);
	} else {
		/* Unsigned multiply */
		Result = (unsigned int)(SValue) * (unsigned int)(DValue);
	}


	/* Set the status register */
	memory_core.sr &= 0xFFF0;
	SRBits->N = ((int)Result < 0);
	SRBits->Z = (Result == 0);

	EA_PutValue(&Destination, Result);

	
	cycle(MULLTime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	unsigned int Instr2;
	char Register;
	MULU_L_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&Instr2);
	Register=(Instr2 & 0x7000) >> 12;

	sprintf(Instruction, "MUL%c.L", (Instr2 & 0x0800) ? 'S' : 'U');
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Addressing_Print(32, 0, Register, Arg2);
	return 0;
}

int mulu_l_5206_register(void)
{
	instruction_register(0x4C00, 0xFFC0, &execute, &disassemble);
	return 2;
}
