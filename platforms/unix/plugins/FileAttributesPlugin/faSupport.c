/*
 * faSupport.c - Unix support routines for the FileAttributesPlugin
 *
 * Author: akgrant@gmail.com
 */
#include <dirent.h>
#include <errno.h>

#include "sq.h"
#include "faSupport.h"



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

sqInt faOpenDirectory(osdir *dirState)
{
sqInt		pathLength;
sqInt		status;
DIR		*dir;


/* Open the directory */ 
dir = opendir(dirState->path);
if (dir == NULL)
	return FA_CANT_OPEN_DIR;

dirState->platformDir = (void *)dir;
fprintf(stderr, "faOpenDirectory: osdir * %p, DIR * %p\n", dirState, dir);
fflush(stderr);
return faReadDirectory(dirState);
}




/*
 * faReadDirectory
 *
 * Read the next entry from the already opened directory (dirState)
 *
 * If there are no entries, return FA_NO_MORE_DATA
 */

sqInt faReadDirectory(osdir *dirState)
{
sqInt		haveEntry;
struct dirent	*entry;
sqInt		entry_length;
DIR		*dirPtr;
sqInt		status;

dirPtr = (DIR *)dirState->platformDir;
fprintf(stderr, "faReadDirectory: osdir * %p, DIR * %p\n", dirState, dirPtr);
fflush(stderr);
haveEntry = 0;
errno = 0;
do {
	entry = readdir(dirPtr);
	if (entry == NULL)
		if (errno == 0)
			return FA_NO_MORE_DATA;
		else
			return FA_CANT_READ_DIR;
	if ((!(entry->d_name[0] == '.' && entry->d_name[1] == 0)) && strcmp(entry->d_name, ".."))
		haveEntry = 1;
} while (!haveEntry);

entry_length = strlen(entry->d_name);
if (entry_length > dirState->max_file_len)
	return FA_STRING_TOO_LONG;

fprintf(stderr, "read: %s\n", entry->d_name);
fflush(stderr);

strncpy(dirState->path_file, entry->d_name, dirState->max_file_len);

return FA_SUCCESS;
}



/*
 * faCloseDirectory(void *dirStateId)
 *
 * Close the supplied directory.
 */

sqInt faCloseDirectory(osdir *dirState)
{
DIR	*dirPtr;
sqInt	status;

dirPtr = (DIR *)dirState->platformDir;
fprintf(stderr, "faCloseDirectory: osdir * %p, DIR * %p\n", dirState, dirPtr);
fflush(stderr);
status = closedir(dirPtr);
if (status) return FA_UNABLE_TO_CLOSE_DIR;
dirState->platformDir = 0;

return FA_SUCCESS;
}


