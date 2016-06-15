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
#include "mpeg3demux.h"
#include "mpeg3private.h"
#include "mpeg3video.h"

#include <stdio.h>
#include <stdlib.h>

int mpeg3video_getseqhdr(mpeg3video_t *video)
{
	int i;
	mpeg3_t *file = (mpeg3_t *) video->file;

	int aspect_ratio, picture_rate, vbv_buffer_size;
	int constrained_parameters_flag;
	int load_intra_quantizer_matrix, load_non_intra_quantizer_matrix;

	video->horizontal_size = mpeg3bits_getbits(video->vstream, 12);
	video->vertical_size = mpeg3bits_getbits(video->vstream, 12);
	aspect_ratio = mpeg3bits_getbits(video->vstream, 4);
	video->framerate_code = mpeg3bits_getbits(video->vstream, 4);
	video->bitrate = mpeg3bits_getbits(video->vstream, 18);
	mpeg3bits_getbit_noptr(video->vstream); /* marker bit (=1) */
	vbv_buffer_size = mpeg3bits_getbits(video->vstream, 10);
	constrained_parameters_flag = mpeg3bits_getbit_noptr(video->vstream);
	video->frame_rate = mpeg3_frame_rate_table[video->framerate_code];

 	load_intra_quantizer_matrix = mpeg3bits_getbit_noptr(video->vstream);
 	if(load_intra_quantizer_matrix)
	{
    	for(i = 0; i < 64; i++)
      		video->intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]] = mpeg3bits_getbyte_noptr(video->vstream);
  	}
  	else 
	{
    	for(i = 0; i < 64; i++)
      		video->intra_quantizer_matrix[i] = mpeg3_default_intra_quantizer_matrix[i];
  	}

	load_non_intra_quantizer_matrix = mpeg3bits_getbit_noptr(video->vstream);
	if(load_non_intra_quantizer_matrix)
	{
    	for(i = 0; i < 64; i++)
      		video->non_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]] = mpeg3bits_getbyte_noptr(video->vstream);
  	}
  	else 
	{
    	for(i = 0; i < 64; i++)
      		video->non_intra_quantizer_matrix[i] = 16;
  	}

/* copy luminance to chrominance matrices */
  	for(i = 0; i < 64; i++)
	{
    	video->chroma_intra_quantizer_matrix[i] = video->intra_quantizer_matrix[i];
   	 	video->chroma_non_intra_quantizer_matrix[i] = video->non_intra_quantizer_matrix[i];
  	}

	return 0;
}


/* decode sequence extension */

int mpeg3video_sequence_extension(mpeg3video_t *video)
{
	int prof_lev;
	int horizontal_size_extension, vertical_size_extension;
	int bit_rate_extension, vbv_buffer_size_extension, low_delay;
	int frame_rate_extension_n, frame_rate_extension_d;
	int pos = 0;

	video->mpeg2 = 1;
	video->scalable_mode = SC_NONE; /* unless overwritten by seq. scal. ext. */
	prof_lev = mpeg3bits_getbyte_noptr(video->vstream);
	video->prog_seq = mpeg3bits_getbit_noptr(video->vstream);
	video->chroma_format = mpeg3bits_getbits(video->vstream, 2);
	horizontal_size_extension = mpeg3bits_getbits(video->vstream, 2);
	vertical_size_extension = mpeg3bits_getbits(video->vstream, 2);
	bit_rate_extension = mpeg3bits_getbits(video->vstream, 12);
	mpeg3bits_getbit_noptr(video->vstream);
	vbv_buffer_size_extension = mpeg3bits_getbyte_noptr(video->vstream);
	low_delay = mpeg3bits_getbit_noptr(video->vstream);
	frame_rate_extension_n = mpeg3bits_getbits(video->vstream, 2);
	frame_rate_extension_d = mpeg3bits_getbits(video->vstream, 5);
	video->horizontal_size = (horizontal_size_extension << 12) | (video->horizontal_size & 0x0fff);
	video->vertical_size = (vertical_size_extension << 12) | (video->vertical_size & 0x0fff);
}


