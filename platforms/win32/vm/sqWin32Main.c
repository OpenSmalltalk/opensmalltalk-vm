/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Main.c
*   CONTENT: Main entry point and support stuff for Win95/WinNT/WinXP on x86
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES: (I think this comment of Andreas' is obsolete; eem 6/2013)
*    1) When using this module the virtual machine MUST NOT be compiled
*       with Unicode support.
*****************************************************************************/
#include <windows.h>
#include <stdio.h>
#include <stdlib.h> /* exit */
#include <string.h>
#include <fcntl.h> /* _O_BINARY */
#include <float.h>
#include <ole2.h>
#include <process.h>
#include "sq.h"
#include "sqWin32Prefs.h"
#include "sqAssert.h"
#include "sqWin32Backtrace.h"
#include "sqSCCSVersion.h"
#if COGVM
# include "cogmethod.h"
# if COGMTVM
#  include "cointerpmt.h"
# else
#  include "cointerp.h"
# endif
#endif

#if !defined(IMAGE_SIZEOF_NT_OPTIONAL_HEADER)
#include <winnt.h>
#define  IMAGE_SIZEOF_NT_OPTIONAL_HEADER  sizeof(IMAGE_OPTIONAL_HEADER)
#endif

/* Windows Vista support 
 * AUTHOR: Korakurider (kr)
 * CHANGE NOTES:
 *   1) new command line option "-lowRights" was introduced
 *      to support IE7/protected mode.
 */
#define VISTA_SECURITY 1 /* IE7/Vista protected mode support */

/*** Crash debug -- Imported from Virtual Machine ***/
int getFullScreenFlag(void);
sqInt methodPrimitiveIndex(void);
int getCurrentBytecode(void);

extern TCHAR* squeakIniName;
extern void printPhaseTime(int);

/* Import from sqWin32Alloc.c */
LONG CALLBACK sqExceptionFilter(LPEXCEPTION_POINTERS exp);

/* Import from sqWin32Window.c */
char * GetAttributeString(int id);
void ShowSplashScreen(void);
void HideSplashScreen(void);

/* Import from sqWin32Heartbeat.c */
void ioReleaseTime(void);

/* Import from SecurityPlugin/sqWin32Security.c */
sqInt ioInitSecurity(void);

/* forwarded declaration */
static void printCrashDebugInformation(LPEXCEPTION_POINTERS exp);

/*** Variables -- command line */
static TCHAR *initialCmdLine;
static int  numOptionsVM = 0;
static char **vmOptions;
static int  numOptionsImage = 0;
static char **imageOptions;
static int clargc; /* the Unix-style command line, saved for GetImageOption */
static char **clargv;

/* console buffer */
BOOL fIsConsole = 0;
TCHAR consoleBuffer[4096] = { 0 };

/* stderr and stdout names */
TCHAR stderrName[MAX_PATH+1] = { 0 };
TCHAR stdoutName[MAX_PATH+1] = { 0 };

char* vmLogDirUTF8 = NULL;
WCHAR* vmLogDirW = NULL;
 
TCHAR* logName = NULL;             /* full path and name to log file */

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

static LONG CALLBACK
squeakExceptionHandler(LPEXCEPTION_POINTERS exp)
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
  if (result != EXCEPTION_CONTINUE_EXECUTION) {
    DWORD code = exp->ExceptionRecord->ExceptionCode;
    if ((code >= EXCEPTION_FLT_DENORMAL_OPERAND) && (code <= EXCEPTION_FLT_UNDERFLOW)) {
      /* turn on the default masking of exceptions in the FPU and proceed */
      _control87(FPU_DEFAULT, _MCW_EM | _MCW_RC | _MCW_PC | _MCW_IC);
      result = EXCEPTION_CONTINUE_EXECUTION;
    }
  }

  /* #3: If that didn't work either try passing it on to the old
     top-level filter */
  if (result != EXCEPTION_CONTINUE_EXECUTION) {
    if (TopLevelFilter) {
      result = TopLevelFilter(exp);
    }
  }
