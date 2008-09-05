/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Plugin.c
*   CONTENT: Generic Squeak Plugin
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Plugin.c,v 1.6 2001/05/18 04:13:05 anonymous Exp $
*
*   NOTES:
*		1) I HATE browsers. Why is there such a thing as a plugin API
*		   if it all works different with different browsers???
*		2) Netscape bug: Netscape does NOT return the url requested
*		   in the url field of an NPStream. That means we can't use
*		   the requested URL for determining what stream is actually
*		   coming in (Netscape reports some sort of 'canonical' URL,
*		   e.g., 'http://isgwww.cs.uni-magdeburg.de' translates into
*		   'http://isgwww.CS.Uni-Magdeburg.DE' or somesuch). So we're
*		   using the notification mechanism to match the issued request
*		   with the incoming stream (it seems that the URL reported in
*		   NPP_URLNotify matches the URL reported in the stream).
*		3) IE bug: IE calls NPP_URLNotify *before* the stream is even
*		   created. This is ridiculous. Also, IE doesn't even honor
*		   the notify request for posted data (e.g., NPN_PostURLNotify).
*		   However, it seems that IE actually reports the requested URL
*		   in the 'url' field of the created stream so we actually
*		   don't need the notification here.
*		4) I HATE browsers. Did I mention this already?!
*
*****************************************************************************/
/*
 * Retrofit for Windows Vista (IE7/Protected mode)
 *
 * AUTHOR: Korakurider (kr)
 *
 * CHANGE NOTES:
 *      1) If this is activated in protected mode, VM is invoked with "-lowRights" option, 
 *         and as a low integrity process.
 *         The updated VM capable of the option is needed.
 *         Writable place for ActiveX in protected mode is only under %USERPROFILE%\AppData\LocalLow.
 *         That VM is needed to switch "untrustedUserDirectory" if that option is specified.
 *      
 *      2) If there isn't private registry setting for current user (HKCU\Software\Squeak),
 *         try shared setting (HKLM\Software\Squeak).
 *
 *      3) registry setting "Image" is now treated as full path name for the image.
 */
 /* 
 *  AUTHOR: Bernd Eckardt (be)    
 *  CHANGES:
 *    1)  registry setting "Image" reverted to former usage (relative) 
 *    2)  registry setting "UserImage" added to handel a absolute path 
 *        if this is defined in registry this is used,  otherwise fallback to "Inage"  
 *
 */
 
 
 
#define VISTA_SECURITY

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <sddl.h> /* for Vista */

#include "sqWin32Plugin.h"

const char* gInstanceLookupString = "hWnd->squeak";
/* What's the root registry key for Squeak?! */

#ifndef HKEY_SQUEAK_ROOT
#define HKEY_SQUEAK_ROOT "SOFTWARE\\Squeak"
#endif



/* are we running IE?! */
int ieMode = 0;

DWORD g_WM_QUIT_SESSION = 0;
DWORD g_WM_BWND_SIZE = 0;
DWORD g_WM_REQUEST_DATA = 0;
DWORD g_WM_POST_DATA = 0;
DWORD g_WM_RECEIVE_DATA = 0;
DWORD g_WM_INVALIDATE = 0;

DWORD g_WM_BROWSER_PIPE = 0;
DWORD g_WM_CLIENT_PIPE = 0;

HANDLE hCurrentProcess = NULL;

#ifdef VISTA_SECURITY
/* For Integrity Level on Vista */
#define SID_INTEGRITYLEVEL_LOW     "S-1-16-4096"
#define SID_INTEGRITYLEVEL_MEDIUM  "S-1-16-8192"
#define SID_INTEGRITYLEVEL_HIGH    "S-1-16-12288"

#define INTEGRITYLEVEL_UNKNOWN  -1
#define INTEGRITYLEVEL_LOW   0
#define INTEGRITYLEVEL_MEDIUM  1
#define INTEGRITYLEVEL_HIGHT  2
#endif /* VISTA_SECURITY */

#define FREE(ptr) if(ptr) { free(ptr); ptr = NULL; }
#define STRDUP(ptr) ((ptr) ? strdup(ptr) : NULL)

#if 0
#define NULL_TEST(x,y) if(!x) MessageBox(0, "WARNING: NULL pointer not expected", y, MB_OK);
#else
#define NULL_TEST(x,y)
#endif



#if defined (NDEBUG)
void DPRINT(char *format, ...) { }
#else
void DPRINT(char *format, ...)
{
    static FILE *debuglog;
    va_list ap;
     if (!debuglog) 
	{
	  debuglog = fopen("npsqueak.log", "a+");
	  fprintf(debuglog, "=== START PLUGIN ===\n");
	}


	va_start(ap, format);
	vfprintf(debuglog, format, ap);
	va_end(ap);
	fflush(debuglog);

}