/* decode sequence display extension */

int mpeg3video_sequence_display_extension(mpeg3video_t *video)
{
	int colour_primaries = 0, transfer_characteristics = 0;
	int display_horizontal_size, display_vertical_size;
	int pos = 0;
	int video_format = mpeg3bits_getbits(video->vstream, 3);
	int colour_description = mpeg3bits_getbit_noptr(video->vstream);

	if(colour_description)
	{
    	colour_primaries = mpeg3bits_getbyte_noptr(video->vstream);
    	transfer_characteristics = mpeg3bits_getbyte_noptr(video->vstream);
    	video->matrix_coefficients = mpeg3bits_getbyte_noptr(video->vstream);
	}

	display_horizontal_size = mpeg3bits_getbits(video->vstream, 14);
	mpeg3bits_getbit_noptr(video->vstream);
	display_vertical_size = mpeg3bits_getbits(video->vstream, 14);
}


/* decode quant matrix entension */

int mpeg3video_quant_matrix_extension(mpeg3video_t *video)
{
	int i;
	int load_intra_quantiser_matrix, load_non_intra_quantiser_matrix;
	int load_chroma_intra_quantiser_matrix;
	int load_chroma_non_intra_quantiser_matrix;
	int pos = 0;

	if((load_intra_quantiser_matrix = mpeg3bits_getbit_noptr(video->vstream)) != 0)
	{
      	for(i = 0; i < 64; i++)
		{
    		video->chroma_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]]
    			= video->intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]]
    			= mpeg3bits_getbyte_noptr(video->vstream);
      	}
	}

	if((load_non_intra_quantiser_matrix = mpeg3bits_getbit_noptr(video->vstream)) != 0)
	{
    	for (i = 0; i < 64; i++)
		{
    		video->chroma_non_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]]
    			= video->non_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]]
    			= mpeg3bits_getbyte_noptr(video->vstream);
    	}
	}

	if((load_chroma_intra_quantiser_matrix = mpeg3bits_getbit_noptr(video->vstream)) != 0)
	{
    	for(i = 0; i < 64; i++)
    		video->chroma_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]] = mpeg3bits_getbyte_noptr(video->vstream);
	}

	if((load_chroma_non_intra_quantiser_matrix = mpeg3bits_getbit_noptr(video->vstream)) != 0)
	{
      	for(i = 0; i < 64; i++)
    		video->chroma_non_intra_quantizer_matrix[video->mpeg3_zigzag_scan_table[i]] = mpeg3bits_getbyte_noptr(video->vstream);
	}
}


/* decode sequence scalable extension */

int mpeg3video_sequence_scalable_extension(mpeg3video_t *video)
{
	int layer_id;

	video->scalable_mode = mpeg3bits_getbits(video->vstream, 2) + 1; /* add 1 to make SC_DP != SC_NONE */
	layer_id = mpeg3bits_getbits(video->vstream, 4);

	if(video->scalable_mode == SC_SPAT)
	{
    	video->llw = mpeg3bits_getbits(video->vstream, 14); /* lower_layer_prediction_horizontal_size */
    	mpeg3bits_getbit_noptr(video->vstream);
    	video->llh = mpeg3bits_getbits(video->vstream, 14); /* lower_layer_prediction_vertical_size */
    	video->hm = mpeg3bits_getbits(video->vstream, 5);
    	video->hn = mpeg3bits_getbits(video->vstream, 5);
    	video->vm = mpeg3bits_getbits(video->vstream, 5);
    	video->vn = mpeg3bits_getbits(video->vstream, 5);
	}

	if(video->scalable_mode == SC_TEMP)
      	fprintf(stderr, "mpeg3video_sequence_scalable_extension: temporal scalability not implemented\n");
}


