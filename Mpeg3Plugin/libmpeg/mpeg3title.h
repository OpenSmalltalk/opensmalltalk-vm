#ifndef MPEG3TITLE_H
#define MPEG3TITLE_H

#include "mpeg3io.h"

typedef struct
{
	long start_byte;
	double start_time;
	double absolute_start_time;
	double absolute_end_time;
	long end_byte;
	double end_time;
	int program;
} mpeg3demux_timecode_t;

typedef struct
{
	void *file;
	mpeg3_fs_t *fs;
	long total_bytes;     /* Total bytes in file.  Critical for seeking and length. */
/* Timecode table */
	mpeg3demux_timecode_t *timecode_table;
	long timecode_table_size;    /* Number of entries */
	long timecode_table_allocation;    /* Number of available slots */
} mpeg3_title_t;

#endif
