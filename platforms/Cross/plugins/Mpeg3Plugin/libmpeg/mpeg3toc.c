/*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
*/
#include "libmpeg3.h"

#include <stdio.h>
#include <string.h>

#ifdef MACINTOSH
#include <stat.h>
#else
#include <sys/stat.h>
#endif


int main(int argc, char *argv[])
{
	int i;
/*	FILE *output; */
	char new_path[1024], *ext;
	struct stat st;
	long size;
	int timecode_search = 0;

	if(argc < 2)
	{
		fprintf(stderr, "Create a table of contents for a DVD.\n"
			"	Usage: mpeg3toc [-t] <filename>...\n"
			"	-t Perform timecode search.\n"
			"\n"
			"	The filenames should be absolute paths unless you plan\n"
			"	to always run your movie player from the same directory\n"
			"	as the filename.  Alternatively you can edit the toc by\n"
			"	hand.\n"
			"	The timecode search allows XMovie to play the Matrix.\n"
			"Example: mpeg3toc /cd2/video_ts/vts_01_*.vob > titanic.toc\n");
		exit(1);
	}

	for(i = 1; i < argc; i++)
	{
		if(!strcmp(argv[i], "-t"))
		{
			timecode_search = 1;
		}
		else
		{
/* Get just name */
			ext = strrchr(argv[i], '/');
			if(ext)
			{
				ext++;
				strcpy(new_path, ext);
			}
			else
				strcpy(new_path, argv[i]);


/* Replace suffix */
			ext = strrchr(new_path, '.');
			if(ext)
			{
				sprintf(ext, ".toc");
			}
			else
				strcat(new_path, ".toc");

/*			fprintf(stderr, "Creating %s\n", new_path); */

			stat(argv[i], &st);
			size = (long)st.st_size;

			if(!size)
			{
				fprintf(stderr, "%s is 0 length.  Skipping\n", new_path);
			}
			else
			{
/* Just want the first title's streams */
				if(mpeg3_generate_toc(stdout, argv[i], timecode_search, i == argc - 1))
				{
					fprintf(stderr, "Skipping %s\n", argv[i]);
				}
			}
		}
	}
}
