/*
 * faSupport.c - Windows support routines for the FileAttributesPlugin
 */
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>

#include "sq.h"
#include "faCommon.h"

#define	S_IFLNK	0xA000

extern struct VirtualMachine * interpreterProxy;


sqInt faSetStDir(fapath *aFaPath, char *pathName, int len)
{
sqInt	status;

	/* Set the St encoded path and ensure trailing delimiter */
	if (len+1 >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	memcpy(aFaPath->path, pathName, len);
	if (aFaPath->path[len-1] != PATH_SEPARATOR)
		aFaPath->path[len++] = PATH_SEPARATOR;
	aFaPath->path[len] = 0;
	aFaPath->path_len = len;
	aFaPath->path_dirlen = len;
	aFaPath->path_file = aFaPath->path + len;
	aFaPath->max_file_len = FA_PATH_MAX - len;

	/* Convert to platform specific form 
 		Include the \\?\ prefix to allow long path names */
	aFaPath->winpathLPP[0] = L'\\';
	aFaPath->winpathLPP[1] = L'\\';
	aFaPath->winpathLPP[2] = L'?';
	aFaPath->winpathLPP[3] = L'\\';
	aFaPath->winpath = aFaPath->winpathLPP + 4;
	status = MultiByteToWideChar(CP_UTF8, 0, 
				aFaPath->path, -1, 
				aFaPath->winpath, FA_PATH_MAX);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->winpathLPP_len = wcslen(aFaPath->winpathLPP);
	aFaPath->winpath_len = aFaPath->winpathLPP_len - 4;
	aFaPath->winpath_dirlen = aFaPath->winpath_len;
	aFaPath->winpath_file = aFaPath->winpathLPP + aFaPath->winpathLPP_len;
	aFaPath->winmax_file_len = FA_PATH_MAX - aFaPath->winpath_len;

	return 0;
}



sqInt faSetStPath(fapath *aFaPath, char *pathName, int len)
{
sqInt	status;

	/* Set the St encoded path */
	if (len >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	memcpy(aFaPath->path, pathName, len);
	aFaPath->path[len] = 0;
	aFaPath->path_len = len;
	aFaPath->path_dirlen = 0;
	aFaPath->path_file = 0;
	aFaPath->max_file_len = 0;

	/* Convert to platform specific form 
 		Include the \\?\ prefix to allow long path names */
	aFaPath->winpathLPP[0] = L'\\';
	aFaPath->winpathLPP[1] = L'\\';
	aFaPath->winpathLPP[2] = L'?';
	aFaPath->winpathLPP[3] = L'\\';
	aFaPath->winpath = aFaPath->winpathLPP + 4;
	status = MultiByteToWideChar(CP_UTF8, 0, 
				aFaPath->path, -1, 
				aFaPath->winpath, FA_PATH_MAX);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->winpathLPP_len = wcslen(aFaPath->winpathLPP);
	aFaPath->winpath_len = aFaPath->winpathLPP_len - 4;
	aFaPath->winpath_dirlen = 0;
	aFaPath->winpath_file = 0;
	aFaPath->winmax_file_len = 0;

	return 0;
}



sqInt faSetStFile(fapath *aFaPath, char *pathName)
{
int		len;
sqInt	status;

	assert(aFaPath->path_file != 0);
	/* Set the St encoded path */
	len = strlen(pathName);
	if (len >= aFaPath->max_file_len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	strcpy(aFaPath->path_file, pathName);
	aFaPath->path_len = strlen(aFaPath->path);

	/* Convert to platform specific form */
	status = MultiByteToWideChar(CP_UTF8, 0, 
				aFaPath->path_file, -1, 
				aFaPath->winpath_file, aFaPath->winmax_file_len);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	aFaPath->winpath_len = wcslen(aFaPath->winpath);

	return 0;
}



/*
 * faSetPlatPath
 *
 * The supplied pathName must not include the Long Path Prefix (\\?\).
 */
sqInt faSetPlatPath(fapath *aFaPath, WCHAR *pathName)
{
int		len;

	len = wcslen(pathName);
	if (len >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set the platform encoded path */
	aFaPath->winpathLPP[0] = L'\\';
	aFaPath->winpathLPP[1] = L'\\';
	aFaPath->winpathLPP[2] = L'?';
	aFaPath->winpathLPP[3] = L'\\';
	aFaPath->winpath = aFaPath->winpathLPP + 4;
	wcscpy(aFaPath->winpath, pathName);
	aFaPath->winpath[len] = 0;
	aFaPath->winpath_len = len;
	aFaPath->winpath_dirlen = 0;
	aFaPath->winpath_file = 0;
	aFaPath->winmax_file_len = 0;
	aFaPath->winpathLPP_len = aFaPath->winpath_len + 4;

	/* Convert to St specific form */
	len = WideCharToMultiByte(CP_UTF8, 
		0, 
		pathName, 
		-1, 
		aFaPath->path, 
		FA_PATH_MAX, 
		NULL, 
		NULL);
	if (!len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->path_len = strlen(aFaPath->path);
	aFaPath->path_dirlen = 0;
	aFaPath->path_file = 0;
	aFaPath->max_file_len = 0;

	return 0;
}



sqInt faSetPlatPathOop(fapath *aFaPath, sqInt pathNameOop)
{
int	byteCount;
char	*bytePtr;
int	len;

	byteCount = interpreterProxy->stSizeOf(pathNameOop);
	bytePtr = interpreterProxy->arrayValueOf(pathNameOop);
	len = byteCount / sizeof(WCHAR);
	if (len >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);

	aFaPath->winpathLPP[0] = L'\\';
	aFaPath->winpathLPP[1] = L'\\';
	aFaPath->winpathLPP[2] = L'?';
	aFaPath->winpathLPP[3] = L'\\';
	aFaPath->winpath = aFaPath->winpathLPP + 4;
	memcpy(aFaPath->winpath, bytePtr, byteCount);
	aFaPath->winpath[len] = 0;
	aFaPath->winpath_len = len;
	aFaPath->winpath_dirlen = 0;
	aFaPath->winpathLPP_len = len + 4;
	aFaPath->winpath_file = 0;
	aFaPath->winmax_file_len = 0;

	/* Convert to St specific form */
	len = WideCharToMultiByte(CP_UTF8, 
		0, 
		aFaPath->winpath, 
		-1, 
		aFaPath->path, 
		FA_PATH_MAX, 
		NULL, 
		NULL);
	if (!len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->path_len = strlen(aFaPath->path);
	aFaPath->path_dirlen = 0;
	aFaPath->path_file = 0;
	aFaPath->max_file_len = 0;

	return 0;
}



sqInt faSetPlatFile(fapath *aFaPath, WCHAR *pathName)
{
int		len;

	assert(aFaPath->winpath_file != 0);
	/* Set the platform encoded file name */
	len = wcslen(pathName);
	if (len >= aFaPath->winmax_file_len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	wcscpy(aFaPath->winpath_file, pathName);
	aFaPath->winpath_dirlen = wcslen(aFaPath->winpath);

	/* Convert to St specific form */
	len = WideCharToMultiByte(CP_UTF8, 
		0, 
		pathName, 
		-1, 
		aFaPath->path_file, 
		aFaPath->winmax_file_len, 
		NULL, 
		NULL);
	if (!len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	aFaPath->path_dirlen = strlen(aFaPath->path);

	return 0;
}



/*
 * faClearFile
 *
 * Remove the file off the current path, i.e. terminate the string
 * where the directory name ends.
 *
 * aFaPath must have been initialised with faSetStDir prior to calling
 * this function.
 */
void faClearFile(fapath *aFaPath)
{
	aFaPath->path[aFaPath->path_dirlen] = 0;
	aFaPath->winpath[aFaPath->winpath_dirlen] = 0;
}



/*
 * faDbgDump
 *
 * Print the contents of the supplied fapath
 */
void faDbgDump(fapath *aFaPath)
{
int	i;

	printf("StPath: %s\n", aFaPath->path);
	printf("StPathLen:	%d\n", aFaPath->path_len);
	printf("StPath strlen:	%d\n", strlen(aFaPath->path));
	printf("Path: 0x%p, File: 0x%p\n", (void *)aFaPath->path, (void *)aFaPath->path_file);
	printf("Max File Len:	%d\n", aFaPath->max_file_len);
	printf("Plat code points: ");
	for (i=0; i<wcslen(aFaPath->winpath); i++) {
		printf(" %d", aFaPath->winpath[i]);
	}
	printf("\n");
	printf("PlatPathLen:	%d\n", aFaPath->winpath_len);
	printf("PlatPath wcslen: %d\n", wcslen(aFaPath->winpath));
	printf("PathLPP: 0x%p, Path: 0x%p, File: 0x%p\n",
		(void *)aFaPath->winpathLPP, (void *)aFaPath->winpath, (void *)aFaPath->winpath_file);
	printf("Max File Len:	%d (%d)\n", aFaPath->winmax_file_len, MAX_PATH);
	printf("faGetPlatPathCPP(): 0x%p\n", faGetPlatPathCPP(aFaPath));
	wprintf(L"faGetPlatPathCPP(): %s\n", faGetPlatPathCPP(aFaPath));
	wprintf(L"faGetPlatPathLPP(): %s\n", faGetPlatPathLPP(aFaPath));
	fflush(stdout);
}




/*
 * faCheckFindData
 *
 * Check the current file in aFaPath and retrieve entries until a valid file
 * is returned or the end of directory is reached.
 *
 * Invalid files are '.' and '..'.
 */
sqInt faCheckFindData(fapath *aFaPath, sqInt closeFind)
{
sqInt	sz;
sqInt	status;
sqInt	haveEntry;

haveEntry = FALSE;
do {
	if ((!(aFaPath->findData.cFileName[0] == L'.' && 
		aFaPath->findData.cFileName[1] == 0)) 
		&& wcscmp(aFaPath->findData.cFileName, L".."))
			haveEntry = TRUE;
	else {
		status = FindNextFileW(aFaPath->directoryHandle, &aFaPath->findData);
		if (status == 0) {
			if (closeFind == 1)
				FindClose(aFaPath->directoryHandle);
			return FA_NO_MORE_DATA;
		}
	}
} while (!haveEntry);

	status = faSetPlatFile(aFaPath, aFaPath->findData.cFileName);
	if (status) return status;

	return FA_SUCCESS;
}


/*
 * faConvertWinToLongSqueakTime
 *
 * Convert the supplied Windows System time to a long Squeak time.
 * Squeak time has an epoch of 1901 and uses local time
 * i.e. timezone + daylight savings
 * 
 * Answer an sqLong which is guaranteed to be 64 bits on all platforms.
 */
sqLong faConvertWinToLongSqueakTime(SYSTEMTIME st)
{
sqLong	dy;
sqLong	secs;
static sqLong nDaysPerMonth[14] = { 
		/* SYSTEMTIME uses 1 based month number.
		 * Add a offset entry at the start instead of subtracting 
		 * 1 from the index */
		0,  0,  31,  59,  90, 120, 151,
		181, 212, 243, 273, 304, 334, 365 };

	/* Squeak epoch is Jan 1, 1901
	 * compute delta year */
	dy = st.wYear - 1901;
	secs = (dy * 365 * 24 * 60 * 60)       /* base seconds */
			+ ((dy >> 2) * 24 * 60 * 60);   /* seconds of leap years */
	/* check if month > 2 and current year is a leap year */
	if ((st.wMonth > 2) && ((dy & 0x3) == 0x3)) {
		/* add one day */
		secs += 24 * 60 * 60; }
	/* add the days from the beginning of the year */
	secs += (nDaysPerMonth[st.wMonth] + st.wDay - 1) * 24 * 60 * 60;
	/* add the hours, minutes, and seconds */
	secs += st.wSecond + 60*(st.wMinute + 60*st.wHour);
	return secs;
}



/*
 * pathNameToOop
 *
 * Convert the supplied platform encoded C string to a 
 * precomposed UTF8 ByteArray.
 */
sqInt pathNameToOop(WCHAR *pathName)
{
sqInt	pathOop;
int		status;
int		len;
char	stName[FA_PATH_MAX];

	len = WideCharToMultiByte(CP_UTF8, 
		0, 
		pathName, 
		-1, 
		stName, 
		FA_PATH_MAX, 
		NULL, 
		NULL);
	if (!len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);

	status = faCharToByteArray(stName, &pathOop);
	if (status)
		return interpreterProxy->primitiveFailForOSError(status);
	return pathOop;
}



/*
 * faSetStMode
 *
 * Set the bits in st_mode that Windows supports
 *
 * Any existing value is overwritten
 */
int faSetStMode(fapath *aFaPath, unsigned int *st_mode, DWORD dwFileAttributes)
{
WCHAR	*ext;
int	pathLen;

	/* permissions are the bottom 9 bits */
	*st_mode = S_IRUSR | (S_IRUSR>>3) | (S_IRUSR>>6);
	if (!(dwFileAttributes & FILE_ATTRIBUTE_READONLY))
		*st_mode |= S_IWUSR | (S_IWUSR>>3) | (S_IWUSR>>6);
	if (dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		*st_mode |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
	else {
		pathLen = wcslen(aFaPath->winpathLPP);
		if (aFaPath->winpathLPP[pathLen - 4] == L'.') {
		ext = &aFaPath->winpathLPP[pathLen - 3];
		if (!_wcsicmp (ext, L"COM"))
			*st_mode |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
		else if (!_wcsicmp (ext, L"EXE"))
			*st_mode |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
		else if (!_wcsicmp (ext, L"BAT"))
			*st_mode |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6);
		else if (!_wcsicmp (ext, L"CMD"))
			*st_mode |= S_IXUSR | (S_IXUSR>>3) | (S_IXUSR>>6); } }

	/* file type */
	if (dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
		*st_mode |= S_IFDIR; }
	else if (dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
		*st_mode |= S_IFLNK; }
	else {
		*st_mode |= S_IFREG; }
	return 0;
}



/*
 * faWinDevId
 *
 * Answer the device id, which is the drive number of the disk containing
 * the file.
 *
 * TODO: UNC paths aren't handled properly yet
 */
int faWinDevId(fapath *aFaPath)
{
char	*path;

	path = faGetStPath(aFaPath);
	if (path[1] == ':')
		return path[0] - 'A';
	else
		return 26;
}



/*
 * faOpenDirectory
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

sqInt faOpenDirectory(fapath *aFaPath)
{
int		status;
DWORD	ffError;


	/* aFaPath already has the directory set, with trailing separator.
	 * Add the wildcard for the search */
	status = faSetStFile(aFaPath, "*");
	if (status) return status;
 
	aFaPath->directoryHandle = FindFirstFileW(faGetPlatPathCPP(aFaPath), &aFaPath->findData);
	if (aFaPath->directoryHandle == INVALID_HANDLE_VALUE) {
		ffError = GetLastError();
		if (ffError == ERROR_NO_MORE_FILES)
			return FA_NO_MORE_DATA;
		return FA_CANT_OPEN_DIR;
	}

	return faCheckFindData(aFaPath, 1);
}



/*
 * faReadDirectory
 *
 * Return the next entry for the already opened directory identified by
 * aFaPath.
 *
 * Return FA_NO_MORE_DATA after the last file.
 */

sqInt faReadDirectory(fapath *aFaPath)
{
	if (!FindNextFileW(aFaPath->directoryHandle, &aFaPath->findData))
		return FA_NO_MORE_DATA;

	return faCheckFindData(aFaPath, 0);
}



/*
 * faCloseDirectory
 *
 * Close the supplied directory.
 */

sqInt faCloseDirectory(fapath *aFaPath)
{
sqInt	status;

	status = FindClose(aFaPath->directoryHandle);
	aFaPath->directoryHandle = 0;
	if (status)
		return FA_SUCCESS;
	else
		return FA_UNABLE_TO_CLOSE_DIR;
}



/*
 * faRewindDirectory
 *
 * Rewind the supplied directory and answer the first entry.
 */

sqInt faRewindDirectory(fapath *aFaPath)
{
sqInt	status;

	/* 
	 * Windows doesn't directly support rewind.
	 * Close and re-open the directory
	 */
	status = faCloseDirectory(aFaPath);
	if (status) return status;
	/* Remove any existing file from the path */
	faClearFile(aFaPath);
	return faOpenDirectory(aFaPath);
}


/*
 * winFileAttributes
 *
 * Populate the supplied WIN32_FILE_ATTRIBUTE_DATA structure.
 *
 * First attempt to use GetFileAttributesExW().
 * However this fails sometimes and MS requires us to fall back to search
 * for the file with FindFirstFileW() and copying the attributes across.
 */
sqInt winFileAttributes(fapath *aFaPath, WIN32_FILE_ATTRIBUTE_DATA *wfa)
{
int			status;
HANDLE			findHandle;
WIN32_FIND_DATAW	wfd;
BOOL			closeStatus;
DWORD			lastError;

	status = GetFileAttributesExW(faGetPlatPathCPP(aFaPath), 
			GetFileExInfoStandard, wfa);
	if (status) 
		/* Call succeeded and wfa is populated */
		return status;

	lastError = GetLastError();
	/* For anything but a sharing violation, return the error */
	if (lastError != ERROR_SHARING_VIOLATION) {
		return 0; }

	/* Try again using FindFirstFileW() */
	findHandle = FindFirstFileW(faGetPlatPathCPP(aFaPath), &wfd);
	if (findHandle == INVALID_HANDLE_VALUE) {
		return 0; }

	wfa->dwFileAttributes = wfd.dwFileAttributes;
	wfa->ftCreationTime = wfd.ftCreationTime;
	wfa->ftLastAccessTime = wfd.ftLastAccessTime;
	wfa->ftLastWriteTime = wfd.ftLastWriteTime;
	wfa->nFileSizeHigh = wfd.nFileSizeHigh;
	wfa->nFileSizeLow = wfd.nFileSizeLow;

	closeStatus = FindClose(findHandle);
	if (!closeStatus) {
		return 0; }

	return 1;
}



/*
 * faFileAttribute
 *
 * Answer a single attribute (OOP) for the supplied file name.
 *
 * Set the interpreterProxy primitiveFailure flag on error.
 *
 * The attributeNumber has previously been validated.
 *
 * See FileAttributesPlugin>>primitiveFileAttribute for the list of attribute
 * numbers.
 */
sqInt faFileAttribute(fapath *aFaPath, sqInt attributeNumber)
{
int		status;
sqInt		resultOop = 0;
unsigned int	st_mode;
sqLong		attributeDate;
FILETIME	fileTime;
SYSTEMTIME	sysTime;
faStatStruct	statBuf;
WIN32_FILE_ATTRIBUTE_DATA winAttrs;
sqLong		fileSize;
DWORD		lastError;


	status = winFileAttributes(aFaPath, &winAttrs);
	if (!status) {
		interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		return 0; }
	faSetStMode(aFaPath, &st_mode, winAttrs.dwFileAttributes);

	switch (attributeNumber) {

		case 1: /* fileName, not supported for a single attribute */
			resultOop = interpreterProxy->nilObject();
			break;

		case 2: /* Mode */
			resultOop = interpreterProxy->positive32BitIntegerFor(st_mode);
			break;

		case 3: /* inode */
			resultOop = interpreterProxy->positive32BitIntegerFor(0);
			break;

		case 4: /* device id */
			resultOop = interpreterProxy->positive32BitIntegerFor(faWinDevId(aFaPath));
			break;

		case 5: /* nlink - not yet supported */
			interpreterProxy->primitiveFailForOSError(FA_UNSUPPORTED_OPERATION);
			resultOop = 0;
			break;

		case 6: /* uid - not supported on Windows */
			resultOop = interpreterProxy->positive32BitIntegerFor(0);
			break;

		case 7: /* gid - not supported on windows */
			resultOop = interpreterProxy->positive32BitIntegerFor(0);
			break;

		case 8: /* size (if file) */
			fileSize = winAttrs.nFileSizeHigh;
			fileSize = (fileSize << 32) + winAttrs.nFileSizeLow;
			if (S_ISDIR(st_mode) == 0)
				resultOop = interpreterProxy->positive64BitIntegerFor(fileSize);
			else
				resultOop = interpreterProxy->positive32BitIntegerFor(0);
			break;

		case 9: /* access time */
			if (!FileTimeToLocalFileTime(&winAttrs.ftLastAccessTime, &fileTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			if (!FileTimeToSystemTime(&fileTime, &sysTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			attributeDate = faConvertWinToLongSqueakTime(sysTime);
			resultOop = interpreterProxy->signed64BitIntegerFor(attributeDate);
			break;

		case 10: /* modified time */
			if (!FileTimeToLocalFileTime(&winAttrs.ftLastWriteTime, &fileTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			if (!FileTimeToSystemTime(&fileTime, &sysTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			attributeDate = faConvertWinToLongSqueakTime(sysTime);
			resultOop = interpreterProxy->signed64BitIntegerFor(attributeDate);
			break;

		case 11: /* change time */
			resultOop = interpreterProxy->nilObject();
			break;

		case 12: /* creation time */
			if (!FileTimeToLocalFileTime(&winAttrs.ftCreationTime, &fileTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			if (!FileTimeToSystemTime(&fileTime, &sysTime))
 				return interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
			attributeDate = faConvertWinToLongSqueakTime(sysTime);
			resultOop = interpreterProxy->signed64BitIntegerFor(attributeDate);
			break;

		case 13:
			if (st_mode & S_IRUSR)
				resultOop = interpreterProxy->trueObject();
			else
				resultOop = interpreterProxy->falseObject();
			break;

		case 14:
			if (st_mode & S_IWUSR)
				resultOop = interpreterProxy->trueObject();
			else
				resultOop = interpreterProxy->falseObject();
			break;

		case 15:
			if (st_mode & S_IXUSR)
				resultOop = interpreterProxy->trueObject();
			else
				resultOop = interpreterProxy->falseObject();
			break;

		case 16:
			if ((st_mode & S_IFLNK) == S_IFLNK)
				resultOop = interpreterProxy->trueObject();
			else
				resultOop = interpreterProxy->falseObject();
			break;
	}

	return resultOop;
}



/*
 * faFileStatAttributes
 *
 * Populate the supplied array with the file attributes.
 *
 * On error answer the status.
 */
sqInt faFileStatAttributes(fapath *aFaPath, int lStat, sqInt attributeArray)
{
int		status;
sqInt		resultOop = 0;
unsigned int	st_mode;
sqLong		attributeDate;
FILETIME	fileTime;
SYSTEMTIME	sysTime;
faStatStruct	statBuf;
WIN32_FILE_ATTRIBUTE_DATA winAttrs;
sqLong		fileSize;

	if (lStat)
		return FA_UNSUPPORTED_OPERATION;

	status = winFileAttributes(aFaPath, &winAttrs);
	if (!status) {
		interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		return FA_CANT_STAT_PATH; }
	faSetStMode(aFaPath, &st_mode, winAttrs.dwFileAttributes);

	interpreterProxy->storePointerofObjectwithValue(
		0, attributeArray,
		interpreterProxy->nilObject());

	interpreterProxy->storePointerofObjectwithValue(
		1, attributeArray,
		interpreterProxy->positive32BitIntegerFor(st_mode));

	interpreterProxy->storePointerofObjectwithValue(
		2, attributeArray,
		interpreterProxy->positive32BitIntegerFor(0));

	/* device id */
	interpreterProxy->storePointerofObjectwithValue(
		3, attributeArray,
		interpreterProxy->positive32BitIntegerFor(faWinDevId(aFaPath)));

	/* nlinks - Not Yet Supported */
	interpreterProxy->storePointerofObjectwithValue(
		4, attributeArray,
		interpreterProxy->nilObject());

	/* uid */
	interpreterProxy->storePointerofObjectwithValue(
		5, attributeArray,
		interpreterProxy->positive32BitIntegerFor(0));

	/* gid */
	interpreterProxy->storePointerofObjectwithValue(
		6, attributeArray,
		interpreterProxy->positive32BitIntegerFor(0));

	fileSize = winAttrs.nFileSizeHigh;
	fileSize = (fileSize << 32) + winAttrs.nFileSizeLow;
	interpreterProxy->storePointerofObjectwithValue(
		7, attributeArray,
		(S_ISDIR(st_mode) == 0) ?
			interpreterProxy->positive64BitIntegerFor(fileSize) :
			interpreterProxy->positive32BitIntegerFor(0));

	if (!FileTimeToLocalFileTime(&winAttrs.ftLastAccessTime, &fileTime)) {
 		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	if (!FileTimeToSystemTime(&fileTime, &sysTime)) {
 		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	attributeDate = faConvertWinToLongSqueakTime(sysTime);
	interpreterProxy->storePointerofObjectwithValue(
		8, attributeArray,
		interpreterProxy->signed64BitIntegerFor(attributeDate));

	if (!FileTimeToLocalFileTime(&winAttrs.ftLastWriteTime, &fileTime)) {
 		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	if (!FileTimeToSystemTime(&fileTime, &sysTime)) {
 		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	attributeDate = faConvertWinToLongSqueakTime(sysTime);
	interpreterProxy->storePointerofObjectwithValue(
		9, attributeArray,
		interpreterProxy->signed64BitIntegerFor(attributeDate));

	interpreterProxy->storePointerofObjectwithValue(
		10, attributeArray,
		interpreterProxy->nilObject());

	if (!FileTimeToLocalFileTime(&winAttrs.ftCreationTime, &fileTime)) {
		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	if (!FileTimeToSystemTime(&fileTime, &sysTime)) {
 		interpreterProxy->primitiveFailForOSError(FA_TIME_CONVERSION_FAILED);
		return FA_TIME_CONVERSION_FAILED; }
	attributeDate = faConvertWinToLongSqueakTime(sysTime);
	interpreterProxy->storePointerofObjectwithValue(
		11, attributeArray,
		interpreterProxy->signed64BitIntegerFor(attributeDate));

	interpreterProxy->storePointerofObjectwithValue(
		12, attributeArray,
		interpreterProxy->positive32BitIntegerFor(winAttrs.dwFileAttributes));

	return FA_SUCCESS;
}




/*
 * faExists
 *
 * Answer a boolean indicating whether the supplied path name exists.
 */
sqInt faExists(fapath *aFaPath)
{
WIN32_FILE_ATTRIBUTE_DATA	winAttrs;
int				status;

	return winFileAttributes(aFaPath, &winAttrs);
}



/*
 * faAccessAttributes
 *
 * Store whether the current user has access (R, W, X) to the supplied
 * file.
 *
 * Answer 0 on success or the error code on failure
 */
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset)
{
int	status;
unsigned int	st_mode;
sqInt	index;
sqInt	trueOop;
sqInt	falseOop;
sqInt	accessOop;
WIN32_FILE_ATTRIBUTE_DATA winAttrs;

	status = winFileAttributes(aFaPath, &winAttrs);
	if (!status) {
		interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		return FA_CANT_STAT_PATH; }
	faSetStMode(aFaPath, &st_mode, winAttrs.dwFileAttributes);

	index = offset;
	trueOop = interpreterProxy->trueObject();
	falseOop = interpreterProxy->falseObject();

	accessOop = (st_mode & S_IRUSR) ? trueOop : falseOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = (st_mode & S_IWUSR) ? trueOop : falseOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = (st_mode & S_IXUSR) ? trueOop : falseOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	return 0;
}
