#ifndef PHAROVM_STRING_UTILITIES_H
#define PHAROVM_STRING_UTILITIES_H

#pragma once

#include "errorCode.h"

/**
 * Function for appending string into a buffer. This like strncat, but the size
 * refers to the buffer size instead of the number of elements to copy. Characters
 * that do not fit in the target buffer are truncated.
 */
EXPORT(void) vm_string_append_into(char *dest, const char *source, size_t destBufferSize);


#endif //PHAROVM_STRING_UTILITIES_H
