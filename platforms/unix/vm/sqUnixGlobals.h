#ifndef __sqUnixGlobals_h
#define __sqUnixGlobals_h

#if 1 /* use global structure */

extern int  getFullScreenFlag(void);
extern void setFullScreenFlag(int i);
extern int  getInterruptCheckCounter(void);
extern void setInterruptCheckCounter(int i);
extern int  getInterruptKeycode(void);
extern void setInterruptKeycode(int i);
extern int  getInterruptPending(void);
extern void setInterruptPending(int i);
extern int  getSavedWindowSize(void);
extern void setSavedWindowSize(int i);

#else /* ! global structure */

  extern int fullScreenFlag;
  extern int interruptCheckCounter;
  extern int interruptKeycode;
  extern int interruptPending;
  extern int savedWindowSize;

# define getFullScreenFlag()		(fullScreenFlag)
# define setFullScreenFlag(I)		(fullScreenFlag= (I))
# define getInterruptCheckCounter()	(interruptCheckCounter)
# define setInterruptCheckCounter(I)	(interruptCheckCounter= (I))
# define getInterruptKeycode()		(interruptKeycode)
# define setInterruptKeycode(I)		(interruptKeycode= (I))
# define getInterruptPending()		(interruptPending)
# define setInterruptPending(I)		(interruptPending= (I))
# define getSavedWindowSize()		(savedWindowSize)
# define setSavedWindowSize(I)		(savedWindowSize= (I))

#endif /* !global structure */

#endif /* __sqUnixGlobals_h */
