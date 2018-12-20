/* sqUnixFBDevMouse.c -- abstraction over the mouse (Squeak!)
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2003-08-21 15:02:15 by piumarta on felina.inria.fr
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
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


#define _self	struct ms *self


struct ms;

typedef void (*ms_callback_t)(int buttons, int dx, int dy);
typedef void (*ms_init_t)(_self);
typedef void (*ms_handler_t)(_self);

struct ms
{
  char		*msName;
  int		 fd;
  ms_init_t	 init;
  ms_handler_t	 handleEvents;
  ms_callback_t  callback;
  unsigned char	 buf[3*64];
  int		 bufSize;
};


static int ms_read(_self, unsigned char *out, int limit, int quant, int usecs)
{
  unsigned char *buf=   self->buf;
  int		 count= self->bufSize;
  int		 len=   min(limit, sizeof(self->buf));

  len -= count;
  buf += count;

  while ((len > 0) && fdReadable(self->fd, usecs))
    {
      int n= read(self->fd, buf, len);
      if (n > 0)
	{
	  buf   += n;
	  count += n;
	  len   -= n;
	}
      if ((count % quant) == 0)
	break;
    }

  self->bufSize= count;
  count= min(count, limit);
  count= (count / quant) * quant;

  if (count)
    {
      memcpy(out, self->buf, count);
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
      self->bufSize -= count;
      if (self->bufSize)
	memcpy(self->buf, self->buf + count, self->bufSize);
    }

  return count;
}


#include "sqUnixFBDevMousePS2.c"
#include "sqUnixFBDevMouseADB.c"


static void ms_noCallback(int b, int x, int y) {}


static void msHandler(int fd, void *data, int flags)
{
  _self= (struct ms *)data;
  self->handleEvents(self);
  aioHandle(fd, msHandler, AIO_RX);
}


static ms_callback_t ms_setCallback(_self, ms_callback_t callback)
{
  ms_callback_t old= self->callback;
  if (callback)
    {
      self->callback= callback;
      aioEnable(self->fd, self, AIO_EXT);
      aioHandle(self->fd, msHandler, AIO_RX);
    }
  else
    {
      aioDisable(self->fd);
      self->callback= ms_noCallback;
    }
  return old;
}


static int ms_open(_self, char *msDev, char *msProto)
{
  ms_init_t init= 0;
  ms_handler_t handler= 0;

  assert(self->fd == -1);

  if (msDev)
    self->fd= open(self->msName= msDev, O_RDWR);
  else
    {
      static struct _mstab {
  	  char *dev;		char *proto;
      } mice[]=	{
	{ "/dev/psaux",		"ps2"	},
	{ "/dev/input/mice",	"ps2"	},
	{ "/dev/adbmouse",	"adb"	},
	{ 0, 0 }
      };
      int i;
      for (i= 0;  mice[i].dev;  ++i)
	if ((self->fd= open(self->msName= mice[i].dev,  O_RDWR)) >= 0)
	  {
	    if (!msProto)
	      msProto= mice[i].proto;
	    break;
	  }
	else
	  perror(mice[i].dev);
    }
  if (self->fd < 0)
    failPermissions("mouse");

  if (msProto)
    {
      static struct _mptab {
	char *name;	ms_init_t init;	ms_handler_t handler;
      } protos[]= {
	{ "ps2",	ms_ps2_init,	ms_ps2_handleEvents,	},
	{ "adb",	ms_adb_init,	ms_adb_handleEvents,	},
	{ 0, 0, 0 }
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

  DPRINTF("using: %s (%d), %s\n", self->msName, self->fd, msProto);

  self->init= init;
  self->handleEvents= handler;

  return 1;
}


static void ms_close(_self)
{
  if (self->fd >= 0)
    {
      close(self->fd);
      DPRINTF("%s (%d) closed\n", self->msName, self->fd);
      self->fd= -1;
    }
}


static struct ms *ms_new(void)
{
  _self= (struct ms *)calloc(1, sizeof(struct ms));
  if (!self) outOfMemory();
  self->fd= -1;
  self->callback= ms_noCallback;
  return self;
}


static void ms_delete(_self)
{
  free(self);
}


#undef _self
