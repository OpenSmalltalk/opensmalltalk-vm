#ifndef PHAROVM_PATH_UTITILITIES_H
#define PHAROVM_PATH_UTITILITIES_H

#pragma once

#include <stddef.h>
#include <stdbool.h>
#include "errorCodes.h"

#include "pharo.h" // For EXPORT FIXME: it should be possible to avoid including all of that.

EXPORT(pharovm_error_code_t) pharovm_path_getCurrentWorkingDirInto(char *target, size_t targetSize);

EXPORT(pharovm_error_code_t) pharovm_path_makeAbsoluteInto(char *target, size_t targetSize, const char *src);
EXPORT(pharovm_error_code_t) pharovm_path_extractDirnameInto(char *target, size_t targetSize, const char *src);
EXPORT(pharovm_error_code_t) pharovm_path_extractBaseNameInto(char *target, size_t targetSize, const char *src);
EXPORT(pharovm_error_code_t) pharovm_path_joinInto(char *target, size_t targetSize, const char *first, const char *second);
EXPORT(bool) pharovm_path_isAbsolutePath(const char *path);

EXPORT(size_t) pharovm_path_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize);

#endif //PHAROVM_PATH_UTITILITIES_H
