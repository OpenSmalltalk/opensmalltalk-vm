// defines for controlling the memory permissions of the Cogit's code zone on arm64
#include <sys/auxv.h> // for __clear_cache
#if !DUAL_MAPPED_CODE_ZONE
# error "the only scheme in use so far is the DUAL_MAPPED_CODE_ZONE"
#endif
// since we're using the DUAL_MAPPED_CODE_ZONE, no machinery is needed.
// we can defer to the default macro implementations in cogitARMv8.c
