/*------------------------------------------------------------
| NAME: TLCursor.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to Mac cursor functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 01.12.94 from MiniEdit.
------------------------------------------------------------*/
#ifndef _CURSOR_H_
#define _CURSOR_H_

 
extern Cursor   editCursor;
extern Cursor   waitCursor;

void        SetArrowCursor();
void        SetEditCursor();
void        SetUpCursors();
void        SetWaitCursor();

#endif
