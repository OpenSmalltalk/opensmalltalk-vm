/* sqaio -- asynchronous I/O support  */

#include "sqaio.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <errno.h>


#define TRACE 0
#if TRACE
#include <stdarg.h>
static tprintf(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vprintf(fmt, ap);
}
#else
static void tprintf(const char *fmt, ...)
{
  /* do nothing */
}
#endif
	       

/* data structures to remember registered handlers */
static AioHandler  handler[FD_SETSIZE];
static void* handlerData[FD_SETSIZE];


/* the largest descriptor currently registered */
static int lastSocket;

/* select masks that are currently in effect */
static fd_set	readMask, writeMask, exceptionMask;



void aioInitialize() 
{
  int i;

  tprintf("aioInitialize()\n");
  
  for(i=0; i<FD_SETSIZE; i++) {
    handler[i] = NULL;
    handlerData[i] = NULL;
  }
     
  lastSocket = -1;

  FD_ZERO(&readMask);
  FD_ZERO(&writeMask);
  FD_ZERO(&exceptionMask);
}




void aioHandle(int fd, AioHandler handlerFn, void *data, int flags) 
{
  tprintf("aioHandle(%d, %p, %p, ", fd, handlerFn, data);
  if(flags & AIO_RD)
    tprintf("AIO_RD|");
  if(flags & AIO_WR)
    tprintf("AIO_WR|");
  tprintf("AIO_EX)\n");

  /* sanity check */
  if(fd >= FD_SETSIZE) {
    fprintf(stderr, "aioHandle: fd is too large! (%d)\n", fd);
    return;
  }
  
  /* special case if no events are of interest */
  if(flags == 0) {
    aioStopHandling(fd);
    return;
  }
     

  /* sanity check: did someone forget to unregister a dead descriptor? */
  if ((handler[fd] != NULL) && (handlerData[fd] != data))
    {
      fprintf(stderr,
	      "aioHandle: registering different data on same descriptor!!  %d %p %p\n",	      fd, handlerData[fd], data);
    }
  handlerData[fd] = data;
  handler[fd]= handlerFn;

     
  /* update lastSocket */
  if (fd > lastSocket)
    lastSocket= fd;

  /* update the select flags */
  if (flags & AIO_RD)
    FD_SET(fd, &readMask);
  else
    FD_CLR(fd, &readMask);
  
  if (flags & AIO_WR)
    FD_SET(fd, &writeMask);
  else
    FD_CLR(fd, &writeMask);
  

  /* always watch for exceptions */
  FD_SET(fd, &exceptionMask);
}




/* disable listening on a descriptor */
void aioStopHandling(int fd) 
{
  tprintf("aioStopHandling(%d)\n", fd);
  
  handlerData[fd] = NULL;
  handler[fd] = NULL;

  FD_CLR(fd, &readMask);
  FD_CLR(fd, &writeMask);
  FD_CLR(fd, &exceptionMask);
  

  /* update lastSocket */
  while(lastSocket >= 0 && handlerData[lastSocket])
    lastSocket -= 1;
}



void aioPoll(int waitMicros)
{
  int fd;
  fd_set rd, wr, ex;
  struct timeval tv;

  /* get out early if there is no pending i/o and no need to relinquish cpu */
  if ((lastSocket == 0) && (waitMicros == 0))
    return;


  /* run select() */
  rd= readMask;
  wr= writeMask;
  ex= exceptionMask;
  tv.tv_sec=  waitMicros / 1000000;
  tv.tv_usec= waitMicros % 1000000;

  {
    int result;

    do
      {
	result= select(lastSocket+1, &rd, &wr, &ex, &tv);
      }
    while ((result < 0) && (errno == EINTR))
      ;
    if (result < 0) {
      perror("select");
      return;
    }
    if(result == 0) {
      /* no activity */
      return;
    }
  }
  
  for (fd=0; fd <= lastSocket; fd++)
    {
      if(handler[fd] != NULL) {
	int readFlag, writeFlag, exceptionFlag;
	  
	readFlag = FD_ISSET(fd, &rd);
	writeFlag = FD_ISSET(fd, &wr);
	exceptionFlag = FD_ISSET(fd, &ex);

	if(readFlag || writeFlag || exceptionFlag) {
	  /* something happened on this descriptor -- call
	     its handler */
	  (handler[fd])(handlerData[fd],
			readFlag, writeFlag, exceptionFlag);
	}
      }
    }
}
