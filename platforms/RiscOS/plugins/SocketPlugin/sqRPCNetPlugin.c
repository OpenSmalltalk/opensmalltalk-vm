/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqRPCNetPlugin.c                                 */
/*  hook up to RiscOS socket stuff                                        */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */

/* Shamelessly copied from Unix socket support.
 *
 * Author: Ian Piumarta (ian.piumarta@inria.fr)
 * Minor Acorn changes: Tim Rowledge (tim@sumeru.stanford.edu)
 *
 * Last edited: April 20 2000 by tim@sumeru.stanford.edu to convert for plugin VM usage
 *
 * Notes:
 *
 * 1. 	UDP support is fully implemented here, but is missing in the
 * 	image.
 *
 * 2.	Sockets are completely asynchronous, but the resolver is still
 *	synchronous.
 *
 * 3.	Due to bugs in Solaris and HP-UX (and possibly others) the SIGIO
 *	mechanism is no longer used.  Instead aioPollForIO() is periodically
 *	called from HandleEvents in sqXWindow.c in order to check for I/O
 *	completion using select().
 */
#include "sq.h"
#include "SocketPlugin.h"

// uncomment to get lots of maybe useful info printed out --
//#define DEBUG

#ifdef ACORN
  #include <time.h>
  #define __time_t
  #include <signal.h>
  #include "inetlib.h"
  #include "socklib.h"
  #include "netdb.h"
  #include "unixlib.h"
  #include "sys/ioctl.h"
  #include "sys/errno.h"
  #define h_errno errno
  #define MAXHOSTNAMELEN 256
  #define socklen_t int 
#else
  #ifdef HAVE_UNISTD_H
  # include <sys/types.h>
  # include <unistd.h>
  // Acorn library bug in strncpy
  #define copyNCharsFromTo(max, res, lastName) strncpy((lastName), (res), MAXHOSTNAMELEN);
  #endif
  
  #ifdef NEED_GETHOSTNAME_P
    extern int gethostname();
  #endif
  
  #include <signal.h>
  #include <sys/param.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <netdb.h>
  
  #include <sys/ioctl.h>
  #include <errno.h>
  
  #ifdef HAVE_SYS_TIME_H
  # include <sys/time.h>
  #else
  # include <time.h>
  #endif
  
  #ifdef HAS_SYS_SELECT_H
  # include <sys/select.h>
  #endif
  
  #ifndef FIONBIO
  # ifdef HAVE_SYS_FILIO_H
  #  include <sys/filio.h>
  # endif
  # ifndef FIONBIO
  #  ifdef FIOSNBIO
  #   define FIONBIO FIOSNBIO
  #  else
  #   error: FIONBIO is not defined
  #  endif
  # endif
  #endif
#endif

/* debugging stuff; can probably be deleted */

#ifdef DEBUG
#ifdef ACORN
#define FPRINTF(s)\
{\
	extern os_error privateErr;\
	extern void platReportError( os_error * e);\
	privateErr.errnum = (bits)0;\
	sprintf s;\
	platReportError((os_error *)&privateErr);\
};
#else
# define FPRINTF(X) fprintf X
#endif
  char *ticks= "-\\|/";
  char *ticker= "";
# define DO_TICK() \
    { fprintf(stderr, "\r%c\r", *ticker); if (!*ticker++) ticker= ticks; }
#else
# define FPRINTF(X)
# define DO_TICK()
#endif


/*** Socket types ***/

#define TCPSocketType	 	0
#define UDPSocketType	 	1


/*** Resolver states ***/

#define ResolverUninitialized	0
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
static u_long localHostAddress;		/* WARNING: GROSS IPv4 ASSUMPTION!!! */

typedef struct privateSocketStruct {
  int s;				/* Unix socket */
  int sema;				/* io notification semaphore */
  int sockState;			/* connection + data state */
  int sockError;			/* errno after socket error */
  struct sockaddr_in peer;		/* default send/recv address for UDP */
} privateSocketStruct;


/*** Accessors for private socket members from a Squeak socket pointer ***/