#endif

#ifdef VISTA_SECURITY
/* for DEBUG */
void ShowLastError(LPTSTR lpszFunction) 
{ 
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;

    DWORD dw = GetLastError(); 

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
        (lstrlen((LPCTSTR)lpMsgBuf)+lstrlen((LPCTSTR)lpszFunction)+40)*sizeof(TCHAR)); 
    wsprintf((LPTSTR)lpDisplayBuf, 
        TEXT("%s failed with error %d: %s"), 
        lpszFunction, dw, lpMsgBuf); 
    MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK); 

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
}
/********************************************************************/
/* Vista security stuff                                             */
/********************************************************************/
static int GetProcessIntegrityLevel(HANDLE hProcess)
{
  int integrityLevel = INTEGRITYLEVEL_UNKNOWN;
  HANDLE hToken;
  BOOL bRet;

  DWORD dwLengthNeeded;
  DWORD dwError = ERROR_SUCCESS;

  PTOKEN_MANDATORY_LABEL pTIL = NULL;
  DWORD dwIntegrityLevel;
 
  bRet = OpenProcessToken(hProcess, TOKEN_QUERY | TOKEN_QUERY_SOURCE, &hToken);
  if(!bRet) {
	  return INTEGRITYLEVEL_UNKNOWN;
  }

  // Get the Integrity level.
  bRet = GetTokenInformation(hToken, TokenIntegrityLevel, 
						NULL, 0, &dwLengthNeeded);
  if(!bRet) {
      dwError = GetLastError();
      if (dwError == ERROR_INSUFFICIENT_BUFFER) {
          pTIL = (PTOKEN_MANDATORY_LABEL)LocalAlloc(0, dwLengthNeeded);
          if (pTIL == NULL) {
		      CloseHandle(hToken);
		      return INTEGRITYLEVEL_UNKNOWN;
		  }

		  bRet = GetTokenInformation(hToken, TokenIntegrityLevel, 
								pTIL, dwLengthNeeded, &dwLengthNeeded);
		  if(!bRet) {
		      LocalFree(pTIL);
			  CloseHandle(hToken);
		  }

		  dwIntegrityLevel = *GetSidSubAuthority(pTIL->Label.Sid, 
								(DWORD)(UCHAR)(*GetSidSubAuthorityCount(pTIL->Label.Sid)-1));
		  if (dwIntegrityLevel < SECURITY_MANDATORY_MEDIUM_RID) {
				// Low Integrity
					integrityLevel = INTEGRITYLEVEL_LOW;
		  } else if (dwIntegrityLevel >= SECURITY_MANDATORY_MEDIUM_RID && 
									dwIntegrityLevel < SECURITY_MANDATORY_HIGH_RID) {
				// Medium Integrity
					integrityLevel = INTEGRITYLEVEL_MEDIUM;
		  } else if (dwIntegrityLevel >= SECURITY_MANDATORY_HIGH_RID) {
				// High Integrity
					integrityLevel = INTEGRITYLEVEL_HIGHT;
		  }
		  LocalFree(pTIL);
	  }
   }
   CloseHandle(hToken);
   return integrityLevel;
}

/* Get Well-Known SID for an Integrity Level */
static LPCTSTR GetIntegritySid(int IntegrityLevel) 
{
  LPCTSTR szSid = NULL;

  switch(IntegrityLevel) {
  case INTEGRITYLEVEL_LOW:
	  szSid = SID_INTEGRITYLEVEL_LOW;
      break;
  case INTEGRITYLEVEL_MEDIUM:
	  szSid = SID_INTEGRITYLEVEL_MEDIUM;
	  break;
  case INTEGRITYLEVEL_HIGHT:
	  szSid = SID_INTEGRITYLEVEL_HIGH;
	  break;
  }
  return szSid;
}

