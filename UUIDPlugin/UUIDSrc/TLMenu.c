/*------------------------------------------------------------
| TLMenu.c
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to application log functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 12.09.96
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdio.h>
#include <Menus.h>
#include <ToolUtils.h>

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLList.h"
#include "TLMenu.h"
#include "TLWin.h"
#include "TLDialog.h"
#include "TLModes.h"

//#include "TradingFile.h" // For 'TheVRefNum'.

// This identifies the current menu resource ID's: each 
// application must set these: numbers must be consecutive
// and without gaps.

s32 FirstMenuID; // The resource ID of the first menu.
s32 LastMenuID;  // The resource ID of the last menu.

List*       TheWindowMenuList;
            // Holds the titles and window record addresses of 
            // all open application windows.

Handle      CurrentMenuBar;
            // A handle to a menu bar list produced by 
            // 'GetMenuBar'.

// Each application defines one of these:
MenuHandle  TheMenuHandles[ MaxMenuCount ];
            // Holds the handles of the current menus.

// Named copies of handles held in 'TheMenuHandles' for 
// speed and ease of reference.
MenuHandle  AppleMenuHandle;
MenuHandle  FileMenuHandle;
MenuHandle  EditMenuHandle;
MenuHandle  WindowMenuHandle;

// Menu interpretation procedures.  Must be in same
// order as the resource IDs and without gaps.

// Define this in your application:
//
//  void* 
//  MenuProcedures[] =
//  {
//      DoAppleMenu,
//      DoFileMenu,
//      DoEditMenu,
//      DoWindowMenu,...
//  };

// Here's an example menu interpretation procedure:
#ifdef EXAMPLE_ONLY
/*------------------------------------------------------------
| DoAppleMenu
|-------------------------------------------------------------
|
| PURPOSE: To interpret a selection in the apple menu.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.01.94 revised
|          02.03.94 made 'about' a submode
|
------------------------------------------------------------*/
void
DoAppleMenu( s16 AMenuItem )
{
    Str255  name;
    
    MenuHandle  AMenuHandle;
    
    if( AMenuItem == AboutItemID )
    {
        EnterSubMode( AboutMode );
    }
    else // Call a desk accessory.
    {
        AMenuHandle = TheMenuHandle( AppleMenuID );
    
        GetMenuItemText(AMenuHandle, AMenuItem, &name);
        
        OpenDeskAcc(name);
        
        if( TheMode == TextEditMode && TheTextWindow )
        {
            SetPort( TheTextWindow );
        }
    }
}
#endif

/*------------------------------------------------------------
| DoWindowMenu
|-------------------------------------------------------------
|
| PURPOSE: To interpret a selection in the Window menu.
|
| DESCRIPTION: Selects the window whose title is selected
| from the 'Window' menu.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.01.94 revised
|          02.11.94 filled in stub.
|
------------------------------------------------------------*/
void
DoWindowMenu( s16 AMenuItem )
{
    s16 i;
    
    // The list of window names also holds the window
    // record in the 'SizeOfData' field of each item.
    //
    ReferToList( TheWindowMenuList );
    
    // Advance to the correct item.
    for( i=1; i < AMenuItem; i++ )
    {
        ToNextItem();
    }
     
    SelectWindow( (WindowPtr) TheDataSize );

    RevertToList();
}

/*------------------------------------------------------------
| InterpretMenuItem
|-------------------------------------------------------------
|
| PURPOSE: To interpret a menu selection or equivalent command
| key.
|
| DESCRIPTION: Use this within event handlers.
|
| EXAMPLE:
|  
|   void
|   DemoTitleModeMouseDown()
|   {
|       s16 ButtonID;
|       
|       if( IsInMenuBar )
|       {
|           InterpretMenuItem( TheMenuResult );
|           return;
|       }
|   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.11.94
|
------------------------------------------------------------*/
void 
InterpretMenuItem( s32 AMenuResult )
{
    s32             TheMenuIndex;
    AnyProcedure    AProcedure;
    
    TheMenuID   = HiWord(AMenuResult);
    TheMenuItem = LoWord(AMenuResult);

    if( TheMenuID >= FirstMenuID &&
        TheMenuID <= LastMenuID )
    {
        TheMenuIndex = MenuIndex( TheMenuID );
        
        AProcedure = (AnyProcedure)
                     MenuProcedures[TheMenuIndex];
                     
        /* Call the special menu procedure. */            
        (*AProcedure)(TheMenuItem); 
        
        HiliteMenu(0);
    }
}

