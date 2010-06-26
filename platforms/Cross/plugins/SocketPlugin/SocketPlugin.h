/* squeak socket support header file */

/* module initialization/shutdown */
sqInt socketInit(void);
sqInt socketShutdown(void);

typedef struct
{
  int	sessionID;
  int	socketType;  /* 0 = TCP, 1 = UDP */
  void	*privateSocketPtr;
}  SQSocket, *SocketPtr;

/* networking primitives */
sqInt sqNetworkInit(sqInt resolverSemaIndex);
void  sqNetworkShutdown(void);
void  sqResolverAbort(void);
void  sqResolverAddrLookupResult(char *nameForAddress, sqInt nameSize);
sqInt sqResolverAddrLookupResultSize(void);
sqInt sqResolverError(void);
sqInt sqResolverLocalAddress(void);
sqInt sqResolverNameLookupResult(void);
void  sqResolverStartAddrLookup(sqInt address);
void  sqResolverStartNameLookup(char *hostName, sqInt nameSize);
sqInt sqResolverStatus(void);
void  sqSocketAbortConnection(SocketPtr s);
void  sqSocketCloseConnection(SocketPtr s);
sqInt sqSocketConnectionStatus(SocketPtr s);
void  sqSocketConnectToPort(SocketPtr s, sqInt addr, sqInt port);
void  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(SocketPtr s, sqInt netType, sqInt socketType, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex);
void  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt netType, sqInt socketType, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex);
void  sqSocketDestroy(SocketPtr s);
sqInt sqSocketError(SocketPtr s);
void  sqSocketListenOnPort(SocketPtr s, sqInt port);
sqInt sqSocketLocalAddress(SocketPtr s);
sqInt sqSocketLocalPort(SocketPtr s);
sqInt sqSocketReceiveDataAvailable(SocketPtr s);
sqInt sqSocketReceiveDataBufCount(SocketPtr s, char *buf, sqInt bufSize);
sqInt sqSocketRemoteAddress(SocketPtr s);
sqInt sqSocketRemotePort(SocketPtr s);
sqInt sqSocketSendDataBufCount(SocketPtr s, char *buf, sqInt bufSize);
sqInt sqSocketSendDone(SocketPtr s);
/* ar 7/16/1999: New primitives for accept().  Note: If accept() calls are not supported simply make the calls fail and the old connection style will be used. */
void  sqSocketListenOnPortBacklogSize(SocketPtr s, sqInt port, sqInt backlogSize);
void  sqSocketListenOnPortBacklogSizeInterface(SocketPtr s, sqInt port, sqInt backlogSize, sqInt addr);
void  sqSocketAcceptFromRecvBytesSendBytesSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex);
void  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex);
sqInt sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, char *buf, sqInt bufSize,  sqInt *address,  sqInt *port, sqInt *moreFlag);
sqInt sqSockettoHostportSendDataBufCount(SocketPtr s, sqInt address, sqInt port, char *buf, sqInt bufSize);
sqInt sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, char *optionValue, sqInt optionValueSize, sqInt *result);
sqInt sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, sqInt *result);
/* tpr 4/12/06 add declarations for two new socket routines */
void sqSocketBindToPort(SocketPtr s, int addr, int port);
void sqSocketSetReusable(SocketPtr s);
