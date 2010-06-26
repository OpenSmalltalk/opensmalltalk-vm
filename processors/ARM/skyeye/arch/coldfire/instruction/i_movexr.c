/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* MOVE to SR instruction
 * MOVE from SR instruction
 * MOVE to CCR instruction
 * MOVE from CCR instruction */


/*    
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
MOVE to SR:
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 1 | 1 | 0 | 1 | 1 |   Mode    |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
MOVE from SR:
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
MOVE to CCR:
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 1 |   Mode    |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
MOVE from CCR:
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 1 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+


*/


INSTRUCTION_6ARGS(MOVEXR,
	unsigned Code2,5,
	unsigned To,1,
	unsigned Reg,1,
	unsigned Code1,3,
	unsigned Mode,3,
	unsigned Register,3);

int MOVE2SRTime=1;	/* Add +6 for non immediate EA */
int MOVEXRTime=1;  

static void execute(void)
{
	struct _Address Source;
	unsigned int SValue;
	char CCR;
	MOVEXR_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	CCR = Instr.Bits.To ^ Instr.Bits.Reg;

	if(!EA_GetFromPC(&Source, 16, Instr.Bits.Mode, Instr.Bits.Register)) return;


	if(CCR == 0 && !SRBits->S ) {
		/* User state, ptivilege violation */
		exception_do_exception(8);
		return;
	}

	if(Instr.Bits.To) {
		EA_GetValue(&SValue, &Source);
		if(CCR == 0) {
			memory_core.sr = SValue;
			if( (Instr.Bits.Mode == 0x07) && (Instr.Bits.Register==0x04) )
				cycle(MOVE2SRTime + 6);
			else
				cycle(MOVE2SRTime);
		} else {
			memory_core.sr = (memory_core.sr & 0xffffff00) | 
						(SValue & 0x000000ff);
			cycle(MOVEXRTime);
		}
	} else {
		SValue = (unsigned int)((CCR==0) ? memory_core.sr : 
					(memory_core.sr&0x000000ff) );
		
		EA_PutValue(&Source, SValue);
		cycle(MOVEXRTime);
	}

	/* Don't play with the Status register any more :) */
	return;

}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	MOVEXR_Instr Instr;
	char CCR;
	Memory_RetrWordFromPC(&Instr.Code);

	CCR = Instr.Bits.To ^ Instr.Bits.Reg;

	sprintf(Instruction, "MOVE");

	if(Instr.Bits.To) {
		char *ptr;
		ptr = Arg1;
		Arg1 = Arg2;
		Arg2 = ptr;
	}

	if(CCR)
		sprintf(Arg1, "CCR");
	else
		sprintf(Arg1, "SR");
	Addressing_Print(16, Instr.Bits.Mode, Instr.Bits.Register, Arg2);

	return 0;
}

int movexr_5206_register(void)
{
	instruction_register(0x40C0, 0xF9C0, &execute, &disassemble);
	instruction_register(0x40C0, 0xF9C0, &execute, &disassemble);
	return 1;
}
