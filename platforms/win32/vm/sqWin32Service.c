/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Service.c
*   CONTENT: Windows NT Service support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:   On Win95 the two "magic" entries in the registry are
*
*    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\\Run
*    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\\RunServices
*
*****************************************************************************/
#include <windows.h>
#include "sq.h"

#ifndef NO_SERVICE

/****************************************************************/
/* Imports from sqWin32Main.c                                  */
/****************************************************************/

extern TCHAR *logName;        /* full path and name to log file */
extern TCHAR serviceName[];   /* The name of the NT service */


HANDLE                  hServDoneEvent = NULL;
HANDLE                  threadHandle = NULL;
SERVICE_STATUS          ssStatus;       /* current status of the service */
SERVICE_STATUS_HANDLE   sshStatusHandle;
DWORD                   dwGlobalErr;

void sqStopService(LPTSTR lpszMsg);
void sqEventLogMessage(LPTSTR lpszMsg);
BOOL ReportStatusToSCMgr(DWORD dwCurrentState, DWORD dwWin32ExitCode, 
                         DWORD dwCheckPoint,DWORD dwWaitHint);
void sqServiceControl(DWORD dwCtrlCode);
void sqServiceMainFunction(DWORD dwArgc, LPTSTR *lpszArgv);

#define failOn(condition, msg)\
   if(condition)\
     {\
       printLastError(msg);\
       return 0;\
     }

/* printCommandLine(): Return a command line string from the current settings */

TCHAR *printCommandLine(int printFor95)
{ static TCHAR buffer[1024];
  TCHAR lbuf[50];

  *buffer = 0;

  if(printFor95)
    {
      GetModuleFileName(hInstance, buffer, 1024);
      lstrcat(buffer,TEXT(" -service95 -headless "));
    }

  if(dwMemorySize) /* need -memory: mb */
    {
      lstrcat(buffer,TEXT("-memory: "));
#ifdef UNICODE
      lstrcat(buffer, _ltow(dwMemorySize, lbuf, 10));
#else
      lstrcat(buffer, _ltoa(dwMemorySize, lbuf, 10));
#endif
      lstrcat(buffer,TEXT(" "));
    }
#if STACKVM
 { extern sqInt desiredNumStackPages;
   extern sqInt desiredEdenBytes;
   if (desiredEdenBytes) {
      lstrcat(buffer,TEXT("-eden: "));
# ifdef UNICODE
      lstrcat(buffer, _ltow(desiredEdenBytes, lbuf, 10));
# else
      lstrcat(buffer, _ltoa(desiredEdenBytes, lbuf, 10));
# endif
      lstrcat(buffer,TEXT(" "));
   }
   if (desiredNumStackPages) {
      lstrcat(buffer,TEXT("-stackpages: "));
# ifdef UNICODE
      lstrcat(buffer, _ltow(desiredNumStackPages, lbuf, 10));
# else
      lstrcat(buffer, _ltoa(desiredNumStackPages, lbuf, 10));
# endif
      lstrcat(buffer,TEXT(" "));
   }
 }
#endif /* STACKVM */
  if(*logName) /* need -log: "logName" */
    {
      lstrcat(buffer, TEXT("-log: \""));
      lstrcat(buffer, logName);
      lstrcat(buffer, TEXT("\" "));
    }
  /* add image name */
  lstrcat(buffer, TEXT("\""));
  lstrcat(buffer, toUnicode(imageName));
  lstrcat(buffer, TEXT("\"\0"));

  return buffer;
}

/****************************************************************************
 Service Install/deinstall functions
 ****************************************************************************/

