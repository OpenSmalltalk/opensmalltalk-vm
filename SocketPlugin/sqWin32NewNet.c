/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Net.c
*   CONTENT: Networking in Squeak
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32NewNet.c,v 1.1 2001/10/24 23:14:25 rowledge Exp $
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
#include <windows.h>
#include <winsock.h>
#include "sq.h"
#include "SocketPlugin.h"

#ifndef NO_NETWORK

#ifndef NO_RCSID
  static char RCSID[]="$Id: sqWin32NewNet.c,v 1.1 2001/10/24 23:14:25 rowledge Exp $";
#endif

#ifndef NDEBUG
#define DBG(s) debugCheckWatcherThreads(PSP(s))
#else
#define DBG(s)
#endif

/*** Socket Type Constants ***/
#define TCPSocketType 0
#define UDPSocketType 1

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

/* Socket structure private to primitive implementation */
typedef struct privateSocketStruct {
  struct privateSocketStruct *next;
  SOCKET s;

  int sockType;
  int sockState;
  int sockError;
  int semaphoreIndex;
  struct sockaddr_in peer;  /* socket address in connect() or send/rcv address for UDP */

  HANDLE mutex;             /* The mutex used for synchronized access to this socket */
  acceptedSocketStruct *accepted; /* Accepted connections on a socket */


  DWORD  readWatcherOp;      /* read operation to watch */
  HANDLE hReadWatcherEvent;  /* event for waking up read watcher */

  DWORD  writeWatcherOp;     /* write operation to watch */
  HANDLE hWriteWatcherEvent; /* event for waking up write watcher */

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

  /* Cleanup any accepted sockets */
  while(pss->accepted) {
    acceptedSocketStruct *temp = pss->accepted;
    struct linger l;
    pss->accepted = temp->next;
    l.l_onoff = 1;
    l.l_linger = 0;
    setsockopt(temp->s, SOL_SOCKET, SO_LINGER, (char*)&l, sizeof(l));
    closesocket(temp->s);
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
    /* Disable TCP delays */
    setsockopt(newSocket, IPPROTO_TCP, TCP_NODELAY, (char*) &one, sizeof(one));
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
  printf("### Socket [%x]\n", pss);
  printf("\tHandle: %x\n", pss->s);
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
  printf("\tSema: %d\n", pss->semaphoreIndex);
  { /* count pending accept()s */
    acceptedSocketStruct *tmp = pss->accepted;
    int n = 0;
    while(tmp) {
      tmp = tmp->next;
      n++;
    }
    printf("\tPending accepts: %d\n",n);
  }
  printf("\tRead Watcher Op: %d\n", pss->readWatcherOp);
  printf("\tWrite Watcher Op: %d\n",pss->writeWatcherOp);
  printf("\tClose pending: %d\n",pss->closePending);
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
}

static void debugCheckWatcherThreads(privateSocketStruct *pss) {
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
    printf("#### WARNING: Watcher threads are running wild on socket\n");
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
	  /* Data is available */
	  pss->sockState |= SOCK_DATA_READABLE;
	  doWait = 1; /* until data has been read */
	  break;
	case WatchClose:
	  /* Pending close has succeeded */
	  pss->sockState = ThisEndClosed;
	  pss->readWatcherOp = 0; /* since a close succeeded */
	  doWait = 1;
	  break;
	case WatchAcceptSingle:
	  /* Accept a single connection inplace */
	  inplaceAcceptHandler(pss);
	  pss->readWatcherOp = WatchData; /* check for incoming data */
	  pss->writeWatcherOp = WatchData; /* and signal when writable */
	  doWait = 0;
	  break;
	case WatchAccept:
	  /* Connection can be accepted */
	  acceptHandler(pss);
	  doWait = 0; /* only wait for more connections */
	  break;
	}
	
	UNLOCKSOCKET(pss->mutex);
	/* Socket state changed so signal */
	signalSemaphoreWithIndex(pss->semaphoreIndex);
      } else {
	if(n != SOCKET_ERROR) {
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
	  } else {
	    /* get socket error */
	    errSize = sizeof(pss->sockError);
	    getsockopt(pss->s, SOL_SOCKET, SO_ERROR, (char*)&pss->sockError, &errSize);
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
	    /* And fall through since data can be sent */
	    pss->writeWatcherOp = WatchData;
	  case WatchData:
	    /* Data can be sent */
	    pss->sockState |= SOCK_DATA_WRITABLE;
	    doWait = 1; /* until data has been written */
	    break;
	  }
	}
	UNLOCKSOCKET(pss->mutex);
	/* Socket state changed so signal */
	signalSemaphoreWithIndex(pss->semaphoreIndex);
      } else {
	if(n != SOCKET_ERROR) {
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
		 pageSize,                 /* default stack size     */
		 (LPTHREAD_START_ROUTINE) readWatcherThread, /* what to do */
		 (LPVOID) pss,      /* parameter for thread   */
		 CREATE_SUSPENDED,  /* creation parameter -- create suspended so we can check the return value */
		 &id);              /* return value for thread id */
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
		 pageSize,                 /* default stack size     */
		 (LPTHREAD_START_ROUTINE) writeWatcherThread,/* what to do */
		 (LPVOID) pss,      /* parameter for thread   */
		 CREATE_SUSPENDED,  /* creation parameter -- create suspended so we can check the return value */
		 &id);              /* return value for thread id */
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
int sqNetworkInit(int resolverSemaIndex)
{
  int err;


  if (thisNetSession != 0) return 0;  /* noop if network is already initialized */

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
  resolverSemaphoreIndex = resolverSemaIndex;

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
    success(false);
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
      pss->sockError = err;
    }
  } else {
    pss->sockState = Unconnected;
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
    GlobalFree(GlobalHandle(temp));
  }
  UNLOCKSOCKET(pss->mutex);
}

