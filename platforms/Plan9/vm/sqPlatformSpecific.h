/*
 * Plan9-specific support for sq.h
 */

#ifndef _SQ_PLATFORM_SPECIFIC_H
#define _SQ_PLATFORM_SPECIFIC_H

#include <stdio.h>

typedef long long squeakFileOffsetType;
typedef unsigned long size_t;
typedef long time_t;
int rename(const char*, const char*);

#define MAXPATHLEN FILENAME_MAX

#define exit(n) do { \
					if (n == 0) threadexitsall(NULL); \
					else { \
					char errmsg[20]; \
					sprint(errmsg, "Exit value: %d", n); \
					threadexitsall(errmsg); \
					} \
				} while (0)

#endif /* _SQ_PLATFORM_SPECIFIC_H */
