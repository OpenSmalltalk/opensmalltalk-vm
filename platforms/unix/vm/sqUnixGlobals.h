#ifndef __sqUnixGlobals_h
#define __sqUnixGlobals_h

#include "sqMemoryAccess.h"

extern sqInt forceInterruptCheck(void);

#if 1 /* use global structure */

  extern sqInt getFullScreenFlag(void);
  extern void  setFullScreenFlag(sqInt i);
  extern sqInt getInterruptKeycode(void);
  extern void  setInterruptKeycode(sqInt i);
  extern sqInt getInterruptPending(void);
  extern void  setInterruptPending(sqInt i);
  extern sqInt getSavedWindowSize(void);
  extern void  setSavedWindowSize(sqInt i);

#else /* ! global structure */

  extern sqInt fullScreenFlag;
  extern sqInt interruptCheckCounter;
  extern sqInt interruptKeycode;
  extern sqInt interruptPending;
  extern sqInt savedWindowSize;

# define getFullScreenFlag()		(fullScreenFlag)
# define setFullScreenFlag(I)		(fullScreenFlag= (I))
# define getInterruptKeycode()		(interruptKeycode)
# define setInterruptKeycode(I)		(interruptKeycode= (I))
# define getInterruptPending()		(interruptPending)
# define setInterruptPending(I)		(interruptPending= (I))
# define getSavedWindowSize()		(savedWindowSize)
# define setSavedWindowSize(I)		(savedWindowSize= (I))

#endif /* !global structure */

#endif /* __sqUnixGlobals_h */
