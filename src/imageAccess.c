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

/* 128 Kb */
#define CHUNK_SIZE 128 * 1024
#define BARLENGTH 50

static int showOutputInConsole = false;

static char* progressText = "";

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
	size_t chunkToRead = 0;
	size_t remainingBytes = 0;
	void* currentPtr = initialPtr;

	if(bytesToRead <= CHUNK_SIZE){
		return fread(initialPtr, sz, count, (FILE*)f);
	}


#ifdef posix_fadvise
	off_t initialPosition;
	initialPosition = sqImageFilePosition(f);
	if(posix_fadvise(fileno(f), initialPosition, bytesToRead, POSIX_FADV_SEQUENTIAL)){
		logErrorFromErrno("posix_fadvise");
	}
#endif

	remainingBytes = bytesToRead;

	do{
		chunkToRead = remainingBytes < CHUNK_SIZE? remainingBytes : CHUNK_SIZE;

		lastReadBytes = fread(currentPtr, 1, chunkToRead, (FILE*)f);

		if(lastReadBytes < 0){
			logErrorFromErrno("fread");
			return lastReadBytes;
		}

		readBytes += lastReadBytes;
		currentPtr += lastReadBytes;
		remainingBytes -= lastReadBytes;

		sqImageReportProgress(bytesToRead, readBytes);

	} while(lastReadBytes > 0 && readBytes < bytesToRead);

	if(bytesToRead != readBytes){
		logError("Error reading expected to read: %lld actual read:%lld", (long long)bytesToRead, (long long)readBytes);
	}

	return readBytes;
}

int basicImageFileSeek(sqImageFile f, long int pos){
	return fseek((FILE*)f, pos, SEEK_SET);
}

int basicImageFileSeekEnd(sqImageFile f, long int pos){
	return fseek((FILE*)f, pos, SEEK_END);
}

size_t basicImageFileWrite(void* initialPtr, size_t sz, size_t count, sqImageFile f){

	size_t wroteBytes = 0;
	size_t remainingBytes = 0;
	size_t bytesToWrite = sz * count;
	size_t lastWriteBytes = 0;
	size_t chunkToWrite = 0;
	void* currentPtr = initialPtr;

	if(bytesToWrite <= CHUNK_SIZE){
		return fwrite(initialPtr, sz, count, (FILE*)f);
 	 }

	remainingBytes = bytesToWrite;

	do{
		chunkToWrite = remainingBytes < CHUNK_SIZE ? remainingBytes : CHUNK_SIZE;

		lastWriteBytes = fwrite(currentPtr, 1, chunkToWrite, (FILE*)f);

		if(lastWriteBytes != chunkToWrite){
			logErrorFromErrno("fwrite");
			return lastWriteBytes + wroteBytes;
		}

		wroteBytes += chunkToWrite;
		currentPtr += lastWriteBytes;
		remainingBytes -= lastWriteBytes;

		sqImageReportProgress(bytesToWrite, wroteBytes);

	} while(bytesToWrite > wroteBytes);

	if(bytesToWrite != wroteBytes){
		logError("Error reading expected to write: %lld actual wrote:%lld", (long long)bytesToWrite, (long long)wroteBytes);
	}

	return bytesToWrite;
}

int basicImageFileExists(const char* aPath){
	struct stat st;

	return stat(aPath, &st) == 0;
}

void basicImageReportProgress(size_t totalSize, size_t currentSize){

	char bar[BARLENGTH + 1];
	bar[BARLENGTH] = 0;

	if(!showOutputInConsole)
		return;

	if(totalSize){
		int percentage = currentSize * 100 / totalSize;

		for(int i = 0; i < BARLENGTH; i++){
			bar[i] = percentage >= ((i+1) * (100/BARLENGTH)) ? '#' : '-';
		}

		printf("\r%s: [%s] %d%%", progressText, bar, percentage);
	}else{
		printf("\r%s...", progressText);
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
