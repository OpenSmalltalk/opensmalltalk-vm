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
#include "libmpeg3.h"
#include "mpeg3protos.h"

#include <stdlib.h>

mpeg3_vtrack_t* mpeg3_new_vtrack(mpeg3_t *file, int stream_id, mpeg3_demuxer_t *demuxer)
{
	int result = 0;
	mpeg3_vtrack_t *new_vtrack;
	new_vtrack = (mpeg3_vtrack_t *) memoryAllocate(1, sizeof(mpeg3_vtrack_t));
	new_vtrack->demuxer = mpeg3_new_demuxer(file, 0, 1, stream_id);
	if(demuxer) mpeg3demux_copy_titles(new_vtrack->demuxer, demuxer);
	new_vtrack->current_position = 0;

/* Get information about the track here. */
	new_vtrack->video = mpeg3video_new(file, new_vtrack);
	if(!new_vtrack->video)
	{
/* Failed */
		mpeg3_delete_vtrack(file, new_vtrack);
		new_vtrack = 0;
	}
	return new_vtrack;
}

int mpeg3_delete_vtrack(mpeg3_t *file, mpeg3_vtrack_t *vtrack)
{
	if(vtrack->video)
		mpeg3video_delete(vtrack->video);
	if(vtrack->demuxer)
		mpeg3_delete_demuxer(vtrack->demuxer);
	memoryFree(vtrack);
}
