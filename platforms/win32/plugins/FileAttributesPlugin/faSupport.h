/*
 * faSupport.h - Windows macro and type definitions for FileAttributesPlugin
 */
#include <windows.h>
#include <sys/stat.h>

/* Maximum path length allowed on this platform */
#define	FA_PATH_MAX	32768
#define PATH_SEPARATOR	'\\'

/*
 * Set the structure used by stat().
 */
typedef struct _stat	faStatStruct;


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
 * path_dirlen	- length of the directory component of the path.
 * 		  0 if directory not set.
 * path_len	- length of path.
 * path_file	- When iterating over a directory, this points to the 
 * 		  character after the trailing path separator.
 * 		  The current file will be stored here and is used to 
 * 		  stat() each file.
 * max_file_len	- The space remaining after the path for the file name.
 *
 * winpath, winpath_dirlen, winpath_len, winpath_file and winmax_file_len are 
 * the Windows wide string encoded equivalents.
 *
 * Some windows functions require the path name be prepended with "\\?\" to
 * support long file names, while others support long file names without the
 * leading characters. winpath includes the "\\?\" prefix, while winpath2 
 * excludes it.
 */
typedef struct fapathstruct {
	char	path[FA_PATH_MAX];
	sqInt	path_dirlen;
	sqInt	path_len;
	char	*path_file;
	sqInt	max_file_len;

	/* Add 4 bytes to winpath for the \\?\ prefix */
	WCHAR	winpathLPP[FA_PATH_MAX+4];
	sqInt	winpathLPP_len; /* Number of characters, including the LPP */
	WCHAR	*winpath_file;
	WCHAR	*winpath;	/* Pointer to the path, excluding the LPP */
	sqInt	winpath_dirlen; /* Number of characters, not bytes */
	sqInt	winpath_len; /* Number of characters, not bytes */
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
#define	faGetStPath(aFaPath)		(aFaPath)->path
#define faGetStDirLen(aFaPath)		(aFaPath)->path_dirlen
#define faGetStPathLen(aFaPath)		(aFaPath)->path_len
#define	faGetStFile(aFaPath)		(aFaPath)->path_file
#define	faGetPlatPath(aFaPath)		(aFaPath)->winpath
#define faGetPlatPathByteCount(aFaPath)	((aFaPath)->winpath_len * sizeof(WCHAR))
#define	faGetPlatPathLPP(aFaPath)		(aFaPath)->winpathLPP
#define faGetPlatPathLPPByteCount(aFaPath)	((aFaPath)->winpathLPP_len * sizeof(WCHAR))
#define	faGetPlatFile(aFaPath)		(aFaPath)->winpath_file

/*
 * faGetPlatPathCPP
 *
 * Get the platform path encoding, taking in to account whether the MS
 * Long Path Prefix (\\?\) should be used.
 *
 * The current heuristic is to use the LPP if the path length > MAX_PATH-12.
 *
 * Additional information that could be used is lpMaximumComponentLength from
 * GetVolumneInformation().
 *
 * MAX_PATH-12 is used as when creating directories space for an 8.3 file name
 * must be available (within MAX_PATH).
 *
 * For additional confusion, see:
 * http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx#maxpath
 *
 * If the LPP should always be prepended, use faGetPlatPathLPP().
 * If the LPP should never be prepended, use faGetPlatPath().
 *
 * Note that testing is difficult as getting it wrong doesn't guarantee that 
 * a call will fail, e.g. it might work with C:\a\b\c.txt, but fail with
 * C:\a\b\..\d\c.txt
 */
#define faGetPlatPathCPP(aFaPath)	((wcslen((aFaPath)->winpath) <= (MAX_PATH-12)) ? (aFaPath)->winpath : (aFaPath)->winpathLPP)


sqInt faOpenDirectory(fapath *aFaPath);
sqInt faReadDirectory(fapath *aFaPath);
sqInt faCloseDirectory(fapath *aFaPath);
sqInt faRewindDirectory(fapath *aFaPath);
sqInt faFileAttribute(fapath *aFaPath, sqInt attributeNumber);
sqInt faFileStatAttributes(fapath *aFaPath, int lStat, sqInt attributeArray);
sqInt faExists(fapath *aFaPath);
sqInt faAccessAttributes(fapath *aFaPath, sqInt attributeArray, sqInt offset);