#ifdef NDEBUG
  /* #4: If that didn't work either give up and print a crash debug information */
  if (result != EXCEPTION_CONTINUE_EXECUTION) {
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

/* N.B. As of cygwin 1.5.25 fopen("crash.dmp","a") DOES NOT WORK!  crash.dmp
 * contains garbled output as if the file pointer gets set to the start of the
 * file, not the end.  So we synthesize our own append mode.
 */
#if __MINGW32__
# include <io.h>
static FILE *
fopen_for_append(char *filename)
{
  FILE *f = !access(filename, F_OK) /* access is bass ackwards */
    ? fopen(filename,"r+")
    : fopen(filename,"w+");
  if (f)
    fseek(f,0,SEEK_END);
  return f;
}
#else
# define fopen_for_append(filename) fopen(filename,"a+t")
#endif

/****************************************************************************/
/*                      Console Window functions                            */
/****************************************************************************/
static int
OutputLogMessage(char *string)
{
  FILE *fp;

  if (!*logName) return 1;
  char* logNameUTF8 = NULL;
  TCHAR_TO_UTF8(logName, logNameUTF8);
  fp = fopen_for_append(logNameUTF8);
  if (!fp) return 1;
  fprintf(fp, "%s", string);
  fflush(fp);
  fclose(fp);
  return 1;
}

static int
OutputConsoleString(char *string)
{
  int pos;

  if (fDynamicConsole && !fShowConsole) {
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

// recommend using DPRINTF ifdef'ing to DPRINTF for debug output
int __cdecl DPRINTF(const char *fmt, ...)
{
  va_list al;

  va_start(al, fmt);
  TCHAR* tFmt = NULL;
  UTF8_TO_TCHAR(fmt, tFmt);
  if (!fIsConsole) {
    wvsprintf(consoleBuffer, tFmt, al);
    OutputDebugString(consoleBuffer);
  }
  vfprintf(stdout, fmt, al);
  va_end(al);
  return 1;
}

#if !defined(_MSC_VER) && !defined(NODBGPRINT)

// redefining printf doesn't seem like a good idea to me...

int __cdecl
printf(const char *fmt, ...)
{
  va_list al;
  int result;

  va_start(al, fmt);
  if (!fIsConsole) {
    wvsprintf(consoleBuffer, fmt, al);
    OutputLogMessage(consoleBuffer);
    if (IsWindow(stWindow)) {
      /* not running as service? */
      OutputConsoleString(consoleBuffer);
    }
  }
  result = vfprintf(stdout, fmt, al);
  va_end(al);
  return result;
}

int __cdecl
fprintf(FILE *fp, const char *fmt, ...)
{
  va_list al;
  int result;

  va_start(al, fmt);
  if (!fIsConsole && (fp == stdout || fp == stderr))
    {
      wvsprintf(consoleBuffer, fmt, al);
      OutputLogMessage(consoleBuffer);
      if (IsWindow(stWindow)) /* not running as service? */
        OutputConsoleString(consoleBuffer);
    }
  result = vfprintf(fp, fmt, al);
  va_end(al);
  return result;
}


int __cdecl
putchar(int c)
{
  return printf("%c",c);
}

#endif /* !defined(_MSC_VER) && !defined(NODBGPRINT) */

/****************************************************************************/
/*                   Message Processing                                     */
/****************************************************************************/

static messageHook nextMessageHook = NULL;

int ServiceMessageHook(void * hwnd, unsigned int message, unsigned int wParam, long lParam)
{
  if (fRunService && fWindows95 && message == WM_BROADCAST_SERVICE && hwnd == stWindow)
    {
      /* broadcast notification - install the running Win95 service in the system tray */
      SetSystemTrayIcon(1);
      return 1;
    }
   if (message == WM_USERCHANGED)
      {
        SetSystemTrayIcon(1);
        return 1;
      }
  if (nextMessageHook)
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
  NOTIFYICONDATA nid;

  nid.cbSize = sizeof(nid);
  nid.hWnd   = stWindow;
  nid.uID    = (usqIntptr_t)hInstance;
  nid.uFlags = NIF_MESSAGE | NIF_TIP | NIF_ICON;
  nid.uCallbackMessage = WM_USER+42;
  nid.hIcon  = LoadIcon(hInstance, MAKEINTRESOURCE(1));
  lstrcpy(nid.szTip, TEXT(VM_NAME) TEXT("!"));
  if (on) {
    Shell_NotifyIcon(NIM_ADD, &nid);
  } else {
    Shell_NotifyIcon(NIM_DELETE, &nid);
   }
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
  if (!fRunService || !fWindows95) return;
  hKernel32 = LoadLibrary(TEXT("kernel32.dll"));
  if (!hKernel32)
    {
      printLastError(TEXT("Unable to load kernel32.dll"));
      return;
    }
  (FARPROC) RegisterServiceProcess = GetProcAddress(hKernel32, "RegisterServiceProcess");
  if (!RegisterServiceProcess)
    {
      printLastError(TEXT("Unable to find RegisterServiceProcess"));
      return;
    }
  if ( !(*RegisterServiceProcess)(GetCurrentProcessId(), RSP_SIMPLE_SERVICE ) )
    printLastError(TEXT("RegisterServiceProcess failed"));
#endif /* NO_SERVICE */
}

/****************************************************************************/
/*                      System Attributes                                   */
/****************************************************************************/

char *GetVMOption(int id)
{
  if (id < numOptionsVM)
    return vmOptions[id];
  else
    return NULL;
}

char *GetImageOption(int id)
{
  if (id < numOptionsImage)
    return imageOptions[id];
  else
    return NULL;
}

char *ioGetLogDirectory(void) {
  return vmLogDirUTF8  ? vmLogDirUTF8 : "";
}

sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz) {
  RECALLOC_OR_RESET(vmLogDirUTF8, sz + 1, sizeof(char), return 0);
  strncpy(vmLogDirUTF8, lblIndex, sz);
  vmLogDirUTF8[sz] = 0;

  int wsz = MultiByteToWideChar(CP_UTF8, 0, vmLogDirUTF8, -1, NULL, 0);
  RECALLOC_OR_RESET(vmLogDirW, wsz + 1, sizeof(WCHAR), return 0);
  MultiByteToWideChar(CP_UTF8, 0, vmLogDirUTF8, -1, vmLogDirW, wsz);
}

/* New MinGW defines this, as does MSVC - so who still needs it? */
#if !defined(VerifyVersionInfo)
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
#endif /* !defined(VerifyVersionInfo) */

/* New MinGW defines this, as does MSVC - so who still needs it? */
#if !defined(EnumDisplayDevices)
typedef struct _DISPLAY_DEVICE {
  DWORD cb;
  TCHAR DeviceName[32];
  TCHAR DeviceString[128];
  DWORD StateFlags;
  TCHAR DeviceID[128];
  TCHAR DeviceKey[128];
} DISPLAY_DEVICE, *PDISPLAY_DEVICE;
#endif /* !defined(EnumDisplayDevices) */

typedef BOOL (CALLBACK *pfnEnumDisplayDevices)(
  LPCTSTR lpDevice,                // device name
  DWORD iDevNum,                   // display device
  PDISPLAY_DEVICE lpDisplayDevice, // device information
  DWORD dwFlags                    // reserved
);
char *osInfoString = "";
char *hwInfoString = "";
char *gdInfoString = "";
char *win32VersionName = "";

void gatherSystemInfo(void)
{

#define SYSTEM_INFO_BUF_SIZE 256
#define GET_INFO_REG_X(hive, name, dest, sz, dflt) {          \
  DWORD dwSize = sz;                                          \
  DWORD ok = RegQueryValueEx(hive, TEXT( name ), NULL, NULL,  \
                             (LPBYTE) dest, &dwSize);         \
  if (ERROR_SUCCESS != ok) {                                  \
    dflt;                                                     \
      }                                                           \
}
#define GET_INFO_REG_S(hive, name, dest) \
  GET_INFO_REG_X(hive, name, dest, \
                 SYSTEM_INFO_BUF_SIZE, lstrcpy(dest, TEXT("???")))

  OSVERSIONINFOEX osInfo = { 0 };
  MEMORYSTATUS memStat = { 0 };
  SYSTEM_INFO sysInfo = { 0 };
  DISPLAY_DEVICE gDev = { 0 };
  unsigned int proc, screenX, screenY;
  TCHAR tmpString[4096];

  TCHAR keyName[SYSTEM_INFO_BUF_SIZE] = { 0 };
  HKEY hk = NULL;

  /* Retrieve version info for crash logs */
  osInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
  GetVersionEx((OSVERSIONINFO*)&osInfo);
  GetSystemInfo(&sysInfo);

  /* Set up the win32VersionName */
  _stprintf(tmpString, TEXT("%lu.%lu"),
            (ULONG)osInfo.dwMajorVersion, (ULONG)osInfo.dwMinorVersion);
  {
    char* uTmp = NULL;
    TCHAR_TO_UTF8(tmpString, uTmp);
    win32VersionName = _strdup(uTmp);
  }

  memStat.dwLength = sizeof(MEMORYSTATUS);
  GlobalMemoryStatus(&memStat);

  screenX = GetSystemMetrics(SM_CXSCREEN);
  screenY = GetSystemMetrics(SM_CYSCREEN);

  gDev.cb = sizeof(DISPLAY_DEVICE);
  EnumDisplayDevices(NULL, 0, &gDev, 0);

  {
    /* Figure out make and model from OEMINFO.ini */
    TCHAR iniName[MAX_PATH];
    TCHAR manufacturer[SYSTEM_INFO_BUF_SIZE];
    TCHAR model[SYSTEM_INFO_BUF_SIZE];

    GetSystemDirectory(iniName, MAX_PATH);
    lstrcat(iniName, TEXT("\\OEMINFO.INI"));

    GetPrivateProfileString(TEXT("General"),
                            TEXT("Manufacturer"), TEXT("Unknown"),
                            manufacturer, SYSTEM_INFO_BUF_SIZE, iniName);

    GetPrivateProfileString(TEXT("General"),
                            TEXT("Model"), TEXT("Unknown"),
                            model, SYSTEM_INFO_BUF_SIZE, iniName);


    _stprintf(tmpString,
              TEXT("Hardware information: \n")
              TEXT("\tManufacturer: %s\n")
              TEXT("\tModel: %s\n")
              TEXT("\tNumber of processors: %lu\n")
              TEXT("\tPage size: %lu\n")
              TEXT("\nMemory Information (upon launch):\n")
              TEXT("\tPhysical Memory Size: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tPhysical Memory Free: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tPage File Size: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tPage File Free: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tVirtual Memory Size: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tVirtual Memory Free: %" ) TEXT(PRIuSQPTR) TEXT( " kbytes\n")
              TEXT("\tMemory Load: %lu percent\n"),
              manufacturer, model,
              (ULONG) sysInfo.dwNumberOfProcessors,
              (ULONG) sysInfo.dwPageSize,
              memStat.dwTotalPhys / 1024,
              memStat.dwAvailPhys / 1024,
              memStat.dwTotalPageFile / 1024,
              memStat.dwAvailPageFile / 1024,
              memStat.dwTotalVirtual / 1024,
              memStat.dwAvailVirtual / 1024,
              (ULONG) memStat.dwMemoryLoad);
  }

  /* find more information about EACH processor */
  for (proc = 0; proc < sysInfo.dwNumberOfProcessors; proc++) {

    TCHAR *tmp = tmpString + lstrlen(tmpString);

    lstrcpy(keyName, TEXT("HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0"));
    _itot_s(proc, keyName + lstrlen(keyName) - 1, SYSTEM_INFO_BUF_SIZE - (lstrlen(keyName) + 2), 10);

    if (ERROR_SUCCESS == RegOpenKey(HKEY_LOCAL_MACHINE, keyName, &hk)) {
      TCHAR nameString[SYSTEM_INFO_BUF_SIZE];
      TCHAR identifier[SYSTEM_INFO_BUF_SIZE];
      DWORD mhz;

      GET_INFO_REG_S(hk, "ProcessorNameString", nameString);
      GET_INFO_REG_S(hk, "Identifier", identifier);
      GET_INFO_REG_X(hk, "~MHz", &mhz, sizeof(DWORD), mhz = ~0);
      _stprintf(tmp,
                TEXT("\nProcessor %u: %s\n")
                TEXT("\tIdentifier: %s\n")
                TEXT("\t~MHZ: %lu\n"),
                proc, nameString, identifier, (ULONG) mhz);
      RegCloseKey(hk);
    }
  }

  {
    char* uTmp = NULL;
    TCHAR_TO_UTF8(tmpString, uTmp);
    hwInfoString = _strdup(uTmp);
  }

  {
    TCHAR owner[SYSTEM_INFO_BUF_SIZE];
    TCHAR company[SYSTEM_INFO_BUF_SIZE];
    TCHAR product[SYSTEM_INFO_BUF_SIZE];
    TCHAR productid[SYSTEM_INFO_BUF_SIZE];
 
    DWORD ok = ERROR_SUCCESS;
    if (osInfo.dwPlatformId == VER_PLATFORM_WIN32_NT) {
      ok = RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"), &hk);
    } else {
      ok = RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows\\CurrentVersion"), &hk);
    }

    if (ERROR_SUCCESS == ok) {
      GET_INFO_REG_S(hk, "RegisteredOwner", owner);
      GET_INFO_REG_S(hk, "RegisteredOrganization", company);
      GET_INFO_REG_S(hk, "ProductName", product);
      RegCloseKey(hk);
    }

    _stprintf(tmpString,
              TEXT("Operating System: %s (Build %lu %s)\n")
              TEXT("\tRegistered Owner: %s\n")
              TEXT("\tRegistered Company: %s\n")
              TEXT("\tSP major version: %d\n")
              TEXT("\tSP minor version: %d\n")
              TEXT("\tSuite mask: %lx\n")
              TEXT("\tProduct type: %lx\n"),
              product, 
              (ULONG) osInfo.dwBuildNumber, osInfo.szCSDVersion,
              owner, company,
              osInfo.wServicePackMajor, osInfo.wServicePackMinor,
#if defined(_MSC_VER) && _MSC_VER < 1300
# define wSuiteMask wReserved[0]
# define wProductType wReserved[1] & 0xFF
#endif
              osInfo.wSuiteMask, osInfo.wProductType);
  }


  {
    char* uTmp = NULL;
    TCHAR_TO_UTF8(tmpString, uTmp);
    osInfoString = _strdup(uTmp);
  }


  _stprintf(tmpString,
            TEXT("Display Information: \n")
            TEXT("\tGraphics adapter name: %s\n")
            TEXT("\tPrimary monitor resolution: %d x %d\n"),
            gDev.DeviceString,
            screenX, screenY);

  /* Find the driver key in the registry */
  keyName[0] = 0;
  if (ERROR_SUCCESS == RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("HARDWARE\\DEVICEMAP\\VIDEO"), &hk)) {
    DWORD dwSize = SYSTEM_INFO_BUF_SIZE;
    RegQueryValueEx(hk, TEXT("\\Device\\Video0"), NULL, NULL, (LPBYTE) keyName, &dwSize);
    RegCloseKey(hk);
  }

  if (*keyName) {
    /* Got the key name; open it and get the info out of there */
    TCHAR* tmp = tmpString + lstrlen(tmpString);
    TCHAR deviceDesc[SYSTEM_INFO_BUF_SIZE];
    TCHAR adapterString[SYSTEM_INFO_BUF_SIZE];
    TCHAR biosString[SYSTEM_INFO_BUF_SIZE];
    TCHAR chipType[SYSTEM_INFO_BUF_SIZE];
    TCHAR dacType[SYSTEM_INFO_BUF_SIZE];
    TCHAR version[SYSTEM_INFO_BUF_SIZE];
    WCHAR buffer[SYSTEM_INFO_BUF_SIZE];
    TCHAR *drivers = NULL;
    TCHAR *drv = NULL;
    DWORD memSize = 0;

    /* \Registry\Machine\ is a Driver-related alias to HKEY_LOCAL_MACHINE,
       so we can strip it when we use HKEY_LOCAL_MACHINE in RegOpenKey */
 
    if (_tcsncicmp(keyName, TEXT("\\registry\\machine\\"), 18 /* len of text over there */) == 0) {
     /* can't use memcpy here cause we may not know how much memory to copy
        for a character. So we need a temporary, because strcpy/_tcscpy are undefined
        for overlapping memory.... */
     TCHAR* copytmp = _tcsdup(keyName);
     _tcsncpy(keyName, copytmp + 18, lstrlen(copytmp) - 17);
     free(copytmp);
    }

    if (ERROR_SUCCESS != RegOpenKey(HKEY_LOCAL_MACHINE, keyName, &hk)) {
      MessageBox(0, keyName, TEXT("Cannot open:"), MB_OK);
    } else {
      GET_INFO_REG_S(hk, "Device Description", deviceDesc);
      GET_INFO_REG_S(hk, "HardwareInformation.AdapterString", adapterString);
      GET_INFO_REG_S(hk, "HardwareInformation.BiosString", biosString);
      GET_INFO_REG_S(hk, "HardwareInformation.ChipType", chipType);
      GET_INFO_REG_S(hk, "HardwareInformation.DacType", dacType);
      GET_INFO_REG_X(hk, "HardwareInformation.MemorySize", memSize, sizeof(DWORD), memSize = -1);

      _stprintf(tmp,
                TEXT("\nDevice: %s\n")
                TEXT("\tAdapter String: %s\n")
                TEXT("\tBios String: %s\n")
                TEXT("\tChip Type: %s\n")
                TEXT("\tDAC Type: %s\n")
                TEXT("\tMemory Size: 0x%.8X\n"),
                deviceDesc,
                adapterString,
                biosString,
                chipType,
                dacType,
                memSize);

      /* Now process the installed drivers */
      DWORD dwSize = 0;
      DWORD ok = RegQueryValueEx(hk, TEXT("InstalledDisplayDrivers"),
                                 NULL, NULL, NULL, &dwSize);
      if (ERROR_SUCCESS == ok) {
        drivers = calloc(1, dwSize);
        ok = RegQueryValueEx(hk, TEXT("InstalledDisplayDrivers"),
                             NULL, NULL, (LPBYTE) drivers, &dwSize);

        if (ERROR_SUCCESS == ok) {
          lstrcat(tmpString, TEXT("\nDriver Versions:"));

          /* InstalledDrivers is REG_MULTI_SZ (extra terminating zero) */
          for (drv = drivers; drv[0]; drv += lstrlen(drv)) {
            DWORD verSize = 0, hh = 0;
            UINT vLen = 0;
            LPVOID verInfo = NULL, vInfo = NULL;
            /* Concat driver name */
            lstrcat(tmpString, TEXT("\n\t"));
            lstrcat(tmpString, drv);
            lstrcat(tmpString, TEXT(": "));

            verSize = GetFileVersionInfoSize(drv, &hh);
            if (!verSize) { goto done; }

            verInfo = calloc(1, verSize);
            if (!GetFileVersionInfo(drv, 0, verSize, verInfo)) { goto done; }

/* Language identifier from https://msdn.microsoft.com/en-us/library/dd318693 */
#define SYSINFO_LANG_EN_US TEXT("0409")
/* CodePage number from https://msdn.microsoft.com/en-us/library/dd317756 */
#define SYSINFO_CP_ANSI TEXT("04E4")
#define SYSINFO_CP_UNICODE TEXT("04E0")

            /* Try English/Unicode first */
            if (VerQueryValue(verInfo, 
                TEXT("\\StringFileInfo\\") SYSINFO_LANG_EN_US SYSINFO_CP_UNICODE TEXT("\\FileVersion"),
                &vInfo, &vLen)) {
              lstrcat(tmpString, vInfo);
              goto done;
            }

            /* Try English/Ansi Latin 1 next */
            if (VerQueryValue(verInfo,
                TEXT("\\StringFileInfo\\") SYSINFO_LANG_EN_US SYSINFO_CP_ANSI TEXT("\\FileVersion"),
                &vInfo, &vLen)) {
              lstrcat(tmpString, vInfo);
              goto done;
            }

            lstrcat(tmpString, TEXT("???"));
done:
            if (verInfo) {
              free(verInfo);
              verInfo = NULL;
            }
          }

          lstrcat(tmpString, TEXT("\n"));
        }
      }
      RegCloseKey(hk);
    }
  }
  {
    char* uTmp = NULL;
    TCHAR_TO_UTF8(tmpString, uTmp);
    gdInfoString = _strdup(uTmp);
  }
}

