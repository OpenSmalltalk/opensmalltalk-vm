#if defined(_WIN32)
#include "sqPlatformSpecific-Win32.c"
#elif defined(__linux__) || defined(__unix__)
#include "sqPlatformSpecific-Unix.c"
#else
#include "sqPlatformSpecific-Generic.c"
#endif