#if 0
/*------------------------------------------------------------
| UpdateWindowMenu
|-------------------------------------------------------------
|
| PURPOSE: To update the item list attached to the window
|          menu.
|
| DESCRIPTION: The titles of all open windows are arranged
| in alphabetical order under the 'Window' menu.
|
| If there are no open windows then the window item is
| made inactive.
|
| Uses the window titles to text window, including the
| 'Reference Manual' window, and then adds the 'Quick Reference'
| window if it is open.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: The 'Window' menu is in the menu bar.
|          The 'Window' menu is the last menu in the bar.
|          'WindowMenuHandle' is valid.
|
| HISTORY: 02.11.94
|          02.12.94 added change status mark and under line
|                   for active window.
------------------------------------------------------------*/
void 
UpdateWindowMenu()
{
    Str255          ATitle;
    WindowPtr   AWindow;
    s8*             AString;
    Item*           AnItem;
    s16             ItemIndex;
    
    // Reset the current list of window records, if any.
    if( TheWindowMenuList )
    {
        DeleteListOfDynamicData( TheWindowMenuList );
        TheWindowMenuList = 0;
    }
    
    TheWindowMenuList = CreateList();
    
    // Make a list of window names and put the window
    // record into the 'SizeOfData' field of each item.
    //
    ReferToList( TheTextWindowList );
     
    // First add the text windows if any.
    while( TheItem )
    {
        AWindow = (WindowPtr) TheDataAddress;
        
        GetWTitle(AWindow,&ATitle);
        
        PtoCstr(&ATitle);
        
        AString = DuplicateString((s8*) &ATitle);
        
        AnItem = InsertDataLastInList(TheWindowMenuList,
                                      (AddressOfByte) AString);
        
        // If the window has been changed, then mark the
        // menu item too.
        //
        if( TheItemMark )
        {
            MarkItem(AnItem);
        }
                                      
        // Preserve the window record.                
        PutSizeOfItemData( AnItem, (Quad) AWindow);
        
        ToNextItem();
    }
    
    RevertToList();

#if 0
    // Add the 'Quick Reference' window if it is open.
    if(QuickRefDialog)
    {
        AWindow = (WindowPtr) QuickRefDialog;
        
        GetWTitle(AWindow,&ATitle);
        
        PtoCstr(&ATitle);
        
        AString = DuplicateString((s8*) &ATitle);

        AnItem = InsertDataLastInList(TheWindowMenuList,
                                      (AddressOfByte) AString);
        
        // Preserve the window record.                    
        PutSizeOfItemData( AnItem, (Quad) AWindow);
    }
#endif
    
    // Sort the window menu list in alphabetical order.
    SortListAlphabetically( TheWindowMenuList );
    
    // Clear the current items attached to the 'Window'
    // menu.
    //
    DeleteMenu(WindowMenuID);
    DisposeMenu(WindowMenuHandle);
    WindowMenuHandle = NewMenu( WindowMenuID, "\pWindow" );
    TheMenuHandle(WindowMenuID) = WindowMenuHandle;

    // Append the window titles as items under the 'Window'
    // menu.
     
    ReferToList( TheWindowMenuList );
     
    ItemIndex = 1;
    
    while( TheItem )
    {
        CopyString( (s8*) TheDataAddress,
                    (s8*) &ATitle );
                   
        CtoPstr( &ATitle );
        
        AppendMenu( WindowMenuHandle, &ATitle );
        
        // Mark any changed documents with a delta.
        if( TheItemMark )
        {
            SetItemMark( WindowMenuHandle, ItemIndex, 198 );
        }
        
        // Underline the current window.
        AWindow = (WindowPtr) TheDataSize;
        
        if( AWindow == FrontWindow() )
        {
            SetItemStyle( WindowMenuHandle,
                          ItemIndex,
                          4 );
        }
        
        ItemIndex++;
        
        ToNextItem();
    }
    
    // Dim or highlight the window menu depending on
    // whether there are any items in the menu.
    // 
    if( TheItemCount )
    {
        EnableItem( WindowMenuHandle, 0 );
    }
    else
    {
        DisableItem( WindowMenuHandle, 0 );
        
        // Reset the new window counter if none are
        // visible.
        //
        NewWindowCount = 0;
    }
    
    RevertToList();
    
    // Put the menu in the menu bar.
    InsertMenu( WindowMenuHandle, 0 );
    
    // Now draw the menu bar to show any changes.
    DrawMenuBar();
}
#endif

#endif // FOR_MACOS
