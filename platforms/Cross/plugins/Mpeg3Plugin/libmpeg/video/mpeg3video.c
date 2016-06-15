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
#include "mpeg3videoprotos.h"
#include <stdlib.h>

unsigned char mpeg3_zig_zag_scan_mmx[64] =
{
    0*8+0 /* 0*/, 1*8+0 /* 1*/, 0*8+1 /* 8*/, 0*8+2 /*16*/, 1*8+1 /* 9*/, 2*8+0 /* 2*/, 3*8+0 /* 3*/, 2*8+1 /*10*/,
    1*8+2 /*17*/, 0*8+3 /*24*/, 0*8+4 /*32*/, 1*8+3 /*25*/, 2*8+2 /*18*/, 3*8+1 /*11*/, 4*8+0 /* 4*/, 5*8+0 /* 5*/,
    4*8+1 /*12*/, 5*8+2 /*19*/, 2*8+3 /*26*/, 1*8+4 /*33*/, 0*8+5 /*40*/, 0*8+6 /*48*/, 1*8+5 /*41*/, 2*8+4 /*34*/,
    3*8+3 /*27*/, 4*8+2 /*20*/, 5*8+1 /*13*/, 6*8+0 /* 6*/, 7*8+0 /* 7*/, 6*8+1 /*14*/, 5*8+2 /*21*/, 4*8+3 /*28*/,
    3*8+4 /*35*/, 2*8+5 /*42*/, 1*8+6 /*49*/, 0*8+7 /*56*/, 1*8+7 /*57*/, 2*8+6 /*50*/, 3*8+5 /*43*/, 4*8+4 /*36*/,
    5*8+3 /*29*/, 6*8+2 /*22*/, 7*8+1 /*15*/, 7*8+2 /*23*/, 6*8+3 /*30*/, 5*8+4 /*37*/, 4*8+5 /*44*/, 3*8+6 /*51*/,
    2*8+7 /*58*/, 3*8+7 /*59*/, 4*8+6 /*52*/, 5*8+5 /*45*/, 6*8+4 /*38*/, 7*8+3 /*31*/, 7*8+4 /*39*/, 6*8+5 /*46*/,
    7*8+6 /*53*/, 4*8+7 /*60*/, 5*8+7 /*61*/, 6*8+6 /*54*/, 7*8+5 /*47*/, 7*8+6 /*55*/, 6*8+7 /*62*/, 7*8+7 /*63*/
};

/* alternate scan */
unsigned char mpeg3_alternate_scan_mmx[64] =
{
     0*8+0 /*0 */, 0*8+1 /* 8*/, 0*8+2 /*16*/, 0*8+3 /*24*/, 1*8+0 /* 1*/, 1*8+1 /* 9*/, 2*8+0 /* 2*/, 2*8+1 /*10*/,
     1*8+2 /*17*/, 1*8+3 /*25*/, 0*8+4 /*32*/, 0*8+5 /*40*/, 0*8+6 /*48*/, 0*8+7 /*56*/, 1*8+7 /*57*/, 1*8+6 /*49*/,
     1*8+5 /*41*/, 1*8+4 /*33*/, 2*8+3 /*26*/, 2*8+2 /*18*/, 3*8+0 /* 3*/, 3*8+1 /*11*/, 4*8+0 /* 4*/, 4*8+1 /*12*/,
     3*8+2 /*19*/, 3*8+3 /*27*/, 2*8+4 /*34*/, 2*8+5 /*42*/, 2*8+6 /*50*/, 2*8+7 /*58*/, 3*8+4 /*35*/, 3*8+5 /*43*/,
     3*8+6 /*51*/, 3*8+7 /*59*/, 4*8+2 /*20*/, 4*8+3 /*28*/, 5*8+0 /* 5*/, 5*8+1 /*13*/, 6*8+0 /* 6*/, 6*8+1 /*14*/,
     5*8+2 /*21*/, 5*8+3 /*29*/, 4*8+4 /*36*/, 4*8+5 /*44*/, 4*8+6 /*52*/, 4*8+7 /*60*/, 5*8+4 /*37*/, 5*8+5 /*45*/,
     5*8+6 /*53*/, 5*8+7 /*61*/, 6*8+2 /*22*/, 6*8+3 /*30*/, 7*8+0 /* 7*/, 7*8+1 /*15*/, 7*8+2 /*23*/, 7*8+3 /*31*/,
     6*8+4 /*38*/, 6*8+5 /*46*/, 6*8+6 /*54*/, 6*8+7 /*62*/, 7*8+4 /*39*/, 7*8+5 /*47*/, 7*8+6 /*55*/, 7*8+6 /*63*/
};



