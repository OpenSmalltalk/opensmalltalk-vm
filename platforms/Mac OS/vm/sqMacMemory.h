/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacMemory.h,v 1.2 2002/03/04 00:34:03 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar 1st, 2002, JMM cleanup a bit. 
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif
UInt32	sqGetAvailableMemory(void);
void sqMacMemoryFree();