/* sqStartService: start the named service */
int
sqStartService(LPCTSTR serviceName)
{
  SC_HANDLE   schService;
  SC_HANDLE   schSCManager;
  int ok = 0;

  /* open service control manager on the local machine with default database */
  schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
  failOn(!schSCManager, TEXT("OpenSCManager failed"));

  schService = OpenService(schSCManager, serviceName, SERVICE_ALL_ACCESS);
  if(schService)
    {
      /* This may take some time */
      SetCursor(LoadCursor(NULL,IDC_WAIT));
      if(StartService(schService, 0, NULL))
        ok = 1;
      else
        printLastError(TEXT("StartService failed"));
      SetCursor(LoadCursor(NULL,IDC_ARROW));
      CloseServiceHandle(schService);
    }
  else
    {
      printLastError(TEXT("OpenService failed"));
    }
  CloseServiceHandle(schSCManager);
  return ok;
}

/* sqChangeServiceConfig: change the startup type of the named service */
int
sqChangeServiceConfig(LPCTSTR serviceName, DWORD startType)
{
  SC_HANDLE   schService;
  SC_HANDLE   schSCManager;
  int ok = 0;

  /* open service control manager on the local machine with default database */
  schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
  failOn(!schSCManager, TEXT("OpenSCManager failed"));

  schService = OpenService(schSCManager, serviceName, SERVICE_ALL_ACCESS);
  if (schService != NULL)
    {
      if(ChangeServiceConfig(schService,
                             SERVICE_WIN32_OWN_PROCESS,
                             startType,
                             SERVICE_ERROR_IGNORE,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             NULL))
        {
          ok = 1;
        }
      else
          printLastError(TEXT("ChangeServiceConfig() failed"));
      CloseServiceHandle(schService);
    }
  else
      printLastError(TEXT("OpenService failed"));
  CloseServiceHandle(schSCManager);
  return ok;
}

/* sqRemoveService: remove the named service */
int
sqRemoveService(LPCTSTR serviceName)
{
  SC_HANDLE   schService;
  SC_HANDLE   schSCManager;
  BOOL    ret;

  /* open service control manager on the local machine with default database */
  schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
  failOn(!schSCManager, TEXT("OpenSCManager failed"));

  schService = OpenService(schSCManager, serviceName, SERVICE_ALL_ACCESS);
  if (schService == NULL)
    {
      printLastError(TEXT("OpenService failed"));
      ret = 0;
    }
  else
    {
      ret = DeleteService(schService);
      if(!ret)
        printLastError(TEXT("DeleteService failed"));
      CloseServiceHandle(schService);
    }
  CloseServiceHandle(schSCManager);
  return ret;
}

/* sqInstallService: install the named service */
int
sqInstallService(LPCTSTR serviceName, LPCTSTR serviceExe)
{
  LPCTSTR lpszBinaryPathName = serviceExe;
  SC_HANDLE   schService;
  SC_HANDLE   schSCManager;

  /* open service control manager on the local machine with default database */
  schSCManager = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
  failOn(!schSCManager, TEXT("OpenSCManager failed"));

  schService = CreateService(
      schSCManager,               /* SCManager database */
      serviceName,                /* name of service    */
      serviceName,                /* name to display    */
      SERVICE_ALL_ACCESS,         /* desired access     */
      SERVICE_WIN32_OWN_PROCESS,  /* service type       */
      SERVICE_DEMAND_START,       /* start type         */
      SERVICE_ERROR_NORMAL,       /* error control type */
      lpszBinaryPathName,         /* service's binary   */
      NULL,                       /* no load ordering group */
      NULL,                       /* no tag identifier  */
      NULL,                       /* no dependencies    */
      NULL,                       /* LocalSystem account */
      NULL);                      /* no password        */

  if (schService != NULL)
    CloseServiceHandle(schService);
  else
    {
      if(GetLastError() == ERROR_SERVICE_EXISTS)
        {
          /* The service already exists - ask the user to remove it */
          if(MessageBox(0,TEXT("A service of this name already exists. Try to remove it?"),
                        serviceName, MB_YESNOCANCEL) == IDYES)
            {
              /* Now close the service manager ... */
              CloseServiceHandle(schSCManager);
              /* ... delete the old service ...  */
              if(sqRemoveService(serviceName))
              /* ... and try again ... */
                return sqInstallService(serviceName,serviceExe);
            }
          else
            /* Just to make sure we don't get any weird messages below */
            SetLastError(ERROR_SERVICE_EXISTS);
        }
      printLastError(TEXT("CreateService failed"));
    }
  CloseServiceHandle(schSCManager);
  return schService != NULL;
}

