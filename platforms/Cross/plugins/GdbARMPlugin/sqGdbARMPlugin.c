#define COG 1
#define FOR_COG_PLUGIN 1

#include "GdbARMPlugin.h"
//disassembler
#include <gdbconfig.h> /*  TPR - <---- this is actually a *link* to the gdb gdb-7.6/bfd/config.h because it otherwise clashes with the Squeak one also in the assorted include paths. Must be a proper way to handle this case; it must happen elsewhere */
#include <bfd.h>
#include <dis-asm.h>

#include <stdarg.h>

//emulator
#include <armdefs.h>
#include <armemu.h>

ARMul_State*	lastCPU = NULL;

/* When compiling armulator, it generally sets NEED_UI_LOOP_HOOK, which 
	makes the main emulation step require this symbol to be set. */
extern int (*deprecated_ui_loop_hook) (int) = NULL;

// These two variables exist, in case there are library-functions which write to a stream.
// In that case, we would write functions which print to that stream instead of stderr or similar
#define LOGSIZE 4096
static char	gdb_log[LOGSIZE+1];
static int	gdblog_index = 0;

ulong	minReadAddress, minWriteAddress;

// what is that for?
	   void			(*prevInterruptCheckChain)() = 0;

void
print_state(ARMul_State* state)
{
	printf("NextInstr: %i\ttheMemory: 0x%p\tNumInstrs: 0x%p\tPC: 0x%p\tmode: %i\tEndCondition: %i\tEmulate: %i\n", 
		state->NextInstr, state->MemDataPtr, 
		state->NumInstrs, state->Reg[15], 
		state->Mode, state->EndCondition, 
		state->Emulate);
}

void*
newCPU()
{
	if(lastCPU == NULL) ARMul_EmulateInit();
	lastCPU = ARMul_NewState();
	ARMul_SelectProcessor (lastCPU, ARM_v5_Prop | ARM_v5e_Prop | ARM_XScale_Prop | ARM_v6_Prop);
	return lastCPU;
}

int
resetCPU(void* cpu)
{
	unsigned int i, j;
	ARMul_State* state = (ARMul_State*) cpu;
	// test whether the supplied instance is an ARMul type?
	
	gdblog_index = 0;
	
	// reset registers in all modes
	for (i = 0; i < 16; i++)
	{
		state->Reg[i] = 0;
		for (j = 0; j < 7; j++)
			state->RegBank[j][i] = 0;
	}
	for (i = 0; i < 7; i++)
		state->Spsr[i] = 0;
	
	ARMul_Reset(state);
	return 0;
}

int
runOnCPU(void *cpu, void *memory, 
		ulong byteSize, ulong minAddr, ulong minWriteMaxExecAddr, ARMword (*run)(ARMul_State*))
{
	ARMul_State* state = (ARMul_State*) cpu;
	lastCPU = state;
	
	// test whether the supplied instance is an ARMul type?
	state->MemDataPtr = (unsigned char*) memory;
	state->MemSize = byteSize;
	minReadAddress = minAddr;
	minWriteAddress = minWriteMaxExecAddr;
	
	gdblog_index = 0;
	
	state->EndCondition = NoError;
	state->NextInstr = RESUME;
	
	state->Reg[15] = run(state);
	
	// collect the PSR from their dedicated flags to have easy access from the image.
	ARMul_SetCPSR(state, ARMul_GetCPSR(state));
	
	if(state->EndCondition != NoError){
		return state->EndCondition;
	}
	
	return gdblog_index == 0 ? 0 : SomethingLoggedError;
}

int
singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		ulong byteSize, ulong minAddr, ulong minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, ARMul_DoInstr);
}

int
runCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		ulong byteSize, ulong minAddr, ulong minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, ARMul_DoProg);
}

/*
 * Currently a dummy for ARM Processor Alien.
 */
void
flushICacheFromTo(void *cpu, ulong saddr, ulong eaddr)
{
#if 0
# error not yet implemented
#endif
}

int
gdb_log_printf(void* stream, const char * format, ...)
{
	va_list arg;
	int n;
	va_start(arg,format);
	
	if(stream == NULL){
		n = vsnprintf((char*) (&gdb_log) + gdblog_index, LOGSIZE-gdblog_index, format, arg);
		gdblog_index = gdblog_index + n;
	} else {
		vfprintf(stream, format, arg);
	}
	return 0;
}

int
disassembleForAtInSize(void *cpu, ulong laddr,
			void *memory, ulong byteSize)
{
	gdblog_index = 0;
	// ignore the cpu
	// start disassembling at laddr relative to memory
	// stop disassembling at memory+byteSize
	
	disassemble_info* dis = (disassemble_info*) calloc(1, sizeof(disassemble_info));
	// void init_disassemble_info (struct disassemble_info *dinfo, void *stream, fprintf_ftype fprintf_func)
	init_disassemble_info ( dis, NULL, gdb_log_printf);
	
	dis->arch = bfd_arch_arm;
	dis->mach = bfd_mach_arm_unknown;
	
	// sets some fields in the structure dis to architecture specific values
	disassemble_init_for_target( dis );
	
	dis->buffer_vma = 0;
	dis->buffer = memory;
	dis->buffer_length = byteSize;
	
	// first print the address
	gdb_log_printf( NULL, "%08lx: ", laddr);
	//other possible functions are listed in opcodes/dissassemble.c
	unsigned int size = print_insn_little_arm((bfd_vma) laddr, dis);
	
	free(dis);
	gdb_log[gdblog_index+1] = 0;
	
	return size;
}

void
forceStopRunning()
{
	lastCPU->Emulate = STOP;
}

int
errorAcorn(void) { return 0; }

char *
getlog(long *len)
{
	*len = gdblog_index;
	return gdb_log;
}

// adding custom Software Interrupts to the ARMulator
unsigned __real_ARMul_OSHandleSWI(ARMul_State*, ARMword);
  
unsigned
__wrap_ARMul_OSHandleSWI (ARMul_State * state, ARMword number)
{
	switch(number)
	  {
		case 0x200000:
			// This is the SWI number which is returned by our memory interface 
			// if there is an instruction fetch for an illegal address.
			state->Emulate = STOP;
			state->EndCondition = InstructionPrefetchError;
			
			// during execution, the pc points the next fetch address, which is 8 byte after the current instruction.
			gdb_log_printf(NULL, "Illegal Instruction fetch address (%#p).", state->Reg[15]-8);
			return TRUE;
	  }
	return __real_ARMul_OSHandleSWI(state, number);
}
