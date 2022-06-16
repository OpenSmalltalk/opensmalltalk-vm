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

/* Win32 File Dialog support */
#include <stdio.h>
#include <ShlObj.h>
#include <malloc.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "FileDialogPlugin.h"


#if _WIN32_WINNT < 0x0500 /* i.e., an old mingw */

static HRESULT (__stdcall *SHGetFolderPathW)(HWND, int, HANDLE, DWORD, WCHAR*);

#define CSIDL_APPDATA 0x001A
#define CSIDL_PROGRAM_FILES 0x0026
#define CSIDL_MYMUSIC 0x000D
#define CSIDL_MYPICTURES 0x0027
#define CSIDL_MYVIDEO 0x000E
#define CSIDL_PROFILE	40

#endif

#define DLG_MAX 10

typedef struct {
  int used;
  int doneSema;
  char *filterDesc;
  DWORD errorCode;
  OPENFILENAMEW ofn;
  HANDLE hThread;
} sqWin32FileDialog;

extern struct VirtualMachine *interpreterProxy;
static HWND *theSTWindow = NULL; /* a reference to Squeak's main window */
static sqWin32FileDialog allDialogs[DLG_MAX];

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* dlgFromHandle: Convert a dialog handle into a reference.
   Arguments:
     dlgHandle: Handle for the dialog.
   Return value: Dialog reference or NULL
*/
static sqWin32FileDialog *
dlgFromHandle(int dlgHandle)
{
	if (dlgHandle >= 0 && dlgHandle < DLG_MAX) {
		sqWin32FileDialog *dlg = allDialogs + dlgHandle;
		if (dlg->used)
			return dlg;
	}
	return NULL;
}

/* runOpenDlg: Run the file open dialog in a separate thread.
   Arguments:
     dlg: The dialog reference.
   Return value: Nothing.
*/
static DWORD WINAPI
runOpenDlg(LPVOID lpParam)
{
  sqWin32FileDialog *dlg = (sqWin32FileDialog*)lpParam;
  int ok;

  dlg->ofn.Flags |= OFN_HIDEREADONLY;
  ok = GetOpenFileNameW(&dlg->ofn);
  if (!ok) {
    /* user canceled or error */
    dlg->errorCode = CommDlgExtendedError();
    dlg->ofn.lpstrFile[0] = 0;
  }
  CloseHandle(dlg->hThread);
  dlg->hThread = 0;
  if (dlg->doneSema) interpreterProxy->signalSemaphoreWithIndex(dlg->doneSema);
  ExitThread(0);
}

