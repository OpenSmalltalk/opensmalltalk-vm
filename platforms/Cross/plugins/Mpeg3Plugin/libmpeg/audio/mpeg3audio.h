 /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */

#ifndef MPEG3AUDIO_H
#define MPEG3AUDIO_H

#include "ac3.h"
#include "bitstream.h"
#ifndef M_PI
#define M_PI		3.14159265358979323846
#define M_SQRT2		1.41421356237309504880
#endif

#define MAXFRAMESIZE 1792
#define HDRCMPMASK 0xfffffd00
#define SBLIMIT 32
#define SSLIMIT 18
#define SCALE_BLOCK 12
#define MPEG3AUDIO_PADDING 1024

/* Values for mode */
#define MPG_MD_STEREO			0
#define MPG_MD_JOINT_STEREO 	1
#define MPG_MD_DUAL_CHANNEL 	2
#define MPG_MD_MONO 			3

/* IMDCT variables */
typedef struct
{
	float real;
	float imag;
} mpeg3_complex_t;

#define AC3_N 512

struct al_table 
{
	short bits;
	short d;
};

typedef struct
{
	void* file;
	void* track;
	mpeg3_bits_t *astream;

/* In order of importance */
	int format;               /* format of audio */
	int layer;                /* layer if mpeg */
	int channels;
	long outscale;
	long framenum;
	long prev_framesize;
	long framesize;           /* For mp3 current framesize without header.  For AC3 current framesize with header. */
	float avg_framesize;      /* Includes the 4 byte header */
	float *pcm_sample;        /* Interlaced output from synthesizer in floats */
	int pcm_point;            /* Float offset in pcm_sample to write to */
	long pcm_position;        /* Sample start of pcm_samples in file */
	long pcm_size;            /* Number of pcm samples in the buffer */
	long pcm_allocated;       /* Allocated number of samples in pcm_samples */
	int sample_seek;
	double percentage_seek;
	unsigned long oldhead;
	unsigned long newhead;
	unsigned long firsthead;
	int bsnum;
	int lsf;
	int mpeg35;
	int sampling_frequency_code;
	int bitrate_index;
	int bitrate;
	int samples_per_frame;
	int padding;
	int extension;
	int mode;
	int mode_ext;
	int copyright;
	int original;
	int emphasis;
	int error_protection;

/* Back step buffers for mp3 */
	unsigned char bsspace[2][MAXFRAMESIZE + 512]; /* MAXFRAMESIZE */
	unsigned char *bsbuf, *bsbufold;
	long ssize;
	int init;
	int single;
    struct al_table *alloc;
    int II_sblimit;
    int jsbound;
	int bo;                      /* Static variable in synthesizer */

/* MP3 Static arrays here */
	float synth_stereo_buffs[2][2][0x110];
	float synth_mono_buff[64];
	unsigned int layer2_scfsi_buf[64];

	float mp3_block[2][2][SBLIMIT * SSLIMIT];
	int mp3_blc[2];

/* AC3 specific stuff.  AC3 also shares objects with MPEG */
	unsigned int ac3_framesize_code;
	mpeg3_ac3bsi_t ac3_bsi;
	mpeg3_ac3audblk_t ac3_audblk;
	mpeg3_ac3_bitallocation_t ac3_bit_allocation;
	mpeg3_ac3_mantissa_t ac3_mantissa;
	mpeg3_complex_t ac3_imdct_buf[AC3_N / 4];

/* Delay buffer for DCT interleaving */
	float ac3_delay[6][AC3_N / 2];
/* Twiddle factor LUT */
	mpeg3_complex_t *ac3_w[7];
	mpeg3_complex_t ac3_w_1[1];
	mpeg3_complex_t ac3_w_2[2];
	mpeg3_complex_t ac3_w_4[4];
	mpeg3_complex_t ac3_w_8[8];
	mpeg3_complex_t ac3_w_16[16];
	mpeg3_complex_t ac3_w_32[32];
	mpeg3_complex_t ac3_w_64[64];
	int ac3_lfsr_state;
	unsigned char ac3_buffer[MAX_AC3_FRAMESIZE];
	mpeg3ac3_stream_samples_t ac3_samples;
} mpeg3audio_t;


/* dct.c */
int mpeg3audio_dct64_1(float *out0, float *out1, float *b1, float *b2, float *samples);
int mpeg3audio_dct64(float *a, float *b, float *c);
int mpeg3audio_dct36(float *inbuf, float *o1, float *o2, float *wintab, float *tsbuf);
int mpeg3audio_dct12(float *in, float *rawout1, float *rawout2, register float *wi, register float *ts);
int mpeg3audio_imdct_init(mpeg3audio_t *audio);
/* header.c */
int mpeg3audio_prev_header(mpeg3audio_t *audio);
int mpeg3audio_read_header(mpeg3audio_t *audio);
/* layer2.c */
int mpeg3audio_dolayer2(mpeg3audio_t *audio);
/* layer3.c */
int mpeg3audio_read_layer3_frame(mpeg3audio_t *audio);
int mpeg3audio_dolayer3(mpeg3audio_t *audio);
/* mpeg3audio.c */
int mpeg3audio_replace_buffer(mpeg3audio_t *audio, long new_allocation);
int mpeg3audio_seek_percentage(mpeg3audio_t *audio, double percentage);
int mpeg3audio_seek_sample(mpeg3audio_t *audio, long sample);
int mpeg3audio_read_raw(mpeg3audio_t *audio, unsigned char *output, long *size, long max_size);
int mpeg3audio_decode_audio(mpeg3audio_t *audio, float *output_f, short *output_i, int channel, long start_position, long len);
/* pcm.c */
int mpeg3audio_read_pcm_header(mpeg3audio_t *audio);
int mpeg3audio_do_pcm(mpeg3audio_t *audio);
/* synthesizers.c */
int mpeg3audio_synth_stereo(mpeg3audio_t *audio, float *bandPtr, int channel, float *out, int *pnt);
int mpeg3audio_synth_mono(mpeg3audio_t *audio, float *bandPtr, float *samples, int *pnt);
int mpeg3audio_reset_synths(mpeg3audio_t *audio);
/* tables.c */
int mpeg3audio_new_decode_tables(mpeg3audio_t *audio);

#endif /* MPEG3AUDIO_H */
