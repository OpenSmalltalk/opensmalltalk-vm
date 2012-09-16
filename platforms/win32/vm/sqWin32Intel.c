/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Intel.c
*   CONTENT: Special support stuff only for Win95/WinNT on x86
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id$
*
*   NOTES:
*    1) When using this module the virtual machine MUST NOT be compiled
*       with Unicode support.
*****************************************************************************/
/* Windows Vista support 
 * AUTHOR: Korakurider (kr)
 * CHANGE NOTES:
 *   1) new command line option "-lowRights" was introduced
 *      to support IE7/protected mode.
 */
#define VISTA_SECURITY 1 /* IE7/Vista protected mode support */

#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h> /* _O_BINARY */
#include <mingw-include/float.h>	/* prevent the one in lib/gcc/XYZ/include from interfering */
#include <ole2.h>
#include "sq.h"
#include "sqWin32Args.h"

/*** Crash debug -- Imported from Virtual Machine ***/
int getFullScreenFlag(void);
int methodPrimitiveIndex(void);
int getCurrentBytecode(void);
int printCallStack(void);

extern TCHAR squeakIniName[];

/* Import from sqWin32Alloc.c */
LONG CALLBACK sqExceptionFilter(LPEXCEPTION_POINTERS exp);

/* forwarded declaration */
void printCrashDebugInformation(LPEXCEPTION_POINTERS exp);

/*** Variables -- command line */
char *initialCmdLine;
int  numOptionsVM = 0;
char *(vmOptions[MAX_OPTIONS]);
int  numOptionsImage = 0;
char *(imageOptions[MAX_OPTIONS]);

/* console buffer */
TCHAR consoleBuffer[4096];

/* stderr and stdout names */
char stderrName[MAX_PATH+1];
char stdoutName[MAX_PATH+1];

TCHAR *logName = TEXT("");             /* full path and name to log file */

#ifdef VISTA_SECURITY 
BOOL fLowRights = 0;  /* started as low integiry process, 
			need to use alternate untrustedUserDirectory */
#endif /* VISTA_SECURITY */

/* Service stuff */
TCHAR  serviceName[MAX_PATH+1];   /* The name of the NT service */
TCHAR *installServiceName = NULL; /* the name under which the service is to install */
BOOL  fBroadcastService95 = 0;   /* Do we need a broadcast when a user has logged on? */
UINT  WM_BROADCAST_SERVICE = 0;  /* The broadcast message we send */
TCHAR *msgBroadcastService = TEXT("SQUEAK_SERVICE_BROADCAST_MESSAGE"); /* The name of the broadcast message */

UINT  SQ_LAUNCH_DROP = 0;  /* Message sent when second instance launches */

/* Embedded images */
static sqImageFile imageFile = 0;
static int imageSize = 0;

void SetSystemTrayIcon(BOOL on);

/* default fpu control word:
   _RC_NEAR: round to nearest
   _PC_53 :  double precision arithmetic (instead of extended)
   _EM_XXX: silent operations (no signals please)
*/
#define FPU_DEFAULT (_RC_NEAR + _PC_53 + _EM_INVALID + _EM_ZERODIVIDE + _EM_OVERFLOW + _EM_UNDERFLOW + _EM_INEXACT + _EM_DENORMAL)

/****************************************************************************/
/*                     Exception handling                                   */
/****************************************************************************/
/* The following installs us a global exception filter for *all* exceptions */
/* in Squeak. This is necessary since the C support of Mingw32 for SEH is   */
/* not as sophisticated as MSVC's support. However, with this new handling  */
/* scheme the entire thing becomes actually a lot simpler...                */
/****************************************************************************/
static LPTOP_LEVEL_EXCEPTION_FILTER TopLevelFilter = NULL;

LONG CALLBACK squeakExceptionHandler(LPEXCEPTION_POINTERS exp)
{
  DWORD result;

  /* #1: Try to handle exception in the regular (memory access)
     exception filter if virtual memory support is enabled */
#ifndef NO_VIRTUAL_MEMORY
  result = sqExceptionFilter(exp);
#else
  result = EXCEPTION_CONTINUE_SEARCH;
#endif

  /* #2: If that didn't work, try to handle any FP problems */
  if(result != EXCEPTION_CONTINUE_EXECUTION) {
    DWORD code = exp->ExceptionRecord->ExceptionCode;
    if((code >= EXCEPTION_FLT_DENORMAL_OPERAND) && (code <= EXCEPTION_FLT_UNDERFLOW)) {
      /* turn on the default masking of exceptions in the FPU and proceed */
      _control87(FPU_DEFAULT, _MCW_EM | _MCW_RC | _MCW_PC | _MCW_IC);
      result = EXCEPTION_CONTINUE_EXECUTION;
    }
  }

  /* #3: If that didn't work either try passing it on to the old
     top-level filter */
  if(result != EXCEPTION_CONTINUE_EXECUTION) {
    if(TopLevelFilter) {
      result = TopLevelFilter(exp);
    }
  }
#ifdef NDEBUG
  /* #4: If that didn't work either give up and print a crash debug information */
  if(result != EXCEPTION_CONTINUE_EXECUTION) {
    printCrashDebugInformation(exp);
    result = EXCEPTION_EXECUTE_HANDLER;
  }
#endif
  return result;
}

void InstallExceptionHandler(void)
{
  TopLevelFilter = SetUnhandledExceptionFilter(squeakExceptionHandler);
}

void UninstallExceptionHandler(void)
{
  SetUnhandledExceptionFilter(TopLevelFilter);
  TopLevelFilter = NULL;
}

