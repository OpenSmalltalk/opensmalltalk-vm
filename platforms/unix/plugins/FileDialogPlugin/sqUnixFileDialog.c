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

/*
 *  sqMacFileDialog.c
 *
 *  Copied from Mac OS sqMacFileDialog.c:
 *
 * This is a shell that only implements fileDialogGetLocation
 */

#include "sq.h"
#include "sqVirtualMachine.h"
#include "FileDialogPlugin.h"
#include "sqUnixCharConv.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h>


extern struct VirtualMachine *interpreterProxy; /* signalSemaphoreWithIndex */

#define DLG_MAX 10

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* fileDialogInitialize: Initialize file dialogs.
   Arguments: None.
   Return value: True if successful.
*/
int fileDialogInitialize(void) {
	return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* fileDialogCreate: Create a new host dialog.
   Arguments: None.
   Return value: Dialog handle, or -1 on error.
*/
int fileDialogCreate(void) { return -1; }

/* fileDialogSetLabel: Set the label to be used for the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     dlgLabel: Label for the dialog.
   Return value: None.
*/
void fileDialogSetLabel(int dlgHandle, char *dlgLabel) { }

/* fileDialogSetFile: Set the initial file/path of the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filePath: Initial file path.
   Return value: None.

   On the mac, we only use the file name, to initialize the save file name
   for save file dialogs.  
*/
void fileDialogSetFile(int dlgHandle, char *filePath) { }

/* fileDialogAddFilter: Add a filter to the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filterDesc: Description of the filter ("Text files (*.txt)")
     filterPattern: Filter pattern ("*.txt")
   Return value: None.
*/
void fileDialogAddFilter(int dlgHandle, char *filterDesc, char *filterPattern){ }

/* fileDialogSetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
     index: Current filter index (1-based)
   Return value: None.
*/
void fileDialogSetFilterIndex(int dlgHandle, int index) { }

/* fileDialogGetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: Current filter index (1-based)
*/
int fileDialogGetFilterIndex(int dlgHandle) { return -1; }

/* fileDialogDoneSemaphore: Set the semaphore to be signaled when done.
   Arguments:
     dlgHandle: Dialog handle.
     semaIndex: External semaphore index.
     Return value: None.
*/
void fileDialogDoneSemaphore(int dlgHandle, int semaIndex) { }

/* fileDialogSetProperty: Set a boolean property.
   Arguments:
     dlgHandle: Dialog handle.
     propName: Name of the property (see below)
     propValue: Boolean value of property.
   Return value: True if the property is supported, false otherwise.
*/
int fileDialogSetProperty(int dlgHandle, char *propName, int propValue) {
  return 0; /* no properties currently supported */
}

/* fileDialogShow: Show a file dialog.
   Arguments:
     dlgHandle: Dialog handle.
     fSaveAs: Display a "save as" dialog instead of an "open" dialog.
   Return value: True if successful, false otherwise.
*/
int fileDialogShow(int dlgHandle, int fSaveAs) { return 0; }

/* fileDialogDone: Answer whether a file dialog is finished.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if dialog is finished or invalid (!); false if busy.
*/
int fileDialogDone(int dlgHandle) { return 1; }

/* fileDialogGetResult: Get the result of a file dialog invokation.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: File path or NULL if canceled.
   N.B.  We fail this primitive so that the image can use the failure to detect
   that the plugin does not support native dialogs.
*/
char *fileDialogGetResult(int dlgHandle) {
	interpreterProxy->primitiveFail();
	return NULL;
}

/* fileDialogDestroy: Destroy the given file dialog.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if successfully destroyed; false if not.
*/
int fileDialogDestroy(int dlgHandle) { return 0; }

/* fileDialogGetLocation: Return a known file location.
   Arguments:
     location: Symbolic name for a path.
   Return value: Path for the given location or NULL.
*/
char *fileDialogGetLocation(char *location){
	struct stat s;
	static char path[FILENAME_MAX];

#define okdir(f) (access(f,R_OK|X_OK) >= 0 && stat(f,&s) >= 0 && (s.st_mode & S_IFDIR))

	if (strcmp("home", location) == 0)
		return getenv("HOME");
	if (strcmp("temp", location) == 0) {
		char *usrtmp = getenv("TMPDIR");
		if (usrtmp && okdir(usrtmp))
			return usrtmp;
		if (okdir("/usr/tmp"))
			return "/usr/tmp";
	}
	if (strcmp("desktop", location) == 0) {
		char *home = getenv("HOME");
		if (home) {
			strcpy(path,home);
			strcat(path,"/Desktop");
			if (okdir(path))
				return path;
		}
	}
#if 0 // this is for reference, listing the full set of names
	if (strcmp("preferences", location) == 0) {
		err = FSFindFolder(kUserDomain, kPreferencesFolderType, 1, &fsRef);
	}
	if (strcmp("applications", location) == 0) {
		err = FSFindFolder(kLocalDomain, kApplicationsFolderType, 1, &fsRef);
	}
	if (strcmp("fonts", location) == 0) {
		err = FSFindFolder(kLocalDomain, kFontsFolderType, 1, &fsRef);
	}
	if (strcmp("documents", location) == 0) {
		err = FSFindFolder(kUserDomain, kDocumentsFolderType, 1, &fsRef);
	}
	if (strcmp("music", location) == 0) {
		err = FSFindFolder(kUserDomain, kMusicDocumentsFolderType, 1, &fsRef);
	}
	if (strcmp("pictures", location) == 0) {
		err = FSFindFolder(kUserDomain, kPictureDocumentsFolderType, 1, &fsRef);
	}
	if (strcmp("videos", location) == 0) {
		err = FSFindFolder(kUserDomain, kMovieDocumentsFolderType, 1, &fsRef);
	}
#endif
	return 0;
}