#define PSP(S)		((privateSocketStruct *)((S)->privateSocketPtr))

#define SOCKET(S)	(PSP(S)->s)
#define SOCKETSEMA(S)	(PSP(S)->sema)
#define SOCKETSTATE(S)	(PSP(S)->sockState)
#define SOCKETERROR(S)	(PSP(S)->sockError)
#define SOCKETPEER(S)	(PSP(S)->peer)

#define SIGNAL(PSS)	(interpreterProxy->signalSemaphoreWithIndex((PSS)->sema))

/*** Resolver state ***/

static char lastName[MAXHOSTNAMELEN+1];
static int  lastAddr= 0;
static int  lastError= 0;

static int  resolverSema;

/*** Variables ***/
extern struct VirtualMachine *interpreterProxy;
int setHookFn;

/*** asynchronous i/o support ***/

/* handler flags */
#define AIO_EX	(0<<0)
#define AIO_RD	(1<<0)
#define AIO_WR	(1<<1)
#define AIO_RW	(AIO_RD | AIO_WR)

typedef void (*AioHandler)(privateSocketStruct *pss, int errorFlag);

static privateSocketStruct *sockets[FD_SETSIZE];
static AioHandler	    handler[FD_SETSIZE];

static int	lastSocket;
static fd_set	readMask;
static fd_set	writeMask;
static fd_set	exceptionMask;

static void nullHandler(privateSocketStruct *, int);
static void acceptHandler(privateSocketStruct *, int);
static void connectHandler(privateSocketStruct *, int);
static void dataHandler(privateSocketStruct *, int);
static void closeHandler(privateSocketStruct *, int);
void aioPollForIO(int microSeconds, int extraFd);


#ifdef DEBUG
static char *handlerName(AioHandler h) {
  if (h == nullHandler)    return "nullHandler";
  if (h == acceptHandler)  return "acceptHandler";
  if (h == connectHandler) return "connectHandler";
  if (h == dataHandler)    return "dataHandler";
  if (h == closeHandler)   return "closeHandler";
  return "***unknownHandler***";
}
#endif

/* module initialization/shutdown */
int socketInit(void) {

	setHookFn = interpreterProxy->ioLoadFunctionFrom( "setSocketPollFunction" , NULL);
	if(!setHookFn) {
		/* no hook found. can't continue */
		return 0;
	}
	/* install my socket polling function */
	((void (*) (int)) setHookFn)((int)aioPollForIO);
	return 1;
}

int socketShutdown(void) {
// first turn off the polling function
	((void (*) (int)) setHookFn)(0);
// then shutdown the network
	sqNetworkShutdown();
	return 1;
}


/* poll for io activity and call the appropriate handler(s) *
 *
 * Note: this can be called from ioProcessEvents with a zero timeout
 *       and from ioRelinquishProcessor with a non-zero timeout.
 *
 *	 "extraFd" is a file descriptor that is polled for reading but
 *	 never handled -- this allows a relinquished CPU to return
 *	 early if there is mouse or keyboard input activity.  Essential
 *	 for (e.g.) handling keyboard interrupts during i/o wait.
 */
void aioPollForIO(int microSeconds, int extraFd)
{
  int fd;
  fd_set rd, wr, ex;
  struct timeval tv;

  DO_TICK();

  /* get out early if there is no pending i/o and no need to relinquish cpu */
  if (!lastSocket && !microSeconds) return;

  rd= readMask;
  wr= writeMask;
  ex= exceptionMask;
  if (extraFd) FD_SET(extraFd, &rd);
  tv.tv_sec=  microSeconds / 1000000;
  tv.tv_usec= microSeconds % 1000000;

  {
    int limit= (extraFd > lastSocket ? extraFd : lastSocket) + 1;
    int result;
    do {
      result= select(limit, &rd, &wr, &ex, &tv);
    } while (result < 0 && errno == EINTR);
    if (result < 0) perror("select");
    if (result != 0)
      for (fd= 0; fd < lastSocket + 1; ++fd) {
	if (FD_ISSET(fd, &ex))
	  handler[fd](sockets[fd], 1);
	else if (FD_ISSET(fd, &rd) || FD_ISSET(fd, &wr))
	  if (fd != extraFd)
	    handler[fd](sockets[fd], 0);
      }
  }
}