/****************************************************************************/
/*                      Console Window functions                            */
/****************************************************************************/
int OutputLogMessage(char *string)
{ FILE *fp;

  if(!*logName) return 1;
  fp = fopen(logName, "at");
  if(!fp) return 1;
  fprintf(fp, "%s", string);
  fflush(fp);
  fclose(fp);
  return 1;
}

int OutputConsoleString(char *string)
{ 
  int pos;

  if(fDynamicConsole && !fShowConsole) {
    /* show console window */
    ShowWindow(consoleWindow, SW_SHOW);
    fShowConsole = TRUE;
#ifndef NO_PREFERENCES
    CheckMenuItem(vmPrefsMenu, 0x0030, MF_BYCOMMAND | MF_CHECKED);
#endif
    OutputConsoleString(
      "# Debug console\n"
      "# To close: F2 -> 'debug options' -> 'show output console'\n"
      "# To disable: F2 -> 'debug options' -> 'show console on errors'\n"
      );
  }
  pos = SendMessage(consoleWindow,WM_GETTEXTLENGTH, 0,0);
  SendMessage(consoleWindow, EM_SETSEL, pos, pos);
  while(*string)
    {
      SendMessage( consoleWindow, WM_CHAR, *string, 1);
      string++;
    }
  return 1;
}

int __cdecl printf(const char *fmt, ...)
{ va_list al;

  va_start(al, fmt);
  wvsprintf(consoleBuffer, fmt, al);
  OutputLogMessage(consoleBuffer);
  if(IsWindow(stWindow)) /* not running as service? */
    OutputConsoleString(consoleBuffer);
  vfprintf(stdout, fmt, al);
  va_end(al);
  return 1;
}

int __cdecl fprintf(FILE *fp, const char *fmt, ...)
{ va_list al;

  va_start(al, fmt);
  if(fp == stdout || fp == stderr)
    {
      wvsprintf(consoleBuffer, fmt, al);
      OutputLogMessage(consoleBuffer);
      if(IsWindow(stWindow)) /* not running as service? */
        OutputConsoleString(consoleBuffer);
    }
  vfprintf(fp, fmt, al);
  va_end(al);
  return 1;
}


int __cdecl putchar(int c)
{
  return printf("%c",c);
}

/****************************************************************************/
/*                   Message Processing                                     */
/****************************************************************************/

static messageHook nextMessageHook = NULL;

int ServiceMessageHook(void * hwnd, unsigned int message, unsigned int wParam, long lParam)
{
  if(fRunService && fWindows95 && message == WM_BROADCAST_SERVICE && hwnd == stWindow)
    {
      /* broadcast notification - install the running Win95 service in the system tray */
      SetSystemTrayIcon(1);
      return 1;
    }
   if(message == WM_USERCHANGED)
      {
        SetSystemTrayIcon(1);
        return 1;
      }
  if(nextMessageHook)
    return(*nextMessageHook)(hwnd, message,wParam, lParam);
  else
    return 0;
}


/****************************************************************************/
/*                     Window Setup                                         */
/****************************************************************************/
/* SetSystemTrayIcon(): Set the icon in the system tray */
void SetSystemTrayIcon(BOOL on)
{
  BOOL (WINAPI *ShellNotifyIcon)(DWORD,NOTIFYICONDATA*);
  static HMODULE hShell = NULL;
  NOTIFYICONDATA nid;

  /* NOTE: There is explicitly no unload of the shell32.dll in here.
           Win95 has _serious_ problems with the module counter and
           may just unload the shell32.dll even if it is referenced
           by other processes */
  if(!hShell) hShell = LoadLibrary(TEXT("shell32.dll"));
  if(!hShell) return; /* should not happen */
  /* On WinNT 3.* the following will just return NULL */
  ShellNotifyIcon = GetProcAddress(hShell, "Shell_NotifyIconA");
  if(!ShellNotifyIcon) return;  /* ok, we don't have it */
  nid.cbSize = sizeof(nid);
  nid.hWnd   = stWindow;
  nid.uID    = (UINT)hInstance;
  nid.uFlags = NIF_MESSAGE | NIF_TIP | NIF_ICON;
  nid.uCallbackMessage = WM_USER+42;
  nid.hIcon  = LoadIcon(hInstance, MAKEINTRESOURCE(1));
  strcpy(nid.szTip, VM_NAME "!");
  if(on)
    (*ShellNotifyIcon)(NIM_ADD, &nid);
  else
    (*ShellNotifyIcon)(NIM_DELETE, &nid);
}

void SetupService95()
{
#ifndef NO_SERVICE
#ifndef RSP_SIMPLE_SERVICE
#define RSP_SIMPLE_SERVICE 1
#endif
  BOOL (WINAPI *RegisterServiceProcess)(DWORD,DWORD);
  static HMODULE hKernel32 = NULL;

  /* Inform Windows95 that we're running as a service process */
  if(!fRunService || !fWindows95) return;
  hKernel32 = LoadLibrary(TEXT("kernel32.dll"));
  if(!hKernel32)
    {
      printLastError(TEXT("Unable to load kernel32.dll"));
      return;
    }
  (FARPROC) RegisterServiceProcess = GetProcAddress(hKernel32, "RegisterServiceProcess");
  if(!RegisterServiceProcess)
    {
      printLastError(TEXT("Unable to find RegisterServiceProcess"));
      return;
    }
  if( !(*RegisterServiceProcess)(GetCurrentProcessId(), RSP_SIMPLE_SERVICE ) )
    printLastError(TEXT("RegisterServiceProcess failed"));
#endif /* NO_SERVICE */
}

/****************************************************************************/
/*                      System Attributes                                   */
/****************************************************************************/

