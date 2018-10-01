#include <windows.h>
#include <sys/stat.h>

/* Maximum path length allowed on this platform */
#define	FA_PATH_MAX	4096
#define PATH_SEPARATOR	'\\'

typedef struct _stat	faStatStruct;


/*
 * typedef osdir
 *
 * This holds the current state for retrieving all the children of a 
 * directory.
 *
 * The directory (path) being enumerated and the current file name are stored
 * in a single string (path) to simplify stat()ing the file.
 *
 * platformDir	- platform specific data for directory enumeration.
 * path_len	- length of the name of the path being enumerated.
 * path_file	- points to the file name of the current entry.
 * 		  This is set to the byte after the directory name
 * 		  and is used to stat() each file.
 * max_file_len	- The space remaining after the path for the file name.
 * path		- The directory name being enumerated, with UTF8 encoding.
 */
typedef struct fapathstruct {
	char	path[FA_PATH_MAX];
	sqInt	path_len;
	char	*path_file;
	sqInt	max_file_len;

	/* Add 4 bytes to winpath for the \\?\ prefix */
	WCHAR	winpath[FA_PATH_MAX+4];
	sqInt	winpath_len; /* Number of characters, including the prefix */
	WCHAR	*winpath_file;
	WCHAR	*winpath2;
	sqInt	winpath2_len; /* Number of characters, not bytes */
	sqInt	winmax_file_len;

	HANDLE			directoryHandle;
	WIN32_FIND_DATAW	findData;
	} fapath;

sqInt faSetStDir(fapath *aFaPath, char *pathName, int len);
sqInt faSetStPath(fapath *aFaPath, char *pathName, int len);
sqInt faSetStFile(fapath *aFaPath, char *pathName);
sqInt faSetPlatPath(fapath *aFaPath, WCHAR *pathName);
sqInt faSetPlatPathOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetPlatFile(fapath *aFaPath, WCHAR *pathName);
#define	faGetStPath(aFaPath)		aFaPath->path
#define faGetStPathLen(aFaPath)		aFaPath->path_len
#define	faGetStFile(aFaPath)		aFaPath->path_file
#define	faGetPlatPath(aFaPath)		aFaPath->winpath
#define faGetPlatPathByteCount(aFaPath)	(aFaPath->winpath_len * sizeof(WCHAR))
#define	faGetPlatPath2(aFaPath)		aFaPath->winpath2
#define faGetPlatPath2ByteCount(aFaPath)	(aFaPath->winpath2_len * sizeof(WCHAR))
#define	faGetPlatFile(aFaPath)		aFaPath->winpath_file

sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetStPathOop(fapath *aFaPath, sqInt pathNameOop);

sqInt faOpenDirectory(fapath *aFaPath);
sqInt faReadDirectory(fapath *aFaPath);
sqInt faCloseDirectory(fapath *aFaPath);
sqInt faFileAttribute(fapath *aFaPath, sqInt attributeNumber);
sqInt faStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop);
sqInt faLinkStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop);
sqInt faExists(fapath *aFaPath);
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset);

