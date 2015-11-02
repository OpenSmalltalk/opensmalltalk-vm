/* sqUnixAsynchFile.c -- non-blocking file i/o
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
 *
 * Author: Ian.Piumarta@INRIA.Fr
 */

/*
  Experimental support for asynchronous file reading and writing.

  When a read or write operation is initiated, control is returned to Squeak
  immediately.  A semaphore is signaled when the operation completes, at which
  time the client can find out how many bytes were actually read or written
  and copy the results of the read operation from the file buffer into a Squeak
  buffer.  Only one operation may be in progress on a given file at a given time,
  but operations on different files may be done in parallel.

  The semaphore is signalled once for each transfer operation that is successfully
  started, even if that operation later fails.  Write operations always write
  their entire buffer if they succeed, but read operations may transfer less than
  their buffer size if they are started less than a buffer's size from the end
  of the file.
  
  The state of a file is kept in the following structure, which is stored directly
  in a Squeak ByteArray object:

    typedef struct {
	  int	sessionID;
	  void *state;		// private to the implementation
    } AsyncFile;

  The session ID is used to detect stale files--files that were open
  when the image was saved.  The state pointer of such files is meaningless.
  Async file handles use the same session ID as ordinary file handles.

  Note: These primitives are experimental!  They need not be implemented on
  every platform, and they may be withdrawn or replaced in a future release.
 */

#include "sq.h"
#include "AsynchFilePlugin.h"
#include "sqUnixAsynchFile.h"


/*** module initialisation ***/

#include "sqVirtualMachine.h"
#include "sqaio.h"

#include <sys/types.h>
#include <unistd.h>
#include <time.h>

int sqUnixAsyncFileSessionID= 0;

static struct VirtualMachine *vm= 0;

static fd_set fds;
static int    nfd= 0;

#define isValid(f)	(f->sessionID == sqUnixAsyncFileSessionID)
#define validate(f)	if ((!isValid(f)) || (!(f->state))) return vm->primitiveFail()

int asyncFileInit(void)
{
  vm= sqGetInterpreterProxy();
  sqUnixAsyncFileSessionID= clock() + time(0);
  FD_ZERO(&fds);
  nfd= 0;
  return 1;
}

int asyncFileShutdown(void)
{
  /* protect against calling stale aio handlers */
  int i;
  for (i= 0; i < nfd; ++i)
    if (FD_ISSET(i, &fds))
      aioDisable(i);
  nfd= 0;
  FD_ZERO(&fds);
  sqUnixAsyncFileSessionID= 0;
  return 1;
}


/*** module ***/


#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

#ifdef __GNUC__
# define	INLINE inline
#else
# define	INLINE
#endif

#define min(a,b)	((a) < (b) ? (a) : (b))
#define max(a,b)	((a) > (b) ? (a) : (b))

static void readHandler(int fd, void *data, int flags);
static void writeHandler(int fd, void *data, int flags);


INLINE static FilePtr newFileRec(int fd, int sema)
{
  FilePtr fp= (FilePtr)calloc(1, sizeof(FileRec));
  if (fp)
    {
      fp->fd=   fd;
      fp->sema= sema;
      fp->rd.status= Busy;	/* read not ready */
      fp->wr.status= Busy;	/* write not complete */
    }
  return fp;
}

INLINE static int allocateBuffer(struct FileBuf *buf, int size)
{
  if (buf->capacity >= size)
    return 1;
  if (buf->capacity > 0)
    {
      free(buf->bytes);
      buf->capacity= 0;
    }
  buf->bytes= (char *)malloc(size);
  if (!buf->bytes)
    {
      fprintf(stderr, "out of memory\n");
      return 0;
    }
  buf->capacity= size;
  return 1;
}


FilePtr asyncFileAttach(AsyncFile *f, int fd, int semaIndex)
{
  FilePtr fp= newFileRec(fd, semaIndex);
  if (fp)
    {
      f->sessionID= sqUnixAsyncFileSessionID;
      f->state= (void *)fp;
      aioEnable(fd, (void *)fp, 0);
      FD_SET(fd, &fds);
      nfd= max(nfd, fd + 1);
      return fp;	/* success */
    }
  fprintf(stderr, "out of memory\n");
  f->sessionID= 0;
  f->state= 0;
  return 0;
}


/*** public functions ***/


