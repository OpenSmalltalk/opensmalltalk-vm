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

// On Unix we use the native file interface.

#define sqImageFile	int
#define squeakFileOffsetType off_t

// Save/restore.
// Read the image from the given file starting at the given image offset
size_t readImageFromFileHeapSizeStartingAt(sqImageFile f, usqInt desiredHeapSize, squeakFileOffsetType imageOffset);

static int sIFOMode;

static inline sqImageFile
sqImageFileOpen(const char *fileName, const char *mode)
{
	int fd = open(fileName,
				  sIFOMode = !strcmp(mode,"rb") ? O_RDONLY : O_RDWR+O_CREAT,
				  0666);
	if (fd < 0) {
		perror("sqImageFileOpen open");
		exit(errno);
	}
	return fd;
}

static inline void
sqImageFileClose(sqImageFile f)
{
extern sqInt failed(void);

	if (!failed()
	 && sIFOMode == O_RDWR+O_CREAT
	 && ftruncate(f,lseek(f, 0, SEEK_CUR)) < 0)
		perror("sqImageFileClose ftruncate");
	/* Don't exit; if snapshotting, continuing is probably the best course */
	if (close(f) < 0)
		perror("sqImageFileClose close");
}

#if !defined(min)
# define min(a,b) ((a)<=(b)?(a):b)
#endif
#define OneGb 0x40000000 // hah,hah,hah,hah https://y2u.be/watch?v=EJR1H5tf5wE

// sqImageFileRead answers the number of items read, not number of bytes
// size_t is for sizes.  ssize_t is signed, for sizes + the -1 error flag
static inline size_t
sqImageFileRead(void *ptr_arg, long sz, long count, sqImageFile f)
{
	size_t to_be_read = sz * count, nread_in_total = 0;
	unsigned char *ptr = ptr_arg;

	/* read may refuse to write more than 2Gb-1.  At least on MacOS 10.13.6,
	 * read craps out above 2Gb, so chunk the read into to 1Gb segments.
	 */
	do {
		ssize_t n = read(f, ptr, min(to_be_read-nread_in_total,OneGb));

		// Don't exit!!; if snapshotting, we obviously must continue
		if (n == (size_t)-1) {
			perror("sqImageFileRead read");
			return nread_in_total;
		}
		nread_in_total += n;
		ptr += n;
	}
	while (nread_in_total < to_be_read);

	return nread_in_total / sz;
}

// sqImageFileWrite answers the number of items written, not number of bytes
// size_t is for sizes.  ssize_t is signed, for sizes + the -1 error flag
static inline size_t
sqImageFileWrite(void *ptr_arg, size_t sz, size_t count, sqImageFile f)
{
	size_t to_be_written = sz * count, nwritten_in_total = 0;
	unsigned char *ptr = ptr_arg;

	/* write may refuse to write more than 2Gb-1.  At least on MacOS 10.13.6,
	 * write craps out above 2Gb, so chunk the write into to 1Gb segments.
	 */
	do {
		ssize_t n = write(f, ptr, min(to_be_written-nwritten_in_total,OneGb));

		// Don't exit!!; if snapshotting, we obviously must continue
		if (n == (size_t)-1) {
			perror("sqImageFileWrite write");
			return nwritten_in_total;
		}
		nwritten_in_total += n;
		ptr += n;
	}
	while (nwritten_in_total < to_be_written);

	return nwritten_in_total / sz;
}
#undef OneGb

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
