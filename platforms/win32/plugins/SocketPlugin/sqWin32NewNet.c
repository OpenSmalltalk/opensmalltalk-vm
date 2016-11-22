/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Net.c
*   CONTENT: Networking in Squeak
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*	1) TCP & UDP are now fully supported.
*	2) State changes are now recorded from separate threads to give
*	   maximum responsiveness to Squeak servers.
*	3) Sockets are always accept()ed by the OS level thread. I *think*
*	   that this is a good idea because it makes loosing connections due
*	   to inactivity from Squeak rather unlikely.Though, of course, it
*	   requires resources...
*
*****************************************************************************/

/* add definition to make newer mingw header files compatible */
#define DECLARE_STDCALL_P( type ) __stdcall type 

#include <ws2tcpip.h>
#include <winsock2.h>
#include <windows.h>
#include <wspiapi.h>

#include "sq.h"
#include "SocketPlugin.h"

#ifndef NO_NETWORK

#ifndef STACK_SIZE_PARAM_IS_A_RESERVATION
#  define STACK_SIZE_PARAM_IS_A_RESERVATION 0x00010000
#endif

#ifndef NDEBUG
#define DBG(s,c) debugCheckWatcherThreads(PSP(s),c)
#else
#define DBG(s,c)
#endif

/*** Socket Type Constants ***/
#define TCPSocketType 0
#define UDPSocketType 1
#define RAWSocketType 2

/*** Resolver Status Constants ***/
#define RESOLVER_UNINITIALIZED 0
#define RESOLVER_SUCCESS  1
#define RESOLVER_BUSY   2
#define RESOLVER_ERROR   3

/*** TCP Socket Status Constants ***/
#define Unconnected    0
#define WaitingForConnection 1
#define Connected    2
#define OtherEndClosed   3
#define ThisEndClosed   4

/* read/write watcher operations */
#define WatchNone 0
#define WatchData 1
#define WatchConnect 2
#define WatchClose 3
#define WatchAccept 4
#define WatchAcceptSingle 5

#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define SIGNAL(index) synchronizedSignalSemaphoreWithIndex(index)

#ifndef INVALID_SOCKET
#define INVALID_SOCKET (-1)
#endif
#ifndef SOCKET_ERROR
#define SOCKET_ERROR (-1)
#endif

static WSADATA wsaData;

static int resolverSemaphoreIndex = 0;
static int thisNetSession = 0;
static int runningVista = 0;
static u_long zero = 0;
static u_long one = 1;

#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN 256
#endif
static char localHostName[MAXHOSTNAMELEN];
static u_long localHostAddress;

/* Structure for storing accepted sockets */
typedef struct acceptedSocketStruct {
  struct acceptedSocketStruct *next;
  struct sockaddr_in peer;
  SOCKET s;
} acceptedSocketStruct;

union sockaddr_any
{
  struct sockaddr	sa;
  struct sockaddr_in	sin;
  struct sockaddr_in6	sin6;
};

/* Socket structure private to primitive implementation */
typedef struct privateSocketStruct {
  struct privateSocketStruct *next;
  SOCKET s;

  int sockType;
  int sockState;
  int sockError;

  int readSema;
  int writeSema;
  int connSema;

  union sockaddr_any peer;  /* socket address in connect() or send/rcv address for UDP */
  socklen_t peerSize;		/* dynamic sizeof(peer) */

  HANDLE mutex;             /* The mutex used for synchronized access to this socket */
  acceptedSocketStruct *accepted; /* Accepted connections on a socket */


  DWORD  readWatcherOp;      /* read operation to watch */
  HANDLE hReadWatcherEvent;  /* event for waking up read watcher */
  HANDLE hReadThread;

  DWORD  writeWatcherOp;     /* write operation to watch */
  HANDLE hWriteWatcherEvent; /* event for waking up write watcher */
  HANDLE hWriteThread;

  volatile DWORD closePending; /* Cleanup counter */

  int readSelect;
  int writeSelect;
} privateSocketStruct;

static privateSocketStruct *firstSocket = NULL;
/* Additional flags for sockState which will be received by async notification:
   SOCK_DATA_WRITABLE      - all pending data has been sent
   SOCK_DATA_READABLE      - data is available for this connection
   SOCK_SERVER			   - socket has been initialized for accept()
   SOCK_BOUND_UDP		   - UDP socket has a local port assigned
*/
#define SOCK_PUBLIC_MASK   0x0000FFFF
#define SOCK_DATA_WRITABLE 0x00010000
#define SOCK_DATA_READABLE 0x00020000
#define SOCK_BOUND_UDP     0x00040000

/********* Private accessors of a Squeak socket pointer *********/
#define PSP(s)         ((privateSocketStruct*) ((s)->privateSocketPtr))

#define SOCKET(s)      (PSP(s)->s)
#define SOCKETSTATE(s) (PSP(s)->sockState)
#define SOCKETERROR(s) (PSP(s)->sockError)
#define ADDRESS(s)      ((struct sockaddr_in*)(&PSP(s)->peer))
#define SOCKETPEER(S)		(PSP(S)->peer)
#define SOCKETPEERSIZE(S)	(PSP(S)->peerSize)

extern struct VirtualMachine *interpreterProxy;
#define FAIL()         interpreterProxy->primitiveFail()

#define LOCKSOCKET(mutex, duration) \
  if(WaitForSingleObject(mutex, duration) == WAIT_FAILED)\
      printLastError(TEXT("Failed to lock socket"));
#define UNLOCKSOCKET(mutex)\
  if(ReleaseMutex(mutex) == 0)\
    printLastError(TEXT("Failed to unlock socket"));

/*****************************************************************************
 Helpers
 *****************************************************************************/
static int socketReadable(SOCKET s)
{
  struct timeval tv= { 0, 0 };
  fd_set fds;

  FD_ZERO(&fds);
  FD_SET(s, &fds);
  return select(1, &fds, NULL, NULL, &tv) == 1;
}

static int socketWritable(SOCKET s)
{
  struct timeval tv= { 0, 0 };
  fd_set fds;

  FD_ZERO(&fds);
  FD_SET(s, &fds);
  return select(1, NULL, &fds, NULL, &tv) == 1;
}

static int socketError(SOCKET s)
{
  struct timeval tv= { 0, 0 };
  fd_set fds;

  FD_ZERO(&fds);
  FD_SET(s, &fds);
  return select(1, NULL, NULL, &fds, &tv) == 1;
}

static int removeFromList(privateSocketStruct *pss) {
  /* remove the private pointer from the list */
  privateSocketStruct *tmp;
  if(pss == firstSocket) firstSocket = pss->next;
  else {
    tmp = firstSocket;
    while(tmp && tmp->next != pss) tmp = tmp->next;
    if(tmp) tmp->next = pss->next;
  }
  return 0;
}

/* cleanupSocket:
   Clean up the private socket structure and associated elements.
   The function is called from the watcher threads when a socket
   is being destroyed.
*/
static void cleanupSocket(privateSocketStruct *pss)
{
  int remainingThreads;

  /* Guard socket state for modification */
  LOCKSOCKET(pss->mutex, INFINITE);
  remainingThreads = --pss->closePending;
  UNLOCKSOCKET(pss->mutex);
  if(remainingThreads > 0) {
    /* somebody else will do the cleanup */
    return;
  }
  /* I am the last thread. Do the cleanup */
  CloseHandle(pss->mutex);
  CloseHandle(pss->hReadWatcherEvent);
  CloseHandle(pss->hWriteWatcherEvent);
  CloseHandle(pss->hReadThread);
  CloseHandle(pss->hWriteThread);

  /* Cleanup any accepted sockets */
  while(pss->accepted) {
    acceptedSocketStruct *temp = pss->accepted;
    struct linger l;
    pss->accepted = temp->next;
    l.l_onoff = 1;
    l.l_linger = 0;
    setsockopt(temp->s, SOL_SOCKET, SO_LINGER, (char*)&l, sizeof(l));
    closesocket(temp->s);
    temp->s = 0;
    GlobalFree(GlobalHandle(temp));
  }
  /* And again: C allocators thread safe?! */
  free(pss);
  /* done */
}


/* inplaceAcceptHandler:
   Accept an incoming connection and store the new socket in place
   of the old one. NOTE: Called from thread while socket is locked.
*/
static int inplaceAcceptHandler(privateSocketStruct *pss)
{
  SOCKET newSocket;
  struct linger l;

  newSocket = accept(pss->s,0,NULL);
  if(newSocket == INVALID_SOCKET) {
    pss->sockError = WSAGetLastError();
  } else {
    /* Destroy the server socket */
    l.l_onoff = 1;
    l.l_linger = 0;
    setsockopt(pss->s, SOL_SOCKET, SO_LINGER, (char*)&l, sizeof(l));
    ioctlsocket(newSocket,FIONBIO,&zero);
    closesocket(pss->s);
    pss->s = 0;
    /* Make the socket non-blocking */
    ioctlsocket(newSocket,FIONBIO,&one);
    /* And install the new socket */
    pss->s = newSocket;
    pss->sockState = Connected | SOCK_DATA_WRITABLE; /* connected and ready to send */
  }
  return 1;
}

