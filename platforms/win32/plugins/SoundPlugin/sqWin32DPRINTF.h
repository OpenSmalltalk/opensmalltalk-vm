#include "sqWin32.h"

/* Need separate cases for GNU C and MSVC. */
#ifdef DEBUG 
#warning "DEBUG printing enabled"
#define DPRINTF(x) warnPrintf x
#define CRASH(x) warnPrintf x
#elif defined(_DEBUG)
#pragma message ( "DEBUG printing enabled" )
#define DPRINTF(x) { warnPrintf x; fflush(stdout); }
#define CRASH(x) { int *foo = NULL; warnPrintf x; fflush(stdout); foo[10] = 20; }
#else
#define DPRINTF(x)
#define CRASH(x)
#endif