char *GetVMOption(int id)
{
  if(id < numOptionsVM)
    return vmOptions[id];
  else
    return NULL;
}

char *GetImageOption(int id)
{
  if(id < numOptionsImage)
    return imageOptions[id];
  else
    return NULL;
}

#if 0

typedef struct _OSVERSIONINFOEX {
  DWORD dwOSVersionInfoSize;
  DWORD dwMajorVersion;
  DWORD dwMinorVersion;
  DWORD dwBuildNumber;
  DWORD dwPlatformId;
  TCHAR szCSDVersion[128];
  WORD wServicePackMajor;
  WORD wServicePackMinor;
  WORD wSuiteMask;
  BYTE wProductType;
  BYTE wReserved;
} OSVERSIONINFOEX;

typedef struct _DISPLAY_DEVICE {
  DWORD cb;
  TCHAR DeviceName[32];
  TCHAR DeviceString[128];
  DWORD StateFlags;
  TCHAR DeviceID[128];
  TCHAR DeviceKey[128];
} DISPLAY_DEVICE, *PDISPLAY_DEVICE;

#endif

typedef BOOL (CALLBACK *pfnEnumDisplayDevices)(
  LPCTSTR lpDevice,                // device name
  DWORD iDevNum,                   // display device
  PDISPLAY_DEVICE lpDisplayDevice, // device information
  DWORD dwFlags                    // reserved
);
char *osInfoString = "";
char *hwInfoString = "";
char *gdInfoString = "";

