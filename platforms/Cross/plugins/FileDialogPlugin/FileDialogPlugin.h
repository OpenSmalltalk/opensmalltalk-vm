/**
 * Project OpenQwaq
 *
 * Copyright (c) 2005-2021, 3D Immersive Collaboration Corp., All Rights Reserved
 *
 * Redistributions in source code form must reproduce the above
 * copyright and this condition.
 *
 * The contents of this file are subject to the GNU General Public
 * License, Version 2 (the "License"); you may not use this file
 * except in compliance with the License. A copy of the License is
 * available at http://www.opensource.org/licenses/gpl-2.0.php.
 *
 */

/* FileDialogPlugin.h: Header file for file dialog support. */

/* fileDialogInitialize: Initialize file dialogs.
   Arguments: None.
   Return value: True if successful.
*/
int fileDialogInitialize(void);

/* fileDialogGetLocation: Return a known file location.
   Arguments:
     location: Symbolic name for a path.
   Return value: Path for the given location or NULL.
*/
char *fileDialogGetLocation(char *location);

/* fileDialogCreate: Create a new host dialog.
   Arguments: None.
   Return value: Dialog handle.
*/
int fileDialogCreate(void);

/* fileDialogSetLabel: Set the label to be used for the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     dlgLabel: Label for the dialog.
   Return value: None.
*/
void fileDialogSetLabel(int dlgHandle, char *dlgLabel);

/* fileDialogSetFile: Set the initial file/path of the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filePath: Initial file path.
   Return value: None.
*/
void fileDialogSetFile(int dlgHandle, char *filePath);

/* fileDialogSetLabel: Set the label of the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     dlgLabel: Dialog label.
   Return value: None.
*/
void fileDialogSetLabel(int dlgHandle, char *dlgLabel);

/* fileDialogAddFilter: Add a filter to the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filterDesc: Description of the filter ("Text files (*.txt)")
     filterPattern: Filter pattern ("*.txt")
   Return value: None.
*/
void fileDialogAddFilter(int dlgHandle, char *filterDesc, char *filterPattern);

/* fileDialogSetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
     index: Current filter index (1-based)
   Return value: None.
*/
void fileDialogSetFilterIndex(int dlgHandle, int index);

/* fileDialogGetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: Current filter index (1-based)
*/
int fileDialogGetFilterIndex(int dlgHandle);

/* fileDialogDoneSemaphore: Set the semaphore to be signaled when done.
   Arguments:
     dlgHandle: Dialog handle.
     semaIndex: External semaphore index.
     Return value: None.
*/
void fileDialogDoneSemaphore(int dlgHandle, int semaIndex);

/* fileDialogSetProperty: Set a boolean property.
   Arguments:
     dlgHandle: Dialog handle.
     propName: Name of the property (see below)
     propValue: Boolean value of property.
   Return value: True if the property is supported, false otherwise.
*/
int fileDialogSetProperty(int dlgHandle, char *propName, int propValue);

/* fileDialogShow: Show a file dialog.
   Arguments:
     dlgHandle: Dialog handle.
     fSaveAs: Display a "save as" dialog instead of an "open" dialog.
   Return value: True if successful, false otherwise.
*/
int fileDialogShow(int dlgHandle, int fSaveAs);

/* fileDialogDone: Answer whether a file dialog is finished.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if dialog is finished or invalid (!); false if busy.
*/
int fileDialogDone(int dlgHandle);

/* fileDialogGetResult: Get the result of a file dialog invokation.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: File path or NULL if canceled.
*/
char *fileDialogGetResult(int dlgHandle);

/* fileDialogDestroy: Destroy the given file dialog.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if successfully destroyed; false if not.
*/
int fileDialogDestroy(int dlgHandle);
