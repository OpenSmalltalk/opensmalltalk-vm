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
  	  Changed Dec 3rd 2001 by John M McIntosh to ignore extents on file names
  	  
 */

#include "libmpeg3.h"
#include "mpeg3protos.h"

#include <stdlib.h>
#include <string.h>

#define MAX(a, b) ((a) > (b) ? (a) : (b))

mpeg3_t* mpeg3_new(char *path,int size)
{
	int i;
	mpeg3_t *file = (mpeg3_t *) memoryAllocate(1, sizeof(mpeg3_t));
	file->cpus = 1;
	file->fs = mpeg3_new_fs(path,size);
	file->have_mmx = mpeg3_mmx_test();
	file->demuxer = mpeg3_new_demuxer(file, 0, 0, -1);
	return file;
}

int mpeg3_delete(mpeg3_t *file)
{
	int i;

	for(i = 0; i < file->total_vstreams; i++)
		mpeg3_delete_vtrack(file, file->vtrack[i]);

	for(i = 0; i < file->total_astreams; i++)
		mpeg3_delete_atrack(file, file->atrack[i]);

	mpeg3_delete_fs(file->fs);
	mpeg3_delete_demuxer(file->demuxer);
	memoryFree(file);
}

int mpeg3_check_sig(char *path)
{
	mpeg3_fs_t *fs;
	unsigned int bits;
	char *ext;
	int result = 0;

	fs = mpeg3_new_fs(path,0);
	if(mpeg3io_open_file(fs))
	{
/* File not found */
		return 0;
	}

	bits = mpeg3io_read_int32(fs);
/* Test header */
	if(bits == MPEG3_TOC_PREFIX || bits == MPEG3_TOC_PREFIXLOWER)
	{
		result = 1;
	}
	else
	if((((bits >> 24) & 0xff) == MPEG3_SYNC_BYTE) ||
		(bits == MPEG3_PACK_START_CODE) ||
		((bits & 0xfff00000) == 0xfff00000) ||
		(bits == MPEG3_SEQUENCE_START_CODE) ||
		(bits == MPEG3_PICTURE_START_CODE) ||
		/*JMM (((bits & 0xffff0000) >> 16) == MPEG3_AC3_START_CODE) || */
		((bits >> 8) == MPEG3_ID3_PREFIX) ||
		(bits == MPEG3_RIFF_CODE))
	{
		result = 1;

		/* JMM Don't want extends, too ugly 
		ext = strrchr(path, '.');
		if(ext)
		{
/* Test file extension. 
			if(strncasecmp(ext, ".mp2", 4) && 
				strncasecmp(ext, ".mp3", 4) &&
				strncasecmp(ext, ".m1v", 4) &&
				strncasecmp(ext, ".m2v", 4) &&
				strncasecmp(ext, ".m2s", 4) &&
				strncasecmp(ext, ".mpg", 4) &&
				strncasecmp(ext, ".vob", 4) &&
				strncasecmp(ext, ".mpeg", 4) /* JMM &&
				strncasecmp(ext, ".ac3", 4) )
				result = 0;
		} */
	}

	mpeg3io_close_file(fs);
	mpeg3_delete_fs(fs);
	return result;
}

