#ifndef MPEG3PROTOS_H
#define MPEG3PROTOS_H

/* CSS */

mpeg3_css_t* mpeg3_new_css();

/* DEMUX */

mpeg3_demuxer_t* mpeg3_new_demuxer(mpeg3_t *file, int do_audio, int do_video, int stream_id);
int mpeg3_delete_demuxer(mpeg3_demuxer_t *demuxer);
int mpeg3demux_read_data(mpeg3_demuxer_t *demuxer, unsigned char *output, long size);
unsigned int mpeg3demux_read_int32(mpeg3_demuxer_t *demuxer);
unsigned int mpeg3demux_read_int24(mpeg3_demuxer_t *demuxer);
unsigned int mpeg3demux_read_int16(mpeg3_demuxer_t *demuxer);
double mpeg3demux_length(mpeg3_demuxer_t *demuxer);
mpeg3_demuxer_t* mpeg3_get_demuxer(mpeg3_t *file);
long mpeg3demux_tell(mpeg3_demuxer_t *demuxer);
double mpeg3demux_tell_percentage(mpeg3_demuxer_t *demuxer);
double mpeg3demux_get_time(mpeg3_demuxer_t *demuxer);
int mpeg3demux_eof(mpeg3_demuxer_t *demuxer);
int mpeg3demux_bof(mpeg3_demuxer_t *demuxer);

/* TITLE */

mpeg3_title_t* mpeg3_new_title(mpeg3_t *file, char *path);


/* ATRACK */

mpeg3_atrack_t* mpeg3_new_atrack(mpeg3_t *file, int stream_id, int is_ac3, mpeg3_demuxer_t *demuxer);
int mpeg3_delete_atrack(mpeg3_t *file, mpeg3_atrack_t *atrack);

/* VTRACK */

mpeg3_vtrack_t* mpeg3_new_vtrack(mpeg3_t *file, int stream_id, mpeg3_demuxer_t *demuxer);
int mpeg3_delete_vtrack(mpeg3_t *file, mpeg3_vtrack_t *vtrack);

/* AUDIO */
mpeg3audio_t* mpeg3audio_new(mpeg3_t *file, mpeg3_atrack_t *track, int is_ac3);
int mpeg3audio_delete(mpeg3audio_t *audio);


/* VIDEO */
mpeg3video_t* mpeg3video_new(mpeg3_t *file, mpeg3_vtrack_t *track);
int mpeg3video_delete(mpeg3video_t *video);
int mpeg3video_read_frame(mpeg3video_t *video, 
		long frame_number, 
		unsigned char **output_rows,
		int in_x, 
		int in_y, 
		int in_w, 
		int in_h, 
		int out_w, 
		int out_h, 
		int color_model);

/* FILESYSTEM */

mpeg3_fs_t* mpeg3_new_fs(char *path,int size);
int mpeg3_delete_fs(mpeg3_fs_t *fs);
int mpeg3io_open_file(mpeg3_fs_t *fs);
int mpeg3io_close_file(mpeg3_fs_t *fs);
int mpeg3io_read_data(unsigned char *buffer, long bytes, mpeg3_fs_t *fs);
int mpeg3io_end_of_file(mpeg3_fs_t *fs);
int mpeg3io_scanf (mpeg3_fs_t *fs,char *format, void * string1, void * string2);
int mpeg3io_scanf5 (mpeg3_fs_t *fs,char *format, void * string1, void * string2, void * string3, void * string4, void * string5);
int mpeg3io_fgetc(mpeg3_fs_t *fs);

/* BITSTREAM */
mpeg3_bits_t* mpeg3bits_new_stream(mpeg3_t *file, mpeg3_demuxer_t *demuxer);
unsigned int mpeg3bits_getbits(mpeg3_bits_t* stream, int n);


#endif
