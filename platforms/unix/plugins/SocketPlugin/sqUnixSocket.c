/* sqUnixSocket.c -- Unix socket support
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
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
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2001-02-12 15:04:28 by piumarta on rnd10-51.rd.wdi.disney.com
 * 
 * Support for "accept" primitives contributed by:
 *	Lex Spoon <lex@cc.gatech.edu>
 * 
 * Notes:
 *
 * 1. 	UDP support is fully implemented here, but is (probably) missing
 *	in the image.
 * 
 * 2.	Sockets are completely asynchronous, but the resolver is still
 *	synchronous.
 *
 * 3.	Due to bugs in Solaris and HP-UX (and possibly others) the SIGIO
 *	mechanism is no longer used.  Instead aioPollForIO() is periodically
 *	called from HandleEvents in sqXWindow.c in order to check for I/O
 *	completion using select().
 * 
 * BUGS:
 *	Now that the image has real UDP primitives, the TCP/UDP duality in
 *	many of the connection-oriented functions should be removed and
 * 	cremated.
 */

#include "sq.h"
#include "SocketPlugin.h"
#include "sqaio.h"

#undef DEBUG

#ifdef ACORN
/* you know, I can't help thinking that a lot of this nonsense would
   simply vanish if Acorn used configure like the rest of us */
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

# ifdef HAVE_UNISTD_H
#   include <sys/types.h>
#   include <unistd.h>
# endif /* HAVE_UNISTD_H */
  
# ifdef NEED_GETHOSTNAME_P
    extern int gethostname();
# endif
  
# include <signal.h>
# include <sys/param.h>
# include <sys/socket.h>
# include <netinet/in.h>
# include <netinet/udp.h>
# include <netinet/tcp.h>
# include <arpa/inet.h>
# include <netdb.h>
# include <sys/ioctl.h>
# include <errno.h>
  
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

#endif /* !ACORN */

/* debugging stuff. can probably be deleted */

#ifdef DEBUG
# ifdef ACORN
#   define FPRINTF(s) \
    { \
      extern os_error privateErr; \
      extern void platReportError(os_error *e); \
      privateErr.errnum = (bits)0; \
      sprintf s; \
      platReportError((os_error *)&privateErr); \
    };
# else /* !ACORN */
#   define FPRINTF(X) fprintf X
# endif
  char *ticks= "-\\|/";
  char *ticker= "";
  #define DO_TICK() \
  { \
    fprintf(stderr, "\r%c\r", *ticker); \
    if (!*ticker++) ticker= ticks; \
  }
#else /* !DEBUG */
# define FPRINTF(X)
# define DO_TICK()
#endif


/*** Socket types ***/

#define TCPSocketType	 	0
#define UDPSocketType	 	1


/*** Resolver states ***/

#define ResolverUninitialised	0
#define ResolverSuccess		1
#define ResolverBusy		2
#define ResolverError		3


/*** TCP Socket states ***/

#define Unconnected		0x00
#define WaitingForConnection	0x01
#define Connected		0x02
#define OtherEndClosed		0x03
#define ThisEndClosed		0x04

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
  int pendingEvents;		/* conn/read/write events that the image is interested in;
				   when these states go high, the image should be signalled */
} privateSocketStruct;

#define CONN_NOTIFY	(1<<0)
#define READ_NOTIFY	(1<<1)
#define WRITE_NOTIFY	(1<<2)

/*** Accessors for private socket members from a Squeak socket pointer ***/

#define PSP(S)		((privateSocketStruct *)((S)->privateSocketPtr))

#define SOCKET(S)	(PSP(S)->s)
#define SOCKETSTATE(S)	(PSP(S)->sockState)
#define SOCKETERROR(S)	(PSP(S)->sockError)
#define SOCKETPEER(S)	(PSP(S)->peer)


/*** Resolver state ***/

static char lastName[MAXHOSTNAMELEN+1];
static int  lastAddr= 0;
static int  lastError= 0;

