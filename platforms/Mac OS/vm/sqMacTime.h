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

    #include <Carbon/Carbon.h>

void SetUpTimers(void);
time_t convertToSqueakTime(time_t unixTime);
int ioLowResMSecs(void);
time_t convertToSqueakTime(time_t unixTime);
