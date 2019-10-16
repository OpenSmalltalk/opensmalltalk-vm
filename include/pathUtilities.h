#ifndef PHAROVM_PATH_UTITILITIES_H
#define PHAROVM_PATH_UTITILITIES_H

#pragma once

#include <stddef.h>
#include <stdbool.h>
#include "errorCode.h"


EXPORT(VMErrorCode) vm_path_get_current_working_dir_into(char *target, size_t targetSize);

EXPORT(VMErrorCode) vm_path_make_absolute_into(char *target, size_t targetSize, const char *src);
EXPORT(VMErrorCode) vm_path_extract_dirname_into(char *target, size_t targetSize, const char *src);
EXPORT(VMErrorCode) vm_path_extract_basename_into(char *target, size_t targetSize, const char *src);
EXPORT(VMErrorCode) vm_path_join_into(char *target, size_t targetSize, const char *first, const char *second);
EXPORT(bool) vm_path_is_absolute_path(const char *path);

EXPORT(size_t) vm_path_find_files_with_extension_in_folder(const char *searchPath, const char *extension, char *imagePathBuffer, size_t imagePathBufferSize);

#endif //PHAROVM_PATH_UTITILITIES_H