/* decode picture display extension */

int mpeg3video_picture_display_extension(mpeg3video_t *video)
{
	int n, i;
	short frame_centre_horizontal_offset[3];
	short frame_centre_vertical_offset[3];

	if(video->prog_seq || video->pict_struct != FRAME_PICTURE)
		n = 1;
	else 
		n = video->repeatfirst ? 3 : 2;

	for(i = 0; i < n; i++)
	{
    	frame_centre_horizontal_offset[i] = (short)mpeg3bits_getbits(video->vstream, 16);
    	mpeg3bits_getbit_noptr(video->vstream);
    	frame_centre_vertical_offset[i] = (short)mpeg3bits_getbits(video->vstream, 16);
    	mpeg3bits_getbit_noptr(video->vstream);
	}
}


/* decode picture coding extension */

int mpeg3video_picture_coding_extension(mpeg3video_t *video)
{
	int chroma_420_type, composite_display_flag;
	int v_axis = 0, field_sequence = 0, sub_carrier = 0, burst_amplitude = 0, sub_carrier_phase = 0;

	video->h_forw_r_size = mpeg3bits_getbits(video->vstream, 4) - 1;
	video->v_forw_r_size = mpeg3bits_getbits(video->vstream, 4) - 1;
	video->h_back_r_size = mpeg3bits_getbits(video->vstream, 4) - 1;
	video->v_back_r_size = mpeg3bits_getbits(video->vstream, 4) - 1;
	video->dc_prec = mpeg3bits_getbits(video->vstream, 2);
	video->pict_struct = mpeg3bits_getbits(video->vstream, 2);
	video->topfirst = mpeg3bits_getbit_noptr(video->vstream);
	video->frame_pred_dct = mpeg3bits_getbit_noptr(video->vstream);
	video->conceal_mv = mpeg3bits_getbit_noptr(video->vstream);
	video->qscale_type = mpeg3bits_getbit_noptr(video->vstream);
	video->intravlc = mpeg3bits_getbit_noptr(video->vstream);
	video->altscan = mpeg3bits_getbit_noptr(video->vstream);
	video->repeatfirst = mpeg3bits_getbit_noptr(video->vstream);
	chroma_420_type = mpeg3bits_getbit_noptr(video->vstream);
	video->prog_frame = mpeg3bits_getbit_noptr(video->vstream);

	if(video->repeat_count > 100)
		video->repeat_count = 0;
	video->repeat_count += 100;

	video->current_repeat = 0;

	if(video->prog_seq)
	{
		if(video->repeatfirst)
		{
			if(video->topfirst)
				video->repeat_count += 200;
			else
				video->repeat_count += 100;
		}
	}
	else
	if(video->prog_frame)
	{
		if(video->repeatfirst)
		{
			video->repeat_count += 50;
		}
	}

/*printf("mpeg3video_picture_coding_extension %d\n", video->repeat_count); */
	composite_display_flag = mpeg3bits_getbit_noptr(video->vstream);

	if(composite_display_flag)
	{
    	v_axis = mpeg3bits_getbit_noptr(video->vstream);
    	field_sequence = mpeg3bits_getbits(video->vstream, 3);
    	sub_carrier = mpeg3bits_getbit_noptr(video->vstream);
    	burst_amplitude = mpeg3bits_getbits(video->vstream, 7);
    	sub_carrier_phase = mpeg3bits_getbyte_noptr(video->vstream);
	}
}


/* decode picture spatial scalable extension */