char *
getVersionInfo(int verbose)
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  char *info= (char *)malloc(4096);
  info[0]= '\0';

#if SPURVM
# if BytesPerOop == 8
#  define ObjectMemory " Spur 64-bit"
# else
#  define ObjectMemory " Spur"
# endif
#else
# define ObjectMemory
#endif
#if defined(NDEBUG)
# define BuildVariant "Production" ObjectMemory
#elif DEBUGVM
# define BuildVariant "Debug" ObjectMemory
# else
# define BuildVariant "Assert" ObjectMemory
#endif

  sprintf(info+strlen(info), "%s [" BuildVariant " VM]\n", vmBuildString);
  if (verbose)
    sprintf(info+strlen(info), "Built from: ");
  sprintf(info+strlen(info), "%s\n", INTERP_BUILD);
#if COGVM
  if (verbose)
    sprintf(info+strlen(info), "With: ");
  sprintf(info+strlen(info), "%s\n", GetAttributeString(1008)); /* __cogitBuildInfo */
#endif
  if (verbose)
    sprintf(info+strlen(info), "Revision: ");
  sprintf(info+strlen(info), "%s\n", sourceVersionString('\n'));
  return info;
}

#if !defined(_MSC_VER) 
/* Calling exit(ec) apparently does NOT provide the correct exit code for the
 * terminating process (MinGW bug?). So instead call the shutdown sequence via
 * _cexit() and then terminate explicitly.
 */
# define exit(ec) do { _cexit(); ExitProcess(ec); } while (0)
#endif

static void
versionInfo(void)
{
#if 0
  /* we could create a console but to version the non-consoel VM it is
   * sufficient to do e.g. Squeak.exe >foo; cat foo.  But feel free to
   * add the code if you have the energy ;)
   */
  DWORD mode;
  HANDLE stdouth = GetStdHandle(STD_OUTPUT_HANDLE);

  if (GetConsoleMode(stdouth, &mode) != 0) {
    char *vi = getVersionInfo(0);
    WriteConsole(stdouth, vi, strlen(vi), 0, 0);
  }
  else
#endif
    printf("%s", getVersionInfo(0));
  exit(EXIT_SUCCESS);
}

/****************************************************************************/
/*                      Error handling                                      */
/****************************************************************************/
void SetupStderr()
{
  TCHAR tmpName[MAX_PATH + 1];

  /* re-open stdout && stderr */
  GetTempPath(MAX_PATH,tmpName);
  if (GetStdHandle(STD_ERROR_HANDLE) == INVALID_HANDLE_VALUE) {
    GetTempFileName(tmpName,TEXT("sq"),0,stderrName);
    _tfreopen(stderrName, TEXT("w+t"), stderr);
  }
  if (GetStdHandle(STD_OUTPUT_HANDLE) == INVALID_HANDLE_VALUE) {
    GetTempFileName(tmpName,TEXT("sq"),0,stdoutName);
    _tfreopen(stdoutName,TEXT("w+t"), stdout);
  }
}

