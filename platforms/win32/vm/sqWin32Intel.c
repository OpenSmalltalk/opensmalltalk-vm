/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Intel.c
*   CONTENT: Special support stuff only for Win95/WinNT on x86
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Intel.c,v 1.5 2002/09/05 19:33:54 andreasraab Exp $
*
*   NOTES:
*    1) When using this module the virtual machine MUST NOT be compiled
*       with Unicode support.
*****************************************************************************/
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h> /* _O_BINARY */
#include <Float.h>
#include <ole2.h>
#include "sq.h"
#include "sqWin32Args.h"

/*** Variables -- Imported from Virtual Machine ***/
extern int fullScreenFlag;

/*** Crash debug -- Imported from Virtual Machine ***/
int methodPrimitiveIndex(void);
int getCurrentBytecode(void);
int printCallStack(void);


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

/* Service stuff */
TCHAR  serviceName[MAX_PATH+1];   /* The name of the NT service */
TCHAR *installServiceName = NULL; /* the name under which the service is to install */
BOOL  fBroadcastService95 = 0;   /* Do we need a broadcast when a user has logged on? */
UINT  WM_BROADCAST_SERVICE = 0;  /* The broadcast message we send */
TCHAR *msgBroadcastService = TEXT("SQUEAK_SERVICE_BROADCAST_MESSAGE"); /* The name of the broadcast message */

/* Embedded images */
static sqImageFile imageFile = 0;
static int imageSize = 0;

void SetSystemTrayIcon(BOOL on);

/****************************************************************************/
/*                     Exception handling                                   */
/****************************************************************************/
/* The following installs us a global exception filter for *all* exceptions */
/* in Squeak. This is necessary since the C support of Mingw32 for SEH is   */
/* not as sophisticated as MSVC's support. However, with this new handling  */
/* scheme the entire thing becomes actually a lot simpler...                */
/****************************************************************************/
#ifndef _CW_DEFAULT
#define _CW_DEFAULT ( _RC_NEAR + _PC_53 + _EM_INVALID + _EM_ZERODIVIDE + _EM_OVERFLOW + _EM_UNDERFLOW + _EM_INEXACT + _EM_DENORMAL)
#endif
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
      _control87( _CW_DEFAULT, _MCW_EM); /* | _MCW_RC | _MCW_PC | _MCW_IC | _MCW_DN */
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
  (FARPROC)ShellNotifyIcon = GetProcAddress(hShell, "Shell_NotifyIconA");
  if(!ShellNotifyIcon) return;  /* ok, we don't have it */
  nid.cbSize = sizeof(nid);
  nid.hWnd   = stWindow;
  nid.uID    = (UINT)hInstance;
  nid.uFlags = NIF_MESSAGE | NIF_TIP | NIF_ICON;
  nid.uCallbackMessage = WM_USER+42;
  nid.hIcon  = LoadIcon(hInstance, MAKEINTRESOURCE(1));
  strcpy(nid.szTip, "Squeak!");
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
    return "";
}

char *GetImageOption(int id)
{
  if(id < numOptionsImage)
    return imageOptions[id];
  else
    return "";
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
    MessageBox(0,crashInfo,TEXT("Squeak fatal error"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);

  SetCurrentDirectory(vmPath);
  /* print the above information */
  f = fopen("crash.dmp","a");
  if(f)
    {  time_t crashTime = time(NULL);
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
       fprintf(f,"\n"
                 "Current byte code: %d\n"
                 "Primitive index: %d\n"
                 "Stack dump follows:\n\n",
                 byteCode,
                 methodPrimitiveIndex());
    }
  fflush(f);

  /* print the caller's stack twice (to stdout and "crash.dmp")*/
  {
	  FILE tmpStdout;
	  tmpStdout = *stdout;
	  *stdout = *f;
	  printCallStack();
	  *f = *stdout;
	  *stdout = tmpStdout;
	  fprintf(f,"\n");
	  fclose(f);
  }

  } EXCEPT(EXCEPTION_EXECUTE_HANDLER) {
    /* that's to bad ... */
    if(!fHeadlessImage)
      MessageBox(0,TEXT("Squeak has crashed. Sorry."),TEXT("Squeak fatal error:"),
                 MB_OK | MB_APPLMODAL | MB_ICONSTOP);
    else
      abortMessage(TEXT("Squeak has crashed. Sorry."));
  }
}

void printErrors()
{ TCHAR *errorMsg;
  fpos_t stdoutSize,stderrSize;

  if(*stdoutName)
    {
      fgetpos(stdout,&stdoutSize);
      fseek(stdout,0,SEEK_SET);
    }
  else stdoutSize = 0;

  if(*stderrName)
    {
      fgetpos(stderr,&stderrSize);
      fseek(stderr,0,SEEK_SET);
    }
  else stderrSize = 0;

  if(stdoutSize <= 0 && stderrSize <= 0) return;
  errorMsg = (char*) calloc((int)(stdoutSize+stderrSize+2),1);
  fread(errorMsg,(int)stdoutSize,1,stdout);
  errorMsg[stdoutSize] = '\n';
  fread(&errorMsg[(int)(stdoutSize+1)],(int)stderrSize,1,stderr);
  if(!fHeadlessImage)
    MessageBox(0,errorMsg,TEXT("Squeak Error:"),MB_OK);
  free(errorMsg);
}

extern int inCleanExit;

void __cdecl Cleanup(void)
{ /* not all of these are essential, but they're polite... */

  if(!inCleanExit) {
    printCallStack();
  }
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
  if(!browserWindow)
	  printErrors();
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
		MessageBox(0,"Error opening VM","Squeak",MB_OK);
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
int sqMain(char *lpCmdLine, int nCmdShow)
{ 
  int virtualMemory;

  LoadPreferences();
  /* parse command line args */
  if(!parseArguments(strdup(GetCommandLine()), args))
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
  SetupPrinter();
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

    /* read the image file */
    if(!imageFile) {
      imageFile = sqImageFileOpen(imageName,"rb");
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, 0);
    } else {
      readImageFromFileHeapSizeStartingAt(imageFile, virtualMemory, sqImageFilePosition(imageFile));
    }
    sqImageFileClose(imageFile);
    
    /* display the main window */
    SetWindowSize();
    if(!fHeadlessImage) {
      ShowWindow(stWindow,nCmdShow);
      SetFocus(stWindow);
    }
    /* if headless running is requested, try to to create an icon
       in the Win95/NT system tray */
    else if(!fRunService || fWindows95)
      SetSystemTrayIcon(1);
    
    ioSetFullScreen(fullScreenFlag);

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

  /* check if we're running NT or 95 */
  fWindows95 = (GetVersion() & 0x80000000) != 0;

  /* fetch us a copy of the command line */
  initialCmdLine = strdup(lpCmdLine);

  /* fetch us the name of the executable */
  GetModuleFileName(hInst, vmName, MAX_PATH);

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