/* Get Security Token For Specified Integrity Level */
static HANDLE GetTokenForIntegrityLevel(HANDLE hProcess, int IntegrityLevel)
{
  BOOL bRet;
  HANDLE hToken;
  HANDLE hNewToken = NULL;

  PSID pIntegritySid = NULL;
  LPCTSTR szIntegritySid;
  TOKEN_MANDATORY_LABEL TIL = {0};
  
  szIntegritySid = GetIntegritySid(IntegrityLevel);
  if(szIntegritySid == NULL) {
	  return NULL;
  }

  bRet = OpenProcessToken(hProcess, MAXIMUM_ALLOWED, &hToken);
  if(!bRet) {
	  return NULL;
  }

  bRet = DuplicateTokenEx(hToken, MAXIMUM_ALLOWED, NULL, SecurityImpersonation, TokenPrimary, &hNewToken);
  if(!bRet) {
	  CloseHandle(hToken);
	  return NULL;
  }

  bRet = ConvertStringSidToSid(szIntegritySid, &pIntegritySid);
  if(!bRet) {
	  CloseHandle(hNewToken);
	  CloseHandle(hToken);
	  return NULL;
  }
  TIL.Label.Attributes = SE_GROUP_INTEGRITY;
  TIL.Label.Sid = pIntegritySid;
 
  bRet = SetTokenInformation(hNewToken, TokenIntegrityLevel, &TIL,
			  sizeof(TOKEN_MANDATORY_LABEL)+ GetLengthSid(pIntegritySid));
  if(!bRet) {
	  CloseHandle(hNewToken);
	  CloseHandle(hToken);
	  return NULL;
  }
  CloseHandle(hToken);
  return(hNewToken);
}
#endif /* VISTA_SECURITY */

/********************************************************************/
/* Initialization stuff                                             */
/********************************************************************/

void SqueakPluginInitialize(void)
{
  DuplicateHandle(
		  GetCurrentProcess(), 
		  GetCurrentProcess(), 
		  GetCurrentProcess(), 
		  &hCurrentProcess, 
		  1, 
		  0, 
		  DUPLICATE_SAME_ACCESS);
  g_WM_QUIT_SESSION = RegisterWindowMessage("SqueakQuitSession");
  g_WM_BWND_SIZE = RegisterWindowMessage("SqueakSetBrowserWindowSize");
  g_WM_REQUEST_DATA = RegisterWindowMessage("SqueakRequestData");
  g_WM_POST_DATA = RegisterWindowMessage("SqueakPostData");
  g_WM_RECEIVE_DATA = RegisterWindowMessage("SqueakReceiveData");
  g_WM_INVALIDATE = RegisterWindowMessage("SqueakInvalidateRect");
  g_WM_BROWSER_PIPE = RegisterWindowMessage("SqueakBrowserPipe");
  g_WM_CLIENT_PIPE = RegisterWindowMessage("SqueakClientPipe");
}

void SqueakPluginSetIEMode(void)
{
  ieMode = 1;
}

/********************************************************************/
/* Window stuff                                                     */
/********************************************************************/

LRESULT CALLBACK PluginWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  SqueakPlugin* squeak = (SqueakPlugin*) 
    GetProp(hWnd, gInstanceLookupString);
	
  if(!squeak) {
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
  }
  if(uMsg == g_WM_CLIENT_PIPE) {
    HANDLE hProcess;
    HANDLE hPipe;
    hProcess = (HANDLE) squeak->processInfo.hProcess;
    hPipe = (HANDLE) lParam;
    if(!DuplicateHandle(hProcess, hPipe, GetCurrentProcess(), 
			&squeak->hClientPipe, 0, FALSE, 
			DUPLICATE_SAME_ACCESS)) {
	  ShowLastError("ClientPipe DuplicateError");
      MessageBox(squeak->hWnd, "Can not establish communication channel!", 
		 "Squeak Plugin Error:", MB_OK | MB_ICONSTOP);
    }
    return 1;
  }
  if(uMsg == g_WM_REQUEST_DATA || uMsg == g_WM_POST_DATA) {
    char *url, *target, *data;
    DWORD urlSize, targetSize, dataSize;
    DWORD nBytes;

    /* Read the URL from the pipe */
    ReadFile(squeak->hParentReadEnd, &urlSize, 4, &nBytes, NULL);
    if(urlSize > 0) {
      url = malloc(urlSize+1);
      ReadFile(squeak->hParentReadEnd, url, urlSize, &nBytes, NULL);
      url[urlSize] = 0;
    } else url = NULL;
    /* Read the target from the pipe */
    ReadFile(squeak->hParentReadEnd, &targetSize, 4, &nBytes, NULL);
    if(targetSize > 0) {
      target = malloc(targetSize+1);
      ReadFile(squeak->hParentReadEnd, target, targetSize, &nBytes, NULL);
      target[targetSize] = 0;
    } else target = NULL;
    if(uMsg == g_WM_POST_DATA) {
      /* Read the data from the pipe */
      ReadFile(squeak->hParentReadEnd, &dataSize, 4, &nBytes, NULL);
      if(dataSize > 0) {
	data = malloc(dataSize+1);
	ReadFile(squeak->hParentReadEnd, data, dataSize, &nBytes, NULL);
	data[dataSize] = 0;
      } else data = NULL;
    } else data = NULL;
    
    if(squeak->maxStreams < MAX_STREAMS) {
      /* Request the stream from the browser */
      squeak->maxStreams++;
      if(ieMode) {/* See comments 1), 3), and 4) on top */
	int i;
	NULL_TEST(url,"PluginWindowProc");
	for(i = 0; i < MAX_STREAMS; i++)
	  if(!squeak->requests[i].url) {
	    squeak->requests[i].url = STRDUP(url);
	    squeak->requests[i].id = wParam;
	    break;
	  }
      }
      if(uMsg == g_WM_REQUEST_DATA)
	SqueakPluginRequestStream(squeak->cbData, url, target, wParam);
      else
	SqueakPluginPostData(squeak->cbData, url, target, data, wParam);
      if(url) free(url);
      if(target) free(target);
      if(data) free(data);
    } else {
      /* No more space; just abort */
      if(url) free(url);
      if(target) free(target);
      if(data) free(data);
      PostThreadMessage(squeak->processInfo.dwThreadId, 
			g_WM_RECEIVE_DATA, wParam, 0);
    }
    return 1;
  }
  if(uMsg == WM_PAINT) {
    RECT r;
    if(GetUpdateRect(hWnd, &r, FALSE)) {
      PostThreadMessage(squeak->processInfo.dwThreadId, 
			g_WM_INVALIDATE, 0, 0);
    }
    /* FALL THROUGH */
  }
  /* and pass control to the previous window procedure */
  return CallWindowProc(squeak->prevWindowProc, hWnd, uMsg, wParam, lParam);
}


