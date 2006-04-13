/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqArguments.h                                    */
/*  handle commandline arguments                                          */
/**************************************************************************/

#ifndef __SQ_ARGS_H
#define __SQ_ARGS_H

/* Squeak command line parsing helpers */

#define MAX_OPTIONS 1024

extern int numOptionsVM;
extern char *(vmOptions[MAX_OPTIONS]);
extern int numOptionsImage;
extern char *(imageOptions[MAX_OPTIONS]);

#define ARG_NONE   0
#define ARG_FLAG   1
#define ARG_STRING 2
#define ARG_INT    3
#define ARG_UINT   4

typedef struct vmArg{
  int   type;
  void *value;
  char *name;
} vmArg;

/* use like:

  int headlessFlag = 0;
  char *logFilename = NULL;
  unsigned int memorySize = 32;

  sqArg args[] = {
    { ARG_FLAG,   &headlessFlag, "-headless" },
    { ARG_STRING, &logFilename, "-log:" },
    { ARG_UINT,    &memorySize, "-memory:"},
    { ARG_NONE, NULL, NULL }
  };
*/


int parseArguments(char *argv[], int argc, vmArg args[]);

#endif /* sqArgs.h */
