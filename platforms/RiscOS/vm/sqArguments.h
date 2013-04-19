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

//  handle commandline arguments

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
