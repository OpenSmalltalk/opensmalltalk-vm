/*
 * faSupport.c - Windows support routines for the FileAttributesPlugin
 *
 * Author: akgrant@gmail.com
 */
#include <windows.h>

#include "sq.h"
#include "faSupport.h"




sqInt faCheckFindData(osdir *dirState, sqInt closeFind)
{
while (1) {
	/* check for '.' or '..' directories */
	if (dirState->findData.cFileName[0] == L'.')
	  if (dirState->findData.cFileName[1] == 0 ||
	    (dirState->findData.cFileName[1] == L'.' &&
	      dirState->findData.cFileName[2] == 0)) {
		if (!FindNextFileW(dirState->directoryHandle, &dirState->findData)) {
			if (closeFind)
				FindClose(dirState->directoryHandle);
			return NO_MORE_DATA;
		} else
			break;
}

/* convert to UTF-8 */
sz = WideCharToMultiByte(CP_UTF8, 
	0, 
	dirState->findData.cFileName, 
	-1, 
	dirState->path_file, 
	dirState->max_file_len, 
	NULL, 
	NULL);
if (!sz)
	return FA_CANT_READ_DIR;

return FA_SUCCESS;
}



/*
 * faOpenDirectory(char *pathString)
 *
 * Open the supplied directory for iteration and return the first entry.
 *
 * '.' and '..' are never returned.
 *
 * On Windows pathString cannot be empty, i.e. the root directory should be
 * handled separately.
 *
 * If there are no entries, close the directory and return FA_NO_MORE_DATA
 */

sqInt faOpenDirectory(osdir *dirState)
{
WCHAR		*widePathString;
sqInt		sz;
sqInt		patternLength;
DWORD		ffError;


/* Ensure wildcard pattern in dirState->path (which must already end in a path separator). */
if (dirState->path_len == 0)
	return FA_INVALID_ARGUMENTS;
patternLength = dirState->path_len;
pattern[patternLength++] = '*';
pattern[patternLength] = 0;
 
/* convert the path name into a wide null-terminated C string */
ALLOC_WIN32_PATH(widePathString, dirState->path, patternLength);

/* remove the wildcard pattern from dirState->path (but leave the trailing 
 * delimeter */
dirState->path[dirState->path_len] = 0;

dirState->directoryHandle = FindFirstFileW(widePathString, &dirState->findData);
if (dirState->directoryHandle == INVALID_HANDLE_ERROR) {
	ffError = GetLastError();
	if (ffError == ERROR_NO_MORE_FILES)
		return FA_NO_MORE_DATA;
	return FA_CANT_OPEN_DIR;
}

return faCheckFindData(dirState, 1);
}



/*
 * faReadDirectory(osdir *dirState)
 *
 * Return the next entry for the already opened directory identified by
 * dirStateId.
 *
 * Return FA_NO_MORE_DATA after the last file.
 */

sqInt faReadDirectory(osdir *dirState)
{
DWORD		ffError;


if (!FindNextFileW(dirState->directoryHandle, &dirState->findData))
	return FA_NO_MORE_DATA;

return faCheckFindData(dirState, 0);
}



/*
 * faCloseDirectory(void *dirStateId)
 *
 * Close the supplied directory.
 */

sqInt faCloseDirectory(osdir *dirState)
{
sqInt	status;

status = FindClose(dirState->directoryHandle);
dirState->directoryHandle = 0;
if (status)
	return FA_SUCCESS;
else
	return FA_UNABLE_TO_CLOSE_DIR;
}