mpeg3_t* mpeg3_open_copy(char *path, mpeg3_t *old_file,int size)
{
	mpeg3_t *file = 0;
	unsigned int bits;
	int i, done;

/* Initialize the file structure */
	file = mpeg3_new(path,size);

/* Need to perform authentication before reading a single byte. */
	if(mpeg3io_open_file(file->fs))
	{
		mpeg3_delete(file);
		return 0;
	}

/* =============================== Create the title objects ========================= */
	bits = mpeg3io_read_int32(file->fs);

	if(bits == MPEG3_TOC_PREFIX || bits == MPEG3_TOC_PREFIXLOWER)   /* TOCV */
	{
/* Table of contents for another file */
		if(mpeg3_read_toc(file))
		{
			mpeg3_delete(file);
			return 0;
		}
		mpeg3io_close_file(file->fs);
	}
	else
	if(((bits >> 24) & 0xff) == MPEG3_SYNC_BYTE)
	{
/* Transport stream */
		file->packet_size = MPEG3_TS_PACKET_SIZE;
		file->is_transport_stream = 1;
	}
	else
	if(bits == MPEG3_PACK_START_CODE)
	{
/* Program stream */
		file->packet_size = MPEG3_DVD_PACKET_SIZE;
		file->is_program_stream = 1;
	}
	else
	if((bits & 0xfff00000) == 0xfff00000 ||
		((bits >> 8) == MPEG3_ID3_PREFIX) ||
		(bits == MPEG3_RIFF_CODE))
	{
/* MPEG Audio only */
		file->packet_size = MPEG3_DVD_PACKET_SIZE;
		file->has_audio = 1;
		file->is_audio_stream = 1;
	}
	else
	if(bits == MPEG3_SEQUENCE_START_CODE ||
		bits == MPEG3_PICTURE_START_CODE)
	{
/* Video only */
		file->packet_size = MPEG3_DVD_PACKET_SIZE;
		file->is_video_stream = 1;
	}
	else
	if(((bits & 0xffff0000) >> 16) == MPEG3_AC3_START_CODE)
	{
/* AC3 Audio only */
		file->packet_size = MPEG3_DVD_PACKET_SIZE;
		file->has_audio = 1;
		file->is_audio_stream = 1;
	}
	else
	{
/*  file->packet_size = MPEG3_DVD_PACKET_SIZE; */
/*  file->is_audio_stream = 1; */
		mpeg3_delete(file);
		fprintf(stderr, "mpeg3_open: not an MPEG 2 stream\n");
		return 0;
	}

/* Create title */
/* Copy timecodes from an old demuxer */
	if(old_file && mpeg3_get_demuxer(old_file))
	{
		mpeg3demux_copy_titles(file->demuxer, mpeg3_get_demuxer(old_file));
	}
	else
/* Start from scratch */
	if(!file->demuxer->total_titles)
	{
		mpeg3demux_create_title(file->demuxer, 0, 0);
	}

/* =============================== Get title information ========================= */
	if(file->is_transport_stream || file->is_program_stream)
	{
/* Create video tracks */
/* Video must be created before audio because audio uses the video timecode */
/* to get its length. */
		for(i = 0; i < MPEG3_MAX_STREAMS; i++)
		{
			if(file->demuxer->vstream_table[i])
			{
				file->vtrack[file->total_vstreams] = mpeg3_new_vtrack(file, i, file->demuxer);
				if(file->vtrack[file->total_vstreams]) file->total_vstreams++;
			}
		}

/* Create audio tracks */
		for(i = 0; i < MPEG3_MAX_STREAMS; i++)
		{
			if(file->demuxer->astream_table[i])
			{
				file->atrack[file->total_astreams] = mpeg3_new_atrack(file, 
					i, 
					file->demuxer->astream_table[i], 
					file->demuxer);
				if(file->atrack[file->total_astreams]) file->total_astreams++;
			}
		}
	}
	else
	if(file->is_video_stream)
	{
/* Create video tracks */
		file->vtrack[0] = mpeg3_new_vtrack(file, -1, file->demuxer);
		if(file->vtrack[0]) file->total_vstreams++;
	}
	else
	if(file->is_audio_stream)
	{
/* Create audio tracks */
		file->atrack[0] = mpeg3_new_atrack(file, -1, AUDIO_UNKNOWN, file->demuxer);
		if(file->atrack[0]) file->total_astreams++;
	}

	if(file->total_vstreams) file->has_video = 1;
	if(file->total_astreams) file->has_audio = 1;

	mpeg3io_close_file(file->fs);
	return file;
}

mpeg3_t* mpeg3_open(char *path,int size)
{
	return mpeg3_open_copy(path, 0,size);
}

