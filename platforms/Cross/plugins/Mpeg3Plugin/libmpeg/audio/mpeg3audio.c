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
#include "mpeg3private.h"
#include "mpeg3protos.h"

#include "mpeg3audio.h"
#include "tables.h"

#include <math.h>
#include <stdlib.h>

mpeg3audio_t* mpeg3audio_allocate_struct(mpeg3_t *file, mpeg3_atrack_t *track)
{
	mpeg3audio_t *audio = (mpeg3audio_t *) memoryAllocate(1, sizeof(mpeg3audio_t));
	audio->file = file;
	audio->track = track;
	audio->astream = mpeg3bits_new_stream(file, track->demuxer);
	audio->outscale = 1;
	audio->bsbuf = audio->bsspace[1];
	audio->init = 1;
	audio->bo = 1;
	audio->channels = 1;
	return audio;
}


int mpeg3audio_delete_struct(mpeg3audio_t *audio)
{
	mpeg3bits_delete_stream(audio->astream);
	if(audio->pcm_sample) memoryFree(audio->pcm_sample);
	memoryFree(audio);
	return 0;
}

int mpeg3audio_replace_buffer(mpeg3audio_t *audio, long new_allocation)
{
	long i;

	if(!audio->pcm_sample)
	{
		audio->pcm_sample = (float *) memoryAllocate(1,sizeof(float) * new_allocation * audio->channels);
		audio->pcm_allocated = new_allocation;
	}
	else
	{
		float *new_samples = (float *) memoryAllocate(1,sizeof(float) * new_allocation * audio->channels);
		for(i = 0; i < audio->pcm_allocated * audio->channels; i++)
		{
			new_samples[i] = audio->pcm_sample[i];
		}
		memoryFree(audio->pcm_sample);
		audio->pcm_sample = new_samples;
		audio->pcm_allocated = new_allocation;
	}
	return 0;
}

int mpeg3audio_read_frame(mpeg3audio_t *audio)
{
	int result = 0;
	result = mpeg3audio_read_header(audio);

	if(!result)
	{
		switch(audio->format)
		{
			case AUDIO_AC3:
				//JMM result = mpeg3audio_do_ac3(audio);
				result = -1; //JMM 
				break;	
				
			case AUDIO_MPEG:
				switch(audio->layer)
				{
					case 1:
						break;

					case 2:
						result = mpeg3audio_dolayer2(audio);
						break;

					case 3:
						result = mpeg3audio_dolayer3(audio);
						break;

					default:
						result = 1;
						break;
				}
				break;
			
			case AUDIO_PCM:
				result = mpeg3audio_do_pcm(audio);
				break;
		}
	}

	if(!result)
	{
/* Byte align the stream */
		mpeg3bits_byte_align(audio->astream);
	}
	return result;
}

