/* Bochs seems to use error code 1 for execution errors.
 * So we use > 1 for various errors
 */
#define NoError 0
#define ExecutionError 1
#define BadCPUInstance 2
#define MemoryBoundsError 3
#define PanicError 4
#define UnsupportedOperationError 5
#define SomethingLoggedError 6

#if !defined(ulong)
typedef unsigned long ulong;
#endif

/*
 * Answer a pointer to a new Bochs x64 CPU (an instance of C++ class bx_cpu_c)
 */
extern void *newCPU();
/*
 * reset the cpu to register contents 0, protected 64-bit mode.
 */
extern int   resetCPU(void *cpu);
/*
 * Single-step *cpu (a bx_cpu_c instance) using memory as its memory.
 * Answer 0 on success, or an integer error code if something went awry.
 */
extern int  singleStepCPUInSizeMinAddrReadWrite(void *cpu, void *memory,
					ulong byteSize, ulong minReadAddr, ulong minWriteAddr);
/*
 * Run *cpu (a bx_cpu_c instance) using memory as its memory.
 * Answer an integer error code when the processor hits some exception.
 * Answer 0 when it is interrupted.
 */
extern int	runCPUInSizeMinAddrReadWrite(void *cpu, void *memory,
					ulong byteSize, ulong minReadAddr, ulong minWriteAddr);
/*
 * Flush any icache entries from start to end
 */
extern void	flushICacheFromTo(void *cpu, ulong strt, ulong nd);
/*
 * force runCPUInSize to exit asap.  Used by interrupts.
 */
extern void	forceStopRunning(void);
/*
 * The previous entry in the interruptCheckChain so forceStopRunning can chain.
 */
extern void (*prevInterruptCheckChain)();
/*
 * Disassemble the instruction at address in memory, writing the output to the
 * log.
 */
extern int disassembleForAtInSize(void *cpu, ulong laddr,
									void *memory, ulong byteSize);
/*
 * The saved error if the previous singleStepIn failed.
 */
extern int   errorAcorn();
/*
 * The current log (if singleStep failed with SomethingLoggedError).
 */
extern char *getlog(long *len);