/*****************************************************************************
  sqSocketConnectionStatus: return public status flags of the socket
*****************************************************************************/
int sqSocketConnectionStatus(SocketPtr s)
{
  int status;

  if (!SocketValid(s)) return -1;
  DBG(s);
  status = SOCKETSTATE(s) & 0xFFFF;
  return status;
}

/*****************************************************************************
  sqSocketConnectToPort:
	TCP => open a connection.
	UDP => set remote address.
*****************************************************************************/
void sqSocketConnectToPort(SocketPtr s, int addr, int port)
{
  int err;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;
  ZeroMemory(ADDRESS(s),sizeof(struct sockaddr_in));
  ADDRESS(s)->sin_family = AF_INET;
  ADDRESS(s)->sin_port = htons((short)port);
  ADDRESS(s)->sin_addr.s_addr = htonl(addr);

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
  err = connect( SOCKET(s), (struct sockaddr*) ADDRESS(s), sizeof(struct sockaddr_in));
  if(err) {
    err = WSAGetLastError();
    if(err != WSAEWOULDBLOCK) {
      success(false);
      return;
    }
    /* Connection in progress => Start write watcher */
    LOCKSOCKET(pss->mutex, INFINITE);
    pss->sockState = WaitingForConnection;
    pss->writeWatcherOp = WatchConnect;
    SetEvent(pss->hWriteWatcherEvent);
    UNLOCKSOCKET(pss->mutex);
  } else {
    /* Connection completed synchronously */
    LOCKSOCKET(pss->mutex, INFINITE);
    pss->sockState = Connected | SOCK_DATA_WRITABLE;
    pss->readWatcherOp = WatchData; /* waiting for data */
    SetEvent(pss->hReadWatcherEvent);
    UNLOCKSOCKET(pss->mutex);
  }
}

