/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIClipBoard.c
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
#include <ApplicationServices/ApplicationServices.h>

void FreeClipboard(void);
void SetUpClipboard(void);
