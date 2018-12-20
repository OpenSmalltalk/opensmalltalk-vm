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
#include "mpeg3video.h"
#include <stdlib.h>
#include <string.h>

unsigned int mpeg3bits_next_startcode(mpeg3_bits_t* stream)
{
/* Perform forwards search */
	mpeg3bits_byte_align(stream);

/* Perform search */
	while((mpeg3bits_showbits32_noptr(stream) >> 8) != MPEG3_PACKET_START_CODE_PREFIX && 
		!mpeg3bits_eof(stream))
	{
		mpeg3bits_getbyte_noptr(stream);
	}
	return mpeg3bits_showbits32_noptr(stream);
}

/* Line up on the beginning of the next code. */
int mpeg3video_next_code(mpeg3_bits_t* stream, unsigned int code)
{
	while(!mpeg3bits_eof(stream) && 
		mpeg3bits_showbits32_noptr(stream) != code)
	{
		mpeg3bits_getbyte_noptr(stream);
	}
	return mpeg3bits_eof(stream);
}

/* Line up on the beginning of the previous code. */
int mpeg3video_prev_code(mpeg3_bits_t* stream, unsigned int code)
{
	while(!mpeg3bits_bof(stream) && 
		mpeg3bits_showbits_reverse(stream, 32) != code)
	{
		mpeg3bits_getbits_reverse(stream, 8);
	}
	return mpeg3bits_bof(stream);
}

long mpeg3video_goptimecode_to_frame(mpeg3video_t *video)
{
/*  printf("mpeg3video_goptimecode_to_frame %d %d %d %d %f\n",  */
/*  	video->gop_timecode.hour, video->gop_timecode.minute, video->gop_timecode.second, video->gop_timecode.frame, video->frame_rate); */
	return (long)(video->gop_timecode.hour * 3600 * video->frame_rate + 
		video->gop_timecode.minute * 60 * video->frame_rate +
		video->gop_timecode.second * video->frame_rate +
		video->gop_timecode.frame) - 1 - video->first_frame;
}

int mpeg3video_match_refframes(mpeg3video_t *video)
{
	unsigned char *dst, *src;
	int i, j, size;

	for(i = 0; i < 3; i++)
	{
		if(video->newframe[i])
		{
			if(video->newframe[i] == video->refframe[i])
			{
				src = video->refframe[i];
				dst = video->oldrefframe[i];
			}
			else
			{
				src = video->oldrefframe[i];
				dst = video->refframe[i];
			}

    		if(i == 0)
				size = video->coded_picture_width * video->coded_picture_height + 32 * video->coded_picture_width;
    		else 
				size = video->chrom_width * video->chrom_height + 32 * video->chrom_width;

			memcpy(dst, src, size);
		}
	}
	return 0;
}

