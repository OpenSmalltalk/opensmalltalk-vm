/* aio.c -- asynchronous file i/o
 * 
 *   Copyright (C) 1996-2006 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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

/* Authors: Ian.Piumarta@squeakland.org, eliot.miranda@gmail.com
 * 
 * Last edited: Tue Mar 29 13:06:00 PDT 2016
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

# if HAVE_KQUEUE
#   include <sys/event.h>
# elif HAVE_EPOLL
#   include <sys/epoll.h>
# elif HAVE_SELECT
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

# if __sun__
  # include <sys/sockio.h>
  # define signal(a, b) sigset(a, b)
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

#endif /* !HAVE_CONFIG_H */


#if defined(AIO_DEBUG)
long	aioLastTick = 0;
long	aioThisTick = 0;

#endif

#define _DO_FLAG_TYPE()	do { _DO(AIO_R, rd) _DO(AIO_W, wr) _DO(AIO_X, ex) } while (0)

static aioHandler rdHandler[FD_SETSIZE];
static aioHandler wrHandler[FD_SETSIZE];
static aioHandler exHandler[FD_SETSIZE];

static void *clientData[FD_SETSIZE];

static int maxFd;
static fd_set fdMask;		/* handled by aio	 */
static fd_set rdMask;		/* handle read		 */
static fd_set wrMask;		/* handle write		 */
static fd_set exMask;		/* handle exception	 */
static fd_set xdMask;		/* external descriptor	 */


static void 
undefinedHandler(int fd, void *clientData, int flags)
{
	fprintf(stderr, "undefined handler called (fd %d, flags %x)\n", fd, flags);
}

