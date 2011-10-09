#ifndef __SQ_ARGS_H
#define __SQ_ARGS_H

/* Squeak command line parsing helpers */

#define MAX_OPTIONS 1024

extern int numOptionsVM;
extern char *(vmOptions[MAX_OPTIONS]);
extern int numOptionsImage;
extern char *(imageOptions[MAX_OPTIONS]);

/* this goes separately so that we can insert the "hidden" name */
extern char imageName[];

#define ARG_NONE        0
#define ARG_FLAG        1
#define ARG_STRING      2
#define ARG_INT         3
#define ARG_UINT        4
#define ARG_STRING_FUNC 5
#define ARG_INT_FUNC    6
#define ARG_NULL 7

typedef struct vmArg{
  int   type;
  void *value;
  char *name;
} vmArg;

/* use like:

  int headlessFlag;
  char *logFilename;
  unsigned int memorySize;

  sqArg args[] = {
    { ARG_FLAG,   &headlessFlag, "-headless" },
    { ARG_STRING, &logFilename, "-log:" },
    { ARG_UINT,    &memorySize, "-memory:"},
    { ARG_NULL,    0, "--help"},
    { ARG_NONE, NULL, NULL }
  };
*/


int parseArguments(char *cmdLine, vmArg args[]);

#endif /* sqArgs.h */

