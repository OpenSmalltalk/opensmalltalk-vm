/* squeak socket record; see sqMacNetwork.c for details */

/* module initialization/shutdown */
int socketInit(void);
int socketShutdown(void);

typedef struct {
	int		sessionID;
	int		socketType;  /* 0 = TCP, 1 = UDP */
	void	*privateSocketPtr;
}  SQSocket, *SocketPtr;

/* networking primitives */
int		sqNetworkInit(int resolverSemaIndex);
void	sqNetworkShutdown(void);
void	sqResolverAbort(void);
void	sqResolverAddrLookupResult(char *nameForAddress, int nameSize);
int		sqResolverAddrLookupResultSize(void);
int		sqResolverError(void);
int		sqResolverLocalAddress(void);
int		sqResolverNameLookupResult(void);
void	sqResolverStartAddrLookup(int address);
void	sqResolverStartNameLookup(char *hostName, int nameSize);
int		sqResolverStatus(void);
void	sqSocketAbortConnection(SocketPtr s);
void	sqSocketCloseConnection(SocketPtr s);
int		sqSocketConnectionStatus(SocketPtr s);
void	sqSocketConnectToPort(SocketPtr s, int addr, int port);
void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex);
void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex);
void	sqSocketDestroy(SocketPtr s);
int		sqSocketError(SocketPtr s);
void	sqSocketListenOnPort(SocketPtr s, int port);
int		sqSocketLocalAddress(SocketPtr s);
int		sqSocketLocalPort(SocketPtr s);
int		sqSocketReceiveDataAvailable(SocketPtr s);
int		sqSocketReceiveDataBufCount(SocketPtr s, int buf, int bufSize);
int		sqSocketRemoteAddress(SocketPtr s);
int		sqSocketRemotePort(SocketPtr s);
int		sqSocketSendDataBufCount(SocketPtr s, int buf, int bufSize);
int		sqSocketSendDone(SocketPtr s);
/* 	ar 7/16/1999: New primitives for accept().
	Note: If accept() calls are not supported simply make the calls fail
	and the old connection style will be used */
void	sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize);
void	sqSocketAcceptFromRecvBytesSendBytesSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex);
void	sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex);
int 		sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, int buf, int bufSize,  int *address,  int *port, int *moreFlag);
int		sqSockettoHostportSendDataBufCount(SocketPtr s, int address, int port, int buf, int bufSize);
int     	sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int optionValue, int optionValueSize, int *result);
int     	sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(
			SocketPtr s,int optionName, int optionNameSize, int *result);

/*** security traps ***/
/* check if we are allowed to create the given socket */
int ioCanCreateSocketOfType(int netType, int socketType);
/* check if we are allowed to connect to the given port */
int ioCanConnectToPort(int netAddr, int port);
/* check if we are allowed to listen on the given port
	Note: ability to listen applies also to setting ports of UDP sockets.
	For TCP sockets, the ability to listen implies the ability to accept(). */
int ioCanListenOnPort(SocketPtr s, int port);
/* disable all use of sockets */
int ioDisableSocketAccess(void);
/* query for socket availability */
int ioHasSocketAccess(void);

#ifdef DISABLE_SECURITY
#define ioCanCreateSocketOfType(netType, socketType) 1
#define ioCanConnectToPort(netAddr, port) 1
#define ioCanListenOnPort(s, port) 1
#define ioDisableSocketAccess() 1
#define ioHasSocketAccess() 1
#endif

