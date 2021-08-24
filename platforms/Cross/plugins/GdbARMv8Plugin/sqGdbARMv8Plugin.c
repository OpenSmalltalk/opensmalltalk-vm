#define COG 1
#define FOR_COG_PLUGIN 1

#include "sqAssert.h"
#include "GdbARMv8Plugin.h"

#include <stdarg.h>

#include <aarch64/config.h>
#undef PACKAGE
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_VERSION
#include <simulator.h>
#include <memory.h>
#undef PACKAGE
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_VERSION
#include <bfd.h>
#include <disassemble.h>

#include "sqSetjmpShim.h"

struct sim_state *lastCPU = NULL;
sim_cpu initialSimState = {0,};

jmp_buf error_abort;

// These two variables exist, in case there are library-functions which write to a stream.
// In that case, we would write functions which print to that stream instead of stderr or similar
#define LOGSIZE 4096
static char	gdb_log[LOGSIZE+1];
static int	gdblog_index = 0;

static unsigned char *theMemory = 0;
static unsigned long  theMemorySize;
static unsigned long  minReadAddress;
static unsigned long  minWriteAddress;
static int            theErrorAcorn;
static int            continueRunning;

/* The interrupt check chain is a convention wherein functions wanting to be
 * called on interrupt check chain themselves together by remembering the head
 * of the interruptCheckChain when they register to be informed. See the source
 * of the plugin itself, src/plugins/GdbARMv8Plugin/GdbARMv8Plugin.c
 */
void	(*prevInterruptCheckChain)() = 0;

void *
newCPU()
{
	if (!lastCPU) {
		char *av8_argv[] = {"ARMv8", 0};

		lastCPU = sim_open(SIM_OPEN_STANDALONE, 0, 0, av8_argv);
		initialSimState = *(lastCPU->cpu[0]);
		memset(&initialSimState.gr[0],
				0,
				(char *)&initialSimState.base - (char *)&initialSimState.gr[0]);
		lastCPU->base.engine.jmpbuf = error_abort;
	}
	return lastCPU->cpu[0];
}

long
resetCPU(void *cpu)
{
	gdblog_index = 0;

	*(sim_cpu *)cpu = initialSimState;
	if (lastCPU->cpu[0]) /* why does this get nilled? eem 2019/11/19 */
		*(lastCPU->cpu[0]) = initialSimState;
	return 0;
}

#define run 0
#define step 1

static inline long
runOnCPU(sim_cpu *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr, int runOrStep)
{
	uint64_t postpc = cpu->pc + sizeof(cpu->instr);

	theMemory = (unsigned char *)memory;
	theMemorySize = byteSize;
	minReadAddress = minAddr;
	minWriteAddress = minWriteMaxExecAddr;
	theErrorAcorn = 0;

	if ((theErrorAcorn = setjmp(error_abort)) != 0)
		return theErrorAcorn;

	assert(lastCPU->base.engine.jmpbuf = error_abort);
	gdblog_index = 0;

	if (runOrStep == step) {
		if (postpc <= minWriteMaxExecAddr
		 && aarch64_step(cpu)
		 && cpu->nextpc <= minWriteMaxExecAddr)
			cpu->pc = cpu->nextpc;
	}
	else {
		continueRunning = 1;
		while (continueRunning
			&& postpc <= minWriteMaxExecAddr
			&& aarch64_step(cpu)
			&& !gdblog_index) {
			if (cpu->nextpc <= minWriteMaxExecAddr)
				cpu->pc = cpu->nextpc;
			postpc = cpu->nextpc + sizeof(cpu->instr);
		}
	}
	if (postpc > minWriteMaxExecAddr
	 || cpu->nextpc > minWriteMaxExecAddr)
		return InstructionPrefetchError;

#if 0
	// collect the PSR from their dedicated flags to have easy access from the image.
	ARMul_SetCPSR(state, ARMul_GetCPSR(state));

	if (state->EndCondition != NoError)
		return state->EndCondition;
#endif
	if (theErrorAcorn)
		return theErrorAcorn;

	return gdblog_index == 0 ? 0 : SomethingLoggedError;
}

