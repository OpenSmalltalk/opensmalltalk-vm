//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqArgument.c (Oh no it isn't!)
// Parse the commandline arguments and deal with them.
// See sqRPCMain.c -> vmArg args[] for details of the options

//#define DEBUG
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "sq.h"
#include "sqArguments.h"

static int opt = 0;
static int numOptions;
static char** optionArray;
int ImageVersionNumber;

static char* nextOption(void) {
	if(opt >= numOptions) return 0;
	return optionArray[opt++];
}


static int IsImage(char *name) {
/* check the named file to see if it is a decent candidate for a Squeak image
 * file. Remember to check both the very beginning of the file and 512 bytes
 * into it, just in case it was written from a unix machine - which adds a
 * short extra header
 */
FILE *fp;
int magic;
extern sqInt byteSwapped(sqInt);

	fp = fopen(name,"rb");
	if(!fp) return 0; /* could not open file */
	if(fread(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
		/* could not read an int from file */
		fclose(fp);
		return 0;
	}
	if (magic > 0xFFFF) {
		magic = byteSwapped(magic);
	}
	ImageVersionNumber = magic;
	if (readableFormat(magic)) {
		fclose(fp);
		return true;
	}
	/* no luck at beginning of file, seek to 512 and try again */
	if(fseek( fp, 512, SEEK_SET)) {
		/* seek failed, which implies file is too small */
		fclose(fp);
		return false;
	}
	if(fread(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
	/* could not read an int from file */
	fclose(fp);
	return 0;
	}
	if (magic > 0xFFFF) {
		magic = byteSwapped(magic);
	}
	ImageVersionNumber = magic;
	if (readableFormat(magic)) {
		fclose(fp);
		return true;
	}
	fclose(fp);
	return false;
}


/* parse an unsigned integer argument */
static char *parseUnsignedArg(char *src, unsigned *dst) {
char buf[50];
char *tmp = buf;
int factor = 1;

	while(isdigit(*src)) *(tmp++) = *(src++);

	if(*src && tolower(*src) == 'k') {factor = 1024; src++;}
	else if(*src && tolower(*src) == 'm') {factor = 1024*1024; src++;}
	else if(*src && *src != ' ') /* strange chars at end */
		return NULL;
	if(tmp == buf) /* no numbers found */
		return NULL;
	*tmp = 0;
	*dst = atol(buf) * factor;
	if(*src) *(src++) = 0;
	return src;
}

/* parse a (possibly signed) integer argument */
static char *parseSignedArg(char *src, int *dst) {
int negative;
unsigned value;

	negative = *src == '-';
	if(negative) src++;
	src = parseUnsignedArg(src, &value);
	if(!src) return NULL;
	if(negative) *dst = 0-(int)value;
	else *dst = (int) value;
	return src;
}

/* parse all arguments meaningful to the VM */
static int parseVMArgs(vmArg args[]) {
vmArg *arg;
int arglen;
char * string;

	while(1)
		{
			if((string = nextOption()) == NULL)
				return NULL; /* no more */

			if(*string != '-') {
				opt--;
				return 1; /* no '-' means this isn't a VM option - probably the image name */
			}

			// save the string for the image to look at
			vmOptions[numOptionsVM++] = string;

			/* search args list */
			arg = args;
			while(arg->type != ARG_NONE){
				arglen = strlen(arg->name);
				if(strncmp(arg->name, string, strlen(arg->name)) == 0)
					break;
				arg++;
			}
			if(arg->type == ARG_NONE)
				return NULL; /* done */

			/* if the char at the end of the option name is ':',
			 * null it out and skip ahead one
			 */
			string += (arglen-1);
			if(*string== ':') *(string++) = 0;

			switch(arg->type) {
				case ARG_FLAG:
					*(int*)arg->value = 1;
					break;

				case ARG_STRING:
					vmOptions[numOptionsVM++] = string;
					*(char**) arg->value = string;
					break;

				case ARG_INT:
					vmOptions[numOptionsVM++] = string;
					string = parseSignedArg(string, (int*)arg->value);
					if(!string) return NULL;
					break;

				case ARG_UINT:
					vmOptions[numOptionsVM++] = string;
					string = parseUnsignedArg(string, (unsigned int*)arg->value);
					if(!string) return NULL;
					break;

				default:
					printf("Unknown option encountered!\n");
					return NULL;
			 };
		}
}

/* parse all arguments starting with the image name */
static int parseGenericArgs(void) {
char *string, *imageName= getImageName();
extern char * canonicalizeFilename(char* inString, char * outString);
extern void setDefaultImageName(void);

	if (!(string = nextOption()) ) {
		// no options left, so can only use default image name & return
		setDefaultImageName();
		imageOptions[numOptionsImage++] = imageName;
		return 1;
	}

	/* now decode the putative image name */
	canonicalizeFilename(string, imageName);

	if(*imageName && IsImage(imageName)) {
		// all is ok, its the image name
	} else { /* Not the image name -- use a default in the !Squeak appdir */
		setDefaultImageName();
		// and skip back 1 on the option list
		opt--;
	}
	imageOptions[numOptionsImage++] = imageName;

	// now go through any more options
	while((string = nextOption()) && *string) {
			if(numOptionsImage > MAX_OPTIONS)
				return NULL; /* too many args */
			while(*string && *string == ' ')
				string++; /* skip blanks */
			imageOptions[numOptionsImage++] = string;
			if(!string) return NULL;
	}
	return 1;
}


int parseArguments(char *argv[], int argc, vmArg args[]) {
extern char * decodeVMPath(char*);
numOptionsVM = 0;
numOptionsImage = 0;
numOptions = argc;
optionArray = &argv[0];

	/* argv[0] = executable name */
	vmOptions[numOptionsVM++] = decodeVMPath( nextOption());

	/* parse VM options */
	parseVMArgs(args);

	/* parse image and generic args */
	return parseGenericArgs() != NULL;
}