/* acceptHandler:
   Accept an incoming connection and store the socket in the
   list of accepted sockets from the server socket.
   NOTE: Called from thread while socket is locked.
*/
static int acceptHandler(privateSocketStruct *pss)
{
  SOCKET result;
  int addrSize = sizeof(struct sockaddr_in);
  struct sockaddr_in addr;
  acceptedSocketStruct *accepted = NULL;

  /* accept incoming connections */
  result = accept(pss->s, (struct sockaddr*) &pss->peer, &addrSize);
  if(result != INVALID_SOCKET) {
    /* prepare the accept structure */
    /* Q: Are the C allocation functions thread safe?! */
    accepted = GlobalLock(GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, sizeof(acceptedSocketStruct)));
    if(accepted) {
      accepted->s = result;
      MoveMemory(&accepted->peer, &addr, addrSize);
    }
  } else {
    pss->sockError = WSAGetLastError();
  }
  if(accepted != NULL) {
    accepted->next = pss->accepted;
    pss->accepted = accepted;
    pss->sockState = Connected;
  }
  return 1;
}

/*****************************************************************************
 ****************************************************************************/
static void debugPrintSocket(privateSocketStruct *pss) {
  printf("### Socket [%p]\n", pss);
  printf("\tHandle: %" PRIxSQPTR "\n", pss->s);
  printf("\tType: %d\n", pss->sockType);
  printf("\tState: %x", pss->sockState & SOCK_PUBLIC_MASK);
  if(pss->sockState & SOCK_DATA_READABLE)
    printf(" [readable]");
  if(pss->sockState & SOCK_DATA_WRITABLE)
    printf(" [writable]");
  if(pss->sockState & SOCK_BOUND_UDP)
    printf(" [bound for udp]");
  printf("\n");
  printf("\tError: %x\n", pss->sockError);
  printf("\treadSema: %d\n", pss->readSema);
  printf("\twriteSema: %d\n", pss->writeSema);
  printf("\tconnSema: %d\n", pss->connSema);
  { /* count pending accept()s */
    acceptedSocketStruct *tmp = pss->accepted;
    int n = 0;
    while(tmp) {
      tmp = tmp->next;
      n++;
    }
    printf("\tPending accepts: %d\n",n);
  }
  printf("\tRead Watcher Op: %lu\n", pss->readWatcherOp);
  printf("\tWrite Watcher Op: %lu\n",pss->writeWatcherOp);
  printf("\tClose pending: %lu\n",pss->closePending);
  printf("\tIn read select: %d\n", pss->readSelect);
  printf("\tIn write select: %d\n", pss->writeSelect);
}

int win32DebugPrintSocketState(void) {
  privateSocketStruct *pss;

  pss = firstSocket;
  while(pss) {
    debugPrintSocket(pss);
    pss = pss->next;
  }
  return 1;
}

static void debugCheckWatcherThreads(privateSocketStruct *pss, char* caller) {
  int state = pss->sockState;
  int printReason = 0;

  if(pss->readWatcherOp == WatchAccept) {
    /* accept() is different; don't bother */
    return;
  }
  if(pss->readWatcherOp == WatchAcceptSingle) {
    /* same thing */
    return;
  }

  if( (state & SOCK_PUBLIC_MASK) == Unconnected )
    /* means we should not be watching anything */
    if(pss->readSelect || pss->writeSelect ||
       (pss->readWatcherOp != 0) || (pss->writeWatcherOp != 0)) {
      printReason |= 1; /* watching stuff on unconnected socket */
    }

  if( (state & SOCK_PUBLIC_MASK) == Connected) {
    if(pss->readWatcherOp != WatchData)
      printReason |= 2; /* watching non-data stuff on connected socket */
    if( (state & SOCK_DATA_READABLE) == pss->readSelect)
      printReason |= 4; /* watching w/ data or not watching w/o data */
    if(pss->writeWatcherOp != WatchData)
      printReason |= 8; /* watching non-data stuff */
    if( (state & SOCK_DATA_WRITABLE) == pss->writeSelect)
      printReason |= 16; /* watching w/ data or not watching w/o data */
  }

  if( (state & SOCK_PUBLIC_MASK) == WaitingForConnection) {
    if(!pss->writeSelect || (pss->writeWatcherOp != WatchConnect))
      printReason |= 32; /* not watching for connection */
  }
  if( (state & SOCK_PUBLIC_MASK) == ThisEndClosed) {
    if(!pss->readSelect || (pss->readWatcherOp != WatchClose))
      printReason |= 64; /* not watching for close */
  }
  if(printReason) {
    printf("#### WARNING: Watcher threads are running wild on socket (%s)\n", caller);
    if(printReason & 1)
      printf("\t* Watching for stuff while unconnected\n");
    if(printReason & 2)
      printf("\t* Watching for non-data while no data readable\n");
    if(printReason & 4)
      printf("\t* Socket read state differs from select() state\n");
    if(printReason & 8)
      printf("\t* Watching for non-data while no data writable\n");
    if(printReason & 16)
      printf("\t* Socket write state differs from select() state\n");
    if(printReason & 32)
      printf("\t* Watching for non-connect while connecting\n");
    if(printReason & 64)
      printf("\t* Watching for non-close while closing\n");
    debugPrintSocket(pss);
  }
}

/*****************************************************************************
 *****************************************************************************
 State watcher threads:
 The following two functions are run from separate threads. They identify
 a change in read/write state (e.g., whenever a socket switches from
 non-readable to readable or from non-writeable to writeable) set the
 appropriate flags and signal the associated semaphore. To avoid possible
 problems with resource allocation, the threads are never explicitly
 terminated. They have instead an associated timeout value in select()
 after which they can terminate themselves if requested.
 *****************************************************************************
 *****************************************************************************/

static DWORD WINAPI readWatcherThread(privateSocketStruct *pss)
{
  struct timeval tv= { 1000, 0 }; /* Timeout value == 1000 sec */
  fd_set fds;
  int n, doWait;

  while(1) {
    doWait = 1;
    /* Do we have a task to perform?! */
    if(pss->readWatcherOp) {
      /* Determine state of the socket */
      FD_ZERO(&fds);
      FD_SET(pss->s, &fds);
      pss->readSelect = 1;
      n = select(1, &fds, NULL, NULL, &tv);
      pss->readSelect = 0;
      /* Note: select will return
	 0 - if it timed out (unlikely but possible)
	 1 - if the socket is readable
	 SOCKET_ERROR - if the socket has been closed
      */
      if(n == 1) {
	/* Guard socket state modification */
	LOCKSOCKET(pss->mutex, INFINITE);
	/* Change appropriate socket state */
	switch(pss->readWatcherOp) {
	case WatchData:
	  /* Data may be available */
	  pss->sockState |= SOCK_DATA_READABLE;
	  SIGNAL(pss->readSema);
	  doWait = 1; /* until data has been read */
	  break;
	case WatchClose:
	  /* Pending close has succeeded */
	  pss->sockState = ThisEndClosed;
	  pss->readWatcherOp = 0; /* since a close succeeded */
	  pss->s = 0;
	  SIGNAL(pss->connSema);
	  doWait = 1;
	  break;
	case WatchAcceptSingle:
	  /* Accept a single connection inplace */
	  inplaceAcceptHandler(pss);
	  pss->readWatcherOp = WatchData; /* check for incoming data */
	  pss->writeWatcherOp = WatchData; /* and signal when writable */
	  SIGNAL(pss->connSema);
	  doWait = 0;
	  break;
	case WatchAccept:
	  /* Connection can be accepted */
	  acceptHandler(pss);
	  SIGNAL(pss->connSema);
	  doWait = 0; /* only wait for more connections */
	  break;
	}
	UNLOCKSOCKET(pss->mutex);
      } else {
	if(n == SOCKET_ERROR) {
	  int err = WSAGetLastError();
	  LOCKSOCKET(pss->mutex, INFINITE);
	  pss->sockState = OtherEndClosed;
	  pss->sockError = err;
	  SIGNAL(pss->connSema);
	  UNLOCKSOCKET(pss->mutex);
	} else {
	  /* select() timed out */
	  doWait = 0; /* continue waiting in select() */
	}
      }
    }

    /* Wait until we have something to do */
    if(doWait && !pss->closePending)
      WaitForSingleObject(pss->hReadWatcherEvent, INFINITE);

    /* Check if we need to close the socket */
    if(pss->closePending) {
      cleanupSocket(pss);
      /* And stop running */
      ExitThread(0);
    }
  }
}

