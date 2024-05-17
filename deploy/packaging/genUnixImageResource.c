// Take as input an image file. Produce as output a C file defining
// a byte array called embeddedImage which contains the contents of
// the image file, and a string called embeddedImageName containing
// the base name of the image.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define NITEMS (80/5)
int
main(int argc, char *argv[])
{
    FILE *ifh, *ofh;
	unsigned char data[NITEMS];
	char *basename, *dot;
	size_t n;

	if (argc == 2 || argc == 3) {
		if (!(ifh = fopen(argv[1], "rb"))) {
			perror("fopen");
			return 1;
		}
		if (argc == 3) {
			if (!(ofh = fopen(argv[2], "w"))) {
				perror("fopen");
				return 2;
			}
		}
		else
			ofh = stdout;
	}
	else {
		printf("usage: %s file.image [output file]\n", argv[0]);
		exit(2);
	}
	if ((basename = strrchr(argv[1],'/')))
		basename = basename + 1;
	else
		basename = argv[1];
	if (!(dot = strrchr(basename,'.')))
		dot = basename + strlen(basename) - 1;
	fprintf(ofh,
			"char embeddedImageName[] = \"%.*s\";\n",
			(int)(dot - basename), basename);
	fseek(ifh,0,SEEK_END);
	fprintf(ofh,"unsigned long embeddedImageSize = %ld;\n",ftell(ifh));
	fseek(ifh,0,SEEK_SET);
	fprintf(ofh, "unsigned char embeddedImage[] = {\n");
	while ((n = fread(data,sizeof(unsigned char),NITEMS,ifh)) > 0) {
		unsigned char lastchar = feof(ifh) ? '\n' : ',';
		for (int i = 0; i < n; i++)
			fprintf(ofh,"0x%02x%c", data[i], i < (n - 1) ? ',' : (feof(ifh) ? '\n' : ','));
		if (!feof(ifh))
			fprintf(ofh,"\n");
	}
	fprintf(ofh,"};\n");
	(void)fclose(ifh);
	(void)fclose(ofh);
	return 0;
}