void UnsubclassWindow(HWND hWnd, SqueakPlugin *squeak)
{
  if(!squeak->hWnd) return;
  SetWindowLong(squeak->hWnd, GWL_WNDPROC, (DWORD) squeak->prevWindowProc);
  squeak->hWnd = NULL;
  squeak->prevWindowProc = NULL;
  SetProp( hWnd, gInstanceLookupString, (HANDLE)NULL);
}

void SubclassWindow(HWND hWnd, SqueakPlugin *squeak)
{
  /* subclass the window */
  UnsubclassWindow(hWnd, squeak);
  squeak->hWnd = hWnd;
  squeak->prevWindowProc = (WNDPROC) GetWindowLong(hWnd, GWL_WNDPROC);
  SetWindowLong(hWnd, GWL_WNDPROC, (DWORD) PluginWindowProc);
  SetProp( hWnd, gInstanceLookupString, (HANDLE)squeak);
  /* make the window clip its children or else we might have serious
     trouble due to synchronization problems. Remember, Squeak is
     running in its own thread so if the window draws atop Squeak
     after Squeak has drawn itself we'll get damagy looking stuff.
     And believe me, this *does* happen.
  */
  SetWindowLong(hWnd, GWL_STYLE, GetWindowLong(hWnd, GWL_STYLE) | WS_CLIPCHILDREN);
}

/********************************************************************/
/* Startup stuff                                                    */
/********************************************************************/
int ReadRegistrySettings(HMODULE hPluginModule, SqueakPlugin *squeak) {
  DWORD dwType, dwSize, ok;
  TCHAR tmp[MAX_PATH+1];
  TCHAR installDirectory[MAX_PATH+1];
  HKEY hk;

  /* try private setting first */
  ok = RegOpenKey(HKEY_CURRENT_USER, HKEY_SQUEAK_ROOT, &hk);
  if(ok != ERROR_SUCCESS) {
	  /* try shared setting next */
      ok = RegOpenKey(HKEY_LOCAL_MACHINE, HKEY_SQUEAK_ROOT, &hk);
  }
  /* Read the Squeak path from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,"InstallDirectory",NULL, &dwType, 
		       (LPBYTE) installDirectory, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(installDirectory[dwSize-2] != '\\') {
      installDirectory[dwSize-1] = '\\';
      installDirectory[dwSize] = 0;
    }
  } else {
    /* No base directory found; use default plugin location */
    GetModuleFileName(hPluginModule, installDirectory, MAX_PATH);
    /* MessageBox(0, squeak->vmName,"Module name", MB_OK); */
    strrchr(installDirectory,'\\')[1] = 0;
  }

  /* Read VM name from the subkey */
  strcpy(squeak->vmName, installDirectory);

  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk, "VM", NULL, &dwType, (LPBYTE)tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    tmp[dwSize] = 0;
    strcat(squeak->vmName, tmp);
  } else {
    /* No VM name found; use default VM name */
    strcat(squeak->vmName, "Squeak.exe");
  }

  /* Read image name from the subkey */
  dwSize = MAX_PATH;

  ok = RegQueryValueEx(hk, "UserImage", NULL, &dwType, (LPBYTE)tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
		tmp[dwSize = 0];
	  	strcpy(squeak->imageName, tmp);
  }
  else{
	  ok = RegQueryValueEx(hk, "Image", NULL, &dwType, (LPBYTE)tmp, &dwSize);
	  if(ok == ERROR_SUCCESS) {
		tmp[dwSize = 0];

		strcpy(squeak->imageName, installDirectory);
		strcat(squeak->imageName, tmp);
	
	  } else {
		/* No image name found; use default image name */
		strcpy(squeak->imageName, installDirectory);
		strcat(squeak->imageName, "SqueakPlugin.image");
	  }
  }