/* zig-zag scan */
unsigned char mpeg3_zig_zag_scan_nommx[64] =
{
  0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 
  12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 
  35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 
  58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63
};

/* alternate scan */
unsigned char mpeg3_alternate_scan_nommx[64] =
{
  0, 8, 16, 24, 1, 9, 2, 10, 17, 25, 32, 40, 48, 56, 57, 49, 
  41, 33, 26, 18, 3, 11, 4, 12, 19, 27, 34, 42, 50, 58, 35, 43, 
  51, 59, 20, 28, 5, 13, 6, 14, 21, 29, 36, 44, 52, 60, 37, 45, 
  53, 61, 22, 30, 7, 15, 23, 31, 38, 46, 54, 62, 39, 47, 55, 63
};

/* default intra quantization matrix */
unsigned char mpeg3_default_intra_quantizer_matrix[64] =
{
  8, 16, 19, 22, 26, 27, 29, 34,
  16, 16, 22, 24, 27, 29, 34, 37,
  19, 22, 26, 27, 29, 34, 34, 38,
  22, 22, 26, 27, 29, 34, 37, 40,
  22, 26, 27, 29, 32, 35, 40, 48,
  26, 27, 29, 32, 35, 40, 48, 58,
  26, 27, 29, 34, 38, 46, 56, 69,
  27, 29, 35, 38, 46, 56, 69, 83
};

unsigned char mpeg3_non_linear_mquant_table[32] = 
{
   0, 1, 2, 3, 4, 5, 6, 7,
   8, 10, 12, 14, 16, 18, 20, 22, 
  24, 28, 32, 36, 40, 44, 48, 52, 
  56, 64, 72, 80, 88, 96, 104, 112
};

double mpeg3_frame_rate_table[16] =
{
  0.0,   /* Pad */
  24000.0/1001.0,       /* Official frame rates */
  24.0,
  25.0,
  30000.0/1001.0,
  30.0,
  50.0,
  ((60.0*1000.0)/1001.0),
  60.0,

  1,                    /* Unofficial economy rates */
  5, 
  10,
  12,
  15,
  0,
  0,
};

