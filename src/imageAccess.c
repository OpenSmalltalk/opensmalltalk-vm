#include "pharovm/pharo.h"
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

/*
 * The read and write function uses a 128kb chunk size.
 * It is based in the analysis of how cp, cat and other tools access the disk
 * Check https://eklitzke.org/efficient-file-copying-on-linux
 */

sqInt basicImageFileClose(sqImageFile f){
	return fclose((FILE*)f);
}

sqImageFile basicImageFileOpen(char* fileName, char *mode){
	return fopen(fileName, mode);
}

long int basicImageFilePosition(sqImageFile f){
	return ftell((FILE*)f);
}

size_t basicImageFileRead(void * initialPtr, size_t sz, size_t count, sqImageFile f){

	size_t readBytes = 0;
	size_t bytesToRead = sz * count;
	size_t lastReadBytes = 0;
	size_t chunkToRead = 128 * 1024; // 128 Kb
	void* currentPtr = initialPtr;

	if(bytesToRead <= chunkToRead){
		return fread(initialPtr, sz, count, (FILE*)f);
	}

#ifdef posix_fadvise
	off_t initialPosition;
	initialPosition = sqImageFilePosition(f);
	if(posix_fadvise(fileno(f), initialPosition, bytesToRead, POSIX_FADV_SEQUENTIAL)){
		logErrorFromErrno("posix_fadvise");
	}
#endif

	do{
		lastReadBytes = fread(currentPtr, 1, chunkToRead, (FILE*)f);

		if(lastReadBytes < 0){
			logErrorFromErrno("fread");
			return lastReadBytes;
		}

		readBytes += lastReadBytes;
		currentPtr += lastReadBytes;

		sqImageReportProgress(bytesToRead, readBytes, "Loading image");

	} while(lastReadBytes > 0 && readBytes < bytesToRead);

	return bytesToRead;
}

int basicImageFileSeek(sqImageFile f, long int pos){
	return fseek((FILE*)f, pos, SEEK_SET);
}

int basicImageFileSeekEnd(sqImageFile f, long int pos){
	return fseek((FILE*)f, pos, SEEK_END);
}

size_t basicImageFileWrite(void* ptr, size_t sz, size_t count, sqImageFile f){
	return fwrite(ptr, sz, count, (FILE*)f);
}

int basicImageFileExists(const char* aPath){
	struct stat st;

	return stat(aPath, &st) == 0;
}

#define BARLENGTH 50

void basicImageReportProgress(size_t totalSize, size_t currentSize, char* text){

	char bar[BARLENGTH + 1];
	bar[BARLENGTH] = 0;

	if(totalSize){
		int percentage = currentSize * 100 / totalSize;

		for(int i = 0; i < BARLENGTH; i++){
			bar[i] = percentage >= ((i+1) * (100/BARLENGTH)) ? '#' : '-';
		}

		printf("\r%s: [%s] %d%%", text, bar, percentage);
	}else{
		printf("\r%s...");
	}

	if(totalSize <= currentSize)
		printf("\n");

	fflush(stdout);
}

FileAccessHandler defaultFileAccessHandler = {
		basicImageFileClose,
		basicImageFileOpen,
		basicImageFilePosition,
		basicImageFileRead,
		basicImageFileSeek,
		basicImageFileSeekEnd,
		basicImageFileWrite,
		basicImageFileExists,
		basicImageReportProgress
};

FileAccessHandler* fileAccessHandler = &defaultFileAccessHandler;

FileAccessHandler* currentFileAccessHandler(){
	return fileAccessHandler;
}

void setFileAccessHandler(FileAccessHandler* aFileAccessHandler){
	fileAccessHandler = aFileAccessHandler;
}
