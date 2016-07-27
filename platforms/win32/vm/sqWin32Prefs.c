/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Prefs.c
*   CONTENT: Preferences management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*
*   NOTES:
*****************************************************************************/
#ifdef NO_PREFERENCES
void CreatePrefsMenu(void) {}
void TrackPrefsMenu(void) {}
void HandlePrefsMenu(int) {}
#else

#include <windows.h>
#include "sq.h"
#include "sqWin32Prefs.h"

/* from SecurityPlugin/sqWin32Security.c */
int ioHasFileAccess();
int ioHasSocketAccess();
int _ioSetFileAccess(int enable);
int _ioSetImageWrite(int enable);
int _ioSetSocketAccess(int enable);

/* from SocketPlugin/sqWin32NewNet.c */
int win32DebugPrintSocketState();

/* from sqWin32Window.c */
void SetTheDefaultPrinter();

/* from VM */
void printCallStack(void);
void printAllStacks(void);

/* VM preference variables */
extern TCHAR squeakIniName[]; /* full path and name to ini file */
HMENU vmPrefsMenu;         /* preferences menu */
extern int caseSensitiveFileMode;

/****************************************************************************/
/*                   Preference functions                                   */
/****************************************************************************/
#ifdef WCE_PREFERENCES
#define GetCursorPos(pt) *(pt) = mousePosition;
#define WritePrivateProfileString(a1,a2,a3,a4);
#endif