static DWORD WINAPI writeWatcherThread(privateSocketStruct *pss)
{
  struct timeval tv= { 1000, 0 }; /* Timeout value == 1000 sec */
  fd_set fds, err;
  int n, doWait, errSize;

  while(1) {
    doWait = 1;
    if(pss->writeWatcherOp) {
      /* Determine state of the socket */
      FD_ZERO(&fds);
      FD_SET(pss->s, &fds);
      FD_ZERO(&err);
      FD_SET(pss->s, &err);
      pss->writeSelect = 1;
      n = select(1, NULL, &fds, &err, &tv);
      pss->writeSelect = 0;
      /* Note: select will return
	 0 - if it timed out (unlikely but possible)
	 1 - if the socket is writable or an error occured
	 SOCKET_ERROR - if the socket has been closed
      */
      if(n == 1) {
	/* Guard socket state modification */
	LOCKSOCKET(pss->mutex, INFINITE);
	if(FD_ISSET(pss->s, &err)) {
	  /* An error occured */
	  if(pss->writeWatcherOp == WatchConnect) {
	    /* asynchronous connect failed */
	    pss->sockState = Unconnected;
	    SIGNAL(pss->connSema);
	  } else {
	    /* get socket error */
	    /* printf("ERROR: %d\n", WSAGetLastError()); */
	    errSize = sizeof(pss->sockError);
	    getsockopt(pss->s, SOL_SOCKET, SO_ERROR, (char*)&pss->sockError, &errSize);
	    SIGNAL(pss->writeSema);
	  }
	  pss->writeWatcherOp = 0; /* what else can we do */
	  doWait = 1; /* until somebody wakes us up */
	} else {
	  /* Change appropriate socket state */
	  switch(pss->writeWatcherOp) {
	  case WatchConnect:
	    /* Pending connect() has succeeded */
	    pss->sockState = Connected | SOCK_DATA_WRITABLE;
	    /* Start read watcher for incoming data */
	    pss->readWatcherOp = WatchData;
	    SetEvent(pss->hReadWatcherEvent);
	    SIGNAL(pss->connSema);
	    /* And fall through since data can be sent */
	    pss->writeWatcherOp = WatchData;
	  case WatchData:
	    /* Data can be sent */
	    pss->sockState |= SOCK_DATA_WRITABLE;
	    SIGNAL(pss->writeSema);
	    doWait = 1; /* until data has been written */
	    break;
	  }
	}
	UNLOCKSOCKET(pss->mutex);
      } else {
	if(n == SOCKET_ERROR) {
	  int err = WSAGetLastError();
	  LOCKSOCKET(pss->mutex, INFINITE);
	  pss->sockState = OtherEndClosed;
	  pss->sockError = err;
	  SIGNAL(pss->connSema);
	  UNLOCKSOCKET(pss->mutex);
	} else {
	  /* select() timed out */
	  doWait = 0; /* continue waiting in select() */
	}
      }
    }
    /* Wait until we have something to do */
    if(doWait && !pss->closePending) {
      WaitForSingleObject(pss->hWriteWatcherEvent, INFINITE);
    }

    /* Check if we need to close the socket */
    if(pss->closePending) {
      cleanupSocket(pss);
      /* And stop running */
      ExitThread(0);
    }
  }
}

/*****************************************************************************
 *****************************************************************************
 *****************************************************************************/

static void abortSocket(privateSocketStruct *pss)
{
  struct linger l;

  LOCKSOCKET(pss->mutex, INFINITE);
  l.l_onoff = 1;
  l.l_linger = 0;
  setsockopt(pss->s, SOL_SOCKET, SO_LINGER, (char*)&l, sizeof(l));
  closesocket(pss->s);
  pss->s = 0;
  pss->sockState = Unconnected;
  pss->readWatcherOp = 0;
  pss->writeWatcherOp = 0;
  UNLOCKSOCKET(pss->mutex);
}

/* createWatcherThreads: Create the state change watcher threads */
static int createWatcherThreads(privateSocketStruct *pss)
{
  DWORD id;
  HANDLE hThread;
  SYSTEM_INFO sysInfo;
  DWORD pageSize;

  /* determine page boundaries */
  GetSystemInfo(&sysInfo);
  pageSize = sysInfo.dwPageSize;

  /* Setup events */
  pss->hReadWatcherEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
  pss->hWriteWatcherEvent = CreateEvent(NULL, FALSE, FALSE, NULL);

  /* Create the read watcher */
  hThread =
    CreateThread(NULL,			   /* No security descriptor */
		 128*1024,                 /* max stack size     */
		 (LPTHREAD_START_ROUTINE) readWatcherThread, /* what to do */
		 (LPVOID) pss,      /* parameter for thread   */
		 CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,  
		   /* creation parameter -- create suspended so we can check the return value */
		 &id);              /* return value for thread id */
  pss->hReadThread = hThread;
  if(!hThread) {
    printLastError(TEXT("CreateThread() failed"));
    removeFromList(pss);
    pss->closePending = 1;
    abortSocket(pss);
    cleanupSocket(pss);
    return 0;
  }
  if(!SetThreadPriority(hThread, THREAD_PRIORITY_HIGHEST))
    printLastError(TEXT("SetThreadPriority() failed"));
  if(!ResumeThread(hThread))
    printLastError(TEXT("ResumeThread() failed"));

  /* Create the write watcher */
  hThread =
    CreateThread(NULL,			   /* No security descriptor */
		 128*1024,                 /* max stack size     */
		 (LPTHREAD_START_ROUTINE) writeWatcherThread,/* what to do */
		 (LPVOID) pss,      /* parameter for thread   */
		 CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,  
		   /* creation parameter -- create suspended so we can check the return value */
		 &id);              /* return value for thread id */
  pss->hWriteThread = hThread;
  if(!hThread) {
    printLastError(TEXT("CreateThread() failed"));
    removeFromList(pss);
    abortSocket(pss);
    pss->closePending = 1;
    SetEvent(pss->hReadWatcherEvent);
    return 0;
  }
  if(!SetThreadPriority(hThread, THREAD_PRIORITY_HIGHEST))
    printLastError(TEXT("SetThreadPriority() failed"));
  if(!ResumeThread(hThread))
    printLastError(TEXT("ResumeThread() failed"));

  return 1;
}

/*****************************************************************************
 *****************************************************************************
 *****************************************************************************/

/*****************************************************************************
  sqNetworkInit: Initialize network with the given DNS semaphore.
*****************************************************************************/
sqInt sqNetworkInit(sqInt semaIndex)
{
  int err;
  OSVERSIONINFOEX osInfo;

  if (thisNetSession != 0) return 0; /* network is already initialized */

  /* detect if we're running on Vista */
  ZeroMemory(&osInfo, sizeof(osInfo));
  osInfo.dwOSVersionInfoSize = sizeof(osInfo);
  GetVersionEx((OSVERSIONINFO*)&osInfo);
  runningVista = osInfo.dwMajorVersion >= 6;

  err = WSAStartup( MAKEWORD(2,0), &wsaData );
  if ( err != 0 )
    return -1;

  /* Confirm that the Windows Sockets DLL supports 1.1 or greater */
  if(HIBYTE(wsaData.wVersion < 1) || HIBYTE(wsaData.wVersion) > 2) {
    WSACleanup();
    return -1;
  }

  gethostname(localHostName,MAXHOSTNAMELEN);
  thisNetSession = GetTickCount();
  if (thisNetSession == 0) thisNetSession = 1;  /* don't use 0 */

  /* install resolver semaphore */
  resolverSemaphoreIndex = semaIndex;

  /* Done. */
  return 0;
}

/*****************************************************************************
  sqNetworkShutdown: Clean up networking.
*****************************************************************************/
void sqNetworkShutdown(void)
{
  privateSocketStruct *pss;
  if (thisNetSession == 0) return;  /* noop if network is already shut down */

  /* Clean up pending sockets */
  while(firstSocket) {
    pss = firstSocket;
    /* Abort socket */
    abortSocket(pss);
    /* Prepare cleanup from threads */
    LOCKSOCKET(pss->mutex, INFINITE);
    pss->closePending = 2; /* threads are running */
    pss->readWatcherOp = 0;
    pss->writeWatcherOp = 0;
    SetEvent(pss->hReadWatcherEvent);
    SetEvent(pss->hWriteWatcherEvent);
    firstSocket = pss->next;
    UNLOCKSOCKET(pss->mutex);
    /* Note: it is important that we guard the SetEvent() above
       since the threads are running at higher priority and may
       immediately try to clean up once SetEvent() is called.
       Locking the socket prevents them until we are finished */
  }
  thisNetSession = 0;
  WSACleanup();
}

/*** Squeak Generic Socket Functions ***/

/*****************************************************************************
  SocketValid: Validate a given SocketPtr
*****************************************************************************/
static int SocketValid(SocketPtr s) {
  if ((s != NULL) &&
      (s->privateSocketPtr != NULL) &&
      (s->sessionID == thisNetSession)) {
    return true;
  } else {
    FAIL();
    return false;
  }
}

/*****************************************************************************
  sqSocketAbortConnection: Immediately terminate a pending connection
*****************************************************************************/
void sqSocketAbortConnection(SocketPtr s)
{
  if (!SocketValid(s)) return;
  /* abort the socket connection */
  abortSocket(PSP(s));
}

/*****************************************************************************
  sqSocketCloseConnection: gracefully close an open socket
*****************************************************************************/
void sqSocketCloseConnection(SocketPtr s)
{
  privateSocketStruct *pss = PSP(s);
  int err;

  if (!SocketValid(s)) return;
  /* Try to gracefully close the socket */
  err = closesocket(SOCKET(s));
  LOCKSOCKET(pss->mutex, INFINITE);
  pss->readWatcherOp = pss->writeWatcherOp = 0;
  if(err) {
    err = WSAGetLastError();
    if(err == WSAEWOULDBLOCK) {
      /* Setup the read watcher to see when it closed */
      pss->sockState = ThisEndClosed;
      pss->readWatcherOp = WatchClose;
      pss->writeWatcherOp = 0;
      SetEvent(pss->hReadWatcherEvent);
    } else {
      pss->sockState = Unconnected;
      pss->sockError = err;
      SIGNAL(pss->connSema);
    }
  } else {
    pss->s = 0;
    pss->sockState = Unconnected;
    SIGNAL(pss->connSema);
  }
  /* Cleanup any accepted sockets */
  while(pss->accepted) {
    acceptedSocketStruct *temp = pss->accepted;
    struct linger l;
    pss->accepted = temp->next;
    l.l_onoff = 1;
    l.l_linger = 0;
    setsockopt(temp->s, SOL_SOCKET, SO_LINGER, (char*)&l, sizeof(l));
    closesocket(temp->s);
    temp->s = 0;
    GlobalFree(GlobalHandle(temp));
  }
  UNLOCKSOCKET(pss->mutex);
}

/*****************************************************************************
  sqSocketConnectionStatus: return public status flags of the socket
*****************************************************************************/
sqInt sqSocketConnectionStatus(SocketPtr s)
{
  int status;

  if (!SocketValid(s)) return -1;
  DBG(s, "sqSocketConnectionStatus");
  status = SOCKETSTATE(s) & 0xFFFF;
  return status;
}

