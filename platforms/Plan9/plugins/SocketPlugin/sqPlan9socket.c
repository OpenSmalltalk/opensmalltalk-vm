/*
 * Plan9 Socket plugin implementation
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#include "sq.h"
#include "SocketPlugin.h"

#include <bio.h>
#include <ip.h>
#include <mach.h>
#include <ndb.h>
#include <thread.h>

#define LOCALHOST 0x7f000001

/* Possible connection states */
enum connection_state {
	STATE_UNCONNECTED = 0,
	STATE_WAITING_FOR_CONNECTION = 1,
	STATE_CONNECTED = 2,
	STATE_CLOSED_BY_PEER = 3,
	STATE_CLOSED_BY_HOST = 4
};

enum resolver_state {
	RESOLVER_UNINITIALIZED = 0,
	RESOLVER_SUCCESS = 1,
	RESOLVER_IN_PROGRESS = 2,
	RESOLVER_FAIL = 3
};

enum resolver_type {
	TYPE_INVALID = 0,
	TYPE_IP = 1,
	TYPE_PTR = 2
};

typedef struct {
	sqInt connSemaIndex;
	sqInt readSemaIndex;
	sqInt writeSemaIndex;
	sqInt netType;
	int state;
	int error;
	/* State variables */
	int data_fd;
	int ctl_fd;
	char* conn_dir;
	int threadid;
	sqInt localAddr;
	sqInt localPort;
	sqInt remoteAddr;
	sqInt remotePort;
} privateSocket;

typedef struct {
	privateSocket* ps;
	char* net;
	sqInt addr;
	sqInt port;
} dialThreadArgs;

int sessionID = 0;

int resolverSemaphore;
int lastDNSAddr = 0;
char* lastDNSName = NULL;
int resolverState = RESOLVER_UNINITIALIZED;
int resolverThreadID = -1;
Channel resolverChannel;

/* Internal, static functions */
static int verifySocketPtr(SocketPtr s) {
	if (s->sessionID != sessionID) {
		return 0;
	}
	return 1;
}

static int getv4AddrPort(char* file, int* addr);
static int getAddrPort(char* file, char* addr, int addrlen);
static int getLocalPort(char* dir);

static void dialThread(void* arg) {
	dialThreadArgs* args = (dialThreadArgs*)arg;
	privateSocket* ps = args->ps;
	char* net = args->net;
	sqInt addr = args->addr;
	sqInt port = args->port;
	free(args);

	char maddr[40];
	char dir[NETPATHLEN];

	snprintf(maddr, sizeof(maddr), "%s!%d.%d.%d.%d!%d", net, (addr >> 24) & 0xff, 
			(addr >> 16) & 0xff, (addr >> 8) & 0xff, addr & 0xff, port);

	ps->data_fd = dial(maddr, NULL, dir, &ps->ctl_fd);

	yield(); //To possibly be killed if necessary

	if (ps->data_fd == -1) {
		//Socket remains unconnected
		ps->error = -1;
		ps->state = STATE_UNCONNECTED;
		signalSemaphoreWithIndex(ps->connSemaIndex);
		threadexits("failure");
	}
	ps->state = STATE_CONNECTED;
	ps->remoteAddr = addr;
	ps->remotePort = port;
	ps->localAddr = LOCALHOST;
	ps->localPort = getLocalPort(dir);
	ps->conn_dir = strdup(dir);
	signalSemaphoreWithIndex(ps->connSemaIndex);	
	threadexits("success");
}

static void listenThread(void* arg) {
	privateSocket* ps = (privateSocket*)arg;

	char dir[NETPATHLEN];
	int newfd = listen(ps->conn_dir, dir);

	yield(); //To possibly be killed if necessary

	if (newfd == -1) {
		ps->error = -1;
		ps->state = STATE_UNCONNECTED;
		signalSemaphoreWithIndex(ps->connSemaIndex);
		threadexits("failure");
	}

	//Close previous listen control fd
	close(ps->ctl_fd);
	ps->ctl_fd = newfd;

	//Pivot connection directory
	free(ps->conn_dir);
	ps->conn_dir = strdup(dir);

	ps->data_fd = accept(ps->ctl_fd, dir);

	yield(); //To possibly be killed if necessary
	
	if (ps->data_fd == -1) {
		hangup(ps->ctl_fd);
		close(ps->ctl_fd);
		ps->error = -2;
		ps->state = STATE_UNCONNECTED;
		signalSemaphoreWithIndex(ps->connSemaIndex);
		threadexits("failure");
	}

	char remotefile[NETPATHLEN+7];
	char remoteAddr[40];
	snprintf(remotefile, sizeof(remotefile), "%s/remote", ps->conn_dir);

	ps->remotePort = getv4AddrPort(remotefile, &ps->remoteAddr);
	if (ps->remotePort == -1) {
		hangup(ps->ctl_fd);
		close(ps->data_fd);
		close(ps->ctl_fd);
		ps->error = -3;
		ps->state = STATE_UNCONNECTED;
		signalSemaphoreWithIndex(ps->connSemaIndex);
		threadexits("failure");
	}
	
	ps->state = STATE_CONNECTED;
	signalSemaphoreWithIndex(ps->connSemaIndex);
	threadexits("success");
}