/* runSaveDlg: Run the file save dialog in a separate thread.
   Arguments:
     dlg: The dialog reference.
   Return value: Nothing.
*/
static DWORD WINAPI
runSaveDlg(LPVOID lpParam)
{
  sqWin32FileDialog *dlg = (sqWin32FileDialog*)lpParam;
  int ok = GetSaveFileNameW(&dlg->ofn);
  if (!ok) {
    /* user canceled or error */
    dlg->errorCode = CommDlgExtendedError();
    dlg->ofn.lpstrFile[0] = 0;
  }
  CloseHandle(dlg->hThread);
  dlg->hThread = 0;
  if (dlg->doneSema)
	interpreterProxy->signalSemaphoreWithIndex(dlg->doneSema);
  ExitThread(0);
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* fileDialogInitialize: Initialize file dialogs.
   Arguments: None.
   Return value: True if successful.
*/
int
fileDialogInitialize(void)
{
  int i;
  HANDLE hShell;

  theSTWindow = (HWND*) interpreterProxy->ioLoadFunctionFrom("stWindow","");
  for (i = 0; i < DLG_MAX; i++)
    allDialogs[i].used = 0;

#if _WIN32_WINNT < 0x0500 /* i.e. on old mingw */
  hShell = LoadLibrary("SHFolder.dll");
  SHGetFolderPathW = (void*)GetProcAddress(hShell, "SHGetFolderPathW");
#endif
  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* fileDialogCreate: Create a new host dialog.
   Arguments: None.
   Return value: Dialog handle, or -1 on error.
*/
int
fileDialogCreate(void)
{
  sqWin32FileDialog *dlg;
  int i;

  for (i=0; i<DLG_MAX; i++) {
    if (!allDialogs[i].used) {
      dlg = allDialogs+i;
      dlg->used = 1;
      dlg->errorCode = 0;
      dlg->filterDesc = NULL;
      memset(&dlg->ofn, 0, sizeof(dlg->ofn));
      dlg->ofn.lStructSize = sizeof(dlg->ofn);
      dlg->ofn.nMaxFile = MAX_PATH;
      dlg->ofn.lpstrFile = calloc(dlg->ofn.nMaxFile+1, sizeof(WCHAR));
      dlg->ofn.lpstrFile[0] = 0;
      return i;
    }
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
fileDialogSetLabel(int dlgHandle, char* dlgLabel)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  int sz;
  if (!dlg)
	return;
  sz = MultiByteToWideChar(CP_UTF8, 0, dlgLabel, -1, NULL, 0);
  dlg->ofn.lpstrTitle = calloc(sz, sizeof(WCHAR));
  MultiByteToWideChar(CP_UTF8, 0, dlgLabel, -1, (LPTSTR)dlg->ofn.lpstrTitle, sz);  
}

/* fileDialogSetFile: Set the initial file/path of the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filePath: Initial file path.
   Return value: None.
*/
void fileDialogSetFile(int dlgHandle, char* filePath)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  int sz;
  if (!dlg)
	return;
  if (filePath[strlen(filePath)-1] == '\\') {
    /* it's a path - use initial dir */
    if (dlg->ofn.lpstrInitialDir) free(dlg->ofn.lpstrInitialDir);
    sz = MultiByteToWideChar(CP_UTF8, 0, filePath, -1, NULL, 0);
    dlg->ofn.lpstrInitialDir = calloc(sz, sizeof(WCHAR));
    MultiByteToWideChar(CP_UTF8, 0, filePath,-1,dlg->ofn.lpstrInitialDir,sz);
  }
  else {
    /* it's a file - use lpstrFile */
    MultiByteToWideChar(CP_UTF8, 0, filePath, -1, 
			dlg->ofn.lpstrFile, dlg->ofn.nMaxFile);
  }
}

/* fileDialogAddFilter: Add a filter to the dialog.
   Arguments:
     dlgHandle: Dialog handle.
     filterDesc: Description of the filter ("Text files (*.txt)")
     filterPattern: Filter pattern ("*.txt")
   Return value: None.
*/
void fileDialogAddFilter(int dlgHandle, char* filterDesc, char* filterPattern){
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  char *newFilter, *filterStart, *filterEnd;
  int sz, delta;

  if (!dlg)
	return;

  sz = (int)(strlen(filterDesc) + strlen(filterPattern)) + 3;
  filterStart = dlg->filterDesc;
  filterEnd   = dlg->filterDesc;
  if (filterStart) {
    while (filterEnd[0]) {
      /* skip past previous entries */
      filterEnd += strlen(filterEnd)+1;
      filterEnd += strlen(filterEnd)+1;
    }
    /* copy previous contents */
    delta = (int)(filterEnd-filterStart);
    newFilter = malloc(sz+delta);
    memcpy(newFilter, filterStart, delta);
    free(filterStart);
    filterStart = newFilter+delta;
  }
  else
    newFilter = filterStart = malloc(sz);

  /* copy new filter description */
  sz = (int)strlen(filterDesc)+1;
  memcpy(filterStart,filterDesc, sz); 
  filterStart += sz;

  /* copy new filter pattern */
  sz = (int)strlen(filterPattern)+1;
  memcpy(filterStart,filterPattern, sz); 
  filterStart += sz;

  /* final zero */
  filterStart[0] = 0;
  dlg->filterDesc = newFilter;

  sz = MultiByteToWideChar(CP_UTF8,0,newFilter,(int)(filterStart-newFilter+1),0,0);
  if (dlg->ofn.lpstrFilter)
	free(dlg->ofn.lpstrFilter);
  dlg->ofn.lpstrFilter = calloc(sz, sizeof(WCHAR));
  MultiByteToWideChar(CP_UTF8, 0, newFilter, (int)(filterStart - newFilter + 1),
						(LPWSTR)dlg->ofn.lpstrFilter, sz);
}

/* fileDialogSetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
     index: Current filter index (1-based)
   Return value: None.
*/
void
fileDialogSetFilterIndex(int dlgHandle, int index)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (dlg)
	dlg->ofn.nFilterIndex = index-1;
}

/* fileDialogGetFilterIndex: Set the current filter.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: Current filter index (1-based)
*/
int
fileDialogGetFilterIndex(int dlgHandle)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (!dlg)
	return 0;
  return dlg->ofn.nFilterIndex+1;
}