int mpeg3_close(mpeg3_t *file)
{
/* File is closed in the same procedure it is opened in. */
	mpeg3_delete(file);
	return 0;
}

int mpeg3_set_cpus(mpeg3_t *file, int cpus)
{
	int i;
	file->cpus = cpus;
	for(i = 0; i < file->total_vstreams; i++)
		mpeg3video_set_cpus(file->vtrack[i]->video, cpus);
	return 0;
}

int mpeg3_set_mmx(mpeg3_t *file, int use_mmx)
{
	int i;
	file->have_mmx = use_mmx;
	for(i = 0; i < file->total_vstreams; i++)
		mpeg3video_set_mmx(file->vtrack[i]->video, use_mmx);
	return 0;
}

int mpeg3_generate_toc(FILE *output, char *path, int timecode_search, int print_streams)
{
	mpeg3_t *file = mpeg3_open(path,0);
	mpeg3_demuxer_t *demuxer;
	int i;

	if(file)
	{
		fprintf(output, "TOCVERSION 2\n"
			"PATH: %s\n", path);
		demuxer = mpeg3_new_demuxer(file, 0, 0, -1);
		mpeg3demux_create_title(demuxer, timecode_search, output);
/* Just print the first title's streams */
		if(print_streams) mpeg3demux_print_streams(demuxer, output);

		fprintf(output, "SIZE: %ld\n", demuxer->titles[demuxer->current_title]->total_bytes);
		fprintf(output, "PACKETSIZE: %ld\n", demuxer->packet_size);

		mpeg3demux_print_timecodes(demuxer->titles[demuxer->current_title], output);

		mpeg3_delete_demuxer(demuxer);
		mpeg3_close(file);
		return 0;
	}
	return 1;
}

int mpeg3_read_toc(mpeg3_t *file)
{
	char string[MPEG3_STRLEN];
	int number1;

/* Test version number */
	file->is_program_stream = 1;
	mpeg3io_seek(file->fs, 0);
	
//	fscanf(file->fs->fd, "%s %d", string, &number1);
//  Jan 20th 2006, John M Mcintosh (johnmci@smalltalkconsulting.com  move logic to mpeg3io.c

	mpeg3io_scanf(file->fs,"%s %d",string,&number1);
	if(number1 > 2 || number1 < 2) return 1;

/* Read titles */
	mpeg3demux_read_titles(file->demuxer);
	return 0;
}

int mpeg3_has_audio(mpeg3_t *file)
{
	return file->has_audio;
}

int mpeg3_total_astreams(mpeg3_t *file)
{
	return file->total_astreams;
}

int mpeg3_audio_channels(mpeg3_t *file,
		int stream)
{
	if(file->has_audio)
		return file->atrack[stream]->channels;
	return -1;
}

int mpeg3_sample_rate(mpeg3_t *file,
		int stream)
{
	if(file->has_audio)
		return file->atrack[stream]->sample_rate;
	return -1;
}

long mpeg3_get_sample(mpeg3_t *file,
		int stream)
{
	if(file->has_audio)
		return file->atrack[stream]->current_position;
	return -1;
}

int mpeg3_set_sample(mpeg3_t *file, 
		long sample,
		int stream)
{
	if(file->has_audio)
	{
		file->atrack[stream]->current_position = sample;
		mpeg3audio_seek_sample(file->atrack[stream]->audio, sample);
		return 0;
	}
	return -1;
}

long mpeg3_audio_samples(mpeg3_t *file,
		int stream)
{
	if(file->has_audio)
		return file->atrack[stream]->total_samples;
	return -1;
}

int mpeg3_has_video(mpeg3_t *file)
{
	return file->has_video;
}

int mpeg3_total_vstreams(mpeg3_t *file)
{
	return file->total_vstreams;
}

int mpeg3_video_width(mpeg3_t *file,
		int stream)
{
	if(file->has_video)
		return file->vtrack[stream]->width;
	return -1;
}

