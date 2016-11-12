/* Windows Vista support 
 * AUTHOR: Korakurider (kr)
 * CHANGE NOTES:
 *   1) untrustedDirectory is determined by "UserDirectoryLow" setting 
 *      in INI file if command line option "-lowRights" is specified.
 */

#include <windows.h>
#include <shlobj.h> /* CSIDL_XXX */
#include "sq.h"

#ifndef HKEY_SQUEAK_ROOT
/* the default place in the registry to look for */
#define HKEY_SQUEAK_ROOT "SOFTWARE\\Squeak"
#endif

static HRESULT (__stdcall *shGetFolderPath)(HWND, int, HANDLE, DWORD, WCHAR*);

static TCHAR untrustedUserDirectory[MAX_PATH];
static int untrustedUserDirectoryLen;
static TCHAR secureUserDirectory[MAX_PATH];
static int secureUserDirectoryLen;
static TCHAR resourceDirectory[MAX_PATH];
static int resourceDirectoryLen;

/* imported from sqWin32Prefs.c */
extern TCHAR squeakIniName[MAX_PATH];

/* imported from sqWin32Main.c */
extern BOOL fLowRights;  /* started as low integrity process, 
                        need to use alternate untrustedUserDirectory */

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* file security */
static int allowFileAccess = 1;  /* full access to files */
static const TCHAR U_DOT[] = TEXT(".");

static int testDotDot(TCHAR *pathName, int index) {
  while(pathName[index]) {
    if(pathName[index] == U_DOT[0]) {
      if(pathName[index-1] == U_DOT[0]) {
        if (pathName[index-2] == U_BACKSLASH[0]) {
          return 0; /* Gotcha! */
        }
      }
    }
    index++;
  }
  return 1;
}

static int lstrncmp(TCHAR *s1, TCHAR *s2, int len) {
  int s1Len = lstrlen(s1);
  int s2Len = lstrlen(s2);
  int max = min(s1Len, min(s2Len, len));
  int i;
  for (i = 0; i < max; i++) {
    if (s1[i] > s2[i]) {
      return 1;
    } else if (s1[i] < s2[i]) {
      return -1;
    }
  }
  return 0;
}

static int isAccessiblePathName(TCHAR *pathName, int writeFlag) {
  int pathLen = lstrlen(pathName);
  if (pathLen > (MAX_PATH - 1)) return 0;

  if (pathLen >= untrustedUserDirectoryLen
      && 0 == lstrncmp(pathName, untrustedUserDirectory, untrustedUserDirectoryLen)) {
    if (pathLen > untrustedUserDirectoryLen + 2)
      return testDotDot(pathName, untrustedUserDirectoryLen+2);
    return 1;
  }
  if (writeFlag)
    return 0;

  if (pathLen >= resourceDirectoryLen
      &&  0 == lstrncmp(pathName, resourceDirectory, resourceDirectoryLen)) {
    if (pathLen > resourceDirectoryLen + 2)
      return testDotDot(pathName, resourceDirectoryLen+2);
    return 1;
  }
  return 0;
}

static int isAccessibleFileName(TCHAR *fileName, int writeFlag) {
  return isAccessiblePathName(fileName, writeFlag);
}

/* directory access */
int ioCanCreatePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength), 1);
}

int ioCanListPathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength), 0);
}

int ioCanDeletePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength), 1);
}

/* file access */
int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength), writeFlag);
}

int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  return ioCanOpenFileOfSizeWritable(pathString,pathStringLength,writeFlag);
}
int ioCanDeleteFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength), 1);
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength), 1);
}


int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

/* disabling/querying */
int ioDisableFileAccess(void) {
  allowFileAccess = 0;
  return 0;
}

