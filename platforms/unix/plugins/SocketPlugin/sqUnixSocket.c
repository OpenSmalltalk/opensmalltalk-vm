/* sqUnixSocket.c -- Unix socket support
 * 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Ian.Piumarta@inria.fr
 * 
 * Support for BSD-style "accept" primitives contributed by:
 *	Lex Spoon <lex@cc.gatech.edu>
 *
 * Raw Socket Support by Andreas Raab, RIP.
 *
 * Fix to option parsing in sqSocketSetOptions... by Eliot Miranda, 2013/4/12
 * 
 * Notes:
 * 	Sockets are completely asynchronous, but the resolver is still synchronous.
 * 
 * BUGS:
 *	Now that the image has real UDP primitives, the TCP/UDP duality in
 *	many of the connection-oriented functions should be removed and cremated.
 */

#include "sq.h"
#include "SocketPlugin.h"
#include "sqaio.h"

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
# include <sys/stat.h>
# include <sys/socket.h>
# include <sys/un.h>
# include <netinet/in.h>
# include <netinet/udp.h>
# include <netinet/tcp.h>
# include <arpa/inet.h>
# include <netdb.h>
#include <ifaddrs.h>
# include <errno.h>
# include <unistd.h>
  
#endif /* !ACORN */

/* Solaris sometimes fails to define this in netdb.h */
#ifndef  MAXHOSTNAMELEN
# define MAXHOSTNAMELEN	256
#endif

#ifdef HAVE_SD_DAEMON
# include <systemd/sd-daemon.h>
#else
# define SD_LISTEN_FDS_START 3
# define sd_listen_fds(u) 0
#endif

/*** Socket types ***/

#define TCPSocketType			0 /* SOCK_STREAM on AF_INET or AF_INET6 */
#define UDPSocketType			1 /* SOCK_DGRAM on AF_INET or AF_INET6 */
#define RAWSocketType			2 /* SOCK_RAW on AF_INET or AF_INET6 */
#define SeqPacketSocketType		3 /* SOCK_SEQPACKET on AF_INET or AF_INET6 */
#define ReliableDGramSocketType	4 /* SOCK_RDM on AF_INET or AF_INET6 */

#define ReuseExistingSocket		65536

#define ProvidedTCPSocketType		(TCPSocketType + ReuseExistingSocket)
#define ProvidedUDPSocketType		(UDPSocketType + ReuseExistingSocket)
#define ProvidedRAWSocketType		(RAWSocketType + ReuseExistingSocket)
#define ProvidedSeqPacketSocketType	(SeqPacketSocketType + ReuseExistingSocket)
#define ProvidedReliableDGramSocketType	(ReliableDGramSocketType + ReuseExistingSocket)



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

union sockaddr_any
{
  struct sockaddr	sa;
  struct sockaddr_un	saun;
  struct sockaddr_in	sin;
  struct sockaddr_in6	sin6;
};

typedef struct privateSocketStruct
{
  int s;			/* Unix socket */
  int connSema;			/* connection io notification semaphore */
  int readSema;			/* read io notification semaphore */
  int writeSema;		/* write io notification semaphore */
  int sockState;		/* connection + data state */
  int sockError;		/* errno after socket error */
  union sockaddr_any peer;	/* default send/recv address for UDP */
  socklen_t peerSize;		/* dynamic sizeof(peer) */
  union sockaddr_any sender;	/* sender address for last UDP receive */
  socklen_t senderSize;		/* dynamic sizeof(sender) */
  int multiListen;		/* whether to listen for multiple connections */
  int acceptedSock;		/* a connection that has been accepted */
} privateSocketStruct;

#define CONN_NOTIFY	(1<<0)
#define READ_NOTIFY	(1<<1)
#define WRITE_NOTIFY	(1<<2)

