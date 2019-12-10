#ifndef PHAROVM_STRING_UTILITIES_H
#define PHAROVM_STRING_UTILITIES_H

#pragma once

#include "errorCode.h"
#include <stdint.h>

/**
 * Function for appending string into a buffer. This like strncat, but the size
 * refers to the buffer size instead of the number of elements to copy. Characters
 * that do not fit in the target buffer are truncated.
 */
EXPORT(void) vm_string_append_into(char *dest, const char *source, size_t destBufferSize);

/**
 * This concatenates two different strings into a newly allocated string.
 * The result must be freed with free
 */
EXPORT(char*) vm_string_concat(const char *first, const char *second);

#ifdef _WIN32
/**
 * On Windows we need to convert between UTF-8 and UTF-16 for calling different
 * different native APIs.
 */

/**
 * Converts an utf-8 string into an utf-16 string. This is typically used for calling win32 APIs
 * The result must be freed with free.
 */
EXPORT(uint16_t*) vm_string_convert_utf8_to_utf16(const char *utf8String);

/**
 * Converts an utf-8 string into an utf-16 string. This is typically used for calling win32 APIs
 * The result must be freed with free.
 */
EXPORT(char*) vm_string_convert_utf16_to_utf8(const uint16_t *utf16String);

#endif

#endif //PHAROVM_STRING_UTILITIES_H
