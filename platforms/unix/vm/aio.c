/* aio.c -- asynchronous file i/o
 * 
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 *   You are not allowed to distribute a modified version of this file
 *   under its original name without explicit permission to do so.  If
 *   you change it, rename it.
 */

/* Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2003-02-06 16:36:13 by piumarta on emilia.local.
 */

#include "aio.h"

#ifdef HAVE_CONFIG_H

# include "config.h"

# ifdef HAVE_UNISTD_H
#   include <sys/types.h>
#   include <unistd.h>
# endif /* HAVE_UNISTD_H */
  
# ifdef NEED_GETHOSTNAME_P
    extern int gethostname();
# endif
  
# include <stdio.h>
# include <signal.h>
# include <errno.h>
# include <sys/ioctl.h>
  
# ifdef HAVE_SYS_TIME_H
#   include <sys/time.h>
# else
#   include <time.h>
# endif
  
# ifdef HAS_SYS_SELECT_H
#   include <sys/select.h>
# endif
  
# ifndef FIONBIO
#   ifdef HAVE_SYS_FILIO_H
#     include <sys/filio.h>
#   endif
#   ifndef FIONBIO
#     ifdef FIOSNBIO
#       define FIONBIO FIOSNBIO
#     else
#       error: FIONBIO is not defined
#     endif
#   endif
# endif

#else /* !HAVE_CONFIG_H -- assume lowest common demoninator */

# include <stdio.h>
# include <stdlib.h>
# include <unistd.h>
# include <errno.h>
# include <signal.h>
# include <sys/types.h>
# include <sys/time.h>
# include <sys/select.h>
# include <sys/ioctl.h>

#endif


#undef	DEBUG

#ifdef DEBUG
# define FPRINTF(X) fprintf X
  static char *ticks= "-\\|/";
  static char *ticker= "";
  #define DO_TICK() \
  { \
    fprintf(stderr, "\r%c\r", *ticker); \
    if (!*ticker++) ticker= ticks; \
  }
#else /* !DEBUG */
# define FPRINTF(X)
# define DO_TICK()
#endif

#define _DO_FLAG_TYPE()	_DO(AIO_R, rd) _DO(AIO_W, wr) _DO(AIO_X, ex)

static int one= 1;

static aioHandler  rdHandler[FD_SETSIZE];
static aioHandler  wrHandler[FD_SETSIZE];
static aioHandler  exHandler[FD_SETSIZE];

static void       *clientData[FD_SETSIZE];

static int	maxFd;
static fd_set	fdMask;	/* handled by aio	*/
static fd_set	rdMask; /* handle read		*/
static fd_set	wrMask; /* handle write		*/
static fd_set	exMask; /* handle exception	*/
static fd_set	xdMask; /* external descriptor	*/


static void undefinedHandler(int fd, void *clientData, int flags)
{
  fprintf(stderr, "undefined handler called (fd %d, flags %x)\n", fd, flags);
}

#ifdef DEBUG
static char *handlerName(aioHandler h)
{
  if (h == undefinedHandler) return "undefinedHandler";
#ifdef DEBUG_SOCKETS
 {
   extern char *socketHandlerName(aioHandler);
   return socketHandlerName(h);
 }
#endif
 return "***unknown***";
}
#endif

/* initialise asynchronous i/o */

void aioInit(void)
{
  FD_ZERO(&fdMask);
  FD_ZERO(&rdMask);
  FD_ZERO(&wrMask);
  FD_ZERO(&exMask);
  FD_ZERO(&xdMask);
  maxFd= 0;
  signal(SIGPIPE, SIG_IGN);
}


/* disable handlers and close all handled non-exteral descriptors */

void aioFini(void)
{
  int fd;
  for (fd= 0;  fd < maxFd;  fd++)
    if (FD_ISSET(fd, &fdMask) && !(FD_ISSET(fd, &xdMask)))
      {
	aioDisable(fd);
	close(fd);
	FD_CLR(fd, &fdMask);
	FD_CLR(fd, &rdMask);
	FD_CLR(fd, &wrMask);
	FD_CLR(fd, &exMask);
      }
  while (maxFd && !FD_ISSET(maxFd - 1, &fdMask))
    --maxFd;
  signal(SIGPIPE, SIG_DFL);
}


