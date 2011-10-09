/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Args.c
*   CONTENT: Command line processing
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Args.c 400 2002-05-26 18:52:10Z andreasraab $
*
*   NOTES:
*
*****************************************************************************/
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "sq.h"
#include "sqWin32Args.h"

static int IsImage(char *name) { 
  int magic;
  int byteSwapped(int);
  sqImageFile fp;

  fp = sqImageFileOpen(name,"rb");
  if(!fp) return 0; /* not an image */
  if(sqImageFileRead(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
    sqImageFileClose(fp);
    return 0;
  }
  if(readableFormat(magic) || readableFormat(byteSwapped(magic))) {
    sqImageFileClose(fp);
    return true;
  }
   
  /* no luck at beginning of file, seek to 512 and try again */
  sqImageFileSeek( fp, 512);
  if(sqImageFileRead(&magic, 1, sizeof(magic), fp) != sizeof(magic)) {
    sqImageFileClose(fp);
    return 0;
  }
  sqImageFileClose(fp);
  return readableFormat(magic) || readableFormat(byteSwapped(magic));
}

/* parse a possibly quoted string argument */
static char *parseStringArg(char *src, char **argPtr)
{
  while(*src && *src == ' ') src++; /* skip blanks */
  if(*src == '"') /* double quoted string */
    { 
      (*argPtr)++;
      do {
        src++;
        while(*src && *src != '"') src++;
      } while(*src && *(src-1) == '\\');
    }
  else /* not quoted */
    { 
      while(*src && *src != ' ') src++;
    }
  if(*src) *(src++) = 0;
  return src;
}

/* parse an unsigned integer argument */
static char *parseUnsignedArg(char *src, unsigned *dst)
{ char buf[50];
  char *tmp = buf;
  unsigned multiplier = 1;

  while(*src && *src == ' ') src++; /* skip blanks */
  while(isdigit(*src)) *(tmp++) = *(src++);
  if(*src && *src != ' ') { /* suffix or strange chars at end */
    switch (*src) {
    case 'k': case 'K':
      multiplier = 1024;
      break;
    case 'm': case 'M':
      multiplier = 1024*1024;
      break;
	default:
      return NULL;
    }
  }
  if(tmp == buf) /* no numbers found */
    return NULL;
  *dst = atol(buf) * multiplier;
  if(*src) *(src++) = 0;
  return src;
}

/* parse a (possibly signed) integer argument */
static char *parseSignedArg(char *src, int *dst)
{
  int negative;
  unsigned value;

  while(*src && *src == ' ') src++; /* skip blanks */
  negative = *src == '-';
  if(negative) src++;
  src = parseUnsignedArg(src, &value);
  if(!src) return NULL;
  if(negative) *dst = 0-(int)value;
  else *dst = (int) value;
  return src;
}

/* parse all arguments meaningful to the VM */
static char* parseVMArgs(char *string, vmArg args[])
{ vmArg *arg;
  int arglen;

  while(1)
    {
      if(numOptionsVM >= MAX_OPTIONS)
        return NULL; /* too many args */
      while(*string && *string == ' ') string++; /* skip blanks */
      if(*string != '-') return string; /* image name */
      vmOptions[numOptionsVM++] = string;

      /* search args list */
      arg = args;
      while(arg->type != ARG_NONE)
        {
          arglen = strlen(arg->name);
          if(strncmp(arg->name, string, strlen(arg->name)) == 0)
            break;
          arg++;
        }
      if(arg->type == ARG_NONE)
        return string; /* done */

      string += arglen;
	  /* can't just bash the string; if we have -breaksel:at:put: this would
	   * truncate breaksel to t:put:.
	   */
      if (*string)
		if (*string == ' ')
			*(string++) = 0;
		else {
			char save = *string;
			*string = 0;
			vmOptions[numOptionsVM - 1] = strdup(vmOptions[numOptionsVM - 1]);
			*string = save;
		}

      while(*string && *string == ' ') string++; /* skip blanks */

      switch(arg->type) {
        case ARG_FLAG:
          *(int*)arg->value = 1;
          break;

        case ARG_STRING:
        case ARG_STRING_FUNC: {
		  char *theValue;
          vmOptions[numOptionsVM++] = theValue = string;
          string = parseStringArg(string, &theValue);
		  if (arg->type == ARG_STRING)
            *(char**) arg->value = theValue;
		  else
			((void (*)(char *))(arg->value))(theValue);
          if(!string) return NULL;
          break;
		}

        case ARG_INT_FUNC: {
		  int dummy;
          vmOptions[numOptionsVM++] = string;
          string = parseSignedArg(string, &dummy);
          ((void (*)(int))(arg->value))(dummy);
          if(!string) return NULL;
          break;
		}
        case ARG_INT:
          vmOptions[numOptionsVM++] = string;
          *(char**) arg->value = string;
          string = parseSignedArg(string, (int*)arg->value);
          if(!string) return NULL;
          break;

        case ARG_UINT:
          vmOptions[numOptionsVM++] = string;
          *(char**) arg->value = string;
          string = parseUnsignedArg(string, (unsigned int*)arg->value);
          if(!string) return NULL;
          break;

        case ARG_NULL:
          return NULL;

        default:
          fprintf(stderr,"Unknown option encountered!\n");
          return NULL;
       };
    }
}

/* parse all arguments starting with the image name */
static char *parseGenericArgs(char *string)
{ char *tmpImageName;

  while(*string && *string == ' ') string++; /* skip blanks */
  /* now get the image name */
  tmpImageName = string;
  string = parseStringArg(string, &tmpImageName);
  if(!string) return NULL; /* parse error */
  if(*imageName == 0) {
	/* only attempt to use image name if none is provided */
	if(*tmpImageName && IsImage(tmpImageName))
      strcpy(imageName, tmpImageName);
  } else {
	  /* provide image name as second argument if implicitly specified */
	  imageOptions[numOptionsImage++] = imageName;
  }
  imageOptions[numOptionsImage++] = tmpImageName;
  while(string && *string)
    {
      if(numOptionsImage > MAX_OPTIONS) return string; /* too many args */
      while(*string && *string == ' ') string++; /* skip blanks */
      imageOptions[numOptionsImage++] = string;
      string = parseStringArg(string, &(imageOptions[numOptionsImage-1]));
      if(!string) return NULL;
    }
  return string;
}

int parseArguments(char *cmdLine, vmArg args[])
{
  /* argv[0] = executable name */
  vmOptions[numOptionsVM++] = cmdLine;
  cmdLine = parseStringArg(cmdLine, &(vmOptions[numOptionsVM-1]));
  if(!cmdLine) return 0;
  /* parse VM options */
  cmdLine = parseVMArgs(cmdLine, args);
  if(cmdLine == NULL) return 0;
  /* parse image and generic args */
  cmdLine = parseGenericArgs(cmdLine);
  return cmdLine != NULL;
}
