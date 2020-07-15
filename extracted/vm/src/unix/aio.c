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
#include "pharovm/debug.h"
#include "pharovm/semaphores/platformSemaphore.h"
#include "sqMemoryFence.h"

#include <sys/types.h>
#include <sys/socket.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/select.h>
#include <sys/ioctl.h>
#include <fcntl.h>

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

/*
 * This is important, the AIO poll should only do a long pause if there is no pending signals for semaphores.
 * Check ExternalSemaphores to understand this function.
 */
int isPendingSemaphores();

void heartbeat_poll_enter(long microSeconds);
void heartbeat_poll_exit(long microSeconds);
static int aio_handle_events(long microSeconds);

Semaphore* interruptFIFOMutex;
int pendingInterruption;
int aio_in_sleep = 0;
int aio_request_interrupt = 0;

static void 
undefinedHandler(int fd, void *clientData, int flags)
{
	logError("Undefined handler called (fd %d, flags %x)\n", fd, flags);
}

/* initialise asynchronous i/o */

int signal_pipe_fd[2];

void 
aioInit(void)
{
	extern void forceInterruptCheck(int);	/* not really, but hey */
	int arg;

	interruptFIFOMutex = platform_semaphore_new(1);

	FD_ZERO(&fdMask);
	FD_ZERO(&rdMask);
	FD_ZERO(&wrMask);
	FD_ZERO(&exMask);
	FD_ZERO(&xdMask);
	maxFd = 0;

	if (pipe(signal_pipe_fd) != 0) {
	    logErrorFromErrno("pipe");
	    exit(-1);
	}

	if ((arg = fcntl(signal_pipe_fd[0], F_GETFL, 0)) < 0)
		logErrorFromErrno("fcntl(F_GETFL)");
	if (fcntl(signal_pipe_fd[0], F_SETFL, arg | O_NONBLOCK | O_ASYNC ) < 0)
		logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");

	if ((arg = fcntl(signal_pipe_fd[1], F_GETFL, 0)) < 0)
		logErrorFromErrno("fcntl(F_GETFL)");
	if (fcntl(signal_pipe_fd[1], F_SETFL, arg | O_NONBLOCK | O_ASYNC | O_APPEND) < 0)
		logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");


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
#ifndef max
# define max(a, b)  (((a) > (b)) ? (a) : (b))
#endif


volatile int aio_requests = 0;
volatile int aio_responses = 0;

/*
 * I Try to clear all the data available in the pipe, so it does not passes the limit of data.
 * Do not call me outside the mutex area of interruptFIFOMutex.
 */
void
aio_flush_pipe(int fd){

	int bytesRead;
	char buf[1024];

	interruptFIFOMutex->wait(interruptFIFOMutex);
	if(pendingInterruption){
		pendingInterruption = false;
	}

	do {
		bytesRead = read(fd, &buf, 1024);

		if(bytesRead == -1){

			if(errno == EAGAIN || errno == EWOULDBLOCK){
				interruptFIFOMutex->signal(interruptFIFOMutex);
				return;
			}

			logErrorFromErrno("pipe - read");

			interruptFIFOMutex->signal(interruptFIFOMutex);
			return;
		}

	} while(bytesRead > 0);

	interruptFIFOMutex->signal(interruptFIFOMutex);
}

long
aioPoll(long microSeconds){
	long timeout;

	interruptFIFOMutex->wait(interruptFIFOMutex);

	if(pendingInterruption || isPendingSemaphores()){
		timeout = 0;
	}else{
		timeout = microSeconds;
	}

	if(pendingInterruption){
		pendingInterruption = false;
	}

	interruptFIFOMutex->signal(interruptFIFOMutex);

	return aio_handle_events(timeout);
}

static int
aio_handle_events(long microSeconds){
	int	fd;
	fd_set	rd, wr, ex;
	unsigned long long us;
	int maxFdToUse;
	long remainingMicroSeconds;

	/*
	 * Copy the Masks as they are used to know which
	 * FD wants which event
	 */
	rd = rdMask;
	wr = wrMask;
	ex = exMask;
	us = ioUTCMicroseconds();

	remainingMicroSeconds = microSeconds;

	FD_SET(signal_pipe_fd[0], &rd);

	maxFdToUse = maxFd > (signal_pipe_fd[0] + 1) ? maxFd : signal_pipe_fd[0] + 1;

	heartbeat_poll_enter(microSeconds);

	for (;;) {
		struct timeval tv;
		int	n;
		unsigned long long now;

		tv.tv_sec = remainingMicroSeconds / 1000000;
		tv.tv_usec = remainingMicroSeconds % 1000000;

		n = select(maxFdToUse, &rd, &wr, &ex, &tv);

		if (n > 0)
			break;
		if (n == 0) {
			if (remainingMicroSeconds)
				addIdleUsecs(remainingMicroSeconds);
			heartbeat_poll_exit(microSeconds);
			return 0;
		}
		if (errno && (EINTR != errno)) {
            logError("errno %d\n", errno);
            logErrorFromErrno("select");
			heartbeat_poll_exit(microSeconds);
			return 0;
		}
		now = ioUTCMicroseconds();
		remainingMicroSeconds -= max(now - us, 1);

		if (remainingMicroSeconds <= 0){
			heartbeat_poll_exit(microSeconds);
			return 0;
		}
		us = now;
	}

	heartbeat_poll_exit(microSeconds);
	aio_flush_pipe(signal_pipe_fd[0]);

    // We clear signal_pipe_fd because when it arrives here we do not care anymore
    // about it, but it may cause a crash if it is set because we do not have
    // a handler for it. Another solution could be to just add a handler to signal_pipe_fd
    // but for now it does not seems needed.
    FD_CLR(signal_pipe_fd[0], &rd);
    
	for (fd = 0; fd < maxFd; ++fd) {
        aioHandler handler;
        
		//_DO_FLAG_TYPE();
        //_DO(AIO_R, rd)
        if (FD_ISSET(fd, &rd)) {
            handler = rdHandler[fd];
            FD_CLR(fd, &rdMask);
            handler(fd, clientData[fd], AIO_R);
            rdHandler[fd]= undefinedHandler;
        }
        //_DO(AIO_W, wr)
        if (FD_ISSET(fd, &wr)) {
            handler = wrHandler[fd];
            FD_CLR(fd, &wrMask);
            handler(fd, clientData[fd], AIO_W);
            wrHandler[fd]= undefinedHandler;
        }
        //_DO(AIO_X, ex)
        if (FD_ISSET(fd, &ex)) {
            handler = exHandler[fd];
            FD_CLR(fd, &exMask);
            handler(fd, clientData[fd], AIO_X);
            exHandler[fd]= undefinedHandler;
        }
	}

	return 1;
}

/*
 * This function is used to interrupt a aioPoll.
 * Used when signalling a Pharo semaphore to re-wake the VM and execute code of the image.
 */

void
aioInterruptPoll(){
	int n;

	n = write(signal_pipe_fd[1], "1", 1);
	if(n != 1){
		logErrorFromErrno("write to pipe");
	}
	fsync(signal_pipe_fd[1]);

	interruptFIFOMutex->wait(interruptFIFOMutex);
	pendingInterruption = true;
	interruptFIFOMutex->signal(interruptFIFOMutex);
}

void 
aioEnable(int fd, void *data, int flags)
{
	if (fd < 0) {
		logWarn("AioEnable(%d): IGNORED - Negative Number", fd);
		return;
	}
	if (FD_ISSET(fd, &fdMask)) {
		logWarn("AioEnable: descriptor %d already enabled", fd);
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
			logErrorFromErrno("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			logErrorFromErrno("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | O_ASYNC) < 0)
			logErrorFromErrno("fcntl(F_SETFL, O_ASYNC)");

#elif defined(FASYNC)
		if (fcntl(fd, F_SETOWN, getpid()) < 0)
			logErrorFromErrno("fcntl(F_SETOWN, getpid())");
		if ((arg = fcntl(fd, F_GETFL, 0)) < 0)
			logErrorFromErrno("fcntl(F_GETFL)");
		if (fcntl(fd, F_SETFL, arg | O_NONBLOCK | FASYNC) < 0)
			logErrorFromErrno("fcntl(F_SETFL, FASYNC)");

#elif defined(FIOASYNC)
		arg = getpid();
		if (ioctl(fd, SIOCSPGRP, &arg) < 0)
			logErrorFromErrno("ioctl(SIOCSPGRP, getpid())");
		arg = 1;
		if (ioctl(fd, FIOASYNC, &arg) < 0)
			logErrorFromErrno("ioctl(FIOASYNC, 1)");
#endif
	}
}


/* install/change the handler for a descriptor */

void 
aioHandle(int fd, aioHandler handlerFn, int mask)
{
	if (fd < 0) {
		logWarn("aioHandle(%d): IGNORED - Negative FD", fd);
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
		logWarn("aioSuspend(%d): IGNORED - Negative FD\n", fd);
		return;
	}

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
		logWarn( "aioDisable(%d): IGNORED - Negative FD\n", fd);
		return;
	}
	aioSuspend(fd, AIO_RWX);
	FD_CLR(fd, &xdMask);
	FD_CLR(fd, &fdMask);
	rdHandler[fd] = wrHandler[fd] = exHandler[fd] = 0;
	clientData[fd] = 0;
	/* keep maxFd accurate (drops to zero if no more sockets) */
	while (maxFd && !FD_ISSET(maxFd - 1, &fdMask))
		--maxFd;
}
