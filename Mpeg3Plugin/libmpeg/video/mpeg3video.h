 /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */
#ifndef MPEGVIDEO_H
#define MPEGVIDEO_H

#include "bitstream.h"
#include "mpeg3private.inc"
#include "timecode.h"

#include "idct.h"
#include "slice.h"

/* zig-zag scan */
extern unsigned char mpeg3_zig_zag_scan_nommx[64];
extern unsigned char mpeg3_zig_zag_scan_mmx[64];

/* alternate scan */
extern unsigned char mpeg3_alternate_scan_nommx[64];
extern unsigned char mpeg3_alternate_scan_mmx[64];

/* default intra quantization matrix */
extern unsigned char mpeg3_default_intra_quantizer_matrix[64];

/* Frame rate table must agree with the one in the encoder */
extern double mpeg3_frame_rate_table[16];

/* non-linear quantization coefficient table */
extern unsigned char mpeg3_non_linear_mquant_table[32];

#define CHROMA420     1     /* chroma_format */
#define CHROMA422     2
#define CHROMA444     3

#define TOP_FIELD     1     /* picture structure */
#define BOTTOM_FIELD  2
#define FRAME_PICTURE 3

#define SEQ_ID        1     /* extension start code IDs */
#define DISP_ID       2
#define QUANT_ID      3
#define SEQSCAL_ID    5
#define PANSCAN_ID    7
#define CODING_ID     8
#define SPATSCAL_ID   9
#define TEMPSCAL_ID  10

#define MPERROR (-1)

#define SC_NONE       0   /* scalable_mode */
#define SC_DP         1
#define SC_SPAT       2
#define SC_SNR        3
#define SC_TEMP       4

#define I_TYPE        1     /* picture coding type */
#define P_TYPE        2
#define B_TYPE        3
#define D_TYPE        4

#define MB_INTRA      1 	/* macroblock type */
#define MB_PATTERN    2
#define MB_BACKWARD   4
#define MB_FORWARD    8
#define MB_QUANT      16
#define MB_WEIGHT     32
#define MB_CLASS4     64

#define MC_FIELD      1     /* motion_type */
#define MC_FRAME      2
#define MC_16X8       2
#define MC_DMV        3

#define MV_FIELD      0     /* mv_format */
#define MV_FRAME      1

#define CLIP(x)  ((x) >= 0 ? ((x) < 255 ? (x) : 255) : 0)

/* Statically allocate as little as possible so a fake video struct */
/* can be used for reading the GOP headers. */

typedef struct
{
	void* file;
	void* track;

/* ================================= Seeking variables ========================= */
	mpeg3_bits_t *vstream;
	int decoder_initted;
	unsigned char **output_rows;     /* Output frame buffer supplied by user */
	int in_x, in_y, in_w, in_h, out_w, out_h; /* Output dimensions */
	int *x_table, *y_table;          /* Location of every output pixel in the input */
	int color_model;
	int want_yvu;                    /* Want to return a YUV frame */
	char *y_output, *u_output, *v_output; /* Output pointers for a YUV frame */

	mpeg3_slice_t slice_decoders[MPEG3_MAX_CPUS];  /* One slice decoder for every CPU */
	int total_slice_decoders;                       /* Total slice decoders in use */
	mpeg3_slice_buffer_t slice_buffers[MPEG3_MAX_CPUS];   /* Buffers for holding the slice data */
	int total_slice_buffers;         /* Total buffers in the array to be decompressed */
	int slice_buffers_initialized;     /* Total buffers initialized in the array */
#ifdef USE_PTHREADS
	pthread_mutex_t slice_lock;      /* Lock slice array while getting the next buffer */
	pthread_mutex_t test_lock;
#endif
	int blockreadsize;
	long maxframe;         /* Max value of frame num to read */
	double percentage_seek;   /* Perform a percentage seek before the next frame is read */
	int frame_seek;        /* Perform a frame seek before the next frame is read */
	long framenum;         /* Number of the next frame to be decoded */
	long last_number;       /* Last framenum rendered */
	int found_seqhdr;
	long bitrate;
	mpeg3_timecode_t gop_timecode;     /* Timecode for the last GOP header read. */

/* These are only available from elementary streams. */
	long frames_per_gop;       /* Frames per GOP after the first GOP. */
	long first_gop_frames;     /* Frames in the first GOP. */
	long first_frame;     /* Number of first frame stored in timecode */
	long last_frame;      /* Last frame in file */

/* ================================= Compression variables ===================== */
/* Malloced frame buffers.  2 refframes are swapped in and out. */
/* while only 1 auxframe is used. */
	unsigned char *yuv_buffer[5];  /* Make YVU buffers contiguous for all frames */
	unsigned char *oldrefframe[3], *refframe[3], *auxframe[3];
	unsigned char *llframe0[3], *llframe1[3];
	unsigned char *mpeg3_zigzag_scan_table;
	unsigned char *mpeg3_alternate_scan_table;
// Source for the next frame presentation
	unsigned char **output_src;
/* Pointers to frame buffers. */
	unsigned char *newframe[3];
	int horizontal_size, vertical_size, mb_width, mb_height;
	int coded_picture_width,  coded_picture_height;
	int chroma_format, chrom_width, chrom_height, blk_cnt;
	int pict_type;
	int forw_r_size, back_r_size, full_forw, full_back;
	int prog_seq, prog_frame;
	int h_forw_r_size, v_forw_r_size, h_back_r_size, v_back_r_size;
	int dc_prec, pict_struct, topfirst, frame_pred_dct, conceal_mv;
	int intravlc;
	int repeatfirst;
	int repeat_count;    /* Number of times to repeat the current frame * 100 since floating point is impossible in MMX */
	int current_repeat;  /* Number of times the current frame has been repeated * 100 */
	int secondfield;
	int skip_bframes;
	int stwc_table_index, llw, llh, hm, hn, vm, vn;
	int lltempref, llx0, lly0, llprog_frame, llfieldsel;
	int matrix_coefficients;
	int framerate_code;
	float frame_rate;
	long *cr_to_r, *cr_to_g, *cb_to_g, *cb_to_b;
	long *cr_to_r_ptr, *cr_to_g_ptr, *cb_to_g_ptr, *cb_to_b_ptr;
	int have_mmx;
	int intra_quantizer_matrix[64], non_intra_quantizer_matrix[64];
	int chroma_intra_quantizer_matrix[64], chroma_non_intra_quantizer_matrix[64];
	int mpeg2;
	int qscale_type, altscan;      /* picture coding extension */
	int pict_scal;                /* picture spatial scalable extension */
	int scalable_mode;            /* sequence scalable extension */
} mpeg3video_t;

#endif