static void dnsThread(void* args) {
	char* name, *type_str;
	int type;
	while (recv(&resolverChannel, &name) > 0) {
		type = (int)recvp(&resolverChannel);
		if (type == TYPE_INVALID) break;

		type_str = "ip";
		if (type == TYPE_PTR)
			type_str = "ptr";

		Ndbtuple* result = dnsquery("/net", name, type_str);
		free(name);
		if (result == NULL) {
			resolverState = RESOLVER_FAIL;
			signalSemaphoreWithIndex(resolverSemaphore);
			continue;
		}

		//Get first entry
		if (type == TYPE_PTR) {
			//We actually want the domain value
			type_str = "dom";
		}

		Ndbtuple* entry = ndbfindattr(result, NULL, type_str);
		if (entry == NULL) {
			ndbfree(result);
			resolverState = RESOLVER_FAIL;
			signalSemaphoreWithIndex(resolverSemaphore);
			continue;
		}
		else {
			if (type == TYPE_IP) {
				v4parseip((uchar*)&lastDNSAddr,entry->val);
				//Swap the bytes, if necessary
				lastDNSAddr = beswal(lastDNSAddr);
			}
			else if (type == TYPE_PTR) {
				lastDNSName = strdup(entry->val);
			}
		}

		ndbfree(result);

		//Only signal if we're still 'in progress', for aborted lookups
		if (resolverState == RESOLVER_IN_PROGRESS) {
			signalSemaphoreWithIndex(resolverSemaphore);
			resolverState = RESOLVER_SUCCESS;
		}
	}
	printf("bye\n");
	threadexits("success");
}

static int getv4AddrPort(char* file, int* addr) {
	char remoteAddr[40];
	int port;
	uchar ipaddr[16];

	port = getAddrPort(file, remoteAddr, sizeof(remoteAddr));
	if (port == -1) {
		return -1;
	}

	//Try to get the v4 address
	*addr = parseip(ipaddr, remoteAddr);
	if (*addr == 6) {
		int i = 0;
		int ipv4 = 1;
		if (!memcmp(v4prefix, ipaddr, 12)) {
			*addr = ipaddr[12] << 24 | ipaddr[13] << 16 | ipaddr[14] << 8 | ipaddr[15];
		}
		else {
			*addr = -1;
		}
	}
	return port;
}

static int getAddrPort(char* file, char* addr, int addrlen) {
	FILE* f = fopen(file, "r");
	if (f == NULL) {
		return -1;
	}

	char addrbuf[40];
	int port;
	fscanf(f, "%s!%d", addrbuf, port);
	fclose(f);

	//Ensure there's enough room
	if (addr != NULL) {
		if (strlen(addrbuf)+1 > addrlen) {
			return -1;
		}
		strcpy(addr, addrbuf);
	}
	return port;
}

static int getLocalPort(char* dir) {
	char localfile[NETPATHLEN+6];
	snprintf(localfile, sizeof(localfile), "%s/local", dir);

	return getAddrPort(localfile, NULL, 0);
}


/* Externally-referenced functions */
sqInt socketInit(void) {
	return 1;
}

sqInt socketShutdown(void) {
	return 1;
}

sqInt sqNetworkInit(sqInt resolverSemaIndex) {
	if (sessionID != 0) {
		return 0;
	}
	sessionID = ioMSecs();
	if (sessionID == 0)
		sessionID = 1;

	//Initialize resolver values
	resolverSemaphore = resolverSemaIndex;
	if (chaninit(&resolverChannel, sizeof(char*), 0) < 0) {
		success(0);
		sessionID = 0;
		resolverSemaphore = 0;
		return;
	}
	//Dns thread actually needs a good amount of stack space
	resolverThreadID = proccreate(dnsThread, NULL, 4096);
	resolverState = RESOLVER_SUCCESS;
	
	return 0;
}

