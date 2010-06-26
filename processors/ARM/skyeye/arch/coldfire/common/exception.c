/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

/*#define SKYEYE_DBGR_OFF*/

#include "coldfire.h"

SKYEYE_DBGR_DEFAULT_CHANNEL(exception);

static short exception_pending = 0;
static unsigned int (*iack_func[8])(unsigned int interrupt_level)
	= { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };

void exception_check_and_handle(void)
{
	int x;
	if(!exception_pending) return;

	SKYEYE_DBG("exception_pending = 0x%04x\n", exception_pending);

	/* if the mask is 7, do nothing, if the mask is 0, check 
	 * all interrupts 7->1, interrupts level 0 doesn't make sense
	 *  FIXME: can the coldfire fire an interrupt with priority 0 ? */
	
	SKYEYE_DBG("currint interrupt mask is %d, checking 7->%d\n", 
		SRBits->InterruptPriorityMask, SRBits->InterruptPriorityMask+1);
	
	for(x=7; x>=SRBits->InterruptPriorityMask+1; x--) {
		if(iack_func[x] != NULL) {
			unsigned int vector;
			SKYEYE_DBG("Found interrupt_level %d to do exception.\n",
					x);
			vector = (iack_func[x])(x);
			SKYEYE_DBG("iack_func returned vector %lu\n", vector);
			exception_push_stack_frame(vector);
			/* Set the new interrupt priority */
			SRBits->InterruptPriorityMask = x;
			
			/* Set the Master/Interrupt bit to 0 */
			SRBits->M = 0;
			SKYEYE_DBG("   Interrupt Priority mask is now %d\n",
						SRBits->InterruptPriorityMask);
			/* Do the RAW exception */
			exception_do_raw_exception(vector);
			return;
		}
	}
}


void exception_post(unsigned int interrupt_level, 
		unsigned int (*func)(unsigned int interrupt_level) )
{
	SKYEYE_DBG("Exception posted at interrupt level %d\n", interrupt_level);
	exception_pending |= (0x1 << interrupt_level);
	iack_func[interrupt_level] = func;
}

void exception_withdraw(unsigned int interrupt_level)
{
	SKYEYE_DBG("Exception withdrawn at interrupt level %d\n", interrupt_level);
	if(iack_func[interrupt_level] == NULL) {
		SKYEYE_ERR("Attempting to withdraw interrupt level %d which is not set.\n",
				interrupt_level);
	}
	exception_pending &= ~(0x1 << interrupt_level);
	iack_func[interrupt_level] = NULL;
}

/* This table is for whether the PC should be set to the next instruction
 * after the fault, or the current instruction, this is only the first 16
 * Vectors.. all others are '0'
 * 
 *  0 = Next address  1 = Fault address */
static char exception_pc_location[16] = {
	0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0 };

void exception_push_stack_frame(short vector)
{
	unsigned int PC_to_push = memory_core.pc;
	unsigned int stack_frame;

	/* Restore the PC to the fault address */
	SKYEYE_DBG("pushing exception stack frame for exception vector=%d\n", vector);
	if(vector < 16) {
		if(exception_pc_location[vector] == 1)
			PC_to_push = memory_core.pc_instruction_begin;
	}

	/* See if we can read from SP-4 and SP-8 */
	if(!memory_seek(memory_core.a[7]-4) || !memory_seek(memory_core.a[7]-8)) {
		/* Push won't fit */
		printf("pushing to SP=0x%08lx for vector %d would cause an error\n", memory_core.a[7], vector);
		/* location of a known good stack pointer:
		 * - 5206, the SP is in the MBAR, 32 bit offset #1
		 * */
		Memory_Retr(&memory_core.a[7], 32, memory_core.vbr);
		printf("SP reset to 0x%08lx\n", memory_core.a[7]);
		/* Force return to monitor for debugging.*/
		printf("Forcing Autovector Interrupt 7\n");
		exception_push_stack_frame(31);
		//Monitor_HandleException(31);
		exception_restore_from_stack_frame();
	}



	
	/* Stack Frame:
	 * 31      27        25             17       15            0
	 * +--------+---------+-------------+---------+------------+
	 * | Format | FS[3:2] | Vector[7:0] | FS[1:0] |     SR     |
	 * +--------+---------+-------------+---------+------------+
	 * |                 PC                                    |
	 * +-------------------------------------------------------+
	 */

	/* Build the stack frame in a portable fashion */
	stack_frame = 	((0x4 | (memory_core.a[7] & 0x3)) << 28) |	
			(0x0 << 26) |
			((vector & 0xFF) << 18) |
			(0x0 << 16) |
			(memory_core.sr & 0xFFFF);

	SKYEYE_DBG("Pushing PC [0x%x] and StackFrame [0x%x]\n", PC_to_push,
			 *(int *)&stack_frame);

	/* Align the stack to the next longword offset */
/*	FIXME: I'm not convinced that this is correct
	memory_core.a[7] &= 0xfffffffc;*/

	/* Push the PC to the stack */
	Stack_Push(32, PC_to_push);
	/* Push the rest of the stack frame */
	Stack_Push(32, *(int *)&stack_frame);
}

void exception_restore_from_stack_frame(void)
{
	int frame;
	/* Pop the SR and PC off the stack */
	frame = Stack_Pop(32);
	memory_core.sr = frame & 0x0000FFFF;
	memory_core.pc = Stack_Pop(32);

	/* Align the stack according to the format */
/*	FIXME: I'm not convinced that this is correct 
	memory_core.a[7] += (frame & 0x30000000 >> 28);*/

	SKYEYE_DBG("Set SR=0x%08lx\n", memory_core.sr);
	SKYEYE_DBG("Set PC=0x%08lx\n", memory_core.pc);
}


int exception_do_raw_exception(short vector)
{
	unsigned int offset=0;
	static struct _memory_segment *seg;
	/* Find the jump offset in the vbr */
	SKYEYE_DBG("Doing Exception Vector=%d, vbr=0x%08lx\n", vector, 
			memory_core.vbr);
	/* If this falis, we could go into an infinite loop, with an invalid
	 * memory access exception */
	if(!Memory_Retr(&offset, 32, memory_core.vbr + (vector*4))) return 0;
	
	SKYEYE_DBG("ISR is at 0x%08lx\n", offset);

	/* Assert the S bit, and clear the T bit */
	SRBits->S = 1;
	SRBits->T = 0;

	/* If the offset is in the rom, (the base_register for the
	 *  segment the ISR is in is the address of the rombar)
	 *  then we'll ask the monitor to  handle the exception */
	seg = memory_find_segment_for(offset);
	if( seg->base_register == &memory_core.rombar) {
		
		/* Handler in rom, somwhere.  Ask monitor to handle the 
		 * exception for us .
		 * Monitor provides an alternative for every exception */
		//Monitor_HandleException(vector);
		/* Restore the process for monitor, because it doens't
		 * know how to do it */
		exception_restore_from_stack_frame();
		return 0;
	}
	memory_core.pc=offset;

	SKYEYE_DBG("Set PC to ISR offset [0x%x]\n", memory_core.pc);
	SKYEYE_DBG("Done\n");
	return 0;
}


int exception_do_exception(short vector)
{
	//return 0;
	exception_push_stack_frame(vector);
	return exception_do_raw_exception(vector);
}

