/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Clear (CLR) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | Size  | EAMode    |EARegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int CLRTime[8]={ 1, 1, 1, 1, 1, 2, 1, -1};


INSTRUCTION_4ARGS(CLR,
	unsigned Code1,8,
	unsigned Size,2,
	unsigned EAMode,3,
	unsigned EARegister,3);

const short CLR_SizeBits[4]={ 8 ,  16 , 32 , 0 }; 
const char  CLR_SizeStr[4]= {'B', 'W', 'L', '?'};

static void execute(void)
{
	struct _Address Destination;
	CLR_Instr Instr;
	
	Memory_RetrWordFromPC(&Instr.Code);


	if(Instr.Bits.Size == 3) {
		SKYEYE_ERR("Invalid size=3", memory_core.pc);
		return;
	}

	if(!EA_GetFromPC(&Destination, CLR_SizeBits[(short)Instr.Bits.Size], Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_PutValue(&Destination, 0);

	/* X - Not affected
	   N - Always Cleared
	   Z - Always Set
	   V - Always Cleared
	   C - Always Cleared
	*/
	SRBits->N=0;
	SRBits->Z=1;
	SRBits->V=0;
	SRBits->C=0;
	cycle(CLRTime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	CLR_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "CLR.%c", CLR_SizeStr[(short)Instr.Bits.Size]);

	Addressing_Print(CLR_SizeBits[(short)Instr.Bits.Size], Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Arg2[0]=0;

	return 0;
}

int clr_5206_register(void)
{
	instruction_register(0x4200, 0xFF00, &execute, &disassemble);
	return 1;
}
