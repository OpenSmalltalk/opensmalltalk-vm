//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

// This is sqRPCNetPlugin.c
// It provides unix like sockets for Squeak.
// If you understand sockets and RISC OS, feel free to offer to improve it.

/* Shamelessly copied from Unix socket support.
 *
 * Original Author: Ian Piumarta (ian.piumarta@inria.fr)
 * Minor Acorn changes: Tim Rowledge (tim@rowledge.org)
 */

/* sqUnixSocket.c -- Unix socket support
 *
 *   Copyright (C) 1996-2003 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *
 *     You are NOT ALLOWED to distribute modified versions of this file
 *     under its original name.  If you want to modify it and then make
 *     your modifications available publicly, rename the file first.
 *
 *   This file is part of Unix Squeak.
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

/* Author: Ian.Piumarta@inria.fr
 *
 * Last edited: 2004-04-02 14:21:17 by piumarta on emilia.local
 *
 * Support for BSD-style "accept" primitives contributed by:
 *	Lex Spoon <lex@cc.gatech.edu>
 *
 * Notes:
 * 	Sockets are completely asynchronous, but the resolver is still
 *	synchronous.
 *
 * BUGS:
 *	Now that the image has real UDP primitives, the TCP/UDP duality in
 *	many of the connection-oriented functions should be removed and
 * 	cremated.
 */

#include "sq.h"
#include "SocketPlugin.h"
#include "aio.h"
// define this to get lots of debug notifiers
//#define DEBUG

#undef	AIO_DEBUG

#ifdef ACORN
# include <time.h>
# define __time_t
# include <signal.h>
# include "inetlib.h"
# include "socklib.h"
# include "netdb.h"
# include "unixlib.h"
# include "sys/ioctl.h"
# include "sys/errno.h"
# define h_errno errno
# define MAXHOSTNAMELEN 256
# define socklen_t int
# define strncpy(dst, src, len) copyNCharsFromTo(len, src, dst)

#else /* !ACORN */

# ifdef NEED_GETHOSTNAME_P
    extern int gethostname();
# endif
# ifdef HAVE_SYS_TIME_H
#   include <sys/time.h>
# else
#   include <time.h>
# endif
# include <sys/param.h>
# include <sys/socket.h>
# include <netinet/in.h>
# include <netinet/udp.h>
# include <netinet/tcp.h>
# include <arpa/inet.h>
# include <netdb.h>
# include <errno.h>
# include <unistd.h>

#endif /* !ACORN */

/* Solaris sometimes fails to define this in netdb.h */
#ifndef  MAXHOSTNAMELEN
# define MAXHOSTNAMELEN	256
#endif


/* debugging stuff. can probably be deleted */

#ifdef DEBUG
#define FPRINTF(X) fprintf X
#else /* !DEBUG */
# define FPRINTF(X)
#endif

/* debugging stuff; can probably be deleted */
# define DO_TICK()


/*** Socket types ***/

#define TCPSocketType	 	0
#define UDPSocketType	 	1


/*** Resolver states ***/

#define ResolverUninitialised	0
#define ResolverSuccess		1
#define ResolverBusy		2
#define ResolverError		3


/*** TCP Socket states ***/

#define Invalid			-1
#define Unconnected		 0
#define WaitingForConnection	 1
#define Connected		 2
#define OtherEndClosed		 3
#define ThisEndClosed		 4

#define LINGER_SECS		 1

static int thisNetSession= 0;
static int one= 1;

static char   localHostName[MAXHOSTNAMELEN];
static u_long localHostAddress;	/* GROSS IPv4 ASSUMPTION! */

typedef struct privateSocketStruct
{
  int s;			/* Unix socket */
  int connSema;			/* connection io notification semaphore */
  int readSema;			/* read io notification semaphore */
  int writeSema;		/* write io notification semaphore */
  int sockState;		/* connection + data state */
  int sockError;		/* errno after socket error */
  struct sockaddr_in peer;	/* default send/recv address for UDP */
  int multiListen;		/* whether to listen for multiple connections */
  int acceptedSock;		/* a connection that has been accepted */
} privateSocketStruct;

#define CONN_NOTIFY	(1<<0)
#define READ_NOTIFY	(1<<1)
#define WRITE_NOTIFY	(1<<2)

