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

#include "mpeg3audio.h"
#include "mpeg3private.inc"

int mpeg3audio_read_pcm_header(mpeg3audio_t *audio)
{
	unsigned int code;
	
	code = mpeg3bits_getbits(audio->astream, 16);
	while(!mpeg3bits_eof(audio->astream) && code != MPEG3_PCM_START_CODE)
	{
		code <<= 8;
		code &= 0xffff;
		code |= mpeg3bits_getbits(audio->astream, 8);
	}

	audio->avg_framesize = audio->framesize = 0x7db;
	audio->channels = 2;
	
	return mpeg3bits_eof(audio->astream);
}

int mpeg3audio_do_pcm(mpeg3audio_t *audio)
{
	int i, j, k;
	MPEG3_INT16 sample;
	int frame_samples = (audio->framesize - 3) / audio->channels / 2;

	if(mpeg3bits_read_buffer(audio->astream, audio->ac3_buffer, frame_samples * audio->channels * 2))
		return 1;

/* Need more room */
	if(audio->pcm_point / audio->channels >= audio->pcm_allocated - MPEG3AUDIO_PADDING * audio->channels)
	{
		mpeg3audio_replace_buffer(audio, audio->pcm_allocated + MPEG3AUDIO_PADDING * audio->channels);
	}

	k = 0;
	for(i = 0; i < frame_samples; i++)
	{
		for(j = 0; j < audio->channels; j++)
		{
			sample = ((MPEG3_INT16)(audio->ac3_buffer[k++])) << 8;
			sample |= audio->ac3_buffer[k++];
			audio->pcm_sample[audio->pcm_point + i * audio->channels + j] = 
				(float)sample / 32767;
		}
	}
	audio->pcm_point += frame_samples * audio->channels;
	return 0;
}
