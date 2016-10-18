/*
 * Safe(r) string functions adapted from BSD's strlcpy() and strlcat() functions.
 */

#ifndef SQ_STR_SAFE_H
#define SQ_STR_SAFE_H

#include <sys/types.h>

extern size_t
strSafeCpy(char *dst, const char *src, size_t dsize);

extern size_t
strSafeCat(char *dst, const char *src, size_t dsize);

extern size_t
strSafeCpyLen(char *dst, const char *src, size_t slen, size_t dsize);

#endif