void sqNetworkShutdown(void) {
	sessionID = 0;
	resolverSemaphore = 0;

	threadkill(resolverThreadID);
	threadint(resolverThreadID);
	chanclose(&resolverChannel);
	chanfree(&resolverChannel);
	resolverState = RESOLVER_UNINITIALIZED;
}


/* Resolver Functions */
void  sqResolverAbort(void) {
	resolverState = RESOLVER_FAIL;
}

void  sqResolverAddrLookupResult(char *nameForAddress, sqInt nameSize) {
	if (lastDNSName == NULL)
		return;

	int len = strlen(lastDNSName);
	memcpy(nameForAddress, lastDNSName, len < nameSize ? len : nameSize);
	free(lastDNSName);
	lastDNSName = NULL;
}

sqInt sqResolverAddrLookupResultSize(void) {
	if (lastDNSName == NULL)
		return -1;

	return strlen(lastDNSName);
}

sqInt sqResolverError(void) {
	return -1;
}

sqInt sqResolverLocalAddress(void) {
	return LOCALHOST;
}

sqInt sqResolverNameLookupResult(void) {
	if (resolverState == RESOLVER_FAIL)
		return -1;
	return lastDNSAddr;
}

void  sqResolverStartAddrLookup(sqInt address) {
	if (resolverState == RESOLVER_IN_PROGRESS) {
		//lookup already in progress
		success(0);
		return;
	}

	char* addrstr = (char*)malloc(16*sizeof(char));
	if (addrstr == NULL) {
		success(0);
		return;
	}

	snprintf(addrstr, 16, "%d.%d.%d.%d", (address >> 24) & 0xff,
			(address >> 16) & 0xff,	(address >> 8) & 0xff, address & 0xff);
	addrstr[15] = '\0';

	resolverState = RESOLVER_IN_PROGRESS;
	sendp(&resolverChannel, (void*)addrstr);
	sendp(&resolverChannel, (void*)TYPE_PTR);
}

void  sqResolverStartNameLookup(char *hostName, sqInt nameSize) {
	if (resolverState == RESOLVER_IN_PROGRESS) {
		//lookup already in progress
		success(0);
		return;
	}

	char* name = (char*)malloc((nameSize+1)*sizeof(char));
	if (name == NULL) {
		success(0);
		return;
	}
	memcpy(name, hostName, nameSize);
	name[nameSize] = '\0';

	resolverState = RESOLVER_IN_PROGRESS;
	sendp(&resolverChannel, (void*)name);
	sendp(&resolverChannel, (void*)TYPE_IP);
}

sqInt sqResolverStatus(void) {
	return resolverState;
}


void  sqResolverGetAddressInfoHostSizeServiceSizeFlagsFamilyTypeProtocol(char *hostName, sqInt hostSize, char *servName, sqInt servSize,
																		 sqInt flags, sqInt family, sqInt type, sqInt protocol) {
	//Unsupported
}

sqInt sqResolverGetAddressInfoSize(void) {
	return 0;
}

void  sqResolverGetAddressInfoResultSize(char *addr, sqInt addrSize) {
	//Unsupported
}

sqInt sqResolverGetAddressInfoFamily(void) {
	return 0;
}

sqInt sqResolverGetAddressInfoType(void) {
	return 0;
}

sqInt sqResolverGetAddressInfoProtocol(void) {
	return 0;
}

sqInt sqResolverGetAddressInfoNext(void) {
	return 0;
}


void  sqResolverGetNameInfoSizeFlags(char *addr, sqInt addrSize, sqInt flags) {
	//Unsupported
}

sqInt sqResolverGetNameInfoHostSize(void) {
	return 0;
}

void  sqResolverGetNameInfoHostResultSize(char *name, sqInt nameSize) {
	//Unsupported
}

sqInt sqResolverGetNameInfoServiceSize(void) {
	return 0;
}

void  sqResolverGetNameInfoServiceResultSize(char *name, sqInt nameSize) {
	//Unsupported
}


sqInt sqResolverHostNameSize(void) {
	return 0;
}

void  sqResolverHostNameResultSize(char *name, sqInt nameSize) {
	//Unsupported
}


