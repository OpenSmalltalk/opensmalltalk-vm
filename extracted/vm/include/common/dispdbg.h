/*
 * Break-pointer debugging facilities for the StackInterpreter VM.
 * Edit this to install various debugging traps.  In a production
 * VM this header should define only the assert macros and empty
 * sendBreakpointreceiver and bytecodeDispatchDebugHook macros.
 */

#include "sqAssert.h"

#if !defined(VMBIGENDIAN)
# error "sqConfig.h does not define VMBIGENDIAN"
#elif !((VMBIGENDIAN == 1) || (VMBIGENDIAN == 0))
# error "sqConfig.h does not define VMBIGENDIAN as either 1 or 0"
#endif

/*
 * various definitions of the sendBreakpointreceiver macro for break-pointing at
 * specific sends.
 */
#if STACKVM
# define warnSendBreak() do { \
		suppressHeartbeatFlag = 1; \
		warning("send breakpoint (heartbeat suppressed)"); \
	} while (0)
# define warnMNUBreak() do { \
		suppressHeartbeatFlag = 1; \
		warning("MNU breakpoint (heartbeat suppressed)"); \
	} while (0)
#else
# define warnSendBreak() warning("send breakpoint")
# define warnMNUBreak() warning("MNU breakpoint")
#endif

#if PRODUCTION && !SENDTRACE /* default for no send breakpoint. */
# define sendBreakpointreceiver(sel, len, rcvr) 0
# define mnuBreakpointreceiver(sel, len, rcvr) 0

#elif SENDTRACE /* send tracing.  */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if (sendTrace) \
		printf("%.*s\n", (int)(len), (char *)(sel)); \
} while (0)
# define mnuBreakpointreceiver(sel, len, rcvr) 0

#elif 0 /* send trace/byte count.  */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if (sendTrace) \
		printf("%u %.*s\n", GIV(byteCount), (int)(len), (char *)(sel)); \
} while (0)
# define mnuBreakpointreceiver(sel, len, rcvr) 0

#else /* breakpoint for assert and debug configurations. */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if ((len) == breakSelectorLength \
	 && !strncmp((char *)(sel), breakSelector, breakSelectorLength)) { \
		warnSendBreak(); \
		if (0) sendTrace = 1; \
	} \
	if (sendTrace) \
		printf("%.*s\n", (int)(len), (char *)(sel)); \
} while (0)
# define mnuBreakpointreceiver(sel, len, rcvr) do { \
	if ((len) == -breakSelectorLength \
	 && !strncmp((char *)(sel), breakSelector, -breakSelectorLength)) { \
		warnMNUBreak(); \
		if (0) sendTrace = 1; \
	} \
} while (0)

#endif

/*
 * various definitions of the bytecodeDispatchDebugHook macro for
 * debugging code at the bytecode dispatch switch.
 */
#if STACKVM
# define ValidInstructionPointerCheck() \
	validInstructionPointerinMethodframePointer((usqInt)localIP, GIV(method), localFP)
#else
# define ValidInstructionPointerCheck() \
	(GIV(method) == iframeMethod(localFP) \
	 && validInstructionPointerinMethod((usqInt)localIP, GIV(method)))
#endif

#if PRODUCTION
# define bytecodeDispatchDebugHook() 0

#elif 1 /* check for valid instruction pointer */
# define bytecodeDispatchDebugHook() do { \
	if (!ValidInstructionPointerCheck()) \
		warning("invalidInstructionPointerinMethod"); \
  } while (0)
#elif 0 /* check for valid stack-related pointers */
# define DEBUG_DISABLE_HEARTBEAT 1
# define bytecodeDispatchDebugHook() do { \
	if (++GIV(byteCount) % 100000 == 0) \
		forceInterruptCheck(); \
	assertValidExecutionPointersimbarline(localIP,localFP,localSP,1,__LINE__); \
  } while (0)