int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize,
		  int writeFlag, int semaIndex)
{
  int fd= 0;
  char *name= alloca(fileNameSize + 1);
  memcpy((void *)name, (void *)fileNamePtr, fileNameSize);
  name[fileNameSize]= '\0';
  /* if opening for wr then open for rw so that we can use these primitives
     to read bidirectional files (e.g., master ptys for interactive child
     processes) */
  fd= (writeFlag
       ? open(name, O_RDWR | O_CREAT, 0644)
       : open(name, O_RDONLY));
  if (fd >= 0)
    {
      if (asyncFileAttach(f, fd, semaIndex))
	return 0;	/* success */
      close(fd);
    }
  vm->primitiveFail();
  return 0;		/* failure */
}


int asyncFileClose(AsyncFile *f)
{
  FilePtr fp= 0;
  validate(f);
  if ((fp= (FilePtr)f->state))
    {
      if (fp->fd >= 0)
	{
	  aioDisable(fp->fd);
	  FD_CLR(fp->fd, &fds);
	  close(fp->fd);
	}
      if (fp->buf.bytes)
	free((void *)fp->buf.bytes);
      free((void *)fp);
      f->state= 0;
    }
  return 0;			/* success */
}


/* this no longer appears to be used */

int asyncFileRecordSize(void)
{
  fprintf(stderr, "asyncFileRecordSize() called -- why?\n");
  vm->primitiveFail();
  return 0;
}


int asyncFileReadResult(AsyncFile *f, void *bufferPtr, int bufferSize)
{
  FilePtr fp= 0;
  int n= 0;
  validate(f);
  fp= (FilePtr)f->state;
  n= read(fp->fd, bufferPtr, bufferSize);
  if      ((n < 0) && (errno == EWOULDBLOCK))
    return fp->rd.status= Busy;
  else if (n <= 0)
    return fp->rd.status= Error;
  else /* (n > 0) */
    fp->rd.pos += n;

  return fp->rd.status= n;
}


static void readHandler(int fd, void *data, int flags)
{
  signalSemaphoreWithIndex(((FilePtr)data)->sema);
}


int asyncFileReadStart(AsyncFile *f, int fPosition, int count)
{
  FilePtr fp= 0;
  validate(f);
  fp= (FilePtr)f->state;
  
  if ((  (fPosition >= 0))		/* (fPos < 0) => current position */
      && (fp->rd.pos != fPosition))	/* avoid EPIPE on pty */
    {
      if (lseek(fp->fd, fPosition, SEEK_SET) < 0)
	{
	  perror("lseek");
	  goto fail;
	}
      fp->rd.pos= fPosition;
    }
  fp->rd.status= Busy;
  aioHandle(fp->fd, readHandler, AIO_R);
  return 0;

 fail:
  fp->rd.status= Error;
  vm->primitiveFail();
  return 0;
}


int asyncFileWriteResult(AsyncFile *f)
{
  int n= 0;
  FilePtr fp= 0;
  validate(f);
  fp= (FilePtr)f->state;
  n= fp->wr.status;
  fp->wr.status= Busy;
  return n;
}


static void writeBuffer(FilePtr fp)
{
  int n= 0;
  while ((n= fp->buf.size - fp->buf.pos) > 0)
    {
      n= write(fp->fd, (void *)(fp->buf.bytes + fp->buf.pos), n);
      if (n < 0)
	switch (errno)
	  {
	  case EWOULDBLOCK:
	    aioHandle(fp->fd, writeHandler, AIO_W);
	    return;
	  default:
	    fp->wr.status= Error;
	    return;
	  }
      fp->buf.pos += n;
      fp->wr.pos += n;
    }
  /* completed */
  fp->wr.status= fp->buf.size;
  signalSemaphoreWithIndex(fp->sema);
}


static void writeHandler(int fd, void *data, int flags)
{
  writeBuffer((FilePtr)data);
}


int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int count)
{
  FilePtr fp= 0;
  validate(f);
  fp= (FilePtr)f->state;

  if ((  (fPosition >= 0))		/* (fPos < 0) => current position */
      && (fp->wr.pos != fPosition))	/* avoid EPIPE on tty */
    {
      if (lseek(fp->fd, fPosition, SEEK_SET) < 0)
	{
	  perror("lseek");
	  goto fail;
	}
      fp->wr.pos= fPosition;
    }

  if (count < 1)
    {
      fp->wr.status= 0;
      signalSemaphoreWithIndex(fp->sema);
      return 0;
    }

  if (!allocateBuffer(&fp->buf, count))
    {
      fprintf(stderr, "out of memory\n");
      goto fail;
    }

  memcpy((void *)fp->buf.bytes, bufferPtr, count);
  fp->buf.pos= 0;	/* current output pointer */
  fp->buf.size= count;	/* bytes to transfer */
  fp->wr.status= Busy;	/* transfer in progress */
  writeBuffer(fp);	/* begin transfer */
  return 0;

 fail:
  fp->wr.status= Error;
  vm->primitiveFail();
  return 0;
}
