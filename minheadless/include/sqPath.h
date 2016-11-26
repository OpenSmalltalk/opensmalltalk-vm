#ifndef SQ_PATH_H
#define SQ_PATH_H

#include <stdlib.h>

void sqGetCurrentWorkingDir(char *target, size_t targetSize);

void sqPathMakeAbsolute(char *target, size_t targetSize, const char *src);
void sqPathExtractDirname(char *target, size_t targetSize, const char *src);
void sqPathExtractBaseName(char *target, size_t targetSize, const char *src);
void sqPathJoin(char *target, size_t targetSize, const char *first, const char *second);
int sqIsAbsolutePath(const char *path);

#endif /* SQ_PATH_H */
