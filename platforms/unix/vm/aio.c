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

#include "interp.h" /* For COGVM define */
#include "sqaio.h"
#include "sqAssert.h"

#ifdef HAVE_CONFIG_H

# include "config.h"

# ifdef HAVE_UNISTD_H
#   include <sys/types.h>
#   include <unistd.h>
# endif /* HAVE_UNISTD_H */

# ifdef NEED_GETHOSTNAME_P
    extern int gethostname();
# endif

# include <signal.h>
# include <stdio.h>
# include <string.h>
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
  # include <sys/file.h> /* FASYNC or ioctl FIOASYNC will be issued  */
  # define signal(a, b) sigset(a, b)
# endif

#else /* !HAVE_CONFIG_H -- assume lowest common demoninator */

# include <errno.h>
# include <signal.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <unistd.h>
# include <sys/types.h>
# include <sys/time.h>
# include <sys/select.h>
# include <sys/ioctl.h>
# include <fcntl.h>

#endif /* !HAVE_CONFIG_H */

/* function to inform the VM about idle time */
extern void addIdleUsecs(long idleUsecs);

#if defined(AIO_DEBUG)
long	aioLastTick = 0;
long	aioThisTick = 0;
long	aioDebugLogging = 0;
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

char *(*handlerNameChain)(aioHandler h) = 0;

static char *
handlerName(aioHandler h)
{
	char *name;

	if (h == undefinedHandler)
		return "undefinedHandler";
	if (handlerNameChain
	 && (name = handlerNameChain(h)))
		return name;
	return "***unknown***";
}
#endif /* AIO_DEBUG */

/* In various configurations it is necessary to use sigaltstack and the
 * SA_ONSTACK flag to ensure that signals are delivered on a dedicated signal
 * stack, rather than the user stack.  Two cases are described below.
 */

/* Allow the VM builder to override the default in their makefile. */
#if !defined(USE_SIGALTSTACK)

/* Especially useful on linux when LD_BIND_NOW is not in effect and the
 * dynamic linker happens to run in a signal handler.
 */
# if ITIMER_HEARTBEAT
#	define USE_SIGALTSTACK 1
# endif

#endif /* !defined(USE_SIGALTSTACK) */

#if USE_SIGALTSTACK
/* If the ticker is run from the heartbeat signal handler one needs to use an
 * alternative stack to avoid overflowing the VM's stack pages.  Keep
 * the structure around for reference during debugging.
 */
# define SIGNAL_STACK_SIZE (1024 * sizeof(void *) * 16)
static stack_t signal_stack;
#endif /* USE_SIGALTSTACK */

/* initialise asynchronous i/o */

static int stderrIsAFile = 0; // for pollpip to avoid cluttering logs

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

	stderrIsAFile = !isatty(fileno(stderr));

	signal(SIGPIPE, SIG_IGN);
#if !USE_SIGALTSTACK
	signal(SIGIO, forceInterruptCheck);
#else
# define max(x,y) (((x)>(y))?(x):(y))
	if (!signal_stack.ss_size) {
		signal_stack.ss_flags = 0;
		signal_stack.ss_size = max(SIGNAL_STACK_SIZE,MINSIGSTKSZ);
		if (!(signal_stack.ss_sp = malloc(signal_stack.ss_size))) {
			perror("ioInitHeartbeat malloc");
			exit(1);
		}
		if (sigaltstack(&signal_stack, 0) < 0) {
			perror("ioInitHeartbeat sigaltstack");
			exit(1);
		}
	}
	{	struct sigaction sigio_action;

		sigio_action.sa_sigaction = forceInterruptCheck;
		sigio_action.sa_flags = SA_RESTART | SA_ONSTACK;
		sigemptyset(&sigio_action.sa_mask);
		if (sigaction(SIGIO, &sigio_action, 0)) {
			perror("aioInit sigaction SIGIO");
			exit(1);
		}
	}
#endif /* USE_SIGALTSTACK */
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
long pollpipOutput = 0;

#define TICKS_PER_CHAR 10
#define DO_TICK(bool)											\
do if ((bool) && !(++tickCount % TICKS_PER_CHAR)) {				\
	if (!*ticker) ticker = ticks;								\
	fprintf(stderr, stderrIsAFile ? "%c" : "\r%c\r", *ticker++);\
	pollpipOutput = 1;											\
} while (0)

