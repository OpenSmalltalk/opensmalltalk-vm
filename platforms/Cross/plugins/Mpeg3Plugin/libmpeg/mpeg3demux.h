#ifndef MPEG3DEMUX_H
#define MPEG3DEMUX_H

#include "mpeg3title.h"
#include <stdio.h>

typedef struct
{
	void* file;
/* Data consisting of the multiplexed packet */
	unsigned char *raw_data;
	long raw_offset;
	int raw_size;
	long packet_size;
/* Only one is on depending on which track owns the demultiplexer. */
	int do_audio;
	int do_video;
/* Data consisting of the elementary stream */
	unsigned char *data_buffer;
	long data_size;
	long data_position;
	long data_allocated;
/* Remember when the file descriptor is at the beginning of the packet just read. */
	int reverse;
/* Set to 1 when eof or attempt to read before beginning */
	int error_flag;
/* Temp variables for returning */
	unsigned char next_char;
/* Correction factor for time discontinuity */
	double time_offset;
	int generating_timecode;

/* Titles */
	mpeg3_title_t *titles[MPEG3_MAX_STREAMS];
	int total_titles;
	int current_title;

/* Tables of every stream ID encountered */
	int astream_table[MPEG3_MAX_STREAMS];  /* macro of audio format if audio  */
	int vstream_table[MPEG3_MAX_STREAMS];  /* 1 if video */

/* Programs */
	int total_programs;
	int current_program;

/* Timecode in the current title */
	int current_timecode;

/* Byte position in the current title */
	long current_byte;

	int transport_error_indicator;
	int payload_unit_start_indicator;
	int pid;
	int transport_scrambling_control;
	int adaptation_field_control;
	int continuity_counter;
	int is_padding;
	int pid_table[MPEG3_PIDMAX];
	int continuity_counters[MPEG3_PIDMAX];
	int total_pids;
	int adaptation_fields;
	double time;           /* Time in seconds */
	int audio_pid;
	int video_pid;
	int astream;     /* Video stream ID being decoded.  -1 = select first ID in stream */
	int vstream;     /* Audio stream ID being decoded.  -1 = select first ID in stream */
	int aformat;      /* format of the audio derived from multiplexing codes */
	long program_association_tables;
	int table_id;
	int section_length;
	int transport_stream_id;
	long pes_packets;
	double pes_audio_time;  /* Presentation Time stamps */
	double pes_video_time;  /* Presentation Time stamps */
} mpeg3_demuxer_t;

/* ========================================================================= */
/*                             Entry points */
/* ========================================================================= */

#define mpeg3demux_error(demuxer) (((mpeg3_demuxer_t *)(demuxer))->error_flag)

#define mpeg3demux_time_offset(demuxer) (((mpeg3_demuxer_t *)(demuxer))->time_offset)

#define mpeg3demux_current_time(demuxer) (((mpeg3_demuxer_t *)(demuxer))->time + ((mpeg3_demuxer_t *)(demuxer))->time_offset)

#define mpeg3demux_read_char(demuxer) \
    ((((mpeg3_demuxer_t *)(demuxer))->data_position < ((mpeg3_demuxer_t *)(demuxer))->data_size) ? \
    ((mpeg3_demuxer_t *)(demuxer))->data_buffer[((mpeg3_demuxer_t *)(demuxer))->data_position++] : \
    mpeg3demux_read_char_packet(demuxer))

#define mpeg3demux_read_prev_char(demuxer) \
    ((((mpeg3_demuxer_t *)(demuxer))->data_position != 0) ? \
    ((mpeg3_demuxer_t *)(demuxer))->data_buffer[((mpeg3_demuxer_t *)(demuxer))->data_position--] : \
    mpeg3demux_read_prev_char_packet(demuxer))


#endif
