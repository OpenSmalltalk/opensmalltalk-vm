/* 
 *
 *  This file is part of libmpeg3
 *	
 * LibMPEG3
 * Author: Adam Williams <broadcast@earthling.net>
 * Page: heroine.linuxbox.com
 * Page: http://www.smalltalkconsulting.com/html/mpeg3source.html (for Squeak)
 *
    LibMPEG3 was originally licenced under GPL. It was relicensed by
    the author under the LGPL and the Squeak license on Nov 1st, 2000
    
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
    
    Also licensed under the Squeak license.
    http://www.squeak.org/license.html
 */
 
 /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */
#include "mpeg3private.h"
#include "mpeg3protos.h"

#if !(defined(TARGET_OS_MAC) || defined(WIN32))
#include <mntent.h>
#endif

#if defined( TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
#include <stat.h>
#else
#include <sys/stat.h>
#endif

#include <stdlib.h>
#include <string.h>

mpeg3_fs_t* mpeg3_new_fs(char *path)
{
	mpeg3_fs_t *fs = (mpeg3_fs_t *) memoryAllocate(1, sizeof(mpeg3_fs_t));
	fs->css = mpeg3_new_css();
	strcpy(fs->path, path);
	return fs;
}

int mpeg3_delete_fs(mpeg3_fs_t *fs)
{
	mpeg3_delete_css(fs->css);
	memoryFree(fs);
	return 0;
}

int mpeg3_copy_fs(mpeg3_fs_t *dst, mpeg3_fs_t *src)
{
	strcpy(dst->path, src->path);
	dst->current_byte = 0;
	return 0;
}

long mpeg3io_get_total_bytes(mpeg3_fs_t *fs)
{
/*
 * 	struct stat st;
 * 	if(stat(fs->path, &st) < 0) return 0;
 * 	return (long)st.st_size;
 */

	fseek(fs->fd, 0, SEEK_END);
	fs->total_bytes = ftell(fs->fd);
	fseek(fs->fd, 0, SEEK_SET);
	return fs->total_bytes;
}

int mpeg3io_open_file(mpeg3_fs_t *fs)
{
/* Need to perform authentication before reading a single byte. */
	mpeg3_get_keys(fs->css, fs->path);

	if(!(fs->fd = fopen(fs->path, "rb")))
	{
		perror("mpeg3io_open_file");
		return 1;
	}

	fs->total_bytes = mpeg3io_get_total_bytes(fs);
	
	if(!fs->total_bytes)
	{
		fclose(fs->fd);
		return 1;
	}
	fs->current_byte = 0;
	return 0;
}

int mpeg3io_close_file(mpeg3_fs_t *fs)
{
	if(fs->fd) fclose(fs->fd);
	fs->fd = 0;
	return 0;
}

int mpeg3io_read_data(unsigned char *buffer, long bytes, mpeg3_fs_t *fs)
{
	int result = 0;
	result = !fread(buffer, 1, bytes, fs->fd);
	fs->current_byte += bytes;
	return (result && bytes);
}

int mpeg3io_device(char *path, char *device)
{
	struct stat file_st, device_st;
    struct mntent *mnt;
	FILE *fp;

	if(stat(path, &file_st) < 0)
	{
		perror("mpeg3io_device");
		return 1;
	}

#if !(defined(WIN32) || defined(TARGET_OS_MAC))
    fp = setmntent(MOUNTED, "r");
    while(fp && (mnt = getmntent(fp)))
	{
		if(stat(mnt->mnt_fsname, &device_st) < 0) continue;
		if(device_st.st_rdev == file_st.st_dev)
		{
			strncpy(device, mnt->mnt_fsname, MPEG3_STRLEN);
			break;
		}
	}
	endmntent(fp); 
#endif

	return 0;
}

int mpeg3io_seek(mpeg3_fs_t *fs, long byte)
{
	fs->current_byte = byte;
	return fseek(fs->fd, byte, SEEK_SET);
}

int mpeg3io_seek_relative(mpeg3_fs_t *fs, long bytes)
{
	fs->current_byte += bytes;
	return fseek(fs->fd, fs->current_byte, SEEK_SET);
}

