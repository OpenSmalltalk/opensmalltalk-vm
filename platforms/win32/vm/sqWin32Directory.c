/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Directory.c
*   CONTENT: Directory management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   UPDATES:
*     1) Support for long path names added by using UNC prefix in that case
*        (Marcel Taeumel, Hasso Plattner Institute, Postdam, Germany)
*
*****************************************************************************/
#include <windows.h>

#include "sq.h"
#include "../plugins/FilePlugin/sqWin32File.h"
#ifdef PharoVM
# include <sys/types.h>
# include <sys/stat.h>
#endif

extern struct VirtualMachine *interpreterProxy;

#define FAIL() { return interpreterProxy->primitiveFail(); }

/***
	The interface to the directory primitive is path based.
	That is, the client supplies a Squeak string describing
	the path to the directory on every call. To avoid traversing
	this path on every call, a cache is maintained of the last
	path seen.
***/

/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2

#ifdef PharoVM
#define DEFAULT_DRIVE_PERMISSIONS (S_IRUSR | (S_IRUSR>>3) | (S_IRUSR>>6) | \
                                   S_IWUSR | (S_IWUSR>>3) | (S_IWUSR>>6) | \
                                   S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6))
  
static void read_permissions(sqInt *posixPermissions, WCHAR* path, int pathLength, int attr)
{
  *posixPermissions |= S_IRUSR | (S_IRUSR>>3) | (S_IRUSR>>6);
  if(!(attr & FILE_ATTRIBUTE_READONLY)) {
    *posixPermissions |= S_IWUSR | (S_IWUSR>>3) | (S_IWUSR>>6);
  }
  if(attr & FILE_ATTRIBUTE_DIRECTORY) {
    *posixPermissions |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
  }
  else if (path && path[pathLength - 4] == L'.') {
    WCHAR *ext = &path[pathLength - 3];
    if (!_wcsicmp (ext, L"COM")) {
      *posixPermissions |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
    }
    else if (!_wcsicmp (ext, L"EXE")) {
      *posixPermissions |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
    }
    else if (!_wcsicmp (ext, L"BAT")) {
      *posixPermissions |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
    }
    else if (!_wcsicmp (ext, L"CMD")) { 
      *posixPermissions |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
    }
  }
}

static int findFileFallbackOnSharingViolation(WCHAR *win32Path, WIN32_FILE_ATTRIBUTE_DATA* winAttrs) {
  WIN32_FIND_DATAW findData;
  HANDLE findHandle = FindFirstFileW(win32Path,&findData);
  if(findHandle == INVALID_HANDLE_VALUE) {
    return 0;
  }
  winAttrs->ftCreationTime = findData.ftCreationTime;
  winAttrs->ftLastWriteTime = findData.ftLastWriteTime;
  winAttrs->dwFileAttributes = findData.dwFileAttributes;
  winAttrs->nFileSizeLow = findData.nFileSizeLow;
  winAttrs->nFileSizeHigh = findData.nFileSizeHigh;
  FindClose(findHandle);
  return 1;
}
#endif


/* figure out if a case sensitive duplicate of the given path exists.
   useful for trying to stay in sync with case-sensitive platforms. */
int caseSensitiveFileMode = 0;

int hasCaseSensitiveDuplicate(WCHAR *path) {
  WCHAR *src, *dst, *prev;
  WCHAR* findPath = NULL;
  WIN32_FIND_DATAW findData; /* cached find data */
  HANDLE findHandle = 0; /* cached find handle */

  if(!caseSensitiveFileMode) return 0;

  if(!path) return 0;
  if(*path == 0) return 0;

  findPath = (WCHAR*)alloca((wcslen(path) + 1) * sizeof(WCHAR));

  /* figure out the root of the path (we can't test it) */
  dst = findPath;
  src = path;
  *dst++ = *src++;
  *dst++ = *src++;
  if(path[0] == L'\\' && path[1] == L'\\') {
    /* \\server\name resp. an UNC path */
    while(*src != 0 && *src != L'\\') *dst++ = *src++;
  } else if(path[1] != L':' || path[2] != L'\\') {
    /* Oops??? What is this??? */
    printf("hasCaseSensitiveDuplicate: Unrecognized path root\n");
    return 0;
  }
  *dst = 0;

  /* from the root, enumerate all the path components and find 
     potential mismatches */
  while(true) {
    /* skip backslashes */
    while(*src != 0 && *src == L'\\') src++;
    if(!*src) return 0; /* we're done */
    /* copy next path component into findPath */
    *dst++ = L'\\';
    prev = dst;
    while(*src != 0 && *src != L'\\') *dst++ = *src++;
    *dst = 0;
    /* now let's go find it */
    findHandle = FindFirstFileW(findPath, &findData);
    /* not finding a path means there is no duplicate */
    if(findHandle == INVALID_HANDLE_VALUE) return 0;
    FindClose(findHandle);
    {
      WCHAR *tmp = findData.cFileName;
      while(*tmp) if(*tmp++ != *prev++) break;
      if(*tmp == *prev) return 1; /* duplicate */
    }
  }
}

