/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIEvents.h,v 1.5 2003/12/02 04:53:02 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 27th, 2002, JMM changed for carbon event logic.
*  Mar 8th,  2002, JMM external prims that make dialog windows must do this on main thread
*   3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding, plus multiple keystrokes for input
****************************************************************************/
 
#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

typedef int (*eventMessageHook)(EventRecord* event);

void recordKeystroke(EventRecord *theEvent);
void recordModifierButtons(EventRecord *theEvent);
void recordMouseDown(EventRecord *theEvent);
int recordMouseEvent(EventRecord *theEvent, int theButtonState);
int recordDragDropEvent(EventRecord *theEvent, int numberOfItems, int dragType);
int recordKeyboardEvent(EventRecord *theEvent, int keyType);
int MouseModifierState(EventRecord *theEvent);
WindowPtr getSTWindow(void);
void setMessageHook(eventMessageHook theHook);
void setPostMessageHook(eventMessageHook theHook);
int checkForModifierKeys();
void ignoreLastEvent();
void DoZoomWindow (EventRecord* theEvent, WindowPtr theWindow, short zoomDir, short hMax, short vMax);
void SetupKeyboard(void);    
pascal short SqueakYieldToAnyThread(void);
int getUIToLock(long *);