int mpeg3video_seek(mpeg3video_t *video)
{
	long this_gop_start;
	int result = 0;
	int back_step;
	int attempts;
	mpeg3_t *file = (mpeg3_t *) video->file;
	mpeg3_bits_t *vstream = video->vstream;
	double percentage;
	long frame_number;
	int match_refframes = 1;

/* Seek to a percentage */
	if(video->percentage_seek >= 0)
	{
		percentage = video->percentage_seek;
		video->percentage_seek = -1;
		mpeg3bits_seek_percentage(vstream, percentage);
// Go to previous I-frame
		mpeg3bits_start_reverse(vstream);
		result = mpeg3video_prev_code(vstream, MPEG3_GOP_START_CODE);
		if(!result) mpeg3bits_getbits_reverse(vstream, 32);
		mpeg3bits_start_forward(vstream);

		if(mpeg3bits_tell_percentage(vstream) < 0) mpeg3bits_seek_percentage(vstream, 0);

// Read up to the correct percentage
		result = 0;
		while(!result && mpeg3bits_tell_percentage(vstream) < percentage)
		{
			result = mpeg3video_read_frame_backend(video, 0);
			if(match_refframes)
				mpeg3video_match_refframes(video);
			match_refframes = 0;
		}
	}
	else
/* Seek to a frame */
	if(video->frame_seek >= 0)
	{
		frame_number = video->frame_seek;
		video->frame_seek = -1;
		if(frame_number < 0) frame_number = 0;
		if(frame_number > video->maxframe) frame_number = video->maxframe;

/* Seek to start of file */
		if(frame_number < 16)
		{
			video->repeat_count = video->current_repeat = 0;
			mpeg3bits_seek_start(vstream);
			video->framenum = 0;
			result = mpeg3video_drop_frames(video, frame_number - video->framenum);
		}
		else
		{
/* Seek to an I frame. */
			if((frame_number < video->framenum || frame_number - video->framenum > MPEG3_SEEK_THRESHOLD))
			{
/* Elementary stream */
				if(file->is_video_stream)
				{
					mpeg3_t *file = (mpeg3_t *) video->file;
					mpeg3_vtrack_t *track = (mpeg3_vtrack_t *) video->track;
					long byte = (long)((float)(mpeg3demuxer_total_bytes(vstream->demuxer) / 
						track->total_frames) * 
						frame_number);
					long minimum = 65535;
					int done = 0;

//printf("seek elementary %d\n", frame_number);
/* Get GOP just before frame */
					do
					{
						result = mpeg3bits_seek_byte(vstream, byte);
						mpeg3bits_start_reverse(vstream);
						if(!result) result = mpeg3video_prev_code(vstream, MPEG3_GOP_START_CODE);
						mpeg3bits_start_forward(vstream);
						mpeg3bits_getbits(vstream, 8);
						if(!result) result = mpeg3video_getgophdr(video);
						this_gop_start = mpeg3video_goptimecode_to_frame(video);

//printf("wanted %ld guessed %ld byte %ld result %d\n", frame_number, this_gop_start, byte, result);
						if(labs(this_gop_start - frame_number) >= labs(minimum)) 
							done = 1;
						else
						{
							minimum = this_gop_start - frame_number;
							byte += (long)((float)(frame_number - this_gop_start) * 
								(float)(mpeg3demuxer_total_bytes(vstream->demuxer) / 
								track->total_frames));
							if(byte < 0) byte = 0;
						}
					}while(!result && !done);

//printf("wanted %d guessed %d\n", frame_number, this_gop_start);
					if(!result)
					{
						video->framenum = this_gop_start;
						result = mpeg3video_drop_frames(video, frame_number - video->framenum);
					}
				}
				else
/* System stream */
				{
					mpeg3bits_seek_time(vstream, (double)frame_number / video->frame_rate);
					percentage = mpeg3bits_tell_percentage(vstream);
//printf("seek frame %ld percentage %f byte %ld\n", frame_number, percentage, mpeg3bits_tell(vstream));
					mpeg3bits_start_reverse(vstream);
					mpeg3video_prev_code(vstream, MPEG3_GOP_START_CODE);
					mpeg3bits_getbits_reverse(vstream, 32);
					mpeg3bits_start_forward(vstream);
//printf("seek system 1 %f\n", (double)frame_number / video->frame_rate);

					while(!result && mpeg3bits_tell_percentage(vstream) < percentage)
					{
						result = mpeg3video_read_frame_backend(video, 0);
						if(match_refframes)
							mpeg3video_match_refframes(video);

//printf("seek system 2 %f %f\n", mpeg3bits_tell_percentage(vstream) / percentage);
						match_refframes = 0;
					}
//printf("seek system 3 %f\n", (double)frame_number / video->frame_rate);
				}

				video->framenum = frame_number;
			}
			else
// Drop frames
			{
				mpeg3video_drop_frames(video, frame_number - video->framenum);
			}
		}
	}

	return result;
}

int mpeg3video_drop_frames(mpeg3video_t *video, long frames)
{
	int result = 0;
	long frame_number = video->framenum + frames;

/* Read the selected number of frames and skip b-frames */
	while(!result && frame_number > video->framenum)
	{
		result = mpeg3video_read_frame_backend(video, frame_number - video->framenum);
	}
	return result;
}