long
aioPoll(long microSeconds)
{
	int	fd;
	fd_set	rd, wr, ex;
	unsigned long long us;
#if AIO_DEBUG
	struct  sigaction current_sigio_action;
	extern void forceInterruptCheck(int);	/* not really, but hey */
#endif

	DO_TICK(SHOULD_TICK());

#if defined(AIO_DEBUG)
# if AIO_DEBUG >= 2
	FPRINTF((stderr, "aioPoll(%ld)\n", microSeconds));
# endif
	// check that our signal handler is in place.
	// If it isn't, things aren't right.
	sigaction(SIGIO, NULL, &current_sigio_action);
	assert(current_sigio_action.sa_handler == forceInterruptCheck);
#endif
	/*
	 * get out early if there is no pending i/o and no need to relinquish
	 * cpu
	 */

#ifdef TARGET_OS_IS_IPHONE
	if (maxFd == 0)
		return 0;
#else
	if (maxFd == 0 && microSeconds == 0)
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
		if (n == 0) {
			if (microSeconds)
				addIdleUsecs(microSeconds);
			return 0;
		}
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
	/* This makes no sense at all.  This simply increases latency.  It calls
	 * aioPoll and then immediately enters a nonasleep for the requested time.
	 * Hence if there is pending i/o it will prevent responding to that i/o for
	 * the requested sleep.  Not a good idea. eem May 2017.
	 */
#if defined(HAVE_NANOSLEEP) && 0
	if (microSeconds < (1000000 / 60)) {	/* < 1 timeslice? */
		if (!aioPoll(0)) {
			struct timespec rqtp = {0, microSeconds * 1000};
			struct timespec rmtp = {0, 0};

			nanosleep(&rqtp, &rmtp);
			addIdleUsecs((rqtp.tv_nsec - rmtp.tv_nsec) / 1000);
			microSeconds = 0;	/* poll but don't block */
		}
	}
#endif
	/* This makes perfect sense.  Poll with a timeout of microSeconds, returning
	 * when the timeout has elapsed or i/o is possible, whichever is sooner.
	 */
	return aioPoll(microSeconds);
}


/* enable asynchronous notification for a descriptor */

void
aioEnable(int fd, void *data, int flags)
{
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
		FPRINTF((stderr, "aioEnable(%d): external\n", fd));
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
# if defined(F_SETNOSIGPIPE)
		if ((arg = fcntl(fd, F_SETNOSIGPIPE, 1)) < 0)
			perror("fcntl(F_GETFL)");
# endif
		FPRINTF((stderr, "aioEnable(%d): Elicit SIGIO via O_ASYNC/fcntl\n", fd));

#elif defined(FASYNC)
		if (fcntl(fd, F_SETOWN, getpid()) < 0)
			perror("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			perror("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | FASYNC) < 0)
			perror("fcntl(F_SETFL, FASYNC)");
# if defined(F_SETNOSIGPIPE)
		if ((arg = fcntl(fd, F_SETNOSIGPIPE, 1)) < 0)
			perror("fcntl(F_GETFL)");
# endif
		FPRINTF((stderr, "aioEnable(%d): Elicit SIGIO via FASYNC/fcntl\n", fd));

#elif defined(FIOASYNC)
		arg = getpid();
		if (ioctl(fd, SIOCSPGRP, &arg) < 0)
			perror("ioctl(SIOCSPGRP, getpid())");
		arg = 1;
		if (ioctl(fd, FIOASYNC, &arg) < 0)
			perror("ioctl(FIOASYNC, 1)");
		FPRINTF((stderr, "aioEnable(%d): Elicit SIGIO via FIOASYNC/fcntl\n", fd));
#else
		FPRINTF((stderr, "aioEnable(%d): UNABLE TO ELICIT SIGIO!!\n", fd));
#endif
	}
}

#if defined(AIO_DEBUG)
const char *
aioEnableStatusName(int fd)
{
# if defined(O_ASYNC)
#	define FCNTL_ASYNC_FLAG O_ASYNC
# elif defined(FASYNC)
#	define FCNTL_ASYNC_FLAG FASYNC
# endif

# if !defined(FCNTL_ASYNC_FLAG)
	return "";
# else
	int flags = fcntl(fd,F_GETFL,0);
	if (flags < 0)
		return "fcntl(fd,F_GETFL,0) < 0";

	if ((flags & FCNTL_ASYNC_FLAG))
		if ((flags & O_NONBLOCK))
			return "O_ASYNC|O_NONBLOCK";
		else
			return "O_ASYNC";
	else if ((flags & O_NONBLOCK))
		return "O_NONBLOCK";

	return "!fcntl(fd,F_GETFL,0) !!";
# endif
}

const char *aioMaskNames[]
= { "0", "AIO_X", "AIO_R", "AIO_RX", "AIO_W", "AIO_WX", "AIO_RW", "AIO_RWX" };

#endif // AIO_DEBUG


/* install/change the handler for a descriptor */

void
aioHandle(int fd, aioHandler handlerFn, int mask)
{
	FPRINTF((stderr, "aioHandle(%d, %s, %d/%s)\n", fd, handlerName(handlerFn), mask, aioMaskName(mask)));
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
