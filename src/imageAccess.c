#include "pharovm/pharo.h"
#include <stdio.h>
#include <sys/stat.h>

sqInt basicImageFileClose(sqImageFile f){
	return fclose((FILE*)f);
}

sqImageFile basicImageFileOpen(char* fileName, char *mode){
	return fopen(fileName, mode);
}

long int basicImageFilePosition(sqImageFile f){
	return ftell((FILE*)f);
}

size_t basicImageFileRead(void * ptr, size_t sz, size_t count, sqImageFile f){
	return fread(ptr, sz, count, (FILE*)f);
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

FileAccessHandler defaultFileAccessHandler = {
		basicImageFileClose,
		basicImageFileOpen,
		basicImageFilePosition,
		basicImageFileRead,
		basicImageFileSeek,
		basicImageFileSeekEnd,
		basicImageFileWrite,
		basicImageFileExists
};

FileAccessHandler* fileAccessHandler = &defaultFileAccessHandler;

FileAccessHandler* currentFileAccessHandler(){
	return fileAccessHandler;
}

void setFileAccessHandler(FileAccessHandler* aFileAccessHandler){
	fileAccessHandler = aFileAccessHandler;
}
