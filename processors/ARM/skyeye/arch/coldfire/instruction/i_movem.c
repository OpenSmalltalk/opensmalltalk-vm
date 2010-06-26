/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Movem instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | dr| 0 | 0 | 1 | 1 |  EAMode   | EARegister|
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|         A7..A0,D7...D0   Register List Mask                   |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

INSTRUCTION_5ARGS(MOVEM,
	unsigned Code2,5,
	unsigned Direction,1,
	unsigned Code1,4,
	unsigned EAMode,3,
	unsigned EARegister,3);

int MOVEMTime=1;

static void execute(void)
{
	struct _Address Address;
	unsigned int AddressValue;
	MOVEM_Instr Instr;
	unsigned int RegisterListMask;
	short move_count;
	int x;
	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&RegisterListMask);

	/* dr field: 	0- register to memory
			1- memory to register */

	if(Instr.Bits.EAMode != 2 && Instr.Bits.EAMode != 5) {
		printf("MOVEM: EAMode 0x%02x is not allowed\n", Instr.Bits.EAMode);
		return;
	}

	/* Get the effective address */
	
	if(!EA_GetFromPC(&Address, 32, Instr.Bits.EAMode, Instr.Bits.EARegister)) return;
	EA_GetEA(&AddressValue, &Address);

	move_count=0;
	if(Instr.Bits.Direction==0) {
		/* Registers to memory */
		for(x=0;x<8;x++,RegisterListMask>>=1) {
			if(RegisterListMask & 0x0001) {
				/* Save this register */
				Memory_Stor(32, AddressValue + (move_count*4), memory_core.d[x]);
				move_count++;
			}
		}
		for(x=8;x<16;x++,RegisterListMask>>=1) {
			if(RegisterListMask & 0x0001) {
				/* Save this register */
				Memory_Stor(32, AddressValue + (move_count*4), memory_core.a[x-8]);
				move_count++;
			}
		}
		
	} else {
		/* Memory to registers */
		for(x=0;x<8;x++,RegisterListMask>>=1) {
			if(RegisterListMask & 0x0001) {
				/* Retr this register */
				Memory_Retr(&memory_core.d[x], 32, AddressValue + (move_count*4));
				move_count++;
			}
		}
		for(x=8;x<16;x++,RegisterListMask>>=1) {
			if(RegisterListMask & 0x0001) {
				/* Retr this register */
				Memory_Retr(&memory_core.a[x-8], 32, AddressValue + (move_count*4));
				move_count++;
			}
		}
	}

	/* Condition codes are not affected */
	cycle((MOVEMTime + move_count));
	return;
}

static int movem_print(char *buffer, char reg, unsigned int reg_list)
{
	int x;
	char n_printed = 0;
	char one_printed = 0;
	char *orignal_buffer = buffer;

	/* reg_list number 8 should be 0, so after the 8th register, we will
	 * always write out the last string of registers (if any) */
	
	for(x=0;x<9;x++,reg_list >>= 1) {
		if(reg_list & 1) {
			if(!n_printed) {
				/* Last one not printed, and this one needs it */
				/* If at least one is printed, we need a comma */
				if(one_printed)
					buffer  += sprintf(buffer, ",");
				buffer += sprintf(buffer, "%c%d", reg, x);
				one_printed = 1;
			}
			n_printed++;
		} else {
			if(n_printed > 1) {
				buffer += sprintf(buffer, "-%c%d", reg, x-1);
				n_printed = 0;
			}
		}
	}
	return (buffer - orignal_buffer);
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	MOVEM_Instr Instr;
	char *regStr;
	short size;
	unsigned int RegisterListMask;

	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&RegisterListMask);

	sprintf(Instruction, "MOVEM.L");

	if(Instr.Bits.Direction==0) {
		/* Registers to memory */
		regStr = Arg1;
		Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg2);
	} else {
		Addressing_Print(32, Instr.Bits.EAMode, Instr.Bits.EARegister, Arg1);
		regStr = Arg2;
	}
	regStr[0]=0;

	/* RegisterListMask   1 for "yes", 0 for no
		A7 A6 A5 ... A1 A0 D7 D6 .... D1 D0
	*/
	size = movem_print(regStr, 'D', RegisterListMask & 0x00FF);
	if(size && (RegisterListMask & 0xFF00)) {
		regStr += size;
		regStr += sprintf(regStr, "/");
	}
	movem_print(regStr, 'A', (RegisterListMask & 0xFF00) >> 8);

	return 0;
}

int movem_5206_register(void)
{
	instruction_register(0x48C0, 0xFBC0, &execute, &disassemble);
	return 1;
}
