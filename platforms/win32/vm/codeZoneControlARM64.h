// defines for controlling the memory permissions of the Cogit's code zone on arm64
// Windows allows the use of PAGE_EXECUTE_READWRITE so nothing need be done and
// we can defer to the default macro implementations in cogitARMv8.c
#include <processthreadsapi.h> // For FlushInstructionCache
