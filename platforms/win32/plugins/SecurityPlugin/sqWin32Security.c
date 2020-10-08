/* Windows Vista support 
 * AUTHOR: Korakurider (kr)
 * CHANGE NOTES:
 *   1) untrustedDirectory is determined by "UserDirectoryLow" setting 
 *      in INI file if command line option "-lowRights" is specified.
 */

#include <Windows.h>
#include <shlobj.h> /* CSIDL_XXX */
#include "sq.h"
#include "sqWin32.h"

#ifndef HKEY_SQUEAK_ROOT
/* the default place in the registry to look for */
#define HKEY_SQUEAK_ROOT "SOFTWARE\\Squeak"
#endif

static HRESULT (__stdcall *shGetFolderPath)(HWND, int, HANDLE, DWORD, WCHAR*);

static WCHAR untrustedUserDirectory[MAX_PATH+1];
static int untrustedUserDirectoryLen;
static WCHAR secureUserDirectory[MAX_PATH+1];
static int secureUserDirectoryLen;
static WCHAR resourceDirectory[MAX_PATH+1];
static int resourceDirectoryLen;

static char untrustedUserDirectoryUTF8[MAX_PATH_UTF8+1];
static char secureUserDirectoryUTF8[MAX_PATH_UTF8+1];
static char resourceDirectoryUTF8[MAX_PATH_UTF8+1];

/* imported from sqWin32Main.c */
extern BOOL fLowRights;  /* started as low integrity process, 
                        need to use alternate untrustedUserDirectory */

extern int sqAskSecurityYesNoQuestion(const char *question);
extern const char *sqGetCurrentImagePath(void);

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* environment security */
static int allowEnvironmentAccess = 1; /* full access to C environment */

sqInt ioDisableEnvironmentAccess(void) { return allowEnvironmentAccess = 0; }
sqInt ioHasEnvironmentAccess(void) { return allowEnvironmentAccess; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* file security */
static int allowFileAccess = 1;  /* full access to files */
static const WCHAR SEC_U_DOT[] = L".";
static const WCHAR SEC_U_BACKSLASH[] = L"\\";

static int testDotDot(WCHAR *pathName, int index) {
  while(pathName[index]) {
    if(pathName[index] == SEC_U_DOT[0]) {
      if(pathName[index-1] == SEC_U_DOT[0]) {
        if (pathName[index-2] == SEC_U_BACKSLASH[0]) {
          return 0; /* Gotcha! */
        }
      }
    }
    index++;
  }
  return 1;
}

static int isAccessiblePathName(WCHAR *pathName, int writeFlag) {
  int pathLen = wcslen(pathName);
  if (pathLen > (MAX_PATH - 1)) return 0;

  if (pathLen >= untrustedUserDirectoryLen
      && 0 == wcsncmp(pathName, untrustedUserDirectory, untrustedUserDirectoryLen)) {
    if (pathLen > untrustedUserDirectoryLen + 2)
      return testDotDot(pathName, untrustedUserDirectoryLen+2);
    return 1;
  }
  if (writeFlag)
    return 0;

  if (pathLen >= resourceDirectoryLen
      &&  0 == wcsncmp(pathName, resourceDirectory, resourceDirectoryLen)) {
    if (pathLen > resourceDirectoryLen + 2)
      return testDotDot(pathName, resourceDirectoryLen+2);
    return 1;
  }
  return 0;
}

static int isAccessibleUTF8PathName(char *pathName, int pathLen , int writeFlag) {
	DWORD len;
	WCHAR widePath[MAX_PATH];
	/* this form of call is not going to put a terminating NULL */
	len = MultiByteToWideChar(CP_UTF8, 0, pathName, pathLen, widePath, MAX_PATH-1);
	if (len == 0) return 0; /* if conversion fails, then it's not accessible */
	widePath[len] = 0;
	return isAccessiblePathName(widePath, writeFlag);
}

static int isAccessibleFileName(WCHAR *fileName, int writeFlag) {
  return isAccessiblePathName(fileName, writeFlag);
}

static int isAccessibleUTF8FileName(char *fileName, int fileLen, int writeFlag) {
	return isAccessibleUTF8PathName(fileName, fileLen , writeFlag);
}

/* directory access */
int ioCanCreatePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8PathName(pathString, pathStringLength, 1);
}

int ioCanListPathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8PathName(pathString, pathStringLength, 0);
}

int ioCanDeletePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8PathName(pathString, pathStringLength, 1);
}

/* file access */
int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8FileName(pathString, pathStringLength, writeFlag);
}

int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  return ioCanOpenFileOfSizeWritable(pathString,pathStringLength,writeFlag);
}
int ioCanDeleteFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8FileName(pathString, pathStringLength, 1);
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleUTF8FileName(pathString, pathStringLength, 1);
}


int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