#define PING(S,EVT)						\
{								\
  FPRINTF((stderr, "notify %d %s\n", (S)->s, #EVT));		\
  interpreterProxy->signalSemaphoreWithIndex((S)->EVT##Sema);	\
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

#define SOCKET(S)		(PSP(S)->s)
#define SOCKETSTATE(S)		(PSP(S)->sockState)
#define SOCKETERROR(S)		(PSP(S)->sockError)
#define SOCKETPEER(S)		(PSP(S)->peer)
#define SOCKETPEERSIZE(S)	(PSP(S)->peerSize)


/*** Resolver state ***/

static char lastName[MAXHOSTNAMELEN+1];
static int  lastAddr= 0;
static int  lastError= 0;
static int  resolverSema= 0;

/*** Variables ***/

extern struct VirtualMachine *interpreterProxy;
int setHookFn;


static void acceptHandler(int, void *, int);
static void connectHandler(int, void *, int);
static void dataHandler(int, void *, int);
static void closeHandler(int, void *, int);



#ifdef AIO_DEBUG
char *socketHandlerName(aioHandler h)
{
  if (h == acceptHandler)     return "acceptHandler";
  if (h == connectHandler)    return "connectHandler";
  if (h == dataHandler)       return "dataHandler";
  if (h == closeHandler)      return "closeHandler";
  return "***unknownHandler***";
}
#endif


/*** module initialisation/shutdown ***/


sqInt socketInit(void)
{
  return 1;
}

sqInt socketShutdown(void)
{
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

sqInt sqNetworkInit(sqInt resolverSemaIndex)
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
  aioFini();
}



/***  Squeak Generic Socket Functions   ***/


/* create a new socket */

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(SocketPtr s, sqInt domain, sqInt socketType, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex)
{
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, domain, socketType,recvBufSize, sendBufSize, semaIndex, semaIndex, semaIndex);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt domain, sqInt socketType, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{
  int newSocket= -1;
  privateSocketStruct *pss;

  switch (domain)
    {
    case 0:	domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_UNSPECIFIED */
    case 1:	domain= AF_UNIX;	break;	/* SQ_SOCKET_DOMAIN_LOCAL */
    case 2:	domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_INET4 */
    case 3:	domain= AF_INET6;	break;	/* SQ_SOCKET_DOMAIN_INET6 */
    }

  s->sessionID= 0;
  if (TCPSocketType == socketType)
    {
      /* --- TCP --- */
      newSocket= socket(domain, SOCK_STREAM, 0);
    }
  else if (UDPSocketType == socketType)
    {
      /* --- UDP --- */
      newSocket= socket(domain, SOCK_DGRAM, 0);
    }
  else if (ProvidedTCPSocketType == socketType)
    {
      /* --- Existing socket --- */
      if (sd_listen_fds(0) == 0)
        {
          socketType = TCPSocketType;
          newSocket= SD_LISTEN_FDS_START + 0;
        }
      else
        {
          interpreterProxy->success(false);
          return;
        }
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
  pss->peer.sin.sin_family= AF_INET;
  pss->peer.sin.sin_port= 0;
  pss->peer.sin.sin_addr.s_addr= INADDR_ANY;
  /* Squeak socket */
  s->sessionID= thisNetSession;
  s->socketType= socketType;
  s->privateSocketPtr= pss;
  FPRINTF((stderr, "create(%d) -> %lx\n", SOCKET(s), (unsigned long)PSP(s)));
  /* Note: socket is in BLOCKING mode until aioEnable is called for it! */
}

void sqSocketCreateRawProtoTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt domain, sqInt protocol, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{
  int newSocket= -1;
  privateSocketStruct *pss;

  s->sessionID= 0;
  switch(protocol) {
	case 1: newSocket = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP); break;
  }
  if (-1 == newSocket)
    {
      /* socket() failed, or incorrect protocol type */
      fprintf(stderr, "primSocketCreateRAW: socket() failed; protocol = %ld, errno = %d\n", protocol, errno);
      interpreterProxy->success(false);
      return;
    }

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

  /* RAW sockets are born "connected" */
  pss->sockState= Connected;
  aioEnable(pss->s, pss, 0);
  pss->sockError= 0;
  /* initial UDP peer := wildcard */
  memset(&pss->peer, 0, sizeof(pss->peer));
  pss->peer.sin.sin_family= AF_INET;
  pss->peer.sin.sin_port= 0;
  pss->peer.sin.sin_addr.s_addr= INADDR_ANY;
  /* Squeak socket */
  s->sessionID= thisNetSession;
  s->socketType= RAWSocketType;
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
  FPRINTF((stderr, "listenOnPortBacklogSize(%d, %ld)\n", SOCKET(s), backlogSize));
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
      /* --- UDP/RAW --- */
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
  if (TCPSocketType != s->socketType)
    {
      /* --- UDP/RAW --- */
      if (SOCKET(s) >= 0)
	{
	  int result;
	  memcpy((void *)&SOCKETPEER(s), (void *)&saddr, sizeof(saddr));
	  SOCKETPEERSIZE(s)= sizeof(struct sockaddr_in);
	  result= connect(SOCKET(s), (struct sockaddr *)&saddr, sizeof(saddr));
	  if (result == 0)
	    SOCKETSTATE(s)= Connected;
	}
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


void sqSocketAcceptFromRecvBytesSendBytesSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex)
{
  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, serverSocket, recvBufSize, sendBufSize, semaIndex, semaIndex, semaIndex);
}


void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
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

void sqSocketAbortConnection(SocketPtr s)
{
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
  /* --- UDP/RAW --- */
  return ntohl(SOCKETPEER(s).sin.sin_addr.s_addr);
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
  /* --- UDP/RAW --- */
  return ntohs(SOCKETPEER(s).sin.sin_port);
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
sqInt sqSocketReceiveDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  int nread= 0;

  if (!socketValid(s))
    return -1;

  SOCKETPEERSIZE(s)= 0;

  if (TCPSocketType != s->socketType)
    {
      /* --- UDP/RAW --- */
      socklen_t addrSize= sizeof(SOCKETPEER(s));
      if ((nread= recvfrom(SOCKET(s), buf, bufSize, 0, (struct sockaddr *)&SOCKETPEER(s), &addrSize)) <= 0)
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
      SOCKETPEERSIZE(s)= addrSize;
    }
  else
    {
      /* --- TCP --- */
      if ((nread= read(SOCKET(s), buf, bufSize)) <= 0)
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
sqInt sqSocketSendDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  int nsent= 0;

  if (!socketValid(s))
    return -1;

  if (TCPSocketType != s->socketType)
    {
      /* --- UDP/RAW --- */
      FPRINTF((stderr, "UDP sendData(%d, %ld)\n", SOCKET(s), bufSize));
      if ((nsent= sendto(SOCKET(s), buf, bufSize, 0, (struct sockaddr *)&SOCKETPEER(s), sizeof(SOCKETPEER(s)))) <= 0)
	{
      int err = errno;
	  if (err == EWOULDBLOCK)	/* asynchronous write in progress */
	    return 0;
	  FPRINTF((stderr, "UDP send failed %d %s\n", err, strerror(err)));
	  SOCKETERROR(s)= err;
	  return 0;
	}
    }
  else
    {
      /* --- TCP --- */
      FPRINTF((stderr, "TCP sendData(%d, %ld)\n", SOCKET(s), bufSize));
      if ((nsent= write(SOCKET(s), buf, bufSize)) <= 0)
	{
	  if ((nsent == -1) && (errno == EWOULDBLOCK))
	    {
	      FPRINTF((stderr, "TCP sendData(%d, %ld) -> %d [blocked]",
		       SOCKET(s), bufSize, nsent));
	      return 0;
	    }
	  else
	    {
	      /* error: most likely "connection closed by peer" */
	      SOCKETSTATE(s)= OtherEndClosed;
	      SOCKETERROR(s)= errno;
	      FPRINTF((stderr, "TCP write failed -> %d", SOCKETERROR(s)));
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
sqInt sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, char *buf, sqInt bufSize,  sqInt *address,  sqInt *port, sqInt *moreFlag)
{
  if (socketValid(s) && (TCPSocketType != s->socketType)) /* --- UDP/RAW --- */
    {
      struct sockaddr_in saddr;
      socklen_t addrSize= sizeof(saddr);

      FPRINTF((stderr, "recvFrom(%d)\n", SOCKET(s)));
      memset(&saddr, 0, sizeof(saddr));
      { 
	int nread= recvfrom(SOCKET(s), buf, bufSize, 0, (struct sockaddr *)&saddr, &addrSize);
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
sqInt sqSockettoHostportSendDataBufCount(SocketPtr s, sqInt address, sqInt port, char *buf, sqInt bufSize)
{
  if (socketValid(s) && (TCPSocketType != s->socketType))
    {
      struct sockaddr_in saddr;

      FPRINTF((stderr, "sendTo(%d)\n", SOCKET(s)));
      memset(&saddr, 0, sizeof(saddr));
      saddr.sin_family= AF_INET;
      saddr.sin_port= htons((short)port);
      saddr.sin_addr.s_addr= htonl(address);
      {
	int nsent= sendto(SOCKET(s), buf, bufSize, 0, (struct sockaddr *)&saddr, sizeof(saddr));
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
  { "TCP_MAXSEG",			SOL_TCP,	TCP_MAXSEG },
  { "TCP_NODELAY",			SOL_TCP,	TCP_NODELAY },
#ifdef TCP_CORK
  { "TCP_CORK",		        SOL_TCP,	TCP_CORK },
#endif
#ifdef SO_REUSEPORT
  { "SO_REUSEPORT",			SOL_SOCKET,	SO_REUSEPORT },
#endif
#if 0 /*** deliberately unsupported options -- do NOT enable these! ***/
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
#endif
  { (char *)0,				0,		0 }
};


static socketOption *findOption(char *name, size_t nameSize)
{
  if (nameSize < 32)
    {
      socketOption *opt= 0;
      char buf[32];
      buf[nameSize]= '\0';
      strncpy(buf, name, nameSize);
      for (opt= socketOptions; opt->name != 0; ++opt)
	if (!strcmp(buf, opt->name))
	  return opt;
      fprintf(stderr, "SocketPlugin: ignoring unknown option '%s'\n", buf);
    }
  return 0;
}


/* set the given option for the socket.  the option comes in as a
 * String.  (why on earth we might think this a good idea eludes me
 * ENTIRELY, so... if the string doesn't smell like an integer then we
 * copy it verbatim, assuming it's really a ByteArray pretending to be
 * a struct.  caveat hackor.)
 */
sqInt sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, char *optionValue, sqInt optionValueSize, sqInt *result)
{
  if (socketValid(s))
    {
      socketOption *opt= findOption(optionName, (size_t)optionNameSize);
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
	  memcpy((void *)buf, optionValue, optionValueSize);
	  if (optionValueSize <= sizeof(int)
	   && (strtol(buf, &endptr, 0),
	       endptr - buf == optionValueSize)) /* are all option chars digits? */
	    {
	      val= strtol(buf, &endptr, 0);
		  memcpy((void *)buf, (void *)&val, sizeof(val));
		  optionValueSize= sizeof(val);
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
sqInt sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, sqInt *result)
{
  if (socketValid(s))
    {
      socketOption *opt= findOption(optionName, (size_t)optionNameSize);
      if (opt != 0)
	{
	  int optval;	/* NOT sqInt */
	  socklen_t optlen= sizeof(optval);
	  if ((getsockopt(PSP(s)->s, opt->optlevel, opt->optname, (void *)&optval, &optlen)) < 0)
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
  size_t bufSize;
  unsigned char buf[4];

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


sqInt sqResolverStatus(void)
{
  if (!thisNetSession)
    return ResolverUninitialised;
  if (lastError != 0)
    return ResolverError;
  return ResolverSuccess;
}

/*** trivialities ***/

sqInt sqResolverAddrLookupResultSize(void)	{ return strlen(lastName); }
sqInt sqResolverError(void)			{ return lastError; }
sqInt sqResolverLocalAddress(void)
#if 0 
/* old code */
{	sqInt localaddr = nameToAddr(localHostName);
	if (!localaddr)
		localaddr = nameToAddr("localhost");
	return localaddr;
}
#else
/* experimental new code */
{
    struct ifaddrs *ifaddr, *ifa;
    int s;
    char host[NI_MAXHOST];
    sqInt localAddr = 0;

    if (getifaddrs(&ifaddr) == -1) {
        interpreterProxy->success(false);
        return 0;
    }


    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) 
    {
        if (ifa->ifa_addr == NULL)
            continue;  

        s=getnameinfo(ifa->ifa_addr,sizeof(struct sockaddr_in),host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST);

        if(((strcmp(ifa->ifa_name,"eth0")==0)||(strcmp(ifa->ifa_name,"wlan0")==0))&&(ifa->ifa_addr->sa_family==AF_INET))
        {
            if (s != 0)
            {
                interpreterProxy->success(false);
                return 0;
            }
            FPRINTF((stderr, "\tInterface : <%s>\n",ifa->ifa_name ));
            FPRINTF((stderr, "\t IP       : <%s>\n", inet_ntoa(((struct sockaddr_in *)(ifa->ifa_addr))->sin_addr)));
            if(localAddr == 0) { /* take the first plausible answer */
                localAddr = ((struct sockaddr_in *)(ifa->ifa_addr))->sin_addr.s_addr;
            }
           
        }
    }

    freeifaddrs(ifaddr);
    return ntohl(localAddr);

}
#endif
sqInt sqResolverNameLookupResult(void)		{ return lastAddr; }

void sqResolverAddrLookupResult(char *nameForAddress, sqInt nameSize)
{
  memcpy(nameForAddress, lastName, nameSize);
}

/*** name resolution ***/

void sqResolverStartNameLookup(char *hostName, sqInt nameSize)
{
  int len= (nameSize < MAXHOSTNAMELEN) ? nameSize : MAXHOSTNAMELEN;
  memcpy(lastName, hostName, len);
  lastName[len]= lastError= 0;
  FPRINTF((stderr, "name lookup %s\n", lastName));
  lastAddr= nameToAddr(lastName);
  /* we're done before we even started */
  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
}


/* ikp 2007-06-07: Generalised primitives for IPv6, &c. */

/* flags */

#define SQ_SOCKET_NUMERIC		(1<<0)
#define SQ_SOCKET_PASSIVE		(1<<1)

/* family */

#define SQ_SOCKET_FAMILY_UNSPECIFIED	0
#define SQ_SOCKET_FAMILY_LOCAL		1
#define SQ_SOCKET_FAMILY_INET4		2
#define SQ_SOCKET_FAMILY_INET6		3
#define SQ_SOCKET_FAMILY_MAX		4

/* type */

#define SQ_SOCKET_TYPE_UNSPECIFIED	0
#define SQ_SOCKET_TYPE_STREAM		1
#define SQ_SOCKET_TYPE_DGRAM		2
#define SQ_SOCKET_TYPE_MAX		3

/* protocol */

#define SQ_SOCKET_PROTOCOL_UNSPECIFIED	0
#define SQ_SOCKET_PROTOCOL_TCP		1
#define SQ_SOCKET_PROTOCOL_UDP		2
#define SQ_SOCKET_PROTOCOL_MAX		3

void  sqResolverGetAddressInfoHostSizeServiceSizeFlagsFamilyTypeProtocol(char *hostName, sqInt hostSize, char *servName, sqInt servSize,
									 sqInt flags, sqInt family, sqInt type, sqInt protocol);
sqInt sqResolverGetAddressInfoSize(void);
void  sqResolverGetAddressInfoResultSize(char *addr, sqInt addrSize);
sqInt sqResolverGetAddressInfoFamily(void);
sqInt sqResolverGetAddressInfoType(void);
sqInt sqResolverGetAddressInfoProtocol(void);
sqInt sqResolverGetAddressInfoNext(void);

sqInt sqSocketAddressSizeGetPort(char *addr, sqInt addrSize);
void  sqSocketAddressSizeSetPort(char *addr, sqInt addrSize, sqInt port);

void  sqResolverGetNameInfoSizeFlags(char *addr, sqInt addrSize, sqInt flags);
sqInt sqResolverGetNameInfoHostSize(void);
void  sqResolverGetNameInfoHostResultSize(char *name, sqInt nameSize);
sqInt sqResolverGetNameInfoServiceSize(void);
void  sqResolverGetNameInfoServiceResultSize(char *name, sqInt nameSize);

sqInt sqResolverHostNameSize(void);
void  sqResolverHostNameResultSize(char *name, sqInt nameSize);

void  sqSocketBindToAddressSize(SocketPtr s, char *addr, sqInt addrSize);
void  sqSocketListenBacklog(SocketPtr s, sqInt backlogSize);
void  sqSocketConnectToAddressSize(SocketPtr s, char *addr, sqInt addrSize);

sqInt sqSocketLocalAddressSize(SocketPtr s);
void  sqSocketLocalAddressResultSize(SocketPtr s, char *addr, int addrSize);
sqInt sqSocketRemoteAddressSize(SocketPtr s);
void  sqSocketRemoteAddressResultSize(SocketPtr s, char *addr, int addrSize);

sqInt sqSocketSendUDPToSizeDataBufCount(SocketPtr s, char *addr, sqInt addrSize, char *buf, sqInt bufSize);
sqInt sqSocketReceiveUDPDataBufCount(SocketPtr s, char *buf, sqInt bufSize);


/* ---- address and service lookup ---- */


static struct addrinfo *addrList= 0;
static struct addrinfo *addrInfo= 0;
static struct addrinfo *localInfo= 0;


void sqResolverGetAddressInfoHostSizeServiceSizeFlagsFamilyTypeProtocol(char *hostName, sqInt hostSize, char *servName, sqInt servSize,
									sqInt flags, sqInt family, sqInt type, sqInt protocol)
{
  char host[MAXHOSTNAMELEN+1], serv[MAXHOSTNAMELEN+1];
  struct addrinfo request;
  int gaiError= 0;

  FPRINTF((stderr, "GetAddressInfo %ld %ld %ld %ld %ld %ld\n", hostSize, servSize, flags, family, type, protocol));

  if (addrList)
    {
      freeaddrinfo(addrList);
      addrList= addrInfo= 0;
    }

  if (localInfo)
    {
      free(localInfo->ai_addr);
      free(localInfo);
      localInfo= addrInfo= 0;
    }

  if ((!thisNetSession)
      || (hostSize < 0) || (hostSize > MAXHOSTNAMELEN)
      || (servSize < 0) || (servSize > MAXHOSTNAMELEN)
      || (family   < 0) || (family   >= SQ_SOCKET_FAMILY_MAX)
      || (type     < 0) || (type     >= SQ_SOCKET_TYPE_MAX)
      || (protocol < 0) || (protocol >= SQ_SOCKET_PROTOCOL_MAX))
    goto fail;

  if (hostSize)
    memcpy(host, hostName, hostSize);
  host[hostSize]= '\0';

  if (servSize)
    memcpy(serv, servName, servSize);
  serv[servSize]= '\0';

  FPRINTF((stderr, "  -> GetAddressInfo %s %s\n", host, serv));

  if (servSize && (family == SQ_SOCKET_FAMILY_LOCAL) && (servSize < sizeof(((struct sockaddr_un *)0)->sun_path)) && !(flags & SQ_SOCKET_NUMERIC))
    {
      struct stat st;
      if ((0 == stat(servName, &st)) && (st.st_mode & S_IFSOCK))
	{
	  struct sockaddr_un *saun= calloc(1, sizeof(struct sockaddr_un));
	  localInfo= (struct addrinfo *)calloc(1, sizeof(struct addrinfo));
	  localInfo->ai_family= AF_UNIX;
	  localInfo->ai_socktype= SOCK_STREAM;
	  localInfo->ai_addrlen= sizeof(struct sockaddr_un);
	  localInfo->ai_addr= (struct sockaddr *)saun;
	  /*saun->sun_len= sizeof(struct sockaddr_un);*/
	  saun->sun_family= AF_UNIX;
	  memcpy(saun->sun_path, servName, servSize);
	  saun->sun_path[servSize]= '\0';
	  addrInfo= localInfo;
	  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
	  return;
	}
    }

  memset(&request, 0, sizeof(request));

  if (flags & SQ_SOCKET_NUMERIC)	request.ai_flags |= AI_NUMERICHOST;
  if (flags & SQ_SOCKET_PASSIVE)	request.ai_flags |= AI_PASSIVE;

  switch (family)
    {
    case SQ_SOCKET_FAMILY_LOCAL:	request.ai_family= AF_UNIX;		break;
    case SQ_SOCKET_FAMILY_INET4:	request.ai_family= AF_INET;		break;
    case SQ_SOCKET_FAMILY_INET6:	request.ai_family= AF_INET6;		break;
    }

  switch (type)
    {
    case SQ_SOCKET_TYPE_STREAM:		request.ai_socktype= SOCK_STREAM;	break;
    case SQ_SOCKET_TYPE_DGRAM:		request.ai_socktype= SOCK_DGRAM;	break;
    }

  switch (protocol)
    {
    case SQ_SOCKET_PROTOCOL_TCP:	request.ai_protocol= IPPROTO_TCP;	break;
    case SQ_SOCKET_PROTOCOL_UDP:	request.ai_protocol= IPPROTO_UDP;	break;
    }

  gaiError= getaddrinfo(hostSize ? host : 0, servSize ? serv : 0, &request, &addrList);

  if (gaiError)
    {
      /* Linux gives you either <netdb.h> with   correct NI_* bit definitions and no  EAI_* definitions at all
	 or                <bind/netdb.h> with incorrect NI_* bit definitions and the EAI_* definitions we need.
	 We cannot distinguish between impossible constraints and genuine lookup failure, so err conservatively. */
#    if defined(EAI_BADHINTS)
      if (EAI_BADHINTS != gaiError)
	{
	  fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(gaiError));
	  lastError= gaiError;
	  goto fail;
	}
#    else
      fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(gaiError));
#    endif
      addrList= 0;	/* succeed with zero results for impossible constraints */
    }

  addrInfo= addrList;
  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
  return;

 fail:
  interpreterProxy->success(false);
  return;
}


struct addressHeader
{
  int	sessionID;
  int	size;
};

#define AddressHeaderSize	sizeof(struct addressHeader)

#define addressHeader(A)	((struct addressHeader *)(A))
#define socketAddress(A)	((struct sockaddr *)((char *)(A) + AddressHeaderSize))

#define addressValid(A, S)	(thisNetSession && (thisNetSession == addressHeader(A)->sessionID) && (addressHeader(A)->size == ((S) - AddressHeaderSize)))
#define addressSize(A)		(addressHeader(A)->size)


#if 0
static void dumpAddr(struct sockaddr *addr, int addrSize)
{
  int i;
  for (i= 0;  i < addrSize;  ++i)
    fprintf(stderr, "%02x ", ((unsigned char *)addr)[i]);
  fprintf(stderr, " ");
  switch (addr->sa_family)
    {
    case AF_UNIX:	fprintf(stderr, "local\n"); break;
    case AF_INET:	fprintf(stderr, "inet\n"); break;
    case AF_INET6:	fprintf(stderr, "inet6\n"); break;
    default:		fprintf(stderr, "?\n"); break;
    }
}
#endif

sqInt sqResolverGetAddressInfoSize(void)
{
  if (!addrInfo)
    return -1;
  return AddressHeaderSize + addrInfo->ai_addrlen;
}


void sqResolverGetAddressInfoResultSize(char *addr, sqInt addrSize)
{
  if ((!addrInfo) || (addrSize < (AddressHeaderSize + addrInfo->ai_addrlen)))
    {
      interpreterProxy->success(false);
      return;
    }

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      addrInfo->ai_addrlen;
  memcpy(socketAddress(addr), addrInfo->ai_addr, addrInfo->ai_addrlen);
  /*dumpAddr(socketAddress(addr), addrSize - AddressHeaderSize);*/
}


sqInt sqResolverGetAddressInfoFamily(void)
{
  if (!addrInfo)
    {
      interpreterProxy->success(false);
      return 0;
    }

  switch (addrInfo->ai_family)
    {
    case AF_UNIX:	return SQ_SOCKET_FAMILY_LOCAL;
    case AF_INET:	return SQ_SOCKET_FAMILY_INET4;
    case AF_INET6:	return SQ_SOCKET_FAMILY_INET6;
    }

  return SQ_SOCKET_FAMILY_UNSPECIFIED;
}


sqInt sqResolverGetAddressInfoType(void)
{
  if (!addrInfo)
    {
      interpreterProxy->success(false);
      return 0;
    }

  switch (addrInfo->ai_socktype)
    {
    case SOCK_STREAM:	return SQ_SOCKET_TYPE_STREAM;
    case SOCK_DGRAM:	return SQ_SOCKET_TYPE_DGRAM;
    }

  return SQ_SOCKET_TYPE_UNSPECIFIED;
}


sqInt sqResolverGetAddressInfoProtocol(void)
{
  if (!addrInfo)
    {
      interpreterProxy->success(false);
      return 0;
    }

  switch (addrInfo->ai_protocol)
    {
    case IPPROTO_TCP:	return SQ_SOCKET_PROTOCOL_TCP;
    case IPPROTO_UDP:	return SQ_SOCKET_PROTOCOL_UDP;
    }

 return SQ_SOCKET_PROTOCOL_UNSPECIFIED;
}


sqInt sqResolverGetAddressInfoNext(void)
{
  return (addrInfo && (addrInfo= addrInfo->ai_next)) ? true : false;
}


/* ---- address manipulation ---- */


sqInt sqSocketAddressSizeGetPort(char *addr, sqInt addrSize)
{
  if (addressValid(addr, addrSize))
    switch (socketAddress(addr)->sa_family)
      {
      case AF_INET:	return ntohs(((struct sockaddr_in  *)socketAddress(addr))->sin_port);
      case AF_INET6:	return ntohs(((struct sockaddr_in6 *)socketAddress(addr))->sin6_port);
      }

  interpreterProxy->success(false);
  return 0;
}


void sqSocketAddressSizeSetPort(char *addr, sqInt addrSize, sqInt port)
{
  if (addressValid(addr, addrSize))
    switch (socketAddress(addr)->sa_family)
      {
      case AF_INET:	((struct sockaddr_in  *)socketAddress(addr))->sin_port= htons(port);	return;
      case AF_INET6:	((struct sockaddr_in6 *)socketAddress(addr))->sin6_port= htons(port);	return;
      }

  interpreterProxy->success(false);
}


/* ---- host name lookup ---- */


static char hostNameInfo[MAXHOSTNAMELEN+1];
static char servNameInfo[MAXHOSTNAMELEN+1];

static int nameInfoValid= 0;


void sqResolverGetNameInfoSizeFlags(char *addr, sqInt addrSize, sqInt flags)
{
  int niFlags= 0;
  int gaiError= 0;

  FPRINTF((stderr, "GetNameInfoSizeFlags %p %ld %ld\n", addr, addrSize, flags));

  nameInfoValid= 0;

  if (!addressValid(addr, addrSize))
    goto fail;

  niFlags |= NI_NOFQDN;

  if (flags & SQ_SOCKET_NUMERIC) niFlags |= (NI_NUMERICHOST | NI_NUMERICSERV);

  /*dumpAddr(socketAddress(addr), addrSize - AddressHeaderSize);  fprintf(stderr, "%02x\n", niFlags);*/

  gaiError= getnameinfo(socketAddress(addr), addrSize - AddressHeaderSize,
			hostNameInfo, sizeof(hostNameInfo),
			servNameInfo, sizeof(servNameInfo),
			niFlags);

  if (gaiError)
    {
      fprintf(stderr, "getnameinfo: %s\n", gai_strerror(gaiError));
      lastError= gaiError;
      goto fail;
    }

  nameInfoValid= 1;
  interpreterProxy->signalSemaphoreWithIndex(resolverSema);
  return;

 fail:
  interpreterProxy->success(false);
}


sqInt sqResolverGetNameInfoHostSize(void)
{
  if (!nameInfoValid)
    {
      interpreterProxy->success(false);
      return 0;
    }
  return strlen(hostNameInfo);
}


void sqResolverGetNameInfoHostResultSize(char *name, sqInt nameSize)
{
  int len;

  if (!nameInfoValid)
    goto fail;

  len= strlen(hostNameInfo);
  if (nameSize < len)
    goto fail;

  memcpy(name, hostNameInfo, len);
  return;

 fail:
  interpreterProxy->success(false);
}


sqInt sqResolverGetNameInfoServiceSize(void)
{
  if (!nameInfoValid)
    {
      interpreterProxy->success(false);
      return 0;
    }
  return strlen(servNameInfo);
}


void sqResolverGetNameInfoServiceResultSize(char *name, sqInt nameSize)
{
  int len;

  if (!nameInfoValid)
    goto fail;

  len= strlen(servNameInfo);
  if (nameSize < len)
    goto fail;

  memcpy(name, servNameInfo, len);
  return;

 fail:
  interpreterProxy->success(false);
}


sqInt sqResolverHostNameSize(void)
{
  char buf[MAXHOSTNAMELEN+1];
  if (gethostname(buf, sizeof(buf)))
    {
      interpreterProxy->success(false);
      return 0;
    }
  return strlen(buf);
}


void sqResolverHostNameResultSize(char *name, sqInt nameSize)
{
  char buf[MAXHOSTNAMELEN+1];
  int len;
  if (gethostname(buf, sizeof(buf)) || (nameSize < (len= strlen(buf))))
    {
      interpreterProxy->success(false);
      return;
    }
  memcpy(name, buf, len);
}


/* ---- circuit setup ---- */


void sqSocketBindToAddressSize(SocketPtr s, char *addr, sqInt addrSize)
{
  privateSocketStruct *pss= PSP(s);

  if (!(socketValid(s) && addressValid(addr, addrSize)))
    goto fail;

  if (bind(SOCKET(s), socketAddress(addr), addressSize(addr)) == 0)
    return;

  pss->sockError= errno;

 fail:
  interpreterProxy->success(false);
}


void sqSocketListenBacklog(SocketPtr s, sqInt backlogSize)
{
  if (!socketValid(s))
    goto fail;

  if ((backlogSize > 1) && (s->socketType != TCPSocketType))
    goto fail;

  PSP(s)->multiListen= (backlogSize > 1);

  FPRINTF((stderr, "listenBacklog(%d, %ld)\n", SOCKET(s), backlogSize));

  if (TCPSocketType == s->socketType)
    {
      listen(SOCKET(s), backlogSize);	/* acceptHandler catches errors */
      SOCKETSTATE(s)= WaitingForConnection;
      aioEnable(SOCKET(s), PSP(s), 0);
      aioHandle(SOCKET(s), acceptHandler, AIO_RX); /* R => accept() */
    }

  return;

 fail:
  interpreterProxy->success(false);
  return;
}


void sqSocketConnectToAddressSize(SocketPtr s, char *addr, sqInt addrSize)
{
  /* TCP => open a connection.
   * UDP => set remote address.
   */
  if (!(socketValid(s) && addressValid(addr, addrSize)))
    {
      interpreterProxy->success(false);
      return;
    }

  FPRINTF((stderr, "connectToAddressSize(%d)\n", SOCKET(s)));

  if (TCPSocketType != s->socketType)	/* --- UDP/RAW --- */
    {
      if (SOCKET(s) >= 0)
	{
	  int result;
	  memcpy((void *)&SOCKETPEER(s), socketAddress(addr), addressSize(addr));
	  SOCKETPEERSIZE(s)= addressSize(addr);
	  result= connect(SOCKET(s), socketAddress(addr), addressSize(addr));
	  if (result == 0)
	    SOCKETSTATE(s)= Connected;
	}
    }
  else					/* --- TCP --- */
    {
      int result;
      aioEnable(SOCKET(s), PSP(s), 0);
      result= connect(SOCKET(s), socketAddress(addr), addressSize(addr));
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
	      perror("sqConnectToAddressSize");
	      SOCKETSTATE(s)= Unconnected;
	      SOCKETERROR(s)= errno;
	      notify(PSP(s), CONN_NOTIFY);
	    }
	}
    }
}


sqInt sqSocketLocalAddressSize(SocketPtr s)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;

  if (getsockname(SOCKET(s), &saddr.sa, &saddrSize))
    return 0;

  return AddressHeaderSize + saddrSize;
}


void sqSocketLocalAddressResultSize(SocketPtr s, char *addr, int addrSize)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    goto fail;

  if (getsockname(SOCKET(s), &saddr.sa, &saddrSize))
    goto fail;

  if (addrSize != (AddressHeaderSize + saddrSize))
    goto fail;

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      saddrSize;
  memcpy(socketAddress(addr), &saddr.sa, saddrSize);
  return;

 fail:
  interpreterProxy->success(false);
  return;
}


sqInt sqSocketRemoteAddressSize(SocketPtr s)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s))
    return -1;

  if (TCPSocketType == s->socketType)		/* --- TCP --- */
    {
      if (0 == getpeername(SOCKET(s), &saddr.sa, &saddrSize))
	{
	  if (saddrSize < sizeof(SOCKETPEER(s)))
	    {
	      memcpy(&SOCKETPEER(s), &saddr.sa, saddrSize);
	      return AddressHeaderSize + (SOCKETPEERSIZE(s)= saddrSize);
	    }
	}
    }
  else if (SOCKETPEERSIZE(s))			/* --- UDP/RAW --- */
    {
      return AddressHeaderSize + SOCKETPEERSIZE(s);
    }

  return -1;
}


void sqSocketRemoteAddressResultSize(SocketPtr s, char *addr, int addrSize)
{
  if (!socketValid(s)
   || !SOCKETPEERSIZE(s)
   || (addrSize != (AddressHeaderSize + SOCKETPEERSIZE(s)))) {
    interpreterProxy->success(false);
    return;
  }

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      SOCKETPEERSIZE(s);
  memcpy(socketAddress(addr), &SOCKETPEER(s), SOCKETPEERSIZE(s));
  SOCKETPEERSIZE(s)= 0;
}


/* ---- communication ---- */


sqInt sqSocketSendUDPToSizeDataBufCount(SocketPtr s, char *addr, sqInt addrSize, char *buf, sqInt bufSize)
{
  FPRINTF((stderr, "sendTo(%d)\n", SOCKET(s)));
  if (socketValid(s) && addressValid(addr, addrSize) && (TCPSocketType != s->socketType)) /* --- UDP/RAW --- */
    {
      int nsent= sendto(SOCKET(s), buf, bufSize, 0, socketAddress(addr), addrSize - AddressHeaderSize);
      if (nsent >= 0)
	return nsent;
	
      if (errno == EWOULDBLOCK)	/* asynchronous write in progress */
	return 0;

      FPRINTF((stderr, "UDP send failed\n"));
      SOCKETERROR(s)= errno;
    }

  interpreterProxy->success(false);
  return 0;
}


sqInt sqSocketReceiveUDPDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  FPRINTF((stderr, "recvFrom(%d)\n", SOCKET(s)));
  if (socketValid(s) && (TCPSocketType != s->socketType)) /* --- UDP/RAW --- */
    {
      socklen_t saddrSize= sizeof(SOCKETPEER(s));
      int nread= recvfrom(SOCKET(s), buf, bufSize, 0, &SOCKETPEER(s).sa, &saddrSize);
      if (nread >= 0)
	{
	  SOCKETPEERSIZE(s)= saddrSize;
	  return nread;
	}
      SOCKETPEERSIZE(s)= 0;
      if (errno == EWOULDBLOCK)	/* asynchronous read in progress */
	return 0;
      SOCKETERROR(s)= errno;
      FPRINTF((stderr, "receiveData(%d)= %da\n", SOCKET(s), 0));
    }
  interpreterProxy->success(false);
  return 0;
}