void SetDeferredUpdate() {
  CheckMenuItem(vmPrefsMenu, ID_DEFERUPDATES, MF_BYCOMMAND | 
		(fDeferredUpdate ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("DeferUpdate"),
			    fDeferredUpdate ? U_ON : U_OFF,squeakIniName);
}

void SetShowConsole() {
  CheckMenuItem(vmPrefsMenu, ID_SHOWCONSOLE, MF_BYCOMMAND | 
		(fShowConsole ? MF_CHECKED : MF_UNCHECKED));
  if(IsWindow(stWindow)) 
    ShowWindow(consoleWindow, fShowConsole ? SW_SHOW : SW_HIDE);
  WritePrivateProfileString(U_GLOBAL,TEXT("ShowConsole"),
			    fShowConsole ? U_ON:U_OFF,squeakIniName);
}

void SetDynamicConsole() {
  CheckMenuItem(vmPrefsMenu, ID_DYNAMICCONSOLE, MF_BYCOMMAND | 
		(fDynamicConsole ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("DynamicConsole"),
			    fDynamicConsole ? U_ON:U_OFF,squeakIniName);
}

void SetReduceCPUUsage() {
  CheckMenuItem(vmPrefsMenu, ID_REDUCECPUUSAGE, MF_BYCOMMAND | 
		(fReduceCPUUsage ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("ReduceCPUUsage"),
			    fReduceCPUUsage ? U_ON:U_OFF,squeakIniName);
}

void SetReduceCPUInBackground() {
  CheckMenuItem(vmPrefsMenu, ID_REDUCEBACKGROUNDCPU, MF_BYCOMMAND | 
		(fReduceCPUInBackground ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("ReduceCPUInBackground"),
			    fReduceCPUInBackground ? U_ON:U_OFF,squeakIniName);
}

void Set3ButtonMouse() {
  CheckMenuItem(vmPrefsMenu, ID_3BUTTONMOUSE, MF_BYCOMMAND | 
		(f3ButtonMouse ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("3ButtonMouse"),
			    f3ButtonMouse ? U_ON : U_OFF,squeakIniName);
}

void Set1ButtonMouse() {
  CheckMenuItem(vmPrefsMenu, ID_1BUTTONMOUSE, MF_BYCOMMAND | 
		(f1ButtonMouse ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("1ButtonMouse"),
			    f1ButtonMouse ? U_ON : U_OFF,squeakIniName);
}

void SetUseDirectSound() {
  CheckMenuItem(vmPrefsMenu, ID_DIRECTSOUND, MF_BYCOMMAND | 
		(fUseDirectSound ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("UseDirectSound"),
			    fUseDirectSound ? U_ON : U_OFF,squeakIniName);
}

void SetAllowFileAccess() {
  CheckMenuItem(vmPrefsMenu, ID_FILEACCESS, MF_BYCOMMAND | 
		(ioHasFileAccess() ? MF_CHECKED : MF_UNCHECKED));
}

void SetAllowImageWrite() {
  CheckMenuItem(vmPrefsMenu, ID_IMAGEWRITE, MF_BYCOMMAND | 
		(ioCanWriteImage() ? MF_CHECKED : MF_UNCHECKED));
}
#ifndef NO_NETWORK
void SetAllowSocketAccess() {
  CheckMenuItem(vmPrefsMenu, ID_SOCKETACCESS, MF_BYCOMMAND | 
		(ioHasSocketAccess() ? MF_CHECKED : MF_UNCHECKED));
}
#endif

void SetShowAllocations() {
  CheckMenuItem(vmPrefsMenu, ID_SHOWALLOCATIONS, MF_BYCOMMAND | 
		(fShowAllocations ? MF_CHECKED : MF_UNCHECKED));
}

void SetPriorityBoost() {
  CheckMenuItem(vmPrefsMenu, ID_PRIORITYBOOST, MF_BYCOMMAND | 
		(fPriorityBoost ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("PriorityBoost"),
			    fPriorityBoost ? U_ON : U_OFF,squeakIniName);
}

void SetB3DXUsesOpenGL() {
  CheckMenuItem(vmPrefsMenu, ID_USEOPENGL, MF_BYCOMMAND | 
		(fUseOpenGL ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("B3DXUsesOpenGL"),
			    fUseOpenGL ? U_ON : U_OFF,squeakIniName);
}

void SetCaseSensitiveFileMode() {
  CheckMenuItem(vmPrefsMenu, ID_CASEFILES, MF_BYCOMMAND | 
		(caseSensitiveFileMode ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("CaseSensitiveFileMode"),
			    caseSensitiveFileMode ? U_ON : U_OFF,squeakIniName);
}

int prefsEnableAltF4Quit(void) {
  fEnableAltF4Quit   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("EnableAltF4Quit"),
			 fEnableAltF4Quit,squeakIniName);
  return fEnableAltF4Quit;
}

int prefsEnableF2Menu(void) {
  fEnableF2Menu   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("EnableF2Menu"),
			 fEnableF2Menu,squeakIniName);
  return fEnableF2Menu;
}



#if 0 /* I don't think we need those in the menu */
void SetEnableF2Menu() {
  CheckMenuItem(vmPrefsMenu, ID_ENABLEF2MENU, MF_BYCOMMAND | 
		(fEnableF2Menu ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("EnableF2Menu"),
			    fEnableF2Menu ? U_ON : U_OFF,squeakIniName);
}

void SetEnableAltF4Quit() {
  CheckMenuItem(vmPrefsMenu, ID_ENABLEALTF4QUIT, MF_BYCOMMAND | 
		(fEnableAltF4Quit ? MF_CHECKED : MF_UNCHECKED));
  WritePrivateProfileString(U_GLOBAL,TEXT("EnableAltF4Quit"),
			    enableAltF4Quit ? U_ON : U_OFF,squeakIniName);
}
#endif

void LoadPreferences()
{
  /* Set preferences */
#ifndef WCE_PREFERENCES
  int size;

  /* make ini file name based on executable file name */
  lstrcpy(squeakIniName, vmName);
  size = lstrlen(squeakIniName);
  lstrcpy(squeakIniName + (size-3), TEXT("ini"));

  /* get image file name from ini file */
  size = GetPrivateProfileString(U_GLOBAL, TEXT("ImageFile"), 
			 TEXT(""), imageName, MAX_PATH, squeakIniName);
  if(size > 0) {
    if( !(imageName[0] == '\\' && imageName[1] == '\\') && !(imageName[1] == ':' && imageName[2] == '\\')) {
      /* make the path relative to VM directory */
      lstrcpy(imageName, vmName);
      (lstrrchr(imageName,U_BACKSLASH[0]))[1] = 0;
      size = lstrlen(imageName);
      size = GetPrivateProfileString(U_GLOBAL, TEXT("ImageFile"), 
			 TEXT(""), imageName + size, MAX_PATH - size, squeakIniName);
	}
  }

  /* get window title from ini file */
  GetPrivateProfileString(U_GLOBAL, TEXT("WindowTitle"), 
			 TEXT(""), windowTitle, MAX_PATH, squeakIniName);

  /* get the window class name from the ini file */
  GetPrivateProfileString(U_GLOBAL, TEXT("WindowClassName"), 
#if NewspeakVM
				TEXT(VM_NAME"WindowClass"),
#else
				TEXT("SqueakWindowClass"),
#endif
				windowClassName, 
				MAX_PATH, squeakIniName);
  fRunSingleApp =
    GetPrivateProfileInt(U_GLOBAL, TEXT("RunSingleApp"),
			 fRunSingleApp, squeakIniName);
  fDeferredUpdate = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("DeferUpdate"), 
			 fDeferredUpdate,squeakIniName);
  fShowConsole = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("ShowConsole"),
			 fShowConsole,squeakIniName);
  fDynamicConsole = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("DynamicConsole"),
			 fDynamicConsole,squeakIniName);
  fReduceCPUUsage = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("ReduceCPUUsage"),
			 fReduceCPUUsage,squeakIniName);
  fReduceCPUInBackground = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("ReduceCPUInBackground"),
			 fReduceCPUInBackground,squeakIniName);
  f1ButtonMouse   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("1ButtonMouse"),
			 f1ButtonMouse,squeakIniName);
  f3ButtonMouse   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("3ButtonMouse"),
			 f3ButtonMouse,squeakIniName);

  fPriorityBoost   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("PriorityBoost"),
			 fPriorityBoost,squeakIniName);

  fUseDirectSound   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("UseDirectSound"),
			 fUseDirectSound,squeakIniName);
  fUseOpenGL   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("B3DXUsesOpenGL"),
			 fUseOpenGL,squeakIniName);
  caseSensitiveFileMode   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("CaseSensitiveFileMode"),
			 caseSensitiveFileMode,squeakIniName);
  fEnableAltF4Quit   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("EnableAltF4Quit"),
			 fEnableAltF4Quit,squeakIniName);

  fEnableF2Menu   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("EnableF2Menu"),
			 fEnableF2Menu,squeakIniName);

  fEnablePrefsMenu   = 
    GetPrivateProfileInt(U_GLOBAL,TEXT("EnablePrefsMenu"),
			 fEnablePrefsMenu,squeakIniName);