#elif 0 /* maintain byteCount & break-point & heart-beat every 100k bytecodes */
# define DEBUG_DISABLE_HEARTBEAT 1
# define bytecodeDispatchDebugHook() do { \
	if (++GIV(byteCount) % 100000 == 0) \
		forceInterruptCheck(); \
	if (GIV(byteCount) == -1 /*256696UL*/) { \
		sendTrace = 1; \
		warning("break byteCount reached\n"); \
	} \
	if (!((localFP < ((GIV(stackPage->baseAddress)))) \
	 && (localFP > (((GIV(stackPage->realStackLimit))) - (((sqInt) LargeContextSize >> 1)))))) { \
		warning("invalidLocalFPInPage"); \
		sendTrace = 1; \
	} \
	if (GIV(stackLimit) != (char *)-1 && GIV(stackLimit) != GIV(stackPage->realStackLimit)) { \
		warning("invalidStackLimitInPage"); \
		sendTrace = 1; \
	} \
  } while (0)

#elif 0 /* maintain byteCount & check for valid instruction pointer */
# define bytecodeDispatchDebugHook() do { \
	if (++GIV(byteCount) == 175779UL) \
		warning("break byteCount reached\n"); \
	if (!ValidInstructionPointerCheck()) \
		warning("invalidInstructionPointerinMethod"); \
  } while (0)

#elif 0 /* maintain byteCount & check for valid instruction pointer */
#define bytecodeDispatchDebugHook() do { \
	printf("%ld: %d %x(%d)\n", ++GIV(byteCount), localIP-GIV(method)-3, currentBytecode, currentBytecode); \
	if (!ValidInstructionPointerCheck()) \
		warning("invalidInstructionPointerinMethod"); \
	if (sendTrace > 1) printContext(GIV(activeContext)); \
  } while (0)
#elif 0 /* maintain byteCount & check for valid instruction pointer */
#define bytecodeDispatchDebugHook() do { \
	printf("%ld: %d %x(%d)\n", ++GIV(byteCount), localIP-GIV(method)-3, currentBytecode, currentBytecode); \
	if (!ValidInstructionPointerCheck()) \
		warning("invalidInstructionPointerinMethod"); \
	if (sendTrace > 1) printCallStack(); \
  } while (0)
#elif MULTIPLEBYTECODESETS && 0 /* maintain bytecode trace and check against trace file */
# if defined(SQ_USE_GLOBAL_STRUCT) /* define only in interpreter */
static FILE *bct = 0;
void openBytecodeTraceFile(char *fn)
{ if (!(bct = fopen(fn,"r"))) perror("fopen"); }
void closeBytecodeTraceFile() { if (bct) { fclose(bct); bct = 0; } }
# endif
# define bytecodeDispatchDebugHook() do { char line[64], expected[64]; \
	/* print byteCount pc byteCode(hex) stackPtr */ \
	snprintf(expected, sizeof(expected), "%ld: %d %d(%x) %d %s\n", \
			++GIV(byteCount), localIP-GIV(method)-3, currentBytecode, currentBytecode, \
			(localFP-localSP)/sizeof(sqInt)-5, bytecodeNameTable[currentBytecode]); \
	printf(expected); \
	if (bct) { \
		fgets(line, sizeof(line) - 1, bct); \
		if (strcmp(line,expected)) \
		warning("bytecode trace mismatch"); \
	} \
	if (0) printFrameWithSP(localFP,localSP); \
	if (!ValidInstructionPointerCheck()) \
		warning("invalidInstructionPointerinMethod"); \
  } while (0)
#elif 0 /* print current frame & instruction pointer on every bytecode. */
# define bytecodeDispatchDebugHook() do { \
	printFrameWithSP(localFP,localSP); \
	printf("%d %x\n", localIP - GIV(method) - 3, currentBytecode); \
  } while (0)

#elif 0 /* print current frame & pc on every bytecode if sendTrace/hit break. */
# define bytecodeDispatchDebugHook() do { \
	if (sendTrace) { \
		printFrameWithSP(localFP,localSP); \
		printf("%d %x\n", localIP - GIV(method) - 3, currentBytecode); \
	} \
  } while (0)
#elif 0
# define bytecodeDispatchDebugHook() printContextWithSP(activeContext,localSP)
#else
# define bytecodeDispatchDebugHook() 0
#endif
