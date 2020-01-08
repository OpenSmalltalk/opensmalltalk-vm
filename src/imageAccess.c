#include "pharovm/pharo.h"
#include <stdio.h>

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

FileAccessHandler defaultFileAccessHandler = {
		basicImageFileClose,
		basicImageFileOpen,
		basicImageFilePosition,
		basicImageFileRead,
		basicImageFileSeek,
		basicImageFileSeekEnd,
		basicImageFileWrite
};

FileAccessHandler* fileAccessHandler = &defaultFileAccessHandler;

FileAccessHandler* currentFileAccessHandler(){
	return fileAccessHandler;
}

void setFileAccessHandler(FileAccessHandler* aFileAccessHandler){
	fileAccessHandler = aFileAccessHandler;
}