/****************************************************************************
 Service Install/deinstall functions for Windows 95
 ****************************************************************************/

/* sqInstallService95: install the named service on a Windows 95 system */
int
sqInstallService95(LPTSTR serviceName)
{ TCHAR tmpString[1024];
  DWORD dwSize, dwType;
  HKEY hk;
  int ok;

  /* Add a broadcast  for user startup */
  ok = RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run"), &hk);
  failOn(ok != ERROR_SUCCESS, TEXT("RegOpenKey failed"));
  dwSize = 1024;
  ok = RegQueryValueEx(hk, TEXT("SqueakBroadcastNotification"),NULL, &dwType, (LPBYTE) &tmpString, &dwSize);
  /* ERROR_SUCCESS indicates that we have already an entry */
  if(ok != ERROR_SUCCESS)
    /* ERROR_FILE_NOT_FOUND indicates no entry */
    if(ok != ERROR_FILE_NOT_FOUND)
      failOn(1 ,TEXT("RegQueryValueEx failed"));

  /* set the new service entry */
  GetModuleFileName(hInstance, tmpString, 1024);
  lstrcat(tmpString,TEXT(" -broadcast95"));
  ok = RegSetValueEx(hk,        /* subkey handle         */
      TEXT("SqueakBroadcastNotification"), /* value name       */
      0,                        /* must be zero          */
      REG_SZ,                   /* value type            */
      (LPBYTE) &tmpString,      /* address of value data */
      lstrlen(tmpString));      /* length of value data  */
  failOn(ok != ERROR_SUCCESS, TEXT("RegSetValueEx failed"));
  RegCloseKey(hk);

  ok = RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunServices"), &hk);
  if(ok != ERROR_SUCCESS) {
    /* ERROR_FILE_NOT_FOUND indicates no entry */
    if(ok != ERROR_FILE_NOT_FOUND)
      failOn(1, TEXT("RegOpenKey failed"));
    ok = RegCreateKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunServices"), &hk);
    failOn(ok != ERROR_SUCCESS, TEXT("RegCreateKey failed"));
  } else { /* check for any existing service */
    dwSize = 1024;
    ok = RegQueryValueEx(hk,serviceName,NULL, &dwType, (LPBYTE) &tmpString, &dwSize);
    /* ERROR_SUCCESS indicates that we have already an entry */
    if(ok == ERROR_SUCCESS) { 
      /* The service already exists - ask the user to remove it */
      if(MessageBox(0,TEXT("A service of this name already exists. Try to remove it?"),
                    serviceName, MB_YESNOCANCEL) != IDYES)
        return 0; /* Just return, in any other case we just overwrite the entry */
    } else { /* ERROR_FILE_NOT_FOUND indicates no entry */
      if(ok != ERROR_FILE_NOT_FOUND)
        failOn(1 , TEXT("RegQueryValueEx failed"));
	}
  }
  /* set the new service entry */
  lstrcpy(tmpString, printCommandLine(1));
  ok = RegSetValueEx(hk,        /* subkey handle         */
      serviceName,              /* value name            */
      0,                        /* must be zero          */
      REG_SZ,                   /* value type            */
      (LPBYTE) &tmpString,      /* address of value data */
      lstrlen(tmpString));       /* length of value data  */
  failOn(ok != ERROR_SUCCESS, TEXT("RegSetValueEx failed"));
  RegCloseKey(hk);

  return 1;
}

