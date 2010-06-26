/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include <stdlib.h>
#include "coldfire.h"


SKYEYE_DBGR_DEFAULT_CHANNEL(i);

#define MALLOC_STEP 16
struct _Instruction *Instruction = NULL;
short InstructionCount=0;

struct _Instruction **instruction_cache = NULL;

void Instruction_Init(void)
{
	SKYEYE_DBG("Initializing...\n");
	/* Ensure sanity */
	Instruction = NULL;
	InstructionCount=0;
	instruction_cache = malloc(0x10000 * sizeof(void *));
	if(!instruction_cache) printf("Could not allocate instruction cache\n");
	SKYEYE_DBG("Done.\n");
}

/* This is for sorting */
static int Instruction_CompareFunction(const void *A, const void *B)
{
	/* Biggest mask first, this sorts backwards */
	/* printf("Comparing %p and %p.  Mask=%x %x\n", A, B, IA->Mask, IB->Mask);*/
	return ( ((struct _Instruction *)B)->Mask -
		 ((struct _Instruction *)A)->Mask );
}


void instruction_register(unsigned short code, unsigned short mask, 
		void (*execute)(void),
		int (*disassemble)(char *, char *, char *))
{
	struct _Instruction *InstrPtr;
	/* Check if any reallocating is necessary */
	SKYEYE_DBG("Registering Code=0x%04hx Mask=0x%04hx\n", code, mask);
	if((InstructionCount % MALLOC_STEP)==0)  {
		SKYEYE_DBG("Reallocing to %d bytes\n",(InstructionCount + MALLOC_STEP) * sizeof(struct _Instruction)); 
		Instruction = realloc(Instruction, (InstructionCount + MALLOC_STEP) * sizeof(struct _Instruction));
	}
	/* Add this instruction */
	InstrPtr = &Instruction[InstructionCount];
	InstrPtr->Code = code;
	InstrPtr->Mask = mask;
	InstrPtr->FunctionPtr = (void (*)(void))execute;
	InstrPtr->DIFunctionPtr = (int (*)(char *Instruction, char *Arg1, char *Arg2))disassemble;
	InstructionCount++;

        qsort(Instruction, InstructionCount, sizeof(struct _Instruction),
			                &Instruction_CompareFunction);
	SKYEYE_DBG("Done\n");
		
}

void Instruction_DeInit(void)
{
	if(instruction_cache) free(instruction_cache);
	if(Instruction) free(Instruction);
}

/* Returns a pointer to the instruction that matches Instr
 *           (Finds by matching Code and Mask) */
static struct _Instruction *Instruction_LookupInstruction(unsigned short Instr)
{
	int x;

	for(x=0;x<InstructionCount;x++) {
		if((Instr & Instruction[x].Mask) == Instruction[x].Code) {
			/* Return the instruction */
			return &Instruction[x];
		}
	}

	/* We should never get here.. the DC.W instruction, with
	 * mask 0xFFFF will pick up all instructions */
	//SKYEYE_ERR("Unknown instruction \n");
	return NULL;
}

struct _Instruction *Instruction_FindInstruction(unsigned short Instr)
{
	/* O(1) instruction lookup, instead of O(n) */
	return instruction_cache[Instr];
	
/*	O(n) instruction lookup, yuck.
 *	return Instruction_LookupInstruction(Instr);*/
}

static void instruction_build_cache(void)
{
	unsigned int x;
	if(!instruction_cache) {
		printf("Skipping instruction cache build, cache not allocated\n");
		return;
	}
	printf("\tbuilding instruction cache... " );
	fflush(stdout);
	for(x=0;x<0x10000;x++) {
		instruction_cache[x] = Instruction_LookupInstruction(x);
	}
	printf("done.\n");
}

void instruction_register_instructions(void)
{
	int x=0;
	struct _board_data *bd = board_get_data();

	switch(bd->cpu) {
	case CF_5206:
		printf(" (Motorola Coldfire 5206)\n");
		printf("\tunimplemented instructions: CPUSHL PULSE WDDATA WDEBUG\n");
		break;
	case CF_5206e: 
		printf(" (Motorola Coldfire 5206e)\n");
		printf("\tunimplemented instructions: CPUSHL PULSE WDDATA WDEBUG\n");
		break;
	case CF_5307: 
		printf(" (Motorola Coldfire 5307)\n");
		printf("\tunimplemented instructions: CPUSHL PULSE WDDATA WDEBUG\n");
		break;
	default:
		printf("\tUnknown processor type '%d'\n", bd->cpu);
		break;
	}
	/* Register intstructions */
	x+=add_5206_register();
	x+=adda_5206_register();
	x+=addi_5206_register();
	x+=addq_5206_register();
	x+=addx_5206_register();
	x+=and_5206_register();
	x+=andi_5206_register();
	x+=asx_5206_register();
	x+=bcc_5206_register();
	x+=btst_5206_register();
	x+=clr_5206_register();
	x+=cmp_5206_register();
	x+=cmpa_5206_register();
	x+=cmpi_5206_register();
	x+=dc_5206_register();
	x+=eor_5206_register();
	x+=eori_5206_register();
	x+=ext_5206_register();
	x+=halt_5206_register();
	x+=illegal_5206_register();
	x+=jmp_5206_register();
	x+=jsr_5206_register();
	x+=lea_5206_register();
	x+=link_5206_register();
	x+=lsx_5206_register();
	x+=move_5206_register();
	x+=movec_5206_register();
	x+=movem_5206_register();
	x+=moveq_5206_register();
	x+=movexr_5206_register();
	x+=mulu_l_5206_register();
	x+=mul_w_5206_register();
	x+=neg_5206_register();
	x+=negx_5206_register();
	x+=nop_5206_register();
	x+=not_5206_register();
	x+=or_5206_register();
	x+=ori_5206_register();
	x+=pea_5206_register();
	x+=rte_5206_register();
	x+=rts_5206_register();
	x+=scc_5206_register();
	x+=stop_5206_register();
	x+=sub_5206_register();
	x+=suba_5206_register();
	x+=subi_5206_register();
	x+=subq_5206_register();
	x+=subx_5206_register();
	x+=swap_5206_register();
	x+=trap_5206_register();
	x+=trapf_5206_register();
	x+=tst_5206_register();
	x+=unlk_5206_register();
	x+=div_5206e_register();
	
	//if(bd->cpu >= CF_5206e) x+= div_5206e_register();
	
	printf("\t%d instructions registered\n", x);
	if(x==0) {
		/* This could get interesting */
		SKYEYE_ERR("No registered instructions, hmmm, something is wrong\n");
	}

	instruction_build_cache();
/*
	for(x=0;x<InstructionCount;x++) {
		printf("Instr Code=0x%04x, Mask=0x%04x, Code&Mask=0x%04x\n",
			Instruction[x].Code, Instruction[x].Mask, 
			Instruction[x].Code & Instruction[x].Mask) ;
	}
*/
}