/* enable asynchronous notification for a socket */
static void aioEnable(privateSocketStruct *pss)
{
  int fd= pss->s;

  FPRINTF((stderr, "aioEnable(%d)\n", fd));

  sockets[fd]= pss;
  handler[fd]= nullHandler;
#ifdef FIOSNBIO	/* HP-UKes again */
  if (ioctl(fd, FIOSNBIO, (char *)&one) < 0) perror("ioctl(FIOSNBIO,1)");
#else
  if (ioctl(fd, FIONBIO, (char *)&one) < 0) perror("ioctl(FIONBIO,1)");
#endif
}

/* install/change the handler for a socket */
static void aioHandle(privateSocketStruct *pss,
		      AioHandler handlerFn,
		      int flags)
{
  int fd= pss->s;

  FPRINTF((stderr, "aioHandle(%d,%s,%d)\n",
	   fd, handlerName(handlerFn), flags));

  if (sockets[fd] != pss) {
    fprintf(stderr, "aioHandle: bad match\n");
    sockets[fd]= pss;
  }
  handler[fd]= handlerFn;
  if (fd > lastSocket) lastSocket= fd;
  if (flags & AIO_RD) FD_SET(fd, &readMask);
  if (flags & AIO_WR) FD_SET(fd, &writeMask);
  FD_SET(fd, &exceptionMask);
}


/* temporarily suspend asynchronous notification for a socket */
static void aioSuspend(privateSocketStruct *pss)
{
  int fd= pss->s;

  FPRINTF((stderr, "aioSuspend(%d)\n", fd));

  if (fd) {
    FD_CLR(fd, &readMask);
    FD_CLR(fd, &writeMask);
/*  FD_CLR(fd, &exceptionMask); */
    handler[fd]= nullHandler;
    /* keep lastSocket accurate (reduces to zero if no more sockets) */
    while (lastSocket && !FD_ISSET(lastSocket, &exceptionMask))
      --lastSocket;
  }
}


/* definitively disable asynchronous notification for a socket */
static void aioDisable(privateSocketStruct *pss)
{
  int fd= pss->s;

  FPRINTF((stderr, "aioDisable(%d)\n", fd));

  if (fd) {
    FD_CLR(fd, &exceptionMask);
    aioSuspend(pss);
    sockets[fd]= 0;
    handler[fd]= 0;
  }
}


/* initialise asynchronous i/o handlers */
static void aioInit()
{
  int i;

  for (i= 0; i < FD_SETSIZE; i++) {
    sockets[i]= 0;
    handler[i]= 0;
  }
  FD_ZERO(&readMask);
  FD_ZERO(&writeMask);
  FD_ZERO(&exceptionMask);
  lastSocket= 0;
#ifndef ACORN
  signal(SIGPIPE, SIG_IGN);
#endif
}


/* disable handlers and close all sockets */
static void aioShutdown()
{
  int i;

  for (i= 0; i < lastSocket+1; i++)
    if (sockets[i]) {
      aioDisable(sockets[i]);
      close(sockets[i]->s);
    }
}


/*** Miscellaneous sundries ***/

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
  if ((s != 0) && (s->privateSocketPtr != 0) && (s->sessionID == thisNetSession))
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


/*** aio handlers ***/

/* Each handler must at least:
 *   - suspend further handling for the associated socket
 *   - signal its semaphore to indicate that the operation is complete
 */

/* this handler should never normally be invoked */
static void nullHandler(privateSocketStruct *pss, int errFlag)
{
  fprintf(stderr, "nullHandler(%d,%d)\n", pss->s, errFlag);
  aioSuspend(pss);
  if (errFlag)
    pss->sockState= OtherEndClosed;
  SIGNAL(pss);	/* operation complete */
}

/* accept() can now be performed for the socket: call accept(),
   and replace the server socket with the new client socket
   leaving the client socket unhandled */
