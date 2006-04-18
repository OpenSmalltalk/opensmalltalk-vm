/* aio.c -- asynchronous file i/o
 * 
 *   Copyright (C) 1996-2006 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

/* Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2006-04-17 21:44:32 by piumarta on margaux.local
 */

#include "sqaio.h"

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
# include <fcntl.h>
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
# include <fcntl.h>

#endif


#undef	DEBUG
#undef	DEBUG_TICKER

#if defined(DEBUG)
  int aioLastTick= 0;
  int aioThisTick= 0;
# define FPRINTF(X) { aioThisTick= ioLowResMSecs();  fprintf(stderr, "%8d %8d ", aioThisTick, aioThisTick - aioLastTick);  aioLastTick= aioThisTick;  fprintf X; }
#else
# define FPRINTF(X)
#endif

#if defined(DEBUG_TICKER)
  static char *ticks= "-\\|/";
  static char *ticker= "";
  #define DO_TICK()				\
  {						\
    fprintf(stderr, "\r%c\r", *ticker);		\
    if (!*ticker++) ticker= ticks;		\
  }
#else
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
  extern void forceInterruptCheck(int);	/* not really, but hey */

  FD_ZERO(&fdMask);
  FD_ZERO(&rdMask);
  FD_ZERO(&wrMask);
  FD_ZERO(&exMask);
  FD_ZERO(&xdMask);
  maxFd= 0;
  signal(SIGPIPE, SIG_IGN);
  signal(SIGIO,   forceInterruptCheck);
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


/* answer whether i/o becomes possible within the given number of microSeconds */

int aioPoll(int microSeconds)
{
  int	 fd, ms;
  fd_set rd, wr, ex;

  FPRINTF((stderr, "aioPoll(%d)\n", microSeconds));
  DO_TICK();

  /* get out early if there is no pending i/o and no need to relinquish cpu */

  if ((maxFd == 0) && (microSeconds == 0))
    return 0;

  rd= rdMask;
  wr= wrMask;
  ex= exMask;
  ms= ioMSecs();

  for (;;)
    {
      struct timeval tv;
      int n, now;
      tv.tv_sec=  microSeconds / 1000000;
      tv.tv_usec= microSeconds % 1000000;
      n= select(maxFd, &rd, &wr, &ex, &tv);
      if (n  > 0) break;
      if (n == 0) return 0;
      if (errno && (EINTR != errno))
	{
	  fprintf(stderr, "errno %d\n", errno);
	  perror("select");
	  return 0;
	}
      now= ioMSecs();
      microSeconds -= (now - ms) * 1000;
      if (microSeconds <= 0)
	return 0;
      ms= now;
    }

  for (fd= 0; fd < maxFd; ++fd)
    {
#     define _DO(FLAG, TYPE)				\
      {							\
	if (FD_ISSET(fd, &TYPE))			\
	  {						\
	    aioHandler handler= TYPE##Handler[fd];	\
	    FD_CLR(fd, &TYPE##Mask);			\
	    TYPE##Handler[fd]= undefinedHandler;	\
	    handler(fd, clientData[fd], FLAG);		\
	  }						\
      }
      _DO_FLAG_TYPE();
#     undef _DO
    }
  return 1;
}


/* sleep for microSeconds or until i/o becomes possible, avoiding
   sleeping in select() is timeout too small */

int aioSleep(int microSeconds)
{
  if (microSeconds < (1000000/60))	/* < 1 timeslice? */
    {
#    if defined(__MACH__)		/* can sleep with 1ms resolution */
      if (!aioPoll(0))
	{
	  struct timespec rqtp= { 0, microSeconds * 1000 };
	  struct timespec rmtp;
	  while ((nanosleep(&rqtp, &rmtp) < 0) && (errno == EINTR))
	    rqtp= rmtp;
	}
#    endif
      microSeconds= 0;			/* poll but don't block */
    }
  return aioPoll(microSeconds);
}


/* enable asynchronous notification for a descriptor */

void aioEnable(int fd, void *data, int flags)
{
  FPRINTF((stderr, "aioEnable(%d)\n", fd));
  if (fd < 0)
    {
      FPRINTF((stderr, "aioEnable(%d): IGNORED\n", fd));
      return;
    }
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
      /* enable non-blocking asynchronous i/o and delivery of SIGIO to the active process */
      int flags;
      FD_CLR(fd, &xdMask);
      if (        fcntl(fd, F_SETOWN, getpid()                    )  < 0)  perror("fcntl(F_SETOWN, getpid())");
      if ((flags= fcntl(fd, F_GETFL,  0                           )) < 0)  perror("fcntl(F_GETFL)");
      if (        fcntl(fd, F_SETFL,  flags | O_NONBLOCK | O_ASYNC)  < 0)  perror("fcntl(F_SETFL, O_ASYNC)");
    }
}


/* install/change the handler for a descriptor */

void aioHandle(int fd, aioHandler handlerFn, int mask)
{
  FPRINTF((stderr, "aioHandle(%d, %s, %d)\n", fd, handlerName(handlerFn), mask));
  if (fd < 0)
    {
      FPRINTF((stderr, "aioHandle(%d): IGNORED\n", fd));
      return;
    }
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
  if (fd < 0)
    {
      FPRINTF((stderr, "aioSuspend(%d): IGNORED\n", fd));
      return;
    }
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
  if (fd < 0)
    {
      FPRINTF((stderr, "aioDisable(%d): IGNORED\n", fd));
      return;
    }
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