/* sqStartService95: start the named service on a Windows 95 system */
int
sqStartService95(LPTSTR serviceName)
{ TCHAR tmpString[1024];
  STARTUPINFO sInfo;
  PROCESS_INFORMATION pInfo;
  DWORD dwSize, dwType;
  HKEY hk;
  int ok;

  ok = RegOpenKey(HKEY_LOCAL_MACHINE, TEXT("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunServices"), &hk);
  failOn(ok != ERROR_SUCCESS, TEXT("RegOpenKey failed"));
  /* get the name of the program to run */
  dwSize = 1024;
  ok = RegQueryValueEx(hk,serviceName,NULL, &dwType, (LPBYTE) &tmpString, &dwSize);
  failOn(ok != ERROR_SUCCESS, TEXT("RegQueryValueEx failed"));
  RegCloseKey(hk);
  tmpString[dwSize] = 0;
  /* and start up */
  ZeroMemory(&sInfo, sizeof(sInfo));
  ok = CreateProcess(NULL, /* no image name */
                tmpString, /* but full command line */
                NULL, /* no process security attributes */
                NULL, /* no thread security attributes */
                FALSE, /* don't inherit handles */
                0, /* no special flags */
                NULL, /* no separate environment */
                NULL, /* no startup dir */
                &sInfo, /* startup info */
                &pInfo); /* process info */
  failOn(ok == 0, TEXT("CreateProcess failed"));
  return 1;
}

/****************************************************************************
 Main service install function
 ****************************************************************************/
/* sqServiceInstall:   Install the currently active Squeak VM and Image as
                       NT Service. Run it afterwards */
void sqServiceInstall(void)
{ HKEY hk;
  TCHAR tmp[1024];
  DWORD ok;

  if( fWindows95 )
    { /* Running on Win95 */
      if(!sqInstallService95(serviceName))
        {
          warnPrintf(TEXT("The service was NOT installed."));
          return;
        }
      if(MessageBox(0,TEXT("Service installation successful.\n")
                      TEXT("Do you wish to start the service right now?"),
                      serviceName,MB_YESNOCANCEL) == IDYES)
        {
          if(!sqStartService95(serviceName))
            warnPrintf(TEXT("The service was NOT started.\n")
                       TEXT("You have to restart your system first."));
        }
      /* success */
      exit(0);
    }
  /* get the VM name */
  GetModuleFileName(hInstance,tmp, 255);
  if(!sqInstallService(serviceName, tmp))
    {
      warnPrintf(TEXT("The service has NOT been installed."));
      return;
    }
  /* Create a new key for our service */
  wsprintf(tmp,TEXT("SYSTEM\\CurrentControlSet\\Services\\%s\\Startup"),serviceName);
  ok = RegCreateKey(HKEY_LOCAL_MACHINE, tmp, &hk);
  if(ok != ERROR_SUCCESS)
    {
      printLastError(TEXT("RegCreateKey failed"));
      return;
    }
  /* Add the image name to the subkey. */
  ok = RegSetValueEx(hk,        /* subkey handle         */
      TEXT("Image"),            /* value name            */
      0,                        /* must be zero          */
      REG_EXPAND_SZ,            /* value type            */
      (LPBYTE) imageName,       /* address of value data */
      strlen(imageName) + 1);   /* length of value data  */
  if(ok != ERROR_SUCCESS)
    {
      printLastError(TEXT("RegSetValueEX failed"));
      return;
    }
  /* Add the log file to the subkey. */
  ok = RegSetValueEx(hk,        /* subkey handle         */
      TEXT("Log"),              /* value name            */
      0,                        /* must be zero          */
      REG_EXPAND_SZ,            /* value type            */
      (LPBYTE) logName,         /* address of value data */
      lstrlen(logName) + 1);    /* length of value data  */
  if(ok != ERROR_SUCCESS)
    {
      printLastError(TEXT("RegSetValueEX failed"));
      return;
    }
  /* Add the memory size to the subkey. */
  ok = RegSetValueEx(hk,        /* subkey handle         */
      TEXT("Memory"),           /* value name            */
      0,                        /* must be zero          */
      REG_DWORD,                /* value type            */
      (LPBYTE) &dwMemorySize,   /* address of value data */
      sizeof(DWORD));           /* length of value data  */
  if(ok != ERROR_SUCCESS)
    {
      printLastError(TEXT("RegSetValueEX failed"));
      return;
    }
  RegCloseKey(hk);
  /* Successfully finished install */
  if(MessageBox(0,TEXT("Service installation successful. ")
                  TEXT("Do you wish to start the service automatically on system startup?"), 
                  serviceName,MB_YESNOCANCEL) == IDYES)
    {
      if(!sqChangeServiceConfig(serviceName, SERVICE_AUTO_START))
        warnPrintf(TEXT("The service was NOT configured.\n")
                   TEXT("Please go to control panel and configure the service manually.\n"));
    }
  if(MessageBox(0,TEXT("Do you wish to start the service right now?"),
                  serviceName,MB_YESNOCANCEL) == IDYES)
    {
      if(!sqStartService(serviceName))
        warnPrintf(TEXT("The service was NOT started.\n")
                   TEXT("Please go to the control panel and start the service manually.\n"));
    }
  exit(0);  
}

