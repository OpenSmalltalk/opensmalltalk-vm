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

// On Unix we use the native file interface. There is also support for embedded images

#define sqImageFile	int
#define invalidSqImageFile(sif) ((sif) < 0)
#define squeakFileOffsetType off_t
#define ImageIsEmbedded ((sqImageFile)1)

// Save/restore.

extern sqInt checkImageHeaderFromBytesAndSize(char *bytes, sqInt totalSize);

// Read the image from the given file starting at the given image offset
size_t readImageFromFileHeapSizeStartingAt(sqImageFile f, usqInt desiredHeapSize, squeakFileOffsetType imageOffset);


// Image I/O API

sqImageFile sqImageFileOpen(const char *fileName, const char *mode);
void sqImageFileClose(sqImageFile f);
int sqImageFileIsEmbedded(void);
size_t sqImageFileRead(void *ptr_arg, long sz, long count, sqImageFile f);
// sqImageFileWrite answers the number of items written, not number of bytes
// size_t is for sizes.  ssize_t is signed, for sizes + the -1 error flag
size_t sqImageFileWrite(void *ptr_arg, size_t sz, size_t count, sqImageFile f);
off_t sqImageFilePosition(sqImageFile f);
void sqImageFileSeek(sqImageFile f,off_t pos);
void sqImageFileSeekEnd(sqImageFile f,off_t pos);

#define sqImageFileStartLocation(f,fileName,sz)	0

// Image I/O API Implementation

#if INCLUDE_SIF_CODE

static int sIFOMode;

sqImageFile
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

void
sqImageFileClose(sqImageFile f)
{
extern sqInt failed(void);

	if (f == ImageIsEmbedded)
		return;

	if (!failed()
	 && sIFOMode == O_RDWR+O_CREAT
	 && ftruncate(f,lseek(f, 0, SEEK_CUR)) < 0)
		perror("sqImageFileClose ftruncate");
	/* Don't exit; if snapshotting, continuing is probably the best course */
	if (close(f) < 0)
		perror("sqImageFileClose close");
}

// Support for image embedded as a resource
static unsigned char *eiData = NULL;
static unsigned long eiSize = 0;
static off_t eiReadPosition = 0;

static inline void
noteEmbeddedImage(unsigned char *data, unsigned long size)
{
	eiData = data;
	eiSize = size;
}

int
sqImageFileIsEmbedded(void) { return eiData != NULL; }

static inline size_t
sqEmbeddedImageRead(void *ptr, size_t sz, size_t count)
{
	if (eiReadPosition + (sz * count) > eiSize) {
		fprintf(stderr,"Attempting to read beyond end of embedded image\n");
		return 0;
	}

	memcpy(ptr,eiData + eiReadPosition, sz * count);
	eiReadPosition += sz * count;
	return count;
}


#if !defined(min)
# define min(a,b) ((a)<=(b)?(a):b)
#endif
#define OneGb 0x40000000 // hah,hah,hah,hah https://y2u.be/watch?v=EJR1H5tf5wE

// sqImageFileRead answers the number of items read, not number of bytes
// size_t is for sizes.  ssize_t is signed, for sizes + the -1 error flag
size_t
sqImageFileRead(void *ptr_arg, long sz, long count, sqImageFile f)
{
	size_t to_be_read = sz * count, nread_in_total = 0;
	unsigned char *ptr = ptr_arg;

	if (f == ImageIsEmbedded)
		return sqEmbeddedImageRead(ptr,sz,count);

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
size_t
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

off_t
sqImageFilePosition(sqImageFile f)
{
	if (f == ImageIsEmbedded)
		return eiReadPosition;

	off_t pos = lseek(f, 0, SEEK_CUR);
	if (pos == (off_t)-1)
		perror("sqImageFilePosition lseek");
	return pos;
}

void
sqImageFileSeek(sqImageFile f,off_t pos)
{
	if (f == ImageIsEmbedded)
		eiReadPosition = pos;
	else if (lseek(f, pos, SEEK_SET) < 0)
		perror("sqImageFileSeek lseek");
}

void
sqImageFileSeekEnd(sqImageFile f,off_t pos)
{
	if (f == ImageIsEmbedded)
		eiReadPosition = eiSize;
	else if (lseek(f, pos, SEEK_END) < 0)
		perror("sqImageFileSeekEnd lseek");
}

#endif // INCLUDE_SIF_CODE
#endif // _SQ_IMAGE_FILE_ACCESS_H
