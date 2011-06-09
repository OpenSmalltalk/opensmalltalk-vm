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
 /*  Changed May 23 by Jason Dufair to handle mp3 files with ID3v2 tags
     (specifically ones with binary data in them)
     - Added mpeg3io_get_id3v2_size
     - modified all fseek's to use the id3v2 offset
	 
	Changed Jan 20th 2006 by John M McIntosh to support reading mpeg file from a buffer
	setvbuf(remember,0, _IOFBF, 64*1024);  //JMM Feb 26th, 2006 for CD reader performance

	
 */
#include "mpeg3private.h"
#include "mpeg3protos.h"

#if defined(__linux__)
#include <mntent.h>
#endif

#if defined( TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
#include <stat.h>
#else
#include <sys/stat.h>
#endif

#include <stdlib.h>
#include <string.h>

mpeg3_fs_t* mpeg3_new_fs(char *path,int size)
{
	mpeg3_fs_t *fs = (mpeg3_fs_t *) memoryAllocate(1, sizeof(mpeg3_fs_t));
	fs->css = mpeg3_new_css();
	if (size) {
		fs->mpeg_is_in_buffer = (char *) memoryAllocate(1, size);
		fs->mpeg_is_in_buffer_file_position = 0;
		fs->mpeg_buffer_size = size;
		memmove(fs->mpeg_is_in_buffer,path,size);
		fs->path[0] = 0x00;
	} else {
	strcpy(fs->path, path);
		fs->mpeg_is_in_buffer = NULL;
		fs->mpeg_is_in_buffer_file_position = 0;
		fs->mpeg_buffer_size = 0;
	}
	return fs;
}

int mpeg3_delete_fs(mpeg3_fs_t *fs)
{
	mpeg3_delete_css(fs->css);
	if (fs->mpeg_is_in_buffer)
		memoryFree(fs->mpeg_is_in_buffer);
	fs->mpeg_is_in_buffer = NULL;
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
	if (fs->mpeg_is_in_buffer) {
		fs->total_bytes = fs->mpeg_buffer_size - fs->id3v2_offset;
		fs->mpeg_is_in_buffer_file_position = fs->id3v2_offset;
		return fs->total_bytes;
	}

	if (! fs->fd) {	// bgf error protection for win
		return 0;
	}

	fseek(fs->fd, 0, SEEK_END);
	fs->total_bytes = ftell(fs->fd) - fs->id3v2_offset;
	fseek(fs->fd, fs->id3v2_offset, SEEK_SET);

	return fs->total_bytes;
}

int mpeg3io_get_id3v2_size(mpeg3_fs_t *fs)
{
  unsigned long synchsafe_size = 0;

  if (fs->mpeg_is_in_buffer) {
	fs->mpeg_is_in_buffer_file_position = 6;
  } else {
	if (! fs->fd) return 0;
	fseek(fs->fd, 6, SEEK_SET);
  }

  synchsafe_size = mpeg3io_read_int32(fs);

  return ((synchsafe_size & 0xff) | (synchsafe_size & 0xff00) >> 1 | (synchsafe_size & 0xff0000) >> 2 | (synchsafe_size & 0xff000000) >> 3) + 10;
}

int mpeg3io_open_file(mpeg3_fs_t *fs)
{
        unsigned int bits;

  if (!fs->mpeg_is_in_buffer) {
/* Need to perform authentication before reading a single byte. */
	mpeg3_get_keys(fs->css, fs->path);
	if(!(fs->fd = fopen(fs->path, "rb")))
	{
		perror("mpeg3io_open_file");
		return 1;
	}
	setvbuf(fs->fd,0, _IOFBF, 64*1024);  //JMM Feb 26th, 2006 for CD reader performance
	}

	bits = mpeg3io_read_int32(fs);

	if ((bits >> 8) == MPEG3_ID3_PREFIX)
	  {
	    fs->id3v2_offset = mpeg3io_get_id3v2_size(fs);
	  } else {
	    fs->id3v2_offset = 0;
	  }

	fs->total_bytes = mpeg3io_get_total_bytes(fs);
	
	if(!fs->total_bytes)
	{
		if (!fs->mpeg_is_in_buffer) {
			if (fs->fd) fclose(fs->fd);
		}
		fprintf(stderr, "MP2 - empty file %s\n", fs->path);
		fs->fd = NULL;
		return 1;
	}
	fs->current_byte = 0;
	return 0;
}

int mpeg3io_close_file(mpeg3_fs_t *fs)
{
	if (!fs->mpeg_is_in_buffer)
	if(fs->fd) fclose(fs->fd);
	else {
		if (fs->mpeg_is_in_buffer)
			memoryFree(fs->mpeg_is_in_buffer);
		fs->mpeg_is_in_buffer = 0; 
	}
	/* fprintf (stderr, "MP2 closing %s\n", fs->path); */
	fs->fd = 0;
	return 0;
}

