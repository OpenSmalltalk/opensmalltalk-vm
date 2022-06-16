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
 */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <sys/stat.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "FileDialogPlugin.h"

extern struct VirtualMachine *interpreterProxy; /* signalSemaphoreWithIndex */

#define DLG_MAX 10

typedef struct {
	char *result;
	char **results;
	char *title;
	char *saveFileName;
	char *directory;
	char *filters;
	int doneSema;
	int panelResponse;
	int nResults;
	char used, multiSelect;
} sqMacFileDialog;

static sqMacFileDialog allDialogs[DLG_MAX];

extern WindowPtr getSTWindow();

// THIS IS HOW TO OPEN ASYNCHRONOUSLY:
// https://developer.apple.com/documentation/appkit/nssavepanel/1535870-beginsheetmodalforwindow?language=objc
// https://github.com/JHiroGuo/JHPanel

/* dlgFromHandle: Convert a dialog handle into a reference.
   Arguments:
     dlgHandle: Handle for the dialog.
   Return value: Dialog reference or NULL
*/
static sqMacFileDialog *
dlgFromHandle(int dlgHandle)
{
	if (dlgHandle >= 0 && dlgHandle < DLG_MAX) {
		sqMacFileDialog *dlg = allDialogs + dlgHandle;
		if (dlg->used)
			return dlg;
	}
	return NULL;
}

/* fileDialogInitialize: Initialize file dialogs.
   Arguments: None.
   Return value: True if successful.
*/
int
fileDialogInitialize(void)
{
	for (int i = 0; i < DLG_MAX; i++)
		allDialogs[i].used = 0;
	return 1;
}

/* fileDialogCreate: Create a new host dialog.
   Arguments: None.
   Return value: Dialog handle, or -1 on error.
*/
int
fileDialogCreate(void)
{
  for (int i=0; i<DLG_MAX; i++)
    if (!allDialogs[i].used) {
	  sqMacFileDialog *dlg = allDialogs+i;
      memset((void *)dlg, 0, sizeof(*dlg));
	  dlg->panelResponse = -1;
      dlg->used = 1;
      return i;
    }
  return -1;
}

/* fileDialogSetLabel: Set the label to be used for the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     dlgLabel: Label for the dialog.
   Return value: None.
*/
void
fileDialogSetLabel(int dlgHandle, char *dlgLabel)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (dlg)
		dlg->title = strdup(dlgLabel);
}

/* fileDialogSetFile: Set the initial file/path of the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filePath: Initial file path.
   Return value: None.

   On the mac, we only use the file name, to initialize the save file name
   for save file dialogs.  
*/
void
fileDialogSetFile(int dlgHandle, char *path)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (dlg) {
		char *fname = strrchr(path, '/');
		struct stat statBuf;
		int isDirectory = !stat(path, &statBuf) && (statBuf.st_mode & S_IFDIR);

		dlg->directory = strdup(path);
		if (fname && !isDirectory) {
			dlg->directory[fname - path] = 0;
			if (*++fname) /* Did not end with a slash; there is a path */
				dlg->saveFileName = strdup(fname);
		}
		else /* No slash - path is just a name. */
			dlg->saveFileName = strdup(path);
	}
}

/* fileDialogAddFilter: Add a filter to the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filterDesc: Description of the filter ("Text files (*.txt)")
     filterPattern: Filter pattern ("*.txt")
   Return value: None.
*/
void
fileDialogAddFilter(int dlgHandle, char *filterDesc, char *filterPattern)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);

	if (!dlg
	 || !filterPattern
	 || !strlen(filterPattern)
	 || (filterPattern[0] == '*' && filterPattern[1] == '.' && !filterPattern[2]))
		return;

#if 0
	if (filterPattern[0] == '*' && filterPattern[1] == '.')
		filterPattern += 2;
#endif

	if (!dlg->filters) {
		dlg->filters = strdup(filterPattern);
		return;
	}
	/* Terf's file patterns tend to look like
	 *	Everything: *.ext1;*.ext2
	 *	Thing One: *.ext1
	 *	Thing Two: *.ext2
	 * but duplications aren't helpful; filter them out.
	 */
	if (strstr(dlg->filters,filterPattern))
		return;

	int sz = strlen(dlg->filters) + strlen(filterPattern) + 2;
	char *new = malloc(sz);
	if (!new)
		return;
	strcat(new,dlg->filters);
	strcat(new,";");
	strcat(new,filterPattern);
	free(dlg->filters);
	dlg->filters = new;
}

/* fileDialogSetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
     index: Current filter index (1-based)
   Return value: None.
*/
/* -- ignored; the mac always shows all available files on open -- */
void
fileDialogSetFilterIndex(int dlgHandle, int index) { }

/* fileDialogGetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: Current filter index (1-based)
*/
/* -- ignored; the mac always uses the first filter index -- */
int
fileDialogGetFilterIndex(int dlgHandle) { return 1; }

