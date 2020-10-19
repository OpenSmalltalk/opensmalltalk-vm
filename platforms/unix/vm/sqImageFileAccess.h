/****************************************************************************
*   PROJECT: API for reading/writing image files
*   FILE:    sqImageFileAccess.h
*
*/

/* This is expected to be included by the interpreters and the file containing
 * main that actually launches the system.
 */

#ifndef _SQ_IMAGE_FILE_ACCESS_H
#define _SQ_IMAGE_FILE_ACCESS_H

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

/* On Unix we use the native file interface. */

#define sqImageFile	int
#define squeakFileOffsetType off_t

/* Save/restore. */
/* Read the image from the given file starting at the given image offset */
size_t readImageFromFileHeapSizeStartingAt(sqImageFile f, usqInt desiredHeapSize, squeakFileOffsetType imageOffset);

static inline void
sqImageFileClose(sqImageFile f)
{
	/* Don't exit; if snapshotting, continuing is probably the best course */
	if (close(f) < 0)
		perror("close");
}

static inline sqImageFile
sqImageFileOpen(const char *fileName, const char *mode)
{
	int fd = open(fileName,
				  !strcmp(mode,"rb") ? O_RDONLY : O_RDWR+O_CREAT,
				  0666);
	if (fd < 0) {
		perror("open");
		exit(errno);
	}
	return fd;
}

// sqImageFileRead answers the number of items read, not number of bytes
// size_t is for sizes.  ssize_t is for sizes + the -1 error flag
static inline size_t
sqImageFileRead(void *ptr, long sz, long count, sqImageFile f)
{
	ssize_t nread = read(f, ptr, (size_t)(count * sz));
	if (nread == (size_t)-1) {
		perror("read");
		exit(errno);
	}
	return nread / sz;
}

// sqImageFileWrite answers the number of items written, not number of bytes
// size_t is for sizes.  ssize_t is for sizes + the -1 error flag
static inline size_t
sqImageFileWrite(void *ptr, long sz, long count, sqImageFile f)
{
	ssize_t nwritten = write(f, ptr, (size_t)(count * sz));

	/* Don't exit; if snapshotting, continuing is probably the best course */
	if (nwritten == (size_t)-1)
		perror("write");

	return nwritten / sz;
}

static inline off_t
sqImageFilePosition(sqImageFile f)
{
	off_t pos = lseek(f, 0, SEEK_CUR);
	if (pos == (off_t)-1)
		perror("sqImageFilePosition lseek");
	return pos;
}

static inline void
sqImageFileSeek(sqImageFile f,off_t pos)
{
	if (lseek(f, pos, SEEK_SET) < 0)
		perror("sqImageFileSeek lseek");
}

static inline void
sqImageFileSeekEnd(sqImageFile f,off_t pos)
{
	if (lseek(f, pos, SEEK_END) < 0)
		perror("sqImageFileSeekEnd lseek");
}

#define sqImageFileStartLocation(f,fileName,sz)	0

#endif /* _SQ_IMAGE_FILE_ACCESS_H */
