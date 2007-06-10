/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacMemory.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Mar 1st, 2002, JMM cleanup a bit. 
****************************************************************************/

    #include <Carbon/Carbon.h>

usqInt	sqGetAvailableMemory(void);
void sqMacMemoryFree(void);