/*  MessageBox(0, squeak->imageName,"Image name", MB_OK); */
  RegCloseKey(hk);
  return 1;
}

SqueakPlugin *SqueakPluginNew(HANDLE hPluginModule, void *cbData) 
{
  SqueakPlugin *squeak;
  int i;

  squeak = (SqueakPlugin*) calloc(1,sizeof(SqueakPlugin));
  if(squeak) {
    squeak->params = calloc(1,10); /* initial zero terminated string */
    /* Default settings */
#ifdef DISNEY
    { 
      DWORD dwType, dwSize, ok;
      HKEY hk;

      ok = RegOpenKey(HKEY_CURRENT_USER, 
		      "SOFTWARE\\Disney\\DisneyOnline\\Squeak", &hk);
      if(ok != ERROR_SUCCESS) {
	MessageBox(0, "Cannot find Disney registry entry", 
		   "Squeak Plugin Error:", MB_OK);
	return NULL;
      }
      /* Read the Squeak path from the subkey. */
      dwSize = MAX_PATH;
      ok = RegQueryValueEx(hk,"InstallDirectory",NULL, &dwType, 
			   (LPBYTE) squeak->vmName, &dwSize);
      if(ok != ERROR_SUCCESS) {
	MessageBox(0, "Cannot find Squeak registry entry", 
		   "Squeak Plugin Error:", MB_OK);
	return NULL;
      }
      if(squeak->vmName[dwSize-2] != '\\') {
	squeak->vmName[dwSize-1] = '\\';
	squeak->vmName[dwSize] = 0;
      }
      /* MessageBox(0,squeak->vmName, "Squeak location:", MB_OK); */
      strcpy(squeak->imageName, squeak->vmName);
      strcat(squeak->vmName,"DOLSqueak.exe");
      strcat(squeak->imageName,"DOLSqueak.image");
    }
#else
    ReadRegistrySettings(hPluginModule, squeak);
#endif
    strcpy(squeak->params,"\"\" ");
    squeak->cbData = cbData;
    if(!CreatePipe(&squeak->hParentReadEnd, &squeak->hParentWriteEnd, 
		   NULL, 4096))
      return NULL;
    for(i=0; i< MAX_STREAMS; i++) {
      squeak->requests[i].id = -1;
      squeak->requests[i].state = -1;
    }
  }
  return squeak;
}

int SqueakPluginActive(SqueakPlugin *squeak)
{
  if(!squeak) return 0;
  return squeak->processInfo.hProcess != NULL;
}

int TerminateSqueakPlugin(SqueakPlugin *squeak)
{
  DWORD exitCode;
  int maxStop = 50; /* Wait at most five seconds to complete */
  if(!squeak) return 0;
  if(!squeak->processInfo.hProcess) return 0;

  UnsubclassWindow(squeak->hWnd, squeak);
  /* Gracefully terminate the process */
  do {
    GetExitCodeProcess(squeak->processInfo.hProcess, &exitCode);
    if(exitCode == STILL_ACTIVE) {
      PostThreadMessage(squeak->processInfo.dwThreadId, 
			g_WM_QUIT_SESSION, 0, 0);
      Sleep(100);
    }
  } while(exitCode == STILL_ACTIVE && maxStop-- > 0);
  if(maxStop <= 0) {
    /* Sorry folks - we have to do it the hard way */
    TerminateProcess(squeak->processInfo.hProcess,0);
  }
  squeak->processInfo.hProcess = NULL;
  return 1;
}

