/* This file is a heavily modified version of the file "sqMacJoystick.c".
 *
 * Modifications by: Ian Piumarta (ian.piumarta@inria.fr)
 *
 * Support for Linux/i386 joysticks contributed by:
 *	J"orn Eyrich <joern@eyrich.org>
 *
 * The original version of this file can be regenerated from the Squeak
 * image by executing:
 *
 * 	InterpreterSupportCode writeMacSourceFiles
 */

#include "sq.h"

#if defined(__linux__) && defined(__i386__)

#include <linux/joystick.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#define FILENAMEBUFLEN 30
#define MAX_JOYSTICKS  (JS_MAX)

static int  numJoysticks = 0;
static int  joyFileDes  [MAX_JOYSTICKS];

static const char * filenamePrefixes[]= {
  "/dev/input/js",
  "/dev/js"
};
#define NUM_FILENAME_PREFIXES (sizeof(filenamePrefixes) / sizeof(filenamePrefixes[0]))

int joystickInit(void)
{
  static char filenameBuf [FILENAMEBUFLEN];
  int prefixNum, i;
  for(prefixNum=0; prefixNum<NUM_FILENAME_PREFIXES; prefixNum++) {
    const char * filenamePrefix = filenamePrefixes[prefixNum];
    
    for (i=0; i<JS_MAX; i++)
      {
	int fd;
	       
	sprintf(filenameBuf,"%s%d",filenamePrefix,i);
	fd = open(filenameBuf,O_RDONLY|O_NONBLOCK);
	       
	if(fd >= 0) {
	  if(numJoysticks < MAX_JOYSTICKS) {
	    joyFileDes[numJoysticks] = fd;
	    numJoysticks++;
	  }
	  else {
	    fprintf(stderr, "more joysticks detected than are supported");
	    close(fd);
	  }
	}
      }
    return 1;
  }
}


int joystickRead(int index)
{
  struct JS_DATA_TYPE joyStruct;
 
  if (index <= 0 || index > numJoysticks)  {
    return 0;
  }

  if (read(joyFileDes[index-1], &joyStruct, JS_RETURN) == -1)  {
    perror("read");  /* should the device be closed, in this case? */
    return 0;
  }

  /* x/y are 0..255, convert to 0..2047 by shifting left 3 bits */
  return    (                1 << 27)
          | ((joyStruct.buttons & 0x1F) << 22)
          | ((joyStruct.y       & 0xFF) << 14)
          | ((joyStruct.x       & 0xFF) <<  3);

  /*
     the comments in sqMacJoystickAndTablet.c are wrong on two counts:

     1: x and y components in the return word format are switched
     2: x and y values are not -1024..1023, but 0..2047

     (see InputSensor>>joystickXY:)
  */
}


int joystickShutdown(void)
{
  /* exit() will close the file descriptors for us */

  return 0;
}

#else

int joystickInit(void)		{ return 0; }
int joystickRead(int index)	{ return 0; }
int joystickShutdown(void)      { return 0; }

#endif
