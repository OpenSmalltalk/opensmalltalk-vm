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

mpeg3_atrack_t* mpeg3_new_atrack(mpeg3_t *file, int stream_id, int format, mpeg3_demuxer_t *demuxer)
{
	mpeg3_atrack_t *new_atrack;

	new_atrack = (mpeg3_atrack_t *) memoryAllocate(1, sizeof(mpeg3_atrack_t));
	new_atrack->channels = 0;
	new_atrack->sample_rate = 0;
	new_atrack->total_samples = 0;
	new_atrack->current_position = 0;
	new_atrack->demuxer = mpeg3_new_demuxer(file, 1, 0, stream_id);
	if(demuxer) mpeg3demux_copy_titles(new_atrack->demuxer, demuxer);
	new_atrack->audio = mpeg3audio_new(file, new_atrack, format);

	if(!new_atrack->audio)
	{
/* Failed */
		mpeg3_delete_atrack(file, new_atrack);
		new_atrack = 0;
	}
	return new_atrack;
}

int mpeg3_delete_atrack(mpeg3_t *file, mpeg3_atrack_t *atrack)
{
	if(atrack->audio)
		mpeg3audio_delete(atrack->audio);
	if(atrack->demuxer)
		mpeg3_delete_demuxer(atrack->demuxer);
	memoryFree(atrack);
}