/* fileDialogDoneSemaphore: Set the semaphore to be signaled when done.
   Arguments:
     dlgHandle: Dialog handle.
     semaIndex: External semaphore index.
     Return value: None.
*/
void
fileDialogDoneSemaphore(int dlgHandle, int semaIndex)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (dlg)
		dlg->doneSema = semaIndex;
}

/* fileDialogSetProperty: Set a boolean property.
   Arguments:
     dlgHandle: Dialog handle.
     propName: Name of the property (see below)
     propValue: Boolean value of property.
   Return value: True if the property is supported, false otherwise.
*/
int
fileDialogSetProperty(int dlgHandle, char *propName, int propValue)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (!dlg)
		return 0;
	if (!strcmp(propName,"multiSelect")) {
		dlg->multiSelect = (char)propValue;
		return 1;
	}
	return 0;
}

/* fileDialogShow: Show a file dialog.
   Arguments:
     dlgHandle: Dialog handle.
     fSaveAs: Display a "save as" dialog instead of an "open" dialog.
   Return value: Answer if successful.
*/
int
fileDialogShow(int dlgHandle, int fSaveAs)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);

	if (!dlg)
		return 0;

	NSOpenPanel *panel = fSaveAs
						? (NSOpenPanel *)[NSSavePanel savePanel]
						: [NSOpenPanel openPanel];
	if (dlg->title) {
		NSString *title = [[NSString alloc]
							initWithBytesNoCopy: dlg->title
							length: strlen(dlg->title)
							encoding: kCFStringEncodingUTF8
							freeWhenDone: false];
		[panel setTitle: title];
		[panel setMessage: title];
	}
	if (dlg->saveFileName) {
		NSString *saveFileName = [[NSString alloc]
									initWithBytesNoCopy: dlg->saveFileName
									length: strlen(dlg->saveFileName)
									encoding: kCFStringEncodingUTF8
									freeWhenDone: false];
		[panel setNameFieldStringValue: saveFileName];
	}
	if (dlg->directory) {
		NSString *directory = [[NSString alloc]
									initWithBytesNoCopy: dlg->directory
									length: strlen(dlg->directory)
									encoding: kCFStringEncodingUTF8
									freeWhenDone: false];
		[panel setDirectoryURL:[NSURL fileURLWithPath: (@"file://", directory)]];
	}
	if (dlg->filters && !strstr(dlg->filters, "*.*")) {
		char *p = dlg->filters;
		int nFilters = 1;

		while (*p) if (*p++ == ';' && *p) ++nFilters;

		NSMutableArray *fileTypes = [NSMutableArray arrayWithCapacity: nFilters];

		p = dlg->filters;
		for (int i = 0; i < nFilters; i++) {
			char *separator = strchr(p,';');
			char *filterPattern = p[0] == '*' && p[1] == '.' ? p + 2 : p;
			fileTypes[i] = [[NSString alloc]
								initWithBytesNoCopy: filterPattern
								length: (separator ? separator - filterPattern : strlen(filterPattern))
								encoding: kCFStringEncodingUTF8
								freeWhenDone: false];
			p = separator + 1;
		}
		[panel setAllowedFileTypes: fileTypes];
	}
	if (dlg->multiSelect && !fSaveAs)
		[panel setAllowsMultipleSelection: true];
	[panel beginWithCompletionHandler: ^(NSInteger response) {
		if ((dlg->panelResponse = (int)response) == NSModalResponseOK) {
			if (dlg->multiSelect) {
				dlg->results = malloc((dlg->nResults = [panel.URLs count]) * sizeof(void *));
				int i = 0;
				for (NSURL *fileURL in [panel URLs])
					dlg->results[i++] = strdup([fileURL.path UTF8String]);
			}
			else {
				dlg->nResults = 1;
				dlg->result = strdup([panel.URL.path UTF8String]);
			}
		}
		if (dlg->doneSema)
			interpreterProxy->signalSemaphoreWithIndex(dlg->doneSema);
	  }];
	/** The dialog is running as a window-modal overlay atop the main Squeak window. **/
	return 1;
}

/* fileDialogDone: Answer whether a file dialog is finished.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: Answer if dialog is finished.
*/
int
fileDialogDone(int dlgHandle)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	return dlg && dlg->panelResponse >= 0;
}

/* fileDialogGetResults: Get the results of a "multiSelect" file dialog invocation.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: File path or NULL if canceled or not multiSelect.
*/
sqInt
fileDialogGetResults(int dlgHandle)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (!dlg
	 || dlg->panelResponse == NSModalResponseCancel
	 || !dlg->multiSelect
	 || dlg->nResults == 1)
		return 0;

	sqInt result = interpreterProxy->instantiateClassindexableSize
							(interpreterProxy->classArray(),
							 dlg->nResults);
	for (int i = dlg->nResults; --i >= 0; )
		interpreterProxy->storePointerofObjectwithValue
							(i,
							 result,
							 interpreterProxy->stringForCString(dlg->results[i]));
	return result;
}

