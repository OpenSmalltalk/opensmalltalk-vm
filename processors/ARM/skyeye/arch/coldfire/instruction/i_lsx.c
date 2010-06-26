/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Logical Shift Left/Right LSL, LSR instructions */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 1 | 1 | 1 | 0 | Count/Reg | dr| 1 | 0 |i/r| 0 | 1 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int LSXTime=1;


INSTRUCTION_7ARGS(LSX,
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
	LSX_Instr Instr;
	int last_bit;

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


	if(SValue == 0) {
		SRBits->C = 0;
		Result = DValue;
	} else {
		last_bit = 0;
		if(Instr.Bits.DR==0) {
			/* Shift Right */
			/* Catch if we are shifting the register clean, this
			 * catchs any funny modulo arithmetic the native
			 * hardware does with a shift */
			if(SValue <= 32) 
				last_bit = DValue & (0x1 << (SValue-1));
			
			/* On x86, the instruction takes modulo 32, so a 
			 * shift by 0x20 actually shifts 0, and 
			 * 0x21 shifts 1, etc. but we want to be able
			 * to shift everything out of the register */
			Result = (SValue >= 32) ? 0 : (DValue >> SValue);
			
		} else {
			/* Shift Left */
			if(SValue <= 32) 
				last_bit = DValue & (0x80000000 >> (SValue-1));
			
			Result = (SValue >= 32) ? 0 : (DValue << SValue);
		}
		SRBits->C = (last_bit) ? 1 : 0;
		SRBits->X = (last_bit) ? 1 : 0;
	}

	/* X - Set according to last bit shifted out of
		the operand; unaffected for shift count of 0
	   N - Set if result is -ve, cleared otherwise
	   Z - Set if result is zero, cleared otherwise
	   V - always cleared
	   C - set according to the last bit shifted out 
		of the operand; cleared for a shift count of 0
	*/
	SRBits->N = ((int)Result < 0) ? 1 : 0;
	SRBits->Z = (Result == 0) ? 1 : 0;
	
	EA_PutValue(&Destination, Result);

	cycle(LSXTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2) 
{
	LSX_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);

	if(Instr.Bits.DR==0) {
		/* Shift Right */
		sprintf(Instruction, "LSR.L");
	} else {
		/* Shift Left */
		sprintf(Instruction, "LSL.L");
	}
	if(Instr.Bits.IR==0) {
		/* Shift from count in instruction word */
		int SValue = Instr.Bits.CountReg;
		if(SValue == 0) SValue = 8;
		sprintf(Arg1, "#0x%02lX", SValue);
	} else {
		sprintf(Arg1, "D%d", Instr.Bits.CountReg);
	}
	Addressing_Print(32, 0, Instr.Bits.Register, Arg2);
	return 0;
}

int lsx_5206_register(void)
{
	instruction_register(0xE088, 0xF0D8, &execute, &disassemble);
	instruction_register(0xE088, 0xF0D8, &execute, &disassemble);
	return 2;
}