typedef union {
  struct {
    DWORD dwLow;
    DWORD dwHigh;
  };
  squeakFileOffsetType offset;
} win32FileOffset;

DWORD convertToSqueakTime(SYSTEMTIME st)
{ DWORD secs;
  DWORD dy;
  static DWORD nDaysPerMonth[14] = { 
    0,  0,  31,  59,  90, 120, 151,
      181, 212, 243, 273, 304, 334, 365 };
  /* Squeak epoch is Jan 1, 1901 */
  dy = st.wYear - 1901; /* compute delta year */
  secs = dy * 365 * 24 * 60 * 60       /* base seconds */
         + (dy >> 2) * 24 * 60 * 60;   /* seconds of leap years */
  /* check if month > 2 and current year is a leap year */
  if(st.wMonth > 2 && (dy & 0x0003) == 0x0003)
    secs += 24 * 60 * 60; /* add one day */
  /* add the days from the beginning of the year */
  secs += (nDaysPerMonth[st.wMonth] + st.wDay - 1) * 24 * 60 * 60;
  /* add the hours, minutes, and seconds */
  secs += st.wSecond + 60*(st.wMinute + 60*st.wHour);
  return secs;
}

int dir_Create(char *pathString, int pathLength)
{
  WCHAR *win32Path = NULL;

  /* convert the path name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, pathString, pathLength);

  return CreateDirectoryW(win32Path,NULL);
}

int dir_Delimitor(void)
{
  return '\\';
}

#ifdef PharoVM
int dir_Lookup(char *pathString, int pathLength, int index,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
               int *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
#else
int dir_Lookup(char *pathString, int pathLength, int index,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
               int *isDirectory, squeakFileOffsetType *sizeIfFile)
#endif
{
  /* Lookup the index-th entry of the directory with the given path, starting
     at the root of the file system. Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:
		0 	if a entry is found at the given index
		1	if the directory has fewer than index entries
		2	if the given path has bad syntax or does not reach a directory
  */
  static WIN32_FIND_DATAW findData; /* cached find data */
  static HANDLE findHandle = 0; /* cached find handle */
  static int lastIndex = 0; /* cached last index */
  static WCHAR *lastString = NULL; /* cached last path */
  static int lastStringLength = 0; /* cached length of last path */
  WCHAR *win32Path = NULL;
  int win32PathLength = 0;
  FILETIME fileTime;
  SYSTEMTIME sysTime;
  int i, sz;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;
#ifdef PharoVM
  *posixPermissions = 0;
  *isSymlink        = 0;
#endif

  /* convert the path name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, pathString, pathLength);
  win32PathLength = wcslen(win32Path);

  /* check for a dir cache hit (but NEVER on the top level) */
  if(win32PathLength > 0 && 
     lastStringLength == win32PathLength && 
     lastIndex + 1 == index) {
    for(i=0;i<win32PathLength; i++) {
      if(lastString[i] != win32Path[i]) break;
    }
    if(i == win32PathLength) {
      lastIndex = index;
      index = 2;
      goto dirCacheHit;
    }
  }

  if(findHandle) {
    FindClose(findHandle);
    findHandle = NULL;
  }
  lastIndex = index;

#if !defined(_WIN32_WCE)
  /* Like Unix, Windows CE does not have drive letters */
  if(win32PathLength == 0) { 
    /* we're at the top of the file system --- return possible drives */
    int mask;

    mask = GetLogicalDrives();
    for(i=0;i<26; i++)
      if(mask & (1 << i))
	if(--index == 0) {
	  /* found the drive ! */
          name[0]           = 'A'+i;
          name[1]	          = ':';
          *nameLength       = 2;
          *creationDate     = 0;
          *modificationDate = 0;
          *isDirectory      = true;
          *sizeIfFile       = 0;
#ifdef PharoVM
	  *posixPermissions |= DEFAULT_DRIVE_PERMISSIONS;
#endif
          return ENTRY_FOUND;
        }
    return NO_MORE_ENTRIES;
  }
#endif /* !defined(_WIN32_WCE) */

  /* cache the path */
  if(lastString) free(lastString);
  lastString = (WCHAR*)calloc(win32PathLength+1, sizeof(WCHAR));
//  wcscpy_s(lastString, win32PathLength, win32Path);
  wcscpy(lastString, win32Path);
  lastString[win32PathLength] = 0;
  lastStringLength = win32PathLength;


  if(hasCaseSensitiveDuplicate(win32Path)) {
    lastStringLength = 0;
    return BAD_PATH;
  }

  /* Ensure trailing delimiter and add wildcard pattern. */
  if(win32Path[win32PathLength-1] != L'\\') {
    win32PathLength += 2;
  } else {
    win32PathLength++;
  };
  REALLOC_WIN32_PATH(win32Path, win32PathLength);
  win32Path[win32PathLength-1-1] = L'\\';
  win32Path[win32PathLength-1] = L'*';
  win32Path[win32PathLength] = 0; // Not needed. See REALLOC_WIN32_PATH.

  /* and go looking for entries */
  findHandle = FindFirstFileW(win32Path,&findData);
  if(findHandle == INVALID_HANDLE_VALUE) {
    /* Directory could be empty, so we must check for that */
    DWORD dwErr = GetLastError();
#ifdef PharoVM
    return (dwErr == ERROR_NO_MORE_FILES || dwErr == ERROR_ACCESS_DENIED) ? NO_MORE_ENTRIES : BAD_PATH;
#else
    return (dwErr == ERROR_NO_MORE_FILES) ? NO_MORE_ENTRIES : BAD_PATH;
#endif
  }
  while(1) {
    /* check for '.' or '..' directories */
    if(findData.cFileName[0] == L'.')
      if(findData.cFileName[1] == 0 ||
	 (findData.cFileName[1] == L'.' &&
	  findData.cFileName[2] == 0))
	index = index + 1; /* hack us back to the last index */
    if(index <= 1) break;
  dirCacheHit: /* If we come to this label we've got a hit in the dir cache */
    if (!FindNextFileW(findHandle,&findData)) {
      FindClose(findHandle);
      findHandle = NULL;
      return NO_MORE_ENTRIES;
    }
    index = index - 1;
  }

  /* convert to UTF-8 */
  sz = WideCharToMultiByte(CP_UTF8, 0, findData.cFileName, -1, name, MAX_PATH, NULL, NULL);
  *nameLength = sz-1;

  FileTimeToLocalFileTime(&findData.ftCreationTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *creationDate = convertToSqueakTime(sysTime);
  FileTimeToLocalFileTime(&findData.ftLastWriteTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *modificationDate = convertToSqueakTime(sysTime);

#ifdef PharoVM
  read_permissions(posixPermissions, findData.cFileName, sz, findData.dwFileAttributes); 
#endif

  if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
    *isDirectory= true;
  else {
    win32FileOffset ofs;
    ofs.dwLow = findData.nFileSizeLow;
    ofs.dwHigh = findData.nFileSizeHigh;
    *sizeIfFile = ofs.offset;
  }
  return ENTRY_FOUND;
}

#ifdef PharoVM
int dir_EntryLookup(char *pathString, int pathLength, char* nameString, int nameStringLength,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
                    int *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)
#else
int dir_EntryLookup(char *pathString, int pathLength, char* nameString, int nameStringLength,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
	       int *isDirectory, squeakFileOffsetType *sizeIfFile)
#endif
{
  /* Lookup a given file in a given named directory.
     Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:
		0 	if found (a file or directory 'nameString' exists in directory 'pathString')
		1	if the directory has no such entry
		2	if the given path has bad syntax or does not reach a directory
  */

  WIN32_FILE_ATTRIBUTE_DATA winAttrs;
  WCHAR *win32Path = NULL;
  int win32PathLength = 0;
  FILETIME fileTime;
  SYSTEMTIME sysTime;
  int sz, fsz;
#ifdef PharoVM
  HANDLE findHandle;
  int i;
#endif

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;
#ifdef PharoVM
  *posixPermissions = 0;
  *isSymlink        = 0;
#endif

  /* convert the path name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, pathString, pathLength);
  win32PathLength = wcslen(win32Path);

#if !defined(_WIN32_WCE)
  /* Like Unix, Windows CE does not have drive letters */
  if (win32PathLength == 0) { 
    /* we're at the top of the file system --- return possible drives */
    char drive = toupper(nameString[0]);
    int mask;
    if (nameStringLength != 2 
	|| (drive < 'A') || (drive > 'Z') 
	|| (nameString[1] != ':')) {
      return NO_MORE_ENTRIES;
    }
    mask = GetLogicalDrives();
    if (mask & (1 << (drive - 'A'))) {
      /* found the drive ! */
      name[0]           = drive;
      name[1]	        = ':';
      *nameLength       = 2;
      *creationDate     = 0;
      *modificationDate = 0;
      *isDirectory      = true;
      *sizeIfFile       = 0;
#ifdef PharoVM
      *posixPermissions |= DEFAULT_DRIVE_PERMISSIONS;
#endif
      return ENTRY_FOUND;
    }
    return NO_MORE_ENTRIES;
  }
#endif /* !defined(_WIN32_WCE) */

  if (hasCaseSensitiveDuplicate(win32Path)) {
    return BAD_PATH;
  }

  /* Ensure trailing delimiter and add filename. */
  if(win32Path[win32PathLength-1] != L'\\') win32PathLength++;
  fsz = MultiByteToWideChar(CP_UTF8, 0, nameString, nameStringLength, NULL, 0);
  sz = win32PathLength;
  win32PathLength += fsz;
  if(win32PathLength >= 32767) FAIL();
  REALLOC_WIN32_PATH(win32Path, win32PathLength);
  win32Path[win32PathLength-fsz-1] = L'\\';
  MultiByteToWideChar(CP_UTF8, 0, nameString, nameStringLength, win32Path+sz, fsz); 
  win32Path[win32PathLength] = 0; // Not needed. See REALLOC_WIN32_PATH.

  if(!GetFileAttributesExW(win32Path, 0, &winAttrs)) {
#ifdef PharoVM
    if(GetLastError() == ERROR_SHARING_VIOLATION) {
      if(!findFileFallbackOnSharingViolation(win32Path, &winAttrs)) return NO_MORE_ENTRIES;
    } else {
      return NO_MORE_ENTRIES;
    }
#else
      return NO_MORE_ENTRIES;
#endif
  }

  memcpy(name, nameString, nameStringLength);
  *nameLength = nameStringLength;

  FileTimeToLocalFileTime(&winAttrs.ftCreationTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *creationDate = convertToSqueakTime(sysTime);
  FileTimeToLocalFileTime(&winAttrs.ftLastWriteTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *modificationDate = convertToSqueakTime(sysTime);

  if (winAttrs.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
    *isDirectory= true;
  else {
    win32FileOffset ofs;
    ofs.dwLow = winAttrs.nFileSizeLow;
    ofs.dwHigh = winAttrs.nFileSizeHigh;
    *sizeIfFile = ofs.offset;
  }

#ifdef PharoVM
  read_permissions(posixPermissions, win32Path, win32PathLength, winAttrs.dwFileAttributes);
#endif
  return ENTRY_FOUND;
}


int dir_SetMacFileTypeAndCreator(char *filename, int filenameSize,
			     char *fType, char *fCreator)
{
  /* Win32 files are untyped, and the creator is correct by default */
  return true;
}

int dir_GetMacFileTypeAndCreator(char *filename, int filenameSize,
			     char *fType, char *fCreator)
{
  /* Win32 files are untyped, and the creator is correct by default */
  FAIL();
}

int dir_Delete(char *pathString, int pathLength) {
  /* Delete the existing directory with the given path. */
  WCHAR *win32Path = NULL;

  /* convert the file name into a null-terminated C string */
  ALLOC_WIN32_PATH(win32Path, pathString, pathLength);

  if(hasCaseSensitiveDuplicate(win32Path)) return false;
  return RemoveDirectoryW(win32Path) == 0 ? false : true;
}
