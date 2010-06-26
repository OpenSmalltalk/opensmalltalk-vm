/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Jump (JMP) instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 1 | 1 |  EAMode   | EARegister|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int JMPTime[8]={-1, 3, -1, -1, 3, 4, 3, -1};


INSTRUCTION_3ARGS(JMP,
	unsigned Code1,10,
	unsigned EAMode,3,
	unsigned EARegister,3);

static void execute(void)
{
	struct _Address Destination;
	unsigned int DValue;
	JMP_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	
	

	if(!EA_GetFromPC(&Destination, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_GetEA(&DValue, &Destination);



	/* Set the new PC */
	memory_core.pc=DValue;

	cycle(JMPTime[cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	JMP_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "JMP");
	Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
	Arg2[0]=0;
	return 0;
}

int jmp_5206_register(void)
{
	instruction_register(0x4EC0, 0xFFC0, &execute, &disassemble);
	return 1;
}