/* fileDialogGetResult: Get the result of a file dialog invocation.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: File path or NULL if canceled.
   N.B.  We do not fail this primitive with a 0 dlgHandle so that the image can
   use the success of this primitive to detect that the plugin does support
   native dialogs.
*/
char *
fileDialogGetResult(int dlgHandle)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	return (!dlg || dlg->panelResponse == NSModalResponseCancel)
		? 0
		: (dlg->multiSelect ? dlg->results[0] : dlg->result);
}

/* fileDialogDestroy: Destroy the given file dialog.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if successfully destroyed; false if not.
*/
int
fileDialogDestroy(int dlgHandle)
{
	sqMacFileDialog *dlg = dlgFromHandle(dlgHandle);
	if (!dlg)
		return 0;
	if (dlg->multiSelect) {
		if (dlg->results) {
			for (int i = dlg->nResults; --i >= 0; )
				free(dlg->results[i]);
			free(dlg->results);
		}
	}
	else if (dlg->result)
		free(dlg->result);
	if (dlg->title) free(dlg->title);
	if (dlg->saveFileName) free(dlg->saveFileName);
	if (dlg->directory) free(dlg->directory);
	if (dlg->filters) free(dlg->filters);
	dlg->used = 0;
	return 1;
}

/* fileDialogGetLocation: Return a known file location.
   Arguments:
     location: Symbolic name for a path.
   Return value: Path for the given location or NULL.
*/
char *
fileDialogGetLocation(char *location)
{
	OSErr err;
	FSRef fsRef;
	static char result[MAXPATHLEN+1];

	result[0] = 0;

// https://stackoverflow.com/questions/19404239/locating-mac-os-x-folders-using-urlfordirectory-instead-of-fsfindfolder
// NSAdminApplicationDirectory
// NSAllApplicationsDirectory
// NSAllLibrariesDirectory
// NSApplicationDirectory
// NSApplicationScriptsDirectory
// NSApplicationSupportDirectory
// NSAutosavedInformationDirectory
// NSCachesDirectory
// NSCoreServiceDirectory
// NSDemoApplicationDirectory
// NSDesktopDirectory
// NSDeveloperApplicationDirectory
// NSDeveloperDirectory
// NSDocumentDirectory
// NSDocumentationDirectory
// NSDownloadsDirectory
// NSInputMethodsDirectory
// NSItemReplacementDirectory
// NSLibraryDirectory
// NSMoviesDirectory
// NSMusicDirectory
// NSPicturesDirectory
// NSPreferencePanesDirectory
// NSPrinterDescriptionDirectory
// NSSharedPublicDirectory
// NSTrashDirectory
// NSUserDirectory

	if (!strcmp("applications", location))
		err = FSFindFolder(kLocalDomain, kApplicationsFolderType, 1, &fsRef);
	else if (!strcmp("desktop", location))
		err = FSFindFolder(kUserDomain, kDesktopFolderType, 1, &fsRef);
	else if (!strcmp("documents", location))
		err = FSFindFolder(kUserDomain, kDocumentsFolderType, 1, &fsRef);
	else if (!strcmp("fonts", location))
		err = FSFindFolder(kLocalDomain, kFontsFolderType, 1, &fsRef);
	else if (!strcmp("home", location))
		err = FSFindFolder(kUserDomain, kCurrentUserFolderType, 1, &fsRef);
	else if (!strcmp("music", location))
		err = FSFindFolder(kUserDomain, kMusicDocumentsFolderType, 1, &fsRef);
	else if (!strcmp("pictures", location))
		err = FSFindFolder(kUserDomain, kPictureDocumentsFolderType, 1, &fsRef);
	else if (!strcmp("preferences", location))
		err = FSFindFolder(kUserDomain, kPreferencesFolderType, 1, &fsRef);
	else if (!strcmp("temp", location))
#if 0	// On Big Sur access to the temp directory is problematic; one can't see the
		// containing folder, and one can't necesseraly write to it.  So use a
		// temp directory in our preferences directory.
		err = FSFindFolder(kLocalDomain, kTemporaryFolderType, 1, &fsRef);
#else
		err = FSFindFolder(kUserDomain, kPreferencesFolderType, 1, &fsRef);
#endif
	else if (!strcmp("videos", location))
		err = FSFindFolder(kUserDomain, kMovieDocumentsFolderType, 1, &fsRef);
	else
		return NULL;

	if (err) {
		//printf("fileDialogGetLocation(\'%s\'): FSFindFolder error code %d (%x) \n", location, err, err);
		return NULL;
	}

	err = FSRefMakePath(&fsRef, result, MAXPATHLEN);
	if (!err) {
		if (!strcmp("temp", location))
			strcat(result,"/OpenQwaq/tmp");
		return result;
	}
	// printf("fileDialogGetLocation FSRefMakePath error: %d\n", err);
	return NULL;
}