/*****************************************************************************
  sqSocketConnectToPort:
	TCP => open a connection.
	UDP => set remote address.
*****************************************************************************/
void sqSocketConnectToPort(SocketPtr s, sqInt addr, sqInt port)
{
  int err;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;
  ZeroMemory(ADDRESS(s),sizeof(struct sockaddr_in));
  ADDRESS(s)->sin_family = AF_INET;
  ADDRESS(s)->sin_port = htons((short)port);
  ADDRESS(s)->sin_addr.s_addr = htonl(addr);

  if(TCPSocketType != s->socketType) { /* UDP/RAW */
    if(!pss->sockState & SOCK_BOUND_UDP) {
      /* The socket is locally unbound and we
	 must 'magically' assign a local port so
	 that client code can also read from the socket */
      sqSocketListenOnPort(s,0); /* Note: 0 is a wildcard */
    }
    return;
  }

  /* TCP */
  err = connect( SOCKET(s), (struct sockaddr*) ADDRESS(s), sizeof(struct sockaddr_in));
  if(err) {
    err = WSAGetLastError();
    if(err != WSAEWOULDBLOCK) {
      pss->sockState = Unconnected; /* reset */
      pss->sockError = err;
      SIGNAL(pss->connSema);
    } else {
      /* Connection in progress => Start write watcher */
      LOCKSOCKET(pss->mutex, INFINITE);
      pss->sockState = WaitingForConnection;
      pss->writeWatcherOp = WatchConnect;
      SetEvent(pss->hWriteWatcherEvent);
      UNLOCKSOCKET(pss->mutex);
    }
  } else {
    /* Connection completed synchronously */
    LOCKSOCKET(pss->mutex, INFINITE);
    pss->sockState = Connected | SOCK_DATA_WRITABLE;
    pss->readWatcherOp = WatchData; /* waiting for data */
    SetEvent(pss->hReadWatcherEvent);
    SIGNAL(pss->connSema);
    SIGNAL(pss->writeSema);
    UNLOCKSOCKET(pss->mutex);
  }
}

/*****************************************************************************
  sqSocketListenOnPort:
	TCP => start listening for incoming connections.
	UDP => associate the local port number with the socket.
*****************************************************************************/
void sqSocketListenOnPort(SocketPtr s, sqInt port)
{
  int result;
  struct sockaddr_in addr;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;
  /* bind the socket */
  ZeroMemory(&addr,sizeof(struct sockaddr_in));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((short)port);
  addr.sin_addr.s_addr = INADDR_ANY;

  result = bind( SOCKET(s), (struct sockaddr*) &addr, sizeof(struct sockaddr_in));
  if(result == SOCKET_ERROR) {
    pss->sockError = WSAGetLastError();
    FAIL();
    return;
  }
  if(TCPSocketType != s->socketType) { /* UDP/RAW */
    SOCKETSTATE(s) = Connected | SOCK_BOUND_UDP | SOCK_DATA_WRITABLE;
  } else { /* TCP */
    /* show our willingness to accept a single incoming connection */
    result = listen(SOCKET(s), 1);
    if(result == SOCKET_ERROR) {
      FAIL();
    } else {
      /* Waiting for accept => Start read watcher */
      pss->sockState = WaitingForConnection;
      pss->readWatcherOp = WatchAcceptSingle;
      SetEvent(pss->hReadWatcherEvent);
    }
  }
}

/*****************************************************************************
  sqSocketBindToPort: allow binding a socket to a specific port and address
*****************************************************************************/
void sqSocketBindToPort(SocketPtr s, int addr, int port)
{
  int result;
  struct sockaddr_in inaddr;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;

  /* bind the socket */
  ZeroMemory(&inaddr,sizeof(struct sockaddr_in));
  inaddr.sin_family = AF_INET;
  inaddr.sin_port = htons((short)port);
  inaddr.sin_addr.s_addr = htonl(addr);

  result = bind( SOCKET(s), (struct sockaddr*) &inaddr, sizeof(struct sockaddr_in));
  if(result == SOCKET_ERROR) {
    pss->sockError = WSAGetLastError();
    FAIL();
    return;
  }
}


/*****************************************************************************
  sqSocketListenOnPortBacklogSize:
	TCP => start listening for incoming connections.
	UDP => Just call sqListenOnPort
*****************************************************************************/
void sqSocketListenOnPortBacklogSize(SocketPtr s, sqInt port, sqInt backlogSize) {
  sqSocketListenOnPortBacklogSizeInterface(s, port, backlogSize, 0);
}


void sqSocketListenOnPortBacklogSizeInterface(SocketPtr s, sqInt port, sqInt backlogSize, sqInt addr)
{
  int result;
  struct sockaddr_in inaddr;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;

  if(TCPSocketType != s->socketType) { /* UDP/RAW */
    sqSocketListenOnPort(s, port);
    return;
  }

  /* bind the socket */
  ZeroMemory(&inaddr,sizeof(struct sockaddr_in));
  inaddr.sin_family = AF_INET;
  inaddr.sin_port = htons((short)port);
  inaddr.sin_addr.s_addr = htonl(addr);

  result = bind( SOCKET(s), (struct sockaddr*) &inaddr, sizeof(struct sockaddr_in));
  if(result == SOCKET_ERROR) {
    pss->sockError = WSAGetLastError();
    FAIL();
    return;
  }
  /* show our willingness to accept a backlogSize incoming connections */
  result = listen(SOCKET(s), backlogSize);
  if(result != SOCKET_ERROR) {
    LOCKSOCKET(pss->mutex, INFINITE);
    /* Waiting for accept => Start read watcher */
    pss->sockState = WaitingForConnection;
    pss->readWatcherOp = WatchAccept;
    SetEvent(pss->hReadWatcherEvent);
    UNLOCKSOCKET(pss->mutex);
  } else {
    pss->sockError = WSAGetLastError();
    FAIL();
  }
}

/*****************************************************************************
  sqSocketDestroy: Release the resources associated with this socket.
                   If a connection is open, it is aborted
*****************************************************************************/
void sqSocketDestroy(SocketPtr s)
{
  privateSocketStruct *pss;

  if (!SocketValid(s)) return;

  pss = s->privateSocketPtr;

  /* close the socket if it is open */
  if(pss->s) {
    sqSocketAbortConnection(s);
  }

  removeFromList(pss);
  s->privateSocketPtr = NULL;

  /* Prepare cleanup from threads */
  LOCKSOCKET(pss->mutex, INFINITE);
  pss->closePending = 2; /* threads are running */
  pss->readWatcherOp = 0;
  pss->writeWatcherOp = 0;
  SetEvent(pss->hReadWatcherEvent);
  SetEvent(pss->hWriteWatcherEvent);
  UNLOCKSOCKET(pss->mutex);
  /* Note: it is important that we guard the SetEvent() above
     since the threads are running at higher priority and may
     immediately try to clean up once SetEvent() is called.
     Locking the socket prevents them until we are finished */
}

/*****************************************************************************
  sqSocketReceiveDataAvailable: Return non-zero if data available
*****************************************************************************/
sqInt sqSocketReceiveDataAvailable(SocketPtr s)
{
  int sockState;

  if(!SocketValid(s)) return 0;
  DBG(s,"sqSocketReceiveDataAvailable");
  sockState = SOCKETSTATE(s);
  return (sockState & SOCK_DATA_READABLE) /* e.g., do we have data? */
    && ((sockState & SOCK_PUBLIC_MASK) == Connected); /* and are we still connected? */
}

/*****************************************************************************
  sqSocketReceiveDataBufCount:
  Receive data into the given buffer. Do not exceed bufSize.
  Return the number of bytes actually read.
*****************************************************************************/
sqInt sqSocketReceiveDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  privateSocketStruct *pss = PSP(s);
  int result;
  int addrSize;

  if (!SocketValid(s)) return -1;
  if(bufSize <= 0) return bufSize;

  /* read incoming data */
  if(TCPSocketType != pss->sockType) { /* UDP/RAW */
    addrSize = sizeof(pss->peer);
    result = recvfrom(pss->s, buf, bufSize, 0,
		      (struct sockaddr*) &pss->peer, &addrSize);
  } else { /* TCP */
    result = recv(pss->s,buf, bufSize, 0);
  }

/* printf("Data read (%d) WSAGetLastError (%d)\n", result, WSAGetLastError()); */

  /* Guard eventual writes to socket state */
  LOCKSOCKET(pss->mutex, INFINITE)

  /* Check if something went wrong */
  if(result <= 0) {
      if(result == 0) {
	/* UDP/RAW doesn't know "other end closed" state */
	if(pss->sockType == TCPSocketType)
	  pss->sockState = OtherEndClosed;
      } else if(result < 0) {
	int err = WSAGetLastError();
	if(err != WSAEWOULDBLOCK) {
	  /* printf("ERROR: %d\n", err); */
	  /* NOTE: We consider all other errors to be fatal, e.g.,
	     report them as "other end closed". Looking at the
	     WSock documentation this ought to be correct. */
	  /* UDP/RAW doesn't know "other end closed" state */
	  if(pss->sockType == TCPSocketType) {
	    pss->sockState = OtherEndClosed;
	    SIGNAL(pss->connSema);
	  }
	  pss->sockError = err;
	}
	result = 0;
      }
  }

  if(!socketReadable(pss->s)) {
    /* no more data to read; wake up read watcher */
    pss->sockState &= ~SOCK_DATA_READABLE;
    pss->readWatcherOp = WatchData;
    SetEvent(pss->hReadWatcherEvent);
  }

  UNLOCKSOCKET(pss->mutex);
  return result;
}

