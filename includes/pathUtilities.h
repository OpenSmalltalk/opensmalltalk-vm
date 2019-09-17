#ifndef PHAROVM_PATH_UTITILITIES_H
#define PHAROVM_PATH_UTITILITIES_H

#pragma once

#include <stddef.h>
#include <stdbool.h>
#include "errorCodes.h"

pharovm_error_code_t pharovm_path_getCurrentWorkingDirInto(char *target, size_t targetSize);

pharovm_error_code_t pharovm_path_makeAbsoluteInto(char *target, size_t targetSize, const char *src);
pharovm_error_code_t pharovm_path_extractDirnameInto(char *target, size_t targetSize, const char *src);
pharovm_error_code_t pharovm_path_extractBaseNameInto(char *target, size_t targetSize, const char *src);
pharovm_error_code_t pharovm_path_joinInto(char *target, size_t targetSize, const char *first, const char *second);
bool pharovm_path_isAbsolutePath(const char *path);

size_t pharovm_path_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize);

#endif //PHAROVM_PATH_UTITILITIES_H