int SqueakPluginRun(SqueakPlugin *squeak, HWND hWnd, int terminateOld)
{
  STARTUPINFO sInfo;
  char lbuf[50];
  char *runString;
  int ok, runSize;
  int integrityLevel;
  HANDLE hProcess;
  HANDLE hToken;

  if(!squeak) {
	  MessageBox(0, "No plugin instance", "Squeak", MB_OK);
	  return 0;
  }
  if(!hWnd) {
	  MessageBox(0, "No window for plugin", "Squeak", MB_OK);
	  return 0;
  }
  if(terminateOld)
    TerminateSqueakPlugin(squeak);

  if(squeak->vmName[0] == 0) {
	  MessageBox(0, "No vm name", "Squeak", MB_OK);
	  return 0;
  }
  if(squeak->imageName[0] == 0) {
	  MessageBox(0, "No image name", "Squeak", MB_OK);
	  return 0;
  }

  SubclassWindow(hWnd, squeak);

  /* Start Squeak */
  ZeroMemory(&sInfo, sizeof(sInfo));
  sInfo.cb = sizeof(sInfo);
  /* setup cmd line */
  runSize = 256; /* some additional space for -browserWindow: etc */
  runSize += strlen(squeak->vmName);
  runSize += strlen(squeak->imageName);
  if(squeak->params) runSize += strlen(squeak->params);
  if(squeak->vmParams) runSize += strlen(squeak->vmParams);
  runString = calloc(1, runSize+1);
  strcat(runString, squeak->vmName);
  if(squeak->vmParams) {
    strcat(runString," ");
    strcat(runString, squeak->vmParams);
  }
  strcat(runString, " -browserWindow: "); 
  strcat(runString, ltoa((int)hWnd, lbuf, 10) );

  if(squeak->memory) {
    strcat(runString," -memory: ");
    strcat(runString, ltoa(squeak->memory, lbuf, 10) );
  }
#ifdef VISTA_SECURITY /* for IE7/Vista security */
  hProcess = GetCurrentProcess();
  integrityLevel = GetProcessIntegrityLevel(hProcess);
/* In Protected Mode, untrustedUserDirectory must be 'low rights' area */
  if(integrityLevel == INTEGRITYLEVEL_LOW) {
	  strcat(runString, " -lowRights");
  }
#endif /* VISTA_SECURITY */

  strcat(runString, " \"");
  strcat(runString, squeak->imageName);
  strcat(runString, "\" ");
  if(squeak->params) strcat(runString, squeak->params);


#ifdef VISTA_SECURITY /* for IE7/Vista security */
/* Call VM as invoker's integirty */
  hToken = GetTokenForIntegrityLevel(hProcess, integrityLevel);
  if(hToken) {
		ok = CreateProcessAsUser(
				hToken, /* security token */
				NULL, 
				runString, /* full command line */
                NULL, /* no process security attributes */
                NULL, /* no thread security attributes */
                FALSE, /* don't inherit handles */
                0, /* no special flags */
                NULL, /* no separate environment */
                NULL, /* no startup dir */
                &sInfo, /* startup info */
                &squeak->processInfo); /* process info */
		/* CloseHandle(hToken); */
	} else {
		ok = 0;
	}
	CloseHandle(hProcess);
#else
    ok = CreateProcess(NULL, /* no image name */
                runString, /* but full command line */
                NULL, /* no process security attributes */
                NULL, /* no thread security attributes */
                TRUE, /* don't inherit handles */
                0, /* no special flags */
                NULL, /* no separate environment */
                NULL, /* no startup dir */
                &sInfo, /* startup info */
                &squeak->processInfo); /* process info */
#endif
  if(ok == 0) { /* Error! */
    DWORD lastError = GetLastError();
    LPVOID lpMsgBuf;
    char msgBuf[256];
    UnsubclassWindow(squeak->hWnd, squeak);
    squeak->processInfo.hProcess = NULL;
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |  
		  FORMAT_MESSAGE_FROM_SYSTEM | 
		  FORMAT_MESSAGE_IGNORE_INSERTS, 
		  NULL, 
		  lastError, 
		  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		  (LPTSTR) &lpMsgBuf, 
		  0, 
		  NULL );
    sprintf(msgBuf, "Squeak Plugin Error (code = %x)", lastError);
    MessageBox(hWnd, lpMsgBuf, msgBuf, MB_OK | MB_ICONSTOP);
    LocalFree( lpMsgBuf );
    return 0;
  }
  WaitForInputIdle(squeak->processInfo.hProcess, INFINITE);
  if(!DuplicateHandle(
		      GetCurrentProcess(),
		      squeak->hParentWriteEnd,
		      squeak->processInfo.hProcess,
		      &squeak->hParentWriteEnd,
		      0,
		      FALSE,
			  DUPLICATE_SAME_ACCESS | DUPLICATE_CLOSE_SOURCE)) {
	ShowLastError("Communication Channel-a");
    MessageBox(hWnd, "Unable to establish communication channel", 
	       "Squeak Plugin error", MB_OK | MB_ICONSTOP);
  }
  if(PostThreadMessage(
		squeak->processInfo.dwThreadId, 
		g_WM_BROWSER_PIPE, 
		(WPARAM) hCurrentProcess, 
		(LPARAM) squeak->hParentWriteEnd) == 0) {
	    ShowLastError("Communication Channel-b");
		MessageBox(hWnd, "Failed to establish communication channel", 
	       "Squeak Plugin error", MB_OK | MB_ICONSTOP);
  }
  free(runString);
  return 1;
}


