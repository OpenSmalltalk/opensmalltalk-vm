/*------------------------------------------------------------
| TLMenuList.c
|-------------------------------------------------------------
|
| PURPOSE: To provide general routines for managing menus.
|
| DESCRIPTION: The basic idea is to construct a general
| menu specification that can be used for building menus and
| then later for dispatching commands when menu items are
| chosen by the user.  
|
| So, for every visible menu, an internal menu list is built 
| to connect the menu item to it's associated function and 
| data.  
|
| Such lists are called 'menu lists'.  Menu lists are 
| implemented using standard lists but the items use the 
| fields of 'Item' records in a special way:
|
| 'DataAddress' holds the address of the name of the menu
|               item as it will appear in the menu.
|
| 'SizeOfBuffer' holds the address of the procedure executed
|                when the menu item is selected.
|
| 'BufferAddress' holds the address of the data that is 
|                 passed to the procedure executed when the
|                 menu item is selected.
|
| This arrangement allows standard list routines to be used
| for sorting and searching menu items by name.
|
| NOTE: 
|
| HISTORY: 11.26.97
------------------------------------------------------------*/

#include <stdio.h> 

#include <TextUtils.h>

#include "TLTypes.h"
#include "TLTwo.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLStrings.h"
#include "TLMenuList.h"

/*------------------------------------------------------------
| AppendItemToMenuList
|-------------------------------------------------------------
|
| PURPOSE: To append an item to a menu list.
|
| DESCRIPTION: Use this routine to construct menu lists.  
|
| See the header of this file for more on menu lists.
|
| EXAMPLE:
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.26.97 TL
------------------------------------------------------------*/
void
AppendItemToMenuList( List*  L, 
                      u8* AddrOfProcedure,
                      u8* AddrOfData,
                      u8* AddrOfName )
{
    Item*   A;
    
    // Make a new 'Item' record.
    A = MakeItem();
    
    // Set the fields using the parameters passed to this
    // procedure.
    A->DataAddress   = AddrOfName;
    A->SizeOfBuffer  = (u32) AddrOfProcedure;
    A->BufferAddress = AddrOfData;
    
    // Append the item to the list.
    InsertItemLastInList( L, A );
}
    
/*------------------------------------------------------------
| EnableMenuAndItems
|-------------------------------------------------------------
|
| PURPOSE: To enable a menu and all items on a menu.
|
| DESCRIPTION:  
|
| EXAMPLE:
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 11.30.97 TL from 'FindMenuItemNumberByName'.
------------------------------------------------------------*/
void
EnableMenuAndItems( MenuHandle H )
{
    s32 ItemCount;
    
    // Enable the menu itself.
    EnableItem( H, 0 );
    
    // Get a count of how many items are in the menu.                  
    ItemCount = CountMItems( H );
    
    // For each item.
    while( ItemCount )
    {
        // Enable the item.
        EnableItem( H, ItemCount );
        
        // Move to the next item.
        ItemCount--;
    }
}

/*------------------------------------------------------------
| ExecuteNthItemOfMenuList
|-------------------------------------------------------------
|
| PURPOSE: To execute the procedure connected to the nth
|          item of a menu list.
|
| DESCRIPTION: The first item of a menu list is indexed as 0.
|
| The data associated with the menu item is passed to the
| procedure connected to the menu item.
|
| EXAMPLE:
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.26.97 TL
------------------------------------------------------------*/
void
ExecuteNthItemOfMenuList( List* L, s32 N )
{
    Item*   A;
    u32 D;
    void    (*AProcedure)(u32);
    
    // Find the nth item.
    A = FindNthItem( L, N );
    
    // Refer to the procedure.
    AProcedure = (void  (*)(u32)) A->SizeOfBuffer;
    
    // Get the datum.
    D = (u32) A->BufferAddress;
    
    // Call the procedure with the data.
    (*AProcedure)(D);
}
    
/*------------------------------------------------------------
| FindMenuItemNumberByName
|-------------------------------------------------------------
|
| PURPOSE: To find the item number of the named item in a 
|          menu.
|
| DESCRIPTION: Returns the 1-based index of the named item
| or 0 if the item isn't found in the menu.
|
| EXAMPLE:
|
|         n = FindItemNumberByName( h, "Openä" );
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.30.97 TL
------------------------------------------------------------*/
s32
FindMenuItemNumberByName( MenuHandle H, s8* ItemName )
{ 
    Str255  ItemString;
    s32 ItemCount;
    
    // Get a count of how many items are in the menu.                  
    ItemCount = CountMItems( H );
    
    // For each item.
    while( ItemCount )
    {
        // Get the text of the indexed item.
        GetMenuItemText( H, ItemCount, ItemString );
        
        // Convert the text to C-string format.
        p2cstr( ItemString );
        
        // If the given name matches.
        if( ! CompareStrings( ItemName, (s8*) ItemString ) )
        {
            return( ItemCount );
        }
        else // No match.
        {
            // Move to the next item.
            ItemCount--;
        }
    }
    
    // Not found.
    return( 0 );
}
/*------------------------------------------------------------
| InsertMenuItemC
|-------------------------------------------------------------
|
| PURPOSE: To put an item into a menu.
|
| DESCRIPTION: This is the C-string equivalent of 
|              'InsertMenuItem'.
|
| EXAMPLE:
|
|          InsertMenuItemC( h, "Openä", 0 );
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 10.15.97 TL
------------------------------------------------------------*/
void
InsertMenuItemC( MenuHandle M, 
                 s8*      ItemString, 
                 s32      AfterItemIndex )
{
    s8  PascalItemString[255];
 
    CopyString( ItemString, PascalItemString );

    // Convert the string to Pascal-format.
    c2pstr( (char*) PascalItemString );

    // Insert the menu item at the indexed location
    // where 0 means first in the list.
    InsertMenuItem( M, 
                    (ConstStr255Param) PascalItemString, 
                    AfterItemIndex );
}

/*------------------------------------------------------------
| PutItemNamesIntoMenu
|-------------------------------------------------------------
|
| PURPOSE: To add a list of item names to a menu.
|
| DESCRIPTION: Given a handle to an empty menu and a menu 
| list, adds the item names to the menu.
|
| Also enables the menu and it's items.
|
| EXAMPLE:
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 11.26.97 TL from 'PutPlugInNamesIntoMenu'.
------------------------------------------------------------*/
void
PutItemNamesIntoMenu( MenuHandle AMenu, List* L )
{
    s32 MenuItemNumber;

    // Enable the menu itself.
    EnableItem( AMenu, 0 );
    
    MenuItemNumber = 1;
    
    ReferToList( L );
    
    // For each item in the menu.
    while( TheItem )
    {
        // Put item name into the menu.
        InsertMenuItemC( AMenu, 
                         (s8*) TheDataAddress, 
                         MenuItemNumber - 1 ) ;
 
        // Enable the menu item.
        EnableItem( AMenu, MenuItemNumber );
        
        // Account for the new menu item.
        MenuItemNumber++;
        
        ToNextItem();
    }
        
    RevertToList();
}