/****************************************************************************
 sqServiceMain(): This function will be called when the service is about to start
 ****************************************************************************/

int sqServiceMain(void)
{
    SERVICE_TABLE_ENTRY dispatchTable[] = {
        /* NOTE: The service name is ignored with SERVICE_WIN32_OWN_SERVICE */
        { TEXT("SqueakService"), (LPSERVICE_MAIN_FUNCTION)sqServiceMainFunction },
        { NULL, NULL }
    };

    /* Try starting the service control dispatcher.
       If this fails we can't do anything, so we can just
       return false to try the usual (windowed) startup.
       If the start of the service control dispatcher is
       successful, then we won't exit this call before
       the service is terminated. Just return true to allow
       a quick exit from the WinMain() function */
    if (!StartServiceCtrlDispatcher(dispatchTable)) 
      return 0;
    return 1;
}

/****************************************************************************
 sqThreadMain(): Squeak startup point when running as service
 ****************************************************************************/

DWORD WINAPI sqThreadMain(DWORD ignored)
{ DWORD dwSize, dwType, ok;
  HKEY hk;
  static TCHAR tmpString[256];
  static TCHAR lbuf[50];
  char *cmd;

  /* first of all set a few flags */
  fHeadlessImage  = 1; /* no windows please */
  fRunService     = 1; /* report errors to the event log */

  /* get values from the registry settings */
  /* Create a new key for our service */
  wsprintf(tmpString,TEXT("SYSTEM\\CurrentControlSet\\Services\\%s\\Startup"),serviceName);
  ok = RegOpenKey(HKEY_LOCAL_MACHINE, tmpString, &hk);
  if(ok != ERROR_SUCCESS)
    {
      sqStopService(TEXT("Failed to open registry for startup parameters"));
      TerminateThread(GetCurrentThread(), 0);
    }
  /* Read the image name from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,TEXT("Image"),NULL, &dwType, (LPBYTE) imageName, &dwSize);
  if(ok != ERROR_SUCCESS || dwType != REG_EXPAND_SZ)
    {
      sqStopService(TEXT("Failed to read the image name from registry"));
      TerminateThread(GetCurrentThread(), 0);
    }
  imageName[dwSize] = 0;
  /* Read the log file name from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,TEXT("Log"),NULL, &dwType, (LPBYTE) &tmpString, &dwSize);
  if(ok != ERROR_SUCCESS || dwType != REG_EXPAND_SZ)
    {
      sqStopService(TEXT("Failed to read the log file name from registry"));
      TerminateThread(GetCurrentThread(), 0);
    }
  tmpString[dwSize] = 0;
  logName = malloc(lstrlen(tmpString)+1);
  lstrcpy(logName, tmpString);
  /* Read the memory size from the subkey. */
  dwSize = sizeof(DWORD);
  ok = RegQueryValueEx(hk,TEXT("Memory"),NULL, &dwType, (LPBYTE) &dwMemorySize, &dwSize);
  if(ok != ERROR_SUCCESS || dwType != REG_DWORD)
    {
      sqStopService(TEXT("Failed to read the memory amount from registry"));
      TerminateThread(GetCurrentThread(), 0);
    }
  RegCloseKey(hk);

  /* and away we go ... */
  cmd = printCommandLine(0);
  sqMain(0,&cmd);
  return 1;
}

