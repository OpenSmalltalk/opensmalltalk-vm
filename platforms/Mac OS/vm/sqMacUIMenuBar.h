/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacUIMenuBar.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIMenuBar.h,v 1.2 2002/02/23 11:26:08 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
#endif

void SetUpMenus(void);
void MenuBarHide(void);
void MenuBarRestore(void);
void AdjustMenus(void);
 
/*** Enumerations ***/
enum { appleID = 1, fileID, editID };
enum { quitItem = 1 };
