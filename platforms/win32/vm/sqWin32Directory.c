/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Directory.c
*   CONTENT: Directory management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Directory.c,v 1.4 2003/06/21 18:16:24 andreasraab Exp $
*
*   NOTES:
*
*****************************************************************************/
#include <windows.h>
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;

#ifndef NO_RCSID
  static char RCSID[]="$Id: sqWin32Directory.c,v 1.4 2003/06/21 18:16:24 andreasraab Exp $";
#endif

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

static TCHAR DELIMITER[] = TEXT("\\");
static TCHAR DOT[] = TEXT(".");

/* figure out if a case sensitive duplicate of the given path exists.
   useful for trying to stay in sync with case-sensitive platforms. */
int caseSensitiveFileMode = 0;

int hasCaseSensitiveDuplicate(TCHAR *path) {
  TCHAR *src, *dst, *prev;
  TCHAR findPath[MAX_PATH];
  WIN32_FIND_DATA findData; /* cached find data */
  HANDLE findHandle = 0; /* cached find handle */

  if(!caseSensitiveFileMode) return 0;

  if(!path) return 0;
  if(*path == 0) return 0;

#ifdef DEBUG
  printf("hasCaseSensitiveDuplicate: Checking %s\n", path);
#endif

  /* figure out the root of the path (we can't test it) */
  dst = findPath;
  src = path;
  *dst++ = *src++;
  *dst++ = *src++;
  if(path[0] == '\\' && path[1] == '\\') {
    /* \\server\name */
    while(*src != 0 && *src != '\\') *dst++ = *src++;
  } else if(path[1] != ':' || path[2] != '\\') {
    /* Oops??? What is this??? */
    printf("hasCaseSensitiveDuplicate: Unrecognized path root in %s\n", path);
    return 0;
  }
  *dst = 0;
#ifdef DEBUG
  printf("%s\n", findPath);
#endif
  /* from the root, enumerate all the path components and find potential mismatches */
  while(true) {
    /* skip backslashes */
    while(*src != 0 && *src == '\\') src++;
    if(!*src) {
      /* we're done */
#ifdef DEBUG
      printf("Okay\n");
#endif
      return 0;
    }
    /* copy next path component into findPath */
    *dst++ = '\\';
    prev = dst;
    while(*src != 0 && *src != '\\') *dst++ = *src++;
    *dst = 0;
#ifdef DEBUG
    printf("%s", findPath);
#endif
    /* now let's go find it */
    findHandle = FindFirstFile(findPath, &findData);
    if(findHandle == INVALID_HANDLE_VALUE) {
      /* not finding a path means there is no duplicate */
#ifdef DEBUG
      printf(" not found (errCode: %x)\n", GetLastError());
#endif
      return 0;
    }
    FindClose(findHandle);
    if(lstrcmp(findData.cFileName, prev) != 0) {
      /* duplicate! */
#ifdef DEBUG
      printf("duplicate: %s\n", findData.cFileName);
#endif
      return 1;
    }
#ifdef DEBUG
    printf(" ok \n");
#endif
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

int dir_Create(char *pathString, int pathStringLength)
{
  /* Create a new directory with the given path. By default, this
     directory is created relative to the cwd. */
  TCHAR *win32Path = fromSqueak(pathString, pathStringLength);
  return CreateDirectory(win32Path,NULL);
}

int dir_Delimitor(void)
{
  return DELIMITER[0];
}

int dir_Lookup(char *pathString, int pathStringLength, int index,
/* outputs: */ char *name, int *nameLength, int *creationDate, int *modificationDate,
	       int *isDirectory, squeakFileOffsetType *sizeIfFile)
{
  /* Lookup the index-th entry of the directory with the given path, starting
     at the root of the file system. Set the name, name length, creation date,
     creation time, directory flag, and file size (if the entry is a file).
     Return:
		0 	if a entry is found at the given index
		1	if the directory has fewer than index entries
		2	if the given path has bad syntax or does not reach a directory
  */
  static WIN32_FIND_DATA findData; /* cached find data */
  static HANDLE findHandle = 0; /* cached find handle */
  static int lastIndex = 0; /* cached last index */
  static char lastString[MAX_PATH+1]; /* cached last path */
  static int lastStringLength = 0; /* cached length of last path */
  TCHAR *win32Path;
  FILETIME fileTime;
  SYSTEMTIME sysTime;
  int i;

  /* default return values */
  *name             = 0;
  *nameLength       = 0;
  *creationDate     = 0;
  *modificationDate = 0;
  *isDirectory      = false;
  *sizeIfFile       = 0;

  /* check for a dir cache hit (but NEVER on the top level) */
  if(pathStringLength && 
     lastStringLength == pathStringLength && 
     lastIndex + 1 == index) {
    for(i=0;i<pathStringLength; i++) {
      if(lastString[i] != pathString[i])
	break;
    }
    if(i == pathStringLength) {
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
  if(pathStringLength == 0) { 
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
          return ENTRY_FOUND;
        }
    return NO_MORE_ENTRIES;
  }
#endif /* !defined(_WIN32_WCE) */

  /* cache the path */
  for(i=0; i < pathStringLength;i++)
    lastString[i] = pathString[i];
  lastString[pathStringLength] = 0;
  lastStringLength = pathStringLength;

  /* convert the path to a win32 string */
  win32Path = fromSqueak(pathString, pathStringLength);
  if(hasCaseSensitiveDuplicate(win32Path)) {
    lastStringLength = 0;
    return BAD_PATH;
  }
  if(win32Path[pathStringLength-1] != DELIMITER[0])
    lstrcat(win32Path,DELIMITER);
  lstrcat(win32Path,TEXT("*"));

  /* and go looking for entries */
  findHandle = FindFirstFile(win32Path,&findData);
  if(findHandle == INVALID_HANDLE_VALUE) {
    /* Directory could be empty, so we must check for that */
    DWORD dwErr = GetLastError();
    return (dwErr == ERROR_NO_MORE_FILES) ? NO_MORE_ENTRIES : BAD_PATH;
  }
  while(1) {
    /* check for '.' or '..' directories */
    if(findData.cFileName[0] == DOT[0])
      if(findData.cFileName[1] == 0 ||
	 (findData.cFileName[1] == DOT[0] &&
	  findData.cFileName[2] == 0))
	index = index + 1; /* hack us back to the last index */
    if(index <= 1) break;
  dirCacheHit: /* If we come to this label we've got a hit in the dir cache */
    if (!FindNextFile(findHandle,&findData)) {
      FindClose(findHandle);
      findHandle = NULL;
      return NO_MORE_ENTRIES;
    }
    index = index - 1;
  }

  *nameLength = lstrlen(findData.cFileName);
  for (i=0;i<=*nameLength;i++)
    name[i] = (char)findData.cFileName[i];

  FileTimeToLocalFileTime(&findData.ftCreationTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *creationDate = convertToSqueakTime(sysTime);
  FileTimeToLocalFileTime(&findData.ftLastWriteTime, &fileTime);
  FileTimeToSystemTime(&fileTime, &sysTime);
  *modificationDate = convertToSqueakTime(sysTime);

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

dir_SetMacFileTypeAndCreator(char *filename, int filenameSize,
			     char *fType, char *fCreator)
{
  /* Win32 files are untyped, and the creator is correct by default */
  return true;
}

dir_GetMacFileTypeAndCreator(char *filename, int filenameSize,
			     char *fType, char *fCreator)
{
  /* Win32 files are untyped, and the creator is correct by default */
  return interpreterProxy->primitiveFail();
}

int dir_Delete(char *pathString, int pathStringLength) {
	/* Delete the existing directory with the given path. */
	TCHAR *win32Path;

	win32Path = fromSqueak(pathString, pathStringLength);
	if(hasCaseSensitiveDuplicate(win32Path)) return false;
	return RemoveDirectory(win32Path) == 0 ? false : true;
}