/****************************************************************************/
/*                      Release                                             */
/****************************************************************************/

static void
dumpStackIfInMainThread(FILE *optionalFile)
{
  extern void printCallStack(void);

  if (!optionalFile) {
    if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
      printf("\n\nSmalltalk stack dump:\n");
      printCallStack();
    }
    else
      printf("\nCan't dump Smalltalk stack. Not in VM thread\n");
    return;
  }
  if (ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())) {
    FILE tmpStdout = *stdout;
    fprintf(optionalFile, "\n\nSmalltalk stack dump:\n");
    *stdout = *optionalFile;
    printCallStack();
    *optionalFile = *stdout;
    *stdout = tmpStdout;
    fprintf(optionalFile,"\n");
  }
  else
    fprintf(optionalFile,"\nCan't dump Smalltalk stack. Not in VM thread\n");
}

#if STACKVM
static void
dumpPrimTrace(FILE *optionalFile)
{
  extern void dumpPrimTraceLog(void);

  if (optionalFile) {
    FILE tmpStdout = *stdout;
    *stdout = *optionalFile;
    dumpPrimTrace(0);
    *optionalFile = *stdout;
    *stdout = tmpStdout;
  } else {
    printf("\nPrimitive trace:\n");
    dumpPrimTraceLog();
    printf("\n");
  }
}
#else
# define dumpPrimTrace(f) 0
#endif

void
printCommonCrashDumpInfo(FILE *f) {
#if STACKVM
extern char *__interpBuildInfo;
# if COGVM
extern char *__cogitBuildInfo;
# endif
#endif

  fprintf(f,"\n\n%s", hwInfoString);
  fprintf(f,"\n%s", osInfoString);
  fprintf(f,"\n%s", gdInfoString);

  /* print VM version information */
  fprintf(f,"\nVM Version: %s\n", VM_VERSION_TEXT);
#if STACKVM
  fprintf(f,"Interpreter Build: %s\n", __interpBuildInfo);
# if COGVM
  fprintf(f,"Cogit Build: %s\n", __cogitBuildInfo);
# endif
#endif
  fprintf(f,"Source Version: %s\n", sourceVersionString('\n'));
  fflush(f);
  fprintf(f,"\n"
    "Current byte code: %d\n"
    "Primitive index: %" PRIdSQINT "\n",
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

  printModuleInfo(f);
  fflush(f);
}

#define MAXFRAMES 64

/* Print an error message, possibly Smalltalk and C stack traces, and exit. */
/* Disable Intel compiler inlining of error which is used for breakpoints */
#pragma auto_inline(off)
static int inError = 0;

void
error(char *msg) {
  FILE *f;
  TCHAR crashInfo[1024];
  void *callstack[MAXFRAMES];
  symbolic_pc symbolic_pcs[MAXFRAMES];
  int nframes;
  int inVMThread = ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread());

  if (inError) {
    exit(-2);
  }

  inError = 1;
  nframes = backtrace(callstack, MAXFRAMES);
  symbolic_backtrace(++nframes, callstack, symbolic_pcs);

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
#if defined(UNICODE)
     vmLogDirW,
#else
     vmLogDirUTF8,
#endif
     TEXT("crash.dmp"));
  if (!fHeadlessImage)
    MessageBox(stWindow,crashInfo,TEXT("Fatal VM error"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);

#if !NewspeakVM
  if (wcslen(vmLogDirW) > MAX_PATH) {
    MessageBox(stWindow, 
      TEXT("Cannot change current directory to the VM log dir,")
        TEXT(" its path is too long.") 
        TEXT("The crash.dmp will be written to the current directory."),
      TEXT("Fatal VM error"),
      MB_OK | MB_APPLMODAL | MB_ICONSTOP);
  } else {
    SetCurrentDirectoryW(vmLogDirW);
  }
#endif
  /* print the above information */
  f = fopen_for_append("crash.dmp");
  if (f) {
    time_t crashTime = time(NULL);
    fprintf(f,"---------------------------------------------------------------------\n");
    fprintf(f,"%s %s\n\n", ctime(&crashTime), GetAttributeString(0));

    fprintf(f,
        "Error in %s thread\nReason: %s\n\n",
        inVMThread ? "the VM" : "some other",
        msg);
    printCommonCrashDumpInfo(f);
    dumpPrimTrace(f);
    fflush(f);
    print_backtrace(f, nframes, MAXFRAMES, callstack, symbolic_pcs);
    fflush(f);
    dumpStackIfInMainThread(f);
    fflush(f);
    fclose(f);
  }
  printf("Error in %s thread\nReason: %s\n\n",
      inVMThread ? "the VM" : "some other",
      msg);
  dumpPrimTrace(0);
  print_backtrace(stdout, nframes, MAXFRAMES, callstack, symbolic_pcs);
  /* /Don't/ print the caller's stack to stdout here; Cleanup will do so. */
  /* dumpStackIfInMainThread(0); */
  exit(-1);
}

static int inCleanExit = 0; /* to suppress stack trace in Cleanup */

sqInt ioExit(void)
{
  return ioExitWithErrorCode(0);
}

sqInt
ioExitWithErrorCode(int ec)
{
#if COGVM
extern sqInt reportStackHeadroom;
  if (reportStackHeadroom)
    reportMinimumUnusedHeadroom();
#endif
  printPhaseTime(3);
  inCleanExit = 1;
  exit(ec);
  return ec;
}

#pragma auto_inline(on)

static void
printCrashDebugInformation(LPEXCEPTION_POINTERS exp)
{
  void *callstack[MAXFRAMES];
  symbolic_pc symbolic_pcs[MAXFRAMES];
  int nframes, inVMThread;
  TCHAR crashInfo[1024];
  FILE *f;
  int byteCode = -2;

  UninstallExceptionHandler();

  if ((inVMThread = ioOSThreadsEqual(ioCurrentOSThread(),getVMOSThread())))
    /* Retrieve current byte code.
     If this fails the IP is probably wrong */
    TRY {
      byteCode = getCurrentBytecode();
    } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
      byteCode = -1;
    }


  TRY {
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
  if (inVMThread)
  ifValidWriteBackStackPointersSaveTo((void *)exp->ContextRecord->Ebp,
                    (void *)exp->ContextRecord->Esp,
                    0,
                    0);
  callstack[0] = (void *)exp->ContextRecord->Eip;
  nframes = backtrace_from_fp((void*)exp->ContextRecord->Ebp,
              callstack+1,
              MAXFRAMES-1);
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
  if (inVMThread)
  ifValidWriteBackStackPointersSaveTo((void *)exp->ContextRecord->Rbp,
                    (void *)exp->ContextRecord->Rsp,
                    0,
                    0);
  callstack[0] = (void *)exp->ContextRecord->Rip;
  nframes = backtrace_from_fp((void*)exp->ContextRecord->Rbp,
              callstack+1,
              MAXFRAMES-1);
#else
#error "unknown architecture, cannot dump stack"
#endif
  symbolic_backtrace(++nframes, callstack, symbolic_pcs);
  wsprintf(crashInfo,
    TEXT("Sorry but the VM has crashed.\n\n")
    TEXT("Exception code: %08X\n")
    TEXT("Exception address: %08X\n")
    TEXT("Current byte code: %d\n")
    TEXT("Primitive index: %d\n\n")
    TEXT("Crashed in %s thread\n\n")
    TEXT("This information will be stored in the file\n")
    TEXT("%s\\%s\n")
    TEXT("with a complete stack dump"),
    exp->ExceptionRecord->ExceptionCode,
    exp->ExceptionRecord->ExceptionAddress,
    byteCode,
    methodPrimitiveIndex(),
    inVMThread ? "the VM" : "some other",
#if defined(UNICODE)
    vmLogDirW,
#else
    vmLogDirUTF8,
#endif
    TEXT("crash.dmp"));
  if (!fHeadlessImage)
    MessageBox(stWindow,crashInfo,TEXT("Fatal VM error"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);

#if !NewspeakVM
  if (wcslen(vmLogDirW) > MAX_PATH) {
   MessageBox(stWindow, 
     TEXT("Cannot change current directory to the VM log dir,")
       TEXT(" its path is too long.") 
       TEXT("The crash.dmp will be written to the current directory."),
     TEXT("Fatal VM error"),
     MB_OK | MB_APPLMODAL | MB_ICONSTOP);
  } else {
    SetCurrentDirectoryW(vmLogDirW);
  }
#endif
  /* print the above information */
  f = fopen_for_append("crash.dmp");
  if (f) {
    time_t crashTime = time(NULL);
    fprintf(f,"---------------------------------------------------------------------\n");
    fprintf(f,"%s\n", ctime(&crashTime));
    /* Print the exception code */
    fprintf(f,"Exception code: %08lX\nException addr: %0*" PRIXSQPTR "\n",
      exp->ExceptionRecord->ExceptionCode,
      (int) sizeof(exp->ExceptionRecord->ExceptionAddress)*2,
      (usqIntptr_t) exp->ExceptionRecord->ExceptionAddress);
    if (exp->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION) {
      /* For access violations print what actually happened */
      fprintf(f,"Access violation (%s) at %0*" PRIXSQPTR "\n",
        (exp->ExceptionRecord->ExceptionInformation[0] ? "write access" : "read access"),
        (int) sizeof(exp->ExceptionRecord->ExceptionInformation[1])*2,
        exp->ExceptionRecord->ExceptionInformation[1]);
    }
#if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
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
#elif defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
    fprintf(f,"RAX:%016" PRIxSQPTR "\tRBX:%016" PRIxSQPTR "\tRCX:%016" PRIxSQPTR "\tRDX:%016" PRIxSQPTR "\n",
      exp->ContextRecord->Rax,
      exp->ContextRecord->Rbx,
      exp->ContextRecord->Rcx,
      exp->ContextRecord->Rdx);
    fprintf(f,"RSI:%016" PRIxSQPTR "\tRDI:%016" PRIxSQPTR "\tRBP:%016" PRIxSQPTR "\tRSP:%016" PRIxSQPTR "\n",
      exp->ContextRecord->Rsi,
      exp->ContextRecord->Rdi,
      exp->ContextRecord->Rbp,
      exp->ContextRecord->Rsp);
    fprintf(f,"R8 :%016" PRIxSQPTR "\tR9 :%016" PRIxSQPTR "\tR10:%016" PRIxSQPTR "\tR11:%016" PRIxSQPTR "\n",
      exp->ContextRecord->R8,
      exp->ContextRecord->R9,
      exp->ContextRecord->R10,
      exp->ContextRecord->R11);
    fprintf(f,"R12:%016" PRIxSQPTR "\tR13:%016" PRIxSQPTR "\tR14:%016" PRIxSQPTR "\tR14:%015" PRIxSQPTR "\n",
      exp->ContextRecord->R12,
      exp->ContextRecord->R13,
      exp->ContextRecord->R14,
      exp->ContextRecord->R15);
    fprintf(f,"RIP:%016" PRIxSQPTR "\tEFL:%08lx\n",
      exp->ContextRecord->Rip,
      exp->ContextRecord->EFlags);
    fprintf(f,"FP Control: %08x\nFP Status:  %08x\nFP Tag:     %08x\n",
      exp->ContextRecord->FltSave.ControlWord,
      exp->ContextRecord->FltSave.StatusWord,
      exp->ContextRecord->FltSave.TagWord);
#else
#error "unknown architecture, cannot pick dump registers"
#endif

    fprintf(f, "\n\nCrashed in %s thread\n\n", inVMThread ? "the VM" : "some other");

    printCommonCrashDumpInfo(f);
    dumpPrimTrace(f);
    print_backtrace(f, nframes, MAXFRAMES, callstack, symbolic_pcs);
    dumpStackIfInMainThread(f);
    fclose(f);
  }

  /* print recently called prims to stdout */
  dumpPrimTrace(0);
  /* print C stack to stdout */
  print_backtrace(stdout, nframes, MAXFRAMES, callstack, symbolic_pcs);
  /* print the caller's stack to stdout */
  dumpStackIfInMainThread(0);
#if COGVM
  reportMinimumUnusedHeadroom();
#endif

  } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
    /* that's too bad ... */
    if (!fHeadlessImage)
      MessageBox(0,TEXT("The VM has crashed. Sorry."),TEXT("Fatal error:"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);
    else
      abortMessage(TEXT("The VM has crashed. Sorry."));
  }
}

