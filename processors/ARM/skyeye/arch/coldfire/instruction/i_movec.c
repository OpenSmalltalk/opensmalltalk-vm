/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* MoveC instruction */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1 | 1 | 0 | 1 | 1 |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
|A/D| Register  |             Control Register                  |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

int MOVECTime=9;


/* We are going to cheat here, and define this for the SECOND 
 * word of the instr */
INSTRUCTION_3ARGS(MOVEC,
	unsigned AD,1,
	unsigned Register,3,
	unsigned ControlRegister,12);

static void execute(void)
{
	struct _Address Source;
	unsigned int SValue;
	MOVEC_Instr Instr;
	/* Get the instr, but we alreday know what it is */
	Memory_RetrWordFromPC(&Instr.Code);
	/* Get the second word, that we care about */
	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Source, 32, Instr.Bits.AD, Instr.Bits.Register)) return;

	EA_GetValue(&SValue, &Source);

	if(SRBits->S) {
		/* Supervisor State */
		switch(Instr.Bits.ControlRegister) {
		case 0x002: /* Cache Control Register */
			memory_core.cacr = SValue;
			break;
		case 0x004: /* Access Control Register 0 */
			SKYEYE_ERR("Storing 0x%08lx in the ACR0 is unimplemented!\n", SValue);
			break;
		case 0x005: /* Access Control Register 1 */
			SKYEYE_ERR("Storing 0x%08lx in the ACR1 is unimplemented!\n", SValue);
			break;
		case 0x801: /* VBR */
			memory_core.vbr = SValue;
			break;
		case 0x80F: /* Program Counter */
			memory_core.pc = SValue;
			break;
		case 0xC00: /* ROM Base Address Register */
			memory_core.rombar = SValue & 0xfffffc00;
			break;
		case 0xC04: /* SRAM Base Address Register */
			memory_core.rambar = SValue & 0xfffffc00;
			break;
		case 0xC05: /**/
			memory_core.rambar1 = SValue & 0xfffffc00;
			break;
		case 0xC0E: /**/
			memory_core.mbar2 = SValue & 0xfffffc00;
			break;
		case 0xC0F: /* Module Base Address Register */
			memory_core.mbar = SValue & 0xfffffc00;
			break;
		default:
			SKYEYE_ERR("Unimplemented Control register 0x%x\n", Instr.Bits.ControlRegister);
			break;

		}
		/* Condition code are not affected */
	} else {
		/* User state */
		/* FIXME: Generate an exception violation here */
	}


	cycle(MOVECTime);
	
	return;
}

static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	MOVEC_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	Memory_RetrWordFromPC(&Instr.Code);

	sprintf(Instruction, "MOVEC");

	Addressing_Print(32, Instr.Bits.AD, Instr.Bits.Register, Arg1);
	switch(Instr.Bits.ControlRegister) {
	case 0x002: /* Cache Control Register */
		sprintf(Arg2, "CACR");
		break;
	case 0x004: /* Access Control Register 0 */
		sprintf(Arg2, "ACR0");
		break;
	case 0x005: /* Access Control Register 1 */
		sprintf(Arg2, "ACR1");
		break;
	case 0x801: /* VBR */
		sprintf(Arg2, "VBR");
		break;
	case 0x80F: /* Program Counter */
		sprintf(Arg2, "PC");
		break;
	case 0xC00: /* ROM Base Address Register */
		sprintf(Arg2, "ROMBAR");
		break;
	case 0xC04: /* SRAM Base Address Register */
		sprintf(Arg2, "RAMBAR");
		break;
	case 0xC0F: /* Module Base Address Register */
		sprintf(Arg2, "MBAR");
		break;
	default:
		sprintf(Arg2, "???");
		break;
	}

	return 0;
}

int movec_5206_register(void)
{
	instruction_register(0x4E7B, 0xFFFF, &execute, &disassemble);
	return 1;
}
