/* sqUnixEvdevMouse.c -- libevdev code for mouse input
 *
 * Author: Ken.Dickey@whidbey.com
 * Last Updated: August 2020
 */
/* 
 * Copyright (C) 2020 Kenneth A Dickey
 * All Rights Reserved.
 * 
 * This file is part of OpenSmalltalk / Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

#include <stdint.h>
#include <linux/version.h>
#include <linux/input.h>

#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <getopt.h>
#include <ctype.h>
#include <signal.h>
#include <limits.h>
#include <unistd.h>
#include <limits.h> /* PATH_MAX */

#ifndef input_event_sec
#define input_event_sec  time.tv_sec
#define input_event_usec time.tv_usec
#endif

#define BITS_PER_LONG (sizeof(long) * 8)
#define NBITS(x) ((((x)-1)/BITS_PER_LONG)+1)
#define OFF(x)  ((x)%BITS_PER_LONG)
#define BIT(x)  (1UL<<OFF(x))
#define LONG(x) ((x)/BITS_PER_LONG)
#define test_bit(bit, array)	((array[LONG(bit)] >> OFF(bit)) & 1)

#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"

#ifndef EV_SYN
#define EV_SYN 0
#endif
#ifndef SYN_MAX
#define SYN_MAX 3
#define SYN_CNT (SYN_MAX + 1)
#endif
#ifndef SYN_MT_REPORT
#define SYN_MT_REPORT 2
#endif
#ifndef SYN_DROPPED
#define SYN_DROPPED 3
#endif

/* wiki.squeak.org/squeak/897 shows:
   red    #b100 left  (4)	button1
   yellow #b010 mid   (2)	button2
   blue   #b001 right (1)	button3
 So binary view of bit matches mouse (l|m|r) position
 */
#define LeftMouseButtonBit  RedButtonBit
#define MidMouseButtonBit   YellowButtonBit
#define RightMouseButtonBit BlueButtonBit


#define _mouse	struct ms *mouseSelf

struct ms;

typedef void (*ms_callback_t)(int buttons, int dx, int dy);
typedef void (*ms_init_t)(_mouse);
typedef void (*ms_handler_t)(_mouse);

struct ms
{
  char		*msName;
  int		 fd;
  ms_init_t	 init;
  ms_handler_t	 handleEvents;
  ms_callback_t  callback;
  unsigned char	 buf[3*64];
  int		 bufSize;
  struct libevdev *dev;
};

const char* mouseFile = "/dev/input/event0".

static int ms_read(_mouse, unsigned char *out, int limit, int quant, int usecs)
{
  unsigned char *buf=   mouseSelf->buf;
  int		 count= mouseSelf->bufSize;
  int		 len=   min(limit, sizeof(mouseSelf->buf));

  len -= count;
  buf += count;

  while ((len > 0) && fdReadable(mouseSelf->fd, usecs))
    {
      int n= read(mouseSelf->fd, buf, len);
      if (n > 0)
	{
	  buf   += n;
	  count += n;
	  len   -= n;
	}
      if ((count % quant) == 0)
	break;
    }

  mouseSelf->bufSize= count;
  count= min(count, limit);
  count= (count / quant) * quant;

  if (count)
    {
      memcpy(out, mouseSelf->buf, count);
#    if DEBUG_AN_AWFUL_LOT
      {
	int i= 0;
	while (i < count)
	  {
	    DPRINTF("<%02x\n", out[i]);
	    ++i;
	  }
      }
#    endif
      mouseSelf->bufSize -= count;
      if (mouseSelf->bufSize)
	memcpy(mouseSelf->buf, mouseSelf->buf + count, mouseSelf->bufSize);
    }

  return count;
}



static void ms_noCallback(int b, int x, int y) {}


static void msHandler(int fd, void *data, int flags)
{
  _mouse= (struct ms *)data;
  mouseSelf->handleEvents(mouseSelf);
  aioHandle(fd, msHandler, AIO_RX);
}


static ms_callback_t ms_setCallback(_mouse, ms_callback_t callback)
{
  ms_callback_t old= mouseSelf->callback;
  if (callback)
    {
      mouseSelf->callback= callback;
      aioEnable(mouseSelf->fd, mouseSelf, AIO_EXT);
      aioHandle(mouseSelf->fd, msHandler, AIO_RX);
    }
  else
    {
      aioDisable(mouseSelf->fd);
      mouseSelf->callback= ms_noCallback;
    }
  return old;
}

static int ms_open(_mouse, char *msDev, char *msProto)
{
  ms_init_t init= 0;
  ms_handler_t handler= 0;
  int rc = 0;

  assert(mouseSelf->fd == -1);

  if (msDev)
    mouseSelf->fd= open(mouseSelf->msName= msDev, O_RDONLY);
  else
    {
      static struct _mstab {
  	  char *dev;		char *proto;
      } mice[]=	{
	{ "/dev/input/event1",  "evdev" }, /* Alpine Linux RasPi3 */
	{ 0, 0 }
      };
      int i;
      for (i= 0;  mice[i].dev;  ++i)
	if ((mouseSelf->fd= open(mouseSelf->msName= mice[i].dev,  O_RDWR)) >= 0)
	  {
	    if (!msProto)
	      msProto= mice[i].proto;
	    break;
	  }
	else
	  perror(mice[i].dev);
    }
  if (mouseSelf->fd < 0) {
    if (errno == EACCES && getuid() != 0)
	fprintf(stderr, "You do not have access to %s. Try "
			"running as root instead.\n",
			mouseSelf->msName );
    failPermissions("mouse");
  }
  else {
    rc = libevdev_new_from_fd( mouseSelf->fd, &mouseSelf->dev );
    if (rc < 0)
      fatal("Unable to initialize libevdev (%s)\n",
	    strerror(-rc) );
  }
  
  if (msProto)
    {
      static struct _mptab {
	char *name;	ms_init_t init;	ms_handler_t handler;
      } protos[]= {
	{ "evdev",	ms_evdev_init,	ms_evd_handleEvents,	},		
	{ 0,	0,	0 }
      };
      int i;
      for (i= 0;  protos[i].name;  ++i)
	if (!strcmp(msProto, protos[i].name))
	  {
	    init=    protos[i].init;
	    handler= protos[i].handler;
	    break;
	  }
      if (!init)
	{
	  fprintf(stderr, "unknown mouse protocol: '%s'\n", msProto);
	  fprintf(stderr, "supported protocols:");
	  for (i= 0;  protos[i].name;  ++i)
	    fprintf(stderr, " %s", protos[i].name);
	  fprintf(stderr, "\n");
	  exit(1);
	}
    }

  DPRINTF("using: %s (%d), %s\n", mouseSelf->msName, mouseSelf->fd, msProto);

  mouseSelf->init= init;
  mouseSelf->handleEvents= handler;

  return 1;
}


static void ms_close(_mouse)
{
  if (mouseSelf->fd >= 0)
    {
      close(mouseSelf->fd);
      DPRINTF("%s (%d) closed\n", mouseSelf->msName, mouseSelf->fd);
      mouseSelf->fd= -1;
    }
}


static struct ms *ms_new(void)
{
  _mouse= (struct ms *)calloc(1, sizeof(struct ms));
  if (!mouseSelf) outOfMemory();
  mouseSelf->fd= -1;
  mouseSelf->callback= ms_noCallback;
  return mouseSelf;
}


static void ms_delete(_mouse)
{
  free(mouseSelf);
}


#undef _mouse


/*			E O F			*/