/*****************************************************************************
  sqSocketListenOnPort: 
	TCP => start listening for incoming connections.
	UDP => associate the local port number with the socket.
*****************************************************************************/
void sqSocketListenOnPort(SocketPtr s, int port)
{
  struct sockaddr_in addr;
  privateSocketStruct *pss = PSP(s);
	
  if (!SocketValid(s)) return;
  /* bind the socket */
  ZeroMemory(&addr,sizeof(struct sockaddr_in));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((short)port);
  addr.sin_addr.s_addr = localHostAddress;
  
  bind( SOCKET(s), (struct sockaddr*) &addr, sizeof(struct sockaddr_in));
  if(UDPSocketType == s->socketType) { /* UDP */
    SOCKETSTATE(s) = Connected | SOCK_BOUND_UDP | SOCK_DATA_WRITABLE;
  } else { /* TCP */
    /* show our willingness to accept a single incoming connection */
    listen(SOCKET(s), 1);
    /* Waiting for accept => Start read watcher */
    pss->sockState = WaitingForConnection;
    pss->readWatcherOp = WatchAcceptSingle;
    SetEvent(pss->hReadWatcherEvent);
  }
}

/*****************************************************************************
  sqSocketListenOnPortBacklogSize: 
	TCP => start listening for incoming connections.
	UDP => Just call sqListenOnPort
*****************************************************************************/
void sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize)
{
  struct sockaddr_in addr;
  privateSocketStruct *pss = PSP(s);

  if (!SocketValid(s)) return;

  if(UDPSocketType == s->socketType) {
    sqSocketListenOnPort(s, port);
    return;
  }

  /* bind the socket */
  ZeroMemory(&addr,sizeof(struct sockaddr_in));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((short)port);
  addr.sin_addr.s_addr = localHostAddress;

  bind( SOCKET(s), (struct sockaddr*) &addr, sizeof(struct sockaddr_in));
  /* show our willingness to accept a backlogSize incoming connections */
  listen(SOCKET(s), backlogSize);
  LOCKSOCKET(pss->mutex, INFINITE);
  /* Waiting for accept => Start read watcher */
  pss->sockState = WaitingForConnection;
  pss->readWatcherOp = WatchAccept;
  SetEvent(pss->hReadWatcherEvent);
  UNLOCKSOCKET(pss->mutex);
}

/*****************************************************************************
  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID:
  Create a socket for the given netType (which is always internet here)
  a given socketType (UDP or TCP) appropriate buffer size (being ignored ;-)
  and a semaphore to signal upon changes in the socket state.
*****************************************************************************/
void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
            SocketPtr s, int netType, int socketType,
            int recvBufSize, int sendBufSize, int semaIndex)
{
  SOCKET newSocket;
  privateSocketStruct *pss;

  s->sessionID = 0;
  /* perform internal initialization */
  if(socketType == TCPSocketType)
    newSocket = socket(AF_INET,SOCK_STREAM, 0);
  else if(socketType == UDPSocketType)
    newSocket = socket(AF_INET, SOCK_DGRAM, 0);
  else { success(false); return; }
  if(newSocket == INVALID_SOCKET) {
    success(false);
    return;
  }
  /* Allow the re-use of the current port */
  setsockopt(newSocket, SOL_SOCKET, SO_REUSEADDR, (char*) &one, sizeof(one));
  /* Disable TCP delays */
  setsockopt(newSocket, IPPROTO_TCP, TCP_NODELAY, (char*) &one, sizeof(one));
  /* Make the socket non-blocking */
  ioctlsocket(newSocket,FIONBIO,&one);

  /* initialize private socket structure */
  pss = (privateSocketStruct*) calloc(1,sizeof(privateSocketStruct));
  pss->s = newSocket;
  pss->sockType = socketType;
  pss->semaphoreIndex = semaIndex;

  /* UDP sockets are born "connected" */
  if(UDPSocketType == socketType) {
    pss->sockState = Connected | SOCK_DATA_WRITABLE;
  } else {/* TCP */
    pss->sockState = Unconnected;
  }
  pss->sockError= 0;

  /* initial UDP peer := wildcard */
  ZeroMemory(&pss->peer, sizeof(pss->peer));
  pss->peer.sin_family= AF_INET;
  pss->peer.sin_port= htons((short)0);;
  pss->peer.sin_addr.s_addr= INADDR_ANY;

  /* fill the SQSocket */
  s->sessionID = thisNetSession;
  s->socketType = socketType;
  s->privateSocketPtr = pss;

  /* Create a new mutex object for synchronized access */
  pss->mutex = CreateMutex(NULL, 0,NULL);
  if(!pss->mutex) { success(false); return; }
  
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
    primitiveFail();
  }
}

