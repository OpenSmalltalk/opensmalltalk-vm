/*
	mman.c - portable mmap/munmap function for skyeye
	Copyright (C) 2007 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.gro.clinux.org>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
*/

/*
 * 01/30/2007   initial version by Anthony Lee
 */

#include "mman.h"

#define SKYEYE_MMAP_USE_MALLOC	0

#ifndef HAVE_MMAP_AND_MUNMAP

#ifdef __BEOS__
#include "./beos/mman.c"
#endif /* __BEOS__ */

#ifdef __MINGW32__
#include "./win32/mman.c"
#endif /* __MINGW32__ */

#if SKYEYE_MMAP_USE_MALLOC

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>


int getpagesize(void)
{
	return 1;
}


void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)
{
	if (flags == MAP_ANONYMOUS && length > 0) {
		void *retVal = malloc(length);
		if(retVal != NULL) return retVal;

	} else if (flags == MAP_PRIVATE && prot == PROT_READ && fd != -1 && length > 0) {
		ssize_t nBytes = 0;
		void *retVal = malloc(length);

		if (retVal != NULL) {
			if (lseek(fd, offset, SEEK_SET) != (off_t)-1) {
				while (nBytes < length && eof(fd) == 0) {
					ssize_t nRead = read(fd, (void*)((char*)retVal + nBytes), length);
					if (nRead == -1) {
						nBytes = -1;
						break;
					} else {
						nBytes += nRead;
					}
				}

				if (nBytes != -1) return retVal;
			}

			free(retVal);
		}
	}

	return MAP_FAILED;
}


int munmap(void *addr, size_t length)
{
	if (addr == NULL || addr == MAP_FAILED) return -1;
	free(addr);
	return 0;
}


#endif /* SKYEYE_MMAP_USE_MALLOC */

#endif