int mpeg3video_initdecoder(mpeg3video_t *video)
{
	int blk_cnt_tab[3] = {6, 8, 12};
	int cc;
  	int i;
	long size[4], padding[2];         /* Size of Y, U, and V buffers */

	if(!video->mpeg2)
	{
/* force MPEG-1 parameters */
    	video->prog_seq = 1;
    	video->prog_frame = 1;
    	video->pict_struct = FRAME_PICTURE;
    	video->frame_pred_dct = 1;
    	video->chroma_format = CHROMA420;
    	video->matrix_coefficients = 5;
	}

/* Get dimensions rounded to nearest multiple of coded macroblocks */
	video->mb_width = (video->horizontal_size + 15) / 16;
	video->mb_height = (video->mpeg2 && !video->prog_seq) ? 
					(2 * ((video->vertical_size + 31) / 32)) : 
					((video->vertical_size + 15) / 16);
	video->coded_picture_width = 16 * video->mb_width;
	video->coded_picture_height = 16 * video->mb_height;
	video->chrom_width = (video->chroma_format == CHROMA444) ? 
					video->coded_picture_width : 
					(video->coded_picture_width >> 1);
	video->chrom_height = (video->chroma_format != CHROMA420) ? 
					video->coded_picture_height : 
                    (video->coded_picture_height >> 1);
	video->blk_cnt = blk_cnt_tab[video->chroma_format - 1];

/* Get sizes of YUV buffers */
	padding[0] = 16 * video->coded_picture_width;
	size[0] = video->coded_picture_width * video->coded_picture_height + padding[0] * 2;

	padding[1] = 16 * video->chrom_width;
	size[1] = video->chrom_width * video->chrom_height + 2 * padding[1];

	size[2] = (video->llw * video->llh);
	size[3] = (video->llw * video->llh) / 4;

/* Allocate contiguous fragments for YUV buffers for hardware YUV decoding */
	video->yuv_buffer[0] = (unsigned char*)memoryAllocate(1, (size[0] + padding[0]) + 2 * (size[1] + padding[1]));
	video->yuv_buffer[1] = (unsigned char*)memoryAllocate(1, (size[0] + padding[0]) + 2 * (size[1] + padding[1]));
	video->yuv_buffer[2] = (unsigned char*)memoryAllocate(1, (size[0] + padding[0]) + 2 * (size[1] + padding[1]));

    if(video->scalable_mode == SC_SPAT)
	{
		video->yuv_buffer[3] = (unsigned char*)memoryAllocate(1, size[2] + 2 * size[3]);
		video->yuv_buffer[4] = (unsigned char*)memoryAllocate(1, size[2] + 2 * size[3]);
	}

/* Direct pointers to areas of contiguous fragments in YVU order per Microsoft */	
	for(cc = 0; cc < 3; cc++)
	{
		video->llframe0[cc] = 0;
		video->llframe1[cc] = 0;
		video->newframe[cc] = 0;
	}

	video->refframe[0]    = video->yuv_buffer[0];
	video->oldrefframe[0] = video->yuv_buffer[1];
	video->auxframe[0]    = video->yuv_buffer[2];
	video->refframe[2]    = video->yuv_buffer[0] + size[0] + padding[0];
	video->oldrefframe[2] = video->yuv_buffer[1] + size[0] + padding[0];
	video->auxframe[2]    = video->yuv_buffer[2] + size[0] + padding[0];
	video->refframe[1]    = video->yuv_buffer[0] + size[0] + padding[0] + size[1] + padding[1];
	video->oldrefframe[1] = video->yuv_buffer[1] + size[0] + padding[0] + size[1] + padding[1];
	video->auxframe[1]    = video->yuv_buffer[2] + size[0] + padding[0] + size[1] + padding[1];

    if(video->scalable_mode == SC_SPAT)
	{
/* this assumes lower layer is 4:2:0 */
		video->llframe0[0] = video->yuv_buffer[3] + padding[0] 				   ;
		video->llframe1[0] = video->yuv_buffer[4] + padding[0] 				   ;
		video->llframe0[2] = video->yuv_buffer[3] + padding[1] + size[2]		   ;
		video->llframe1[2] = video->yuv_buffer[4] + padding[1] + size[2]		   ;
		video->llframe0[1] = video->yuv_buffer[3] + padding[1] + size[2] + size[3];
		video->llframe1[1] = video->yuv_buffer[4] + padding[1] + size[2] + size[3];
    }

/* Initialize the YUV tables for software YUV decoding */
	video->cr_to_r = (long *) memoryAllocate(1,sizeof(long) * 256);
	video->cr_to_g = (long *) memoryAllocate(1,sizeof(long) * 256);
	video->cb_to_g = (long *) memoryAllocate(1,sizeof(long) * 256);
	video->cb_to_b = (long *) memoryAllocate(1,sizeof(long) * 256);
	video->cr_to_r_ptr = video->cr_to_r + 128;
	video->cr_to_g_ptr = video->cr_to_g + 128;
	video->cb_to_g_ptr = video->cb_to_g + 128;
	video->cb_to_b_ptr = video->cb_to_b + 128;

	for(i = -128; i < 128; i++)
	{
		video->cr_to_r_ptr[i] = (long)( 1.371 * 65536 * i);
		video->cr_to_g_ptr[i] = (long)(-0.698 * 65536 * i);
		video->cb_to_g_ptr[i] = (long)(-0.336 * 65536 * i);
		video->cb_to_b_ptr[i] = (long)( 1.732 * 65536 * i);
	}

	return 0;
}