# if STACKVM
  { sqInt nStackPagesPref;
    nStackPagesPref = GetPrivateProfileInt(U_GLOBAL,TEXT("SqueakNumStackPages"),0,squeakIniName);
    if (nStackPagesPref) {
		extern sqInt desiredNumStackPages;
		desiredNumStackPages = nStackPagesPref;
	}
  }
  { sqInt nEdenBytesPref;
    nEdenBytesPref = GetPrivateProfileInt(U_GLOBAL,TEXT("SqueakEdenBytes"),0,squeakIniName);
    if (nEdenBytesPref) {
		extern sqInt desiredEdenBytes;
		desiredEdenBytes = nEdenBytesPref;
	}
  }
# endif
#endif
}

void SetAllPreferences() {
  /* now make the necessary settings */
  SetDeferredUpdate();
  SetShowConsole();
  SetDynamicConsole();
  SetReduceCPUUsage();
  SetReduceCPUInBackground();
  Set3ButtonMouse();
  Set1ButtonMouse();
  SetUseDirectSound();
  SetAllowFileAccess();
  SetAllowImageWrite();
#ifndef NO_NETWORK
  SetAllowSocketAccess();
#endif
  SetShowAllocations();
  SetPriorityBoost();
  SetB3DXUsesOpenGL();
  SetCaseSensitiveFileMode();
}

