/*
	mman.c - portable mmap/munmap function for skyeye on Win32
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

#include <windows.h>
#include "portable/mman.h"


int getpagesize(void)
{
	return 1024;
}


void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset)
{
	HANDLE handle, file;
	DWORD nRead = 0;
	void *retVal = NULL;

	if ((flags & (MAP_FIXED | MAP_SHARED)) ||
	    ((prot & PROT_WRITE) && fd != -1) ||
	    !(fd == -1 || (file = (HANDLE)_get_osfhandle(fd)) != INVALID_HANDLE_VALUE) ||
	    length == 0) return MAP_FAILED;

	if ((handle = CreateFileMapping(INVALID_HANDLE_VALUE, NULL,
					PAGE_READWRITE,
					0, (DWORD)length,
					NULL)) == NULL) return MAP_FAILED;

	if ((retVal = MapViewOfFile(handle, FILE_MAP_ALL_ACCESS, 0, 0, 0)) == NULL) goto exit;

	if (fd != -1) {
		if (SetFilePointer(file, (DWORD)offset,
				   NULL, FILE_BEGIN) == INVALID_SET_FILE_POINTER) goto err;
		if (ReadFile(file, retVal, (DWORD)length, &nRead, NULL) == 0) goto err;
	}

	goto exit;

err:
	UnmapViewOfFile(retVal);
	retVal = NULL;

exit:
	CloseHandle(handle);
	return (retVal == NULL ? MAP_FAILED : retVal);
}


int munmap(void *addr, size_t length)
{
	if (addr == NULL || addr == MAP_FAILED) return -1;

	return (UnmapViewOfFile(addr) == 0 ? -1 : 0);
}