int mpeg3_video_height(mpeg3_t *file,
		int stream)
{
	if(file->has_video)
		return file->vtrack[stream]->height;
	return -1;
}

float mpeg3_frame_rate(mpeg3_t *file,
		int stream)
{
	if(file->has_video)
		return file->vtrack[stream]->frame_rate;
	return -1;
}

long mpeg3_video_frames(mpeg3_t *file,
		int stream)
{
	if(file->has_video)
		return file->vtrack[stream]->total_frames;
	return -1;
}

long mpeg3_get_frame(mpeg3_t *file,
		int stream)
{
	if(file->has_video)
		return file->vtrack[stream]->current_position;
	return -1;
}

int mpeg3_set_frame(mpeg3_t *file, 
		long frame,
		int stream)
{
	if(file->has_video)
	{
		file->vtrack[stream]->current_position = frame;
		mpeg3video_seek_frame(file->vtrack[stream]->video, frame);
		return 0;
	}
	return -1;
}

int mpeg3_seek_percentage(mpeg3_t *file, double percentage)
{
	int i;
	for(i = 0; i < file->total_astreams; i++)
	{
		mpeg3audio_seek_percentage(file->atrack[i]->audio, percentage);
	}

	for(i = 0; i < file->total_vstreams; i++)
	{
		mpeg3video_seek_percentage(file->vtrack[i]->video, percentage);
	}
	return 0;
}

int mpeg3_previous_frame(mpeg3_t *file, int stream)
{
	file->last_type_read = 2;
	file->last_stream_read = stream;

	if(file->has_video)
		return mpeg3video_previous_frame(file->vtrack[stream]->video);
}

double mpeg3_tell_percentage(mpeg3_t *file)
{
	double percent = 0;
	if(file->last_type_read == 1)
	{
		percent = mpeg3demux_tell_percentage(file->atrack[file->last_stream_read]->demuxer);
	}

	if(file->last_type_read == 2)
	{
		percent = mpeg3demux_tell_percentage(file->vtrack[file->last_stream_read]->demuxer);
	}
	return percent;
}

double mpeg3_get_time(mpeg3_t *file)
{
	double atime = 0, vtime = 0;

	if(file->is_transport_stream || file->is_program_stream)
	{
/* Timecode only available in transport stream */
		if(file->last_type_read == 1)
		{
			atime = mpeg3demux_get_time(file->atrack[file->last_stream_read]->demuxer);
		}
		else
		if(file->last_type_read == 2)
		{
			vtime = mpeg3demux_get_time(file->vtrack[file->last_stream_read]->demuxer);
		}
	}
	else
	{
/* Use percentage and total time */
		if(file->has_audio)
		{
			atime = mpeg3demux_tell_percentage(file->atrack[0]->demuxer) * 
						mpeg3_audio_samples(file, 0) / mpeg3_sample_rate(file, 0);
		}

		if(file->has_video)
		{
			vtime = mpeg3demux_tell_percentage(file->vtrack[0]->demuxer) *
						mpeg3_video_frames(file, 0) / mpeg3_frame_rate(file, 0);
		}
	}

	return MAX(atime, vtime);
}

int mpeg3_end_of_audio(mpeg3_t *file, int stream)
{
	int result = 0;
	result = mpeg3demux_eof(file->atrack[stream]->demuxer);
	return result;
}

int mpeg3_end_of_video(mpeg3_t *file, int stream)
{
	int result = 0;
	result = mpeg3demux_eof(file->vtrack[stream]->demuxer);
	return result;
}


int mpeg3_read_frame(mpeg3_t *file, 
		unsigned char **output_rows, 
		int in_x, 
		int in_y, 
		int in_w, 
		int in_h, 
		int out_w, 
		int out_h, 
		int color_model,
		int stream)
{
	int result = -1;


	if(file->has_video)
	{
		result = mpeg3video_read_frame(file->vtrack[stream]->video, 
					file->vtrack[stream]->current_position, 
					output_rows,
					in_x, 
					in_y, 
					in_w, 
					in_h, 
					out_w,
					out_h,
					color_model);
		file->last_type_read = 2;
		file->last_stream_read = stream;
		file->vtrack[stream]->current_position++;
	}


	return result;
}