/*****************************************************************************
  sqSocketSendDone: Return non-zero if all data has been sent.
*****************************************************************************/
sqInt sqSocketSendDone(SocketPtr s)
{
  int sockState;

  if (!SocketValid(s)) return 1;
  DBG(s, "sqSocketSendDone");
  sockState = SOCKETSTATE(s);
  return (sockState & SOCK_DATA_WRITABLE) /* e.g., everything has been written */
    && ((sockState & SOCK_PUBLIC_MASK) == Connected); /* and we are still connected */
}

/*****************************************************************************
  sqSocketSendDataBufCount:
  Send bufSize bytes from the data pointed to by buf.
  Return the number of bytes sent.
*****************************************************************************/
sqInt sqSocketSendDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  privateSocketStruct *pss = PSP(s);
  int result;
  int addrSize;

  if (!SocketValid(s)) return -1;
  /***NOTE***NOTE***NOTE***NOTE***NOTE***
      It's not clear if we should just bail out here
      if the buffer size is zero. It's consistent with
      what the Unix VM does but I think we should actually
      fail here....
  **************************************/
  if(!bufSize) return 0;

  /* send actual data */
  if(TCPSocketType != pss->sockType) { /* UDP/RAW */
    addrSize = sizeof(pss->peer);
    result = sendto(pss->s, buf, bufSize, 0,
		    (struct sockaddr*) &pss->peer, addrSize);
  } else {
    result = send(pss->s, buf, bufSize, 0);
  }
/* printf("Data sent (%d) WSAGetLastError (%d)\n", result, WSAGetLastError()); */

  /* Guard eventual writes to socket state */
  LOCKSOCKET(pss->mutex, INFINITE)

  /* Check if something went wrong */
  if(result <= 0) {
      if(result == 0) {
	/* UDP/RAW doesn't know "other end closed" state */
	if(pss->sockType == TCPSocketType)
	  pss->sockState = OtherEndClosed;
      } else {
	int err = WSAGetLastError();
	if(err != WSAEWOULDBLOCK) {
	  /* printf("ERROR: %d\n", err); */
	  /* NOTE: We consider all other errors to be fatal, e.g.,
	     report them as "other end closed". Looking at the
	     WSock documentation this ought to be correct. */
	  /* UDP/RAW doesn't know "other end closed" state */
	  if(pss->sockType == TCPSocketType) {
	    pss->sockState = OtherEndClosed;
	    SIGNAL(pss->connSema);
	  }
	  pss->sockError = err;
	}
	result = 0;
      }
  }

  if(!socketWritable(pss->s)) {
    /* can't write more data; wake up write watcher */
    pss->sockState &= ~SOCK_DATA_WRITABLE;
    pss->writeWatcherOp = WatchData;
    SetEvent(pss->hWriteWatcherEvent);
  }

  UNLOCKSOCKET(pss->mutex);
  return result;
}

/*****************************************************************************
  sqSocketError: Return any error on the socket.
*****************************************************************************/
sqInt sqSocketError(SocketPtr s)
{
  if(!SocketValid(s)) return -1;
  return SOCKETERROR(s);
}

/*****************************************************************************
  sqSocketLocalAddress: Return the address of the socket on this host.
*****************************************************************************/
sqInt sqSocketLocalAddress(SocketPtr s)
{
  struct sockaddr_in sin;
  int sinSize = sizeof(sin);

  if (!SocketValid(s)) return -1;
  if(getsockname(SOCKET(s), (struct sockaddr *)&sin, &sinSize)) return 0; /* failed */
  if(sin.sin_family != AF_INET) return 0; /* can't handle other than internet addresses */
  return ntohl(sin.sin_addr.s_addr);
}

/*****************************************************************************
  sqSocketLocalPort: Return the port of the socket on this host
*****************************************************************************/
sqInt sqSocketLocalPort(SocketPtr s)
{
  struct sockaddr_in sin;
  int sinSize = sizeof(sin);

  if (!SocketValid(s)) return -1;
  if(getsockname(SOCKET(s), (struct sockaddr *)&sin, &sinSize)) return 0; /* failed */
  if(sin.sin_family != AF_INET) return 0; /* can't handle other than internet addresses */
  return ntohs(sin.sin_port);
}

/*****************************************************************************
  sqSocketRemoteAddress: Return the address of the socket on the remote host
*****************************************************************************/
sqInt sqSocketRemoteAddress(SocketPtr s)
{
  struct sockaddr_in sin;
  int sinSize = sizeof(sin);

  if (!SocketValid(s)) return -1;
  if(TCPSocketType == s->socketType) { /* TCP */
    if(getpeername(SOCKET(s), (struct sockaddr *)&sin, &sinSize)) return 0; /* failed */
  } else { /* UDP/RAW */
    MoveMemory(&sin,&(PSP(s)->peer),sinSize);
  }
  if(sin.sin_family != AF_INET) return 0; /* can't handle other than internet addresses */
  return ntohl(sin.sin_addr.s_addr);
}

/*****************************************************************************
  sqSocketRemotePort: Return the port of the socket on the remote host
*****************************************************************************/
sqInt sqSocketRemotePort(SocketPtr s)
{
  struct sockaddr_in sin;
  int sinSize = sizeof(sin);

  if (!SocketValid(s)) return -1;
  if(TCPSocketType == s->socketType) { /* TCP */
    if(getpeername(SOCKET(s), (struct sockaddr *)&sin, &sinSize)) return 0; /* failed */
  } else { /* UDP */
    MoveMemory(&sin,&(PSP(s)->peer),sinSize);
  }
  if(sin.sin_family != AF_INET) return 0; /* can't handle other than internet addresses */
  return ntohs(sin.sin_port);
}


/*****************************************************************************
  sqSocketSetReusable: set the SO_REUSEADDR option for the socket.
*****************************************************************************/
void sqSocketSetReusable (SocketPtr s)
{
  size_t bufSize;
  unsigned char   buf[4];
  int err;

  if (!SocketValid(s)) return;
  *(int *)buf = 1;
  bufSize = 4;
  err = setsockopt(SOCKET(s), SOL_SOCKET, SO_REUSEADDR, buf, bufSize);
  if(err < 0) interpreterProxy->success(false);
}

/*****************************************************************************
 *****                     New Socket Functions                          *****
 *****************************************************************************/
/*****************************************************************************
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID:
  Create a socket for the given netType (which is always internet here)
  a given socketType (UDP or TCP) appropriate buffer size (being ignored ;-)
  and a semaphore to signal upon changes in the socket state.
*****************************************************************************/
void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
            SocketPtr s, sqInt netType, sqInt socketType,
            sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex)
{
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, netType, socketType, recvBufSize, sendBufSize, semaIndex, semaIndex, semaIndex);
}

void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt netType, sqInt socketType, sqInt recvBufSize, sqInt sendBufSize, sqInt connSemaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{

  SOCKET newSocket;
  privateSocketStruct *pss;
  int domain;

  switch (netType) {
    case 0: domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_UNSPECIFIED */
    case 2:	domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_INET4 */
    case 3:	domain= AF_INET6;	break;	/* SQ_SOCKET_DOMAIN_INET6 */
	default:
		FAIL();
		return;
  }

  s->sessionID = 0;
  /* perform internal initialization */
  if(socketType == TCPSocketType)
    newSocket = socket(domain,SOCK_STREAM, 0);
  else if(socketType == UDPSocketType)
    newSocket = socket(domain, SOCK_DGRAM, 0);
  else { FAIL(); return; }
  if(newSocket == INVALID_SOCKET) {
    FAIL();
    return;
  }
  /* Allow the re-use of the current port */
  setsockopt(newSocket, SOL_SOCKET, SO_REUSEADDR, (char*) &one, sizeof(one));
  /* Make the socket non-blocking */
  ioctlsocket(newSocket,FIONBIO,&one);

   /* XXXX: Work around a Windows Vista bug. Vista's TCP stack tries
     to auto-tune the TCP window size and fails miserably with some
     equipment in the middle. The effect is that after a little while
     the network connection will simply stall and not receive any
     more data. We work around this by specifying the window size
     explicitly (only for Vista; one would hope that later versions
     of windows get this done without failing. */
  if(runningVista && socketType == TCPSocketType) {
    unsigned int val = 65536;
    setsockopt(newSocket, SOL_SOCKET, SO_RCVBUF, (char *)&val, sizeof(val));
  }

  /* initialize private socket structure */
  pss = (privateSocketStruct*) calloc(1,sizeof(privateSocketStruct));
  pss->s = newSocket;
  pss->sockType = socketType;
  pss->connSema = connSemaIndex;
  pss->readSema = readSemaIndex;
  pss->writeSema = writeSemaIndex;

  /* UDP sockets are born "connected" */
  if(UDPSocketType == socketType) {
    pss->sockState = Connected | SOCK_DATA_WRITABLE;
  } else {/* TCP */
    pss->sockState = Unconnected;
  }
  pss->sockError= 0;

  /* initial UDP peer := wildcard */
  ZeroMemory(&pss->peer, sizeof(pss->peer));
  pss->peer.sin.sin_family= AF_INET;
  pss->peer.sin.sin_port= htons((short)0);;
  pss->peer.sin.sin_addr.s_addr= INADDR_ANY;

  /* fill the SQSocket */
  s->sessionID = thisNetSession;
  s->socketType = socketType;
  s->privateSocketPtr = pss;

  /* Create a new mutex object for synchronized access */
  pss->mutex = CreateMutex(NULL, 0,NULL);
  if(!pss->mutex) { FAIL(); return; }

  /* Install the socket into the socket list */
  pss->next = firstSocket;
  firstSocket = pss;

  /* Setup the watchers */
  if(UDPSocketType == socketType) {
    /* Since UDP sockets are always connected */
    pss->readWatcherOp = pss->writeWatcherOp = WatchData;
  }
  if(!createWatcherThreads(pss)) {
    /* note: necessary cleanup is done from within createWatcherThreads */
    s->privateSocketPtr = NULL; /* declare invalid */
    FAIL();
  }
}

