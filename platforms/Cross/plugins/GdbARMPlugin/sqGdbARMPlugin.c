// If this doesn't come first then e.g. Manjaro linux on Raspberry Pi
// complains that config.h has been included too late.
#include "config.h" 

#define COG 1
#define FOR_COG_PLUGIN 1

#include "sqAssert.h"
#include "GdbARMPlugin.h"

//disassembler
// bfd.h expects bfd/config.h to be included. But bfd/config.h expects
// __CONFIG_H__ to have been defined. Placate it.
#define __CONFIG_H__ 1
#include "bfd/config.h" // expected to be in [../]../gdbarm32/bfd/config.h
#include <bfd.h>
#include <dis-asm.h>
#include <opcodes/disassemble.h>

#include <stdarg.h>

//emulator
#include <armdefs.h>
#include <armemu.h>

ARMul_State*	lastCPU = NULL;

// These two variables exist, in case there are library-functions which write to a stream.
// In that case, we would write functions which print to that stream instead of stderr or similar
#define LOGSIZE 4096
static char	gdb_log[LOGSIZE+1];
static int	gdblog_index = 0;

uintptr_t	minReadAddress, minWriteAddress;

/* The interrupt check chain is a convention wherein functions wanting to be
 * called on interrupt check chain themselves together by remembering the head
 * of the interruptCheckChain when they register to be informed. See the source
 * of the plugin itself, src/plugins/GdbARMPlugin/GdbARMPlugin.c
 */
void	(*prevInterruptCheckChain)() = 0;

void
print_state(ARMul_State *state)
{
	printf("ErorCode: %u\tNextInstr: %u\ttheMemory: %p\tNumInstrs: %ld\tPC: 0x%u\tmode: %u\tEndCondition: %u\tprog32Sig: %s\tEmulate: %u\n", 
		state->ErrorCode, state->NextInstr, state->MemDataPtr, 
		state->NumInstrs, state->Reg[15], 
		state->Mode, state->EndCondition, 
		state->prog32Sig == LOW ? "LOW" : (state->prog32Sig == HIGH ? "HIGH" :
		(state->prog32Sig == HIGHLOW ? "HIGHLOW" : "???")), state->Emulate);
}

void*
newCPU()
{
	if (lastCPU == NULL) ARMul_EmulateInit();
	lastCPU = ARMul_NewState();
#if 0 /* XScale seems to disable floating point */
	ARMul_SelectProcessor (lastCPU, ARM_v5_Prop | ARM_v5e_Prop | ARM_XScale_Prop | ARM_v6_Prop);
#else /* see sim_create_inferior in sim/arm/wrapper.c */
	ARMul_SelectProcessor (lastCPU, ARM_v5_Prop | ARM_v5e_Prop | ARM_v6_Prop);
#endif
	return lastCPU;
}

long
resetCPU(void *cpu)
{
	unsigned int i, j;
	ARMul_State *state = (ARMul_State*) cpu;
	// test whether the supplied instance is an ARMul type?

	gdblog_index = 0;

	// reset registers in all modes
	for (i = 0; i < 16; i++) {
		state->Reg[i] = 0;
		for (j = 0; j < 7; j++)
			state->RegBank[j][i] = 0;
	}
	for (i = 0; i < 7; i++)
		state->Spsr[i] = 0;
	for (i = 0; i < 32; i++)
		state->VFP_Reg[i].dword = 0ULL;
	// make sure the processor is at least in 32-bit mode
	if (!state->prog32Sig)
		state->prog32Sig = HIGH;
	ARMul_Reset(state);
	return 0;
}

static inline long
runOnCPU(ARMul_State *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr, ARMword (*runOrStep)(ARMul_State*))
{
	assert(lastCPU == cpu);

	assert(cpu->prog32Sig == HIGH || cpu->prog32Sig == HIGHLOW);
	// test whether the supplied instance is an ARMul type?
	cpu->MemDataPtr = (unsigned char *)memory;
	cpu->MemSize = byteSize;
	minReadAddress = minAddr;
	minWriteAddress = minWriteMaxExecAddr;

	gdblog_index = 0;

	cpu->EndCondition = NoError;
	cpu->NextInstr = RESUME;

	cpu->Reg[15] = runOrStep(cpu);

	// collect the PSR from their dedicated flags to have easy access from the image.
	ARMul_SetCPSR(cpu, ARMul_GetCPSR(cpu));

	if (cpu->EndCondition != NoError)
		return cpu->EndCondition;

	return gdblog_index == 0 ? 0 : SomethingLoggedError;
}

ARMword
ARMul_Emulate26 (ARMul_State * state)
{
	assertf("GdbARMPlugin is in Thumb mode.  This should not happen!");
	/* i.e. we *should never* switch to Thumb mode */
	state->EndCondition = PanicError;
	return state->Reg[15];
}

long
singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, ARMul_DoInstr);
}

long
runCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, ARMul_DoProg);
}

/*
 * Currently a dummy for ARM Processor Alien.
 */
void
flushICacheFromTo(void *cpu, uintptr_t saddr, uintptr_t eaddr)
{
#if 0
# error not yet implemented
#endif
}

int
gdb_log_printf(void *stream, const char *format, ...)
{
	va_list arg;
	int n;
	va_start(arg,format);

	if (stream == NULL){
		n = vsnprintf((char*) (&gdb_log) + gdblog_index, LOGSIZE-gdblog_index, format, arg);
		gdblog_index = gdblog_index + n;
	} else {
		vfprintf(stream, format, arg);
	}
	return 0;
}

long
disassembleForAtInSize(void *cpu, uintptr_t laddr,
			void *memory, uintptr_t byteSize)
{
	gdblog_index = 0;
	// ignore the cpu
	// start disassembling at laddr relative to memory
	// stop disassembling at memory+byteSize

	disassemble_info *dis = (disassemble_info*) calloc(1, sizeof(disassemble_info));
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

long
errorAcorn(void) { return 0; }

char *
getlog(long *len)
{
	*len = gdblog_index;
	return gdb_log;
}

void
storeIntegerRegisterStateOfinto(void *cpu, WordType *registerState)
{
	for (int n = -1; ++n < 16;)
		registerState[n] = ((ARMul_State *)cpu)->Reg[n];
#if 1
	registerState[16] = ((ARMul_State *)cpu)->Cpsr;
#else
	registerState[16] = ((((ARMul_State *)cpu)->NFlag & 1) << 5)
					  + ((((ARMul_State *)cpu)->ZFlag & 1) << 4)
					  + ((((ARMul_State *)cpu)->CFlag & 1) << 3)
					  + ((((ARMul_State *)cpu)->VFlag & 1) << 2)
					  +  (((ARMul_State *)cpu)->IFFlags & 3);
#endif
}
