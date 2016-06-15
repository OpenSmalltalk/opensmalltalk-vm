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
#include "mpeg3video.h"
#include "slice.h"
#include "vlc.h"

#include <stdio.h>

int mpeg3video_get_macroblock_address(mpeg3_slice_t *slice)
{
	int code, val = 0;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;

  	while((code = mpeg3slice_showbits(slice_buffer, 11)) < 24)
	{
/* Is not macroblock_stuffing */
    	if(code != 15)
		{     
/* Is macroblock_escape */
      		if(code == 8)
			{
        		val += 33;
      		}
      		else 
			{
/*        		fprintf(stderr, "mpeg3video_get_macroblock_address: invalid macroblock_address_increment code\n"); */
        		slice->fault = 1;
        		return 1;
      		}
    	}

    	mpeg3slice_flushbits(slice_buffer, 11);
  	}

  	if(code >= 1024)
	{
    	mpeg3slice_flushbit(slice_buffer);
    	return val + 1;
  	}

  	if(code >= 128)
	{
    	code >>= 6;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_MBAtab1[code].len);
    	return val + mpeg3_MBAtab1[code].val;
  	}

  	code -= 24;
  	mpeg3slice_flushbits(slice_buffer, mpeg3_MBAtab2[code].len);

  	return val + mpeg3_MBAtab2[code].val;
}

/* macroblock_type for pictures with spatial scalability */

static inline int mpeg3video_getsp_imb_type(mpeg3_slice_t *slice)
{
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
  	unsigned int code = mpeg3slice_showbits(slice_buffer, 4);
	if(!code)
	{
/*    	fprintf(stderr,"mpeg3video_getsp_imb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
    	return 0;
  	}

  	mpeg3slice_flushbits(slice_buffer, mpeg3_spIMBtab[code].len);
  	return mpeg3_spIMBtab[code].val;
}

static inline int mpeg3video_getsp_pmb_type(mpeg3_slice_t *slice)
{
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
  	int code = mpeg3slice_showbits(slice_buffer, 7);
	if(code < 2)
	{
/*    	fprintf(stderr,"mpeg3video_getsp_pmb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
    	return 0;
  	}

  	if(code >= 16)
	{
    	code >>= 3;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_spPMBtab0[code].len);

    	return mpeg3_spPMBtab0[code].val;
  	}

  	mpeg3slice_flushbits(slice_buffer, mpeg3_spPMBtab1[code].len);
  	return mpeg3_spPMBtab1[code].val;
}

static inline int mpeg3video_getsp_bmb_type(mpeg3_slice_t *slice)
{
  	mpeg3_VLCtab_t *p;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
  	int code = mpeg3slice_showbits9(slice_buffer);

  	if(code >= 64) 
		p = &mpeg3_spBMBtab0[(code >> 5) - 2];
  	else 
	if(code >= 16) 
		p = &mpeg3_spBMBtab1[(code >> 2) - 4];
  	else 
	if(code >= 8)  
		p = &mpeg3_spBMBtab2[code - 8];
  	else 
	{
/*    	fprintf(stderr,"mpeg3video_getsp_bmb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
    	return 0;
  	}

  	mpeg3slice_flushbits(slice_buffer, p->len);
  	return p->val;
}

static inline int mpeg3video_get_imb_type(mpeg3_slice_t *slice)
{
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
	if(mpeg3slice_getbit(slice_buffer))
	{
    	return 1;
  	}

  	if(!mpeg3slice_getbit(slice_buffer))
	{
/*    	fprintf(stderr,"mpeg3video_get_imb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
  	}

  	return 17;
}

static inline int mpeg3video_get_pmb_type(mpeg3_slice_t *slice)
{
  	int code;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;

  	if((code = mpeg3slice_showbits(slice_buffer, 6)) >= 8)
	{
    	code >>= 3;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_PMBtab0[code].len);
    	return mpeg3_PMBtab0[code].val;
  	}

  	if(code == 0)
	{
/*    	fprintf(stderr,"mpeg3video_get_pmb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
    	return 0;
  	}

  	mpeg3slice_flushbits(slice_buffer, mpeg3_PMBtab1[code].len);
  	return mpeg3_PMBtab1[code].val;
}

static inline int mpeg3video_get_bmb_type(mpeg3_slice_t *slice)
{
  	int code;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;

  	if((code = mpeg3slice_showbits(slice_buffer, 6)) >= 8)
	{
    	code >>= 2;
    	mpeg3slice_flushbits(slice_buffer, mpeg3_BMBtab0[code].len);
    	return mpeg3_BMBtab0[code].val;
  	}

  	if(code == 0)
	{
/*    	fprintf(stderr,"mpeg3video_get_bmb_type: invalid macroblock_type code\n"); */
    	slice->fault = 1;
    	return 0;
  	}

  	mpeg3slice_flushbits(slice_buffer, mpeg3_BMBtab1[code].len);

	return mpeg3_BMBtab1[code].val;
}

static inline int mpeg3video_get_dmb_type(mpeg3_slice_t *slice)
{
  	if(!mpeg3slice_getbit(slice->slice_buffer))
	{
/*    	fprintf(stderr,"mpeg3video_get_dmb_type: invalid macroblock_type code\n"); */
    	slice->fault=1;
  	}

  	return 1;
}


