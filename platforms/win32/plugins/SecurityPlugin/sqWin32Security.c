/* Windows Vista support 
 * AUTHOR: Korakurider (kr)
 * CHANGE NOTES:
 *   1) untrustedDirectory is determined by "UserDirectoryLow" setting 
 *      in INI file if command line option "-lowRights" is specified.
 */

#include <windows.h>
#include <initguid.h>
#include <KnownFolders.h> /* FOLDERID_XXX */
#include <ShlObj.h>  /* SHGetKnownFolderPath */
#include <lmcons.h> /* UNLEN */
#include "sq.h"

#ifndef HKEY_SQUEAK_ROOT
/* the default place in the registry to look for */
#define HKEY_SQUEAK_ROOT TEXT("SOFTWARE\\Squeak")
#endif


static char* untrustedUserDirectory;
static int untrustedUserDirectoryLen;
static char* secureUserDirectory;
static int secureUserDirectoryLen;

/* imported from sqWin32Prefs.c */
extern TCHAR* squeakIniName;

/* imported from sqWin32Main.c */
extern BOOL fLowRights;  /* started as low integrity process, 
			need to use alternate untrustedUserDirectory */

void __cdecl CleanupSecurity(void);

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

  TCHAR *tUntrustedUserDirectory = NULL;
  UTF8_TO_TCHAR(untrustedUserDirectory, tUntrustedUserDirectory);
  if (pathLen >= untrustedUserDirectoryLen
      && 0 == lstrncmp(pathName, tUntrustedUserDirectory, untrustedUserDirectoryLen)) {
    if (pathLen > untrustedUserDirectoryLen + 2)
      return testDotDot(pathName, untrustedUserDirectoryLen + 2);
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


/* note: following is called from VM directly, not from plugin */
int ioInitSecurity(void) {

  TCHAR* tSecureUserDirectory = NULL;
  TCHAR* tUntrustedUserDirectory = NULL;

  atexit(CleanupSecurity);

  /* establish the secure user directory */
  RECALLOC_OR_RESET(tSecureUserDirectory, UNLEN + 1 + _tcslen(imagePath), sizeof(TCHAR), return 0);
  lstrcpy(tSecureUserDirectory, imagePath);
  {
    int dirLen = lstrlen(tSecureUserDirectory);
    DWORD dwSize = MAX_PATH_SQUEAK - dirLen;
    GetUserName(tSecureUserDirectory + dirLen, &dwSize);
  }

#define MY_SQUEAK TEXT("\\My Squeak")
#define MY_DOCUMENTS_VAR L"MYDOCUMENTS"

#ifdef _MSC_VER
  PWSTR documentsPath = NULL;
  if (S_OK == SHGetKnownFolderPath(&FOLDERID_Documents, 0, NULL, &documentsPath))
#else
  WCHAR documentsPath[MAX_PATH];
  if (S_OK == SHGetFolderPathW(NULL, CSIDL_PERSONAL, NULL, 0, documentsPath))
#endif
  {
#if defined(UNICODE)
    RECALLOC_OR_RESET(tUntrustedUserDirectory,
      wcslen(documentsPath) + _tcslen(MY_SQUEAK) + 1 /* \0 */,
      sizeof(WCHAR), return 0);
    lstrcpy(tUntrustedUserDirectory, documentsPath);
#else
    {
      int sz = WideCharToMultiByte(CP_ACP, 0, documentsPath, -1, NULL, 0, NULL, NULL);
      RECALLOC_OR_RESET(tUntrustedUserDirectory, 
        sz + _tcslen(MY_SQUEAK) + 1 /* \0 */,
        sizeof(char), return 0);
      WideCharToMultiByte(CP_ACP, 0, documentsPath, -1, tUntrustedUserDirectory, sz, NULL, NULL);
    }
#endif
    /* Set the Environment variabel MYDOCUMENTS to document path, so
       autormatic expansion can take care of things */
    SetEnvironmentVariableW(MY_DOCUMENTS_VAR, documentsPath);
    CoTaskMemFree(documentsPath);
    lstrcat(tUntrustedUserDirectory, MY_SQUEAK);
  } else {
    /* establish untrusted user directory */
    tUntrustedUserDirectory = _tcsdup(TEXT("C:\\My Squeak\\%USERNAME%"));
  }


  /* Query Squeak.ini for network installations */
  {
    TCHAR* tmp = calloc(MAX_PATH_SQUEAK + 1, sizeof(TCHAR));

#define GET_SQUEAK_INI(Section, Entry, Destination, FileName) {             \
    DWORD iniSz = GetPrivateProfileString(TEXT( #Section ), TEXT( #Entry ), \
       NULL, tmp, MAX_PATH_SQUEAK, FileName);                               \
    if (iniSz != 0) {                                                       \
      BOOL ok = TRUE;                                                       \
      RECALLOC_OR_RESET(Destination, iniSz + 1, sizeof(TCHAR), ok = FALSE); \
      if (ok) { lstrcpy(Destination, tmp);}}}                               \

    GET_SQUEAK_INI(Security, SecureDirectory, tSecureUserDirectory, squeakIniName);

    if (fLowRights) {/* use alternate untrusted UserDirectory */
      GET_SQUEAK_INI(Security, UserDirectoryLow, tUntrustedUserDirectory, squeakIniName);
    } else {
      GET_SQUEAK_INI(Security, UserDirectory, tUntrustedUserDirectory, squeakIniName);
    }
    free(tmp);
  }

  /* Attempt to read local user settings from registry */
  HKEY hk = NULL;
  LSTATUS ok = RegOpenKey(HKEY_CURRENT_USER, HKEY_SQUEAK_ROOT, &hk);
  if (ok == ERROR_SUCCESS) {
    /* Reg Key is there, read from it. */

#define GET_SQUEAK_REG(Hk, Subkey, Target) {                        \
    DWORD dwSize = 0;                                               \
    ok = RegQueryValueEx(hk, TEXT( #Subkey ), NULL, NULL,           \
                         NULL, &dwSize);                            \
    if (ok == ERROR_SUCCESS) { /* Value was found */                \
      RECALLOC_OR_RESET(Target, dwSize + 1, sizeof(BYTE), ok = -1); \
      if (ok == ERROR_SUCCESS) { /* Alloc was ok */                 \
        ok = RegQueryValueEx(hk, TEXT( #Subkey ), NULL, NULL,       \
                             (LPBYTE) Target, &dwSize);             \
        if (ok == ERROR_SUCCESS) { /* Value was copied */           \
          if (Target[dwSize - 2] != U_BACKSLASH[0]) {               \
            Target[dwSize - 1] = U_BACKSLASH[0];                    \
            Target[dwSize] = 0;}}}}}                                \

    /* Read the secure directory from the subkey. */
    GET_SQUEAK_REG(hk, SecureDirectory, tSecureUserDirectory);
    /* Read the user directory from the subkey. */
    GET_SQUEAK_REG(hk, UserDirectory, tUntrustedUserDirectory);
    RegCloseKey(hk);
  }

  /* See https://msdn.microsoft.com/en-us/library/ms724265(v=vs.85).aspx
    When using ANSI strings, the buffer size should be the string length, 
    plus terminating null character, plus one. When using Unicode strings, 
    the buffer size should be the string length plus the terminating null 
    character.
  */
#if defined(UNICODE)
#define EXTRA_SPACE 0
#else
#define EXTRA_SPACE 1
#endif


  
  TCHAR* tTmp = NULL;
  TCHAR* tFull = NULL;

#define GET_EXPANDED_PATH_TO_UTF8(in_tpath, out_utf8path) {        \
  /* Expand any environment variables in user directory. */        \
  DWORD envSz = ExpandEnvironmentStrings(in_tpath, NULL, 0);       \
  BOOL ok = TRUE;                                                  \
  DWORD tmpSize = envSz + 1 + EXTRA_SPACE;                         \
  RECALLOC_OR_RESET(tTmp, tmpSize, sizeof(TCHAR), ok = FALSE);     \
  if (ok) {                                                        \
    ExpandEnvironmentStrings(in_tpath, tTmp, envSz);               \
    /* Expand relative paths to absolute paths */                  \
    DWORD fullSize = GetFullPathName(tTmp, 0, NULL, NULL);         \
    RECALLOC_OR_RESET(tFull, fullSize, sizeof(TCHAR), ok = FALSE); \
    if (ok) {                                                      \
      char* uTmp = NULL;                                           \
      GetFullPathName(tTmp, fullSize, tFull, NULL);                \
      TCHAR_TO_UTF8(tFull, uTmp);                                  \
      if (out_utf8path) free(out_utf8path);                        \
      out_utf8path = _strdup(uTmp);}}}                             \


  GET_EXPANDED_PATH_TO_UTF8(tUntrustedUserDirectory, untrustedUserDirectory);
  GET_EXPANDED_PATH_TO_UTF8(tSecureUserDirectory, secureUserDirectory);

  secureUserDirectoryLen = strlen(secureUserDirectory);
  untrustedUserDirectoryLen = strlen(untrustedUserDirectory);

  return 1;

#undef EXTRA_SPACE
#undef MY_SQUEAK
#undef MY_DOCUMENTS_VAR
#undef GET_SQUEAK_REG
#undef GET_SQUEAK_INI
#undef GET_EXPANDED_PATH_TO_UTF8
}


void __cdecl CleanupSecurity(void)
{
  /* Be nice and clean up */
  free(untrustedUserDirectory);
  untrustedUserDirectory = NULL;
  untrustedUserDirectoryLen = 0;
  free(secureUserDirectory);
  secureUserDirectory = NULL;
  secureUserDirectoryLen = 0;
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