/* Get the length but also initialize the frame sizes. */
int mpeg3audio_get_length(mpeg3audio_t *audio, mpeg3_atrack_t *track)
{
	long result = 0;
	long framesize1 = 0, total1 = 0;
	long framesize2 = 0, total2 = 0;
	long total_framesize = 0, total_frames = 0;
	long byte_limit = 131072;  /* Total bytes to gather information from */
	long total_bytes = 0;
	long major_framesize;     /* Bigger framesize + header */
	long minor_framesize;     /* Smaller framesize + header */
	long major_total;
	long minor_total;
	mpeg3_t *file = (mpeg3_t *) audio->file;

/* Get the frame sizes */
	mpeg3bits_seek_start(audio->astream);
	audio->pcm_point = 0;
	result = mpeg3audio_read_frame(audio); /* Stores the framesize */
	audio->samples_per_frame = audio->pcm_point / audio->channels;

	switch(audio->format)
	{
		case AUDIO_AC3:
			audio->avg_framesize = audio->framesize;
			break;

		case AUDIO_MPEG:
			framesize1 = audio->framesize;
			total_bytes += audio->framesize;
			total1 = 1;

			while(!result && total_bytes < byte_limit)
			{
				audio->pcm_point = 0;
				result = mpeg3audio_read_frame(audio);
				total_bytes += audio->framesize;
				if(audio->framesize != framesize1)
				{
					framesize2 = audio->framesize;
					total2 = 1;
					break;
				}
				else
				{
					total1++;
				}
			}

			while(!result && total_bytes < byte_limit)
			{
				audio->pcm_point = 0;
				result = mpeg3audio_read_frame(audio);
				total_bytes += audio->framesize;
				if(audio->framesize != framesize2)
				{
					break;
				}
				else
				{
					total2++;
				}
			}

			audio->pcm_point = 0;
			result = mpeg3audio_read_frame(audio);
			if(audio->framesize != framesize1 && audio->framesize != framesize2)
			{
/* Variable bit rate.  Get the average frame size. */
				while(!result && total_bytes < byte_limit)
				{
					audio->pcm_point = 0;
					result = mpeg3audio_read_frame(audio);
					total_bytes += audio->framesize;
					if(!result)
					{
						total_framesize += audio->framesize;
						total_frames++;
					}
				}
				audio->avg_framesize = 4 + (float)(total_framesize + framesize1 + framesize2) / (total_frames + total1 + total2);
			}
			else
			{
				major_framesize = framesize2 > framesize1 ? framesize2 : framesize1;
				major_total = framesize2 > framesize1 ? total2 : total1;
				minor_framesize = framesize2 > framesize1 ? framesize1 : framesize2;
				minor_total = framesize2 > framesize1 ? total1 : total2;
/* Add the headers to the framesizes */
				audio->avg_framesize = 4 + (float)(major_framesize * major_total + minor_framesize * minor_total) / (major_total + minor_total);
			}
			break;

		case AUDIO_PCM:
			break;
	}

/* Estimate the total samples */
	if(file->is_audio_stream)
	{
/* From the raw file */
		result = (long)((float)mpeg3demuxer_total_bytes(audio->astream->demuxer) / audio->avg_framesize * audio->samples_per_frame);
	}
	else
	{
/* Gross approximation from a multiplexed file. */
		result = (long)(mpeg3demux_length(audio->astream->demuxer) * track->sample_rate);
/*		result = (long)((float)mpeg3_video_frames(file, 0) / mpeg3_frame_rate(file, 0) * track->sample_rate); */
/* We would scan the multiplexed packets here for the right timecode if only */
/* they had meaningful timecode. */
	}

	audio->pcm_point = 0;
	mpeg3bits_seek_start(audio->astream);
	mpeg3audio_reset_synths(audio);
	return result;
}

int mpeg3audio_seek(mpeg3audio_t *audio, long position)
{
	int result = 0;
	mpeg3_t *file = (mpeg3_t *) audio->file;
	mpeg3_atrack_t *track = (mpeg3_atrack_t *) audio->track;
	long frame_number;
	long byte_position = 0;
	double time_position;

/* Sample seek wasn't requested */
	if(audio->sample_seek < 0)
	{
		audio->pcm_position = position;
		audio->pcm_size = 0;
		return 0;
	}

/* Can't slide buffer.  Seek instead. */
	if(!file->is_audio_stream)
	{
/* Seek in a multiplexed stream using the multiplexer. */
	   	time_position = (double)position / track->sample_rate;
		result |= mpeg3bits_seek_time(audio->astream, time_position);
	   	audio->pcm_position = mpeg3bits_packet_time(audio->astream) * track->sample_rate;
/*printf("wanted %f got %f\n", time_position, mpeg3bits_packet_time(audio->astream)); */
	}
	else
	{
/* Seek in an elemental stream.  This algorithm achieves sample accuracy on fixed bitrates. */
/* Forget about variable bitrates or program streams. */
		frame_number = position / audio->samples_per_frame;
		byte_position = (long)(audio->avg_framesize * frame_number);
	   	audio->pcm_position = frame_number * audio->samples_per_frame;

		if(byte_position < audio->avg_framesize * 2)
		{
			result |= mpeg3bits_seek_start(audio->astream);
			audio->pcm_position = 0;
		}
		else
		{
			result |= mpeg3bits_seek_byte(audio->astream, byte_position);
		}
	}

/* Arm the backstep buffer for layer 3 if not at the beginning already. */
	if(byte_position >= audio->avg_framesize * 2 && audio->layer == 3 && !result)
	{
		result |= mpeg3audio_prev_header(audio);
		result |= mpeg3audio_read_layer3_frame(audio);
	}

/* Reset the tables. */
	mpeg3audio_reset_synths(audio);
	audio->pcm_size = 0;
	audio->pcm_point = 0;
	return result;
}

