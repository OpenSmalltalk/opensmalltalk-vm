/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacWindow.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacWindow.h,v 1.4 2004/09/22 18:54:37 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  May 5th, 2002, JMM build as NS plugin
*  Jun 7th, 2003, JMM fix up full screen threading issue
*  Sept 11th, 2004, JMM add getDominateScreen
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
int ioSetFullScreenActual(int fullScreen);
#else
#endif

void SetWindowTitle(char *title);
WindowPtr getSTWindow(void);
void SetUpWindow(void);
void SetUpPixmap(void);
void FreePixmap(void);
GDHandle	getThatDominateGDevice(void);