/*****************************************************************************
  sqSocketAcceptFromRecvBytesSendBytesSemaID:
  Create a new socket by accepting an incoming connection from the source socket.
*****************************************************************************/
void sqSocketAcceptFromRecvBytesSendBytesSemaID(
            SocketPtr s, SocketPtr serverSocket,
            int recvBufSize, int sendBufSize, int semaIndex)
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
    success(false);
    return;
  }
  if(accepted->s == INVALID_SOCKET) {
    success(false);
    return;
  }
  /* private socket structure */
  pss = (privateSocketStruct*) calloc(1,sizeof(privateSocketStruct));
  pss->s = accepted->s;
  pss->sockType = PSP(serverSocket)->sockType;
  pss->semaphoreIndex = semaIndex;
  pss->sockState= Connected | SOCK_DATA_WRITABLE;
  pss->sockError= 0;
  MoveMemory(&pss->peer, &accepted->peer, sizeof(struct sockaddr_in));
  
  /* fill the SQSocket */
  s->sessionID = thisNetSession;
  s->socketType = pss->sockType;
  s->privateSocketPtr = pss;
	
  /* Disable TCP delays */
  setsockopt(SOCKET(s), IPPROTO_TCP, TCP_NODELAY, (char*) &one, sizeof(one));
  /* Make the socket non-blocking */
  ioctlsocket(SOCKET(s),FIONBIO,&one);

  /* Create a new mutex object for synchronized access */
  pss->mutex = CreateMutex(NULL, 0,NULL);
  if(!pss->mutex) { success(false); return; }

  /* Install the socket into the socket list */
  pss->next = firstSocket;
  firstSocket = pss;

  /* Setup the watchers */
  pss->readWatcherOp = pss->writeWatcherOp = WatchData;

  if(!createWatcherThreads(pss)) {
    /* note: necessary cleanup is done from within createWatcherThreads */
    s->privateSocketPtr = NULL; /* declare invalid */
    primitiveFail();
  }

  /* Cleanup */
  GlobalFree(GlobalHandle(accepted));
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
int sqSocketReceiveDataAvailable(SocketPtr s)
{
  int sockState;

  if(!SocketValid(s)) return 0;
  DBG(s);
  sockState = SOCKETSTATE(s);
  return (sockState & SOCK_DATA_READABLE) /* e.g., do we have data? */
    && ((sockState & SOCK_PUBLIC_MASK) == Connected); /* and are we still connected? */
}

/*****************************************************************************
  sqSocketReceiveDataBufCount:
  Receive data into the given buffer. Do not exceed bufSize.
  Return the number of bytes actually read.
*****************************************************************************/
int sqSocketReceiveDataBufCount(SocketPtr s, int buf, int bufSize)
{
  privateSocketStruct *pss = PSP(s);
  int result;
  int addrSize;

  if (!SocketValid(s)) return -1;
  if(bufSize <= 0) return bufSize;

  /* read incoming data */
  if(UDPSocketType == pss->sockType) { /* UDP */
    addrSize = sizeof(pss->peer);
    result = recvfrom(pss->s, (void*)buf, bufSize, 0, 
		      (struct sockaddr*) &pss->peer, &addrSize);
  } else { /* TCP */
    result = recv(pss->s,(void*)buf, bufSize, 0);
  }

/* printf("Data read (%d) WSAGetLastError (%d)\n", result, WSAGetLastError()); */
  /* Check if something went wrong */
  if(result <= 0) {
    /* Guard eventual writes to socket state */
    LOCKSOCKET(pss->mutex, INFINITE)
      if(result == 0)
	pss->sockState = OtherEndClosed;
      else if(result < 0) {
	int err = WSAGetLastError();
	if(err == WSAECONNRESET) /* connection reset by peer */
	  pss->sockState = OtherEndClosed;
	else if(err == WSAEWOULDBLOCK) {
	  /* no data available -> wake up read watcher */
	  pss->sockState &= ~SOCK_DATA_READABLE;
	  pss->readWatcherOp = WatchData;
	  SetEvent(pss->hReadWatcherEvent);
	} else {
	  pss->sockError = err;
	}
	result = 0;
      }
    UNLOCKSOCKET(pss->mutex);
  }
  return result;
}