int mpeg3io_read_data(unsigned char *buffer, long bytes, mpeg3_fs_t *fs)
{
	int result = 0;
	if (fs->mpeg_is_in_buffer) {
		int normalizedBytes;
		normalizedBytes = fs->mpeg_is_in_buffer_file_position + bytes;
		if (normalizedBytes > fs->mpeg_buffer_size) {
			normalizedBytes = fs->mpeg_buffer_size - fs->mpeg_is_in_buffer_file_position;
		}
		else 
			normalizedBytes = bytes;
		memmove(buffer,fs->mpeg_is_in_buffer+fs->mpeg_is_in_buffer_file_position,normalizedBytes);
		fs->mpeg_is_in_buffer_file_position += normalizedBytes;
		result = !normalizedBytes;
	} else {
		result = (fs->fd != NULL) && !fread(buffer, 1, bytes, fs->fd);
	}
	fs->current_byte += bytes;
	return (result && bytes);
}

int mpeg3io_device(char *path, char *device)
{
	struct stat file_st, device_st;
#if defined(__linux__)
	struct mntent *mnt;
#endif
	FILE *fp;

	if(stat(path, &file_st) < 0)
	{
		perror("mpeg3io_device");
		return 1;
	}

#if defined(__linux__)
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
	if (fs->mpeg_is_in_buffer) {
		int target;
		
		target = byte + fs->id3v2_offset;
		if (target > fs->mpeg_buffer_size) 
				return -1;
		if (target < 0) 
				return -1;
		fs->mpeg_is_in_buffer_file_position = target;
		return 0;
	}
	// For Squeak-Teleplace, where we only deal in static mpeg files.
	// No seek beyond the EOF.  Partly to protect against win32 seek woes.
	if (byte < 0) {
		return -1;
	} else if (fs->total_bytes && (byte > fs->total_bytes)) {
		/* fprintf(stderr, "libmpeg3 seek out of range %ld vs %ld\n", byte, fs->total_bytes); */
		return -1;
	} else {
		if (fs->fd) {
			return fseek(fs->fd, (byte + fs->id3v2_offset), SEEK_SET);
		}
		fprintf(stderr, "MP2: seek no fd\n");
		return -1;
	}
}

int mpeg3io_seek_relative(mpeg3_fs_t *fs, long bytes)
{
	long old_current_byte = fs->current_byte;
	fs->current_byte += bytes;
	if (fs->mpeg_is_in_buffer) {
		long target = fs->current_byte + fs->id3v2_offset;
		if (target > fs->mpeg_buffer_size)
			return -1;
		if (target < 0) {
			return -1;		}
		fs->mpeg_is_in_buffer_file_position = target;
		return 0;
	}
	if (fs->current_byte < 0) {
		return -1;
	} else if (fs->total_bytes && (fs->current_byte > fs->total_bytes)) {
		/*  For Squeak-Teleplace, where we only deal in static mpeg files. */
		/*  No seek beyond the EOF.  Partly to protect against win32 seek woes. */
		return -1;
	}

	if (fs->fd) {
		return fseek(fs->fd, fs->current_byte + fs->id3v2_offset, SEEK_SET);
	} 
	fprintf(stderr, "MP2: rel seek no fd\n");
	return -1;
}

int mpeg3io_scanf (mpeg3_fs_t *fs,char *format, void * string1, void * string2) {
	int return_value;
	if (fs->mpeg_is_in_buffer) {
		return_value = sscanf(fs->mpeg_is_in_buffer+fs->mpeg_is_in_buffer_file_position,format, string1, string2);
		return return_value;
	}
	if (! fs->fd) {
		fprintf(stderr, "MP2 scan3 - no file\n");
		return -1;
	}
	return_value = fscanf(fs->fd,format, string1, string2);
	return return_value;
}

int mpeg3io_scanf5 (mpeg3_fs_t *fs,char *format, void * string1, void * string2, void * string3, void * string4, void * string5) {
	int return_value;
	
	if (fs->mpeg_is_in_buffer) {
		return_value = sscanf(fs->mpeg_is_in_buffer+fs->mpeg_is_in_buffer_file_position,format, string1, string2, string3, string4, string5);
		return return_value;
	}
	if (! fs->fd) {
		fprintf(stderr, "MP2 scan5 - no file\n");
		return -1;
	}
	return_value = fscanf(fs->fd,format, string1, string2, string3, string4, string5);
	return return_value;
}

int mpeg3io_end_of_file(mpeg3_fs_t *fs ) {
	if (fs->mpeg_is_in_buffer) {
		return fs->mpeg_is_in_buffer_file_position == fs->mpeg_buffer_size;
	}
	
	return ( ! fs->fd ) || feof(fs->fd);
}

inline int mpeg3io_fgetc(mpeg3_fs_t *fs) {
	if (fs->mpeg_is_in_buffer) {
		unsigned int value;
		fs->mpeg_is_in_buffer_file_position++;
		if (fs->mpeg_is_in_buffer_file_position >= fs->mpeg_buffer_size) {
			fs->mpeg_is_in_buffer_file_position = fs->mpeg_buffer_size;
			return 0;
		}
		value = (unsigned int) fs->mpeg_is_in_buffer[fs->mpeg_is_in_buffer_file_position-1];
		return value;
	}
	return (fs->fd ? fgetc(fs->fd) : 0);
}