int SqueakPluginResize(SqueakPlugin *squeak, HWND hWnd)
{
  RECT r;
  if(!squeak) return 0;
  if(!squeak->processInfo.hProcess) return 0;
  if(!hWnd) return 0;
  if(GetWindowLong(hWnd, GWL_WNDPROC) != (int)PluginWindowProc) {
    SubclassWindow(hWnd, squeak);
  }
  GetClientRect(hWnd, &r);
  PostThreadMessage(squeak->processInfo.dwThreadId, 
		    g_WM_BWND_SIZE, (r.right - r.left), (r.bottom - r.top));
  return 1;
}


int SqueakPluginDestroy(SqueakPlugin *squeak)
{
  if(!squeak) return 1;
  TerminateSqueakPlugin(squeak);
  if(squeak->vmParams) free(squeak->vmParams);
  if(squeak->params) free(squeak->params);
  free(squeak);
  return 1;
}

void SqueakPluginSetVM(SqueakPlugin *squeak, char *vmName)
{
#ifndef DISNEY
  strcpy(squeak->vmName, vmName);
#endif
}

void SqueakPluginSetImage(SqueakPlugin *squeak, char *imageName)
{
#ifndef DISNEY
  strcpy(squeak->imageName, imageName);
#endif
}

void SqueakPluginSetMemory(SqueakPlugin *squeak, char *src)
{
  char buf[50], *tmp;
  int imageSize, requestedSize;
  int baseSize;
  HANDLE hFile;

  hFile = CreateFile(squeak->imageName, 
		     GENERIC_READ, 
		     FILE_SHARE_READ | FILE_SHARE_WRITE, 
		     NULL, 
		     OPEN_EXISTING, 
		     FILE_ATTRIBUTE_NORMAL, 
		     NULL);
  if(hFile) {
    baseSize = (int) SetFilePointer(hFile, 0, NULL, FILE_END);
    CloseHandle(hFile);
  } else {
    baseSize = 0;
  }
  imageSize = 0;
  while(*src) {
    switch(*src) {
    case ' ': /* white spaces; ignore */
    case '"':
      src++; break;
    case '*': /* multiple of image size */
      tmp = buf; src++;
      while(*src && isdigit(*src)) *(tmp++) = *(src++); /* integer part */
      if(*src == '.') { /* fraction part */
	*(tmp++) = *(src++);
	while(*src && isdigit(*src)) *(tmp++) = *(src++);
      }
      *(tmp++) = 0;
      imageSize += (int) (baseSize * atof(buf));
      break;
    case '+': /* additional space in bytes */
      tmp = buf; src++;
      while(*src && isdigit(*src)) *(tmp++) = *(src++);
      *(tmp++) = 0;
      if (imageSize == 0) 
	imageSize = baseSize;
      requestedSize = atoi(buf);
      imageSize += (requestedSize <= 1000) ? 
	requestedSize*1024*1024 : requestedSize;
      break;
    default: /* absolute size */
      tmp = buf;
      *(tmp++) = *(src++);
      while(*src && isdigit(*src)) *(tmp++) = *(src++);
      *(tmp++) = 0;
      requestedSize = atoi(buf);
      imageSize = (requestedSize <= 1000) ? 
	requestedSize*1024*1024 : requestedSize;
    }
  }
  squeak->memory = imageSize / (1024 * 1024);
}
void SqueakPluginAddParam(SqueakPlugin *squeak, char *name, char *value)
{
  if(name && value) {
    squeak->paramSize += strlen(name) + 3; /* quotes + space */
    squeak->paramSize += strlen(value) + 3; /* quotes + space */
    squeak->params = realloc(squeak->params, squeak->paramSize + 10);
    strcat(squeak->params,"\"");
    strcat(squeak->params, name);
    strcat(squeak->params,"\" \"");
    strcat(squeak->params, value);
    strcat(squeak->params,"\" ");
  }
}