#ifdef AIO_DEBUG
const char *
__shortFileName(const char *full__FILE__name)
{
	const char *p = strrchr(full__FILE__name, '/');

	return p ? p + 1 : full__FILE__name;
}
static char *
handlerName(aioHandler h)
{
	if (h == undefinedHandler)
		return "undefinedHandler";
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

void 
aioInit(void)
{
	extern void forceInterruptCheck(int);	/* not really, but hey */

	FD_ZERO(&fdMask);
	FD_ZERO(&rdMask);
	FD_ZERO(&wrMask);
	FD_ZERO(&exMask);
	FD_ZERO(&xdMask);
	maxFd = 0;
	signal(SIGPIPE, SIG_IGN);
	signal(SIGIO, forceInterruptCheck);
}


/* disable handlers and close all handled non-exteral descriptors */

void 
aioFini(void)
{
	int	fd;

	for (fd = 0; fd < maxFd; fd++)
		if (FD_ISSET(fd, &fdMask) && !(FD_ISSET(fd, &xdMask))) {
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


/*
 * answer whether i/o becomes possible within the given number of
 * microSeconds
 */
#define max(x,y) (((x)>(y))?(x):(y))

long	pollpip = 0;		/* set in sqUnixMain.c by -pollpip arg */

#if COGMTVM
/*
 * If on the MT VM and pollpip > 1 only pip if a threaded FFI call is in
 * progress, which we infer from disownCount being non-zero.
 */
extern long disownCount;

# define SHOULD_TICK() (pollpip == 1 || (pollpip > 1 && disownCount))
#else
# define SHOULD_TICK() pollpip
#endif

static char *ticks = "-\\|/";
static char *ticker = "";
static int tickCount = 0;

#define TICKS_PER_CHAR 10
#define DO_TICK(bool)				\
do if ((bool) && !(++tickCount % TICKS_PER_CHAR)) {		\
	fprintf(stderr, "\r%c\r", *ticker);		\
	if (!*ticker++) ticker= ticks;			\
} while (0)

long 
aioPoll(long microSeconds)
{
	int	fd;
	fd_set	rd, wr, ex;
	unsigned long long us;

	FPRINTF((stderr, "aioPoll(%ld)\n", microSeconds));
	DO_TICK(SHOULD_TICK());

	/*
	 * get out early if there is no pending i/o and no need to relinquish
	 * cpu
	 */

#ifdef TARGET_OS_IS_IPHONE
	if (maxFd == 0)
		return 0;
#else
	if ((maxFd == 0) && (microSeconds == 0))
		return 0;
#endif

	rd = rdMask;
	wr = wrMask;
	ex = exMask;
	us = ioUTCMicroseconds();

	for (;;) {
		struct timeval tv;
		int	n;
		unsigned long long now;

		tv.tv_sec = microSeconds / 1000000;
		tv.tv_usec = microSeconds % 1000000;
		n = select(maxFd, &rd, &wr, &ex, &tv);
		if (n > 0)
			break;
		if (n == 0)
			return 0;
		if (errno && (EINTR != errno)) {
			fprintf(stderr, "errno %d\n", errno);
			perror("select");
			return 0;
		}
		now = ioUTCMicroseconds();
		microSeconds -= max(now - us, 1);
		if (microSeconds <= 0)
			return 0;
		us = now;
	}

	for (fd = 0; fd < maxFd; ++fd) {
#undef _DO
#define _DO(FLAG, TYPE)								\
		if (FD_ISSET(fd, &TYPE)) {					\
			aioHandler handler= TYPE##Handler[fd];	\
			FD_CLR(fd, &TYPE##Mask);				\
			TYPE##Handler[fd]= undefinedHandler;	\
			handler(fd, clientData[fd], FLAG);		\
		}
		_DO_FLAG_TYPE();
	}
	return 1;
}


/*
 * sleep for microSeconds or until i/o becomes possible, avoiding sleeping in
 * select() if timeout too small
 */

long 
aioSleepForUsecs(long microSeconds)
{
#if defined(HAVE_NANOSLEEP)
	if (microSeconds < (1000000 / 60)) {	/* < 1 timeslice? */
		if (!aioPoll(0)) {
			struct timespec rqtp = {0, microSeconds * 1000};
			struct timespec rmtp;

			nanosleep(&rqtp, &rmtp);
			microSeconds = 0;	/* poll but don't block */
		}
	}
#endif
	return aioPoll(microSeconds);
}


/* enable asynchronous notification for a descriptor */

void 
aioEnable(int fd, void *data, int flags)
{
	FPRINTF((stderr, "aioEnable(%d)\n", fd));
	if (fd < 0) {
		FPRINTF((stderr, "aioEnable(%d): IGNORED\n", fd));
		return;
	}
	if (FD_ISSET(fd, &fdMask)) {
		fprintf(stderr, "aioEnable: descriptor %d already enabled\n", fd);
		return;
	}
	clientData[fd] = data;
	rdHandler[fd] = wrHandler[fd] = exHandler[fd] = undefinedHandler;
	FD_SET(fd, &fdMask);
	FD_CLR(fd, &rdMask);
	FD_CLR(fd, &wrMask);
	FD_CLR(fd, &exMask);
	if (fd >= maxFd)
		maxFd = fd + 1;
	if (flags & AIO_EXT) {
		FD_SET(fd, &xdMask);
		/* we should not set NBIO ourselves on external descriptors! */
	}
	else {
		/*
		 * enable non-blocking asynchronous i/o and delivery of SIGIO
		 * to the active process
		 */
		int	arg;

		FD_CLR(fd, &xdMask);

#if defined(O_ASYNC)
		if (fcntl(fd, F_SETOWN, getpid()) < 0)
			perror("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			perror("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | O_ASYNC) < 0)
			perror("fcntl(F_SETFL, O_ASYNC)");

#elif defined(FASYNC)
		if (fcntl(fd, F_SETOWN, getpid()) < 0)
			perror("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			perror("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | FASYNC) < 0)
			perror("fcntl(F_SETFL, FASYNC)");

#elif defined(FIOASYNC)
		arg = getpid();
		if (ioctl(fd, SIOCSPGRP, &arg) < 0)
			perror("ioctl(SIOCSPGRP, getpid())");
		arg = 1;
		if (ioctl(fd, FIOASYNC, &arg) < 0)
			perror("ioctl(FIOASYNC, 1)");
#endif
	}
}


/* install/change the handler for a descriptor */

void 
aioHandle(int fd, aioHandler handlerFn, int mask)
{
	FPRINTF((stderr, "aioHandle(%d, %s, %d)\n", fd, handlerName(handlerFn), mask));
	if (fd < 0) {
		FPRINTF((stderr, "aioHandle(%d): IGNORED\n", fd));
		return;
	}
#undef _DO
#define _DO(FLAG, TYPE)					\
    if (mask & FLAG) {					\
      FD_SET(fd, &TYPE##Mask);			\
      TYPE##Handler[fd]= handlerFn;		\
    }
	_DO_FLAG_TYPE();
}


/* temporarily suspend asynchronous notification for a descriptor */

void 
aioSuspend(int fd, int mask)
{
	if (fd < 0) {
		FPRINTF((stderr, "aioSuspend(%d): IGNORED\n", fd));
		return;
	}
	FPRINTF((stderr, "aioSuspend(%d)\n", fd));
#undef _DO
#define _DO(FLAG, TYPE)							\
	if (mask & FLAG) {							\
		FD_CLR(fd, &TYPE##Mask);				\
		TYPE##Handler[fd]= undefinedHandler;	\
	}
	_DO_FLAG_TYPE();
}


/* definitively disable asynchronous notification for a descriptor */

void 
aioDisable(int fd)
{
	if (fd < 0) {
		FPRINTF((stderr, "aioDisable(%d): IGNORED\n", fd));
		return;
	}
	FPRINTF((stderr, "aioDisable(%d)\n", fd));
	aioSuspend(fd, AIO_RWX);
	FD_CLR(fd, &xdMask);
	FD_CLR(fd, &fdMask);
	rdHandler[fd] = wrHandler[fd] = exHandler[fd] = 0;
	clientData[fd] = 0;
	/* keep maxFd accurate (drops to zero if no more sockets) */
	while (maxFd && !FD_ISSET(maxFd - 1, &fdMask))
		--maxFd;
}