int mpeg3video_deletedecoder(mpeg3video_t *video)
{
	int i, padding;

	memoryFree(video->yuv_buffer[0]);
	memoryFree(video->yuv_buffer[1]);
	memoryFree(video->yuv_buffer[2]);

	if(video->llframe0[0])
	{
		memoryFree(video->yuv_buffer[3]);
		memoryFree(video->yuv_buffer[4]);
	}

	memoryFree(video->cr_to_r);
	memoryFree(video->cr_to_g);
	memoryFree(video->cb_to_g);
	memoryFree(video->cb_to_b);
	return 0;
}

void mpeg3video_init_scantables(mpeg3video_t *video)
{
#ifdef HAVE_MMX
	if(video->have_mmx)
	{
		video->mpeg3_zigzag_scan_table = mpeg3_zig_zag_scan_mmx;
		video->mpeg3_alternate_scan_table = mpeg3_alternate_scan_mmx;
	}
	else
#endif
	{
		video->mpeg3_zigzag_scan_table = mpeg3_zig_zag_scan_nommx;
		video->mpeg3_alternate_scan_table = mpeg3_alternate_scan_nommx;
	}
}

mpeg3video_t* mpeg3video_allocate_struct(mpeg3_t *file, mpeg3_vtrack_t *track)
{
	int i;
	mpeg3video_t *video = (mpeg3video_t *) memoryAllocate(1, sizeof(mpeg3video_t));
	
#ifdef USE_PTHREADS
	pthread_mutexattr_t mutex_attr;
#endif

	video->file = file;
	video->track = track;
	video->vstream = mpeg3bits_new_stream(file, track->demuxer);
	video->last_number = -1;

/* First frame is all green */
	video->framenum = -1;
	video->have_mmx = file->have_mmx;

	video->percentage_seek = -1;
	video->frame_seek = -1;

	mpeg3video_init_scantables(video);
	mpeg3video_init_output();

#ifdef USE_PTHREADS
	pthread_mutexattr_init(&mutex_attr);
	pthread_mutex_init(&(video->test_lock), &mutex_attr);
	pthread_mutex_init(&(video->slice_lock), &mutex_attr);
#endif
	return video;
}

int mpeg3video_delete_struct(mpeg3video_t *video)
{
	int i;
	mpeg3bits_delete_stream(video->vstream);
#ifdef USE_PTHREADS
	pthread_mutex_destroy(&(video->test_lock));
	pthread_mutex_destroy(&(video->slice_lock));
#endif
	if(video->x_table)
	{
		memoryFree(video->x_table);
		memoryFree(video->y_table);
	}
	if(video->total_slice_decoders)
	{
		for(i = 0; i < video->total_slice_decoders; i++)
			mpeg3_delete_slice_decoder(video->slice_decoders[i]);
	}
	for(i = 0; i < video->slice_buffers_initialized; i++)
		mpeg3_delete_slice_buffer(&(video->slice_buffers[i]));

	memoryFree(video);
}


int mpeg3video_read_frame_backend(mpeg3video_t *video, int skip_bframes)
{
	int result = 0;

	if(mpeg3bits_eof(video->vstream)) result = 1;

	if(!result) result = mpeg3video_get_header(video, 0);

//printf("frame type %d\n", video->pict_type);
/* skip_bframes is the number of bframes we can skip successfully. */
/* This is in case a skipped B-frame is repeated and the second repeat happens */
/* to be a B frame we need. */
	video->skip_bframes = skip_bframes;

	if(!result)
		result = mpeg3video_getpicture(video, video->framenum);

#ifdef HAVE_MMX
	if(video->have_mmx)
		__asm__ __volatile__ ("emms");
#endif

	if(!result)
	{
		video->last_number = video->framenum;
		video->framenum++;
	}
	return result;
}

