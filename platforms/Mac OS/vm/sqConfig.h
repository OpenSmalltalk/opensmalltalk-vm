/* sqConfig.h -- platform identification and configuration */

#if defined(__MWERKS__) && !defined(macintosh)  && !defined(BEOS_SQUEAK)
  /* CodeWarrior 8 neglects to define "macintosh" */
# define macintosh
#endif

#if defined (__APPLE__) && defined(__MACH__)
  /* For Apple's OS X, ppc version of darwin */
#define macintosh
#include <mactypes.h>
#endif


#if defined(macintosh)
# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# define SQ_CONFIG_DONE
#endif

#if !defined(SQ_CONFIG_DONE)
# error test for, and describe, your architecture here.
#endif
