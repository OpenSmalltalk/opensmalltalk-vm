/*------------------------------------------------------------
| FILE NAME: Menu.h
|
| PURPOSE: To provide interface to general menu functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 12.05.96
------------------------------------------------------------*/

#ifndef _MENU_H_
#define _MENU_H_

// ------------------------ EQUATES -------------------------  

// This identifies the current menu resource ID's: each 
// application must set these.

extern s32 FirstMenuID; // The resource ID of the first menu.
extern s32 LastMenuID;  // The resource ID of the last menu.

// Here's an example of how you should define your menu
// resource IDs: numbers must be consecutive without gaps.
//
// Resource IDs of Menus
#define AppleMenuID     128
#define FileMenuID      129
#define EditMenuID      130
#define WindowMenuID    131

// Apple Menu Item IDs
#define AboutItemID     1

// File Menu Item IDs
#define NewItemID       1
#define OpenItemID      2
#define CloseItemID     3
// ............................
#define SaveItemID      5
#define SaveAsItemID    6
#define RevertItemID    7
// ............................
#define PageSetUpItemID 9
#define PrintItemID     10
// ............................
#define QuitItemID      12

// Edit Menu Item IDs
#define UndoItemID      1
#define CutItemID       3
#define CopyItemID      4
#define PasteItemID     5
#define ClearItemID     6
#define SelectAllItemID 7


#define MaxMenuCount 50
        // How many menus there can be at any one time.

#define MenuIndex(x)    (x-FirstMenuID)
        // Returns the menu index in the menu handle array
        // or menu procedure tables given the resource ID.

#define TheMenuHandle(x)   TheMenuHandles[MenuIndex(x)]
        // Returns the menu handle given the resource ID.

extern Handle           CurrentMenuBar;
            // A handle to a menu bar list produced by 
            // 'GetMenuBar'.

extern  MenuHandle      TheMenuHandles[];
            // Holds the handles of the menus used in the
            // application.
  
extern  List*   TheWindowMenuList;
                // Holds the titles and window record 
                // addresses of all open application windows.
                
extern void* MenuProcedures[];

// Named copies of handles held in 'TheMenuHandles' for 
// speed and ease of reference.
extern MenuHandle   AppleMenuHandle;
extern MenuHandle   FileMenuHandle;
extern MenuHandle   EditMenuHandle;
extern MenuHandle   WindowMenuHandle;
                         
//void  DoAppleMenu(s16);
void    DoWindowMenu(s16);
void    InterpretMenuItem(s32);
//void  UpdateWindowMenu();

#endif