/* ================================================================ */
/*                                    ENTRY POINTS */
/* ================================================================ */




mpeg3audio_t* mpeg3audio_new(mpeg3_t *file, mpeg3_atrack_t *track, int format)
{
	mpeg3audio_t *audio = mpeg3audio_allocate_struct(file, track);
	int result = 0;

/* Init tables */
	mpeg3audio_new_decode_tables(audio);
	audio->percentage_seek = -1;
	audio->sample_seek = -1;
	audio->format = format;

/* Determine the format of the stream */
	if(format == AUDIO_UNKNOWN)
	{
		if(((mpeg3bits_showbits(audio->astream, 32) & 0xffff0000) >> 16) == MPEG3_AC3_START_CODE)
			audio->format = AUDIO_AC3;
		else
			audio->format = AUDIO_MPEG;
	}

/* get channel count */
	result = mpeg3audio_read_header(audio);

/* Set up the sample buffer */
	mpeg3audio_replace_buffer(audio, 262144);

/* Copy information to the mpeg struct */
	if(!result)
	{
		track->channels = audio->channels;

		switch(audio->format)
		{
			case AUDIO_AC3:
				//JMM track->sample_rate = mpeg3_ac3_samplerates[audio->sampling_frequency_code];
				break;

			case AUDIO_MPEG:
				track->sample_rate = mpeg3_freqs[audio->sampling_frequency_code];
				break;

			case AUDIO_PCM:
				track->sample_rate = 48000;
				break;
		}

		track->total_samples = mpeg3audio_get_length(audio, track);
		result |= mpeg3bits_seek_start(audio->astream);
	}
	else
	{
		mpeg3audio_delete_struct(audio);
		audio = 0;
	}

	return audio;
}

int mpeg3audio_delete(mpeg3audio_t *audio)
{
	mpeg3audio_delete_struct(audio);
	return 0;
}

int mpeg3audio_seek_percentage(mpeg3audio_t *audio, double percentage)
{
	audio->percentage_seek = percentage;
	return 0;
}

int mpeg3audio_seek_sample(mpeg3audio_t *audio, long sample)
{
	audio->sample_seek = sample;
	return 0;
}

/* Read raw frames for concatenation purposes */
int mpeg3audio_read_raw(mpeg3audio_t *audio, unsigned char *output, long *size, long max_size)
{
	int result = 0;
	int i;
	*size = 0;

	switch(audio->format)
	{
		case AUDIO_AC3:
/* Just write the AC3 stream */
			if(mpeg3bits_read_buffer(audio->astream, output, audio->framesize))
				return 1;
			*size = audio->framesize;
			break;

		case AUDIO_MPEG:
/* Fix the mpeg stream */
			result = mpeg3audio_read_header(audio);
			if(!result)
			{
				if(max_size < 4) return 1;
				*output++ = (audio->newhead & 0xff000000) >> 24;
				*output++ = (audio->newhead & 0xff0000) >> 16;
				*output++ = (audio->newhead & 0xff00) >> 8;
				*output++ = (audio->newhead & 0xff);
				*size += 4;

				if(max_size < 4 + audio->framesize) return 1;
				if(mpeg3bits_read_buffer(audio->astream, output, audio->framesize))
					return 1;

				*size += audio->framesize;
			}
			break;
		
		case AUDIO_PCM:
			if(mpeg3bits_read_buffer(audio->astream, output, audio->framesize))
				return 1;
			*size = audio->framesize;
			break;
	}
	return result;
}

