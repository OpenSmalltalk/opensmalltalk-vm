/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIAppleEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIAppleEvents.h,v 1.1 2002/02/23 10:47:55 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
    #include <AppleEvents.h>
    #ifndef NewAEEventHandlerUPP
        #define NewAEEventHandlerUPP NewAEEventHandlerProc 
    #endif
#endif

void InstallAppleEventHandlers(void);
