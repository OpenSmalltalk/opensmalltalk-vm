/* sqConfig.h -- platform identification and configuration */

#if defined(__MWERKS__) && !defined(macintoshSqueak)  && !defined(BEOS_SQUEAK)
  /* CodeWarrior 8 neglects to define "macintosh" */
# define macintoshSqueak
#endif

#if defined (__APPLE__) && defined(__MACH__)
  /* For Apple's OS X, ppc version of darwin */
#include <mactypes.h>
#define macintoshSqueak
#endif


#if defined(macintoshSqueak)
# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# define SQ_CONFIG_DONE
#endif

#if !defined(SQ_CONFIG_DONE)
# error test for, and describe, your architecture here.
#endif