/* Socket Functions */
void  sqSocketAbortConnection(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;

	if (ps->threadid != 0) {
		threadkill(ps->threadid);
		threadint(ps->threadid);
	}

	ps->threadid = 0;
	if (ps->ctl_fd != 0) {
		hangup(ps->ctl_fd);
		close(ps->ctl_fd);
	}
	if (ps->data_fd != 0)
		close(ps->data_fd);
	ps->ctl_fd = 0;
	ps->data_fd = 0;
	free(ps->conn_dir);
	ps->conn_dir = NULL;

	ps->state = STATE_UNCONNECTED;
}

void  sqSocketCloseConnection(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}
	
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;

	if (ps->state != STATE_CONNECTED) {
		success(0);
		return;
	}

	hangup(ps->ctl_fd);
	close(ps->ctl_fd);
	close(ps->data_fd);
	ps->ctl_fd = 0;
	ps->data_fd = 0;
	ps->threadid = 0;
	free(ps->conn_dir);
	ps->conn_dir = NULL;

	ps->state = STATE_UNCONNECTED;
}

sqInt sqSocketConnectionStatus(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}
	return ((privateSocket*)s->privateSocketPtr)->state;
}

void  sqSocketConnectToPort(SocketPtr s, sqInt addr, sqInt port) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;

	char* net;
	if (s->socketType == 0) net = "tcp";
	else if (s->socketType == 1) net = "udp";
	else net = "net";

	dialThreadArgs* args = (dialThreadArgs*)malloc(sizeof(dialThreadArgs));
	if (args == NULL) {
		success(0);
		return;
	}
	args->ps = ps;
	args->net = net;
	args->addr = addr;
	args->port = port;
	ps->state = STATE_WAITING_FOR_CONNECTION;

	ps->threadid = proccreate(dialThread, args, 1024);
}

void  sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID
(SocketPtr s, sqInt netType, sqInt socketType,
 sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex) {
	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
	(s, netType, socketType, recvBufSize, sendBufSize,
	 semaIndex, semaIndex, semaIndex);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID
(SocketPtr s, sqInt netType, sqInt socketType,
 sqInt recvBufSize, sqInt sendBufSize,
 sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex) {
 	privateSocket *ps;
 	s->sessionID = sessionID;
 	s->socketType = socketType;
 	ps = (privateSocket*)calloc(1,sizeof(privateSocket));
 	if (ps == NULL) {
 		success(0);
 		return;
	}
	ps->netType = netType;
	ps->connSemaIndex = semaIndex;
	ps->readSemaIndex = readSemaIndex;
	ps->writeSemaIndex = writeSemaIndex;
	ps->state = STATE_UNCONNECTED;
	s->privateSocketPtr = (void*)ps;
}

void sqSocketCreateRawProtoTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, sqInt domain, sqInt protocol, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex) {
	if (!verifySocketPtr(s)) {
		return;
	}
}

void  sqSocketDestroy(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	free(ps->conn_dir);
	free(ps);
	s->privateSocketPtr = NULL;
	s->sessionID = 0;
	s->socketType = -1;
}

sqInt sqSocketError(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}
	return ((privateSocket*)s->privateSocketPtr)->error;
}

void  sqSocketListenOnPort(SocketPtr s, sqInt port) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}

	char addr[15];
	char dir[NETPATHLEN];
	char* net;
	if (s->socketType == 0) net = "tcp";
	else if (s->socketType == 1) net = "udp";
	else net = "net";

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;

	snprintf(addr, sizeof(addr), "%s!*!%d", net, port);

	ps->ctl_fd = announce(addr, dir);
	if (ps->ctl_fd == -1) {
		//Socket remains unconnected
		success(0);
		return;
	}

	ps->conn_dir = strdup(dir);
	if (ps->conn_dir == NULL) {
		success(0);
		return;
	}

	ps->localAddr = LOCALHOST;
	ps->localPort = port;
	ps->state = STATE_WAITING_FOR_CONNECTION;

	//Spawn thread to wait for listen to return
	ps->threadid = proccreate(listenThread, ps, 1024);
}

sqInt sqSocketLocalAddress(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	if (((privateSocket*)s->privateSocketPtr)->state != STATE_CONNECTED)
		return 0;

	return ((privateSocket*)s->privateSocketPtr)->localAddr;
}

sqInt sqSocketLocalPort(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	if (((privateSocket*)s->privateSocketPtr)->state != STATE_CONNECTED)
		return 0;

	return ((privateSocket*)s->privateSocketPtr)->localPort;
}