/* poll for i/o activity, with microSeconds wait */

int aioPoll(int microSeconds)
{
  int fd;
  fd_set rd, wr, ex;
  struct timeval tv;

  DO_TICK();

  /* get out early if there is no pending i/o and no need to relinquish cpu */

  if ((maxFd == 0) && (microSeconds == 0))
    return 0;

  rd= rdMask;
  wr= wrMask;
  ex= exMask;
  tv.tv_sec=  microSeconds / 1000000;
  tv.tv_usec= microSeconds % 1000000;

  {
    int result;
    do
      {
	result= select(maxFd, &rd, &wr, &ex, &tv);
      }
    while ((result < 0) && (errno == EINTR));
    if (result < 0)
      perror("select");
    else if (result > 0)
      {
	for (fd= 0; fd < maxFd; ++fd)
	  {
#           define _DO(FLAG, TYPE)				\
	    {							\
	      if (FD_ISSET(fd, &TYPE))				\
		{						\
		  aioHandler handler= TYPE##Handler[fd];	\
		  FD_CLR(fd, &TYPE##Mask);			\
		  TYPE##Handler[fd]= undefinedHandler;		\
		  handler(fd, clientData[fd], FLAG);		\
		}						\
	    }
	    _DO_FLAG_TYPE();
#           undef _DO
	  }
      }
  }
  return 0;
}


/* enable asynchronous notification for a descriptor */

void aioEnable(int fd, void *data, int flags)
{
  FPRINTF((stderr, "aioEnable(%d)\n", fd));
  if (FD_ISSET(fd, &fdMask))
    {
      fprintf(stderr, "aioEnable: descriptor %d already enabled\n", fd);
      return;
    }
  clientData[fd]= data;
  rdHandler[fd]= wrHandler[fd]= exHandler[fd]= undefinedHandler;
  FD_SET(fd, &fdMask);
  FD_CLR(fd, &rdMask);
  FD_CLR(fd, &wrMask);
  FD_CLR(fd, &exMask);
  if (fd >= maxFd)
    maxFd= fd + 1;
  if (flags & AIO_EXT)
    {
      FD_SET(fd, &xdMask);
      /* we should not set NBIO ourselves on external descriptors! */
    }
  else
    {
      FD_CLR(fd, &xdMask);
      if (ioctl(fd, FIONBIO, (char *)&one) < 0)
	perror("ioctl(FIONBIO, 1)");
    }
}


/* install/change the handler for a descriptor */

void aioHandle(int fd, aioHandler handlerFn, int mask)
{
  FPRINTF((stderr, "aioHandle(%d, %s, %d)\n", fd, handlerName(handlerFn), mask));
# define _DO(FLAG, TYPE)			\
    if (mask & FLAG) {				\
      FD_SET(fd, &TYPE##Mask);			\
      TYPE##Handler[fd]= handlerFn;		\
    }
  _DO_FLAG_TYPE();
# undef _DO
}


/* temporarily suspend asynchronous notification for a descriptor */

void aioSuspend(int fd, int mask)
{
  FPRINTF((stderr, "aioSuspend(%d)\n", fd));
# define _DO(FLAG, TYPE)			\
  {						\
    if (mask & FLAG)				\
      {						\
	FD_CLR(fd, &TYPE##Mask);		\
	TYPE##Handler[fd]= undefinedHandler;	\
      }						\
  }
  _DO_FLAG_TYPE();
# undef _DO
}


/* definitively disable asynchronous notification for a descriptor */

void aioDisable(int fd)
{
  FPRINTF((stderr, "aioDisable(%d)\n", fd));
  aioSuspend(fd, AIO_RWX);
  FD_CLR(fd, &xdMask);
  FD_CLR(fd, &fdMask);
  rdHandler[fd]= wrHandler[fd]= exHandler[fd]= 0;
  clientData[fd]= 0;
  /* keep maxFd accurate (drops to zero if no more sockets) */
  while (maxFd && !FD_ISSET(maxFd - 1, &fdMask))
    --maxFd;
}
