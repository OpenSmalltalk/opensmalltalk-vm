/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIMenuBar.c
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

void SetUpMenus(void);
void MenuBarHide(void);
void MenuBarRestore(void);
void AdjustMenus(void);
 
/*** Enumerations ***/
enum { appleID = 1, fileID, editID };
enum { quitItem = 1 };
