/*------------------------------------------------------------
| TLDialog.c
|-------------------------------------------------------------
|
| PURPOSE: To provide general dialog functions for MacOS.
|
| DESCRIPTION: 
|
| HISTORY: 11.25.96 
|          09.19.98 Revised to use os-generic windows to
|                   refer to dialogs. 
------------------------------------------------------------*/
#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdio.h>
#include <Dialogs.h>

#include "TLBuf.h"
#include "TLMemOS.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLCursor.h"

#include "TLDialog.h"

/*------------------------------------------------------------
| DeleteDialog
|-------------------------------------------------------------
|
| PURPOSE: To erase and deallocate a dialog.
|
| DESCRIPTION:  
|
| EXAMPLE: DeleteDialog( (DialogPtr) TitleDialog );  
|
| NOTES:   
|
| ASSUMES: Memory for the dialog was dynamically allocated.
|
| HISTORY: 01.26.94 
------------------------------------------------------------*/
void
DeleteDialog( DialogPtr ADialog )
{
    DisposeDialog( ADialog );
}

/*------------------------------------------------------------
| DoActivateDialog
|-------------------------------------------------------------
|
| PURPOSE: To make TheEventWindow the active dialog.
|
| DESCRIPTION: An activate event processing function which
| may be put into an event table.
|
| EXAMPLE:   ActivateDialog();
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 02.04.94 
|          02.07.94 revised to use DialogSelect
------------------------------------------------------------*/
void
DoActivateDialog()
{
// This is handled by DialogSelect.
//  if(TheEventModifiers & activeFlag) 
//  {   
//      SelectWindow( TheEventWindow );
//  }
}

/*------------------------------------------------------------
| DoAlert
|-------------------------------------------------------------
|
| PURPOSE: To call a given 'Alert-type' dialog.
|
| DESCRIPTION: Sets cursor to arrow for the alert.
|
| EXAMPLE:  ButtonID = DoAlert(YesNoCancelAlertID);
|
| NOTES:   
|
| ASSUMES: Cyclic procedure of the current mode will
|          set up the cursor properly after the alert.
|
| HISTORY: 02.13.94 
------------------------------------------------------------*/
s16
DoAlert( s16 AlertID )
{
    s16 ButtonID;
    
    // Change cursor to arrow and make visible.
    SetArrowCursor();

    // Get the button.
    ButtonID = Alert( AlertID, 0L );
    
    // Return the button pressed.
    return( ButtonID );
}

/*------------------------------------------------------------
| DoUpdateDialog
|-------------------------------------------------------------
|
| PURPOSE: To update the contents of TheEventWindow as if
| it were a dialog.
|
| DESCRIPTION: An update event processing function which
| may be put into an event table.
|
| EXAMPLE:   ActivateDialog();
|
| NOTES:   
|
| ASSUMES: The dialog is visible and can be drawn.
|
| HISTORY: 02.04.94 
|          02.07.94 revised to use DialogSelect
------------------------------------------------------------*/
void
DoUpdateDialog()
{
// This is handled by DialogSelect. 
//  GrafPtr savePort;
//  
//  GetPort(&savePort);
//  
//  SetPort(TheEventWindow);
//
//  BeginUpdate(TheEventWindow);
//  
//  EraseRect(&TheEventWindow->portRect);
//
//  DrawDialog(TheEventWindow);
//
//  EndUpdate(TheEventWindow);
//
//  SetPort(savePort);
}

/*------------------------------------------------------------
| DrawItemOutline
|-------------------------------------------------------------
|
| PURPOSE: To draw a rounded box outline around a button.
|
| DESCRIPTION: This is a draw procedure for a userItem.
| The address of this procedure is placed in item list of
| the dialog containing the userItem.
|
| See page I-404,405 Inside Mac.
|
| EXAMPLE:  
|
| NOTES:   
|
| ASSUMES: The current grafPort is set to the dialog window.
|
| HISTORY: 02.04.94 
------------------------------------------------------------*/
pascal
void
DrawItemOutline( WindowPtr AWindow,
                 s16       ItemNumber )
{
    Rect    ItemRect;
    Handle  ItemHandle;
    s16     ItemType;
    
    GetDialogItem(AWindow, 
             ItemNumber,
             &ItemType,
             &ItemHandle,
             &ItemRect);
             
    PenSize(3,3);
    InsetRect(&ItemRect,-4,-4);
    FrameRoundRect(&ItemRect,16,16);
}

