/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include "coldfire.h"

/* Set Conditionally */

/* Format 
   
 15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
| 0 | 1 | 0 | 1 |   Condition   | 1 | 1 | 0 | 0 | 0 |  Register |
+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

*/

const char *code_mnemonic[16] = { "T", "F", "HI", "LS", "CC", "CS", "NE", "EQ",
			"VC", "VS", "PL", "MI", "GE", "LT", "GT", "LE"};


INSTRUCTION_4ARGS(SCC,
	unsigned Code2,4,
	unsigned Condition,4,
	unsigned Code1,5,
	unsigned Register,3);

int SCCTime=1;

static void execute(void)
{
	struct _Address Destination;
	SCC_Instr Instr;
	unsigned char Result=0;

	Memory_RetrWordFromPC(&Instr.Code);

	if(!EA_GetFromPC(&Destination, 8, 0, Instr.Bits.Register)) return;

	cycle(SCCTime);

	switch(Instr.Bits.Condition) {
	case 0: /* True */
		Result=1;
		break;
	case 1: /* False */
		break;
	case 2: /* SHI */
		/* The docs say (!C or !Z), however processor seems to do 
		 * this: */
		Result = SRBits->C || !SRBits->Z;
		break;
	case 3: /* SLS */
		Result = SRBits->C || SRBits->Z;
		break;
	case 4: /* SCC */
		Result = !SRBits->C;
		break;
	case 5: /* SCS */
		Result = SRBits->C;
		break;
	case 6: /* SNE */
		/* Set if they are not equal, ie Dest-Source != 0 */
		Result = (!SRBits->Z);
		break;
	case 7: /* BEQ */
		/* Don't set if they are not equal */
		Result = (SRBits->Z);
		break;
	case 8: /* SVC */
		Result = (!SRBits->V);
		break;
	case 9: /* SVS */
		Result = SRBits->V;
		break;
	case 10: /* SPL */
		Result = !SRBits->N;
		break;
	case 11: /* SMI */
		Result = SRBits->N;
		break;
	case 12: /* SGE */
		Result = ((SRBits->N && SRBits->V) || 
					(!SRBits->N && !SRBits->V));
		break;
	case 13: /* SLT */
		Result = ((SRBits->N && !SRBits->V) || 
					(!SRBits->N && SRBits->V));
		break;
	case 14: /* SGT */
		Result = ((SRBits->N && SRBits->V && !SRBits->Z) || 
				(!SRBits->N && !SRBits->V && !SRBits->Z));
		break;
	case 15: /* SLE */
		Result = (SRBits->Z || (SRBits->N && !SRBits->V) ||
				(!SRBits->N && SRBits->V) );
		break;
	default:
		SKYEYE_ERR("Unknown Condition Code 0x%02x\n", Instr.Bits.Condition);
		return;
	}
	if(Result) Result = 0x000000FF;

	EA_PutValue(&Destination, Result);
	
	
	return;
}


static int disassemble(char *Instruction, char *Arg1, char *Arg2)
{
	
	SCC_Instr Instr;
	Memory_RetrWordFromPC(&Instr.Code);
	sprintf(Instruction, "S%s", code_mnemonic[(int)Instr.Bits.Condition]);
	sprintf(Arg1, "D%d", Instr.Bits.Register);
	Arg2[0]=0;	
	return 0;
}

int scc_5206_register(void)
{
	instruction_register(0x50C0, 0xF0F8, &execute, &disassemble);
	return 1;
}
