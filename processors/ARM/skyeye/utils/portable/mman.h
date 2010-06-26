/*
	mman.h - portable mmap/munmap function for skyeye
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

#ifndef __SKYEYE_PORTABLE_MMAN_H__
#define __SKYEYE_PORTABLE_MMAN_H__

/*
 * The mmap/munmap function just for malloc large memory for skyeye.
 * When you found that the system don't support the mmap/munmap function,
 * please follow the mman.c to see how to write the portable function.
 */

#if !(defined(__MINGW32__) || defined(__BEOS__))

#include <sys/mman.h>
#include <unistd.h>
#define HAVE_MMAP_AND_MUNMAP

#else

#include <sys/types.h>

enum {
	PROT_NONE = 0,
	PROT_EXEC = 1,
	PROT_READ = 2,
	PROT_WRITE = 4,
};

enum {
	MAP_PRIVATE = 0,
	MAP_FIXED = 1,
	MAP_SHARED = 2,
	MAP_ANONYMOUS = 4,
};

#define		MAP_FAILED	((void*)-1)

int		getpagesize(void);
void*		mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
int		munmap(void *addr, size_t length);

#endif

#endif /* __SKYEYE_PORTABLE_MMAN_H__ */
