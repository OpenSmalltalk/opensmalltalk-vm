/*------------------------------------------------------------
| TLWin.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to general window functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 12.05.96
------------------------------------------------------------*/

#ifndef _TLWIN_H_
#define _TLWIN_H_

#if macintosh
#include <Windows.h>
#include <TextEdit.h>
#endif

// All information about a window.
typedef struct
{
    Item*       MyItem;       // The address of the Item record in the
                              // master window list that refers to this
                              // record.
                              //
    s8*         Title;        // If non-zero, the title of the window. 
                              // Dynamic C-string.
                              //
    s8*         Path;         // If non-zero, the full path to the file 
                              // that is associated the window. Dynamic 
                              // C-string.
                              //
    s32         VolRef;       // Volume reference number of the volume
                              // holding the file associated with the window.
                              //
    WindowPtr   Wos;          // OS-specific window structure.  On the Mac
                              // this refers to any type of window.
                              //
    u32         DialogID;     // OS-specific dialog resource identifier.
                              //    
    Rect        Content;      // The content rectangle of the window in global 
                              // coordinate space.
                              //
    u32         IsVisible;    // 1 if the window is visible.
                              //
    u32         IsColor;      // 1 if the window is color; 0 if mono.
                              //
    u32         IsText;       // 1 if the window holds text.
                              //
    u32         IsGraphics;   // 1 if the window holds graphics.
                              //
    u32         IsDocument;   // 1 if the window holds a document.
                              //
    u32         IsDialog;     // 1 if the window is a dialog window.
                              //
    u32         IsFile;       // 1 if a file is associated with the
                              // window.
                              //
    u32         IsEditable;   // 1 if the window contains editable data.
                              //
    u32         IsFileOnDisk; // 1 if a file is associated with the
                              // window is on disk.
                              //
    u32         IsDataChanged;// If the data of the window has been changed since 
                              // the data was created or read from disk.
                              //
    u32         IsDiskUpdateRequired;// 1 if the window data in memory needs
                              // to be updated to disk.
                              // 
    u32         IsUpdateRequired; // 1 if the image in the window needs
                              // to be updated on the display.
                              //
    List*       Controls;     // A list of the controls associated
                              // with the window.
                              //
//TL    WindowData* D;        // Contents of the window, text and images.
                              //
    TEHandle    TE;           // Text editing record reference.
                              //
    u32         UpdateProcedure; // Address of the procedure to
                              // call to update the window.
                              //
    u32         ActivateProcedure; // Address of the procedure to
                              // call to activate the window.
                              //
    u32         DeactivateProcedure; // Address of the procedure to
                              // call to deactivate the window.
} Window;

extern List*    TheWindowList;
                // The list of the currently open windows.
                // The data address field of each item holds
                // the address of a dynamically allocated
                // 'Window' record.  The windows are ordered 
                // from front to back, so the first window
                // is front-most.

extern Window*  TheWindow;
                // The current active, front-most window.
                
extern List*    TheGraphicsWindowList;
                // The list of the currently open graphics
                // window records.

void    ActivateWindow( Window* );
void    DeactivateWindow( Window* );
void    DeleteGenericWindow( Window* );
Window* FindFrontMostEditableWindow();
Window* FindFrontMostTextWindow();
Window* FindOSGenericWindow( WindowPtr );
Window* FindWindowForFile( s8*, s16 );
void    HideGenericWindow( Window* );
u32     IsAnyEditableWindows();
Window* MakeGenericWindow();
void    MakeWindowInvisible( Window* );
void    MakeWindowVisible( Window* );
void    MoveWindowToFront( Window* );
void    SetPathOfGenericWindow( Window*, s8* );
void    SetTitleOfGenericWindow( Window*, s8* );
void    SetUpTheWindowSystem();
void    ShowGenericWindow( Window* );
void    UpdateWindowImage( Window* );


#endif // _TLWIN_H_