static void acceptHandler(privateSocketStruct *pss, int errFlag)
{
  FPRINTF((stderr, "acceptHandler(%d,%d)\n", pss->s, errFlag));
  aioSuspend(pss);
  if (errFlag) {
    /* error during listen() */
    close(pss->s);
    pss->sockState= Unconnected;
    pss->sockError= EBADF;	/* educated guess */
  } else {
    /* accept() is ready */
    int newSock= accept(pss->s, 0, 0);
    aioDisable(pss);
    close(pss->s);
    if (newSock < 0) {
      /* error during accept() */
      pss->sockError= errno;
      pss->sockState= Unconnected;
      perror("acceptHandler");
    } else {
      /* connection accepted */
      pss->s= newSock;
      pss->sockState= Connected;
      aioEnable(pss);
    }
  }
  SIGNAL(pss);	/* operation complete */
}

/* connect() has completed: check errors, leaving the socket unhandled */
static void connectHandler(privateSocketStruct *pss, int errFlag)
{
  FPRINTF((stderr, "connectHandler(%d,%d)\n", pss->s, errFlag));
  aioSuspend(pss);
  if (errFlag) {
    /* error during asynchronous connect() */
    close(pss->s);
    perror("connectHandler failed");
    pss->sockError= errno;
    pss->sockState= Unconnected;
  } else {
    /* connect() has completed */
    pss->sockState= Connected;
    FPRINTF ((stderr, "connectHandler ok\n"));
  }
  SIGNAL(pss);	/* operation complete */
}

/* read or write data transfer is now possible for the socket */
static void dataHandler(privateSocketStruct *pss, int errFlag)
{
  FPRINTF((stderr, "dataHandler(%d,%d)\n", pss->s, errFlag));
  aioSuspend(pss);
  if (errFlag)
    /* error: almost certainly "connection closed by peer" */
    pss->sockState= OtherEndClosed;
  SIGNAL(pss);	/* operation complete */
}

/* a non-blocking close() has completed -- finish tidying up */
static void closeHandler(privateSocketStruct *pss, int errFlag)
{
  FPRINTF((stderr, "closeHandler(%d,%d)\n", pss->s, errFlag));
  aioDisable(pss);
  pss->sockState= Unconnected;
  pss->s= 0;
  SIGNAL(pss);	/* operation complete */
}


/*** Squeak network functions ***/

/* start a new network session */
int sqNetworkInit(int resolverSemaIndex)
{
  if (0 != thisNetSession) return 0;  /* already initialised */
  gethostname(localHostName, MAXHOSTNAMELEN);
  localHostAddress= nameToAddr(localHostName);
  thisNetSession= clock() + time(0);
  if (0 == thisNetSession) thisNetSession= 1;  /* 0 => uninitialised */
  resolverSema= resolverSemaIndex;
  aioInit();
  return 0;
}

/* terminate the current network session (invalidates all open sockets) */
void sqNetworkShutdown(void)
{
  thisNetSession= 0;
  resolverSema= 0;
  aioShutdown();
}




/*** Squeak Generic Socket Functions ***/

