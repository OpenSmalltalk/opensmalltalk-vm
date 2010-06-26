/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Move instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | Size  | DRegister |  DMode    |  SMode    | SRegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+


   If the destination is an address register, then the condition codes
    are unaffected, and MOVEA designates this 
*/


INSTRUCTION_6ARGS(MOVE,
	unsigned Code1,2,
	unsigned Size,2,
	unsigned DestRegister,3,
	unsigned DestMode,3,
	unsigned SourceMode,3,
	unsigned SourceRegister,3);

const short MOVE_SizeBits[4]={ 0 ,  8 , 32 , 16 }; 
const char  MOVE_SizeStr[4]= {'?', 'B', 'L', 'W'};

int MOVE816Time[][7]= {	{1,1,1,1,1,2,1},
			{1,1,1,1,1,2,1},
			{3,3,3,3,3,4,3},
			{3,3,3,3,3,4,3},
			{3,3,3,3,3,4,3},
			{3,3,3,3,3,-1,-1},
			{4,4,4,4,-1,-1,-1},
			{3,3,3,3,-1,-1,-1},
			{3,3,3,3,-1,-1,-1},
			{3,3,3,3,3,-1,-1},
			{4,4,4,4,-1,-1,-1},
			{1,3,3,3,-1,-1,-1}
			};
		
int MOVE32Time[][7]= {	{1,1,1,1,1,2,1},
			{1,1,1,1,1,2,1},
			{2,2,2,2,2,3,2},
			{2,2,2,2,2,3,2},
			{2,2,2,2,2,3,2},
			{2,2,2,2,2,-1,-1},
			{3,3,3,3,-1,-1,-1},
			{2,2,2,2,-1,-1,-1},
			{2,2,2,2,-1,-1,-1},
			{2,2,2,2,2,-1,-1},
			{3,3,3,3,-1,-1,-1},
			{1,2,2,2,-1,-1,-1}
			};	


static void execute(void)
{
	struct _Address Source, Destination;
	unsigned int SValue;
	int cycle_source_ea=0, cycle_destination_ea=0;
	MOVE_Instr Instr;

	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.Size==0) {
		SKYEYE_ERR("Invalid size in instruction, size=0\n");
		return;
	}

	if(!EA_GetFromPC(&Source, MOVE_SizeBits[(short)Instr.Bits.Size], 
		Instr.Bits.SourceMode, Instr.Bits.SourceRegister)) return;
	EA_GetValue(&SValue, &Source);

	if(!EA_GetFromPC(&Destination, MOVE_SizeBits[(short)Instr.Bits.Size], 
		Instr.Bits.DestMode, Instr.Bits.DestRegister)) return;

	EA_PutValue(&Destination, SValue);

	/* 	X - not affected
		N - set if result is -ve, cleared otherwise
		Z - set if result is zero, cleared otherwise
		V - always cleared
		C - always cleared */
		/* Set the status register */
	if(Instr.Bits.DestMode != 1) {
		/* MOVE */
		memory_core.sr &= 0xFFF0;
		SRBits->N = ((int)SValue < 0);
		SRBits->Z = (SValue == 0);
	} else {
		/* MOVEA */
		/* Destination is an address register, codes are unaffected */
	}

	/* Do cycle counting */
	cycle_source_ea = cycle_EA(Instr.Bits.SourceRegister, Instr.Bits.SourceMode);
	cycle_destination_ea = cycle_EA(Instr.Bits.DestRegister, Instr.Bits.DestMode);

	if(Instr.Bits.Size == 0x02) /* 32 bit */
		cycle(MOVE32Time[cycle_source_ea][cycle_destination_ea]);
	else
		cycle(MOVE816Time[cycle_source_ea][cycle_destination_ea]);


	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	MOVE_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	/* If dest is 'A' an size is (2) == 32 bit or (3)==16 bit, 
	 * then it's actually a MOVEA.L/W instruction */
	if(Instr.Bits.DestMode == 1 && Instr.Bits.Size >= 2)
		sprintf(Instruction, "MOVEA.%c", MOVE_SizeStr[(short)Instr.Bits.Size]);
	else
		sprintf(Instruction, "MOVE.%c", MOVE_SizeStr[(short)Instr.Bits.Size]);

	Addressing_Print(MOVE_SizeBits[(short)Instr.Bits.Size], 
			Instr.Bits.SourceMode, Instr.Bits.SourceRegister, Arg1);

	Addressing_Print(MOVE_SizeBits[(short)Instr.Bits.Size], 
			Instr.Bits.DestMode, Instr.Bits.DestRegister, Arg2);
	return 0;
}

int move_5206_register(void)
{
	/* Register once for each size, we don't want to decode an instruction
	 * where the size specifier turns out to be 00 */
	instruction_register(0x1000, 0xF000, &execute, &disassemble);
	instruction_register(0x2000, 0xF000, &execute, &disassemble);
	instruction_register(0x3000, 0xF000, &execute, &disassemble);
	instruction_register(0x3000, 0xF000, &execute, &disassemble);
	return 1;
}