/*************************************************************************/

void sqSocketCreateRawProtoTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt netType, sqInt protoType, sqInt recvBufSize, sqInt sendBufSize, sqInt connSemaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{

  SOCKET newSocket;
  privateSocketStruct *pss;
  int domain;

  switch (netType) {
    case 0: domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_UNSPECIFIED */
    case 2:	domain= AF_INET;	break;	/* SQ_SOCKET_DOMAIN_INET4 */
    case 3:	domain= AF_INET6;	break;	/* SQ_SOCKET_DOMAIN_INET6 */
	default:
		FAIL();
		return;
  }

  s->sessionID = 0;
  /* perform internal initialization */
  switch(protoType) {
    case 1: newSocket = socket(domain, SOCK_RAW, IPPROTO_ICMP); break;
    default: newSocket = INVALID_SOCKET;
  }
  if(newSocket == INVALID_SOCKET) {
    FAIL();
    return;
  }

  /* Make the socket non-blocking */
  ioctlsocket(newSocket,FIONBIO,&one);

  /* initialize private socket structure */
  pss = (privateSocketStruct*) calloc(1,sizeof(privateSocketStruct));
  pss->s = newSocket;
  pss->sockType = RAWSocketType;
  pss->connSema = connSemaIndex;
  pss->readSema = readSemaIndex;
  pss->writeSema = writeSemaIndex;

  /* Raw sockets are born "connected" */
  pss->sockState = Connected | SOCK_DATA_WRITABLE;
  pss->sockError= 0;

  /* initial peer := wildcard */
  ZeroMemory(&pss->peer, sizeof(pss->peer));
  pss->peer.sin.sin_family= AF_INET;
  pss->peer.sin.sin_port= htons((short)0);;
  pss->peer.sin.sin_addr.s_addr= INADDR_ANY;

  /* fill the SQSocket */
  s->sessionID = thisNetSession;
  s->socketType = RAWSocketType;
  s->privateSocketPtr = pss;

  /* Create a new mutex object for synchronized access */
  pss->mutex = CreateMutex(NULL, 0,NULL);
  if(!pss->mutex) { FAIL(); return; }

  /* Install the socket into the socket list */
  pss->next = firstSocket;
  firstSocket = pss;

  /* Setup the watchers */
  pss->readWatcherOp = pss->writeWatcherOp = WatchData;
  if(!createWatcherThreads(pss)) {
    /* note: necessary cleanup is done from within createWatcherThreads */
    s->privateSocketPtr = NULL; /* declare invalid */
    FAIL();
  }
}

/*****************************************************************************
  sqSocketAcceptFromRecvBytesSendBytesSemaID:
  Create a new socket by accepting an incoming connection from the source socket.
*****************************************************************************/

void sqSocketAcceptFromRecvBytesSendBytesSemaID(
            SocketPtr s, SocketPtr serverSocket,
            sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex)
{
  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, serverSocket, recvBufSize, sendBufSize, semaIndex, semaIndex, semaIndex);
}

void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt connSemaIndex, sqInt readSemaIndex, sqInt writeSemaIndex)
{
  acceptedSocketStruct *accepted;
  privateSocketStruct *pss;

  /* Lock the server socket and retrieve the last accepted connection */
  pss = PSP(serverSocket); /* temporarily */

  /* Guard modification in server socket state */
  LOCKSOCKET(pss->mutex, INFINITE);
  accepted = pss->accepted;
  if(accepted) {
    pss->accepted = accepted->next;
    if(!pss->accepted) {
      /* No more connections; go back to waiting state and start watcher */
      pss->sockState = WaitingForConnection;
      pss->readWatcherOp = WatchAccept;
      SetEvent(pss->hReadWatcherEvent);
    }
  }
  UNLOCKSOCKET(pss->mutex);

  if(!accepted) { /* something was wrong here */
    FAIL();
    return;
  }
  if(accepted->s == INVALID_SOCKET) {
    FAIL();
    return;
  }
  /* private socket structure */
  pss = (privateSocketStruct*) calloc(1,sizeof(privateSocketStruct));
  pss->s = accepted->s;
  pss->sockType = PSP(serverSocket)->sockType;
  pss->connSema = connSemaIndex;
  pss->readSema = readSemaIndex;
  pss->writeSema = writeSemaIndex;
  pss->sockState= Connected | SOCK_DATA_WRITABLE;
  pss->sockError= 0;
  MoveMemory(&pss->peer, &accepted->peer, sizeof(struct sockaddr_in));

  /* fill the SQSocket */
  s->sessionID = thisNetSession;
  s->socketType = pss->sockType;
  s->privateSocketPtr = pss;

  /* Make the socket non-blocking */
  ioctlsocket(SOCKET(s),FIONBIO,&one);

  /* Create a new mutex object for synchronized access */
  pss->mutex = CreateMutex(NULL, 0,NULL);
  if(!pss->mutex) { FAIL(); return; }

  /* Install the socket into the socket list */
  pss->next = firstSocket;
  firstSocket = pss;

  /* Setup the watchers */
  pss->readWatcherOp = pss->writeWatcherOp = WatchData;

  if(!createWatcherThreads(pss)) {
    /* note: necessary cleanup is done from within createWatcherThreads */
    s->privateSocketPtr = NULL; /* declare invalid */
    FAIL();
  }

  /* Cleanup */
  GlobalFree(GlobalHandle(accepted));
}

sqInt sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, char *buf, sqInt bufSize,  sqInt *address,  sqInt *port, sqInt *moreFlag)
{
  int nRead;
  if(TCPSocketType == s->socketType)
    return interpreterProxy->primitiveFail();
  /* bind UDP/RAW socket*/
  sqSocketConnectToPort(s, *address, *port);
  if(interpreterProxy->failed()) return 0;
  /* receive data */
  nRead = sqSocketReceiveDataBufCount(s, buf, bufSize);
  if(nRead >= 0) {
    *address= ntohl(ADDRESS(s)->sin_addr.s_addr);
    *port= ntohs(ADDRESS(s)->sin_port);
  }
  return nRead;
}