/* create a new socket */
void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
        SocketPtr s, int netType, int socketType,
        int recvBufSize, int sendBufSize, int semaIndex)
{
  int newSocket= -1;
  privateSocketStruct *pss;

  s->sessionID= 0;
  if (TCPSocketType == socketType)
    /* --- TCP --- */
    newSocket= socket(AF_INET, SOCK_STREAM, 0);
  else if (UDPSocketType == socketType)
    /* --- UDP --- */
    newSocket= socket(AF_INET, SOCK_DGRAM, 0);
  if (-1 == newSocket) { /* socket() failed, or incorrect socketType */
    interpreterProxy->success(false);
    return;
  }
  setsockopt(newSocket, SOL_SOCKET, SO_REUSEADDR, (char *)&one, sizeof(one));
  /* private socket structure */
  pss= (privateSocketStruct *)calloc(1, sizeof(privateSocketStruct));
  pss->s= newSocket;
  pss->sema= semaIndex;
  /* UDP sockets are born "connected" */
  pss->sockState= (UDPSocketType == socketType) ? Connected : Unconnected;
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
int sqSocketConnectionStatus(SocketPtr s)
{
  if (!socketValid(s)) return -1;

  return SOCKETSTATE(s);
}

/* TCP => start listening for incoming connections.
 * UDP => associate the local port number with the socket.
 */
void sqSocketListenOnPort(SocketPtr s, int port)
{
  struct sockaddr_in saddr;

  if (!socketValid(s)) return;

  FPRINTF((stderr, "listenOnPort(%d)\n", SOCKET(s)));

  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family= AF_INET;
  saddr.sin_port= htons((short)port);
  saddr.sin_addr.s_addr= INADDR_ANY;
  bind(SOCKET(s), (struct sockaddr*) &saddr, sizeof(saddr));
  if (TCPSocketType == s->socketType) {
    /* --- TCP --- */
    /* set backlog to 1, since Squeak server sockets only ever accept a single
       connection.  (This is unforgivable, but that's the way things are.) */
    listen(SOCKET(s), 1);
    SOCKETSTATE(s)= WaitingForConnection;
    aioEnable(PSP(s));
    aioHandle(PSP(s), acceptHandler, AIO_RD); /* => accept() possible */
  } else {
    /* --- UDP --- */
  }
}

/* TCP => open a connection.
 * UDP => set remote address.
 */
void sqSocketConnectToPort(SocketPtr s, int addr, int port)
{
  struct sockaddr_in saddr;

  if (!socketValid(s)) return;

  FPRINTF((stderr, "connectTo(%d)\n", SOCKET(s)));

  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family= AF_INET;
  saddr.sin_port= htons((short)port);
  saddr.sin_addr.s_addr= htonl(addr);

  if (UDPSocketType == s->socketType) {
    /* --- UDP --- */
    memcpy((void *)&SOCKETPEER(s), (void *)&saddr, sizeof(SOCKETPEER(s)));
    SOCKETSTATE(s)= Connected;
  } else {
    /* --- TCP --- */
    int result;
    aioEnable(PSP(s));
    result= connect(SOCKET(s), (struct sockaddr *)&saddr, sizeof(saddr));
    FPRINTF((stderr, "connect() => %d\n", result));
    if (result == 0) {
      /* connection completed synchronously */
      SOCKETSTATE(s)= Connected;
      SIGNAL(PSP(s));	/* operation complete */
    } else {
      if (errno == EINPROGRESS || errno == EWOULDBLOCK) {
	/* asynchronous connection in progress */
	SOCKETSTATE(s)= WaitingForConnection;
	aioHandle(PSP(s), connectHandler, AIO_WR);  /* => connect() done */
      } else {
	/* connection error */
	perror("sqConnectToPort");
	SOCKETSTATE(s)= Unconnected;
	SOCKETERROR(s)= errno;
	SIGNAL(PSP(s));	/* operation complete */
      }
    }
  }
}

/* close the socket */
void sqSocketCloseConnection(SocketPtr s)
{
  int result;

  if (!socketValid(s)) return;

  FPRINTF((stderr, "closeConnection(%d)\n", SOCKET(s)));

  aioDisable(PSP(s));
  SOCKETSTATE(s)= ThisEndClosed;
  result= close(SOCKET(s));
  if (result == -1 && errno != EWOULDBLOCK) {
    /* error */
    SOCKETSTATE(s)= Unconnected;
    SOCKETERROR(s)= errno;
    SIGNAL(PSP(s));	/* operation complete */
  } else if (0 == result) {
    /* close completed synchronously */
    SOCKETSTATE(s)= Unconnected;
    SOCKET(s)= 0;
    SIGNAL(PSP(s));	/* operation complete */
  } else {
    /* asynchronous close in progress */
    SOCKETSTATE(s)= ThisEndClosed;
    aioHandle(PSP(s), closeHandler, AIO_EX);  /* => close() done */
  }
}

/* close the socket without lingering */
void sqSocketAbortConnection(SocketPtr s)
{
  struct linger linger= { 0, 0 };

  FPRINTF((stderr, "abortConnection(%d)\n", SOCKET(s)));

  if (!socketValid(s)) return;
  setsockopt(SOCKET(s), SOL_SOCKET, SO_LINGER,
	     (char *)&linger, sizeof(linger));
  sqSocketCloseConnection(s);
}

/* Release the resources associated with this socket. 
   If a connection is open, abort it.*/
void sqSocketDestroy(SocketPtr s)
{
  if (!socketValid(s)) return;

  FPRINTF((stderr, "destroy(%d)\n", SOCKET(s)));

  if (SOCKET(s)) sqSocketAbortConnection(s);	/* close if necessary */
  if (PSP(s)) free(PSP(s));			/* release private struct */
  /* PSP(s)= 0;*/	/* HP-UKes cannot cope with this */
  s->privateSocketPtr= 0;
}

/* answer the OS error code for the last socket operation */
int sqSocketError(SocketPtr s)
{
  if (!socketValid(s)) return -1;

  return SOCKETERROR(s);
}

/* return the local IP address bound to a socket */
int sqSocketLocalAddress(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!socketValid(s)) return -1;

  if (getsockname(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize) ||
      AF_INET != saddr.sin_family)
    return 0;
  return ntohl(saddr.sin_addr.s_addr);
}