/*****************************************************************************
  sqSocketSendDone: Return non-zero if all data has been sent.
*****************************************************************************/
int sqSocketSendDone(SocketPtr s)
{
  int sockState;

  if (!SocketValid(s)) return 1;
  DBG(s);
  sockState = SOCKETSTATE(s);
  return (sockState & SOCK_DATA_WRITABLE) /* e.g., everything has been written */
    && ((sockState & SOCK_PUBLIC_MASK) == Connected); /* and we are still connected */
}

/*****************************************************************************
  sqSocketSendDataBufCount:
  Send bufSize bytes from the data pointed to by buf. 
  Return the number of bytes sent.
*****************************************************************************/
int sqSocketSendDataBufCount(SocketPtr s, int buf, int bufSize)
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
  if(UDPSocketType == pss->sockType) { /* UDP */
    addrSize = sizeof(pss->peer);
    result = sendto(pss->s, (void*)buf, bufSize, 0, 
		    (struct sockaddr*) &pss->peer, addrSize);
  } else {
    result = send(pss->s, (void*)buf, bufSize, 0);
  }
/* printf("Data sent (%d) WSAGetLastError (%d)\n", result, WSAGetLastError()); */
  /* Check if something went wrong */
  if(result <= 0) {
    /* Guard eventual writes to socket state */
    LOCKSOCKET(pss->mutex, INFINITE)
      /***NOTE***NOTE***NOTE***NOTE***NOTE***
	  It's clear that for a write result being
	  equal to zero the other side must have
	  closed down (since we're rejecting zero
	  writes above) but nevertheless keep it
	  in mind if you change the above...
      **************************************/
      if(result == SOCKET_ERROR) {
	int err = WSAGetLastError();
	if(err == WSAECONNRESET) /* connection reset by peer */
	  pss->sockState = OtherEndClosed;
	else if(err == WSAEWOULDBLOCK) {
	  /* no data available => wake up write watcher */
	  pss->sockState &= ~SOCK_DATA_WRITABLE;
	  pss->writeWatcherOp = WatchData;
	  SetEvent(pss->hWriteWatcherEvent);
	} else {
	  pss->sockError = err;
	}
	result = 0;
      }
    UNLOCKSOCKET(pss->mutex);
  }
  return result;
}

/*****************************************************************************
  sqSocketError: Return any error on the socket.
*****************************************************************************/
int sqSocketError(SocketPtr s)
{
  if(!SocketValid(s)) return -1;
  return SOCKETERROR(s);
}

/*****************************************************************************
  sqSocketLocalAddress: Return the address of the socket on this host.
*****************************************************************************/
int sqSocketLocalAddress(SocketPtr s)
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
int sqSocketLocalPort(SocketPtr s)
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
int sqSocketRemoteAddress(SocketPtr s)
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
  return ntohl(sin.sin_addr.s_addr);
}

/*****************************************************************************
  sqSocketRemotePort: Return the port of the socket on the remote host
*****************************************************************************/
int sqSocketRemotePort(SocketPtr s)
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
 *****                     New Socket Functions                          *****
 *****************************************************************************
 NOTE: The semantics of the 3-sema socket is currently not well-defined.
       Therefore, it is not supported.
 *****************************************************************************/
