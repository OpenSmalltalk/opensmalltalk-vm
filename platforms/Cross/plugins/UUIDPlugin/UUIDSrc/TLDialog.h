/*------------------------------------------------------------
| NAME: TLDialog.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to general dialog functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 11.25.96
------------------------------------------------------------*/
#ifndef _DIALOG_H_
#define _DIALOG_H_

// ------------------------ EQUATES ------------------------- 
// Alert Resource IDs
#define YesNoAlertID            6691
#define YesNoCancelAlertID      6692
#define OkAlertID               6693


// Alert Button IDs
#define OkButtonID      1
#define YesButtonID     1
#define NoButtonID      2
#define CancelButtonID  3

void        DeleteDialog(DialogPtr);
void        DoActivateDialog();
s16         DoAlert(s16);
void        DoUpdateDialog();
pascal 
void        DrawItemOutline(WindowPtr,s16);
Window*     LoadDialog(s16);
Window*     LoadAndShowDialog(s16);
void        SetUserItemDrawProcedures(DialogPtr);

#endif

