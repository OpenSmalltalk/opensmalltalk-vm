#ifndef JIT_H
#define JIT_H

#if defined(_MSC_VER)

#include <processthreadsapi.h>

// Flush the instruction cache in WIN32 if needed
// Use a function because computed arguments in macros seem to be eaten by the preprocessor
static inline BOOL flushICacheFromto(char* startAddress,char* endAddress) {
	return FlushInstructionCache(GetCurrentProcess(), startAddress, endAddress - startAddress);
}

#elif defined(__arm__)|| defined(__aarch64__)

// Flush the instruction cache on Linux systems using __clear_cache
#define flushICacheFromto(startAddress,endAddress) __clear_cache((char*) startAddress, (char*) (endAddress ))

#else

// Do not Flush the instruction cache on Intel systems
// Flushing the instruction cache is only required if code and data do not have the same linear addresses.
// See the CPUID and CLFLUSH instructions in the x86 manual
#define flushICacheFromto(startAddress,endAddress) 0

#endif

#endif //JIT_H
