/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Bit Test (BTST) instruction */

/* Format, Bit number dynamic
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 |  Register | 1 |   OP  |  EAMode   |EARegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

   Format, Bit number static (immediate data)

 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |  OP   |  EAMode   |EARegister |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |          Bit Number           |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

OP: 00 == BTST
    01 == BCHG
    10 == BCLR
    11 == BSET

*/


INSTRUCTION_6ARGS(BTST,
	unsigned Code2,4,
	unsigned Register,3,
	unsigned Dynamic,1,
	unsigned OP,2,
	unsigned EAMode,3,
	unsigned EARegister,3);

int BTSTTime[2][8]={{1, 3, 3, 3, 3, -1, -1, 1},
		    {2, 3, 3, 3, 3, 4, 3, -1}};


static void execute(void)
{
	struct _Address Destination, BitNum;
	unsigned int DValue, BitNumValue;
	int mask;
	BTST_Instr Instr;
	/* If the destination is a data register, size is longword, else,
	 * size is byte */
	char size;

	/* Pull the instruction */
	Memory_RetrWordFromPC(&Instr.Code);

	/* Do this after fetching the instruction */
	size = (Instr.Bits.EAMode == 0) ? 32 : 8;


	/* Get the bit number FIRST, since the order of the opcode is
	 * BTST [bit number] [EA offset] */

	/* For dynamic (Dynamic==1) a data register is given, need 32 bits
	 *  from the register
	 * For static (Dynamic==0) the bit number is the displacement
	 * specified in the extension word, (8 bits from the PC) */
	if(Instr.Bits.Dynamic == 1) {
		/* Dynamic, pull bit from a register */
		if(!EA_GetFromPC(&BitNum, 32, 0, Instr.Bits.Register)) return;
	} else {
		/* Get the bit number from immediate data */
		/* Magic happening here.... Remember, size 8 from the 
		 * PC skips the first byte, and only grabs the second 
		 * one of the word, so this is OK */
		if(!EA_GetFromPC(&BitNum, 8, 7, 4)) return;
	}
	EA_GetValue(&BitNumValue, &BitNum);
	BitNumValue %= size;

	/* Longword for Data register, all others byte operation */
	if(!EA_GetFromPC(&Destination, size, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_GetValue(&DValue, &Destination);

	mask = (0x1 << BitNumValue);


	/* Condition codes */
	/* If the tested bit is 0, Z is set, else it is cleared */
	/* Else, unchanged */
	SRBits->Z = (DValue & mask) ? 0 : 1;

	switch(Instr.Bits.OP) {
	case 0: /* BTST */
		/* leave the bit alone, short circuit to done */
		return;
	case 1: /* BCHG */
		/* Toggle the bit */
		DValue = (DValue & ~mask) | (DValue ^ mask);
		break;
	case 2: /* BCLR */
		/* Clear the bit */
		DValue &= ~mask;
		break;
	case 3: /* BSET */
		/* Set the bit */
		DValue |= mask;
		break;
	}
	EA_PutValue(&Destination, DValue);

	if (Instr.Bits.Dynamic == 1)
		cycle(BTSTTime[0][cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);
	else cycle(BTSTTime[1][cycle_EA(Instr.Bits.EARegister,Instr.Bits.EAMode)]);

	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	BTST_Instr Instr;
	char size = (Instr.Bits.EAMode == 0) ? 32 : 8;

	Memory_RetrWordFromPC(&Instr.Code);

	switch(Instr.Bits.OP) {
	case 0: /* BTST */
/*		sprintf(Instruction, "BTST%s", (size == 32) ? ".L" : ""); */
		strcpy(Instruction, "BTST");
		break;
	case 1: /* BCHG */
		strcpy(Instruction, "BCHG"); 
		break;
	case 2: /* BCLR */
		strcpy(Instruction, "BCLR"); 
		break;
	case 3: /* BSET */
		strcpy(Instruction, "BSET"); 
		break;
	}

	if(Instr.Bits.Dynamic == 1)
		Addressing_Print(32, 0, Instr.Bits.Register, Arg1);
	else
		Addressing_Print(8, 7, 4, Arg1);

	Addressing_Print(size, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg2);
	return 0;
}

int btst_5206_register(void)
{
	/* Register both forms for the "same" instruction */
	/* Dynamic */
	instruction_register(0x0100, 0xF100, &execute, &disassemble);
	/* Static */
	instruction_register(0x0800, 0xFF00, &execute, &disassemble);
	return 4; /* BTST, BCLR, BSET, BCHG */
}
