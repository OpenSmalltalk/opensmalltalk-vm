/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Trapf instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 |   OpMode  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                    Optional Immediate Word                    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|                    Optional Immediate Word                    |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int TRAPFTime=1;


INSTRUCTION_2ARGS(TRAPF,
	unsigned Code1,13,
	unsigned OpMode,3);

static void execute(void)
{
	TRAPF_Instr Instr;
	unsigned int dummy;

	Memory_RetrWordFromPC(&Instr.Code);


	switch(Instr.Bits.OpMode) {
		case 0x2: /* One extension word */
			Memory_RetrWordFromPC(&dummy);
			break;
		case 0x3: /* Two extension words */
			Memory_RetrLongWordFromPC(&dummy);
			break;
		case 0x4: /* No extension words */
			break;
		default:
			SKYEYE_ERR("Invalid OpMode=%d\n", Instr.Bits.OpMode);
			break;
	}
	
	cycle(TRAPFTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	TRAPF_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	switch(Instr.Bits.OpMode) {
		case 0x2: /* One extension word */
			sprintf(Instruction, "TRAPF.W");
			Addressing_Print(16, 7, 4, Arg1);
			break;
		case 0x3: /* Two extension words */
			sprintf(Instruction, "TRAPF.L");
			Addressing_Print(32, 7, 4, Arg1);
			break;
		case 0x4: /* No extension words */
			sprintf(Instruction, "TRAPF");
			break;
		default:
			SKYEYE_ERR("Invalid OpMode=%d\n", Instr.Bits.OpMode);
			break;

	}
	Arg2[0]=0;
	return 0;
}

int trapf_5206_register(void)
{
	instruction_register(0x51F8, 0xFFF8, &execute, &disassemble);
	return 1;
}
