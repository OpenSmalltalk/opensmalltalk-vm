/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

void SetUpTimers(void);
#ifdef MACINTOSHUSEUNIXFILENAMES
time_t convertToSqueakTime(time_t unixTime);
#endif