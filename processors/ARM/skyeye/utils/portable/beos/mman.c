/*
	mman.c - portable mmap/munmap function for skyeye on BeOS
	Copyright (C) 2007 Anthony Lee <don.anthony.lee+program@gmail.com>

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
 * 04/12/2007   Written by Anthony Lee
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <kernel/OS.h>
#include "portable/mman.h"


int getpagesize(void)
{
	return B_PAGE_SIZE;
}


void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)
{
	area_id area;
	struct stat stat;
	ssize_t nBytes = 0, nRead;
	void *retVal = NULL;

	if ((flags & (MAP_FIXED | MAP_SHARED)) ||
	    ((prot & PROT_WRITE) && fd != -1) ||
	    length == 0) return MAP_FAILED;

	length = (length + (B_PAGE_SIZE - 1)) & ~(B_PAGE_SIZE - 1);

	if ((area = create_area("none", &retVal, B_ANY_ADDRESS,
				length, B_NO_LOCK,
				B_READ_AREA | B_WRITE_AREA)) < 0) return MAP_FAILED;

	if (fd != -1) {
		if (fstat(fd, &stat) != 0 ||
		    offset >= stat.st_size ||
		    lseek(fd, offset, SEEK_SET) == (off_t)-1) goto err;

		while (nBytes < (ssize_t)length) {
			offset = lseek(fd, 0, SEEK_CUR);
			if (offset == (off_t)-1 || offset >= stat.st_size) break;

			nRead = read(fd, (void*)((char*)retVal + nBytes), length);
			if (nRead == -1) {
				nBytes = -1;
				break;
			} else {
				nBytes += nRead;
			}
		}

		if (nBytes == -1) goto err;
	}

	goto exit;

err:
	delete_area(area);
	retVal = NULL;

exit:
	return (retVal == NULL ? MAP_FAILED : retVal);
}


int munmap(void *addr, size_t length)
{
	area_id area;

	if (addr == NULL || addr == MAP_FAILED) return -1;
	if ((area = area_for(addr)) < 0) return -1;

	return (delete_area(area) != B_OK ? -1 : 0);
}

