#include "libmpeg3.h"
#include <stdlib.h>

#define BUFSIZE 10000000

int main(int argc, char *argv[])
{
	mpeg3_t *file;
	int i, result = 0;
	unsigned char *output, **output_rows;
	float *audio_output_f;
	short *audio_output_i;
	long total_samples = 0;

	if(argc < 2)
	{
		printf("Need an MPEG stream.\n");
		exit(1);
	}

	file = mpeg3_open(argv[1]);
	if(file)
	{
		fprintf(stderr, "MMX supported %d\n", file->have_mmx);
		fprintf(stderr, "Audio streams: %d\n", mpeg3_total_astreams(file));
		for(i = 0; i < mpeg3_total_astreams(file); i++)
		{
			fprintf(stderr, "  Stream %d: channels %d sample rate %d total samples %ld\n", 
				i, 
				mpeg3_audio_channels(file, i), 
				mpeg3_sample_rate(file, i),
				mpeg3_audio_samples(file, i));
		}
		fprintf(stderr, "Video streams: %d\n", mpeg3_total_vstreams(file));
		for(i = 0; i < mpeg3_total_vstreams(file); i++)
		{
			fprintf(stderr, "  Stream %d: width %d height %d frame rate %0.3f total frames %ld\n", 
				i, 
				mpeg3_video_width(file, i), 
				mpeg3_video_height(file, i), 
				mpeg3_frame_rate(file, i),
				mpeg3_video_frames(file, i));
		}

		mpeg3_set_cpus(file, 1);
/* 		audio_output_f = malloc(BUFSIZE * sizeof(float)); */
		audio_output_i = malloc(BUFSIZE * sizeof(short));
/*		mpeg3_set_sample(file, 11229518, 0); */
/*  		result = mpeg3_read_audio(file, audio_output_f, 0, 0, BUFSIZE, 0); */
//		result = mpeg3_read_audio(file, 0, audio_output_i, 1, BUFSIZE, 0);
 		fwrite(audio_output_i, BUFSIZE, 1, stdout);

  		output = malloc(mpeg3_video_width(file, 0) * mpeg3_video_height(file, 0) * 3 + 4);
  		output_rows = malloc(sizeof(unsigned char*) * mpeg3_video_height(file, 0));
  		for(i = 0; i < mpeg3_video_height(file, 0); i++)
  			output_rows[i] = &output[i * mpeg3_video_width(file, 0) * 3];
// 		mpeg3_set_frame(file, 1000, 0);
 		result = mpeg3_read_frame(file, 
 					output_rows, 
 					0, 
 					0, 
 					mpeg3_video_width(file, 0), 
					mpeg3_video_height(file, 0), 
 					mpeg3_video_width(file, 0), 
 					mpeg3_video_height(file, 0), 
					MPEG3_RGB888, 
 					0);

		mpeg3_close(file);
	}
	return 0;
}