void CreatePrefsMenu(void) {
#if COGVM
extern sqInt recordPrimTraceFunc();
#endif
  HMENU hMenu,pMenu;

  vmPrefsMenu = pMenu = CreatePopupMenu();
  if(!fEnablePrefsMenu) return;

  AppendMenu(pMenu,MF_STRING | MF_DISABLED, 0,
	     TEXT("[VM Preferences]"));
  AppendMenu(pMenu,MF_SEPARATOR, 0,NULL);
  { /* Create mouse button menu */
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED , ID_1BUTTONMOUSE, 
	       TEXT("1 button mouse"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED , ID_3BUTTONMOUSE, 
	       TEXT("3 button mouse"));
    AppendMenu(pMenu, MF_STRING | MF_POPUP, (sqIntptr_t)hMenu,
	       TEXT("Mouse Mapping"));
  }
  { /* Create security menu */
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_FILEACCESS, 
	       TEXT("Allow file access"));
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_IMAGEWRITE, 
	       TEXT("Allow image writes"));    
#ifndef NO_NETWORK
	AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_SOCKETACCESS, 
	       TEXT("Allow socket access"));
#endif
    AppendMenu(pMenu, MF_STRING | MF_POPUP, (sqIntptr_t)hMenu,
	       TEXT("Security Settings"));
  }
  { /* Create media related menu */
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_DIRECTSOUND, 
	       TEXT("Use DirectSound"));
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_USEOPENGL,
	       TEXT("Use OpenGL (instead of D3D)"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_DEFERUPDATES, 
	       TEXT("Defer display update"));
    AppendMenu(pMenu, MF_STRING | MF_POPUP, (sqIntptr_t)hMenu,
	       TEXT("Display and Sound"));
  }

  { /* System related settings */
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_REDUCECPUUSAGE, 
	       TEXT("Reduce CPU usage"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_REDUCEBACKGROUNDCPU, 
	       TEXT("Reduce background CPU usage"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_PRIORITYBOOST, 
	       TEXT("Thread Priority Boost"));
#ifndef NO_PRINTER
    AppendMenu(hMenu,MF_SEPARATOR, 0,NULL);
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED , ID_DEFAULTPRINTER, 
	       TEXT("Printer configuration ..."));
#endif /* NO_PRINTER */
    AppendMenu(pMenu, MF_STRING | MF_POPUP, (sqIntptr_t)hMenu,
	       TEXT("System Configuration"));
  }

  { /* Create debug menu */
    hMenu = CreatePopupMenu();
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED , ID_CASEFILES, 
	       TEXT("Case sensitive files"));
    AppendMenu(hMenu,MF_SEPARATOR, 0,NULL);
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED , ID_SHOWCONSOLE, 
	       TEXT("Show output console"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_DYNAMICCONSOLE, 
	       TEXT("Show console on errors"));
    AppendMenu(hMenu,MF_STRING | MF_UNCHECKED, ID_SHOWALLOCATIONS, 
	       TEXT("Show allocation activity"));
    AppendMenu(hMenu,MF_SEPARATOR, 0,NULL);
#ifndef NO_NETWORK
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_DBGPRINTSOCKET,
	       TEXT("Dump network state"));
#endif
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_DBGPRINTSTACK,
	       TEXT("Dump call stack"));
    AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_PRINTALLSTACKS,
	       TEXT("Dump all processes"));
#if COGVM
    if (recordPrimTraceFunc())
      AppendMenu(hMenu, MF_STRING | MF_UNCHECKED, ID_DUMPPRIMLOG,
	       TEXT("Dump recent primitives"));