/* fileDialogDoneSemaphore: Set the semaphore to be signaled when done.
   Arguments:
     dlgHandle: Dialog handle.
     semaIndex: External semaphore index.
     Return value: None.
*/
void
fileDialogDoneSemaphore(int dlgHandle, int semaIndex)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (dlg) dlg->doneSema = semaIndex;
}

/* fileDialogSetProperty: Set a boolean property.
   Arguments:
     dlgHandle: Dialog handle.
     propName: Name of the property (see below)
     propValue: Boolean value of property.
   Return value: True if the property is supported, false otherwise.
*/
int
fileDialogSetProperty(int dlgHandle, char* propName, int propValue)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (!dlg)
	return 0;

  if (!strcmp(propName, "oldFilesOnly")) {
    if (propValue) dlg->ofn.Flags |= OFN_FILEMUSTEXIST;
    return 1;
  }
  if (!strcmp(propName, "overwritePrompt")) {
    if (propValue) dlg->ofn.Flags |= OFN_OVERWRITEPROMPT;
    return 1;
  }
  return 0; /* no properties currently supported */
}

/* fileDialogShow: Show a file dialog.
   Arguments:
     dlgHandle: Dialog handle.
     fSaveAs: Display a "save as" dialog instead of an "open" dialog.
   Return value: True if successful, false otherwise.
*/
int
fileDialogShow(int dlgHandle, int fSaveAs)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  LPTHREAD_START_ROUTINE proc;
  DWORD id;

  if (!dlg)
	return 0;

  if (theSTWindow) dlg->ofn.hwndOwner = *theSTWindow;

  proc = (LPTHREAD_START_ROUTINE) (fSaveAs ? runSaveDlg : runOpenDlg);
  dlg->hThread = CreateThread(NULL, 128*1024, proc, (LPVOID)dlg, 
			      STACK_SIZE_PARAM_IS_A_RESERVATION, &id);
  if (!dlg->hThread) {
    MessageBoxA(0, "Failed to create Thread", "FileDialogPlugin", MB_OK);
    return 0;
  }
  return 1;
}

/* fileDialogDone: Answer whether a file dialog is finished.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if dialog is finished or invalid (!); false if busy.
*/
int
fileDialogDone(int dlgHandle)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (dlg && dlg->hThread)
	return 0;
  return 1;
}

/* fileDialogGetResults: Get the results of a "multiSelect" file dialog invocation.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: File path or NULL if canceled or not multiSelect.
*/
sqInt
fileDialogGetResults(int dlgHandle) { return 0; }

