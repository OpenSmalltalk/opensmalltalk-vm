/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#include <stdio.h>
#include <stdarg.h>

#include "coldfire.h"

SKYEYE_DBGR_DEFAULT_CHANNEL(handlers);


void SR_Set(short Instr, int Source, int Destination, int Result)
{
	char Sm = (Source >= 0) ? 0 : 1;
	char Dm = (Destination >= 0) ? 0 : 1;
	char Rm = (Result >= 0) ? 0 : 1;
	short BackupSR = memory_core.sr;

	SKYEYE_DBG("Setting Source=0x%08lx, Destination=0x%08lx, Result=0x%08lx\n", Source, Destination, Result);
	SKYEYE_DBG("Sm=%d, Dm=%d, Rm=%d\n", Sm,Dm,Rm);

	/* Clear out the XNZVC */	
	memory_core.sr &= 0xFFE0;
	

	switch(Instr) {
	case I_ADDX:
		/* Z - cleared if result is non-zero, unchanged otherwise */
	case I_ADD: case I_ADDI: case I_ADDQ:
		/* Set the status register */
		/* X - Set to value of carry bit
		   N - Set if result is -ve, cleared otherwise
		   Z - Set if result is zero, cleared otherwise
		   V - Set if an overflow occurs, cleared otherwise
		   C - Set if a carry is generated, cleared otherwise
		*/
		if(Rm)		memory_core.sr |= SR_N;
		if(Instr==I_ADDX) {
			if(Result) /* SR_Z will already be cleared */;
			else /* Restore the old one */
				memory_core.sr |= (BackupSR & SR_Z);
		} else {
			if(Result==0)	memory_core.sr |= SR_Z;
		}
		if((Sm && Dm && !Rm) || (!Sm && !Dm && Rm) )
			memory_core.sr |= SR_V;

		if((Sm && Dm) || (!Rm && Dm) || (Sm && !Rm) ) {
			memory_core.sr |= SR_C;
			memory_core.sr |= SR_X;
		}
		break;
	case I_SUBX:
		/* Z - cleared if result is non-zero, unchanged otherwise */
	case I_SUB: case I_SUBI: case I_SUBQ:
		/* Set the status register */
		/* X - Set to value of carry bit
		   N - Set if result is -ve, cleared otherwise
		   Z - Set if result is zero, cleared otherwise
		   V - Set if an overflow occurs, cleared otherwise
		   C - Set if a borrow occurs, cleared otherwise
		*/
		if(Rm)		memory_core.sr |= SR_N;
		if(Instr==I_SUBX) {
			if(Result) /* SR_Z will already be cleared */;
			else /* Restore the old one */
				memory_core.sr |= (BackupSR & SR_Z);
		} else {
			if(Result==0)	memory_core.sr |= SR_Z;
		}
		if((!Sm && Dm && !Rm) || (Sm && !Dm && Rm) )
			memory_core.sr |= SR_V;

		if((Sm && !Dm) || (Rm && !Dm) || (Sm && Rm) ) {
			memory_core.sr |= SR_C;
			memory_core.sr |= SR_X;
		}
		
		break;
	case I_CMP: case I_CMPA: case I_CMPI:
		/* Set the status register
		 *  X - Not affected 
		 *  N - Set if result is -ve, cleared otherwise
		 *  Z - Set if result is zero, cleared otherwise
		 *  V - Set if an overflow occurs, cleared otherwise
		 *  C - Set if a borrow occurs, cleared otherwise
		 */
		
		if(Rm)		memory_core.sr |= SR_N;
		if(Result==0)	memory_core.sr |= SR_Z;
		
		if((!Sm && Dm && !Rm) || (Sm && !Dm && Rm) )
			memory_core.sr |= SR_V;

		if((Sm && !Dm) || (Rm && !Dm) || (Sm && Rm) )
			memory_core.sr |= SR_C;
		
		/* Restore X */
		memory_core.sr |= (BackupSR & SR_X);
		
		break;

	case I_NEG: 
		/* X - Set to value of carry bit
		   N - Set if result is -ve, cleared otherwise
		   Z - Set if result is zero, cleared otherwise
		   V - Set if an overflow occurs, cleared otherwise
		   C - Cleared if the result is zero, set otherwise
		*/
		if(Rm)		memory_core.sr |= SR_N;
		if(Result==0)	memory_core.sr |= SR_Z;
		if(Dm && Rm)	memory_core.sr |= SR_V;
		if(Dm || Rm) 	memory_core.sr |= (SR_C | SR_X);
		break;
		
	case I_NEGX:
		/* X - Set to value of carry bit
		   N - Set if result is -ve, cleared otherwise
		   Z - Cleared if the result is non-zero, unchanged otherwise
		   V - Set if an overflow occurs, cleared otherwise
		   C - Cleared if the result is zero, set otherwise
		*/
		if(Rm)		memory_core.sr |= SR_N;
		if(Result==0)	memory_core.sr |= (BackupSR & SR_Z);
		if(Dm && Rm)	memory_core.sr |= SR_V;
		if(Dm || Rm) 	memory_core.sr |= (SR_C | SR_X);

		break;


	default:
		SKYEYE_ERR("Called with unknown instruction %d\n", Instr);
		break;
	}
	SKYEYE_DBG("X:%d, Neg:%d, Zero:%d, Overflow:%d, Carry:%d\n", (memory_core.sr&SR_X) >> 4,(memory_core.sr&SR_N) >> 3,(memory_core.sr&SR_Z) >> 2,(memory_core.sr&SR_V) >> 1, (memory_core.sr&SR_C));
	return;
}