sqInt sqSocketReceiveDataAvailable(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	if (ps->state != STATE_CONNECTED) {
		return -1;
	}

	Dir* d = dirfstat(ps->data_fd);
	int ret = (d->length > 0);
	free(d);
	return ret;
}

sqInt sqSocketReceiveDataBufCount(SocketPtr s, char *buf, sqInt bufSize) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	if (ps->state != STATE_CONNECTED) {
		return 0;
	}

	int bytes_read = read(ps->data_fd, buf, bufSize);
	signalSemaphoreWithIndex(ps->readSemaIndex);
	if (bytes_read == 0) {
		ps->state = STATE_CLOSED_BY_PEER;
	}
	return bytes_read;
}

sqInt sqSocketRemoteAddress(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	if (((privateSocket*)s->privateSocketPtr)->state != STATE_CONNECTED)
		return 0;

	return ((privateSocket*)s->privateSocketPtr)->remoteAddr;
}

sqInt sqSocketRemotePort(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}
	
	if (((privateSocket*)s->privateSocketPtr)->state != STATE_CONNECTED)
		return 0;

	return ((privateSocket*)s->privateSocketPtr)->remotePort;
}

sqInt sqSocketSendDataBufCount(SocketPtr s, char *buf, sqInt bufSize) {
	if (!verifySocketPtr(s)) {
		return -1;
	}
	
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	if (ps->state != STATE_CONNECTED) {
		return 0;
	}

	int bytes_written = write(ps->data_fd, buf, bufSize);
	signalSemaphoreWithIndex(ps->writeSemaIndex);

	//read(2) says that if write doesn't write as many bytes as requested, it
	//should be regarded as an error
	if (bytes_written != bufSize) {
		ps->state = STATE_CLOSED_BY_PEER;
		return 0;
	}
	return bufSize;
}

sqInt sqSocketSendDone(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	if (ps->state != STATE_CONNECTED) {
		return -1;
	}

	//As far as we can tell, we can always write bytes without blocking
	return 1;
}

/* ar 7/16/1999: New primitives for accept().  Note: If accept() calls are not supported simply make the calls fail and the old connection style will be used. */
void  sqSocketListenOnPortBacklogSize(SocketPtr s, sqInt port, sqInt backlogSize) {
	if (!verifySocketPtr(s)) {
		return;
	}
	success(0);
}

void  sqSocketListenOnPortBacklogSizeInterface(SocketPtr s, sqInt port, sqInt backlogSize, sqInt addr) {
	if (!verifySocketPtr(s)) {
		return;
	}
	success(0);
}

/* Since we don't use sqSocketListenOnPortBacklogSize, the following two
 * functions shouldn't ever be called. But here's what a likely implementation
 * would look like.
 */
void  sqSocketAcceptFromRecvBytesSendBytesSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex) {
	sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, serverSocket, recvBufSize, sendBufSize, semaIndex, semaIndex, semaIndex);
}

void  sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(SocketPtr s, SocketPtr serverSocket, sqInt recvBufSize, sqInt sendBufSize, sqInt semaIndex, sqInt readSemaIndex, sqInt writeSemaIndex) {
	if (!verifySocketPtr(serverSocket)) {
		success(0);
		return;
	}
	
 	privateSocket *ps, *ops;
 	s->sessionID = sessionID;
 	s->socketType = serverSocket->socketType;
 	ps = (privateSocket*)calloc(1,sizeof(privateSocket));
 	if (ps == NULL) {
 		success(0);
 		return;
	}
	ops = (privateSocket*)serverSocket->privateSocketPtr;
	ps->netType = ops->netType;
	ps->connSemaIndex = semaIndex;
	ps->readSemaIndex = readSemaIndex;
	ps->writeSemaIndex = writeSemaIndex;
	ps->state = STATE_UNCONNECTED;
	s->privateSocketPtr = (void*)ps;

	ps->data_fd = accept(ps->ctl_fd, NULL);
	if (ps->data_fd == -1) {
		free(ps);
		s->privateSocketPtr = NULL;
		s->sessionID = 0;
		success(0);
		return;
	}

	ps->state = STATE_CONNECTED;
	signalSemaphoreWithIndex(ps->connSemaIndex);
}