/* Channel is 0 to channels - 1 */
int mpeg3audio_decode_audio(mpeg3audio_t *audio, 
		float *output_f, 
		short *output_i, 
		int channel, 
		long start_position, 
		long len)
{
	long allocation_needed = len + MPEG3AUDIO_PADDING;
	long i, j, result = 0;
	mpeg3_t *file = (mpeg3_t *) audio->file;
	mpeg3_atrack_t *atrack = (mpeg3_atrack_t *) audio->track;
	long attempts;

/* Create new buffer */
	if(audio->pcm_allocated < allocation_needed)
	{
		mpeg3audio_replace_buffer(audio, allocation_needed);
	}

/* There was a percentage seek */
	if(audio->percentage_seek >= 0)
	{
		mpeg3bits_seek_percentage(audio->astream, audio->percentage_seek);
/* Force the pcm buffer to be reread. */
		audio->pcm_position = start_position;
		audio->pcm_size = 0;
		audio->percentage_seek = -1;
	}
	else
	{
/* Entire output is in buffer so don't do anything. */
		if(start_position >= audio->pcm_position && start_position < audio->pcm_position + audio->pcm_size &&
			start_position + len <= audio->pcm_size)
		{
			;
		}
		else
/* Output starts in buffer but ends later so slide it back. */
		if(start_position <= audio->pcm_position + audio->pcm_size &&
			start_position >= audio->pcm_position)
		{
			for(i = 0, j = (start_position - audio->pcm_position) * audio->channels;
				j < audio->pcm_size * audio->channels;
				i++, j++)
			{
				audio->pcm_sample[i] = audio->pcm_sample[j];
			}

			audio->pcm_point = i;
			audio->pcm_size -= start_position - audio->pcm_position;
			audio->pcm_position = start_position;
		}
		else
		{
/* Output is outside buffer completely. */
			result = mpeg3audio_seek(audio, start_position);
			audio->sample_seek = -1;
/* Check sanity */
			if(start_position < audio->pcm_position) audio->pcm_position = start_position;
		}
		audio->sample_seek = -1;
	}





/* Read packets until the buffer is full. */
	if(!result)
	{
		attempts = 0;
		while(attempts < 6 &&
			!mpeg3bits_eof(audio->astream) &&
			audio->pcm_size + audio->pcm_position < start_position + len)
		{
			result = mpeg3audio_read_frame(audio);
			if(result) attempts++;
			audio->pcm_size = audio->pcm_point / audio->channels;
		}
	}





/* Copy the buffer to the output */
	if(output_f)
	{
		for(i = 0, j = (start_position - audio->pcm_position) * audio->channels + channel; 
			i < len && j < audio->pcm_size * audio->channels; 
			i++, j += audio->channels)
		{
			output_f[i] = audio->pcm_sample[j];
		}
		for( ; i < len; i++)
		{
			output_f[i] = 0;
		}
	}
	else
	if(output_i)
	{
		int sample;
		for(i = 0, j = (start_position - audio->pcm_position) * audio->channels + channel; 
			i < len && j < audio->pcm_size * audio->channels; 
			i++, j += audio->channels)
		{
			sample = (int)(audio->pcm_sample[j] * 32767);
			if(sample > 32767) sample = 32767;
			else 
			if(sample < -32768) sample = -32768;
			
			output_i[i] = sample;
		}
		for( ; i < len; i++)
		{
			output_i[i] = 0;
		}
	}

	if(audio->pcm_point > 0)
		return 0;
	else
		return result;
}