void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex)
{
	primitiveFail();
}

void sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex)
{
	primitiveFail();
}

int sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, int buf, int bufSize,  int *address,  int *port, int *moreFlag)
{
	return primitiveFail();
}

int	sqSockettoHostportSendDataBufCount(SocketPtr s, int address, int port, int buf, int bufSize)
{
	return primitiveFail();
}

int sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int optionValue, int optionValueSize, int *result)
{
	return primitiveFail();
}

int sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int *result)
{
	return primitiveFail();
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
  asyncLookupHandle = 0;
}

/*****************************************************************************
  sqResolverAddrLookupResult: Return the result of the last name lookup
*****************************************************************************/
void sqResolverAddrLookupResult(char *nameForAddress, int nameSize)
{
  MoveMemory(nameForAddress, lastName, nameSize);
}

/*****************************************************************************
  sqResolverAddrLookupResult: Return sizeof(result) of the last name lookup
*****************************************************************************/
int sqResolverAddrLookupResultSize(void)
{
  return strlen(lastName);
}

/*****************************************************************************
  sqResolverError: Return the last error of a DNS lookup
*****************************************************************************/
int sqResolverError(void)
{
  return lastError;
}

/*****************************************************************************
  sqResolverLocalAddress: Return the address of the local host
*****************************************************************************/
int sqResolverLocalAddress(void)
{
  return addressOf(localHostName);
}

/*****************************************************************************
  sqResolverNameLookupResult: Return the address of the last DNS lookup
*****************************************************************************/
int sqResolverNameLookupResult(void)
{
  return lastAddr;
}

/*****************************************************************************
  sqResolverStartAddrLookup: Look up the name to a given address
*****************************************************************************/
void sqResolverStartAddrLookup(int address)
{
  DWORD id;
  if(asyncLookupHandle) return; /* lookup in progress */
  asyncLookupHandle =
    CreateThread(NULL,                    /* No security descriptor */
                 0,                       /* default stack size     */
                 (LPTHREAD_START_ROUTINE) &sqGetHostByAddr, /* what to do */
                 (LPVOID) address,        /* parameter for thread   */
                 CREATE_SUSPENDED,        /* creation parameter -- create suspended so we can check the return value */
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
void sqResolverStartNameLookup(char *hostName, int nameSize)
{ int len;
  DWORD id;

  if(asyncLookupHandle) return; /* lookup in progress */
  len = nameSize < MAXHOSTNAMELEN ? nameSize : MAXHOSTNAMELEN;
  if((strlen(lastName) == len) && (strncmp(hostName, lastName, len) == 0)) {
	  /* same as last, no point in looking it up */
	  signalSemaphoreWithIndex(resolverSemaphoreIndex);
	  return;
  }
  MoveMemory(lastName,hostName, len);
  lastName[len] = 0;
  lastError = 0;
  asyncLookupHandle =
    CreateThread(NULL,                    /* No security descriptor */
                 0,                       /* default stack size     */
                 (LPTHREAD_START_ROUTINE) &sqGetHostByName, /* what to do */
                 (LPVOID) lastName,       /* parameter for thread   */
                 CREATE_SUSPENDED,        /* creation parameter -- create suspended so we can check the return value */
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
int sqResolverStatus(void)
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
    }
  else
    lastError = WSAGetLastError();
  asyncLookupHandle = 0;
  synchronizedSignalSemaphoreWithIndex(resolverSemaphoreIndex);
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
    }
  else
    lastError = WSAGetLastError();
  asyncLookupHandle = 0;
  synchronizedSignalSemaphoreWithIndex(resolverSemaphoreIndex);
  ExitThread(0);
  return 1;
}

/***** socket module initializers *****/
int socketInit(void)
{
	thisNetSession = 0;
	return 1;
}

int socketShutdown(void)
{
	sqNetworkShutdown();
	sqResolverAbort();
	return 1;
}

#endif /* NO_NETWORK */
