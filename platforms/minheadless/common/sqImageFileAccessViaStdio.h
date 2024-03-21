/****************************************************************************
*   PROJECT: API for reading/writing image files
*   FILE:    sqImageFileAccessViaStdio.h
*
*/

/* This is a lowest common denominator, a poor man's image file interface built
 * using macros around stdio. Stdio is poor because it provides buffered i/o.
 * Much better is unbuffered i/o using the platform's native file interface.
 * Apart from a few fields in the image header the entire image is read and
 * written in segments, many megabytes in size.  Unbuffered is the way to go.
 *
 * This file may be included by a platform's sqImageFileAccess.h if it is
 * unable to provide the interface itself, or offers it as an option.
 */
#include <stdio.h>

#define sqImageFile								FILE *
#define invalidSqImageFile(sif)					(!(sif))
#define sqImageFileClose(f)						fclose(f)
#define sqImageFileOpen(fileName, mode)			fopen(fileName, mode)
#define sqImageFilePosition(f)					ftello(f)
#define sqImageFileRead(ptr, sz, count, f)		fread(ptr, sz, count, f)
#define sqImageFileSeek(f, pos)					fseeko(f, pos, SEEK_SET)
#define sqImageFileSeekEnd(f, pos)				fseeko(f, pos, SEEK_END)
#define sqImageFileWrite(ptr, sz, count, f)		fwrite(ptr, sz, count, f)
#define sqImageFileStartLocation(f,fileName,sz)	0
#define sqImageFileIsEmbedded() 0
extern sqInt checkImageHeaderFromBytesAndSize(char *bytes, sqInt totalSize);
