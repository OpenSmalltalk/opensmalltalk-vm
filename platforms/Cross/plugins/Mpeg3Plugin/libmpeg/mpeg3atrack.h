 /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */
#ifndef MPEG3ATRACK_H
#define MPEG3ATRACK_H

#include "mpeg3demux.h"
#include "mpeg3audio.h"


typedef struct
{
	int channels;
	int sample_rate;
	mpeg3_demuxer_t *demuxer;
	mpeg3audio_t *audio;
	long current_position;
	long total_samples;
} mpeg3_atrack_t;

#endif