void SqueakPluginSetVMParams(SqueakPlugin *squeak, char *params)
{
  int length;
  
  if(!params || !*params) return;
  if(squeak->vmParams) free(squeak->vmParams);
  /* skip double quotes if necessary */
  if(params[0] == '"') {
    params++;
    length = strlen(params);
    if(params[length-1] = '"') params[length-1] = 0;
  }
  squeak->vmParams = STRDUP(params);
}

/********************************************************************/
/* Streaming stuff                                                  */
/********************************************************************/
void SqueakReturnRequest(SqueakPlugin *squeak, int index)
{
  char *localName = squeak->requests[index].localName;
  DWORD length, written;

  /* This makes the VM aware of data coming in */
  PostThreadMessage(
		squeak->processInfo.dwThreadId, 
		g_WM_RECEIVE_DATA, 
		squeak->requests[index].id,
		squeak->requests[index].state);

  if(localName)
    length = strlen(localName);
  else
    length = 0;
  WriteFile(squeak->hClientPipe, &length, 4, &written, NULL);
  if(length)
    WriteFile(squeak->hClientPipe, localName, length, &written, NULL);
  
  FREE(squeak->requests[index].url);
  FREE(squeak->requests[index].localName);
  squeak->requests[index].id = -1;
  squeak->requests[index].state = -1;
  squeak->maxStreams--;
}

void SqueakPluginStreamFile(SqueakPlugin *squeak, char *url, char *localName, int id)
{
  int i;
  if(!squeak->maxStreams) return; /* no streams requested */
  NULL_TEST(url,"PluginStreamFile(url)");
  NULL_TEST(localName, url);
  if(ieMode) {
    /* See comments on top */
    for(i=0; i < MAX_STREAMS; i++) {
      if(squeak->requests[i].url && squeak->requests[i].id >= 0) {
	if(stricmp(squeak->requests[i].url, url) == 0) {
	  squeak->requests[i].localName = STRDUP(localName);
	  SqueakReturnRequest(squeak, i);
	  return;
	}
      }
    }
  } else { /* !ieMode */
    /* Cache the URL and the local name */
    for(i = 0; i < MAX_STREAMS; i++)
      if(!squeak->requests[i].url) {
	squeak->requests[i].id = id;
	squeak->requests[i].url = STRDUP(url);
	squeak->requests[i].localName = STRDUP(localName);
	return;
      }
  }
}

/* NOTE: The following is never used iff ieMode != 0 */
void SqueakPluginNotify(SqueakPlugin *squeak, int id, char *url, int ok)
{
  int i;

  if(!squeak->maxStreams) return; /* no streams requested */
  NULL_TEST(url,"PluginNotify");
  /* See comments 1), 2), and 4) on top */
  for(i = 0; i < MAX_STREAMS; i++) {
    if(squeak->requests[i].url && (stricmp(squeak->requests[i].url, url) == 0 || (squeak->requests[i].id == id))) {
      squeak->requests[i].id = id;
      squeak->requests[i].state = ok;
      SqueakReturnRequest(squeak, i);
      DPRINT("NP: notifySqueak request found for notification %s (id: %i state ok:%i)\n",url,id,ok);
      return;
    }
    else{
      if(squeak->requests[i].url){
      DPRINT("NP: notifySqueak %s not equal \n",url);
      DPRINT("NP: notifySqueak %s not equal \n",squeak->requests[i].url);
      }
    }
  }
  DPRINT("NP: notifySqueak no request found for notification\n");
  /* Note: If we come here, NS has never created a stream for the request.
     Handle it as if it were an empty request */
  for(i = 0; i < MAX_STREAMS; i++) {
    if(!squeak->requests[i].url) {
      squeak->requests[i].url = STRDUP(url);
      squeak->requests[i].id = id;
      squeak->requests[i].state = ok;
      if(!ok) SqueakReturnRequest(squeak, i);
      return;
    }
  }
}

void SqueakPluginStreamState(SqueakPlugin *squeak, char *url, int ok)
{
  int i;

  if(!squeak->maxStreams) return; /* no streams requested */
  NULL_TEST(url,"PluginStreamState");
  for(i = 0; i < MAX_STREAMS; i++) {
    if(squeak->requests[i].url && stricmp(squeak->requests[i].url, url) == 0) {
      squeak->requests[i].state = ok;
      if(squeak->requests[i].id >= 0) SqueakReturnRequest(squeak, i);
      return;
    }
  }
}