int ioHasFileAccess(void) {
  return allowFileAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* image security */

static int allowImageWrite = 1;  /* allow writing the image */
sqInt ioCanRenameImage(void) {
  return allowImageWrite; /* only when we're allowed to save the image */
}

sqInt ioCanWriteImage(void) {
  return allowImageWrite;
}

sqInt ioDisableImageWrite(void) {
  allowImageWrite = 0;
  return 0;
}
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* socket security - for now it's all or nothing */
static int allowSocketAccess = 1; /* allow access to sockets */

int ioCanCreateSocketOfType(int netType, int socketType) {
  return allowSocketAccess;
}

int ioCanConnectToPort(int netAddr, int port) {
  return allowSocketAccess;
}

int ioCanListenOnPort(void* s, int port) {
  return allowSocketAccess;
}

int ioDisableSocketAccess() {
  allowSocketAccess = 0;
  return 0;
}

int ioHasSocketAccess() {
  return allowSocketAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* SecurityPlugin primitive support */

char *ioGetSecureUserDirectory(void) {
  return secureUserDirectory;
}

char *ioGetUntrustedUserDirectory(void) {
  return untrustedUserDirectory;
}

/* helper function to expand %MYDOCUMENTSFOLDER% */

int expandMyDocuments(char *pathname, char *replacement, char *result)
{
  TCHAR search4[MAX_PATH+1];
  TCHAR *start;

  lstrcpy(search4, TEXT("%MYDOCUMENTS%"));

  if(!(start = strstr(pathname, search4))) return 0;

  strncpy(result, pathname, start-pathname); 
  result[start-pathname] = '\0';
  sprintf(result+(start-pathname),"%s%s", replacement, start+strlen(search4));
  
  return strlen(result);
}



/* note: following is called from VM directly, not from plugin */
sqInt ioInitSecurity(void) {
  DWORD dwType, dwSize, ok;
  TCHAR tmp[MAX_PATH+1];
  WCHAR wTmp[MAX_PATH+1];
  WCHAR wDir[MAX_PATH+1];
  TCHAR myDocumentsFolder[MAX_PATH+1];  
  HKEY hk;
  int dirLen;

  /* establish the secure user directory */
  lstrcpy(secureUserDirectory, imagePath);
  dirLen = lstrlen(secureUserDirectory);
  dwSize = MAX_PATH-dirLen;
  GetUserName(secureUserDirectory+dirLen, &dwSize);

  /* establish untrusted user directory */
  lstrcpy(untrustedUserDirectory, TEXT("C:\\My Squeak\\%USERNAME%"));

  /* establish untrusted user directory */
  lstrcpy(resourceDirectory, imagePath);
  if (resourceDirectory[lstrlen(resourceDirectory)-1] == '\\') {
    resourceDirectory[lstrlen(resourceDirectory)-1] = 0;
  }

  /* Look up shGetFolderPathW */
  shGetFolderPath = (void*)GetProcAddress(LoadLibrary("SHFolder.dll"), 
                                          "SHGetFolderPathW");

  if(shGetFolderPath) {
    /* If we have shGetFolderPath use My Documents/My Squeak */
    WCHAR widepath[MAX_PATH];
    int sz;
    /*shGetfolderPath does not return utf8*/
    if(shGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, widepath) == S_OK) {
       WideCharToMultiByte(CP_ACP,0,widepath,-1,untrustedUserDirectory,
                          MAX_PATH,NULL,NULL); 
      sz = strlen(untrustedUserDirectory);
      if(untrustedUserDirectory[sz-1] != '\\') 
        strcat(untrustedUserDirectory, "\\");
           lstrcpy(myDocumentsFolder,untrustedUserDirectory);
      strcat(untrustedUserDirectory, "My Squeak");
    }
  }


  /* Query Squeak.ini for network installations */
  GetPrivateProfileString(TEXT("Security"), TEXT("SecureDirectory"),
                          secureUserDirectory, secureUserDirectory,
                          MAX_PATH, squeakIniName);
  if(fLowRights) {/* use alternate untrustedUserDirectory */
      GetPrivateProfileString(TEXT("Security"), TEXT("UserDirectoryLow"),
                          untrustedUserDirectory, untrustedUserDirectory,
                          MAX_PATH, squeakIniName);
  } else {
      GetPrivateProfileString(TEXT("Security"), TEXT("UserDirectory"),
                          untrustedUserDirectory, untrustedUserDirectory,
                          MAX_PATH, squeakIniName);
  }

  GetPrivateProfileString(TEXT("Security"), TEXT("ResourceDirectory"),
                          resourceDirectory, resourceDirectory,
                          MAX_PATH, squeakIniName);

  /* Attempt to read local user settings from registry */
  ok = RegOpenKey(HKEY_CURRENT_USER, HKEY_SQUEAK_ROOT, &hk);

  /* Read the secure directory from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,"SecureDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize-2] != '\\') {
      tmp[dwSize-1] = '\\';
      tmp[dwSize] = 0;
    }
    strcpy(secureUserDirectory, tmp);
  }

  /* Read the user directory from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,"UserDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize-2] != '\\') {
      tmp[dwSize-1] = '\\';
      tmp[dwSize] = 0;
    }
    strcpy(untrustedUserDirectory, tmp);
  }

  /* Read the resource directory from the subkey. */
  dwSize = MAX_PATH;
  ok = RegQueryValueEx(hk,"ResourceDirectory",NULL, &dwType, 
                       (LPBYTE) tmp, &dwSize);
  if(ok == ERROR_SUCCESS) {
    if(tmp[dwSize-2] != '\\') {
      tmp[dwSize-1] = '\\';
      tmp[dwSize] = 0;
    }
    strcpy(resourceDirectory, tmp);
  }

  RegCloseKey(hk);
  
  if(shGetFolderPath) {  
    dwSize = expandMyDocuments(untrustedUserDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      strcpy(untrustedUserDirectory, tmp);

    dwSize = expandMyDocuments(secureUserDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      strcpy(secureUserDirectory, tmp);

    dwSize = expandMyDocuments(resourceDirectory, myDocumentsFolder, tmp);
    if(dwSize > 0 && dwSize < MAX_PATH)
      strcpy(resourceDirectory, tmp);
  }

  /* Expand any environment variables in user directory. */
  MultiByteToWideChar(CP_ACP, 0, untrustedUserDirectory, -1, wDir, MAX_PATH);
  ExpandEnvironmentStringsW(wDir, wTmp, MAX_PATH-1);
  /* Expand relative paths to absolute paths */
  GetFullPathNameW(wTmp, MAX_PATH, wDir, NULL);
  WideCharToMultiByte(CP_UTF8,0,wDir,-1,untrustedUserDirectory,MAX_PATH,NULL,NULL);

  /* same for the secure directory*/
  MultiByteToWideChar(CP_ACP, 0, secureUserDirectory, -1, wDir, MAX_PATH);
  ExpandEnvironmentStringsW(wDir, wTmp, MAX_PATH-1);
  /* Expand relative paths to absolute paths */
  GetFullPathNameW(wTmp, MAX_PATH, wDir, NULL);
  WideCharToMultiByte(CP_UTF8,0,wDir,-1,secureUserDirectory,MAX_PATH,NULL,NULL);

  /* and for the resource directory*/
  MultiByteToWideChar(CP_ACP, 0, resourceDirectory, -1, wDir, MAX_PATH);
  ExpandEnvironmentStringsW(wDir, wTmp, MAX_PATH-1);
  /* Expand relative paths to absolute paths */
  GetFullPathNameW(wTmp, MAX_PATH, wDir, NULL);
  WideCharToMultiByte(CP_UTF8,0,wDir,-1,resourceDirectory,MAX_PATH,NULL,NULL);

  secureUserDirectoryLen = lstrlen(secureUserDirectory);
  untrustedUserDirectoryLen = lstrlen(untrustedUserDirectory);
  resourceDirectoryLen = lstrlen(resourceDirectory);

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
    if(MessageBox(stWindow, TEXT("WARNING: Re-enabling the ability to write the image is a serious security hazard. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
  }
  allowImageWrite = enable;
  return 1;
}

int _ioSetFileAccess(int enable) {
  if(enable == allowFileAccess) return 1;
  if(!allowFileAccess) {
    if(MessageBox(stWindow, TEXT("WARNING: Re-enabling the ability to access arbitrary files is a serious security hazard. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
  }
  allowFileAccess = enable;
  return 1;
}

int _ioSetSocketAccess(int enable) {
  if(enable == allowSocketAccess) return 1;
  if(!allowSocketAccess) {
    if(MessageBox(stWindow, TEXT("WARNING: Re-enabling the ability to use sockets is a serious security hazard. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: Untrusted code could WIPE OUT your entire hard disk, STEAL your credit card information and send your PERSONAL documents to the entire world. Do you really want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
    if(MessageBox(stWindow, TEXT("WARNING: This is your last chance. If you proceed you will have to deal with the implications on your own. WE ARE REJECTING EVERY RESPONSIBILITY IF YOU CLICK ON YES. Do you want to continue?"), TEXT("Squeak Security Alert"), MB_YESNO | MB_ICONSTOP) != IDYES)
      return 0;
  }
  allowSocketAccess = enable;
  return 1;
}