void __cdecl Cleanup(void)
{
  /* not all of these are essential, but they're polite... */

  if (!inCleanExit) {
    dumpStackIfInMainThread(0);
  }
  ioShutdownAllModules();
#ifndef NO_PLUGIN_SUPPORT
  pluginExit();
#endif
  ioReleaseTime();
  /* tricky ... we have no systray icon when running
     headfull or when running as service on NT */
  if (fHeadlessImage && (!fRunService || fWindows95))
    SetSystemTrayIcon(0);
  if (palette) DeleteObject(palette);
  PROFILE_SHOW(ticksForReversal);
  PROFILE_SHOW(ticksForBlitting);
  if (*stderrName) {
    fclose(stderr);
    _tremove(stderrName);
  }
  if (*stdoutName) {
    fclose(stdout);
    _tremove(stdoutName);
  }
  free(vmLogDirUTF8);
  vmLogDirUTF8 = NULL;
  free(vmLogDirW);
  vmLogDirW = NULL;
  free(installServiceName);
  installServiceName = NULL;
  free(logName);
  logName = NULL;
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
  char* vmNameUTF8 = NULL;

  {
#if defined(UNICODE)
    int sz = WideCharToMultiByte(CP_UTF8, 0, vmName, -1, NULL, 0, NULL, NULL);
    RECALLOC_OR_RESET(vmNameUTF8, sz + 1, sizeof(char), return 0);
    WideCharToMultiByte(CP_UTF8, 0, vmName, -1, vmNameUTF8, sz, NULL, NULL);
#else
    char* vmNameUTF8 = vmName;
#endif
    f = sqImageFileOpen(vmNameUTF8, "rb");
  }

  f = sqImageFileOpen(vmName, "rb");
  if (!f) {
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
  if (magic != SQ_IMAGE_MAGIC || start < 0 || start >= endMarker) {
    /* nope */
    sqImageFileClose(f);
    return 0;
  }
  /* Might have an embedded image; seek back and double check */
  sqImageFileSeek(f,start);
  sqImageFileRead(&magic, 1, 4, f);
  sqMessageBox(MB_OK, "Magic number", "Expected:\t%x\nFound:\t\t%x", SQ_IMAGE_MAGIC, magic);
  if (magic != SQ_IMAGE_MAGIC) {
    /* nope */
    sqImageFileClose(f);
    return 0;
  }
  /* now triple check for image format */
  sqImageFileRead(&magic, 1, 4, f);
  if (!readableFormat(magic) && !readableFormat(byteSwapped(magic))) {
    /* nope */
    sqImageFileClose(f);
    return 0;
  }
  /* Gotcha! */
  sqImageFileSeek(f, sqImageFilePosition(f) - 4);
  strncpy(imageName, vmNameUTF8, IMAGE_NAME_SIZE);
  imageSize = endMarker - sqImageFilePosition(f);
  return f;
}
#else
int findEmbeddedImage(void) { return 0; }
#endif


/****************************************************************************/
/*                        sqMain                                            */
/****************************************************************************/
#if (STACKVM || NewspeakVM) && !COGVM
extern sqInt sendTrace;
#endif
#if STACKVM || NewspeakVM
extern sqInt checkForLeaks;
#endif /* STACKVM || NewspeakVM */
#if STACKVM
extern sqInt desiredNumStackPages;
extern sqInt desiredEdenBytes;
extern sqInt suppressHeartbeatFlag;
#endif /* STACKVM */
#if COGVM
extern sqInt desiredCogCodeSize;
extern int traceFlags;
extern sqInt traceStores;
extern usqIntptr_t debugPrimCallStackOffset;
extern sqInt maxLiteralCountForCompile;
extern sqInt minBackwardJumpCountForCompile;
#endif /* COGVM */


/* sqMain: 
  This is common entry point regardless of whether we're running as a normal
  app or as a service. Note that a number of things may have been set up
  before coming here. In particular,
    * fRunService - to determine whether we're running as NT service
  However, the command line must always contain all parameters necessary.
  In other words, even though the logName may have been set before,
  the command line has to include the -log switch.
*/
static int parseArguments(int argc, char *argv[]);

int
sqMain(int argc, char *argv[])
{
  int virtualMemory;

  /* set default fpu control word */
  _control87(FPU_DEFAULT, _MCW_EM | _MCW_RC | _MCW_PC | _MCW_IC);

  LoadPreferences();

  /* If running as single app, find the previous instance */
  if (fRunSingleApp) {
    HWND win = GetTopWindow(0);
    while (win != NULL) {
      /* Class name maximum is 256, see lpszClassName in
      https://msdn.microsoft.com/en-us/library/ms633577
      */
      TCHAR buf[256] = { 0 };
      GetClassName(win, buf, 256);
      if (lstrcmp(windowClassName, buf) == 0) {
        break;
      }
      win = GetNextWindow(win, GW_HWNDNEXT);
    }

    if (win) {
      WCHAR *cmdLineW = GetCommandLineW();
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

      if (IsIconic(win)) ShowWindow(win, SW_RESTORE);
      SetForegroundWindow(win);
      SetActiveWindow(win);
      return PostMessage(win, SQ_LAUNCH_DROP, 0, 0);
    }
  }

  /* parse command line args */
  if (!parseArguments(argc, argv)) {
    return printUsage(1);
  }

  /* a quick check if we have any argument at all */
  if (!fRunService && (*imageName == 0)) {
    /* Check if the image is embedded */
    imageFile = findEmbeddedImage();
    if (!imageFile) {
      /* Search the current directory if there's a single image file */
      if (!findImageFile()) {
        /* Nope. Give the user a chance to open an image interactively */
        if (!openImageFile()) return -1; /* User cancelled file open */
      }
    }
  }

#ifdef NO_SERVICE
  fRunService = 0;
#endif

  /* look for a few things easy to handle */
  if (fWindows95 && fBroadcastService95) {
    PostMessage(HWND_BROADCAST, WM_BROADCAST_SERVICE, 0, 0);
    return 0;
  }

  /* set time zone accordingly */
  _tzset();


  /* Initialize OLE library so we don't have to do it from other places */
  OleInitialize(NULL);

  /* Give us some log information when running as service */
  if (fRunService) {
    char* uInitialCmdLine = NULL;
    time_t svcStart = time(NULL);

    OutputLogMessage("\n\n");
    OutputLogMessage(ctime(&svcStart));
    if (fWindows95) {
      /* don't have a service name */
      OutputLogMessage("The service");
    } else {
      char* uServiceName = NULL;
      TCHAR_TO_UTF8(serviceName, uServiceName);
      OutputLogMessage(uServiceName);
    }
    OutputLogMessage(" started with the following command line\n");
    TCHAR_TO_UTF8(initialCmdLine, uInitialCmdLine);
    OutputLogMessage(uInitialCmdLine);
    OutputLogMessage("\n");
  }

  SetupFilesAndPath();
  {
    char* vmPathUTF8 = NULL;
    TCHAR_TO_UTF8(vmPath, vmPathUTF8);
    int cbVmPathUTF8 = strnlen(vmPathUTF8, MAX_PATH_SQUEAK);
    ioSetLogDirectoryOfSize(vmPathUTF8, cbVmPathUTF8);
  }

  /* release resources on exit */
  atexit(Cleanup);

#ifndef NO_SERVICE
  /* if service installing is requested, do so */
  if (installServiceName && *installServiceName) {
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
  {
    extern void ioInitTime(void);
    extern void ioInitThreads(void);
    ioInitTime();
    ioInitThreads();
# if !COGMTVM
    /* Set the current VM thread.  If the main thread isn't the VM thread then
     * when that thread is spawned it can reassign ioVMThread.
     */
    ioVMThread = ioCurrentOSThread();
# endif
  }

  /* check the interpreter's size assumptions for basic data types */
  if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
  if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");
  if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
#if 0
  if (sizeof(time_t) != 4) error("This C compiler's time_t's are not 32 bits.");
#endif


  if (!imageFile) {
    imageSize = SqueakImageLength(imageName);
    if (imageSize == 0) printUsage(2);
  }

  /* allocate this before anything is going to happen */
  vmWakeUpEvent = CreateEvent(NULL, 1, 0, NULL);

#ifdef NO_VIRTUAL_MEMORY
  if (!dwMemorySize) {
    dwMemorySize = 4;
    virtualMemory = (int)imageSize + max(imageSize, dwMemorySize * 0x00100000);
  } else {
    virtualMemory = (int)dwMemorySize * 0x00100000;
  }
#else
  /* initial commit size = imageSize + 4MB */
  virtualMemory = imageSize + 0x00400000;
#endif

#if !NO_FIRST_LEVEL_EXCEPTION_HANDLER
# ifndef _MSC_VER
  /* Install our top-level exception handler */
  InstallExceptionHandler();
# else
  __try {
# endif
#endif /* !NO_FIRST_LEVEL_EXCEPTION_HANDLER */

#if !NewspeakVM
    /* set the CWD to the image location */
    if (*imageName) {
      /* use wide version explicitely */
      WCHAR* win32Path = NULL;
      WCHAR* ptr = NULL;
      ALLOC_WIN32_PATH(win32Path, imageName,
                       strnlen(imageName, IMAGE_NAME_SIZE), win32Path = L"");
      ptr = wcsrchr(win32Path, L'\\');
      if (ptr) {
        *ptr = 0;
        if (wcslen(win32Path) > MAX_PATH) {
          if (!fRunService) {
            MessageBox(stWindow,
                       TEXT("Cannot change current directory to the image dir,")
                         TEXT(" its path is too long."),
                       TEXT("VM error"), MB_OK | MB_APPLMODAL | MB_ICONSTOP);
          }
        } else {
          SetCurrentDirectoryW(win32Path);
        }
      }
    }
#endif /* !NewspeakVM */

    /* display the splash screen */
    ShowSplashScreen();

    /* if headless running is requested, try to to create an icon
       in the Win95/NT system tray */
    if (fHeadlessImage && (!fRunService || fWindows95))
      SetSystemTrayIcon(1);
    
    /* read the image file */
    if (!imageFile) {
      imageFile = sqImageFileOpen(imageName,"rb");
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, 0);
    } else {
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, sqImageFilePosition(imageFile));
    }
    sqImageFileClose(imageFile);

    if (fHeadlessImage) HideSplashScreen(); /* need to do it manually */
    SetWindowSize();
    ioSetFullScreen(getFullScreenFlag());

    /* run Squeak */
    ioInitSecurity();
  printPhaseTime(2);
    interpret();
#if !NO_FIRST_LEVEL_EXCEPTION_HANDLER
# ifdef _MSC_VER
  } __except (squeakExceptionHandler(GetExceptionInformation())) {
    /* Do nothing */
  }
# else
  /* remove the top-level exception handler */
  UninstallExceptionHandler();
# endif
#endif /* !NO_FIRST_LEVEL_EXCEPTION_HANDLER */
  return 1;
}

