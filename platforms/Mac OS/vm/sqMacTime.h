/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacTime.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacTime.h 1344 2006-03-05 21:07:15Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
****************************************************************************/

    #include <Carbon/Carbon.h>

void SetUpTimers(void);
time_t convertToSqueakTime(time_t unixTime);
sqLong convertToLongSqueakTime(time_t unixTime);
