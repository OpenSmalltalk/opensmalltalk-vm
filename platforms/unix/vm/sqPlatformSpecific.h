/* Unix sqPlatformSpecific.h -- Platform-specific prototypes and definitions */

/* How to use this file:
   This file is for general platform-specific macros and declarations.
   The goal is to keep most of the other header files generic across platforms.
   To override a definition or macro from sq.h, you must first #undef it, then
   provide the new definition.

*/



#ifdef UNIX
/* unix-specific prototypes and definitions */
void aioPollForIO(int microSeconds, int extraFd);
#define SQ_FORM_FILENAME        "squeak-form.ppm"

/* undefine clock macros that are implemented as functions */
#undef ioMSecs
#undef ioMicroMSecs
#undef ioLowResMSecs
#else
#endif /* UNIX */

