/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMain.h,v 1.2 2002/04/27 18:56:16 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Apr 17th, 2002, JMM os 9 check
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

Boolean RunningOnCarbonX(void);
Boolean isSystem9_0_or_better(void);

