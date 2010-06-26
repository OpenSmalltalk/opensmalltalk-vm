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
#if PRODUCTION /* default for no send breakpoint. */
# define sendBreakpointreceiver(sel, len, rcvr) 0

#elif 0 /* send tracing.  */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if (sendTrace) \
		printf("%.*s\n", len, (char *)(sel)); \
} while (0)

#elif 0 /* send trace/byte count.  */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if (sendTrace) \
		printf("%u %.*s\n", GIV(byteCount), len, (char *)(sel)); \
} while (0)

#elif 1 /* breakpoint without byteCount. */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if ((len) == breakSelectorLength \
	 && !strncmp((char *)(sel), breakSelector, breakSelectorLength)) { \
		suppressHeartbeatFlag = 1; \
		warning("send breakpoint (heartbeat suppressed)"); \
		if (0) sendTrace = 1; \
	} \
	if (sendTrace) { \
		printf("%.*s\n", len, (char *)(sel)); \
		if (0 && !checkHeapIntegrity()) error("object leak"); \
	} \
} while (0)

#elif 0 /* breakpoint with byteCount. */
# define sendBreakpointreceiver(sel, len, rcvr) do { \
	if ((len) == breakSelectorLength \
	 && !strncmp((char *)(sel), breakSelector, breakSelectorLength)) { \
		suppressHeartbeatFlag = 1; \
		warning("send breakpoint (heartbeat suppressed)"); \
		if (0) sendTrace = 1; \
	} \
	if (sendTrace) \
		printf("%u %.*s\n", GIV(byteCount), len, (char *)(sel)); \
} while (0)
#endif

/*
 * various definitions of the bytecodeDispatchDebugHook macro for
 * debugging code at the bytecode dispatch switch.
 */
#if PRODUCTION
# define bytecodeDispatchDebugHook() 0

#elif 1 /* check for valid instruction pointer */
# define bytecodeDispatchDebugHook() do { \
	if (!validInstructionPointerinMethodframePointer((usqInt)localIP, GIV(method), localFP)) \
		warning("invalidInstructionPointerinMethod"); \
  } while (0)

#elif 0 /* check for valid stack-related pointers */
# define DEBUG_DISABLE_HEARTBEAT 1
# define bytecodeDispatchDebugHook() do { \
	if (++GIV(byteCount) % 100000 == 0) \
		forceInterruptCheck(); \
	assertValidExecutionPointersimbar(localIP,localFP,localSP,1); \
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
	if (!validInstructionPointerinMethodframePointer((usqInt)localIP, GIV(method), localFP)) \
		warning("invalidInstructionPointerinMethod"); \
  } while (0)

#elif 0 /* maintain byteCount & check for valid instruction pointer */
# define bytecodeDispatchDebugHook() do { \
	printf("%ld: %x %d\n", ++GIV(byteCount), localIP-GIV(method)-3, currentBytecode); \
	if (!validInstructionPointerinMethodframePointer((usqInt)localIP, GIV(method), localFP)) \
		warning("invalidInstructionPointerinMethod"); \
	if (sendTrace) printCallStack(); \
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
#endif