/*------------------------------------------------------------
| LoadDialog
|-------------------------------------------------------------
|
| PURPOSE: To load a dialog resource into memory.
|
| DESCRIPTION: Loads the dialog window but doesn't draw it.
|
| EXAMPLE:  TitleDialog = LoadDialog(TitleDialogID);
|
| NOTES:   
|
| ASSUMES: Dialog will be de-allocated using FreeDialog.
|
|          The dialog is not marked as initally visible.
|
| HISTORY: 01.26.94 
|          09.19.98 Revised to return os-generic window
|                   instead of a 'DialogPtr'.
|          09.27.98 Added saving the dialog ID to the
|                   'DialogID' field of the window record.
------------------------------------------------------------*/
Window*
LoadDialog( s16 ADialogID )
{
    Window*     W;
    DialogPtr   ADialog;
    
    // Make an OS-generic window record for the dialog.
    W = MakeGenericWindow();
    
    // Mark the window as a dialog.
    W->IsDialog = 1;
    
    // Save the dialog resoure ID in the window structure.
    W->DialogID = (u32) ADialogID;
    
    // Load the dialog resource.
    ADialog = 
        GetNewDialog( 
            (s16) ADialogID,
            (WindowRecord *) 0, // allocate storage
            (WindowPtr) -1 );   // in front of all windows.
            
    // Install the draw procedure addresses for 
    // userItems which may be in the given dialog list.
    SetUserItemDrawProcedures( ADialog );

    // Put the dialog reference in the window record.
    W->Wos = ADialog;
    
    // Return the os-generic window.
    return( W );
}

/*------------------------------------------------------------
| LoadAndShowDialog
|-------------------------------------------------------------
|
| PURPOSE: To load a dialog from disk and draw it on the 
|          display as the front most window.
|
| DESCRIPTION: Returns the memory address of the dialog.
|
| EXAMPLE:  
|
| NOTES:   
|
| ASSUMES: 
|
| HISTORY: 01.26.94 
|          09.19.98 Revised to return os-generic window
|                   instead of a 'DialogPtr'.
------------------------------------------------------------*/
Window*
LoadAndShowDialog( s16 ADialogID )
{
    Window* W;
    
    // Load the dialog resource as the front-most window
    // but don't draw it.
    W = LoadDialog( ADialogID ); 
    
    // Make the window front-most.
    MoveWindowToFront( W );
    
    // Show the dialog and generate an activate event to
    // make the dialog active.
    ShowGenericWindow( W );
    
    // Return the window address.
    return( W );
}

/*------------------------------------------------------------
| SetUserItemDrawProcedures
|-------------------------------------------------------------
|
| PURPOSE: To install the draw procedure addresses for 
| userItems which may be in the the given dialog list.
|
| DESCRIPTION: Searches through the item list of the given
| dialog and installs the 'DrawItemOutline' procedure.
|
| EXAMPLE:  
|
| NOTES: See page I-404,405 Inside Mac.  
|
| ASSUMES:  
|
| HISTORY: 02.07.94 
------------------------------------------------------------*/
void
SetUserItemDrawProcedures( DialogPtr ADialog )
{
    Rect    ItemRect;
    Handle  ItemHandle;
    s16     ItemType;
    Handle  ItemList;
    s16     ItemCount;
    s16     ItemNumber;
    
    ItemList = ( (DialogRecord *) ADialog )->items;
    
    // The item count - 1 is the first pair in the
    // item list record. see p. I-433.
    //
    ItemCount = **((s16**) ItemList);
    ItemCount++;
    
    ItemNumber = 1;
    
    while( ItemNumber <= ItemCount )
    {
        GetDialogItem( ADialog, 
                  ItemNumber,
                  &ItemType,
                  &ItemHandle,
                  &ItemRect );
                
        if( ItemType == userItem )
        {
            ItemHandle = (Handle) DrawItemOutline;
            
            SetDialogItem( ADialog,
                      ItemNumber,
                      ItemType,
                      ItemHandle,
                      &ItemRect );
        }
        
        ItemNumber++;
    }
             
}

#endif // FOR_MACOS