static int  resolverSema;

/*** Variables ***/

extern struct VirtualMachine *interpreterProxy;
int setHookFn;


static void nullHandler(void *, int, int, int);
static void acceptHandler(void *, int, int, int);
static void connectHandler(void *, int, int, int);
static void dataHandler(void *, int, int, int);
static void closeHandler(void *, int, int, int);


#ifdef DEBUG
static char *handlerName(AioHandler h)
{
  if (h == nullHandler)    return "nullHandler";
  if (h == acceptHandler)  return "acceptHandler";
  if (h == connectHandler) return "connectHandler";
  if (h == dataHandler)    return "dataHandler";
  if (h == closeHandler)   return "closeHandler";
  return "***unknownHandler***";
}
#endif



/*** module initialisation/shutdown ***/

int socketInit(void)
{
  signal(SIGPIPE, SIG_IGN);
  return 1;
}


int socketShutdown(void)
{
  /* shutdown the network */
  sqNetworkShutdown();
  return 1;
}



/*** utility wrappers for AIO functions ***/

static void sockSuspend(privateSocketStruct *pss) 
{
  aioHandle(pss->s, nullHandler, pss, AIO_EX);
}

static void sockEnable(privateSocketStruct *pss)
{
  if (ioctl(pss->s, FIONBIO, (char *)&one) < 0)
    perror("ioctl(FIONBIO,1)");
  aioHandle(pss->s, nullHandler, pss, AIO_EX);
}



/***      miscellaneous sundries           ***/



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
  if ((s != 0) && (thisNetSession != 0) && (s->privateSocketPtr != 0) && (s->sessionID == thisNetSession))
    return true;
  interpreterProxy->success(false);
  return false;
}


/* answer whether the socket can be read (or accept()ed) without blocking */