int* mpeg3video_get_scaletable(int input_w, int output_w)
{
	int *result = (int *) memoryAllocate(1,sizeof(int) * output_w);
	float i;
	float scale = (float)input_w / output_w;
	for(i = 0; i < output_w; i++)
	{
		result[(int)i] = (int)(scale * i);
	}
	return result;
}

/* Get the first frame read. */
int mpeg3video_get_firstframe(mpeg3video_t *video)
{
	int result = 0;
	if(video->framenum < 0)
	{
		video->repeat_count = video->current_repeat = 0;
		result = mpeg3video_read_frame_backend(video, 0);
		mpeg3bits_seek_byte(video->vstream, 0);
		mpeg3video_match_refframes(video);
	}
	return result;
}


/* ======================================================================= */
/*                                    ENTRY POINTS */
/* ======================================================================= */



mpeg3video_t* mpeg3video_new(mpeg3_t *file, mpeg3_vtrack_t *track)
{
	mpeg3video_t *video;
	int result = 0;

	video = mpeg3video_allocate_struct(file, track);
	result = mpeg3video_get_header(video, 1);

	if(!result)
	{
		int hour, minute, second, frame;
		int gop_found;

		mpeg3video_initdecoder(video);
		video->decoder_initted = 1;
		track->width = video->horizontal_size;
		track->height = video->vertical_size;
		track->frame_rate = video->frame_rate;

/* Get the length of the file from an elementary stream */
		if(file->is_video_stream)
		{
/* Load the first GOP */
			mpeg3bits_seek_start(video->vstream);
			result = mpeg3video_next_code(video->vstream, MPEG3_GOP_START_CODE);
			if(!result) mpeg3bits_getbits(video->vstream, 32);
			if(!result) result = mpeg3video_getgophdr(video);

			hour = video->gop_timecode.hour;
			minute = video->gop_timecode.minute;
			second = video->gop_timecode.second;
			frame = video->gop_timecode.frame;
			video->first_frame = (long)(hour * 3600 * video->frame_rate + 
				minute * 60 * video->frame_rate +
				second * video->frame_rate +
				frame);

/* GOPs always have 16 frames */
			video->frames_per_gop = 16;

/* Read the last GOP in the file by seeking backward. */
			mpeg3bits_seek_end(video->vstream);
			mpeg3bits_start_reverse(video->vstream);
			result = mpeg3video_prev_code(video->vstream, MPEG3_GOP_START_CODE);
			mpeg3bits_start_forward(video->vstream);
			mpeg3bits_getbits(video->vstream, 8);
			if(!result) result = mpeg3video_getgophdr(video);

			hour = video->gop_timecode.hour;
			minute = video->gop_timecode.minute;
			second = video->gop_timecode.second;
			frame = video->gop_timecode.frame;

			video->last_frame = (long)(hour * 3600 * video->frame_rate + 
				minute * 60 * video->frame_rate +
				second * video->frame_rate +
				frame);

/* Count number of frames to end */
			while(!result)
			{
				result = mpeg3video_next_code(video->vstream, MPEG3_PICTURE_START_CODE);
				if(!result)
				{
					mpeg3bits_getbyte_noptr(video->vstream);
					video->last_frame++;
				}
			}

			track->total_frames = video->last_frame - video->first_frame + 1;
			mpeg3bits_seek_start(video->vstream);
		}
		else
		{
/* Gross approximation from a multiplexed file. */
			video->first_frame = 0;
			track->total_frames = video->last_frame = 
				(long)(mpeg3demux_length(video->vstream->demuxer) * 
					video->frame_rate);
			video->first_frame = 0;
		}

		video->maxframe = track->total_frames;
		mpeg3bits_seek_start(video->vstream);
	}
	else
	{
		mpeg3video_delete(video);
		video = 0;
	}

	return video;
}

int mpeg3video_delete(mpeg3video_t *video)
{
	if(video->decoder_initted)
	{
		mpeg3video_deletedecoder(video);
	}
	mpeg3video_delete_struct(video);
	return 0;
}

int mpeg3video_set_cpus(mpeg3video_t *video, int cpus)
{
	return 0;
}

