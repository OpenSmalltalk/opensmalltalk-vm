/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Test (TST) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 0 | 1 | 0 | Size  |  EAMode   |EARegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int TSTTime[8]={1, 3, 3, 3, 3, 4, 3, 1};


INSTRUCTION_4ARGS(TST,
	unsigned Code1,8,
	unsigned Size,2,
	unsigned EAMode,3,
	unsigned EARegister,3);

const short TST_SizeBits[4]={ 8 , 16 , 32 , 0  }; 
const char  TST_SizeStr[4]= {'B', 'W', 'L', '?'};

static void execute(void)
{
	struct _Address Source;
	unsigned int SValue;
	TST_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.Size == 3) {
		SKYEYE_ERR("Invalid size=3");
		return;
	}
	if(!EA_GetFromPC(&Source, TST_SizeBits[(short)Instr.Bits.Size], 
		Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_GetValue(&SValue, &Source);


	/* Set the status register;
	 *  X - Not affected
	 *  N - Set if source is -ve, cleared otherwise
	 *  Z - Set if source is zero, cleared otherwise
	 *  V - always cleared
	 *  C - always cleared
	 */
	SRBits->N = ((int)SValue < 0);
	SRBits->Z = (SValue == 0);
	SRBits->V = 0;
	SRBits->C = 0;
	
	
	cycle(TSTTime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	TST_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "TST.%c", TST_SizeStr[(short)Instr.Bits.Size]);

	Addressing_Print(TST_SizeBits[(short)Instr.Bits.Size], 
		Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);

	Arg2[0]=0;
	return 0;
}

int tst_5206_register(void)
{
	/* This needs to be 3 registers, 4A[11xx]x is taken (ILLEGAL) :( */
	instruction_register(0x4A00, 0xFFC0, &execute, &disassemble);
	instruction_register(0x4A40, 0xFFC0, &execute, &disassemble);
	instruction_register(0x4A80, 0xFFC0, &execute, &disassemble);
	return 1;
}
