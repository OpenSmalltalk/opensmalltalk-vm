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

	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
	 * and 52 non-leap years later than Squeak. */
	if (interpreterProxy->fileTimesInUTC())
		return (sqLong)unixTime + (52*365UL + 17*366UL) * 24*60*60UL;

	squeakTime = unixTime;
#if defined(HAVE_TM_GMTOFF)
	squeakTime = squeakTime + localtime(&unixTime)->tm_gmtoff;
#elif defined(HAVE_TIMEZONE)
	squeakTime = squeakTime + (daylight*60*60) - timezone;
#else
#	error: cannot determine timezone correction
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
sqInt	rstatus, cstatus;

	/* Open the directory */ 
	aFaPath->platformDir = opendir(faGetPlatPath(aFaPath));
	if (aFaPath->platformDir == NULL)
		return FA_CANT_OPEN_DIR;

	rstatus = faReadDirectory(aFaPath);
	if (rstatus == FA_NO_MORE_DATA) {
		cstatus = faCloseDirectory(aFaPath);
		if (cstatus != FA_SUCCESS)
			return cstatus; }
	return rstatus;
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

	if (attributeNumber <= 12) {
		/* Requested attribute comes from stat() entry */
		if (stat(faGetPlatPath(aFaPath), &statBuf)) {
			interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
			return 0; }

		switch (attributeNumber) {

		case 1: /* fileName, not supported for a single attribute */
			return nilOop;

		case 2: /* Mode */
			return interpreterProxy->positive32BitIntegerFor(statBuf.st_mode);

		case 3: /* inode */
			return interpreterProxy->positive64BitIntegerFor(statBuf.st_ino);

		case 4: /* device id */
			return interpreterProxy->positive64BitIntegerFor(statBuf.st_dev);

		case 5: /* nlink */
			return interpreterProxy->positive64BitIntegerFor(statBuf.st_nlink);

		case 6: /* uid */
			return interpreterProxy->positive32BitIntegerFor(statBuf.st_uid);

		case 7: /* gid */
			return interpreterProxy->positive32BitIntegerFor(statBuf.st_gid);

		case 8: /* size (if file) */
			if (S_ISDIR(statBuf.st_mode) == 0)
				return interpreterProxy->positive64BitIntegerFor(statBuf.st_size);
			else
				return interpreterProxy->positive32BitIntegerFor(0);

		case 9: /* access time */
			return interpreterProxy->signed64BitIntegerFor(
				faConvertUnixToLongSqueakTime(statBuf.st_atime));

		case 10: /* modified time */
			return interpreterProxy->signed64BitIntegerFor(
				faConvertUnixToLongSqueakTime(statBuf.st_mtime));

		case 11: /* change time */
			return interpreterProxy->signed64BitIntegerFor(
				faConvertUnixToLongSqueakTime(statBuf.st_ctime));

		case 12: /* creation time */
#if defined(_DARWIN_FEATURE_64_BIT_INODE)
			return interpreterProxy->signed64BitIntegerFor(
				faConvertUnixToLongSqueakTime(statBuf.st_birthtime));
#else
			return nilOop;
#endif
		default:
			interpreterProxy->primitiveFailFor(PrimErrBadArgument);
		}
	}
	if (attributeNumber < 16) {
		int mode;
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
		return access(faGetPlatPath(aFaPath), mode) == 0
			? trueOop
			: falseOop;
	}
	if (attributeNumber == 16) {
		/* isSymlink */
		if (lstat(faGetPlatPath(aFaPath), &statBuf)) {
			interpreterProxy->primitiveFailForOSError(FA_CANT_STAT_PATH);
			 return 0; }
		return S_ISLNK(statBuf.st_mode)
			? trueOop
			: falseOop;
	}

	interpreterProxy->primitiveFailFor(PrimErrBadArgument);
	return nilOop;
}



/*
 * faFileStatAttributes
 *
 * Populate the supplied array with the file attributes.
 *
 * On error answer the status.
 *
 */
sqInt faFileStatAttributes(fapath *aFaPath, int lStat, sqInt attributeArray)
{
faStatStruct	statBuf;
int		status;
int		mode;
sqInt		targetOop;
char		targetFile[FA_PATH_MAX];


	targetOop = nilOop;
	if (lStat) {
		status = lstat(faGetPlatPath(aFaPath), &statBuf);
		if (status)
			return FA_CANT_STAT_PATH;
		if (S_ISLNK(statBuf.st_mode)) {
			/* This is a symbolic link, provide the target filename */
			status = readlink(faGetPlatPath(aFaPath), targetFile, FA_PATH_MAX);
			if (status >= 0)
				targetOop = pathNameToOop(targetFile); } }
	else {
		status = stat(faGetPlatPath(aFaPath), &statBuf);
		if (status)
			return FA_CANT_STAT_PATH; }

	interpreterProxy->storePointerofObjectwithValue(
		0, attributeArray,
		targetOop);

	interpreterProxy->storePointerofObjectwithValue(
		1, attributeArray,
		interpreterProxy->positive32BitIntegerFor(statBuf.st_mode));

	interpreterProxy->storePointerofObjectwithValue(
		2, attributeArray,
		interpreterProxy->positive64BitIntegerFor(statBuf.st_ino));

	interpreterProxy->storePointerofObjectwithValue(
		3, attributeArray,
		interpreterProxy->positive64BitIntegerFor(statBuf.st_dev));

	interpreterProxy->storePointerofObjectwithValue(
		4, attributeArray,
		interpreterProxy->positive32BitIntegerFor(statBuf.st_nlink));

	interpreterProxy->storePointerofObjectwithValue(
		5, attributeArray,
		interpreterProxy->positive32BitIntegerFor(statBuf.st_uid));

	interpreterProxy->storePointerofObjectwithValue(
		6, attributeArray,
		interpreterProxy->positive32BitIntegerFor(statBuf.st_gid));

	interpreterProxy->storePointerofObjectwithValue(
		7, attributeArray,
		(S_ISDIR(statBuf.st_mode) == 0) ?
			interpreterProxy->positive64BitIntegerFor(statBuf.st_size) :
			interpreterProxy->positive32BitIntegerFor(0));

	interpreterProxy->storePointerofObjectwithValue(
		8, attributeArray,
		interpreterProxy->signed64BitIntegerFor(
			faConvertUnixToLongSqueakTime(statBuf.st_atime)));

	interpreterProxy->storePointerofObjectwithValue(
		9, attributeArray,
		interpreterProxy->signed64BitIntegerFor(
			faConvertUnixToLongSqueakTime(statBuf.st_mtime)));

	interpreterProxy->storePointerofObjectwithValue(
		10, attributeArray,
		interpreterProxy->signed64BitIntegerFor(
			faConvertUnixToLongSqueakTime(statBuf.st_ctime)));

	interpreterProxy->storePointerofObjectwithValue(11, attributeArray, nilOop);

	/* Windows file attribute flags - not supported on Unix */
	interpreterProxy->storePointerofObjectwithValue(12, attributeArray, nilOop);

	return FA_SUCCESS;
}


/*
 * faAccessAttributes
 *
 * Call access() for each access type (R, W, X) on the supplied path, 
 * storing the results in the st array attributeArray.
 */
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset)
{
	sqInt accessOop, index = offset;

	accessOop = access(faGetPlatPath(aFaPath), R_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = access(faGetPlatPath(aFaPath), W_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	accessOop = access(faGetPlatPath(aFaPath), X_OK) ? falseOop : trueOop;
	interpreterProxy->storePointerofObjectwithValue(index++, attributeArray, accessOop);

	return 0;
}