static int socketReadable(int s)
{
  struct timeval tv= { 0, 0 };
  fd_set fds;
  
  FD_ZERO(&fds);
  FD_SET(s, &fds);
  return select(s+1, &fds, 0, 0, &tv) > 0;
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


/***     asynchronous io handlers       ***/

/* Each handler must at least:
 *   - suspend further handling for the associated socket
 *   - signal its semaphore to indicate that the operation is complete
 */


/* notify(pss, eventMask) - signal the appropriate semaphores for
   socket pss, assuming that the states in eventMask are true.
*/
void notify(privateSocketStruct *pss, int eventMask)
{
  int eventsToSignal= pss->pendingEvents & eventMask;
  if (eventsToSignal & CONN_NOTIFY)
    {
      interpreterProxy->signalSemaphoreWithIndex((pss)->connSema);
      pss->pendingEvents &= ~CONN_NOTIFY;
    }
  
  if (eventsToSignal & READ_NOTIFY)
    {
      interpreterProxy->signalSemaphoreWithIndex((pss)->readSema);
      pss->pendingEvents &= ~READ_NOTIFY;
    }
  
  if (eventsToSignal & WRITE_NOTIFY)
    {
      interpreterProxy->signalSemaphoreWithIndex((pss)->writeSema);
      pss->pendingEvents &= ~WRITE_NOTIFY;
    }
}


static void installAppropriateDataHandler(privateSocketStruct *pss)
{
  int listenFlags= AIO_EX;
  if(pss->pendingEvents & READ_NOTIFY)
    listenFlags|= AIO_RD;
  if(pss->pendingEvents & WRITE_NOTIFY)
    listenFlags|= AIO_WR;
  
  /* keep listening for more data? */
  if(listenFlags == AIO_EX)
    {
      /* don't listen */
      aioHandle(pss->s, nullHandler, pss, AIO_EX);
    }
  else
    {
      /* listen for listenFlags */
      aioHandle(pss->s, dataHandler, pss, listenFlags);
    }
  
}



/* this handler should never normally be invoked */
static void nullHandler(void *pssIn, int readFlag, int writeFlag, int errFlag)
{
  privateSocketStruct *pss = (privateSocketStruct *)pssIn;
  
  sockSuspend(pss);
  
  fprintf(stderr, "nullHandler(%d, %d, %d)\n", pss->s, errFlag, readFlag);
  
  if (errFlag)
    pss->sockState= OtherEndClosed;
  
  /* *** removed by ikp: this handler should NEVER be invoked during normal operation ***
     SET_WILLTAPCONNSEMA(pss);
     tapSemaphores(pss); */
}


/* accept() can now be performed for the socket: call accept(),
   and replace the server socket with the new client socket
   leaving the client socket unhandled
*/
static void acceptHandler(void *pssIn, int readFlag, int writeFlag, int errFlag)
{
  privateSocketStruct *pss = (privateSocketStruct *)pssIn;
  sockSuspend(pss);
  
  FPRINTF((stderr, "acceptHandler(%d,%d,%d)\n", pss->s, errFlag, readFlag));
  if (errFlag)
    {
      /* error during listen() */
      close(pss->s);
      pss->sockState= Unconnected;
      pss->sockError= EBADF;	/* educated guess */
    }
  else
    {
      /* accept() is ready */
      int newSock= accept(pss->s, 0, 0);
      aioStopHandling(pss->s);
      if (newSock < 0)
	{
#        if 0
	  /* error during accept() */
	  pss->sockError= errno;
	  pss->sockState= Unconnected;
	  perror("acceptHandler");
#        else
	  /* let's assume it's a transient error, and continue to wait
	     for a connection */
	  pss->sockError= errno;
	  pss->sockState= WaitingForConnection;
	  perror("acceptHandler (ignored)");
	  aioHandle(pss->s, acceptHandler, pss, AIO_RD|AIO_EX); /* => accept() possible */
	  return;	/* do NOT notify connection below */
#        endif
	}
      else
	{
	  /* connection accepted */
	  pss->sockState= Connected;
	  /* sockEnable(pss); *** removed by ikp *** */
	  if(pss->multiListen)
	    {
	      pss->acceptedSock= newSock;
	      // aio re-enabled in sqSockAcceptFrom...()
	    }
	  else
	    {
	      close(pss->s);
	      pss->s= newSock;
	      sockEnable(pss);	/*** added by ikp ***/
	    }
	}
    }
  notify(pss, CONN_NOTIFY);
}


/* connect() has completed: check errors, leaving the socket unhandled */

static void connectHandler(void *pssIn, int readFlag, int writeFlage, int errFlag)
{
  privateSocketStruct *pss = (privateSocketStruct *)pssIn;
  sockSuspend(pss);

  FPRINTF((stderr, "connectHandler(%d,%d,%d)\n", pss->s, errFlag, readFlag));
  if (errFlag)
    {
      /* error during asynchronous connect() */
      close(pss->s);
      perror("connectHandler failed");
      pss->sockError= errno;
      pss->sockState= Unconnected;
    }
  else
    {
      /* connect() has completed.  Check whether it was successful */
      int s_errno = 0;   /* errno from SO_ERROR */
      socklen_t len;     /* Length of return buffer */

      len = sizeof(s_errno);
      getsockopt(pss->s, SOL_SOCKET, SO_ERROR, &s_errno, &len);
      if(s_errno != 0) {
	/* connection failure */
        pss->pendingEvents |= CONN_NOTIFY;
        pss->sockError = s_errno;
        pss->sockState = Unconnected;  
        FPRINTF ((stderr, "connectHandler failed\n"));
      } else {
	/* success! */
        pss->sockState= Connected;
        FPRINTF ((stderr, "connectHandler ok\n"));
      }
    }
  notify(pss, CONN_NOTIFY);
}



/* read or write data transfer is now possible for the socket */

static void dataHandler(void *pssIn, int readFlag, int writeFlag, int errFlag)
{
  privateSocketStruct *pss = (privateSocketStruct *)pssIn;

  FPRINTF((stderr, "dataHandler(%d,%d,%d)\n", pss->s, errFlag, readFlag));
  if (errFlag)
    /* error: almost certainly "connection closed by peer" */
    pss->sockState= OtherEndClosed;
  if(readFlag)
    notify(pss, READ_NOTIFY);
  if(writeFlag)
    notify(pss, WRITE_NOTIFY);

  installAppropriateDataHandler(pss);
}



      
/* a non-blocking close() has completed -- finish tidying up */

static void closeHandler(void *pssIn, int readFlag, int writeFlag, int errFlag)
{
  privateSocketStruct *pss = (privateSocketStruct *)pssIn;
  aioStopHandling(pss->s);
  FPRINTF((stderr, "closeHandler(%d,%d,%d)\n", pss->s, errFlag, readFlag));
  pss->sockState= Unconnected;
  pss->s= 0;
  notify(pss, CONN_NOTIFY);
}


/***     Squeak network functions        ***/


/* start a new network session */

int sqNetworkInit(int resolverSemaIndex)
{
  if (0 != thisNetSession)
    return 0;  /* already initialised */
  gethostname(localHostName, MAXHOSTNAMELEN);
  localHostAddress= nameToAddr(localHostName);
  thisNetSession= clock() + time(0);
  if (0 == thisNetSession)
    thisNetSession= 1;  /* 0 => uninitialised */
  resolverSema= resolverSemaIndex;
  return 0;
}


/* terminate the current network session (invalidates all open sockets) */

void sqNetworkShutdown(void)
{
  thisNetSession= 0;
  resolverSema= 0;
}



/***  Squeak Generic Socket Functions   ***/


/* create a new socket */

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID
    (SocketPtr s, int netType, int socketType,
     int recvBufSize, int sendBufSize, int semaIndex)
{
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (s, netType, socketType,recvBufSize, sendBufSize,
     semaIndex, semaIndex, semaIndex);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (SocketPtr s, int netType, int socketType,
     int recvBufSize, int sendBufSize,
     int semaIndex, int readSemaIndex, int writeSemaIndex)
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
  pss->s= newSocket;
  pss->connSema= semaIndex;
  pss->readSema= readSemaIndex;
  pss->writeSema= writeSemaIndex;
  pss->pendingEvents= 0;

  /* UDP sockets are born "connected" */
  if (UDPSocketType == socketType)
    {
      pss->sockState= Connected;
      sockEnable(pss);
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
  /* Note: socket is in BLOCKING mode until sockEnable is called for it! */
}


/* return the state of a socket */

int sqSocketConnectionStatus(SocketPtr s)
{
  if (!socketValid(s))
    return -1;
  
  return SOCKETSTATE(s);
}



/* TCP => start listening for incoming connections.
 * UDP => associate the local port number with the socket.
 */
void sqSocketListenOnPort(SocketPtr s, int port)
{
  sqSocketListenOnPortBacklogSize(s, port, 1);
}

void sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize)
{
  struct sockaddr_in saddr;

  if (!socketValid(s))
    return;
  if((backlogSize > 1) && (s->socketType != TCPSocketType))
    {
      /* only TCP sockets have a backlog */
      interpreterProxy->success(false);
      return;
    }
  PSP(s)->multiListen= backlogSize > 1;
  FPRINTF((stderr, "listenOnPortBacklogSize(%d)\n", SOCKET(s)));
  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family= AF_INET;
  saddr.sin_port= htons((short)port);
  saddr.sin_addr.s_addr= INADDR_ANY;
  bind(SOCKET(s), (struct sockaddr*) &saddr, sizeof(saddr));
  if (TCPSocketType == s->socketType)
    {
      /* --- TCP --- */
      /* hacked to use the backlogSize */
      listen(SOCKET(s), backlogSize);
      SOCKETSTATE(s)= WaitingForConnection;
      sockEnable(PSP(s));
      aioHandle(SOCKET(s), acceptHandler, PSP(s), AIO_RD|AIO_EX); /* => accept() possible */
    }
  else
    {
      /* --- UDP --- */
    }
}


/* TCP => open a connection.
 * UDP => set remote address.
 */
void sqSocketConnectToPort(SocketPtr s, int addr, int port)
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
      sockEnable(PSP(s));
      result= connect(SOCKET(s), (struct sockaddr *)&saddr, sizeof(saddr));
      FPRINTF((stderr, "connect() => %d\n", result));
      if (result == 0)
	{
	  /* connection completed synchronously */
	  SOCKETSTATE(s)= Connected;
	  notify(PSP(s), CONN_NOTIFY);
	}
      else
	{
	  if (errno == EINPROGRESS || errno == EWOULDBLOCK)
	    {
	      /* asynchronous connection in progress */
	      SOCKETSTATE(s)= WaitingForConnection;
	      PSP(s)->pendingEvents|= CONN_NOTIFY;
	      
	      aioHandle(SOCKET(s), connectHandler, PSP(s), AIO_WR);  /* => connect() done */
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
  /* notify(PSP(s), 0); */
}


void sqSocketAcceptFromRecvBytesSendBytesSemaID
    (SocketPtr s, SocketPtr serverSocket,
     int recvBufSize, int sendBufSize, int semaIndex) 
{
  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (s, serverSocket, recvBufSize, sendBufSize, 
     semaIndex, semaIndex, semaIndex);
}


void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
    (SocketPtr s, SocketPtr serverSocket,
     int recvBufSize, int sendBufSize,
     int semaIndex, int readSemaIndex, int writeSemaIndex) 
{
  struct privateSocketStruct *pss;

  FPRINTF((stderr, "acceptFrom(%d, %d)\n", SOCKET(s), SOCKET(serverSocket)));

  /* sanity checks */
  if(!socketValid(serverSocket) || !PSP(serverSocket)->multiListen)
    {
      FPRINTF((stderr, "accept failed: (multi->%d)\n", PSP(serverSocket)->multiListen));
      interpreterProxy->success(false);
      return;
    }
  /* check that a connection is there */
  if(PSP(serverSocket)->acceptedSock < 0)
    {
      printf("no sock available\n");
      interpreterProxy->success(false);
      return;
    }
  /* got connection -- fill in the structure */
  s->sessionID= 0;
  pss= calloc(1, sizeof(*pss));
  if(pss == NULL)
    {
      printf("out of memory\n");
      interpreterProxy->success(false);
      return;
    }

  PSP(s)= pss;
  pss->s= PSP(serverSocket)->acceptedSock;
  PSP(serverSocket)->acceptedSock= -1;
  SOCKETSTATE(serverSocket)= WaitingForConnection;
  sockEnable(PSP(serverSocket));
  aioHandle(SOCKET(serverSocket), acceptHandler, PSP(serverSocket), AIO_RD|AIO_EX);
  s->sessionID= thisNetSession;
  pss->connSema= semaIndex;
  pss->readSema= readSemaIndex;
  pss->writeSema= writeSemaIndex;
  pss->pendingEvents= 0;
  pss->sockState= Connected;
  pss->sockError= 0;
  sockEnable(PSP(s));
}


/* close the socket */

void sqSocketCloseConnection(SocketPtr s)
{
  int result;

  if (!socketValid(s))
    return;
  FPRINTF((stderr, "closeConnection(%d)\n", SOCKET(s)));
  aioStopHandling(SOCKET(s));
  SOCKETSTATE(s)= ThisEndClosed;
  result= close(SOCKET(s));
  if ((result == -1) && (errno != EWOULDBLOCK))
    {
      /* error */
      SOCKETSTATE(s)= Unconnected;
      SOCKETERROR(s)= errno;
      notify(PSP(s), CONN_NOTIFY);
    }
  else if (0 == result)
    {
      /* close completed synchronously */
      SOCKETSTATE(s)= Unconnected;
      SOCKET(s)= 0;
      notify(PSP(s), CONN_NOTIFY);
    }
  else
    {
      /* asynchronous close in progress */
      SOCKETSTATE(s)= ThisEndClosed;
      aioHandle(SOCKET(s), closeHandler, PSP(s), AIO_EX);  /* => close() done */
    }
}


/* close the socket without lingering */

void sqSocketAbortConnection(SocketPtr s)
{
  struct linger linger= { 0, 0 };

  FPRINTF((stderr, "abortConnection(%d)\n", SOCKET(s)));
  if (!socketValid(s))
    return;
  setsockopt(SOCKET(s), SOL_SOCKET, SO_LINGER, (char *)&linger, sizeof(linger));
  sqSocketCloseConnection(s);
}


/* Release the resources associated with this socket. 
   If a connection is open, abort it.*/

void sqSocketDestroy(SocketPtr s)
{
  if (!socketValid(s))
    return;
  FPRINTF((stderr, "destroy(%d)\n", SOCKET(s)));
  if (SOCKET(s))
    sqSocketAbortConnection(s);		/* close if necessary */
  if (PSP(s))
    free(PSP(s));			/* release private struct */
  /* PSP(s)= 0;*/	/* HP-UKes cannot cope with this */
  s->privateSocketPtr= 0;
}


/* answer the OS error code for the last socket operation */

int sqSocketError(SocketPtr s)
{
  if (!socketValid(s))
    return -1;
  return SOCKETERROR(s);
}


/* return the local IP address bound to a socket */

int sqSocketLocalAddress(SocketPtr s)
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

int sqSocketRemoteAddress(SocketPtr s)
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

int sqSocketLocalPort(SocketPtr s)
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

int sqSocketRemotePort(SocketPtr s)
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


/* answer whether the socket has data available for reading */

int sqSocketReceiveDataAvailable(SocketPtr s)
{
  if (!socketValid(s))
    return -1;
  if (SOCKETSTATE(s) == Connected)
    {
      if (socketReadable(SOCKET(s)))
	return true;
      PSP(s)->pendingEvents|= READ_NOTIFY;
      installAppropriateDataHandler(PSP(s));
    }
  return false;
}


/* answer whether the socket has space to receive more data */

int sqSocketSendDone(SocketPtr s)
{
  if (!socketValid(s))
    return -1;
  if (SOCKETSTATE(s) == Connected)
    {
      if (socketWritable(SOCKET(s))) return true;
      PSP(s)->pendingEvents|= WRITE_NOTIFY;
      installAppropriateDataHandler(PSP(s));
    }
  return false;
}


/* read data from the socket s into buf for at most bufSize bytes.
   answer the number actually read.  For UDP, fill in the peer's address
   with the approriate value.
*/
int sqSocketReceiveDataBufCount(SocketPtr s, int buf, int bufSize)
{
  int nread;

  if (!socketValid(s))
    return -1;
  if (UDPSocketType == s->socketType)
    {
      /* --- UDP --- */
      socklen_t addrSize= sizeof(SOCKETPEER(s));
      if ((nread= recvfrom(SOCKET(s), (void*)buf, bufSize, 0,
			   (struct sockaddr *)&SOCKETPEER(s),
			   &addrSize)) <= 0)
	{
	  if (errno == EWOULDBLOCK)
	    {
	      /* asynchronous read in progress */
	      aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => retry */
	      return 0;
	    }
	  SOCKETERROR(s)= errno;
	  FPRINTF((stderr, "receiveData(%d)= %da\n", SOCKET(s), 0));
	  return 0;
	}
    }
  else
    {
      /* --- TCP --- */
      if ((nread= read(SOCKET(s), (void*)buf, bufSize)) <= 0)
	{
	  if (errno == EWOULDBLOCK)
	    {
	      /* asynchronous read in progress */
	      aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => retry */
	      return 0;
	    }
	  else
	    {
	      /* error: most probably "connection closed by peer" */
	      SOCKETSTATE(s)= OtherEndClosed;
	      SOCKETERROR(s)= errno;
	      FPRINTF((stderr, "receiveData(%d) = %db\n", SOCKET(s), 0));
	      return 0;
	    }
	}
    }
  /* read completed synchronously */
  FPRINTF((stderr, "receiveData(%d) = %d\n", SOCKET(s), nread));
  sockSuspend(PSP(s));
  return nread;
}


/* write data to the socket s from buf for at most bufSize bytes.
   answer the number of bytes actually written.
*/ 
int sqSocketSendDataBufCount(SocketPtr s, int buf, int bufSize)
{
  int nsent;

  if (!socketValid(s))
    return -1;

  FPRINTF((stderr, "sendData(%d,%d)\n", SOCKET(s), bufSize));

  if (UDPSocketType == s->socketType)
    {
      /* --- UDP --- */
      FPRINTF((stderr, "UDP sendData(%d,%d)\n", SOCKET(s), bufSize));
      if ((nsent= sendto(SOCKET(s), (void *)buf, bufSize, 0,
			 (struct sockaddr *)&SOCKETPEER(s),
			 sizeof(SOCKETPEER(s)))) <= 0)
	{
	  if (errno == EWOULDBLOCK)
	    {
	      /* asynchronous write in progress */
	      aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => data sent */
	      return 0;
	    }
	  FPRINTF((stderr, "UDP send failed\n"));
	  SOCKETERROR(s)= errno;
	  return 0;
	}
    }
  else
    {
      /* --- TCP --- */
      FPRINTF((stderr, "TCP sendData(%d,%d)\n", SOCKET(s), bufSize));
      if ((nsent= write(SOCKET(s), (char *)buf, bufSize)) <= 0)
	{
	  if (errno == EWOULDBLOCK)
	    {
	      /* asynchronous write in progress */
	      aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => data sent */
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
  FPRINTF((stderr, "sendData done(%d) = %d\n", SOCKET(s), nsent));
  sockSuspend(PSP(s));
  return nsent;
}


/* read data from the UDP socket s into buf for at most bufSize bytes.
   answer the number of bytes actually read.
*/ 
int sqSocketReceiveUDPDataBufCountaddressportmoreFlag
    (SocketPtr s, int buf, int bufSize,  int *address,  int *port, int *moreFlag)
{
  if (socketValid(s) && (UDPSocketType == s->socketType))
    {
      struct sockaddr_in saddr;
      socklen_t addrSize= sizeof(saddr);

      FPRINTF((stderr, "recvFrom(%d)\n", SOCKET(s)));
      memset(&saddr, 0, sizeof(saddr));
      saddr.sin_family= AF_INET;
      saddr.sin_port= htons((short)*port);
      saddr.sin_addr.s_addr= htonl(*address);
      { 
	int nread= recvfrom(SOCKET(s), (void*)buf, bufSize, 0,
			    (struct sockaddr *)&saddr,
			    &addrSize);
	if (nread >= 0)
	  return nread;
	if (errno == EWOULDBLOCK)
	  {
	    /* asynchronous read in progress */
	    aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => retry */
	    return 0;
	  }
	SOCKETERROR(s)= errno;
	FPRINTF((stderr, "receiveData(%d)= %da\n", SOCKET(s), 0));
      }
    }
  interpreterProxy->success(false);
  return 0;
}


/* write data to the UDP socket s from buf for at most bufSize bytes.
   answer the number of bytes actually written.
*/ 
int sqSockettoHostportSendDataBufCount(SocketPtr s, int address, int port,
				       int buf, int bufSize)
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
	
	if (errno == EWOULDBLOCK)
	  {
	    /* asynchronous write in progress */
	    aioHandle(SOCKET(s), dataHandler, PSP(s), AIO_RW);	/* => data sent */
	    return 0;
	  }
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
  { "TCP_MAXSEG",			SOL_TCP,	TCP_MAXSEG },
  { "TCP_NODELAY",			SOL_TCP,	TCP_NODELAY },
# if 0 /*** deliberately unsupported options -- do NOT enable these! ***/
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


static socketOption *findOption(char *name, size_t nameSize)
{
  socketOption *opt= 0;
  char buf[32];
  strncpy(buf, name, nameSize);
  for (opt= socketOptions; opt->name != 0; ++opt)
    if (!strcmp(buf, opt->name))
      return opt;
  return 0;
}


/* set the given option for the socket.
 */
int sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue
    (SocketPtr s,int optionName, int optionNameSize,
     int optionValue, int optionValueSize, int *result)
{
  if (socketValid(s))
    {
      socketOption *opt= findOption((char *)optionName, (size_t)optionNameSize);
      if (opt != 0)
	{
	  int buf[32];
	  /* this is JUST PLAIN WRONG (I mean the design in the image rather
	     than the implementation here, which is probably correct
	     w.r.t. the broken design) */
	  if (optionValueSize > sizeof(buf))
	    goto barf;
	  memcpy((void *)buf, (void *)optionValue, (size_t)optionValueSize);
	  if ((setsockopt(PSP(s)->s, opt->optlevel, opt->optname,
			  (const void *)buf, (size_t)optionValueSize)) < 0)
	    goto barf;
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
	  if (optionValueSize != sizeof(*result))
	    goto barf;
	  *result= buf[1];
	  return 0;
	}
    }
 barf:
  interpreterProxy->success(false);
  return false;
}


/* query the socket for the given option.  */
int sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue
    (SocketPtr s,int optionName, int optionNameSize, int *result)
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

#if 0
/* TPR - shouldn't be reuired now SocketPlugin is fixed */
int ioCanCreateSocketOfType(int netType, int socketType)	{ return true; }
int ioCanConnectToPort(int netAddr, int port)			{ return true; }
int ioCanListenOnPort(SocketPtr s, int port)			{ return true; }
int ioDisableSocketAccess(void)					{ return true; }
int ioHasSocketAccess(void)					{ return true; }
#endif

/*** Resolver functions ***/


/* Note: the Mac and Win32 implementations implement asynchronous lookups
 * in the DNS.  I can't think of an easy way to do this in Unix without
 * going totally ott with threads or somesuch.  If anyone knows differently,
 * please tell me about it. - Ian
 */


/*** irrelevancies ***/

void sqResolverAbort(void) {}

void sqResolverStartAddrLookup(int address)
{
  const char *res;
  res= addrToName(address);
  strncpy(lastName, res, MAXHOSTNAMELEN);
  FPRINTF((stderr, "startAddrLookup %s\n", lastName));
}


int sqResolverStatus(void)
{
  if(!thisNetSession)
    return ResolverUninitialised;
  if(lastError != 0)
    return ResolverError;
  return ResolverSuccess;
}

/*** trivialities ***/

int sqResolverAddrLookupResultSize(void)	{ return strlen(lastName); }
int sqResolverError(void)			{ return lastError; }
int sqResolverLocalAddress(void)		{ return nameToAddr(localHostName); }
int sqResolverNameLookupResult(void)		{ return lastAddr; }

void sqResolverAddrLookupResult(char *nameForAddress, int nameSize)
{
  memcpy(nameForAddress, lastName, nameSize);
}

/*** name resolution ***/

void sqResolverStartNameLookup(char *hostName, int nameSize)
{
  int len= (nameSize < MAXHOSTNAMELEN) ? nameSize : MAXHOSTNAMELEN;
  memcpy(lastName, hostName, len);
  lastName[len]= lastError= 0;
  FPRINTF((stderr, "name lookup %s\n", lastName));
  lastAddr= nameToAddr(lastName);
  /* we're done before we even started */
  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
}