sqInt sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, char *buf, sqInt bufSize, sqInt *address, sqInt *port, sqInt *moreFlag) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	char remotefile[NETPATHLEN+7];
	snprintf(remotefile, sizeof(remotefile), "%s/remote", ps->conn_dir);

	int recvd = sqSocketReceiveDataBufCount(s, buf, bufSize);
	*moreFlag = sqSocketReceiveDataAvailable(s);
	*port = getv4AddrPort(remotefile, address);
	ps->remotePort = *port;
	ps->remoteAddr = *address;
	return recvd;
}

sqInt sqSockettoHostportSendDataBufCount(SocketPtr s, sqInt address, sqInt port, char *buf, sqInt bufSize) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	//Disconnect from previous connection
	if (((privateSocket*)s->privateSocketPtr)->state == STATE_CONNECTED) {
		sqSocketCloseConnection(s);
	}
	else {
		sqSocketAbortConnection(s);
	}

	sqSocketConnectToPort(s, address, port);
	return sqSocketSendDataBufCount(s, buf, bufSize);
}

sqInt sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, char *optionValue, sqInt optionValueSize, sqInt *result) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	//No options supported currently
	success(0);
	return 0;
}

sqInt sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(SocketPtr s, char *optionName, sqInt optionNameSize, sqInt *result) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	//No options supported currently
	success(0);
	return 0;
}

/* tpr 4/12/06 add declarations for two new socket routines */
void sqSocketBindToPort(SocketPtr s, int addr, int port) {
	if (!verifySocketPtr(s)) {
		success(0);
		return;
	}
	//No such concept in Plan9
	success(0);
	return;
}

void sqSocketSetReusable(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return;
	}
	//Always reusable in Plan9
	return;
}

sqInt sqSocketAddressSizeGetPort(char *addr, sqInt addrSize) {
	//Unsupported
	success(0);
	return -1;
}

void  sqSocketAddressSizeSetPort(char *addr, sqInt addrSize, sqInt port) {
	//Unsupported
	success(0);
}

void  sqSocketBindToAddressSize(SocketPtr s, char *addr, sqInt addrSize) {
	if (!verifySocketPtr(s)) {
		return;
	}
	//TODO listen for connections to addr
}

void  sqSocketListenBacklog(SocketPtr s, sqInt backlogSize) {
	if (!verifySocketPtr(s)) {
		return;
	}

	//Not supported
	success(0);
}

void  sqSocketConnectToAddressSize(SocketPtr s, char *addr, sqInt addrSize) {
	if (!verifySocketPtr(s)) {
		return;
	}
	//TODO connect to addr
}

sqInt sqSocketLocalAddressSize(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	char localfile[NETPATHLEN+6];
	char addr[40];
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	snprintf(localfile, sizeof(localfile), "%s/local", ps->conn_dir);

	int port = getAddrPort(localfile, addr, sizeof(addr));
	if (port == -1) {
		success(0);
		return -1;
	}

	return strlen(addr);
}

void  sqSocketLocalAddressResultSize(SocketPtr s, char *addr, int addrSize) {
	if (!verifySocketPtr(s)) {
		return;
	}

	char localfile[NETPATHLEN+6];
	char maddr[40];
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	snprintf(localfile, sizeof(localfile), "%s/local", ps->conn_dir);

	int port = getAddrPort(localfile, maddr, sizeof(maddr));
	if (port == -1) {
		success(0);
		return;
	}

	if (addrSize < strlen(maddr)) {
		success(0);
		return;
	}

	memcpy(addr, maddr, strlen(maddr));
}

sqInt sqSocketRemoteAddressSize(SocketPtr s) {
	if (!verifySocketPtr(s)) {
		return -1;
	}

	char remotefile[NETPATHLEN+7];
	char addr[40];
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	snprintf(remotefile, sizeof(remotefile), "%s/remote", ps->conn_dir);

	int port = getAddrPort(remotefile, addr, sizeof(addr));
	if (port == -1) {
		success(0);
		return -1;
	}

	return strlen(addr);
}

void  sqSocketRemoteAddressResultSize(SocketPtr s, char *addr, int addrSize) {
	if (!verifySocketPtr(s)) {
		return;
	}

	char remotefile[NETPATHLEN+7];
	char maddr[40];
	privateSocket* ps = (privateSocket*)s->privateSocketPtr;
	snprintf(remotefile, sizeof(remotefile), "%s/remote", ps->conn_dir);

	int port = getAddrPort(remotefile, maddr, sizeof(maddr));
	if (port == -1) {
		success(0);
		return;
	}

	if (addrSize < strlen(maddr)) {
		success(0);
		return;
	}

	memcpy(addr, maddr, strlen(maddr));
}