/* fileDialogGetResult: Get the result of a file dialog invokation.
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
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  static char result[MAX_PATH];
  if (!dlg)
	return NULL; /* fail */
  if (dlg->errorCode != 0) {
    /* FAIL */
    interpreterProxy->primitiveFail();
    return NULL;
  }
  WideCharToMultiByte(CP_UTF8, 0, dlg->ofn.lpstrFile, -1, result, MAX_PATH, 0, 0);
  return result;
}

/* fileDialogDestroy: Destroy the given file dialog.
   Arguments:
     dlgHandle: Dialog handle.
   Return value: True if successfully destroyed; false if not.
*/
int
fileDialogDestroy(int dlgHandle)
{
  sqWin32FileDialog *dlg = dlgFromHandle(dlgHandle);
  if (!dlg)
	return 1; /* doesn't exist; ignore error */
  if (dlg && dlg->hThread)
	return 0; /* still running */

  if (dlg->filterDesc) free(dlg->filterDesc);
  if (dlg->ofn.lpstrFile) free(dlg->ofn.lpstrFile);
  if (dlg->ofn.lpstrTitle) free(dlg->ofn.lpstrTitle);
  if (dlg->ofn.lpstrFilter) free(dlg->ofn.lpstrFilter);
  if (dlg->ofn.lpstrInitialDir) free(dlg->ofn.lpstrInitialDir);
  dlg->doneSema = 0;
  dlg->used = 0;
  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* fileDialogGetLocation: Return a known file location.
   Arguments:
     location: Symbolic name for a path.
   Return value: Path for the given location or NULL.
*/

char *
fileDialogGetLocation(char *location)
{
  int folder, sz;
  static WCHAR result[MAX_PATH+1];
  static char utf8Result[MAX_PATH+1]; 
  static char *iniFile = NULL;

  result[0] = 0;
  utf8Result[0] = 0;

  /* First check the ini file if we have an override in [FileLocations] */
  if (!iniFile) {
#ifdef SQUEAK_BUILTIN_PLUGIN
    extern char squeakIniNameA[];
    iniFile = squeakIniNameA;
#else
    static char modulePath[MAX_PATH];
    GetModuleFileNameA(NULL, modulePath, MAX_PATH);
    strcpy(modulePath + strlen(modulePath)-3, "ini");
    iniFile = modulePath;
#endif
  }

  sz = GetPrivateProfileStringA("FileLocations", location, "", 
			       utf8Result, MAX_PATH, (const char *)iniFile);
  if (sz > 0)
	return utf8Result;

  if (!strcmp("temp", location)) {
    GetTempPathW(MAX_PATH, result);
    WideCharToMultiByte(CP_UTF8, 0, result, -1, utf8Result, MAX_PATH, 0, 0);
    return utf8Result;
  }

#if _WIN32_WINNT < 0x0500 /* i.e. on old mingw */
  if (!SHGetFolderPathW)
	return NULL;
#endif

  folder = 0;
  if      (!strcmp("home", location))
	folder = CSIDL_PROFILE;
  else if (!strcmp("desktop", location))
	folder = CSIDL_DESKTOPDIRECTORY;
  else if (!strcmp("preferences", location))
	folder = CSIDL_APPDATA;
  else if (!strcmp("applications", location))
	folder = CSIDL_PROGRAM_FILES;
  else if (!strcmp("fonts", location))
	folder = CSIDL_FONTS;
  else if (!strcmp("documents", location))
	folder = CSIDL_PERSONAL;
  else if (!strcmp("music", location))
	folder = CSIDL_MYMUSIC;
  else if (!strcmp("pictures", location))
	folder = CSIDL_MYPICTURES;
  else if (!strcmp("videos", location))
	folder = CSIDL_MYVIDEO;
  else
	return NULL;

  if (SHGetFolderPathW(NULL, folder, NULL, 0, result) != S_OK)
	return NULL;

  WideCharToMultiByte(CP_UTF8,0,result,-1, utf8Result, MAX_PATH, 0, 0);
  return utf8Result;
}