/****************************************************************************/
/*                        WinMain                                           */
/****************************************************************************/

#ifdef _MSC_VER
/* use main also for gui startup. See
  http://stackoverflow.com/a/11785733

*/
#  if defined(UNICODE)
#pragma comment(linker, "/subsystem:windows /ENTRY:wmainCRTStartup")
#  else
#pragma comment(linker, "/subsystem:windows /ENTRY:mainCRTStartup")
#  endif
#endif

int _tmain(int argc, TCHAR* argv[], TCHAR* envp[])
{

  /* The arguments of the GUI WinMain are
  WinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
  or
  _tWinMain(HINSTANCE hInst, HINSTANCE hPrevInstance, LPTSTR lpCmdLine, int nCmdShow)
  But we can get them nevertheless:
    http://stackoverflow.com/a/11785228 / 
    https://msdn.microsoft.com/en-us/library/windows/desktop/ms683199.aspx
  */
  const HINSTANCE hInst = GetModuleHandle(NULL);
  /* unused in Squeak: const HINSTANCE hPrevInstance = NULL; */
  LPTSTR lpCmdLine = GetCommandLine();
  /* unused in Squeak: int nCmdShow = .. (see http://stackoverflow.com/a/25250854) */
  DWORD mode;

  /* a few things which need to be done first */
  gatherSystemInfo();

  /* check if we're running NT or 95 */
  fWindows95 = (GetVersion() & 0x80000000) != 0;
  /* Determine if we're running as a console application  We can't report
   * allocation failures unless running as a console app because doing so
   * via a MessageBox will make the system unusable.
   */
  fIsConsole = GetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), &mode);

  /* fetch us a copy of the command line */
  initialCmdLine = _tcsdup(lpCmdLine);

  /* fetch us the name of the executable */
  {
    DWORD copied = 0;
    DWORD size = 0;
    do {
      size += MAX_PATH;
      RECALLOC_OR_RESET(vmName, size, sizeof(TCHAR), return 1);
      copied = GetModuleFileName(hInst, vmName, size);
    } while (copied >= size);
  }
  /* parse the command line into the unix-style argc, argv, converting to
   * UTF-8 on the way. */
  {
    LPWSTR *argList = CommandLineToArgvW(GetCommandLineW(), &clargc);
    int i;

    clargv = calloc(clargc + 1, sizeof(char *));
    vmOptions = calloc(clargc + 1, sizeof(char *));
    imageOptions = calloc(clargc + 1, sizeof(char *));
    if (!clargv || !vmOptions || !imageOptions) {
      fprintf(stderr,"out of memory for command line?!\n");
      return 1;
    }
    for (i = 0; i < clargc; i++) {
      int n = WideCharToMultiByte(CP_UTF8, 0, argList[i], -1, NULL, 0, NULL, NULL);
      if (!(clargv[i] = malloc(n))) {
        fprintf(stderr,"out of memory for command line?!\n");
        return 1;
      }
      WideCharToMultiByte(CP_UTF8, 0, argList[i], -1, clargv[i], n, NULL, NULL);
    }
    LocalFree(argList);
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
  if (!fWindows95 &&         /* 1) running NT */
      !*lpCmdLine &&         /* 2) No command line */
      sqServiceMain())       /* try starting the service */
    return 0;                /* service was run - exit */

#endif

  SQ_LAUNCH_DROP = RegisterWindowMessage(TEXT("SQUEAK_LAUNCH_DROP"));

  /* Special startup stuff for windows 95 */
  if (fWindows95) {
    /* The message we use for notifying services of user logon */
    WM_BROADCAST_SERVICE = RegisterWindowMessage(msgBroadcastService);
  }

  /* start the non-service version */
  sqMain(clargc, clargv);
  return 0;
}

static sqIntptr_t  
strtobkm(const char *str)  
{
  char *suffix;
#if SQ_HOST64
  sqIntptr_t value = strtoll(str, &suffix, 10);
#else
  sqIntptr_t value = strtol(str, &suffix, 10);
#endif
  switch (*suffix) {
  case 'k': case 'K': value *= 1024; break;
  case 'm': case 'M': value *= 1024*1024; break;
  }
  return value;
}

