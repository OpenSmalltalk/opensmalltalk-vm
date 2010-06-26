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
 
#include "mpeg3audio.h"
#include "tables.h"

#define WRITE_SAMPLE(samples, sum) \
{ \
	(*samples) = (sum); \
}

int mpeg3audio_synth_stereo(mpeg3audio_t *audio, float *bandPtr, int channel, float *out, int *pnt)
{
	const int step = 2;
	float *samples = out + *pnt;
    register float sum;
	float *b0, (*buf)[0x110];
	int bo1;

	if(!channel)
	{
    	audio->bo--;
    	audio->bo &= 0xf;
    	buf = audio->synth_stereo_buffs[0];
	}
	else 
	{
    	samples++;
    	buf = audio->synth_stereo_buffs[1];
	}

	if(audio->bo & 0x1)
	{
    	b0 = buf[0];
    	bo1 = audio->bo;
    	mpeg3audio_dct64(buf[1] + ((audio->bo + 1) & 0xf), buf[0] + audio->bo, bandPtr);
	}
	else 
	{
    	b0 = buf[1];
    	bo1 = audio->bo + 1;
    	mpeg3audio_dct64(buf[0] + audio->bo, buf[1] + audio->bo + 1, bandPtr);
	}

/*printf("%f %f %f\n", buf[0][0], buf[1][0], bandPtr[0]); */

	{
    	register int j;
    	float *window = mpeg3_decwin + 16 - bo1;

    	for(j = 16; j; j--, b0 += 0x10, window += 0x20, samples += step)
    	{
    		sum  = window[0x0] * b0[0x0];
    		sum -= window[0x1] * b0[0x1];
    		sum += window[0x2] * b0[0x2];
    		sum -= window[0x3] * b0[0x3];
    		sum += window[0x4] * b0[0x4];
    		sum -= window[0x5] * b0[0x5];
    		sum += window[0x6] * b0[0x6];
    		sum -= window[0x7] * b0[0x7];
    		sum += window[0x8] * b0[0x8];
    		sum -= window[0x9] * b0[0x9];
    		sum += window[0xA] * b0[0xA];
    		sum -= window[0xB] * b0[0xB];
    		sum += window[0xC] * b0[0xC];
    		sum -= window[0xD] * b0[0xD];
    		sum += window[0xE] * b0[0xE];
    		sum -= window[0xF] * b0[0xF];

    		WRITE_SAMPLE(samples, sum);
      	}

    	sum  = window[0x0] * b0[0x0];
    	sum += window[0x2] * b0[0x2];
    	sum += window[0x4] * b0[0x4];
    	sum += window[0x6] * b0[0x6];
    	sum += window[0x8] * b0[0x8];
    	sum += window[0xA] * b0[0xA];
    	sum += window[0xC] * b0[0xC];
    	sum += window[0xE] * b0[0xE];
    	WRITE_SAMPLE(samples, sum);
    	b0 -= 0x10;
		window -= 0x20;
		samples += step;
      	window += bo1 << 1;

    	for(j = 15; j; j--, b0 -= 0x10, window -= 0x20, samples += step)
    	{
    		sum = -window[-0x1] * b0[0x0];
    		sum -= window[-0x2] * b0[0x1];
    		sum -= window[-0x3] * b0[0x2];
    		sum -= window[-0x4] * b0[0x3];
    		sum -= window[-0x5] * b0[0x4];
    		sum -= window[-0x6] * b0[0x5];
    		sum -= window[-0x7] * b0[0x6];
    		sum -= window[-0x8] * b0[0x7];
    		sum -= window[-0x9] * b0[0x8];
    		sum -= window[-0xA] * b0[0x9];
    		sum -= window[-0xB] * b0[0xA];
    		sum -= window[-0xC] * b0[0xB];
    		sum -= window[-0xD] * b0[0xC];
    		sum -= window[-0xE] * b0[0xD];
    		sum -= window[-0xF] * b0[0xE];
    		sum -= window[-0x0] * b0[0xF];

    		WRITE_SAMPLE(samples, sum);
    	}
	}
	*pnt += 64;

	return 0;
}

int mpeg3audio_synth_mono(mpeg3audio_t *audio, float *bandPtr, float *samples, int *pnt)
{
	float *samples_tmp = audio->synth_mono_buff;
	float *tmp1 = samples_tmp;
	int i, ret;
	int pnt1 = 0;

	ret = mpeg3audio_synth_stereo(audio, bandPtr, 0, samples_tmp, &pnt1);
	samples += *pnt;

	for(i = 0; i < 32; i++)
	{
    	*samples = *tmp1;
    	samples++;
    	tmp1 += 2;
	}
	*pnt += 32;

	return ret;
}


/* Call this after every seek to reset the buffers */
int mpeg3audio_reset_synths(mpeg3audio_t *audio)
{
	int i, j, k;
	for(i = 0; i < 2; i++)
	{
		for(j = 0; j < 2; j++)
		{
			for(k = 0; k < 0x110; k++)
			{
				audio->synth_stereo_buffs[i][j][k] = 0;
			}
		}
	}
	for(i = 0; i < 64; i++)
	{
		audio->synth_mono_buff[i] = 0;
		audio->layer2_scfsi_buf[i] = 0;
	}
	for(i = 0; i < 2; i++)
	{
		for(j = 0; j < 2; j++)
		{
			for(k = 0; k < SBLIMIT * SSLIMIT; k++)
			{
				audio->mp3_block[i][j][k] = 0;
			}
		}
	}
	audio->mp3_blc[0] = 0;
	audio->mp3_blc[1] = 0;
	for(i = 0; i < audio->channels; i++)
	{
		for(j = 0; j < AC3_N / 2; j++)
		{
			audio->ac3_delay[i][j] = 0;
		}
	}
	return 0;
}