static inline int mpeg3video_get_snrmb_type(mpeg3_slice_t *slice)
{
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
    int code = mpeg3slice_showbits(slice_buffer, 3);

    if(code == 0)
    {
/*      fprintf(stderr,"mpeg3video_get_snrmb_type: invalid macroblock_type code\n"); */
        slice->fault = 1;
        return 0;
    }

    mpeg3slice_flushbits(slice_buffer, mpeg3_SNRMBtab[code].len);
    return mpeg3_SNRMBtab[code].val;
}

int mpeg3video_get_mb_type(mpeg3_slice_t *slice, mpeg3video_t *video)
{
	if(video->scalable_mode == SC_SNR)
	{
		return mpeg3video_get_snrmb_type(slice);
	}
	else
	{
    	switch(video->pict_type)
		{
    		case I_TYPE: return video->pict_scal ? mpeg3video_getsp_imb_type(slice) : mpeg3video_get_imb_type(slice);
    		case P_TYPE: return video->pict_scal ? mpeg3video_getsp_pmb_type(slice) : mpeg3video_get_pmb_type(slice);
    		case B_TYPE: return video->pict_scal ? mpeg3video_getsp_bmb_type(slice) : mpeg3video_get_bmb_type(slice);
    		case D_TYPE: return mpeg3video_get_dmb_type(slice);
    		default: 
				/*fprintf(stderr, "mpeg3video_getmbtype: unknown coding type\n"); */
				break;
/* MPEG-1 only, not implemented */
	  	}
  	}

  	return 0;
}

int mpeg3video_macroblock_modes(mpeg3_slice_t *slice, 
		mpeg3video_t *video, 
		int *pmb_type, 
		int *pstwtype, 
		int *pstwclass, 
		int *pmotion_type, 
		int *pmv_count, 
		int *pmv_format, 
		int *pdmv, 
		int *pmvscale,
		int *pdct_type)
{
	int mb_type;
	int stwtype, stwcode, stwclass;
	int motion_type = 0, mv_count, mv_format, dmv, mvscale;
	int dct_type;
	mpeg3_slice_buffer_t *slice_buffer = slice->slice_buffer;
	static unsigned char stwc_table[3][4]
    	= { {6,3,7,4}, {2,1,5,4}, {2,5,7,4} };
	static unsigned char stwclass_table[9]
    	= {0, 1, 2, 1, 1, 2, 3, 3, 4};

/* get macroblock_type */
  	mb_type = mpeg3video_get_mb_type(slice, video);

  	if(slice->fault) return 1;

/* get spatial_temporal_weight_code */
  	if(mb_type & MB_WEIGHT)
  	{
    	if(video->stwc_table_index == 0)
      		stwtype = 4;
    	else
    	{
      		stwcode = mpeg3slice_getbits2(slice_buffer);
      		stwtype = stwc_table[video->stwc_table_index - 1][stwcode];
    	}
  	}
  	else
    	stwtype = (mb_type & MB_CLASS4) ? 8 : 0;

/* derive spatial_temporal_weight_class (Table 7-18) */
  	stwclass = stwclass_table[stwtype];

/* get frame/field motion type */
  	if(mb_type & (MB_FORWARD | MB_BACKWARD))
	{
    	if(video->pict_struct == FRAME_PICTURE)
		{ 
/* frame_motion_type */
      		motion_type = video->frame_pred_dct ? MC_FRAME : mpeg3slice_getbits2(slice_buffer);
    	}
    	else 
		{ 
/* field_motion_type */
      		motion_type = mpeg3slice_getbits2(slice_buffer);
    	}
  	}
  	else 
	if((mb_type & MB_INTRA) && video->conceal_mv)
  	{
/* concealment motion vectors */
    	motion_type = (video->pict_struct == FRAME_PICTURE) ? MC_FRAME : MC_FIELD;
  	}

/* derive mv_count, mv_format and dmv, (table 6-17, 6-18) */
  	if(video->pict_struct == FRAME_PICTURE)
  	{
    	mv_count = (motion_type == MC_FIELD && stwclass < 2) ? 2 : 1;
    	mv_format = (motion_type == MC_FRAME) ? MV_FRAME : MV_FIELD;
  	}
  	else
  	{
    	mv_count = (motion_type == MC_16X8) ? 2 : 1;
    	mv_format = MV_FIELD;
  	}

  	dmv = (motion_type == MC_DMV); /* dual prime */

/* field mv predictions in frame pictures have to be scaled */
  	mvscale = ((mv_format == MV_FIELD) && (video->pict_struct == FRAME_PICTURE));

/* get dct_type (frame DCT / field DCT) */
  	dct_type = (video->pict_struct == FRAME_PICTURE) && 
             	(!video->frame_pred_dct) && 
             	(mb_type & (MB_PATTERN | MB_INTRA)) ? 
             	mpeg3slice_getbit(slice_buffer) : 0;

/* return values */
	*pmb_type = mb_type;
	*pstwtype = stwtype;
	*pstwclass = stwclass;
	*pmotion_type = motion_type;
	*pmv_count = mv_count;
	*pmv_format = mv_format;
	*pdmv = dmv;
	*pmvscale = mvscale;
	*pdct_type = dct_type;
	return 0;
}