static int
parseVMArgument(int argc, char *argv[])
{
  /* flags */
       if (!strcmp(argv[0], "-help"))       { printUsage(1); return 1; }
  else if (!strcmp(argv[0], "-version"))    { versionInfo();  return 1; }
  else if (!strcmp(argv[0], "-headless"))   { fHeadlessImage = true; return 1; }
  else if (!strcmp(argv[0], "-headfull"))   { fHeadlessImage = false; return 1;}
  else if (!strcmp(argv[0], "-timephases")) { printPhaseTime(1); return 1; }
#ifdef  VISTA_SECURITY 
  /* IE7/Vista protected mode support */
  /* started with low rights, use alternate untrustedUserDirectory */
  else if (!strcmp(argv[0], "-lowRights"))  { fLowRights = true; return 1; }
#endif /* VISTA_SECURITY */
#if (STACKVM || NewspeakVM) && !COGVM
  else if (!strcmp(argv[0], "-sendtrace"))  { extern sqInt sendTrace; sendTrace = 1; return 1; }
#endif

  /* parameters (in UTF8) */
  else if (argc > 1 && !strcmp(argv[0], "-service")) {
    TCHAR* tmp = NULL;
    UTF8_TO_TCHAR(argv[1], tmp);
    installServiceName = _tcsdup(tmp);
    return 2;
  }
  else if (!strncmp(argv[0], "-service:", 9)) {
    TCHAR* tmp = NULL;
    UTF8_TO_TCHAR(argv[0] + 9, tmp);
    installServiceName = _tcsdup(tmp);
    return 1;
  }
  else if (argc > 1 && !strcmp(argv[0], "-log")) {
    TCHAR* tmp = NULL;
    UTF8_TO_TCHAR(argv[1], tmp);
    logName = _tcsdup(tmp);
  }
  else if (!strncmp(argv[0], "-log:", 5)) {
    TCHAR* tmp = NULL;
    UTF8_TO_TCHAR(argv[0] + 5, tmp);
    logName = _tcsdup(tmp);
    return 1;
  }
  else if (argc > 1 && !strcmp(argv[0], "-memory")) {
    dwMemorySize = strtobkm(argv[1]);
    return 2;
  }
  else if (!strncmp(argv[0], "-memory:", 8)) {
    dwMemorySize = strtobkm(argv[0] + 8);
    return 1;
  }
#if STACKVM || NewspeakVM
  else if (argc > 1 && !strcmp(argv[0], "-breaksel")) {
    extern void setBreakSelector(char *);
    setBreakSelector(argv[1]);
    return 2; }
  else if (!strncmp(argv[0], "-breaksel:", 10)) {
    extern void setBreakSelector(char *);
    setBreakSelector(argv[0] + 10);
    return 1; }
  else if (argc > 1 && !strcmp(argv[0], "-numextsems")) {
    ioSetMaxExtSemTableSize(atoi(argv[1]));
    return 2; }
  else if (!strncmp(argv[0], "-numextsems:", 12)) {
    ioSetMaxExtSemTableSize(atoi(argv[1]+12));
    return 1; }
#endif /* STACKVM || NewspeakVM */
#if STACKVM
      else if (!strcmp(argv[0], "-breakmnu")) {
    extern void setBreakMNUSelector(char *);
    setBreakMNUSelector(argv[1]);
    return 2; }
  else if (!strncmp(argv[0], "-breakmnu:", 10)) {
    extern void setBreakMNUSelector(char *);
    setBreakMNUSelector(argv[0] + 10);
    return 1; }
  else if (argc > 1 && !strcmp(argv[0], "-eden")) {
    extern sqInt desiredEdenBytes;
    desiredEdenBytes = strtobkm(argv[1]);   
    return 2; }
  else if (!strncmp(argv[0], "-eden:", 6)) {
    extern sqInt desiredEdenBytes;
    desiredEdenBytes = strtobkm(argv[0]+6);   
    return 2; }
  else if (argc > 1 && !strcmp(argv[0], "-leakcheck")) {
    extern sqInt checkForLeaks;
    checkForLeaks = atoi(argv[1]);   
    return 2; }
  else if (!strncmp(argv[0], "-leakcheck:", 11)) {
    extern sqInt checkForLeaks;
    checkForLeaks = atoi(argv[0]+11);   
    return 2; }
  else if (argc > 1 && !strcmp(argv[0], "-stackpages")) {
    extern sqInt desiredNumStackPages;
    desiredNumStackPages = atoi(argv[1]);   
    return 2; }
  else if (!strncmp(argv[0], "-stackpages:", 12)) {
    extern sqInt desiredNumStackPages;
    desiredNumStackPages = atoi(argv[0]+12);   
    return 2; }
  else if (!strcmp(argv[0], "-checkpluginwrites")) {
    extern sqInt checkAllocFiller;
    checkAllocFiller = 1;
    return 1; }
  else if (!strcmp(argv[0], "-noheartbeat")) {
    extern sqInt suppressHeartbeatFlag;
    suppressHeartbeatFlag = 1;
    return 1; }
  else if (!strcmp(argv[0], "-warnpid")) {
    extern sqInt warnpid;
    warnpid = _getpid();
    return 1; }
#endif /* STACKVM */
#if COGVM
  else if (!strcmp(argv[0], "-codesize")) {
    extern sqInt desiredCogCodeSize;
    desiredCogCodeSize = strtobkm(argv[1]);   
    return 2; }
# define TLSLEN (sizeof("-trace")-1)
  else if (!strncmp(argv[0], "-trace", TLSLEN)) {
    extern int traceFlags;
    char *equalsPos = strchr(argv[0],'=');

    if (!equalsPos) {
      traceFlags = 1;
      return 1;
    }
    if (equalsPos - argv[0] != TLSLEN
      || (equalsPos[1] != '-' && !isdigit(equalsPos[1])))
      return 0;

    traceFlags = atoi(equalsPos + 1);
    return 1; }
  else if (!strcmp(argv[0], "-tracestores")) {
    extern sqInt traceStores;
    traceStores = 1;
    return 1; }
  else if (!strcmp(argv[0], "-dpcso")) {
    extern usqIntptr_t debugPrimCallStackOffset;
    debugPrimCallStackOffset = (usqIntptr_t) strtobkm(argv[1]);   
    return 2; }
  else if (argc > 1 && !strcmp(argv[0], "-cogmaxlits")) {
    extern sqInt maxLiteralCountForCompile;
    maxLiteralCountForCompile = strtobkm(argv[1]);   
    return 2; }
  else if (!strncmp(argv[0], "-cogmaxlits:", 12)) {
    extern sqInt maxLiteralCountForCompile;
    maxLiteralCountForCompile = strtobkm(argv[0]+12); 
    return 2; }
  else if (argc > 1 && !strcmp(argv[0], "-cogminjumps")) {
    extern sqInt minBackwardJumpCountForCompile;
    minBackwardJumpCountForCompile = strtobkm(argv[1]); 
    return 2; }
  else if (!strncmp(argv[0], "-cogminjumps:",13)) {
    extern sqInt minBackwardJumpCountForCompile;
    minBackwardJumpCountForCompile = strtobkm(argv[0]+13); 
    return 2; }
    else if (!strcmp(argv[0], "-reportheadroom")
          || !strcmp(argv[0], "-rh")) {
    extern sqInt reportStackHeadroom;
    reportStackHeadroom = 1;
    return 1; }
#endif /* COGVM */
#if SPURVM
    else if (!strcmp(argv[0], "-maxoldspace")) { 
		extern usqInt maxOldSpaceSize;
		maxOldSpaceSize = (usqInt) strtobkm(argv[1]);	 
		return 2; }
    else if (!strncmp(argv[0], "-maxoldspace:", 13)) { 
		maxOldSpaceSize = (usqInt) strtobkm(argv[0]+13);	 
		return 2; }
#endif

  /* NOTE: the following flags are "undocumented" */
  else if (argc > 1 && !strcmp(argv[0], "-browserWindow")) {
#if SQ_HOST32
    browserWindow = (HWND)atoi(argv[1]);
#else
    browserWindow = (HWND)atoll(argv[1]);
#endif
    return 2; }
  else if (!strncmp(argv[0], "-browserWindow:", 15)) {
#if SQ_HOST32
    browserWindow = (HWND)atoi(argv[0]+15);
#else
    browserWindow = (HWND)atoll(argv[0]+15);
#endif
    return 1; }

  /* service support on 95 */
  else if (!strcmp(argv[0], "-service95"))   { fRunService = true; return 1; }
  else if (!strcmp(argv[0], "-broadcast95")) { fBroadcastService95 = true; return 1; }

  return 0;  /* option not recognised */
}

/* parse all arguments meaningful to the VM; answer index of last VM arg + 1 */
static int
parseVMArgs(int argc, char *argv[])
{
  int n, i = 0, j;

  while (++i < argc && *argv[i] == '-' && strcmp(argv[i],"--")) {
        if ((n = parseVMArgument(argc - i, argv + i))) {
      for (j = 0; j < n; j++)
        vmOptions[numOptionsVM++] = argv[i+j];
      i += n - 1;
    }
    else {
          fprintf(stderr,"Unknown option encountered!\n");
          return i;
    }
  }
  return i;
}

