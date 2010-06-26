/* sqConfig.h -- platform identification and configuration */

  /* For Apple's OS X, ppc version of darwin */
#include <MacTypes.h>
#define macintoshSqueak 1

# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# define SQ_CONFIG_DONE

#if !defined(SQ_CONFIG_DONE)
# error test for, and describe, your architecture here.
#endif

#if defined(__BIG_ENDIAN__)
# define VMBIGENDIAN 1
#else
# define VMBIGENDIAN 0
#endif
