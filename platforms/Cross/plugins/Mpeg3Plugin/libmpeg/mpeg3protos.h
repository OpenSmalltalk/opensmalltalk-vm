#ifndef MPEG3PROTOS_H
#define MPEG3PROTOS_H

#include "mpeg3private.h" /* mpeg3_t */

/* CSS */

mpeg3_css_t* mpeg3_new_css();

/* DEMUX */

mpeg3_demuxer_t* mpeg3_new_demuxer(mpeg3_t *file, int do_audio, int do_video, int stream_id);
void mpeg3_delete_demuxer(mpeg3_demuxer_t *demuxer);
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



/* AUDIO */
#if defined(MPEG3AUDIO_H)
int mpeg3audio_delete(mpeg3audio_t *audio);
int mpeg3audio_seek_percentage(mpeg3audio_t *audio, double percentage);
int mpeg3audio_seek_sample(mpeg3audio_t *audio, long sample);
int mpeg3audio_read_raw(mpeg3audio_t *audio, unsigned char *output, long *size, long max_size);
int mpeg3audio_decode_audio(mpeg3audio_t *audio, float *output_f, short *output_i, int channel, long start_position, long len);
#endif


/* VIDEO */
#if defined(MPEGVIDEO_H)
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
#endif

/* FILESYSTEM */

mpeg3_fs_t* mpeg3_new_fs(char *path,int size);
int mpeg3_delete_fs(mpeg3_fs_t *fs);
int mpeg3io_open_file(mpeg3_fs_t *fs);
int mpeg3io_close_file(mpeg3_fs_t *fs);
int mpeg3io_read_data(unsigned char *buffer, long bytes, mpeg3_fs_t *fs);
int mpeg3io_end_of_file(mpeg3_fs_t *fs);
int mpeg3io_scanf (mpeg3_fs_t *fs,char *format, void * string1, void * string2);
int mpeg3io_scanf5 (mpeg3_fs_t *fs,char *format, void * string1, void * string2, void * string3, void * string4, void * string5);

/* BITSTREAM */
mpeg3_bits_t* mpeg3bits_new_stream(mpeg3_t *file, mpeg3_demuxer_t *demuxer);
unsigned int mpeg3bits_getbits(mpeg3_bits_t* stream, int n);

