/*
 * faSupport.h - Unix macro and type definitions for FileAttributesPlugin
 */
#include <dirent.h>
#include <sys/stat.h>

/* Maximum path length allowed on this platform */
#define	FA_PATH_MAX	PATH_MAX
#define PATH_SEPARATOR	'/'

#include "sqUnixCharConv.h"

/*
 * Set the structure used by stat().
 */
typedef struct stat	faStatStruct;


/*
 * fapath
 *
 * fapath is used to pass path names between smalltalk and the primitives.
 * The structure holds the path name in Smalltalk format (precomposed UTF8)
 * and the platform format (Wide Strings for Windows).
 * Set and Get functions are used to ensure that the two formats are always 
 * kept in sync.
 *
 * State information for iterating over directories is also held by fapath.
 * The directory (path) being enumerated and the current file name are stored
 * in a single string (path) to simplify stat()ing the file.
 *
 * path		- The path name in precomposed UTF8 encoding (Smalltalk encoding).
 * path_len	- length of path.
 * path_file	- When iterating over a directory, this points to the 
 * 		  character after the trailing path separator.
 * 		  The current file will be stored here and is used to 
 * 		  stat() each file.
 * max_file_len	- The space remaining after the path for the file name.
 *
 * uxpath, uxpath_len, uxpath_file and uxmax_file_len are the Unix 
 * encoded equivalents:
 * - UTF8 for Linux
 * - HFS specific decomposed UTF8 for OSX
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
sqInt faSetStPath(fapath *aFaPath, char *pathName, int len);
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
sqInt faRewindDirectory(fapath *aFaPath);
sqInt faFileAttribute(fapath *aFaPath, sqInt attributeNumber);
sqInt faFileStatAttributes(fapath *aFaPath, int lStat, sqInt attributeArray);
sqInt faExists(fapath *aFaPath);
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset);

