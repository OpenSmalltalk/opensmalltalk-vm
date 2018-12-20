/*
 * General squeak functions and interpreter entrypoint for Plan9.
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#include "sq.h"
#include "p9iface.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <thread.h>

/* 8MB stack for main interpreter thread */
int mainstacksize = 1024*1024*8;

#define DefaultHeapSize 20      /* megabytes BEYOND actual image size */

int    argCnt=		0;	/* global copies for access from plugins */
char **argVec=		0;
char **envVec=		0;

static int    vmArgCnt=		0;	/* for getAttributeIntoLength() */
static char **vmArgVec=		0;
static int    squeakArgCnt=	0;
static char **squeakArgVec=	0;

static long   extraMemory=	0;

char   imageName[MAXPATHLEN+1]; /* full path to image */
char   shortImageName[MAXPATHLEN+1];	/* image name */
char   vmName[MAXPATHLEN+1];     /* full path to VM */
char   vmPath[MAXPATHLEN+1];     /* full path to image directory */

/**
 * @brief Rename a file
 *
 * @param old previous file name
 * @param new new file name
 *
 * @return 0 on success, -1 on error
 */
int rename(const char* old, const char* new) {
	Dir d;
	nulldir(&d);
	d.name = new;
	dirwstat(old, &d);
	return 0;
}


/*** errors ***/
static int notify_endpoint(void* ureg, char* msg) {
	if (strstr(msg, "sys: bad address") != NULL) {
  		printf("\nSegmentation fault\n\n");
	}
	else {
		printf("Note: %s\n", msg);
	}

	return 0;
}

static void outOfMemory(void)
{
  fprintf(stderr, "out of memory\n");
  threadexits("out of memory");
}

/**
 * @brief Retrieves environment variables for the process
 *
 * @return a malloc'd array of environment variables, ending in NULL
 */
char** env_vars(void) {
	Dir* dir = NULL;
	char** env = NULL;
	int i;
	int env_file = open("/env", OREAD);

	if (env_file == -1) {
		env = (char**)malloc(sizeof(char*));
		if (env == NULL) {
			outOfMemory();
			return NULL;
		}
		env[0] = NULL;
		return env;
	}

	/* Read in directory contents */
	int count = dirread(env_file, &dir);
	close(env_file);

	/* Fill in environment vector */
	env = (char**)malloc(sizeof(char*)*(count+1));
	if (env == NULL) {
		outOfMemory();
		return NULL;
	}

	char file[MAXPATHLEN];
	for (i = 0; i < count; i++) {
		size_t namelen = strlen(dir[i].name);
		snprintf(file, sizeof(file), "/env/%s", dir[i].name);
		int env_val = open(file, OREAD);
		if (env_val == -1) {
			continue;
		}

		size_t length = sizeof(char)*(namelen+dir[i].length+2);
		env[i] = (char*)malloc(length);
		if (env[i] == NULL) {
			while (i--) free(env[i]);
			free(env);
			outOfMemory();
			return NULL;
		}
		snprintf(env[i], length, "%s=", dir[i].name);
		readn(env_val, env[i]+namelen+1, dir[i].length);
		close(env_val);
		env[i][length-1] = '\0';
	}

	free(dir);
	return env;
}

void free_env_vars(char** vars) {
	int i = 0;
	while (vars[i] != NULL) {
		free(vars[i]);
		i++;
	}
	free(vars);
}

/**
 * @brief Parse commandline arguments
 *
 * @param argc number of arguments
 * @param argv argument vector
 */
static void parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgVec[vmArgCnt++]= *skipArg())

	saveArg();	/* vm name */

	while ((argc > 0) && (**argv == '-'))	{ /* more options to parse */
		if (!strcmp(*argv, "--")) break; /* escape from option processing */

		/* Skip all options for now */
		skipArg();
	}

	if (!argc) return;
	
	if (!strcmp(*argv, "--")) skipArg();
	else { /* image name */
		strcpy(shortImageName, saveArg());

		if (!strstr(shortImageName, ".image"))
			strcat(shortImageName, ".image");
	}

	getwd(imageName,sizeof(imageName));
	strcat(imageName, "/");
	strcat(imageName, shortImageName);
	strcpy(vmPath, imageName);
	int lastslash = -1;
	for (int i = 0; i < sizeof(vmPath) && vmPath[i] != '\0'; i++) {
		if (vmPath[i] == '/') {
			lastslash = i;
		}
	}
	if (lastslash != -1) {
		vmPath[lastslash+1] = '\0';
	}
	/*cleanname(imageName);*/

	/* save remaining arguments as Squeak arguments */
	while (argc > 0)
		squeakArgVec[squeakArgCnt++]= *skipArg();

# undef saveArg
# undef skipArg
}

