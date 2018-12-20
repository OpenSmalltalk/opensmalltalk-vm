/*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 *
 * Concatenate elementary streams */

#include "libmpeg3.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MPEG3_SEQUENCE_START_CODE        0x000001b3
#define BUFFER_SIZE            1000000

int main(int argc, char *argv[])
{
	char inpath[1024];
	mpeg3_t *in;
	int current_file, current_output_file = 0, i;
	unsigned int bits;
	unsigned char *buffer;
	long output_size;
	int result = 0;
	long total_frames = 0;
	int do_audio = 0, do_video = 0;
	int stream = 0;

	if(argc < 2)
	{
		fprintf(stderr, "Concatenate elementary streams or demultiplex a program stream.\n"
			"Usage: mpeg3cat -[av0123456789] <infile> [infile...] > <outfile>\n\n"
			"Example: Concatenate 2 video files: mpeg3cat xena1.m2v xena2.m2v > xena.m2v\n"
			"         Extract audio stream 0: mpeg3cat -a0 xena.vob > war_cry.ac3\n");
		exit(1);
	}

	for(i = 1; i < argc; i++)
	{
		if(argv[i][0] == '-')
		{
			if(argv[i][1] != 'a' && argv[i][1] != 'v')
			{
				fprintf(stderr, "invalid option %s\n", argv[i]);
			}
			else
			{
				if(argv[i][1] == 'a') do_audio = 1;
				else
				if(argv[i][1] == 'v') do_video = 1;
				
				if(argv[i][2] != 0)
				{
					stream = argv[i][2] - 48;
				}
			}
		}
	}

	buffer = (unsigned char *) malloc(BUFFER_SIZE);

	for(current_file = 1; current_file < argc; current_file++)
	{
		if(argv[current_file][0] == '-') continue;

		strcpy(inpath, argv[current_file]);
		if(!(in = mpeg3_open(inpath)))
		{
			fprintf(stderr, "Skipping %s\n", inpath);
			continue;
		}

		if((mpeg3_has_audio(in) && in->is_audio_stream) || 
			(do_audio && !in->is_audio_stream && !in->is_video_stream))
		{
			do_audio = 1;
/* Add audio stream to end */
			while(!mpeg3_read_audio_chunk(in, buffer, 
				&output_size, 
				BUFFER_SIZE,
				stream))
			{
				result = !fwrite(buffer, output_size, 1, stdout);
				if(result)
				{
					perror("fwrite audio chunk");
					break;
				}
			}
		}
		else
		if((mpeg3_has_video(in) && in->is_video_stream) ||
			(do_video && !in->is_video_stream && !in->is_audio_stream))
		{
/* Add video stream to end */
			int hour, minute, second, frame;
			long gop_frame;
			unsigned long code;
			float carry;
			int i, offset;
			
			do_video = 1;
			while(!mpeg3_read_video_chunk(in, 
				buffer, 
				&output_size, 
				BUFFER_SIZE,
				stream) &&
				output_size >= 4)
			{
				code = (unsigned long)buffer[output_size - 4] << 24; 
				code |= (unsigned long)buffer[output_size - 3] << 16; 
				code |= (unsigned long)buffer[output_size - 2] << 8; 
				code |= (unsigned long)buffer[output_size - 1]; 

/* Got a frame at the end of this buffer. */
				if(code == MPEG3_PICTURE_START_CODE)
				{
					total_frames++;
				}
				else
				if(code == MPEG3_SEQUENCE_END_CODE)
				{
/* Got a sequence end code at the end of this buffer. */
					output_size -= 4;
				}

				code = (unsigned long)buffer[0] << 24;
				code |= (unsigned long)buffer[1] << 16;
				code |= (unsigned long)buffer[2] << 8;
				code |= buffer[3];

				i = 0;
				offset = 0;
				if(code == MPEG3_SEQUENCE_START_CODE && current_output_file > 0)
				{
/* Skip the sequence start code */
					i += 4;
					while(i < output_size && 
						code != MPEG3_GOP_START_CODE)
					{
						code <<= 8;
						code |= buffer[i++];
					}
					i -= 4;
					offset = i;
				}

/* Search for GOP header to fix */
				code = (unsigned long)buffer[i++] << 24;
				code |= (unsigned long)buffer[i++] << 16;
				code |= (unsigned long)buffer[i++] << 8;
				code |= buffer[i++];
				while(i < output_size &&
					code != MPEG3_GOP_START_CODE)
				{
					code <<= 8;
					code |= buffer[i++];
				}

				if(code == MPEG3_GOP_START_CODE)
				{
/* Get the time code */
					code = (unsigned long)buffer[i] << 24;
					code |= (unsigned long)buffer[i + 1] << 16;
					code |= (unsigned long)buffer[i + 2] << 8;
					code |= (unsigned long)buffer[i + 3];

					hour = code >> 26 & 0x1f;
					minute = code >> 20 & 0x3f;
					second = code >> 13 & 0x3f;
					frame = code >> 7 & 0x3f;

					gop_frame = (long)(hour * 3600 * mpeg3_frame_rate(in, stream) +
							minute * 60 * mpeg3_frame_rate(in, stream) +
							second * mpeg3_frame_rate(in, stream) + 
							frame);
/* fprintf(stderr, "old: %02d:%02d:%02d:%02d ", hour, minute, second, frame); */
/* Write a new time code */
					hour = (long)((float)(total_frames - 1) / mpeg3_frame_rate(in, stream) / 3600);
					carry = hour * 3600 * mpeg3_frame_rate(in, stream);
					minute = (long)((float)(total_frames - 1 - carry) / mpeg3_frame_rate(in, stream) / 60);
					carry += minute * 60 * mpeg3_frame_rate(in, stream);
					second = (long)((float)(total_frames - 1 - carry) / mpeg3_frame_rate(in, stream));
					carry += second * mpeg3_frame_rate(in, stream);
					frame = (total_frames - 1 - carry);

					buffer[i] = ((code >> 24) & 0x80) | (hour << 2) | (minute >> 4);
					buffer[i + 1] = ((code >> 16) & 0x08) | ((minute & 0xf) << 4) | (second >> 3);
					buffer[i + 2] = ((second & 0x7) << 5) | (frame >> 1);
					buffer[i + 3] = (code & 0x7f) | ((frame & 0x1) << 7);
/* fprintf(stderr, "new: %02d:%02d:%02d:%02d\n", hour, minute, second, frame); */
				}

/* Write the frame */
				result = !fwrite(buffer + offset, output_size - offset, 1, stdout);
				if(result)
				{
					perror("fwrite video chunk");
					break;
				}
			}
		}
		else
		{
			fprintf(stderr, "Unsupported stream type.\n");
			mpeg3_close(in);
			in = 0;
			continue;
		}
		
		mpeg3_close(in);
		in = 0;
		current_output_file++;
	}

/* Terminate output */
	if(current_output_file > 0 && do_video)
	{
/*fprintf(stderr, "\n"); */
/* Write new end of sequence */
		buffer[0] = MPEG3_SEQUENCE_END_CODE >> 24;
		buffer[1] = (MPEG3_SEQUENCE_END_CODE >> 16) & 0xff;
		buffer[2] = (MPEG3_SEQUENCE_END_CODE >> 8) & 0xff;
		buffer[3] = MPEG3_SEQUENCE_END_CODE & 0xff;
		result = !fwrite(buffer, 4, 1, stdout);
	}

	exit(0);
}
