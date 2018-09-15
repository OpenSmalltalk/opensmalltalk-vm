

/* REQUIRED: c file must have included standard squeak definitions */
#include "faConstants.h"

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
typedef struct dirptrstruct {
	sqInt			path_len;
	char			*path_file;
	sqInt			max_file_len;
	char			path[PATH_MAX+4];
	HANDLE			directoryHandle;
	WIN32_FIND_DATAW	findData;
	} osdir;

#define PATH_SEPARATOR	'\\'

sqInt faOpenDirectory(osdir *dirState);
sqInt faReadDirectory(osdir *dirState);
sqInt faCloseDirectory(osdir *dirState);

