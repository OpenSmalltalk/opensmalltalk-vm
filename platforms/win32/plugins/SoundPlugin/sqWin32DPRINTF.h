#include "sqWin32.h"

/* Need separate cases for GNU C and MSVC. */
#if _MSC_VER
# if defined(DEBUG) || defined(_DEBUG) || SOUND_PLUGIN_DEBUG
#	pragma message ( "DEBUG printing enabled" )
#	define DPRINTF(x) { warnPrintf x; fflush(stdout); }
# endif
#elif defined(DEBUG) || SOUND_PLUGIN_DEBUG
# warning "DEBUG printing enabled"
# define DPRINTF(x) warnPrintf x
#endif

#if SOUND_PLUGIN_DEBUG & 1
#  define DMPRINTF(x) DPRINTF(x) // Microphone-specific printing
#  if SOUND_PLUGIN_DEBUG & 4
#	define DVMPRINTF(x) DPRINTF(x) // Verbose microphone-specific printing
#  endif
#endif
#if SOUND_PLUGIN_DEBUG & 2
#  define DSPRINTF(x) DPRINTF(x) // Speaker-specific printing
#  if SOUND_PLUGIN_DEBUG & 4
#	define DSMPRINTF(x) DPRINTF(x) // Verbose speaker-specific printing
#  endif
#endif

#if !defined(DPRINTF)
#  define DPRINTF(x)
#endif
#if !defined(DMPRINTF)
#  define DMPRINTF(x)
#endif
#if !defined(DVMPRINTF)
#  define DVMPRINTF(x)
#endif
#if !defined(DSPRINTF)
#  define DSPRINTF(x)
#endif
#if !defined(DVSPRINTF)
#  define DVSPRINTF(x)
#endif
