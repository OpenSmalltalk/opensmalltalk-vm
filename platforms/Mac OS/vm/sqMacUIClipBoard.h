/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIClipBoard.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIClipBoard.h,v 1.1 2002/02/23 10:48:03 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

void FreeClipboard(void);
void SetUpClipboard(void);
