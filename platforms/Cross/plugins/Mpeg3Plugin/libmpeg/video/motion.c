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
#include "mpeg3video.h"
#include "vlc.h"

#include <stdio.h>


/* calculate motion vector component */

static inline void mpeg3video_calc_mv(int *pred, int r_size, int motion_code, int motion_r, int full_pel_vector)
{
	int lim = 16 << r_size;
	int vec = full_pel_vector ? (*pred >> 1) : (*pred);

	if(motion_code > 0)
	{
    	vec += ((motion_code - 1) << r_size) + motion_r + 1;
    	if(vec >= lim) vec -= lim + lim;
	}
	else 
	if(motion_code < 0)
	{
    	vec -= ((-motion_code - 1) << r_size) + motion_r + 1;
    	if(vec < -lim) vec += lim + lim;
	}
	*pred = full_pel_vector ? (vec << 1) : vec;
}




/*
int *dmvector, * differential motion vector *
int mvx, int mvy  * decoded mv components (always in field format) *
*/
void mpeg3video_calc_dmv(mpeg3video_t *video, 
		int DMV[][2], 
		int *dmvector, 
		int mvx, 
		int mvy)
{
	if(video->pict_struct == FRAME_PICTURE)
	{
    	if(video->topfirst)
		{
/* vector for prediction of top field from bottom field */
    		DMV[0][0] = ((mvx  + (mvx>0)) >> 1) + dmvector[0];
    		DMV[0][1] = ((mvy  + (mvy>0)) >> 1) + dmvector[1] - 1;

/* vector for prediction of bottom field from top field */
    		DMV[1][0] = ((3 * mvx + (mvx > 0)) >> 1) + dmvector[0];
    		DMV[1][1] = ((3 * mvy + (mvy > 0)) >> 1) + dmvector[1] + 1;
    	}
    	else 
		{
/* vector for prediction of top field from bottom field */
    		DMV[0][0] = ((3 * mvx + (mvx>0)) >> 1) + dmvector[0];
    		DMV[0][1] = ((3 * mvy + (mvy>0)) >> 1) + dmvector[1] - 1;

/* vector for prediction of bottom field from top field */
    		DMV[1][0] = ((mvx + (mvx>0)) >> 1) + dmvector[0];
    		DMV[1][1] = ((mvy + (mvy>0)) >> 1) + dmvector[1] + 1;
    	}
	}
	else 
	{
/* vector for prediction from field of opposite 'parity' */
    	DMV[0][0] = ((mvx + (mvx > 0)) >> 1) + dmvector[0];
    	DMV[0][1] = ((mvy + (mvy > 0)) >> 1) + dmvector[1];

/* correct for vertical field shift */
    	if(video->pict_struct == TOP_FIELD)
			DMV[0][1]--;
    	else 
			DMV[0][1]++;
	}
}

static inline int mpeg3video_get_mv(mpeg3_slice_t *slice)
{
  	int code;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;

  	if(mpeg3slice_getbit(slice_buffer))
	{
    	return 0;
  	}

  	if((code = mpeg3slice_showbits9(slice_buffer)) >= 64)
	{
    	code >>= 6;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_MVtab0[code].len);
    	return mpeg3slice_getbit(slice_buffer) ? -mpeg3_MVtab0[code].val : mpeg3_MVtab0[code].val;
  	}

  	if(code >= 24)
	{
    	code >>= 3;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_MVtab1[code].len);
	    return mpeg3slice_getbit(slice_buffer) ? -mpeg3_MVtab1[code].val : mpeg3_MVtab1[code].val;
  	}

  	if((code -= 12) < 0)
	{
/*    	fprintf(stdout,"mpeg3video_get_mv: invalid motion_vector code\n"); */
    	slice->fault = 1;
    	return 1;
  	}

  	mpeg3slice_flushbits(slice_buffer, mpeg3_MVtab2[code].len);
 	return mpeg3slice_getbit(slice_buffer) ? -mpeg3_MVtab2[code].val : mpeg3_MVtab2[code].val;
}

/* get differential motion vector (for dual prime prediction) */

static inline int mpeg3video_get_dmv(mpeg3_slice_t *slice)
{
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
  	if(mpeg3slice_getbit(slice_buffer))
	{
    	return mpeg3slice_getbit(slice_buffer) ? -1 : 1;
  	}
  	else 
	{
    	return 0;
  	}
}



/* get and decode motion vector and differential motion vector */

void mpeg3video_motion_vector(mpeg3_slice_t *slice,
		mpeg3video_t *video, 
		int *PMV, 
		int *dmvector, 
		int h_r_size, 
		int v_r_size,
		int dmv, 
		int mvscale, 
		int full_pel_vector)
{
	int motion_r;
	int motion_code = mpeg3video_get_mv(slice);
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;

	if(slice->fault) return;
	motion_r = (h_r_size != 0 && motion_code != 0) ? mpeg3slice_getbits(slice_buffer, h_r_size) : 0;

  	mpeg3video_calc_mv(&PMV[0], h_r_size, motion_code, motion_r, full_pel_vector);

  	if(dmv) dmvector[0] = mpeg3video_get_dmv(slice);

  	motion_code = mpeg3video_get_mv(slice);
  	if(slice->fault)  return;
  	motion_r = (v_r_size != 0 && motion_code != 0) ? mpeg3slice_getbits(slice_buffer, v_r_size) : 0;

/* DIV 2 */
  	if(mvscale) PMV[1] >>= 1; 

  	mpeg3video_calc_mv(&PMV[1], v_r_size, motion_code, motion_r, full_pel_vector);

	if(mvscale) PMV[1] <<= 1;
	if(dmv) dmvector[1] = mpeg3video_get_dmv(slice);
}

int mpeg3video_motion_vectors(mpeg3_slice_t *slice,
		mpeg3video_t *video, 
		int PMV[2][2][2], 
		int dmvector[2], 
		int mv_field_sel[2][2],
		int s, 
		int mv_count, 
		int mv_format, 
		int h_r_size, 
		int v_r_size, 
		int dmv, 
		int mvscale)
{
	int result = 0;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
	if(mv_count == 1)
	{
		if(mv_format == MV_FIELD && !dmv)
		{
			mv_field_sel[1][s] = mv_field_sel[0][s] = mpeg3slice_getbit(slice_buffer);
		}

    	mpeg3video_motion_vector(slice, 
			video, 
			PMV[0][s], 
			dmvector, 
			h_r_size, 
			v_r_size, 
			dmv, 
			mvscale, 
			0);
    	if(slice->fault) return 1;

/* update other motion vector predictors */
    	PMV[1][s][0] = PMV[0][s][0];
    	PMV[1][s][1] = PMV[0][s][1];
  	}
  	else 
	{
    	mv_field_sel[0][s] = mpeg3slice_getbit(slice_buffer);
    	mpeg3video_motion_vector(slice, 
			video, 
			PMV[0][s], 
			dmvector, 
			h_r_size, 
			v_r_size, 
			dmv, 
			mvscale, 
			0);
    	if(slice->fault) return 1;

    	mv_field_sel[1][s] = mpeg3slice_getbit(slice_buffer);
    	mpeg3video_motion_vector(slice, 
			video, 
			PMV[1][s], 
			dmvector, 
			h_r_size, 
			v_r_size, 
			dmv, 
			mvscale, 
			0);
    	if(slice->fault) return 1;
  	}
	return 0;
}
