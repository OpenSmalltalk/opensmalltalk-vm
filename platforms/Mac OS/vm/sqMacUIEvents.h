/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIEvents.h,v 1.1 2002/02/23 10:48:13 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
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
