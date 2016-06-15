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
#include "mpeg3title.h"

#include <stdlib.h>

mpeg3_title_t* mpeg3_new_title(mpeg3_t *file, char *path)
{
	mpeg3_title_t *title = (mpeg3_title_t *) memoryAllocate(1, sizeof(mpeg3_title_t));
	
	if (file->fs->mpeg_buffer_size) {
		title->fs = mpeg3_new_fs(file->fs->mpeg_is_in_buffer,file->fs->mpeg_buffer_size);
	} else {
		title->fs = mpeg3_new_fs(path,0);
	}
	title->file = file;
	return title;
}

int mpeg3_delete_title(mpeg3_title_t *title)
{
	mpeg3_delete_fs(title->fs);
	if(title->timecode_table_size)
	{
		memoryFree(title->timecode_table);
	}
	memoryFree(title);
	return 0;
}


int mpeg3_copy_title(mpeg3_title_t *dst, mpeg3_title_t *src)
{
	int i;

	mpeg3_copy_fs(dst->fs, src->fs);
	dst->total_bytes = src->total_bytes;
	
	if(src->timecode_table_size)
	{
		dst->timecode_table_allocation = src->timecode_table_allocation;
		dst->timecode_table_size = src->timecode_table_size;
		dst->timecode_table = (mpeg3demux_timecode_t *) memoryAllocate(1, sizeof(mpeg3demux_timecode_t) * dst->timecode_table_allocation);

		for(i = 0; i < dst->timecode_table_size; i++)
		{
			dst->timecode_table[i] = src->timecode_table[i];
		}
	}
}

int mpeg3_dump_title(mpeg3_title_t *title)
{
	int i;
	
	for(i = 0; i < title->timecode_table_size; i++)
	{
		printf("%f: %d - %d %f %f %d\n", 
			title->timecode_table[i].absolute_start_time, 
			title->timecode_table[i].start_byte, 
			title->timecode_table[i].end_byte, 
			title->timecode_table[i].start_time, 
			title->timecode_table[i].end_time, 
			title->timecode_table[i].program);
	}
}
