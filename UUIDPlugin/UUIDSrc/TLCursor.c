/*------------------------------------------------------------
| TLCursor.c
|-------------------------------------------------------------
|
| PURPOSE: To provide Mac cursor functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 01.12.94 from MiniEdit.
------------------------------------------------------------*/

#include    <Quickdraw.h>

#include    "TLTypes.h"

#include    "TLCursor.h"

Cursor  editCursor;
Cursor  waitCursor;


/*------------------------------------------------------------
| SetArrowCursor
|-------------------------------------------------------------
|
| PURPOSE: To change the cursor to the standard arrow cursor.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.13.94 
|
------------------------------------------------------------*/
void
SetArrowCursor()
{
    InitCursor();
}

/*------------------------------------------------------------
| SetEditCursor
|-------------------------------------------------------------
|
| PURPOSE: To change the cursor to the standard edit cursor.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.13.94 
|
------------------------------------------------------------*/
void
SetEditCursor()
{
    SetCursor( &editCursor );
}

/*------------------------------------------------------------
| SetUpCursors
|-------------------------------------------------------------
|
| PURPOSE: To 
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.11.94 
|
------------------------------------------------------------*/
void 
SetUpCursors()
{
    CursHandle  hCurs;
    
    hCurs = GetCursor(1);
    editCursor = **hCurs;
    hCurs = GetCursor(watchCursor);
    waitCursor = **hCurs;
    SetArrowCursor();
}

/*------------------------------------------------------------
| SetWaitCursor
|-------------------------------------------------------------
|
| PURPOSE: To change the cursor to the watch cursor.
|
| DESCRIPTION: Signals a lengthy operation to the user.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 02.13.94 
|
------------------------------------------------------------*/
void
SetWaitCursor()
{
    SetCursor(&waitCursor);
}