int mpeg3video_picture_spatial_scalable_extension(mpeg3video_t *video)
{
	video->pict_scal = 1; /* use spatial scalability in this picture */

	video->lltempref = mpeg3bits_getbits(video->vstream, 10);
	mpeg3bits_getbit_noptr(video->vstream);
	video->llx0 = mpeg3bits_getbits(video->vstream, 15);
	if(video->llx0 >= 16384) video->llx0 -= 32768;
	mpeg3bits_getbit_noptr(video->vstream);
	video->lly0 = mpeg3bits_getbits(video->vstream, 15);
	if(video->lly0 >= 16384) video->lly0 -= 32768;
	video->stwc_table_index = mpeg3bits_getbits(video->vstream, 2);
	video->llprog_frame = mpeg3bits_getbit_noptr(video->vstream);
	video->llfieldsel = mpeg3bits_getbit_noptr(video->vstream);
}


/* decode picture temporal scalable extension
 *
 * not implemented
 *
 */

int mpeg3video_picture_temporal_scalable_extension(mpeg3video_t *video)
{
  	fprintf(stderr, "mpeg3video_picture_temporal_scalable_extension: temporal scalability not supported\n");
}


/* decode extension and user data */

int mpeg3video_ext_user_data(mpeg3video_t *video)
{
  	int code = mpeg3bits_next_startcode(video->vstream);


  	while(code == MPEG3_EXT_START_CODE || code == MPEG3_USER_START_CODE &&
		!mpeg3bits_eof(video->vstream))
	{
    	mpeg3bits_refill(video->vstream);
		
    	if(code == MPEG3_EXT_START_CODE)
		{
      		int ext_id = mpeg3bits_getbits(video->vstream, 4);
      		switch(ext_id)
			{
    			case SEQ_ID:
					mpeg3video_sequence_extension(video);
					break;
    			case DISP_ID:
					mpeg3video_sequence_display_extension(video);
					break;
    			case QUANT_ID:
					mpeg3video_quant_matrix_extension(video);
					break;
    			case SEQSCAL_ID:
					mpeg3video_sequence_scalable_extension(video);
					break;
    			case PANSCAN_ID:
					mpeg3video_picture_display_extension(video);
					break;
    			case CODING_ID:
					mpeg3video_picture_coding_extension(video);
					break;
    			case SPATSCAL_ID:
					mpeg3video_picture_spatial_scalable_extension(video);
					break;
    			case TEMPSCAL_ID:
					mpeg3video_picture_temporal_scalable_extension(video);
					break;
    			default:
					fprintf(stderr,"mpeg3video_ext_user_data: reserved extension start code ID %d\n", ext_id);
					break;
      		}
   		}
   		code = mpeg3bits_next_startcode(video->vstream);
  	}
}


/* decode group of pictures header */

int mpeg3video_getgophdr(mpeg3video_t *video)
{
	int drop_flag, closed_gop, broken_link;

	drop_flag = mpeg3bits_getbit_noptr(video->vstream);
	video->gop_timecode.hour = mpeg3bits_getbits(video->vstream, 5);
	video->gop_timecode.minute = mpeg3bits_getbits(video->vstream, 6);
	mpeg3bits_getbit_noptr(video->vstream);
	video->gop_timecode.second = mpeg3bits_getbits(video->vstream, 6);
	video->gop_timecode.frame = mpeg3bits_getbits(video->vstream, 6);
	closed_gop = mpeg3bits_getbit_noptr(video->vstream);
	broken_link = mpeg3bits_getbit_noptr(video->vstream);

/*
 * printf("%d:%d:%d:%d %d %d %d\n", video->gop_timecode.hour, video->gop_timecode.minute, video->gop_timecode.second, video->gop_timecode.frame, 
 *  	drop_flag, closed_gop, broken_link);
 */
	return mpeg3bits_error(video->vstream);
}

/* decode picture header */