int mpeg3video_set_mmx(mpeg3video_t *video, int use_mmx)
{
	video->have_mmx = use_mmx;
	mpeg3video_init_scantables(video);
	return 0;
}

int mpeg3video_seek_percentage(mpeg3video_t *video, double percentage)
{
	video->percentage_seek = percentage;
	return 0;
}

int mpeg3video_previous_frame(mpeg3video_t *video)
{
	if(mpeg3bits_tell_percentage(video->vstream) <= 0) return 1;
	mpeg3bits_start_reverse(video->vstream);
	mpeg3video_prev_code(video->vstream, MPEG3_PICTURE_START_CODE);
	mpeg3bits_getbits_reverse(video->vstream, 32);
	
	if(mpeg3bits_bof(video->vstream)) mpeg3bits_seek_percentage(video->vstream, 0);
	mpeg3bits_start_forward(video->vstream);
	video->repeat_count = 0;
	return 0;
}

int mpeg3video_seek_frame(mpeg3video_t *video, long frame)
{
	video->frame_seek = frame;
	return 0;
}

/* Read all the way up to and including the next picture start code */
int mpeg3video_read_raw(mpeg3video_t *video, unsigned char *output, long *size, long max_size)
{
	unsigned MPEG3_INT32 code = 0;
	mpeg3_bits_t *vstream = video->vstream;

	*size = 0;
	while(code != MPEG3_PICTURE_START_CODE && 
		code != MPEG3_SEQUENCE_END_CODE &&
		*size < max_size && 
		!mpeg3bits_eof(vstream))
	{
		code <<= 8;
		*output = mpeg3bits_getbyte_noptr(vstream);
		code |= *output++;
		(*size)++;
	}
	return mpeg3bits_eof(vstream);
}

int mpeg3video_read_frame(mpeg3video_t *video, 
		long frame_number, 
		unsigned char **output_rows,
		int in_x, 
		int in_y, 
		int in_w, 
		int in_h, 
		int out_w, 
		int out_h, 
		int color_model)
{
	int result = 0;

	video->want_yvu = 0;
	video->output_rows = output_rows;
	video->color_model = color_model;

/* Get scaling tables */
	if(video->out_w != out_w || video->out_h != out_h ||
		video->in_w != in_w || video->in_h != in_h ||
		video->in_x != in_x || video->in_y != in_y)
	{
		if(video->x_table)
		{
			memoryFree(video->x_table);
			memoryFree(video->y_table);
			video->x_table = 0;
			video->y_table = 0;
		}
	}

	video->out_w = out_w;
	video->out_h = out_h;
	video->in_w = in_w;
	video->in_h = in_h;
	video->in_x = in_x;
	video->in_y = in_y;

	if(!video->x_table)
	{
		video->x_table = mpeg3video_get_scaletable(video->in_w, video->out_w);
		video->y_table = mpeg3video_get_scaletable(video->in_h, video->out_h);
	}

	mpeg3video_get_firstframe(video);

	if(!result) result = mpeg3video_seek(video);

	if(!result) result = mpeg3video_read_frame_backend(video, 0);

	if(video->output_src) mpeg3video_present_frame(video);

	video->percentage_seek = -1;
	return result;
}

int mpeg3video_read_yuvframe(mpeg3video_t *video, 
					long frame_number, 
					char *y_output,
					char *u_output,
					char *v_output,
					int in_x,
					int in_y,
					int in_w,
					int in_h)
{
	int result = 0;

	video->want_yvu = 1;
	video->y_output = y_output;
	video->u_output = u_output;
	video->v_output = v_output;
	video->in_x = in_x;
	video->in_y = in_y;
	video->in_w = in_w;
	video->in_h = in_h;

	mpeg3video_get_firstframe(video);

	if(!result) result = mpeg3video_seek(video);

	if(!result) result = mpeg3video_read_frame_backend(video, 0);

	if(video->output_src) mpeg3video_present_frame(video);

	video->want_yvu = 0;
	video->percentage_seek = -1;
	return result;
}
