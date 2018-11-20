/*
 * faSupport.c - Windows support routines for the FileAttributesPlugin
 */
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>

#include "sq.h"
#include "faCommon.h"

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

	/* Convert to platform specific form */
	status = MultiByteToWideChar(CP_UTF8, 0, 
				aFaPath->path_file, -1, 
				aFaPath->winpath_file, aFaPath->winmax_file_len);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);

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
	aFaPath->path[aFaPath->path_len] = 0;
	aFaPath->winpath[aFaPath->winpath_len] = 0;
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
	printf("Path: 0x%p, File: 0x%p\n", (void *)aFaPath->path, (void *)aFaPath->path_file);
	printf("Max File Len:	%d\n\n", aFaPath->max_file_len);

	printf("Plat code points: ");
	for (i=0; i<aFaPath->winpath_len; i++) {
		printf(" %d", aFaPath->winpath[i]);
	}
	printf("\n");
	printf("PlatPathLen:	%d\n", aFaPath->winpath_len);
	printf("PathLPP: 0x%p, Path: 0x%p, File: 0x%p\n",
		(void *)aFaPath->winpathLPP, (void *)aFaPath->winpath, (void *)aFaPath->winpath_file);
	printf("Max File Len:	%d\n", aFaPath->winmax_file_len);
	printf("\n\n\n");
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
 
	aFaPath->directoryHandle = FindFirstFileW(faGetPlatPathLPP(aFaPath), &aFaPath->findData);
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
int			status;
sqInt		resultOop = 0;
int			mode;
sqLong		attributeDate;
FILETIME	fileTime;
SYSTEMTIME	sysTime;
faStatStruct	statBuf;
WIN32_FILE_ATTRIBUTE_DATA winAttrs;

	if (attributeNumber <= 8) {
		/* Requested attribute comes from stat() entry */
		status = _wstat(faGetPlatPath(aFaPath), &statBuf);
		if (status)
			return interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);

		switch (attributeNumber) {

			case 1: /* fileName, not supported for a single attribute */
				resultOop = interpreterProxy->nilObject();
				break;

			case 2: /* Mode */
				resultOop = interpreterProxy->positive32BitIntegerFor(statBuf.st_mode);
				break;

			case 3: /* inode */
				resultOop = interpreterProxy->positive64BitIntegerFor(statBuf.st_ino);
				break;

			case 4: /* device id */
				resultOop = interpreterProxy->positive64BitIntegerFor(statBuf.st_dev);
				break;

			case 5: /* nlink */
				resultOop = interpreterProxy->positive64BitIntegerFor(statBuf.st_nlink);
				break;

			case 6: /* uid */
				resultOop = interpreterProxy->positive32BitIntegerFor(statBuf.st_uid);
				break;

			case 7: /* gid */
				resultOop = interpreterProxy->positive32BitIntegerFor(statBuf.st_gid);
				break;

			case 8: /* size (if file) */
				if (S_ISDIR(statBuf.st_mode) == 0)
					resultOop = interpreterProxy->positive64BitIntegerFor(statBuf.st_size);
				else
					resultOop = interpreterProxy->positive32BitIntegerFor(0);
				break;
		}

	} else if (attributeNumber <= 12) {
		status = GetFileAttributesExW(faGetPlatPath(aFaPath), 
					GetFileExInfoStandard, &winAttrs);
		if (!status) 
			return interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		switch (attributeNumber) {
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
		}
	} else if (attributeNumber < 16) {
		switch (attributeNumber) {
			case 13:
				mode = R_OK;
				break;

			case 14:
				mode = W_OK;
				break;

			case 15:
				mode = X_OK;
				break;
		}
		if (_waccess(faGetPlatPath(aFaPath), mode) == 0)
			resultOop = interpreterProxy->trueObject();
		else
			resultOop = interpreterProxy->falseObject();
	} else if (attributeNumber == 16) {
		/* isSymlink */
		status = GetFileAttributesExW(faGetPlatPath(aFaPath), 
					GetFileExInfoStandard, &winAttrs);
		if (!status) 
			return interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		if (winAttrs.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT)
			resultOop = interpreterProxy->trueObject();
		else
			resultOop = interpreterProxy->falseObject();
	}

	return resultOop;
}



/*
 * faStat
 *
 * Populate the supplied stat buffer.
 *
 * fileNameOop only applies to symbolic links, answer nil.
 */
sqInt faStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop)
{
int		status;

	status = _wstat(faGetPlatPath(aFaPath), statBuf);
	if (status) return FA_CANT_STAT_PATH;
	fileNameOop[0] = interpreterProxy->nilObject();
	return 0;
}



/*
 * faLinkStat
 *
 * Populate the supplied stat buffer with symbolic link information.
 *
 * Not supported on Windows
 */
sqInt faLinkStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop)
{
	return FA_UNSUPPORTED_OPERATION;
}



/*
 * faExists
 *
 * Answer a boolean indicating whether the supplied path name exists.
 */
sqInt faExists(fapath *aFaPath)
{
int		status;

	if (_waccess(faGetPlatPath(aFaPath), F_OK))
		return interpreterProxy->falseObject();
	else
		return interpreterProxy->trueObject();
}



/*
 * faAccessAttributes
 *
 * Call access() for each access type (R, W, X) on the supplied path, 
 * storing the results in the st array attributeArray.
 */
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset)
{
sqInt	index;
sqInt	trueOop;
sqInt	falseOop;
sqInt	accessOop;


	index = offset;
	trueOop = interpreterProxy->trueObject();
	falseOop = interpreterProxy->falseObject();

	accessOop = _waccess(faGetPlatPath(aFaPath), R_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = _waccess(faGetPlatPath(aFaPath), W_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = _waccess(faGetPlatPath(aFaPath), X_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	return 0;
}
