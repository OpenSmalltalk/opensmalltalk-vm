/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacWindow.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacWindow.h,v 1.2 2002/05/09 19:26:05 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  May 5th, 2002, JMM build as NS plugin
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

void SetWindowTitle(char *title);
WindowPtr getSTWindow(void);
void SetUpWindow(void);
void SetUpPixmap(void);
void FreePixmap(void);