/****************************************************************************
 sqServiceMain(): This function will be called when the service is about to run
 ****************************************************************************/
void sqServiceMainFunction(DWORD dwArgc, LPTSTR *lpszArgv)
{ DWORD id;
  HANDLE eventList[2];

  /* store the name of our service */
  lstrcpy(serviceName, lpszArgv[0]);

  /* register our service control handler: */
  sshStatusHandle = RegisterServiceCtrlHandler( serviceName, 
                      (LPHANDLER_FUNCTION) sqServiceControl);

  if (!sshStatusHandle) goto cleanup;

    /* SERVICE_STATUS members that don't change */
    ssStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    ssStatus.dwServiceSpecificExitCode = 0;


    /* report the status to Service Control Manager.*/
    if (!ReportStatusToSCMgr(SERVICE_START_PENDING,NO_ERROR,1,3000))
        goto cleanup;

    /* create the event object. The control handler function signals
       this event when it receives the "stop" control code. */

    hServDoneEvent = CreateEvent(NULL,TRUE,FALSE,NULL);

    if (hServDoneEvent == (HANDLE)NULL) goto cleanup;

    /* report the status to the service control manager. */
    if (!ReportStatusToSCMgr(SERVICE_START_PENDING,NO_ERROR,2,3000))
        goto cleanup;

    /* start the thread that performs the work of the service. */
    threadHandle =
        CreateThread(NULL,                    /* No security descriptor */
                     0,                       /* default stack size     */
                     (LPTHREAD_START_ROUTINE) &sqThreadMain, /* what to do */
                     NULL,                    /* parameter for thread   */
                     STACK_SIZE_PARAM_IS_A_RESERVATION, /* creation parameter -- create running*/
                     &id);                    /* return value for thread id */
    if(!threadHandle) goto cleanup;

    /* report the status to the service control manager. */
    if (!ReportStatusToSCMgr( SERVICE_RUNNING, NO_ERROR,0, 0))
        goto cleanup;

    sqEventLogMessage(TEXT("The service was started"));

    /* wait indefinitely until either hServDoneEvent 
       is signaled or sqThreadMain finished */
    eventList[0] = hServDoneEvent;
    eventList[1] = threadHandle;
    WaitForMultipleObjects(2, eventList,FALSE, INFINITE);

    /* somebody wants us terminated */
    if(threadHandle)
      TerminateThread(threadHandle,0);

    sqEventLogMessage(TEXT("The service was stopped"));
cleanup:
    if (hServDoneEvent != NULL)
        CloseHandle(hServDoneEvent);

    /* try to report the stopped status to the service control manager. */
    if (sshStatusHandle != 0)
        ReportStatusToSCMgr( SERVICE_STOPPED, dwGlobalErr, 0, 0);

    /* When SERVICE MAIN FUNCTION returns in a single service
       process, the StartServiceCtrlDispatcher function in
       the main thread returns, terminating the process. */
    return;
}


/****************************************************************************
  sqServiceControl: this function is called by the Service Controller whenever
                    someone calls ControlService in reference to our service.
 ****************************************************************************/