static int
IsImage(char *name)
{
  int magic;
  extern sqInt byteSwapped(sqInt);
  sqImageFile fp;

  fp = sqImageFileOpen(name,"rb");
  if (!fp) return 0; /* not an image */
  if (sqImageFileRead(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
    sqImageFileClose(fp);
    return 0;
  }
  if (readableFormat(magic) || readableFormat(byteSwapped(magic))) {
    sqImageFileClose(fp);
    return true;
  }

  /* no luck at beginning of file, seek to 512 and try again */
  sqImageFileSeek( fp, 512);
  if (sqImageFileRead(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
    sqImageFileClose(fp);
    return 0;
  }
  sqImageFileClose(fp);
  return readableFormat(magic) || readableFormat(byteSwapped(magic));
}

/*
 * Answer exe's SUBSYSTEM type.  From http://support.microsoft.com/kb/90493.
 */
static int
SubsystemType()
{
  HANDLE hImage = NULL;
  DWORD  bytes = 0L;
  ULONG  ntSignature = 0L;
  IMAGE_DOS_HEADER      image_dos_header = { 0 };
  IMAGE_OPTIONAL_HEADER image_optional_header = { 0 };
  int result = 0;

  /* Ensure that we close the handle when we determine an error
     during subsystem detection. (Attention: uses goto.)
     */
#define FAIL_SUBSYSEM(err_code) {\
  result = err_code; \
  goto subsystem_finally;\
}

  {
    WCHAR* wVmName = NULL;
#if defined(UNICODE)
    int sz = lstrlen(vmPath);
    if (sz >= MAX_PATH - 12) {// see ALLOC_WIN32_PATH
      wVmName = (WCHAR*) alloca((sz + 4 + 1) * sizeof(WCHAR));
      wcscpy(wVmName, L"\\\\?\\");
      wcscat(wVmName, vmName);
    } else {
      wVmName = vmName;
    }
#else
    int sz = MultiByteToWideChar(CP_ACP, 0, vmName, -1, NULL, 0);
    if (sz >= MAX_PATH - 12) {
      wVmName = (WCHAR*) alloca((sz + 4 + 1) * sizeof(WCHAR));
      wVmName[0] = L'\\'; wVmName[1] = L'\\'; wVmName[2] = L'?'; wVmName[3] = L'\\';
      MultiByteToWideChar(CP_ACP, 0, vmName, -1, wVmName + 4, sz);
      wVmName[sz + 4] = 0;
    } else {
      wVmName = (WCHAR*) alloca((sz + 1) * sizeof(WCHAR));
      MultiByteToWideChar(CP_ACP, 0, vmName, -1, wVmName, sz);
      wVmName[sz] = 0;
    }
#endif
    /* Open the reference file. */ 
    hImage = CreateFileW(wVmName,
                        GENERIC_READ,
                        FILE_SHARE_READ,
                        NULL,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL);

  }

  if (INVALID_HANDLE_VALUE == hImage) {
    FAIL_SUBSYSEM(-1);
  }

  /* Read the MS-DOS image header. */ 
  if (!ReadFile(hImage, &image_dos_header, sizeof(IMAGE_DOS_HEADER), &bytes, 0)
      || bytes != sizeof(IMAGE_DOS_HEADER)) {
    FAIL_SUBSYSEM(-2);
  }

  if (image_dos_header.e_magic != IMAGE_DOS_SIGNATURE) {
    FAIL_SUBSYSEM(-3);
  }

  /* Get actual COFF header. */ 
  if (INVALID_SET_FILE_POINTER ==
      SetFilePointer(hImage, image_dos_header.e_lfanew, NULL, FILE_BEGIN)) {
    FAIL_SUBSYSEM(-4);
  }

  if (!ReadFile(hImage, &ntSignature, sizeof(ULONG), &bytes, 0)
      || bytes != sizeof(ULONG)) {
    FAIL_SUBSYSEM(-5);
  }

  if (ntSignature != IMAGE_NT_SIGNATURE) {
    FAIL_SUBSYSEM(-6);
  }

  if (INVALID_SET_FILE_POINTER ==
      SetFilePointer(hImage, IMAGE_SIZEOF_FILE_HEADER, NULL, FILE_CURRENT)) {
    FAIL_SUBSYSEM(-7);
  }

  /* Read optional header. */ 
  if (!ReadFile(hImage, &image_optional_header, sizeof(IMAGE_OPTIONAL_HEADER), &bytes, 0)
      || bytes != sizeof(IMAGE_OPTIONAL_HEADER)) {
    FAIL_SUBSYSEM(-8);
  }
  
  result = image_optional_header.Subsystem;
  
subsystem_finally:
  if (INVALID_HANDLE_VALUE != hImage) {
    CloseHandle(hImage);
  }
  return result;
#undef FAIL_SUBSYSEM
}

/* parse all arguments starting with the image name */
static int
parseGenericArgs(int argc, char *argv[])
{
  int i;

  if (argc < 1)
    switch (SubsystemType()) {
    case IMAGE_SUBSYSTEM_WINDOWS_GUI:
    case IMAGE_SUBSYSTEM_WINDOWS_CE_GUI:
      return 1; /* ok not to have an image since user can choose one. */
    default:
      return 0;
    }

  if (*imageName == 0) {
    /* only try to use image name if none is provided */
    if (*argv[0] && IsImage(argv[0])) {
      strncpy(imageName, argv[0], IMAGE_NAME_SIZE);
      /* if provided, the image is a vm argument. */
      vmOptions[numOptionsVM++] = argv[0];
    }
  }
  else /* provide image name as second argument if implicitly specified */
    imageOptions[numOptionsImage++] = imageName;

  imageOptions[numOptionsImage++] = argv[0];
  for (i = 1; i < argc; i++)
    imageOptions[numOptionsImage++] = argv[i];

  return 1;
}

static int
parseArguments(int argc, char *argv[])
{
  int nvmargs;

  /* argv[0] = executable name */
  vmOptions[numOptionsVM++] = argv[0];
  /* parse VM options */
  nvmargs = parseVMArgs(argc, argv);
  /* parse image and generic args */
  return parseGenericArgs(argc - nvmargs, argv + nvmargs);
}

#if COGVM
#include <signal.h>

/*
 * Support code for Cog.
 * a) Answer whether the C frame pointer is in use, for capture of the C stack
 *    pointers.
 * b) answer the amount of stack room to ensure in a Cog stack page, including
 *    the size of the redzone, if any.
 */
# if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__) \
  || defined(x86_64) || defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(__amd64__) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
/*
 * Cog has already captured CStackPointer  before calling this routine.  Record
 * the original value, capture the pointers again and determine if CFramePointer
 * lies between the two stack pointers and hence is likely in use.  This is
 * necessary since optimizing C compilers for x86 may use %ebp as a general-
 * purpose register, in which case it must not be captured.
 */
int
isCFramePointerInUse()
{
  extern usqIntptr_t CStackPointer, CFramePointer;
  extern void (*ceCaptureCStackPointers)(void);
  usqIntptr_t currentCSP = CStackPointer;

  currentCSP = CStackPointer;
  ceCaptureCStackPointers();
  assert(CStackPointer < currentCSP);
  return CFramePointer >= CStackPointer && CFramePointer <= currentCSP;
}
# endif /* defined(i386) || defined(__i386) || defined(__i386__) */

/* Answer an approximation of the size of the redzone (if any).  Do so by
 * sending a signal to the process and computing the difference between the
 * stack pointer in the signal handler and that in the caller. Assumes stacks
 * descend.
 */

#if !defined(min)
# define min(x,y) (((x)>(y))?(y):(x))
#endif
static char * volatile p = 0;

static void
sighandler(int sig)
{
  p = (char *)&sig;
}

static int
getRedzoneSize()
{
#if defined(SIGPROF) /* cygwin */
  struct sigaction handler_action, old;
  handler_action.sa_sigaction = sighandler;
  handler_action.sa_flags = SA_NODEFER | SA_SIGINFO;
  sigemptyset(&handler_action.sa_mask);
  (void)sigaction(SIGPROF, &handler_action, &old);

  do kill(getpid(),SIGPROF); while (!p);
  (void)sigaction(SIGPROF, &old, 0);
  return (char *)min(&old,&handler_action) - sizeof(struct sigaction) - p;
#else /* cygwin */
  void (*old)(int) = signal(SIGBREAK, sighandler);

  do raise(SIGBREAK); while (!p);
  return (char *)&old - p;
#endif /* cygwin */
}

sqInt reportStackHeadroom;
static int stackPageHeadroom;

/* Answer the redzone size plus space for any signal handlers to run in.
 * N.B. Space for signal handers may include space for the dynamic linker to
 * run in since signal handlers may reference other functions, and linking may
 * be lazy.  The reportheadroom switch can be used to check empirically that
 * there is sufficient headroom.
 */
int
osCogStackPageHeadroom()
{
  if (!stackPageHeadroom)
    stackPageHeadroom = getRedzoneSize() + 1024;
  return stackPageHeadroom;
}
#endif /* COGVM */