int mpeg3video_getpicturehdr(mpeg3video_t *video)
{
	int temp_ref, vbv_delay;

	video->pict_scal = 0; /* unless overwritten by pict. spat. scal. ext. */

	temp_ref = mpeg3bits_getbits(video->vstream, 10);
	video->pict_type = mpeg3bits_getbits(video->vstream, 3);
	vbv_delay = mpeg3bits_getbits(video->vstream, 16);

	if(video->pict_type == P_TYPE || video->pict_type == B_TYPE)
	{
    	video->full_forw = mpeg3bits_getbit_noptr(video->vstream);
    	video->forw_r_size = mpeg3bits_getbits(video->vstream, 3) - 1;
	}

	if(video->pict_type == B_TYPE)
	{
    	video->full_back = mpeg3bits_getbit_noptr(video->vstream);
    	video->back_r_size = mpeg3bits_getbits(video->vstream, 3) - 1;
	}

/* get extra bit picture */
	while(mpeg3bits_getbit_noptr(video->vstream) &&
		!mpeg3bits_eof(video->vstream)) mpeg3bits_getbyte_noptr(video->vstream);
	return 0;
}


int mpeg3video_get_header(mpeg3video_t *video, int dont_repeat)
{
	unsigned int code;

/* a sequence header should be found before returning from `getheader' the */
/* first time (this is to set horizontal/vertical size properly) */

/* Repeat the frame until it's less than 1 count from repeat_count */
	if(video->repeat_count - video->current_repeat >= 100 && !dont_repeat)
	{
		return 0;
	}

	if(dont_repeat)
	{
		video->repeat_count = 0;
		video->current_repeat = 0;
	}
	else
		video->repeat_count -= video->current_repeat;

	while(1)
	{
/* look for startcode */
    	code = mpeg3bits_next_startcode(video->vstream);
		if(mpeg3bits_eof(video->vstream)) return 1;
		if(code != MPEG3_SEQUENCE_END_CODE) mpeg3bits_refill(video->vstream);
 
    	switch(code)
		{
    		case MPEG3_SEQUENCE_START_CODE:
    			video->found_seqhdr = 1;
    			mpeg3video_getseqhdr(video);  
    			mpeg3video_ext_user_data(video);
    			break;

    		case MPEG3_GOP_START_CODE:
    			mpeg3video_getgophdr(video);
    			mpeg3video_ext_user_data(video);
    			break;

    		case MPEG3_PICTURE_START_CODE:
    			mpeg3video_getpicturehdr(video);
    			mpeg3video_ext_user_data(video);
    			if(video->found_seqhdr) return 0;       /* Exit here */
    			break;

    		case MPEG3_SEQUENCE_END_CODE:
// Continue until the end
				mpeg3bits_refill(video->vstream);
				break;

    		default:
    			break;
    	}
  	}
 	return 1;      /* Shouldn't be reached. */
}

int mpeg3video_ext_bit_info(mpeg3_slice_buffer_t *slice_buffer)
{
	while(mpeg3slice_getbit(slice_buffer)) mpeg3slice_getbyte(slice_buffer);
	return 0;
}

/* decode slice header */
int mpeg3video_getslicehdr(mpeg3_slice_t *slice, mpeg3video_t *video)
{
	int slice_vertical_position_extension, intra_slice;
	int qs;

  	slice_vertical_position_extension = (video->mpeg2 && video->vertical_size > 2800) ? 
		mpeg3slice_getbits(slice->slice_buffer, 3) : 0;

  	if(video->scalable_mode == SC_DP) slice->pri_brk = mpeg3slice_getbits(slice->slice_buffer, 7);

  	qs = mpeg3slice_getbits(slice->slice_buffer, 5);
  	slice->quant_scale = video->mpeg2 ? (video->qscale_type ? mpeg3_non_linear_mquant_table[qs] : (qs << 1)) : qs;

  	if(mpeg3slice_getbit(slice->slice_buffer))
	{
    	intra_slice = mpeg3slice_getbit(slice->slice_buffer);
    	mpeg3slice_getbits(slice->slice_buffer, 7);
    	mpeg3video_ext_bit_info(slice->slice_buffer);
  	}
  	else 
		intra_slice = 0;

	return slice_vertical_position_extension;
}