void sqServiceControl(DWORD dwCtrlCode)
{
    DWORD  dwState = SERVICE_RUNNING;

    /* Handle the requested control code. */
    switch(dwCtrlCode) {
        case SERVICE_CONTROL_PAUSE:
          /* Pause the service if it is running. */
          if (ssStatus.dwCurrentState == SERVICE_RUNNING) 
            {
              if(threadHandle) SuspendThread(threadHandle);
              dwState = SERVICE_PAUSED;
            }
          break;
        case SERVICE_CONTROL_CONTINUE:
          /* Resume the paused service. */
          if (ssStatus.dwCurrentState == SERVICE_PAUSED) 
            {
              if(threadHandle) ResumeThread(threadHandle);
              dwState = SERVICE_RUNNING;
            }
          break;
        case SERVICE_CONTROL_STOP:
          /* Stop the service. */
          dwState = SERVICE_STOP_PENDING;
          /* Report the status, specifying the checkpoint and waithint,
             before setting the termination event. */
          ReportStatusToSCMgr( SERVICE_STOP_PENDING, NO_ERROR, 1, 3000);
          SetEvent(hServDoneEvent);
          return;
        case SERVICE_CONTROL_INTERROGATE:
            /* Update the service status. */
            break;
        default:
            break;
    }

    /* send a status response. */
    ReportStatusToSCMgr(dwState, NO_ERROR, 0, 0);
}

/****************************************************************************
 Helpers
 ****************************************************************************/

/* ReportStatusToSCMgr()
      This function is called by the ServMainFunc() and
      ServCtrlHandler() functions to update the service's status
      to the service control manager. */

BOOL
ReportStatusToSCMgr(DWORD dwCurrentState,
                    DWORD dwWin32ExitCode,
                    DWORD dwCheckPoint,
                    DWORD dwWaitHint)
{
    BOOL fResult;

    /* Disable control requests until the service is started. */

    if (dwCurrentState == SERVICE_START_PENDING)
        ssStatus.dwControlsAccepted = 0;
    else
        ssStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP |
            SERVICE_ACCEPT_PAUSE_CONTINUE;

    /* These SERVICE_STATUS members are set from parameters. */
    ssStatus.dwCurrentState = dwCurrentState;
    ssStatus.dwWin32ExitCode = dwWin32ExitCode;
    ssStatus.dwCheckPoint = dwCheckPoint;

    ssStatus.dwWaitHint = dwWaitHint;

    /* Report the status of the service to the service control manager. */
    if (!(fResult = SetServiceStatus( sshStatusHandle, &ssStatus)))
      {
        /* If an error occurs, stop the service. */
        sqStopService(TEXT("SetServiceStatus"));
      }
    return fResult;
}

/* sqStopService: report an error, and stop the service. */

void sqStopService(LPTSTR lpszMsg)
{
    TCHAR   chMsg[256];
    HANDLE  hEventSource;
    LPTSTR  lpszStrings[2];

    dwGlobalErr = GetLastError();

    /* Use event logging to log the error. */
    hEventSource = RegisterEventSource(NULL, serviceName);

    wsprintf(chMsg, TEXT("%s error: %d"), serviceName, dwGlobalErr);
    lpszStrings[0] = chMsg;
    lpszStrings[1] = lpszMsg;

    if (hEventSource != NULL)
      {
        ReportEvent(hEventSource, EVENTLOG_ERROR_TYPE, 0, 0, NULL, 2, 0, (LPCTSTR*)lpszStrings, NULL);
        DeregisterEventSource(hEventSource);
      }

    /* Set a termination event to stop SERVICE MAIN FUNCTION. */
    SetEvent(hServDoneEvent);
}

/* sqEventLogMessage: report a message to the event log */

void sqEventLogMessage(LPTSTR lpszMsg)
{
    HANDLE  hEventSource;
    LPTSTR  lpszStrings[1];

    hEventSource = RegisterEventSource(NULL, serviceName);
    lpszStrings[0] = lpszMsg;
    if (hEventSource != NULL) 
      {
        ReportEvent(hEventSource, EVENTLOG_INFORMATION_TYPE, 0, 0, NULL, 1, 0, (LPCTSTR*)lpszStrings, NULL);
        DeregisterEventSource(hEventSource);
    }
}

#endif /* NO_SERVICE */