#endif
    AppendMenu(pMenu, MF_STRING | MF_POPUP, (sqIntptr_t)hMenu,
	       TEXT("Debug Options"));
  }

  AppendMenu(pMenu,MF_SEPARATOR, 0,NULL);
  AppendMenu(pMenu,MF_STRING | MF_UNCHECKED , ID_ABOUT, 
	     TEXT("Display version information"));
  hMenu = GetSystemMenu(stWindow,false);
  AppendMenu(hMenu,MF_SEPARATOR, 0,NULL);
  AppendMenu(hMenu, MF_POPUP, (sqIntptr_t) pMenu, TEXT("&VM Preferences"));
  SetAllPreferences();
}

void TrackPrefsMenu(void) {
  POINT p;
  GetCursorPos(&p);
  SetAllPreferences(); /* in case any have changed */
  TrackPopupMenu(vmPrefsMenu, TPM_LEFTALIGN, p.x, p.y, 0, stWindow, NULL);
}

void HandlePrefsMenu(int cmd) {
  switch(cmd) {
  case ID_ABOUT: 
    MessageBox(stWindow,VM_VERSION_TEXT,
	       TEXT("About ") TEXT(VM_NAME) TEXT(" on Win32"), MB_OK);
    break;
  case ID_DEFERUPDATES:
    fDeferredUpdate = !fDeferredUpdate;
    SetDeferredUpdate();
    break;
  case ID_SHOWCONSOLE:
    fShowConsole = !fShowConsole;
    SetShowConsole();
    break;
  case ID_DYNAMICCONSOLE:
    fDynamicConsole = !fDynamicConsole;
    SetDynamicConsole();
    break;
  case ID_REDUCECPUUSAGE:
    fReduceCPUUsage = !fReduceCPUUsage;
    SetReduceCPUUsage();
    break;
  case ID_3BUTTONMOUSE:
    f3ButtonMouse = !f3ButtonMouse;
    Set3ButtonMouse();
    break;
  case ID_DEFAULTPRINTER:
    SetTheDefaultPrinter();
    break;
  case ID_REDUCEBACKGROUNDCPU:
    fReduceCPUInBackground = !fReduceCPUInBackground;
    SetReduceCPUInBackground();
    break;
  case ID_1BUTTONMOUSE:
    f1ButtonMouse = !f1ButtonMouse;
    Set1ButtonMouse();
    break;
  case ID_DIRECTSOUND:
    fUseDirectSound = !fUseDirectSound;
    SetUseDirectSound();
    break;
  case ID_FILEACCESS:
    _ioSetFileAccess(!ioHasFileAccess());
    SetAllowFileAccess();
    break;
  case ID_IMAGEWRITE:
    _ioSetImageWrite(!ioCanWriteImage());
    SetAllowImageWrite();
    break;
  case ID_SHOWALLOCATIONS:
    fShowAllocations = !fShowAllocations;
    SetShowAllocations();
    break;
#ifndef NO_NETWORK
  case ID_SOCKETACCESS:
    _ioSetSocketAccess(!ioHasSocketAccess());
    SetAllowSocketAccess();
    break;
  case ID_DBGPRINTSOCKET:
    win32DebugPrintSocketState();
   break;
#endif
  case ID_DBGPRINTSTACK:
    printCallStack();
    break;
  case ID_PRINTALLSTACKS:
    printf("Printing all processes:\n");
    printAllStacks();
    break;
#if STACKVM
  case ID_DUMPPRIMLOG: { extern void dumpPrimTraceLog(void);
    printf("Printing recent primitives:\n");
    dumpPrimTraceLog();
    break;
  }
#endif
  case ID_PRIORITYBOOST:
    fPriorityBoost = !fPriorityBoost;
    SetPriorityBoost();
    break;
  case ID_USEOPENGL:
    fUseOpenGL = !fUseOpenGL;
    SetB3DXUsesOpenGL();
    break;
  case ID_CASEFILES:
    printf("case files %d\n", caseSensitiveFileMode);
    caseSensitiveFileMode = !caseSensitiveFileMode;
    SetCaseSensitiveFileMode();
    printf("case files %d\n", caseSensitiveFileMode);
    break;
  }
}

#endif /* NO_PREFERENCES */
