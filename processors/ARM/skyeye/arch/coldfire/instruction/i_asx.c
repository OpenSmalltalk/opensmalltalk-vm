/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Arithmetic Shift Left/Right ASL, ASR instructions */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 1 | 1 | 1 | 0 | Count/Reg | dr| 1 | 0 |i/r| 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int ASXTime=1;


INSTRUCTION_7ARGS(ASX,
	unsigned Code3,4,
	unsigned CountReg,3,
	unsigned DR,1,
	unsigned Code2,2,
	unsigned IR,1,
	unsigned Code1,2,
	unsigned Register,3);

static void execute(void)
{
	struct _Address Source,Destination;
	unsigned int Result, SValue, DValue;
	ASX_Instr Instr;
	int x;

	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.IR==0) {
		/* Shift from count in instruction word */
		SValue = Instr.Bits.CountReg;
		if(SValue == 0) SValue = 8;
	} else {
		if(!EA_GetFromPC(&Source, 32, 0, Instr.Bits.CountReg)) return;
		/* Get source, modulo 64 */
		EA_GetValue(&SValue, &Source);
		SValue &= 0x0000003F;
	}
	if(!EA_GetFromPC(&Destination, 32, 0, Instr.Bits.Register)) return;
	EA_GetValue(&DValue, &Destination);

	Result = DValue;
	if(Instr.Bits.DR==0) {
		/* Shift Right */
		
		for(x=0;x<SValue;x++) {
			SRBits->C = Result & 0x00000001;
			SRBits->X = Result & 0x00000001;
			Result >>= 1;
			if(Result & 0x40000000) 
				Result |= 0x80000000;
		}
		
	} else {
		/* Shift Left */
		for(x=0;x<SValue;x++) {
			SRBits->C = (Result & 0x80000000) ? 1 : 0;
			SRBits->X = (Result & 0x80000000) ? 1 : 0;
			Result <<= 1;
		}
	}
	SRBits->N=((signed int)Result<0)  ? 1 : 0;
	SRBits->Z=(Result==0) ? 1 : 0;
	SRBits->V=0;



	EA_PutValue(&Destination, Result);

	cycle(ASXTime);

	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	ASX_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.DR==0) {
		/* Shift Right */
		sprintf(Instruction, "ASR.L");
	} else {
		/* Shift Left */
		sprintf(Instruction, "ASL.L");
	}
	if(Instr.Bits.IR==0) {
		/* Shift from count in instruction word */
		int SValue = Instr.Bits.CountReg;
		if(SValue == 0) SValue = 8;
		sprintf(Arg1, "#0x%02ld", SValue);
	} else {
		sprintf(Arg1, "D%d", Instr.Bits.CountReg);
	}
	Addressing_Print(32, 0, Instr.Bits.Register, Arg2);
	return 0;
}

int asx_5206_register(void)
{
	instruction_register(0xE080, 0xF0D8, &execute, &disassemble);
	return 2;
}
