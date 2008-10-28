/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacMain.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Apr 17th, 2002, JMM os 9 check
****************************************************************************/

    #include <Carbon/Carbon.h>

void fetchPrefrences(void);
char * GetAttributeString(int id);
void ExitCleanup(void);