#define PING(S,EVT)						\
{								\
  interpreterProxy->signalSemaphoreWithIndex((S)->EVT##Sema);	\
  FPRINTF((stderr, "notify %d %s\n", (S)->s, #EVT));		\
}

#define notify(SOCK,MASK)						\
{									\
  if ((MASK) & CONN_NOTIFY)  PING(SOCK,conn);				\
  if ((MASK) & READ_NOTIFY)  PING(SOCK,read);				\
  if ((MASK) & WRITE_NOTIFY) PING(SOCK,write);				\
}


/*** Accessors for private socket members from a Squeak socket pointer ***/

#define _PSP(S)		(((S)->privateSocketPtr))
#define PSP(S)		((privateSocketStruct *)((S)->privateSocketPtr))

#define SOCKET(S)	(PSP(S)->s)
#define SOCKETSTATE(S)	(PSP(S)->sockState)
#define SOCKETERROR(S)	(PSP(S)->sockError)
#define SOCKETPEER(S)	(PSP(S)->peer)


/*** Resolver state ***/

static char lastName[MAXHOSTNAMELEN+1];
static int  lastAddr= 0;
static int  lastError= 0;
static int  resolverSema= 0;

/*** Variables ***/

extern struct VirtualMachine *interpreterProxy;
void* setHookFn;


static void acceptHandler(int, void *, int);
static void connectHandler(int, void *, int);
static void dataHandler(int, void *, int);
static void closeHandler(int, void *, int);



/* this MUST be turned on if DEBUG is turned on in aio.c  */

#ifdef DEBUG
char *socketHandlerName(aioHandler h)
{
  if (h == acceptHandler)     return "acceptHandler";
  if (h == connectHandler)    return "connectHandler";
  if (h == dataHandler)       return "dataHandler";
  if (h == closeHandler)      return "closeHandler";
  return "***unknownHandler***";
}
#endif


#define _DO_FLAG_TYPE()	_DO(AIO_R, rd) _DO(AIO_W, wr) _DO(AIO_X, ex)

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
#ifndef ACORN
  signal(SIGPIPE, SIG_IGN);
#endif
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
#ifndef ACORN
  signal(SIGPIPE, SIG_DFL);
#endif
}


/* poll for i/o activity, with microSeconds wait */

int aioPoll(int microSeconds)
{
  int	 fd, ms;
  fd_set rd, wr, ex;

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
      if (EINTR != errno)
	{
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
      FD_CLR(fd, &xdMask);
      if (ioctl(fd, FIONBIO, (char *)&one) < 0)
	perror("ioctl(FIONBIO, 1)");
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


/*** module initialisation/shutdown ***/


sqInt socketInit(void)
{
	setHookFn = interpreterProxy->ioLoadFunctionFrom( "setSocketPollFunction" , NULL);
	if(!setHookFn) {
		/* no hook found. can't continue */
		return 0;
	}
	/* install my socket polling function */
	((void (*) (int)) setHookFn)((int)aioPoll);
  return 1;
}

sqInt socketShutdown(void)
{
// first turn off the polling function
	((void (*) (int)) setHookFn)(0);
  /* shutdown the network */
  sqNetworkShutdown();
  return 1;
}


/***      miscellaneous sundries           ***/

/* set linger on a connected stream */

static void setLinger(int fd, int flag)
{
  struct linger linger= { flag, flag * LINGER_SECS };
  setsockopt(fd, SOL_SOCKET, SO_LINGER, (char *)&linger, sizeof(linger));
}

/* answer the hostname for the given IP address */

static const char *addrToName(int netAddress)
{
  u_long nAddr;
  struct hostent *he;

  lastError= 0;			/* for the resolver */
  nAddr= htonl(netAddress);
  if ((he= gethostbyaddr((char *)&nAddr, sizeof(nAddr), AF_INET)))
    return he->h_name;
  lastError= h_errno;		/* ditto */
  return "";
}

/* answer the IP address for the given hostname */

static int nameToAddr(char *hostName)
{
  struct hostent *he;

  lastError= 0;			/* ditto */
  if ((he= gethostbyname(hostName)))
    return ntohl(*(long *)(he->h_addr_list[0]));
  lastError= h_errno;		/* and one more ditto */
  return 0;
}

/* answer whether the given socket is valid in this net session */

static int socketValid(SocketPtr s)
{
  if (s && s->privateSocketPtr && thisNetSession && (s->sessionID == thisNetSession))
    return true;
  interpreterProxy->success(false);
  return false;
}

/* answer 1 if the given socket is readable,
          0 if read would block, or
         -1 if the socket is no longer connected */

static int socketReadable(int s)
{
  char buf[1];
  int n= recv(s, (void *)buf, 1, MSG_PEEK);
  if (n > 0) return 1;
  if ((n < 0) && (errno == EWOULDBLOCK)) return 0;
  return -1;	/* EOF */
}


/* answer whether the socket can be written without blocking */

static int socketWritable(int s)
{
  struct timeval tv= { 0, 0 };
  fd_set fds;

  FD_ZERO(&fds);
  FD_SET(s, &fds);
  return select(s+1, 0, &fds, 0, &tv) > 0;
}

/* answer the error condition on the given socket */

static int socketError(int s)
{
  int error= 0;
  socklen_t errsz= sizeof(error);
  /* Solaris helpfuly returns -1 if there is an error on the socket, so
     we can't check the success of the getsockopt call itself.  Ho hum. */
  getsockopt(s, SOL_SOCKET, SO_ERROR, (void *)&error, &errsz);
  return error;
}


/***     asynchronous io handlers       ***/


/* accept() can now be performed for the socket: call accept(),
   and replace the server socket with the new client socket
   leaving the client socket unhandled
*/
static void acceptHandler(int fd, void *data, int flags)
{
  privateSocketStruct *pss= (privateSocketStruct *)data;
  FPRINTF((stderr, "acceptHandler(%d, %p ,%d)\n", fd, data, flags));
  if (flags & AIO_X) /* -- exception */
    {
      /* error during listen() */
      aioDisable(fd);
      pss->sockError= socketError(fd);
      pss->sockState= Invalid;
      pss->s= -1;
      close(fd);
      fprintf(stderr, "acceptHandler: aborting server %d pss=%p\n", fd, pss);
    }
  else /* (flags & AIO_R) -- accept() is ready */
    {
      int newSock= accept(fd, 0, 0);
      if (newSock < 0)
	{
	  if (errno == ECONNABORTED)
	    {
	      /* let's just pretend this never happened */
	      aioHandle(fd, acceptHandler, AIO_RX);
	      return;
	    }
	  /* something really went wrong */
	  pss->sockError= errno;
	  pss->sockState= Invalid;
	  perror("acceptHandler");
	  aioDisable(fd);
	  close(fd);
	  fprintf(stderr, "acceptHandler: aborting server %d pss=%p\n", fd, pss);
	}
      else /* newSock >= 0 -- connection accepted */
	{
	  pss->sockState= Connected;
	  setLinger(newSock, 1);
	  if (pss->multiListen)
	    {
	      pss->acceptedSock= newSock;
	    }
	  else /* traditional listen -- replace server with client in-place */
	    {
	      aioDisable(fd);
	      close(fd);
	      pss->s= newSock;
	      aioEnable(newSock, pss, 0);
	    }
	}
    }
  notify(pss, CONN_NOTIFY);
}


/* connect() has completed: check errors, leaving the socket unhandled */

static void connectHandler(int fd, void *data, int flags)
{
  privateSocketStruct *pss= (privateSocketStruct *)data;
  FPRINTF((stderr, "connectHandler(%d, %p, %d)\n", fd, data, flags));
  if (flags & AIO_X) /* -- exception */
    {
      /* error during asynchronous connect() */
      aioDisable(fd);
      pss->sockError= socketError(fd);
      pss->sockState= Unconnected;
      perror("connectHandler");
    }
  else /* (flags & AIO_W) -- connect completed */
    {
      /* connect() has completed */
      int error= socketError(fd);
      if (error)
	{
	  FPRINTF((stderr, "connectHandler: error %d (%s)\n", error, strerror(error)));
	  pss->sockError= error;
	  pss->sockState= Unconnected;
	}
      else
	{
	  pss->sockState= Connected;
	  setLinger(pss->s, 1);
	}
    }
  notify(pss, CONN_NOTIFY);
}


/* read or write data transfer is now possible for the socket. */

static void dataHandler(int fd, void *data, int flags)
{
  privateSocketStruct *pss= (privateSocketStruct *)data;
  FPRINTF((stderr, "dataHandler(%d=%d, %p, %d)\n", fd, pss->s, data, flags));

  if (pss == NULL)
    {
      fprintf(stderr, "dataHandler: pss is NULL fd=%d data=%p flags=0x%x\n", fd, data, flags);
      return;
    }

  if (flags & AIO_R)
    {
      int n= socketReadable(fd);
      if (n == 0)
	{
	  fprintf(stderr, "dataHandler: selected socket fd=%d flags=0x%x would block (why?)\n", fd, flags);
	}
      if (n != 1)
	{
	  pss->sockError= socketError(fd);
	  pss->sockState= OtherEndClosed;
	}
    }
  if (flags & AIO_X)
    {
      /* assume out-of-band data has arrived */
      /* NOTE: Squeak's socket interface is currently incapable of reading
       *       OOB data.  We have no choice but to discard it.  Ho hum. */
      char buf[1];
      int n= recv(fd, (void *)buf, 1, MSG_OOB);
      if (n == 1) fprintf(stderr, "socket: received OOB data: %02x\n", buf[0]);
    }
  if (flags & AIO_R) notify(pss, READ_NOTIFY);
  if (flags & AIO_W) notify(pss, WRITE_NOTIFY);
}


/* a non-blocking close() has completed -- finish tidying up */

static void closeHandler(int fd, void *data, int flags)
{
  privateSocketStruct *pss= (privateSocketStruct *)data;
  aioDisable(fd);
  FPRINTF((stderr, "closeHandler(%d, %p, %d)\n", fd, data, flags));
  pss->sockState= Unconnected;
  pss->s= -1;
  notify(pss, CONN_NOTIFY);
}


/***     Squeak network functions        ***/


/* start a new network session */

sqInt  sqNetworkInit(sqInt  resolverSemaIndex)
{
  if (0 != thisNetSession)
    return 0;  /* already initialised */
  gethostname(localHostName, MAXHOSTNAMELEN);
  localHostAddress= nameToAddr(localHostName);
#if VM_PROXY_MINOR > 6
	thisNetSession = interpreterProxy->getThisSessionID();
#else
  thisNetSession= clock() + time(0);
  if (0 == thisNetSession)
    thisNetSession= 1;  /* 0 => uninitialised */
#endif
  resolverSema= resolverSemaIndex;
  aioInit();
  return 0;
}


/* terminate the current network session (invalidates all open sockets) */

void sqNetworkShutdown(void)
{
  thisNetSession= 0;
  resolverSema= 0;
  aioFini();
}



/***  Squeak Generic Socket Functions   ***/


/* create a new socket */

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID
    (SocketPtr s, sqInt netType, sqInt socketType,
     sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex)
{
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (s, netType, socketType,recvBufSize, sendBufSize,
     semaIndex, semaIndex, semaIndex);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (SocketPtr s, sqInt netType, sqInt socketType,
     sqInt recvBufSize, sqInt sendBufSize,
     sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{
  int newSocket= -1;
  privateSocketStruct *pss;

  s->sessionID= 0;
  if (TCPSocketType == socketType)
    {
      /* --- TCP --- */
      newSocket= socket(AF_INET, SOCK_STREAM, 0);
    }
  else if (UDPSocketType == socketType)
    {
      /* --- UDP --- */
      newSocket= socket(AF_INET, SOCK_DGRAM, 0);
    }
  if (-1 == newSocket)
    {
      /* socket() failed, or incorrect socketType */
      interpreterProxy->success(false);
      return;
    }
  setsockopt(newSocket, SOL_SOCKET, SO_REUSEADDR, (char *)&one, sizeof(one));
  /* private socket structure */
  pss= (privateSocketStruct *)calloc(1, sizeof(privateSocketStruct));
  if (pss == NULL)
    {
      fprintf(stderr, "acceptFrom: out of memory\n");
      interpreterProxy->success(false);
      return;
    }
  pss->s= newSocket;
  pss->connSema= semaIndex;
  pss->readSema= readSemaIndex;
  pss->writeSema= writeSemaIndex;

  /* UDP sockets are born "connected" */
  if (UDPSocketType == socketType)
    {
      pss->sockState= Connected;
      aioEnable(pss->s, pss, 0);
    }
  else
    {
      pss->sockState= Unconnected;
    }
  pss->sockError= 0;
  /* initial UDP peer := wildcard */
  memset(&pss->peer, 0, sizeof(pss->peer));
  pss->peer.sin_family= AF_INET;
  pss->peer.sin_port= 0;
  pss->peer.sin_addr.s_addr= INADDR_ANY;
  /* Squeak socket */
  s->sessionID= thisNetSession;
  s->socketType= socketType;
  s->privateSocketPtr= pss;
  FPRINTF((stderr, "create(%d) -> %lx\n", SOCKET(s), (unsigned long)PSP(s)));
  /* Note: socket is in BLOCKING mode until aioEnable is called for it! */
}


/* return the state of a socket */

sqInt sqSocketConnectionStatus(SocketPtr s)
{
  if (!socketValid(s))
    return Invalid;
  /* we now know that the net session is valid, so if state is Invalid... */
  if (SOCKETSTATE(s) == Invalid)	/* see acceptHandler() */
    {
      fprintf(stderr, "socketStatus: freeing invalidated pss=%p\n", PSP(s));
      /*free(PSP(s));*/	/* this almost never happens -- safer not to free()?? */
      _PSP(s)= 0;
      interpreterProxy->success(false);
      return Invalid;
    }
#if 0
  /* check for connection closed by peer */
  if (SOCKETSTATE(s) == Connected)
    {
      int fd= SOCKET(s);
      int n=  socketReadable(fd);
      if (n < 0)
	{
	  FPRINTF((stderr, "socketStatus(%d): detected other end closed\n", fd));
	  SOCKETSTATE(s)= OtherEndClosed;
	}
    }
#endif
  FPRINTF((stderr, "socketStatus(%d) -> %d\n", SOCKET(s), SOCKETSTATE(s)));
  return SOCKETSTATE(s);
}



/* TCP => start listening for incoming connections.
 * UDP => associate the local port number with the socket.
 */
void sqSocketListenOnPort(SocketPtr s, sqInt port)
{
  sqSocketListenOnPortBacklogSize(s, port, 1);
}

void sqSocketListenOnPortBacklogSizeInterface(SocketPtr s, sqInt port, sqInt backlogSize, sqInt addr)
{
  struct sockaddr_in saddr;

  if (!socketValid(s))
    return;

  /* only TCP sockets have a backlog */
  if ((backlogSize > 1) && (s->socketType != TCPSocketType))
    {
      interpreterProxy->success(false);
      return;
    }

  PSP(s)->multiListen= (backlogSize > 1);
  FPRINTF((stderr, "listenOnPortBacklogSize(%d, %d)\n", SOCKET(s), backlogSize));
  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family= AF_INET;
  saddr.sin_port= htons((short)port);
  saddr.sin_addr.s_addr= htonl(addr);
  bind(SOCKET(s), (struct sockaddr*) &saddr, sizeof(saddr));
  if (TCPSocketType == s->socketType)
    {
      /* --- TCP --- */
      listen(SOCKET(s), backlogSize);
      SOCKETSTATE(s)= WaitingForConnection;
      aioEnable(SOCKET(s), PSP(s), 0);
      aioHandle(SOCKET(s), acceptHandler, AIO_RX); /* R => accept() */
    }
  else
    {
      /* --- UDP --- */
    }
}

void sqSocketListenOnPortBacklogSize(SocketPtr s, sqInt port, sqInt backlogSize)
{
  sqSocketListenOnPortBacklogSizeInterface(s, port, backlogSize, INADDR_ANY);
}

/* TCP => open a connection.
 * UDP => set remote address.
 */
void sqSocketConnectToPort(SocketPtr s, sqInt addr, sqInt port)
{
  struct sockaddr_in saddr;

  if (!socketValid(s))
    return;
  FPRINTF((stderr, "connectTo(%d)\n", SOCKET(s)));
  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family= AF_INET;
  saddr.sin_port= htons((short)port);
  saddr.sin_addr.s_addr= htonl(addr);
  if (UDPSocketType == s->socketType)
    {
      /* --- UDP --- */
      memcpy((void *)&SOCKETPEER(s), (void *)&saddr, sizeof(SOCKETPEER(s)));
      SOCKETSTATE(s)= Connected;
    }
  else
    {
      /* --- TCP --- */
      int result;
      aioEnable(SOCKET(s), PSP(s), 0);
      result= connect(SOCKET(s), (struct sockaddr *)&saddr, sizeof(saddr));
      FPRINTF((stderr, "connect() => %d\n", result));
      if (result == 0)
	{
	  /* connection completed synchronously */
	  SOCKETSTATE(s)= Connected;
	  notify(PSP(s), CONN_NOTIFY);
	  setLinger(SOCKET(s), 1);
	}
      else
	{
	  if (errno == EINPROGRESS || errno == EWOULDBLOCK)
	    {
	      /* asynchronous connection in progress */
	      SOCKETSTATE(s)= WaitingForConnection;
	      aioHandle(SOCKET(s), connectHandler, AIO_WX);  /* W => connect() */
	    }
	  else
	    {
	      /* connection error */
	      perror("sqConnectToPort");
	      SOCKETSTATE(s)= Unconnected;
	      SOCKETERROR(s)= errno;
	      notify(PSP(s), CONN_NOTIFY);
	    }
	}
    }
}


void sqSocketAcceptFromRecvBytesSendBytesSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex){
  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (s, serverSocket, recvBufSize, sendBufSize,
     semaIndex, semaIndex, semaIndex);
}


void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (SocketPtr s, SocketPtr serverSocket,
     sqInt recvBufSize, sqInt sendBufSize,
     sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{
  /* The image has already called waitForConnection, so there is no
     need to signal the server's connection semaphore again. */

  struct privateSocketStruct *pss;

  FPRINTF((stderr, "acceptFrom(%p, %d)\n", s, SOCKET(serverSocket)));

  /* sanity checks */
  if (!socketValid(serverSocket) || !PSP(serverSocket)->multiListen)
    {
      FPRINTF((stderr, "accept failed: (multi->%d)\n", PSP(serverSocket)->multiListen));
      interpreterProxy->success(false);
      return;
    }

  /* check that a connection is there */
  if (PSP(serverSocket)->acceptedSock < 0)
    {
      fprintf(stderr, "acceptFrom: no socket available\n");
      interpreterProxy->success(false);
      return;
    }

  /* got connection -- fill in the structure */
  s->sessionID= 0;
  pss= (privateSocketStruct *)calloc(1, sizeof(privateSocketStruct));
  if (pss == NULL)
    {
      fprintf(stderr, "acceptFrom: out of memory\n");
      interpreterProxy->success(false);
      return;
    }

  _PSP(s)= pss;
  pss->s= PSP(serverSocket)->acceptedSock;
  PSP(serverSocket)->acceptedSock= -1;
  SOCKETSTATE(serverSocket)= WaitingForConnection;
  aioHandle(SOCKET(serverSocket), acceptHandler, AIO_RX);
  s->sessionID= thisNetSession;
  pss->connSema= semaIndex;
  pss->readSema= readSemaIndex;
  pss->writeSema= writeSemaIndex;
  pss->sockState= Connected;
  pss->sockError= 0;
  aioEnable(SOCKET(s), PSP(s), 0);
}


/* close the socket */

void sqSocketCloseConnection(SocketPtr s)
{
  int result= 0;

  if (!socketValid(s))
    return;

  FPRINTF((stderr, "closeConnection(%d)\n", SOCKET(s)));

  if (SOCKET(s) < 0)
    return;	/* already closed */

  aioDisable(SOCKET(s));
  SOCKETSTATE(s)= ThisEndClosed;
  result= close(SOCKET(s));
  if ((result == -1) && (errno != EWOULDBLOCK))
    {
      /* error */
      SOCKETSTATE(s)= Unconnected;
      SOCKETERROR(s)= errno;
      notify(PSP(s), CONN_NOTIFY);
      perror("closeConnection");
    }
  else if (0 == result)
    {
      /* close completed synchronously */
      SOCKETSTATE(s)= Unconnected;
      FPRINTF((stderr, "closeConnection: disconnected\n"));
      SOCKET(s)= -1;
    }
  else
    {
      /* asynchronous close in progress */
      SOCKETSTATE(s)= ThisEndClosed;
      aioHandle(SOCKET(s), closeHandler, AIO_RWX);  /* => close() done */
      FPRINTF((stderr, "closeConnection: deferred [aioHandle is set]\n"));
    }
}


/* close the socket without lingering */

void sqSocketAbortConnection(SocketPtr s) {
  FPRINTF((stderr, "abortConnection(%d)\n", SOCKET(s)));
  if (!socketValid(s))
    return;
  setLinger(SOCKET(s), 0);
  sqSocketCloseConnection(s);
}


/* Release the resources associated with this socket.
   If a connection is open, abort it. */

void sqSocketDestroy(SocketPtr s)
{
  if (!socketValid(s))
    return;

  FPRINTF((stderr, "destroy(%d)\n", SOCKET(s)));

  if (SOCKET(s))
    sqSocketAbortConnection(s);		/* close if necessary */

  if (PSP(s))
    free(PSP(s));			/* release private struct */

  _PSP(s)= 0;
}


/* answer the OS error code for the last socket operation */

sqInt sqSocketError(SocketPtr s)
{
  if (!socketValid(s))
    return -1;
  return SOCKETERROR(s);
}


/* return the local IP address bound to a socket */

sqInt sqSocketLocalAddress(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;
  if (getsockname(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize)
      || (AF_INET != saddr.sin_family))
    return 0;
  return ntohl(saddr.sin_addr.s_addr);
}


/* return the peer's IP address */

sqInt sqSocketRemoteAddress(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;
  if (TCPSocketType == s->socketType)
    {
      /* --- TCP --- */
      if (getpeername(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize)
	  || (AF_INET != saddr.sin_family))
	return 0;
      return ntohl(saddr.sin_addr.s_addr);
    }
  /* --- UDP --- */
  return ntohl(SOCKETPEER(s).sin_addr.s_addr);
}


/* return the local port number of a socket */

sqInt sqSocketLocalPort(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;
  if (getsockname(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize)
      || (AF_INET != saddr.sin_family))
    return 0;
  return ntohs(saddr.sin_port);
}


/* return the peer's port number */

sqInt sqSocketRemotePort(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;
  if (TCPSocketType == s->socketType)
    {
      /* --- TCP --- */
      if (getpeername(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize)
	  || (AF_INET != saddr.sin_family))
	return 0;
      return ntohs(saddr.sin_port);
    }
  /* --- UDP --- */
  return ntohs(SOCKETPEER(s).sin_port);
}


/* answer whether the socket has data available for reading:
   if the socket is not connected, answer "false";
   if the socket is open and data can be read, answer "true".
   if the socket is open and no data is currently readable, answer "false";
   if the socket is closed by peer, change the state to OtherEndClosed
	and answer "false";
*/
sqInt sqSocketReceiveDataAvailable(SocketPtr s)
{
  if (!socketValid(s)) return false;
  if (SOCKETSTATE(s) == Connected)
    {
      int fd= SOCKET(s);
      int n=  socketReadable(fd);
      if (n > 0)
	{
	  FPRINTF((stderr, "receiveDataAvailable(%d) -> true\n", fd));
	  return true;
	}
      else if (n < 0)
	{
	  FPRINTF((stderr, "receiveDataAvailable(%d): other end closed\n", fd));
	  SOCKETSTATE(s)= OtherEndClosed;
	}
    }
  else /* (SOCKETSTATE(s) != Connected) */
    {
      FPRINTF((stderr, "receiveDataAvailable(%d): socket not connected\n", SOCKET(s)));
    }
  aioHandle(SOCKET(s), dataHandler, AIO_RX);
  FPRINTF((stderr, "receiveDataAvailable(%d) -> false [aioHandle is set]\n", SOCKET(s)));
  return false;
}


/* answer whether the socket has space to receive more data */

sqInt sqSocketSendDone(SocketPtr s)
{
  if (!socketValid(s))
    return false;
  if (SOCKETSTATE(s) == Connected)
    {
      if (socketWritable(SOCKET(s))) return true;
      aioHandle(SOCKET(s), dataHandler, AIO_WX);
    }
  return false;
}


/* read data from the socket s into buf for at most bufSize bytes.
   answer the number actually read.  For UDP, fill in the peer's address
   with the approriate value.
*/
sqInt sqSocketReceiveDataBufCount(SocketPtr s, char* buf, sqInt bufSize)
{
  int nread= 0;

  if (!socketValid(s))
    return -1;
  if (UDPSocketType == s->socketType)
    {
      /* --- UDP --- */
      socklen_t addrSize= sizeof(SOCKETPEER(s));
      if ((nread= recvfrom(SOCKET(s), (void *)buf, bufSize, 0,
			   (struct sockaddr *)&SOCKETPEER(s),
			   &addrSize)) <= 0)
	{
	  if ((nread == -1) && (errno == EWOULDBLOCK))
	    {
	      FPRINTF((stderr, "UDP receiveData(%d) < 1 [blocked]\n", SOCKET(s)));
	      return 0;
	    }
	  SOCKETERROR(s)= errno;
	  FPRINTF((stderr, "UDP receiveData(%d) < 1 [a:%d]\n", SOCKET(s), errno));
	  return 0;
	}
    }
  else
    {
      /* --- TCP --- */
      if ((nread= read(SOCKET(s), (void *)buf, bufSize)) <= 0)
	{
	  if ((nread == -1) && (errno == EWOULDBLOCK))
	    {
	      FPRINTF((stderr, "TCP receiveData(%d) < 1 [blocked]\n", SOCKET(s)));
	      return 0;
	    }
	  /* connection reset */
	  SOCKETSTATE(s)= OtherEndClosed;
	  SOCKETERROR(s)= errno;
	  FPRINTF((stderr, "TCP receiveData(%d) < 1 [b:%d]\n", SOCKET(s), errno));
	  notify(PSP(s), CONN_NOTIFY);
	  return 0;
	}
    }
  /* read completed synchronously */
  FPRINTF((stderr, "receiveData(%d) done = %d\n", SOCKET(s), nread));
  return nread;
}


/* write data to the socket s from buf for at most bufSize bytes.
   answer the number of bytes actually written.
*/
sqInt sqSocketSendDataBufCount(SocketPtr s, char * buf, sqInt bufSize)
{
  int nsent= 0;

  if (!socketValid(s))
    return -1;

  if (UDPSocketType == s->socketType)
    {
      /* --- UDP --- */
      FPRINTF((stderr, "UDP sendData(%d, %d)\n", SOCKET(s), bufSize));
      if ((nsent= sendto(SOCKET(s), (void *)buf, bufSize, 0,
			 (struct sockaddr *)&SOCKETPEER(s),
			 sizeof(SOCKETPEER(s)))) <= 0)
	{
	  if (errno == EWOULDBLOCK)	/* asynchronous write in progress */
	    return 0;
	  FPRINTF((stderr, "UDP send failed\n"));
	  SOCKETERROR(s)= errno;
	  return 0;
	}
    }
  else
    {
      /* --- TCP --- */
      FPRINTF((stderr, "TCP sendData(%d, %d)\n", SOCKET(s), bufSize));
      if ((nsent= write(SOCKET(s), (char *)buf, bufSize)) <= 0)
	{
	  if ((nsent == -1) && (errno == EWOULDBLOCK))
	    {
	      FPRINTF((stderr, "TCP sendData(%d, %d) -> %d [blocked]",
		       SOCKET(s), bufSize, nsent));
	      return 0;
	    }
	  else
	    {
	      /* error: most likely "connection closed by peer" */
	      SOCKETSTATE(s)= OtherEndClosed;
	      SOCKETERROR(s)= errno;
	      FPRINTF((stderr, "TCP write failed -> %d", errno));
	      return 0;
	    }
	}
    }
  /* write completed synchronously */
  FPRINTF((stderr, "sendData(%d) done = %d\n", SOCKET(s), nsent));
  return nsent;
}


/* read data from the UDP socket s into buf for at most bufSize bytes.
   answer the number of bytes actually read.
*/
sqInt sqSocketReceiveUDPDataBufCountaddressportmoreFlag
    (SocketPtr s, char * buf, sqInt bufSize,  sqInt *address,  sqInt *port, sqInt *moreFlag)
{
  if (socketValid(s) && (UDPSocketType == s->socketType))
    {
      struct sockaddr_in saddr;
      socklen_t addrSize= sizeof(saddr);

      FPRINTF((stderr, "recvFrom(%d)\n", SOCKET(s)));
      memset(&saddr, 0, sizeof(saddr));
      {
	int nread= recvfrom(SOCKET(s), (void *)buf, bufSize, 0,
			    (struct sockaddr *)&saddr,
			    &addrSize);
	if (nread >= 0)
	  {
	    *address= ntohl(saddr.sin_addr.s_addr);
	    *port= ntohs(saddr.sin_port);
	    return nread;
	  }
	if (errno == EWOULDBLOCK)	/* asynchronous read in progress */
	  return 0;
	SOCKETERROR(s)= errno;
	FPRINTF((stderr, "receiveData(%d)= %da\n", SOCKET(s), 0));
      }
    }
  interpreterProxy->success(false);
  return 0;
}


/* write data to the UDP socket s from buf for at most bufSize bytes.
 * answer the number of bytes actually written.
 */
sqInt sqSockettoHostportSendDataBufCount(SocketPtr s, sqInt address, sqInt port,
				       char * buf, sqInt bufSize)
{
  if (socketValid(s) && (UDPSocketType == s->socketType))
    {
      struct sockaddr_in saddr;

      FPRINTF((stderr, "sendTo(%d)\n", SOCKET(s)));
      memset(&saddr, 0, sizeof(saddr));
      saddr.sin_family= AF_INET;
      saddr.sin_port= htons((short)port);
      saddr.sin_addr.s_addr= htonl(address);
      {
	int nsent= sendto(SOCKET(s), (void *)buf, bufSize, 0,
			  (struct sockaddr *)&saddr,
			  sizeof(saddr));
	if (nsent >= 0)
	  return nsent;

	if (errno == EWOULDBLOCK)	/* asynchronous write in progress */
	  return 0;
	FPRINTF((stderr, "UDP send failed\n"));
	SOCKETERROR(s)= errno;
      }
    }
  interpreterProxy->success(false);
  return 0;
}


/*** socket options ***/


/* NOTE: we only support the portable options here as an incentive for
         people to write portable Squeak programs.  If you need
         non-portable socket options then go write yourself a plugin
         specific to your platform.  This decision is unilateral and
         non-negotiable.  - ikp
   NOTE: we only support the integer-valued options because the code
	 in SocketPlugin doesn't seem able to cope with the others.
	 (Personally I think that things like SO_SNDTIMEO et al would
	 by far more interesting than the majority of things on this
	 list, but there you go...)
   NOTE: if your build fails because of a missing option in this list,
	 simply DELETE THE OPTION (or comment it out) and then send
	 me mail (ian.piumarta@inria.fr) to let me know about it.
 */

typedef struct
{
  char *name;		/* name as known to Squeak */
  int   optlevel;	/* protocol level */
  int   optname;	/* name as known to Unix */
} socketOption;

#ifndef SOL_IP
# define SOL_IP IPPROTO_IP
#endif

#ifndef SOL_UDP
# define SOL_UDP IPPROTO_UDP
#endif

#ifndef SOL_TCP
# define SOL_TCP IPPROTO_TCP
#endif

static socketOption socketOptions[]= {
  { "SO_DEBUG",				SOL_SOCKET,	SO_DEBUG },
  { "SO_REUSEADDR",			SOL_SOCKET,	SO_REUSEADDR },
  { "SO_DONTROUTE",			SOL_SOCKET,	SO_DONTROUTE },
  { "SO_BROADCAST",			SOL_SOCKET,	SO_BROADCAST },
  { "SO_SNDBUF",			SOL_SOCKET,	SO_SNDBUF },
  { "SO_RCVBUF",			SOL_SOCKET,	SO_RCVBUF },
  { "SO_KEEPALIVE",			SOL_SOCKET,	SO_KEEPALIVE },
  { "SO_OOBINLINE",			SOL_SOCKET,	SO_OOBINLINE },
  { "SO_LINGER",			SOL_SOCKET,	SO_LINGER },
  { "IP_TTL",				SOL_IP,		IP_TTL },
  { "IP_HDRINCL",			SOL_IP,		IP_HDRINCL },
  { "IP_MULTICAST_IF",			SOL_IP,		IP_MULTICAST_IF },
  { "IP_MULTICAST_TTL",			SOL_IP,		IP_MULTICAST_TTL },
  { "IP_MULTICAST_LOOP",		SOL_IP,		IP_MULTICAST_LOOP },
#ifdef IP_ADD_MEMBERSHIP
  { "IP_ADD_MEMBERSHIP",		SOL_IP,		IP_ADD_MEMBERSHIP },
  { "IP_DROP_MEMBERSHIP",		SOL_IP,		IP_DROP_MEMBERSHIP },
#endif
# if 0 /*** deliberately unsupported options -- do NOT enable these! ***/
  { "TCP_MAXSEG",			SOL_TCP,	TCP_MAXSEG },
  { "TCP_NODELAY",			SOL_TCP,	TCP_NODELAY },
  { "SO_REUSEPORT",			SOL_SOCKET,	SO_REUSEPORT },
  { "SO_PRIORITY",			SOL_SOCKET,	SO_PRIORITY },
  { "SO_RCVLOWAT",			SOL_SOCKET,	SO_RCVLOWAT },
  { "SO_SNDLOWAT",			SOL_SOCKET,	SO_SNDLOWAT },
  { "IP_RCVOPTS",			SOL_IP,		IP_RCVOPTS },
  { "IP_RCVDSTADDR",			SOL_IP,		IP_RCVDSTADDR },
  { "UDP_CHECKSUM",			SOL_UDP,	UDP_CHECKSUM },
  { "TCP_ABORT_THRESHOLD",		SOL_TCP,	TCP_ABORT_THRESHOLD },
  { "TCP_CONN_NOTIFY_THRESHOLD",	SOL_TCP,	TCP_CONN_NOTIFY_THRESHOLD },
  { "TCP_CONN_ABORT_THRESHOLD",		SOL_TCP,	TCP_CONN_ABORT_THRESHOLD },
  { "TCP_NOTIFY_THRESHOLD",		SOL_TCP,	TCP_NOTIFY_THRESHOLD },
  { "TCP_URGENT_PTR_TYPE",		SOL_TCP,	TCP_URGENT_PTR_TYPE },
# endif
  { (char *)0,				0,		0 }
};


static socketOption *findOption(char *name, size_t nameSize) {
	if (nameSize < 32) {
		socketOption *opt= 0;
		char buf[32];
		buf[nameSize]= '\0';
		strncpy(buf, name, nameSize);
		for (opt= socketOptions; opt->name != 0; ++opt)
	if (!strcmp(buf, opt->name))
	return opt;
	}
    return 0;
}


/* set the given option for the socket.  the option comes in as a
 * String.  (why on earth we might think this a good idea eludes me
 * ENTIRELY, so... if the string doesn't smell like an integer then we
 * copy it verbatim, assuming it's really a ByteArray pretending to be
 * a struct.  caveat hackor.)
 */
sqInt sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue
    (SocketPtr s, char *optionName, sqInt optionNameSize,
     char *optionValue, sqInt optionValueSize, sqInt *result)
{
  if (socketValid(s))
    {
      socketOption *opt= findOption((char *)optionName, (size_t)optionNameSize);
      if (opt != 0)
	{
	  int   val= 0;
	  char  buf[32];
	  char *endptr;
	  /* this is JUST PLAIN WRONG (I mean the design in the image rather
	     than the implementation here, which is probably correct
	     w.r.t. the broken design) */
	  if (optionValueSize > sizeof(buf) - 1)
	    goto barf;

	  memset((void *)buf, 0, sizeof(buf));
	  memcpy((void *)buf, (void *)optionValue, optionValueSize);
	  if (optionValueSize == 1)	/* character `1' or `0' */
	    {
	      val= strtol(buf, &endptr, 0);
	      if (endptr != buf)
		{
		  memcpy((void *)buf, (void *)&val, sizeof(val));
		  optionValueSize= sizeof(val);
		}
	    }
	  if ((setsockopt(PSP(s)->s, opt->optlevel, opt->optname,
			  (const void *)buf, optionValueSize)) < 0)
	    {
	      perror("setsockopt");
	      goto barf;
	    }
	  /* it isn't clear what we're supposed to return here, since
	     setsockopt isn't supposed to have any value-result parameters
	     (go grok that `const' on the buffer argument if you don't
	     believe me).  the image says "the result of the negotiated
	     value".  what the fuck is there to negotiate?  either
	     setsockopt sets the value or it barfs.  and i'm not about to go
	     calling getsockopt just to see if the value got changed or not
	     (the image should send getOption: to the Socket if it really
	     wants to know).  if the following is wrong then I could
	     probably care (a lot) less...  fix the logic in the image and
	     then maybe i'll care about fixing the logic in here.  (i know
	     that isn't very helpful, but it's 05:47 in the morning and i'm
	     severely grumpy after fixing several very unpleasant bugs that
	     somebody introduced into this file while i wasn't looking.)  */
	  *result= val;
	  return 0;
	}
    }
 barf:
  interpreterProxy->success(false);
  return false;
}


/* query the socket for the given option.  */
sqInt sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue
    (SocketPtr s, char *optionName, sqInt optionNameSize, sqInt *result)
{
  if (socketValid(s))
    {
      socketOption *opt= findOption((char *)optionName, (size_t)optionNameSize);
      if (opt != 0)
	{
	  int optval;
	  socklen_t optlen= sizeof(optval);
	  if ((getsockopt(PSP(s)->s, opt->optlevel, opt->optname,
			  (void *)&optval, &optlen)) < 0)
	    goto barf;
	  if (optlen != sizeof(optval))
	    goto barf;
	  *result= optval;
	  return 0;
	}
    }
 barf:
  interpreterProxy->success(false);
  return errno;
}

void sqSocketBindToPort(SocketPtr s, int addr, int port)
{
  int result;
  struct sockaddr_in inaddr;
  privateSocketStruct *pss= PSP(s);

  if (!socketValid(s)) return;

  /* bind the socket */
  memset(&inaddr, 0, sizeof(inaddr));
  inaddr.sin_family= AF_INET;
  inaddr.sin_port= htons(port);
  inaddr.sin_addr.s_addr= htonl(addr);

  if (bind(SOCKET(s), (struct sockaddr *)&inaddr, sizeof(struct sockaddr_in)) < 0)
    {
      pss->sockError= errno;
      interpreterProxy->success(false);
      return;
    }
}

void sqSocketSetReusable(SocketPtr s)
{
  char optionValue[256];
  size_t bufSize;
  unsigned char buf[4];
  int err;

  if (!socketValid(s)) return;

  *(int *)buf= 1;
  bufSize= 4;
  if (setsockopt(SOCKET(s), SOL_SOCKET, SO_REUSEADDR, buf, bufSize) < 0)
    {
      PSP(s)->sockError= errno;
      interpreterProxy->success(false);
      return;
    }
}


/*** Resolver functions ***/


/* Note: the Mac and Win32 implementations implement asynchronous lookups
 * in the DNS.  I can't think of an easy way to do this in Unix without
 * going totally ott with threads or somesuch.  If anyone knows differently,
 * please tell me about it. - Ian
 */


/*** irrelevancies ***/

void sqResolverAbort(void) {}

void sqResolverStartAddrLookup(sqInt address)
{
  const char *res;
  res= addrToName(address);
  strncpy(lastName, res, MAXHOSTNAMELEN);
  FPRINTF((stderr, "startAddrLookup %s\n", lastName));
}


sqInt sqResolverStatus(void) {
  if(!thisNetSession)
    return ResolverUninitialised;
  if(lastError != 0)
    return ResolverError;
  return ResolverSuccess;
}

/*** trivialities ***/

sqInt sqResolverAddrLookupResultSize(void)	{ return strlen(lastName); }
sqInt sqResolverError(void)			{ return lastError; }
sqInt sqResolverLocalAddress(void)		{ return nameToAddr(localHostName); }
sqInt sqResolverNameLookupResult(void)		{ return lastAddr; }

void sqResolverAddrLookupResult(char *nameForAddress, sqInt nameSize) {
  memcpy(nameForAddress, lastName, nameSize);
}

/*** name resolution ***/

void sqResolverStartNameLookup(char *hostName, sqInt nameSize) {
  int len= (nameSize < MAXHOSTNAMELEN) ? nameSize : MAXHOSTNAMELEN;
  memcpy(lastName, hostName, len);
  lastName[len]= lastError= 0;
  FPRINTF((stderr, "name lookup %s\n", lastName));
  lastAddr= nameToAddr(lastName);
  /* we're done before we even started */
  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
}

// stubs for newer socketplugin routines - fail them for now
void  sqResolverGetAddressInfoHostSizeServiceSizeFlagsFamilyTypeProtocol(char *hostName, sqInt hostSize, char *servName, sqInt servSize,
									 sqInt flags, sqInt family, sqInt type, sqInt protocol) {
	interpreterProxy->success(false);
	return;
}

sqInt sqResolverGetAddressInfoSize(void) {return -1;}

void  sqResolverGetAddressInfoResultSize(char *addr, sqInt addrSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqResolverGetAddressInfoFamily(void) {
	interpreterProxy->success(false);
	return 0;
}

sqInt sqResolverGetAddressInfoType(void) {
	interpreterProxy->success(false);
	return 0;
}

sqInt sqResolverGetAddressInfoProtocol(void) {
	interpreterProxy->success(false);
	return 0;
}

sqInt sqResolverGetAddressInfoNext(void) {
	return false;
}

sqInt sqSocketAddressSizeGetPort(char *addr, sqInt addrSize) {
	interpreterProxy->success(false);
	return 0;
}

void  sqSocketAddressSizeSetPort(char *addr, sqInt addrSize, sqInt port) {
	interpreterProxy->success(false);
	return;
}

void  sqResolverGetNameInfoSizeFlags(char *addr, sqInt addrSize, sqInt flags) {
	interpreterProxy->success(false);
	return;
}

sqInt sqResolverGetNameInfoHostSize(void) {
	interpreterProxy->success(false);
	return 0;
}

void  sqResolverGetNameInfoHostResultSize(char *name, sqInt nameSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqResolverGetNameInfoServiceSize(void) {
	interpreterProxy->success(false);
	return 0;
}

void  sqResolverGetNameInfoServiceResultSize(char *name, sqInt nameSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqResolverHostNameSize(void) {
	interpreterProxy->success(false);
	return 0;
}

void  sqResolverHostNameResultSize(char *name, sqInt nameSize) {
	interpreterProxy->success(false);
	return;
}

void  sqSocketBindToAddressSize(SocketPtr s, char *addr, sqInt addrSize) {
	interpreterProxy->success(false);
	return;
}

void  sqSocketListenBacklog(SocketPtr s, sqInt backlogSize) {
	interpreterProxy->success(false);
	return;
}

void  sqSocketConnectToAddressSize(SocketPtr s, char *addr, sqInt addrSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqSocketLocalAddressSize(SocketPtr s) {
	interpreterProxy->success(false);
	return 0;
}

void  sqSocketLocalAddressResultSize(SocketPtr s, char *addr, int addrSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqSocketRemoteAddressSize(SocketPtr s) {
	interpreterProxy->success(false);
	return -1;
}

void  sqSocketRemoteAddressResultSize(SocketPtr s, char *addr, int addrSize) {
	interpreterProxy->success(false);
	return;
}

sqInt sqSocketSendUDPToSizeDataBufCount(SocketPtr s, char *addr, sqInt addrSize, char *buf, sqInt bufSize) {
	interpreterProxy->success(false);
	return 0;
}

sqInt sqSocketReceiveUDPDataBufCount(SocketPtr s, char *buf, sqInt bufSize) {
	interpreterProxy->success(false);
	return 0;
}

