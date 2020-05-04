#pragma once

#ifndef __imageAccess_h__
#define __imageAccess_h__

#define sqImageFile void*
#define squeakFileOffsetType size_t

typedef struct {
	sqInt (*imageFileClose)(sqImageFile f);

	sqImageFile (*imageFileOpen)(char* fileName, char *mode);
	long int (*imageFilePosition)(sqImageFile f);
	size_t (*imageFileRead)(void * ptr, size_t sz, size_t count, sqImageFile f);

	int (*imageFileSeek)(sqImageFile f, long int pos);
	int (*imageFileSeekEnd)(sqImageFile f, long int pos);
	size_t (*imageFileWrite)(void* ptr, size_t sz, size_t count, sqImageFile f);
	int (*imageFileExists)(const char* aPath);
	void (*imageReportProgress)(size_t totalSize, size_t currentSize);
} _FileAccessHandler;

typedef _FileAccessHandler FileAccessHandler;

EXPORT(FileAccessHandler*) currentFileAccessHandler();
EXPORT(void) setFileAccessHandler(FileAccessHandler* aFileAccessHandler);

#define sqImageFileClose(f) 				currentFileAccessHandler()->imageFileClose(f)
#define sqImageFileOpen(fileName, mode)		currentFileAccessHandler()->imageFileOpen(fileName, mode)
#define sqImageFilePosition(f)				currentFileAccessHandler()->imageFilePosition(f)

#define sqImageFileRead(ptr, sz, count, f)  currentFileAccessHandler()->imageFileRead(ptr, sz, count, f)

#define sqImageFileSeek(f, pos)				currentFileAccessHandler()->imageFileSeek(f, pos)
#define sqImageFileSeekEnd(f, pos)			currentFileAccessHandler()->imageFileSeekEnd(f, pos)
#define sqImageFileWrite(ptr, sz, count, f)	currentFileAccessHandler()->imageFileWrite(ptr, sz, count, f)

#define sqImageFileExists(aPath)			currentFileAccessHandler()->imageFileExists(aPath)

#define sqImageFileStartLocation(fileRef, fileName, size)  0
#define sqImageReportProgress(totalSize, currentSize)	currentFileAccessHandler()->imageReportProgress(totalSize, currentSize)

#endif