sqInt	sqSockettoHostportSendDataBufCount(SocketPtr s, sqInt address, sqInt port, char *buf, sqInt bufSize)
{
  if(TCPSocketType == s->socketType)
    return interpreterProxy->primitiveFail();
  /* bind UDP/RAW socket */
  sqSocketConnectToPort(s, address, port);
  if(interpreterProxy->failed()) return 0;
  /* send data */
  return sqSocketSendDataBufCount(s, buf, bufSize);
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
	 me mail (andreas.raab@gmx.de) to let me know about it.
*/

typedef struct {
  char *name;		/* name as known to Squeak */
  int   optLevel;	/* protocol level */
  int   optName;	/* name as known to the network layer */
  int   optType;        /* type of option */
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
  { "SO_DEBUG",			SOL_SOCKET,	SO_DEBUG,          1 },
  { "SO_REUSEADDR",		SOL_SOCKET,	SO_REUSEADDR,      1 },
  { "SO_DONTROUTE",		SOL_SOCKET,	SO_DONTROUTE,      1 },
  { "SO_BROADCAST",		SOL_SOCKET,	SO_BROADCAST,      1 },
  { "SO_SNDBUF",		SOL_SOCKET,	SO_SNDBUF,         1 },
  { "SO_RCVBUF",		SOL_SOCKET,	SO_RCVBUF,         1 },
  { "SO_KEEPALIVE",		SOL_SOCKET,	SO_KEEPALIVE,      1 },
  { "SO_OOBINLINE",		SOL_SOCKET,	SO_OOBINLINE,      1 },
  { "SO_LINGER",		SOL_SOCKET,	SO_LINGER,         1 },
  { "IP_MULTICAST_IF",		SOL_IP,		IP_MULTICAST_IF,   1 },
  { "IP_MULTICAST_TTL",		SOL_IP,		IP_MULTICAST_TTL,  1 },
  { "IP_MULTICAST_LOOP",	SOL_IP,		IP_MULTICAST_LOOP, 1 },
  { "TCP_NODELAY",		SOL_TCP,	TCP_NODELAY,       1 },
  { "SO_RCVLOWAT",		SOL_SOCKET,	SO_RCVLOWAT,       1 },
  { "SO_SNDLOWAT",		SOL_SOCKET,	SO_SNDLOWAT,       1 },

  /* multicast support */
  {"IP_ADD_MEMBERSHIP",         SOL_IP,         IP_ADD_MEMBERSHIP,  100},
  {"IP_DROP_MEMBERSHIP",        SOL_IP,         IP_DROP_MEMBERSHIP, 100},

#if 0
  /* WSAIoctl() support */
  {"SIO_GET_BROADCAST_ADDRESS",	0,	SIO_GET_BROADCAST_ADDRESS, 200},
#endif
  { (char *)0,			0,		0,                  0 }
};


static socketOption *findOption(char *name, size_t nameSize) {
  socketOption *opt= 0;
  char buf[128];
  if(nameSize > 127) return NULL;
  strncpy(buf, name, nameSize);
  buf[nameSize] = 0;
  for (opt= socketOptions; opt->name != 0; ++opt)
    if (!strcmp(buf, opt->name))
      return opt;
  return NULL;
}


/*
  set the given option for the socket.
*/
sqInt sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue
    (SocketPtr s,char *optionName, sqInt optionNameSize,
     char *optionValueIndex, sqInt optionValueSize, sqInt *result)
{
  char optionValue[256];
  size_t bufSize;
  unsigned char   buf[256];

  if (SocketValid(s)) {
    socketOption *opt= findOption(optionName, (size_t)optionNameSize);

    if (opt == 0) goto barf;
    if(optionValueSize >= sizeof(optionValue)) goto barf;

    memcpy(optionValue, optionValueIndex, optionValueSize);
    optionValue[optionValueSize] = 0;

    if(opt->optType == 1) {
      /* integer options */
      ((int*)buf)[0] = atoi(optionValue);
      bufSize = sizeof(int);
      /* printf("optionValue: %d (%s)\n", ((int*)buf)[0], optionValue); */
    } else if(opt->optType == 100) {
      /* multicast options, taking one or two IP addresses, e.g.,
         '1.2.3.4|5.6.7.8' specifies multicast group + interface
	 '1.2.3.4' specifies only multicast group (interface is INADDR_ANY)
      */
      if(optionValueSize == 4) {
	((int*)buf)[0] = ((int*)optionValue)[0];
	((int*)buf)[1] = INADDR_ANY;
      } else if(optionValueSize == 8) {
	((int*)buf)[0] = ((int*)optionValue)[0];
	((int*)buf)[1] = ((int*)optionValue)[1];
      } else {
	goto barf;
      }
      bufSize = 8;
    } else {
      goto barf;
    }
    {
      int err;
      err = setsockopt(SOCKET(s), opt->optLevel, opt->optName,buf, bufSize);
      /* printf("setsockopt(): %d\n", err); */
      if(err < 0) goto barf;
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
    *result= 0;
    return 0;
  }
 barf:
  interpreterProxy->success(false);
  return false;
}


/* query the socket for the given option.  */
sqInt sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue
    (SocketPtr s,char *optionName, sqInt optionNameSize, sqInt *result)
{
  int optval;
  size_t len;
  socketOption *opt;
  if (!SocketValid(s)) goto barf;
  opt= findOption(optionName, (size_t)optionNameSize);
  if (opt == 0) {
    /* printf("option not found\n"); */
    goto barf;
  }
  if (opt->optType == 1) {
    len= sizeof(optval);
    if ((getsockopt(SOCKET(s), opt->optLevel, opt->optName,
		    (char*)&optval,&len)) < 0)
      {
	/* printf("getsockopt() returned < 0\n"); */
	goto barf;
      }
    if (len != sizeof(optval)) {
      /* printf("len != sizeof(optval)"); */
      goto barf;
    }
    *result= optval;
    return 0;
  }

#if 0
  if(opt->optType == 200) {
    int sz, err;
    struct sockaddr_in addr;
    /* WSAIoctl() */
    if(opt->optName != SIO_GET_BROADCAST_ADDRESS) goto barf;
    err = WSAIoctl(SOCKET(s),
		   SIO_GET_BROADCAST_ADDRESS,
		   NULL, 0,
		   &addr, sizeof(addr),
		   &sz,
		   NULL, NULL);
    if(err) {
      printf("WSAIoctl error: %d (WSAGetLastError=%d)\n",
	     err, WSAGetLastError());
      goto barf;
    }
    if(sz != sizeof(addr)) {
      printf("WSAIoctl returned %d instead of %d\n", sz, sizeof(addr));
      goto barf;
    }
    *result = ntohl(addr.sin_addr.s_addr);
    return 0;
  }
#endif

 barf:
  interpreterProxy->success(false);
  return errno;
}

/*****************************************************************************
 *****                     Resolver Functions                            *****
 *****************************************************************************
 NOTE: Resolver functions don't need synchronization - there is only one
       resolver process running at a time.
 *****************************************************************************/

static char lastName[MAXHOSTNAMELEN+1];
static int lastAddr;

static int lastError;
static HANDLE asyncLookupHandle = 0;
static char hostentBuffer[MAXGETHOSTSTRUCT];

static DWORD WINAPI sqGetHostByAddr(int netAddress);
static DWORD WINAPI sqGetHostByName(char *hostName);

/*****************************************************************************
  Convenience functions. We may use them later.
*****************************************************************************/
static char *
nameOf(int netAddress)
{ u_long nAddr;
  struct hostent *he;

  lastError = 0;
  nAddr = htonl(netAddress);
  he = gethostbyaddr((char*)&nAddr,sizeof(nAddr),AF_INET);
  if(he) return he->h_name;
  lastError = h_errno;
  return "";
}

static int
addressOf(char *hostName)
{ struct hostent *he;

  lastError = 0;
  he = gethostbyname(hostName);
  if(he) return ntohl(*(long*)(he->h_addr_list[0]));
  lastError = h_errno;
  return 0;
}

/*****************************************************************************
  sqResolverAbort: Abort a pending DNS lookup
*****************************************************************************/
void sqResolverAbort(void)
{
  if(!asyncLookupHandle) return; /* lookup already finished */
  TerminateThread(asyncLookupHandle, 0);
  /* forget last name */
  lastName[0] = 0;
  /* indicate finished operation */
  CloseHandle(asyncLookupHandle);
  asyncLookupHandle = 0;
}

/*****************************************************************************
  sqResolverAddrLookupResult: Return the result of the last name lookup
*****************************************************************************/
void sqResolverAddrLookupResult(char *nameForAddress, sqInt nameSize)
{
  MoveMemory(nameForAddress, lastName, nameSize);
}

/*****************************************************************************
  sqResolverAddrLookupResult: Return sizeof(result) of the last name lookup
*****************************************************************************/
sqInt sqResolverAddrLookupResultSize(void)
{
  return strlen(lastName);
}

/*****************************************************************************
  sqResolverError: Return the last error of a DNS lookup
*****************************************************************************/
sqInt sqResolverError(void)
{
  return lastError;
}

/*****************************************************************************
  sqResolverLocalAddress: Return the address of the local host
*****************************************************************************/
sqInt sqResolverLocalAddress(void)
{
  return addressOf(localHostName);
}

/*****************************************************************************
  sqResolverNameLookupResult: Return the address of the last DNS lookup
*****************************************************************************/
sqInt sqResolverNameLookupResult(void)
{
  return lastAddr;
}

/*****************************************************************************
  sqResolverStartAddrLookup: Look up the name to a given address
*****************************************************************************/
void sqResolverStartAddrLookup(sqInt address)
{
  DWORD id;
  if(asyncLookupHandle) return; /* lookup in progress */
  asyncLookupHandle =
    CreateThread(NULL,                    /* No security descriptor */
                 128*1024,                /* max stack size     */
                 (LPTHREAD_START_ROUTINE) &sqGetHostByAddr, /* what to do */
                 (LPVOID) address,        /* parameter for thread   */
                 CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,
					/* creation parameter -- create suspended so we can check the return value */
                 &id);                    /* return value for thread id */
  if(!asyncLookupHandle)
    printLastError(TEXT("CreateThread() failed"));
  /* lookups run with normal priority */
  if(!SetThreadPriority(asyncLookupHandle, THREAD_PRIORITY_NORMAL))
    printLastError(TEXT("SetThreadPriority() failed"));
  if(!ResumeThread(asyncLookupHandle))
    printLastError(TEXT("ResumeThread() failed"));
}

/*****************************************************************************
  sqResolverStartNameLookup: Look up the address to a given host name
*****************************************************************************/
void sqResolverStartNameLookup(char *hostName, sqInt nameSize)
{ int len;
  DWORD id;

  if(asyncLookupHandle) return; /* lookup in progress */
  len = nameSize < MAXHOSTNAMELEN ? nameSize : MAXHOSTNAMELEN;
  if((lastError == 0) &&
     (strlen(lastName) == len) &&
     (strncmp(hostName, lastName, len) == 0)) {
	  /* same as last, no point in looking it up */
	  SIGNAL(resolverSemaphoreIndex);
	  return;
  }
  MoveMemory(lastName,hostName, len);
  lastName[len] = 0;
  lastError = 0;
  asyncLookupHandle =
    CreateThread(NULL,                    /* No security descriptor */
                 128*1024,                /* max stack size     */
                 (LPTHREAD_START_ROUTINE) &sqGetHostByName, /* what to do */
                 (LPVOID) lastName,       /* parameter for thread   */
                 CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,
					/* creation parameter -- create suspended so we can check the return value */
                 &id);                    /* return value for thread id */
  if(!asyncLookupHandle)
    printLastError(TEXT("CreateThread() failed"));
  /* lookups run with normal priority */
  if(!SetThreadPriority(asyncLookupHandle, THREAD_PRIORITY_NORMAL))
    printLastError(TEXT("SetThreadPriority() failed"));
  if(!ResumeThread(asyncLookupHandle))
    printLastError(TEXT("ResumeThread() failed"));
}

/*****************************************************************************
  sqResolverStatus: Return resolver status
*****************************************************************************/
sqInt sqResolverStatus(void)
{
  if(!thisNetSession)
    return RESOLVER_UNINITIALIZED; /* not initialized */

  if(asyncLookupHandle)
    return RESOLVER_BUSY; /* lookup in progress */

  if(lastError)
    return RESOLVER_ERROR; /* resolver idle but last request failed */

  return RESOLVER_SUCCESS; /* ready and idle */
}



/*****************************************************************************
 sqGetHostByAddr: Perform a threaded gethostbyaddr()
*****************************************************************************/
DWORD WINAPI sqGetHostByAddr(int netAddress)
{ struct hostent *he;
  u_long nAddr;

  nAddr = htonl(netAddress);
  he = gethostbyaddr((char*)&nAddr, 4, PF_INET);
  if(he)
    {
      strcpy(lastName,he->h_name);
      lastAddr = ntohl(*(long*)(he->h_addr_list[0]));
      lastError = 0;
    }
  else
    lastError = WSAGetLastError();
  CloseHandle(asyncLookupHandle);
  asyncLookupHandle = 0;
  SIGNAL(resolverSemaphoreIndex);
  ExitThread(0);
  return 1;
}


/*****************************************************************************
 sqGetHostByName: Perform a threaded gethostbyname()
*****************************************************************************/
DWORD WINAPI sqGetHostByName(char *hostName)
{ struct hostent *he;

  he = gethostbyname(hostName);
  if(he)
    {
      strcpy(lastName,he->h_name);
      lastAddr = ntohl(*(long*)(he->h_addr_list[0]));
      lastError = 0;
    }
  else
    lastError = WSAGetLastError();
  CloseHandle(asyncLookupHandle);
  asyncLookupHandle = 0;
  SIGNAL(resolverSemaphoreIndex);
  ExitThread(0);
  return 1;
}

/***** socket module initializers *****/
sqInt socketInit(void)
{
	thisNetSession = 0;
	return 1;
}

sqInt socketShutdown(void)
{
	sqNetworkShutdown();
	sqResolverAbort();
	return 1;
}


/* mir 2009-03-26: Generalised primitives for IPv6, &c. (based on the unix version) */

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
      || (family   == SQ_SOCKET_FAMILY_LOCAL)
      || (type     < 0) || (type     >= SQ_SOCKET_TYPE_MAX)
      || (protocol < 0) || (protocol >= SQ_SOCKET_PROTOCOL_MAX))
    goto fail;

  if (hostSize)
    memcpy(host, hostName, hostSize);
  host[hostSize]= '\0';

  if (servSize)
    memcpy(serv, servName, servSize);
  serv[servSize]= '\0';

  memset(&request, 0, sizeof(request));

  if (flags & SQ_SOCKET_NUMERIC)	request.ai_flags |= AI_NUMERICHOST;
  if (flags & SQ_SOCKET_PASSIVE)	request.ai_flags |= AI_PASSIVE;

  switch (family)
    {
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
      fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(gaiError));
      addrList= 0;	/* succeed with zero results for impossible constraints */
    }

  addrInfo= addrList;
  interpreterProxy->signalSemaphoreWithIndex(resolverSemaphoreIndex);
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