void imgInit(void)
{
	/* read the image file and allocate memory for Squeak heap */
	FILE *f = 0;
	Dir* d;
	char imageName[MAXPATHLEN];

	strcpy(imageName, shortImageName);
	
	if ((NULL == (d = dirstat(imageName))) || (NULL == (f = fopen(imageName, "r")))) {
		fprintf(stderr, "Image file could not be opened: %s", imageName);
		exit(1);
	}
	
	extraMemory = DefaultHeapSize * 1024 *1024;
	extraMemory += d->length;
	readImageFromFileHeapSize(f, extraMemory);
	sqImageFileClose(f);
	free(d);
}

/*** interpreter entrypoint ***/
void threadmain(int argc, char **argv) {
	/* Make parameters global for access from plugins */
	argCnt = argc;
	argVec = argv;
	envVec = env_vars();

	/* Allocate arrays to store copies of pointers to command line
		arguments.  Used by getAttributeIntoLength(). */

	if ((vmArgVec= calloc(argc + 1, sizeof(char *))) == 0)
		outOfMemory();

	if ((squeakArgVec= calloc(argc + 1, sizeof(char *))) == 0)
		outOfMemory();

	threadnotify(notify_endpoint,1);

	parseArguments(argc, argv);

	/* fill in vm path */
	getwd(vmName, sizeof(vmName));
	strcat(vmName,"/");
	strcat(vmName, argVec[0]);

	/* init system */
	if (displayInit() == -1) {
		threadexits("Failed to initialize display");
	}
	if (ioInit() == -1) {
		threadexits("Failed to initialize keyboard/mouse");
	}
	imgInit();
	timeInit();

	/* run Squeak */
	interpret();

	/* destroy data from initialization */
	ioDestroy();
	displayDestroy();
	free_env_vars(envVec);
}

/* Copy aFilenameString to aCharBuffer and optionally resolveAlias (or
   symbolic link) to the real path of the target.  Answer 0 if
   successful of -1 to indicate an error.  Assume aCharBuffer is at
   least MAXPATHLEN bytes long.  Note that MAXSYMLINKS is a lower bound
   on the (potentially unlimited) number of symlinks allowed in a
   path, but calling sysconf() seems like overkill. */

sqInt sqGetFilenameFromString(char *aCharBuffer, char *aFilenameString, sqInt filenameLength, sqInt resolveAlias)
{
  if ((filenameLength < 0) || (filenameLength > MAXPATHLEN)) {
  	  return -1;
  }
  strncpy(aCharBuffer, aFilenameString, filenameLength);
  aCharBuffer[filenameLength] = '\0';

  return 0;
}

/* Attribute functions */
static char *getAttribute(sqInt id)
{
	if (id < 0) {
		if (-id  < vmArgCnt)
			return vmArgVec[-id];
	}
	else switch (id) {
		case 0:
			return vmName[0] ? vmName : vmArgVec[0];
		case 1:
			return imageName;
		case 1001:
			/* OS type: "unix", "win32", "mac", ... */
			return OS_TYPE;
		case 1002:
			/* OS name: "solaris2.5" on unix, "win95" on win32, ... */
			return VM_HOST_OS;
		case 1003:
			/* processor architecture: "68k", "x86", "PowerPC", ...  */
			return VM_HOST_CPU;
		case 1004:
			/* Interpreter version string */
			return  (char *)interpreterVersion;
		case 1005:
			/* window system name */
			return  WINDOW_SYS_NAME;
		case 1006:
			/* vm build string */
			return VM_BUILD_STRING;
		default:
			if ((id - 2) < squeakArgCnt)
				return squeakArgVec[id - 2];
		}

	success(false);
	return "";
}

sqInt attributeSize(sqInt indexNumber) {
	return strlen(getAttribute(indexNumber));
}

sqInt getAttributeIntoLength(sqInt indexNumber, sqInt byteArrayIndex, sqInt length) {
	if (length > 0) {
		strncpy((char*)pointerForOop(byteArrayIndex), getAttribute(indexNumber), length);
	}
	return 0;
}


/* Image functions */
char *getImageName(void) {
	return imageName;
}

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length) {
	char* buf = (char*)pointerForOop(sqImageNameIndex);
	int count = length < strlen(imageName) ? length : strlen(imageName);

	strncpy(buf, imageName, count);
	return count;
}

sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length) {
	char* buf = (char*)pointerForOop(sqImageNameIndex);
	int count = length < sizeof(imageName) ? length : sizeof(imageName) - 1;

	strncpy(imageName, buf, count);
	imageName[count] = '\0';
	return count;
}

sqInt imageNameSize(void) {
	return strlen(imageName);
}

sqInt vmPathSize(void) {
	return strlen(vmPath);
}

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length) {
	char* buf = (char*)pointerForOop(sqVMPathIndex);
	int count = length < strlen(vmPath) ? length : strlen(vmPath);

	strncpy(buf, vmPath, count);
	return count;
}

/* Image security traps */
sqInt ioCanRenameImage(void) {
	return true;
}

sqInt ioCanWriteImage(void) {
	return true;
}

sqInt ioDisableImageWrite(void) {
	return false;
}
