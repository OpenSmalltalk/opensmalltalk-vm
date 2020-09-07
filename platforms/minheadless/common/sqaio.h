/* sqaio.h -- asynchronous file i/o
 *
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
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

/* author: ian.piumarta@inria.fr
 */

#ifndef __sqaio_h
#define __sqaio_h


#define AIO_X	(1<<0)	/* handle for exceptions */
#define AIO_R	(1<<1)	/* handle for read */
#define AIO_W	(1<<2)	/* handle for write */
#define AIO_SEQ	(1<<3)	/* call handlers sequentially  */
#define AIO_EXT	(1<<4)	/* external fd -- don't close on aio shutdown  */

#define AIO_RW	(AIO_R | AIO_W)
#define AIO_RX	(AIO_R | AIO_X)
#define AIO_WX	(AIO_W | AIO_X)

#define AIO_RWX	(AIO_R | AIO_W | AIO_X)

extern void aioInit(void);
extern void aioFini(void);

/* Initialise `fd' for handling by AIO.  `flags' can be 0 (aio takes
 * over the descriptor entirely and the application should not assume
 * anything about its subsequent behaviour) or AIO_EXT (aio will never
 * set NBIO on `fd' or close it on behalf of the client).
 */
extern void aioEnable(int fd, void *clientData, int flags);

/* Declare an interest in one or more events on `fd'.  `mask' can be
 * any combination in AIO_[R][W][X].  `handlerFn' will be called the
 * next time any event in `mask' arrives on `fd' and will receive
 * `fd', the original `clientData' (see aioEnable) and a `flag'
 * containing ONE of AIO_{R,W,X} indicating which event occurred.  In
 * the event that the same handler is set for multiple events (either
 * by setting more than one bit in `mask', or by calling aioHandle
 * several times with different `mask's) and several events arrive
 * simultaneously for the descriptor, then `handlerFn' is called
 * multiple times -- once for each event in `mask'.  The `handlerFn'
 * will NOT be called again for the same event until the client calls
 * aioHandle with an appropriate `mask' (the handled event is removed
 * implicitly from the current mask before calling `handlerFn') .
 * (Calls to aioHandle are cumulative: successive `mask's are ORed
 * with the mask currently in effect for `fd'.)
 */
typedef void (*aioHandler)(int fd, void *clientData, int flag);
extern void aioHandle(int fd, aioHandler handlerFn, int mask);

/* Suspend handling of the events in `mask' for `fd'.
 */
extern void aioSuspend(int fd, int mask);

/* Disable further AIO handling of `fd'.  The descriptor is reset to its
 * default state (w.r.t. NBIO, etc.) but is NOT closed.
 */
extern void aioDisable(int fd);

/* Sleep for at most `microSeconds'.  Any event(s) arriving for
 * handled fd(s) will terminate the sleep, with the appropriate
 * handler(s) being called before returning.
 */
extern long aioPoll(long microSeconds);

/* As above, but avoid sleeping in select() if microSeconds is small
 * (less than a timeslice).  Handlers are called, if neccessary, at
 * the start and end of the sleep.
 */
extern long aioSleepForUsecs(long microSeconds);

extern unsigned long long ioUTCMicroseconds(void);
extern unsigned long long ioUTCMicrosecondsNow(void);

/* debugging stuff. */
#ifdef AIO_DEBUG
# ifdef ACORN
#   define FPRINTF(s) \
    do { \
      extern os_error privateErr; \
      extern void platReportError(os_error *e); \
      privateErr.errnum = (bits)0; \
      sprintf s; \
      platReportError((os_error *)&privateErr); \
    } while (0)
# else /* !ACORN */
    extern long aioLastTick, aioThisTick, ioMSecs(void);
	extern const char *__shortFileName(const char *);
#   define FPRINTF(X) do { \
	aioThisTick = ioMSecs(); \
	fprintf(stderr, "%8ld %4ld %s:%d ", aioThisTick, aioThisTick - aioLastTick,\
			__shortFileName(__FILE__),__LINE__); \
	aioLastTick = aioThisTick; \
	fprintf X; } while (0)
# endif /* ACORN */
#else /* !DEBUG */
# define FPRINTF(X)
#endif

#endif /* __sqaio_h */