#define addressValid(A, S)	(thisNetSession && (thisNetSession == addressHeader(A)->sessionID) && (addressHeader(A)->size == (S) - AddressHeaderSize))
#define addressSize(A)		(addressHeader(A)->size)


sqInt sqResolverGetAddressInfoSize(void)
{
  if (!addrInfo)
    return -1;
  return AddressHeaderSize + addrInfo->ai_addrlen;
}


void sqResolverGetAddressInfoResultSize(char *addr, sqInt addrSize)
{
  if ((!addrInfo) || (addrSize < AddressHeaderSize + addrInfo->ai_addrlen))
    {
      interpreterProxy->success(false);
      return;
    }

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      addrInfo->ai_addrlen;
  memcpy(socketAddress(addr), addrInfo->ai_addr, addrInfo->ai_addrlen);
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
    case AF_INET:	return SQ_SOCKET_FAMILY_INET4;
    case AF_INET6:	return SQ_SOCKET_FAMILY_INET6;
    }

  return SQ_SOCKET_FAMILY_UNSPECIFIED;
}


sqInt sqResolverGetAddressInfoType(void)
{
  if (!addrInfo)
    FAIL();

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
  interpreterProxy->signalSemaphoreWithIndex(resolverSemaphoreIndex);
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

  if (!(SocketValid(s) && addressValid(addr, addrSize)))
    goto fail;

  if (bind(SOCKET(s), socketAddress(addr), addressSize(addr)) == 0)
    return;

  pss->sockError= errno;

 fail:
  interpreterProxy->success(false);
}


void sqSocketListenBacklog(SocketPtr s, sqInt backlogSize)
{
	int result;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;

  if(UDPSocketType == s->socketType) {
    SOCKETSTATE(s) = Connected | SOCK_BOUND_UDP | SOCK_DATA_WRITABLE;
    return;
  }

  if ((backlogSize > 1) && (s->socketType != TCPSocketType))
    FAIL();

	/* no need to bind the socket, has been done before calling this function */
	
  /* show our willingness to accept a backlogSize incoming connections */
  result = listen(SOCKET(s), backlogSize);
  if(result != SOCKET_ERROR) {
    LOCKSOCKET(pss->mutex, INFINITE);
    /* Waiting for accept => Start read watcher */
    pss->sockState = WaitingForConnection;
    pss->readWatcherOp = WatchAccept;
    SetEvent(pss->hReadWatcherEvent);
    UNLOCKSOCKET(pss->mutex);
  } else {
    pss->sockError = WSAGetLastError();
    FAIL();
  }
}


void sqSocketConnectToAddressSize(SocketPtr s, char *addr, sqInt addrSize)
{
  int err;
  privateSocketStruct *pss = PSP(s);

  /* TCP => open a connection.
   * UDP => set remote address.
   */
  if (!(SocketValid(s) && addressValid(addr, addrSize)))
      FAIL();

  if(UDPSocketType == s->socketType) { /* UDP */
    if(!pss->sockState & SOCK_BOUND_UDP) {
      /* The socket is locally unbound and we
	 must 'magically' assign a local port so
	 that client code can also read from the socket */
      sqSocketListenOnPort(s,0); /* Note: 0 is a wildcard */
    }
    return;
	}

  /* TCP */
  err = connect( SOCKET(s), socketAddress(addr), addressSize(addr));
  if(err) {
    err = WSAGetLastError();
    if(err != WSAEWOULDBLOCK) {
      pss->sockState = Unconnected; /* reset */
      pss->sockError = err;
      SIGNAL(pss->connSema);
    } else {
      /* Connection in progress => Start write watcher */
      LOCKSOCKET(pss->mutex, INFINITE);
      pss->sockState = WaitingForConnection;
      pss->writeWatcherOp = WatchConnect;
      SetEvent(pss->hWriteWatcherEvent);
      UNLOCKSOCKET(pss->mutex);
    }
  } else {
    /* Connection completed synchronously */
    LOCKSOCKET(pss->mutex, INFINITE);
    pss->sockState = Connected | SOCK_DATA_WRITABLE;
    pss->readWatcherOp = WatchData; /* waiting for data */
    SetEvent(pss->hReadWatcherEvent);
    SIGNAL(pss->connSema);
    SIGNAL(pss->writeSema);
    UNLOCKSOCKET(pss->mutex);
  }
}


sqInt sqSocketLocalAddressSize(SocketPtr s)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!SocketValid(s))
    return -1;

  if (getsockname(SOCKET(s), &saddr.sa, &saddrSize))
    return 0;

  return AddressHeaderSize + saddrSize;
}


void sqSocketLocalAddressResultSize(SocketPtr s, char *addr, int addrSize)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!SocketValid(s))
		FAIL();

  if (getsockname(SOCKET(s), &saddr.sa, &saddrSize))
		FAIL();

  if (addrSize != AddressHeaderSize + saddrSize)
		FAIL();

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      saddrSize;
  memcpy(socketAddress(addr), &saddr.sa, saddrSize);
  return;

}


sqInt sqSocketRemoteAddressSize(SocketPtr s)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!SocketValid(s))
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
  else if (SOCKETPEERSIZE(s))			/* --- UDP --- */
    {
      return AddressHeaderSize + SOCKETPEERSIZE(s);
    }

  return -1;
}


void sqSocketRemoteAddressResultSize(SocketPtr s, char *addr, int addrSize)
{
  union sockaddr_any saddr;
  socklen_t saddrSize= sizeof(saddr);

  if (!SocketValid(s))
		FAIL();

  if ((!SOCKETPEERSIZE(s)) || (addrSize != AddressHeaderSize + SOCKETPEERSIZE(s)))
		FAIL();

  addressHeader(addr)->sessionID= thisNetSession;
  addressHeader(addr)->size=      SOCKETPEERSIZE(s);
  memcpy(socketAddress(addr), &SOCKETPEER(s), SOCKETPEERSIZE(s));
  SOCKETPEERSIZE(s)= 0;
  return;

}


/* ---- communication ---- */


sqInt sqSocketSendUDPToSizeDataBufCount(SocketPtr s, char *addr, sqInt addrSize, char *buf, sqInt bufSize)
{
  if(UDPSocketType != s->socketType)
    return interpreterProxy->primitiveFail();

  /* send data */
  return sqSocketSendDataBufCount(s, buf, bufSize);
}


sqInt sqSocketReceiveUDPDataBufCount(SocketPtr s, char *buf, sqInt bufSize)
{
  if (SocketValid(s) && (UDPSocketType == s->socketType))
  {
      socklen_t saddrSize= sizeof(SOCKETPEER(s));
      int nread= recvfrom(SOCKET(s), buf, bufSize, 0, &SOCKETPEER(s).sa, &saddrSize);
      if (nread >= 0)
      {
          SOCKETPEERSIZE(s)= saddrSize;
          return nread;
      }
  }
  return 0;
}

#endif /* NO_NETWORK */
