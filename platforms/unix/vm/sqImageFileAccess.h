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
#if HAVE_LIBZ && INCLUDE_SIF_CODE
# include <zlib.h>
#endif

// On Unix we use the native file interface. There is also support for embedded images,
// which may be compressed with gzip. See deploy/packaging/genUnixImageResource.c

#define sqImageFile	int
#define invalidSqImageFile(sif) ((sif) < 0)
#define squeakFileOffsetType off_t
#define ImageIsEmbedded ((sqImageFile)1)
#define ImageIsEmbeddedAndCompressed ((sqImageFile)2)

#define GZIPMagic0 0x1f
#define GZIPMagic1 0x8b


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

static int sIFOMode; // input/output file mode

// Support for image embedded as a resource
static unsigned char *eiData = NULL;
static unsigned long eiSize = 0, eicSize = 0;
static off_t eiReadPosition = 0;
#if HAVE_LIBZ
static z_stream eizs = { 0, }; // embedded image zlib stream
#endif


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
#if HAVE_LIBZ
	if (f == ImageIsEmbeddedAndCompressed) {
		(void)inflateEnd(&eizs);
		return;
	}
#endif

	if (!failed()
	 && sIFOMode == O_RDWR+O_CREAT
	 && ftruncate(f,lseek(f, 0, SEEK_CUR)) < 0)
		perror("sqImageFileClose ftruncate");
	/* Don't exit; if snapshotting, continuing is probably the best course */
	if (close(f) < 0)
		perror("sqImageFileClose close");
}

static inline void
noteEmbeddedImage(unsigned char *data, unsigned long size, unsigned long csize)
{
	eiData = data;
	eiSize = size;
	eicSize = csize;
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

#if HAVE_LIBZ
static inline size_t
sqCompressedImageRead(void *ptr, size_t sz, size_t count)
{
	size_t nread = 0, ntoread = sz * count;
	unsigned long nreadSoFar = eizs.total_out;
	int ret;

	if (!eizs.next_in) {
		eizs.avail_in = eicSize;
		eizs.next_in = eiData;
		ret = inflateInit2(&eizs,MAX_WBITS+16);
		if (ret != Z_OK) {
			fprintf(stderr,"inflateInit failed on reading compressed embedded image\n");
			return 0;
		}
	}

	if (eiReadPosition + ntoread > eiSize) {
		fprintf(stderr,"Attempting to read beyond end of embedded image\n");
		return 0;
	}
	// N.B. seeking backwards is as yet unimplemented (cuz all platforms,
	// and hence all images, are little endian as of 2024). One way to
	// implement this is to go back to the beginning and advance forward.
	// This should be a fine strategy since seeking backwards is only done
	// if the initial image magic number looks wrong, and the initial
	// magic number is the first word in the image file.
	assert(eiReadPosition >= nreadSoFar);
	// to seek forward simply discard that much data
	if (eiReadPosition > nreadSoFar) {
		assert(eiReadPosition - nreadSoFar <= sz * count);
		eizs.avail_out = eiReadPosition - nreadSoFar;
		eizs.next_out = ptr;

		// Decompress to fill ptr with eiReadPosition - nreadSoFar's worth
		ret = inflate(&eizs, Z_NO_FLUSH);
		switch (ret) {
		case Z_NEED_DICT:
		case Z_DATA_ERROR:
		case Z_MEM_ERROR:
			(void)inflateEnd(&eizs);
			return nread;
		}
		nreadSoFar = eiReadPosition;
	}
	eizs.avail_out = ntoread;
	eizs.next_out = ptr;

	// Decompress to fill ptr with count's worth
	ret = inflate(&eizs, Z_NO_FLUSH);
	switch (ret) {
	case Z_NEED_DICT:
	case Z_DATA_ERROR:
	case Z_MEM_ERROR:
		(void)inflateEnd(&eizs);
		return nread;
	}
	assert(eizs.total_out - nreadSoFar == sz * count);
	eiReadPosition += ntoread;
	return count;
}
#endif // HAVE_LIBZ

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
#if HAVE_LIBZ
	if (f == ImageIsEmbeddedAndCompressed)
		return sqCompressedImageRead(ptr,sz,count);
#else
	if (f == ImageIsEmbeddedAndCompressed) {
		fprintf(stderr,"Embedded image is compressed but libz is missing!\n");
		exit(1);
	}
#endif

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
	if (f == ImageIsEmbedded
	 || f == ImageIsEmbeddedAndCompressed)
		return eiReadPosition;

	off_t pos = lseek(f, 0, SEEK_CUR);
	if (pos == (off_t)-1)
		perror("sqImageFilePosition lseek");
	return pos;
}

void
sqImageFileSeek(sqImageFile f,off_t pos)
{
	if (f == ImageIsEmbedded
	 || f == ImageIsEmbeddedAndCompressed)
		eiReadPosition = pos;
	else if (lseek(f, pos, SEEK_SET) < 0)
		perror("sqImageFileSeek lseek");
}

void
sqImageFileSeekEnd(sqImageFile f,off_t pos)
{
	if (f == ImageIsEmbedded
	 || f == ImageIsEmbeddedAndCompressed)
		eiReadPosition = eiSize;
	else if (lseek(f, pos, SEEK_END) < 0)
		perror("sqImageFileSeekEnd lseek");
}

#endif // INCLUDE_SIF_CODE
#endif // _SQ_IMAGE_FILE_ACCESS_H