void gatherSystemInfo(void) {
  OSVERSIONINFOEX osInfo;
  MEMORYSTATUS memStat;
  SYSTEM_INFO sysInfo;
  DISPLAY_DEVICE gDev;
  int proc, screenX, screenY;
  char tmpString[2048];

  char keyName[256];
  DWORD ok, dwSize;
  HKEY hk;

  /* Retrieve version info for crash logs */
  ZeroMemory(&osInfo, sizeof(osInfo));
  osInfo.dwOSVersionInfoSize = sizeof(osInfo);
  GetVersionEx((OSVERSIONINFO*)&osInfo);
  GetSystemInfo(&sysInfo);

  ZeroMemory(&memStat, sizeof(memStat));
  memStat.dwLength = sizeof(memStat);
  GlobalMemoryStatus(&memStat);

  screenX = GetSystemMetrics(SM_CXSCREEN);
  screenY = GetSystemMetrics(SM_CYSCREEN);


  {
    HANDLE hUser = LoadLibrary( "user32.dll" );
    pfnEnumDisplayDevices pEnumDisplayDevices = (pfnEnumDisplayDevices)
      GetProcAddress(hUser, "EnumDisplayDevicesA");
    ZeroMemory(&gDev, sizeof(gDev));
    gDev.cb = sizeof(gDev);
    if(pEnumDisplayDevices) pEnumDisplayDevices(NULL, 0, &gDev, 0);
  }

  { /* Figure out make and model from OEMINFO.ini */
    char iniName[256];
    char manufacturer[256];
    char model[256];

    GetSystemDirectory(iniName, 256);
    strcat(iniName,"\\OEMINFO.INI");

    GetPrivateProfileString("General", "Manufacturer", "Unknown", 
			    manufacturer, 256, iniName);

    GetPrivateProfileString("General", "Model", "Unknown", 
			    model, 256, iniName);

    sprintf(tmpString, 
	    "Hardware information: \n"
	    "\tManufacturer: %s\n"
	    "\tModel: %s\n"
	    "\tNumber of processors: %d\n"
	    "\tPage size: %d\n"
	    "\nMemory Information (upon launch):\n"
	    "\tPhysical Memory Size: %d kbytes\n"
	    "\tPhysical Memory Free: %d kbytes\n"
	    "\tPage File Size: %d kbytes\n"
	    "\tPage File Free: %d kbytes\n"
	    "\tVirtual Memory Size: %d kbytes\n"
	    "\tVirtual Memory Free: %d kbytes\n"
	    "\tMemory Load: %d percent\n",
	    manufacturer, model,
	    sysInfo.dwNumberOfProcessors,
	    sysInfo.dwPageSize,
	    memStat.dwTotalPhys / 1024,
	    memStat.dwAvailPhys / 1024,
	    memStat.dwTotalPageFile / 1024,
	    memStat.dwAvailPageFile / 1024,
	    memStat.dwTotalVirtual / 1024,
	    memStat.dwAvailVirtual / 1024,
	    memStat.dwMemoryLoad,
	    0);
  }

  /* find more information about each processor */
  for(proc=0; proc < sysInfo.dwNumberOfProcessors; proc++) {

    char *tmp = tmpString + strlen(tmpString);

    strcpy(keyName, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0");
    keyName[strlen(keyName)-1] = 48+proc; /* 0, 1, 2 etc. */

    ok = RegOpenKey(HKEY_LOCAL_MACHINE, keyName, &hk);
    if(ok == 0) {
      char nameString[256];
      char identifier[256];
      DWORD mhz;

      dwSize = 256;
      ok = RegQueryValueEx(hk, "ProcessorNameString", NULL, NULL, 
			   (LPBYTE)nameString, &dwSize);
      if(ok != 0) strcpy(nameString, "???");

      dwSize = 256;
      ok = RegQueryValueEx(hk, "Identifier", NULL, NULL, 
			   (LPBYTE)identifier, &dwSize);
      if(ok != 0) strcpy(identifier, "???");

      dwSize = sizeof(DWORD);
      ok = RegQueryValueEx(hk, "~MHz", NULL, NULL, 
			   (LPBYTE)&mhz, &dwSize);
      if(ok != 0) mhz = -1;
      sprintf(tmp,
	      "\nProcessor %d: %s\n"
	      "\tIdentifier: %s\n"
	      "\t~MHZ: %d\n",
	      proc, nameString, identifier, mhz);
      RegCloseKey(hk);
    }
  }

  hwInfoString = strdup(tmpString);

  {
    char owner[256];
    char company[256];
    char product[256];
    char productid[256];

    if(osInfo.dwPlatformId == VER_PLATFORM_WIN32_NT) {
      strcpy(keyName, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion");
    } else {
      strcpy(keyName, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion");
    }
    ok = RegOpenKey(HKEY_LOCAL_MACHINE, keyName, &hk);
    if(ok == 0) {
      dwSize = 256;
      if(RegQueryValueEx(hk, "RegisteredOwner", NULL, NULL, 
			  (LPBYTE)owner, &dwSize)) strcpy(owner, "???");
      dwSize = 256;
      if(RegQueryValueEx(hk, "RegisteredOrganization", NULL, NULL, 
			  (LPBYTE)company, &dwSize)) strcpy(company, "???");
      dwSize = 256;
      if(RegQueryValueEx(hk, "ProductName", NULL, NULL, 
			  (LPBYTE)product, &dwSize)) strcpy(product, "???");
      RegCloseKey(hk);
    }

    sprintf(tmpString,
	    "Operating System: %s (Build %d %s)\n"
	    "\tRegistered Owner: %s\n"
	    "\tRegistered Company: %s\n"
	    "\tSP major version: %d\n"
	    "\tSP minor version: %d\n"
	    "\tSuite mask: %lx\n"
	    "\tProduct type: %lx\n",
	    product, 
	    osInfo.dwBuildNumber, osInfo.szCSDVersion,
	    owner, company,
	    osInfo.wServicePackMajor, osInfo.wServicePackMinor,
	    osInfo.wSuiteMask, osInfo.wProductType);
    osInfoString = strdup(tmpString);
  }

  sprintf(tmpString,
	  "Display Information: \n"
	  "\tGraphics adapter name: %s\n"
	  "\tPrimary monitor resolution: %d x %d\n",
	  gDev.DeviceString,
	  screenX, screenY);

  /* Find the driver key in the registry */
  keyName[0] = 0;
  ok = RegOpenKey(HKEY_LOCAL_MACHINE, 
		  "HARDWARE\\DEVICEMAP\\VIDEO", 
		  &hk);
  if(ok == 0) {
    dwSize = 256;
    RegQueryValueEx(hk,"\\Device\\Video0", NULL, NULL, 
		    (LPBYTE)keyName, &dwSize);
    RegCloseKey(hk);
  }
  if(*keyName) {
    /* Got the key name; open it and get the info out of there */
    char *tmp = tmpString + strlen(tmpString);
    char deviceDesc[256];
    char adapterString[256];
    char biosString[256];
    char chipType[256];
    char dacType[256];
    char version[256];
    char *drivers, *drv;
    WCHAR buffer[256];
    DWORD memSize;

    /* Argh. It seems that the registry key regularly starts
       with \Registry\Machine\ which doesn't work with RegOpenKey below.
       I have no idea why but for now I'll just truncate that part if
       we recognize it... */
    if(strnicmp(keyName, "\\registry\\machine\\", 18) == 0) {
      memcpy(keyName, keyName+18, strlen(keyName)-17);
    }

    ok = RegOpenKey(HKEY_LOCAL_MACHINE, keyName, &hk);
    if(ok != 0) MessageBox(0, keyName, "Cannot open:", MB_OK);
    if(ok == 0) {
      dwSize = 256;
      ok = RegQueryValueEx(hk,"Device Description", NULL, NULL, 
		      (LPBYTE)deviceDesc, &dwSize);
      if(ok != 0) strcpy(deviceDesc, "???");

      dwSize = 256*sizeof(WCHAR);
      ok = RegQueryValueEx(hk,"HardwareInformation.AdapterString", NULL, NULL, 
		      (LPBYTE)buffer, &dwSize);
      if(ok == 0) {
	WideCharToMultiByte(CP_UTF8,0,buffer,-1,adapterString,256,NULL,NULL);
      } else strcpy(adapterString, "???");

      dwSize = 256*sizeof(WCHAR);
      ok = RegQueryValueEx(hk,"HardwareInformation.BiosString", NULL, NULL, 
		      (LPBYTE)buffer, &dwSize);
      if(ok == 0) {
	WideCharToMultiByte(CP_UTF8,0,buffer,-1,biosString,256,NULL,NULL);
      } else strcpy(biosString, "???");

      dwSize = 256*sizeof(WCHAR);
      ok = RegQueryValueEx(hk,"HardwareInformation.ChipType", NULL, NULL, 
		      (LPBYTE)buffer, &dwSize);
      if(ok == 0) {
	WideCharToMultiByte(CP_UTF8,0,buffer,-1,chipType,256,NULL,NULL);
      } else strcpy(chipType, "???");

      dwSize = 256*sizeof(WCHAR);
      ok = RegQueryValueEx(hk,"HardwareInformation.DacType", NULL, NULL, 
		      (LPBYTE)buffer, &dwSize);
      if(ok == 0) {
	WideCharToMultiByte(CP_UTF8,0,buffer,-1,dacType,256,NULL,NULL);
      } else strcpy(dacType, "???");

      dwSize = sizeof(DWORD);
      ok = RegQueryValueEx(hk,"HardwareInformation.MemorySize", NULL, NULL, 
		      (LPBYTE)&memSize, &dwSize);
      if(ok != 0) memSize = -1;

      sprintf(tmp,
	      "\nDevice: %s\n"
	      "\tAdapter String: %s\n"
	      "\tBios String: %s\n"
	      "\tChip Type: %s\n"
	      "\tDAC Type: %s\n"
	      "\tMemory Size: 0x%.8X\n",
	      deviceDesc,
	      adapterString,
	      biosString,
	      chipType,
	      dacType,
	      memSize);

      /* Now process the installed drivers */
      ok = RegQueryValueEx(hk,"InstalledDisplayDrivers", 
			   NULL, NULL, NULL, &dwSize);
      if(ok == 0) {
	drivers = malloc(dwSize);
	ok = RegQueryValueEx(hk,"InstalledDisplayDrivers",
			     NULL, NULL, drivers, &dwSize);
      }
      if(ok == 0) {
	strcat(tmpString,"\nDriver Versions:");
	/* InstalledDrivers is REG_MULTI_SZ (extra terminating zero) */
	for(drv = drivers; drv[0]; drv +=strlen(drv)) {
	  DWORD verSize, hh;
	  UINT vLen;
	  LPVOID verInfo = NULL, vInfo;

	  /* Concat driver name */
	  strcat(tmpString,"\n\t"); 
	  strcat(tmpString, drv);
	  strcat(tmpString,": ");

	  verSize = GetFileVersionInfoSize(drv, &hh);
	  if(!verSize) goto done;

	  verInfo = malloc(verSize);
	  if(!GetFileVersionInfo(drv, 0, verSize, verInfo)) goto done;

	  /* Try Unicode first */
	  if(VerQueryValue(verInfo,"\\StringFileInfo\\040904B0\\FileVersion", 
			   &vInfo, &vLen)) {
	    strcat(tmpString, vInfo);
	    goto done;
	  }

	  /* Try US/English next */
	  if(VerQueryValue(verInfo,"\\StringFileInfo\\040904E4\\FileVersion", 
			   &vInfo, &vLen)) {
	    strcat(tmpString, vInfo);
	    goto done;
	  }

	  strcat(tmpString, "???");

	done:
	  if(verInfo) {
	    free(verInfo);
	    verInfo = NULL;
	  }
	}
	strcat(tmpString,"\n");
      }
      RegCloseKey(hk);
    }
  }
  gdInfoString = strdup(tmpString);
}

/****************************************************************************/
/*                      Error handling                                      */
/****************************************************************************/
void SetupStderr()
{ TCHAR tmpName[MAX_PATH+1];

  *stderrName = *stdoutName = 0;
  /* re-open stdout && stderr */
  GetTempPath(MAX_PATH,tmpName);
  if(GetStdHandle(STD_ERROR_HANDLE) == INVALID_HANDLE_VALUE)
    {
      GetTempFileName(tmpName,TEXT("sq"),0,stderrName);
      freopen(stderrName,"w+t",stderr);
    }
  else *stderrName = 0;

  if(GetStdHandle(STD_OUTPUT_HANDLE) == INVALID_HANDLE_VALUE)
    {
      GetTempFileName(tmpName,TEXT("sq"),0,stdoutName);
      freopen(stdoutName,"w+t",stdout);
    }
  else *stdoutName = 0;
}

/****************************************************************************/
/*                      Release                                             */
/****************************************************************************/

void
printCommonCrashDumpInfo(FILE *f) {

    fprintf(f,"\n\n%s", hwInfoString);
    fprintf(f,"\n%s", osInfoString);
    fprintf(f,"\n%s", gdInfoString);

    /* print VM version information */
    fprintf(f,"\nVM Version: %s\n", VM_VERSION_INFO);
    fflush(f);
    fprintf(f,"\n"
	    "Current byte code: %d\n"
	    "Primitive index: %d\n",
	    getCurrentBytecode(),
	    methodPrimitiveIndex());
    fflush(f);
    /* print loaded plugins */
    fprintf(f,"\nLoaded plugins:\n");
    {
      int index = 1;
      char *pluginName;
      while( (pluginName = ioListLoadedModule(index)) != NULL) {
	fprintf(f,"\t%s\n", pluginName);
	fflush(f);
	index++;
      }
    }
	/* print the caller's stack to "crash.dmp" */
    fprintf(f,"\nThe Smalltalk Stack:\n");
    {
	  FILE tmpStdout;
	  tmpStdout = *stdout;
	  *stdout = *f;
	  printCallStack();
	  *f = *stdout;
	  *stdout = tmpStdout;
	  fprintf(f,"\n");
    }
}

void
error(char *msg) {
  FILE *f;
  TCHAR crashInfo[1024];

    wsprintf(crashInfo,
	   TEXT("Sorry but the VM has crashed.\n\n")
	   TEXT("Reason: %s\n\n")
	   TEXT("Current byte code: %d\n")
	   TEXT("Primitive index: %d\n\n")
	   TEXT("This information will be stored in the file\n")
	   TEXT("%s\\%s\n")
	   TEXT("with a complete stack dump"),
	   msg,
	   getCurrentBytecode(),
	   methodPrimitiveIndex(),
	   vmPath,
	   TEXT("crash.dmp"));
  if(!fHeadlessImage)
    MessageBox(stWindow,crashInfo,TEXT("Fatal VM error"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);

  SetCurrentDirectory(vmPath);
  /* print the above information */
  f = fopen("crash.dmp","a");
  if(f){  
    time_t crashTime = time(NULL);
    fprintf(f,"---------------------------------------------------------------------\n");
    fprintf(f,"%s\n\n", ctime(&crashTime));

	fprintf(f,"Reason: %s\n", msg);
	printCommonCrashDumpInfo(f);
	fclose(f);
  }
  /* print the caller's stack to stdout */
  printCallStack();
  exit(-1);
}


void printCrashDebugInformation(LPEXCEPTION_POINTERS exp)
{ TCHAR crashInfo[1024];
  FILE *f;
  int byteCode;

  UninstallExceptionHandler();
  /* Retrieve current byte code.
     If this fails the IP is probably wrong */
  TRY {
#ifndef JITTER
    byteCode = getCurrentBytecode();
#else
    byteCode = -1;
#endif
  } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
    byteCode = -1;
  }

  TRY {
  wsprintf(crashInfo,TEXT("Sorry but the VM has crashed.\n\n")
					 TEXT("Exception code: %08X\n")
					 TEXT("Exception address: %08X\n")
                     TEXT("Current byte code: %d\n")
                     TEXT("Primitive index: %d\n\n")
                     TEXT("This information will be stored in the file\n")
                     TEXT("%s%s\n")
                     TEXT("with a complete stack dump"),
					 exp->ExceptionRecord->ExceptionCode,
					 exp->ExceptionRecord->ExceptionAddress,
                     byteCode,
                     methodPrimitiveIndex(),
                     vmPath,
                     TEXT("crash.dmp"));
  if(!fHeadlessImage)
    MessageBox(stWindow,crashInfo,TEXT("Fatal VM error"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);

  SetCurrentDirectory(vmPath);
  /* print the above information */
  f = fopen("crash.dmp","a");
  if(f){  
    time_t crashTime = time(NULL);
    fprintf(f,"---------------------------------------------------------------------\n");
    fprintf(f,"%s\n", ctime(&crashTime));
    /* Print the exception code */
    fprintf(f,"Exception code: %08X\nException addr: %08X\n",
	    exp->ExceptionRecord->ExceptionCode,
	    exp->ExceptionRecord->ExceptionAddress);
    if(exp->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION) {
      /* For access violations print what actually happened */
      fprintf(f,"Access violation (%s) at %08X\n",
	      (exp->ExceptionRecord->ExceptionInformation[0] ? "write access" : "read access"),
	      exp->ExceptionRecord->ExceptionInformation[1]);
    }
    fprintf(f,"EAX:%08X\tEBX:%08X\tECX:%08X\tEDX:%08X\n",
	    exp->ContextRecord->Eax,
	    exp->ContextRecord->Ebx,
	    exp->ContextRecord->Ecx,
	    exp->ContextRecord->Edx);
    fprintf(f,"ESI:%08X\tEDI:%08X\tEBP:%08X\tESP:%08X\n",
	    exp->ContextRecord->Esi,
	    exp->ContextRecord->Edi,
	    exp->ContextRecord->Ebp,
	    exp->ContextRecord->Esp);
    fprintf(f,"EIP:%08X\tEFL:%08X\n",
	    exp->ContextRecord->Eip,
	    exp->ContextRecord->EFlags);
    fprintf(f,"FP Control: %08X\nFP Status:  %08X\nFP Tag:     %08X\n",
	    exp->ContextRecord->FloatSave.ControlWord,
	    exp->ContextRecord->FloatSave.StatusWord,
	    exp->ContextRecord->FloatSave.TagWord);

	printCommonCrashDumpInfo(f);
	fclose(f);

    /* print the caller's stack twice (to stdout and "crash.dmp")*/
	printCallStack();
  }
  } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
    /* that's to bad ... */
    if(!fHeadlessImage)
      MessageBox(0,TEXT("The VM has crashed. Sorry."),TEXT("Fatal error:"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);
    else
      abortMessage(TEXT("The VM has crashed. Sorry."));
  }
}

extern int inCleanExit;

void __cdecl Cleanup(void)
{ /* not all of these are essential, but they're polite... */

  ioShutdownAllModules();
#ifndef NO_PLUGIN_SUPPORT
  pluginExit();
#endif
  ReleaseTimer();
  /* tricky ... we have no systray icon when running
     headfull or when running as service on NT */
  if(fHeadlessImage && (!fRunService || fWindows95))
    SetSystemTrayIcon(0);
  if(palette) DeleteObject(palette);
  PROFILE_SHOW(ticksForReversal);
  PROFILE_SHOW(ticksForBlitting);
  /* Show errors only if not in a browser */
  if(*stderrName)
    {
      fclose(stderr);
      remove(stderrName);
    }
  if(*stdoutName)
    {
      fclose(stdout);
      remove(stdoutName);
    }
#ifndef NO_VIRTUAL_MEMORY
  sqReleaseMemory();
#endif
  OleUninitialize();
}


/****************************************************************************/
/*                      Embedded Images                                     */
/****************************************************************************/
#if 0
/* SQ_IMAGE_MAGIC - the magic number for embedded images "SQIM" */
#define SQ_IMAGE_MAGIC 0x83817377

int sqImageFile findEmbeddedImage(void) {
	sqImageFile f;
	int endMarker;
	int magic;
	int start;
	int length;

	f = sqImageFileOpen(vmName, "rb");
	if(!f) {
		MessageBox(0,"Error opening VM",VM_NAME,MB_OK);
		return 0;
	}
	endMarker = sqImageFileSize(f) - 8;
	magic = start = 0;
	sqImageFileSeek(f, endMarker);
    sqImageFileRead(&magic, 1, 4, f);
	sqImageFileRead(&start, 1, 4, f);
	sqMessageBox(MB_OK, "Magic number", "Expected:\t%x\nFound:\t\t%x", SQ_IMAGE_MAGIC, magic);
	/* Magic number must be okay and start must be within executable boundaries */
	if(magic != SQ_IMAGE_MAGIC || start < 0 || start >= endMarker) {
		/* nope */
		sqImageFileClose(f);
		return 0;
	}
	/* Might have an embedded image; seek back and double check */
	sqImageFileSeek(f,start);
	sqImageFileRead(&magic, 1, 4, f);
	sqMessageBox(MB_OK, "Magic number", "Expected:\t%x\nFound:\t\t%x", SQ_IMAGE_MAGIC, magic);
	if(magic != SQ_IMAGE_MAGIC) {
		/* nope */
		sqImageFileClose(f);
		return 0;
	}
	/* now triple check for image format */
	sqImageFileRead(&magic, 1, 4, f);
	if(!readableFormat(magic) && !readableFormat(byteSwapped(magic)) {
		/* nope */
		sqImageFileClose(f);
		return 0;
	}
	/* Gotcha! */
	sqImageFileSeek(f, sqImageFilePosition(f) - 4);
	strcpy(imageName, name);
	imageSize = endMarker - sqImageFilePosition(f);
	return f;
}
#else
int findEmbeddedImage(void) { return 0; }
#endif


/****************************************************************************/
/*                        sqMain                                            */
/****************************************************************************/
static vmArg args[] = {
  { ARG_STRING, &installServiceName, "-service:" }, /* the name of a service */
  { ARG_FLAG, &fHeadlessImage, "-headless" },       /* do we run headless? */
  { ARG_STRING, &logName, "-log:" },                /* VM log file */
  { ARG_UINT, &dwMemorySize, "-memory:" },          /* megabyte of memory to use */

  /* NOTE: the following flags are "undocumented" */
  { ARG_INT, &browserWindow, "-browserWindow:"},    /* The web browser window we run in */

  /* service support on 95 */
  { ARG_FLAG, &fRunService, "-service95" },           /* do we start as service? */
  { ARG_FLAG, &fBroadcastService95, "-broadcast95" }, /* should we notify services of a user logon? */
#ifdef  VISTA_SECURITY /* IE7/Vista protected mode support */
  { ARG_FLAG, &fLowRights, "-lowRights" }, /* started with low rights, 
					use alternate untrustedUserDirectory */
#endif /* VISTA_SECURITY */
  { ARG_NONE, NULL, NULL }
};

/* sqMain: 
   This is common entry point regardless of whether we're running
   as a normal app or as a service. Note that a number of things
   may have been set up before coming here. In particular,
   * fRunService - to determine whether we're running as NT service
   However, the command line must always contain all parameters necessary.
   In other words, even though the logName may have been set before,
   the command line has to include the -log: switch.
*/
int sqMain(char *lpCmdLine, int nCmdShow) { 
  int virtualMemory;
  WCHAR *cmdLineW;
  char *cmdLineA;
  int sz;

  /* set default fpu control word */
  _control87(FPU_DEFAULT, _MCW_EM | _MCW_RC | _MCW_PC | _MCW_IC);

  LoadPreferences();

  /* Fetch the command line */
  cmdLineW = GetCommandLineW();
  sz = WideCharToMultiByte(CP_UTF8, 0, cmdLineW, -1, NULL, 0, NULL, NULL);
  cmdLineA = calloc(sz, sizeof(char));
  WideCharToMultiByte(CP_UTF8, 0, cmdLineW, -1, cmdLineA, sz, NULL, NULL);

  /* If running as single app, find the previous instance */
  if(fRunSingleApp) {
    HWND win = GetTopWindow(0);
    while (win != NULL) {
      char buf[MAX_PATH];
      GetClassName(win, buf, 80);
      if(strcmp(windowClassName, buf) == 0) break;
      win = GetNextWindow(win, GW_HWNDNEXT);
    }

    if(win) {
      /* An instance is running already. Inform it about the app. */
      int bytes = (wcslen(cmdLineW)+1) * sizeof(WCHAR);
      HANDLE h = GlobalAlloc(GMEM_MOVEABLE | GMEM_DDESHARE, bytes);
      WCHAR *string = GlobalLock(h);
      memcpy(string, cmdLineW, bytes);
      GlobalUnlock(h);

      OpenClipboard(NULL);
      EmptyClipboard();
      SetClipboardData(CF_UNICODETEXT, h);
      CloseClipboard();

      if(IsIconic(win)) ShowWindow(win, SW_RESTORE);
      SetForegroundWindow(win);
      SetActiveWindow(win);
      return PostMessage(win, SQ_LAUNCH_DROP, 0, 0);
    }
  }


  if(!parseArguments(cmdLineA, args))
    return printUsage(1);

  /* a quick check if we have any argument at all */
  if(!fRunService && (*imageName == 0)) {
    /* Check if the image is embedded */
    imageFile = findEmbeddedImage();
    if(!imageFile) {
      /* Search the current directory if there's a single image file */
      if(!findImageFile()) {
	/* Nope. Give the user a chance to open an image interactively */
	if(!openImageFile()) return -1; /* User cancelled file open */
      }
    }
  }

#ifdef NO_SERVICE
  fRunService = 0;
#endif

  /* look for a few things easy to handle */
  if(fWindows95 && fBroadcastService95) {
    PostMessage(HWND_BROADCAST, WM_BROADCAST_SERVICE, 0, 0);
    return 0;
  }

  /* set time zone accordingly */
  _tzset();


  /* Initialize OLE library so we don't have to do it from other places */
  OleInitialize(NULL);

  /* Give us some log information when running as service */
  if(fRunService) { 
    time_t svcStart;
    
    svcStart = time(NULL);
    OutputLogMessage("\n\n");
    OutputLogMessage(ctime(&svcStart));
    if(fWindows95) /* don't have a service name */
      OutputLogMessage("The service");
    else
      OutputLogMessage(serviceName);
    OutputLogMessage(" started with the following command line\n");
    OutputLogMessage(initialCmdLine);
    OutputLogMessage("\n");
  }

  SetupFilesAndPath();

  /* release resources on exit */
  atexit(Cleanup);

#ifndef NO_SERVICE
  /* if service installing is requested, do so */
  if(installServiceName && *installServiceName) {
    strcpy(serviceName, installServiceName);
    sqServiceInstall();
    /* When installing was successful we won't come
       to this point. Otherwise ... */
    exit(-1); /* this will show any printfs during install */
  }
#endif

  /* initialisation */
  SetupKeymap();
  SetupWindows();
  SetupPixmaps();
  SetupService95();
  SetupTimer();

  /* check the interpreter's size assumptions for basic data types */
  if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
  if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
  if (sizeof(time_t) != 4) error("This C compiler's time_t's are not 32 bits.");


  if(!imageFile) {
    imageSize = SqueakImageLength(toUnicode(imageName));
    if(imageSize == 0) printUsage(2);
  }

  /* allocate the synchronization mutex before anything is going to happen */
  vmSemaphoreMutex = CreateMutex(NULL, 0, NULL);
  vmWakeUpEvent = CreateEvent(NULL, 1, 0, NULL);

#ifdef NO_VIRTUAL_MEMORY
  if(!dwMemorySize) {
    dwMemorySize = 4;
    virtualMemory = (int)imageSize + max(imageSize, dwMemorySize * 0x00100000);
  } else {
    virtualMemory = (int)dwMemorySize * 0x00100000;
  }
#else
  /* initial commit size = imageSize + 4MB */
  virtualMemory = imageSize + 0x00400000;
#endif

#ifndef _MSC_VER
  /* Install our top-level exception handler */
  InstallExceptionHandler();
#else
  __try {
#endif
    /* set the CWD to the image location */
    if(*imageName) {
      char path[MAX_PATH+1], *ptr;
      strcpy(path,imageName);
      ptr = strrchr(path, '\\');
      if(ptr) {
	*ptr = 0;
	SetCurrentDirectory(path);
      }
    }

    /* display the splash screen */
    ShowSplashScreen();

    /* if headless running is requested, try to to create an icon
       in the Win95/NT system tray */
    if(fHeadlessImage && (!fRunService || fWindows95))
      SetSystemTrayIcon(1);
    
    /* read the image file */
    if(!imageFile) {
      imageFile = sqImageFileOpen(imageName,"rb");
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, 0);
    } else {
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, sqImageFilePosition(imageFile));
    }
    sqImageFileClose(imageFile);

    if(fHeadlessImage) HideSplashScreen(); /* need to do it manually */
    SetWindowSize();
    ioSetFullScreen(getFullScreenFlag());

    /* run Squeak */
    ioInitSecurity();
    interpret();
#ifdef _MSC_VER
  } __except(squeakExceptionHandler(GetExceptionInformation())) {
    /* Do nothing */
  }
#else
  /* remove the top-level exception handler */
  UninstallExceptionHandler();
#endif
  return 1;
}

/****************************************************************************/
/*                        WinMain                                           */
/****************************************************************************/
int WINAPI WinMain (HINSTANCE hInst,
                    HINSTANCE hPrevInstance,
                    LPSTR  lpCmdLine,
                    int    nCmdShow)
{
  /* a few things which need to be done first */
  gatherSystemInfo();

  /* check if we're running NT or 95 */
  fWindows95 = (GetVersion() & 0x80000000) != 0;

  /* fetch us a copy of the command line */
  initialCmdLine = strdup(lpCmdLine);

  /* fetch us the name of the executable */
  {
    WCHAR vmNameW[MAX_PATH];
    GetModuleFileNameW(hInst, vmNameW, MAX_PATH);
    WideCharToMultiByte(CP_UTF8, 0, vmNameW, -1, vmName, MAX_PATH, NULL, NULL);
  }
  /* open all streams in binary mode */
  _fmode  = _O_BINARY;

  /* get us the instance handle */
  hInstance = hInst;

#ifndef NO_PLUGIN_SUPPORT
  pluginInit();
#endif
#ifndef NO_SERVICE
  /* Find out if we're running from a service.
     That's a bit tricky since there is no difference between
     usual startup and service startup. We do two assumptions here:
     1) If we're NOT running on NT we can't be service
     2) If there is a command line we can't be service
     Still, there is a chance that a user just double clicks on
     the Squeak executable in NT. Therefore we _try_ to connect
     to the service control manager in the sqServiceMain function.
     If this fails, we try the usual startup. It might take a bit
     longer than the normal startup but this only happens if there
     is no image name given - and that's not our fault. Anyways,
     if somebody out there knows how to find out when we're starting
     as a service - LET ME KNOW!
  */
  if(!fWindows95)                      /* 1) running NT */
    if(!*lpCmdLine)                  /* 2) No command line */
      if(sqServiceMain())          /* try starting the service */
	return 0;                /* service was run - exit */

#endif

  /* Special startup stuff for windows 95 */
  if(fWindows95) {
    /* The message we use for notifying services of user logon */
    WM_BROADCAST_SERVICE = RegisterWindowMessage(msgBroadcastService);
  }

  /* start the non-service version */
  sqMain(lpCmdLine, nCmdShow);
  return 0;
}
