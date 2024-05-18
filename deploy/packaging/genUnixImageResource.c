// Take as input an image file. Produce as output a C file defining a byte
// array called embeddedImage which contains the contents of the image
// file, a string called embeddedImageName containing the base name of the
// image, and an unsigned long, called embeddedImageSize, containing the
// uncompressed size of the image. If the -z flag is supplied, compress the
// image via gzip and include the compressed data, not the original.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>

#define NITEMS (80/5)
int
main(int argc, char *argv[])
{
    FILE *ifh, *ofh, *ttyfh;
	unsigned char data[NITEMS];
	char compressCommandOrFile[PATH_MAX+16];
	char *basename, *dot;
	size_t n;
	int compress = argc > 1 && !strcmp(argv[1],"-z");

	if (argc != 2 + compress && argc != 3 + compress) {
		printf("usage: %s [-z] file.image [output file]\n", argv[0]);
		return 1;
	}
	if (compress) {
		char *mytty = ttyname(fileno(stdin));
		FILE *ttyfh;

		if (!(ttyfh = fopen(mytty,"w+"))) {
			fprintf(stderr,"failed to open %s\n", mytty);
			return 2;
		}
		sprintf(compressCommandOrFile,"gzip -9 -k %s\n",argv[2]);//-9=best compression,-k=keep input
		fprintf(ttyfh,"running gzip to compress file %s...\n",argv[2]);
		if (system(compressCommandOrFile)) {
			fprintf(stderr,"failed to run gzip to compress file\n");
			return 3;
		}
	}
	if (!(ifh = fopen(argv[1+compress], "rb"))) {
		perror("fopen input file");
		return 4;
	}
	if (argc == 2 + compress)
		ofh = stdout;
	else if (!(ofh = fopen(argv[2+compress], "w"))) {
		perror("fopen output file");
		return 5;
	}
	if ((basename = strrchr(argv[1+compress],'/')))
		basename = basename + 1;
	else
		basename = argv[1+compress];
	if (!(dot = strrchr(basename,'.')))
		dot = basename + strlen(basename);
	fprintf(ofh,
			"char embeddedImageName[] = \"%.*s\";\n",
			(int)(dot - basename), basename);
	fseek(ifh,0,SEEK_END);
	fprintf(ofh,"unsigned long embeddedImageSize = %ld;\n",ftell(ifh));
	fseek(ifh,0,SEEK_SET);
	if (compress) {
		(void)fclose(ifh);
		sprintf(compressCommandOrFile,"%s.gz",argv[2]);
		if (!(ifh = fopen(compressCommandOrFile, "rb"))) {
			perror("fopen compressed file");
			return 6;
		}
		fseek(ifh,0,SEEK_END);
		fprintf(ofh,"unsigned long embeddedCompressedDataSize = %ld;\n",ftell(ifh));
		fseek(ifh,0,SEEK_SET);
	}
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