/* Other prototypes added eem '19/7/30, extracted using cproto */
/* changesForSqueak.c */
int mpeg3_generate_toc_for_Squeak(mpeg3_t *file, int timecode_search, int print_streams, char *buffer, int bufferSize);
int mpeg3demux_create_title_for_Squeak(mpeg3_demuxer_t *demuxer, int timecode_search, char *buffer, int buffer_size);
int mpeg3demux_print_streams_for_Squeak(mpeg3_demuxer_t *demuxer, char *buffer, int buffer_size);
int mpeg3_delete_css(mpeg3_css_t *css);
int mpeg3_get_keys(mpeg3_css_t *css, char *path);
int mpeg3_decrypt_packet(mpeg3_css_t *css, unsigned char *sector);
int IsImageName(char *name);
/* libmpeg3.c */
mpeg3_t *mpeg3_new(char *path, int size);
void mpeg3_delete(mpeg3_t *file);
int mpeg3_check_sig(char *path);
mpeg3_t *mpeg3_open_copy(char *path, mpeg3_t *old_file, int size);
mpeg3_t *mpeg3_open(char *path, int size);
int mpeg3_close(mpeg3_t *file);
int mpeg3_set_cpus(mpeg3_t *file, int cpus);
int mpeg3_set_mmx(mpeg3_t *file, int use_mmx);
int mpeg3_generate_toc(FILE *output, char *path, int timecode_search, int print_streams);
int mpeg3_read_toc(mpeg3_t *file);
int mpeg3_has_audio(mpeg3_t *file);
int mpeg3_total_astreams(mpeg3_t *file);
int mpeg3_audio_channels(mpeg3_t *file, int stream);
int mpeg3_sample_rate(mpeg3_t *file, int stream);
long mpeg3_get_sample(mpeg3_t *file, int stream);
int mpeg3_set_sample(mpeg3_t *file, long sample, int stream);
long mpeg3_audio_samples(mpeg3_t *file, int stream);
int mpeg3_has_video(mpeg3_t *file);
int mpeg3_total_vstreams(mpeg3_t *file);
int mpeg3_video_width(mpeg3_t *file, int stream);
int mpeg3_video_height(mpeg3_t *file, int stream);
float mpeg3_frame_rate(mpeg3_t *file, int stream);
long mpeg3_video_frames(mpeg3_t *file, int stream);
long mpeg3_get_frame(mpeg3_t *file, int stream);
int mpeg3_set_frame(mpeg3_t *file, long frame, int stream);
int mpeg3_seek_percentage(mpeg3_t *file, double percentage);
int mpeg3_previous_frame(mpeg3_t *file, int stream);
double mpeg3_tell_percentage(mpeg3_t *file);
double mpeg3_get_time(mpeg3_t *file);
int mpeg3_end_of_audio(mpeg3_t *file, int stream);
int mpeg3_end_of_video(mpeg3_t *file, int stream);
int mpeg3_read_frame(mpeg3_t *file, unsigned char **output_rows, int in_x, int in_y, int in_w, int in_h, int out_w, int out_h, int color_model, int stream);
int mpeg3_drop_frames(mpeg3_t *file, long frames, int stream);
int mpeg3_read_yuvframe(mpeg3_t *file, char *y_output, char *u_output, char *v_output, int in_x, int in_y, int in_w, int in_h, int stream);
int mpeg3_read_audio(mpeg3_t *file, float *output_f, short *output_i, int channel, long samples, int stream);
int mpeg3_reread_audio(mpeg3_t *file, float *output_f, short *output_i, int channel, long samples, int stream);
int mpeg3_read_audio_chunk(mpeg3_t *file, unsigned char *output, long *size, long max_size, int stream);
int mpeg3_read_video_chunk(mpeg3_t *file, unsigned char *output, long *size, long max_size, int stream);
/* mpeg3atrack.c */
/* mpeg3demux.c */
unsigned char mpeg3packet_read_char(mpeg3_demuxer_t *demuxer);
int mpeg3_get_adaptation_field(mpeg3_demuxer_t *demuxer);
int mpeg3_get_program_association_table(mpeg3_demuxer_t *demuxer);
int mpeg3packet_get_data_buffer(mpeg3_demuxer_t *demuxer);
int mpeg3_get_pes_packet_header(mpeg3_demuxer_t *demuxer, unsigned long *pts, unsigned long *dts);
int get_unknown_data(mpeg3_demuxer_t *demuxer);
int mpeg3_get_pes_packet_data(mpeg3_demuxer_t *demuxer, unsigned int stream_id);
int mpeg3_get_pes_packet(mpeg3_demuxer_t *demuxer);
int mpeg3_get_payload(mpeg3_demuxer_t *demuxer);
int mpeg3_read_transport(mpeg3_demuxer_t *demuxer);
int mpeg3_get_system_header(mpeg3_demuxer_t *demuxer);
unsigned long mpeg3_get_timestamp(mpeg3_demuxer_t *demuxer);
int mpeg3_get_pack_header(mpeg3_demuxer_t *demuxer, unsigned int *header);
int mpeg3_get_ps_pes_packet(mpeg3_demuxer_t *demuxer, unsigned int *header);
int mpeg3_read_program(mpeg3_demuxer_t *demuxer);
double mpeg3_lookup_time_offset(mpeg3_demuxer_t *demuxer, long byte);
int mpeg3_advance_timecode(mpeg3_demuxer_t *demuxer, int reverse);
int mpeg3_read_next_packet(mpeg3_demuxer_t *demuxer);
int mpeg3_read_prev_packet(mpeg3_demuxer_t *demuxer);
unsigned int mpeg3demux_read_char_packet(mpeg3_demuxer_t *demuxer);
unsigned int mpeg3demux_read_prev_char_packet(mpeg3_demuxer_t *demuxer);
mpeg3demux_timecode_t *mpeg3_append_timecode(mpeg3_demuxer_t *demuxer, mpeg3_title_t *title, long prev_byte, double prev_time, long next_byte, double next_time, int dont_store);
mpeg3demux_timecode_t *mpeg3demux_next_timecode(mpeg3_demuxer_t *demuxer, int *current_title, int *current_timecode, int current_program);
mpeg3demux_timecode_t *mpeg3demux_prev_timecode(mpeg3_demuxer_t *demuxer, int *current_title, int *current_timecode, int current_program);
int mpeg3demux_open_title(mpeg3_demuxer_t *demuxer, int title_number);
int mpeg3demux_assign_programs(mpeg3_demuxer_t *demuxer);
int mpeg3demux_create_title(mpeg3_demuxer_t *demuxer, int timecode_search, FILE *toc);
int mpeg3demux_print_timecodes(mpeg3_title_t *title, FILE *output);
int mpeg3demux_read_titles(mpeg3_demuxer_t *demuxer);
int mpeg3demux_copy_titles(mpeg3_demuxer_t *dst, mpeg3_demuxer_t *src);
int mpeg3demux_print_streams(mpeg3_demuxer_t *demuxer, FILE *toc);
int mpeg3demux_seek_byte(mpeg3_demuxer_t *demuxer, long byte);
int mpeg3demux_seek_time(mpeg3_demuxer_t *demuxer, double new_time);
int mpeg3demux_seek_percentage(mpeg3_demuxer_t *demuxer, double percentage);
long mpeg3demuxer_total_bytes(mpeg3_demuxer_t *demuxer);
/* mpeg3io.c */
int mpeg3_copy_fs(mpeg3_fs_t *dst, mpeg3_fs_t *src);
long mpeg3io_get_total_bytes(mpeg3_fs_t *fs);
int mpeg3io_get_id3v2_size(mpeg3_fs_t *fs);
int mpeg3io_device(char *path, char *device);
int mpeg3io_seek(mpeg3_fs_t *fs, long byte);
int mpeg3io_seek_relative(mpeg3_fs_t *fs, long bytes);
int mpeg3io_scanf(mpeg3_fs_t *fs, char *format, void *string1, void *string2);
int mpeg3io_scanf5(mpeg3_fs_t *fs, char *format, void *string1, void *string2, void *string3, void *string4, void *string5);
/* mpeg3title.c */
int mpeg3_delete_title(mpeg3_title_t *title);
void mpeg3_copy_title(mpeg3_title_t *dst, mpeg3_title_t *src);
void mpeg3_dump_title(mpeg3_title_t *title);
/* video/mmxtest.c */
int mpeg3_mmx_test(void);
#endif