int mpeg3_drop_frames(mpeg3_t *file, long frames, int stream)
{
	int result = -1;

	if(file->has_video)
	{
		result = mpeg3video_drop_frames(file->vtrack[stream]->video, 
						frames);
		if(frames > 0) file->vtrack[stream]->current_position += frames;
		file->last_type_read = 2;
		file->last_stream_read = stream;
	}
	return result;
}

int mpeg3_read_yuvframe(mpeg3_t *file,
		char *y_output,
		char *u_output,
		char *v_output,
		int in_x, 
		int in_y,
		int in_w,
		int in_h,
		int stream)
{
	int result = -1;

//printf("mpeg3_read_yuvframe 1 %d %d\n", mpeg3demux_tell(file->vtrack[stream]->demuxer), mpeg3demuxer_total_bytes(file->vtrack[stream]->demuxer));
	if(file->has_video)
	{
		result = mpeg3video_read_yuvframe(file->vtrack[stream]->video, 
					file->vtrack[stream]->current_position, 
					y_output,
					u_output,
					v_output,
					in_x,
					in_y,
					in_w,
					in_h);
		file->last_type_read = 2;
		file->last_stream_read = stream;
		file->vtrack[stream]->current_position++;
	}
//printf("mpeg3_read_yuvframe 2 %d %d\n", mpeg3demux_tell(file->vtrack[stream]->demuxer), mpeg3demuxer_total_bytes(file->vtrack[stream]->demuxer));
	return result;
}


int mpeg3_read_audio(mpeg3_t *file, 
		float *output_f, 
		short *output_i, 
		int channel, 
		long samples,
		int stream)
{
	int result = -1;

//printf("mpeg3_read_audio 1 %d %d\n", mpeg3demux_tell(file->atrack[stream]->demuxer), mpeg3demuxer_total_bytes(file->atrack[stream]->demuxer));
	if(file->has_audio)
	{
		result = mpeg3audio_decode_audio(file->atrack[stream]->audio, 
					output_f, 
					output_i, 
					channel, 
					file->atrack[stream]->current_position, 
					samples);
		file->last_type_read = 1;
		file->last_stream_read = stream;
		file->atrack[stream]->current_position += samples;
	}
//printf("mpeg3_read_audio 2 %d %d\n", mpeg3demux_tell(file->atrack[stream]->demuxer), mpeg3demuxer_total_bytes(file->atrack[stream]->demuxer));

	return result;
}

int mpeg3_reread_audio(mpeg3_t *file, 
		float *output_f, 
		short *output_i, 
		int channel, 
		long samples,
		int stream)
{
	if(file->has_audio)
	{
		mpeg3_set_sample(file, 
			file->atrack[stream]->current_position - samples,
			stream);
		file->last_type_read = 1;
		file->last_stream_read = stream;
		return mpeg3_read_audio(file, 
			output_f, 
			output_i, 
			channel, 
			samples,
			stream);
	}
	return -1;
}

int mpeg3_read_audio_chunk(mpeg3_t *file, 
		unsigned char *output, 
		long *size, 
		long max_size,
		int stream)
{
	int result = 0;
	if(file->has_audio)
	{
		result = mpeg3audio_read_raw(file->atrack[stream]->audio, output, size, max_size);
		file->last_type_read = 1;
		file->last_stream_read = stream;
	}
	return result;
}

int mpeg3_read_video_chunk(mpeg3_t *file, 
		unsigned char *output, 
		long *size, 
		long max_size,
		int stream)
{
	int result = 0;
	if(file->has_video)
	{
		result = mpeg3video_read_raw(file->vtrack[stream]->video, output, size, max_size);
		file->last_type_read = 2;
		file->last_stream_read = stream;
	}
	return result;
}
