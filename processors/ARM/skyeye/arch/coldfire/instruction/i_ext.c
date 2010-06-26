/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Sign Extend (EXT,EXTB) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 0 | 0 |  OPmode   | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int EXTTime=1;



INSTRUCTION_4ARGS(EXT,
	unsigned Code2,7,
	unsigned OPMode,3,
	unsigned Code1,3,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int SValue, Result;
	EXT_Instr Instr;

	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, 0, Instr.Bits.Register)) return;
	EA_GetValue(&SValue, &Source);
	
	if(Instr.Bits.OPMode==2) { /* Byte -> Word */
		if(!EA_GetFromPC(&Destination, 16, 0, Instr.Bits.Register)) return;
		Result=(char)SValue;
	} else if(Instr.Bits.OPMode==3) { /* Word -> Long */
		if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;
		Result=(short)SValue;
		EA_PutValue(&Destination, (short)SValue);
	} else if(Instr.Bits.OPMode==7) { /* Byte -> Long */
		if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;
		Result=(char)SValue;
	} else {
		SKYEYE_ERR("Unknown opmode %d\n", Instr.Bits.OPMode);
		return;
	}

	EA_PutValue(&Destination, Result);
	
	/* Set the status register;
	 *  X - Not affected
	 *  N - Set if result is -ve, cleared otherwise
	 *  Z - Set if result is zero, cleared otherwise
	 *  V - always cleared
	 *  C - always cleared
	 */
	memory_core.sr &= 0xFFF0;
	SRBits->N = ((int)Result < 0);
	SRBits->Z = (Result == 0);

	cycle(EXTTime);

	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	EXT_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.OPMode==2) { /* Byte -> Word */
		sprintf(Instruction, "EXT.W");
	} else if(Instr.Bits.OPMode==3) { /* Word -> Long */
		sprintf(Instruction, "EXT.L");
	} else if(Instr.Bits.OPMode==7) { /* Byte -> Long */
		sprintf(Instruction, "EXTB.L");
	} else {
		SKYEYE_ERR("Unknown opmode\n");
	}

	Addressing_Print(32, 0, Instr.Bits.Register, Arg1);
	Arg2[0]=0;
	return 0;
}

int ext_5206_register(void)
{
	instruction_register(0x4800, 0xFE38, &execute, &disassemble);
	instruction_register(0x4800, 0xFE38, &execute, &disassemble);
	return 2;
}
