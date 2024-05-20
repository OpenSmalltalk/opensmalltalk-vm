/****************************************************************************
*   PROJECT: API for reading/writing image files
*   FILE:    sqImageFileAccess.h
*
*/

/* This is expected to be included by sq.h */

#ifndef _SQ_IMAGE_FILE_ACCESS_H
#define _SQ_IMAGE_FILE_ACCESS_H

#include <Windows.h> // for DWORD type

#if _WIN64
# define sqImageFile unsigned __int64
#else
# define sqImageFile unsigned __int32
#endif
#define invalidSqImageFile(sif) (!(sif))
#define squeakFileOffsetType unsigned __int64

#define ImageIsAResource ((sqImageFile)1)
#define ImageIsACompressedResource ((sqImageFile)2)
#define GZIPMagic0 0x1f
#define GZIPMagic1 0x8b

// Save/restore.

extern sqInt checkImageHeaderFromBytesAndSize(char *bytes, sqInt totalSize);

// Read the image from the given file starting at the given image offset
size_t readImageFromFileHeapSizeStartingAt(sqImageFile f, usqInt desiredHeapSize, squeakFileOffsetType imageOffset);
sqInt byteSwapped(sqInt);

squeakFileOffsetType sqImageFileSize(sqImageFile h);
int sqImageFileClose(sqImageFile h);
sqImageFile sqImageFileOpen(const char *fileName, const char *mode);
squeakFileOffsetType sqImageFilePosition(sqImageFile h);
size_t sqImageFileRead(void *ptr, size_t sz, size_t count, sqImageFile h);
size_t sqImageFileWrite(const void *ptr, size_t sz, size_t count, sqImageFile h);
squeakFileOffsetType sqImageFileSeek(sqImageFile h, squeakFileOffsetType pos);
squeakFileOffsetType sqImageFileSeekEnd(sqImageFile h, squeakFileOffsetType pos);

#define sqImageFileStartLocation(f,fileName,sz)	0
sqInt sqImageFileIsEmbedded(void);
void sqFilePluginNoteImageResourceData(void *,DWORD);

#endif /* _SQ_IMAGE_FILE_ACCESS_H */