long
singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, step);
}

long
runCPUInSizeMinAddressReadWrite(void *cpu, void *memory, 
		uintptr_t byteSize, uintptr_t minAddr, uintptr_t minWriteMaxExecAddr)
{
	return runOnCPU(cpu, memory, byteSize, minAddr, minWriteMaxExecAddr, run);
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
gdb_log_printf(void *stream, const char * format, ...)
{
	va_list arg;
	int n;
	va_start(arg,format);

	if (!stream) {
		n = vsnprintf((char*) (&gdb_log) + gdblog_index, LOGSIZE-gdblog_index, format, arg);
		gdblog_index = gdblog_index + n;
	}
	else
		vfprintf(stream, format, arg);
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

	disassemble_info* dis = (disassemble_info*) calloc(1, sizeof(disassemble_info));
	// void init_disassemble_info (struct disassemble_info *dinfo, void *stream, fprintf_ftype fprintf_func)
	init_disassemble_info ( dis, NULL, gdb_log_printf);

	dis->arch = bfd_arch_aarch64;
#if 0
	dis->mach = bfd_mach_aarch64_unknown;
#endif

	// sets some fields in the structure dis to architecture specific values
	disassemble_init_for_target( dis );

	dis->buffer_vma = 0;
	dis->buffer = memory;
	dis->buffer_length = byteSize;

	// first print the address
	gdb_log_printf( NULL, "%08lx: ", laddr);
	//other possible functions are listed in opcodes/dissassemble.c
	unsigned int size = print_insn_aarch64((bfd_vma) laddr, dis);

	free(dis);
	gdb_log[gdblog_index+1] = 0;

	return size;
}

void
forceStopRunning() { continueRunning = 0; }

long
errorAcorn(void) { return errorAcorn; }

char *
getlog(long *len)
{
	*len = gdblog_index;
	return gdb_log;
}

void
storeIntegerRegisterStateOfinto(void *cpu, WordType *registerState)
{
	for (int n = -1; ++n < 32;)
		registerState[n] = ((sim_cpu *)cpu)->gr[n].u64;
	registerState[32] = ((sim_cpu *)cpu)->pc;
	registerState[33] = ((sim_cpu *)cpu)->CPSR;
}

/* Adapted from sim/aarch64/memory.c -- Memory accessor functions for the AArch64 simulator

   Copyright (C) 2015-2019 Free Software Foundation, Inc.

 */

/* FIXME: AArch64 requires aligned memory access if SCTRLR_ELx.A is set,
   but we are not implementing that here.  */
#define FETCH_FUNC(RETURN_TYPE, ACCESS_TYPE, NAME, N)					\
  RETURN_TYPE															\
  aarch64_get_mem_##NAME (sim_cpu *cpu, uint64_t address)				\
  { RETURN_TYPE val;													\
	if (address < minReadAddress										\
	 || address + N > theMemorySize)									\
		longjmp(error_abort,MemoryBoundsError);							\
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
		longjmp(error_abort,MemoryBoundsError);
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
		longjmp(error_abort,MemoryBoundsError);							\
	memcpy(theMemory + address, &value, N);								\
  }

STORE_FUNC(uint64_t, u64, 8)
STORE_FUNC( int64_t, s64, 8)
STORE_FUNC(uint32_t, u32, 4)
STORE_FUNC( int32_t, s32, 4)
STORE_FUNC(uint16_t, u16, 2)
STORE_FUNC( int16_t, s16, 2)
STORE_FUNC(uint8_t,   u8, 1)
STORE_FUNC( int8_t,   s8, 1)

void
aarch64_set_mem_long_double (sim_cpu *cpu, uint64_t address, FRegister a)
{
	if (address < minWriteAddress
	 || address + 16 > theMemorySize)
		longjmp(error_abort,MemoryBoundsError);
	memcpy(theMemory + address, &a, 16);
}

void
aarch64_get_mem_blk(sim_cpu *cpu, uint64_t address,
					char *buffer, unsigned length)
{
	if (address < minReadAddress
	 || address + length > theMemorySize)
		longjmp(error_abort,MemoryBoundsError);
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
