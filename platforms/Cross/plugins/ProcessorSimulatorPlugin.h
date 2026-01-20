/* Common include file for the Cog processor simulator plugins.
 * Plugins using this file must define NumIntegerRegisterStateFields
 * and WordType as either a 32-bit or a 64-bit unsigned integer type,
 * depending on the word size of the processor being simulated.
 */

#include <sys/types.h>
#include <stdint.h>

#define NoError 0
#define ExecutionError 1
#define BadCPUInstance 2
#define MemoryBoundsError 3
#define PanicError 4
#define UnsupportedOperationError 5
#define SomethingLoggedError 6
#define InstructionPrefetchError 7
#define InitializationError 8

/*
 * Answer a pointer to a new CPU (an instance of whatever the simulator uses)
 */
extern void *newCPU();
/*
 * reset the cpu to register contents 0, default mode.
 */
extern long   resetCPU(void *cpu);

/*
 * The two execution primitives, single-step, and run, execute (an) instruction(s) at the
 * processor's program counter (pc) fetched from the memory argument. memory is readable
 * at or above minReadAddr, writable at or above minWriteMaxExecAddr, and executable
 * below minWriteMaxExecAddr.
 *
 * Normal execution of out-of-range instructions must cause errors that leave the
 * processor in a valid state:
 *  reads and writes to/from addresses at or above the size of memory must trap, leaving
 *	the pc pointing to the read/write instruction.
 *	Control transfers to addresses at or above the size of memory must trap, leaving
 *	the pc pointing to the control transfer instruction.
 *
 * Other exceptions (reading below minReadAddr, writing below minWriteMaxExecAddr,
 * trying to execute instructions at or above minWriteMaxExecAddr) should leave the
 * processor in whatever state the actual processor would if it were to do the same
 * on an unreadbale, unwritable, or unexecutable page. See CogProcessorSimulatorTests
 * in the Cog package.
 */
/*
 * Single-step *cpu using memory as its memory.
 * Answer an integer error code if something went awry (as specified above).
 * Answer 0 on success.
 */
extern long  singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory,
					uintptr_t byteSize, uintptr_t minReadAddr, uintptr_t minWriteMaxExecAddr);
/*
 * Run *cpu using memory as its memory. Use interpreterProxy's
 * interruptCheckChain to cease simulating on an event/interrupt.
 * Answer an integer error code if and when something went awry (as specified above).
 * Answer 0 when interrupted.
 */
extern long	runCPUInSizeMinAddressReadWrite(void *cpu, void *memory,
			uintptr_t byteSize, uintptr_t minReadAddr, uintptr_t minWriteMaxExecAddr);
/*
 * Flush any icache entries from start to end
 */
extern void	flushICacheFromTo(void *cpu, uintptr_t start, uintptr_t end);
/*
 * force runCPUInSize to exit asap.  Used by interrupts.
 */
extern void	forceStopRunning();
/*
 * The previous entry in the interruptCheckChain so forceStopRunning can chain.
 */
extern void (*prevInterruptCheckChain)();
/*
 * Disassemble the instruction at address in memory, writing the output to the
 * log. Answer the number of bytes in the instruction disassembled.
 */
extern long disassembleForAtInSizePrintAddress(void *cpu, uintptr_t laddr,
								void *memory, uintptr_t byteSize, int printAddress);
/*
 * The saved error if the previous singleStepCPU/runCPU failed.
 */
extern long   errorAcorn();
/*
 * The current log (if singleStepCPU/runCPU failed with SomethingLoggedError), also
 * used for disassembly.
 */
extern char *getlog(long *len);

/*
 * Fill an integer array with the register state, including the pc and, if
 * appropriate, the condition code flags, etc.
 */
extern void storeIntegerRegisterStateOfinto(void *cpu, WordType *registerState);

/*
 * Answer the range of double-precision floating-point registers in use,
 * starting at the first. So if the only 5th dpfp register is zero the answer is 5.
 */
extern int fpRegHighTide(void *cpu);

/*
 * Fill a 64-bit integer array as per storeIntegerRegisterStateOfinto followed
 * by the specified number of double-precision floating-point registers.
 */
extern void storeRegisterStateOfnfpinto(void *cpu, int nfpRegs, uint64_t *registerState);

/*
 * Answer zero if a 64-bit performance counter is available, storing its value
 * through the pointer if so.
 * Answer an integer error code if and when something went awry (as specified above).
 */
extern long performanceCounter64ofinto(void *cpu, uintptr_t *perfCounterp);

/*
 * Answer zero if the 64-bit performance counter could be incremented by increment.
 * Answer an integer error code if and when something went awry (as specified above).
 */
extern long incrementPerformanceCounter64ofby(void *cpu, uintptr_t increment);
