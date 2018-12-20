/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIEvents.h 1708 2007-06-10 00:40:04Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Feb 27th, 2002, JMM changed for carbon event logic.
*  Mar 8th,  2002, JMM external prims that make dialog windows must do this on main thread
*   3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding, plus multiple keystrokes for input
****************************************************************************/
 
    #include <Carbon/Carbon.h>

typedef int (*eventMessageHook)(EventRecord* event);

void recordKeystroke(EventRecord *theEvent);
void recordModifierButtons(EventRecord *theEvent);
void recordMouseDown(EventRecord *theEvent);
int recordDragDropEvent(EventRecord *theEvent, int numberOfItems, int dragType);
int recordKeyboardEvent(EventRecord *theEvent, int keyType);
void recordWindowEvent(int windowType,int left, int top, int right, int bottom);
void recordMenu(int menuID,UInt32 menuItem);
int MouseModifierState(EventRecord *theEvent);
WindowPtr getSTWindow(void);
void setMessageHook(eventMessageHook theHook);
void setPostMessageHook(eventMessageHook theHook);
int checkForModifierKeys();
void ignoreLastEvent();
void DoZoomWindow (EventRecord* theEvent, WindowPtr theWindow, short zoomDir, short hMax, short vMax);
void SetupKeyboard(void);    
int getUIToLock(sqInt *);
void SetUpCarbonEvent();
void SetUpCarbonEventForWindowIndex(sqInt index);
void RunApplicationEventLoopWithSqueak(void);
void postFullScreenUpdate(void);
