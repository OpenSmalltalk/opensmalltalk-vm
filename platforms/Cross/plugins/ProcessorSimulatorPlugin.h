/* Common include file for the Cog processor simulator plugins.
 * Plugins using this file must define NumIntegerRegisterStateFields
 * and WordType as either a 32-bit or a 64-bit unsigned integer type,
 * depending on the word size of the processor being simulated.
 */

#include <sys/types.h>

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
 * Single-step *cpu using memory as its memory.
 * Answer 0 on success, or an integer error code if something went awry.
 */
extern long  singleStepCPUInSizeMinAddressReadWrite(void *cpu, void *memory,
					uintptr_t byteSize, uintptr_t minReadAddr, uintptr_t minWriteAddr);
/*
 * Run *cpu using memory as its memory. Use interpreterProxy's
 * interruptCheckChain to cease simulating on an event/interrupt.
 * Answer an integer error code when the processor hits some exception.
 * Answer 0 when interrupted.
 */
extern long	runCPUInSizeMinAddressReadWrite(void *cpu, void *memory,
			uintptr_t byteSize, uintptr_t minReadAddr, uintptr_t minWriteAddr);
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
extern long disassembleForAtInSize(void *cpu, uintptr_t laddr,
									void *memory, uintptr_t byteSize);
/*
 * The saved error if the previous singleStepIn failed.
 */
extern long   errorAcorn();
/*
 * The current log (if singleStep failed with SomethingLoggedError), also
 * used for disassembly.
 */
extern char *getlog(long *len);

/*
 * Fill an integer array with the register state, including the pc and, if
 * appropriate, the condition code flags, etc.
 */
extern void storeIntegerRegisterStateOfinto(void *cpu, WordType *registerState);
