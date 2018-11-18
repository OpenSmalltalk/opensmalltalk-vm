/*
 * faSupport.c - Unix support routines for the FileAttributesPlugin
 *
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

	/* Convert to platform specific form */
	status = sq2uxPath(aFaPath->path, len, aFaPath->uxpath, FA_PATH_MAX, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->uxpath_len = strlen(aFaPath->uxpath);
	aFaPath->uxpath_file = aFaPath->uxpath + aFaPath->uxpath_len;
	aFaPath->uxmax_file_len = FA_PATH_MAX - aFaPath->uxpath_len;

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

	/* Convert to platform specific form */
	status = sq2uxPath(aFaPath->path, len, aFaPath->uxpath, FA_PATH_MAX, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->uxpath_len = strlen(aFaPath->uxpath);
	aFaPath->uxpath_file = 0;
	aFaPath->uxmax_file_len = 0;

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
	status = sq2uxPath(aFaPath->path_file, len, aFaPath->uxpath_file, aFaPath->uxmax_file_len, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);

	return 0;
}



sqInt faSetPlatPath(fapath *aFaPath, char *pathName)
{
int		len;
sqInt	status;

	/* Set the platform encoded path */
	len = strlen(pathName);
	if (len >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	strcpy(aFaPath->uxpath, pathName);
	aFaPath->uxpath[len] = 0;
	aFaPath->uxpath_len = len;
	aFaPath->uxpath_file = 0;
	aFaPath->uxmax_file_len = 0;

	/* Convert to St specific form */
	status = ux2sqPath(aFaPath->uxpath, len, aFaPath->path, FA_PATH_MAX, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->path_len = strlen(aFaPath->path);
	aFaPath->path_file = 0;
	aFaPath->max_file_len = 0;

	return 0;
}



sqInt faSetPlatPathOop(fapath *aFaPath, sqInt pathNameOop)
{
int	len;
char	*bytePtr;
sqInt	status;

	len = interpreterProxy->stSizeOf(pathNameOop);
	bytePtr = interpreterProxy->arrayValueOf(pathNameOop);
	if (len >= FA_PATH_MAX)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	memcpy(aFaPath->uxpath, bytePtr, len);
	aFaPath->uxpath[len] = 0;
	aFaPath->uxpath_len = len;
	aFaPath->uxpath_file = 0;
	aFaPath->uxmax_file_len = 0;

	/* Convert to St specific form */
	status = ux2sqPath(aFaPath->uxpath, len, aFaPath->path, FA_PATH_MAX, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	/* Set aFaPath->uxpath_file and max_file_len to the buffer after the directory */
	aFaPath->path_len = strlen(aFaPath->path);
	aFaPath->path_file = 0;
	aFaPath->max_file_len = 0;

	return 0;
}



sqInt faSetPlatFile(fapath *aFaPath, char *pathName)
{
int		len;
sqInt	status;

	assert(aFaPath->uxpath_file != 0);
	/* Set the platform encoded file name */
	len = strlen(pathName);
	if (len >= aFaPath->uxmax_file_len)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	strcpy(aFaPath->uxpath_file, pathName);

	/* Convert to St specific form */
	status = ux2sqPath(aFaPath->uxpath_file, len, aFaPath->path_file, aFaPath->max_file_len, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);

	return 0;
}




/* 
 * Convert the supplied Unix (UTC) time to Squeak time.
 * Squeak time has an epoch of 1901 and uses local time
 * i.e. timezone + daylight savings
 * 
 * Answer an sqLong which is guaranteed to be 64 bits on all platforms.
 */
sqLong faConvertUnixToLongSqueakTime(time_t unixTime)
{
sqLong	squeakTime;

	squeakTime = unixTime;
#if defined(HAVE_TM_GMTOFF)
	squeakTime = squeakTime + localtime(&unixTime)->tm_gmtoff;
#elif defined(HAVE_TIMEZONE)
	squeakTime = squeakTime + (daylight*60*60) - timezone;
#else
	#error: cannot determine timezone correction
#endif
	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
	 * and 52 non-leap years later than Squeak. */
	squeakTime = squeakTime + 
		(52*365UL + 17*366UL) * 24*60*60UL;
	return squeakTime;
}



/*
 * pathNameToOop
 *
 * Convert the supplied platform encoded C string to a 
 * precomposed UTF8 ByteArray.
 */
sqInt pathNameToOop(char *pathName)
{
sqInt	pathOop;
int		status;
int		len;
char	uxName[FA_PATH_MAX];

	len = strlen(pathName);
	if (len >= FA_PATH_MAX)
   		return interpreterProxy->primitiveFailForOSError(FA_STRING_TOO_LONG);
	status = ux2sqPath(pathName, len, uxName, FA_PATH_MAX, 1);
	if (!status)
		return interpreterProxy->primitiveFailForOSError(FA_INVALID_ARGUMENTS);
	status = faCharToByteArray(uxName, &pathOop);
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
 * The root directory must be represented as '/', and not an empty string.
 *
 * If there are no entries, close the directory and return FA_NO_MORE_DATA
 */

sqInt faOpenDirectory(fapath *aFaPath)
{
	/* Open the directory */ 
	aFaPath->platformDir = opendir(faGetPlatPath(aFaPath));
	if (aFaPath->platformDir == NULL)
		return FA_CANT_OPEN_DIR;

	return faReadDirectory(aFaPath);
}




/*
 * faReadDirectory
 *
 * Read the next entry from the already opened directory (dirState)
 *
 * If there are no entries, return FA_NO_MORE_DATA
 */

sqInt faReadDirectory(fapath *aFaPath)
{
sqInt		haveEntry;
struct dirent	*entry;
sqInt		status;

	if (aFaPath->platformDir == NULL)
		return FA_CORRUPT_VALUE;
	haveEntry = 0;
	errno = 0;
	do {
		entry = readdir(aFaPath->platformDir);
		if (entry == NULL) {
			if (errno == 0)
				return FA_NO_MORE_DATA;
			else
				return FA_CANT_READ_DIR; }
		if ((!(entry->d_name[0] == '.' && entry->d_name[1] == 0)) && strcmp(entry->d_name, ".."))
			haveEntry = 1;
	} while (!haveEntry);

	status = faSetPlatFile(aFaPath, entry->d_name);
	if (status) return status;

	return FA_SUCCESS;
}



/*
 * faCloseDirectory
 *
 * Close the supplied directory.
 */

sqInt faCloseDirectory(fapath *aFaPath)
{
sqInt	status;

	if (aFaPath->platformDir == NULL)
		return FA_CORRUPT_VALUE;
	status = closedir(aFaPath->platformDir);
	if (status) return FA_UNABLE_TO_CLOSE_DIR;
	aFaPath->platformDir = 0;

	return FA_SUCCESS;
}



/*
 * faRewindDirectory
 *
 * Rewind the supplied directory and answer the first entry.
 */

sqInt faRewindDirectory(fapath *aFaPath)
{

	if (aFaPath->platformDir == NULL)
		return FA_CORRUPT_VALUE;
	rewinddir(aFaPath->platformDir);
	return faReadDirectory(aFaPath);
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
faStatStruct	statBuf;
int		status;
sqInt	resultOop = 0;
int		mode;


	if (attributeNumber <= 12) {
		/* Requested attribute comes from stat() entry */
		status = stat(faGetPlatPath(aFaPath), &statBuf);
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

			case 9: /* access time */
				resultOop = interpreterProxy->signed64BitIntegerFor(
					faConvertUnixToLongSqueakTime(statBuf.st_atime));
				break;

			case 10: /* modified time */
				resultOop = interpreterProxy->signed64BitIntegerFor(
					faConvertUnixToLongSqueakTime(statBuf.st_mtime));
				break;

			case 11: /* change time */
				resultOop = interpreterProxy->signed64BitIntegerFor(
					faConvertUnixToLongSqueakTime(statBuf.st_ctime));
				break;

			case 12: /* creation time */
				resultOop = interpreterProxy->nilObject();
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
		if (access(faGetPlatPath(aFaPath), mode) == 0)
			resultOop = interpreterProxy->trueObject();
		else
			resultOop = interpreterProxy->falseObject();
	} else if (attributeNumber == 16) {
		/* isSymlink */
		status = lstat(faGetPlatPath(aFaPath), &statBuf);
		if (status)
			return interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
		if (S_ISLNK(statBuf.st_mode))
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

	status = stat(faGetPlatPath(aFaPath), statBuf);
	if (status) return FA_CANT_STAT_PATH;
	fileNameOop[0] = interpreterProxy->nilObject();
	return 0;
}



/*
 * faLinkStat
 *
 * Populate the supplied stat buffer with symbolic link information
 */
sqInt faLinkStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop)
{
int	status;
char	targetFile[FA_PATH_MAX];

	status = lstat(faGetPlatPath(aFaPath), statBuf);
	if (status) return FA_CANT_STAT_PATH;
	if (S_ISLNK(statBuf->st_mode)) {
		/* This is a symbolic link, provide the target filename */
		status = readlink(faGetPlatPath(aFaPath), targetFile, FA_PATH_MAX);
		if (status < 0) return FA_CANT_READ_LINK;
		*fileNameOop = pathNameToOop(targetFile);
		if (interpreterProxy->failed())
			return interpreterProxy->primitiveFailureCode();
	} else {
		fileNameOop[0] = interpreterProxy->nilObject();
	}
	return 0;
}


/*
 * faExists
 *
 * Answer a boolean indicating whether the supplied path name exists.
 */
sqInt faExists(fapath *aFaPath)
{
	if (access(faGetPlatPath(aFaPath), F_OK))
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

	accessOop = access(faGetPlatPath(aFaPath), R_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = access(faGetPlatPath(aFaPath), W_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = access(faGetPlatPath(aFaPath), X_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	return 0;
}
