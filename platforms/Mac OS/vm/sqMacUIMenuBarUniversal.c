/****************************************************************************
*   PROJECT: Mac menu bar logic
*   FILE:    sqMacUIMenuBar.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIMenuBar.c 1238 2005-08-16 12:36:18Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Oct 18th, 2004, JMM changes for host menu support
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*****************************************************************************/

#include "sqMacUIMenuBar.h"
#include "sqMacMain.h"
#include "sqMacWindow.h"
#include "sq.h"

MenuHandle	appleMenu = nil;
MenuHandle	editMenu = nil;
MenuHandle	fileMenu = nil;

static RgnHandle	menuBarRegion = nil;  /* if non-nil, then menu bar has been hidden */
extern struct VirtualMachine* interpreterProxy;

 
    #define EnableMenuItemCarbon(m1,v1)  EnableMenuItem(m1,v1);
    #define DisableMenuItemCarbon(m1,v1)  DisableMenuItem(m1,v1);

extern Boolean gSqueakHasQuitWithoutSaving;

static int isAqua (void) {
	signed long int theResponse;
	Gestalt(gestaltMenuMgrAttr,&theResponse);
	return (theResponse & gestaltMenuMgrAquaLayoutMask );
}

void MenuBarHide(void) {
 	if (menuBarRegion != nil) return;  /* saved state, so menu bar is already hidden */
	if (!(getThatDominateGDevice(getSTWindow()) == GetMainDevice())) return;  /*Do not did if main window on secondary screen */
    menuBarRegion = (RgnHandle) 1;
    ShowMenuBar();
    HideMenuBar();
}
void MenuBarRestore(void) {
	if (menuBarRegion == nil) return;  /* no saved state, so menu bar is not hidden */
    ShowMenuBar();
    menuBarRegion = nil;
}

void SetUpMenus(void) {
	
	InsertMenu(appleMenu = NewMenu(appleID, "\p\024"), 0);
	
	/* If not OS/X aqua, use a File submenu Quit-Without-Save. 
	   This is just placeholder stuff to reconcile with the original VM.  */

	if ((! isAqua()) || gSqueakHasQuitWithoutSaving) {
		InsertMenu(fileMenu  = NewMenu(fileID,  "\pFile"), 0);
        	AppendMenu(fileMenu, "\pQuit Without Saving");
	}

	InsertMenu(editMenu  = NewMenu(editID,  "\pEdit"), 0);

	/* DisableMenuCommand(NULL,'quit');  */
 	AppendMenu(editMenu, "\pUndo/Z;(-;Cut/X;Copy/C;Paste/V;Clear");
	/* Disable items in the Edit menu */
	DisableMenuItemCarbon(editMenu, 1);
	DisableMenuItemCarbon(editMenu, 3);
	DisableMenuItemCarbon(editMenu, 4);
	DisableMenuItemCarbon(editMenu, 5);
	DisableMenuItemCarbon(editMenu, 6);
	DrawMenuBar();
}

 void AdjustMenus(void) {
	WindowRef		wp;
	int				isDeskAccessory;
	int				cutState;	
		
	cutState = IsMenuItemEnabled(editMenu, 1);

	wp = FrontWindow();
	if (wp != NULL) {
		isDeskAccessory = GetWindowKind(wp) < 0;
	} else {
		isDeskAccessory = false;
	}

	if (isDeskAccessory) {
		/* Enable items in the Edit menu */
		EnableMenuItemCarbon(editMenu, 1);
		EnableMenuItemCarbon(editMenu, 3);
		EnableMenuItemCarbon(editMenu, 4);
		EnableMenuItemCarbon(editMenu, 5);
		EnableMenuItemCarbon(editMenu, 6);
	} else {
		if (cutState) {
			/* Enable items in the Edit menu */
			EnableMenuItemCarbon(editMenu, 1);
			EnableMenuItemCarbon(editMenu, 3);
			EnableMenuItemCarbon(editMenu, 4);
			EnableMenuItemCarbon(editMenu, 5);
		} else {
			/* Disable items in the Edit menu */
			DisableMenuItemCarbon(editMenu, 1);
			DisableMenuItemCarbon(editMenu, 3);
			DisableMenuItemCarbon(editMenu, 4);
			DisableMenuItemCarbon(editMenu, 5);
			DisableMenuItemCarbon(editMenu, 6);
		}
	}
}