/* return the peer's IP address */
int sqSocketRemoteAddress(SocketPtr s)
{
  struct sockaddr_in saddr;
  socklen_t saddrSize;

  if (!socketValid(s)) return -1;

  if (TCPSocketType == s->socketType) {
    /* --- TCP --- */
    saddrSize= sizeof(saddr);
    if (getpeername(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize) ||
	AF_INET != saddr.sin_family)
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

  if (!socketValid(s)) return -1;

  if (getsockname(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize) ||
      AF_INET != saddr.sin_family)
    return 0;
  return ntohs(saddr.sin_port);
}

/* return the peer's port number */
int sqSocketRemotePort(SocketPtr s)
{
  struct sockaddr_in saddr;
  int saddrSize;

  if (!socketValid(s)) return -1;

  if (TCPSocketType == s->socketType) {
    /* --- TCP --- */
    if (getpeername(SOCKET(s), (struct sockaddr *)&saddr, &saddrSize) ||
	AF_INET != saddr.sin_family)
      return 0;
    return ntohs(saddr.sin_port);
  }
  /* --- UDP --- */
  return ntohs(SOCKETPEER(s).sin_port);
}

/* answer whether the socket has data available for reading */
int sqSocketReceiveDataAvailable(SocketPtr s)
{
  if (!socketValid(s)) return -1;
  if (SOCKETSTATE(s) == Connected) {
    if (socketReadable(SOCKET(s))) return true;
    aioHandle(PSP(s), dataHandler, AIO_RW);
  }
  return false;
}

/* answer whether the socket has space to receive more data */
int sqSocketSendDone(SocketPtr s)
{
  if (!socketValid(s)) return -1;
  if (SOCKETSTATE(s) == Connected) {
    if (socketWritable(SOCKET(s))) return true;
    aioHandle(PSP(s), dataHandler, AIO_RW);
  }
  return false;
}

/* read data from the socket s into buf for at most bufSize bytes.
   answer the number actually read.  For UDP, fill in the peer's address
   with the approriate value. */
int sqSocketReceiveDataBufCount(SocketPtr s, int buf, int bufSize)
{
  int nread;

  if (!socketValid(s)) return -1;

  if (UDPSocketType == s->socketType) {
    /* --- UDP --- */
    socklen_t addrSize= sizeof(SOCKETPEER(s));
    if ((nread= recvfrom(SOCKET(s), (void*)buf, bufSize, 0,
			 (struct sockaddr *)&SOCKETPEER(s),
			 &addrSize)) <= 0) {
      addrSize= sizeof(SOCKETPEER(s));
      if (socketReadable(SOCKET(s)) &&
	  ((nread= recvfrom(SOCKET(s), (void*)buf, bufSize, 0,
			    (struct sockaddr *)&SOCKETPEER(s),
			    &addrSize)) <= 0)) {
	SOCKETERROR(s)= errno;
	FPRINTF((stderr, "receiveData(%d) = %da\n", SOCKET(s), 0));
	return 0;
      }
    }
  } else {
    /* --- TCP --- */
    if ((nread= read(SOCKET(s), (void*)buf, bufSize)) <= 0) {
      if (errno == EWOULDBLOCK) {
	/* asynchronous read in progress */
	aioHandle(PSP(s), dataHandler, AIO_RW);	/* => retry */
	return 0;
      } else {
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
  aioSuspend(PSP(s));
  return nread;
}

/* write data to the socket s from buf for at most bufSize bytes.
   answer the number of bytes actually written. */ 
int sqSocketSendDataBufCount(SocketPtr s, int buf, int bufSize)
{
  int nsent;

  if (!socketValid(s)) return -1;

  FPRINTF((stderr, "sendData(%d,%d)\n", SOCKET(s), bufSize));

  if (UDPSocketType == s->socketType) {
    /* --- UDP --- */
  FPRINTF((stderr, "UDP sendData(%d,%d)\n", SOCKET(s), bufSize));
    if ((nsent= sendto(SOCKET(s), (void *)buf, bufSize, 0,
		       (struct sockaddr *)&SOCKETPEER(s),
		       sizeof(SOCKETPEER(s)))) <= 0) {
      if (socketWritable(SOCKET(s)) &&
	  ((nsent= sendto(SOCKET(s), (void *)buf, bufSize, 0,
			  (struct sockaddr *)&SOCKETPEER(s),
			  sizeof(SOCKETPEER(s)))) <= 0)) {
	FPRINTF((stderr, "UDP send failed\n"));
	SOCKETERROR(s)= errno;
	return 0;
      }
    }
  } else {
    /* --- TCP --- */
  FPRINTF((stderr, "TCP sendData(%d,%d)\n", SOCKET(s), bufSize));
    if ((nsent= write(SOCKET(s), (char *)buf, bufSize)) <= 0) {
      if (errno == EWOULDBLOCK) {
	/* asynchronous write in progress */
	aioHandle(PSP(s), dataHandler, AIO_RW);	/* => data sent */
	return 0;
      } else {
	/* error: most likely "connection closed by peer" */
	SOCKETSTATE(s)= OtherEndClosed;
	SOCKETERROR(s)= errno;
	FPRINTF((stderr, "TCP write failed "));
	perror(" ");
	return 0;
      }
    }
  }
  /* write completed synchronously */
  FPRINTF((stderr, "sendData done(%d) = %d\n", SOCKET(s), nsent));
  aioSuspend(PSP(s));
  return nsent;
}


/*!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!*/

void    sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize ){
        interpreterProxy->success(false);
}

void    sqSocketAcceptFromRecvBytesSendBytesSemaID(
        SocketPtr s, SocketPtr serverSocket,
        int recvBufSize, int sendBufSize, int semaIndex) {
        interpreterProxy->success(false);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex)
{
	interpreterProxy->success(false);
}

void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex) {
	interpreterProxy->success(false);
}

int sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, int buf, int bufSize,  int *address,  int *port, int *moreFlag)
{
	interpreterProxy->success(false);
	return false;
}

int sqSockettoHostportSendDataBufCount(SocketPtr s, int address, int port, int buf, int bufSize)
{
	interpreterProxy->success(false);
	return false;
}

int     sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int optionValue, int optionValueSize, int *result)
{
	interpreterProxy->success(false);
	return false;
}


int sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int *result)
{
	interpreterProxy->success(false);
	return false;
}

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
  // Acorn library bug - strncpy(lastName, res, MAXHOSTNAMELEN);
  copyNCharsFromTo(MAXHOSTNAMELEN, res, lastName);
  FPRINTF((stderr, "startAddrLookup %s\n", lastName));
}

int sqResolverStatus(void)
{
  if(!thisNetSession) return ResolverUninitialized;
  if(lastError) return ResolverError;
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
