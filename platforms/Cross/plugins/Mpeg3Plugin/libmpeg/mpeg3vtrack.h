 /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */
#ifndef MPEG3_VTRACK_H
#define MPEG3_VTRACK_H

#include "mpeg3demux.h"
#include "mpeg3video.h"

typedef struct
{
	int width;
	int height;
	float frame_rate;
	mpeg3_demuxer_t *demuxer;
	mpeg3video_t *video;
	long current_position;  /* Number of next frame to be played */
	long total_frames;     /* Total frames in the file */
} mpeg3_vtrack_t;

mpeg3video_t* mpeg3video_new(mpeg3_t *file, mpeg3_vtrack_t *track);
mpeg3_vtrack_t* mpeg3_new_vtrack(mpeg3_t *file, int stream_id, mpeg3_demuxer_t *demuxer);
void mpeg3_delete_vtrack(mpeg3_t *file, mpeg3_vtrack_t *vtrack);

#endif
