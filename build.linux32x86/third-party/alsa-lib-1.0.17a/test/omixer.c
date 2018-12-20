#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>
#include <errno.h>
#include <getopt.h>
#include "../include/mixer_ordinary.h"
#include <sys/time.h>
#include <math.h>

static void help(void)
{
	printf(
"Usage: omixer [OPTION]...\n\n"
"-h,--help      help\n"
"-P,--pname     playback PCM device\n"
"-C,--cname     capture PCM device\n"
);
}

int main(int argc, char *argv[])
{
	struct option long_option[] =
	{
		{"help", 0, NULL, 'h'},
		{"pname", 1, NULL, 'P'},
		{"cname", 1, NULL, 'C'},
		{NULL, 0, NULL, 0},
	};
	int err, morehelp, result = EXIT_SUCCESS;
	char *pname = "default", *cname = "default";
	snd_pcm_t *phandle = NULL, *chandle = NULL;
	sndo_mixer_t *handle;

	morehelp = 0;
	while (1) {
		int c;
		if ((c = getopt_long(argc, argv, "hP:C:", long_option, NULL)) < 0)
			break;
		switch (c) {
		case 'h':
			morehelp++;
			break;
		case 'P':
			pname = strdup(optarg);
			break;
		case 'C':
			cname = strdup(optarg);
			break;
		}
	}

	if (morehelp) {
		help();
		return 0;
	}

	if (strcmp(pname, "-")) { 
		err = snd_pcm_open(&phandle, pname, SND_PCM_STREAM_PLAYBACK, 0);
		if (err < 0) {
			fprintf(stderr, "Playback PCM open error: %s\n", snd_strerror(err));
			result = EXIT_FAILURE;
			goto __end;
		}
	}

	if (strcmp(cname, "-")) {
		err = snd_pcm_open(&chandle, cname, SND_PCM_STREAM_CAPTURE, 0);
		if (err < 0) {
			if (phandle)
				snd_pcm_close(phandle);
			fprintf(stderr, "Capture PCM open error: %s\n", snd_strerror(err));
			result = EXIT_FAILURE;
			goto __end;
		}
	}

	err = sndo_mixer_open_pcm(&handle, phandle, chandle, NULL);
	if (err < 0) {
		fprintf(stderr, "mixer open error: %s\n", snd_strerror(err));
		result = EXIT_FAILURE;
	} else {
		sndo_mixer_close(handle);
	}
      __end:
	if (chandle)
		snd_pcm_close(chandle);
	if (phandle)
		snd_pcm_close(phandle);
	snd_config_update_free_global(); /* to keep valgrind happy */
	return result;
}
