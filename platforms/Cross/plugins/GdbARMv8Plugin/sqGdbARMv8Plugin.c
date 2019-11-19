#define COG 1
#define FOR_COG_PLUGIN 1

#include "sqAssert.h"
#include "GdbARMPlugin.h"
//disassembler
#if __APPLE__ && __MACH__
# include "config.h"
#endif
#include <bfd.h>
#include <dis-asm.h>

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

ulong	minReadAddress, minWriteAddress;

/* The interrupt check chain is a convention wherein functions wanting to be
 * called on interrupt check chain themselves together by remembering the head
 * of the interruptCheckChain when they register to be informed. See the source
 * of the plugin itself, src/plugins/GdbARMv8Plugin/GdbARMv8Plugin.c
 */
void	(*prevInterruptCheckChain)() = 0;

void
print_state(ARMul_State* state)
{
	printf("NextInstr: %i\ttheMemory: 0x%p\tNumInstrs: 0x%p\tPC: 0x%p\tmode: %i\tEndCondition: %i\tprog32Sig: %s\tEmulate: %i\n", 
		state->NextInstr, state->MemDataPtr, 
		state->NumInstrs, state->Reg[15], 
		state->Mode, state->EndCondition, 
		state->prog32Sig == LOW ? "LOW" : (state->prog32Sig == HIGH ? "HIGH" :
		(state->prog32Sig == HIGHLOW ? "HIGHLOW" : "???")), state->Emulate);
}

void*
newCPU()
{
	if(lastCPU == NULL) ARMul_EmulateInit();
	lastCPU = ARMul_NewState();
#if 0 /* XScale seems to disable floating point */
	ARMul_SelectProcessor (lastCPU, ARM_v5_Prop | ARM_v5e_Prop | ARM_XScale_Prop | ARM_v6_Prop);
#else /* see sim_create_inferior in sim/arm/wrapper.c */
	ARMul_SelectProcessor (lastCPU, ARM_v5_Prop | ARM_v5e_Prop | ARM_v6_Prop);
#endif
	return lastCPU;
}

long
resetCPU(void* cpu)
{
	unsigned int i, j;
	ARMul_State* state = (ARMul_State*) cpu;
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
runOnCPU(void *cpu, void *memory, 
		ulong byteSize, ulong minAddr, ulong minWriteMaxExecAddr, ARMword (*run)(ARMul_State*))
{
	ARMul_State* state = (ARMul_State*) cpu;
	lastCPU = state;

	assert(state->prog32Sig == HIGH || state->prog32Sig == HIGHLOW);
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

long
singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		ulong byteSize, ulong minAddr, ulong minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, ARMul_DoInstr);
}

long
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

long
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

long
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

long
errorAcorn(void) { return 0; }

char *
getlog(long *len)
{
	*len = gdblog_index;
	return gdb_log;
}

/* Adapted from sim/aarch64/memory.c -- Memory accessor functions for the AArch64 simulator

   Copyright (C) 2015-2019 Free Software Foundation, Inc.

 */

#if 0
#include "config.h"
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "libiberty.h"

#include "memory.h"
#include "simulator.h"

#include "sim-core.h"
#endif

/* FIXME: AArch64 requires aligned memory access if SCTRLR_ELx.A is set,
   but we are not implementing that here.  */
#define FETCH_FUNC(RETURN_TYPE, ACCESS_TYPE, NAME, N)					\
  RETURN_TYPE															\
  aarch64_get_mem_##NAME (sim_cpu *cpu, uint64_t address)				\
  { RETURN_TYPE val;													\
	if (address < minReadAddress										\
	 || address + N > theMemorySize)									\
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);					\
	memcpy(&val, theMemory + address, N);								\
    return val;															\
  }

FETCH_FUNC(uint64_t, uint64_t, u64, 8)
FETCH_FUNC(int64_t,   int64_t, s64, 8)
FETCH_FUNC(uint32_t, uint32_t, u32, 4)
FETCH_FUNC(int32_t,   int32_t, s32, 4)
FETCH_FUNC(uint32_t, uint16_t, u16, 2)
FETCH_FUNC(int32_t,   int16_t, s16, 2)
FETCH_FUNC(uint32_t,  uint8_t, u8, 1)
FETCH_FUNC(int32_t,    int8_t, s8, 1)

void
aarch64_get_mem_long_double (sim_cpu *cpu, uint64_t address, FRegister *a)
{
	if (address < minReadAddress
	 || address + 16 > theMemorySize)
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);
	memcpy(a, theMemory + address, 16);
}

/* FIXME: Aarch64 requires aligned memory access if SCTRLR_ELx.A is set,
   but we are not implementing that here.  */
#define STORE_FUNC(TYPE, NAME, N)										\
  void																	\
  aarch64_set_mem_##NAME (sim_cpu *cpu, uint64_t address, TYPE value)	\
  {																		\
	if (address < minWriteAddress										\
	 || address + N > theMemorySize)									\
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);					\
	memcpy(theMemory + address, &value, N);								\
  }

STORE_FUNC (uint64_t, u64, 8)
STORE_FUNC (int64_t,  s64, 8)
STORE_FUNC (uint32_t, u32, 4)
STORE_FUNC (int32_t,  s32, 4)
STORE_FUNC (uint16_t, u16, 2)
STORE_FUNC (int16_t,  s16, 2)
STORE_FUNC (uint8_t,  u8, 1)
STORE_FUNC (int8_t,   s8, 1)

void
aarch64_set_mem_long_double (sim_cpu *cpu, uint64_t address, FRegister a)
{
	if (address < minReadAddress
	 || address + 16 > theMemorySize)
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);
	memcpy(theMemory + address, a, 16);
}

void
aarch64_get_mem_blk(sim_cpu *cpu, uint64_t address,
					char *buffer, unsigned length)
{
	if (address < minReadAddress
	 || address + length > theMemorySize)
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);
	memcpy(address, theMemory + address, length);
}

const char *
aarch64_get_mem_ptr(sim_cpu *cpu, uint64_t address) { return address; }

/* We implement a combined stack and heap.  That way the sbrk()
   function in libgloss/aarch64/syscalls.c has a chance to detect
   an out-of-memory condition by noticing a stack/heap collision.

   The heap starts at the end of loaded memory and carries on up
   to an arbitary 2Gb limit.  */

uint64_t
aarch64_get_heap_start (sim_cpu *cpu) { return 0; }

uint64_t
aarch64_get_stack_start (sim_cpu *cpu) { return STACK_TOP; }