/* disabling/querying */
int ioDisableFileAccess(void) { return allowFileAccess = 0; }
int ioHasFileAccess(void) { return allowFileAccess; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* image security */

static int allowImageWrite = 1;  /* allow writing the image */
sqInt ioCanRenameImage(void) {
  return allowImageWrite; /* only when we're allowed to save the image */
}

sqInt ioCanWriteImage(void) { return allowImageWrite; }
sqInt ioDisableImageWrite(void) { return allowImageWrite = 0; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* socket security - for now it's all or nothing */
static int allowSocketAccess = 1; /* allow access to sockets */

int ioCanCreateSocketOfType(int netType, int socketType) {
  return allowSocketAccess;
}

int ioCanConnectToPort(int netAddr, int port) { return allowSocketAccess; }
int ioCanListenOnPort(void* s, int port) { return allowSocketAccess; }
int ioDisableSocketAccess() { return allowSocketAccess = 0; }
int ioHasSocketAccess() { return allowSocketAccess; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* SecurityPlugin primitive support */

char *ioGetSecureUserDirectory(void) {
  return secureUserDirectoryUTF8;
}

char *ioGetUntrustedUserDirectory(void) {
  return untrustedUserDirectoryUTF8;
}

/* helper function to expand %MYDOCUMENTSFOLDER% */

int expandMyDocuments(WCHAR *pathname, WCHAR *replacement, WCHAR *result)
{
  WCHAR search4[MAX_PATH+1];
  WCHAR *start;
  int len;

  wcscpy(search4, L"%MYDOCUMENTS%");

  if(!(start = wcsstr(pathname, search4))) return 0;

  wcsncpy(result, pathname, start-pathname); 
  result[start-pathname] = L'\0';
  len = _snwprintf(result+(start-pathname),MAX_PATH-(start - pathname),L"%s%s", replacement, start+wcslen(search4));

  if (len < 0) { /* handle failure when replacement is too long: abort the replacement... what should we do? */
    result[MAX_PATH]=0;
    return 0;
  } else
    return len + (start - pathname);
}

static void expandVariableInDirectory(WCHAR *directory, WCHAR *wDir, WCHAR *wTmp)
{
    /* Expand environment variables. */
    wcscpy(wDir, directory);
    ExpandEnvironmentStringsW(wDir, wTmp, MAX_PATH - 1);

    /* Expand relative paths to absolute paths */
    GetFullPathNameW(wTmp, MAX_PATH, wDir, NULL);
    wcscpy(directory, wDir);
}

/* note: following is called from VM directly, not from plugin */
sqInt ioInitSecurity(void) {
  DWORD dwType, dwSize, ok;
  WCHAR tmp[MAX_PATH+1];
  WCHAR wTmp[MAX_PATH+1];
  WCHAR wDir[MAX_PATH+1];
  WCHAR myDocumentsFolder[MAX_PATH+1];  
  HKEY hk;
  int dirLen;

  /* establish the secure user directory */
  MultiByteToWideChar(CP_UTF8,0, sqGetCurrentImagePath(),-1,secureUserDirectory, MAX_PATH );
  dirLen = wcslen(secureUserDirectory);
  dwSize = MAX_PATH-dirLen;
  GetUserNameW(secureUserDirectory+dirLen, &dwSize);

  /* establish untrusted user directory */
  wcscpy(untrustedUserDirectory, L"C:\\My Squeak\\%USERNAME%");

  /* establish untrusted user directory */
  MultiByteToWideChar(CP_UTF8, 0, sqGetCurrentImagePath(), -1, resourceDirectory, MAX_PATH);
  if (resourceDirectory[wcslen(resourceDirectory)-1] == '\\') {
    resourceDirectory[wcslen(resourceDirectory)-1] = 0;
  }

  /* Look up shGetFolderPathW */
  shGetFolderPath = (void*)GetProcAddress(LoadLibraryA("SHFolder.dll"), 
                                          "SHGetFolderPathW");

  if(shGetFolderPath) {
    /* If we have shGetFolderPath use My Documents/My Squeak */
    int sz;
    /*shGetfolderPath does not return utf8*/
    if(shGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, untrustedUserDirectory) == S_OK) {
      sz = wcslen(untrustedUserDirectory);
      if(untrustedUserDirectory[sz-1] != '\\') 
        wcscat(untrustedUserDirectory, L"\\");
      wcscpy(myDocumentsFolder,untrustedUserDirectory);
      wcscat(untrustedUserDirectory, L"My Squeak");
    }
  }


  /* Query Squeak.ini for network installations */
  GetPrivateProfileStringW(L"Security", L"SecureDirectory",
                          secureUserDirectory, secureUserDirectory,
                          MAX_PATH, squeakIniNameW);
  if(fLowRights) {/* use alternate untrustedUserDirectory */
      GetPrivateProfileStringW(L"Security", L"UserDirectoryLow",
                          untrustedUserDirectory, untrustedUserDirectory,
                          MAX_PATH, squeakIniNameW);
  } else {
      GetPrivateProfileStringW(L"Security", L"UserDirectory",
                          untrustedUserDirectory, untrustedUserDirectory,
                          MAX_PATH, squeakIniNameW);
  }

  GetPrivateProfileStringW(L"Security", L"ResourceDirectory",
                          resourceDirectory, resourceDirectory,
                          MAX_PATH, squeakIniNameW);

  /* Attempt to read local user settings from registry */
  ok = RegOpenKeyA(HKEY_CURRENT_USER, HKEY_SQUEAK_ROOT, &hk);

  /* Read the secure directory from the subkey. */
  dwSize = MAX_PATH*sizeof(WCHAR);
  ok = RegQueryValueExW(hk, L"SecureDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize/2-2] != '\\') {
      tmp[dwSize/2-1] = '\\';
      tmp[dwSize/2] = 0;
    }
    wcscpy(secureUserDirectory, tmp);
  }

  /* Read the user directory from the subkey. */
  dwSize = MAX_PATH*sizeof(WCHAR);
  ok = RegQueryValueExW(hk, L"UserDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize/2-2] != '\\') {
      tmp[dwSize/2-1] = '\\';
      tmp[dwSize/2] = 0;
    }
    wcscpy(untrustedUserDirectory, tmp);
  }

  /* Read the resource directory from the subkey. */
  dwSize = MAX_PATH*sizeof(WCHAR);
  ok = RegQueryValueExW(hk, L"ResourceDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize/2-2] != '\\') {
      tmp[dwSize/2-1] = '\\';
      tmp[dwSize/2] = 0;
    }
    wcscpy(resourceDirectory, tmp);
  }

  RegCloseKey(hk);
  
  if(shGetFolderPath) {  
    dwSize = expandMyDocuments(untrustedUserDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      wcscpy(untrustedUserDirectory, tmp);

    dwSize = expandMyDocuments(secureUserDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      wcscpy(secureUserDirectory, tmp);

    dwSize = expandMyDocuments(resourceDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      wcscpy(resourceDirectory, tmp);
  }

  /* Expand the directories. */
  expandVariableInDirectory(untrustedUserDirectory, wDir, wTmp);
  expandVariableInDirectory(secureUserDirectory, wDir, wTmp);
  expandVariableInDirectory(resourceDirectory, wDir, wTmp);

  secureUserDirectoryLen = wcslen(secureUserDirectory);
  untrustedUserDirectoryLen = wcslen(untrustedUserDirectory);
  resourceDirectoryLen = wcslen(resourceDirectory);

  /* Keep a UTF-8 copy*/
  WideCharToMultiByte(CP_UTF8, 0, untrustedUserDirectory, -1, untrustedUserDirectoryUTF8, MAX_PATH_UTF8, NULL, NULL);
  WideCharToMultiByte(CP_UTF8, 0, secureUserDirectory   , -1, secureUserDirectoryUTF8   , MAX_PATH_UTF8, NULL, NULL);
  WideCharToMultiByte(CP_UTF8, 0, resourceDirectory     , -1, resourceDirectoryUTF8     , MAX_PATH_UTF8, NULL, NULL);

  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* private entries for restoring rights */
int _ioSetImageWrite(int enable) {
  if(enable == allowImageWrite) return 1;
  if(!allowImageWrite) {
    if(!sqAskSecurityYesNoQuestion("WARNING: Re-enabling the ability to write the image is a serious security hazard. Do you want to continue?"))
      return 0;
    if(!sqAskSecurityYesNoQuestion("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"))
      return 0;
    if(!sqAskSecurityYesNoQuestion("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"))
      return 0;
  }
  allowImageWrite = enable;
  return 1;
}

int _ioSetFileAccess(int enable) {
  if(enable == allowFileAccess) return 1;
  if(!allowFileAccess) {
    if (!sqAskSecurityYesNoQuestion("WARNING: Re-enabling the ability to access arbitrary files is a serious security hazard. Do you want to continue?"))
      return 0;
    if (!sqAskSecurityYesNoQuestion("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"))
      return 0;
    if (!sqAskSecurityYesNoQuestion("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"))
      return 0;
  }
  allowFileAccess = enable;
  return 1;
}

int _ioSetSocketAccess(int enable) {
  if(enable == allowSocketAccess) return 1;
  if(!allowSocketAccess) {
    if (!sqAskSecurityYesNoQuestion("WARNING: Re-enabling the ability to use sockets is a serious security hazard. Do you want to continue?"))
      return 0;
    if (!sqAskSecurityYesNoQuestion("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"))
      return 0;
    if (!sqAskSecurityYesNoQuestion("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"))
      return 0;
  }
  allowSocketAccess = enable;
  return 1;
}
