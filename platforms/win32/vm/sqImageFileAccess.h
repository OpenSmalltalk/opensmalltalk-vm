/****************************************************************************
*   PROJECT: API for reading/writing image files
*   FILE:    sqImageFileAccess.h
*
*/

/* This is expected to be included by sq.h */

#ifndef _SQ_IMAGE_FILE_ACCESS_H
#define _SQ_IMAGE_FILE_ACCESS_H

#ifdef WIN32_FILE_SUPPORT

# define NO_STD_FILE_SUPPORT /* STD_FILE or WIN32_FILE are mutually exclusive options */

# if _WIN64
#	define sqImageFile unsigned __int64
# else
#	define sqImageFile unsigned __int32
# endif

int sqImageFileClose(sqImageFile h);
sqImageFile sqImageFileOpen(const char *fileName, const char *mode);
squeakFileOffsetType sqImageFilePosition(sqImageFile h);
size_t sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile h);
squeakFileOffsetType sqImageFileSeek(sqImageFile h, squeakFileOffsetType pos);
squeakFileOffsetType sqImageFileSeekEnd(sqImageFile h, squeakFileOffsetType pos);
size_t sqImageFileWrite(const void *ptr, size_t sz, size_t count, sqImageFile h);
# else /* when no WIN32_FILE_SUPPORT, add necessary stub for using regular Cross/plugins/FilePlugin functions */
#	include <stdlib.h>
#	include <io.h> /* _get_osfhandle */
#	define PATH_MAX _MAX_PATH
#	define fsync(filenumber) FlushFileBuffers((HANDLE)_get_osfhandle(filenumber))
#	include "sqImageFileAccessViaStdio.h"
# endif /* WIN32_FILE_SUPPORT */
#endif /* _SQ_IMAGE_FILE_ACCESS_H */
