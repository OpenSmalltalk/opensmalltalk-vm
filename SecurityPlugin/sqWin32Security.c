#include <windows.h>
#include <shlobj.h> /* CSIDL_XXX */
#include "sq.h"

#ifndef HKEY_SQUEAK_ROOT
/* the default place in the registry to look for */
#define HKEY_SQUEAK_ROOT "SOFTWARE\\Squeak"
#endif

static HRESULT __stdcall (*shGetFolderPath)(HWND, int, HANDLE, DWORD, WCHAR*);

static TCHAR untrustedUserDirectory[MAX_PATH];
static TCHAR secureUserDirectory[MAX_PATH];

/* imported from sqWin32Prefs.c */
extern TCHAR squeakIniName[MAX_PATH];

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* file security */
static int allowFileAccess = 1;  /* full access to files */
static const TCHAR U_DOT[] = TEXT(".");

static int isAccessiblePathName(TCHAR *pathName) {
  int i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<lstrlen(untrustedUserDirectory)-1; i++)
    if(untrustedUserDirectory[i] != pathName[i]) return 0;
  /* special check for the trusted directory */
  if(pathName[i] == 0) return 1; /* allow access to trusted directory */
  /* check last character in image path (e.g., backslash) */
  if(untrustedUserDirectory[i] != pathName[i]) return 0;
  /* check if somebody wants to trick us into using relative
     paths ala c:\My Squeak\allowed\..\..\" */
  while(pathName[i]) {
    if(pathName[i] == U_DOT[0]) {
      if(pathName[i+1] == U_DOT[0])
	return 0; /* Gotcha! */
    }
    i++;
  }
  return 1;
}

static int isAccessibleFileName(TCHAR *fileName) {
  int i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<lstrlen(untrustedUserDirectory); i++)
    if(untrustedUserDirectory[i] != fileName[i]) return 0;
  /* check if somebody wants to trick us into using relative
     paths ala c:\My Squeak\allowed\..\..\" */
  while(fileName[i]) {
    if(fileName[i] == U_DOT[0]) {
      if(fileName[i+1] == U_DOT[0])
	return 0; /* Gotcha! */
    }
    i++;
  }
  return 1;
}

/* directory access */
int ioCanCreatePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

int ioCanListPathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

int ioCanDeletePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

/* file access */
int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  return ioCanOpenFileOfSizeWritable(pathString,pathStringLength,writeFlag);
}
int ioCanDeleteFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
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
int ioCanRenameImage(void) {
  return allowImageWrite; /* only when we're allowed to save the image */
}

int ioCanWriteImage(void) {
  return allowImageWrite;
}

int ioDisableImageWrite(void) {
  allowImageWrite = 0;
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

/* note: following is called from VM directly, not from plugin */
int ioInitSecurity(void) {
  DWORD dwType, dwSize, ok;
  TCHAR tmp[MAX_PATH+1];
  HKEY hk;
  int dirLen;

  /* establish the secure user directory */
  lstrcpy(secureUserDirectory, imagePath);
  dirLen = lstrlen(secureUserDirectory);
  dwSize = MAX_PATH-dirLen;
  GetUserName(secureUserDirectory+dirLen, &dwSize);

  /* establish untrusted user directory */
  lstrcpy(untrustedUserDirectory, TEXT("C:\\My Squeak\\%USERNAME%"));
  dirLen = lstrlen(untrustedUserDirectory);

  /* Look up shGetFolderPathW */
  shGetFolderPath = (void*)GetProcAddress(LoadLibrary("SHFolder.dll"), 
					  "SHGetFolderPathW");

  if(shGetFolderPath) {
    /* If we have shGetFolderPath use My Documents/My Squeak */
    WCHAR widepath[MAX_PATH];
    int sz;
    if(shGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, widepath) == S_OK) {
      WideCharToMultiByte(CP_UTF8,0,widepath,-1,untrustedUserDirectory,
			  MAX_PATH,NULL,NULL);
      sz = strlen(untrustedUserDirectory);
      if(untrustedUserDirectory[sz-1] != '\\') 
	strcat(untrustedUserDirectory, "\\");
      strcat(untrustedUserDirectory, "My Squeak");
    }
  }


  /* Query Squeak.ini for network installations */
  GetPrivateProfileString(TEXT("Security"), TEXT("SecureDirectory"),
			  secureUserDirectory, secureUserDirectory,
			  MAX_PATH, squeakIniName);
  GetPrivateProfileString(TEXT("Security"), TEXT("UserDirectory"),
			  untrustedUserDirectory, untrustedUserDirectory,
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
  RegCloseKey(hk);

  /* Expand any environment variables in user directory. */
  dwSize = ExpandEnvironmentStrings(untrustedUserDirectory, tmp, MAX_PATH-1);
  if(dwSize > 0 && dwSize < MAX_PATH)
    strcpy(untrustedUserDirectory, tmp);

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
