// defines for controlling the memory permissions of the Cogit's code zone on arm64
#include <sys/auxv.h> // for __clear_cache
#if DUAL_MAPPED_CODE_ZONE
// since we're using the DUAL_MAPPED_CODE_ZONE, no machinery is needed.
// we can defer to the default macro implementations in cogitARMv8.c
#elif __ANDROID__ || ANDROID || __OpenBSD__
// Android allows the use of PROT_READ | PROT_WRITE | PROT_EXEC so nothing need
// be done and we can defer to the default macro implementations in cogitARMv8.c
#else
// We choose to raise an error here rather than merely assume one of the above
// scheme, to document the approach taken by each platform. So try the ANDROID
// approach, and if that fails, try DUAL_MAPPED_CODE_ZONE, and if that fails
// there is work to do.
# error "please choose a scheme for your platform"
#endif
