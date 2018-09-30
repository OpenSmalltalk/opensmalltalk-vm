#include <dirent.h>
#include <sys/stat.h>

# include "sqUnixCharConv.h"

/* REQUIRED: c file must have included standard squeak definitions */
#include "faConstants.h"


/* Maximum path length allowed on this platform */
#define	FA_PATH_MAX	PATH_MAX
#define PATH_SEPARATOR	'/'

typedef struct stat	faStatStruct;


/*
 * typedef fapath
 *
 * This holds the current state for retrieving all the children of a 
 * directory.
 *
 * The directory (path) being enumerated and the current file name are stored
 * in a single string (path) to simplify stat()ing the file.
 *
 * path_len	- length of the name of the path being enumerated.
 * path		- The directory name being enumerated, with precomposed UTF8
 * 		  encoding.
 * platformDir	- platform specific data for directory enumeration.
 * uxpath	- The directory name being enumerated in platform specific encoding
 * 		  Linux: precomposed UTF8
 * 		  OSX: HFS decomposed UTF8
 * uxpath_file	- points to the file name of the current entry.
 * 		  This is set to the byte after the directory name
 * 		  and is used to stat() each file.
 * max_file_len	- The space remaining after the path for the file name.
 */
typedef struct fapathstruct {
	char	path[FA_PATH_MAX];
	sqInt	path_len;
	char	*path_file;
	sqInt	max_file_len;

	char	uxpath[FA_PATH_MAX];
	sqInt	uxpath_len;
	char	*uxpath_file;
	sqInt	uxmax_file_len;

	DIR	*platformDir;
	} fapath;

sqInt faSetStDir(fapath *aFaPath, char *pathName, int len);
sqInt faSetStDirOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetStPath(fapath *aFaPath, char *pathName, int len);
sqInt faSetStPathOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetStFile(fapath *aFaPath, char *pathName);
sqInt faSetPlatPath(fapath *aFaPath, char *pathName);
sqInt faSetPlatPathOop(fapath *aFaPath, sqInt pathNameOop);
sqInt faSetPlatFile(fapath *aFaPath, char *pathName);
#define	faGetStPath(aFaPath)		aFaPath->path
#define faGetStPathLen(aFaPath)		aFaPath->path_len
#define	faGetStFile(aFaPath)		aFaPath->path_file
#define	faGetPlatPath(aFaPath)		aFaPath->uxpath
#define	faGetPlatFile(aFaPath)		aFaPath->uxpath_file
#define faGetPlatPathByteCount(aFaPath)	(aFaPath->uxpath_len * sizeof(char))

sqLong faConvertUnixToLongSqueakTime(time_t unixTime);

sqInt faOpenDirectory(fapath *aFaPath);
sqInt faReadDirectory(fapath *aFaPath);
sqInt faCloseDirectory(fapath *aFaPath);
sqInt faFileAttribute(fapath *aFaPath, sqInt attributeNumber);
sqInt faStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop);
sqInt faLinkStat(fapath *aFaPath, faStatStruct *statBuf, sqInt *fileNameOop);
sqInt faExists(fapath *aFaPath);
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset);

